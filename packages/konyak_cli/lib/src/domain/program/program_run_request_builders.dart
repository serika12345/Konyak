import 'package:fpdart/fpdart.dart';

import '../bottle/bottle_models.dart';
import '../runtime/host_environment.dart';
import '../runtime/runtime_platform_support.dart';
import '../runtime/wine_runtime_paths.dart';
import '../shared/domain_helpers.dart';
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
    bottleId: bottle.id.value,
    programPath: programPath,
    runnerKind: 'wine',
    executable: linuxWineExecutable(hostEnvironment),
    arguments: arguments,
    environment: linuxRuntimeEnvironment(hostEnvironment)
        .merge(programSettingsEnvironment(programSettings))
        .merge(
          _linuxWineEnvironmentWithRuntime(
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
      _linuxWineEnvironmentWithRuntime(
        bottle: bottle,
        environment: environment,
      ),
    ),
    logPath: domainJoinPath(bottle.path.value, const ['logs', 'latest.log']),
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
      _linuxWineEnvironmentWithRuntime(
        bottle: bottle,
        environment: environment,
      ),
    ),
    logPath: domainJoinPath(bottle.path.value, const ['logs', 'latest.log']),
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
      _linuxWineEnvironmentWithRuntime(
        bottle: bottle,
        environment: environment,
      ),
    ),
    logPath: domainJoinPath(bottle.path.value, const ['logs', 'registry.log']),
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
      _linuxWineEnvironmentWithRuntime(
        bottle: bottle,
        environment: environment,
      ),
    ),
    logPath: domainJoinPath(bottle.path.value, const [
      'logs',
      'prefix-init.log',
    ]),
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
      _linuxWineEnvironmentWithRuntime(
        bottle: bottle,
        environment: environment,
      ),
    ),
    logPath: domainJoinPath(bottle.path.value, const ['logs', 'latest.log']),
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
    ).merge(_linuxWinePrefixEnvironment(bottle)),
    logPath: domainJoinPath(bottle.path.value, const [
      'logs',
      'wineserver-kill.log',
    ]),
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
    ).merge(_linuxWinePrefixEnvironment(bottle)),
    logPath: domainJoinPath(bottle.path.value, <String>['logs', logName]),
  );
}

ProgramRunRequest macosWineRequest({
  required BottleRecord bottle,
  required String programPath,
  required HostEnvironment environment,
  required Option<int> macosMajorVersion,
  required ProgramSettingsRecord programSettings,
}) {
  final hostEnvironment = environment;
  final logging = programSettingsLogging(programSettings);
  return ProgramRunRequest(
    bottleId: bottle.id.value,
    programPath: programPath,
    runnerKind: 'macosWine',
    executable: macosWineExecutable(hostEnvironment),
    arguments: <String>[
      'start',
      '/unix',
      programPath,
      ...programSettingsArguments(programSettings),
    ],
    environment: ProgramRunEnvironment(<String, String>{
      ..._macosWineEnvironment(
        bottle: bottle,
        environment: environment,
        macosMajorVersion: macosMajorVersion,
      ).toMap(),
      ...programSettingsEnvironment(programSettings).toMap(),
      'WINEPREFIX': bottle.path.value,
    }),
    logPath: programSettingsLogPath(bottle: bottle, settings: programSettings),
    createLogFile: logging.createLogFile,
    workingDirectory: Option.of(macosWineBinFolder(hostEnvironment)),
  );
}

ProgramRunRequest macosWinebootRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
  required Option<int> macosMajorVersion,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id.value,
    programPath: 'wineboot',
    runnerKind: 'macosWine',
    executable: macosWineExecutable(hostEnvironment),
    arguments: const <String>['wineboot', '--init'],
    environment: _macosPrefixInitializationEnvironment(
      bottle: bottle,
      environment: environment,
      macosMajorVersion: macosMajorVersion,
    ),
    logPath: domainJoinPath(bottle.path.value, const [
      'logs',
      'prefix-init.log',
    ]),
    workingDirectory: Option.of(macosWineBinFolder(hostEnvironment)),
  );
}

