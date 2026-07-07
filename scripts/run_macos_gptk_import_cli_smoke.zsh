#!/usr/bin/env zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd -P)"
cli_dir="$repo_root/packages/konyak_cli"
runtime_smoke_dir="$repo_root/runtime/konyak-macos-runtime"
work_root="${KONYAK_GPTK_IMPORT_CLI_SMOKE_WORK_ROOT:-$repo_root/.dart_tool/konyak/gptk-import-cli-smoke}"
logs_dir="$work_root/logs"
manifest_path="${KONYAK_GPTK_IMPORT_CLI_SMOKE_SOURCE_MANIFEST:-}"
runtime_stack_manifest="$repo_root/runtime/konyak-macos-runtime/dist/konyak-macos-wine-runtime-stack-source.json"
runtime_stack_archive="${KONYAK_GPTK_IMPORT_CLI_SMOKE_RUNTIME_STACK_ARCHIVE:-$repo_root/runtime/konyak-macos-runtime/dist/konyak-macos-wine-runtime-stack.tar.zst}"
gptk3_source="${KONYAK_GPTK3_SOURCE_PATH:-}"
gptk4_source="${KONYAK_GPTK4_SOURCE_PATH:-}"
command_timeout="${KONYAK_GPTK_IMPORT_CLI_SMOKE_COMMAND_TIMEOUT:-240s}"
install_timeout="${KONYAK_GPTK_IMPORT_CLI_SMOKE_INSTALL_TIMEOUT:-1200s}"
import_timeout="${KONYAK_GPTK_IMPORT_CLI_SMOKE_IMPORT_TIMEOUT:-600s}"
run_backend_smoke="${KONYAK_GPTK_IMPORT_CLI_SMOKE_BACKEND_SMOKE:-true}"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "macOS GPTK import CLI smoke is supported on macOS only." >&2
  exit 2
fi

for required_command in dart jq timeout; do
  if ! command -v "$required_command" >/dev/null 2>&1; then
    echo "Missing $required_command. Run this script inside nix develop." >&2
    exit 69
  fi
done

if [[ ! -d "$runtime_smoke_dir" ]]; then
  echo "Missing runtime submodule checkout: $runtime_smoke_dir" >&2
  exit 66
fi

if [[ -z "$gptk3_source" ]]; then
  echo "Set KONYAK_GPTK3_SOURCE_PATH to a user-provided GPTK 3 DMG path." >&2
  exit 64
fi

if [[ -z "$gptk4_source" ]]; then
  echo "Set KONYAK_GPTK4_SOURCE_PATH to a user-provided GPTK 4 DMG path." >&2
  exit 64
fi

prepare_cli_package() {
  (
    cd "$cli_dir"
    dart pub get
    dart run build_runner build
  )
}

resolve_manifest_path() {
  if [[ -n "$manifest_path" ]]; then
    if [[ ! -f "$manifest_path" ]]; then
      echo "Configured GPTK import smoke source manifest does not exist: $manifest_path" >&2
      exit 66
    fi
    print -r -- "$manifest_path"
    return
  fi

  if [[ -f "$runtime_stack_manifest" && -f "$runtime_stack_archive" ]]; then
    local local_manifest="$work_root/konyak-macos-wine-runtime-stack-source.local.json"
    mkdir -p "$work_root"
    jq \
      --arg archive "$runtime_stack_archive" \
      '.components |= map(.archiveUrl = $archive)' \
      "$runtime_stack_manifest" >"$local_manifest"
    print -r -- "$local_manifest"
    return
  fi

  "$repo_root/scripts/prepare_macos_dev_runtime_stack.zsh" --force --print-manifest-path
}

captured_stdout_path=""
captured_stderr_path=""
variant_runtime_root=""
variant_data_home=""
variant_config_home=""
variant_logs_dir=""

