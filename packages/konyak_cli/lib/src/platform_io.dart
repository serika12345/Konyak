part of '../konyak_cli.dart';

String? _bottleLocationPath({
  required BottleRecord bottle,
  required String location,
}) {
  final normalized = location.trim().toLowerCase();
  return switch (normalized) {
    'root' => bottle.path,
    'c-drive' => _joinPath(bottle.path, const ['drive_c']),
    _ => null,
  };
}

String _programLocationPath(String programPath) {
  final normalized = _normalizeFilesystemPath(programPath);
  final separator = normalized.lastIndexOf('/');
  if (separator <= 0) {
    return normalized;
  }

  return normalized.substring(0, separator);
}

KonyakHostPlatform _currentHostPlatform() {
  return switch (Platform.operatingSystem) {
    'macos' => KonyakHostPlatform.macos,
    _ => KonyakHostPlatform.linux,
  };
}

String _pathOpenExecutable() {
  return switch (_currentHostPlatform()) {
    KonyakHostPlatform.macos =>
      File('/usr/bin/open').existsSync() ? '/usr/bin/open' : 'open',
    KonyakHostPlatform.linux => 'xdg-open',
  };
}

String _konyakApplicationSupportFolder(Map<String, String> environment) {
  final override = environment['KONYAK_APPLICATION_SUPPORT'];
  if (override != null && override.trim().isNotEmpty) {
    return override;
  }

  final home = environment['HOME'];
  if (home != null && home.trim().isNotEmpty) {
    return _joinPath(home, const ['Library', 'Application Support', 'Konyak']);
  }

  return 'Konyak';
}

String _macosWineRuntimeRoot(Map<String, String> environment) {
  final override = environment['KONYAK_MACOS_WINE_HOME'];
  if (override != null && override.trim().isNotEmpty) {
    return override;
  }

  return _joinPath(_konyakApplicationSupportFolder(environment), const [
    'Runtimes',
    'macos-wine',
  ]);
}

String _linuxWineRuntimeRoot(Map<String, String> environment) {
  final override = environment['KONYAK_LINUX_WINE_HOME'];
  if (override != null && override.trim().isNotEmpty) {
    return override;
  }

  return _joinPath(_resolveDataHome(environment), const [
    'Runtimes',
    'linux-wine',
  ]);
}

String _macosWineBinFolder(Map<String, String> environment) {
  return _joinPath(_macosWineRuntimeRoot(environment), const ['bin']);
}

String? _linuxManagedRuntimeBinFolder(Map<String, String> environment) {
  final override = environment['KONYAK_LINUX_WINE_HOME'];
  if (override == null || override.trim().isEmpty) {
    return null;
  }

  return _joinPath(override, const ['bin']);
}

String _macosWineExecutable(Map<String, String> environment) {
  return _joinPath(_macosWineBinFolder(environment), const ['wine64']);
}

String _linuxWineExecutable(Map<String, String> environment) {
  final runtimeBin = _linuxManagedRuntimeBinFolder(environment);
  if (runtimeBin != null) {
    return _joinPath(runtimeBin, const ['wine']);
  }

  return 'wine';
}

String _linuxWinebootExecutable(Map<String, String> environment) {
  final runtimeBin = _linuxManagedRuntimeBinFolder(environment);
  if (runtimeBin != null) {
    return _joinPath(runtimeBin, const ['wineboot']);
  }

  return 'wineboot';
}

String _linuxWineserverExecutable(Map<String, String> environment) {
  final runtimeBin = _linuxManagedRuntimeBinFolder(environment);
  if (runtimeBin != null) {
    return _joinPath(runtimeBin, const ['wineserver']);
  }

  return 'wineserver';
}

String _linuxWinedbgExecutable(Map<String, String> environment) {
  final runtimeBin = _linuxManagedRuntimeBinFolder(environment);
  if (runtimeBin != null) {
    return _joinPath(runtimeBin, const ['winedbg']);
  }

  return 'winedbg';
}

