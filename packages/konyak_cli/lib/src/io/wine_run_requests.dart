part of '../../konyak_cli.dart';

const _dxvkOverrideDllNames = <String>[
  'dxgi.dll',
  'd3d9.dll',
  'd3d10core.dll',
  'd3d11.dll',
];

void _syncMacosDxvkDllOverrides({
  required BottleRecord bottle,
  required Map<String, String> environment,
}) {
  final runtimeRoot = _macosWineRuntimeRoot(environment);
  for (final arch in const <(String, String)>[
    ('x64', 'system32'),
    ('x32', 'syswow64'),
  ]) {
    final (runtimeArch, windowsDirectory) = arch;
    final destinationDirectory = Directory(
      _joinPath(bottle.path, <String>['drive_c', 'windows', windowsDirectory]),
    )..createSync(recursive: true);

    for (final dllName in _dxvkOverrideDllNames) {
      final sourcePath = _joinPath(runtimeRoot, <String>[
        'DXVK',
        runtimeArch,
        dllName,
      ]);
      final sourceFile = File(sourcePath);
      if (!sourceFile.existsSync()) {
        throw FileSystemException(
          'DXVK override DLL was not found.',
          sourcePath,
        );
      }
      sourceFile.copySync(_joinPath(destinationDirectory.path, [dllName]));
    }
  }
}

Map<String, String> _linuxWineEnvironment(BottleRecord bottle) {
  return <String, String>{
    ..._linuxWinePrefixEnvironment(bottle),
    ...bottle.runtimeSettings.macosEnvironmentVariables(),
  };
}

Map<String, String> _linuxWinePrefixEnvironment(BottleRecord bottle) {
  return <String, String>{'WINEPREFIX': bottle.path};
}

Map<String, String> _linuxWineEnvironmentWithRuntime({
  required BottleRecord bottle,
  required Map<String, String> environment,
}) {
  final wineEnvironment = <String, String>{..._linuxWineEnvironment(bottle)};
  final dllPathEntries = <String>[];
  if (bottle.runtimeSettings.dxvk) {
    final runtimeRoot = _linuxWineRuntimeRoot(environment);
    dllPathEntries.addAll([
      _joinPath(runtimeRoot, const ['dxvk', 'x64']),
      _joinPath(runtimeRoot, const ['dxvk', 'x86']),
    ]);
  }
  if (bottle.runtimeSettings.vkd3dProton) {
    final runtimeRoot = _linuxWineRuntimeRoot(environment);
    dllPathEntries.addAll([
      _joinPath(runtimeRoot, const ['vkd3d-proton', 'x64']),
      _joinPath(runtimeRoot, const ['vkd3d-proton', 'x86']),
    ]);
  }
  if (dllPathEntries.isNotEmpty) {
    wineEnvironment['WINEDLLPATH'] = dllPathEntries.join(':');
  }

  final dllOverrides = <String>[
    if (bottle.runtimeSettings.dxvk) ...['dxgi', 'd3d9', 'd3d10core', 'd3d11'],
    if (bottle.runtimeSettings.vkd3dProton) ...['d3d12', 'd3d12core'],
  ];
  if (dllOverrides.isNotEmpty) {
    wineEnvironment['WINEDLLOVERRIDES'] = dllOverrides
        .map((dllName) => '$dllName=n,b')
        .join(';');
  }

  return Map.unmodifiable(wineEnvironment);
}

ProgramRunRequest _macosWineCommandRequest({
  required BottleRecord bottle,
  required String command,
  required Map<String, String> environment,
}) {
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: command,
    runnerKind: 'macosWine',
    executable: _macosWineExecutable(environment),
    arguments: <String>[command],
    environment: _macosWineEnvironment(
      bottle: bottle,
      environment: environment,
    ),
    logPath: _joinPath(bottle.path, const ['logs', 'latest.log']),
    workingDirectory: Option.of(_macosWineBinFolder(environment)),
  );
}

