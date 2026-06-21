part of '../../../konyak_cli.dart';

ProgramRunRequest _macosWineRequest({
  required BottleRecord bottle,
  required String programPath,
  required HostEnvironment environment,
  required ProgramSettingsRecord programSettings,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: programPath,
    runnerKind: 'macosWine',
    executable: _macosWineExecutable(hostEnvironment),
    arguments: <String>[
      'start',
      '/unix',
      programPath,
      ..._programSettingsArguments(programSettings),
    ],
    environment: ProgramRunEnvironment(<String, String>{
      ..._macosWineEnvironment(
        bottle: bottle,
        environment: environment,
      ).toMap(),
      ..._programSettingsEnvironment(programSettings).toMap(),
      'WINEPREFIX': bottle.path,
    }),
    logPath: _joinPath(bottle.path, const ['logs', 'latest.log']),
    workingDirectory: Option.of(_macosWineBinFolder(hostEnvironment)),
  );
}

ProgramRunRequest _macosWinebootRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: 'wineboot',
    runnerKind: 'macosWine',
    executable: _macosWineExecutable(hostEnvironment),
    arguments: const <String>['wineboot', '--init'],
    environment: _macosPrefixInitializationEnvironment(
      bottle: bottle,
      environment: environment,
    ),
    logPath: _joinPath(bottle.path, const ['logs', 'prefix-init.log']),
    workingDirectory: Option.of(_macosWineBinFolder(hostEnvironment)),
  );
}

ProgramRunRequest _macosWinebootRestartRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: 'wineboot',
    runnerKind: 'macosWine',
    executable: _macosWineExecutable(hostEnvironment),
    arguments: const <String>['wineboot', '--restart'],
    environment: _macosWineEnvironment(
      bottle: bottle,
      environment: environment,
    ),
    logPath: _joinPath(bottle.path, const ['logs', 'latest.log']),
    workingDirectory: Option.of(_macosWineBinFolder(hostEnvironment)),
  );
}

ProgramRunRequest _macosWineMonoInstallRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
}) {
  final hostEnvironment = environment;
  final runtimeRoot = _macosWineRuntimeRoot(hostEnvironment);
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: 'wine-mono',
    runnerKind: 'macosWine',
    executable: _macosWineExecutable(hostEnvironment),
    arguments: <String>[
      'msiexec',
      '/i',
      _macosWineWindowsPath(_macosWineMonoMsiPath(runtimeRoot)),
      '/qn',
      '/norestart',
    ],
    environment: _macosPrefixInitializationEnvironment(
      bottle: bottle,
      environment: environment,
    ),
    logPath: _joinPath(bottle.path, const ['logs', 'wine-mono-install.log']),
    workingDirectory: Option.of(_macosWineBinFolder(hostEnvironment)),
  );
}

ProgramRunRequest _macosWineserverKillRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: 'wineserver',
    runnerKind: 'macosWineserver',
    executable: _macosWineserverExecutable(hostEnvironment),
    arguments: const <String>['-k'],
    environment: _macosWineEnvironment(
      bottle: bottle,
      environment: environment,
    ),
    logPath: _joinPath(bottle.path, const ['logs', 'wineserver-kill.log']),
    workingDirectory: Option.of(_macosWineBinFolder(hostEnvironment)),
  );
}

ProgramRunRequest _macosWinedbgRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
  required String command,
  required String logName,
  List<String> trailingArguments = const <String>[],
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: 'winedbg',
    runnerKind: 'macosWinedbg',
    executable: _macosWineExecutable(hostEnvironment),
    arguments: <String>['winedbg', '--command', command, ...trailingArguments],
    environment: _macosWineEnvironment(
      bottle: bottle,
      environment: environment,
    ),
    logPath: _joinPath(bottle.path, <String>['logs', logName]),
    workingDirectory: Option.of(_macosWineBinFolder(hostEnvironment)),
  );
}

