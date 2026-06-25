#!/usr/bin/env zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd -P)"
cd "$repo_root"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "macOS app update handoff smoke is supported on macOS only." >&2
  exit 69
fi

for command in bash chmod curl ditto hdiutil jq kill shasum sleep; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Missing required command: $command" >&2
    exit 69
  fi
done

release_root="${KONYAK_RELEASE_OUTPUT_DIR:-$repo_root/.dart_tool/konyak/release/macos}"
app_bundle="${1:-$release_root/Konyak.app}"
cli_executable="$app_bundle/Contents/Resources/konyak-cli"
work_root="${KONYAK_MACOS_APP_UPDATE_HANDOFF_SMOKE_WORK_ROOT:-$repo_root/.dart_tool/konyak/macos-app-update-handoff-smoke}"
target_bundle="$work_root/current/Konyak.app"
updated_bundle="$work_root/update/Konyak.app"
dmg_root="$work_root/dmg-root"
archive_path="$work_root/release/Konyak-1.1.0-macos-smoke.dmg"
release_json="$work_root/release/latest.json"
install_json="$work_root/install.json"
app_pid=""

cleanup() {
  if [[ -n "$app_pid" ]]; then
    kill "$app_pid" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

write_minimal_app_bundle() {
  local bundle_path="$1"
  local marker="$2"

  mkdir -p "$bundle_path/Contents/MacOS" "$bundle_path/Contents/Resources"
  cat >"$bundle_path/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>Konyak</string>
  <key>CFBundleIdentifier</key>
  <string>app.konyak.Konyak.update-smoke</string>
  <key>CFBundleName</key>
  <string>Konyak</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
</dict>
</plist>
PLIST
  cat >"$bundle_path/Contents/MacOS/Konyak" <<'APP'
#!/usr/bin/env zsh
exit 0
APP
  chmod 755 "$bundle_path/Contents/MacOS/Konyak"
  printf "%s\n" "$marker" >"$bundle_path/Contents/Resources/update-smoke-marker.txt"
}

if [[ ! -x "$cli_executable" ]]; then
  echo "Bundled konyak-cli was not found: $cli_executable" >&2
  exit 1
fi
cli_executable="${cli_executable:A}"

rm -rf "$work_root"
mkdir -p "$work_root/release"
write_minimal_app_bundle "$target_bundle" "current"
write_minimal_app_bundle "$updated_bundle" "updated"
mkdir -p "$dmg_root"
ditto "$updated_bundle" "$dmg_root/Konyak.app"
ln -s /Applications "$dmg_root/Applications"
target_bundle="${target_bundle:A}"
updated_bundle="${updated_bundle:A}"
dmg_root="${dmg_root:A}"
archive_path="${archive_path:A}"
release_json="${release_json:A}"
install_json="${install_json:A}"

hdiutil create -volname "Konyak" -srcfolder "$dmg_root" -ov -format UDZO "$archive_path" >/dev/null
archive_sha256="$(shasum -a 256 "$archive_path" | awk '{ print $1 }')"
archive_name="${archive_path:t}"
archive_url="file://$archive_path"

jq -n \
  --arg tagName "v1.1.0" \
  --arg archiveUrl "$archive_url" \
  --arg body "$archive_sha256  $archive_name" \
  '{
    tag_name: $tagName,
    body: $body,
    assets: [
      {
        name: ($archiveUrl | split("/") | last),
        browser_download_url: $archiveUrl
      }
    ]
  }' >"$release_json"

sleep 600 &
app_pid="$!"

env -i \
  PATH="/usr/bin:/bin" \
  HOME="$work_root/home" \
  KONYAK_APP_VERSION="1.0.0" \
  KONYAK_APP_VERSION_URL="file://$release_json" \
  KONYAK_APP_BUNDLE_PATH="$target_bundle" \
  KONYAK_APP_PID="$app_pid" \
  KONYAK_APP_UPDATE_CACHE_HOME="$work_root/cache" \
  "$cli_executable" install-app-update --json \
  >"$install_json"

jq -e \
  --arg target_bundle "$target_bundle" \
  --arg archive_url "$archive_url" \
  --arg archive_sha256 "$archive_sha256" \
  '.schemaVersion == 1
    and .appUpdateInstall.appId == "konyak"
    and .appUpdateInstall.status == "installed"
    and .appUpdateInstall.currentVersion == "1.0.0"
    and .appUpdateInstall.installedVersion == "v1.1.0"
    and .appUpdateInstall.archiveUrl == $archive_url
    and .appUpdateInstall.archiveSha256 == $archive_sha256
    and .appUpdateInstall.installPath == $target_bundle' \
  "$install_json" >/dev/null

for _ in {1..120}; do
  if [[ -f "$target_bundle/Contents/Resources/update-smoke-marker.txt" ]] &&
    [[ "$(cat "$target_bundle/Contents/Resources/update-smoke-marker.txt")" == "updated" ]]; then
    break
  fi
  sleep 0.25
done

if [[ "$(cat "$target_bundle/Contents/Resources/update-smoke-marker.txt" 2>/dev/null || true)" != "updated" ]]; then
  echo "macOS app update handoff did not replace the target bundle." >&2
  cat "$install_json" >&2
  exit 1
fi

if kill -0 "$app_pid" 2>/dev/null; then
  echo "macOS app update handoff did not terminate the running app pid: $app_pid" >&2
  exit 1
fi
app_pid=""

if [[ -e "$target_bundle.konyak-backup" || -e "$target_bundle.konyak-update" ]]; then
  echo "macOS app update handoff left backup or staging bundles behind." >&2
  exit 1
fi

echo "macOS app update handoff smoke passed."