ProgramRunRequest macosWinebootRestartRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
  required Option<int> macosMajorVersion,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id.value,
    programPath: 'wineboot',
    runnerKind: 'macosWine',
    executable: macosWineExecutable(hostEnvironment),
    arguments: const <String>['wineboot', '--restart'],
    environment: _macosWineEnvironment(
      bottle: bottle,
      environment: environment,
      macosMajorVersion: macosMajorVersion,
    ),
    logPath: domainJoinPath(bottle.path.value, const ['logs', 'latest.log']),
    workingDirectory: Option.of(macosWineBinFolder(hostEnvironment)),
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
    bottleId: bottle.id.value,
    programPath: 'wine-mono',
    runnerKind: 'macosWine',
    executable: macosWineExecutable(hostEnvironment),
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
      macosMajorVersion: macosMajorVersion,
    ),
    logPath: domainJoinPath(bottle.path.value, const [
      'logs',
      'wine-mono-install.log',
    ]),
    workingDirectory: Option.of(macosWineBinFolder(hostEnvironment)),
  );
}

ProgramRunRequest macosWineserverKillRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
  required Option<int> macosMajorVersion,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id.value,
    programPath: 'wineserver',
    runnerKind: 'macosWineserver',
    executable: macosWineserverExecutable(hostEnvironment),
    arguments: const <String>['-k'],
    environment: _macosWineEnvironment(
      bottle: bottle,
      environment: environment,
      macosMajorVersion: macosMajorVersion,
    ),
    logPath: domainJoinPath(bottle.path.value, const [
      'logs',
      'wineserver-kill.log',
    ]),
    workingDirectory: Option.of(macosWineBinFolder(hostEnvironment)),
  );
}

ProgramRunRequest macosWinedbgRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
  required Option<int> macosMajorVersion,
  required String command,
  required String logName,
  List<String> trailingArguments = const <String>[],
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id.value,
    programPath: 'winedbg',
    runnerKind: 'macosWinedbg',
    executable: macosWineExecutable(hostEnvironment),
    arguments: <String>['winedbg', '--command', command, ...trailingArguments],
    environment: _macosWineEnvironment(
      bottle: bottle,
      environment: environment,
      macosMajorVersion: macosMajorVersion,
    ),
    logPath: domainJoinPath(bottle.path.value, <String>['logs', logName]),
    workingDirectory: Option.of(macosWineBinFolder(hostEnvironment)),
  );
}

ProgramRunEnvironment _macosWineEnvironment({
  required BottleRecord bottle,
  required HostEnvironment environment,
  required Option<int> macosMajorVersion,
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
  required Option<int> macosMajorVersion,
}) {
  return _macosWineEnvironment(
    bottle: bottle,
    environment: environment,
    macosMajorVersion: macosMajorVersion,
  );
}

