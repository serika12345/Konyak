import 'package:fpdart/fpdart.dart';

import '../../domain/bottle/bottle_models.dart';
import '../../domain/program/program_argument_support.dart';
import '../../domain/program/program_run_environment.dart';
import '../../domain/program/program_run_models.dart';
import '../../domain/program/program_settings_models.dart';
import '../../domain/runtime/host_environment.dart';
import '../../domain/runtime/runtime_platform_support.dart';
import '../../domain/runtime/wine_runtime_paths.dart';
import '../../domain/shared/domain_value_objects.dart';
import '../../io/gptk_wine_installation.dart';
import '../../shared/common_helpers.dart';

ProgramRunRequest macosWineRequest({
  required BottleRecord bottle,
  required ProgramPath programPath,
  required HostEnvironment environment,
  required Option<int> macosMajorVersion,
  required ProgramSettingsRecord programSettings,
}) {
  final hostEnvironment = environment;
  final logging = programSettingsLogging(programSettings);
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: programPath,
    runnerKind: RunnerKind('macosWine'),
    executable: ProgramExecutable(macosWineExecutable(hostEnvironment)),
    arguments: ProgramRunArguments(<String>[
      'start',
      '/unix',
      programPath.value,
      ...programSettingsArguments(programSettings).value,
    ]),
    environment: ProgramRunEnvironment(<String, String>{
      ...macosWineEnvironment(
        bottle: bottle,
        environment: environment,
        macosMajorVersion: macosMajorVersion,
      ).toMap(),
      ...programSettingsEnvironment(programSettings).toMap(),
      'WINEPREFIX': bottle.path.value,
    }),
    logPath: programSettingsLogPath(bottle: bottle, settings: programSettings),
    createLogFile: logging.createLogFile,
    workingDirectory: Option.of(
      ProgramWorkingDirectoryPath(macosWineBinFolder(hostEnvironment)),
    ),
  );
}

ProgramRunRequest macosWinebootRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
  required Option<int> macosMajorVersion,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: ProgramPath('wineboot'),
    runnerKind: RunnerKind('macosWine'),
    executable: ProgramExecutable(macosWineExecutable(hostEnvironment)),
    arguments: ProgramRunArguments(const <String>['wineboot', '--init']),
    environment: macosPrefixInitializationEnvironment(
      bottle: bottle,
      environment: environment,
      macosMajorVersion: macosMajorVersion,
    ),
    logPath: ProgramLogPath(
      joinPath(bottle.path.value, const ['logs', 'prefix-init.log']),
    ),
    workingDirectory: Option.of(
      ProgramWorkingDirectoryPath(macosWineBinFolder(hostEnvironment)),
    ),
  );
}

ProgramRunRequest macosWinebootRestartRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
  required Option<int> macosMajorVersion,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: ProgramPath('wineboot'),
    runnerKind: RunnerKind('macosWine'),
    executable: ProgramExecutable(macosWineExecutable(hostEnvironment)),
    arguments: ProgramRunArguments(const <String>['wineboot', '--restart']),
    environment: macosWineEnvironment(
      bottle: bottle,
      environment: environment,
      macosMajorVersion: macosMajorVersion,
    ),
    logPath: ProgramLogPath(
      joinPath(bottle.path.value, const ['logs', 'latest.log']),
    ),
    workingDirectory: Option.of(
      ProgramWorkingDirectoryPath(macosWineBinFolder(hostEnvironment)),
    ),
  );
}

ProgramRunRequest macosWineMonoInstallRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
  required Option<int> macosMajorVersion,
}) {
  final hostEnvironment = environment;
  final runtimeRoot = macosWineRuntimeRoot(hostEnvironment);
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: ProgramPath('wine-mono'),
    runnerKind: RunnerKind('macosWine'),
    executable: ProgramExecutable(macosWineExecutable(hostEnvironment)),
    arguments: ProgramRunArguments(<String>[
      'msiexec',
      '/i',
      macosWineWindowsPath(macosWineMonoMsiPath(runtimeRoot)),
      '/qn',
      '/norestart',
    ]),
    environment: macosPrefixInitializationEnvironment(
      bottle: bottle,
      environment: environment,
      macosMajorVersion: macosMajorVersion,
    ),
    logPath: ProgramLogPath(
      joinPath(bottle.path.value, const ['logs', 'wine-mono-install.log']),
    ),
    workingDirectory: Option.of(
      ProgramWorkingDirectoryPath(macosWineBinFolder(hostEnvironment)),
    ),
  );
}