String _macosWineserverExecutable(Map<String, String> environment) {
  return _joinPath(_macosWineBinFolder(environment), const ['wineserver']);
}

String _macosWinetricksExecutable(Map<String, String> environment) {
  return _joinPath(_macosWineRuntimeRoot(environment), const ['winetricks']);
}

String _linuxWinetricksExecutable(Map<String, String> environment) {
  final override = environment['KONYAK_LINUX_WINE_HOME'];
  if (override != null && override.trim().isNotEmpty) {
    return _joinPath(override, const ['winetricks']);
  }

  return 'winetricks';
}

Map<String, String> _linuxRuntimeEnvironment(Map<String, String> environment) {
  final runtimeBin = _linuxManagedRuntimeBinFolder(environment);
  final wineLibraryPath = environment['KONYAK_LINUX_WINE_LIBRARY_PATH'];
  final hasWineLibraryPath =
      wineLibraryPath != null && wineLibraryPath.trim().isNotEmpty;
  if (runtimeBin == null && !hasWineLibraryPath) {
    return const <String, String>{};
  }

  final runtimeEnvironment = <String, String>{};
  if (runtimeBin != null) {
    runtimeEnvironment['PATH'] = _prependPath(runtimeBin, environment['PATH']);
  }
  if (hasWineLibraryPath) {
    runtimeEnvironment['LD_LIBRARY_PATH'] = _prependPath(
      wineLibraryPath.trim(),
      environment['LD_LIBRARY_PATH'],
    );
  }

  return Map.unmodifiable(runtimeEnvironment);
}

String _appUpdateCacheDirectory(Map<String, String> environment) {
  final override = environment['KONYAK_APP_UPDATE_CACHE_HOME'];
  if (override != null && override.trim().isNotEmpty) {
    return override;
  }

  final xdgCache = environment['XDG_CACHE_HOME'];
  if (_currentHostPlatform() == KonyakHostPlatform.linux &&
      xdgCache != null &&
      xdgCache.trim().isNotEmpty) {
    return _joinPath(xdgCache, const ['konyak', 'updates']);
  }

  final home = environment['HOME'];
  if (home != null && home.trim().isNotEmpty) {
    return switch (_currentHostPlatform()) {
      KonyakHostPlatform.macos => _joinPath(home, const [
        'Library',
        'Caches',
        'Konyak',
        'Updates',
      ]),
      KonyakHostPlatform.linux => _joinPath(home, const [
        '.cache',
        'konyak',
        'updates',
      ]),
    };
  }

  return _joinPath(Directory.systemTemp.path, const ['konyak', 'updates']);
}

String? _linuxAppImageTargetPath(Map<String, String> environment) {
  final override = environment['KONYAK_APPIMAGE_PATH'];
  if (override != null && override.trim().isNotEmpty) {
    return override.trim();
  }

  final appImage = environment['APPIMAGE'];
  if (appImage != null && appImage.trim().isNotEmpty) {
    return appImage.trim();
  }

  return null;
}

String? _macosAppBundlePath(Map<String, String> environment) {
  final override = environment['KONYAK_APP_BUNDLE_PATH'];
  if (override != null && override.trim().isNotEmpty) {
    return override.trim();
  }

  final executable = environment['KONYAK_APP_EXECUTABLE'];
  if (executable == null || executable.trim().isEmpty) {
    return null;
  }

  return _macosAppBundlePathFromExecutable(executable.trim());
}

String? _macosAppBundlePathFromExecutable(String executable) {
  final normalized = executable.replaceAll('\\', '/');
  const marker = '.app/Contents/MacOS/';
  final markerIndex = normalized.indexOf(marker);
  if (markerIndex < 0) {
    return null;
  }

  return normalized.substring(0, markerIndex + '.app'.length);
}

int? _konyakAppPid(Map<String, String> environment) {
  final raw = environment['KONYAK_APP_PID'];
  if (raw == null || raw.trim().isEmpty) {
    return null;
  }

  final pid = int.tryParse(raw.trim());
  if (pid == null || pid <= 0) {
    return null;
  }

  return pid;
}

