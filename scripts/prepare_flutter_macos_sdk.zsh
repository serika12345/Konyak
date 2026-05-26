#!/usr/bin/env zsh
emulate -L zsh
set -euo pipefail
setopt NULL_GLOB

readonly ROOT="${0:A:h:h}"
readonly LOCAL_SDK="${ROOT}/.dart_tool/konyak/flutter-sdk"
readonly VSCODE_BIN="${ROOT}/.dart_tool/konyak/vscode-bin"
readonly MARKER="${LOCAL_SDK}/.konyak-source-root"
readonly FLUTTER_PROJECT="${ROOT}/apps/konyak"
readonly MACOS_ENGINE_ARTIFACTS=(
  darwin-x64
  darwin-x64-profile
  darwin-x64-release
)

print_sdk_path=false
force=false

for arg in "$@"; do
  case "${arg}" in
    --print-sdk-path)
      print_sdk_path=true
      ;;
    --force)
      force=true
      ;;
    *)
      print -u2 "unknown argument: ${arg}"
      exit 64
      ;;
  esac
done

system_path() {
  print -r -- "/usr/bin:/bin:/usr/sbin:/sbin:${PATH}"
}

resolve_bash_path() {
  local bash_path
  bash_path="$(PATH="$(system_path)" command -v bash || true)"
  if [[ -z "${bash_path}" ]]; then
    print -u2 "bash not found. Run this script inside nix develop."
    exit 69
  fi

  print -r -- "${bash_path}"
}

source_flutter_root() {
  local flutter_bin
  flutter_bin="$(PATH="$(system_path)" command -v flutter)"
  if [[ -z "${flutter_bin}" ]]; then
    print -u2 "flutter not found. Run this script inside nix develop."
    exit 69
  fi

  dirname "$(dirname "$(readlink -f "${flutter_bin}")")"
}

is_prepared() {
  local source_root="$1"

  [[ "${force}" == false ]] || return 1
  [[ -f "${MARKER}" ]] || return 1
  [[ "$(cat "${MARKER}")" == "${source_root}" ]] || return 1
  [[ -x "${LOCAL_SDK}/bin/flutter" ]] || return 1
  [[ -d "${LOCAL_SDK}/bin/cache/artifacts/engine/darwin-x64/FlutterMacOS.xcframework" ]] || return 1
  [[ ! -L "${LOCAL_SDK}/bin/cache/artifacts/engine/darwin-x64/FlutterMacOS.xcframework" ]] || return 1
}

reset_local_sdk() {
  if [[ -e "${LOCAL_SDK}" ]]; then
    chmod -R u+rwX "${LOCAL_SDK}" 2>/dev/null || true
    rm -rf "${LOCAL_SDK}"
  fi

  mkdir -p \
    "${LOCAL_SDK}" \
    "${LOCAL_SDK}/bin" \
    "${LOCAL_SDK}/bin/cache" \
    "${LOCAL_SDK}/bin/cache/artifacts" \
    "${LOCAL_SDK}/bin/cache/artifacts/engine"
}

