#!/usr/bin/env zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd -P)"
fixture_root="$repo_root/tests/fixtures/windows/profile_install"
output_root="$repo_root/.dart_tool/konyak/profile-install-fixture"
x64_cc="${KONYAK_PROFILE_FIXTURE_X64_CC:-x86_64-w64-mingw32-gcc}"
x64_windres="${KONYAK_PROFILE_FIXTURE_X64_WINDRES:-x86_64-w64-mingw32-windres}"
x86_cc="${KONYAK_PROFILE_FIXTURE_X86_CC:-i686-w64-mingw32-gcc}"
fixture_url="https://127.0.0.1:18443"
export SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-1}"

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

for required_command in "$x64_cc" "$x64_windres" "$x86_cc" jq sha256sum; do
  if ! command -v "$required_command" >/dev/null 2>&1; then
    echo "Missing $required_command. Run this script inside nix develop." >&2
    exit 69
  fi
done

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
