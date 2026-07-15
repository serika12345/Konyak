#!/usr/bin/env zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd -P)"
cli_dir="$repo_root/packages/konyak_cli"
fixture_source="$repo_root/tests/fixtures/windows/profile_install"
fixture_root="${KONYAK_PROFILE_INSTALL_FIXTURE_ROOT:-$repo_root/.dart_tool/konyak/profile-install-fixture}"
default_work_root="$repo_root/.dart_tool/konyak/macos-profile-install-cli-smoke"
work_root="${KONYAK_MACOS_PROFILE_INSTALL_SMOKE_WORK_ROOT:-$default_work_root}"
runtime_root="${KONYAK_MACOS_PROFILE_INSTALL_SMOKE_RUNTIME_ROOT:-$work_root/runtime/macos-wine}"
command_timeout="${KONYAK_MACOS_PROFILE_INSTALL_SMOKE_COMMAND_TIMEOUT:-300s}"
install_timeout="${KONYAK_MACOS_PROFILE_INSTALL_SMOKE_INSTALL_TIMEOUT:-1200s}"
profile_timeout="${KONYAK_MACOS_PROFILE_INSTALL_SMOKE_PROFILE_TIMEOUT:-1200s}"
cleanup_timeout="${KONYAK_MACOS_PROFILE_INSTALL_SMOKE_CLEANUP_TIMEOUT:-60s}"
build_fixture="${KONYAK_MACOS_PROFILE_INSTALL_SMOKE_BUILD_FIXTURE:-true}"
install_runtime="${KONYAK_MACOS_PROFILE_INSTALL_SMOKE_INSTALL_RUNTIME:-true}"
fixture_https_port="${KONYAK_MACOS_PROFILE_INSTALL_SMOKE_HTTPS_PORT:-18443}"
fixture_url="https://127.0.0.1:$fixture_https_port"
owner_marker_name=".konyak-macos-profile-install-smoke-root"
owner_marker_value="konyak-macos-profile-install-smoke-v1"
https_server_pid=""
active_profile_directory=""
captured_stdout_path=""
captured_stderr_path=""
captured_exit_code=0
created_bottle_ids=()