bool _supportsD3DMetalDlssMetalFx(Option<int> macosMajorVersion) {
  return macosMajorVersion.match(() => false, (version) => version >= 16);
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

ProgramRunRequest macosWineCommandRequest({
  required BottleRecord bottle,
  required String command,
  required HostEnvironment environment,
  required Option<int> macosMajorVersion,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id.value,
    programPath: command,
    runnerKind: 'macosWine',
    executable: macosWineExecutable(hostEnvironment),
    arguments: wineArgumentsForBottleCommand(command),
    environment: _macosWineEnvironment(
      bottle: bottle,
      environment: environment,
      macosMajorVersion: macosMajorVersion,
    ),
    logPath: domainJoinPath(bottle.path.value, const ['logs', 'latest.log']),
    workingDirectory: Option.of(macosWineBinFolder(hostEnvironment)),
  );
}

ProgramRunRequest macosRegistryUpdateRequest({
  required BottleRecord bottle,
  required RegistryValueUpdate update,
  required HostEnvironment environment,
  required Option<int> macosMajorVersion,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id.value,
    programPath: 'reg',
    runnerKind: 'macosWineRegistry',
    executable: macosWineExecutable(hostEnvironment),
    arguments: registryUpdateArguments(update),
    environment: _macosWineEnvironment(
      bottle: bottle,
      environment: environment,
      macosMajorVersion: macosMajorVersion,
    ),
    logPath: domainJoinPath(bottle.path.value, const ['logs', 'latest.log']),
    workingDirectory: Option.of(macosWineBinFolder(hostEnvironment)),
  );
}

ProgramRunRequest macosRegistryQueryRequest({
  required BottleRecord bottle,
  required RegistryValueQuery query,
  required HostEnvironment environment,
  required Option<int> macosMajorVersion,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id.value,
    programPath: 'reg',
    runnerKind: 'macosWineRegistryQuery',
    executable: macosWineExecutable(hostEnvironment),
    arguments: registryQueryArguments(query),
    environment: _macosWineEnvironment(
      bottle: bottle,
      environment: environment,
      macosMajorVersion: macosMajorVersion,
    ),
    logPath: domainJoinPath(bottle.path.value, const ['logs', 'registry.log']),
    workingDirectory: Option.of(macosWineBinFolder(hostEnvironment)),
  );
}

ProgramRunRequest linuxTerminalCommandRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
  Option<String> initialWineCommand = const Option.none(),
}) {
  return ProgramRunRequest(
    bottleId: bottle.id.value,
    programPath: initialWineCommand.getOrElse(() => 'terminal'),
    runnerKind: 'terminal',
    executable: 'sh',
    arguments: <String>[
      '-lc',
      _linuxTerminalLauncherCommand(environment),
      _linuxWineTerminalShellCommandWithEnvironment(
        bottle: bottle,
        environment: environment,
        initialWineCommand: initialWineCommand,
      ),
    ],
    environment: const ProgramRunEnvironment.empty(),
    logPath: domainJoinPath(bottle.path.value, const ['logs', 'latest.log']),
    workingDirectory: Option.of(bottle.path.value),
  );
}

ProgramRunRequest macosTerminalCommandRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
  required Option<int> macosMajorVersion,
  Option<String> initialWineCommand = const Option.none(),
}) {
  final shellCommand = _macosWineTerminalShellCommand(
    bottle: bottle,
    environment: environment,
    macosMajorVersion: macosMajorVersion,
    initialWineCommand: initialWineCommand,
  );
  final setupScriptPath = _macosTerminalSetupScriptPath(bottle);

  return ProgramRunRequest(
    bottleId: bottle.id.value,
    programPath: initialWineCommand.getOrElse(() => 'terminal'),
    runnerKind: 'macosTerminal',
    executable: '/usr/bin/osascript',
    arguments: <String>[
      '-e',
      _macosTerminalAppleScript(
        shellCommand: shellCommand,
        setupScriptPath: setupScriptPath,
      ),
    ],
    environment: const ProgramRunEnvironment.empty(),
    logPath: domainJoinPath(bottle.path.value, const ['logs', 'latest.log']),
  );
}

ProgramRunRequest linuxWinetricksCommandRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
  Option<String> verb = const Option.none(),
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id.value,
    programPath: verb.getOrElse(() => 'winetricks'),
    runnerKind: 'winetricks',
    executable: linuxWinetricksExecutable(hostEnvironment),
    arguments: verb.match(() => const <String>[], (value) => <String>[value]),
    environment: linuxRuntimeEnvironment(hostEnvironment).merge(
      _linuxWineEnvironmentWithRuntime(
        bottle: bottle,
        environment: environment,
      ),
    ),
    logPath: domainJoinPath(bottle.path.value, const ['logs', 'latest.log']),
  );
}

ProgramRunRequest macosWinetricksCommandRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
  required Option<int> macosMajorVersion,
  required Option<String> verb,
}) {
  final hostEnvironment = environment;
  final runtimeRoot = macosWineRuntimeRoot(hostEnvironment);
  final runtimeBin = macosWineBinFolder(hostEnvironment);

  return ProgramRunRequest(
    bottleId: bottle.id.value,
    programPath: verb.getOrElse(() => 'winetricks'),
    runnerKind: 'macosWinetricks',
    executable: macosWinetricksExecutable(hostEnvironment),
    arguments: verb.match(() => const <String>[], (value) => <String>[value]),
    environment:
        _macosWineEnvironment(
              bottle: bottle,
              environment: environment,
              macosMajorVersion: macosMajorVersion,
            )
            .add('WINE', macosWineExecutable(hostEnvironment))
            .add('PATH', _prependPath(runtimeBin, environment['PATH'])),
    logPath: domainJoinPath(bottle.path.value, const ['logs', 'latest.log']),
    workingDirectory: Option.of(runtimeRoot),
  );
}

