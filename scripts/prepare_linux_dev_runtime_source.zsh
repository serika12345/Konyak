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

require_command_path() {
  local command_name="$1"
  local command_path

  command_path="$(resolve_command_path "${command_name}" || true)"
  if [[ -z "${command_path}" ]]; then
    print -u2 "${command_name} not found. Run this script inside nix develop."
    exit 69
  fi

  print -r -- "${command_path}"
}

readonly PYTHON3_BIN="$(require_command_path python3)"
readonly CURL_BIN="$(require_command_path curl)"
readonly TAR_BIN="$(require_command_path tar)"
readonly ZSTD_BIN="$(require_command_path zstd)"

readonly ROOT="${0:A:h:h}"
readonly RUNTIME_ROOT="${KONYAK_LINUX_WINE_HOME:-${ROOT}/.dart_tool/konyak/dev-runtime/linux-wine}"
readonly SOURCE_ROOT="${ROOT}/.dart_tool/konyak/dev-runtime-source/linux-wine-stack"
readonly DOWNLOAD_CACHE="${ROOT}/.dart_tool/konyak/download-cache"
readonly MANIFEST_PATH="${KONYAK_DEV_LINUX_WINE_STACK_MANIFEST:-${SOURCE_ROOT}/konyak-linux-wine-runtime-stack-source.json}"

readonly DEFAULT_WINE_VERSION="11.9"
readonly DEFAULT_WINE_ARCHIVE_URL="https://github.com/Kron4ek/Wine-Builds/releases/download/11.9/wine-11.9-amd64-wow64.tar.xz"
readonly DEFAULT_WINE_ARCHIVE_SHA256="92e1c1a829752ae20b0f4a2d00f8c234f9ad7b0dec3c533797d9f9f9e71cbed2"

readonly DEFAULT_WINETRICKS_VERSION="20260125"
readonly DEFAULT_WINETRICKS_SCRIPT_URL="https://raw.githubusercontent.com/Winetricks/winetricks/20260125/src/winetricks"
readonly DEFAULT_WINETRICKS_SCRIPT_SHA256="431f82fc74000e6c864409f1d8fb495d696c03928808e3e8acffc45179312a7b"

readonly DEFAULT_WINE_MONO_VERSION="11.1.0"
readonly DEFAULT_WINE_MONO_ARCHIVE_URL="https://github.com/wine-mono/wine-mono/releases/download/wine-mono-11.1.0/wine-mono-11.1.0-x86.msi"
readonly DEFAULT_WINE_MONO_ARCHIVE_SHA256="deb0341431f8260b209fff6bc79ddcc5414b97f8e9236ab9fbdca4ce59e0a9b9"

readonly DEFAULT_DXVK_VERSION="2.7.1"
readonly DEFAULT_DXVK_ARCHIVE_URL="https://github.com/doitsujin/dxvk/releases/download/v2.7.1/dxvk-2.7.1.tar.gz"
readonly DEFAULT_DXVK_ARCHIVE_SHA256="d85ce7c79f57ecd765aaa1b9e7007cb875e6fde9f6d331df799bce73d513ce87"

readonly DEFAULT_VKD3D_PROTON_VERSION="3.0.1"
readonly DEFAULT_VKD3D_PROTON_ARCHIVE_URL="https://github.com/HansKristian-Work/vkd3d-proton/releases/download/v3.0.1/vkd3d-proton-3.0.1.tar.zst"
readonly DEFAULT_VKD3D_PROTON_ARCHIVE_SHA256="3cf2315522af5e43605ef6d3c41dad91387040bf97199934f3f7ab76caaa2f0c"

# Optional source overrides:
# KONYAK_DEV_LINUX_WINE_ARCHIVE_URL or KONYAK_DEV_LINUX_WINE_ARCHIVE
# KONYAK_DEV_LINUX_WINETRICKS_ARCHIVE_URL or KONYAK_DEV_LINUX_WINETRICKS_ARCHIVE
# KONYAK_DEV_LINUX_WINE_MONO_ARCHIVE_URL or KONYAK_DEV_LINUX_WINE_MONO_ARCHIVE
# KONYAK_DEV_LINUX_DXVK_ARCHIVE_URL or KONYAK_DEV_LINUX_DXVK_ARCHIVE
# KONYAK_DEV_LINUX_VKD3D_PROTON_ARCHIVE_URL or KONYAK_DEV_LINUX_VKD3D_PROTON_ARCHIVE
# Each source override must also provide a matching *_ARCHIVE_SHA256 value.

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
    "${CURL_BIN}" --fail --location --output "${target}" "${url}"
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
  "${TAR_BIN}" -cJf "${archive_path}" -C "${payload_root:h}" "${payload_root:t}"
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

