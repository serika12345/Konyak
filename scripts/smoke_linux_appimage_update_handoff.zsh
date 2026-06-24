#!/usr/bin/env zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd -P)"
cd "$repo_root"

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "Linux AppImage update handoff smoke is supported on Linux only." >&2
  exit 69
fi

for command in awk bash cat chmod cmp curl jq kill sha256sum sleep; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Missing required command: $command" >&2
    exit 69
  fi
done

release_root="${KONYAK_RELEASE_OUTPUT_DIR:-$repo_root/.dart_tool/konyak/release/linux}"
appdir="${1:-$release_root/Konyak.AppDir}"
cli_executable="$appdir/usr/share/konyak/konyak-cli"
work_root="${KONYAK_LINUX_APPIMAGE_UPDATE_HANDOFF_SMOKE_WORK_ROOT:-$repo_root/.dart_tool/konyak/linux-appimage-update-handoff-smoke}"
target_appimage="$work_root/current/Konyak-current.AppImage"
updated_appimage="$work_root/release/Konyak-1.1.0-linux-x86_64.AppImage"
release_json="$work_root/release/latest.json"
install_json="$work_root/install.json"
relaunch_sentinel="$work_root/relaunched.txt"
app_pid=""

cleanup() {
  if [[ -n "$app_pid" ]]; then
    kill "$app_pid" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

single_quote() {
  local value="$1"
  printf "'%s'" "${value//\'/\'\\\'\'}"
}

write_appimage_spy() {
  local appimage_path="$1"
  local marker="$2"
  local sentinel="$3"
  local sentinel_quoted

  sentinel_quoted="$(single_quote "$sentinel")"
  cat >"$appimage_path" <<EOF
#!/usr/bin/env bash
set -euo pipefail

printf "%s\n" "$marker" >$sentinel_quoted
EOF
  chmod 755 "$appimage_path"
}

if [[ ! -x "$cli_executable" ]]; then
  echo "Bundled konyak-cli was not found: $cli_executable" >&2
  exit 1
fi
cli_executable="${cli_executable:A}"

rm -rf "$work_root"
mkdir -p "$work_root/current" "$work_root/release" "$work_root/home"

write_appimage_spy "$target_appimage" "current" "$work_root/current-started.txt"
write_appimage_spy "$updated_appimage" "updated" "$relaunch_sentinel"
target_appimage="${target_appimage:A}"
updated_appimage="${updated_appimage:A}"
release_json="${release_json:A}"
install_json="${install_json:A}"
relaunch_sentinel="${relaunch_sentinel:A}"

archive_sha256="$(sha256sum "$updated_appimage" | awk '{ print $1 }')"
archive_name="${updated_appimage:t}"
archive_url="file://$updated_appimage"

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
  PATH="${PATH:-/usr/bin:/bin}" \
  HOME="$work_root/home" \
  KONYAK_APP_VERSION="1.0.0" \
  KONYAK_APP_VERSION_URL="file://$release_json" \
  KONYAK_APPIMAGE_PATH="$target_appimage" \
  KONYAK_APP_PID="$app_pid" \
  KONYAK_APP_UPDATE_CACHE_HOME="$work_root/cache" \
  "$cli_executable" install-app-update --json \
  >"$install_json"

jq -e \
  --arg target_appimage "$target_appimage" \
  --arg archive_url "$archive_url" \
  --arg archive_sha256 "$archive_sha256" \
  '.schemaVersion == 1
    and .appUpdateInstall.appId == "konyak"
    and .appUpdateInstall.status == "installed"
    and .appUpdateInstall.currentVersion == "1.0.0"
    and .appUpdateInstall.installedVersion == "v1.1.0"
    and .appUpdateInstall.archiveUrl == $archive_url
    and .appUpdateInstall.archiveSha256 == $archive_sha256
    and .appUpdateInstall.installPath == $target_appimage' \
  "$install_json" >/dev/null

for _ in {1..120}; do
  if [[ -f "$relaunch_sentinel" ]] &&
    [[ "$(cat "$relaunch_sentinel")" == "updated" ]]; then
    break
  fi
  sleep 0.25
done

if [[ "$(cat "$relaunch_sentinel" 2>/dev/null || true)" != "updated" ]]; then
  echo "Linux AppImage update handoff did not relaunch the updated AppImage." >&2
  cat "$install_json" >&2
  exit 1
fi

if ! cmp -s "$target_appimage" "$updated_appimage"; then
  echo "Linux AppImage update handoff did not replace the target AppImage." >&2
  cat "$install_json" >&2
  exit 1
fi

if kill -0 "$app_pid" 2>/dev/null; then
  echo "Linux AppImage update handoff did not terminate the running app pid: $app_pid" >&2
  exit 1
fi
app_pid=""

if [[ -e "$target_appimage.konyak-backup" || -e "$target_appimage.konyak-update" ]]; then
  echo "Linux AppImage update handoff left backup or staging files behind." >&2
  exit 1
fi

echo "Linux AppImage update handoff smoke passed."
