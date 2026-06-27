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
d3d11_sample_builder="$repo_root/scripts/build_d3d11_probe_exe.zsh"
visible_sample_wait_seconds="${KONYAK_MACOS_RUNTIME_CLI_SMOKE_VISIBLE_SAMPLE_WAIT_SECONDS:-${KONYAK_MACOS_RUNTIME_CLI_SMOKE_BACKEND_PROBE_WAIT_SECONDS:-120}}"
d3d11_sample_exe=""
d3d12_sample_exe="${KONYAK_MACOS_RUNTIME_CLI_SMOKE_D3D12_SAMPLE_EXE:-}"

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
  local prefix_path

  if [[ ! -x "$runtime_root/bin/wineserver" ]]; then
    return
  fi

  for prefix_path in "$data_home"/bottles/*(N); do
    env \
      WINEPREFIX="$prefix_path" \
      DYLD_LIBRARY_PATH="$runtime_root/lib" \
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

build_visible_graphics_sample_executables() {
  if [[ ! -x "$d3d11_sample_builder" ]]; then
    echo "Missing D3D11 visible sample builder: $d3d11_sample_builder" >&2
    exit 69
  fi

  d3d11_sample_exe="$("$d3d11_sample_builder")"
  if [[ ! -f "$d3d11_sample_exe" ]]; then
    echo "D3D11 visible sample builder did not produce $d3d11_sample_exe" >&2
    exit 1
  fi
}

runtime_settings_json_for_backend() {
  local backend_id="$1"
  local dxr=false
  local dxvk=false
  local dxmt=false

  case "$backend_id" in
    d3dmetal)
      dxr=true
      ;;
    dxvk-macos)
      dxvk=true
      ;;
    dxmt)
      dxmt=true
      ;;
    vkd3d)
      ;;
    *)
      echo "Unknown visible graphics sample backend id: $backend_id" >&2
      exit 1
      ;;
  esac

  cat <<JSON
{
  "enhancedSync": "msync",
  "metalHud": false,
  "metalTrace": false,
  "avxEnabled": false,
  "dxrEnabled": $dxr,
  "dxvk": $dxvk,
  "dxmt": $dxmt,
  "dlssMetalFx": false,
  "dxvkAsync": false,
  "dxvkHud": "off",
  "vkd3dProton": false,
  "buildVersion": 0,
  "retinaMode": false,
  "dpiScaling": 96
}
JSON
}

wait_for_visible_sample_sentinel() {
  local sentinel_path="$1"
  local marker="$2"
  local waited_seconds=0

  while (( waited_seconds < visible_sample_wait_seconds )); do
    if [[ -f "$sentinel_path" ]] && grep -q "$marker" "$sentinel_path"; then
      return
    fi

    sleep 1
    waited_seconds=$((waited_seconds + 1))
  done

  echo "Visible graphics sample sentinel was not written within ${visible_sample_wait_seconds}s: $sentinel_path" >&2
  echo "Expected marker: $marker" >&2
  if [[ -f "$sentinel_path" ]]; then
    echo "----- $sentinel_path -----" >&2
    sed -n '1,80p' "$sentinel_path" >&2
  fi
  exit 1
}

run_visible_graphics_sample_smoke() {
  local backend_id="$1"
  local bottle_name="$2"
  local bottle_id="$3"
  local sample_path="$4"
  local success_marker="$5"
  local sentinel_file_name="$6"
  local run_settings_json="$7"
  local settings_json
  local settings_assertion
  local sentinel_path="$data_home/bottles/$bottle_id/drive_c/$sentinel_file_name"

  case "$backend_id" in
    dxvk-macos)
      settings_assertion='.bottle.runtimeSettings.dxvk == true and .bottle.runtimeSettings.dxmt == false and .bottle.runtimeSettings.dxrEnabled == false'
      ;;
    dxmt)
      settings_assertion='.bottle.runtimeSettings.dxvk == false and .bottle.runtimeSettings.dxmt == true and .bottle.runtimeSettings.dxrEnabled == false'
      ;;
    d3dmetal)
      settings_assertion='.bottle.runtimeSettings.dxvk == false and .bottle.runtimeSettings.dxmt == false and .bottle.runtimeSettings.dxrEnabled == true'
      ;;
    vkd3d)
      settings_assertion='.bottle.runtimeSettings.dxvk == false and .bottle.runtimeSettings.dxmt == false and .bottle.runtimeSettings.dxrEnabled == false'
      ;;
    *)
      echo "Unknown visible graphics sample backend id: $backend_id" >&2
      exit 1
      ;;
  esac
  if [[ ! -f "$sample_path" ]]; then
    echo "Visible graphics sample executable does not exist: $sample_path" >&2
    exit 66
  fi

  run_cli_capture "create-$bottle_id" "$command_timeout" \
    create-bottle \
    --name "$bottle_name" \
    --json
  local create_json="$captured_stdout_path"
  assert_jq "$create_json" \
    "create-bottle did not report the expected visible graphics sample bottle: $bottle_id" \
    --arg dataHome "$data_home" \
    --arg bottleId "$bottle_id" \
    '
      .schemaVersion == 1 and
      .bottle.id == $bottleId and
      .bottle.path == ($dataHome + "/bottles/" + $bottleId)
    '

  settings_json="$(runtime_settings_json_for_backend "$backend_id")"
  run_cli_capture "set-runtime-settings-$bottle_id" "$command_timeout" \
    set-runtime-settings \
    "$bottle_id" \
    --settings-json "$settings_json" \
    --json
  local settings_json_path="$captured_stdout_path"
  assert_jq "$settings_json_path" \
    "set-runtime-settings did not select the expected backend for $bottle_id." \
    --arg bottleId "$bottle_id" \
    "
      .schemaVersion == 1 and
      .bottle.id == \$bottleId and
      ($settings_assertion)
    "

  run_cli_capture "run-$bottle_id" "$command_timeout" \
    run-program \
    "$bottle_id" \
    --program "$sample_path" \
    --settings-json "$run_settings_json" \
    --json
  local run_json="$captured_stdout_path"
  assert_jq "$run_json" \
    "run-program did not complete the $backend_id visible graphics sample through macOS Wine." \
    --arg bottleId "$bottle_id" \
    --arg programPath "$sample_path" \
    '
      .schemaVersion == 1 and
      .run.bottleId == $bottleId and
      .run.runnerKind == "macosWine" and
      .run.programPath == $programPath and
      .run.processExitCode == 0
    '

  wait_for_visible_sample_sentinel "$sentinel_path" "$success_marker"
}

macos_d3dmetal_available() {
  [[ -f "$runtime_root/components/gptk-d3dmetal/lib/external/libd3dshared.dylib" ]] &&
    [[ -d "$runtime_root/components/gptk-d3dmetal/lib/external/D3DMetal.framework" ]] &&
    [[ -f "$runtime_root/components/gptk-d3dmetal/lib/wine/x86_64-windows/d3d12.dll" ]] &&
    [[ -e "$runtime_root/components/gptk-d3dmetal/lib/wine/x86_64-unix/d3d12.so" ]] &&
    [[ -f "$runtime_root/components/gptk-d3dmetal/lib/wine/x86_64-windows/dxgi.dll" ]] &&
    [[ -e "$runtime_root/components/gptk-d3dmetal/lib/wine/x86_64-unix/dxgi.so" ]]
}

run_d3d12_sample_smoke() {
  local sample_path="$1"
  local backend_id="vkd3d"

  if [[ -z "$sample_path" ]]; then
    return
  fi

  if macos_d3dmetal_available; then
    backend_id="d3dmetal"
  fi
  echo "D3D12 visible sample backend: $backend_id" >&2

  run_visible_graphics_sample_smoke \
    "$backend_id" \
    "D3D12 MSVC Visible Sample" \
    d3d12-msvc-visible-sample \
    "$sample_path" \
    KONYAK_D3D12_MINIMAL_SAMPLE_OK \
    konyak-d3d12-minimal-sample-ok.txt \
    '{"arguments":"--frames 120","environment":{}}'
}

manifest_path="${KONYAK_DEV_MACOS_WINE_STACK_MANIFEST:-${KONYAK_MACOS_WINE_STACK_MANIFEST:-}}"
if [[ -z "$manifest_path" ]]; then
  manifest_path="$("$repo_root/scripts/prepare_macos_dev_runtime_stack.zsh" --force --print-manifest-path)"
fi

build_visible_graphics_sample_executables

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

run_cli_capture list-winetricks-verbs "$command_timeout" list-winetricks-verbs --json
list_winetricks_verbs_json="$captured_stdout_path"
assert_jq "$list_winetricks_verbs_json" \
  "list-winetricks-verbs did not return the managed runtime verb catalog." \
  '
    .schemaVersion == 1 and
    any(.winetricks.categories[]?.verbs[]?; .name == "win10")
  '

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

run_cli_capture run-winetricks "$command_timeout" run-winetricks ci-prefix-smoke --verb win10 --json
run_winetricks_json="$captured_stdout_path"
assert_jq "$run_winetricks_json" \
  "run-winetricks did not complete through the published macOS runtime." \
  '
    .schemaVersion == 1 and
    .run.bottleId == "ci-prefix-smoke" and
    .run.runnerKind == "macosWinetricks" and
    .run.programPath == "win10" and
    .run.processExitCode == 0
  '

run_visible_graphics_sample_smoke \
  dxvk-macos \
  "DXVK macOS Visible Sample" \
  dxvk-macos-visible-sample \
  "$d3d11_sample_exe" \
  KONYAK_D3D11_PROBE_OK \
  konyak-d3d11-visible-sample-ok.txt \
  '{"arguments":"","environment":{"KONYAK_D3D11_PROBE_HOLD_MS":"3000"}}'

run_visible_graphics_sample_smoke \
  dxmt \
  "DXMT Visible Sample" \
  dxmt-visible-sample \
  "$d3d11_sample_exe" \
  KONYAK_D3D11_PROBE_OK \
  konyak-d3d11-visible-sample-ok.txt \
  '{"arguments":"","environment":{"KONYAK_D3D11_PROBE_HOLD_MS":"3000"}}'

run_d3d12_sample_smoke "$d3d12_sample_exe"

echo "macOS runtime CLI smoke passed."
