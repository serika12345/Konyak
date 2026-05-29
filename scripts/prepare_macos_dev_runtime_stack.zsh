#!/usr/bin/env zsh
original_path="${PATH:-}"
emulate -L zsh
export PATH="${original_path}"
path=("${(@s.:.)original_path}")
set -euo pipefail

resolve_command_path() {
  local command_name="$1"
  local path_entry

  for path_entry in ${(s.:.)PATH}; do
    if [[ -x "${path_entry}/${command_name}" ]]; then
      print -r -- "${path_entry}/${command_name}"
      return 0
    fi
  done

  return 1
}

readonly PYTHON3_BIN="$(resolve_command_path python3 || true)"
if [[ -z "${PYTHON3_BIN}" ]]; then
  print -u2 "python3 not found. Run this script inside nix develop."
  exit 69
fi

readonly ROOT="${0:A:h:h}"
readonly RUNTIME_ROOT="${KONYAK_MACOS_WINE_HOME:-${ROOT}/.dart_tool/konyak/dev-runtime/macos-wine}"
readonly SOURCE_ROOT="${ROOT}/.dart_tool/konyak/dev-runtime-source/macos-wine-stack"
readonly DOWNLOAD_CACHE="${ROOT}/.dart_tool/konyak/download-cache"
readonly MANIFEST_PATH="${SOURCE_ROOT}/konyak-macos-wine-runtime-stack-source.json"
readonly WINE_ARCHIVE_URL="${KONYAK_DEV_MACOS_WINE_ARCHIVE_URL:-https://github.com/Gcenx/macOS_Wine_builds/releases/download/11.9/wine-devel-11.9-osx64.tar.xz}"
readonly WINE_ARCHIVE_SHA256="${KONYAK_DEV_MACOS_WINE_ARCHIVE_SHA256:-e0ac24b3c525d7dd2c88e6447e94fa106fd05a581a178773f47c7a254d4f6296}"
readonly WINE_ARCHIVE_CACHE="${KONYAK_DEV_MACOS_WINE_ARCHIVE_CACHE:-${DOWNLOAD_CACHE}/wine-devel-11.9-osx64.tar.xz}"
readonly DXVK_ARCHIVE_URL="${KONYAK_DEV_DXVK_MACOS_ARCHIVE_URL:-https://github.com/Gcenx/DXVK-macOS/releases/download/v1.10.3-20230507/dxvk-macOS-async-v1.10.3-20230507.tar.gz}"
readonly DXVK_ARCHIVE_SHA256="${KONYAK_DEV_DXVK_MACOS_ARCHIVE_SHA256:-f67d99d0a8eeedd7d406b283a3df9f939b5965acb00efcb33d0c6235c195a516}"
readonly DXVK_ARCHIVE_CACHE="${KONYAK_DEV_DXVK_MACOS_ARCHIVE_CACHE:-${DOWNLOAD_CACHE}/dxvk-macOS-async-v1.10.3-20230507.tar.gz}"
readonly GSTREAMER_ROOT="${KONYAK_DEV_NIX_GSTREAMER_PATH:-}"

print_manifest_path=false
print_runtime_path=false
force=false
download_wine=false

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
    --download-wine)
      download_wine=true
      ;;
    *)
      print -u2 "unknown argument: ${arg}"
      exit 64
      ;;
  esac
done

sha256_file() {
  "${PYTHON3_BIN}" - "$1" <<'PY'
import hashlib
import sys

digest = hashlib.sha256()
with open(sys.argv[1], "rb") as handle:
    for chunk in iter(lambda: handle.read(1024 * 1024), b""):
        digest.update(chunk)
print(digest.hexdigest())
PY
}

verify_sha256() {
  local file_path="$1"
  local expected="$2"
  local actual

  actual="$(sha256_file "${file_path}")"
  if [[ "${actual:l}" != "${expected:l}" ]]; then
    print -u2 "checksum mismatch for ${file_path}: expected ${expected}, got ${actual}"
    exit 65
  fi
}

download_if_missing() {
  local url="$1"
  local target="$2"
  local expected_sha256="$3"

  if [[ "${force}" == true || ! -f "${target}" ]]; then
    mkdir -p "${target:h}"
    curl --fail --location --output "${target}" "${url}"
  fi

  verify_sha256 "${target}" "${expected_sha256}"
}

reset_dir() {
  local target_path="$1"
  rm -rf "${target_path}"
  mkdir -p "${target_path}"
}