ProgramRunRequest macosWineserverKillRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
  required Option<int> macosMajorVersion,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: ProgramPath('wineserver'),
    runnerKind: RunnerKind('macosWineserver'),
    executable: ProgramExecutable(macosWineserverExecutable(hostEnvironment)),
    arguments: ProgramRunArguments(const <String>['-k']),
    environment: macosWineEnvironment(
      bottle: bottle,
      environment: environment,
      macosMajorVersion: macosMajorVersion,
    ),
    logPath: ProgramLogPath(
      joinPath(bottle.path.value, const ['logs', 'wineserver-kill.log']),
    ),
    workingDirectory: Option.of(
      ProgramWorkingDirectoryPath(macosWineBinFolder(hostEnvironment)),
    ),
  );
}

ProgramRunRequest macosWinedbgRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
  required Option<int> macosMajorVersion,
  required WinedbgCommandPlan winedbgCommand,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: ProgramPath('winedbg'),
    runnerKind: RunnerKind('macosWinedbg'),
    executable: ProgramExecutable(macosWineExecutable(hostEnvironment)),
    arguments: ProgramRunArguments(<String>[
      'winedbg',
      '--command',
      winedbgCommand.command.value,
      ...winedbgCommand.trailingArguments.value,
    ]),
    environment: macosWineEnvironment(
      bottle: bottle,
      environment: environment,
      macosMajorVersion: macosMajorVersion,
    ),
    logPath: ProgramLogPath(
      joinPath(bottle.path.value, <String>[
        'logs',
        winedbgCommand.logFileName.value,
      ]),
    ),
    workingDirectory: Option.of(
      ProgramWorkingDirectoryPath(macosWineBinFolder(hostEnvironment)),
    ),
  );
}

ProgramRunEnvironment macosWineEnvironment({
  required BottleRecord bottle,
  required HostEnvironment environment,
  required Option<int> macosMajorVersion,
}) {
  final hostEnvironment = environment;
  final runtimeRoot = macosWineRuntimeRoot(hostEnvironment);
  final d3dMetalSelected = bottle.runtimeSettings.dxrEnabled;
  final selectedBackendWindowsPaths = <String>[
    if (d3dMetalSelected)
      macosD3DMetalWindowsPath(runtimeRoot)
    else if (bottle.runtimeSettings.dxmt) ...[
      joinPath(runtimeRoot, const ['lib', 'dxmt', 'x86_64-windows']),
      joinPath(runtimeRoot, const ['lib', 'dxmt', 'i386-windows']),
    ] else if (bottle.runtimeSettings.dxvk) ...[
      joinPath(runtimeRoot, const ['lib', 'dxvk', 'x86_64-windows']),
      joinPath(runtimeRoot, const ['lib', 'dxvk', 'i386-windows']),
    ],
  ];
  final wineDllPathEntries = <String>[
    ...selectedBackendWindowsPaths,
    ...macosWineWindowsDllPaths(runtimeRoot),
  ];
  final wineSearchPathEntries = <String>[
    ...selectedBackendWindowsPaths,
    ...macosWineWindowsSearchPaths(runtimeRoot),
  ];
  final wineEnvironment = <String, String>{
    'WINEPREFIX': bottle.path.value,
    'WINEDEBUG': 'fixme-all',
    'GST_DEBUG': '1',
    'MVK_CONFIG_LOG_LEVEL': '0',
    'GST_PLUGIN_SYSTEM_PATH': macosGstreamerPluginPath(runtimeRoot),
    'GST_PLUGIN_SCANNER': macosGstreamerPluginScanner(runtimeRoot),
    'GST_REGISTRY': macosGstreamerRegistryPath(bottle.path.value),
    'WINEDATADIR': macosWineDataDir(runtimeRoot),
    'WINEDLLPATH': wineDllPathEntries.join(':'),
    'WINEPATH': macosWineWindowsSearchPath(wineSearchPathEntries),
    'WINELOADER': macosWineExecutable(hostEnvironment),
    'WINESERVER': macosWineserverExecutable(hostEnvironment),
    'DYLD_LIBRARY_PATH': prependPaths(<String>[
      if (d3dMetalSelected) macosD3DMetalExternalPath(runtimeRoot),
      if (d3dMetalSelected) macosD3DMetalUnixPath(runtimeRoot),
      if (bottle.runtimeSettings.dxmt && !d3dMetalSelected)
        macosDxmtUnixPath(runtimeRoot),
      joinPath(runtimeRoot, const ['lib']),
    ], environment['DYLD_LIBRARY_PATH']),
    if (d3dMetalSelected)
      'DYLD_FRAMEWORK_PATH': prependPaths(<String>[
        macosD3DMetalExternalPath(runtimeRoot),
      ], environment['DYLD_FRAMEWORK_PATH']),
    if (d3dMetalSelected)
      'CX_APPLEGPTK_LIBD3DSHARED_PATH': joinPath(runtimeRoot, const [
        ...gptkD3DMetalComponentLibRelativePath,
        'external',
        'libd3dshared.dylib',
      ]),
    ...bottle.runtimeSettings
        .macosEnvironment(
          enableD3DMetalDlssMetalFx: supportsD3DMetalDlssMetalFx(
            macosMajorVersion,
          ),
        )
        .toMap(),
  };

  return ProgramRunEnvironment(wineEnvironment);
}

