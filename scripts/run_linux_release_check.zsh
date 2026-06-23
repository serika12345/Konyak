#!/usr/bin/env zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd -P)"
cd "$repo_root"

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "Linux release checks must run on Linux." >&2
  exit 69
fi

if [[ -z "${IN_NIX_SHELL:-}" ]]; then
  echo "Run this script through: nix develop -c zsh -lc 'just linux-release-check'" >&2
  exit 69
fi

for command in openssl zsh; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Missing required command: $command" >&2
    exit 69
  fi
done

release_root="${KONYAK_RELEASE_OUTPUT_DIR:-$repo_root/.dart_tool/konyak/release/linux}"
manifest_path="$release_root/konyak-linux-wine-runtime-stack-source.json"
signature_path="$release_root/konyak-linux-wine-runtime-stack-source.json.sig"
public_key_path="$release_root/konyak-runtime-stack-public-key.pem"
runtime_smoke_root="${KONYAK_LINUX_RELEASE_CHECK_RUNTIME_SMOKE_ROOT:-$repo_root/.dart_tool/konyak/linux-release-check-runtime-smoke}"
skip_runtime_install="${KONYAK_LINUX_RELEASE_CHECK_SKIP_RUNTIME_INSTALL:-false}"

default_runtime_env=(
  -u KONYAK_DEV_LINUX_WINE_STACK_MANIFEST
  -u KONYAK_DEV_LINUX_WINE_STACK_SOURCE_MANIFEST
  -u KONYAK_DEV_LINUX_RUNTIME_RELEASE_TAG
  -u KONYAK_LINUX_WINE_STACK_MANIFEST
  -u KONYAK_LINUX_WINE_STACK_SIGNATURE_URL
  -u KONYAK_LINUX_WINE_STACK_PUBLIC_KEY_PATH
  -u KONYAK_LINUX_RUNTIME_RELEASE_REPO
  -u KONYAK_LINUX_RUNTIME_RELEASE_TAG
  -u KONYAK_RUNTIME_STACK_SOURCE_MANIFEST
  -u KONYAK_RUNTIME_STACK_SOURCE_SIGNATURE
  -u KONYAK_RUNTIME_STACK_PUBLIC_KEY
  -u KONYAK_RUNTIME_STACK_PUBLIC_KEY_PATH
  -u KONYAK_RUNTIME_STACK_SIGNING_KEY_BASE64
  -u KONYAK_LINUX_WINE_HOME
)

echo "==> Building Linux AppImage from the default runtime release"
env "${default_runtime_env[@]}" "$repo_root/scripts/build_linux_release.zsh"

echo "==> Checking Linux release metadata and AppRun runtime environment"
"$repo_root/scripts/smoke_linux_release_metadata.zsh"
"$repo_root/scripts/smoke_linux_appimage_apprun_env.zsh"
"$repo_root/scripts/smoke_linux_desktop_integration.zsh"

echo "==> Verifying bundled Linux runtime source manifest signature"
for required_file in "$manifest_path" "$signature_path" "$public_key_path"; do
  if [[ ! -f "$required_file" ]]; then
    echo "Missing Linux runtime release file: $required_file" >&2
    exit 70
  fi
done
openssl dgst -sha256 \
  -verify "$public_key_path" \
  -signature "$signature_path" \
  "$manifest_path"

if [[ "$skip_runtime_install" == "true" ]]; then
  echo "Skipping runtime install smoke because KONYAK_LINUX_RELEASE_CHECK_SKIP_RUNTIME_INSTALL=true."
else
  echo "==> Installing and validating the Linux runtime through the public CLI smoke"
  rm -rf "$runtime_smoke_root"
  env "${default_runtime_env[@]}" \
    KONYAK_LINUX_RUNTIME_CLI_SMOKE_WORK_ROOT="$runtime_smoke_root" \
    "$repo_root/scripts/run_linux_runtime_cli_smoke.zsh"
fi

echo "Linux release check passed."
echo "AppImage output: $release_root"
