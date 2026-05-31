#!/usr/bin/env zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Preparing the macOS Vulkan probe bottle is supported on macOS only." >&2
  exit 2
fi

probe_exe="$("$repo_root/scripts/build_vulkan_probe_exe.zsh")"
cli_dir="$repo_root/packages/konyak_cli"
bottle_id="vulkan-probe"

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

set +e
create_output="$(run_cli_json create-bottle --name "Vulkan Probe" --json)"
create_status=$?
set -e
if [[ "$create_status" -ne 0 ]]; then
  if ! printf '%s\n' "$create_output" | jq -e '.error.code == "bottleAlreadyExists" and .error.bottleId == "vulkan-probe"' >/dev/null; then
    printf '%s\n' "$create_output" >&2
    exit "$create_status"
  fi
fi

set +e
pin_output="$(run_cli_json pin-program "$bottle_id" --name "Vulkan Probe" --program "$probe_exe" --json)"
pin_status=$?
set -e
if [[ "$pin_status" -ne 0 ]]; then
  if ! printf '%s\n' "$pin_output" | jq -e '.error.code == "programAlreadyPinned"' >/dev/null; then
    printf '%s\n' "$pin_output" >&2
    exit "$pin_status"
  fi
fi

echo "Prepared Konyak bottle: Vulkan Probe ($bottle_id)"
echo "Pinned program: $probe_exe"
echo "Open Konyak, select the Vulkan Probe bottle, then launch the pinned Vulkan Probe program."
