part of '../konyak_cli.dart';

class _RuntimeStackComponentDefinition {
  const _RuntimeStackComponentDefinition({
    required this.id,
    required this.name,
    required this.role,
    required this.isRequired,
    required this.relativePaths,
  });

  final String id;
  final String name;
  final String role;
  final bool isRequired;
  final List<List<String>> relativePaths;
}

class _RuntimePlatformSpec {
  const _RuntimePlatformSpec({
    required this.runtimeId,
    required this.runtimeName,
    required this.platform,
    required this.architecture,
    required this.runnerKind,
    required this.stackId,
    required this.stackName,
    required this.requiredExecutableRelativePath,
    required this.defaultArchiveFileName,
    required this.developmentSourceManifestEnvironmentKey,
    required this.releaseSourceManifestEnvironmentKey,
    required this.developmentSourceSignatureEnvironmentKey,
    required this.releaseSourceSignatureEnvironmentKey,
    required this.componentDefinitions,
    this.defaultArchiveUrl,
    this.archiveUrlEnvironmentKey,
    this.layoutNormalization = _RuntimeLayoutNormalization.none,
  });

  final String runtimeId;
  final String runtimeName;
  final String platform;
  final String architecture;
  final String runnerKind;
  final String stackId;
  final String stackName;
  final List<String> requiredExecutableRelativePath;
  final String defaultArchiveFileName;
  final String developmentSourceManifestEnvironmentKey;
  final String releaseSourceManifestEnvironmentKey;
  final String developmentSourceSignatureEnvironmentKey;
  final String releaseSourceSignatureEnvironmentKey;
  final List<_RuntimeStackComponentDefinition> componentDefinitions;
  final String? defaultArchiveUrl;
  final String? archiveUrlEnvironmentKey;
  final _RuntimeLayoutNormalization layoutNormalization;
}

enum _RuntimeLayoutNormalization { none, macosWineBundle }

class RuntimeValidationRecord {
  RuntimeValidationRecord({
    required this.runtimeId,
    required this.isValid,
    required Iterable<RuntimeValidationCheck> checks,
  }) : checks = List.unmodifiable(checks);

  final String runtimeId;
  final bool isValid;
  final List<RuntimeValidationCheck> checks;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'runtimeId': runtimeId,
      'isValid': isValid,
      'checks': checks.map((check) => check.toJson()).toList(growable: false),
    };
  }
}

class RuntimeValidationCheck {
  const RuntimeValidationCheck({
    required this.id,
    required this.name,
    required this.isRequired,
    required this.isPassed,
    required this.message,
  });

  final String id;
  final String name;
  final bool isRequired;
  final bool isPassed;
  final String message;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'isRequired': isRequired,
      'isPassed': isPassed,
      'message': message,
    };
  }
}

sealed class RuntimeValidationResult {
  const RuntimeValidationResult();
}

class RuntimeValidationCompleted extends RuntimeValidationResult {
  const RuntimeValidationCompleted(this.validation);

  final RuntimeValidationRecord validation;
}

class RuntimeValidationFailed extends RuntimeValidationResult {
  const RuntimeValidationFailed(this.message);

  final String message;
}

class RuntimeValidationRuntimeNotFound extends RuntimeValidationResult {
  const RuntimeValidationRuntimeNotFound(this.runtimeId);

  final String runtimeId;
}

abstract interface class RuntimeValidator {
  RuntimeValidationResult validate(String runtimeId);
}

class RuntimeExecutableProbeResult {
  const RuntimeExecutableProbeResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;
}

abstract interface class RuntimeExecutableProbe {
  RuntimeExecutableProbeResult run({
    required String executable,
    required List<String> arguments,
    required Map<String, String> environment,
    required String workingDirectory,
  });
}

class DartIoRuntimeExecutableProbe implements RuntimeExecutableProbe {
  const DartIoRuntimeExecutableProbe();

  @override
  RuntimeExecutableProbeResult run({
    required String executable,
    required List<String> arguments,
    required Map<String, String> environment,
    required String workingDirectory,
  }) {
    try {
      final result = Process.runSync(
        executable,
        arguments,
        environment: environment,
        workingDirectory: workingDirectory,
        runInShell: false,
      );

      return RuntimeExecutableProbeResult(
        exitCode: result.exitCode,
        stdout: _processOutputToString(result.stdout),
        stderr: _processOutputToString(result.stderr),
      );
    } on ProcessException catch (error) {
      return RuntimeExecutableProbeResult(
        exitCode: 127,
        stdout: '',
        stderr: error.message,
      );
    }
  }
}

class DartIoMacosWineRuntimeValidator implements RuntimeValidator {
  const DartIoMacosWineRuntimeValidator({
    required this.runtimeCatalog,
    this.fileStatusProbe = const DartIoFileStatusProbe(),
    this.executableProbe = const DartIoRuntimeExecutableProbe(),
  });

  final RuntimeCatalog runtimeCatalog;
  final FileStatusProbe fileStatusProbe;
  final RuntimeExecutableProbe executableProbe;

