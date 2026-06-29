import '../../domain/bottle/bottle_models.dart';
import '../../domain/program/program_argument_support.dart';
import '../../domain/program/program_registry_models.dart';
import '../../domain/program/program_registry_plans.dart';
import '../../domain/program/program_run_models.dart';
import '../../domain/program/program_settings_models.dart';
import '../../domain/runtime/host_environment.dart';
import '../../domain/runtime/wine_runtime_paths.dart';
import '../../domain/shared/domain_value_objects.dart';
import '../../io/wine_run_requests.dart';
import '../../shared/common_helpers.dart';

ProgramRunRequest linuxWineRequest({
  required BottleRecord bottle,
  required String programPath,
  required List<String> wineArguments,
  required HostEnvironment environment,
  required ProgramSettingsRecord programSettings,
}) {
  final hostEnvironment = environment;
  final arguments = <String>[
    ...wineArguments,
    ...programSettingsArguments(programSettings),
  ];
  final logging = programSettingsLogging(programSettings);

  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: ProgramPath(programPath),
    runnerKind: RunnerKind('wine'),
    executable: ProgramExecutable(linuxWineExecutable(hostEnvironment)),
    arguments: ProgramRunArguments(arguments),
    environment: linuxRuntimeEnvironment(hostEnvironment)
        .merge(programSettingsEnvironment(programSettings))
        .merge(
          linuxWineEnvironmentWithRuntime(
            bottle: bottle,
            environment: environment,
          ),
        ),
    logPath: ProgramLogPath(
      programSettingsLogPath(bottle: bottle, settings: programSettings),
    ),
    createLogFile: logging.createLogFile,
  );
}

ProgramRunRequest linuxWineCommandRequest({
  required BottleRecord bottle,
  required String command,
  required HostEnvironment environment,
}) {
  final hostEnvironment = environment;
  final bottleCommand = BottleCommand(command);
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: ProgramPath(bottleCommand.value),
    runnerKind: RunnerKind('wine'),
    executable: ProgramExecutable(linuxWineExecutable(hostEnvironment)),
    arguments: ProgramRunArguments(
      wineArgumentsForBottleCommand(bottleCommand),
    ),
    environment: linuxRuntimeEnvironment(hostEnvironment).merge(
      linuxWineEnvironmentWithRuntime(bottle: bottle, environment: environment),
    ),
    logPath: ProgramLogPath(
      joinPath(bottle.path.value, const ['logs', 'latest.log']),
    ),
  );
}

ProgramRunRequest linuxRegistryUpdateRequest({
  required BottleRecord bottle,
  required RegistryValueUpdate update,
  required HostEnvironment environment,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: ProgramPath('reg'),
    runnerKind: RunnerKind('wineRegistry'),
    executable: ProgramExecutable(linuxWineExecutable(hostEnvironment)),
    arguments: ProgramRunArguments(registryUpdateArguments(update)),
    environment: linuxRuntimeEnvironment(hostEnvironment).merge(
      linuxWineEnvironmentWithRuntime(bottle: bottle, environment: environment),
    ),
    logPath: ProgramLogPath(
      joinPath(bottle.path.value, const ['logs', 'latest.log']),
    ),
  );
}

ProgramRunRequest linuxRegistryQueryRequest({
  required BottleRecord bottle,
  required RegistryValueQuery query,
  required HostEnvironment environment,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: ProgramPath('reg'),
    runnerKind: RunnerKind('wineRegistryQuery'),
    executable: ProgramExecutable(linuxWineExecutable(hostEnvironment)),
    arguments: ProgramRunArguments(registryQueryArguments(query)),
    environment: linuxRuntimeEnvironment(hostEnvironment).merge(
      linuxWineEnvironmentWithRuntime(bottle: bottle, environment: environment),
    ),
    logPath: ProgramLogPath(
      joinPath(bottle.path.value, const ['logs', 'registry.log']),
    ),
  );
}

ProgramRunRequest linuxWinebootRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: ProgramPath('wineboot'),
    runnerKind: RunnerKind('wineboot'),
    executable: ProgramExecutable(linuxWinebootExecutable(hostEnvironment)),
    arguments: ProgramRunArguments(const <String>['--init']),
    environment: linuxRuntimeEnvironment(hostEnvironment).merge(
      linuxWineEnvironmentWithRuntime(bottle: bottle, environment: environment),
    ),
    logPath: ProgramLogPath(
      joinPath(bottle.path.value, const ['logs', 'prefix-init.log']),
    ),
  );
}

ProgramRunRequest linuxWinebootRestartRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: ProgramPath('wineboot'),
    runnerKind: RunnerKind('wineboot'),
    executable: ProgramExecutable(linuxWinebootExecutable(hostEnvironment)),
    arguments: ProgramRunArguments(const <String>['--restart']),
    environment: linuxRuntimeEnvironment(hostEnvironment).merge(
      linuxWineEnvironmentWithRuntime(bottle: bottle, environment: environment),
    ),
    logPath: ProgramLogPath(
      joinPath(bottle.path.value, const ['logs', 'latest.log']),
    ),
  );
}

ProgramRunRequest linuxWineserverKillRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: ProgramPath('wineserver'),
    runnerKind: RunnerKind('wineserver'),
    executable: ProgramExecutable(linuxWineserverExecutable(hostEnvironment)),
    arguments: ProgramRunArguments(const <String>['-k']),
    environment: linuxRuntimeEnvironment(
      hostEnvironment,
    ).merge(linuxWinePrefixEnvironment(bottle)),
    logPath: ProgramLogPath(
      joinPath(bottle.path.value, const ['logs', 'wineserver-kill.log']),
    ),
  );
}

ProgramRunRequest linuxWinedbgRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
  required WinedbgCommandPlan winedbgCommand,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: ProgramPath('winedbg'),
    runnerKind: RunnerKind('winedbg'),
    executable: ProgramExecutable(linuxWinedbgExecutable(hostEnvironment)),
    arguments: ProgramRunArguments(<String>[
      '--command',
      winedbgCommand.command.value,
      ...winedbgCommand.trailingArguments.value,
    ]),
    environment: linuxRuntimeEnvironment(
      hostEnvironment,
    ).merge(linuxWinePrefixEnvironment(bottle)),
    logPath: ProgramLogPath(
      joinPath(bottle.path.value, <String>[
        'logs',
        winedbgCommand.logFileName.value,
      ]),
    ),
  );
}