component_source_override() {
  local id="$1"
  local env_prefix="$2"
  local url_key="${env_prefix}_ARCHIVE_URL"
  local archive_key="${env_prefix}_ARCHIVE"
  local sha_key="${env_prefix}_ARCHIVE_SHA256"
  local version_key="${env_prefix}_VERSION"
  local source="${(P)url_key:-}"
  local sha="${(P)sha_key:-}"
  local version="${(P)version_key:-}"

  if [[ -z "${source}" ]]; then
    source="${(P)archive_key:-}"
  fi

  if [[ -z "${source}" ]]; then
    return 1
  fi

  if [[ -z "${sha}" ]]; then
    print -u2 "${sha_key} is required when ${url_key} or ${archive_key} is set."
    exit 69
  fi

  if [[ -z "${version}" ]]; then
    version="${source:t}"
  fi

  print -r -- "${id}"$'\t'"${version}"$'\t'"${source}"$'\t'"${sha}"
}

component_source() {
  local id="$1"
  local version="$2"
  local source="$3"
  local sha="$4"

  print -r -- "${id}"$'\t'"${version}"$'\t'"${source}"$'\t'"${sha}"
}

prepare_winetricks_component() {
  local version="${KONYAK_DEV_LINUX_WINETRICKS_VERSION:-${DEFAULT_WINETRICKS_VERSION}}"
  local script_url="${KONYAK_DEV_LINUX_WINETRICKS_SCRIPT_URL:-${DEFAULT_WINETRICKS_SCRIPT_URL}}"
  local script_sha="${KONYAK_DEV_LINUX_WINETRICKS_SCRIPT_SHA256:-${DEFAULT_WINETRICKS_SCRIPT_SHA256}}"
  local script_cache="${KONYAK_DEV_LINUX_WINETRICKS_SCRIPT_CACHE:-${DOWNLOAD_CACHE}/winetricks-${version}}"
  local work_root="${SOURCE_ROOT}/work/winetricks"
  local payload_root="${work_root}/payload/konyak-linux-winetricks"
  local archive_path="${SOURCE_ROOT}/components/winetricks.tar.xz"

  download_if_missing "${script_url}" "${script_cache}" "${script_sha}"
  reset_dir "${work_root}"
  mkdir -p "${payload_root}"
  cp -f "${script_cache}" "${payload_root}/winetricks"
  chmod 0755 "${payload_root}/winetricks"
  write_stack_manifest \
    "${payload_root}/.konyak-runtime-stack.json" \
    "winetricks" \
    "${version}"
  archive_payload "${payload_root}" "${archive_path}"
  component_source winetricks "${version}" "${archive_path}" "$(sha256_file "${archive_path}")"
}

prepare_wine_mono_component() {
  local version="${KONYAK_DEV_LINUX_WINE_MONO_VERSION:-${DEFAULT_WINE_MONO_VERSION}}"
  local archive_url="${KONYAK_DEV_LINUX_WINE_MONO_UPSTREAM_ARCHIVE_URL:-${DEFAULT_WINE_MONO_ARCHIVE_URL}}"
  local archive_sha="${KONYAK_DEV_LINUX_WINE_MONO_UPSTREAM_ARCHIVE_SHA256:-${DEFAULT_WINE_MONO_ARCHIVE_SHA256}}"
  local archive_cache="${KONYAK_DEV_LINUX_WINE_MONO_UPSTREAM_ARCHIVE_CACHE:-${DOWNLOAD_CACHE}/wine-mono-${version}-x86.msi}"
  local work_root="${SOURCE_ROOT}/work/wine-mono"
  local payload_root="${work_root}/payload/konyak-linux-wine-mono"
  local archive_path="${SOURCE_ROOT}/components/wine-mono.tar.xz"

  download_if_missing "${archive_url}" "${archive_cache}" "${archive_sha}"
  reset_dir "${work_root}"
  mkdir -p "${payload_root}/share/wine/mono"
  cp -f "${archive_cache}" "${payload_root}/share/wine/mono/wine-mono-${version}-x86.msi"
  write_stack_manifest \
    "${payload_root}/.konyak-runtime-stack.json" \
    "wine-mono" \
    "wine-mono-${version}"
  archive_payload "${payload_root}" "${archive_path}"
  component_source wine-mono "wine-mono-${version}" "${archive_path}" "$(sha256_file "${archive_path}")"
}

