#!/usr/bin/env zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd -P)"
fixture_root="$repo_root/tests/fixtures/windows/profile_install"
default_output_root="$repo_root/.dart_tool/konyak/profile-install-fixture"
output_root="$default_output_root"
owner_marker_name=".konyak-profile-install-fixture-root"
owner_marker_value="konyak-profile-install-fixture-v1"
x64_cc="${KONYAK_PROFILE_FIXTURE_X64_CC:-x86_64-w64-mingw32-gcc}"
x64_windres="${KONYAK_PROFILE_FIXTURE_X64_WINDRES:-x86_64-w64-mingw32-windres}"
x86_cc="${KONYAK_PROFILE_FIXTURE_X86_CC:-i686-w64-mingw32-gcc}"
fixture_https_port="${KONYAK_PROFILE_INSTALL_FIXTURE_HTTPS_PORT:-18443}"
export SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-1}"

resolve_physical_path_allow_missing() {
  python3 -c \
    'import os, sys; print(os.path.realpath(sys.argv[1], strict=False))' \
    "$1"
}

resolve_lexical_absolute_path() {
  python3 -c 'import os, sys; print(os.path.abspath(sys.argv[1]))' "$1"
}

resolve_owned_destructive_root() {
  local candidate="$1"
  local legacy_default_root="$2"
  local marker_name="$3"
  local marker_value="$4"
  local resolved_candidate
  local resolved_default_root
  local resolved_repo_root
  local resolved_home
  local lexical_default_root
  local lexical_repo_root
  local remaining_default_path
  local default_path_component
  local current_default_path
  local protected_root
  local legacy_default_is_trusted=false
  local legacy_default_has_symlink=false

  if [[ -z "$candidate" || -L "$candidate" ]]; then
    echo "Destructive root must be a non-symlink path: $candidate" >&2
    return 64
  fi
  resolved_candidate="$(resolve_physical_path_allow_missing "$candidate")" || return 64
  resolved_default_root="$(resolve_physical_path_allow_missing "$legacy_default_root")" || return 64
  resolved_repo_root="$(resolve_physical_path_allow_missing "$repo_root")" || return 64
  resolved_home="$(resolve_physical_path_allow_missing "$HOME")" || return 64
  lexical_default_root="$(resolve_lexical_absolute_path "$legacy_default_root")" || return 64
  lexical_repo_root="$(resolve_lexical_absolute_path "$repo_root")" || return 64
  case "$lexical_default_root" in
    "$lexical_repo_root"/*)
      remaining_default_path="${lexical_default_root#"$lexical_repo_root"/}"
      current_default_path="$lexical_repo_root"
      while [[ -n "$remaining_default_path" ]]; do
        if [[ "$remaining_default_path" == */* ]]; then
          default_path_component="${remaining_default_path%%/*}"
          remaining_default_path="${remaining_default_path#*/}"
        else
          default_path_component="$remaining_default_path"
          remaining_default_path=""
        fi
        current_default_path="$current_default_path/$default_path_component"
        if [[ -L "$current_default_path" ]]; then
          legacy_default_has_symlink=true
          break
        fi
      done
      if [[ "$legacy_default_has_symlink" == false ]]; then
        case "$resolved_default_root" in
          "$resolved_repo_root"/*) legacy_default_is_trusted=true ;;
        esac
      fi
      ;;
  esac
  for protected_root in / "$resolved_repo_root" "$resolved_home"; do
    if [[ "$resolved_candidate" == "$protected_root" ]]; then
      echo "Refusing protected destructive root: $resolved_candidate" >&2
      return 64
    fi
  done
  if [[ -e "$resolved_candidate" ]]; then
    if [[ ! -d "$resolved_candidate" ]]; then
      echo "Destructive root exists but is not a directory: $resolved_candidate" >&2
      return 64
    fi
    if [[ "$resolved_candidate" != "$resolved_default_root" ]] ||
      [[ "$legacy_default_is_trusted" != true ]]; then
      local marker_path="$resolved_candidate/$marker_name"
      if [[ ! -f "$marker_path" || -L "$marker_path" ]] ||
        [[ "$(<"$marker_path")" != "$marker_value" ]]; then
        echo "Refusing existing unowned destructive root: $resolved_candidate" >&2
        return 64
      fi
    fi
  fi
  print -r -- "$resolved_candidate"
}

validate_fixture_https_port() {
  local port="$1"
  case "$port" in
    '' | *[^0-9]*)
      echo "Profile fixture HTTPS port must be an integer from 1 to 65535: $port" >&2
      return 64
      ;;
  esac
  if (( port < 1 || port > 65535 )); then
    echo "Profile fixture HTTPS port must be an integer from 1 to 65535: $port" >&2
    return 64
  fi
}

while (( $# > 0 )); do
  case "$1" in
    --output)
      if (( $# < 2 )) || [[ -z "$2" ]]; then
        echo "--output requires a path." >&2
        exit 64
      fi
      output_root="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 64
      ;;
  esac
done

validate_fixture_https_port "$fixture_https_port"
fixture_url="https://127.0.0.1:$fixture_https_port"

for required_command in "$x64_cc" "$x64_windres" "$x86_cc" jq python3 sha256sum; do
  if ! command -v "$required_command" >/dev/null 2>&1; then
    echo "Missing $required_command. Run this script inside nix develop." >&2
    exit 69
  fi
done

output_root="$(resolve_owned_destructive_root \
  "$output_root" \
  "$default_output_root" \
  "$owner_marker_name" \
  "$owner_marker_value")"
payload_root="$output_root/payloads"
profile_root="$output_root/profiles"
build_root="$output_root/build"
rm -rf "$output_root"
mkdir -p \
  "$payload_root" \
  "$profile_root/success" \
  "$profile_root/bad-installer-digest" \
  "$profile_root/bad-native-digest" \
  "$profile_root/manual" \
  "$build_root"
print -r -- "$owner_marker_value" >"$output_root/$owner_marker_name"
cp "$repo_root/LICENSE" "$output_root/LICENSE"

common_flags=(
  -std=c11
  -Wall
  -Wextra
  -Werror
  -O2
  -municode
  -Wl,--no-insert-timestamp
)

"$x64_cc" "${common_flags[@]}" \
  "$fixture_root/child.c" \
  -o "$build_root/profile_fixture_child.exe"

"$x64_cc" "${common_flags[@]}" \
  "$fixture_root/launcher.c" \
  -o "$build_root/profile_fixture_launcher.exe"

resource_file="$build_root/installer-resources.rc"
resource_object="$build_root/installer-resources.o"
resource_launcher="$build_root/profile_fixture_launcher.exe"
resource_child="$build_root/profile_fixture_child.exe"
{
  print -r -- "101 RCDATA \"$resource_launcher\""
  print -r -- "102 RCDATA \"$resource_child\""
} >"$resource_file"
"$x64_windres" "$resource_file" "$resource_object"

"$x64_cc" "${common_flags[@]}" \
  "$fixture_root/installer.c" \
  "$resource_object" \
  -lole32 \
  -luuid \
  -lshell32 \
  -o "$payload_root/profile_fixture_installer.exe"

"$x86_cc" \
  -std=c11 \
  -Wall \
  -Wextra \
  -Werror \
  -O2 \
  -shared \
  -Wl,--no-insert-timestamp \
  "$fixture_root/native_dll.c" \
  -o "$payload_root/profile_fixture_x86.dll"

"$x64_cc" \
  -std=c11 \
  -Wall \
  -Wextra \
  -Werror \
  -O2 \
  -shared \
  -Wl,--no-insert-timestamp \
  "$fixture_root/native_dll.c" \
  -o "$payload_root/profile_fixture_x64.dll"

installer_digest="$(sha256sum "$payload_root/profile_fixture_installer.exe" | cut -d ' ' -f 1)"
x86_digest="$(sha256sum "$payload_root/profile_fixture_x86.dll" | cut -d ' ' -f 1)"
x64_digest="$(sha256sum "$payload_root/profile_fixture_x64.dll" | cut -d ' ' -f 1)"
bad_digest="$(printf '0%.0s' {1..64})"

render_profile() {
  local target="$1"
  local profile_id="$2"
  local profile_name="$3"
  local installer_sha="$4"
  local x86_sha="$5"

  jq \
    --arg id "$profile_id" \
    --arg name "$profile_name" \
    --arg installerUrl "$fixture_url/profile_fixture_installer.exe" \
    --arg installerSha "$installer_sha" \
    --arg x86Url "$fixture_url/profile_fixture_x86.dll" \
    --arg x86Sha "$x86_sha" \
    --arg x64Url "$fixture_url/profile_fixture_x64.dll" \
    --arg x64Sha "$x64_digest" \
    '
      .id = $id |
      .name = $name |
      .compatibilityProfile.id = $id |
      .installerResource.url = $installerUrl |
      .installerResource.sha256 = $installerSha |
      .preInstallActions[1].resource.url = $x86Url |
      .preInstallActions[1].resource.sha256 = $x86Sha |
      .preInstallActions[2].resource.url = $x64Url |
      .preInstallActions[2].resource.sha256 = $x64Sha
    ' \
    "$fixture_root/profile.template.json" >"$target"
}

render_variant() {
  local target="$1"
  local overlay="$2"
  local profile_id
  local profile_name
  local digest_target
  local installer_sha="$installer_digest"
  local x86_sha="$x86_digest"
  profile_id="$(jq -er .id "$overlay")"
  profile_name="$(jq -er .name "$overlay")"
  digest_target="$(jq -er .digestTarget "$overlay")"
  case "$digest_target" in
    installer)
      installer_sha="$bad_digest"
      ;;
    x86NativeDll)
      x86_sha="$bad_digest"
      ;;
    none)
      ;;
    *)
      echo "Unknown profile fixture digest target: $digest_target" >&2
      exit 65
      ;;
  esac
  render_profile "$target" "$profile_id" "$profile_name" \
    "$installer_sha" "$x86_sha"
}

render_profile \
  "$profile_root/success/profile.json" \
  profile-install-fixture \
  "Konyak Profile Install Fixture" \
  "$installer_digest" \
  "$x86_digest"
render_variant \
  "$profile_root/bad-installer-digest/profile.json" \
  "$fixture_root/profile-bad-installer-digest.template.json"
render_variant \
  "$profile_root/bad-native-digest/profile.json" \
  "$fixture_root/profile-bad-native-digest.template.json"
render_variant \
  "$profile_root/manual/profile.json" \
  "$fixture_root/profile-manual.template.json"

jq -n \
  --arg installerSha256 "$installer_digest" \
  --arg x86DllSha256 "$x86_digest" \
  --arg x64DllSha256 "$x64_digest" \
  '{
    schemaVersion: 1,
    installerSha256: $installerSha256,
    x86DllSha256: $x86DllSha256,
    x64DllSha256: $x64DllSha256
  }' >"$output_root/fixture-manifest.json"

printf '%s\n' "$output_root"
