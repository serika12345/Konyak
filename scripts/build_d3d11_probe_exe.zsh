#!/usr/bin/env zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
compiler="${KONYAK_MINGW_CC:-x86_64-w64-mingw32-gcc}"
build_dir="$repo_root/.dart_tool/konyak/optional-runtime-probes"
source_file="$repo_root/tests/fixtures/windows/d3d11_probe.c"
probe_exe="$build_dir/d3d11_probe.exe"

if ! command -v "$compiler" >/dev/null 2>&1; then
  echo "Missing $compiler. Run this target inside the Nix dev shell." >&2
  exit 2
fi

mkdir -p "$build_dir"

"$compiler" \
  -std=c11 \
  -Wall \
  -Wextra \
  -Werror \
  -O2 \
  "$source_file" \
  -ld3d11 \
  -ldxgi \
  -luuid \
  -lgdi32 \
  -o "$probe_exe"

printf '%s\n' "$probe_exe"
