#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
SOURCE_ROOT="${KONYAK_DEV_LINUX_RUNTIME_SOURCE_ROOT:-${ROOT}/.dart_tool/konyak/dev-runtime-source/linux-wine-stack}"
MANIFEST_CACHE="${KONYAK_DEV_LINUX_WINE_STACK_MANIFEST_CACHE:-${SOURCE_ROOT}/konyak-linux-wine-runtime-stack-source.json}"
RUNTIME_PATH="${KONYAK_LINUX_WINE_HOME:-${ROOT}/.dart_tool/konyak/dev-runtime/linux-wine}"

print_manifest_path=false
print_runtime_path=false
force=false

for arg in "$@"; do
  case "${arg}" in
    --print-manifest-path)
      print_manifest_path=true
      ;;
    --print-runtime-path)
      print_runtime_path=true
      ;;
    --force)
      force=true
      ;;
    *)
      print -u2 "unknown argument: ${arg}"
      exit 64
      ;;
  esac
done

require_command() {
  local command_name="$1"

  if ! command -v "${command_name}" >/dev/null 2>&1; then
    print -u2 "${command_name} not found. Run this script inside nix develop."
    exit 69
  fi
}

require_command python3
require_command curl

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

cache_url_manifest() {
  local source_url="$1"
  local target="$2"
  local source_marker="${target}.source-url"
  local temp_target="${target}.tmp.$$"

  mkdir -p "${target:h}"
  if [[ "${force}" == false && -f "${target}" && -f "${source_marker}" ]] &&
    [[ "$(cat "${source_marker}")" == "${source_url}" ]]; then
    validate_manifest "${target}"
    return 0
  fi

  rm -f "${temp_target}"
  curl --fail --location --output "${temp_target}" "${source_url}"
  validate_manifest "${temp_target}"
  mv -f "${temp_target}" "${target}"
  print -r -- "${source_url}" >"${source_marker}"
}

cache_local_manifest() {
  local source_path="$1"
  local target="$2"
  local temp_target="${target}.tmp.$$"

  if [[ ! -f "${source_path}" ]]; then
    print -u2 "Linux runtime source manifest does not exist: ${source_path}"
    exit 66
  fi

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

manifest_source="${KONYAK_DEV_LINUX_WINE_STACK_SOURCE_MANIFEST:-${KONYAK_DEV_LINUX_RUNTIME_STACK_SOURCE_MANIFEST:-}}"
legacy_manifest_source="${KONYAK_DEV_LINUX_WINE_STACK_MANIFEST:-}"
if [[ -z "${manifest_source}" && -n "${legacy_manifest_source}" ]]; then
  if is_url "${legacy_manifest_source}" || [[ -f "${legacy_manifest_source}" ]]; then
    manifest_source="${legacy_manifest_source}"
  fi
fi

if [[ -z "${manifest_source}" ]]; then
  print -u2 "Linux development runtime components are not generated in the parent repository."
  print -u2 "Set KONYAK_DEV_LINUX_WINE_STACK_SOURCE_MANIFEST to a complete Linux runtime source manifest produced by the runtime packaging owner."
  exit 66
fi

if is_url "${manifest_source}"; then
  cache_url_manifest "${manifest_source}" "${MANIFEST_CACHE}"
else
  cache_local_manifest "${manifest_source}" "${MANIFEST_CACHE}"
fi

if [[ "${print_manifest_path}" == true ]]; then
  print -r -- "${MANIFEST_CACHE}"
fi

if [[ "${print_runtime_path}" == true ]]; then
  print -r -- "${RUNTIME_PATH}"
fi
