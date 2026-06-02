part of '../../../konyak_cli.dart';

ProgramRunRequest _linuxWineRequest({
  required BottleRecord bottle,
  required String programPath,
  required Map<String, String> environment,
  required ProgramSettingsRecord programSettings,
}) {
  final hostEnvironment = HostEnvironment(environment);
  final arguments = <String>[
    ..._wineArgumentsForProgramPath(programPath),
    ..._programSettingsArguments(programSettings),
  ];

  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: programPath,
    runnerKind: 'wine',
    executable: _linuxWineExecutable(hostEnvironment),
    arguments: arguments,
    environment: ProgramRunEnvironment(<String, String>{
      ..._linuxRuntimeEnvironment(hostEnvironment),
      ..._programSettingsEnvironment(programSettings),
      ..._linuxWineEnvironmentWithRuntime(
        bottle: bottle,
        environment: environment,
      ),
    }),
    logPath: _joinPath(bottle.path, const ['logs', 'latest.log']),
  );
}

ProgramRunRequest _linuxWineCommandRequest({
  required BottleRecord bottle,
  required String command,
  required Map<String, String> environment,
}) {
  final hostEnvironment = HostEnvironment(environment);
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: command,
    runnerKind: 'wine',
    executable: _linuxWineExecutable(hostEnvironment),
    arguments: <String>[command],
    environment: ProgramRunEnvironment(<String, String>{
      ..._linuxRuntimeEnvironment(hostEnvironment),
      ..._linuxWineEnvironmentWithRuntime(
        bottle: bottle,
        environment: environment,
      ),
    }),
    logPath: _joinPath(bottle.path, const ['logs', 'latest.log']),
  );
}

ProgramRunRequest _linuxRegistryUpdateRequest({
  required BottleRecord bottle,
  required _RegistryValueUpdate update,
  required Map<String, String> environment,
}) {
  final hostEnvironment = HostEnvironment(environment);
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: 'reg',
    runnerKind: 'wineRegistry',
    executable: _linuxWineExecutable(hostEnvironment),
    arguments: _registryUpdateArguments(update),
    environment: ProgramRunEnvironment(<String, String>{
      ..._linuxRuntimeEnvironment(hostEnvironment),
      ..._linuxWineEnvironmentWithRuntime(
        bottle: bottle,
        environment: environment,
      ),
    }),
    logPath: _joinPath(bottle.path, const ['logs', 'latest.log']),
  );
}

ProgramRunRequest _linuxRegistryQueryRequest({
  required BottleRecord bottle,
  required _RegistryValueQuery query,
  required Map<String, String> environment,
}) {
  final hostEnvironment = HostEnvironment(environment);
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: 'reg',
    runnerKind: 'wineRegistryQuery',
    executable: _linuxWineExecutable(hostEnvironment),
    arguments: _registryQueryArguments(query),
    environment: ProgramRunEnvironment(<String, String>{
      ..._linuxRuntimeEnvironment(hostEnvironment),
      ..._linuxWineEnvironmentWithRuntime(
        bottle: bottle,
        environment: environment,
      ),
    }),
    logPath: _joinPath(bottle.path, const ['logs', 'registry.log']),
  );
}

ProgramRunRequest _linuxWinebootRequest({
  required BottleRecord bottle,
  required Map<String, String> environment,
}) {
  final hostEnvironment = HostEnvironment(environment);
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: 'wineboot',
    runnerKind: 'wineboot',
    executable: _linuxWinebootExecutable(hostEnvironment),
    arguments: const <String>['--init'],
    environment: ProgramRunEnvironment(<String, String>{
      ..._linuxRuntimeEnvironment(hostEnvironment),
      ..._linuxWineEnvironmentWithRuntime(
        bottle: bottle,
        environment: environment,
      ),
    }),
    logPath: _joinPath(bottle.path, const ['logs', 'prefix-init.log']),
  );
}

ProgramRunRequest _linuxWineserverKillRequest({
  required BottleRecord bottle,
  required Map<String, String> environment,
}) {
  final hostEnvironment = HostEnvironment(environment);
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: 'wineserver',
    runnerKind: 'wineserver',
    executable: _linuxWineserverExecutable(hostEnvironment),
    arguments: const <String>['-k'],
    environment: ProgramRunEnvironment(<String, String>{
      ..._linuxRuntimeEnvironment(hostEnvironment),
      ..._linuxWinePrefixEnvironment(bottle),
    }),
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
  final hostEnvironment = HostEnvironment(environment);
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: 'winedbg',
    runnerKind: 'winedbg',
    executable: _linuxWinedbgExecutable(hostEnvironment),
    arguments: <String>['--command', command, ...trailingArguments],
    environment: ProgramRunEnvironment(<String, String>{
      ..._linuxRuntimeEnvironment(hostEnvironment),
      ..._linuxWinePrefixEnvironment(bottle),
    }),
    logPath: _joinPath(bottle.path, <String>['logs', logName]),
  );
}