archive_payload() {
  local payload_root="$1"
  local archive_path="$2"

  rm -f "${archive_path}"
  mkdir -p "${archive_path:h}"
  tar -cJf "${archive_path}" -C "${payload_root:h}" "${payload_root:t}"
}

write_stack_manifest() {
  local target="$1"
  local component_id="$2"
  local version="$3"

  "${PYTHON3_BIN}" - "$target" "$component_id" "$version" <<'PY'
import json
import sys

target, component_id, version = sys.argv[1:4]
with open(target, "w", encoding="utf-8") as handle:
    json.dump(
        {"schemaVersion": 1, "components": {component_id: version}},
        handle,
        separators=(",", ":"),
    )
    handle.write("\n")
PY
}

prepare_dxvk_component() {
  local work_root="${SOURCE_ROOT}/work/dxvk"
  local extract_root="${work_root}/extract"
  local payload_root="${work_root}/payload/dxvk-macos"
  local archive_path="${SOURCE_ROOT}/components/dxvk-macos.tar.xz"
  local source_x64
  local source_x32

  download_if_missing "${DXVK_ARCHIVE_URL}" "${DXVK_ARCHIVE_CACHE}" "${DXVK_ARCHIVE_SHA256}"
  reset_dir "${work_root}"
  mkdir -p "${extract_root}"
  tar --warning=no-unknown-keyword -xzf "${DXVK_ARCHIVE_CACHE}" -C "${extract_root}"

  source_x64="$(find "${extract_root}" -path '*/x64/dxgi.dll' -type f | head -n 1)"
  source_x32="$(find "${extract_root}" -path '*/x32/dxgi.dll' -type f | head -n 1)"
  if [[ -z "${source_x64}" || -z "${source_x32}" ]]; then
    print -u2 "DXVK-macOS archive does not contain x64/x32 dxgi.dll."
    exit 65
  fi

  mkdir -p \
    "${payload_root}/Components/DXVK-macOS/DXVK/x64" \
    "${payload_root}/Components/DXVK-macOS/DXVK/x32"
  cp -f "${source_x64}" "${payload_root}/Components/DXVK-macOS/DXVK/x64/dxgi.dll"
  cp -f "${source_x32}" "${payload_root}/Components/DXVK-macOS/DXVK/x32/dxgi.dll"
  write_stack_manifest \
    "${payload_root}/.konyak-runtime-stack.json" \
    "dxvk-macos" \
    "v1.10.3-20230507"
  archive_payload "${payload_root}" "${archive_path}"
  print -r -- "${archive_path}"
}

prepare_gstreamer_component() {
  local work_root="${SOURCE_ROOT}/work/gstreamer"
  local payload_root="${work_root}/payload/gstreamer"
  local archive_path="${SOURCE_ROOT}/components/gstreamer.tar.xz"
  local source_dylib

  if [[ -z "${GSTREAMER_ROOT}" ]]; then
    print -u2 "KONYAK_DEV_NIX_GSTREAMER_PATH is required. Run inside nix develop."
    exit 69
  fi

  source_dylib="${GSTREAMER_ROOT}/lib/libgstreamer-1.0.0.dylib"
  if [[ ! -f "${source_dylib}" ]]; then
    print -u2 "GStreamer dylib not found: ${source_dylib}"
    exit 69
  fi

  reset_dir "${work_root}"
  mkdir -p "${payload_root}/Components/GStreamer/lib"
  cp -Lf "${source_dylib}" \
    "${payload_root}/Components/GStreamer/lib/libgstreamer-1.0.0.dylib"
  write_stack_manifest \
    "${payload_root}/.konyak-runtime-stack.json" \
    "gstreamer" \
    "${GSTREAMER_ROOT:t}"
  archive_payload "${payload_root}" "${archive_path}"
  print -r -- "${archive_path}"
}