resolve_physical_path_allow_missing() {
  python3 -c \
    'import os, sys; print(os.path.realpath(sys.argv[1]))' \
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

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "macOS profile-install CLI smoke is supported on macOS only." >&2
  exit 2
fi

for required_command in curl dart jq openssl python3 sha256sum timeout; do
  if ! command -v "$required_command" >/dev/null 2>&1; then
    echo "Missing $required_command. Run this script inside nix develop." >&2
    exit 69
  fi
done

validate_fixture_https_port "$fixture_https_port"
resolved_work_root="$(resolve_owned_destructive_root \
  "$work_root" \
  "$default_work_root" \
  "$owner_marker_name" \
  "$owner_marker_value")"
resolved_runtime_root="$(resolve_physical_path_allow_missing "$runtime_root")" || exit 64
case "$resolved_runtime_root" in
  "$resolved_work_root"/*) ;;
  *)
    echo "Profile-install smoke runtime root must resolve below its work root." >&2
    echo "Work root: $resolved_work_root" >&2
    echo "Runtime root: $resolved_runtime_root" >&2
    exit 64
    ;;
esac
work_root="$resolved_work_root"
runtime_root="$resolved_runtime_root"
logs_dir="$work_root/logs"
certificate_dir="$work_root/private-https"
data_home="$work_root/data"
config_home="$work_root/config"
home_dir="$work_root/home"
launcher_home="$work_root/pinned-launchers"
resource_cache="$work_root/resource-cache"
request_log="$logs_dir/https-requests.jsonl"
runtime_source_root="$work_root/dev-runtime-source"
runtime_manifest_cache="$runtime_source_root/konyak-macos-wine-runtime-stack-source.json"

resolve_runtime_manifest() {
  local manifest_source="$1"
  env \
    KONYAK_DEV_MACOS_WINE_STACK_MANIFEST="$manifest_source" \
    KONYAK_DEV_MACOS_RUNTIME_SOURCE_ROOT="$runtime_source_root" \
    KONYAK_DEV_MACOS_WINE_STACK_MANIFEST_CACHE="$runtime_manifest_cache" \
    "$repo_root/scripts/prepare_macos_dev_runtime_stack.zsh" \
      --force \
      --print-manifest-path
}

write_smoke_result() {
  local original_exit="$1"
  local cleanup_failed="$2"
  local final_exit="$3"
  local result_path="$logs_dir/smoke-result.json"
  local temporary_path="$logs_dir/.smoke-result.json.tmp.$$"
  rm -f "$temporary_path"
  if ! jq -n \
    --arg endedAtUtc "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
    --argjson originalExitCode "$original_exit" \
    --argjson cleanupFailed "$cleanup_failed" \
    --argjson exitCode "$final_exit" \
    '{
      schemaVersion: 1,
      endedAtUtc: $endedAtUtc,
      originalExitCode: $originalExitCode,
      cleanupFailed: $cleanupFailed,
      exitCode: $exitCode
    }' >"$temporary_path"; then
    rm -f "$temporary_path"
    return 1
  fi
  if ! mv -f "$temporary_path" "$result_path"; then
    rm -f "$temporary_path"
    return 1
  fi
}

cleanup() {
  local original_exit=$?
  local bottle_id
  local cleanup_failed=false
  local cleanup_failure_exit=70
  local final_exit="$original_exit"
  trap - EXIT INT TERM
  set +e
  for bottle_id in "${created_bottle_ids[@]}"; do
    if ! best_effort_terminate_bottle "$bottle_id"; then
      cleanup_failed=true
    fi
  done
  if [[ -n "$https_server_pid" ]]; then
    kill "$https_server_pid" >/dev/null 2>&1 || true
    wait "$https_server_pid" >/dev/null 2>&1 || true
  fi
  rm -rf "$certificate_dir"
  if (( original_exit == 0 )) && [[ "$cleanup_failed" == true ]]; then
    final_exit="$cleanup_failure_exit"
  fi
  if ! write_smoke_result "$original_exit" "$cleanup_failed" "$final_exit"; then
    if (( original_exit == 0 )); then
      final_exit="$cleanup_failure_exit"
    fi
  fi
  exit "$final_exit"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

rm -rf "$data_home" "$config_home" "$home_dir" "$launcher_home" \
  "$resource_cache" "$runtime_source_root" "$logs_dir" "$certificate_dir"
mkdir -p "$work_root" "$logs_dir" "$certificate_dir" "$runtime_root:h" \
  "$home_dir" "$launcher_home"
print -r -- "$owner_marker_value" >"$work_root/$owner_marker_name"
chmod 0700 "$certificate_dir"
jq -n \
  --arg startedAtUtc "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
  --arg host "$(uname -a)" \
  --arg workRoot "$work_root" \
  --arg runtimeRoot "$runtime_root" \
  --arg runtimeSourceRoot "$runtime_source_root" \
  --arg runtimeManifestCache "$runtime_manifest_cache" \
  --arg dataHome "$data_home" \
  --arg fixtureRoot "$fixture_root" \
  --arg fixtureUrl "$fixture_url" \
  '{
    schemaVersion: 1,
    startedAtUtc: $startedAtUtc,
    host: $host,
    workRoot: $workRoot,
    runtimeRoot: $runtimeRoot,
    runtimeSourceRoot: $runtimeSourceRoot,
    runtimeManifestCache: $runtimeManifestCache,
    dataHome: $dataHome,
    fixtureRoot: $fixtureRoot,
    fixtureUrl: $fixtureUrl
  }' >"$logs_dir/context.json"

if [[ "$build_fixture" == "true" ]]; then
  env \
    KONYAK_PROFILE_INSTALL_FIXTURE_HTTPS_PORT="$fixture_https_port" \
    "$repo_root/scripts/build_profile_install_fixture_windows.zsh" \
      --output "$fixture_root" >"$logs_dir/fixture-build.stdout" \
      2>"$logs_dir/fixture-build.stderr"
fi
if [[ ! -f "$fixture_root/fixture-manifest.json" ]]; then
  echo "Profile-install fixture is missing: $fixture_root" >&2
  exit 66
fi

assert_fixture_urls_match_server() {
  local profile_path
  local -a profile_paths=("$fixture_root"/profiles/*/profile.json(N))
  if (( ${#profile_paths} == 0 )); then
    echo "Profile-install fixture does not contain any profile records." >&2
    exit 66
  fi
  for profile_path in "${profile_paths[@]}"; do
    if ! jq -e \
      --arg fixtureUrl "$fixture_url" \
      '
        .installerResource.url == ($fixtureUrl + "/profile_fixture_installer.exe") and
        .preInstallActions[1].resource.url == ($fixtureUrl + "/profile_fixture_x86.dll") and
        .preInstallActions[2].resource.url == ($fixtureUrl + "/profile_fixture_x64.dll")
      ' "$profile_path" >/dev/null; then
      echo "Fixture profile URLs do not match the selected local HTTPS server: $profile_path" >&2
      exit 65
    fi
  done
}
assert_fixture_urls_match_server

(
  cd "$cli_dir"
  dart pub get
  dart run build_runner build
)

ca_key="$certificate_dir/ca-key.pem"
ca_certificate="$certificate_dir/ca.pem"
ca_bundle="$certificate_dir/ca-bundle.pem"
server_key="$certificate_dir/server-key.pem"
server_request="$certificate_dir/server.csr"
server_certificate="$certificate_dir/server.pem"
server_extensions="$certificate_dir/server-extensions.cnf"

openssl req \
  -x509 \
  -newkey rsa:2048 \
  -nodes \
  -days 1 \
  -subj '/CN=Konyak Profile Fixture CA' \
  -addext 'basicConstraints=critical,CA:TRUE' \
  -addext 'keyUsage=critical,keyCertSign,cRLSign' \
  -keyout "$ca_key" \
  -out "$ca_certificate" >/dev/null 2>&1
openssl req \
  -newkey rsa:2048 \
  -nodes \
  -subj '/CN=127.0.0.1' \
  -keyout "$server_key" \
  -out "$server_request" >/dev/null 2>&1
{
  print 'subjectAltName=IP:127.0.0.1'
  print 'basicConstraints=critical,CA:FALSE'
  print 'keyUsage=critical,digitalSignature,keyEncipherment'
  print 'extendedKeyUsage=serverAuth'
} >"$server_extensions"
openssl x509 \
  -req \
  -in "$server_request" \
  -CA "$ca_certificate" \
  -CAkey "$ca_key" \
  -CAcreateserial \
  -days 1 \
  -extfile "$server_extensions" \
  -out "$server_certificate" >/dev/null 2>&1

system_ca_bundle="${NIX_SSL_CERT_FILE:-/etc/ssl/certs/ca-certificates.crt}"
if [[ ! -f "$system_ca_bundle" ]]; then
  echo "System CA bundle is missing: $system_ca_bundle" >&2
  exit 66
fi
cp "$system_ca_bundle" "$ca_bundle"
chmod 0600 "$ca_bundle"
printf '\n' >>"$ca_bundle"
openssl x509 -in "$ca_certificate" -outform PEM >>"$ca_bundle"

python3 - "$fixture_https_port" <<'PY'
import socket as socket_module
import sys

with socket_module.socket(socket_module.AF_INET, socket_module.SOCK_STREAM) as socket:
    socket.bind(("127.0.0.1", int(sys.argv[1])))
PY

python3 "$fixture_source/https_server.py" \
  --directory "$fixture_root/payloads" \
  --certificate "$server_certificate" \
  --key "$server_key" \
  --request-log "$request_log" \
  --port "$fixture_https_port" \
  >"$logs_dir/https-server.stdout" \
  2>"$logs_dir/https-server.stderr" &
https_server_pid=$!

for _ in {1..30}; do
  if curl \
    --fail \
    --silent \
    --show-error \
    --cacert "$ca_certificate" \
    "$fixture_url/health" >/dev/null; then
    break
  fi
  sleep 1
done
if ! curl \
  --fail \
  --silent \
  --show-error \
  --cacert "$ca_certificate" \
  "$fixture_url/health" >/dev/null; then
  echo "Local profile fixture HTTPS server did not become ready." >&2
  exit 1
fi

run_cli() {
  local label="$1"
  local timeout_value="$2"
  shift 2
  captured_stdout_path="$logs_dir/$label.stdout"
  captured_stderr_path="$logs_dir/$label.stderr"

  echo "Running konyak $*" >&2
  jq -cn \
    --arg timestamp "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
    --arg label "$label" \
    --arg workingDirectory "$cli_dir" \
    --arg executable "$(command -v dart)" \
    --arg runtimeRoot "$runtime_root" \
    --arg dataHome "$data_home" \
    --arg profileDirectory "$active_profile_directory" \
    --args \
    '{
      timestamp: $timestamp,
      label: $label,
      workingDirectory: $workingDirectory,
      executable: $executable,
      runtimeRoot: $runtimeRoot,
      dataHome: $dataHome,
      profileDirectory: $profileDirectory,
      argv: ([$executable, "run", "bin/konyak.dart"] + $ARGS.positional)
    }' \
    -- "$@" >>"$logs_dir/commands.jsonl"
  set +e
  (
    cd "$cli_dir"
    env \
      HOME="$home_dir" \
      CURL_CA_BUNDLE="$ca_bundle" \
      KONYAK_RUNTIME_PROFILE=development \
      KONYAK_MACOS_WINE_HOME="$runtime_root" \
      KONYAK_DATA_HOME="$data_home" \
      KONYAK_CONFIG_HOME="$config_home" \
      KONYAK_PROFILE_DIRECTORY="$active_profile_directory" \
      KONYAK_PROFILE_INSTALLER_CACHE_HOME="$resource_cache" \
      KONYAK_MACOS_PINNED_LAUNCHERS_HOME="$launcher_home" \
      KONYAK_PINNED_PROGRAM_LAUNCHER_EXECUTABLE="$(command -v dart)" \
      KONYAK_PINNED_PROGRAM_LAUNCHER_ARGUMENTS_JSON='["run","bin/konyak.dart"]' \
      KONYAK_PINNED_PROGRAM_LAUNCHER_WORKING_DIRECTORY="$cli_dir" \
      timeout "$timeout_value" dart run bin/konyak.dart "$@"
  ) >"$captured_stdout_path" 2>"$captured_stderr_path"
  captured_exit_code=$?
  set -e
}

best_effort_terminate_bottle() {
  local bottle_id="$1"
  local label="cleanup-terminate-$bottle_id"
  local previous_profile_directory="$active_profile_directory"
  local termination_exit_code
  local evidence_exit_code=0
  active_profile_directory="$fixture_root/profiles/success"
  captured_exit_code=70
  run_cli "$label" "$cleanup_timeout" \
    terminate-wine-processes \
    --bottle "$bottle_id" \
    --json || true
  termination_exit_code="$captured_exit_code"
  active_profile_directory="$previous_profile_directory"
  set +e
  jq -n \
    --arg bottleId "$bottle_id" \
    --argjson exitCode "$termination_exit_code" \
    --arg stdoutPath "$label.stdout" \
    --arg stderrPath "$label.stderr" \
    '{
      schemaVersion: 1,
      bottleId: $bottleId,
      exitCode: $exitCode,
      stdoutPath: $stdoutPath,
      stderrPath: $stderrPath
    }' >"$logs_dir/cleanup-terminate-$bottle_id.result.json" || evidence_exit_code=$?
  if (( termination_exit_code != 0 || evidence_exit_code != 0 )); then
    return 1
  fi
  return 0
}

