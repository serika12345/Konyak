#!/usr/bin/env zsh
emulate -L zsh
set -euo pipefail

readonly ROOT="${0:A:h:h}"

source_flutter_root() {
  local flutter_bin
  flutter_bin="$(command -v flutter || true)"
  if [[ -z "${flutter_bin}" ]]; then
    print -u2 "flutter not found. Run this command inside nix develop."
    exit 69
  fi

  dirname "$(dirname "$(readlink -f "${flutter_bin}")")"
}

main() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    "${ROOT}/scripts/prepare_flutter_macos_sdk.zsh" --print-sdk-path
    return
  fi

  source_flutter_root
}

main "$@"
