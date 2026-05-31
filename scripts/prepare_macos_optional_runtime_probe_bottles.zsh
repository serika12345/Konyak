#!/usr/bin/env zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Preparing macOS optional runtime probe bottles is supported on macOS only." >&2
  exit 2
fi

vulkan_probe_exe="$("$repo_root/scripts/build_vulkan_probe_exe.zsh")"
d3d11_probe_exe="$("$repo_root/scripts/build_d3d11_probe_exe.zsh")"
cli_dir="$repo_root/packages/konyak_cli"

run_cli_json() {
  local output
  local exit_code

  set +e
  output="$(cd "$cli_dir" && dart run bin/konyak.dart "$@")"
  exit_code=$?
  set -e

  printf '%s\n' "$output"
  return "$exit_code"
}

ensure_bottle() {
  local bottle_id="$1"
  local bottle_name="$2"

  local output
  local exit_code

  set +e
  output="$(run_cli_json create-bottle --name "$bottle_name" --json)"
  exit_code=$?
  set -e

  if [[ "$exit_code" -ne 0 ]]; then
    if ! printf '%s\n' "$output" | jq -e --arg id "$bottle_id" '.error.code == "bottleAlreadyExists" and .error.bottleId == $id' >/dev/null; then
      printf '%s\n' "$output" >&2
      exit "$exit_code"
    fi
  fi
}

pin_program() {
  local bottle_id="$1"
  local program_name="$2"
  local program_path="$3"

  local output
  local exit_code

  set +e
  output="$(run_cli_json pin-program "$bottle_id" --name "$program_name" --program "$program_path" --json)"
  exit_code=$?
  set -e

  if [[ "$exit_code" -ne 0 ]]; then
    if ! printf '%s\n' "$output" | jq -e '.error.code == "programAlreadyPinned"' >/dev/null; then
      printf '%s\n' "$output" >&2
      exit "$exit_code"
    fi
  fi
}

set_runtime_settings() {
  local bottle_id="$1"
  local settings_json="$2"

  run_cli_json set-runtime-settings "$bottle_id" --settings-json "$settings_json" --json >/dev/null
}

prepare_probe() {
  local bottle_id="$1"
  local bottle_name="$2"
  local program_name="$3"
  local program_path="$4"
  local settings_json="$5"

  ensure_bottle "$bottle_id" "$bottle_name"
  pin_program "$bottle_id" "$program_name" "$program_path"
  set_runtime_settings "$bottle_id" "$settings_json"
}

prepare_probe \
  "vulkan-probe" \
  "Vulkan Probe" \
  "Vulkan Triangle Probe" \
  "$vulkan_probe_exe" \
  '{"dxvk":false,"metalHud":false,"metalTrace":false}'

prepare_probe \
  "metal-hud-probe" \
  "Metal HUD Probe" \
  "Vulkan Triangle Probe" \
  "$vulkan_probe_exe" \
  '{"dxvk":false,"metalHud":true,"metalTrace":false}'

prepare_probe \
  "metal-trace-probe" \
  "Metal Trace Probe" \
  "Vulkan Triangle Probe" \
  "$vulkan_probe_exe" \
  '{"dxvk":false,"metalHud":false,"metalTrace":true}'

prepare_probe \
  "dxvk-probe" \
  "DXVK Probe" \
  "D3D11 Swapchain Probe" \
  "$d3d11_probe_exe" \
  '{"dxvk":true,"dxvkAsync":true,"dxvkHud":"off","metalHud":false,"metalTrace":false}'

prepare_probe \
  "dxvk-hud-probe" \
  "DXVK HUD Probe" \
  "D3D11 Swapchain Probe" \
  "$d3d11_probe_exe" \
  '{"dxvk":true,"dxvkAsync":true,"dxvkHud":"partial","metalHud":false,"metalTrace":false}'

echo "Prepared optional runtime probe bottles:"
echo "  Vulkan Probe: Vulkan/MoltenVK triangle"
echo "  Metal HUD Probe: Vulkan triangle with MTL_HUD_ENABLED=1"
echo "  Metal Trace Probe: Vulkan triangle with METAL_CAPTURE_ENABLED=1"
echo "  DXVK Probe: D3D11 swapchain with DXVK enabled"
echo "  DXVK HUD Probe: D3D11 swapchain with DXVK HUD enabled"
echo "Open Konyak and launch each pinned probe from its bottle."
