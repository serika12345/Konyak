part of '../../konyak_cli.dart';

Option<String> _linuxTerminalOverride(Map<String, String> environment) {
  final terminal = environment['TERMINAL'];
  if (terminal != null && terminal.trim().isNotEmpty) {
    return Option.of(terminal.trim());
  }

  return const Option.none();
}

String _linuxTerminalLauncherCommand(Map<String, String> environment) {
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
  required Map<String, String> environment,
}) {
  final hostEnvironment = HostEnvironment(environment);
  final executable = _linuxWineExecutable(hostEnvironment);
  final runtimeBin = _linuxManagedRuntimeBinFolder(hostEnvironment);
  final wineLibraryPath = hostEnvironment.nonEmptyValue(
    'KONYAK_LINUX_WINE_LIBRARY_PATH',
  );
  final shellSetup = <String>[
    'cd ${_shellQuote(bottle.path)}',
    'export WINEPREFIX=${_shellQuote(bottle.path)}',
    'export WINE=${_shellQuote(executable)}',
    ...runtimeBin.match(
      () => const <String>[],
      (path) => <String>['export PATH=${_shellQuote(path)}:\$PATH'],
    ),
    if (wineLibraryPath != null)
      'export LD_LIBRARY_PATH=${_shellQuote(wineLibraryPath)}:\${LD_LIBRARY_PATH:-}',
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
  final runtimeBin = _macosWineBinFolder(HostEnvironment(environment));
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
