#!/usr/bin/env zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd -P)"
cd "$repo_root"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "macOS release builds must run on macOS." >&2
  exit 69
fi

if [[ -z "${IN_NIX_SHELL:-}" && -z "${KONYAK_NIX_RELEASE_APP:-}" ]]; then
  echo "Run this script through: nix run .#macos-release" >&2
  echo "or: nix develop -c zsh -lc './scripts/build_macos_release.zsh'" >&2
  exit 69
fi

for command in dart flutter ditto create-dmg resvg shasum codesign jq rsync zstd otool install_name_tool; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Missing required command: $command" >&2
    exit 69
  fi
done

generate_dmg_background() {
  local output_png="$1"
  local svg_path="$stage_root/konyak-dmg-background.svg"

  cat >"$svg_path" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="640" height="420" viewBox="0 0 640 420">
  <rect width="640" height="420" fill="#fff"/>
  <path d="M260 198 H356 V181 L398 210 L356 239 V222 H260 Z" fill="#eba948"/>
</svg>
SVG

  resvg \
    --width 640 \
    --height 420 \
    --shape-rendering geometricPrecision \
    "$svg_path" \
    "$output_png"
}

pubspec_version="$(awk '/^version:/ { print $2; exit }' apps/konyak/pubspec.yaml)"
build_name="${KONYAK_RELEASE_VERSION:-${pubspec_version%%+*}}"
build_number="${KONYAK_RELEASE_BUILD_NUMBER:-${pubspec_version#*+}}"
if [[ "$build_number" == "$pubspec_version" ]]; then
  build_number="1"
fi

host_arch="$(uname -m)"
release_root="${KONYAK_RELEASE_OUTPUT_DIR:-$repo_root/.dart_tool/konyak/release/macos}"
stage_root="$release_root/stage"
cli_executable="$stage_root/bin/konyak-cli"
dmg_root="$stage_root/dmg"
dmg_background="$stage_root/konyak-dmg-background.png"
app_bundle="$repo_root/apps/konyak/build/macos/Build/Products/Release/Konyak.app"
release_app_bundle="$release_root/Konyak.app"
flutter_framework="$repo_root/apps/konyak/build/macos/Build/Products/Release/FlutterMacOS.framework"
artifact_basename="Konyak-${build_name}-macos-${host_arch}"
dmg_path="$release_root/${artifact_basename}.dmg"
checksum_path="$dmg_path.sha256"
checksums_path="$release_root/SHA256SUMS"
metadata_path="$release_root/${artifact_basename}.release.json"
notes_path="$release_root/release-notes.md"

rm -rf "$stage_root"
mkdir -p "$stage_root/bin" "$release_root"

if [[ -e "$flutter_framework" ]]; then
  chmod -R u+w "$flutter_framework" 2>/dev/null || true
  rm -rf "$flutter_framework"
fi

echo "Building Konyak CLI executable..."
(
  cd packages/konyak_cli
  dart compile exe bin/konyak.dart -o "$cli_executable"
)

echo "Building Flutter macOS app..."
(
  cd apps/konyak
  flutter build macos \
    --release \
    --build-name "$build_name" \
    --build-number "$build_number" \
    --dart-define=KONYAK_CLI_EXECUTABLE=__KONYAK_BUNDLE_RESOURCES__/konyak-cli
)

echo "Signing Konyak.app ad hoc; release artifacts are intentionally unnotarized."
./scripts/finalize_macos_app.zsh \
  --app "$app_bundle" \
  --cli "$cli_executable"

rm -f \
  "$dmg_path" \
  "$checksum_path" \
  "$checksums_path" \
  "$metadata_path" \
  "$notes_path" \
  "$release_root/${artifact_basename}.zip" \
  "$release_root/${artifact_basename}.zip.sha256"
rm -rf "$release_app_bundle"
ditto "$app_bundle" "$release_app_bundle"
codesign --verify --deep --strict --verbose=2 "$release_app_bundle"
rm -rf "$dmg_root"
mkdir -p "$dmg_root"
ditto "$release_app_bundle" "$dmg_root/Konyak.app"
generate_dmg_background "$dmg_background"
create-dmg \
  --volname "Konyak" \
  --background "$dmg_background" \
  --window-pos 120 120 \
  --window-size 640 420 \
  --text-size 14 \
  --icon-size 96 \
  --icon "Konyak.app" 170 210 \
  --app-drop-link 470 210 \
  --hide-extension "Konyak.app" \
  --no-internet-enable \
  --format UDZO \
  "$dmg_path" \
  "$dmg_root"
checksum="$(shasum -a 256 "$dmg_path" | awk '{ print $1 }')"
printf "%s  %s\n" "$checksum" "$(basename "$dmg_path")" >"$checksum_path"
cp "$checksum_path" "$checksums_path"

jq -n \
  --arg schemaVersion "1" \
  --arg appId "konyak" \
  --arg version "$build_name" \
  --arg architecture "$host_arch" \
  --arg artifact "$(basename "$dmg_path")" \
  --arg sha256 "$checksum" \
  '{
    schemaVersion: ($schemaVersion | tonumber),
    appId: $appId,
    version: $version,
    artifacts: [
      {
        platform: "macos",
        architecture: $architecture,
        format: "dmg",
        fileName: $artifact,
        sha256: $sha256
      }
    ]
  }' >"$metadata_path"

{
  printf "# Konyak %s\n\n" "$build_name"
  printf "## SHA-256\n\n"
  printf "\`\`\`text\n"
  cat "$checksums_path"
  printf "\`\`\`\n"
} >"$notes_path"

echo "macOS release artifacts:"
echo "  $release_app_bundle"
echo "  $dmg_path"
echo "  $checksum_path"
echo "  $metadata_path"
echo "  $notes_path"