prepare_winetricks_component() {
  local work_root="${SOURCE_ROOT}/work/winetricks"
  local payload_root="${work_root}/payload/winetricks"
  local archive_path="${SOURCE_ROOT}/components/winetricks.tar.xz"
  local executable="${payload_root}/Components/winetricks/winetricks"
  local verbs="${payload_root}/Components/winetricks/verbs.txt"

  reset_dir "${work_root}"
  mkdir -p "${payload_root}/Components/winetricks"
  cat >"${executable}" <<'EOF'
#!/bin/sh
set -eu

if [ "${1:-}" = "list-all" ]; then
  cat <<'VERBS'
===== apps =====
steam                    Steam Client

===== dlls =====
corefonts                Microsoft Core Fonts
d3dx9                    DirectX 9 libraries
VERBS
  exit 0
fi

printf 'Konyak development winetricks stub: %s\n' "$*" >&2
exit 0
EOF
  chmod +x "${executable}"

  cat >"${verbs}" <<'EOF'
===== apps =====
steam                    Steam Client

===== dlls =====
corefonts                Microsoft Core Fonts
d3dx9                    DirectX 9 libraries
EOF

  write_stack_manifest \
    "${payload_root}/.konyak-runtime-stack.json" \
    "winetricks" \
    "konyak-dev-stub"
  archive_payload "${payload_root}" "${archive_path}"
  print -r -- "${archive_path}"
}

write_source_manifest() {
  local wine_archive_source="$1"
  local dxvk_archive="$2"
  local gstreamer_archive="$3"
  local winetricks_archive="$4"
  local dxvk_sha
  local gstreamer_sha
  local winetricks_sha

  dxvk_sha="$(sha256_file "${dxvk_archive}")"
  gstreamer_sha="$(sha256_file "${gstreamer_archive}")"
  winetricks_sha="$(sha256_file "${winetricks_archive}")"

  mkdir -p "${MANIFEST_PATH:h}"
  "${PYTHON3_BIN}" - \
    "${MANIFEST_PATH}" \
    "${wine_archive_source}" \
    "${WINE_ARCHIVE_SHA256}" \
    "${dxvk_archive}" \
    "${dxvk_sha}" \
    "${gstreamer_archive}" \
    "${gstreamer_sha}" \
    "${winetricks_archive}" \
    "${winetricks_sha}" <<'PY'
import json
import sys

(
    manifest_path,
    wine_archive,
    wine_sha,
    dxvk_archive,
    dxvk_sha,
    gstreamer_archive,
    gstreamer_sha,
    winetricks_archive,
    winetricks_sha,
) = sys.argv[1:10]

payload = {
    "schemaVersion": 1,
    "runtimeId": "konyak-macos-wine",
    "stackId": "macos-konyak-runtime-stack",
    "components": [
        {
            "id": "wine",
            "version": "wine-devel-11.9",
            "archiveUrl": wine_archive,
            "sha256": wine_sha,
        },
        {
            "id": "dxvk-macos",
            "version": "v1.10.3-20230507",
            "archiveUrl": dxvk_archive,
            "sha256": dxvk_sha,
        },
        {
            "id": "gstreamer",
            "version": "nix-gstreamer",
            "archiveUrl": gstreamer_archive,
            "sha256": gstreamer_sha,
        },
        {
            "id": "winetricks",
            "version": "konyak-dev-stub",
            "archiveUrl": winetricks_archive,
            "sha256": winetricks_sha,
        },
    ],
}

with open(manifest_path, "w", encoding="utf-8") as handle:
    json.dump(payload, handle, indent=2)
    handle.write("\n")
PY
}

mkdir -p "${SOURCE_ROOT}" "${DOWNLOAD_CACHE}" "${RUNTIME_ROOT:h}"

if [[ "${download_wine}" == true ]]; then
  download_if_missing "${WINE_ARCHIVE_URL}" "${WINE_ARCHIVE_CACHE}" "${WINE_ARCHIVE_SHA256}"
fi

wine_archive_source="${WINE_ARCHIVE_URL}"
if [[ -f "${WINE_ARCHIVE_CACHE}" ]]; then
  verify_sha256 "${WINE_ARCHIVE_CACHE}" "${WINE_ARCHIVE_SHA256}"
  wine_archive_source="${WINE_ARCHIVE_CACHE}"
fi

dxvk_archive="$(prepare_dxvk_component)"
gstreamer_archive="$(prepare_gstreamer_component)"
winetricks_archive="$(prepare_winetricks_component)"
write_source_manifest \
  "${wine_archive_source}" \
  "${dxvk_archive}" \
  "${gstreamer_archive}" \
  "${winetricks_archive}"

if [[ "${print_manifest_path}" == true ]]; then
  print -r -- "${MANIFEST_PATH}"
fi

if [[ "${print_runtime_path}" == true ]]; then
  print -r -- "${RUNTIME_ROOT}"
fi
