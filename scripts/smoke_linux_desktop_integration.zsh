#!/usr/bin/env zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd -P)"
cd "$repo_root"

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "Linux desktop integration smoke is supported on Linux only." >&2
  exit 69
fi

for command in cmp dart grep jq mktemp; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Missing required command: $command" >&2
    exit 69
  fi
done

work_root="$(mktemp -d)"
cleanup() {
  rm -rf "$work_root"
}
trap cleanup EXIT

xdg_data_home="$work_root/xdg-data"
xdg_config_home="$work_root/xdg-config"
appdir="$work_root/Konyak.AppDir"
first_appimage="$work_root/Konyak-first.AppImage"
moved_appimage="$work_root/Konyak moved.AppImage"
icon_source="$appdir/app.konyak.Konyak.png"
app_executable="$appdir/usr/konyak"
result_json="$work_root/result.json"

mkdir -p "$xdg_data_home" "$xdg_config_home" "$appdir/usr"
printf 'first appimage' >"$first_appimage"
printf 'moved appimage' >"$moved_appimage"
printf 'runner' >"$app_executable"
printf '\211PNG\r\n\032\n' >"$icon_source"

run_registration() {
  local appimage_path="$1"
  (
    cd "$repo_root/packages/konyak_cli"
    XDG_DATA_HOME="$xdg_data_home" \
      XDG_CONFIG_HOME="$xdg_config_home" \
      KONYAK_APPIMAGE_PATH="$appimage_path" \
      KONYAK_APP_EXECUTABLE="$app_executable" \
      KONYAK_APP_ICON_PATH="$icon_source" \
      dart run bin/konyak.dart install-linux-file-associations --json
  ) >"$result_json"
}

run_registration "$first_appimage"
run_registration "$moved_appimage"

desktop_entry="$xdg_data_home/applications/app.konyak.Konyak.desktop"
icon_target="$xdg_data_home/icons/hicolor/256x256/apps/app.konyak.Konyak.png"
mime_apps="$xdg_config_home/mimeapps.list"

jq -e \
  --arg desktop_entry "$desktop_entry" \
  --arg icon_target "$icon_target" \
  --arg mime_apps "$mime_apps" \
  '.schemaVersion == 1
    and .linuxFileAssociations.desktopEntryPath == $desktop_entry
    and .linuxFileAssociations.iconPath == $icon_target
    and .linuxFileAssociations.mimeAppsPath == $mime_apps
    and (.linuxFileAssociations.mimeTypes | index("application/x-ms-dos-executable") != null)' \
  "$result_json" >/dev/null

grep -Fx "Exec=\"${moved_appimage}\" %f" "$desktop_entry" >/dev/null
grep -Fx "Icon=app.konyak.Konyak" "$desktop_entry" >/dev/null
grep -Fx "MimeType=application/x-ms-dos-executable;application/x-msdownload;application/vnd.microsoft.portable-executable;application/x-msi;application/x-ms-installer;application/x-ms-shortcut;application/x-msdos-program;text/x-msdos-batch;" "$desktop_entry" >/dev/null
grep -Fx "application/x-ms-dos-executable=app.konyak.Konyak.desktop" "$mime_apps" >/dev/null
grep -Fx "application/vnd.microsoft.portable-executable=app.konyak.Konyak.desktop" "$mime_apps" >/dev/null
cmp "$icon_source" "$icon_target"

if command -v xdg-mime >/dev/null 2>&1; then
  registered_default="$(
    XDG_DATA_HOME="$xdg_data_home" \
      XDG_CONFIG_HOME="$xdg_config_home" \
      xdg-mime query default application/x-ms-dos-executable
  )"
  if [[ "$registered_default" != "app.konyak.Konyak.desktop" ]]; then
    echo "xdg-mime did not resolve Konyak as the default .exe handler." >&2
    echo "resolved: $registered_default" >&2
    exit 1
  fi
fi

echo "Linux desktop integration smoke passed."