prepare_dxvk_component() {
  local version="${KONYAK_DEV_LINUX_DXVK_VERSION:-${DEFAULT_DXVK_VERSION}}"
  local archive_url="${KONYAK_DEV_LINUX_DXVK_UPSTREAM_ARCHIVE_URL:-${DEFAULT_DXVK_ARCHIVE_URL}}"
  local archive_sha="${KONYAK_DEV_LINUX_DXVK_UPSTREAM_ARCHIVE_SHA256:-${DEFAULT_DXVK_ARCHIVE_SHA256}}"
  local archive_cache="${KONYAK_DEV_LINUX_DXVK_UPSTREAM_ARCHIVE_CACHE:-${DOWNLOAD_CACHE}/dxvk-${version}.tar.gz}"
  local work_root="${SOURCE_ROOT}/work/dxvk"
  local extract_root="${work_root}/extract"
  local payload_root="${work_root}/payload/konyak-linux-dxvk"
  local archive_path="${SOURCE_ROOT}/components/dxvk.tar.xz"
  local source_x64
  local source_x86

  download_if_missing "${archive_url}" "${archive_cache}" "${archive_sha}"
  reset_dir "${work_root}"
  mkdir -p "${extract_root}" \
    "${payload_root}/dxvk/x64" \
    "${payload_root}/dxvk/x86"
  "${TAR_BIN}" -xzf "${archive_cache}" -C "${extract_root}"

  for dll_name in dxgi.dll d3d9.dll d3d10core.dll d3d11.dll; do
    source_x64="$(find "${extract_root}" -path "*/x64/${dll_name}" -type f | head -n 1)"
    source_x86="$(find "${extract_root}" -path "*/x32/${dll_name}" -type f | head -n 1)"
    if [[ -z "${source_x64}" || -z "${source_x86}" ]]; then
      print -u2 "DXVK archive does not contain x64/x32 ${dll_name}."
      exit 65
    fi

    cp -f "${source_x64}" "${payload_root}/dxvk/x64/${dll_name}"
    cp -f "${source_x86}" "${payload_root}/dxvk/x86/${dll_name}"
  done
  write_stack_manifest \
    "${payload_root}/.konyak-runtime-stack.json" \
    "dxvk" \
    "v${version}"
  archive_payload "${payload_root}" "${archive_path}"
  component_source dxvk "v${version}" "${archive_path}" "$(sha256_file "${archive_path}")"
}

prepare_vkd3d_proton_component() {
  local version="${KONYAK_DEV_LINUX_VKD3D_PROTON_VERSION:-${DEFAULT_VKD3D_PROTON_VERSION}}"
  local archive_url="${KONYAK_DEV_LINUX_VKD3D_PROTON_UPSTREAM_ARCHIVE_URL:-${DEFAULT_VKD3D_PROTON_ARCHIVE_URL}}"
  local archive_sha="${KONYAK_DEV_LINUX_VKD3D_PROTON_UPSTREAM_ARCHIVE_SHA256:-${DEFAULT_VKD3D_PROTON_ARCHIVE_SHA256}}"
  local archive_cache="${KONYAK_DEV_LINUX_VKD3D_PROTON_UPSTREAM_ARCHIVE_CACHE:-${DOWNLOAD_CACHE}/vkd3d-proton-${version}.tar.zst}"
  local work_root="${SOURCE_ROOT}/work/vkd3d-proton"
  local extract_root="${work_root}/extract"
  local payload_root="${work_root}/payload/konyak-linux-vkd3d-proton"
  local archive_path="${SOURCE_ROOT}/components/vkd3d-proton.tar.xz"
  local source_d3d12_x64
  local source_d3d12_x86
  local source_d3d12core_x64
  local source_d3d12core_x86

  download_if_missing "${archive_url}" "${archive_cache}" "${archive_sha}"
  reset_dir "${work_root}"
  mkdir -p "${extract_root}" \
    "${payload_root}/vkd3d-proton/x64" \
    "${payload_root}/vkd3d-proton/x86"
  "${TAR_BIN}" --use-compress-program="${ZSTD_BIN}" -xf "${archive_cache}" -C "${extract_root}"

  source_d3d12_x64="$(find "${extract_root}" -path '*/x64/d3d12.dll' -type f | head -n 1)"
  source_d3d12_x86="$(find "${extract_root}" -path '*/x86/d3d12.dll' -type f | head -n 1)"
  source_d3d12core_x64="$(find "${extract_root}" -path '*/x64/d3d12core.dll' -type f | head -n 1)"
  source_d3d12core_x86="$(find "${extract_root}" -path '*/x86/d3d12core.dll' -type f | head -n 1)"
  if [[ -z "${source_d3d12_x64}" ||
        -z "${source_d3d12_x86}" ||
        -z "${source_d3d12core_x64}" ||
        -z "${source_d3d12core_x86}" ]]; then
    print -u2 "vkd3d-proton archive does not contain x64/x86 d3d12.dll and d3d12core.dll."
    exit 65
  fi

  cp -f "${source_d3d12_x64}" "${payload_root}/vkd3d-proton/x64/d3d12.dll"
  cp -f "${source_d3d12_x86}" "${payload_root}/vkd3d-proton/x86/d3d12.dll"
  cp -f "${source_d3d12core_x64}" "${payload_root}/vkd3d-proton/x64/d3d12core.dll"
  cp -f "${source_d3d12core_x86}" "${payload_root}/vkd3d-proton/x86/d3d12core.dll"
  write_stack_manifest \
    "${payload_root}/.konyak-runtime-stack.json" \
    "vkd3d-proton" \
    "v${version}"
  archive_payload "${payload_root}" "${archive_path}"
  component_source vkd3d-proton "v${version}" "${archive_path}" "$(sha256_file "${archive_path}")"
}

