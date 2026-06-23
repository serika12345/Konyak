#!/usr/bin/env zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd -P)"
cd "$repo_root"

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "Linux release metadata smoke is supported on Linux only." >&2
  exit 69
fi

for command in grep jq sha256sum; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Missing required command: $command" >&2
    exit 69
  fi
done

release_root="${KONYAK_RELEASE_OUTPUT_DIR:-$repo_root/.dart_tool/konyak/release/linux}"
metadata_files=("$release_root"/Konyak-*.release.json(N))
checksum_files=("$release_root"/Konyak-*.AppImage.sha256(N))

if (( ${#metadata_files[@]} != 1 )); then
  echo "Expected exactly one Linux release metadata file under $release_root." >&2
  exit 1
fi

if (( ${#checksum_files[@]} != 1 )); then
  echo "Expected exactly one Linux AppImage checksum file under $release_root." >&2
  exit 1
fi

(
  cd "$release_root"
  sha256sum -c "${checksum_files[1]:t}" >/dev/null
  sha256sum -c SHA256SUMS >/dev/null
)

metadata_path="${metadata_files[1]}"
jq -e '
  .schemaVersion == 1
  and .appId == "konyak"
  and (.artifacts | type) == "array"
  and (.artifacts | length) == 1
  and .artifacts[0].platform == "linux"
  and .artifacts[0].architecture == "x86_64"
  and .artifacts[0].format == "appimage"
  and (.runtimeStack | type) == "object"
  and .runtimeStack.runtimeId == "konyak-linux-wine"
  and .runtimeStack.stackId == "linux-wine-runtime-stack"
  and .runtimeStack.sourceManifestFileName == "konyak-linux-wine-runtime-stack-source.json"
' "$metadata_path" >/dev/null

manifest_path="$release_root/konyak-linux-wine-runtime-stack-source.json"
if [[ ! -f "$manifest_path" ]]; then
  echo "Linux runtime source manifest was not published: $manifest_path" >&2
  exit 1
fi

signature_file="$(jq -r '.runtimeStack.signatureFileName // ""' "$metadata_path")"
if [[ -n "$signature_file" && ! -f "$release_root/$signature_file" ]]; then
  echo "Linux runtime source manifest signature was referenced but not published: $signature_file" >&2
  exit 1
fi

public_key_file="$(jq -r '.runtimeStack.publicKeyFileName // ""' "$metadata_path")"
if [[ -n "$public_key_file" && ! -f "$release_root/$public_key_file" ]]; then
  echo "Linux runtime public key was referenced but not published: $public_key_file" >&2
  exit 1
fi

appdir="$release_root/Konyak.AppDir"
appdir_desktop="$appdir/app.konyak.Konyak.desktop"
if [[ ! -f "$appdir_desktop" ]]; then
  echo "Linux AppDir desktop entry was not published: $appdir_desktop" >&2
  exit 1
fi
if ! grep -qx 'Exec=AppRun %f' "$appdir_desktop"; then
  echo "Linux AppDir desktop entry must preserve file arguments with Exec=AppRun %f." >&2
  exit 1
fi
if ! grep -qx 'Icon=app.konyak.Konyak' "$appdir_desktop"; then
  echo "Linux AppDir desktop entry must reference the Konyak icon name." >&2
  exit 1
fi
for icon_file in "$appdir/.DirIcon" "$appdir/app.konyak.Konyak.png"; do
  if [[ ! -f "$icon_file" ]]; then
    echo "Linux AppDir icon was not published: $icon_file" >&2
    exit 1
  fi
done

echo "Linux release metadata smoke passed."
