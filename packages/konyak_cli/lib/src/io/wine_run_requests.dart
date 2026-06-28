import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../domain/bottle/bottle_models.dart';
import '../domain/program/program_argument_support.dart';
import '../domain/program/program_registry_models.dart';
import '../domain/program/program_registry_plans.dart';
import '../domain/program/program_run_environment.dart';
import '../domain/program/program_run_models.dart';
import '../domain/runtime/host_environment.dart';
import '../domain/runtime/wine_runtime_paths.dart';
import '../domain/shared/domain_value_objects.dart';
import '../platform/macos/macos_program_run_requests.dart';
import '../platform/platform_terminal_commands.dart';
import '../shared/common_helpers.dart';
import 'directory_copy_support.dart';
import 'gptk_wine_installation.dart';

const dxvkOverrideDllNames = <String>[
  'dxgi.dll',
  'd3d9.dll',
  'd3d10.dll',
  'd3d10_1.dll',
  'd3d10core.dll',
  'd3d11.dll',
];

const macosD3DTranslationOverrideDllNames = <String>[
  ...dxvkOverrideDllNames,
  'd3d12.dll',
  'nvapi64.dll',
  'nvngx.dll',
  'nvngx-on-metalfx.dll',
  'winemetal.dll',
];

const d3dMetalOverrideDllNames = <String>[
  'dxgi.dll',
  'd3d11.dll',
  'd3d12.dll',
  'nvapi64.dll',
  'nvngx.dll',
];

void removeMacosD3DTranslationDllOverrides({required BottleRecord bottle}) {
  for (final windowsDirectory in const <String>['system32', 'syswow64']) {
    for (final dllName in macosD3DTranslationOverrideDllNames) {
      final dllPath = joinPath(bottle.path.value, <String>[
        'drive_c',
        'windows',
        windowsDirectory,
        dllName,
      ]);
      final type = FileSystemEntity.typeSync(dllPath);
      if (type == FileSystemEntityType.notFound) {
        continue;
      }
      deleteFileSystemEntitySync(dllPath, type);
    }
  }
}

void syncMacosDxvkDllOverrides({
  required BottleRecord bottle,
  required Map<String, String> environment,
}) {
  final hostEnvironment = HostEnvironment(environment);
  final runtimeRoot = macosWineRuntimeRoot(hostEnvironment);
  for (final arch in const <(String, String)>[
    ('x86_64-windows', 'system32'),
    ('i386-windows', 'syswow64'),
  ]) {
    final (runtimeArch, windowsDirectory) = arch;
    final destinationDirectory = Directory(
      joinPath(bottle.path.value, <String>[
        'drive_c',
        'windows',
        windowsDirectory,
      ]),
    )..createSync(recursive: true);

    for (final dllName in dxvkOverrideDllNames) {
      final sourcePath = joinPath(runtimeRoot, <String>[
        'lib',
        'dxvk',
        runtimeArch,
        dllName,
      ]);
      final sourceFile = File(sourcePath);
      if (!sourceFile.existsSync()) {
        throw FileSystemException(
          'DXVK override DLL was not found.',
          sourcePath,
        );
      }
      sourceFile.copySync(joinPath(destinationDirectory.path, [dllName]));
    }
  }
}

void syncMacosD3DMetalDllOverrides({
  required BottleRecord bottle,
  required Map<String, String> environment,
}) {
  final hostEnvironment = HostEnvironment(environment);
  final runtimeRoot = macosWineRuntimeRoot(hostEnvironment);
  final destinationDirectory = Directory(
    joinPath(bottle.path.value, const ['drive_c', 'windows', 'system32']),
  )..createSync(recursive: true);

  for (final dllName in d3dMetalOverrideDllNames) {
    d3DMetalOverrideSourcePath(
      runtimeRoot: runtimeRoot,
      dllName: dllName,
    ).match(
      () {
        throw FileSystemException(
          'D3DMetal override DLL was not found.',
          joinPath(runtimeRoot, <String>[
            ...gptkD3DMetalComponentLibRelativePath,
            'wine',
            'x86_64-windows',
            dllName,
          ]),
        );
      },
      (sourcePath) {
        final sourceFile = File(sourcePath);
        sourceFile.copySync(joinPath(destinationDirectory.path, [dllName]));
      },
    );
  }
}

