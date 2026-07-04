import 'package:fpdart/fpdart.dart';

import '../domain/bottle/bottle_models.dart';
import '../domain/runtime/host_environment.dart';
import '../domain/runtime/wine_runtime_paths.dart';
import '../domain/shared/domain_value_objects.dart';
import '../io/wine_run_requests.dart';
import '../shared/common_helpers.dart';
import 'macos/macos_program_run_requests.dart';

Option<String> linuxTerminalOverride(HostEnvironment environment) {
  return environment.nonEmptyValue('TERMINAL');
}

String linuxTerminalLauncherCommand(HostEnvironment environment) {
  final override = linuxTerminalOverride(environment);
  final candidates = <String>[
    ...override.match(
      () => const <String>[],
      (terminal) => <String>[
        'exec ${shellQuote(terminal)} -e bash -lc "\$0" sh',
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

String linuxWineTerminalShellCommandWithEnvironment({
  required BottleRecord bottle,
  required HostEnvironment environment,
  Option<BottleCommand> initialWineCommand = const Option.none(),
}) {
  final hostEnvironment = environment;
  final executable = linuxWineExecutable(hostEnvironment);
  final runtimeBin = linuxManagedRuntimeBinFolder(hostEnvironment);
  final wineLibraryPath = hostEnvironment.nonEmptyValue(
    'KONYAK_LINUX_WINE_LIBRARY_PATH',
  );
  final shellSetup = <String>[
    'cd ${shellQuote(bottle.path.value)}',
    'export WINEPREFIX=${shellQuote(bottle.path.value)}',
    'export WINE=${shellQuote(executable)}',
    'export PATH=${shellQuote(runtimeBin)}:\$PATH',
    ...wineLibraryPath.match(
      () => const <String>[],
      (path) => <String>[
        'export LD_LIBRARY_PATH=${shellQuote(path)}:\${LD_LIBRARY_PATH:-}',
      ],
    ),
    for (final entry in linuxWineLogSuppressionEnvironment().toMap().entries)
      'export ${entry.key}=${shellQuote(entry.value)}',
    'alias wine=${shellQuote(executable)}',
    'alias wine64=${shellQuote(executable)}',
    'alias winecfg=${shellQuote('$executable winecfg')}',
    'alias msiexec=${shellQuote('$executable msiexec')}',
    ...initialWineCommand.match(
      () => const <String>[],
      (command) => <String>[
        wineTerminalInitialCommand(executable: executable, command: command),
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

String macosWineTerminalShellCommand({
  required BottleRecord bottle,
  required HostEnvironment environment,
  required Option<MacosMajorVersion> macosMajorVersion,
  Option<BottleCommand> initialWineCommand = const Option.none(),
}) {
  final runtimeBin = macosWineBinFolder(environment);
  final executable = macosWineExecutable(environment);
  return <String>[
    'cd ${shellQuote(bottle.path.value)}',
    'export PATH=${shellQuote(runtimeBin)}:\$PATH',
    'export WINE=${shellQuote(executable)}',
    'alias wine=${shellQuote(executable)}',
    'alias wine64=${shellQuote(executable)}',
    'alias winecfg=${shellQuote('$executable winecfg')}',
    'alias msiexec=${shellQuote('$executable msiexec')}',
    'alias regedit=${shellQuote('$executable regedit')}',
    'alias regsvr32=${shellQuote('$executable regsvr32')}',
    'alias wineboot=${shellQuote('$executable wineboot')}',
    'alias wineconsole=${shellQuote('$executable wineconsole')}',
    'alias winedbg=${shellQuote('$executable winedbg')}',
    'alias winefile=${shellQuote('$executable winefile')}',
    'alias winepath=${shellQuote('$executable winepath')}',
    ...macosWineEnvironment(
      bottle: bottle,
      environment: environment,
      macosMajorVersion: macosMajorVersion,
    ).toMap().entries.map((entry) {
      return 'export ${entry.key}=${shellQuote(entry.value)}';
    }),
    ...initialWineCommand.match(
      () => const <String>[],
      (command) => <String>[
        wineTerminalInitialCommand(executable: executable, command: command),
      ],
    ),
  ].join('; ');
}

String wineTerminalInitialCommand({
  required String executable,
  required BottleCommand command,
}) {
  return '${shellQuote(executable)} ${shellQuote(command.value)}';
}

String macosTerminalSetupScriptPath(BottleRecord bottle) {
  return joinPath(bottle.path.value, const [
    'logs',
    'konyak-terminal-setup.zsh',
  ]);
}

String macosTerminalAppleScript({
  required String shellCommand,
  required String setupScriptPath,
}) {
  final setupDirectory = dirname(setupScriptPath);
  final escapedSetupDirectory = appleScriptString(setupDirectory);
  final escapedSetupFile = appleScriptString(setupScriptPath);
  final escapedSetupText = appleScriptString(shellCommand);
  final escapedTerminalCommand = appleScriptString(
    'source ${shellQuote(setupScriptPath)}',
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

String appleScriptString(String value) {
  return value
      .replaceAll(r'\', r'\\')
      .replaceAll('"', r'\"')
      .replaceAll('\n', r'\n');
}

String shellQuote(String value) {
  return "'${value.replaceAll("'", "'\"'\"'")}'";
}

String prependPath(String path, Option<String> existingPath) {
  return existingPath.match(() => path, (existingPath) {
    if (existingPath.trim().isEmpty) {
      return path;
    }

    return '$path:$existingPath';
  });
}

String basename(String path) {
  return path.split('/').last;
}

String dirname(String path) {
  final index = path.lastIndexOf('/');
  if (index <= 0) {
    return '.';
  }

  return path.substring(0, index);
}