ProgramRunRequest _macosRegistryUpdateRequest({
  required BottleRecord bottle,
  required _RegistryValueUpdate update,
  required Map<String, String> environment,
}) {
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: 'reg',
    runnerKind: 'macosWineRegistry',
    executable: _macosWineExecutable(environment),
    arguments: _registryUpdateArguments(update),
    environment: _macosWineEnvironment(
      bottle: bottle,
      environment: environment,
    ),
    logPath: _joinPath(bottle.path, const ['logs', 'latest.log']),
    workingDirectory: Option.of(_macosWineBinFolder(environment)),
  );
}

ProgramRunRequest _macosRegistryQueryRequest({
  required BottleRecord bottle,
  required _RegistryValueQuery query,
  required Map<String, String> environment,
}) {
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: 'reg',
    runnerKind: 'macosWineRegistryQuery',
    executable: _macosWineExecutable(environment),
    arguments: _registryQueryArguments(query),
    environment: _macosWineEnvironment(
      bottle: bottle,
      environment: environment,
    ),
    logPath: _joinPath(bottle.path, const ['logs', 'registry.log']),
    workingDirectory: Option.of(_macosWineBinFolder(environment)),
  );
}

ProgramRunRequest _linuxTerminalCommandRequest({
  required BottleRecord bottle,
  required Map<String, String> environment,
}) {
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: 'terminal',
    runnerKind: 'terminal',
    executable: 'sh',
    arguments: <String>[
      '-lc',
      _linuxTerminalLauncherCommand(environment),
      _linuxWineTerminalShellCommandWithEnvironment(
        bottle: bottle,
        environment: environment,
      ),
    ],
    environment: const <String, String>{},
    logPath: _joinPath(bottle.path, const ['logs', 'latest.log']),
    workingDirectory: Option.of(bottle.path),
  );
}

ProgramRunRequest _macosTerminalCommandRequest({
  required BottleRecord bottle,
  required Map<String, String> environment,
}) {
  final shellCommand = _macosWineTerminalShellCommand(
    bottle: bottle,
    environment: environment,
  );

  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: 'terminal',
    runnerKind: 'macosTerminal',
    executable: '/usr/bin/osascript',
    arguments: <String>['-e', _macosTerminalAppleScript(shellCommand)],
    environment: const <String, String>{},
    logPath: _joinPath(bottle.path, const ['logs', 'latest.log']),
  );
}

ProgramRunRequest _linuxWinetricksCommandRequest({
  required BottleRecord bottle,
  required Map<String, String> environment,
  String? verb,
}) {
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: verb ?? 'winetricks',
    runnerKind: 'winetricks',
    executable: _linuxWinetricksExecutable(environment),
    arguments: verb == null ? const <String>[] : <String>[verb],
    environment: <String, String>{
      ..._linuxRuntimeEnvironment(environment),
      ..._linuxWineEnvironmentWithRuntime(
        bottle: bottle,
        environment: environment,
      ),
    },
    logPath: _joinPath(bottle.path, const ['logs', 'latest.log']),
  );
}

ProgramRunRequest _macosWinetricksCommandRequest({
  required BottleRecord bottle,
  required Map<String, String> environment,
  required String? verb,
}) {
  final runtimeRoot = _macosWineRuntimeRoot(environment);
  final runtimeBin = _macosWineBinFolder(environment);

  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: verb ?? 'winetricks',
    runnerKind: 'macosWinetricks',
    executable: _macosWinetricksExecutable(environment),
    arguments: verb == null ? const <String>[] : <String>[verb],
    environment: <String, String>{
      ..._macosWineEnvironment(bottle: bottle, environment: environment),
      'WINE': 'wine64',
      'PATH': _prependPath(
        runtimeBin,
        Option.fromNullable(environment['PATH']),
      ),
    },
    logPath: _joinPath(bottle.path, const ['logs', 'latest.log']),
    workingDirectory: Option.of(runtimeRoot),
  );
}
