#!/usr/bin/env zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd -P)"
cd "$repo_root"

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "Linux pinned launcher smoke is supported on Linux only." >&2
  exit 69
fi

for command in cat chmod dart grep jq; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Missing required command: $command" >&2
    exit 69
  fi
done

work_root="${KONYAK_LINUX_PINNED_LAUNCHER_SMOKE_WORK_ROOT:-$repo_root/.dart_tool/konyak/linux-pinned-launcher-smoke/$$}"
xdg_data_home="$work_root/xdg-data"
xdg_config_home="$work_root/xdg-config"
home_dir="$work_root/home"
fake_cli="$work_root/fake-konyak-cli"
fake_runtime="$work_root/fake-linux-runtime"
fake_runtime_bin="$fake_runtime/bin"
sentinel="$work_root/launcher-call.json"
program_path="$work_root/Smoke App.exe"

single_quote() {
  local value="$1"
  printf "'%s'" "${value//\'/\'\\\'\'}"
}

rm -rf "$work_root"
mkdir -p "$work_root" "$home_dir" "$fake_runtime_bin"
touch "$program_path"

for runtime_command in wine wineboot wineserver winedbg; do
  cat >"$fake_runtime_bin/$runtime_command" <<'EOF'
#!/usr/bin/env sh
exit 0
EOF
  chmod 755 "$fake_runtime_bin/$runtime_command"
done

sentinel_quoted="$(single_quote "$sentinel")"
cat >"$fake_cli" <<EOF
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
  "argumentCount": "\$#",
  "firstArgument": "\$(json_escape "\${1:-}")",
  "secondArgument": "\$(json_escape "\${2:-}")",
  "thirdArgument": "\$(json_escape "\${3:-}")",
  "fourthArgument": "\$(json_escape "\${4:-}")"
}
JSON
EOF
chmod 755 "$fake_cli"

cli_env=(
  HOME="$home_dir"
  XDG_DATA_HOME="$xdg_data_home"
  XDG_CONFIG_HOME="$xdg_config_home"
  KONYAK_LINUX_WINE_HOME="$fake_runtime"
  KONYAK_PINNED_PROGRAM_LAUNCHER_EXECUTABLE="$fake_cli"
  KONYAK_PINNED_PROGRAM_LAUNCHER_ARGUMENTS_JSON="[]"
)

run_cli_json() {
  local output_path="$1"
  shift

  (
    cd packages/konyak_cli
    if ! env "${cli_env[@]}" dart run bin/konyak.dart "$@" >"$output_path"; then
      cat "$output_path" >&2
      return 1
    fi
  )
}

run_cli_json "$work_root/create-bottle.json" \
  create-bottle \
  --name Smoke \
  --json
run_cli_json "$work_root/pin-program.json" \
  pin-program smoke \
  --name "Smoke App" \
  --program "$program_path" \
  --json

desktop_entries=("$xdg_data_home"/applications/app.konyak.Konyak.pinned.*.desktop(N))
if (( ${#desktop_entries[@]} != 1 )); then
  echo "Expected exactly one Linux pinned launcher desktop entry." >&2
  printf 'Found: %s\n' "${desktop_entries[@]:-<none>}" >&2
  exit 1
fi
desktop_entry="${desktop_entries[1]}"

if ! grep -qx 'Type=Application' "$desktop_entry"; then
  echo "Pinned launcher desktop entry is missing Type=Application." >&2
  exit 1
fi
if ! grep -qx 'Name=Smoke App' "$desktop_entry"; then
  echo "Pinned launcher desktop entry has the wrong Name." >&2
  exit 1
fi
if grep -qx 'NoDisplay=true' "$desktop_entry"; then
  echo "Pinned launcher desktop entry must be visible." >&2
  exit 1
fi

manifests=("$xdg_data_home"/konyak/launchers/linux-pinned/*/konyak-launcher.json(N))
if (( ${#manifests[@]} != 1 )); then
  echo "Expected exactly one Linux pinned launcher manifest." >&2
  printf 'Found: %s\n' "${manifests[@]:-<none>}" >&2
  exit 1
fi
manifest="${manifests[1]}"
launcher_script="${manifest:h}/launch"
if [[ ! -x "$launcher_script" ]]; then
  echo "Pinned launcher script is not executable: $launcher_script" >&2
  exit 1
fi

jq -e \
  --arg program_path "$program_path" \
  '.schemaVersion == 1
    and .createdBy == "app.konyak.Konyak"
    and .bottleId == "smoke"
    and .programName == "Smoke App"
    and .programPath == $program_path
    and (.launcherId | type == "string" and length > 0)' \
  "$manifest" >/dev/null

"$launcher_script" >/dev/null
if [[ ! -f "$sentinel" ]]; then
  echo "Pinned launcher script did not invoke the configured CLI." >&2
  exit 1
fi

jq -e \
  --arg manifest "$manifest" \
  '.argumentCount == "4"
    and .firstArgument == "launch-pinned-program"
    and .secondArgument == "--manifest"
    and .thirdArgument == $manifest
    and .fourthArgument == "--json"' \
  "$sentinel" >/dev/null

run_cli_json "$work_root/unpin-program.json" \
  unpin-program smoke \
  --program "$program_path" \
  --json

remaining_desktop_entries=("$xdg_data_home"/applications/app.konyak.Konyak.pinned.*.desktop(N))
remaining_manifests=("$xdg_data_home"/konyak/launchers/linux-pinned/*/konyak-launcher.json(N))
if (( ${#remaining_desktop_entries[@]} != 0 || ${#remaining_manifests[@]} != 0 )); then
  echo "Pinned launcher files were not removed after unpin." >&2
  exit 1
fi

echo "Linux pinned launcher integration smoke passed."
