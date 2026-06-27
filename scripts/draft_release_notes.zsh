#!/usr/bin/env zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd -P)"
cd "$repo_root"

version="${1:-}"
version="${version#v}"
notes_path="${KONYAK_RELEASE_NOTES_DRAFT:-$repo_root/.dart_tool/konyak/release-notes.md}"

if [[ -z "$version" ]]; then
  echo "Usage: $0 <version>" >&2
  exit 64
fi

if [[ ! "$version" =~ '^[0-9]+\.[0-9]+\.[0-9]+$' ]]; then
  echo "Release version must be X.Y.Z or vX.Y.Z: $version" >&2
  exit 64
fi

mkdir -p "${notes_path:h}"

if [[ ! -f "$notes_path" ]]; then
  cat >"$notes_path" <<EOF
## Highlights

- Add release highlights here.

## Verification

- Add release verification notes here.
EOF
fi

echo "Release notes draft: $notes_path"
if command -v code >/dev/null 2>&1; then
  code -r "$notes_path" || true
else
  echo "Open this file in VSCode, edit it, then run the release task."
fi
