#!/usr/bin/env zsh

set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  print -r -- "macOS Flutter toolchain test skipped on non-Darwin host."
  exit 0
fi

rsync_path=""
for candidate in ${(f)"$(whence -a rsync)"}; do
  if [[ "$candidate" == /nix/store/*-rsync-*/bin/rsync ]]; then
    rsync_path="$candidate"
    break
  fi
done
if [[ -z "$rsync_path" ]]; then
  print -u2 -r -- "Expected the macOS dev shell to provide a Nix rsync."
  exit 1
fi

test_root="$(mktemp -d "${TMPDIR:-/tmp}/konyak-macos-flutter-toolchain.XXXXXX")"
cleanup() {
  chmod -R u+w "$test_root" 2>/dev/null || true
  rm -rf "$test_root"
}
trap cleanup EXIT

source_framework="$test_root/source/FlutterMacOS.framework"
output_directory="$test_root/output"
copied_framework="$output_directory/FlutterMacOS.framework"
mkdir -p "$source_framework/Versions/A" "$output_directory"
touch "$source_framework/Versions/A/FlutterMacOS"
chmod 0444 "$source_framework/Versions/A/FlutterMacOS"
chmod 0555 "$source_framework/Versions/A" "$source_framework/Versions" "$source_framework"

"$rsync_path" \
  -av \
  --delete \
  --filter '- .DS_Store/' \
  --chmod=Du=rwx,Dgo=rx,Fu=rw,Fgo=r \
  "$source_framework" \
  "$output_directory"

if [[ ! -w "$copied_framework/Versions/A" ]]; then
  print -u2 -r -- "Flutter framework copy destination is not user-writable after using: $rsync_path"
  exit 1
fi

touch "$copied_framework/Versions/A/.konyak-lipo-sibling.tmp"

macos_release_recipe="$(just --show macos-release)"
if [[ "$macos_release_recipe" != *"nix run .#macos-release"* ]]; then
  print -u2 -r -- "Expected just macos-release to delegate to the Nix release app."
  print -u2 -r -- "$macos_release_recipe"
  exit 1
fi

print -r -- "macOS Flutter toolchain rsync contract passed: $rsync_path"
