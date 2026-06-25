#!/usr/bin/env zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd -P)"
cd "$repo_root"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "macOS DMG layout smoke is supported on macOS only." >&2
  exit 69
fi

for command in awk grep hdiutil python3 readlink sips strings; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Missing required command: $command" >&2
    exit 69
  fi
done

release_root="${KONYAK_RELEASE_OUTPUT_DIR:-$repo_root/.dart_tool/konyak/release/macos}"
dmg_path="${1:-}"
if [[ -z "$dmg_path" ]]; then
  host_arch="$(uname -m)"
  candidate_dmgs=("$release_root"/Konyak-*-macos-"$host_arch".dmg(N))
  if [[ ${#candidate_dmgs[@]} -ne 1 ]]; then
    echo "Expected exactly one macOS DMG under $release_root; found ${#candidate_dmgs[@]}." >&2
    exit 1
  fi
  dmg_path="${candidate_dmgs[1]}"
fi

work_root="${KONYAK_MACOS_DMG_LAYOUT_SMOKE_WORK_ROOT:-$repo_root/.dart_tool/konyak/macos-dmg-layout-smoke}"
mount_dir="$work_root/mount"
attached=false

cleanup() {
  if [[ "$attached" == true ]]; then
    hdiutil detach "$mount_dir" >/dev/null 2>&1 || true
  fi
  rm -rf "$work_root"
}
trap cleanup EXIT

rm -rf "$work_root"
mkdir -p "$mount_dir"
dmg_path="${dmg_path:A}"

hdiutil attach "$dmg_path" -mountpoint "$mount_dir" -nobrowse -readonly >/dev/null
attached=true

background_path="$mount_dir/.background/konyak-dmg-background.png"
if [[ ! -f "$background_path" ]]; then
  echo "DMG is missing the Finder background image: $background_path" >&2
  exit 1
fi

background_width="$(sips -g pixelWidth "$background_path" 2>/dev/null | awk '/pixelWidth:/ { print $2 }')"
background_height="$(sips -g pixelHeight "$background_path" 2>/dev/null | awk '/pixelHeight:/ { print $2 }')"
if [[ "$background_width" != "640" || "$background_height" != "420" ]]; then
  echo "Unexpected DMG background size: ${background_width}x${background_height}" >&2
  exit 1
fi

python3 - "$background_path" <<'PY'
import struct
import sys
import zlib

path = sys.argv[1]
with open(path, 'rb') as image_file:
    data = image_file.read()

if not data.startswith(b'\x89PNG\r\n\x1a\n'):
    raise SystemExit('DMG background is not a PNG image.')

offset = 8
width = height = bit_depth = color_type = interlace = None
compressed = bytearray()
while offset < len(data):
    length = struct.unpack('>I', data[offset:offset + 4])[0]
    chunk_type = data[offset + 4:offset + 8]
    chunk_data = data[offset + 8:offset + 8 + length]
    offset += 12 + length
    if chunk_type == b'IHDR':
        width, height, bit_depth, color_type, _, _, interlace = struct.unpack(
            '>IIBBBBB',
            chunk_data,
        )
    elif chunk_type == b'IDAT':
        compressed.extend(chunk_data)
    elif chunk_type == b'IEND':
        break

if (width, height, bit_depth, interlace) != (640, 420, 8, 0):
    raise SystemExit(
        f'Unexpected PNG header: {width}x{height}, bit depth {bit_depth}, '
        f'interlace {interlace}.',
    )

if color_type not in (2, 6):
    raise SystemExit(f'Unsupported PNG color type: {color_type}.')

channels = 3 if color_type == 2 else 4
stride = width * channels
raw = zlib.decompress(bytes(compressed))
rows = []
position = 0
previous = [0] * stride
for _ in range(height):
    filter_type = raw[position]
    position += 1
    row = list(raw[position:position + stride])
    position += stride

    for index, value in enumerate(row):
        left = row[index - channels] if index >= channels else 0
        up = previous[index]
        upper_left = previous[index - channels] if index >= channels else 0
        if filter_type == 1:
            row[index] = (value + left) & 0xff
        elif filter_type == 2:
            row[index] = (value + up) & 0xff
        elif filter_type == 3:
            row[index] = (value + ((left + up) // 2)) & 0xff
        elif filter_type == 4:
            prediction = left + up - upper_left
            pa = abs(prediction - left)
            pb = abs(prediction - up)
            pc = abs(prediction - upper_left)
            predictor = left if pa <= pb and pa <= pc else up if pb <= pc else upper_left
            row[index] = (value + predictor) & 0xff
        elif filter_type != 0:
            raise SystemExit(f'Unsupported PNG filter type: {filter_type}.')

    rows.append(row)
    previous = row

def pixel(x, y):
    start = x * channels
    return tuple(rows[y][start:start + 3])

def require_white(x, y, label):
    red, green, blue = pixel(x, y)
    if min(red, green, blue) < 245:
        raise SystemExit(f'{label} is not white enough: {(red, green, blue)}.')

def require_arrow_color(x, y, label):
    red, green, blue = pixel(x, y)
    if (red, green, blue) != (235, 169, 72):
        raise SystemExit(f'{label} is not the arrow color: {(red, green, blue)}.')

def has_antialiased_edge():
    for y in range(176, 244):
        for x in range(348, 400):
            red, green, blue = pixel(x, y)
            if (
                235 < red < 255 and
                169 < green < 255 and
                72 < blue < 255
            ):
                return True
    return False

require_white(20, 20, 'top-left background')
require_white(620, 400, 'bottom-right background')
require_white(412, 210, 'arrow right-side clearance')
require_white(330, 228, 'old arrow shadow area')
require_arrow_color(330, 210, 'arrow body')
if not has_antialiased_edge():
    raise SystemExit('arrow does not contain antialiased vector edges.')
PY

if [[ ! -d "$mount_dir/Konyak.app" ]]; then
  echo "DMG is missing Konyak.app." >&2
  exit 1
fi

if [[ ! -L "$mount_dir/Applications" ]]; then
  echo "DMG is missing the Applications symlink." >&2
  exit 1
fi

if [[ "$(readlink "$mount_dir/Applications")" != "/Applications" ]]; then
  echo "Applications symlink does not point to /Applications." >&2
  exit 1
fi

if [[ ! -f "$mount_dir/.DS_Store" ]]; then
  echo "DMG is missing Finder view metadata." >&2
  exit 1
fi

if ! strings "$mount_dir/.DS_Store" | grep -q "icvp"; then
  echo "DMG Finder metadata does not include icon-view settings." >&2
  exit 1
fi

echo "macOS DMG layout smoke passed."
