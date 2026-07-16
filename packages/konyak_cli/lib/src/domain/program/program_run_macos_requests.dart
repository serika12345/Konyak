import 'package:fpdart/fpdart.dart';

import '../bottle/bottle_models.dart';
import '../runtime/host_environment.dart';
import '../runtime/runtime_platform_support.dart';
import '../runtime/wine_runtime_paths.dart';
import '../shared/domain_helpers.dart';
import '../shared/domain_value_objects.dart';
import 'program_argument_support.dart';
import 'program_registry_models.dart';
import 'program_registry_plans.dart';
import 'program_run_environment.dart';
import 'program_run_models.dart';
import 'program_settings_models.dart';

const _gptkD3DMetalComponentLibRelativePath = <String>[
  'components',
  'gptk-d3dmetal',
  'lib',
];

ProgramRunRequest macosWineRequest({
  required BottleRecord bottle,
  required ProgramPath programPath,
  required ProgramPath executableHostPath,
  required ProgramRunArguments wineArguments,
  required HostEnvironment environment,
  required Option<MacosMajorVersion> macosMajorVersion,
  required ProgramSettingsRecord programSettings,
  ProgramRunEnvironment compatibilityEnvironment =
      const ProgramRunEnvironment.empty(),
}) {
  final hostEnvironment = environment;
  final logging = programSettingsLogging(programSettings);
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: programPath,
    runnerKind: RunnerKind.macosWine,
    executable: ProgramExecutable(macosWineExecutable(hostEnvironment)),
    arguments: ProgramRunArguments(<String>[
      ...wineArguments.value,
      ...programSettingsArguments(programSettings).value,
    ]),
    environment: ProgramRunEnvironment(<String, String>{
      ...macosWineEnvironmentForRequests(
        bottle: bottle,
        environment: environment,
        macosMajorVersion: macosMajorVersion,
      ).toMap(),
      ...programSettingsEnvironment(programSettings).toMap(),
      ...compatibilityEnvironment.toMap(),
      'WINEPREFIX': bottle.path.value,
    }),
    logPath: programSettingsLogPath(bottle: bottle, settings: programSettings),
    createLogFile: logging.createLogFile,
    workingDirectory: resolveProgramWorkingDirectory(
      bottle: bottle,
      executableHostPath: executableHostPath,
      setting: programSettings.workingDirectory,
    ),
  );
}

ProgramRunRequest macosWinebootRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
  required Option<MacosMajorVersion> macosMajorVersion,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: ProgramPath('wineboot'),
    runnerKind: RunnerKind.macosWine,
    executable: ProgramExecutable(macosWineExecutable(hostEnvironment)),
    arguments: ProgramRunArguments(const <String>['wineboot', '--init']),
    environment: _macosPrefixInitializationEnvironment(
      bottle: bottle,
      environment: environment,
      macosMajorVersion: macosMajorVersion,
    ),
    logPath: ProgramLogPath(
      domainJoinPath(bottle.path.value, const ['logs', 'prefix-init.log']),
    ),
    workingDirectory: Option.of(
      ProgramWorkingDirectoryPath(macosWineBinFolder(hostEnvironment)),
    ),
  );
}

ProgramRunRequest macosWinebootRestartRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
  required Option<MacosMajorVersion> macosMajorVersion,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: ProgramPath('wineboot'),
    runnerKind: RunnerKind.macosWine,
    executable: ProgramExecutable(macosWineExecutable(hostEnvironment)),
    arguments: ProgramRunArguments(const <String>['wineboot', '--restart']),
    environment: macosWineEnvironmentForRequests(
      bottle: bottle,
      environment: environment,
      macosMajorVersion: macosMajorVersion,
    ),
    logPath: ProgramLogPath(
      domainJoinPath(bottle.path.value, const ['logs', 'latest.log']),
    ),
    workingDirectory: Option.of(
      ProgramWorkingDirectoryPath(macosWineBinFolder(hostEnvironment)),
    ),
  );
}

