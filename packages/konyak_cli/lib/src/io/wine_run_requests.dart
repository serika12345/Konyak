part of '../../konyak_cli.dart';

const _dxvkOverrideDllNames = <String>[
  'dxgi.dll',
  'd3d9.dll',
  'd3d10core.dll',
  'd3d11.dll',
];

const _macosD3DTranslationOverrideDllNames = <String>[
  ..._dxvkOverrideDllNames,
  'winemetal.dll',
];

void _removeMacosD3DTranslationDllOverrides({required BottleRecord bottle}) {
  for (final windowsDirectory in const <String>['system32', 'syswow64']) {
    for (final dllName in _macosD3DTranslationOverrideDllNames) {
      final dllPath = _joinPath(bottle.path, <String>[
        'drive_c',
        'windows',
        windowsDirectory,
        dllName,
      ]);
      final type = FileSystemEntity.typeSync(dllPath);
      if (type == FileSystemEntityType.notFound) {
        continue;
      }
      _deleteFileSystemEntitySync(dllPath, type);
    }
  }
}

void _syncMacosDxvkDllOverrides({
  required BottleRecord bottle,
  required Map<String, String> environment,
}) {
  final hostEnvironment = HostEnvironment(environment);
  final runtimeRoot = _macosWineRuntimeRoot(hostEnvironment);
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

void _syncMacosBuiltinD3DDllOverrides({
  required BottleRecord bottle,
  required Map<String, String> environment,
}) {
  final hostEnvironment = HostEnvironment(environment);
  final runtimeRoot = _macosWineRuntimeRoot(hostEnvironment);
  for (final arch in const <(String, String)>[
    ('x86_64-windows', 'system32'),
    ('i386-windows', 'syswow64'),
  ]) {
    final (runtimeArch, windowsDirectory) = arch;
    final destinationDirectory = Directory(
      _joinPath(bottle.path, <String>['drive_c', 'windows', windowsDirectory]),
    )..createSync(recursive: true);

    for (final dllName in _dxvkOverrideDllNames) {
      final sourcePath = _joinPath(runtimeRoot, <String>[
        'lib',
        'wine',
        runtimeArch,
        dllName,
      ]);
      final sourceFile = File(sourcePath);
      if (!sourceFile.existsSync()) {
        throw FileSystemException(
          'Wine builtin D3D DLL was not found.',
          sourcePath,
        );
      }
      sourceFile.copySync(_joinPath(destinationDirectory.path, [dllName]));
    }
  }
}

ProgramRunEnvironment _linuxWineEnvironment(BottleRecord bottle) {
  return _linuxWinePrefixEnvironment(
    bottle,
  ).merge(bottle.runtimeSettings.macosEnvironment());
}

ProgramRunEnvironment _linuxWinePrefixEnvironment(BottleRecord bottle) {
  return ProgramRunEnvironment(<String, String>{'WINEPREFIX': bottle.path});
}

ProgramRunEnvironment _linuxWineEnvironmentWithRuntime({
  required BottleRecord bottle,
  required HostEnvironment environment,
}) {
  final wineEnvironment = _linuxWineEnvironment(bottle);
  final hostEnvironment = environment;
  final dllPathEntries = <String>[];
  if (bottle.runtimeSettings.dxvk) {
    final runtimeRoot = _linuxWineRuntimeRoot(hostEnvironment);
    dllPathEntries.addAll([
      _joinPath(runtimeRoot, const ['dxvk', 'x64']),
      _joinPath(runtimeRoot, const ['dxvk', 'x86']),
    ]);
  }
  if (bottle.runtimeSettings.vkd3dProton) {
    final runtimeRoot = _linuxWineRuntimeRoot(hostEnvironment);
    dllPathEntries.addAll([
      _joinPath(runtimeRoot, const ['vkd3d-proton', 'x64']),
      _joinPath(runtimeRoot, const ['vkd3d-proton', 'x86']),
    ]);
  }
  if (dllPathEntries.isNotEmpty) {
    final wineEnvironmentWithDllPath = wineEnvironment.add(
      'WINEDLLPATH',
      dllPathEntries.join(':'),
    );
    return _linuxWineEnvironmentWithDllOverrides(
      wineEnvironment: wineEnvironmentWithDllPath,
      bottle: bottle,
    );
  }

  return _linuxWineEnvironmentWithDllOverrides(
    wineEnvironment: wineEnvironment,
    bottle: bottle,
  );
}

ProgramRunEnvironment _linuxWineEnvironmentWithDllOverrides({
  required ProgramRunEnvironment wineEnvironment,
  required BottleRecord bottle,
}) {
  final dllOverrides = <String>[
    if (bottle.runtimeSettings.dxvk) ...['dxgi', 'd3d9', 'd3d10core', 'd3d11'],
    if (bottle.runtimeSettings.vkd3dProton) ...['d3d12', 'd3d12core'],
  ];
  if (dllOverrides.isNotEmpty) {
    return wineEnvironment.add(
      'WINEDLLOVERRIDES',
      dllOverrides.map((dllName) => '$dllName=n,b').join(';'),
    );
  }

  return wineEnvironment;
}

ProgramRunRequest _macosWineCommandRequest({
  required BottleRecord bottle,
  required String command,
  required HostEnvironment environment,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: command,
    runnerKind: 'macosWine',
    executable: _macosWineExecutable(hostEnvironment),
    arguments: <String>[command],
    environment: _macosWineEnvironment(
      bottle: bottle,
      environment: environment,
    ),
    logPath: _joinPath(bottle.path, const ['logs', 'latest.log']),
    workingDirectory: Option.of(_macosWineBinFolder(hostEnvironment)),
  );
}

ProgramRunRequest _macosRegistryUpdateRequest({
  required BottleRecord bottle,
  required _RegistryValueUpdate update,
  required HostEnvironment environment,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: 'reg',
    runnerKind: 'macosWineRegistry',
    executable: _macosWineExecutable(hostEnvironment),
    arguments: _registryUpdateArguments(update),
    environment: _macosWineEnvironment(
      bottle: bottle,
      environment: environment,
    ),
    logPath: _joinPath(bottle.path, const ['logs', 'latest.log']),
    workingDirectory: Option.of(_macosWineBinFolder(hostEnvironment)),
  );
}

ProgramRunRequest _macosRegistryQueryRequest({
  required BottleRecord bottle,
  required _RegistryValueQuery query,
  required HostEnvironment environment,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: 'reg',
    runnerKind: 'macosWineRegistryQuery',
    executable: _macosWineExecutable(hostEnvironment),
    arguments: _registryQueryArguments(query),
    environment: _macosWineEnvironment(
      bottle: bottle,
      environment: environment,
    ),
    logPath: _joinPath(bottle.path, const ['logs', 'registry.log']),
    workingDirectory: Option.of(_macosWineBinFolder(hostEnvironment)),
  );
}

ProgramRunRequest _linuxTerminalCommandRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
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
    environment: const ProgramRunEnvironment.empty(),
    logPath: _joinPath(bottle.path, const ['logs', 'latest.log']),
    workingDirectory: Option.of(bottle.path),
  );
}

