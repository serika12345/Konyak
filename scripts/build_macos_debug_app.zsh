#!/usr/bin/env zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd -P)"
cd "$repo_root"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "macOS debug app builds must run on macOS." >&2
  exit 69
fi

if [[ -z "${IN_NIX_SHELL:-}" ]]; then
  echo "Run this script through: nix develop -c zsh -lc './scripts/build_macos_debug_app.zsh'" >&2
  exit 69
fi

for command in dart flutter ditto codesign; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Missing required command: $command" >&2
    exit 69
  fi
done

debug_root="${KONYAK_MACOS_DEBUG_APP_OUTPUT_DIR:-$repo_root/.dart_tool/konyak/app/macos/debug}"
stage_root="$debug_root/stage"
cli_executable="$stage_root/bin/konyak-cli"
app_bundle="$repo_root/apps/konyak/build/macos/Build/Products/Debug/Konyak.app"
debug_app_bundle="$debug_root/Konyak.app"
flutter_framework="$repo_root/apps/konyak/build/macos/Build/Products/Debug/FlutterMacOS.framework"
pubspec_version="$(awk '/^version:/ { print $2; exit }' apps/konyak/pubspec.yaml)"
build_name="${pubspec_version%%+*}"

rm -rf "$stage_root"
mkdir -p "$stage_root/bin" "$debug_root"

if [[ -e "$flutter_framework" ]]; then
  chmod -R u+w "$flutter_framework" 2>/dev/null || true
  rm -rf "$flutter_framework"
fi

echo "Building Konyak CLI executable for packaged debug app..."
(
  cd packages/konyak_cli
  dart compile exe \
    -D KONYAK_APP_VERSION="$build_name" \
    bin/konyak.dart \
    -o "$cli_executable"
)

echo "Building Flutter macOS debug app..."
(
  cd apps/konyak
  flutter build macos \
    --debug \
    --dart-define=KONYAK_CLI_EXECUTABLE=__KONYAK_BUNDLE_RESOURCES__/konyak-cli
)

./scripts/finalize_macos_app.zsh \
  --app "$app_bundle" \
  --cli "$cli_executable"

rm -rf "$debug_app_bundle"
ditto "$app_bundle" "$debug_app_bundle"
codesign --verify --deep --strict --verbose=2 "$debug_app_bundle"

echo "macOS packaged debug app:"
echo "  $debug_app_bundle"