run_cli_capture() {
  local label="$1"
  local timeout_value="$2"
  shift 2

  captured_stdout_path="$variant_logs_dir/$label.stdout"
  captured_stderr_path="$variant_logs_dir/$label.stderr"

  echo "Running konyak $*" >&2
  set +e
  (
    cd "$cli_dir"
    env \
      KONYAK_RUNTIME_PROFILE="${KONYAK_RUNTIME_PROFILE:-development}" \
      KONYAK_MACOS_WINE_HOME="$variant_runtime_root" \
      KONYAK_DATA_HOME="$variant_data_home" \
      KONYAK_CONFIG_HOME="$variant_config_home" \
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

assert_path_exists() {
  local path="$1"
  if [[ ! -e "$path" ]]; then
    echo "Expected GPTK/D3DMetal path is missing: $path" >&2
    exit 65
  fi
}

assert_path_absent() {
  local path="$1"
  if [[ -e "$path" ]]; then
    echo "Unexpected GPTK/D3DMetal path is present: $path" >&2
    exit 65
  fi
}

assert_symlink() {
  local path="$1"
  if [[ ! -L "$path" ]]; then
    echo "Expected GPTK/D3DMetal Unix library symlink is not a symlink: $path" >&2
    exit 65
  fi
}

assert_gptk_layout() {
  local expected_version="$1"
  local component_root="$variant_runtime_root/components/gptk-d3dmetal"

  for required_path in \
    "$component_root/lib/external/D3DMetal.framework" \
    "$component_root/lib/external/libd3dshared.dylib" \
    "$component_root/lib/wine/x86_64-windows/d3d11.dll" \
    "$component_root/lib/wine/x86_64-windows/d3d12.dll" \
    "$component_root/lib/wine/x86_64-windows/dxgi.dll" \
    "$component_root/lib/wine/x86_64-windows/nvapi64.dll" \
    "$component_root/lib/wine/x86_64-windows/nvngx.dll" \
    "$component_root/lib/wine/x86_64-unix/d3d11.so" \
    "$component_root/lib/wine/x86_64-unix/d3d12.so" \
    "$component_root/lib/wine/x86_64-unix/dxgi.so" \
    "$component_root/lib/wine/x86_64-unix/nvapi64.so" \
    "$component_root/lib/wine/x86_64-unix/nvngx.so"
  do
    assert_path_exists "$required_path"
  done

  for symlink_path in \
    "$component_root/lib/wine/x86_64-unix/d3d11.so" \
    "$component_root/lib/wine/x86_64-unix/d3d12.so" \
    "$component_root/lib/wine/x86_64-unix/dxgi.so"
  do
    assert_symlink "$symlink_path"
  done

  assert_path_absent "$component_root/lib/wine/x86_64-windows/d3d10.dll"
  assert_path_absent "$component_root/lib/wine/x86_64-unix/d3d10.so"

  case "$expected_version" in
    3)
      assert_path_exists "$component_root/lib/wine/x86_64-windows/atidxx64.dll"
      assert_path_exists "$component_root/lib/wine/x86_64-unix/atidxx64.so"
      ;;
    4)
      assert_path_absent "$component_root/lib/wine/x86_64-windows/atidxx64.dll"
      assert_path_absent "$component_root/lib/wine/x86_64-unix/atidxx64.so"
      ;;
    *)
      echo "Unknown GPTK version assertion: $expected_version" >&2
      exit 70
      ;;
  esac
}