run_cli_success() {
  local label="$1"
  local timeout_value="$2"
  shift 2
  run_cli "$label" "$timeout_value" "$@"
  if (( captured_exit_code != 0 )); then
    echo "konyak $* failed with exit code $captured_exit_code" >&2
    sed -n '1,200p' "$captured_stdout_path" >&2
    sed -n '1,200p' "$captured_stderr_path" >&2
    exit "$captured_exit_code"
  fi
}

run_cli_failure() {
  local label="$1"
  local timeout_value="$2"
  shift 2
  run_cli "$label" "$timeout_value" "$@"
  if (( captured_exit_code == 0 )); then
    echo "konyak $* unexpectedly succeeded." >&2
    sed -n '1,200p' "$captured_stdout_path" >&2
    exit 1
  fi
}

assert_jq() {
  local json_path="$1"
  local message="$2"
  shift 2
  if ! jq -e "$@" "$json_path" >/dev/null; then
    echo "$message" >&2
    jq '.' "$json_path" >&2 || sed -n '1,200p' "$json_path" >&2
    exit 1
  fi
}

last_json_line() {
  local source="$1"
  local target="$2"
  sed '/^[[:space:]]*$/d' "$source" | tail -n 1 >"$target"
  if [[ ! -s "$target" ]]; then
    echo "No JSON record was emitted in $source" >&2
    exit 1
  fi
}