Option<String> _linuxTerminalOverride(HostEnvironment environment) {
  return environment.nonEmptyValue('TERMINAL');
}

String _linuxTerminalLauncherCommand(HostEnvironment environment) {
  final override = _linuxTerminalOverride(environment);
  final candidates = <String>[
    ...override.match(
      () => const <String>[],
      (terminal) => <String>[
        'exec ${_shellQuote(terminal)} -e bash -lc "\$0" sh',
      ],
    ),
    'if command -v x-terminal-emulator >/dev/null 2>&1; then exec x-terminal-emulator -e bash -lc "\$0" sh; fi',
    'if command -v kgx >/dev/null 2>&1; then exec kgx -- bash -lc "\$0"; fi',
    'if command -v gnome-terminal >/dev/null 2>&1; then exec gnome-terminal -- bash -lc "\$0"; fi',
    'if command -v ptyxis >/dev/null 2>&1; then exec ptyxis --standalone -- bash -lc "\$0"; fi',
    'if command -v konsole >/dev/null 2>&1; then exec konsole -e bash -lc "\$0"; fi',
    'if command -v xfce4-terminal >/dev/null 2>&1; then exec xfce4-terminal -x bash -lc "\$0"; fi',
    'if command -v mate-terminal >/dev/null 2>&1; then exec mate-terminal -- bash -lc "\$0"; fi',
    'if command -v tilix >/dev/null 2>&1; then exec tilix -- bash -lc "\$0"; fi',
    'if command -v kitty >/dev/null 2>&1; then exec kitty bash -lc "\$0"; fi',
    'if command -v alacritty >/dev/null 2>&1; then exec alacritty -e bash -lc "\$0"; fi',
    'if command -v wezterm >/dev/null 2>&1; then exec wezterm start -- bash -lc "\$0"; fi',
    'echo "No supported terminal emulator found." >&2',
    'exit 127',
  ];

  return candidates.join('\n');
}

String _linuxWineTerminalShellCommandWithEnvironment({
  required BottleRecord bottle,
  required HostEnvironment environment,
  Option<String> initialWineCommand = const Option.none(),
}) {
  final hostEnvironment = environment;
  final executable = linuxWineExecutable(hostEnvironment);
  final runtimeBin = linuxManagedRuntimeBinFolder(hostEnvironment);
  final wineLibraryPath = hostEnvironment.nonEmptyValue(
    'KONYAK_LINUX_WINE_LIBRARY_PATH',
  );
  final shellSetup = <String>[
    'cd ${_shellQuote(bottle.path.value)}',
    'export WINEPREFIX=${_shellQuote(bottle.path.value)}',
    'export WINE=${_shellQuote(executable)}',
    'export PATH=${_shellQuote(runtimeBin)}:\$PATH',
    ...wineLibraryPath.match(
      () => const <String>[],
      (path) => <String>[
        'export LD_LIBRARY_PATH=${_shellQuote(path)}:\${LD_LIBRARY_PATH:-}',
      ],
    ),
    for (final entry in _linuxWineLogSuppressionEnvironment().toMap().entries)
      'export ${entry.key}=${_shellQuote(entry.value)}',
    'alias wine=${_shellQuote(executable)}',
    'alias wine64=${_shellQuote(executable)}',
    'alias winecfg=${_shellQuote('$executable winecfg')}',
    'alias msiexec=${_shellQuote('$executable msiexec')}',
    ...initialWineCommand.match(
      () => const <String>[],
      (command) => <String>[
        _wineTerminalInitialCommand(executable: executable, command: command),
      ],
    ),
  ];

  return <String>[
    "exec bash --noprofile --rcfile <(cat <<'KONYAK_BASHRC'",
    ...shellSetup,
    'KONYAK_BASHRC',
    ') -i',
  ].join('\n');
}

