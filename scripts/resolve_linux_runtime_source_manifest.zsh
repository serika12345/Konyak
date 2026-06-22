#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
RELEASE_METADATA_PATH="${ROOT}/runtime/linux-wine-release.json"

profile="release"
manifest_cache=""
signature_cache=""
public_key_cache=""
print_manifest_path=false
print_signature_path=false
print_public_key_path=false

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --profile)
      profile="${2:-}"
      shift 2
      ;;
    --manifest-cache)
      manifest_cache="${2:-}"
      shift 2
      ;;
    --signature-cache)
      signature_cache="${2:-}"
      shift 2
      ;;
    --public-key-cache)
      public_key_cache="${2:-}"
      shift 2
      ;;
    --print-manifest-path)
      print_manifest_path=true
      shift
      ;;
    --print-signature-path)
      print_signature_path=true
      shift
      ;;
    --print-public-key-path)
      print_public_key_path=true
      shift
      ;;
    *)
      print -u2 "unknown argument: $1"
      exit 64
      ;;
  esac
done

case "${profile}" in
  development|release)
    ;;
  *)
    print -u2 "Linux runtime source manifest profile must be development or release."
    exit 64
    ;;
esac

require_command() {
  local command_name="$1"

  if ! command -v "${command_name}" >/dev/null 2>&1; then
    print -u2 "${command_name} not found. Run this script inside nix develop."
    exit 69
  fi
}

require_command python3
require_command curl

json_value() {
  local key="$1"

  python3 - "${RELEASE_METADATA_PATH}" "${key}" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    payload = json.load(handle)

if payload.get("schemaVersion") != 1:
    raise SystemExit(f"{sys.argv[1]}: schemaVersion must be 1")

value = payload.get(sys.argv[2], "")
if value is None:
    value = ""
if not isinstance(value, str):
    raise SystemExit(f"{sys.argv[1]}: {sys.argv[2]} must be a string")
print(value.strip())
PY
}

