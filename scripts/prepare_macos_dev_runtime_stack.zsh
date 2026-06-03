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
readonly DXMT_ARCHIVE_URL="${KONYAK_DEV_DXMT_ARCHIVE_URL:-https://github.com/serika12345/konyak-macos-runtime/releases/download/crossover-26.1.0-konyak.0/konyak-macos-dxmt.tar.zst}"
readonly DXMT_ARCHIVE_SHA256="${KONYAK_DEV_DXMT_ARCHIVE_SHA256:-2f3851e4fddc66074ba512146ddb6240646989000e8ba2a555ca6706eac8e611}"
readonly DXMT_ARCHIVE_CACHE="${KONYAK_DEV_DXMT_ARCHIVE_CACHE:-${DOWNLOAD_CACHE}/konyak-macos-dxmt.tar.zst}"
readonly DXMT_VERSION="${KONYAK_DEV_DXMT_VERSION:-aa9df0b86b041dc836a08f3a499f2a203cdbd4d7-konyak.0}"
readonly GSTREAMER_ROOT="${KONYAK_DEV_NIX_GSTREAMER_PATH:-}"
readonly WINETRICKS_SOURCE="${KONYAK_DEV_WINETRICKS_PATH:-}"
readonly WINETRICKS_SCRIPT_URL="${KONYAK_DEV_WINETRICKS_SCRIPT_URL:-https://raw.githubusercontent.com/Winetricks/winetricks/20260125/src/winetricks}"
readonly WINETRICKS_SCRIPT_SHA256="${KONYAK_DEV_WINETRICKS_SCRIPT_SHA256:-431f82fc74000e6c864409f1d8fb495d696c03928808e3e8acffc45179312a7b}"
readonly WINETRICKS_SCRIPT_CACHE="${KONYAK_DEV_WINETRICKS_SCRIPT_CACHE:-${DOWNLOAD_CACHE}/winetricks-20260125}"
readonly WINETRICKS_VERSION="${KONYAK_DEV_WINETRICKS_VERSION:-20260125}"
if [[ -n "${KONYAK_DEV_GPTK_D3DMETAL_PATH:-}" ]]; then
  GPTK_D3DMETAL_ROOT="${KONYAK_DEV_GPTK_D3DMETAL_PATH}"
else
  GPTK_D3DMETAL_ROOT=""
fi
readonly GPTK_D3DMETAL_ROOT
readonly GPTK_D3DMETAL_VERSION="${KONYAK_DEV_GPTK_D3DMETAL_VERSION:-local-gptk-d3dmetal}"

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

  mkdir -p \
    "${payload_root}/Components/DXVK-macOS/DXVK/x64" \
    "${payload_root}/Components/DXVK-macOS/DXVK/x32"
  for dll_name in dxgi.dll d3d9.dll d3d10core.dll d3d11.dll; do
    source_x64="$(find "${extract_root}" -path "*/x64/${dll_name}" -type f | head -n 1)"
    source_x32="$(find "${extract_root}" -path "*/x32/${dll_name}" -type f | head -n 1)"
    if [[ -z "${source_x64}" || -z "${source_x32}" ]]; then
      print -u2 "DXVK-macOS archive does not contain x64/x32 ${dll_name}."
      exit 65
    fi

    cp -f "${source_x64}" "${payload_root}/Components/DXVK-macOS/DXVK/x64/${dll_name}"
    cp -f "${source_x32}" "${payload_root}/Components/DXVK-macOS/DXVK/x32/${dll_name}"
  done
  write_stack_manifest \
    "${payload_root}/.konyak-runtime-stack.json" \
    "dxvk-macos" \
    "v1.10.3-20230507"
  archive_payload "${payload_root}" "${archive_path}"
  print -r -- "${archive_path}"
}

