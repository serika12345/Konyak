#!/usr/bin/env zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd -P)"
cd "$repo_root"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "macOS release runtime extraction smoke is supported on macOS only." >&2
  exit 69
fi

for command in jq otool tar zstd; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Missing required command: $command" >&2
    exit 69
  fi
done

release_root="${KONYAK_RELEASE_OUTPUT_DIR:-$repo_root/.dart_tool/konyak/release/macos}"
app_bundle="${1:-$release_root/Konyak.app}"
resources_dir="$app_bundle/Contents/Resources"
cli_executable="$resources_dir/konyak-cli"
zstd_executable="$resources_dir/zstd"
zstd_library="$resources_dir/libzstd.1.dylib"
work_root="${KONYAK_MACOS_RELEASE_RUNTIME_EXTRACTION_SMOKE_WORK_ROOT:-$repo_root/.dart_tool/konyak/macos-release-runtime-extraction-smoke}"
runtime_source="$work_root/source/Runtime"
runtime_home="$work_root/home"
config_home="$work_root/config"
data_home="$work_root/data"
archive_path="$work_root/runtime-stack.tar.zst"
manifest_path="$work_root/runtime-stack-source.json"
install_json="$work_root/install.json"

if [[ ! -x "$cli_executable" ]]; then
  echo "Packaged Konyak CLI was not found: $cli_executable" >&2
  exit 1
fi
if [[ ! -x "$zstd_executable" ]]; then
  echo "Packaged zstd helper was not found: $zstd_executable" >&2
  exit 1
fi
if [[ ! -f "$zstd_library" ]]; then
  echo "Packaged libzstd was not found: $zstd_library" >&2
  exit 1
fi
if ! otool -L "$zstd_executable" | grep -F "@executable_path/libzstd.1.dylib" >/dev/null; then
  echo "Packaged zstd does not resolve libzstd from its bundle directory." >&2
  otool -L "$zstd_executable" >&2
  exit 1
fi

PATH=/usr/bin:/bin "$zstd_executable" --version >/dev/null

rm -rf "$work_root"
mkdir -p "$runtime_source" "$runtime_home" "$config_home" "$data_home"

while IFS= read -r relative_path; do
  [[ -z "$relative_path" ]] && continue
  mkdir -p "$runtime_source/${relative_path:h}"
  printf "fixture\n" >"$runtime_source/$relative_path"
done <<'RUNTIME_PATHS'
bin/wine
bin/wineloader
bin/wineserver
Konyak Wine Hosted Application/wine
Konyak Wine Hosted Application/wineloader
Konyak Wine Hosted Application/wineserver
lib/wine/x86_64-unix/wine
lib/wine/i386-windows/ntdll.dll
lib/wine/x86_64-windows/wow64.dll
lib/wine/x86_64-windows/wow64cpu.dll
lib/wine/x86_64-windows/wow64win.dll
lib/wine/x86_64-unix/ntdll.so
lib/dxvk/x86_64-windows/dxgi.dll
lib/dxvk/x86_64-windows/d3d9.dll
lib/dxvk/x86_64-windows/d3d10.dll
lib/dxvk/x86_64-windows/d3d10_1.dll
lib/dxvk/x86_64-windows/d3d10core.dll
lib/dxvk/x86_64-windows/d3d11.dll
lib/dxvk/i386-windows/dxgi.dll
lib/dxvk/i386-windows/d3d9.dll
lib/dxvk/i386-windows/d3d10.dll
lib/dxvk/i386-windows/d3d10_1.dll
lib/dxvk/i386-windows/d3d10core.dll
lib/dxvk/i386-windows/d3d11.dll
lib/libMoltenVK.dylib
lib/libgstreamer-1.0.0.dylib
lib/gstreamer-1.0/libgstcoreelements.dylib
lib/gstreamer-1.0/libgstplayback.dylib
lib/gstreamer-1.0/libgsttypefindfunctions.dylib
lib/gstreamer-1.0/libgstisomp4.dylib
lib/gstreamer-1.0/libgstwavparse.dylib
lib/gstreamer-1.0/libgstapplemedia.dylib
libexec/gstreamer-1.0/gst-plugin-scanner
lib/libfreetype.6.dylib
lib/libfreetype.dylib
share/wine/mono/wine-mono-10.4.1-x86.msi
share/wine/gecko/wine-gecko-2.47.4-x86.msi
share/wine/gecko/wine-gecko-2.47.4-x86_64.msi
bin/cabextract
winetricks
verbs.txt
lib/wine/x86_64-windows/libvkd3d-1.dll
lib/wine/x86_64-windows/libvkd3d-shader-1.dll
lib/wine/x86_64-windows/libvkd3d-utils-1.dll
lib/wine/i386-windows/libvkd3d-1.dll
lib/wine/i386-windows/libvkd3d-shader-1.dll
lib/wine/i386-windows/libvkd3d-utils-1.dll
lib/dxmt/x86_64-windows/d3d10core.dll
lib/dxmt/x86_64-windows/d3d11.dll
lib/dxmt/x86_64-windows/dxgi.dll
lib/dxmt/x86_64-windows/winemetal.dll
lib/dxmt/x86_64-windows/winemetal.so
lib/dxmt/x86_64-windows/nvapi64.dll
lib/dxmt/x86_64-windows/nvngx.dll
lib/dxmt/x86_64-unix/winemetal.so
RUNTIME_PATHS

printf '{"schemaVersion":1,"components":{}}\n' >"$runtime_source/.konyak-runtime-stack.json"
tar -cf "$work_root/runtime-stack.tar" -C "$work_root/source" Runtime
zstd -q -f -o "$archive_path" "$work_root/runtime-stack.tar"
archive_sha256="$(shasum -a 256 "$archive_path" | awk '{ print $1 }')"
jq -n \
  --arg archive_url "$archive_path" \
  --arg archive_sha256 "$archive_sha256" \
  '{
    schemaVersion: 1,
    runtimeId: "konyak-macos-wine",
    stackId: "macos-konyak-runtime-stack",
    components: [
      {
        id: "wine",
        version: "smoke",
        archiveUrl: $archive_url,
        sha256: $archive_sha256
      }
    ]
  }' >"$manifest_path"

install_exit=0
env -i \
  PATH=/usr/bin:/bin \
  KONYAK_APPLICATION_SUPPORT="$runtime_home" \
  KONYAK_CONFIG_HOME="$config_home" \
  KONYAK_DATA_HOME="$data_home" \
  "$cli_executable" install-macos-wine --reinstall --source-manifest "$manifest_path" --json \
  >"$install_json" || install_exit=$?

if (( install_exit != 0 )); then
  echo "Packaged Konyak CLI runtime installation failed; install.json follows:" >&2
  cat "$install_json" >&2
  exit "$install_exit"
fi

jq -e \
  '.runtime.id == "konyak-macos-wine" and .runtime.isInstalled == true and .runtime.stack.isComplete == true' \
  "$install_json" >/dev/null

echo "macOS release runtime extraction smoke passed."