ProgramRunRequest macosWineMonoInstallRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
  required Option<MacosMajorVersion> macosMajorVersion,
}) {
  final hostEnvironment = environment;
  final runtimeRoot = macosWineRuntimeRoot(hostEnvironment);
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: ProgramPath('wine-mono'),
    runnerKind: RunnerKind.macosWine,
    executable: ProgramExecutable(macosWineExecutable(hostEnvironment)),
    arguments: ProgramRunArguments(<String>[
      'msiexec',
      '/i',
      _macosWineWindowsPath(_macosWineMonoMsiPath(runtimeRoot)),
      '/qn',
      '/norestart',
    ]),
    environment: _macosPrefixInitializationEnvironment(
      bottle: bottle,
      environment: environment,
      macosMajorVersion: macosMajorVersion,
    ),
    logPath: ProgramLogPath(
      domainJoinPath(bottle.path.value, const [
        'logs',
        'wine-mono-install.log',
      ]),
    ),
    workingDirectory: Option.of(
      ProgramWorkingDirectoryPath(macosWineBinFolder(hostEnvironment)),
    ),
  );
}

ProgramRunRequest macosWineserverKillRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
  required Option<MacosMajorVersion> macosMajorVersion,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: ProgramPath('wineserver'),
    runnerKind: RunnerKind.macosWineserver,
    executable: ProgramExecutable(macosWineserverExecutable(hostEnvironment)),
    arguments: ProgramRunArguments(const <String>['-k']),
    environment: macosWineEnvironmentForRequests(
      bottle: bottle,
      environment: environment,
      macosMajorVersion: macosMajorVersion,
    ),
    logPath: ProgramLogPath(
      domainJoinPath(bottle.path.value, const ['logs', 'wineserver-kill.log']),
    ),
    workingDirectory: Option.of(
      ProgramWorkingDirectoryPath(macosWineBinFolder(hostEnvironment)),
    ),
  );
}

ProgramRunRequest macosWinedbgRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
  required Option<MacosMajorVersion> macosMajorVersion,
  required WinedbgCommandPlan winedbgCommand,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: ProgramPath('winedbg'),
    runnerKind: RunnerKind.macosWinedbg,
    executable: ProgramExecutable(macosWineExecutable(hostEnvironment)),
    arguments: ProgramRunArguments(<String>[
      'winedbg',
      '--command',
      winedbgCommand.command.value,
      ...winedbgCommand.trailingArguments.value,
    ]),
    environment: macosWineEnvironmentForRequests(
      bottle: bottle,
      environment: environment,
      macosMajorVersion: macosMajorVersion,
    ),
    logPath: ProgramLogPath(
      domainJoinPath(bottle.path.value, <String>[
        'logs',
        winedbgCommand.logFileName.value,
      ]),
    ),
    workingDirectory: Option.of(
      ProgramWorkingDirectoryPath(macosWineBinFolder(hostEnvironment)),
    ),
  );
}

