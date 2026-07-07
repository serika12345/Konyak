#!/usr/bin/env zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd -P)"
cli_dir="$repo_root/packages/konyak_cli"
work_root="${KONYAK_MACOS_DLSS_METALFX_SMOKE_WORK_ROOT:-$repo_root/.dart_tool/konyak/macos-dlss-metalfx-smoke}"
logs_dir="$work_root/logs"
data_home="$work_root/data"
config_home="$work_root/config"
runtime_root="${KONYAK_MACOS_WINE_HOME:-$work_root/runtime/macos-wine}"
command_timeout="${KONYAK_MACOS_DLSS_METALFX_SMOKE_COMMAND_TIMEOUT:-300s}"
install_timeout="${KONYAK_MACOS_DLSS_METALFX_SMOKE_INSTALL_TIMEOUT:-1200s}"
install_runtime="${KONYAK_MACOS_DLSS_METALFX_SMOKE_INSTALL:-true}"
import_gptk="${KONYAK_MACOS_DLSS_METALFX_SMOKE_IMPORT_GPTK:-true}"
gptk_source="${KONYAK_MACOS_DLSS_METALFX_SMOKE_GPTK_SOURCE:-${KONYAK_GPTK_D3DMETAL_CI_SOURCE_PATH:-}}"
gptk_version="${KONYAK_MACOS_DLSS_METALFX_SMOKE_GPTK_VERSION:-auto}"
program_exe="${KONYAK_MACOS_DLSS_METALFX_SMOKE_PROGRAM_EXE:-}"
program_arguments="${KONYAK_MACOS_DLSS_METALFX_SMOKE_ARGUMENTS:---frames 180 --require-metalfx-env --require-nv-shims}"
sentinel_file_name="${KONYAK_MACOS_DLSS_METALFX_SMOKE_SENTINEL_FILE:-konyak-dlss-metalfx-preflight-ok.txt}"
sentinel_marker="${KONYAK_MACOS_DLSS_METALFX_SMOKE_SENTINEL_MARKER:-KONYAK_DLSS_METALFX_PREFLIGHT_OK}"
expected_exit_code="${KONYAK_MACOS_DLSS_METALFX_SMOKE_EXPECTED_EXIT_CODE:-0}"
allow_unsupported_host="${KONYAK_MACOS_DLSS_METALFX_SMOKE_ALLOW_UNSUPPORTED_HOST:-false}"
wine_debug_channels="${KONYAK_MACOS_DLSS_METALFX_SMOKE_WINEDEBUG:-+loaddll}"
visible_wait_seconds="${KONYAK_MACOS_DLSS_METALFX_SMOKE_WAIT_SECONDS:-180}"
bottle_id="dlss-metalfx-smoke"
sentinel_windows_path="C:\\$sentinel_file_name"
evidence_windows_path="C:\\konyak-dlss-metalfx-preflight-evidence.txt"
sentinel_host_path="$data_home/bottles/$bottle_id/drive_c/$sentinel_file_name"
evidence_host_path="$data_home/bottles/$bottle_id/drive_c/konyak-dlss-metalfx-preflight-evidence.txt"
wine_log_path="$logs_dir/dlss-metalfx-run.cxlog"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "DLSS/MetalFX CLI smoke is supported on macOS only." >&2
  exit 2
fi

for required_command in dart jq sw_vers timeout; do
  if ! command -v "$required_command" >/dev/null 2>&1; then
    echo "Missing $required_command. Run this script inside nix develop." >&2
    exit 69
  fi
done

if [[ -z "$program_exe" ]]; then
  echo "Set KONYAK_MACOS_DLSS_METALFX_SMOKE_PROGRAM_EXE to a DLSS-capable Windows executable or the Konyak DLSS/MetalFX preflight fixture." >&2
  exit 64
fi

if [[ ! -f "$program_exe" ]]; then
  echo "DLSS/MetalFX smoke program does not exist: $program_exe" >&2
  exit 66
fi

if [[ "$import_gptk" == "true" && -z "$gptk_source" ]]; then
  echo "Set KONYAK_MACOS_DLSS_METALFX_SMOKE_GPTK_SOURCE or KONYAK_GPTK_D3DMETAL_CI_SOURCE_PATH to a user-provided GPTK/D3DMetal source." >&2
  exit 64
fi

macos_version="$(sw_vers -productVersion)"
macos_major="${macos_version%%.*}"
if (( macos_major < 16 )) && [[ "$allow_unsupported_host" != "true" ]]; then
  echo "DLSS powered by MetalFX requires Konyak's macOS 16+ D3DMetal gate; host reports macOS $macos_major." >&2
  echo "Set KONYAK_MACOS_DLSS_METALFX_SMOKE_ALLOW_UNSUPPORTED_HOST=true only for harness diagnostics that do not claim DLSS/MetalFX proof." >&2
  exit 77
fi

