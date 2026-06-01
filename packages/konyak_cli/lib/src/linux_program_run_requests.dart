part of '../konyak_cli.dart';

ProgramRunRequest _linuxWineRequest({
  required BottleRecord bottle,
  required String programPath,
  required Map<String, String> environment,
  required ProgramSettingsRecord programSettings,
}) {
  final arguments = <String>[
    ..._wineArgumentsForProgramPath(programPath),
    ..._programSettingsArguments(programSettings),
  ];

  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: programPath,
    runnerKind: 'wine',
    executable: _linuxWineExecutable(environment),
    arguments: arguments,
    environment: <String, String>{
      ..._linuxRuntimeEnvironment(environment),
      ..._programSettingsEnvironment(programSettings),
      ..._linuxWineEnvironmentWithRuntime(
        bottle: bottle,
        environment: environment,
      ),
    },
    logPath: _joinPath(bottle.path, const ['logs', 'latest.log']),
  );
}

ProgramRunRequest _linuxWineCommandRequest({
  required BottleRecord bottle,
  required String command,
  required Map<String, String> environment,
}) {
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: command,
    runnerKind: 'wine',
    executable: _linuxWineExecutable(environment),
    arguments: <String>[command],
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

ProgramRunRequest _linuxRegistryUpdateRequest({
  required BottleRecord bottle,
  required _RegistryValueUpdate update,
  required Map<String, String> environment,
}) {
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: 'reg',
    runnerKind: 'wineRegistry',
    executable: _linuxWineExecutable(environment),
    arguments: _registryUpdateArguments(update),
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

ProgramRunRequest _linuxRegistryQueryRequest({
  required BottleRecord bottle,
  required _RegistryValueQuery query,
  required Map<String, String> environment,
}) {
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: 'reg',
    runnerKind: 'wineRegistryQuery',
    executable: _linuxWineExecutable(environment),
    arguments: _registryQueryArguments(query),
    environment: <String, String>{
      ..._linuxRuntimeEnvironment(environment),
      ..._linuxWineEnvironmentWithRuntime(
        bottle: bottle,
        environment: environment,
      ),
    },
    logPath: _joinPath(bottle.path, const ['logs', 'registry.log']),
  );
}

ProgramRunRequest _linuxWinebootRequest({
  required BottleRecord bottle,
  required Map<String, String> environment,
}) {
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: 'wineboot',
    runnerKind: 'wineboot',
    executable: _linuxWinebootExecutable(environment),
    arguments: const <String>['--init'],
    environment: <String, String>{
      ..._linuxRuntimeEnvironment(environment),
      ..._linuxWineEnvironmentWithRuntime(
        bottle: bottle,
        environment: environment,
      ),
    },
    logPath: _joinPath(bottle.path, const ['logs', 'prefix-init.log']),
  );
}

ProgramRunRequest _linuxWineserverKillRequest({
  required BottleRecord bottle,
  required Map<String, String> environment,
}) {
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: 'wineserver',
    runnerKind: 'wineserver',
    executable: _linuxWineserverExecutable(environment),
    arguments: const <String>['-k'],
    environment: <String, String>{
      ..._linuxRuntimeEnvironment(environment),
      ..._linuxWinePrefixEnvironment(bottle),
    },
    logPath: _joinPath(bottle.path, const ['logs', 'wineserver-kill.log']),
  );
}

ProgramRunRequest _linuxWinedbgRequest({
  required BottleRecord bottle,
  required Map<String, String> environment,
  required String command,
  required String logName,
  List<String> trailingArguments = const <String>[],
}) {
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: 'winedbg',
    runnerKind: 'winedbg',
    executable: _linuxWinedbgExecutable(environment),
    arguments: <String>['--command', command, ...trailingArguments],
    environment: <String, String>{
      ..._linuxRuntimeEnvironment(environment),
      ..._linuxWinePrefixEnvironment(bottle),
    },
    logPath: _joinPath(bottle.path, <String>['logs', logName]),
  );
}