is_url() {
  case "$1" in
    http://*|https://*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

release_asset_url() {
  local repository="$1"
  local release_tag="$2"
  local file_name="$3"

  if [[ "${release_tag}" == "latest" ]]; then
    print -r -- "https://github.com/${repository}/releases/latest/download/${file_name}"
  else
    print -r -- "https://github.com/${repository}/releases/download/${release_tag}/${file_name}"
  fi
}

resolve_local_path() {
  local source_path="$1"

  if [[ -f "${source_path}" ]]; then
    print -r -- "${source_path}"
  elif [[ -f "${ROOT}/${source_path}" ]]; then
    print -r -- "${ROOT}/${source_path}"
  else
    return 1
  fi
}

validate_manifest() {
  local manifest_path="$1"

  python3 - "${manifest_path}" <<'PY'
import json
import sys

manifest_path = sys.argv[1]
with open(manifest_path, encoding="utf-8") as handle:
    payload = json.load(handle)

if payload.get("schemaVersion") != 1:
    raise SystemExit(f"{manifest_path}: schemaVersion must be 1")
if payload.get("runtimeId") != "konyak-linux-wine":
    raise SystemExit(f"{manifest_path}: runtimeId must be konyak-linux-wine")
if payload.get("stackId") != "linux-wine-runtime-stack":
    raise SystemExit(f"{manifest_path}: stackId must be linux-wine-runtime-stack")

components = payload.get("components")
if not isinstance(components, list):
    raise SystemExit(f"{manifest_path}: components must be an array")

required_ids = {"wine", "winetricks", "wine-mono", "dxvk", "vkd3d-proton"}
seen_ids: set[str] = set()
for index, component in enumerate(components):
    if not isinstance(component, dict):
        raise SystemExit(f"{manifest_path}: component {index} must be an object")
    component_id = component.get("id")
    if not isinstance(component_id, str) or not component_id:
        raise SystemExit(f"{manifest_path}: component {index} has invalid id")
    seen_ids.add(component_id)
    for key in ("version", "archiveUrl", "sha256"):
        value = component.get(key)
        if not isinstance(value, str) or not value.strip():
            raise SystemExit(f"{manifest_path}: component {component_id} missing {key}")

missing = sorted(required_ids - seen_ids)
if missing:
    raise SystemExit(f"{manifest_path}: missing required Linux runtime components: {', '.join(missing)}")
PY
}

cache_url() {
  local source_url="$1"
  local target="$2"
  local temp_target="${target}.tmp.$$"

  mkdir -p "${target:h}"
  rm -f "${temp_target}"
  curl --fail --location --output "${temp_target}" "${source_url}"
  mv -f "${temp_target}" "${target}"
}

cache_manifest_url() {
  local source_url="$1"
  local target="$2"
  local source_marker="${target}.source-url"
  local temp_target="${target}.tmp.$$"

  mkdir -p "${target:h}"
  rm -f "${temp_target}"
  curl --fail --location --output "${temp_target}" "${source_url}"
  validate_manifest "${temp_target}"
  mv -f "${temp_target}" "${target}"
  print -r -- "${source_url}" >"${source_marker}"
}

cache_manifest_file() {
  local source_path="$1"
  local target="$2"
  local temp_target="${target}.tmp.$$"

  validate_manifest "${source_path}"
  if [[ "${source_path:A}" == "${target:A}" ]]; then
    rm -f "${target}.source-url"
    return 0
  fi

  mkdir -p "${target:h}"
  cp -f "${source_path}" "${temp_target}"
  mv -f "${temp_target}" "${target}"
  rm -f "${target}.source-url"
}

copy_optional_file() {
  local source_path="$1"
  local target="$2"

  if [[ -z "${source_path}" || -z "${target}" ]]; then
    return 0
  fi

  if is_url "${source_path}"; then
    cache_url "${source_path}" "${target}"
    return 0
  fi

  local resolved_source
  if ! resolved_source="$(resolve_local_path "${source_path}")"; then
    return 0
  fi

  mkdir -p "${target:h}"
  cp -f "${resolved_source}" "${target}"
}

manifest_source=""
signature_source=""
public_key_source=""

if [[ "${profile}" == "development" ]]; then
  manifest_source="${KONYAK_DEV_LINUX_WINE_STACK_SOURCE_MANIFEST:-${KONYAK_DEV_LINUX_RUNTIME_STACK_SOURCE_MANIFEST:-}}"
  legacy_manifest_source="${KONYAK_DEV_LINUX_WINE_STACK_MANIFEST:-}"
  if [[ -z "${manifest_source}" && -n "${legacy_manifest_source}" ]]; then
    if is_url "${legacy_manifest_source}" || [[ -f "${legacy_manifest_source}" ]]; then
      manifest_source="${legacy_manifest_source}"
    fi
  fi
  signature_source="${KONYAK_DEV_LINUX_WINE_STACK_SIGNATURE_URL:-}"
else
  manifest_source="${KONYAK_RUNTIME_STACK_SOURCE_MANIFEST:-}"
  signature_source="${KONYAK_RUNTIME_STACK_SOURCE_SIGNATURE:-${KONYAK_LINUX_WINE_STACK_SIGNATURE_URL:-}}"
fi

if [[ -z "${manifest_source}" ]]; then
  repository="${KONYAK_LINUX_RUNTIME_RELEASE_REPO:-$(json_value repository)}"
  default_tag="$(json_value defaultReleaseTag)"
  if [[ "${profile}" == "development" ]]; then
    release_tag="${KONYAK_DEV_LINUX_RUNTIME_RELEASE_TAG:-${default_tag}}"
  else
    release_tag="${KONYAK_LINUX_RUNTIME_RELEASE_TAG:-${default_tag}}"
  fi
  manifest_file_name="$(json_value sourceManifestFileName)"
  signature_file_name="$(json_value sourceManifestSignatureFileName)"
  public_key_file_name="$(json_value publicKeyFileName)"
  manifest_source="$(release_asset_url "${repository}" "${release_tag}" "${manifest_file_name}")"
  if [[ -n "${signature_file_name}" ]]; then
    signature_source="$(release_asset_url "${repository}" "${release_tag}" "${signature_file_name}")"
  fi
  if [[ -n "${public_key_file_name}" ]]; then
    public_key_source="$(release_asset_url "${repository}" "${release_tag}" "${public_key_file_name}")"
  fi
fi

manifest_path="${manifest_source}"
if [[ -n "${manifest_cache}" ]]; then
  if is_url "${manifest_source}"; then
    cache_manifest_url "${manifest_source}" "${manifest_cache}"
  else
    resolved_manifest_source="$(resolve_local_path "${manifest_source}")" || {
      print -u2 "Linux runtime source manifest does not exist: ${manifest_source}"
      exit 66
    }
    cache_manifest_file "${resolved_manifest_source}" "${manifest_cache}"
  fi
  manifest_path="${manifest_cache}"
elif ! is_url "${manifest_source}"; then
  manifest_path="$(resolve_local_path "${manifest_source}")" || {
    print -u2 "Linux runtime source manifest does not exist: ${manifest_source}"
    exit 66
  }
  validate_manifest "${manifest_path}"
fi

signature_path="${signature_source}"
if [[ -n "${signature_source}" && -n "${signature_cache}" ]]; then
  copy_optional_file "${signature_source}" "${signature_cache}"
  if [[ -f "${signature_cache}" ]]; then
    signature_path="${signature_cache}"
  fi
fi

public_key_path="${public_key_source}"
if [[ -z "${public_key_path}" && -n "${KONYAK_RUNTIME_STACK_PUBLIC_KEY_PATH:-}" ]]; then
  public_key_path="${KONYAK_RUNTIME_STACK_PUBLIC_KEY_PATH}"
fi
if [[ -n "${public_key_source}" && -n "${public_key_cache}" ]]; then
  copy_optional_file "${public_key_source}" "${public_key_cache}"
  if [[ -f "${public_key_cache}" ]]; then
    public_key_path="${public_key_cache}"
  fi
fi

if [[ "${print_manifest_path}" == true ]]; then
  print -r -- "${manifest_path}"
fi

if [[ "${print_signature_path}" == true && -n "${signature_path}" ]]; then
  print -r -- "${signature_path}"
fi

if [[ "${print_public_key_path}" == true && -n "${public_key_path}" ]]; then
  print -r -- "${public_key_path}"
fi
