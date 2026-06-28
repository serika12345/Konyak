import '../../domain/bottle/bottle_models.dart';
import '../../domain/program/program_argument_support.dart';
import '../../domain/program/program_registry_models.dart';
import '../../domain/program/program_registry_plans.dart';
import '../../domain/program/program_run_models.dart';
import '../../domain/program/program_settings_models.dart';
import '../../domain/runtime/host_environment.dart';
import '../../domain/runtime/wine_runtime_paths.dart';
import '../../io/wine_run_requests.dart';
import '../../shared/common_helpers.dart';

ProgramRunRequest linuxWineRequest({
  required BottleRecord bottle,
  required String programPath,
  required HostEnvironment environment,
  required ProgramSettingsRecord programSettings,
}) {
  final hostEnvironment = environment;
  final arguments = <String>[
    ...wineArgumentsForProgramPath(programPath),
    ...programSettingsArguments(programSettings),
  ];
  final logging = programSettingsLogging(programSettings);

  return ProgramRunRequest(
    bottleId: bottle.id.value,
    programPath: programPath,
    runnerKind: 'wine',
    executable: linuxWineExecutable(hostEnvironment),
    arguments: arguments,
    environment: linuxRuntimeEnvironment(hostEnvironment)
        .merge(programSettingsEnvironment(programSettings))
        .merge(
          linuxWineEnvironmentWithRuntime(
            bottle: bottle,
            environment: environment,
          ),
        ),
    logPath: programSettingsLogPath(bottle: bottle, settings: programSettings),
    createLogFile: logging.createLogFile,
  );
}

ProgramRunRequest linuxWineCommandRequest({
  required BottleRecord bottle,
  required String command,
  required HostEnvironment environment,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id.value,
    programPath: command,
    runnerKind: 'wine',
    executable: linuxWineExecutable(hostEnvironment),
    arguments: wineArgumentsForBottleCommand(command),
    environment: linuxRuntimeEnvironment(hostEnvironment).merge(
      linuxWineEnvironmentWithRuntime(bottle: bottle, environment: environment),
    ),
    logPath: joinPath(bottle.path.value, const ['logs', 'latest.log']),
  );
}

ProgramRunRequest linuxRegistryUpdateRequest({
  required BottleRecord bottle,
  required RegistryValueUpdate update,
  required HostEnvironment environment,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id.value,
    programPath: 'reg',
    runnerKind: 'wineRegistry',
    executable: linuxWineExecutable(hostEnvironment),
    arguments: registryUpdateArguments(update),
    environment: linuxRuntimeEnvironment(hostEnvironment).merge(
      linuxWineEnvironmentWithRuntime(bottle: bottle, environment: environment),
    ),
    logPath: joinPath(bottle.path.value, const ['logs', 'latest.log']),
  );
}

ProgramRunRequest linuxRegistryQueryRequest({
  required BottleRecord bottle,
  required RegistryValueQuery query,
  required HostEnvironment environment,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id.value,
    programPath: 'reg',
    runnerKind: 'wineRegistryQuery',
    executable: linuxWineExecutable(hostEnvironment),
    arguments: registryQueryArguments(query),
    environment: linuxRuntimeEnvironment(hostEnvironment).merge(
      linuxWineEnvironmentWithRuntime(bottle: bottle, environment: environment),
    ),
    logPath: joinPath(bottle.path.value, const ['logs', 'registry.log']),
  );
}

ProgramRunRequest linuxWinebootRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id.value,
    programPath: 'wineboot',
    runnerKind: 'wineboot',
    executable: linuxWinebootExecutable(hostEnvironment),
    arguments: const <String>['--init'],
    environment: linuxRuntimeEnvironment(hostEnvironment).merge(
      linuxWineEnvironmentWithRuntime(bottle: bottle, environment: environment),
    ),
    logPath: joinPath(bottle.path.value, const ['logs', 'prefix-init.log']),
  );
}

ProgramRunRequest linuxWinebootRestartRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id.value,
    programPath: 'wineboot',
    runnerKind: 'wineboot',
    executable: linuxWinebootExecutable(hostEnvironment),
    arguments: const <String>['--restart'],
    environment: linuxRuntimeEnvironment(hostEnvironment).merge(
      linuxWineEnvironmentWithRuntime(bottle: bottle, environment: environment),
    ),
    logPath: joinPath(bottle.path.value, const ['logs', 'latest.log']),
  );
}

ProgramRunRequest linuxWineserverKillRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id.value,
    programPath: 'wineserver',
    runnerKind: 'wineserver',
    executable: linuxWineserverExecutable(hostEnvironment),
    arguments: const <String>['-k'],
    environment: linuxRuntimeEnvironment(
      hostEnvironment,
    ).merge(linuxWinePrefixEnvironment(bottle)),
    logPath: joinPath(bottle.path.value, const ['logs', 'wineserver-kill.log']),
  );
}

ProgramRunRequest linuxWinedbgRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
  required String command,
  required String logName,
  List<String> trailingArguments = const <String>[],
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id.value,
    programPath: 'winedbg',
    runnerKind: 'winedbg',
    executable: linuxWinedbgExecutable(hostEnvironment),
    arguments: <String>['--command', command, ...trailingArguments],
    environment: linuxRuntimeEnvironment(
      hostEnvironment,
    ).merge(linuxWinePrefixEnvironment(bottle)),
    logPath: joinPath(bottle.path.value, <String>['logs', logName]),
  );
}
