#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
SOURCE_ROOT="${KONYAK_DEV_LINUX_RUNTIME_SOURCE_ROOT:-${ROOT}/.dart_tool/konyak/dev-runtime-source/linux-wine-stack}"
MANIFEST_CACHE="${KONYAK_DEV_LINUX_WINE_STACK_MANIFEST_CACHE:-${SOURCE_ROOT}/konyak-linux-wine-runtime-stack-source.json}"
RUNTIME_PATH="${KONYAK_LINUX_WINE_HOME:-${ROOT}/.dart_tool/konyak/dev-runtime/linux-wine}"
RESOLVER="${ROOT}/scripts/resolve_linux_runtime_source_manifest.zsh"

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

if [[ ! -x "${RESOLVER}" ]]; then
  print -u2 "Linux runtime source manifest resolver is not executable: ${RESOLVER}"
  exit 69
fi

# Linux development runtime components are not generated in the parent repository.
# The resolver accepts only complete source manifests containing Wine,
# winetricks, wine-mono, DXVK, and vkd3d-proton component archives. Set
# KONYAK_DEV_LINUX_WINE_STACK_SOURCE_MANIFEST to override the default release
# locator for local development.
manifest_path="$("${RESOLVER}" \
  --profile development \
  --manifest-cache "${MANIFEST_CACHE}" \
  --print-manifest-path)"

if [[ "${print_manifest_path}" == true ]]; then
  print -r -- "${manifest_path}"
fi

if [[ "${print_runtime_path}" == true ]]; then
  print -r -- "${RUNTIME_PATH}"
fi
