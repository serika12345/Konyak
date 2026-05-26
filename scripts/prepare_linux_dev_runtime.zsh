#!/usr/bin/env zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd -P)"
runtime_root="${KONYAK_LINUX_WINE_HOME:-$repo_root/.dart_tool/konyak/dev-runtime/linux-wine}"

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "Linux dev runtime preparation is supported on Linux only." >&2
  exit 69
fi

wine_root="${KONYAK_DEV_NIX_WINE_PATH:-}"
winetricks_root="${KONYAK_DEV_NIX_WINETRICKS_PATH:-}"
vkd3d_root="${KONYAK_DEV_NIX_VKD3D_PROTON_PATH:-}"
wine_version="${KONYAK_DEV_WINE_VERSION:-nix-shell-wine}"
winetricks_version="${KONYAK_DEV_WINETRICKS_VERSION:-nix-shell-winetricks}"
vkd3d_version="${KONYAK_DEV_VKD3D_PROTON_VERSION:-nix-shell-vkd3d-proton}"

for required_var in wine_root winetricks_root vkd3d_root; do
  if [[ -z "${(P)required_var}" ]]; then
    echo "Missing required environment value: ${required_var}" >&2
    exit 69
  fi
done

mkdir -p \
  "$runtime_root/bin" \
  "$runtime_root/vkd3d-proton/x64" \
  "$runtime_root/vkd3d-proton/x86"

ln -sfn "$wine_root/bin/wine" "$runtime_root/bin/wine"
ln -sfn "$wine_root/bin/wine" "$runtime_root/bin/wine64"
ln -sfn "$wine_root/bin/wineboot" "$runtime_root/bin/wineboot"
ln -sfn "$wine_root/bin/wineserver" "$runtime_root/bin/wineserver"
ln -sfn "$winetricks_root/bin/winetricks" "$runtime_root/winetricks"
ln -sfn "$vkd3d_root/lib/libvkd3d-proton-d3d12.so" \
  "$runtime_root/vkd3d-proton/x64/d3d12.dll"
ln -sfn "$vkd3d_root/lib/libvkd3d-proton-d3d12.so" \
  "$runtime_root/vkd3d-proton/x86/d3d12.dll"

cat >"$runtime_root/.konyak-runtime-stack.json" <<EOF
{"schemaVersion":1,"components":{"wine":"$wine_version","winetricks":"$winetricks_version","vkd3d-proton":"$vkd3d_version"}}
EOF

if [[ "${1:-}" == "--print-runtime-path" ]]; then
  printf '%s\n' "$runtime_root"
fi