prepare_cli_package() {
  (
    cd "$cli_dir"
    dart pub get
    dart run build_runner build
  )
}

prepare_cli_package

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

wait_for_sentinel() {
  local waited_seconds=0

  while (( waited_seconds < visible_wait_seconds )); do
    if [[ -f "$sentinel_host_path" ]] &&
      grep -q "$sentinel_marker" "$sentinel_host_path"; then
      return
    fi

    sleep 1
    waited_seconds=$((waited_seconds + 1))
  done

  echo "DLSS/MetalFX smoke sentinel was not written within ${visible_wait_seconds}s: $sentinel_host_path" >&2
  echo "Expected marker: $sentinel_marker" >&2
  if [[ -f "$sentinel_host_path" ]]; then
    echo "----- $sentinel_host_path -----" >&2
    sed -n '1,120p' "$sentinel_host_path" >&2
  fi
  if [[ -f "$evidence_host_path" ]]; then
    echo "----- $evidence_host_path -----" >&2
    sed -n '1,160p' "$evidence_host_path" >&2
    cp "$evidence_host_path" "$logs_dir/preflight-evidence.txt"
  fi
  exit 1
}

assert_gptk_paths() {
  local missing=0
  local required_path

  for required_path in \
    "$runtime_root/components/gptk-d3dmetal/lib/external/libd3dshared.dylib" \
    "$runtime_root/components/gptk-d3dmetal/lib/external/D3DMetal.framework" \
    "$runtime_root/components/gptk-d3dmetal/lib/wine/x86_64-windows/d3d12.dll" \
    "$runtime_root/components/gptk-d3dmetal/lib/wine/x86_64-windows/dxgi.dll" \
    "$runtime_root/components/gptk-d3dmetal/lib/wine/x86_64-windows/nvapi64.dll" \
    "$runtime_root/components/gptk-d3dmetal/lib/wine/x86_64-windows/nvngx.dll" \
    "$runtime_root/components/gptk-d3dmetal/lib/wine/x86_64-unix/d3d12.so" \
    "$runtime_root/components/gptk-d3dmetal/lib/wine/x86_64-unix/dxgi.so" \
    "$runtime_root/components/gptk-d3dmetal/lib/wine/x86_64-unix/nvapi64.so" \
    "$runtime_root/components/gptk-d3dmetal/lib/wine/x86_64-unix/nvngx.so"
  do
    if [[ ! -e "$required_path" ]]; then
      echo "Missing GPTK/D3DMetal path: $required_path" >&2
      missing=1
    fi
  done

  if [[ "$missing" -ne 0 ]]; then
    exit 1
  fi

  {
    echo "runtime_root=$runtime_root"
    echo "program_exe=$program_exe"
    echo "gptk_source=$gptk_source"
    echo "component_root=$runtime_root/components/gptk-d3dmetal"
    echo "libd3dshared=$runtime_root/components/gptk-d3dmetal/lib/external/libd3dshared.dylib"
    echo "d3dmetal_framework=$runtime_root/components/gptk-d3dmetal/lib/external/D3DMetal.framework"
    echo "nvngx_windows=$runtime_root/components/gptk-d3dmetal/lib/wine/x86_64-windows/nvngx.dll"
    echo "nvapi64_windows=$runtime_root/components/gptk-d3dmetal/lib/wine/x86_64-windows/nvapi64.dll"
  } >"$logs_dir/runtime-paths.txt"
}

runtime_settings_json="$logs_dir/runtime-settings.json"
program_settings_json="$logs_dir/program-settings.json"

cat >"$runtime_settings_json" <<JSON
{
  "enhancedSync": "msync",
  "metalHud": true,
  "metalTrace": false,
  "avxEnabled": true,
  "dxrEnabled": true,
  "dxvk": false,
  "dxmt": false,
  "dlssMetalFx": true,
  "dxvkAsync": false,
  "dxvkHud": "off",
  "vkd3dProton": false,
  "buildVersion": 0,
  "retinaMode": false,
  "dpiScaling": 96
}
JSON

jq -n \
  --arg arguments "$program_arguments" \
  --arg logFile "$wine_log_path" \
  --arg channels "$wine_debug_channels" \
  '{
    arguments: $arguments,
    environment: {},
    logging: {
      createLogFile: true,
      additionalWineLoggingChannels: $channels,
      logFilePath: $logFile
    }
  }' >"$program_settings_json"

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
  echo "Skipping runtime install because KONYAK_MACOS_DLSS_METALFX_SMOKE_INSTALL=false." >&2
fi

