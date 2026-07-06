set shell := ["zsh", "-lc"]

default:
  just --list

verify: verify-governance verify-architecture format-check lint verify-safety test flutter-linux-loader-check linux-desktop-integration-smoke linux-pinned-launcher-smoke

flutter-pub-get:
  if [ -d apps/konyak ]; then cd apps/konyak && flutter pub get; fi

cli-pub-get:
  if [ -d packages/konyak_cli ]; then cd packages/konyak_cli && dart pub get; fi

konyak-lints-pub-get:
  if [ -d tools/konyak_lints ]; then cd tools/konyak_lints && dart pub get; fi

cli-codegen: cli-pub-get
  if [ -d packages/konyak_cli ]; then cd packages/konyak_cli && dart run build_runner build; fi

flutter-codegen: flutter-pub-get
  if [ -d apps/konyak ]; then cd apps/konyak && flutter pub run build_runner build; fi

verify-governance: cli-pub-get
  python3 scripts/verify_governance.py

verify-architecture:
  python3 scripts/verify_architecture.py

format: flutter-pub-get cli-pub-get konyak-lints-pub-get
  nixfmt flake.nix
  if [ -d apps/konyak ]; then cd apps/konyak && dart format .; fi
  if [ -d packages/konyak_cli ]; then cd packages/konyak_cli && dart format .; fi
  if [ -d tools/konyak_lints ]; then cd tools/konyak_lints && dart format .; fi

format-check: flutter-pub-get cli-pub-get konyak-lints-pub-get flutter-format-check cli-format-check konyak-lints-format-check
  nixfmt --check flake.nix

lint: flutter-pub-get cli-pub-get konyak-lints-pub-get nix-lint flutter-analyze cli-analyze konyak-lints-analyze

nix-lint:
  deadnix --fail flake.nix
  statix check flake.nix

test: flutter-pub-get cli-pub-get konyak-lints-pub-get flutter-test cli-test konyak-lints-test release-automation-test

verify-safety: flutter-pub-get cli-pub-get
  python3 scripts/verify_no_invisible_chars.py
  python3 scripts/verify_pub_licenses.py
  python3 scripts/verify_cves.py

flutter-format-check: flutter-codegen
  if [ -d apps/konyak ]; then cd apps/konyak && dart format --set-exit-if-changed .; fi

flutter-analyze: flutter-codegen flutter-custom-lint
  if [ -d apps/konyak ]; then cd apps/konyak && flutter analyze --fatal-infos; fi

flutter-custom-lint: flutter-codegen
  if [ -d apps/konyak ]; then cd apps/konyak && flutter pub run custom_lint; fi

flutter-test: flutter-codegen
  if [ -d apps/konyak ]; then cd apps/konyak && flutter test; fi

flutter-linux-loader-check:
  if [ "$(uname -s)" = "Linux" ] && [ -d apps/konyak ]; then cd apps/konyak && flutter build linux --debug && ldd build/linux/x64/debug/bundle/konyak | tee /tmp/konyak-linux-loader-check-ldd.txt && ! rg "not found" /tmp/konyak-linux-loader-check-ldd.txt; fi

cli-format-check: cli-codegen
  if [ -d packages/konyak_cli ]; then cd packages/konyak_cli && dart format --set-exit-if-changed .; fi

konyak-lints-format-check: konyak-lints-pub-get
  if [ -d tools/konyak_lints ]; then cd tools/konyak_lints && dart format --set-exit-if-changed .; fi

cli-custom-lint: cli-pub-get
  if [ -d packages/konyak_cli ]; then cd packages/konyak_cli && dart run custom_lint; fi

cli-analyze: cli-codegen cli-custom-lint
  if [ -d packages/konyak_cli ]; then cd packages/konyak_cli && dart analyze --fatal-infos; fi

konyak-lints-analyze: konyak-lints-pub-get
  if [ -d tools/konyak_lints ]; then cd tools/konyak_lints && dart analyze --fatal-infos; fi

konyak-lints-test: konyak-lints-pub-get
  if [ -d tools/konyak_lints ]; then cd tools/konyak_lints && dart test; fi

cli-test: cli-codegen
  if [ -d packages/konyak_cli ]; then cd packages/konyak_cli && dart test; fi

release-automation-test:
  python3 scripts/prepare_release_test.py

draft-release-notes VERSION:
  ./scripts/draft_release_notes.zsh "{{VERSION}}"

release-candidate-gates:
  ./scripts/run_release_candidate_gates.zsh

diagnose-linux-vulkan-wine:
  zsh scripts/run_linux_vulkan_wine_smoke.zsh

diagnose-macos-vulkan-wine:
  zsh scripts/run_macos_vulkan_wine_smoke.zsh

linux-runtime-cli-smoke:
  zsh scripts/run_linux_runtime_cli_smoke.zsh

linux-desktop-integration-smoke:
  if [ "$(uname -s)" = "Linux" ]; then zsh scripts/smoke_linux_desktop_integration.zsh; fi

linux-pinned-launcher-smoke:
  if [ "$(uname -s)" = "Linux" ]; then zsh scripts/smoke_linux_pinned_launcher_integration.zsh; fi

smoke-linux-appimage-update-handoff:
  if [ "$(uname -s)" = "Linux" ]; then zsh scripts/smoke_linux_appimage_update_handoff.zsh; fi

linux-release-check:
  zsh scripts/run_linux_release_check.zsh

prepare-release *ARGS:
  python3 scripts/prepare_release.py {{ARGS}}

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

smoke-macos-dmg-layout:
  ./scripts/smoke_macos_dmg_layout.zsh

smoke-macos-finder:
  ./scripts/smoke_macos_finder_integration.zsh

smoke-macos-app-cli-bridge:
  ./scripts/smoke_macos_packaged_app_cli_bridge.zsh

smoke-macos-app-update-handoff:
  ./scripts/smoke_macos_app_update_handoff.zsh

smoke-macos-gptk-import-cli:
  ./scripts/run_macos_gptk_import_cli_smoke.zsh

smoke-macos-finder-putty:
  fixture="$(./scripts/fetch_windows_fixture_putty.zsh)"; app_bundle="${KONYAK_MACOS_FINDER_SMOKE_APP:-.dart_tool/konyak/app/macos/debug/Konyak.app}"; ./scripts/smoke_macos_finder_integration.zsh "$app_bundle" "$fixture"

linux-release:
  ./scripts/build_linux_release.zsh