String? _fileNameFromUrl(String url) {
  final parsed = Uri.tryParse(url);
  final segments = parsed?.pathSegments;
  final candidate = segments == null || segments.isEmpty
      ? null
      : segments.last.trim();
  if (candidate == null || candidate.isEmpty) {
    return null;
  }

  return candidate.replaceAll(RegExp(r'[^A-Za-z0-9._+-]'), '_');
}

String _runtimeSiblingPathForInstall(Directory runtimeRoot, String suffix) {
  return '${runtimeRoot.path}.$suffix-${DateTime.now().microsecondsSinceEpoch}';
}

void _replaceRuntimeRootInPlace({
  required Directory runtimeRoot,
  required Directory stagingRoot,
  required Directory backupRoot,
}) {
  var backupCreated = false;
  if (runtimeRoot.existsSync()) {
    if (backupRoot.existsSync()) {
      backupRoot.deleteSync(recursive: true);
    }
    runtimeRoot.renameSync(backupRoot.path);
    backupCreated = true;
  }

  try {
    stagingRoot.renameSync(runtimeRoot.path);
    if (backupCreated && backupRoot.existsSync()) {
      backupRoot.deleteSync(recursive: true);
    }
  } on FileSystemException {
    if (FileSystemEntity.typeSync(runtimeRoot.path) !=
        FileSystemEntityType.notFound) {
      runtimeRoot.deleteSync(recursive: true);
    }
    if (backupCreated && backupRoot.existsSync()) {
      backupRoot.renameSync(runtimeRoot.path);
    }
    rethrow;
  }
}

String? _localSourcePath(String source) {
  final uri = Uri.tryParse(source);
  if (uri != null && uri.scheme == 'file') {
    return uri.toFilePath();
  }

  if (uri == null || uri.scheme.isEmpty) {
    return source;
  }

  return null;
}

String _readAndVerifyRuntimeStackSourceText({
  required String source,
  required String? signatureSource,
  required String? publicKeyPath,
  required String? publicKeyText,
}) {
  final payload = _readTextSource(
    source,
    action: 'download runtime stack source manifest',
  );
  final normalizedPublicKeyPath = publicKeyPath?.trim();
  final normalizedPublicKeyText = publicKeyText?.trim();
  final hasPublicKeyPath =
      normalizedPublicKeyPath != null && normalizedPublicKeyPath.isNotEmpty;
  final hasPublicKeyText =
      normalizedPublicKeyText != null && normalizedPublicKeyText.isNotEmpty;
  final normalizedSignatureSource = signatureSource?.trim();

  if (!hasPublicKeyPath && !hasPublicKeyText) {
    if (normalizedSignatureSource != null &&
        normalizedSignatureSource.isNotEmpty) {
      throw const FileSystemException(
        'Runtime stack source signature was provided without a public key.',
      );
    }
    return payload;
  }

  final effectiveSignatureSource =
      normalizedSignatureSource == null || normalizedSignatureSource.isEmpty
      ? '$source.sig'
      : normalizedSignatureSource;
  final tempDirectory = Directory.systemTemp.createTempSync(
    'konyak-runtime-stack-verify-',
  );
  try {
    final payloadPath = _joinPath(tempDirectory.path, const ['manifest.json']);
    File(payloadPath).writeAsStringSync(payload);

    final signaturePath = _joinPath(tempDirectory.path, const ['manifest.sig']);
    _writeSourceBytes(
      source: effectiveSignatureSource,
      targetPath: signaturePath,
      action: 'download runtime stack source signature',
    );

    final resolvedPublicKeyPath = hasPublicKeyPath
        ? normalizedPublicKeyPath
        : _joinPath(tempDirectory.path, const ['runtime-stack-public-key.pem']);
    if (!hasPublicKeyPath) {
      File(
        resolvedPublicKeyPath,
      ).writeAsStringSync('$normalizedPublicKeyText\n');
    }

    final result = Process.runSync('openssl', [
      'dgst',
      '-sha256',
      '-verify',
      resolvedPublicKeyPath,
      '-signature',
      signaturePath,
      payloadPath,
    ], runInShell: false);
    if (result.exitCode != 0) {
      throw ProcessException(
        'openssl',
        const <String>[],
        'Runtime stack source manifest signature verification failed: '
            '${_commandFailureMessage("verify runtime stack source manifest signature", result)}',
        result.exitCode,
      );
    }

    return payload;
  } finally {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  }
}

