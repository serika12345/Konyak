#!/usr/bin/env zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd -P)"
cli_dir="$repo_root/packages/konyak_cli"
work_root="${KONYAK_MACOS_RUNTIME_CLI_SMOKE_WORK_ROOT:-$repo_root/.dart_tool/konyak/macos-runtime-cli-smoke}"
logs_dir="$work_root/logs"
data_home="$work_root/data"
config_home="$work_root/config"
runtime_root="${KONYAK_MACOS_WINE_HOME:-$work_root/runtime/macos-wine}"
command_timeout="${KONYAK_MACOS_RUNTIME_CLI_SMOKE_COMMAND_TIMEOUT:-240s}"
install_timeout="${KONYAK_MACOS_RUNTIME_CLI_SMOKE_INSTALL_TIMEOUT:-1200s}"
install_runtime="${KONYAK_MACOS_RUNTIME_CLI_SMOKE_INSTALL:-true}"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "macOS runtime CLI smoke is supported on macOS only." >&2
  exit 2
fi

for required_command in dart jq timeout; do
  if ! command -v "$required_command" >/dev/null 2>&1; then
    echo "Missing $required_command. Run this script inside nix develop." >&2
    exit 69
  fi
done

rm -rf "$data_home" "$config_home" "$logs_dir"
mkdir -p "$data_home" "$config_home" "$logs_dir" "$runtime_root:h"

stop_wineserver() {
  local prefix_path="$data_home/bottles/ci-prefix-smoke"

  if [[ -x "$runtime_root/bin/wineserver" && -d "$prefix_path" ]]; then
    env \
      WINEPREFIX="$prefix_path" \
      DYLD_LIBRARY_PATH="$runtime_root/lib" \
      "$runtime_root/bin/wineserver" -k >/dev/null 2>&1 || true
  fi
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
      KONYAK_RUNTIME_PROFILE="${KONYAK_RUNTIME_PROFILE:-development}" \
      KONYAK_MACOS_WINE_HOME="$runtime_root" \
      KONYAK_DATA_HOME="$data_home" \
      KONYAK_CONFIG_HOME="$config_home" \
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
    jq '.' "$json_path" >&2 || sed -n '1,200p' "$json_path" >&2
    exit 1
  fi
}

assert_runtime_component_installed() {
  local component_id="$1"
  local json_path="$2"

  if ! jq -e --arg id "$component_id" '
    .runtimes[] |
      select(.id == "konyak-macos-wine") |
      .stack.components[] |
      select(
        .id == $id and
        .isInstalled == true and
        ((.missingPaths // []) | length == 0)
      )
  ' "$json_path" >/dev/null; then
    echo "Runtime component is not installed or has missing paths: $component_id" >&2
    jq '.runtimes[] | select(.id == "konyak-macos-wine") | .stack.components[] | select(.id == "'"$component_id"'")' "$json_path" >&2
    exit 1
  fi
}

assert_runtime_backend_available() {
  local backend_id="$1"
  local json_path="$2"

  if ! jq -e --arg id "$backend_id" '
    .runtimes[] |
      select(.id == "konyak-macos-wine") |
      .stack.backends[] |
      select(
        .id == $id and
        .isAvailable == true and
        ((.missingComponentIds // []) | length == 0) and
        ((.missingPaths // []) | length == 0)
      )
  ' "$json_path" >/dev/null; then
    echo "Runtime backend is not available or has missing paths: $backend_id" >&2
    jq '.runtimes[] | select(.id == "konyak-macos-wine") | .stack.backends[] | select(.id == "'"$backend_id"'")' "$json_path" >&2
    exit 1
  fi
}

manifest_path="${KONYAK_DEV_MACOS_WINE_STACK_MANIFEST:-${KONYAK_MACOS_WINE_STACK_MANIFEST:-}}"
if [[ -z "$manifest_path" ]]; then
  manifest_path="$("$repo_root/scripts/prepare_macos_dev_runtime_stack.zsh" --force --print-manifest-path)"
fi

if [[ "$install_runtime" == "true" ]]; then
  run_cli_capture install-macos-wine "$install_timeout" \
    install-macos-wine \
    --reinstall \
    --source-manifest "$manifest_path" \
    --progress-json \
    --json

  install_json="$logs_dir/install-macos-wine.final.json"
  write_last_json_line "$captured_stdout_path" "$install_json"
  assert_jq "$install_json" \
    "install-macos-wine did not report an installed macOS runtime." \
    '
    .schemaVersion == 1 and
    .runtime.id == "konyak-macos-wine" and
    .runtime.isInstalled == true
  '
else
  echo "Skipping runtime install because KONYAK_MACOS_RUNTIME_CLI_SMOKE_INSTALL=false." >&2
fi

run_cli_capture list-runtimes "$command_timeout" list-runtimes --json
list_runtimes_json="$captured_stdout_path"
assert_jq "$list_runtimes_json" \
  "list-runtimes did not report a complete Konyak macOS Wine runtime." \
  --arg runtimeRoot "$runtime_root" \
  '
    .schemaVersion == 1 and
    (
      .runtimes[] |
        select(.id == "konyak-macos-wine") |
        .isInstalled == true and
        .libraryPath == $runtimeRoot and
        .stack.isComplete == true
    )
  '

for component_id in \
  wine \
  wine32on64 \
  dxvk-macos \
  moltenvk \
  gstreamer \
  freetype \
  wine-mono \
  wine-gecko \
  winetricks \
  vkd3d \
  dxmt
do
  assert_runtime_component_installed "$component_id" "$list_runtimes_json"
done

for backend_id in dxvk-macos dxmt vkd3d; do
  assert_runtime_backend_available "$backend_id" "$list_runtimes_json"
done

run_cli_capture validate-runtime "$command_timeout" validate-runtime konyak-macos-wine --json
validate_runtime_json="$captured_stdout_path"
assert_jq "$validate_runtime_json" \
  "validate-runtime did not report a valid Konyak macOS Wine runtime." \
  '
  .schemaVersion == 1 and
  .runtimeValidation.runtimeId == "konyak-macos-wine" and
  .runtimeValidation.isValid == true
'

run_cli_capture create-bottle "$command_timeout" create-bottle --name "CI Prefix Smoke" --json
create_bottle_json="$captured_stdout_path"
assert_jq "$create_bottle_json" \
  "create-bottle did not report the expected prefix smoke bottle." \
  --arg dataHome "$data_home" \
  '
    .schemaVersion == 1 and
    .bottle.id == "ci-prefix-smoke" and
    .bottle.path == ($dataHome + "/bottles/ci-prefix-smoke")
  '

echo "macOS runtime CLI smoke passed."