link_entries_except() {
  local source_dir="$1"
  local target_dir="$2"
  shift 2
  local excluded=("$@")

  local entry name excluded_name should_skip
  for entry in "${source_dir}"/* "${source_dir}"/.[!.]* "${source_dir}"/..?*; do
    [[ -e "${entry}" ]] || continue
    name="${entry:t}"
    should_skip=false

    for excluded_name in "${excluded[@]}"; do
      if [[ "${name}" == "${excluded_name}" ]]; then
        should_skip=true
        break
      fi
    done

    [[ "${should_skip}" == false ]] || continue
    ln -s "${entry}" "${target_dir}/${name}"
  done
}

write_flutter_wrapper() {
  local source_root="$1"
  local wrapped_flutter="${source_root}/bin/.flutter-wrapped"
  local bash_path
  bash_path="$(resolve_bash_path)"

  cat >"${LOCAL_SDK}/bin/flutter" <<EOF
#!${bash_path}
set -euo pipefail

export FLUTTER_ROOT="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")/.." && pwd)"
vscode_bin="\$(cd "\${FLUTTER_ROOT}/.." && pwd)/vscode-bin"

clean_env=(
  "HOME=\${HOME:-}"
  "USER=\${USER:-}"
  "TMPDIR=\${TMPDIR:-/tmp}"
  "LANG=\${LANG:-en_US.UTF-8}"
  "SHELL=\${SHELL:-/bin/zsh}"
  "FLUTTER_ROOT=\${FLUTTER_ROOT}"
  "DEVELOPER_DIR=\${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
  "PATH=\${vscode_bin}:/usr/bin:/bin:/usr/sbin:/sbin:\${FLUTTER_ROOT}/bin:\${PATH:-}"
)

for name in \\
  FLUTTER_HOST \\
  PUB_ENVIRONMENT \\
  PUB_CACHE \\
  CI \\
  NO_COLOR \\
  HTTP_PROXY \\
  HTTPS_PROXY \\
  ALL_PROXY \\
  NO_PROXY \\
  http_proxy \\
  https_proxy \\
  all_proxy \\
  no_proxy; do
  if [ -n "\${!name+x}" ]; then
    clean_env+=("\${name}=\${!name}")
  fi
done

while IFS= read -r name; do
  case "\${name}" in
    DASH__*) clean_env+=("\${name}=\${!name}") ;;
  esac
done < <(compgen -e)

exec /usr/bin/env -i "\${clean_env[@]}" "${wrapped_flutter}" "\$@"
EOF

  chmod +x "${LOCAL_SDK}/bin/flutter"
}

materialize_nix_store_symlinks() {
  local artifact_root="$1"
  local link target tmp

  chmod -R u+rwX "${artifact_root}"

  while IFS= read -r -d $'\0' link; do
    target="$(readlink "${link}")"
    case "${target}" in
      /nix/store/*)
        tmp="${link}.materialized"
        rm -rf "${tmp}"
        cp -R "${target}" "${tmp}"
        chmod -R u+rwX "${tmp}"
        rm "${link}"
        mv "${tmp}" "${link}"
        ;;
    esac
  done < <(find "${artifact_root}" -type l -print0)

  chmod -R u+rwX "${artifact_root}"
}

copy_engine_artifacts() {
  local source_root="$1"
  local engine_source="${source_root}/bin/cache/artifacts/engine"
  local engine_target="${LOCAL_SDK}/bin/cache/artifacts/engine"
  local entry name

  for entry in "${engine_source}"/*; do
    [[ -e "${entry}" ]] || continue
    name="${entry:t}"

    if (( ${MACOS_ENGINE_ARTIFACTS[(Ie)${name}]} )); then
      cp -R "${entry}" "${engine_target}/${name}"
      materialize_nix_store_symlinks "${engine_target}/${name}"
    else
      ln -s "${entry}" "${engine_target}/${name}"
    fi
  done
}

prepare_sdk() {
  local source_root="$1"

  reset_local_sdk
  link_entries_except "${source_root}" "${LOCAL_SDK}" bin
  link_entries_except "${source_root}/bin" "${LOCAL_SDK}/bin" cache flutter
  write_flutter_wrapper "${source_root}"
  link_entries_except "${source_root}/bin/cache" "${LOCAL_SDK}/bin/cache" artifacts
  link_entries_except "${source_root}/bin/cache/artifacts" "${LOCAL_SDK}/bin/cache/artifacts" engine
  copy_engine_artifacts "${source_root}"
  print -r -- "${source_root}" >"${MARKER}"
}

repair_flutter_project_permissions() {
  local macos_project="${FLUTTER_PROJECT}/macos"

  [[ -d "${macos_project}" ]] || return
  chmod -R u+rwX "${macos_project}"
}

write_vscode_tool_shims() {
  local tool tool_path

  mkdir -p "${VSCODE_BIN}"

  for tool in pod ruby gem; do
    tool_path="$(PATH="$(system_path)" command -v "${tool}" || true)"
    [[ -n "${tool_path}" ]] || continue
    ln -sfn "${tool_path}" "${VSCODE_BIN}/${tool}"
  done
}

main() {
  local source_root
  source_root="$(source_flutter_root)"

  if ! is_prepared "${source_root}"; then
    prepare_sdk "${source_root}"
  else
    write_flutter_wrapper "${source_root}"
  fi
  repair_flutter_project_permissions
  write_vscode_tool_shims

  if [[ "${print_sdk_path}" == true ]]; then
    print -r -- "${LOCAL_SDK}"
  fi
}

main