String _readTextSource(String source, {required String action}) {
  final localPath = _localSourcePath(source);
  if (localPath != null) {
    return File(localPath).readAsStringSync();
  }

  final result = Process.runSync('curl', [
    '--fail',
    '--location',
    '--silent',
    source,
  ], runInShell: false);
  if (result.exitCode != 0) {
    throw ProcessException(
      'curl',
      const <String>[],
      _commandFailureMessage(action, result),
      result.exitCode,
    );
  }

  return _processOutputToString(result.stdout);
}

void _writeSourceBytes({
  required String source,
  required String targetPath,
  required String action,
}) {
  final localPath = _localSourcePath(source);
  if (localPath != null) {
    File(targetPath).parent.createSync(recursive: true);
    File(localPath).copySync(targetPath);
    return;
  }

  final result = Process.runSync('curl', [
    '--fail',
    '--location',
    '--silent',
    '--output',
    targetPath,
    source,
  ], runInShell: false);
  if (result.exitCode != 0) {
    throw ProcessException(
      'curl',
      const <String>[],
      _commandFailureMessage(action, result),
      result.exitCode,
    );
  }
}

String _macosAppBundleUpdateHandoffScript() {
  return r'''
#!/usr/bin/env bash
set -euo pipefail

source_archive="$1"
target_bundle="$2"
app_pid="$3"
target_parent="$(dirname "$target_bundle")"
bundle_name="$(basename "$target_bundle")"
work_dir="$(mktemp -d "${TMPDIR:-/tmp}/konyak-macos-update.XXXXXX")"
extract_dir="$work_dir/extract"
helper_script="$work_dir/install-macos-app-update-helper.sh"
backup_path="$target_bundle.konyak-backup"

cleanup() {
  rm -rf "$work_dir"
}
trap cleanup EXIT

if [[ ! -d "$target_bundle" ]]; then
  exit 66
fi

mkdir -p "$extract_dir"
ditto -x -k "$source_archive" "$extract_dir"

updated_bundle=""
if [[ -d "$extract_dir/$bundle_name" ]]; then
  updated_bundle="$extract_dir/$bundle_name"
else
  for candidate in "$extract_dir"/*.app "$extract_dir"/*/*.app; do
    if [[ -d "$candidate" ]]; then
      updated_bundle="$candidate"
      break
    fi
  done
fi
if [[ -z "$updated_bundle" ]]; then
  exit 66
fi
if [[ ! -d "$updated_bundle/Contents/MacOS" ]]; then
  exit 66
fi

cat >"$helper_script" <<'HELPER'
#!/usr/bin/env bash
set -euo pipefail

updated_bundle="$1"
target_bundle="$2"
backup_path="$3"
source_archive="$4"
app_pid="$5"
staging_path="$target_bundle.konyak-update"

kill -TERM "$app_pid" 2>/dev/null || true

for ((attempt = 0; attempt < 60; attempt += 1)); do
  if ! kill -0 "$app_pid" 2>/dev/null; then
    break
  fi
  sleep 1
done

if kill -0 "$app_pid" 2>/dev/null; then
  exit 75
fi

rm -rf "$staging_path" "$backup_path"
ditto "$updated_bundle" "$staging_path"

if [[ -e "$target_bundle" ]]; then
  mv "$target_bundle" "$backup_path"
fi

if mv "$staging_path" "$target_bundle"; then
  rm -rf "$backup_path" "$source_archive"
else
  rm -rf "$staging_path"
  if [[ -e "$backup_path" ]]; then
    mv "$backup_path" "$target_bundle"
  fi
  exit 75
fi

xattr -dr com.apple.quarantine "$target_bundle" 2>/dev/null || true
HELPER
chmod 755 "$helper_script"

if [[ -w "$target_parent" ]]; then
  "$helper_script" "$updated_bundle" "$target_bundle" "$backup_path" "$source_archive" "$app_pid"
else
  osascript - "$helper_script" "$updated_bundle" "$target_bundle" "$backup_path" "$source_archive" "$app_pid" <<'APPLESCRIPT'
on run argv
  set helperScript to item 1 of argv
  set updatedBundle to item 2 of argv
  set targetBundle to item 3 of argv
  set backupPath to item 4 of argv
  set sourceArchive to item 5 of argv
  set appPid to item 6 of argv
  set command to "/bin/bash " & quoted form of helperScript & " " & quoted form of updatedBundle & " " & quoted form of targetBundle & " " & quoted form of backupPath & " " & quoted form of sourceArchive & " " & quoted form of appPid
  do shell script command with administrator privileges
end run
APPLESCRIPT
fi

nohup open "$target_bundle" >/dev/null 2>&1 &
''';
}