String _macosWineTerminalShellCommand({
  required BottleRecord bottle,
  required HostEnvironment environment,
  required Option<int> macosMajorVersion,
  Option<String> initialWineCommand = const Option.none(),
}) {
  final runtimeBin = macosWineBinFolder(environment);
  final executable = macosWineExecutable(environment);
  return <String>[
    'cd ${_shellQuote(bottle.path.value)}',
    'export PATH=${_shellQuote(runtimeBin)}:\$PATH',
    'export WINE=${_shellQuote(executable)}',
    'alias wine=${_shellQuote(executable)}',
    'alias wine64=${_shellQuote(executable)}',
    'alias winecfg=${_shellQuote('$executable winecfg')}',
    'alias msiexec=${_shellQuote('$executable msiexec')}',
    'alias regedit=${_shellQuote('$executable regedit')}',
    'alias regsvr32=${_shellQuote('$executable regsvr32')}',
    'alias wineboot=${_shellQuote('$executable wineboot')}',
    'alias wineconsole=${_shellQuote('$executable wineconsole')}',
    'alias winedbg=${_shellQuote('$executable winedbg')}',
    'alias winefile=${_shellQuote('$executable winefile')}',
    'alias winepath=${_shellQuote('$executable winepath')}',
    ..._macosWineEnvironment(
      bottle: bottle,
      environment: environment,
      macosMajorVersion: macosMajorVersion,
    ).toMap().entries.map((entry) {
      return 'export ${entry.key}=${_shellQuote(entry.value)}';
    }),
    ...initialWineCommand.match(
      () => const <String>[],
      (command) => <String>[
        _wineTerminalInitialCommand(executable: executable, command: command),
      ],
    ),
  ].join('; ');
}

String _wineTerminalInitialCommand({
  required String executable,
  required String command,
}) {
  return '${_shellQuote(executable)} ${_shellQuote(command)}';
}

String _macosTerminalSetupScriptPath(BottleRecord bottle) {
  return domainJoinPath(bottle.path.value, const [
    'logs',
    'konyak-terminal-setup.zsh',
  ]);
}

String _macosTerminalAppleScript({
  required String shellCommand,
  required String setupScriptPath,
}) {
  final setupDirectory = _dirname(setupScriptPath);
  final escapedSetupDirectory = _appleScriptString(setupDirectory);
  final escapedSetupFile = _appleScriptString(setupScriptPath);
  final escapedSetupText = _appleScriptString(shellCommand);
  final escapedTerminalCommand = _appleScriptString(
    'source ${_shellQuote(setupScriptPath)}',
  );

  return '''
set setupDirectory to "$escapedSetupDirectory"
set setupFile to "$escapedSetupFile"
set setupText to "$escapedSetupText"
do shell script "umask 077; mkdir -p " & quoted form of setupDirectory & "; printf %s " & quoted form of setupText & " > " & quoted form of setupFile
tell application "Terminal"
activate
do script "$escapedTerminalCommand"
end tell
''';
}

String _appleScriptString(String value) {
  return value
      .replaceAll(r'\', r'\\')
      .replaceAll('"', r'\"')
      .replaceAll('\n', r'\n');
}

String _shellQuote(String value) {
  return "'${value.replaceAll("'", "'\"'\"'")}'";
}

String _prependPath(String path, Option<String> existingPath) {
  return existingPath.match(() => path, (existingPath) {
    if (existingPath.trim().isEmpty) {
      return path;
    }

    return '$path:$existingPath';
  });
}

String _dirname(String path) {
  final index = path.lastIndexOf('/');
  if (index <= 0) {
    return '.';
  }

  return path.substring(0, index);
}

bool isSupportedWinetricksVerb(String verb) {
  return RegExp(r'^[A-Za-z0-9_.+-]+$').hasMatch(verb);
}

String winedbgAttachProcessId(String processId) {
  final normalized = processId.trim();
  if (normalized.startsWith(RegExp('0x', caseSensitive: false))) {
    return normalized;
  }
  if (RegExp(r'^[0-9a-fA-F]+$').hasMatch(normalized)) {
    return '0x$normalized';
  }

  return normalized;
}
