set shell := ["zsh", "-lc"]

default:
  just --list

verify: verify-governance verify-architecture format-check lint verify-safety test flutter-linux-loader-check

flutter-pub-get:
  if [ -d apps/konyak ]; then cd apps/konyak && flutter pub get; fi

cli-pub-get:
  if [ -d packages/konyak_cli ]; then cd packages/konyak_cli && dart pub get; fi

verify-governance:
  python3 scripts/verify_governance.py

verify-architecture:
  python3 scripts/verify_architecture.py

format: flutter-pub-get cli-pub-get
  nixfmt flake.nix
  if [ -d apps/konyak ]; then cd apps/konyak && dart format .; fi
  if [ -d packages/konyak_cli ]; then cd packages/konyak_cli && dart format .; fi

format-check: flutter-pub-get cli-pub-get flutter-format-check cli-format-check
  nixfmt --check flake.nix

lint: flutter-pub-get cli-pub-get nix-lint flutter-analyze cli-analyze

nix-lint:
  deadnix --fail flake.nix
  statix check flake.nix

test: flutter-pub-get cli-pub-get flutter-test cli-test

verify-safety: flutter-pub-get cli-pub-get
  python3 scripts/verify_no_invisible_chars.py
  python3 scripts/verify_pub_licenses.py
  python3 scripts/verify_cves.py

flutter-format-check:
  if [ -d apps/konyak ]; then cd apps/konyak && dart format --set-exit-if-changed .; fi

flutter-analyze:
  if [ -d apps/konyak ]; then cd apps/konyak && flutter analyze --fatal-infos; fi

flutter-test:
  if [ -d apps/konyak ]; then cd apps/konyak && flutter test; fi

flutter-linux-loader-check:
  if [ "$(uname -s)" = "Linux" ] && [ -d apps/konyak ]; then cd apps/konyak && flutter build linux --debug && ldd build/linux/x64/debug/bundle/konyak | tee /tmp/konyak-linux-loader-check-ldd.txt && ! rg "not found" /tmp/konyak-linux-loader-check-ldd.txt; fi

cli-format-check:
  if [ -d packages/konyak_cli ]; then cd packages/konyak_cli && dart format --set-exit-if-changed .; fi

cli-analyze:
  if [ -d packages/konyak_cli ]; then cd packages/konyak_cli && dart analyze --fatal-infos; fi

cli-test:
  if [ -d packages/konyak_cli ]; then cd packages/konyak_cli && dart test; fi

diagnose-linux-vulkan-wine:
  zsh scripts/run_linux_vulkan_wine_smoke.zsh

diagnose-macos-vulkan-wine:
  zsh scripts/run_macos_vulkan_wine_smoke.zsh

linux-runtime-cli-smoke:
  zsh scripts/run_linux_runtime_cli_smoke.zsh

macos-vulkan-probe-bottle:
  zsh scripts/prepare_macos_vulkan_probe_bottle.zsh

macos-optional-runtime-probe-bottles:
  zsh scripts/prepare_macos_optional_runtime_probe_bottles.zsh

swift-lint:
  if [ "$(uname -s)" = "Darwin" ] && [ -d /Applications/Xcode.app/Contents/Developer ]; then DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer PATH=/usr/bin:$PATH swiftlint; else swiftlint; fi

macos-release:
  ./scripts/build_macos_release.zsh

macos-debug-app:
  ./scripts/build_macos_debug_app.zsh

fetch-windows-fixture-putty:
  ./scripts/fetch_windows_fixture_putty.zsh

smoke-macos-runtime-install:
  ./scripts/smoke_macos_release_runtime_extraction.zsh

smoke-macos-finder:
  ./scripts/smoke_macos_finder_integration.zsh

smoke-macos-app-cli-bridge:
  ./scripts/smoke_macos_packaged_app_cli_bridge.zsh

smoke-macos-finder-putty:
  fixture="$(./scripts/fetch_windows_fixture_putty.zsh)"; app_bundle="${KONYAK_MACOS_FINDER_SMOKE_APP:-.dart_tool/konyak/app/macos/debug/Konyak.app}"; ./scripts/smoke_macos_finder_integration.zsh "$app_bundle" "$fixture"

linux-release:
  ./scripts/build_linux_release.zsh
