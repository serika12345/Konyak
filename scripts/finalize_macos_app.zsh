#!/usr/bin/env zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd -P)"
cd "$repo_root"

usage() {
  cat >&2 <<'EOF'
Usage: finalize_macos_app.zsh --app <path> --cli <path>

Finalizes a built Konyak.app bundle by installing packaged helper tools,
licenses, and ad-hoc signatures. This script is shared by debug and release
macOS app packaging.
EOF
}

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "macOS app finalization is supported on macOS only." >&2
  exit 69
fi

app_bundle=""
cli_executable=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app)
      app_bundle="${2:-}"
      shift 2
      ;;
    --cli)
      cli_executable="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      echo "Unknown argument: $1" >&2
      exit 64
      ;;
  esac
done

if [[ -z "$app_bundle" || -z "$cli_executable" ]]; then
  usage
  exit 64
fi

for command in codesign cp mkdir otool install_name_tool zstd; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Missing required command: $command" >&2
    exit 69
  fi
done

if [[ ! -d "$app_bundle" ]]; then
  echo "Konyak.app was not found: $app_bundle" >&2
  exit 1
fi
if [[ ! -x "$cli_executable" ]]; then
  echo "Konyak CLI executable was not found: $cli_executable" >&2
  exit 1
fi

resources_dir="$app_bundle/Contents/Resources"
licenses_dir="$resources_dir/Licenses"
zstd_executable="$(command -v zstd)"
zstd_library="$(otool -L "$zstd_executable" | awk '/libzstd\.1\.dylib/ { print $1; exit }')"

if [[ -z "$zstd_library" || ! -f "$zstd_library" ]]; then
  echo "Could not resolve zstd runtime library for $zstd_executable." >&2
  exit 69
fi

mkdir -p "$licenses_dir"
rm -f \
  "$resources_dir"/SOURCE-*.txt(N) \
  "$licenses_dir"/Konyak-*.txt(N)

cp "$cli_executable" "$resources_dir/konyak-cli"
chmod 755 "$resources_dir/konyak-cli"

cp "$zstd_executable" "$resources_dir/zstd"
cp "${zstd_library:A}" "$resources_dir/libzstd.1.dylib"
chmod 755 "$resources_dir/zstd" "$resources_dir/libzstd.1.dylib"
install_name_tool -id "@executable_path/libzstd.1.dylib" \
  "$resources_dir/libzstd.1.dylib"
install_name_tool -change "$zstd_library" \
  "@executable_path/libzstd.1.dylib" \
  "$resources_dir/zstd"

cp LICENSE "$licenses_dir/Konyak-MIT.txt"
cp THIRD_PARTY_NOTICES.md "$licenses_dir/THIRD_PARTY_NOTICES.md"
cp apps/konyak/assets/fonts/inter/OFL.txt "$licenses_dir/Inter-OFL.txt"
cp docs/licenses/Zstandard-BSD-3-Clause.txt \
  "$licenses_dir/Zstandard-BSD-3-Clause.txt"
if [[ -f apps/konyak/macos/Pods/Target\ Support\ Files/Pods-Runner/Pods-Runner-acknowledgements.markdown ]]; then
  cp apps/konyak/macos/Pods/Target\ Support\ Files/Pods-Runner/Pods-Runner-acknowledgements.markdown \
    "$licenses_dir/CocoaPods-acknowledgements.markdown"
fi
cat >"$resources_dir/NOTICES.txt" <<EOF
Konyak is distributed under the MIT License.

Wine/Proton runtime binaries are not bundled in this application artifact.
Managed runtime components are downloaded after launch into the user's Konyak
runtime directory. Bundled license and third-party notices are included in
Contents/Resources/Licenses.
EOF

codesign --force --sign - "$resources_dir/konyak-cli"
codesign --force --sign - "$resources_dir/zstd"
codesign --force --sign - "$resources_dir/libzstd.1.dylib"
codesign --force --deep --sign - "$app_bundle"
codesign --verify --deep --strict --verbose=2 "$app_bundle"

echo "Finalized macOS app bundle: $app_bundle"