assert_pe_machine() {
  local target_path="$1"
  local expected="$2"
  python3 - "$target_path" "$expected" <<'PY'
import pathlib
import struct
import sys

payload = pathlib.Path(sys.argv[1]).read_bytes()
offset = struct.unpack_from("<I", payload, 0x3C)[0]
assert payload[:2] == b"MZ" and payload[offset:offset + 4] == b"PE\0\0"
machine = struct.unpack_from("<H", payload, offset + 4)[0]
assert machine == int(sys.argv[2], 16), (hex(machine), sys.argv[2])
PY
}

assert_resource_cache_clean() {
  if [[ -d "$resource_cache" ]] &&
    [[ -n "$(find "$resource_cache" -mindepth 1 -print -quit)" ]]; then
    echo "Profile resource cache retained a staging artifact." >&2
    find "$resource_cache" -mindepth 1 -maxdepth 3 -print >&2
    exit 1
  fi
}

assert_profile_actions_metadata() {
  local metadata_path="$1"
  local expected_profile_id="$2"
  assert_jq "$metadata_path" \
    "Bottle metadata did not preserve complete pre-install actions in profile order." \
    --arg expectedProfileId "$expected_profile_id" \
    --arg fixtureUrl "$fixture_url" \
    --arg x86Digest "$(jq -r .x86DllSha256 "$fixture_root/fixture-manifest.json")" \
    --arg x64Digest "$(jq -r .x64DllSha256 "$fixture_root/fixture-manifest.json")" \
    '
      .schemaVersion == 1 and
      (.bottle.profiles | length) == 1 and
      .bottle.profiles[0].profileId == $expectedProfileId and
      .bottle.profiles[0].preInstallActions == [
        {kind: "winetricks", verb: "win10"},
        {
          kind: "nativeDll",
          componentId: "fixture-d3dcompiler-x86",
          machine: "x86",
          destination: "windowsSysWow64",
          targetFileName: "d3dcompiler_47.dll",
          resource: {
            kind: "https",
            url: ($fixtureUrl + "/profile_fixture_x86.dll"),
            sha256: $x86Digest,
            fileName: "profile_fixture_x86.dll"
          }
        },
        {
          kind: "nativeDll",
          componentId: "fixture-d3dcompiler-x64",
          machine: "x64",
          destination: "windowsSystem32",
          targetFileName: "d3dcompiler_47.dll",
          resource: {
            kind: "https",
            url: ($fixtureUrl + "/profile_fixture_x64.dll"),
            sha256: $x64Digest,
            fileName: "profile_fixture_x64.dll"
          }
        }
      ]
    '
}

