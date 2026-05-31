#!/usr/bin/env zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
compiler="${KONYAK_MINGW_CC:-x86_64-w64-mingw32-gcc}"
build_dir="$repo_root/.dart_tool/konyak/vulkan-wine-smoke"
source_file="$repo_root/tests/fixtures/windows/vulkan_probe.c"
probe_exe="$build_dir/vulkan_probe.exe"
shader_header="$build_dir/vulkan_triangle_spv.h"
vertex_spv="$build_dir/vulkan_triangle.vert.spv"
fragment_spv="$build_dir/vulkan_triangle.frag.spv"

if ! command -v "$compiler" >/dev/null 2>&1; then
  echo "Missing $compiler. Run this target inside the Nix dev shell." >&2
  exit 2
fi
if ! command -v glslangValidator >/dev/null 2>&1; then
  echo "Missing glslangValidator. Run this target inside the Nix dev shell." >&2
  exit 2
fi

mkdir -p "$build_dir"

glslangValidator -V \
  "$repo_root/tests/fixtures/windows/vulkan_triangle.vert" \
  -o "$vertex_spv" >/dev/null
glslangValidator -V \
  "$repo_root/tests/fixtures/windows/vulkan_triangle.frag" \
  -o "$fragment_spv" >/dev/null

python3 - "$vertex_spv" "$fragment_spv" "$shader_header" <<'PY'
import pathlib
import sys

vertex = pathlib.Path(sys.argv[1]).read_bytes()
fragment = pathlib.Path(sys.argv[2]).read_bytes()
output = pathlib.Path(sys.argv[3])

def array(name, data):
    values = ", ".join(f"0x{byte:02x}" for byte in data)
    return f"static const unsigned char {name}[] = {{{values}}};\n"

output.write_text(
    "#pragma once\n"
    "#include <stdint.h>\n"
    f"static const uint32_t kTriangleVertexShaderSize = {len(vertex)}u;\n"
    + array("kTriangleVertexShader", vertex)
    + f"static const uint32_t kTriangleFragmentShaderSize = {len(fragment)}u;\n"
    + array("kTriangleFragmentShader", fragment),
    encoding="utf-8",
)
PY

"$compiler" \
  -std=c11 \
  -Wall \
  -Wextra \
  -Werror \
  -O2 \
  -I"$build_dir" \
  "$source_file" \
  -lgdi32 \
  -o "$probe_exe"

printf '%s\n' "$probe_exe"
