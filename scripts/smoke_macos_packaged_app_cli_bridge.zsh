#!/usr/bin/env zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd -P)"
cd "$repo_root"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "macOS packaged app CLI bridge smoke is supported on macOS only." >&2
  exit 69
fi

for command in codesign cp jq open pgrep; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Missing required command: $command" >&2
    exit 69
  fi
done

default_app_bundle="${KONYAK_MACOS_PACKAGED_APP_CLI_BRIDGE_SMOKE_APP:-$repo_root/.dart_tool/konyak/release/macos/Konyak.app}"
app_bundle="${1:-$default_app_bundle}"
fixture_from_argument="${2:-}"
fixture_from_environment="${KONYAK_MACOS_PACKAGED_APP_CLI_BRIDGE_SMOKE_EXE:-}"
work_root="${KONYAK_MACOS_PACKAGED_APP_CLI_BRIDGE_SMOKE_WORK_ROOT:-$repo_root/.dart_tool/konyak/macos-packaged-app-cli-bridge-smoke/$$}"
work_app="$work_root/Konyak.app"
sentinel="$work_root/run-program-sentinel.json"
calls_log="$work_root/cli-calls.log"
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

if [[ ! -d "$app_bundle" ]]; then
  echo "Packaged Konyak.app was not found: $app_bundle" >&2
  exit 1
fi
if [[ ! -x "$app_bundle/Contents/MacOS/Konyak" ]]; then
  echo "Konyak app executable was not found: $app_bundle/Contents/MacOS/Konyak" >&2
  exit 1
fi
if [[ ! -x "$app_bundle/Contents/Resources/konyak-cli" ]]; then
  echo "Bundled konyak-cli was not found: $app_bundle/Contents/Resources/konyak-cli" >&2
  exit 1
fi
app_bundle="${app_bundle:A}"

rm -rf "$work_root"
mkdir -p "$work_root"
cp -R "$app_bundle" "$work_app"
work_app="${work_app:A}"

if [[ -n "$fixture_from_argument" ]]; then
  exe_fixture="$fixture_from_argument"
elif [[ -n "$fixture_from_environment" ]]; then
  exe_fixture="$fixture_from_environment"
else
  exe_fixture="$work_root/cli-bridge-smoke.exe"
  printf "MZ\\0\\0Konyak packaged app CLI bridge smoke fixture\n" >"$exe_fixture"
fi

if [[ ! -f "$exe_fixture" ]]; then
  echo "Packaged app CLI bridge executable fixture was not found: $exe_fixture" >&2
  exit 1
fi
exe_fixture="${exe_fixture:A}"

fake_cli="$work_app/Contents/Resources/konyak-cli"
smoke_root_quoted="$(single_quote "$work_root")"
fixture_quoted="$(single_quote "$exe_fixture")"

cat >"$fake_cli" <<EOF
#!/usr/bin/env zsh
set -euo pipefail

smoke_root=$smoke_root_quoted
fixture_path=$fixture_quoted
calls_log="\$smoke_root/cli-calls.log"
sentinel="\$smoke_root/run-program-sentinel.json"

json_escape() {
  local value="\$1"
  value="\${value//\\\\/\\\\\\\\}"
  value="\${value//\\\"/\\\\\\\"}"
  printf "%s" "\$value"
}

write_call_log() {
  {
    printf "%s" "\$0"
    for argument in "\$@"; do
      printf "\\t%s" "\$argument"
    done
    printf "\\n"
  } >>"\$calls_log"
}

write_call_log "\$@"

if [[ "\$#" -eq 2 && "\$1" == "list-bottles" && "\$2" == "--json" ]]; then
  bottle_path="\$smoke_root/bottles/smoke"
  mkdir -p "\$bottle_path"
  cat <<JSON
{"schemaVersion":1,"bottles":[{"id":"smoke","name":"Smoke","path":"\$(json_escape "\$bottle_path")","windowsVersion":"win10"}]}
JSON
  exit 0
fi

if [[ "\$#" -eq 2 && "\$1" == "get-app-settings" && "\$2" == "--json" ]]; then
  bottles_path="\$smoke_root/bottles"
  mkdir -p "\$bottles_path"
  cat <<JSON
{"schemaVersion":1,"appSettings":{"terminateWineProcessesOnClose":false,"defaultBottlePath":"\$(json_escape "\$bottles_path")","appearanceMode":"system","automaticallyCheckForKonyakUpdates":false,"automaticallyCheckForWineUpdates":false}}
JSON
  exit 0
fi