String macosWineWindowsSearchPath(List<String> unixPaths) {
  return unixPaths.map(macosWineWindowsPath).join(';');
}

String macosWineWindowsPath(String unixPath) {
  final windowsPath = unixPath.replaceAll('/', '\\');
  if (unixPath.startsWith('/')) {
    return 'Z:$windowsPath';
  }
  return windowsPath;
}

ProgramRunEnvironment macosPrefixInitializationEnvironment({
  required BottleRecord bottle,
  required HostEnvironment environment,
  required Option<int> macosMajorVersion,
}) {
  return macosWineEnvironment(
    bottle: bottle,
    environment: environment,
    macosMajorVersion: macosMajorVersion,
  );
}

bool supportsD3DMetalDlssMetalFx(Option<int> macosMajorVersion) {
  return macosMajorVersion.match(() => false, (version) => version >= 16);
}

String macosWineDataDir(String runtimeRoot) {
  return joinPath(runtimeRoot, const ['share', 'wine']);
}

String macosWineMonoMsiPath(String runtimeRoot) {
  return joinPath(runtimeRoot, macosWineMonoComponentPaths.single);
}

String macosD3DMetalExternalPath(String runtimeRoot) {
  return joinPath(runtimeRoot, const [
    ...gptkD3DMetalComponentLibRelativePath,
    'external',
  ]);
}

String macosGstreamerPluginPath(String runtimeRoot) {
  return joinPath(runtimeRoot, const ['lib', 'gstreamer-1.0']);
}

String macosGstreamerPluginScanner(String runtimeRoot) {
  return joinPath(runtimeRoot, const [
    'libexec',
    'gstreamer-1.0',
    'gst-plugin-scanner',
  ]);
}

String macosGstreamerRegistryPath(String bottlePath) {
  return joinPath(bottlePath, const ['gstreamer-1.0-registry.x86_64.bin']);
}

String macosD3DMetalWindowsPath(String runtimeRoot) {
  return joinPath(runtimeRoot, const [
    ...gptkD3DMetalComponentLibRelativePath,
    'wine',
    'x86_64-windows',
  ]);
}

List<String> macosWineWindowsDllPaths(String runtimeRoot) {
  return <String>[
    joinPath(runtimeRoot, const ['lib', 'wine', 'x86_64-windows']),
    joinPath(runtimeRoot, const ['lib', 'wine', 'i386-windows']),
    joinPath(runtimeRoot, const ['lib', 'wine']),
  ];
}

List<String> macosWineWindowsSearchPaths(String runtimeRoot) {
  return <String>[
    joinPath(runtimeRoot, const ['lib', 'wine', 'x86_64-windows']),
    joinPath(runtimeRoot, const ['lib', 'wine', 'i386-windows']),
  ];
}

String macosD3DMetalUnixPath(String runtimeRoot) {
  return joinPath(runtimeRoot, const [
    ...gptkD3DMetalComponentLibRelativePath,
    'wine',
    'x86_64-unix',
  ]);
}

String macosDxmtUnixPath(String runtimeRoot) {
  return joinPath(runtimeRoot, const ['lib', 'dxmt', 'x86_64-unix']);
}

String prependPaths(Iterable<String> paths, Option<String> existingPath) {
  final prefix = paths.where((path) => path.trim().isNotEmpty).join(':');
  return existingPath.match(() => prefix, (existingPath) {
    if (existingPath.trim().isEmpty) {
      return prefix;
    }

    return '$prefix:$existingPath';
  });
}
