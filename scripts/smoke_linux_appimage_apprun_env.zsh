#!/usr/bin/env zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd -P)"
cd "$repo_root"

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "Linux AppImage AppRun environment smoke is supported on Linux only." >&2
  exit 69
fi

for command in cp jq; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Missing required command: $command" >&2
    exit 69
  fi
done

release_root="${KONYAK_RELEASE_OUTPUT_DIR:-$repo_root/.dart_tool/konyak/release/linux}"
appdir="${1:-$release_root/Konyak.AppDir}"
work_root="${KONYAK_LINUX_APPIMAGE_APPRUN_ENV_SMOKE_WORK_ROOT:-$repo_root/.dart_tool/konyak/linux-appimage-apprun-env-smoke/$$}"
work_appdir="$work_root/Konyak.AppDir"
sentinel="$work_root/apprun-env.json"

single_quote() {
  local value="$1"
  printf "'%s'" "${value//\'/\'\\\'\'}"
}

if [[ ! -d "$appdir" ]]; then
  echo "Linux AppDir was not found: $appdir" >&2
  exit 1
fi
if [[ ! -x "$appdir/AppRun" ]]; then
  echo "Linux AppRun was not found: $appdir/AppRun" >&2
  exit 1
fi

rm -rf "$work_root"
mkdir -p "$work_root"
cp -R "$appdir" "$work_appdir"

resources_dir="$work_appdir/usr/share/konyak"
for required_file in \
  "$resources_dir/konyak-cli" \
  "$resources_dir/konyak-linux-wine-runtime-stack-source.json"; do
  if [[ ! -f "$required_file" ]]; then
    echo "Required bundled resource was not found: $required_file" >&2
    exit 1
  fi
done

sentinel_quoted="$(single_quote "$sentinel")"
cat >"$work_appdir/usr/konyak" <<EOF
#!/usr/bin/env zsh
set -euo pipefail

sentinel=$sentinel_quoted

json_escape() {
  local value="\$1"
  value="\${value//\\\\/\\\\\\\\}"
  value="\${value//\\\"/\\\\\\\"}"
  printf "%s" "\$value"
}

cat >"\$sentinel" <<JSON
{
  "bundleResources": "\$(json_escape "\${KONYAK_BUNDLE_RESOURCES:-}")",
  "appExecutable": "\$(json_escape "\${KONYAK_APP_EXECUTABLE:-}")",
  "appImagePath": "\$(json_escape "\${KONYAK_APPIMAGE_PATH:-}")",
  "appIconPath": "\$(json_escape "\${KONYAK_APP_ICON_PATH:-}")",
  "argumentCount": "\$#",
  "firstArgument": "\$(json_escape "\${1:-}")",
  "linuxManifest": "\$(json_escape "\${KONYAK_LINUX_WINE_STACK_MANIFEST:-}")",
  "linuxSignature": "\$(json_escape "\${KONYAK_LINUX_WINE_STACK_SIGNATURE_URL:-}")",
  "runtimePublicKeyPath": "\$(json_escape "\${KONYAK_RUNTIME_STACK_PUBLIC_KEY_PATH:-}")",
  "linuxPublicKeyPath": "\$(json_escape "\${KONYAK_LINUX_WINE_STACK_PUBLIC_KEY_PATH:-}")"
}
JSON
EOF
chmod 755 "$work_appdir/usr/konyak"

fixture_argument="$work_root/fixture setup.exe"
APPIMAGE="$work_root/Konyak-smoke.AppImage" \
  "$work_appdir/AppRun" "$fixture_argument" >/dev/null

if [[ ! -f "$sentinel" ]]; then
  echo "AppRun smoke did not execute the app spy." >&2
  exit 1
fi

jq -e \
  --arg resources_dir "$resources_dir" \
  --arg app_executable "$work_appdir/usr/konyak" \
  --arg appimage_path "$work_root/Konyak-smoke.AppImage" \
  --arg app_icon_path "$work_appdir/app.konyak.Konyak.png" \
  --arg fixture_argument "$fixture_argument" \
  '.bundleResources == $resources_dir
    and .appExecutable == $app_executable
    and .appImagePath == $appimage_path
    and .appIconPath == $app_icon_path
    and .argumentCount == "1"
    and .firstArgument == $fixture_argument
    and .linuxManifest == ($resources_dir + "/konyak-linux-wine-runtime-stack-source.json")
    and (
      .linuxSignature == ""
      or .linuxSignature == ($resources_dir + "/konyak-linux-wine-runtime-stack-source.json.sig")
    )
    and (
      (.runtimePublicKeyPath == "" and .linuxPublicKeyPath == "")
      or (
        .runtimePublicKeyPath == ($resources_dir + "/konyak-runtime-stack-public-key.pem")
        and .linuxPublicKeyPath == ($resources_dir + "/konyak-runtime-stack-public-key.pem")
      )
    )' \
  "$sentinel" >/dev/null

echo "Linux AppImage AppRun environment smoke passed."
