#!/usr/bin/env zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "Skipping Linux Vulkan Wine smoke test on $(uname -s)."
  exit 0
fi

wine_executable="${KONYAK_VULKAN_PROBE_WINE:-}"
if [[ -z "$wine_executable" ]]; then
  if [[ -z "${KONYAK_LINUX_WINE_HOME:-}" ]]; then
    echo "KONYAK_LINUX_WINE_HOME is not set. Run inside the Linux Nix dev shell." >&2
    exit 2
  fi
  wine_executable="$KONYAK_LINUX_WINE_HOME/bin/wine"
fi
if [[ ! -x "$wine_executable" ]]; then
  echo "Wine executable is missing or not executable: $wine_executable" >&2
  echo "Install the Konyak Linux runtime first, for example: just linux-vulkan-wine-smoke after installing from Settings or install-linux-wine." >&2
  exit 2
fi

build_dir="$repo_root/.dart_tool/konyak/vulkan-wine-smoke"
probe_exe="$("$repo_root/scripts/build_vulkan_probe_exe.zsh")"
probe_log="$build_dir/vulkan_probe.log"
wine_prefix="${KONYAK_VULKAN_PROBE_PREFIX:-$build_dir/prefix}"

mkdir -p "$build_dir" "$wine_prefix"

typeset -a env_args
env_args=(
  "WINEPREFIX=$wine_prefix"
  "WINEDEBUG=${WINEDEBUG:--all}"
)
if [[ -n "${KONYAK_LINUX_WINE_LIBRARY_PATH:-}" ]]; then
  env_args+=(
    "LD_LIBRARY_PATH=$KONYAK_LINUX_WINE_LIBRARY_PATH${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  )
fi

set +e
env "${env_args[@]}" timeout 60 "$wine_executable" "$probe_exe" >"$probe_log" 2>&1
probe_status=$?
set -e

cat "$probe_log"

if [[ "$probe_status" -ne 0 ]]; then
  echo "Vulkan Wine probe failed with exit code $probe_status." >&2
  exit "$probe_status"
fi

if ! grep -q 'KONYAK_VULKAN_PROBE_OK' "$probe_log"; then
  echo "Vulkan Wine probe did not print the success marker." >&2
  exit 1
fi

echo "Linux Vulkan Wine smoke test passed: $probe_exe"
