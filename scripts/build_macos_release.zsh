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

for command in dart flutter ditto shasum codesign jq; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Missing required command: $command" >&2
    exit 69
  fi
done

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
app_bundle="$repo_root/apps/konyak/build/macos/Build/Products/Release/Konyak.app"
resources_dir="$app_bundle/Contents/Resources"
artifact_basename="Konyak-${build_name}-macos-${host_arch}"
zip_path="$release_root/${artifact_basename}.zip"
checksum_path="$zip_path.sha256"
checksums_path="$release_root/SHA256SUMS"
metadata_path="$release_root/${artifact_basename}.release.json"
notes_path="$release_root/release-notes.md"

rm -rf "$stage_root"
mkdir -p "$stage_root/bin" "$release_root"

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

mkdir -p "$resources_dir/Licenses"
rm -f \
  "$resources_dir"/SOURCE-*.txt(N) \
  "$resources_dir"/Licenses/Konyak-*.txt(N)
cp "$cli_executable" "$resources_dir/konyak-cli"
chmod 755 "$resources_dir/konyak-cli"
cp LICENSE "$resources_dir/Licenses/Konyak-MIT.txt"
cp THIRD_PARTY_NOTICES.md "$resources_dir/Licenses/THIRD_PARTY_NOTICES.md"
cp apps/konyak/assets/fonts/inter/OFL.txt "$resources_dir/Licenses/Inter-OFL.txt"
if [[ -f apps/konyak/macos/Pods/Target\ Support\ Files/Pods-Runner/Pods-Runner-acknowledgements.markdown ]]; then
  cp apps/konyak/macos/Pods/Target\ Support\ Files/Pods-Runner/Pods-Runner-acknowledgements.markdown \
    "$resources_dir/Licenses/CocoaPods-acknowledgements.markdown"
fi
cat >"$resources_dir/NOTICES.txt" <<EOF
Konyak is distributed under the MIT License.

Wine/Proton runtime binaries are not bundled in this application artifact.
Managed runtime components are downloaded after launch into the user's Konyak
runtime directory. Bundled license and third-party notices are included in
Contents/Resources/Licenses.
EOF

echo "Signing Konyak.app ad hoc; release artifacts are intentionally unnotarized."
codesign --force --sign - "$resources_dir/konyak-cli"
codesign --force --deep --sign - "$app_bundle"
codesign --verify --deep --strict --verbose=2 "$app_bundle"

rm -f "$zip_path" "$checksum_path" "$checksums_path" "$metadata_path" "$notes_path"
ditto -c -k --keepParent "$app_bundle" "$zip_path"
checksum="$(shasum -a 256 "$zip_path" | awk '{ print $1 }')"
printf "%s  %s\n" "$checksum" "$(basename "$zip_path")" >"$checksum_path"
cp "$checksum_path" "$checksums_path"

jq -n \
  --arg schemaVersion "1" \
  --arg appId "konyak" \
  --arg version "$build_name" \
  --arg architecture "$host_arch" \
  --arg artifact "$(basename "$zip_path")" \
  --arg sha256 "$checksum" \
  '{
    schemaVersion: ($schemaVersion | tonumber),
    appId: $appId,
    version: $version,
    artifacts: [
      {
        platform: "macos",
        architecture: $architecture,
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
echo "  $zip_path"
echo "  $checksum_path"
echo "  $metadata_path"
echo "  $notes_path"
