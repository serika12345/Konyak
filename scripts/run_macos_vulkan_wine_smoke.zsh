#!/usr/bin/env zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Skipping macOS Vulkan Wine smoke test on $(uname -s)."
  exit 0
fi

wine_executable="${KONYAK_VULKAN_PROBE_WINE:-}"
runtime_root="${KONYAK_MACOS_WINE_HOME:-}"
if [[ -z "$wine_executable" ]]; then
  if [[ -z "$runtime_root" ]]; then
    echo "KONYAK_MACOS_WINE_HOME is not set. Run inside the macOS Nix dev shell." >&2
    exit 2
  fi
  wine_executable="$runtime_root/bin/wine64"
fi
if [[ ! -x "$wine_executable" ]]; then
  echo "Wine executable is missing or not executable: $wine_executable" >&2
  echo "Install the Konyak macOS runtime first, for example from Settings or install-macos-wine." >&2
  exit 2
fi
if [[ -z "$runtime_root" ]]; then
  runtime_root="$(cd "$(dirname "$wine_executable")/.." && pwd)"
fi

build_dir="$repo_root/.dart_tool/konyak/vulkan-wine-smoke"
probe_exe="$("$repo_root/scripts/build_vulkan_probe_exe.zsh")"
probe_log="$build_dir/macos_vulkan_probe.log"
wine_prefix="${KONYAK_VULKAN_PROBE_PREFIX:-$build_dir/macos-prefix}"

mkdir -p "$build_dir" "$wine_prefix"

typeset -a env_args
env_args=(
  "WINEPREFIX=$wine_prefix"
  "WINEDEBUG=${WINEDEBUG:--all}"
  "DYLD_LIBRARY_PATH=$runtime_root/lib${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"
)

set +e
env "${env_args[@]}" timeout 60 "$wine_executable" "$probe_exe" >"$probe_log" 2>&1
probe_status=$?
set -e

cat "$probe_log"

if [[ "$probe_status" -ne 0 ]]; then
  echo "macOS Vulkan Wine probe failed with exit code $probe_status." >&2
  exit "$probe_status"
fi

if ! grep -q 'KONYAK_VULKAN_PROBE_OK' "$probe_log"; then
  echo "macOS Vulkan Wine probe did not print the success marker." >&2
  exit 1
fi

echo "macOS Vulkan Wine smoke test passed: $probe_exe"
