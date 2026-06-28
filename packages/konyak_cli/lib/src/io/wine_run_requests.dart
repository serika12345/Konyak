part of '../../konyak_cli.dart';

const _dxvkOverrideDllNames = <String>[
  'dxgi.dll',
  'd3d9.dll',
  'd3d10.dll',
  'd3d10_1.dll',
  'd3d10core.dll',
  'd3d11.dll',
];

const _macosD3DTranslationOverrideDllNames = <String>[
  ..._dxvkOverrideDllNames,
  'd3d12.dll',
  'nvapi64.dll',
  'nvngx.dll',
  'nvngx-on-metalfx.dll',
  'winemetal.dll',
];

const _d3dMetalOverrideDllNames = <String>[
  'dxgi.dll',
  'd3d11.dll',
  'd3d12.dll',
  'nvapi64.dll',
  'nvngx.dll',
];

void _removeMacosD3DTranslationDllOverrides({required BottleRecord bottle}) {
  for (final windowsDirectory in const <String>['system32', 'syswow64']) {
    for (final dllName in _macosD3DTranslationOverrideDllNames) {
      final dllPath = _joinPath(bottle.path.value, <String>[
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
  final runtimeRoot = macosWineRuntimeRoot(hostEnvironment);
  for (final arch in const <(String, String)>[
    ('x86_64-windows', 'system32'),
    ('i386-windows', 'syswow64'),
  ]) {
    final (runtimeArch, windowsDirectory) = arch;
    final destinationDirectory = Directory(
      _joinPath(bottle.path.value, <String>[
        'drive_c',
        'windows',
        windowsDirectory,
      ]),
    )..createSync(recursive: true);

    for (final dllName in _dxvkOverrideDllNames) {
      final sourcePath = _joinPath(runtimeRoot, <String>[
        'lib',
        'dxvk',
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

void _syncMacosD3DMetalDllOverrides({
  required BottleRecord bottle,
  required Map<String, String> environment,
}) {
  final hostEnvironment = HostEnvironment(environment);
  final runtimeRoot = macosWineRuntimeRoot(hostEnvironment);
  final destinationDirectory = Directory(
    _joinPath(bottle.path.value, const ['drive_c', 'windows', 'system32']),
  )..createSync(recursive: true);

  for (final dllName in _d3dMetalOverrideDllNames) {
    _d3DMetalOverrideSourcePath(
      runtimeRoot: runtimeRoot,
      dllName: dllName,
    ).match(
      () {
        throw FileSystemException(
          'D3DMetal override DLL was not found.',
          _joinPath(runtimeRoot, <String>[
            ..._gptkD3DMetalComponentLibRelativePath,
            'wine',
            'x86_64-windows',
            dllName,
          ]),
        );
      },
      (sourcePath) {
        final sourceFile = File(sourcePath);
        sourceFile.copySync(_joinPath(destinationDirectory.path, [dllName]));
      },
    );
  }
}

Option<String> _d3DMetalOverrideSourcePath({
  required String runtimeRoot,
  required String dllName,
}) {
  for (final sourceName in _d3DMetalOverrideSourceNames(dllName)) {
    for (final sourceRoot in <List<String>>[
      <String>[
        ..._gptkD3DMetalComponentLibRelativePath,
        'wine',
        'x86_64-windows',
      ],
      const <String>['lib', 'wine', 'x86_64-windows'],
    ]) {
      final sourcePath = _joinPath(runtimeRoot, <String>[
        ...sourceRoot,
        sourceName,
      ]);
      if (File(sourcePath).existsSync()) {
        return Option.of(sourcePath);
      }
    }
  }
  return const Option.none();
}

List<String> _d3DMetalOverrideSourceNames(String dllName) {
  return switch (dllName) {
    'nvngx.dll' => const <String>['nvngx.dll', 'nvngx-on-metalfx.dll'],
    _ => <String>[dllName],
  };
}

ProgramRunEnvironment _linuxWineEnvironment(BottleRecord bottle) {
  return _linuxWinePrefixEnvironment(bottle)
      .merge(bottle.runtimeSettings.linuxEnvironment())
      .merge(_linuxWineLogSuppressionEnvironment());
}

ProgramRunEnvironment _linuxWinePrefixEnvironment(BottleRecord bottle) {
  return ProgramRunEnvironment(<String, String>{
    'WINEPREFIX': bottle.path.value,
  });
}

ProgramRunEnvironment _linuxWineLogSuppressionEnvironment() {
  return ProgramRunEnvironment(const <String, String>{
    'EGL_LOG_LEVEL': 'fatal',
    'MESA_LOG_LEVEL': 'fatal',
    'MESA_DEBUG': 'silent',
  });
}

ProgramRunEnvironment _linuxWineEnvironmentWithRuntime({
  required BottleRecord bottle,
  required HostEnvironment environment,
}) {
  final wineEnvironment = _linuxWineEnvironment(bottle);
  final hostEnvironment = environment;
  final dllPathEntries = <String>[];
  if (bottle.runtimeSettings.dxvk) {
    final runtimeRoot = linuxWineRuntimeRoot(hostEnvironment);
    dllPathEntries.addAll([
      _joinPath(runtimeRoot, const ['dxvk', 'x64']),
      _joinPath(runtimeRoot, const ['dxvk', 'x86']),
    ]);
  }
  if (bottle.runtimeSettings.vkd3dProton) {
    final runtimeRoot = linuxWineRuntimeRoot(hostEnvironment);
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
    if (bottle.runtimeSettings.dxvk) ...[
      'dxgi',
      'd3d9',
      'd3d10',
      'd3d10_1',
      'd3d10core',
      'd3d11',
    ],
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

ProgramRunRequest macosWineCommandRequest({
  required BottleRecord bottle,
  required String command,
  required HostEnvironment environment,
  required Option<int> macosMajorVersion,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id.value,
    programPath: command,
    runnerKind: 'macosWine',
    executable: macosWineExecutable(hostEnvironment),
    arguments: wineArgumentsForBottleCommand(command),
    environment: _macosWineEnvironment(
      bottle: bottle,
      environment: environment,
      macosMajorVersion: macosMajorVersion,
    ),
    logPath: _joinPath(bottle.path.value, const ['logs', 'latest.log']),
    workingDirectory: Option.of(macosWineBinFolder(hostEnvironment)),
  );
}

ProgramRunRequest macosRegistryUpdateRequest({
  required BottleRecord bottle,
  required RegistryValueUpdate update,
  required HostEnvironment environment,
  required Option<int> macosMajorVersion,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id.value,
    programPath: 'reg',
    runnerKind: 'macosWineRegistry',
    executable: macosWineExecutable(hostEnvironment),
    arguments: registryUpdateArguments(update),
    environment: _macosWineEnvironment(
      bottle: bottle,
      environment: environment,
      macosMajorVersion: macosMajorVersion,
    ),
    logPath: _joinPath(bottle.path.value, const ['logs', 'latest.log']),
    workingDirectory: Option.of(macosWineBinFolder(hostEnvironment)),
  );
}

ProgramRunRequest macosRegistryQueryRequest({
  required BottleRecord bottle,
  required RegistryValueQuery query,
  required HostEnvironment environment,
  required Option<int> macosMajorVersion,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id.value,
    programPath: 'reg',
    runnerKind: 'macosWineRegistryQuery',
    executable: macosWineExecutable(hostEnvironment),
    arguments: registryQueryArguments(query),
    environment: _macosWineEnvironment(
      bottle: bottle,
      environment: environment,
      macosMajorVersion: macosMajorVersion,
    ),
    logPath: _joinPath(bottle.path.value, const ['logs', 'registry.log']),
    workingDirectory: Option.of(macosWineBinFolder(hostEnvironment)),
  );
}

ProgramRunRequest linuxTerminalCommandRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
  Option<String> initialWineCommand = const Option.none(),
}) {
  return ProgramRunRequest(
    bottleId: bottle.id.value,
    programPath: initialWineCommand.getOrElse(() => 'terminal'),
    runnerKind: 'terminal',
    executable: 'sh',
    arguments: <String>[
      '-lc',
      _linuxTerminalLauncherCommand(environment),
      _linuxWineTerminalShellCommandWithEnvironment(
        bottle: bottle,
        environment: environment,
        initialWineCommand: initialWineCommand,
      ),
    ],
    environment: const ProgramRunEnvironment.empty(),
    logPath: _joinPath(bottle.path.value, const ['logs', 'latest.log']),
    workingDirectory: Option.of(bottle.path.value),
  );
}

ProgramRunRequest macosTerminalCommandRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
  required Option<int> macosMajorVersion,
  Option<String> initialWineCommand = const Option.none(),
}) {
  final shellCommand = _macosWineTerminalShellCommand(
    bottle: bottle,
    environment: environment,
    macosMajorVersion: macosMajorVersion,
    initialWineCommand: initialWineCommand,
  );
  final setupScriptPath = _macosTerminalSetupScriptPath(bottle);

  return ProgramRunRequest(
    bottleId: bottle.id.value,
    programPath: initialWineCommand.getOrElse(() => 'terminal'),
    runnerKind: 'macosTerminal',
    executable: '/usr/bin/osascript',
    arguments: <String>[
      '-e',
      _macosTerminalAppleScript(
        shellCommand: shellCommand,
        setupScriptPath: setupScriptPath,
      ),
    ],
    environment: const ProgramRunEnvironment.empty(),
    logPath: _joinPath(bottle.path.value, const ['logs', 'latest.log']),
  );
}

ProgramRunRequest linuxWinetricksCommandRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
  Option<String> verb = const Option.none(),
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id.value,
    programPath: verb.getOrElse(() => 'winetricks'),
    runnerKind: 'winetricks',
    executable: linuxWinetricksExecutable(hostEnvironment),
    arguments: verb.match(() => const <String>[], (value) => <String>[value]),
    environment: linuxRuntimeEnvironment(hostEnvironment).merge(
      _linuxWineEnvironmentWithRuntime(
        bottle: bottle,
        environment: environment,
      ),
    ),
    logPath: _joinPath(bottle.path.value, const ['logs', 'latest.log']),
  );
}

ProgramRunRequest macosWinetricksCommandRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
  required Option<int> macosMajorVersion,
  required Option<String> verb,
}) {
  final hostEnvironment = environment;
  final runtimeRoot = macosWineRuntimeRoot(hostEnvironment);
  final runtimeBin = macosWineBinFolder(hostEnvironment);

  return ProgramRunRequest(
    bottleId: bottle.id.value,
    programPath: verb.getOrElse(() => 'winetricks'),
    runnerKind: 'macosWinetricks',
    executable: macosWinetricksExecutable(hostEnvironment),
    arguments: verb.match(() => const <String>[], (value) => <String>[value]),
    environment:
        _macosWineEnvironment(
              bottle: bottle,
              environment: environment,
              macosMajorVersion: macosMajorVersion,
            )
            .add('WINE', macosWineExecutable(hostEnvironment))
            .add('PATH', _prependPath(runtimeBin, environment['PATH'])),
    logPath: _joinPath(bottle.path.value, const ['logs', 'latest.log']),
    workingDirectory: Option.of(runtimeRoot),
  );
}
