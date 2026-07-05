#!/usr/bin/env zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd -P)"
cd "$repo_root"

for command in dart flutter; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Missing required command: $command" >&2
    exit 69
  fi
done

echo "Generating Konyak CLI Dart sources..."
(
  cd packages/konyak_cli
  dart pub get
  dart run build_runner build
)

echo "Generating Konyak Flutter Dart sources..."
(
  cd apps/konyak
  flutter pub get
  flutter pub run build_runner build
)
