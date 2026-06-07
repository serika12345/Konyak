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
    environment: _macosWineEnvironment(
      bottle: bottle,
      environment: environment,
    ),
    logPath: _joinPath(bottle.path, const ['logs', 'prefix-init.log']),
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
  final wineEnvironment = <String, String>{
    'WINEPREFIX': bottle.path,
    'WINEDEBUG': 'fixme-all',
    'GST_DEBUG': '1',
    'DYLD_LIBRARY_PATH': _prependPaths(<String>[
      if (d3dMetalSelected) _macosD3DMetalExternalPath(runtimeRoot),
      if (d3dMetalSelected) _macosD3DMetalUnixPath(runtimeRoot),
      _joinPath(runtimeRoot, const ['lib']),
    ], Option.fromNullable(environment['DYLD_LIBRARY_PATH'])),
    if (d3dMetalSelected)
      'DYLD_FRAMEWORK_PATH': _prependPaths(<String>[
        _macosD3DMetalExternalPath(runtimeRoot),
      ], Option.fromNullable(environment['DYLD_FRAMEWORK_PATH'])),
    if (d3dMetalSelected)
      'CX_APPLEGPTK_LIBD3DSHARED_PATH': _joinPath(runtimeRoot, const [
        'lib',
        'external',
        'libd3dshared.dylib',
      ]),
    ...bottle.runtimeSettings.macosEnvironment().toMap(),
  };
  if (d3dMetalSelected) {
    wineEnvironment['WINEDLLPATH'] = _macosD3DMetalWindowsPath(runtimeRoot);
  } else if (bottle.runtimeSettings.dxmt) {
    wineEnvironment['WINEDLLPATH'] = [
      _joinPath(runtimeRoot, const ['lib', 'dxmt', 'x86_64-windows']),
      _joinPath(runtimeRoot, const ['lib', 'dxmt', 'i386-windows']),
    ].join(':');
  } else if (bottle.runtimeSettings.dxvk) {
    wineEnvironment['WINEDLLPATH'] = [
      _joinPath(runtimeRoot, const ['lib', 'dxvk', 'x86_64-windows']),
      _joinPath(runtimeRoot, const ['lib', 'dxvk', 'i386-windows']),
    ].join(':');
  }

  return ProgramRunEnvironment(wineEnvironment);
}

String _macosD3DMetalExternalPath(String runtimeRoot) {
  return _joinPath(runtimeRoot, const ['lib', 'external']);
}

String _macosD3DMetalWindowsPath(String runtimeRoot) {
  return _joinPath(runtimeRoot, const ['lib', 'wine', 'x86_64-windows']);
}

String _macosD3DMetalUnixPath(String runtimeRoot) {
  return _joinPath(runtimeRoot, const ['lib', 'wine', 'x86_64-unix']);
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