ProgramRunRequest _macosTerminalCommandRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
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
    environment: const ProgramRunEnvironment.empty(),
    logPath: _joinPath(bottle.path, const ['logs', 'latest.log']),
  );
}

ProgramRunRequest _linuxWinetricksCommandRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
  String? verb,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: verb ?? 'winetricks',
    runnerKind: 'winetricks',
    executable: _linuxWinetricksExecutable(hostEnvironment),
    arguments: verb == null ? const <String>[] : <String>[verb],
    environment: _linuxRuntimeEnvironment(hostEnvironment).merge(
      _linuxWineEnvironmentWithRuntime(
        bottle: bottle,
        environment: environment,
      ),
    ),
    logPath: _joinPath(bottle.path, const ['logs', 'latest.log']),
  );
}

ProgramRunRequest _macosWinetricksCommandRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
  required String? verb,
}) {
  final hostEnvironment = environment;
  final runtimeRoot = _macosWineRuntimeRoot(hostEnvironment);
  final runtimeBin = _macosWineBinFolder(hostEnvironment);

  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: verb ?? 'winetricks',
    runnerKind: 'macosWinetricks',
    executable: _macosWinetricksExecutable(hostEnvironment),
    arguments: verb == null ? const <String>[] : <String>[verb],
    environment: _macosWineEnvironment(bottle: bottle, environment: environment)
        .add('WINE', 'wine64')
        .add(
          'PATH',
          _prependPath(runtimeBin, Option.fromNullable(environment['PATH'])),
        ),
    logPath: _joinPath(bottle.path, const ['logs', 'latest.log']),
    workingDirectory: Option.of(runtimeRoot),
  );
}