String _linuxAppImageUpdateHandoffScript() {
  return r'''
#!/usr/bin/env bash
set -euo pipefail

source_archive="$1"
target_appimage="$2"
app_pid="$3"
staging_path="$target_appimage.konyak-update"
backup_path="$target_appimage.konyak-backup"

kill -TERM "$app_pid" 2>/dev/null || true

for _ in $(seq 1 60); do
  if ! kill -0 "$app_pid" 2>/dev/null; then
    break
  fi
  sleep 1
done

if kill -0 "$app_pid" 2>/dev/null; then
  exit 75
fi

rm -f "$staging_path" "$backup_path"
cp "$source_archive" "$staging_path"
chmod 755 "$staging_path"

if [[ -e "$target_appimage" ]]; then
  mv "$target_appimage" "$backup_path"
fi

if mv "$staging_path" "$target_appimage"; then
  rm -f "$backup_path" "$source_archive"
else
  rm -f "$staging_path"
  if [[ -e "$backup_path" ]]; then
    mv "$backup_path" "$target_appimage"
  fi
  exit 75
fi

nohup "$target_appimage" >/dev/null 2>&1 &
''';
}

String? _linuxTerminalOverride(Map<String, String> environment) {
  final terminal = environment['TERMINAL'];
  if (terminal != null && terminal.trim().isNotEmpty) {
    return terminal.trim();
  }

  return null;
}

String _linuxTerminalLauncherCommand(Map<String, String> environment) {
  final override = _linuxTerminalOverride(environment);
  final candidates = <String>[
    if (override != null) 'exec ${_shellQuote(override)} -e bash -lc "\$0" sh',
    'if command -v x-terminal-emulator >/dev/null 2>&1; then exec x-terminal-emulator -e bash -lc "\$0" sh; fi',
    'if command -v kgx >/dev/null 2>&1; then exec kgx -- bash -lc "\$0"; fi',
    'if command -v gnome-terminal >/dev/null 2>&1; then exec gnome-terminal -- bash -lc "\$0"; fi',
    'if command -v ptyxis >/dev/null 2>&1; then exec ptyxis --standalone -- bash -lc "\$0"; fi',
    'if command -v konsole >/dev/null 2>&1; then exec konsole -e bash -lc "\$0"; fi',
    'if command -v xfce4-terminal >/dev/null 2>&1; then exec xfce4-terminal -x bash -lc "\$0"; fi',
    'if command -v mate-terminal >/dev/null 2>&1; then exec mate-terminal -- bash -lc "\$0"; fi',
    'if command -v tilix >/dev/null 2>&1; then exec tilix -- bash -lc "\$0"; fi',
    'if command -v kitty >/dev/null 2>&1; then exec kitty bash -lc "\$0"; fi',
    'if command -v alacritty >/dev/null 2>&1; then exec alacritty -e bash -lc "\$0"; fi',
    'if command -v wezterm >/dev/null 2>&1; then exec wezterm start -- bash -lc "\$0"; fi',
    'echo "No supported terminal emulator found." >&2',
    'exit 127',
  ];

  return candidates.join('\n');
}

