part of '../../konyak_cli.dart';

Option<String> _linuxTerminalOverride(HostEnvironment environment) {
  return environment.nonEmptyValue('TERMINAL');
}

String _linuxTerminalLauncherCommand(HostEnvironment environment) {
  final override = _linuxTerminalOverride(environment);
  final candidates = <String>[
    ...override.match(
      () => const <String>[],
      (terminal) => <String>[
        'exec ${_shellQuote(terminal)} -e bash -lc "\$0" sh',
      ],
    ),
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
  required HostEnvironment environment,
  Option<String> initialWineCommand = const Option.none(),
}) {
  final hostEnvironment = environment;
  final executable = _linuxWineExecutable(hostEnvironment);
  final runtimeBin = _linuxManagedRuntimeBinFolder(hostEnvironment);
  final wineLibraryPath = hostEnvironment.nonEmptyValue(
    'KONYAK_LINUX_WINE_LIBRARY_PATH',
  );
  final shellSetup = <String>[
    'cd ${_shellQuote(bottle.path.value)}',
    'export WINEPREFIX=${_shellQuote(bottle.path.value)}',
    'export WINE=${_shellQuote(executable)}',
    'export PATH=${_shellQuote(runtimeBin)}:\$PATH',
    ...wineLibraryPath.match(
      () => const <String>[],
      (path) => <String>[
        'export LD_LIBRARY_PATH=${_shellQuote(path)}:\${LD_LIBRARY_PATH:-}',
      ],
    ),
    for (final entry in _linuxWineLogSuppressionEnvironment().toMap().entries)
      'export ${entry.key}=${_shellQuote(entry.value)}',
    'alias wine=${_shellQuote(executable)}',
    'alias wine64=${_shellQuote(executable)}',
    'alias winecfg=${_shellQuote('$executable winecfg')}',
    'alias msiexec=${_shellQuote('$executable msiexec')}',
    ...initialWineCommand.match(
      () => const <String>[],
      (command) => <String>[
        _wineTerminalInitialCommand(executable: executable, command: command),
      ],
    ),
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
  required HostEnvironment environment,
  required Option<int> macosMajorVersion,
  Option<String> initialWineCommand = const Option.none(),
}) {
  final runtimeBin = _macosWineBinFolder(environment);
  final executable = _macosWineExecutable(environment);
  return <String>[
    'cd ${_shellQuote(bottle.path.value)}',
    'export PATH=${_shellQuote(runtimeBin)}:\$PATH',
    'export WINE=${_shellQuote(executable)}',
    'alias wine=${_shellQuote(executable)}',
    'alias wine64=${_shellQuote(executable)}',
    'alias winecfg=${_shellQuote('$executable winecfg')}',
    'alias msiexec=${_shellQuote('$executable msiexec')}',
    'alias regedit=${_shellQuote('$executable regedit')}',
    'alias regsvr32=${_shellQuote('$executable regsvr32')}',
    'alias wineboot=${_shellQuote('$executable wineboot')}',
    'alias wineconsole=${_shellQuote('$executable wineconsole')}',
    'alias winedbg=${_shellQuote('$executable winedbg')}',
    'alias winefile=${_shellQuote('$executable winefile')}',
    'alias winepath=${_shellQuote('$executable winepath')}',
    ..._macosWineEnvironment(
      bottle: bottle,
      environment: environment,
      macosMajorVersion: macosMajorVersion,
    ).toMap().entries.map((entry) {
      return 'export ${entry.key}=${_shellQuote(entry.value)}';
    }),
    ...initialWineCommand.match(
      () => const <String>[],
      (command) => <String>[
        _wineTerminalInitialCommand(executable: executable, command: command),
      ],
    ),
  ].join('; ');
}

String _wineTerminalInitialCommand({
  required String executable,
  required String command,
}) {
  return '${_shellQuote(executable)} ${_shellQuote(command)}';
}

String _macosTerminalSetupScriptPath(BottleRecord bottle) {
  return _joinPath(bottle.path.value, const [
    'logs',
    'konyak-terminal-setup.zsh',
  ]);
}

String _macosTerminalAppleScript({
  required String shellCommand,
  required String setupScriptPath,
}) {
  final setupDirectory = _dirname(setupScriptPath);
  final escapedSetupDirectory = _appleScriptString(setupDirectory);
  final escapedSetupFile = _appleScriptString(setupScriptPath);
  final escapedSetupText = _appleScriptString(shellCommand);
  final escapedTerminalCommand = _appleScriptString(
    'source ${_shellQuote(setupScriptPath)}',
  );

  return '''
set setupDirectory to "$escapedSetupDirectory"
set setupFile to "$escapedSetupFile"
set setupText to "$escapedSetupText"
do shell script "umask 077; mkdir -p " & quoted form of setupDirectory & "; printf %s " & quoted form of setupText & " > " & quoted form of setupFile
tell application "Terminal"
activate
do script "$escapedTerminalCommand"
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

String _prependPath(String path, Option<String> existingPath) {
  return existingPath.match(() => path, (existingPath) {
    if (existingPath.trim().isEmpty) {
      return path;
    }

    return '$path:$existingPath';
  });
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