  @override
  RuntimeValidationResult validate(String runtimeId) {
    final runtime = _runtimeById(runtimeCatalog.listRuntimes(), runtimeId);
    if (runtime == null) {
      return RuntimeValidationRuntimeNotFound(runtimeId);
    }

    final runtimeRoot = runtime.libraryPath;
    final executablePath = runtime.executablePath;
    if (runtimeRoot == null || executablePath == null) {
      return RuntimeValidationCompleted(
        RuntimeValidationRecord(
          runtimeId: runtime.id,
          isValid: false,
          checks: const [
            RuntimeValidationCheck(
              id: 'runtime-layout',
              name: 'Runtime layout',
              isRequired: true,
              isPassed: false,
              message: 'Runtime record is missing layout paths.',
            ),
          ],
        ),
      );
    }

    final checks = <RuntimeValidationCheck>[
      _runtimePathCheck(
        id: 'runtime-root',
        name: 'Runtime root',
        path: runtimeRoot,
        fileStatusProbe: fileStatusProbe,
      ),
      _runtimePathCheck(
        id: 'wine-executable',
        name: 'Wine executable',
        path: executablePath,
        fileStatusProbe: fileStatusProbe,
      ),
      _runtimeAnyPathCheck(
        id: 'loader-dylibs',
        name: 'Wine loader libraries',
        paths: _macosWineLoaderLibraryPaths(runtimeRoot),
        fileStatusProbe: fileStatusProbe,
      ),
    ];

    if (!checks.every((check) => !check.isRequired || check.isPassed)) {
      return RuntimeValidationCompleted(
        RuntimeValidationRecord(
          runtimeId: runtime.id,
          isValid: false,
          checks: checks,
        ),
      );
    }

    final loaderResult = executableProbe.run(
      executable: executablePath,
      arguments: const ['--version'],
      environment: <String, String>{
        'DYLD_LIBRARY_PATH': _joinPath(runtimeRoot, const ['lib']),
      },
      workingDirectory: _dirname(executablePath),
    );
    final loaderCheck = RuntimeValidationCheck(
      id: 'wine-loader',
      name: 'Wine loader',
      isRequired: true,
      isPassed: loaderResult.exitCode == 0,
      message: loaderResult.exitCode == 0
          ? 'wine64 --version completed.'
          : _runtimeLoaderFailureMessage(loaderResult),
    );
    final completedChecks = <RuntimeValidationCheck>[...checks, loaderCheck];

    return RuntimeValidationCompleted(
      RuntimeValidationRecord(
        runtimeId: runtime.id,
        isValid: completedChecks.every(
          (check) => !check.isRequired || check.isPassed,
        ),
        checks: completedChecks,
      ),
    );
  }
}

class MacosSetupStatus {
  const MacosSetupStatus({
    required this.isSupported,
    required this.rosetta,
    required this.runtime,
  });

  final bool isSupported;
  final RosettaSetupStatus rosetta;
  final RuntimeSetupStatus runtime;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'isSupported': isSupported,
      'rosetta': rosetta.toJson(),
      'runtime': runtime.toJson(),
    };
  }
}

class RosettaSetupStatus {
  const RosettaSetupStatus({
    required this.isRequired,
    required this.isInstalled,
    required this.installCommand,
  });

  final bool isRequired;
  final bool isInstalled;
  final List<String> installCommand;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'isRequired': isRequired,
      'isInstalled': isInstalled,
      'installCommand': installCommand,
    };
  }
}

class RuntimeSetupStatus {
  const RuntimeSetupStatus({
    required this.runtimeId,
    required this.isInstalled,
  });

  final String runtimeId;
  final bool isInstalled;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'runtimeId': runtimeId,
      'isInstalled': isInstalled,
    };
  }
}

sealed class MacosSetupCheckResult {
  const MacosSetupCheckResult();
}

class MacosSetupCheckCompleted extends MacosSetupCheckResult {
  const MacosSetupCheckCompleted(this.status);

  final MacosSetupStatus status;
}

class MacosSetupCheckFailed extends MacosSetupCheckResult {
  const MacosSetupCheckFailed(this.message);

  final String message;
}

abstract interface class MacosSetupChecker {
  MacosSetupCheckResult check();
}

class DartIoMacosSetupChecker implements MacosSetupChecker {
  const DartIoMacosSetupChecker({
    required this.hostPlatform,
    required this.runtimeCatalog,
    this.fileStatusProbe = const DartIoFileStatusProbe(),
  });

  factory DartIoMacosSetupChecker.current(RuntimeCatalog runtimeCatalog) {
    return DartIoMacosSetupChecker(
      hostPlatform: _currentHostPlatform(),
      runtimeCatalog: runtimeCatalog,
    );
  }

  final KonyakHostPlatform hostPlatform;
  final RuntimeCatalog runtimeCatalog;
  final FileStatusProbe fileStatusProbe;

  @override
  MacosSetupCheckResult check() {
    final runtime = _runtimeById(
      runtimeCatalog.listRuntimes(),
      macosWineRuntimeId,
    );

    return MacosSetupCheckCompleted(
      MacosSetupStatus(
        isSupported: hostPlatform == KonyakHostPlatform.macos,
        rosetta: RosettaSetupStatus(
          isRequired: hostPlatform == KonyakHostPlatform.macos,
          isInstalled: fileStatusProbe.exists(_rosettaRuntimePath),
          installCommand: _rosettaInstallCommand,
        ),
        runtime: RuntimeSetupStatus(
          runtimeId: macosWineRuntimeId,
          isInstalled: runtime?.isInstalled == true,
        ),
      ),
    );
  }
}

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
    workingDirectory: _macosWineBinFolder(environment),
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
    workingDirectory: _macosWineBinFolder(environment),
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
    workingDirectory: _macosWineBinFolder(environment),
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
    workingDirectory: _macosWineBinFolder(environment),
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
      environment['DYLD_LIBRARY_PATH'],
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
