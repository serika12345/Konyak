part of '../konyak_cli.dart';

String _macosAppBundleUpdateHandoffScript() {
  return r'''
#!/usr/bin/env bash
set -euo pipefail

source_archive="$1"
target_bundle="$2"
app_pid="$3"
target_parent="$(dirname "$target_bundle")"
bundle_name="$(basename "$target_bundle")"
work_dir="$(mktemp -d "${TMPDIR:-/tmp}/konyak-macos-update.XXXXXX")"
extract_dir="$work_dir/extract"
helper_script="$work_dir/install-macos-app-update-helper.sh"
backup_path="$target_bundle.konyak-backup"

cleanup() {
  rm -rf "$work_dir"
}
trap cleanup EXIT

if [[ ! -d "$target_bundle" ]]; then
  exit 66
fi

mkdir -p "$extract_dir"
ditto -x -k "$source_archive" "$extract_dir"

updated_bundle=""
if [[ -d "$extract_dir/$bundle_name" ]]; then
  updated_bundle="$extract_dir/$bundle_name"
else
  for candidate in "$extract_dir"/*.app "$extract_dir"/*/*.app; do
    if [[ -d "$candidate" ]]; then
      updated_bundle="$candidate"
      break
    fi
  done
fi
if [[ -z "$updated_bundle" ]]; then
  exit 66
fi
if [[ ! -d "$updated_bundle/Contents/MacOS" ]]; then
  exit 66
fi

cat >"$helper_script" <<'HELPER'
#!/usr/bin/env bash
set -euo pipefail

updated_bundle="$1"
target_bundle="$2"
backup_path="$3"
source_archive="$4"
app_pid="$5"
staging_path="$target_bundle.konyak-update"

kill -TERM "$app_pid" 2>/dev/null || true

for ((attempt = 0; attempt < 60; attempt += 1)); do
  if ! kill -0 "$app_pid" 2>/dev/null; then
    break
  fi
  sleep 1
done

if kill -0 "$app_pid" 2>/dev/null; then
  exit 75
fi

rm -rf "$staging_path" "$backup_path"
ditto "$updated_bundle" "$staging_path"

if [[ -e "$target_bundle" ]]; then
  mv "$target_bundle" "$backup_path"
fi

if mv "$staging_path" "$target_bundle"; then
  rm -rf "$backup_path" "$source_archive"
else
  rm -rf "$staging_path"
  if [[ -e "$backup_path" ]]; then
    mv "$backup_path" "$target_bundle"
  fi
  exit 75
fi

xattr -dr com.apple.quarantine "$target_bundle" 2>/dev/null || true
HELPER
chmod 755 "$helper_script"

if [[ -w "$target_parent" ]]; then
  "$helper_script" "$updated_bundle" "$target_bundle" "$backup_path" "$source_archive" "$app_pid"
else
  osascript - "$helper_script" "$updated_bundle" "$target_bundle" "$backup_path" "$source_archive" "$app_pid" <<'APPLESCRIPT'
on run argv
  set helperScript to item 1 of argv
  set updatedBundle to item 2 of argv
  set targetBundle to item 3 of argv
  set backupPath to item 4 of argv
  set sourceArchive to item 5 of argv
  set appPid to item 6 of argv
  set command to "/bin/bash " & quoted form of helperScript & " " & quoted form of updatedBundle & " " & quoted form of targetBundle & " " & quoted form of backupPath & " " & quoted form of sourceArchive & " " & quoted form of appPid
  do shell script command with administrator privileges
end run
APPLESCRIPT
fi

nohup open "$target_bundle" >/dev/null 2>&1 &
''';
}

String _linuxAppImageUpdateHandoffScript() {
  return r'''
#!/usr/bin/env bash
set -euo pipefail

source_archive="$1"
target_appimage="$2"
app_pid="$3"
staging_path="$target_appimage.konyak-update"
backup_path="$target_appimage.konyak-backup"

kill -TERM "$app_pid" 2>/dev/null || true

for _ in $(seq 1 60); do
  if ! kill -0 "$app_pid" 2>/dev/null; then
    break
  fi
  sleep 1
done

if kill -0 "$app_pid" 2>/dev/null; then
  exit 75
fi

rm -f "$staging_path" "$backup_path"
cp "$source_archive" "$staging_path"
chmod 755 "$staging_path"

if [[ -e "$target_appimage" ]]; then
  mv "$target_appimage" "$backup_path"
fi

if mv "$staging_path" "$target_appimage"; then
  rm -f "$backup_path" "$source_archive"
else
  rm -f "$staging_path"
  if [[ -e "$backup_path" ]]; then
    mv "$backup_path" "$target_appimage"
  fi
  exit 75
fi

nohup "$target_appimage" >/dev/null 2>&1 &
''';
}
