import 'package:fpdart/fpdart.dart';

import '../bottle/bottle_models.dart';
import '../runtime/host_environment.dart';
import '../runtime/wine_runtime_paths.dart';
import '../shared/domain_helpers.dart';
import '../shared/domain_value_objects.dart';
import 'program_argument_support.dart';
import 'program_registry_models.dart';
import 'program_registry_plans.dart';
import 'program_run_environment.dart';
import 'program_run_models.dart';
import 'program_settings_models.dart';

ProgramRunRequest linuxWineRequest({
  required BottleRecord bottle,
  required ProgramPath programPath,
  required ProgramRunArguments wineArguments,
  required HostEnvironment environment,
  required ProgramSettingsRecord programSettings,
}) {
  final hostEnvironment = environment;
  final arguments = <String>[
    ...wineArguments.value,
    ...programSettingsArguments(programSettings),
  ];
  final logging = programSettingsLogging(programSettings);

  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: programPath,
    runnerKind: RunnerKind('wine'),
    executable: ProgramExecutable(linuxWineExecutable(hostEnvironment)),
    arguments: ProgramRunArguments(arguments),
    environment: linuxRuntimeEnvironment(hostEnvironment)
        .merge(programSettingsEnvironment(programSettings))
        .merge(
          _linuxWineEnvironmentWithRuntime(
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
  required BottleCommand command,
  required HostEnvironment environment,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: ProgramPath(command.value),
    runnerKind: RunnerKind('wine'),
    executable: ProgramExecutable(linuxWineExecutable(hostEnvironment)),
    arguments: ProgramRunArguments(wineArgumentsForBottleCommand(command)),
    environment: linuxRuntimeEnvironment(hostEnvironment).merge(
      _linuxWineEnvironmentWithRuntime(
        bottle: bottle,
        environment: environment,
      ),
    ),
    logPath: ProgramLogPath(
      domainJoinPath(bottle.path.value, const ['logs', 'latest.log']),
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
      _linuxWineEnvironmentWithRuntime(
        bottle: bottle,
        environment: environment,
      ),
    ),
    logPath: ProgramLogPath(
      domainJoinPath(bottle.path.value, const ['logs', 'latest.log']),
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
      _linuxWineEnvironmentWithRuntime(
        bottle: bottle,
        environment: environment,
      ),
    ),
    logPath: ProgramLogPath(
      domainJoinPath(bottle.path.value, const ['logs', 'registry.log']),
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
      _linuxWineEnvironmentWithRuntime(
        bottle: bottle,
        environment: environment,
      ),
    ),
    logPath: ProgramLogPath(
      domainJoinPath(bottle.path.value, const ['logs', 'prefix-init.log']),
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
      _linuxWineEnvironmentWithRuntime(
        bottle: bottle,
        environment: environment,
      ),
    ),
    logPath: ProgramLogPath(
      domainJoinPath(bottle.path.value, const ['logs', 'latest.log']),
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
    ).merge(_linuxWinePrefixEnvironment(bottle)),
    logPath: ProgramLogPath(
      domainJoinPath(bottle.path.value, const ['logs', 'wineserver-kill.log']),
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
    ).merge(_linuxWinePrefixEnvironment(bottle)),
    logPath: ProgramLogPath(
      domainJoinPath(bottle.path.value, <String>[
        'logs',
        winedbgCommand.logFileName.value,
      ]),
    ),
  );
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
      domainJoinPath(runtimeRoot, const ['dxvk', 'x64']),
      domainJoinPath(runtimeRoot, const ['dxvk', 'x86']),
    ]);
  }
  if (bottle.runtimeSettings.vkd3dProton) {
    final runtimeRoot = linuxWineRuntimeRoot(hostEnvironment);
    dllPathEntries.addAll([
      domainJoinPath(runtimeRoot, const ['vkd3d-proton', 'x64']),
      domainJoinPath(runtimeRoot, const ['vkd3d-proton', 'x86']),
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

ProgramRunRequest linuxWinetricksCommandRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
  Option<WinetricksVerbId> verb = const Option.none(),
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: ProgramPath(
      verb.match(() => 'winetricks', (value) => value.value),
    ),
    runnerKind: RunnerKind('winetricks'),
    executable: ProgramExecutable(linuxWinetricksExecutable(hostEnvironment)),
    arguments: ProgramRunArguments(
      verb.match(() => const <String>[], (value) => <String>[value.value]),
    ),
    environment: linuxRuntimeEnvironment(hostEnvironment).merge(
      _linuxWineEnvironmentWithRuntime(
        bottle: bottle,
        environment: environment,
      ),
    ),
    logPath: ProgramLogPath(
      domainJoinPath(bottle.path.value, const ['logs', 'latest.log']),
    ),
  );
}
