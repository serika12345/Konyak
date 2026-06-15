#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
SOURCE_ROOT="${KONYAK_DEV_MACOS_RUNTIME_SOURCE_ROOT:-${ROOT}/.dart_tool/konyak/dev-runtime-source/macos-wine-stack}"
MANIFEST_PATH="${KONYAK_DEV_MACOS_WINE_STACK_MANIFEST_CACHE:-${SOURCE_ROOT}/konyak-macos-wine-runtime-stack-source.json}"
RELEASE_METADATA_PATH="${ROOT}/runtime/macos-wine-release.json"
RUNTIME_SOURCE_MODE="${KONYAK_DEV_MACOS_RUNTIME_SOURCE_MODE:-release}"

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

if [[ "${RUNTIME_SOURCE_MODE}" != "release" ]]; then
  print -u2 "KONYAK_DEV_MACOS_RUNTIME_SOURCE_MODE=${RUNTIME_SOURCE_MODE} is no longer supported."
  print -u2 "macOS runtime inputs must be complete source manifests produced by runtime/konyak-macos-runtime."
  exit 64
fi

json_value() {
  local key="$1"
  python3 - "${RELEASE_METADATA_PATH}" "${key}" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    payload = json.load(handle)
value = payload.get(sys.argv[2], "")
if not isinstance(value, str) or not value.strip():
    raise SystemExit(f"missing {sys.argv[2]} in {sys.argv[1]}")
print(value)
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

cache_url_manifest() {
  local source_url="$1"
  local target="$2"
  local source_marker="${target}.source-url"
  local temp_target="${target}.tmp.$$"

  mkdir -p "${target:h}"
  if [[ "${force}" == false && -f "${target}" && -f "${source_marker}" ]] &&
    [[ "$(cat "${source_marker}")" == "${source_url}" ]]; then
    return 0
  fi

  rm -f "${temp_target}"
  curl --fail --location --output "${temp_target}" "${source_url}"
  mv -f "${temp_target}" "${target}"
  print -r -- "${source_url}" >"${source_marker}"
}

runtime_path="${KONYAK_MACOS_WINE_HOME:-${ROOT}/.dart_tool/konyak/dev-runtime/macos-wine}"
manifest_source="${KONYAK_DEV_MACOS_WINE_STACK_MANIFEST:-}"
manifest_path="${MANIFEST_PATH}"

if [[ -z "${manifest_source}" ]]; then
  repository="$(json_value repository)"
  default_tag="$(json_value defaultReleaseTag)"
  manifest_file_name="$(json_value sourceManifestFileName)"
  release_tag="${KONYAK_DEV_MACOS_RUNTIME_RELEASE_TAG:-${default_tag}}"
  manifest_source="https://github.com/${repository}/releases/download/${release_tag}/${manifest_file_name}"
fi

if is_url "${manifest_source}"; then
  cache_url_manifest "${manifest_source}" "${manifest_path}"
else
  if [[ ! -f "${manifest_source}" ]]; then
    print -u2 "macOS runtime source manifest does not exist: ${manifest_source}"
    exit 66
  fi
  manifest_path="${manifest_source}"
fi

if [[ "${print_manifest_path}" == true ]]; then
  print -r -- "${manifest_path}"
fi

if [[ "${print_runtime_path}" == true ]]; then
  print -r -- "${runtime_path}"
fi
