#!/usr/bin/env zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd -P)"
cd "$repo_root"

putty_version=0.84
fixture_url="https://the.earth.li/~sgtatham/putty/0.84/w64/putty.exe"
expected_sha256="7056ca2f6a9f3c525845b116c7bf564ced3284a4083ea80d7e9ef51a16f612c4"

cache_root="${KONYAK_WINDOWS_FIXTURE_CACHE_DIR:-$repo_root/.dart_tool/konyak/fixtures/windows}"
fixture_path="${KONYAK_WINDOWS_FIXTURE_PUTTY_PATH:-$cache_root/putty-${putty_version}-w64.exe}"
fixture_dir="$(dirname "$fixture_path")"
download_path="$fixture_path.download"

for command in awk curl dirname mkdir mv rm shasum; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Missing required command: $command" >&2
    exit 69
  fi
done

actual_sha256() {
  shasum -a 256 "$1" | awk '{print $1}'
}

if [[ -f "$fixture_path" ]]; then
  cached_sha256="$(actual_sha256 "$fixture_path")"
  if [[ "$cached_sha256" == "$expected_sha256" ]]; then
    printf "%s\n" "$fixture_path"
    exit 0
  fi

  echo "Cached PuTTY fixture checksum mismatch; redownloading $fixture_path" >&2
  rm -f "$fixture_path"
fi

mkdir -p "$fixture_dir"
rm -f "$download_path"
curl -fL --retry 3 --retry-delay 1 --connect-timeout 30 \
  -o "$download_path" \
  "$fixture_url"

downloaded_sha256="$(actual_sha256 "$download_path")"
if [[ "$downloaded_sha256" != "$expected_sha256" ]]; then
  rm -f "$download_path"
  echo "PuTTY fixture checksum mismatch." >&2
  echo "Expected: $expected_sha256" >&2
  echo "Actual:   $downloaded_sha256" >&2
  exit 1
fi

mv "$download_path" "$fixture_path"
printf "%s\n" "$fixture_path"
