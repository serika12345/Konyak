#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
SOURCE_ROOT="${KONYAK_DEV_MACOS_RUNTIME_SOURCE_ROOT:-${ROOT}/.dart_tool/konyak/dev-runtime-source/macos-wine-stack}"
MANIFEST_PATH="${KONYAK_DEV_MACOS_WINE_STACK_MANIFEST_CACHE:-${SOURCE_ROOT}/konyak-macos-wine-runtime-stack-source.json}"
RELEASE_METADATA_PATH="${ROOT}/runtime/macos-wine-release.json"
RUNTIME_SOURCE_MODE="${KONYAK_DEV_MACOS_RUNTIME_SOURCE_MODE:-release}"

print_manifest_path=false
print_runtime_path=false
ensure_runtime=false
force=false

for arg in "$@"; do
  case "${arg}" in
    --print-manifest-path)
      print_manifest_path=true
      ;;
    --print-runtime-path)
      print_runtime_path=true
      ;;
    --ensure-runtime)
      ensure_runtime=true
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

validate_manifest() {
  local manifest_path="$1"
  jq -e '
    .schemaVersion == 1 and
    .runtimeId == "konyak-macos-wine" and
    .stackId == "macos-konyak-runtime-stack" and
    (.components | type) == "array" and
    ([.components[] | select(type == "object") | .id] | contains([
      "wine",
      "dxvk-macos",
      "moltenvk",
      "gstreamer",
      "freetype",
      "wine-mono",
      "wine-gecko",
      "winetricks",
      "vkd3d",
      "dxmt"
    ])) and
    all(.components[]; (
      type == "object" and
      (.id | type == "string" and length > 0) and
      (.version | type == "string" and length > 0) and
      (.archiveUrl | type == "string" and length > 0) and
      (.sha256 | type == "string" and length > 0)
    ))
  ' "${manifest_path}" >/dev/null || {
    print -u2 "macOS runtime source manifest is invalid: ${manifest_path}"
    exit 65
  }
}

cache_url_manifest() {
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

runtime_path="${KONYAK_MACOS_WINE_HOME:-${ROOT}/.dart_tool/konyak/dev-runtime/macos-wine}"
manifest_source="${KONYAK_DEV_MACOS_WINE_STACK_MANIFEST:-}"
manifest_path="${MANIFEST_PATH}"

if [[ -z "${manifest_source}" ]]; then
  repository="$(json_value repository)"
  default_tag="$(json_value defaultReleaseTag)"
  manifest_file_name="$(json_value sourceManifestFileName)"
  release_tag="${KONYAK_DEV_MACOS_RUNTIME_RELEASE_TAG:-${default_tag}}"
  if [[ "${release_tag}" == "latest" ]]; then
    manifest_source="https://github.com/${repository}/releases/latest/download/${manifest_file_name}"
  else
    manifest_source="https://github.com/${repository}/releases/download/${release_tag}/${manifest_file_name}"
  fi
fi

if is_url "${manifest_source}"; then
  cache_url_manifest "${manifest_source}" "${manifest_path}"
else
  if [[ ! -f "${manifest_source}" ]]; then
    print -u2 "macOS runtime source manifest does not exist: ${manifest_source}"
    exit 66
  fi
  validate_manifest "${manifest_source}"
  manifest_path="${manifest_source}"
fi

runtime_matches_manifest() {
  local runtime_metadata="${runtime_path}/.konyak-runtime-stack.json"

  [[ -x "${runtime_path}/bin/wineloader" ]] || return 1
  [[ -f "${runtime_metadata}" ]] || return 1
  jq -e --slurpfile source "${manifest_path}" '
    .schemaVersion == 1 and
    (.components | type) == "object" and
    (
      .components as $installed |
      ($source[0].components | map({key: .id, value: .version}) | from_entries) as $expected |
      all($expected | to_entries[]; $installed[.key] == .value)
    )
  ' "${runtime_metadata}" >/dev/null
}

ensure_development_runtime() {
  local dart_executable="${KONYAK_DART_EXECUTABLE:-dart}"
  local cli_script="${KONYAK_CLI_SCRIPT:-${ROOT}/packages/konyak_cli/bin/konyak.dart}"
  local absolute_manifest_path="${manifest_path:A}"

  if runtime_matches_manifest; then
    print -u2 "Konyak macOS development runtime is current."
    return
  fi

  if [[ "${dart_executable}" == */* && ! -x "${dart_executable}" ]]; then
    print -u2 "Dart executable does not exist or is not executable: ${dart_executable}"
    exit 69
  fi
  if [[ ! -f "${cli_script}" ]]; then
    print -u2 "Konyak CLI script does not exist: ${cli_script}"
    exit 66
  fi

  print -u2 "Updating Konyak macOS development runtime from the selected release..."
  (
    cd "${ROOT}/packages/konyak_cli"
    env \
      KONYAK_RUNTIME_PROFILE=development \
      KONYAK_MACOS_WINE_HOME="${runtime_path}" \
      KONYAK_DEV_MACOS_WINE_STACK_MANIFEST="${absolute_manifest_path}" \
      "${dart_executable}" "${cli_script}" \
        install-macos-wine \
        --reinstall \
        --source-manifest "${absolute_manifest_path}" \
        --progress-json \
        --json
  ) >&2

  if ! runtime_matches_manifest; then
    print -u2 "Konyak CLI completed without installing the selected runtime component versions."
    exit 1
  fi
}

if [[ "${ensure_runtime}" == true ]]; then
  ensure_development_runtime
fi

if [[ "${print_manifest_path}" == true ]]; then
  print -r -- "${manifest_path}"
fi

if [[ "${print_runtime_path}" == true ]]; then
  print -r -- "${runtime_path}"
fi
