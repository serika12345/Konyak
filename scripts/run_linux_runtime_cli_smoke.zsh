#!/usr/bin/env zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd -P)"
cli_dir="$repo_root/packages/konyak_cli"
work_root="${KONYAK_LINUX_RUNTIME_CLI_SMOKE_WORK_ROOT:-$repo_root/.dart_tool/konyak/linux-runtime-cli-smoke}"
logs_dir="$work_root/logs"
data_home="$work_root/data"
config_home="$work_root/config"
runtime_root="${KONYAK_LINUX_WINE_HOME:-$work_root/runtime/linux-wine}"
manifest_cache="$work_root/runtime-source/konyak-linux-wine-runtime-stack-source.json"
command_timeout="${KONYAK_LINUX_RUNTIME_CLI_SMOKE_COMMAND_TIMEOUT:-240s}"
install_timeout="${KONYAK_LINUX_RUNTIME_CLI_SMOKE_INSTALL_TIMEOUT:-1200s}"
install_runtime="${KONYAK_LINUX_RUNTIME_CLI_SMOKE_INSTALL:-true}"
run_winetricks_smoke="${KONYAK_LINUX_RUNTIME_CLI_SMOKE_WINETRICKS:-true}"

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "Linux runtime CLI smoke is supported on Linux only." >&2
  exit 2
fi

for required_command in dart jq timeout; do
  if ! command -v "$required_command" >/dev/null 2>&1; then
    echo "Missing $required_command. Run this script inside nix develop." >&2
    exit 69
  fi
done

rm -rf "$data_home" "$config_home" "$logs_dir"
mkdir -p "$data_home" "$config_home" "$logs_dir" "$runtime_root:h" "$manifest_cache:h"