run_backend_smoke_for_variant() {
  local label="$1"
  local probe_root="$work_root/backend-probes-$label"

  if [[ "$run_backend_smoke" != "true" ]]; then
    echo "Skipping backend smoke for $label because KONYAK_GPTK_IMPORT_CLI_SMOKE_BACKEND_SMOKE=$run_backend_smoke." >&2
    return
  fi

  KONYAK_ALLOW_GPTK_UNSUPPORTED_HOST=1 \
    "$runtime_smoke_dir/scripts/smoke-backend-device.zsh" \
      "$variant_runtime_root" \
      gptk-d3d10-unsupported \
      "$probe_root"
  KONYAK_ALLOW_GPTK_UNSUPPORTED_HOST=1 \
    "$runtime_smoke_dir/scripts/smoke-backend-device.zsh" \
      "$variant_runtime_root" \
      gptk-d3d11-device \
      "$probe_root"
  KONYAK_ALLOW_GPTK_UNSUPPORTED_HOST=1 \
    "$runtime_smoke_dir/scripts/smoke-backend-device.zsh" \
      "$variant_runtime_root" \
      gptk-d3d12-device \
      "$probe_root"
}

run_variant() {
  local label="$1"
  local source_path="$2"
  local expected_version="$3"
  local requested_version="$4"
  local variant_root="$work_root/$label"
  local install_json
  local import_json
  local list_json
  typeset -a import_args

  if [[ ! -e "$source_path" ]]; then
    echo "$label source does not exist: $source_path" >&2
    exit 66
  fi

  variant_runtime_root="$variant_root/runtime/macos-wine"
  variant_data_home="$variant_root/data"
  variant_config_home="$variant_root/config"
  variant_logs_dir="$logs_dir/$label"

  rm -rf "$variant_root"
  mkdir -p "$variant_logs_dir" "$variant_runtime_root:h"

  run_cli_capture "install-macos-wine" "$install_timeout" \
    install-macos-wine \
    --reinstall \
    --source-manifest "$manifest_path" \
    --progress-json \
    --json
  install_json="$variant_logs_dir/install-macos-wine.final.json"
  write_last_json_line "$captured_stdout_path" "$install_json"
  assert_jq "$install_json" \
    "$label install-macos-wine did not report an installed macOS runtime." \
    --arg runtimeRoot "$variant_runtime_root" \
    '
      .schemaVersion == 1 and
      .runtime.id == "konyak-macos-wine" and
      .runtime.isInstalled == true and
      .runtime.libraryPath == $runtimeRoot
    '

  import_args=(install-gptk-wine --from "$source_path")
  if [[ -n "$requested_version" ]]; then
    import_args+=(--gptk-version "$requested_version")
  fi
  import_args+=(--json)

  run_cli_capture "install-gptk-wine" "$import_timeout" "${import_args[@]}"
  import_json="$captured_stdout_path"
  assert_jq "$import_json" \
    "$label install-gptk-wine did not report the expected GPTK version." \
    --arg version "$expected_version" \
    --arg runtimeRoot "$variant_runtime_root" \
    '
      .schemaVersion == 1 and
      .gptkWineInstall.componentId == "gptk-d3dmetal" and
      .gptkWineInstall.detectedVersion == $version and
      .gptkWineInstall.runtimeRoot == $runtimeRoot and
      (.gptkWineInstall.installedExecutablePath | endswith("/bin/wineloader"))
    '
  assert_gptk_layout "$expected_version"

  run_cli_capture "list-runtimes-after-gptk" "$command_timeout" list-runtimes --json
  list_json="$captured_stdout_path"
  assert_jq "$list_json" \
    "$label list-runtimes did not report a complete runtime after GPTK import." \
    --arg runtimeRoot "$variant_runtime_root" \
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
  assert_runtime_component_installed gptk-d3dmetal "$list_json"
  assert_runtime_backend_available gptk-d3dmetal "$list_json"

  run_backend_smoke_for_variant "$label"

  echo "$label GPTK import CLI smoke passed. Logs: $variant_logs_dir" >&2
}

prepare_cli_package
rm -rf "$logs_dir"
mkdir -p "$logs_dir"
manifest_path="$(resolve_manifest_path)"

run_variant gptk3 "$gptk3_source" 3 ""
run_variant gptk4 "$gptk4_source" 4 "4"

echo "macOS GPTK import CLI smoke passed. Logs: $logs_dir"