ProgramRunEnvironment _macosWineEnvironment({
  required BottleRecord bottle,
  required HostEnvironment environment,
}) {
  final hostEnvironment = environment;
  final runtimeRoot = _macosWineRuntimeRoot(hostEnvironment);
  final d3dMetalSelected = bottle.runtimeSettings.dxrEnabled;
  final selectedBackendWindowsPaths = <String>[
    if (d3dMetalSelected)
      _macosD3DMetalWindowsPath(runtimeRoot)
    else if (bottle.runtimeSettings.dxmt) ...[
      _joinPath(runtimeRoot, const ['lib', 'dxmt', 'x86_64-windows']),
      _joinPath(runtimeRoot, const ['lib', 'dxmt', 'i386-windows']),
    ] else if (bottle.runtimeSettings.dxvk) ...[
      _joinPath(runtimeRoot, const ['lib', 'dxvk', 'x86_64-windows']),
      _joinPath(runtimeRoot, const ['lib', 'dxvk', 'i386-windows']),
    ],
  ];
  final wineDllPathEntries = <String>[
    ...selectedBackendWindowsPaths,
    ..._macosWineWindowsDllPaths(runtimeRoot),
  ];
  final wineSearchPathEntries = <String>[
    ...selectedBackendWindowsPaths,
    ..._macosWineWindowsSearchPaths(runtimeRoot),
  ];
  final wineEnvironment = <String, String>{
    'WINEPREFIX': bottle.path,
    'WINEDEBUG': 'fixme-all',
    'GST_DEBUG': '1',
    'MVK_CONFIG_LOG_LEVEL': '0',
    'GST_PLUGIN_SYSTEM_PATH': _macosGstreamerPluginPath(runtimeRoot),
    'GST_PLUGIN_SCANNER': _macosGstreamerPluginScanner(runtimeRoot),
    'GST_REGISTRY': _macosGstreamerRegistryPath(bottle.path),
    'WINEDATADIR': _macosWineDataDir(runtimeRoot),
    'WINEDLLPATH': wineDllPathEntries.join(':'),
    'WINEPATH': _macosWineWindowsSearchPath(wineSearchPathEntries),
    'WINELOADER': _macosWineExecutable(hostEnvironment),
    'WINESERVER': _macosWineserverExecutable(hostEnvironment),
    'DYLD_LIBRARY_PATH': _prependPaths(<String>[
      if (d3dMetalSelected) _macosD3DMetalExternalPath(runtimeRoot),
      if (d3dMetalSelected) _macosD3DMetalUnixPath(runtimeRoot),
      if (bottle.runtimeSettings.dxmt && !d3dMetalSelected)
        _macosDxmtUnixPath(runtimeRoot),
      _joinPath(runtimeRoot, const ['lib']),
    ], Option.fromNullable(environment['DYLD_LIBRARY_PATH'])),
    if (d3dMetalSelected)
      'DYLD_FRAMEWORK_PATH': _prependPaths(<String>[
        _macosD3DMetalExternalPath(runtimeRoot),
      ], Option.fromNullable(environment['DYLD_FRAMEWORK_PATH'])),
    if (d3dMetalSelected)
      'CX_APPLEGPTK_LIBD3DSHARED_PATH': _joinPath(runtimeRoot, const [
        ..._gptkD3DMetalComponentLibRelativePath,
        'external',
        'libd3dshared.dylib',
      ]),
    ...bottle.runtimeSettings.macosEnvironment().toMap(),
  };

  return ProgramRunEnvironment(wineEnvironment);
}

String _macosWineWindowsSearchPath(List<String> unixPaths) {
  return unixPaths.map(_macosWineWindowsPath).join(';');
}

String _macosWineWindowsPath(String unixPath) {
  final windowsPath = unixPath.replaceAll('/', '\\');
  if (unixPath.startsWith('/')) {
    return 'Z:$windowsPath';
  }
  return windowsPath;
}

ProgramRunEnvironment _macosPrefixInitializationEnvironment({
  required BottleRecord bottle,
  required HostEnvironment environment,
}) {
  return _macosWineEnvironment(bottle: bottle, environment: environment);
}

String _macosWineDataDir(String runtimeRoot) {
  return _joinPath(runtimeRoot, const ['share', 'wine']);
}

String _macosWineMonoMsiPath(String runtimeRoot) {
  return _joinPath(runtimeRoot, _macosWineMonoComponentPaths.single);
}

String _macosD3DMetalExternalPath(String runtimeRoot) {
  return _joinPath(runtimeRoot, const [
    ..._gptkD3DMetalComponentLibRelativePath,
    'external',
  ]);
}

String _macosGstreamerPluginPath(String runtimeRoot) {
  return _joinPath(runtimeRoot, const ['lib', 'gstreamer-1.0']);
}

String _macosGstreamerPluginScanner(String runtimeRoot) {
  return _joinPath(runtimeRoot, const [
    'libexec',
    'gstreamer-1.0',
    'gst-plugin-scanner',
  ]);
}

String _macosGstreamerRegistryPath(String bottlePath) {
  return _joinPath(bottlePath, const ['gstreamer-1.0-registry.x86_64.bin']);
}

String _macosD3DMetalWindowsPath(String runtimeRoot) {
  return _joinPath(runtimeRoot, const [
    ..._gptkD3DMetalComponentLibRelativePath,
    'wine',
    'x86_64-windows',
  ]);
}

List<String> _macosWineWindowsDllPaths(String runtimeRoot) {
  return <String>[
    _joinPath(runtimeRoot, const ['lib', 'wine', 'x86_64-windows']),
    _joinPath(runtimeRoot, const ['lib', 'wine', 'i386-windows']),
    _joinPath(runtimeRoot, const ['lib', 'wine']),
  ];
}

List<String> _macosWineWindowsSearchPaths(String runtimeRoot) {
  return <String>[
    _joinPath(runtimeRoot, const ['lib', 'wine', 'x86_64-windows']),
    _joinPath(runtimeRoot, const ['lib', 'wine', 'i386-windows']),
  ];
}

String _macosD3DMetalUnixPath(String runtimeRoot) {
  return _joinPath(runtimeRoot, const [
    ..._gptkD3DMetalComponentLibRelativePath,
    'wine',
    'x86_64-unix',
  ]);
}

String _macosDxmtUnixPath(String runtimeRoot) {
  return _joinPath(runtimeRoot, const ['lib', 'dxmt', 'x86_64-unix']);
}

String _prependPaths(Iterable<String> paths, Option<String> existingPath) {
  final prefix = paths.where((path) => path.trim().isNotEmpty).join(':');
  return existingPath.match(() => prefix, (existingPath) {
    if (existingPath.trim().isEmpty) {
      return prefix;
    }

    return '$prefix:$existingPath';
  });
}