if [[ "$import_gptk" == "true" ]]; then
  gptk_version_args=()
  if [[ "$gptk_version" != "auto" ]]; then
    gptk_version_args=(--gptk-version "$gptk_version")
  fi

  run_cli_capture install-gptk-wine "$install_timeout" \
    install-gptk-wine \
    --from "$gptk_source" \
    "${gptk_version_args[@]}" \
    --json

  install_gptk_json="$captured_stdout_path"
  assert_jq "$install_gptk_json" \
    "install-gptk-wine did not report the GPTK/D3DMetal component." \
    --arg runtimeRoot "$runtime_root" \
    '
      .schemaVersion == 1 and
      .gptkWineInstall.componentId == "gptk-d3dmetal" and
      .gptkWineInstall.runtimeRoot == $runtimeRoot and
      .gptkWineInstall.installedExecutablePath == ($runtimeRoot + "/bin/wineloader")
    '
else
  echo "Skipping GPTK import because KONYAK_MACOS_DLSS_METALFX_SMOKE_IMPORT_GPTK=false." >&2
fi

run_cli_capture list-runtimes "$command_timeout" list-runtimes --json
list_runtimes_json="$captured_stdout_path"
assert_jq "$list_runtimes_json" \
  "list-runtimes did not report an available GPTK/D3DMetal backend." \
  --arg runtimeRoot "$runtime_root" \
  '
    .schemaVersion == 1 and
    (
      .runtimes[] |
        select(.id == "konyak-macos-wine") |
        .isInstalled == true and
        .libraryPath == $runtimeRoot and
        .stack.isComplete == true and
        any(.stack.components[]; .id == "gptk-d3dmetal" and .isInstalled == true and ((.missingPaths // []) | length == 0)) and
        any(.stack.backends[]; .id == "gptk-d3dmetal" and .isAvailable == true and ((.missingPaths // []) | length == 0))
    )
  '

assert_gptk_paths

run_cli_capture create-bottle "$command_timeout" create-bottle --name "DLSS MetalFX Smoke" --json
create_bottle_json="$captured_stdout_path"
assert_jq "$create_bottle_json" \
  "create-bottle did not report the expected DLSS/MetalFX smoke bottle." \
  --arg dataHome "$data_home" \
  '
    .schemaVersion == 1 and
    .bottle.id == "dlss-metalfx-smoke" and
    .bottle.path == ($dataHome + "/bottles/dlss-metalfx-smoke")
  '

run_cli_capture set-runtime-settings "$command_timeout" \
  set-runtime-settings \
  "$bottle_id" \
  --settings-json "$(cat "$runtime_settings_json")" \
  --json
set_runtime_json="$captured_stdout_path"
assert_jq "$set_runtime_json" \
  "set-runtime-settings did not enable D3DMetal DLSS/MetalFX settings." \
  '
    .schemaVersion == 1 and
    .bottle.id == "dlss-metalfx-smoke" and
    .bottle.runtimeSettings.dxrEnabled == true and
    .bottle.runtimeSettings.dlssMetalFx == true and
    .bottle.runtimeSettings.metalHud == true and
    .bottle.runtimeSettings.avxEnabled == true
  '

run_cli_capture run-program "$command_timeout" \
  run-program \
  "$bottle_id" \
  --program "$program_exe" \
  --settings-json "$(cat "$program_settings_json")" \
  --json
run_json="$captured_stdout_path"
assert_jq "$run_json" \
  "run-program did not complete the DLSS/MetalFX smoke through macOS Wine." \
  --arg programPath "$program_exe" \
  --argjson expectedExitCode "$expected_exit_code" \
  '
    .schemaVersion == 1 and
    .run.bottleId == "dlss-metalfx-smoke" and
    .run.runnerKind == "macosWine" and
    .run.programPath == $programPath and
    .run.processExitCode == $expectedExitCode
  '

if [[ ! -f "$wine_log_path" ]]; then
  echo "Expected Konyak run log was not created: $wine_log_path" >&2
  exit 1
fi

for expected_log_entry in \
  "WINEDLLOVERRIDES=dxgi,d3d11,d3d12,nvapi64,nvngx=n,b" \
  "D3DM_SUPPORT_DXR=1" \
  "D3DM_ENABLE_METALFX=1" \
  "MTL_HUD_ENABLED=1" \
  "CX_APPLEGPTK_LIBD3DSHARED_PATH="
do
  if ! grep -q "$expected_log_entry" "$wine_log_path"; then
    echo "Konyak run log is missing expected environment entry: $expected_log_entry" >&2
    sed -n '1,220p' "$wine_log_path" >&2
    exit 1
  fi
done

wait_for_sentinel

if [[ -f "$evidence_host_path" ]]; then
  if ! grep -q "marker=KONYAK_DLSS_METALFX_PREFLIGHT_OK" "$evidence_host_path"; then
    echo "DLSS/MetalFX evidence file did not include the preflight marker." >&2
    sed -n '1,120p' "$evidence_host_path" >&2
    exit 1
  fi
  cp "$evidence_host_path" "$logs_dir/preflight-evidence.txt"
fi

echo "DLSS/MetalFX CLI smoke passed."
echo "Logs: $logs_dir"