file_identity() {
  python3 - "$1" <<'PY'
import os
import sys

stat = os.stat(sys.argv[1], follow_symlinks=False)
print(f"{stat.st_ino}:{stat.st_mtime_ns}:{stat.st_size}")
PY
}

snapshot_dll_overrides() {
  local bottle_root="$1"
  local output="$2"
  python3 - "$bottle_root" "$output" <<'PY'
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
output = pathlib.Path(sys.argv[2])
sections = []
for name in ("system.reg", "user.reg", "userdef.reg"):
    path = root / name
    collecting = False
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        if line.startswith("["):
            collecting = line.lower().startswith("[software\\\\wine\\\\dlloverrides]")
        elif collecting and line.startswith('"'):
            sections.append(f"{name}:{line}")
output.write_text("\n".join(sorted(sections)) + "\n", encoding="utf-8")
PY
}

snapshot_manual_invariants() {
  local bottle_root="$1"
  local output="$2"
  local evidence_root="$bottle_root/drive_c/konyak-profile-install-evidence"
  {
    for snapshot_path in \
      "$request_log" \
      "$bottle_root/winetricks.log" \
      "$bottle_root/system.reg" \
      "$bottle_root/user.reg" \
      "$bottle_root/userdef.reg" \
      "$bottle_root/drive_c/windows/syswow64/d3dcompiler_47.dll" \
      "$bottle_root/drive_c/windows/system32/d3dcompiler_47.dll" \
      "$evidence_root/installer-events.log" \
      "$evidence_root/launcher-events.log" \
      "$evidence_root/child-events.log"
    do
      sha256sum "$snapshot_path"
    done
  } | sed "s|$work_root|WORK_ROOT|g" >"$output"
}

active_profile_directory="$fixture_root/profiles/success"
manifest_source="${KONYAK_DEV_MACOS_WINE_STACK_MANIFEST:-${KONYAK_MACOS_WINE_STACK_MANIFEST:-}}"
manifest_path="$(resolve_runtime_manifest "$manifest_source")"
manifest_path="$(resolve_physical_path_allow_missing "$manifest_path")" || exit 64
if [[ ! -f "$manifest_path" ]]; then
  echo "macOS runtime source manifest is missing: $manifest_path" >&2
  exit 66