write_source_manifest() {
  local wine_source="$1"
  local winetricks_source="$2"
  local mono_source="$3"
  local dxvk_source="$4"
  local vkd3d_source="$5"

  mkdir -p "${MANIFEST_PATH:h}"
  "${PYTHON3_BIN}" - \
    "${MANIFEST_PATH}" \
    "${wine_source}" \
    "${winetricks_source}" \
    "${mono_source}" \
    "${dxvk_source}" \
    "${vkd3d_source}" <<'PY'
import json
import sys


def parse_component(source: str) -> dict[str, str]:
    component_id, version, archive_url, sha256 = source.split("\t", 3)
    return {
        "id": component_id,
        "version": version,
        "archiveUrl": archive_url,
        "sha256": sha256,
    }


manifest_path, *sources = sys.argv[1:]
payload = {
    "schemaVersion": 1,
    "runtimeId": "konyak-linux-wine",
    "stackId": "linux-wine-runtime-stack",
    "components": [parse_component(source) for source in sources],
}

with open(manifest_path, "w", encoding="utf-8") as handle:
    json.dump(payload, handle, indent=2)
    handle.write("\n")
PY
}

mkdir -p "${SOURCE_ROOT}/components" "${DOWNLOAD_CACHE}" "${RUNTIME_ROOT:h}"

wine_source="$(component_source_override wine KONYAK_DEV_LINUX_WINE || true)"
if [[ -z "${wine_source}" ]]; then
  wine_source="$(component_source \
    wine \
    "wine-${DEFAULT_WINE_VERSION}" \
    "${DEFAULT_WINE_ARCHIVE_URL}" \
    "${DEFAULT_WINE_ARCHIVE_SHA256}")"
fi

winetricks_source="$(component_source_override winetricks KONYAK_DEV_LINUX_WINETRICKS || true)"
if [[ -z "${winetricks_source}" ]]; then
  winetricks_source="$(prepare_winetricks_component)"
fi

mono_source="$(component_source_override wine-mono KONYAK_DEV_LINUX_WINE_MONO || true)"
if [[ -z "${mono_source}" ]]; then
  mono_source="$(prepare_wine_mono_component)"
fi

dxvk_source="$(component_source_override dxvk KONYAK_DEV_LINUX_DXVK || true)"
if [[ -z "${dxvk_source}" ]]; then
  dxvk_source="$(prepare_dxvk_component)"
fi

vkd3d_source="$(component_source_override vkd3d-proton KONYAK_DEV_LINUX_VKD3D_PROTON || true)"
if [[ -z "${vkd3d_source}" ]]; then
  vkd3d_source="$(prepare_vkd3d_proton_component)"
fi

write_source_manifest \
  "${wine_source}" \
  "${winetricks_source}" \
  "${mono_source}" \
  "${dxvk_source}" \
  "${vkd3d_source}"

if [[ "${print_manifest_path}" == true ]]; then
  print -r -- "${MANIFEST_PATH}"
fi

if [[ "${print_runtime_path}" == true ]]; then
  print -r -- "${RUNTIME_ROOT}"
fi