Option<String> d3DMetalOverrideSourcePath({
  required String runtimeRoot,
  required String dllName,
}) {
  for (final sourceName in d3DMetalOverrideSourceNames(dllName)) {
    for (final sourceRoot in <List<String>>[
      <String>[
        ...gptkD3DMetalComponentLibRelativePath,
        'wine',
        'x86_64-windows',
      ],
      const <String>['lib', 'wine', 'x86_64-windows'],
    ]) {
      final sourcePath = joinPath(runtimeRoot, <String>[
        ...sourceRoot,
        sourceName,
      ]);
      if (File(sourcePath).existsSync()) {
        return Option.of(sourcePath);
      }
    }
  }
  return const Option.none();
}

List<String> d3DMetalOverrideSourceNames(String dllName) {
  return switch (dllName) {
    'nvngx.dll' => const <String>['nvngx.dll', 'nvngx-on-metalfx.dll'],
    _ => <String>[dllName],
  };
}

ProgramRunEnvironment linuxWineEnvironment(BottleRecord bottle) {
  return linuxWinePrefixEnvironment(bottle)
      .merge(bottle.runtimeSettings.linuxEnvironment())
      .merge(linuxWineLogSuppressionEnvironment());
}

ProgramRunEnvironment linuxWinePrefixEnvironment(BottleRecord bottle) {
  return ProgramRunEnvironment(<String, String>{
    'WINEPREFIX': bottle.path.value,
  });
}

ProgramRunEnvironment linuxWineLogSuppressionEnvironment() {
  return ProgramRunEnvironment(const <String, String>{
    'EGL_LOG_LEVEL': 'fatal',
    'MESA_LOG_LEVEL': 'fatal',
    'MESA_DEBUG': 'silent',
  });
}

ProgramRunEnvironment linuxWineEnvironmentWithRuntime({
  required BottleRecord bottle,
  required HostEnvironment environment,
}) {
  final wineEnvironment = linuxWineEnvironment(bottle);
  final hostEnvironment = environment;
  final dllPathEntries = <String>[];
  if (bottle.runtimeSettings.dxvk) {
    final runtimeRoot = linuxWineRuntimeRoot(hostEnvironment);
    dllPathEntries.addAll([
      joinPath(runtimeRoot, const ['dxvk', 'x64']),
      joinPath(runtimeRoot, const ['dxvk', 'x86']),
    ]);
  }
  if (bottle.runtimeSettings.vkd3dProton) {
    final runtimeRoot = linuxWineRuntimeRoot(hostEnvironment);
    dllPathEntries.addAll([
      joinPath(runtimeRoot, const ['vkd3d-proton', 'x64']),
      joinPath(runtimeRoot, const ['vkd3d-proton', 'x86']),
    ]);
  }
  if (dllPathEntries.isNotEmpty) {
    final wineEnvironmentWithDllPath = wineEnvironment.add(
      'WINEDLLPATH',
      dllPathEntries.join(':'),
    );
    return linuxWineEnvironmentWithDllOverrides(
      wineEnvironment: wineEnvironmentWithDllPath,
      bottle: bottle,
    );
  }

  return linuxWineEnvironmentWithDllOverrides(
    wineEnvironment: wineEnvironment,
    bottle: bottle,
  );
}