fi
cp "$manifest_path" "$logs_dir/runtime-source-manifest.json"
(
  cd "$logs_dir"
  sha256sum runtime-source-manifest.json >runtime-source-manifest.sha256
)

if [[ "$install_runtime" == "true" ]]; then
  run_cli_success install-runtime "$install_timeout" \
    install-macos-wine \
    --reinstall \
    --source-manifest "$manifest_path" \
    --progress-json \
    --json
  last_json_line "$captured_stdout_path" "$logs_dir/install-runtime.final.json"
  assert_jq "$logs_dir/install-runtime.final.json" \
    "Public runtime installation did not install the complete macOS runtime." \
    '.schemaVersion == 1 and .runtime.id == "konyak-macos-wine" and .runtime.isInstalled == true'
fi

created_bottle_ids+=(profile-fixture-failure)
run_cli_success create-failure-bottle "$profile_timeout" \
  create-bottle \
  --name "Profile Fixture Failure" \
  --windows-version win10 \
  --json
failure_bottle="$data_home/bottles/profile-fixture-failure"
failure_x86_target="$failure_bottle/drive_c/windows/syswow64/d3dcompiler_47.dll"
failure_x64_target="$failure_bottle/drive_c/windows/system32/d3dcompiler_47.dll"
failure_x86_digest_before="$(sha256sum "$failure_x86_target" | cut -d ' ' -f 1)"
failure_x64_digest_before="$(sha256sum "$failure_x64_target" | cut -d ' ' -f 1)"

: >"$request_log"
active_profile_directory="$fixture_root/profiles/bad-installer-digest"
run_cli_failure bad-installer-digest "$profile_timeout" \
  install-program-profile \
  profile-install-fixture-bad-installer-digest \
  --bottle profile-fixture-failure \
  --progress-json \
  --json
last_json_line "$captured_stdout_path" "$logs_dir/bad-installer-digest.final.json"
assert_jq "$logs_dir/bad-installer-digest.final.json" \
  "Installer digest mismatch was not rejected during verification." \
  '.error.code == "profileResourceDigestMismatch" and .error.programProfileInstall.stage == "verification"'
assert_resource_cache_clean
[[ ! -e "$failure_bottle/winetricks.log" ]]
[[ ! -e "$failure_bottle/drive_c/Program Files/Konyak Profile Fixture/profile_fixture_launcher.exe" ]]
[[ "$(jq -r 'select(.path == "/profile_fixture_installer.exe") | .path' "$request_log" | wc -l | tr -d ' ')" == 1 ]]

: >"$request_log"
active_profile_directory="$fixture_root/profiles/bad-native-digest"
run_cli_failure bad-native-digest "$profile_timeout" \
  install-program-profile \
  profile-install-fixture-bad-native-digest \
  --bottle profile-fixture-failure \
  --progress-json \
  --json
last_json_line "$captured_stdout_path" "$logs_dir/bad-native-digest.final.json"
assert_jq "$logs_dir/bad-native-digest.final.json" \
  "Native DLL digest mismatch was not attributed to the x86 action." \
  '
    .error.code == "profileResourceDigestMismatch" and
    .error.programProfileInstall.stage == "verification" and
    .error.programProfileInstall.actionIndex == 1 and
    .error.programProfileInstall.actionKind == "nativeDll" and
    .error.programProfileInstall.actionId == "fixture-d3dcompiler-x86"
  '
assert_resource_cache_clean
[[ ! -e "$failure_bottle/winetricks.log" ]]
[[ ! -e "$failure_bottle/drive_c/Program Files/Konyak Profile Fixture/profile_fixture_launcher.exe" ]]
[[ "$(sha256sum "$failure_x86_target" | cut -d ' ' -f 1)" == "$failure_x86_digest_before" ]]
[[ "$(sha256sum "$failure_x64_target" | cut -d ' ' -f 1)" == "$failure_x64_digest_before" ]]
assert_jq "$request_log" \
  "Bad native digest fetched an unexpected payload or used the wrong order." \
  -s '[.[].path] == ["/profile_fixture_installer.exe", "/profile_fixture_x86.dll"]'

active_profile_directory="$fixture_root/profiles/success"
created_bottle_ids+=(profile-fixture-success)
run_cli_success create-success-bottle "$profile_timeout" \
  create-bottle \
  --name "Profile Fixture Success" \
  --windows-version win10 \
  --json
success_bottle="$data_home/bottles/profile-fixture-success"
snapshot_dll_overrides "$success_bottle" "$logs_dir/dll-overrides.before"