if [[ "\$#" -eq 2 && "\$1" == "list-runtimes" && "\$2" == "--json" ]]; then
  runtime_root="\$smoke_root/runtime/macos-wine"
  mkdir -p "\$runtime_root/bin" "\$runtime_root/lib"
  cat <<JSON
{"schemaVersion":1,"runtimes":[{"id":"konyak-macos-wine","name":"Konyak macOS Wine","platform":"macos","architecture":"arm64","runnerKind":"macosWine","isBundled":false,"isUpdateable":true,"isInstalled":true,"distributionKind":"managed","applicationSupportPath":"\$(json_escape "\$runtime_root")","libraryPath":"\$(json_escape "\$runtime_root/lib")","executablePath":"\$(json_escape "\$runtime_root/bin/wineloader")"}]}
JSON
  exit 0
fi

if [[ "\$#" -eq 5 && "\$1" == "run-program" && "\$2" == "smoke" && "\$3" == "--program" && "\$5" == "--json" ]]; then
  program_path="\$4"
  runtime_root="\$smoke_root/runtime/macos-wine"
  log_path="\$smoke_root/run.log"
  mkdir -p "\$runtime_root/bin"
  printf "Konyak packaged app CLI bridge smoke run log\\n" >"\$log_path"
  cat >"\$sentinel" <<JSON
{"command":"run-program","bottleId":"smoke","programPath":"\$(json_escape "\$program_path")","expectedProgramPath":"\$(json_escape "\$fixture_path")","bundleResources":"\$(json_escape "\${KONYAK_BUNDLE_RESOURCES:-}")","path":"\$(json_escape "\${PATH:-}")","pinnedLauncherExecutable":"\$(json_escape "\${KONYAK_PINNED_PROGRAM_LAUNCHER_EXECUTABLE:-}")","argv":["run-program","smoke","--program","\$(json_escape "\$program_path")","--json"]}
JSON
  cat <<JSON
{"schemaVersion":1,"run":{"bottleId":"smoke","programPath":"\$(json_escape "\$program_path")","runnerKind":"macosWine","executable":"\$(json_escape "\$runtime_root/bin/wineloader")","workingDirectory":null,"argv":["\$(json_escape "\$runtime_root/bin/wineloader")","start","/unix","\$(json_escape "\$program_path")"],"logPath":"\$(json_escape "\$log_path")","processExitCode":0}}
JSON
  exit 0
fi

cat >&2 <<JSON
{"schemaVersion":1,"error":{"code":"unexpectedSmokeCommand","message":"Unexpected packaged app CLI bridge smoke command."}}
JSON
exit 64
EOF
chmod +x "$fake_cli"

codesign --force --deep --sign - "$work_app" >/dev/null

before_pids="$(pgrep -f "$work_app/Contents/MacOS/Konyak" || true)"
/usr/bin/open \
  -n \
  -a "$work_app" \
  --env "PATH=/usr/bin:/bin" \
  --env "KONYAK_ENABLE_SMOKE_HOOKS=1" \
  --env "KONYAK_SMOKE_OPEN_EXECUTABLE_AUTO_RUN_BOTTLE_ID=smoke" \
  "$exe_fixture"

for _ in {1..80}; do
  current_pids="$(pgrep -f "$work_app/Contents/MacOS/Konyak" || true)"
  for pid in ${(f)current_pids}; do
    if [[ -z "$pid" ]]; then
      continue
    fi
    if ! grep -qx "$pid" <<<"$before_pids"; then
      app_pid="$pid"
      break
    fi
  done
  if [[ -n "$app_pid" ]]; then
    break
  fi
  sleep 0.25
done

if [[ -z "$app_pid" ]]; then
  echo "Konyak did not launch from packaged app CLI bridge smoke fixture." >&2
  exit 1
fi

for _ in {1..120}; do
  if [[ -f "$sentinel" ]]; then
    break
  fi
  sleep 0.25
done

if [[ ! -f "$sentinel" ]]; then
  echo "Konyak did not call run-program through the bundled CLI spy." >&2
  if [[ -f "$calls_log" ]]; then
    cat "$calls_log" >&2
  fi
  exit 1
fi

resources_dir="$work_app/Contents/Resources"
jq -e \
  --arg program_path "$exe_fixture" \
  --arg resources_dir "$resources_dir" \
  --arg fake_cli "$fake_cli" \
  '.command == "run-program"
    and .bottleId == "smoke"
    and .programPath == $program_path
    and .expectedProgramPath == $program_path
    and .bundleResources == $resources_dir
    and (.path | startswith($resources_dir + ":"))
    and .pinnedLauncherExecutable == $fake_cli' \
  "$sentinel" >/dev/null

echo "macOS packaged app CLI bridge smoke passed."