String _linuxWineTerminalShellCommandWithEnvironment({
  required BottleRecord bottle,
  required Map<String, String> environment,
}) {
  final executable = _linuxWineExecutable(environment);
  final runtimeBin = _linuxManagedRuntimeBinFolder(environment);
  final wineLibraryPath = environment['KONYAK_LINUX_WINE_LIBRARY_PATH'];
  final shellSetup = <String>[
    'cd ${_shellQuote(bottle.path)}',
    'export WINEPREFIX=${_shellQuote(bottle.path)}',
    'export WINE=${_shellQuote(executable)}',
    if (runtimeBin != null) 'export PATH=${_shellQuote(runtimeBin)}:\$PATH',
    if (wineLibraryPath != null && wineLibraryPath.trim().isNotEmpty)
      'export LD_LIBRARY_PATH=${_shellQuote(wineLibraryPath.trim())}:\${LD_LIBRARY_PATH:-}',
    'alias wine=${_shellQuote(executable)}',
    'alias wine64=${_shellQuote(executable)}',
    'alias winecfg=${_shellQuote('$executable winecfg')}',
    'alias msiexec=${_shellQuote('$executable msiexec')}',
  ];

  return <String>[
    "exec bash --noprofile --rcfile <(cat <<'KONYAK_BASHRC'",
    ...shellSetup,
    'KONYAK_BASHRC',
    ') -i',
  ].join('\n');
}

String _macosWineTerminalShellCommand({
  required BottleRecord bottle,
  required Map<String, String> environment,
}) {
  final runtimeBin = _macosWineBinFolder(environment);
  final commands = <String>[
    'cd ${_shellQuote(bottle.path)}',
    'export PATH=${_shellQuote(runtimeBin)}:\$PATH',
    'export WINE=${_shellQuote('wine64')}',
    'alias wine=${_shellQuote('wine64')}',
    'alias winecfg=${_shellQuote('wine64 winecfg')}',
    'alias msiexec=${_shellQuote('wine64 msiexec')}',
    'alias regedit=${_shellQuote('wine64 regedit')}',
    'alias regsvr32=${_shellQuote('wine64 regsvr32')}',
    'alias wineboot=${_shellQuote('wine64 wineboot')}',
    'alias wineconsole=${_shellQuote('wine64 wineconsole')}',
    'alias winedbg=${_shellQuote('wine64 winedbg')}',
    'alias winefile=${_shellQuote('wine64 winefile')}',
    'alias winepath=${_shellQuote('wine64 winepath')}',
  ];

  _macosWineEnvironment(bottle: bottle, environment: environment).forEach((
    key,
    value,
  ) {
    commands.add('export $key=${_shellQuote(value)}');
  });

  return commands.join('; ');
}

String _macosTerminalAppleScript(String shellCommand) {
  final escapedCommand = _appleScriptString(shellCommand);
  return '''
tell application "Terminal"
activate
do script "$escapedCommand"
end tell
''';
}

String _appleScriptString(String value) {
  return value
      .replaceAll(r'\', r'\\')
      .replaceAll('"', r'\"')
      .replaceAll('\n', r'\n');
}

String _shellQuote(String value) {
  return "'${value.replaceAll("'", "'\"'\"'")}'";
}

String _prependPath(String path, String? existingPath) {
  if (existingPath == null || existingPath.trim().isEmpty) {
    return path;
  }

  return '$path:$existingPath';
}

String _basename(String path) {
  return path.split('/').last;
}

String _dirname(String path) {
  final index = path.lastIndexOf('/');
  if (index <= 0) {
    return '.';
  }

  return path.substring(0, index);
}

final class _DigestSink implements Sink<Digest> {
  Digest? digest;

  @override
  void add(Digest data) {
    digest = data;
  }

  @override
  void close() {}
}