ProgramRunEnvironment macosWineEnvironmentForRequests({
  required BottleRecord bottle,
  required HostEnvironment environment,
  required Option<MacosMajorVersion> macosMajorVersion,
}) {
  final hostEnvironment = environment;
  final runtimeRoot = macosWineRuntimeRoot(hostEnvironment);
  final d3dMetalSelected = bottle.runtimeSettings.dxrEnabled;
  final selectedBackendWindowsPaths = <String>[
    if (d3dMetalSelected)
      _macosD3DMetalWindowsPath(runtimeRoot)
    else if (bottle.runtimeSettings.dxmt) ...[
      domainJoinPath(runtimeRoot, const ['lib', 'dxmt', 'x86_64-windows']),
      domainJoinPath(runtimeRoot, const ['lib', 'dxmt', 'i386-windows']),
    ] else if (bottle.runtimeSettings.dxvk) ...[
      domainJoinPath(runtimeRoot, const ['lib', 'dxvk', 'x86_64-windows']),
      domainJoinPath(runtimeRoot, const ['lib', 'dxvk', 'i386-windows']),
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
    'WINEPREFIX': bottle.path.value,
    'WINEDEBUG': 'fixme-all',
    'GST_DEBUG': '1',
    'MVK_CONFIG_LOG_LEVEL': '0',
    'GST_PLUGIN_SYSTEM_PATH': _macosGstreamerPluginPath(runtimeRoot),
    'GST_PLUGIN_SCANNER': _macosGstreamerPluginScanner(runtimeRoot),
    'GST_REGISTRY': _macosGstreamerRegistryPath(bottle.path.value),
    'WINEDATADIR': _macosWineDataDir(runtimeRoot),
    'WINEDLLPATH': wineDllPathEntries.join(':'),
    'WINEPATH': _macosWineWindowsSearchPath(wineSearchPathEntries),
    'WINELOADER': macosWineExecutable(hostEnvironment),
    'WINESERVER': macosWineserverExecutable(hostEnvironment),
    'DYLD_LIBRARY_PATH': _prependPaths(<String>[
      if (d3dMetalSelected) _macosD3DMetalExternalPath(runtimeRoot),
      if (d3dMetalSelected) _macosD3DMetalUnixPath(runtimeRoot),
      if (bottle.runtimeSettings.dxmt && !d3dMetalSelected)
        _macosDxmtUnixPath(runtimeRoot),
      domainJoinPath(runtimeRoot, const ['lib']),
    ], environment['DYLD_LIBRARY_PATH']),
    if (d3dMetalSelected)
      'DYLD_FRAMEWORK_PATH': _prependPaths(<String>[
        _macosD3DMetalExternalPath(runtimeRoot),
      ], environment['DYLD_FRAMEWORK_PATH']),
    if (d3dMetalSelected)
      'CX_APPLEGPTK_LIBD3DSHARED_PATH': domainJoinPath(runtimeRoot, const [
        ..._gptkD3DMetalComponentLibRelativePath,
        'external',
        'libd3dshared.dylib',
      ]),
    ...bottle.runtimeSettings
        .macosEnvironment(
          enableD3DMetalDlssMetalFx: _supportsD3DMetalDlssMetalFx(
            macosMajorVersion,
          ),
        )
        .toMap(),
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
  required Option<MacosMajorVersion> macosMajorVersion,
}) {
  return macosWineEnvironmentForRequests(
    bottle: bottle,
    environment: environment,
    macosMajorVersion: macosMajorVersion,
  );
}

bool _supportsD3DMetalDlssMetalFx(Option<MacosMajorVersion> macosMajorVersion) {
  return macosMajorVersion.match(() => false, (version) => version.value >= 16);
}

String _macosWineDataDir(String runtimeRoot) {
  return domainJoinPath(runtimeRoot, const ['share', 'wine']);
}

String _macosWineMonoMsiPath(String runtimeRoot) {
  return domainJoinPath(runtimeRoot, macosWineMonoComponentPaths.single);
}

String _macosD3DMetalExternalPath(String runtimeRoot) {
  return domainJoinPath(runtimeRoot, const [
    ..._gptkD3DMetalComponentLibRelativePath,
    'external',
  ]);
}

String _macosGstreamerPluginPath(String runtimeRoot) {
  return domainJoinPath(runtimeRoot, const ['lib', 'gstreamer-1.0']);
}

String _macosGstreamerPluginScanner(String runtimeRoot) {
  return domainJoinPath(runtimeRoot, const [
    'libexec',
    'gstreamer-1.0',
    'gst-plugin-scanner',
  ]);
}

String _macosGstreamerRegistryPath(String bottlePath) {
  return domainJoinPath(bottlePath, const [
    'gstreamer-1.0-registry.x86_64.bin',
  ]);
}

String _macosD3DMetalWindowsPath(String runtimeRoot) {
  return domainJoinPath(runtimeRoot, const [
    ..._gptkD3DMetalComponentLibRelativePath,
    'wine',
    'x86_64-windows',
  ]);
}

List<String> _macosWineWindowsDllPaths(String runtimeRoot) {
  return <String>[
    domainJoinPath(runtimeRoot, const ['lib', 'wine', 'x86_64-windows']),
    domainJoinPath(runtimeRoot, const ['lib', 'wine', 'i386-windows']),
    domainJoinPath(runtimeRoot, const ['lib', 'wine']),
  ];
}

List<String> _macosWineWindowsSearchPaths(String runtimeRoot) {
  return <String>[
    domainJoinPath(runtimeRoot, const ['lib', 'wine', 'x86_64-windows']),
    domainJoinPath(runtimeRoot, const ['lib', 'wine', 'i386-windows']),
  ];
}

String _macosD3DMetalUnixPath(String runtimeRoot) {
  return domainJoinPath(runtimeRoot, const [
    ..._gptkD3DMetalComponentLibRelativePath,
    'wine',
    'x86_64-unix',
  ]);
}

String _macosDxmtUnixPath(String runtimeRoot) {
  return domainJoinPath(runtimeRoot, const ['lib', 'dxmt', 'x86_64-unix']);
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

ProgramRunRequest macosWineCommandRequest({
  required BottleRecord bottle,
  required BottleCommand command,
  required HostEnvironment environment,
  required Option<MacosMajorVersion> macosMajorVersion,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: ProgramPath(command.value),
    runnerKind: RunnerKind.macosWine,
    executable: ProgramExecutable(macosWineExecutable(hostEnvironment)),
    arguments: wineArgumentsForBottleCommand(command),
    environment: macosWineEnvironmentForRequests(
      bottle: bottle,
      environment: environment,
      macosMajorVersion: macosMajorVersion,
    ),
    logPath: ProgramLogPath(
      domainJoinPath(bottle.path.value, const ['logs', 'latest.log']),
    ),
    workingDirectory: Option.of(
      ProgramWorkingDirectoryPath(macosWineBinFolder(hostEnvironment)),
    ),
  );
}

ProgramRunRequest macosRegistryUpdateRequest({
  required BottleRecord bottle,
  required RegistryValueUpdate update,
  required HostEnvironment environment,
  required Option<MacosMajorVersion> macosMajorVersion,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: ProgramPath('reg'),
    runnerKind: RunnerKind.macosWineRegistry,
    executable: ProgramExecutable(macosWineExecutable(hostEnvironment)),
    arguments: registryUpdateArguments(update),
    environment: macosWineEnvironmentForRequests(
      bottle: bottle,
      environment: environment,
      macosMajorVersion: macosMajorVersion,
    ),
    logPath: ProgramLogPath(
      domainJoinPath(bottle.path.value, const ['logs', 'latest.log']),
    ),
    workingDirectory: Option.of(
      ProgramWorkingDirectoryPath(macosWineBinFolder(hostEnvironment)),
    ),
  );
}

ProgramRunRequest macosRegistryQueryRequest({
  required BottleRecord bottle,
  required RegistryValueQuery query,
  required HostEnvironment environment,
  required Option<MacosMajorVersion> macosMajorVersion,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: ProgramPath('reg'),
    runnerKind: RunnerKind.macosWineRegistryQuery,
    executable: ProgramExecutable(macosWineExecutable(hostEnvironment)),
    arguments: registryQueryArguments(query),
    environment: macosWineEnvironmentForRequests(
      bottle: bottle,
      environment: environment,
      macosMajorVersion: macosMajorVersion,
    ),
    logPath: ProgramLogPath(
      domainJoinPath(bottle.path.value, const ['logs', 'registry.log']),
    ),
    workingDirectory: Option.of(
      ProgramWorkingDirectoryPath(macosWineBinFolder(hostEnvironment)),
    ),
  );
}

ProgramRunRequest macosWinetricksCommandRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
  required Option<MacosMajorVersion> macosMajorVersion,
  required Option<WinetricksVerbId> verb,
}) {
  final hostEnvironment = environment;
  final runtimeRoot = macosWineRuntimeRoot(hostEnvironment);
  final runtimeBin = macosWineBinFolder(hostEnvironment);

  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: ProgramPath(
      verb.match(() => 'winetricks', (value) => value.value),
    ),
    runnerKind: RunnerKind.macosWinetricks,
    executable: ProgramExecutable(macosWinetricksExecutable(hostEnvironment)),
    arguments: ProgramRunArguments(
      verb.match(() => const <String>[], (value) => <String>[value.value]),
    ),
    environment:
        macosWineEnvironmentForRequests(
              bottle: bottle,
              environment: environment,
              macosMajorVersion: macosMajorVersion,
            )
            .add(
              ProgramEnvironmentVariableName('WINE'),
              ProgramEnvironmentVariableValue(
                macosWineExecutable(hostEnvironment),
              ),
            )
            .add(
              ProgramEnvironmentVariableName('PATH'),
              ProgramEnvironmentVariableValue(
                _prependPath(runtimeBin, environment['PATH']),
              ),
            ),
    logPath: ProgramLogPath(
      domainJoinPath(bottle.path.value, const ['logs', 'latest.log']),
    ),
    workingDirectory: Option.of(ProgramWorkingDirectoryPath(runtimeRoot)),
  );
}

String _prependPath(String path, Option<String> existingPath) {
  return existingPath.match(() => path, (existingPath) {
    if (existingPath.trim().isEmpty) {
      return path;
    }

    return '$path:$existingPath';
  });
}