: >"$request_log"
run_cli_success install-profile "$profile_timeout" \
  install-program-profile \
  profile-install-fixture \
  --bottle profile-fixture-success \
  --progress-json \
  --json
last_json_line "$captured_stdout_path" "$logs_dir/install-profile.final.json"
assert_jq "$logs_dir/install-profile.final.json" \
  "Profile installation did not persist its binding." \
  '
    .schemaVersion == 1 and
    .programProfileInstall.stage == "persistence" and
    .programProfileInstall.programProfile.bottleId == "profile-fixture-success" and
    .programProfileInstall.programProfile.profileId == "profile-install-fixture"
  '
assert_resource_cache_clean
assert_jq "$captured_stdout_path" \
  "Pre-install action progress did not preserve declared order." \
  -s '
    [
      .[] |
      .programProfileInstallProgress? |
      select(.stage == "preInstallAction" and .state == "started") |
      [.actionIndex, .actionKind, .actionId]
    ] == [
      [0, "winetricks", "win10"],
      [1, "nativeDll", "fixture-d3dcompiler-x86"],
      [2, "nativeDll", "fixture-d3dcompiler-x64"]
    ]
  '
assert_jq "$request_log" \
  "Profile resources were not requested in installer/x86/x64 order." \
  -s '[.[].path] == ["/profile_fixture_installer.exe", "/profile_fixture_x86.dll", "/profile_fixture_x64.dll"]'
cp "$request_log" "$logs_dir/success-https-requests.jsonl"

x86_target="$success_bottle/drive_c/windows/syswow64/d3dcompiler_47.dll"
x64_target="$success_bottle/drive_c/windows/system32/d3dcompiler_47.dll"
launcher_target="$success_bottle/drive_c/Program Files/Konyak Profile Fixture/profile_fixture_launcher.exe"
shortcut_target="$success_bottle/drive_c/ProgramData/Microsoft/Windows/Start Menu/Programs/Konyak Profile Fixture.lnk"
evidence_root="$success_bottle/drive_c/konyak-profile-install-evidence"
[[ -f "$launcher_target" && -f "$shortcut_target" ]]
[[ -f "$evidence_root/installer-events.log" ]]
grep -q '^win10$' "$success_bottle/winetricks.log"
assert_pe_machine "$x86_target" 014c
assert_pe_machine "$x64_target" 8664
[[ "$(sha256sum "$x86_target" | cut -d ' ' -f 1)" == "$(jq -r .x86DllSha256 "$fixture_root/fixture-manifest.json")" ]]
[[ "$(sha256sum "$x64_target" | cut -d ' ' -f 1)" == "$(jq -r .x64DllSha256 "$fixture_root/fixture-manifest.json")" ]]
snapshot_dll_overrides "$success_bottle" "$logs_dir/dll-overrides.after"
cmp "$logs_dir/dll-overrides.before" "$logs_dir/dll-overrides.after"

run_cli_success inspect-installed-bottle "$command_timeout" \
  inspect-bottle profile-fixture-success --json
assert_jq "$captured_stdout_path" \
  "Installed bottle does not contain exactly one binding and one pin." \
  '
    .schemaVersion == 1 and
    (.bottle.profiles | length) == 1 and
    .bottle.profiles[0].profileId == "profile-install-fixture" and
    (.bottle.pinnedPrograms | length) == 1 and
    .bottle.pinnedPrograms[0].path == "C:\\Program Files\\Konyak Profile Fixture\\profile_fixture_launcher.exe"
  '

x86_stat_before="$(file_identity "$x86_target")"
x64_stat_before="$(file_identity "$x64_target")"
run_cli_success reinstall-profile "$profile_timeout" \
  install-program-profile \
  profile-install-fixture \
  --bottle profile-fixture-success \
  --progress-json \
  --json
assert_resource_cache_clean
[[ "$(file_identity "$x86_target")" == "$x86_stat_before" ]]
[[ "$(file_identity "$x64_target")" == "$x64_stat_before" ]]

run_cli_success list-bottles-after-reinstall "$command_timeout" \
  list-bottles --json
assert_jq "$captured_stdout_path" \
  "Profile reinstall duplicated its binding or pin in list-bottles." \
  '
    .schemaVersion == 1 and
    ([.bottles[] | select(.id == "profile-fixture-success")] | length) == 1 and
    ([.bottles[] | select(.id == "profile-fixture-success")][0].profiles | length) == 1 and
    ([.bottles[] | select(.id == "profile-fixture-success")][0].pinnedPrograms | length) == 1
  '