ProgramRunEnvironment linuxWineEnvironmentWithDllOverrides({
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
  final bottleCommand = BottleCommand(command);
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: ProgramPath(bottleCommand.value),
    runnerKind: RunnerKind('macosWine'),
    executable: ProgramExecutable(macosWineExecutable(hostEnvironment)),
    arguments: ProgramRunArguments(
      wineArgumentsForBottleCommand(bottleCommand),
    ),
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

ProgramRunRequest macosRegistryUpdateRequest({
  required BottleRecord bottle,
  required RegistryValueUpdate update,
  required HostEnvironment environment,
  required Option<int> macosMajorVersion,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: ProgramPath('reg'),
    runnerKind: RunnerKind('macosWineRegistry'),
    executable: ProgramExecutable(macosWineExecutable(hostEnvironment)),
    arguments: ProgramRunArguments(registryUpdateArguments(update)),
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

ProgramRunRequest macosRegistryQueryRequest({
  required BottleRecord bottle,
  required RegistryValueQuery query,
  required HostEnvironment environment,
  required Option<int> macosMajorVersion,
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: ProgramPath('reg'),
    runnerKind: RunnerKind('macosWineRegistryQuery'),
    executable: ProgramExecutable(macosWineExecutable(hostEnvironment)),
    arguments: ProgramRunArguments(registryQueryArguments(query)),
    environment: macosWineEnvironment(
      bottle: bottle,
      environment: environment,
      macosMajorVersion: macosMajorVersion,
    ),
    logPath: ProgramLogPath(
      joinPath(bottle.path.value, const ['logs', 'registry.log']),
    ),
    workingDirectory: Option.of(
      ProgramWorkingDirectoryPath(macosWineBinFolder(hostEnvironment)),
    ),
  );
}

ProgramRunRequest linuxTerminalCommandRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
  Option<String> initialWineCommand = const Option.none(),
}) {
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: ProgramPath(initialWineCommand.getOrElse(() => 'terminal')),
    runnerKind: RunnerKind('terminal'),
    executable: ProgramExecutable('sh'),
    arguments: ProgramRunArguments(<String>[
      '-lc',
      linuxTerminalLauncherCommand(environment),
      linuxWineTerminalShellCommandWithEnvironment(
        bottle: bottle,
        environment: environment,
        initialWineCommand: initialWineCommand,
      ),
    ]),
    environment: const ProgramRunEnvironment.empty(),
    logPath: ProgramLogPath(
      joinPath(bottle.path.value, const ['logs', 'latest.log']),
    ),
    workingDirectory: Option.of(ProgramWorkingDirectoryPath(bottle.path.value)),
  );
}

ProgramRunRequest macosTerminalCommandRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
  required Option<int> macosMajorVersion,
  Option<String> initialWineCommand = const Option.none(),
}) {
  final shellCommand = macosWineTerminalShellCommand(
    bottle: bottle,
    environment: environment,
    macosMajorVersion: macosMajorVersion,
    initialWineCommand: initialWineCommand,
  );
  final setupScriptPath = macosTerminalSetupScriptPath(bottle);

  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: ProgramPath(initialWineCommand.getOrElse(() => 'terminal')),
    runnerKind: RunnerKind('macosTerminal'),
    executable: ProgramExecutable('/usr/bin/osascript'),
    arguments: ProgramRunArguments(<String>[
      '-e',
      macosTerminalAppleScript(
        shellCommand: shellCommand,
        setupScriptPath: setupScriptPath,
      ),
    ]),
    environment: const ProgramRunEnvironment.empty(),
    logPath: ProgramLogPath(
      joinPath(bottle.path.value, const ['logs', 'latest.log']),
    ),
  );
}

ProgramRunRequest linuxWinetricksCommandRequest({
  required BottleRecord bottle,
  required HostEnvironment environment,
  Option<String> verb = const Option.none(),
}) {
  final hostEnvironment = environment;
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: ProgramPath(verb.getOrElse(() => 'winetricks')),
    runnerKind: RunnerKind('winetricks'),
    executable: ProgramExecutable(linuxWinetricksExecutable(hostEnvironment)),
    arguments: ProgramRunArguments(
      verb.match(() => const <String>[], (value) => <String>[value]),
    ),
    environment: linuxRuntimeEnvironment(hostEnvironment).merge(
      linuxWineEnvironmentWithRuntime(bottle: bottle, environment: environment),
    ),
    logPath: ProgramLogPath(
      joinPath(bottle.path.value, const ['logs', 'latest.log']),
    ),
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
    bottleId: bottle.id,
    programPath: ProgramPath(verb.getOrElse(() => 'winetricks')),
    runnerKind: RunnerKind('macosWinetricks'),
    executable: ProgramExecutable(macosWinetricksExecutable(hostEnvironment)),
    arguments: ProgramRunArguments(
      verb.match(() => const <String>[], (value) => <String>[value]),
    ),
    environment:
        macosWineEnvironment(
              bottle: bottle,
              environment: environment,
              macosMajorVersion: macosMajorVersion,
            )
            .add('WINE', macosWineExecutable(hostEnvironment))
            .add('PATH', prependPath(runtimeBin, environment['PATH'])),
    logPath: ProgramLogPath(
      joinPath(bottle.path.value, const ['logs', 'latest.log']),
    ),
    workingDirectory: Option.of(ProgramWorkingDirectoryPath(runtimeRoot)),
  );
}
