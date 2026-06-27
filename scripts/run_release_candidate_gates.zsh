#!/usr/bin/env zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd -P)"
cd "$repo_root"

if [[ -z "${IN_NIX_SHELL:-}" ]]; then
  echo "Run release candidate gates through: nix develop -c zsh -lc 'just release-candidate-gates'" >&2
  exit 69
fi

echo "==> Running repository verification"
just verify

case "$(uname -s)" in
  Darwin)
    release_app=".dart_tool/konyak/release/macos/Konyak.app"
    echo "==> Building macOS release candidate"
    just macos-release
    echo "==> Smoking packaged macOS runtime extraction"
    just smoke-macos-runtime-install
    echo "==> Smoking packaged macOS DMG layout"
    just smoke-macos-dmg-layout
    echo "==> Smoking packaged macOS Finder integration with PuTTY"
    fixture="$(./scripts/fetch_windows_fixture_putty.zsh)"
    ./scripts/smoke_macos_finder_integration.zsh "$release_app" "$fixture"
    echo "==> Smoking packaged macOS app CLI bridge"
    ./scripts/smoke_macos_packaged_app_cli_bridge.zsh "$release_app"
    echo "==> Smoking packaged macOS app update handoff"
    ./scripts/smoke_macos_app_update_handoff.zsh "$release_app"
    ;;
  Linux)
    echo "==> Building Linux release candidate and running release checks"
    just linux-release-check
    ;;
  *)
    echo "Unsupported release candidate gate platform: $(uname -s)" >&2
    exit 69
    ;;
esac

echo "Release candidate gates passed."
