#!/usr/bin/env zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd -P)"
cd "$repo_root"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "macOS Finder integration smoke is supported on macOS only." >&2
  exit 69
fi

for command in defaults mdls open pgrep swift; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Missing required command: $command" >&2
    exit 69
  fi
done

lsregister="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
if [[ ! -x "$lsregister" ]]; then
  echo "lsregister was not found: $lsregister" >&2
  exit 69
fi

debug_root="${KONYAK_MACOS_DEBUG_APP_OUTPUT_DIR:-$repo_root/.dart_tool/konyak/app/macos/debug}"
default_app_bundle="${KONYAK_MACOS_FINDER_SMOKE_APP:-$debug_root/Konyak.app}"
app_bundle="${1:-$default_app_bundle}"
fixture_from_argument="${2:-}"
fixture_from_environment="${KONYAK_MACOS_FINDER_SMOKE_EXE:-}"
work_root="${KONYAK_MACOS_FINDER_SMOKE_WORK_ROOT:-$repo_root/.dart_tool/konyak/macos-finder-smoke/$$}"
window_probe="$work_root/window_probe.swift"
default_app_probe="$work_root/default_app_probe.swift"
ql_output="$work_root/quicklook"
app_pid=""

cleanup() {
  if [[ "${KONYAK_MACOS_FINDER_SMOKE_KEEP_APP_RUNNING:-0}" == "1" ]]; then
    return
  fi
  if [[ -n "$app_pid" ]]; then
    kill "$app_pid" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

if [[ ! -d "$app_bundle" ]]; then
  echo "Packaged Konyak.app was not found: $app_bundle" >&2
  exit 1
fi
if [[ ! -x "$app_bundle/Contents/MacOS/Konyak" ]]; then
  echo "Konyak app executable was not found: $app_bundle/Contents/MacOS/Konyak" >&2
  exit 1
fi
if [[ ! -d "$app_bundle/Contents/PlugIns/ExecutableThumbnail.appex" ]]; then
  echo "ExecutableThumbnail.appex was not bundled in $app_bundle" >&2
  exit 1
fi
app_bundle="${app_bundle:A}"

rm -rf "$work_root"
mkdir -p "$work_root" "$ql_output"

if [[ -n "$fixture_from_argument" ]]; then
  exe_fixture="$fixture_from_argument"
elif [[ -n "$fixture_from_environment" ]]; then
  exe_fixture="$fixture_from_environment"
else
  exe_fixture="$work_root/finder-smoke.exe"
  printf "MZ\\0\\0Konyak Finder smoke fixture\n" >"$exe_fixture"
fi

if [[ ! -f "$exe_fixture" ]]; then
  echo "Finder smoke executable fixture was not found: $exe_fixture" >&2
  exit 1
fi

bundle_id="$(defaults read "$app_bundle/Contents/Info.plist" CFBundleIdentifier)"
if [[ "$bundle_id" != "app.konyak.Konyak" ]]; then
  echo "Unexpected Konyak bundle id: $bundle_id" >&2
  exit 1
fi

"$lsregister" -f "$app_bundle"

content_type="$(mdls -raw -name kMDItemContentType "$exe_fixture" 2>/dev/null || true)"
if [[ "$content_type" != "com.microsoft.windows-executable" ]]; then
  echo "Fixture did not resolve to com.microsoft.windows-executable: $content_type" >&2
  exit 1
fi

cat >"$default_app_probe" <<'SWIFT'
import CoreServices
import Foundation

let fileURL = URL(fileURLWithPath: CommandLine.arguments[1])
let expectedBundleId = CommandLine.arguments[2]

guard let appURL = LSCopyDefaultApplicationURLForURL(fileURL as CFURL, .all, nil)?
  .takeRetainedValue() as URL?
else {
  fputs("No default application for executable fixture.\n", stderr)
  exit(1)
}

guard let bundle = Bundle(url: appURL),
  bundle.bundleIdentifier == expectedBundleId
else {
  fputs("Default application was \(appURL.path), not \(expectedBundleId).\n", stderr)
  exit(1)
}
SWIFT

swift "$default_app_probe" "$exe_fixture" "$bundle_id"

before_pids="$(pgrep -f "$app_bundle/Contents/MacOS/Konyak" || true)"
/usr/bin/open -n -a "$app_bundle" "$exe_fixture"

for _ in {1..80}; do
  current_pids="$(pgrep -f "$app_bundle/Contents/MacOS/Konyak" || true)"
  for pid in ${(f)current_pids}; do
    if [[ -z "$pid" ]]; then
      continue
    fi
    if ! grep -qx "$pid" <<<"$before_pids"; then
      app_pid="$pid"
      break
    fi
  done
  if [[ -n "$app_pid" ]]; then
    break
  fi
  sleep 0.25
done

if [[ -z "$app_pid" ]]; then
  echo "Konyak did not launch from Finder smoke fixture." >&2
  exit 1
fi

cat >"$window_probe" <<'SWIFT'
import CoreGraphics
import Foundation

let pid = Int(CommandLine.arguments[1])!
let windows = CGWindowListCopyWindowInfo(
  [.optionOnScreenOnly, .excludeDesktopElements],
  kCGNullWindowID
) as? [[String: Any]] ?? []

let visible = windows.contains { window in
  guard let ownerPid = window[kCGWindowOwnerPID as String] as? Int,
    ownerPid == pid
  else {
    return false
  }

  if let alpha = window[kCGWindowAlpha as String] as? Double, alpha <= 0 {
    return false
  }

  if let bounds = window[kCGWindowBounds as String] as? [String: Any],
    let width = bounds["Width"] as? Double,
    let height = bounds["Height"] as? Double
  {
    return width > 0 && height > 0
  }

  return true
}

if !visible {
  fputs("No visible Konyak window for pid \(pid).\n", stderr)
  exit(1)
}
SWIFT

for _ in {1..80}; do
  if swift "$window_probe" "$app_pid" >/dev/null 2>&1; then
    break
  fi
  sleep 0.25
done
swift "$window_probe" "$app_pid"

if [[ -n "$fixture_from_argument" || -n "$fixture_from_environment" ]]; then
  qlmanage -r >/dev/null 2>&1 || true
  qlmanage -r cache >/dev/null 2>&1 || true
  qlmanage -t -x -s 256 \
    -o "$ql_output" \
    -c com.microsoft.windows-executable \
    "$exe_fixture" >/dev/null
fi

echo "macOS Finder integration smoke passed."
