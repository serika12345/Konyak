part of '../../../konyak_cli.dart';

ProgramRunRequest _macosWineRequest({
  required BottleRecord bottle,
  required String programPath,
  required Map<String, String> environment,
  required ProgramSettingsRecord programSettings,
}) {
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: programPath,
    runnerKind: 'macosWine',
    executable: _macosWineExecutable(environment),
    arguments: <String>[
      'start',
      '/unix',
      programPath,
      ..._programSettingsArguments(programSettings),
    ],
    environment: <String, String>{
      ..._macosWineEnvironment(bottle: bottle, environment: environment),
      ..._programSettingsEnvironment(programSettings),
      'WINEPREFIX': bottle.path,
    },
    logPath: _joinPath(bottle.path, const ['logs', 'latest.log']),
    workingDirectory: Option.of(_macosWineBinFolder(environment)),
  );
}

ProgramRunRequest _macosWinebootRequest({
  required BottleRecord bottle,
  required Map<String, String> environment,
}) {
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: 'wineboot',
    runnerKind: 'macosWine',
    executable: _macosWineExecutable(environment),
    arguments: const <String>['wineboot', '--init'],
    environment: _macosWineEnvironment(
      bottle: bottle,
      environment: environment,
    ),
    logPath: _joinPath(bottle.path, const ['logs', 'prefix-init.log']),
    workingDirectory: Option.of(_macosWineBinFolder(environment)),
  );
}

ProgramRunRequest _macosWineserverKillRequest({
  required BottleRecord bottle,
  required Map<String, String> environment,
}) {
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: 'wineserver',
    runnerKind: 'macosWineserver',
    executable: _macosWineserverExecutable(environment),
    arguments: const <String>['-k'],
    environment: _macosWineEnvironment(
      bottle: bottle,
      environment: environment,
    ),
    logPath: _joinPath(bottle.path, const ['logs', 'wineserver-kill.log']),
    workingDirectory: Option.of(_macosWineBinFolder(environment)),
  );
}

ProgramRunRequest _macosWinedbgRequest({
  required BottleRecord bottle,
  required Map<String, String> environment,
  required String command,
  required String logName,
  List<String> trailingArguments = const <String>[],
}) {
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: 'winedbg',
    runnerKind: 'macosWinedbg',
    executable: _macosWineExecutable(environment),
    arguments: <String>['winedbg', '--command', command, ...trailingArguments],
    environment: _macosWineEnvironment(
      bottle: bottle,
      environment: environment,
    ),
    logPath: _joinPath(bottle.path, <String>['logs', logName]),
    workingDirectory: Option.of(_macosWineBinFolder(environment)),
  );
}

Map<String, String> _macosWineEnvironment({
  required BottleRecord bottle,
  required Map<String, String> environment,
}) {
  final wineEnvironment = <String, String>{
    'WINEPREFIX': bottle.path,
    'WINEDEBUG': 'fixme-all',
    'GST_DEBUG': '1',
    'DYLD_LIBRARY_PATH': _prependPath(
      _joinPath(_macosWineRuntimeRoot(environment), const ['lib']),
      Option.fromNullable(environment['DYLD_LIBRARY_PATH']),
    ),
    ...bottle.runtimeSettings.macosEnvironmentVariables(),
  };
  if (bottle.runtimeSettings.dxvk) {
    final runtimeRoot = _macosWineRuntimeRoot(environment);
    wineEnvironment['WINEDLLPATH'] = [
      _joinPath(runtimeRoot, const ['DXVK', 'x64']),
      _joinPath(runtimeRoot, const ['DXVK', 'x32']),
    ].join(':');
  }

  return Map.unmodifiable(wineEnvironment);
}