run_cli_success list-programs-after-reinstall "$command_timeout" \
  list-bottle-programs profile-fixture-success --json
assert_jq "$captured_stdout_path" \
  "Profile reinstall produced duplicate public program records." \
  --arg managed 'C:\Program Files\Konyak Profile Fixture\profile_fixture_launcher.exe' \
  --arg shortcut "$shortcut_target" \
  '
    .schemaVersion == 1 and
    .bottlePrograms.bottleId == "profile-fixture-success" and
    (.bottlePrograms.programs | length) ==
      ([.bottlePrograms.programs[].path] | unique | length) and
    ([.bottlePrograms.programs[] | select(.path == $managed)] | length) == 1 and
    ([.bottlePrograms.programs[] | select(.path == $shortcut)] | length) == 1
  '

pin_manifest="$(find "$launcher_home" -type f -name konyak-launcher.json -print | head -n 1)"
if [[ -z "$pin_manifest" ]]; then
  echo "Automatic profile pin did not generate a launcher manifest." >&2
  exit 1
fi
run_cli_success launch-pinned "$command_timeout" \
  launch-pinned-program \
  --manifest "$pin_manifest" \
  --json
assert_jq "$captured_stdout_path" \
  "Pinned program did not run through macOS Wine." \
  '.schemaVersion == 1 and .run.bottleId == "profile-fixture-success" and .run.processExitCode == 0'

run_cli_success launch-shortcut "$command_timeout" \
  run-program \
  profile-fixture-success \
  --program "$shortcut_target" \
  --json
assert_jq "$captured_stdout_path" \
  "The real Windows shortcut did not run through macOS Wine." \
  --arg shortcut "$shortcut_target" \
  '.schemaVersion == 1 and .run.programPath == $shortcut and .run.processExitCode == 0'

python3 - "$evidence_root/launcher-events.log" "$evidence_root/child-events.log" <<'PY'
import pathlib
import re
import sys

launcher_lines = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8").splitlines()
child_lines = pathlib.Path(sys.argv[2]).read_text(encoding="utf-8").splitlines()
assert len(launcher_lines) >= 2, launcher_lines
assert len(child_lines) >= 2, child_lines
launcher_pids = [re.search(r"pid=(\d+)", line).group(1) for line in launcher_lines[-2:]]
child_parents = [re.search(r"parent=(\d+)", line).group(1) for line in child_lines[-2:]]
assert launcher_pids == child_parents, (launcher_pids, child_parents)
for line in child_lines[-2:]:
    assert "--launcher-argument=present" in line, line
    assert "--profile-rule=active" in line, line
PY

assert_profile_actions_metadata "$success_bottle/metadata.json" profile-install-fixture
cp "$success_bottle/metadata.json" \
  "$logs_dir/profile-fixture-success.auto.metadata.json"
snapshot_manual_invariants "$success_bottle" "$logs_dir/manual-invariants.before"
active_profile_directory="$fixture_root/profiles/manual"
run_cli_success manual-apply "$command_timeout" \
  apply-program-profile \
  profile-install-fixture-manual \
  --bottle profile-fixture-success \
  --program 'C:\Program Files\Konyak Profile Fixture\profile_fixture_launcher.exe' \
  --json
assert_jq "$captured_stdout_path" \
  "Manual apply did not persist the selected profile." \
  '.schemaVersion == 1 and .programProfile.profileId == "profile-install-fixture-manual"'
snapshot_manual_invariants "$success_bottle" "$logs_dir/manual-invariants.after"
cmp "$logs_dir/manual-invariants.before" "$logs_dir/manual-invariants.after"

assert_profile_actions_metadata "$success_bottle/metadata.json" profile-install-fixture-manual
cp "$success_bottle/metadata.json" \
  "$logs_dir/profile-fixture-success.manual.metadata.json"
cp "$success_bottle/metadata.json" "$logs_dir/profile-fixture-success.metadata.json"
cp "$success_bottle/winetricks.log" "$logs_dir/profile-fixture-success.winetricks.log"
cp "$evidence_root/installer-events.log" "$logs_dir/installer-events.log"
cp "$evidence_root/launcher-events.log" "$logs_dir/launcher-events.log"
cp "$evidence_root/child-events.log" "$logs_dir/child-events.log"
echo "macOS profile-install CLI smoke passed. Evidence: $logs_dir"
