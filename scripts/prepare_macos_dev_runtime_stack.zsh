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
readonly RELEASE_REFERENCE_PATH="${ROOT}/runtime/macos-wine-release.json"
readonly RUNTIME_ROOT="${KONYAK_MACOS_WINE_HOME:-${ROOT}/.dart_tool/konyak/dev-runtime/macos-wine}"
readonly SOURCE_ROOT="${ROOT}/.dart_tool/konyak/dev-runtime-source/macos-wine-stack"
readonly DOWNLOAD_CACHE="${ROOT}/.dart_tool/konyak/download-cache"
readonly MANIFEST_PATH="${SOURCE_ROOT}/konyak-macos-wine-runtime-stack-source.json"

release_reference_value() {
  "${PYTHON3_BIN}" - "${RELEASE_REFERENCE_PATH}" "$1" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
print(data[sys.argv[2]])
PY
}

release_source_manifest_url() {
  local repository="$1"
  local release_tag="$2"
  local manifest_name="$3"

  if [[ "${release_tag}" == "latest" ]]; then
    print -r -- "https://github.com/${repository}/releases/latest/download/${manifest_name}"
    return 0
  fi

  print -r -- "https://github.com/${repository}/releases/download/${release_tag}/${manifest_name}"
}

readonly DEFAULT_RUNTIME_RELEASE_REPOSITORY="$(release_reference_value repository)"
readonly DEFAULT_RUNTIME_RELEASE_TAG="$(release_reference_value defaultReleaseTag)"
readonly RUNTIME_SOURCE_MANIFEST_FILE_NAME="$(release_reference_value sourceManifestFileName)"
readonly RUNTIME_SOURCE_MODE="${KONYAK_DEV_MACOS_RUNTIME_SOURCE_MODE:-release}"
readonly RUNTIME_RELEASE_REPOSITORY="${KONYAK_DEV_MACOS_RUNTIME_RELEASE_REPO:-${DEFAULT_RUNTIME_RELEASE_REPOSITORY}}"
readonly RUNTIME_RELEASE_TAG="${KONYAK_DEV_MACOS_RUNTIME_RELEASE_TAG:-${DEFAULT_RUNTIME_RELEASE_TAG}}"
if [[ "${KONYAK_DEV_MACOS_WINE_STACK_MANIFEST:-}" == http://* ||
      "${KONYAK_DEV_MACOS_WINE_STACK_MANIFEST:-}" == https://* ]]; then
  RUNTIME_RELEASE_SOURCE_MANIFEST_URL="${KONYAK_DEV_MACOS_WINE_STACK_MANIFEST}"
else
  RUNTIME_RELEASE_SOURCE_MANIFEST_URL="${KONYAK_DEV_MACOS_WINE_STACK_MANIFEST_URL:-$(release_source_manifest_url "${RUNTIME_RELEASE_REPOSITORY}" "${RUNTIME_RELEASE_TAG}" "${RUNTIME_SOURCE_MANIFEST_FILE_NAME}")}"
fi
readonly RUNTIME_RELEASE_SOURCE_MANIFEST_URL
readonly WINE_ARCHIVE_URL="${KONYAK_DEV_MACOS_WINE_ARCHIVE_URL:-}"
readonly WINE_ARCHIVE_SHA256="${KONYAK_DEV_MACOS_WINE_ARCHIVE_SHA256:-}"
readonly WINE_ARCHIVE_CACHE="${KONYAK_DEV_MACOS_WINE_ARCHIVE_CACHE:-${DOWNLOAD_CACHE}/macos-wine-component.tar.xz}"
readonly WINE_VERSION="${KONYAK_DEV_MACOS_WINE_VERSION:-local-macos-wine}"
readonly DXVK_ARCHIVE_URL="${KONYAK_DEV_DXVK_MACOS_ARCHIVE_URL:-https://github.com/Gcenx/DXVK-macOS/releases/download/v1.10.3-20230507/dxvk-macOS-async-v1.10.3-20230507.tar.gz}"
readonly DXVK_ARCHIVE_SHA256="${KONYAK_DEV_DXVK_MACOS_ARCHIVE_SHA256:-f67d99d0a8eeedd7d406b283a3df9f939b5965acb00efcb33d0c6235c195a516}"
readonly DXVK_ARCHIVE_CACHE="${KONYAK_DEV_DXVK_MACOS_ARCHIVE_CACHE:-${DOWNLOAD_CACHE}/dxvk-macOS-async-v1.10.3-20230507.tar.gz}"
readonly DXVK_D3D10_ARCHIVE_URL="${KONYAK_DEV_DXVK_D3D10_ARCHIVE_URL:-https://github.com/doitsujin/dxvk/releases/download/v1.10.3/dxvk-1.10.3.tar.gz}"
readonly DXVK_D3D10_ARCHIVE_SHA256="${KONYAK_DEV_DXVK_D3D10_ARCHIVE_SHA256:-8d1a3c912761b450c879f98478ae64f6f6639e40ce6848170a0f6b8596fd53c6}"
readonly DXVK_D3D10_ARCHIVE_CACHE="${KONYAK_DEV_DXVK_D3D10_ARCHIVE_CACHE:-${DOWNLOAD_CACHE}/dxvk-1.10.3.tar.gz}"
readonly DXVK_VERSION="${KONYAK_DEV_DXVK_VERSION:-v1.10.3-20230507+dxvk-1.10.3-d3d10}"
readonly DXMT_ARCHIVE_URL="${KONYAK_DEV_DXMT_ARCHIVE_URL:-https://github.com/serika12345/konyak-macos-runtime/releases/download/crossover-26.1.0-konyak.0/konyak-macos-dxmt.tar.zst}"
readonly DXMT_ARCHIVE_SHA256="${KONYAK_DEV_DXMT_ARCHIVE_SHA256:-2f3851e4fddc66074ba512146ddb6240646989000e8ba2a555ca6706eac8e611}"
readonly DXMT_ARCHIVE_CACHE="${KONYAK_DEV_DXMT_ARCHIVE_CACHE:-${DOWNLOAD_CACHE}/konyak-macos-dxmt.tar.zst}"
readonly DXMT_VERSION="${KONYAK_DEV_DXMT_VERSION:-aa9df0b86b041dc836a08f3a499f2a203cdbd4d7-konyak.0}"
readonly GSTREAMER_ROOT="${KONYAK_DEV_NIX_GSTREAMER_PATH:-}"
readonly GSTREAMER_PLUGIN_ROOTS_RAW="${KONYAK_DEV_NIX_GSTREAMER_PLUGIN_PATHS:-}"
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

download_release_manifest_if_needed() {
  local target="${MANIFEST_PATH}"
  local source_url="${RUNTIME_RELEASE_SOURCE_MANIFEST_URL}"
  local source_marker="${target}.source-url"
  local temp_target="${target}.tmp.$$"

  mkdir -p "${target:h}"
  rm -f "${temp_target}"
  curl --fail --location --output "${temp_target}" "${source_url}"
  mv -f "${temp_target}" "${target}"
  print -r -- "${source_url}" >"${source_marker}"
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

extract_archive() {
  local archive_path="$1"
  local extract_root="$2"
  shift 2

  if tar --help 2>/dev/null | grep -q -- "--warning"; then
    tar --warning=no-unknown-keyword "$@" -f "${archive_path}" -C "${extract_root}"
  else
    tar "$@" -f "${archive_path}" -C "${extract_root}"
  fi
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
  local d3d10_extract_root="${work_root}/extract-d3d10"
  local payload_root="${work_root}/payload/dxvk-macos"
  local archive_path="${SOURCE_ROOT}/components/dxvk-macos.tar.xz"
  local source_x64
  local source_x32

  download_if_missing "${DXVK_ARCHIVE_URL}" "${DXVK_ARCHIVE_CACHE}" "${DXVK_ARCHIVE_SHA256}"
  download_if_missing "${DXVK_D3D10_ARCHIVE_URL}" "${DXVK_D3D10_ARCHIVE_CACHE}" "${DXVK_D3D10_ARCHIVE_SHA256}"
  reset_dir "${work_root}"
  mkdir -p "${extract_root}" "${d3d10_extract_root}"
  extract_archive "${DXVK_ARCHIVE_CACHE}" "${extract_root}" -xz
  extract_archive "${DXVK_D3D10_ARCHIVE_CACHE}" "${d3d10_extract_root}" -xz

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

  for dll_name in d3d10.dll d3d10_1.dll; do
    source_x64="$(find "${d3d10_extract_root}" -path "*/x64/${dll_name}" -type f | head -n 1)"
    source_x32="$(find "${d3d10_extract_root}" -path "*/x32/${dll_name}" -type f | head -n 1)"
    if [[ -z "${source_x64}" || -z "${source_x32}" ]]; then
      print -u2 "DXVK upstream archive does not contain x64/x32 ${dll_name}."
      exit 65
    fi

    cp -f "${source_x64}" "${payload_root}/Components/DXVK-macOS/DXVK/x64/${dll_name}"
    cp -f "${source_x32}" "${payload_root}/Components/DXVK-macOS/DXVK/x32/${dll_name}"
  done
  write_stack_manifest \
    "${payload_root}/.konyak-runtime-stack.json" \
    "dxvk-macos" \
    "${DXVK_VERSION}"
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
  extract_archive "${DXMT_ARCHIVE_CACHE}" "${extract_root}" --zstd -x

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
  local source_scanner
  local plugin_root
  local plugin_dir
  local plugin_path
  local plugin_roots=("${(@s.:.)GSTREAMER_PLUGIN_ROOTS_RAW}")
  local copied_plugins=0

  if [[ -z "${GSTREAMER_ROOT}" ]]; then
    print -u2 "KONYAK_DEV_NIX_GSTREAMER_PATH is required. Run inside nix develop."
    exit 69
  fi
  if [[ -z "${GSTREAMER_PLUGIN_ROOTS_RAW}" ]]; then
    print -u2 "KONYAK_DEV_NIX_GSTREAMER_PLUGIN_PATHS is required in local macOS runtime source mode."
    exit 69
  fi

  source_dylib="${GSTREAMER_ROOT}/lib/libgstreamer-1.0.0.dylib"
  if [[ ! -f "${source_dylib}" ]]; then
    print -u2 "GStreamer dylib not found: ${source_dylib}"
    exit 69
  fi
  source_scanner="${GSTREAMER_ROOT}/libexec/gstreamer-1.0/gst-plugin-scanner"
  if [[ ! -x "${source_scanner}" ]]; then
    print -u2 "GStreamer plugin scanner not found: ${source_scanner}"
    exit 69
  fi

  reset_dir "${work_root}"
  mkdir -p \
    "${payload_root}/Components/GStreamer/lib" \
    "${payload_root}/Components/GStreamer/lib/gstreamer-1.0" \
    "${payload_root}/Components/GStreamer/libexec/gstreamer-1.0"
  cp -Lf "${source_dylib}" \
    "${payload_root}/Components/GStreamer/lib/libgstreamer-1.0.0.dylib"
  cp -Lf "${source_scanner}" \
    "${payload_root}/Components/GStreamer/libexec/gstreamer-1.0/gst-plugin-scanner"
  chmod +x "${payload_root}/Components/GStreamer/libexec/gstreamer-1.0/gst-plugin-scanner"
  for plugin_root in "${plugin_roots[@]}"; do
    plugin_dir="${plugin_root}/lib/gstreamer-1.0"
    if [[ ! -d "${plugin_dir}" ]]; then
      print -u2 "GStreamer plugin directory not found: ${plugin_dir}"
      exit 69
    fi

    while IFS= read -r plugin_path; do
      cp -Lf "${plugin_path}" \
        "${payload_root}/Components/GStreamer/lib/gstreamer-1.0/${plugin_path:t}"
      copied_plugins=$((copied_plugins + 1))
    done < <(/usr/bin/find "${plugin_dir}" -maxdepth 1 -type f -name '*.dylib' -print)
  done
  if [[ "${copied_plugins}" -eq 0 ]]; then
    print -u2 "No GStreamer plugins were copied."
    exit 69
  fi
  for required_path in \
    lib/gstreamer-1.0/libgstcoreelements.dylib \
    lib/gstreamer-1.0/libgstplayback.dylib \
    lib/gstreamer-1.0/libgsttypefindfunctions.dylib \
    lib/gstreamer-1.0/libgstisomp4.dylib \
    lib/gstreamer-1.0/libgstwavparse.dylib \
    lib/gstreamer-1.0/libgstapplemedia.dylib; do
    if [[ ! -f "${payload_root}/Components/GStreamer/${required_path}" ]]; then
      print -u2 "GStreamer plugin payload is missing ${required_path}."
      exit 69
    fi
  done
  write_stack_manifest \
    "${payload_root}/.konyak-runtime-stack.json" \
    "gstreamer" \
    "${GSTREAMER_ROOT:t}+plugins"
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

resolve_gptk_d3dmetal_unix_library() {
  local source_root="$1"
  local library_name="$2"
  local candidate

  for candidate in \
    "${source_root}/${library_name}" \
    "${source_root}/wine/x86_64-unix/${library_name}" \
    "${source_root}/../wine/x86_64-unix/${library_name}" \
    "${source_root}/../../wine/x86_64-unix/${library_name}" \
    "${source_root}/lib/wine/x86_64-unix/${library_name}" \
    "${source_root}/redist/lib/wine/x86_64-unix/${library_name}" \
    "${source_root}/Wine/lib/wine/x86_64-unix/${library_name}" \
    "${source_root}/Libraries/Wine/lib/wine/x86_64-unix/${library_name}" \
    "${source_root}/Contents/Resources/wine/lib/wine/x86_64-unix/${library_name}"; do
    if [[ -e "${candidate}" || -L "${candidate}" ]]; then
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
  local source_path
  local windows_files=(
    atidxx64.dll
    d3d10.dll
    d3d11.dll
    d3d12.dll
    dxgi.dll
    nvapi64.dll
    nvngx-on-metalfx.dll
  )
  local unix_files=(
    atidxx64.so
    d3d10.so
    d3d11.so
    d3d12.so
    dxgi.so
    nvapi64.so
    nvngx-on-metalfx.so
  )

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
  if [[ -z "${source_framework}" || -z "${source_dylib}" ]]; then
    print -u2 "GPTK/D3DMetal source must contain D3DMetal.framework and libd3dshared.dylib."
    exit 69
  fi
  source_framework_binary="$(gptk_framework_binary "${source_framework}" || true)"
  if [[ -z "${source_framework_binary}" ]]; then
    print -u2 "GPTK/D3DMetal source framework must contain a D3DMetal binary."
    exit 69
  fi
  verify_gptk_macho_file "${source_framework_binary}" "framework binary" || exit 69
  verify_gptk_macho_file "${source_dylib}" "shared library" || exit 69
  for file_name in "${windows_files[@]}"; do
    source_path="$(resolve_gptk_d3dmetal_windows_dll "${GPTK_D3DMETAL_ROOT}" "${file_name}" || true)"
    if [[ -z "${source_path}" ]]; then
      print -u2 "GPTK/D3DMetal source is missing ${file_name}."
      exit 69
    fi
    verify_gptk_pe_file "${source_path}" "${file_name}" || exit 69
  done
  for file_name in "${unix_files[@]}"; do
    source_path="$(resolve_gptk_d3dmetal_unix_library "${GPTK_D3DMETAL_ROOT}" "${file_name}" || true)"
    if [[ -z "${source_path}" ]]; then
      print -u2 "GPTK/D3DMetal source is missing ${file_name}."
      exit 69
    fi
    if [[ "${file_name}" == "d3d11.so" || "${file_name}" == "d3d12.so" || "${file_name}" == "dxgi.so" ]]; then
      if [[ ! -L "${source_path}" || "$(/usr/bin/stat -f '%Y' "${source_path}")" != "../../external/libd3dshared.dylib" ]]; then
        print -u2 "GPTK/D3DMetal ${file_name} must be a symlink to ../../external/libd3dshared.dylib."
        exit 69
      fi
    fi
  done

  reset_dir "${work_root}"
  mkdir -p "${payload_root}/Components/GPTK-D3DMetal/lib/external"
  mkdir -p "${payload_root}/Components/GPTK-D3DMetal/lib/wine/x86_64-windows"
  mkdir -p "${payload_root}/Components/GPTK-D3DMetal/lib/wine/x86_64-unix"
  cp -R "${source_framework}" \
    "${payload_root}/Components/GPTK-D3DMetal/lib/external/D3DMetal.framework"
  cp -Lf "${source_dylib}" \
    "${payload_root}/Components/GPTK-D3DMetal/lib/external/libd3dshared.dylib"
  for file_name in "${windows_files[@]}"; do
    source_path="$(resolve_gptk_d3dmetal_windows_dll "${GPTK_D3DMETAL_ROOT}" "${file_name}")"
    cp -f "${source_path}" \
      "${payload_root}/Components/GPTK-D3DMetal/lib/wine/x86_64-windows/${file_name}"
  done
  for file_name in "${unix_files[@]}"; do
    source_path="$(resolve_gptk_d3dmetal_unix_library "${GPTK_D3DMETAL_ROOT}" "${file_name}")"
    cp -a "${source_path}" \
      "${payload_root}/Components/GPTK-D3DMetal/lib/wine/x86_64-unix/${file_name}"
  done
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
    "${WINE_VERSION}" \
    "${dxvk_archive}" \
    "${dxvk_sha}" \
    "${DXVK_VERSION}" \
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
    wine_version,
    dxvk_archive,
    dxvk_sha,
    dxvk_version,
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
) = sys.argv[1:19]

components = [
    {
        "id": "wine",
        "version": wine_version,
        "archiveUrl": wine_archive,
        "sha256": wine_sha,
    },
    {
        "id": "dxvk-macos",
        "version": dxvk_version,
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
        "version": "nix-gstreamer+plugins",
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

case "${RUNTIME_SOURCE_MODE}" in
  release)
    download_release_manifest_if_needed

    if [[ "${print_manifest_path}" == true ]]; then
      print -r -- "${MANIFEST_PATH}"
    fi

    if [[ "${print_runtime_path}" == true ]]; then
      print -r -- "${RUNTIME_ROOT}"
    fi

    exit 0
    ;;
  local)
    ;;
  *)
    print -u2 "unknown KONYAK_DEV_MACOS_RUNTIME_SOURCE_MODE: ${RUNTIME_SOURCE_MODE}"
    exit 64
    ;;
esac

mkdir -p "${SOURCE_ROOT}" "${DOWNLOAD_CACHE}" "${RUNTIME_ROOT:h}"

if [[ -z "${WINE_ARCHIVE_SHA256}" ]]; then
  print -u2 "KONYAK_DEV_MACOS_WINE_ARCHIVE_SHA256 is required in local macOS runtime source mode."
  exit 69
fi

if [[ -z "${WINE_ARCHIVE_URL}" && ! -f "${WINE_ARCHIVE_CACHE}" ]]; then
  print -u2 "KONYAK_DEV_MACOS_WINE_ARCHIVE_URL or KONYAK_DEV_MACOS_WINE_ARCHIVE_CACHE is required in local macOS runtime source mode."
  exit 69
fi

if [[ "${download_wine}" == true && -z "${WINE_ARCHIVE_URL}" ]]; then
  print -u2 "KONYAK_DEV_MACOS_WINE_ARCHIVE_URL is required with --download-wine in local macOS runtime source mode."
  exit 69
fi

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