stop_wineserver() {
  local prefix_path

  if [[ ! -x "$runtime_root/bin/wineserver" ]]; then
    return
  fi

  for prefix_path in "$data_home"/bottles/*(N); do
    env \
      WINEPREFIX="$prefix_path" \
      PATH="$runtime_root/bin:${PATH:-/usr/bin:/bin}" \
      "$runtime_root/bin/wineserver" -k >/dev/null 2>&1 || true
  done
}

trap stop_wineserver EXIT

captured_stdout_path=""
captured_stderr_path=""

run_cli_capture() {
  local label="$1"
  local timeout_value="$2"
  shift 2

  captured_stdout_path="$logs_dir/$label.stdout"
  captured_stderr_path="$logs_dir/$label.stderr"

  echo "Running konyak $*" >&2
  set +e
  (
    cd "$cli_dir"
    env \
      KONYAK_RUNTIME_PROFILE=development \
      KONYAK_LINUX_WINE_HOME="$runtime_root" \
      KONYAK_DATA_HOME="$data_home" \
      KONYAK_CONFIG_HOME="$config_home" \
      KONYAK_DEV_LINUX_WINE_STACK_MANIFEST="${manifest_path:-}" \
      timeout "$timeout_value" dart run bin/konyak.dart "$@"
  ) >"$captured_stdout_path" 2>"$captured_stderr_path"
  local exit_code=$?
  set -e

  if [[ -s "$captured_stderr_path" ]]; then
    sed -n '1,200p' "$captured_stderr_path" >&2
  fi

  if [[ "$exit_code" -ne 0 ]]; then
    echo "konyak $* failed with exit code $exit_code" >&2
    if [[ -s "$captured_stdout_path" ]]; then
      echo "----- stdout -----" >&2
      sed -n '1,200p' "$captured_stdout_path" >&2
    fi
    if [[ -s "$captured_stderr_path" ]]; then
      echo "----- stderr -----" >&2
      sed -n '1,200p' "$captured_stderr_path" >&2
    fi
    exit "$exit_code"
  fi
}

write_last_json_line() {
  local source_path="$1"
  local target_path="$2"

  sed '/^[[:space:]]*$/d' "$source_path" | tail -n 1 >"$target_path"
  if [[ ! -s "$target_path" ]]; then
    echo "No JSON output captured in $source_path" >&2
    exit 1
  fi
}

assert_jq() {
  local json_path="$1"
  local message="$2"
  shift 2

  if ! jq -e "$@" "$json_path" >/dev/null; then
    echo "$message" >&2
    jq "." "$json_path" >&2 || sed -n '1,200p' "$json_path" >&2
    exit 1
  fi
}

assert_runtime_component_installed() {
  local component_id="$1"
  local json_path="$2"

  if ! jq -e --arg id "$component_id" '
    .runtimes[] |
      select(.id == "konyak-linux-wine") |
      .stack.components[] |
      select(
        .id == $id and
        .isInstalled == true and
        ((.missingPaths // []) | length == 0)
      )
  ' "$json_path" >/dev/null; then
    echo "Runtime component is not installed or has missing paths: $component_id" >&2
    jq '.runtimes[] | select(.id == "konyak-linux-wine") | .stack.components[] | select(.id == "'"$component_id"'")' "$json_path" >&2
    exit 1
  fi
}

assert_runtime_backend_available() {
  local backend_id="$1"
  local json_path="$2"

  if ! jq -e --arg id "$backend_id" '
    .runtimes[] |
      select(.id == "konyak-linux-wine") |
      .stack.backends[] |
      select(
        .id == $id and
        .isAvailable == true and
        ((.missingComponentIds // []) | length == 0) and
        ((.missingPaths // []) | length == 0)
      )
  ' "$json_path" >/dev/null; then
    echo "Runtime backend is not available or has missing inputs: $backend_id" >&2
    jq '.runtimes[] | select(.id == "konyak-linux-wine") | .stack.backends[] | select(.id == "'"$backend_id"'")' "$json_path" >&2
    exit 1
  fi
}

manifest_path="${KONYAK_DEV_LINUX_WINE_STACK_MANIFEST:-${KONYAK_LINUX_WINE_STACK_MANIFEST:-}}"
if [[ -z "$manifest_path" ]]; then
  manifest_path="$("$repo_root/scripts/prepare_linux_dev_runtime_source.zsh" \
    --force \
    --print-manifest-path)"
elif [[ "$manifest_path" == http://* || "$manifest_path" == https://* ]]; then
  manifest_path="$(
    KONYAK_DEV_LINUX_WINE_STACK_SOURCE_MANIFEST="$manifest_path" \
      KONYAK_DEV_LINUX_WINE_STACK_MANIFEST_CACHE="$manifest_cache" \
      "$repo_root/scripts/prepare_linux_dev_runtime_source.zsh" \
        --force \
        --print-manifest-path
  )"
fi

if [[ "$install_runtime" == "true" ]]; then
  run_cli_capture install-linux-wine "$install_timeout" \
    install-linux-wine \
    --reinstall \
    --source-manifest "$manifest_path" \
    --progress-json \
    --json

  install_json="$logs_dir/install-linux-wine.final.json"
  write_last_json_line "$captured_stdout_path" "$install_json"
  assert_jq "$install_json" \
    "install-linux-wine did not report an installed Linux runtime." \
    '
    .schemaVersion == 1 and
    .runtime.id == "konyak-linux-wine" and
    .runtime.isInstalled == true
  '
else
  echo "Skipping runtime install because KONYAK_LINUX_RUNTIME_CLI_SMOKE_INSTALL=false." >&2
fi

run_cli_capture list-runtimes "$command_timeout" list-runtimes --json
list_runtimes_json="$captured_stdout_path"
assert_jq "$list_runtimes_json" \
  "list-runtimes did not report a complete Konyak Linux Wine runtime." \
  --arg runtimeRoot "$runtime_root" \
  '
    .schemaVersion == 1 and
    (
      .runtimes[] |
        select(.id == "konyak-linux-wine") |
        .isInstalled == true and
        .libraryPath == $runtimeRoot and
        .stack.isComplete == true
    )
  '

for component_id in \
  wine \
  winetricks \
  wine-mono \
  dxvk \
  vkd3d-proton
do
  assert_runtime_component_installed "$component_id" "$list_runtimes_json"
done

for backend_id in dxvk vkd3d-proton; do
  assert_runtime_backend_available "$backend_id" "$list_runtimes_json"
done

run_cli_capture validate-runtime "$command_timeout" validate-runtime konyak-linux-wine --json
validate_runtime_json="$captured_stdout_path"
assert_jq "$validate_runtime_json" \
  "validate-runtime did not report a valid Konyak Linux Wine runtime." \
  '
  .schemaVersion == 1 and
  .runtimeValidation.runtimeId == "konyak-linux-wine" and
  .runtimeValidation.isValid == true
'

run_cli_capture create-bottle "$command_timeout" create-bottle --name "CI Prefix Smoke" --json
create_bottle_json="$captured_stdout_path"
assert_jq "$create_bottle_json" \
  "create-bottle did not report the expected Linux prefix smoke bottle." \
  --arg dataHome "$data_home" \
  '
    .schemaVersion == 1 and
    .bottle.id == "ci-prefix-smoke" and
    .bottle.path == ($dataHome + "/bottles/ci-prefix-smoke")
  '

if [[ "$run_winetricks_smoke" == "true" ]]; then
  run_cli_capture list-winetricks-verbs "$command_timeout" list-winetricks-verbs --json
  list_winetricks_verbs_json="$captured_stdout_path"
  assert_jq "$list_winetricks_verbs_json" \
    "list-winetricks-verbs did not return the managed Linux runtime verb catalog." \
    '
      .schemaVersion == 1 and
      any(.winetricks.categories[]?.verbs[]?; .name == "win10")
    '

  run_cli_capture run-winetricks "$command_timeout" run-winetricks ci-prefix-smoke --verb win10 --json
  run_winetricks_json="$captured_stdout_path"
  assert_jq "$run_winetricks_json" \
    "run-winetricks did not complete through the published Linux runtime." \
    '
      .schemaVersion == 1 and
      .run.bottleId == "ci-prefix-smoke" and
      .run.runnerKind == "winetricks" and
      .run.programPath == "win10" and
      .run.processExitCode == 0
    '
else
  echo "Skipping winetricks smoke because KONYAK_LINUX_RUNTIME_CLI_SMOKE_WINETRICKS=false." >&2
fi

echo "Linux runtime CLI smoke passed."
