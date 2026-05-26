set shell := ["zsh", "-lc"]

default:
  just --list

verify: verify-governance format-check lint test

flutter-pub-get:
  if [ -d apps/konyak ]; then cd apps/konyak && flutter pub get; fi

cli-pub-get:
  if [ -d packages/konyak_cli ]; then cd packages/konyak_cli && dart pub get; fi

verify-governance:
  python3 scripts/verify_governance.py

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

flutter-format-check:
  if [ -d apps/konyak ]; then cd apps/konyak && dart format --set-exit-if-changed .; fi

flutter-analyze:
  if [ -d apps/konyak ]; then cd apps/konyak && flutter analyze --fatal-infos; fi

flutter-test:
  if [ -d apps/konyak ]; then cd apps/konyak && flutter test; fi

cli-format-check:
  if [ -d packages/konyak_cli ]; then cd packages/konyak_cli && dart format --set-exit-if-changed .; fi

cli-analyze:
  if [ -d packages/konyak_cli ]; then cd packages/konyak_cli && dart analyze --fatal-infos; fi

cli-test:
  if [ -d packages/konyak_cli ]; then cd packages/konyak_cli && dart test; fi

swift-lint:
  if [ "$(uname -s)" = "Darwin" ] && [ -d /Applications/Xcode.app/Contents/Developer ]; then DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer PATH=/usr/bin:$PATH swiftlint; else swiftlint; fi

macos-release:
  ./scripts/build_macos_release.zsh

linux-release:
  ./scripts/build_linux_release.zsh