prepare_dxmt_component() {
  local work_root="${SOURCE_ROOT}/work/dxmt"
  local extract_root="${work_root}/extract"
  local payload_root="${work_root}/payload/dxmt"
  local archive_path="${SOURCE_ROOT}/components/dxmt.tar.xz"

  download_if_missing "${DXMT_ARCHIVE_URL}" "${DXMT_ARCHIVE_CACHE}" "${DXMT_ARCHIVE_SHA256}"
  reset_dir "${work_root}"
  mkdir -p "${extract_root}"
  tar --warning=no-unknown-keyword --zstd -xf "${DXMT_ARCHIVE_CACHE}" -C "${extract_root}"

  if [[ ! -f "${extract_root}/components/dxmt/x86_64-windows/d3d11.dll" ||
        ! -f "${extract_root}/components/dxmt/x86_64-unix/winemetal.so" ]]; then
    print -u2 "DXMT archive does not contain the expected component layout."
    exit 65
  fi

  mkdir -p "${payload_root}/Components/DXMT/components"
  cp -R "${extract_root}/components/dxmt" \
    "${payload_root}/Components/DXMT/components/dxmt"
  write_stack_manifest \
    "${payload_root}/.konyak-runtime-stack.json" \
    "dxmt" \
    "${DXMT_VERSION}"
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

resolve_winetricks_executable() {
  local source_path="$1"

  if [[ -x "${source_path}" && ! -d "${source_path}" ]]; then
    print -r -- "${source_path}"
    return 0
  fi

  if [[ -x "${source_path}/bin/winetricks" ]]; then
    print -r -- "${source_path}/bin/winetricks"
    return 0
  fi

  return 1
}

prepare_winetricks_component() {
  local work_root="${SOURCE_ROOT}/work/winetricks"
  local payload_root="${work_root}/payload/winetricks"
  local archive_path="${SOURCE_ROOT}/components/winetricks.tar.xz"
  local executable="${payload_root}/Components/winetricks/winetricks"
  local verbs="${payload_root}/Components/winetricks/verbs.txt"
  local source_executable

  if [[ -n "${WINETRICKS_SOURCE}" ]]; then
    source_executable="$(resolve_winetricks_executable "${WINETRICKS_SOURCE}" || true)"
    if [[ -z "${source_executable}" ]]; then
      print -u2 "winetricks executable not found: ${WINETRICKS_SOURCE}"
      exit 69
    fi
  else
    download_if_missing \
      "${WINETRICKS_SCRIPT_URL}" \
      "${WINETRICKS_SCRIPT_CACHE}" \
      "${WINETRICKS_SCRIPT_SHA256}"
    source_executable="${WINETRICKS_SCRIPT_CACHE}"
  fi

  reset_dir "${work_root}"
  mkdir -p "${payload_root}/Components/winetricks"
  cp -Lf "${source_executable}" "${executable}"
  chmod +x "${executable}"

  WINETRICKS_LATEST_VERSION_CHECK=disabled "${executable}" list-all 2>/dev/null |
    awk 'seen || /^===== / { seen = 1; print }' >"${verbs}"
  if ! grep -q '^===== ' "${verbs}"; then
    print -u2 "winetricks list-all did not produce a verb catalog."
    exit 69
  fi

  write_stack_manifest \
    "${payload_root}/.konyak-runtime-stack.json" \
    "winetricks" \
    "${WINETRICKS_VERSION}"
  archive_payload "${payload_root}" "${archive_path}"
  print -r -- "${archive_path}"
}

resolve_gptk_d3dmetal_path() {
  local source_root="$1"
  local relative_path="$2"
  local candidate

  for candidate in \
    "${source_root}/${relative_path}" \
    "${source_root}/lib/external/${relative_path}" \
    "${source_root}/redist/lib/external/${relative_path}" \
    "${source_root}/Wine/lib/external/${relative_path}" \
    "${source_root}/Libraries/Wine/lib/external/${relative_path}" \
    "${source_root}/Contents/Resources/wine/lib/external/${relative_path}"; do
    if [[ -e "${candidate}" ]]; then
      print -r -- "${candidate}"
      return 0
    fi
  done

  return 1
}

resolve_gptk_d3dmetal_windows_dll() {
  local source_root="$1"
  local dll_name="$2"
  local candidate

  for candidate in \
    "${source_root}/${dll_name}" \
    "${source_root}/wine/x86_64-windows/${dll_name}" \
    "${source_root}/../wine/x86_64-windows/${dll_name}" \
    "${source_root}/../../wine/x86_64-windows/${dll_name}" \
    "${source_root}/lib/wine/x86_64-windows/${dll_name}" \
    "${source_root}/redist/lib/wine/x86_64-windows/${dll_name}" \
    "${source_root}/Wine/lib/wine/x86_64-windows/${dll_name}" \
    "${source_root}/Libraries/Wine/lib/wine/x86_64-windows/${dll_name}"; do
    if [[ -f "${candidate}" ]]; then
      print -r -- "${candidate}"
      return 0
    fi
  done

  return 1
}

verify_gptk_macho_file() {
  local path="$1"
  local label="$2"
  local kind

  kind="$(file -b "${path}")"
  if [[ "${kind}" != *"Mach-O"* ]]; then
    print -u2 "GPTK/D3DMetal ${label} must be a Mach-O binary, got: ${kind}"
    return 1
  fi
}

verify_gptk_pe_file() {
  local path="$1"
  local label="$2"
  local kind

  kind="$(file -b "${path}")"
  if [[ "${kind}" != *"PE32"* ]]; then
    print -u2 "GPTK/D3DMetal ${label} must be a PE binary, got: ${kind}"
    return 1
  fi
}

gptk_framework_binary() {
  local framework="$1"
  local candidate

  for candidate in \
    "${framework}/D3DMetal" \
    "${framework}/Versions/A/D3DMetal"; do
    if [[ -f "${candidate}" ]]; then
      print -r -- "${candidate}"
      return 0
    fi
  done

  return 1
}

prepare_gptk_d3dmetal_component() {
  local work_root="${SOURCE_ROOT}/work/gptk-d3dmetal"
  local payload_root="${work_root}/payload/gptk-d3dmetal"
  local archive_path="${SOURCE_ROOT}/components/gptk-d3dmetal.tar.xz"
  local source_framework
  local source_framework_binary
  local source_dylib
  local source_d3d12
  local source_dxgi

  if [[ -z "${GPTK_D3DMETAL_ROOT}" ]]; then
    print -r -- ""
    return 0
  fi

  if [[ ! -d "${GPTK_D3DMETAL_ROOT}" ]]; then
    print -u2 "GPTK/D3DMetal source directory not found: ${GPTK_D3DMETAL_ROOT}"
    exit 69
  fi

  source_framework="$(resolve_gptk_d3dmetal_path "${GPTK_D3DMETAL_ROOT}" "D3DMetal.framework" || true)"
  source_dylib="$(resolve_gptk_d3dmetal_path "${GPTK_D3DMETAL_ROOT}" "libd3dshared.dylib" || true)"
  source_d3d12="$(resolve_gptk_d3dmetal_windows_dll "${GPTK_D3DMETAL_ROOT}" "d3d12.dll" || true)"
  source_dxgi="$(resolve_gptk_d3dmetal_windows_dll "${GPTK_D3DMETAL_ROOT}" "dxgi.dll" || true)"
  if [[ -z "${source_framework}" || -z "${source_dylib}" || -z "${source_d3d12}" || -z "${source_dxgi}" ]]; then
    print -u2 "GPTK/D3DMetal source must contain D3DMetal.framework, libd3dshared.dylib, d3d12.dll, and dxgi.dll."
    exit 69
  fi
  source_framework_binary="$(gptk_framework_binary "${source_framework}" || true)"
  if [[ -z "${source_framework_binary}" ]]; then
    print -u2 "GPTK/D3DMetal source framework must contain a D3DMetal binary."
    exit 69
  fi
  verify_gptk_macho_file "${source_framework_binary}" "framework binary" || exit 69
  verify_gptk_macho_file "${source_dylib}" "shared library" || exit 69
  verify_gptk_pe_file "${source_d3d12}" "d3d12.dll" || exit 69
  verify_gptk_pe_file "${source_dxgi}" "dxgi.dll" || exit 69

  reset_dir "${work_root}"
  mkdir -p "${payload_root}/Components/GPTK-D3DMetal/lib/external"
  mkdir -p "${payload_root}/Components/GPTK-D3DMetal/lib/wine/x86_64-windows"
  cp -R "${source_framework}" \
    "${payload_root}/Components/GPTK-D3DMetal/lib/external/D3DMetal.framework"
  cp -Lf "${source_dylib}" \
    "${payload_root}/Components/GPTK-D3DMetal/lib/external/libd3dshared.dylib"
  cp -f "${source_d3d12}" \
    "${payload_root}/Components/GPTK-D3DMetal/lib/wine/x86_64-windows/d3d12.dll"
  cp -f "${source_dxgi}" \
    "${payload_root}/Components/GPTK-D3DMetal/lib/wine/x86_64-windows/dxgi.dll"
  write_stack_manifest \
    "${payload_root}/.konyak-runtime-stack.json" \
    "gptk-d3dmetal" \
    "${GPTK_D3DMETAL_VERSION}"
  archive_payload "${payload_root}" "${archive_path}"
  print -r -- "${archive_path}"
}

write_source_manifest() {
  local wine_archive_source="$1"
  local dxvk_archive="$2"
  local dxmt_archive="$3"
  local gstreamer_archive="$4"
  local winetricks_archive="$5"
  local gptk_d3dmetal_archive="${6:-}"
  local dxvk_sha
  local dxmt_sha
  local gstreamer_sha
  local winetricks_sha
  local gptk_d3dmetal_sha=""

  dxvk_sha="$(sha256_file "${dxvk_archive}")"
  dxmt_sha="$(sha256_file "${dxmt_archive}")"
  gstreamer_sha="$(sha256_file "${gstreamer_archive}")"
  winetricks_sha="$(sha256_file "${winetricks_archive}")"
  if [[ -n "${gptk_d3dmetal_archive}" ]]; then
    gptk_d3dmetal_sha="$(sha256_file "${gptk_d3dmetal_archive}")"
  fi

  mkdir -p "${MANIFEST_PATH:h}"
  "${PYTHON3_BIN}" - \
    "${MANIFEST_PATH}" \
    "${wine_archive_source}" \
    "${WINE_ARCHIVE_SHA256}" \
    "${dxvk_archive}" \
    "${dxvk_sha}" \
    "${dxmt_archive}" \
    "${dxmt_sha}" \
    "${DXMT_VERSION}" \
    "${gstreamer_archive}" \
    "${gstreamer_sha}" \
    "${winetricks_archive}" \
    "${winetricks_sha}" \
    "${gptk_d3dmetal_archive}" \
    "${gptk_d3dmetal_sha}" \
    "${GPTK_D3DMETAL_VERSION}" \
    "${WINETRICKS_VERSION}" <<'PY'
import json
import sys

(
    manifest_path,
    wine_archive,
    wine_sha,
    dxvk_archive,
    dxvk_sha,
    dxmt_archive,
    dxmt_sha,
    dxmt_version,
    gstreamer_archive,
    gstreamer_sha,
    winetricks_archive,
    winetricks_sha,
    gptk_d3dmetal_archive,
    gptk_d3dmetal_sha,
    gptk_d3dmetal_version,
    winetricks_version,
) = sys.argv[1:17]

components = [
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
        "id": "dxmt",
        "version": dxmt_version,
        "archiveUrl": dxmt_archive,
        "sha256": dxmt_sha,
    },
    {
        "id": "gstreamer",
        "version": "nix-gstreamer",
        "archiveUrl": gstreamer_archive,
        "sha256": gstreamer_sha,
    },
    {
        "id": "winetricks",
        "version": winetricks_version,
        "archiveUrl": winetricks_archive,
        "sha256": winetricks_sha,
    },
]

if gptk_d3dmetal_archive:
    components.append(
        {
            "id": "gptk-d3dmetal",
            "version": gptk_d3dmetal_version,
            "archiveUrl": gptk_d3dmetal_archive,
            "sha256": gptk_d3dmetal_sha,
        }
    )

payload = {
    "schemaVersion": 1,
    "runtimeId": "konyak-macos-wine",
    "stackId": "macos-konyak-runtime-stack",
    "components": components,
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
dxmt_archive="$(prepare_dxmt_component)"
gstreamer_archive="$(prepare_gstreamer_component)"
winetricks_archive="$(prepare_winetricks_component)"
gptk_d3dmetal_archive="$(prepare_gptk_d3dmetal_component)"
write_source_manifest \
  "${wine_archive_source}" \
  "${dxvk_archive}" \
  "${dxmt_archive}" \
  "${gstreamer_archive}" \
  "${winetricks_archive}" \
  "${gptk_d3dmetal_archive}"

if [[ "${print_manifest_path}" == true ]]; then
  print -r -- "${MANIFEST_PATH}"
fi

if [[ "${print_runtime_path}" == true ]]; then
  print -r -- "${RUNTIME_ROOT}"
fi
