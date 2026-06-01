part of '../konyak_cli.dart';

class _CliCommandContext {
  const _CliCommandContext({
    required this.bottleCatalog,
    required this.bottleRepository,
    required this.bottleProgramRepository,
    required this.programMetadataExtractor,
    required this.winetricksVerbRepository,
    required this.winetricksScriptInstaller,
    required this.runtimeCatalog,
    required this.programRunPlanner,
    required this.programRunner,
    required this.bottlePrefixInitializer,
    required this.pathOpener,
    required this.macosWineInstaller,
    required this.linuxWineInstaller,
    required this.gptkWineInstaller,
    required this.runtimeUpdateChecker,
    required this.appUpdateChecker,
    required this.appUpdateInstaller,
    required this.runtimeValidator,
    required this.macosSetupChecker,
    required this.appSettingsRepository,
    required this.runtimeInstallProgressSink,
  });

  final BottleCatalog bottleCatalog;
  final BottleRepository? bottleRepository;
  final BottleProgramRepository bottleProgramRepository;
  final ProgramMetadataExtractor programMetadataExtractor;
  final WinetricksVerbRepository winetricksVerbRepository;
  final WinetricksScriptInstaller winetricksScriptInstaller;
  final RuntimeCatalog runtimeCatalog;
  final ProgramRunPlanner programRunPlanner;
  final ProgramRunner? programRunner;
  final BottlePrefixInitializer? bottlePrefixInitializer;
  final PathOpener? pathOpener;
  final MacosWineInstaller? macosWineInstaller;
  final LinuxWineInstaller? linuxWineInstaller;
  final GptkWineInstaller? gptkWineInstaller;
  final RuntimeUpdateChecker? runtimeUpdateChecker;
  final AppUpdateChecker? appUpdateChecker;
  final AppUpdateInstaller? appUpdateInstaller;
  final RuntimeValidator? runtimeValidator;
  final MacosSetupChecker? macosSetupChecker;
  final AppSettingsRepository? appSettingsRepository;
  final RuntimeInstallProgressSink? runtimeInstallProgressSink;
}

CliResult runCli(
  List<String> arguments, {
  BottleCatalog bottleCatalog = const StaticBottleCatalog(<BottleRecord>[]),
  BottleRepository? bottleRepository,
  BottleProgramRepository bottleProgramRepository =
      const DartIoBottleProgramRepository(),
  ProgramMetadataExtractor programMetadataExtractor =
      const DartIoProgramMetadataExtractor(),
  WinetricksVerbRepository? winetricksVerbRepository,
  WinetricksScriptInstaller winetricksScriptInstaller =
      const DartIoWinetricksScriptInstaller(),
  RuntimeCatalog runtimeCatalog = const StaticRuntimeCatalog(<RuntimeRecord>[]),
  ProgramRunPlanner? programRunPlanner,
  ProgramRunner? programRunner,
  BottlePrefixInitializer? bottlePrefixInitializer,
  PathOpener? pathOpener,
  MacosWineInstaller? macosWineInstaller,
  LinuxWineInstaller? linuxWineInstaller,
  GptkWineInstaller? gptkWineInstaller,
  RuntimeUpdateChecker? runtimeUpdateChecker,
  AppUpdateChecker? appUpdateChecker,
  AppUpdateInstaller? appUpdateInstaller,
  RuntimeValidator? runtimeValidator,
  MacosSetupChecker? macosSetupChecker,
  AppSettingsRepository? appSettingsRepository,
  RuntimeInstallProgressSink? runtimeInstallProgressSink,
}) {
  try {
    return _runCli(
      arguments,
      _CliCommandContext(
        bottleCatalog: bottleCatalog,
        bottleRepository: bottleRepository,
        bottleProgramRepository: bottleProgramRepository,
        programMetadataExtractor: programMetadataExtractor,
        winetricksVerbRepository:
            winetricksVerbRepository ??
            DartIoWinetricksVerbRepository.current(),
        winetricksScriptInstaller: winetricksScriptInstaller,
        runtimeCatalog: runtimeCatalog,
        programRunPlanner: programRunPlanner ?? ProgramRunPlanner.current(),
        programRunner: programRunner,
        bottlePrefixInitializer: bottlePrefixInitializer,
        pathOpener: pathOpener,
        macosWineInstaller: macosWineInstaller,
        linuxWineInstaller: linuxWineInstaller,
        gptkWineInstaller: gptkWineInstaller,
        runtimeUpdateChecker: runtimeUpdateChecker,
        appUpdateChecker: appUpdateChecker,
        appUpdateInstaller: appUpdateInstaller,
        runtimeValidator: runtimeValidator,
        macosSetupChecker: macosSetupChecker,
        appSettingsRepository: appSettingsRepository,
        runtimeInstallProgressSink: runtimeInstallProgressSink,
      ),
    );
  } on BottleRepositoryException catch (error) {
    return _jsonError(
      exitCode: 74,
      code: 'bottleRepositoryError',
      message: error.message,
    );
  } on AppSettingsRepositoryException catch (error) {
    return _jsonError(
      exitCode: 74,
      code: 'appSettingsRepositoryError',
      message: error.message,
    );
  }
}

Future<CliResult> runCliStreaming(
  List<String> arguments, {
  BottleCatalog bottleCatalog = const StaticBottleCatalog(<BottleRecord>[]),
  BottleRepository? bottleRepository,
  BottleProgramRepository bottleProgramRepository =
      const DartIoBottleProgramRepository(),
  ProgramMetadataExtractor programMetadataExtractor =
      const DartIoProgramMetadataExtractor(),
  WinetricksVerbRepository? winetricksVerbRepository,
  WinetricksScriptInstaller winetricksScriptInstaller =
      const DartIoWinetricksScriptInstaller(),
  RuntimeCatalog runtimeCatalog = const StaticRuntimeCatalog(<RuntimeRecord>[]),
  ProgramRunPlanner? programRunPlanner,
  ProgramRunner? programRunner,
  BottlePrefixInitializer? bottlePrefixInitializer,
  PathOpener? pathOpener,
  MacosWineInstaller? macosWineInstaller,
  LinuxWineInstaller? linuxWineInstaller,
  GptkWineInstaller? gptkWineInstaller,
  RuntimeUpdateChecker? runtimeUpdateChecker,
  AppUpdateChecker? appUpdateChecker,
  AppUpdateInstaller? appUpdateInstaller,
  RuntimeValidator? runtimeValidator,
  MacosSetupChecker? macosSetupChecker,
  AppSettingsRepository? appSettingsRepository,
  RuntimeInstallProgressSink? runtimeInstallProgressSink,
}) async {
  final macosWineInstallRequest = _parseJsonMacosWineInstallRequest(arguments);
  if (macosWineInstallRequest?.emitProgress == true &&
      macosWineInstaller is DartIoMacosWineInstaller) {
    final installResult = await macosWineInstaller.installStreaming(
      macosWineInstallRequest!,
      progressSink: runtimeInstallProgressSink,
    );
    return _macosWineInstallCliResult(installResult);
  }

  final linuxWineInstallRequest = _parseJsonLinuxWineInstallRequest(arguments);
  if (linuxWineInstallRequest?.emitProgress == true &&
      linuxWineInstaller is DartIoLinuxWineInstaller) {
    final installResult = await linuxWineInstaller.installStreaming(
      linuxWineInstallRequest!,
      progressSink: runtimeInstallProgressSink,
    );
    return _linuxWineInstallCliResult(installResult);
  }

  return runCli(
    arguments,
    bottleCatalog: bottleCatalog,
    bottleRepository: bottleRepository,
    bottleProgramRepository: bottleProgramRepository,
    programMetadataExtractor: programMetadataExtractor,
    winetricksVerbRepository: winetricksVerbRepository,
    winetricksScriptInstaller: winetricksScriptInstaller,
    runtimeCatalog: runtimeCatalog,
    programRunPlanner: programRunPlanner,
    programRunner: programRunner,
    bottlePrefixInitializer: bottlePrefixInitializer,
    pathOpener: pathOpener,
    macosWineInstaller: macosWineInstaller,
    linuxWineInstaller: linuxWineInstaller,
    gptkWineInstaller: gptkWineInstaller,
    runtimeUpdateChecker: runtimeUpdateChecker,
    appUpdateChecker: appUpdateChecker,
    appUpdateInstaller: appUpdateInstaller,
    runtimeValidator: runtimeValidator,
    macosSetupChecker: macosSetupChecker,
    appSettingsRepository: appSettingsRepository,
    runtimeInstallProgressSink: runtimeInstallProgressSink,
  );
}

CliResult _programUpdateJsonResult(ProgramUpdateResult result) {
  return switch (result) {
    ProgramUpdated(:final bottle) => _bottleJsonResult(bottle),
    ProgramUpdateMissingBottle(:final bottleId) => _bottleNotFoundError(
      bottleId,
    ),
    ProgramUpdateMissingProgram(:final programPath) => _jsonError(
      exitCode: 66,
      code: 'programNotPinned',
      message: 'Program is not pinned.',
      extra: <String, Object?>{'programPath': programPath},
    ),
  };
}

CliResult _runPinnedProgramLauncherCli({
  required _PinnedProgramLaunchCliRequest request,
  required BottleRepository? bottleRepository,
  required ProgramRunPlanner programRunPlanner,
  required ProgramRunner? programRunner,
}) {
  final launcherManifest = _readPinnedProgramLauncherManifest(
    request.manifestPath,
  );
  if (launcherManifest == null) {
    return _jsonError(
      exitCode: 65,
      code: 'invalidPinnedProgramLauncher',
      message: 'Pinned program launcher manifest is invalid.',
      extra: <String, Object?>{'manifestPath': request.manifestPath},
    );
  }

  if (bottleRepository == null) {
    return _bottleRepositoryUnavailableError();
  }

  if (programRunner == null) {
    return _programRunnerUnavailableError();
  }

  final bottle = bottleRepository.findBottle(launcherManifest.bottleId);
  if (bottle == null) {
    return _bottleNotFoundError(launcherManifest.bottleId);
  }

  final expectedLauncherId = _pinnedProgramLauncherId(
    bottleId: launcherManifest.bottleId,
    programPath: launcherManifest.programPath,
  );
  if (launcherManifest.launcherId != expectedLauncherId ||
      !_hasPinnedProgram(bottle, launcherManifest.programPath)) {
    return _jsonError(
      exitCode: 66,
      code: 'programNotPinned',
      message: 'Program is not pinned.',
      extra: <String, Object?>{'programPath': launcherManifest.programPath},
    );
  }

  final settingsResult = bottleRepository.readProgramSettings(
    ProgramSettingsRequest(
      bottleId: bottle.id,
      programPath: launcherManifest.programPath,
    ),
  );
  final programSettings = switch (settingsResult) {
    ProgramSettingsRead(:final settings) => settings,
    ProgramSettingsReadMissingBottle() => const ProgramSettingsRecord(),
  };
  final programRunRequest = programRunPlanner.plan(
    bottle: bottle,
    programPath: launcherManifest.programPath,
    programSettings: programSettings,
  );
  if (programRunRequest == null) {
    return _jsonError(
      exitCode: 65,
      code: 'unsupportedProgramType',
      message: 'Program type is not supported.',
      extra: <String, Object?>{'programPath': launcherManifest.programPath},
    );
  }

  final runResult = programRunner.run(programRunRequest);

  return switch (runResult) {
    ProgramRunCompleted(:final processExitCode) => _programRunJsonResult(
      request: programRunRequest,
      processExitCode: processExitCode,
    ),
    ProgramRunFailed(:final message) => _programRunFailedJsonResult(
      request: programRunRequest,
      message: message,
    ),
  };
}

CliResult _bottleArchiveExportJsonResult(BottleArchiveExportResult result) {
  return switch (result) {
    BottleArchiveExported(:final archive) => _jsonSuccess(<String, Object?>{
      'bottleArchive': archive.toJson(),
    }),
    BottleArchiveExportMissing(:final bottleId) => _bottleNotFoundError(
      bottleId,
    ),
    BottleArchiveExportFailed(:final message) => _jsonError(
      exitCode: 75,
      code: 'bottleArchiveExportFailed',
      message: message,
    ),
  };
}

CliResult _bottleArchiveImportJsonResult(BottleArchiveImportResult result) {
  return switch (result) {
    BottleArchiveImported(:final bottle) => _bottleJsonResult(bottle),
    BottleArchiveImportConflict(:final bottleId) => _jsonError(
      exitCode: 73,
      code: 'bottleAlreadyExists',
      message: 'Bottle already exists.',
      extra: <String, Object?>{'bottleId': bottleId},
    ),
    BottleArchiveImportFailed(:final message) => _jsonError(
      exitCode: 65,
      code: 'invalidBottleArchive',
      message: message,
    ),
  };
}

CliResult _appSettingsJsonResult(AppSettingsRecord settings) {
  return _jsonSuccess(<String, Object?>{'appSettings': settings.toJson()});
}

CliResult _appUpdateJsonResult(AppUpdateRecord update) {
  return _jsonSuccess(<String, Object?>{'appUpdate': update.toJson()});
}

CliResult _appUpdateInstallJsonResult(AppUpdateInstallRecord install) {
  return _jsonSuccess(<String, Object?>{'appUpdateInstall': install.toJson()});
}

CliResult _wineProcessTerminationJsonResult(
  List<WineProcessTerminationRecord> records, {
  String recordsKey = 'bottles',
}) {
  final hasFailures = records.any((record) => record.status != 'terminated');
  return _jsonSuccess(<String, Object?>{
    'wineProcessTermination': <String, Object?>{
      'hasFailures': hasFailures,
      recordsKey: records
          .map((record) => record.toJson())
          .toList(growable: false),
    },
  }, exitCode: hasFailures ? 75 : 0);
}

CliResult _wineProcessListJsonResult(List<WineProcessRecord> records) {
  return _jsonSuccess(<String, Object?>{
    'wineProcesses': <String, Object?>{
      'processes': records
          .map((record) => record.toJson())
          .toList(growable: false),
    },
  });
}

CliResult _programSettingsReadJsonResult({
  required ProgramSettingsRequest request,
  required ProgramSettingsReadResult result,
}) {
  return switch (result) {
    ProgramSettingsRead(:final settings) => _programSettingsJsonResult(
      bottleId: request.bottleId,
      programPath: request.programPath,
      settings: settings,
    ),
    ProgramSettingsReadMissingBottle(:final bottleId) => _bottleNotFoundError(
      bottleId,
    ),
  };
}

CliResult _programSettingsUpdateJsonResult({
  required ProgramSettingsUpdateRequest request,
  required ProgramSettingsUpdateResult result,
}) {
  return switch (result) {
    ProgramSettingsUpdated(:final settings) => _programSettingsJsonResult(
      bottleId: request.bottleId,
      programPath: request.programPath,
      settings: settings,
    ),
    ProgramSettingsUpdateMissingBottle(:final bottleId) => _bottleNotFoundError(
      bottleId,
    ),
  };
}

CliResult _programSettingsJsonResult({
  required String bottleId,
  required String programPath,
  required ProgramSettingsRecord settings,
}) {
  return _jsonSuccess(<String, Object?>{
    'programSettings': <String, Object?>{
      'bottleId': bottleId,
      'programPath': programPath,
      'settings': settings.toJson(),
    },
  });
}

CliResult? _applyRuntimeSettingsRegistryUpdates({
  required BottleRecord bottle,
  required BottleRuntimeSettings runtimeSettings,
  required ProgramRunPlanner programRunPlanner,
  required ProgramRunner? programRunner,
}) {
  return _applyRegistryUpdateRequests(
    requests: programRunPlanner.planRuntimeSettingsRegistryUpdates(
      bottle: bottle,
      currentRuntimeSettings: bottle.runtimeSettings,
      runtimeSettings: runtimeSettings,
    ),
    programRunner: programRunner,
  );
}

CliResult? _syncRuntimeSettingsDllOverrides({
  required BottleRecord bottle,
  required BottleRuntimeSettings runtimeSettings,
  required ProgramRunPlanner programRunPlanner,
}) {
  if (programRunPlanner.hostPlatform != KonyakHostPlatform.macos ||
      !runtimeSettings.dxvk) {
    return null;
  }

  try {
    _syncMacosDxvkDllOverrides(
      bottle: bottle,
      environment: programRunPlanner.environment,
    );
    return null;
  } on FileSystemException catch (error) {
    return _jsonError(
      exitCode: 74,
      code: 'runtimeSettingsDllSyncFailed',
      message: 'Failed to synchronize runtime DLL overrides.',
      extra: <String, Object?>{
        'details': <String, Object?>{
          if (error.path != null) 'path': error.path,
          'osError': error.osError?.message ?? error.message,
        },
      },
    );
  }
}

CliResult? _applyWindowsVersionRegistryUpdates({
  required BottleRecord bottle,
  required String windowsVersion,
  required ProgramRunPlanner programRunPlanner,
  required ProgramRunner? programRunner,
}) {
  return _applyRegistryUpdateRequests(
    requests: programRunPlanner.planWindowsVersionRegistryUpdates(
      bottle: bottle,
      windowsVersion: windowsVersion,
    ),
    programRunner: programRunner,
  );
}

CliResult? _applyRegistryUpdateRequests({
  required Iterable<ProgramRunRequest> requests,
  required ProgramRunner? programRunner,
}) {
  final runner = programRunner;
  if (runner == null) {
    return null;
  }

  for (final request in requests) {
    final result = runner.run(request);
    switch (result) {
      case ProgramRunCompleted(:final processExitCode)
          when processExitCode == 0:
        continue;
      case ProgramRunCompleted(:final processExitCode):
        return _jsonError(
          exitCode: 75,
          code: 'registryUpdateFailed',
          message:
              'Registry update `${request.arguments.join(' ')}` exited with '
              'code $processExitCode.',
          extra: <String, Object?>{'processExitCode': processExitCode},
        );
      case ProgramRunFailed(:final message):
        return _jsonError(
          exitCode: 75,
          code: 'registryUpdateFailed',
          message: message,
        );
    }
  }

  return null;
}

BottleRecord _bottleWithRegistrySettings({
  required BottleRecord bottle,
  required ProgramRunPlanner programRunPlanner,
  required ProgramRunner? programRunner,
}) {
  final runner = programRunner;
  if (runner == null) {
    return bottle;
  }

  var currentBottle = bottle;
  for (final request in programRunPlanner.planBottleSettingsRegistryQueries(
    bottle: bottle,
  )) {
    final result = runner.run(request);
    switch (result) {
      case ProgramRunCompleted(:final processExitCode, :final stdout)
          when processExitCode == 0:
        currentBottle = _bottleWithRegistryValue(
          bottle: currentBottle,
          arguments: request.arguments,
          stdout: stdout,
        );
      case ProgramRunCompleted():
        continue;
      case ProgramRunFailed():
        continue;
    }
  }

  return currentBottle;
}

CliResult _terminateWineProcessesJsonResult({
  required BottleCatalog bottleCatalog,
  required ProgramRunPlanner programRunPlanner,
  required ProgramRunner? programRunner,
  String? bottleId,
}) {
  final runner = programRunner;
  if (runner == null) {
    return _programRunnerUnavailableError();
  }

  final records = <WineProcessTerminationRecord>[];
  final bottles = bottleCatalog.listBottles();
  final targetBottles = bottleId == null
      ? bottles
      : <BottleRecord>[?_findBottle(bottles, bottleId)];
  if (bottleId != null && targetBottles.isEmpty) {
    return _bottleNotFoundError(bottleId);
  }

  for (final bottle in targetBottles) {
    final request = programRunPlanner.planWineProcessTermination(
      bottle: bottle,
    );
    final result = runner.run(request);
    switch (result) {
      case ProgramRunCompleted(:final processExitCode):
        records.add(
          WineProcessTerminationRecord(
            bottleId: bottle.id,
            status: _isSuccessfulWineServerTerminationExit(processExitCode)
                ? 'terminated'
                : 'failed',
            runnerKind: request.runnerKind,
            executable: request.executable,
            argv: request.argv,
            processExitCode: processExitCode,
          ),
        );
      case ProgramRunFailed(:final message):
        records.add(
          WineProcessTerminationRecord(
            bottleId: bottle.id,
            status: 'failed',
            runnerKind: request.runnerKind,
            executable: request.executable,
            argv: request.argv,
            message: message,
          ),
        );
    }
  }

  return _wineProcessTerminationJsonResult(records);
}

bool _isSuccessfulWineServerTerminationExit(int processExitCode) {
  return processExitCode == 0 || processExitCode == 1;
}

CliResult _listWineProcessesJsonResult({
  required BottleCatalog bottleCatalog,
  required ProgramRunPlanner programRunPlanner,
  required ProgramRunner? programRunner,
  required ProgramMetadataExtractor programMetadataExtractor,
}) {
  final runner = programRunner;
  if (runner == null) {
    return _programRunnerUnavailableError();
  }

  final records = <WineProcessRecord>[];
  for (final bottle in bottleCatalog.listBottles()) {
    final request = programRunPlanner.planWineProcessList(bottle: bottle);
    final result = runner.run(request);
    switch (result) {
      case ProgramRunCompleted(:final processExitCode, :final stdout)
          when processExitCode == 0:
        records.addAll(
          _parseWinedbgProcessList(stdout)
              .where((process) {
                return !_isWineInfrastructureProcess(process);
              })
              .map((process) {
                final hostPath = _wineProcessHostPath(
                  bottle: bottle,
                  executable: process.executable,
                );
                final metadata = hostPath == null
                    ? null
                    : programMetadataExtractor.extract(
                        bottle: bottle,
                        programPath: hostPath,
                      );
                return WineProcessRecord(
                  bottleId: bottle.id,
                  processId: process.processId,
                  executable: process.executable,
                  hostPath: hostPath,
                  metadata: metadata,
                );
              }),
        );
      case ProgramRunCompleted(:final processExitCode, :final stderr):
        return _jsonError(
          exitCode: 75,
          code: 'wineProcessListFailed',
          message:
              'Wine process list for `${bottle.id}` exited with code '
              '$processExitCode.',
          extra: <String, Object?>{'diagnostic': stderr},
        );
      case ProgramRunFailed(:final message):
        return _jsonError(
          exitCode: 75,
          code: 'wineProcessListFailed',
          message: message,
        );
    }
  }

  return _wineProcessListJsonResult(records);
}

CliResult _terminateWineProcessJsonResult({
  required BottleCatalog bottleCatalog,
  required ProgramRunPlanner programRunPlanner,
  required ProgramRunner? programRunner,
  required String bottleId,
  required String processId,
}) {
  final runner = programRunner;
  if (runner == null) {
    return _programRunnerUnavailableError();
  }

  final bottle = _findBottle(bottleCatalog.listBottles(), bottleId);
  if (bottle == null) {
    return _bottleNotFoundError(bottleId);
  }

  final request = programRunPlanner.planWineProcessKill(
    bottle: bottle,
    processId: processId,
  );
  final result = runner.run(request);
  final record = switch (result) {
    ProgramRunCompleted(:final processExitCode) => WineProcessTerminationRecord(
      bottleId: bottle.id,
      processId: processId,
      status: processExitCode == 0 ? 'terminated' : 'failed',
      runnerKind: request.runnerKind,
      executable: request.executable,
      argv: request.argv,
      processExitCode: processExitCode,
    ),
    ProgramRunFailed(:final message) => WineProcessTerminationRecord(
      bottleId: bottle.id,
      processId: processId,
      status: 'failed',
      runnerKind: request.runnerKind,
      executable: request.executable,
      argv: request.argv,
      message: message,
    ),
  };

  return _wineProcessTerminationJsonResult(<WineProcessTerminationRecord>[
    record,
  ], recordsKey: 'processes');
}

CliResult _installAppUpdateJsonResult({
  required AppUpdateChecker? appUpdateChecker,
  required AppUpdateInstaller? appUpdateInstaller,
}) {
  final checker = appUpdateChecker;
  if (checker == null) {
    return _unavailableJsonError(
      code: 'appUpdateCheckerUnavailable',
      subject: 'App update checker',
    );
  }

  final installer = appUpdateInstaller;
  if (installer == null) {
    return _unavailableJsonError(
      code: 'appUpdateInstallerUnavailable',
      subject: 'App update installer',
    );
  }

  final updateResult = checker.check();
  return switch (updateResult) {
    AppUpdateCheckCompleted(:final update) when update.status != 'available' =>
      _appUpdateInstallJsonResult(
        AppUpdateInstallRecord(
          appId: update.appId,
          status: update.status,
          currentVersion: update.currentVersion,
          installedVersion: update.currentVersion,
          archiveUrl: update.archiveUrl,
        ),
      ),
    AppUpdateCheckCompleted(:final update) => switch (installer.install(
      update,
    )) {
      AppUpdateInstallCompleted(:final install) => _appUpdateInstallJsonResult(
        install,
      ),
      AppUpdateInstallFailed(:final message) => _jsonError(
        exitCode: 75,
        code: 'appUpdateInstallFailed',
        message: message,
      ),
    },
    AppUpdateCheckFailed(:final message) => _jsonError(
      exitCode: 75,
      code: 'appUpdateCheckFailed',
      message: message,
    ),
  };
}

CliResult _installRuntimeUpdateJsonResult({
  required String runtimeId,
  required RuntimeUpdateChecker? runtimeUpdateChecker,
  required MacosWineInstaller? macosWineInstaller,
  required LinuxWineInstaller? linuxWineInstaller,
}) {
  final checker = runtimeUpdateChecker;
  if (checker == null) {
    return _unavailableJsonError(
      code: 'runtimeUpdateCheckerUnavailable',
      subject: 'Runtime update checker',
    );
  }

  final updateResult = checker.check(runtimeId);
  return switch (updateResult) {
    RuntimeUpdateCheckCompleted(:final update)
        when update.status != 'available' =>
      _jsonError(
        exitCode: 65,
        code: 'runtimeUpdateNotAvailable',
        message: 'Runtime update is not available.',
        extra: <String, Object?>{'runtimeId': runtimeId},
      ),
    RuntimeUpdateCheckCompleted(:final update) => switch (runtimeId) {
      macosWineRuntimeId => switch (macosWineInstaller) {
        null => _unavailableJsonError(
          code: 'macosWineInstallerUnavailable',
          subject: 'macOS Wine installer',
        ),
        final installer => switch (installer.install(
          _macosWineInstallRequestForRuntimeUpdate(update),
        )) {
          MacosWineInstallCompleted(:final runtime) => _runtimeJsonResult(
            runtime,
          ),
          MacosWineInstallFailed(:final message) => _jsonError(
            exitCode: 75,
            code: 'macosWineInstallFailed',
            message: message,
          ),
        },
      },
      linuxWineRuntimeId => switch (linuxWineInstaller) {
        null => _unavailableJsonError(
          code: 'linuxWineInstallerUnavailable',
          subject: 'Linux Wine installer',
        ),
        final installer => switch (installer.install(
          _linuxWineInstallRequestForRuntimeUpdate(update),
        )) {
          LinuxWineInstallCompleted(:final runtime) => _runtimeJsonResult(
            runtime,
          ),
          LinuxWineInstallFailed(:final message) => _jsonError(
            exitCode: 75,
            code: 'linuxWineInstallFailed',
            message: message,
          ),
        },
      },
      _ => _jsonError(
        exitCode: 65,
        code: 'unsupportedRuntimeUpdateInstall',
        message: 'Runtime update installation is not supported.',
        extra: <String, Object?>{'runtimeId': runtimeId},
      ),
    },
    RuntimeUpdateRuntimeNotFound(:final runtimeId) => _jsonError(
      exitCode: 66,
      code: 'runtimeNotFound',
      message: 'Runtime not found.',
      extra: <String, Object?>{'runtimeId': runtimeId},
    ),
    RuntimeUpdateCheckFailed(:final message) => _jsonError(
      exitCode: 75,
      code: 'runtimeUpdateCheckFailed',
      message: message,
    ),
  };
}

CliResult _runtimeJsonResult(RuntimeRecord runtime) {
  return _jsonSuccess(<String, Object?>{'runtime': runtime.toJson()});
}

CliResult _bottleJsonResult(BottleRecord bottle) {
  return _jsonSuccess(<String, Object?>{'bottle': bottle.toJson()});
}

CliResult _macosWineInstallCliResult(MacosWineInstallResult installResult) {
  return switch (installResult) {
    MacosWineInstallCompleted(:final runtime) => _runtimeJsonResult(runtime),
    MacosWineInstallFailed(:final message) => _jsonError(
      exitCode: 75,
      code: 'macosWineInstallFailed',
      message: message,
    ),
  };
}

CliResult _linuxWineInstallCliResult(LinuxWineInstallResult installResult) {
  return switch (installResult) {
    LinuxWineInstallCompleted(:final runtime) => _runtimeJsonResult(runtime),
    LinuxWineInstallFailed(:final message) => _jsonError(
      exitCode: 75,
      code: 'linuxWineInstallFailed',
      message: message,
    ),
  };
}

MacosWineInstallRequest _macosWineInstallRequestForRuntimeUpdate(
  RuntimeUpdateRecord update,
) {
  final archiveUrl = update.archiveUrl;
  final sourceManifestUrl = update.sourceManifestUrl;
  if (sourceManifestUrl != null && sourceManifestUrl.trim().isNotEmpty) {
    return MacosWineInstallRequest.updateInstall(
      sourceManifest: sourceManifestUrl,
      sourceManifestSignature: update.sourceManifestSignatureUrl,
    );
  }
  if (archiveUrl != null && _isRuntimeStackSourceManifestSource(archiveUrl)) {
    return MacosWineInstallRequest.updateInstall(sourceManifest: archiveUrl);
  }

  return MacosWineInstallRequest.updateInstall(archiveUrl: archiveUrl);
}

LinuxWineInstallRequest _linuxWineInstallRequestForRuntimeUpdate(
  RuntimeUpdateRecord update,
) {
  final archiveUrl = update.archiveUrl;
  final sourceManifestUrl = update.sourceManifestUrl;
  if (sourceManifestUrl != null && sourceManifestUrl.trim().isNotEmpty) {
    return LinuxWineInstallRequest.updateInstall(
      sourceManifest: sourceManifestUrl,
      sourceManifestSignature: update.sourceManifestSignatureUrl,
    );
  }
  if (archiveUrl != null && _isRuntimeStackSourceManifestSource(archiveUrl)) {
    return LinuxWineInstallRequest.updateInstall(sourceManifest: archiveUrl);
  }

  return LinuxWineInstallRequest.updateInstall(archiveUrl: archiveUrl);
}

bool _isRuntimeStackSourceManifestSource(String source) {
  final normalized = source.trim().toLowerCase();
  return normalized.endsWith('.json') || normalized.contains('manifest');
}

CliResult? _handleAppCommand(
  List<String> arguments,
  _CliCommandContext context,
) {
  if (_isJsonAppUpdateCheckCommand(arguments)) {
    final checker = context.appUpdateChecker;
    if (checker == null) {
      return _unavailableJsonError(
        code: 'appUpdateCheckerUnavailable',
        subject: 'App update checker',
      );
    }

    return switch (checker.check()) {
      AppUpdateCheckCompleted(:final update) => _appUpdateJsonResult(update),
      AppUpdateCheckFailed(:final message) => _jsonError(
        exitCode: 75,
        code: 'appUpdateCheckFailed',
        message: message,
      ),
    };
  }

  if (_isJsonAppSettingsGetCommand(arguments)) {
    final repository = context.appSettingsRepository;
    if (repository == null) {
      return _appSettingsRepositoryUnavailableError();
    }

    return _appSettingsJsonResult(repository.read());
  }

  final appSettingsUpdate = _parseJsonAppSettingsUpdateRequest(arguments);
  if (appSettingsUpdate != null) {
    final repository = context.appSettingsRepository;
    if (repository == null) {
      return _appSettingsRepositoryUnavailableError();
    }

    return _appSettingsJsonResult(repository.write(appSettingsUpdate));
  }

  if (_isJsonAppUpdateInstallCommand(arguments)) {
    return _installAppUpdateJsonResult(
      appUpdateChecker: context.appUpdateChecker,
      appUpdateInstaller: context.appUpdateInstaller,
    );
  }

  return null;
}

CliResult? _handleHostIntegrationCommand(
  List<String> arguments,
  _CliCommandContext context,
) {
  if (!_isJsonLinuxFileAssociationInstallCommand(arguments)) {
    return null;
  }

  final result = _installLinuxFileAssociations(
    hostPlatform: context.programRunPlanner.hostPlatform,
    environment: context.programRunPlanner.environment,
  );
  return switch (result) {
    _LinuxFileAssociationsInstalled(
      :final desktopEntryPath,
      :final mimeAppsPath,
    ) =>
      _jsonSuccess(<String, Object?>{
        'linuxFileAssociations': <String, Object?>{
          'desktopEntryPath': desktopEntryPath,
          'mimeAppsPath': mimeAppsPath,
          'mimeTypes': _linuxExecutableMimeTypes,
        },
      }),
    _LinuxFileAssociationInstallFailed(:final message) => _jsonError(
      exitCode: 75,
      code: 'linuxFileAssociationInstallFailed',
      message: message,
    ),
  };
}

CliResult _appSettingsRepositoryUnavailableError() {
  return _unavailableJsonError(
    code: 'appSettingsRepositoryUnavailable',
    subject: 'App settings repository',
  );
}

CliResult? _handleRuntimeCommand(
  List<String> arguments,
  _CliCommandContext context,
) {
  if (_isJsonRuntimeListCommand(arguments)) {
    return _jsonSuccess(<String, Object?>{
      'runtimes': context.runtimeCatalog
          .listRuntimes()
          .map((runtime) => runtime.toJson())
          .toList(growable: false),
    });
  }

  if (_isJsonMacosSetupCheckCommand(arguments)) {
    final checker = context.macosSetupChecker;
    if (checker == null) {
      return _unavailableJsonError(
        code: 'macosSetupCheckerUnavailable',
        subject: 'macOS setup checker',
      );
    }

    return switch (checker.check()) {
      MacosSetupCheckCompleted(:final status) => _jsonSuccess(<String, Object?>{
        'macosSetup': status.toJson(),
      }),
      MacosSetupCheckFailed(:final message) => _jsonError(
        exitCode: 75,
        code: 'macosSetupCheckFailed',
        message: message,
      ),
    };
  }

  final gptkWineInstallRequest = _parseJsonGptkWineInstallRequest(arguments);
  if (gptkWineInstallRequest != null) {
    final installer = context.gptkWineInstaller;
    if (installer == null) {
      return _unavailableJsonError(
        code: 'gptkWineInstallerUnavailable',
        subject: 'GPTK-compatible Wine installer',
      );
    }

    return switch (installer.install(gptkWineInstallRequest)) {
      GptkWineInstallCompleted(:final record) => _jsonSuccess(<String, Object?>{
        'gptkWineInstall': record.toJson(),
      }),
      GptkWineInstallFailed(:final message) => _jsonError(
        exitCode: 75,
        code: 'gptkWineInstallFailed',
        message: message,
      ),
    };
  }

  final openUrl = _parseJsonOpenUrlCommand(arguments);
  if (openUrl != null) {
    return _openUrlJsonResult(openUrl, context.pathOpener);
  }

  final runtimeUpdateId = _parseJsonRuntimeIdCommand(
    arguments,
    'check-runtime-update',
  );
  if (runtimeUpdateId != null) {
    return _runtimeUpdateCheckJsonResult(
      runtimeId: runtimeUpdateId,
      runtimeUpdateChecker: context.runtimeUpdateChecker,
    );
  }

  final runtimeUpdateInstallId = _parseJsonRuntimeIdCommand(
    arguments,
    'install-runtime-update',
  );
  if (runtimeUpdateInstallId != null) {
    return _installRuntimeUpdateJsonResult(
      runtimeId: runtimeUpdateInstallId,
      runtimeUpdateChecker: context.runtimeUpdateChecker,
      macosWineInstaller: context.macosWineInstaller,
      linuxWineInstaller: context.linuxWineInstaller,
    );
  }

  final runtimeValidationId = _parseJsonRuntimeIdCommand(
    arguments,
    'validate-runtime',
  );
  if (runtimeValidationId != null) {
    return _runtimeValidationJsonResult(
      runtimeId: runtimeValidationId,
      runtimeValidator: context.runtimeValidator,
    );
  }

  final macosWineInstallRequest = _parseJsonMacosWineInstallRequest(arguments);
  if (macosWineInstallRequest != null) {
    return _macosWineInstallJsonResult(
      request: macosWineInstallRequest,
      installer: context.macosWineInstaller,
      progressSink: context.runtimeInstallProgressSink,
    );
  }

  final linuxWineInstallRequest = _parseJsonLinuxWineInstallRequest(arguments);
  if (linuxWineInstallRequest != null) {
    return _linuxWineInstallJsonResult(
      request: linuxWineInstallRequest,
      installer: context.linuxWineInstaller,
      progressSink: context.runtimeInstallProgressSink,
    );
  }

  return null;
}

CliResult _openUrlJsonResult(String openUrl, PathOpener? pathOpener) {
  if (pathOpener == null) {
    return _pathOpenerUnavailableError();
  }
  final openResult = pathOpener.openPath(openUrl);
  return switch (openResult) {
    PathOpenCompleted() => _jsonSuccess(<String, Object?>{
      'openedUrl': <String, Object?>{'url': openUrl},
    }),
    PathOpenFailed(:final message) => _jsonError(
      exitCode: 75,
      code: 'urlOpenFailed',
      message: message,
      extra: <String, Object?>{'url': openUrl},
    ),
  };
}

CliResult _runtimeUpdateCheckJsonResult({
  required String runtimeId,
  required RuntimeUpdateChecker? runtimeUpdateChecker,
}) {
  if (runtimeUpdateChecker == null) {
    return _unavailableJsonError(
      code: 'runtimeUpdateCheckerUnavailable',
      subject: 'Runtime update checker',
    );
  }

  return switch (runtimeUpdateChecker.check(runtimeId)) {
    RuntimeUpdateCheckCompleted(:final update) => _jsonSuccess(
      <String, Object?>{'runtimeUpdate': update.toJson()},
    ),
    RuntimeUpdateRuntimeNotFound(:final runtimeId) => _jsonError(
      exitCode: 66,
      code: 'runtimeNotFound',
      message: 'Runtime not found.',
      extra: <String, Object?>{'runtimeId': runtimeId},
    ),
    RuntimeUpdateCheckFailed(:final message) => _jsonError(
      exitCode: 75,
      code: 'runtimeUpdateCheckFailed',
      message: message,
    ),
  };
}

CliResult _runtimeValidationJsonResult({
  required String runtimeId,
  required RuntimeValidator? runtimeValidator,
}) {
  if (runtimeValidator == null) {
    return _unavailableJsonError(
      code: 'runtimeValidatorUnavailable',
      subject: 'Runtime validator',
    );
  }

  return switch (runtimeValidator.validate(runtimeId)) {
    RuntimeValidationCompleted(:final validation) => _jsonSuccess(
      <String, Object?>{'runtimeValidation': validation.toJson()},
      exitCode: validation.isValid ? 0 : 75,
    ),
    RuntimeValidationRuntimeNotFound(:final runtimeId) => _jsonError(
      exitCode: 66,
      code: 'runtimeNotFound',
      message: 'Runtime not found.',
      extra: <String, Object?>{'runtimeId': runtimeId},
    ),
    RuntimeValidationFailed(:final message) => _jsonError(
      exitCode: 75,
      code: 'runtimeValidationFailed',
      message: message,
    ),
  };
}

CliResult _macosWineInstallJsonResult({
  required MacosWineInstallRequest request,
  required MacosWineInstaller? installer,
  required RuntimeInstallProgressSink? progressSink,
}) {
  if (installer == null) {
    return _unavailableJsonError(
      code: 'macosWineInstallerUnavailable',
      subject: 'macOS Wine installer',
    );
  }

  return _macosWineInstallCliResult(
    installer.install(
      request,
      progressSink: request.emitProgress ? progressSink : null,
    ),
  );
}

CliResult _linuxWineInstallJsonResult({
  required LinuxWineInstallRequest request,
  required LinuxWineInstaller? installer,
  required RuntimeInstallProgressSink? progressSink,
}) {
  if (installer == null) {
    return _unavailableJsonError(
      code: 'linuxWineInstallerUnavailable',
      subject: 'Linux Wine installer',
    );
  }

  return _linuxWineInstallCliResult(
    installer.install(
      request,
      progressSink: request.emitProgress ? progressSink : null,
    ),
  );
}

CliResult? _handleWineProcessCommand(
  List<String> arguments, {
  required _CliCommandContext context,
  required BottleCatalog activeBottleCatalog,
}) {
  if (_isJsonWineProcessListCommand(arguments)) {
    return _listWineProcessesJsonResult(
      bottleCatalog: activeBottleCatalog,
      programRunPlanner: context.programRunPlanner,
      programRunner: context.programRunner,
      programMetadataExtractor: context.programMetadataExtractor,
    );
  }

  final wineProcessTerminationRequest = _parseJsonWineProcessTerminationRequest(
    arguments,
  );
  if (wineProcessTerminationRequest != null) {
    return _terminateWineProcessJsonResult(
      bottleCatalog: activeBottleCatalog,
      programRunPlanner: context.programRunPlanner,
      programRunner: context.programRunner,
      bottleId: wineProcessTerminationRequest.bottleId,
      processId: wineProcessTerminationRequest.processId,
    );
  }

  final wineProcessGroupTerminationRequest =
      _parseJsonWineProcessGroupTerminationRequest(arguments);
  if (wineProcessGroupTerminationRequest != null) {
    return _terminateWineProcessesJsonResult(
      bottleCatalog: activeBottleCatalog,
      programRunPlanner: context.programRunPlanner,
      programRunner: context.programRunner,
      bottleId: wineProcessGroupTerminationRequest.bottleId,
    );
  }

  return null;
}

CliResult? _handleBottleReadCommand(
  List<String> arguments, {
  required _CliCommandContext context,
  required BottleCatalog activeBottleCatalog,
}) {
  if (_isJsonBottleListCommand(arguments)) {
    final bottles = activeBottleCatalog.listBottles();
    _synchronizeMacosPinnedProgramLaunchers(
      hostPlatform: context.programRunPlanner.hostPlatform,
      environment: context.programRunPlanner.environment,
      bottles: bottles,
    );
    return _jsonSuccess(<String, Object?>{
      'bottles': bottles
          .map((bottle) => bottle.toJson())
          .toList(growable: false),
    });
  }

  if (_isJsonBottleInspectCommand(arguments)) {
    final bottleId = arguments[1];
    final bottle = activeBottleCatalog.findBottle(bottleId);
    if (bottle == null) {
      return _bottleNotFoundError(bottleId);
    }

    final inspectedBottle = _bottleWithRegistrySettings(
      bottle: bottle,
      programRunPlanner: context.programRunPlanner,
      programRunner: context.programRunner,
    );
    return _bottleJsonResult(inspectedBottle);
  }

  final bottleProgramsListId = _parseJsonBottleProgramsListCommand(arguments);
  if (bottleProgramsListId != null) {
    final bottle = activeBottleCatalog.findBottle(bottleProgramsListId);
    if (bottle == null) {
      return _bottleNotFoundError(bottleProgramsListId);
    }

    return _jsonSuccess(<String, Object?>{
      'bottlePrograms': <String, Object?>{
        'bottleId': bottle.id,
        'programs': context.bottleProgramRepository
            .listPrograms(bottle)
            .map((program) => program.toJson())
            .toList(growable: false),
      },
    });
  }

  return null;
}

CliResult? _handleBottleMutationCommand(
  List<String> arguments,
  _CliCommandContext context,
) {
  final createBottleRequest = _parseJsonBottleCreateRequest(arguments);
  if (createBottleRequest != null) {
    final repository = context.bottleRepository;
    if (repository == null) {
      return _bottleRepositoryUnavailableError();
    }

    return switch (repository.createBottle(createBottleRequest)) {
      BottleCreated(:final bottle) => _createdBottleJsonResult(
        bottle: bottle,
        bottlePrefixInitializer: context.bottlePrefixInitializer,
      ),
      BottleCreateConflict(:final bottleId) => _jsonError(
        exitCode: 73,
        code: 'bottleAlreadyExists',
        message: 'Bottle already exists.',
        extra: <String, Object?>{'bottleId': bottleId},
      ),
    };
  }

  final bottleArchiveExportRequest = _parseJsonBottleArchiveExportRequest(
    arguments,
  );
  if (bottleArchiveExportRequest != null) {
    final repository = context.bottleRepository;
    if (repository == null) {
      return _bottleRepositoryUnavailableError();
    }

    return _bottleArchiveExportJsonResult(
      repository.exportBottleArchive(bottleArchiveExportRequest),
    );
  }

  final bottleArchiveImportRequest = _parseJsonBottleArchiveImportRequest(
    arguments,
  );
  if (bottleArchiveImportRequest != null) {
    final repository = context.bottleRepository;
    if (repository == null) {
      return _bottleRepositoryUnavailableError();
    }

    return _bottleArchiveImportJsonResult(
      repository.importBottleArchive(bottleArchiveImportRequest),
    );
  }

  final deleteBottleId = _parseJsonBottleDeleteCommand(arguments);
  if (deleteBottleId != null) {
    final repository = context.bottleRepository;
    if (repository == null) {
      return _bottleRepositoryUnavailableError();
    }

    return switch (repository.deleteBottle(deleteBottleId)) {
      BottleDeleted(:final bottle) => _jsonSuccess(<String, Object?>{
        'deletedBottle': bottle.toJson(),
      }),
      BottleDeleteMissing(:final bottleId) => _bottleNotFoundError(bottleId),
    };
  }

  final renameBottleRequest = _parseJsonBottleRenameRequest(arguments);
  if (renameBottleRequest != null) {
    final repository = context.bottleRepository;
    if (repository == null) {
      return _bottleRepositoryUnavailableError();
    }

    return switch (repository.renameBottle(renameBottleRequest)) {
      BottleRenamed(:final bottle) => _bottleJsonResult(bottle),
      BottleRenameMissing(:final bottleId) => _bottleNotFoundError(bottleId),
      BottleRenameConflict(:final bottleId) => _jsonError(
        exitCode: 73,
        code: 'bottleAlreadyExists',
        message: 'Bottle already exists.',
        extra: <String, Object?>{'bottleId': bottleId},
      ),
    };
  }

  final moveBottleRequest = _parseJsonBottleMoveRequest(arguments);
  if (moveBottleRequest != null) {
    final repository = context.bottleRepository;
    if (repository == null) {
      return _bottleRepositoryUnavailableError();
    }

    return switch (repository.moveBottle(moveBottleRequest)) {
      BottleMoved(:final bottle) => _bottleJsonResult(bottle),
      BottleMoveMissing(:final bottleId) => _bottleNotFoundError(bottleId),
      BottleMoveConflict(:final path) => _jsonError(
        exitCode: 73,
        code: 'bottleMoveDestinationExists',
        message: 'Bottle move destination exists.',
        extra: <String, Object?>{'path': path},
      ),
    };
  }

  return null;
}

CliResult _bottleRepositoryUnavailableError() {
  return _unavailableJsonError(
    code: 'bottleRepositoryUnavailable',
    subject: 'Bottle repository',
  );
}

CliResult? _handleBottleConfigurationCommand(
  List<String> arguments,
  _CliCommandContext context,
) {
  final windowsVersionUpdateRequest = _parseJsonWindowsVersionUpdateRequest(
    arguments,
  );
  if (windowsVersionUpdateRequest != null) {
    final repository = context.bottleRepository;
    if (repository == null) {
      return _bottleRepositoryUnavailableError();
    }

    final bottle = repository.findBottle(windowsVersionUpdateRequest.bottleId);
    if (bottle == null) {
      return _bottleNotFoundError(windowsVersionUpdateRequest.bottleId);
    }

    final registryUpdateFailure = _applyWindowsVersionRegistryUpdates(
      bottle: bottle,
      windowsVersion: windowsVersionUpdateRequest.windowsVersion,
      programRunPlanner: context.programRunPlanner,
      programRunner: context.programRunner,
    );
    if (registryUpdateFailure != null) {
      return registryUpdateFailure;
    }

    return _bottleUpdateJsonResult(
      repository.setWindowsVersion(windowsVersionUpdateRequest),
    );
  }

  final runtimeSettingsUpdateRequest = _parseJsonRuntimeSettingsUpdateRequest(
    arguments,
  );
  if (runtimeSettingsUpdateRequest != null) {
    final repository = context.bottleRepository;
    if (repository == null) {
      return _bottleRepositoryUnavailableError();
    }

    final bottle = repository.findBottle(runtimeSettingsUpdateRequest.bottleId);
    if (bottle == null) {
      return _bottleNotFoundError(runtimeSettingsUpdateRequest.bottleId);
    }

    final registryUpdateFailure = _applyRuntimeSettingsRegistryUpdates(
      bottle: bottle,
      runtimeSettings: runtimeSettingsUpdateRequest.runtimeSettings,
      programRunPlanner: context.programRunPlanner,
      programRunner: context.programRunner,
    );
    if (registryUpdateFailure != null) {
      return registryUpdateFailure;
    }

    final dllSyncFailure = _syncRuntimeSettingsDllOverrides(
      bottle: bottle,
      runtimeSettings: runtimeSettingsUpdateRequest.runtimeSettings,
      programRunPlanner: context.programRunPlanner,
    );
    if (dllSyncFailure != null) {
      return dllSyncFailure;
    }

    return _bottleUpdateJsonResult(
      repository.setRuntimeSettings(runtimeSettingsUpdateRequest),
    );
  }

  return null;
}

CliResult _bottleUpdateJsonResult(BottleUpdateResult result) {
  return switch (result) {
    BottleUpdated(:final bottle) => _bottleJsonResult(bottle),
    BottleUpdateMissing(:final bottleId) => _bottleNotFoundError(bottleId),
  };
}

CliResult? _handlePinnedProgramCommand(
  List<String> arguments,
  _CliCommandContext context,
) {
  final programPinRequest = _parseJsonProgramPinRequest(arguments);
  if (programPinRequest != null) {
    if (!_isSupportedProgramPath(programPinRequest.programPath)) {
      return _jsonError(
        exitCode: 65,
        code: 'unsupportedProgramType',
        message: 'Program type is not supported.',
        extra: <String, Object?>{'programPath': programPinRequest.programPath},
      );
    }

    final repository = context.bottleRepository;
    if (repository == null) {
      return _bottleRepositoryUnavailableError();
    }

    final pinResult = repository.pinProgram(programPinRequest);
    if (pinResult is ProgramPinned) {
      _synchronizeMacosPinnedProgramLaunchers(
        hostPlatform: context.programRunPlanner.hostPlatform,
        environment: context.programRunPlanner.environment,
        bottles: repository.listBottles(),
      );
    }

    return switch (pinResult) {
      ProgramPinned(:final bottle) => _bottleJsonResult(bottle),
      ProgramPinMissing(:final bottleId) => _bottleNotFoundError(bottleId),
      ProgramPinConflict(:final programPath) => _jsonError(
        exitCode: 73,
        code: 'programAlreadyPinned',
        message: 'Program is already pinned.',
        extra: <String, Object?>{'programPath': programPath},
      ),
    };
  }

  final programUnpinRequest = _parseJsonProgramUnpinRequest(arguments);
  if (programUnpinRequest != null) {
    final repository = context.bottleRepository;
    if (repository == null) {
      return _bottleRepositoryUnavailableError();
    }

    final updateResult = repository.unpinProgram(programUnpinRequest);
    if (updateResult is ProgramUpdated) {
      _synchronizeMacosPinnedProgramLaunchers(
        hostPlatform: context.programRunPlanner.hostPlatform,
        environment: context.programRunPlanner.environment,
        bottles: repository.listBottles(),
      );
    }

    return _programUpdateJsonResult(updateResult);
  }

  final programRenameRequest = _parseJsonProgramRenameRequest(arguments);
  if (programRenameRequest != null) {
    final repository = context.bottleRepository;
    if (repository == null) {
      return _bottleRepositoryUnavailableError();
    }

    final updateResult = repository.renamePinnedProgram(programRenameRequest);
    if (updateResult is ProgramUpdated) {
      _synchronizeMacosPinnedProgramLaunchers(
        hostPlatform: context.programRunPlanner.hostPlatform,
        environment: context.programRunPlanner.environment,
        bottles: repository.listBottles(),
      );
    }

    return _programUpdateJsonResult(updateResult);
  }

  final pinnedProgramLaunchCliRequest = _parseJsonPinnedProgramLaunchCliRequest(
    arguments,
  );
  if (pinnedProgramLaunchCliRequest != null) {
    return _runPinnedProgramLauncherCli(
      request: pinnedProgramLaunchCliRequest,
      bottleRepository: context.bottleRepository,
      programRunPlanner: context.programRunPlanner,
      programRunner: context.programRunner,
    );
  }

  return null;
}

CliResult? _handleProgramSettingsCommand(
  List<String> arguments,
  _CliCommandContext context,
) {
  final programSettingsRequest = _parseJsonProgramSettingsRequest(arguments);
  if (programSettingsRequest != null) {
    final repository = context.bottleRepository;
    if (repository == null) {
      return _bottleRepositoryUnavailableError();
    }

    return _programSettingsReadJsonResult(
      request: programSettingsRequest,
      result: repository.readProgramSettings(programSettingsRequest),
    );
  }

  final programSettingsUpdateRequest = _parseJsonProgramSettingsUpdateRequest(
    arguments,
  );
  if (programSettingsUpdateRequest != null) {
    final repository = context.bottleRepository;
    if (repository == null) {
      return _bottleRepositoryUnavailableError();
    }

    return _programSettingsUpdateJsonResult(
      request: programSettingsUpdateRequest,
      result: repository.setProgramSettings(programSettingsUpdateRequest),
    );
  }

  return null;
}

CliResult? _handleProgramRunCommand(
  List<String> arguments,
  _CliCommandContext context,
) {
  final programRunCliRequest = _parseJsonProgramRunCliRequest(arguments);
  if (programRunCliRequest != null) {
    return _runProgramJsonResult(programRunCliRequest, context);
  }

  final winetricksRunCliRequest = _parseJsonWinetricksRunCliRequest(arguments);
  if (winetricksRunCliRequest != null) {
    return _runWinetricksJsonResult(winetricksRunCliRequest, context);
  }

  final bottleCommandRunCliRequest = _parseJsonBottleCommandRunCliRequest(
    arguments,
  );
  if (bottleCommandRunCliRequest != null) {
    return _runBottleCommandJsonResult(bottleCommandRunCliRequest, context);
  }

  return null;
}

CliResult _runProgramJsonResult(
  _ProgramRunCliRequest request,
  _CliCommandContext context,
) {
  final repository = context.bottleRepository;
  if (repository == null) {
    return _bottleRepositoryUnavailableError();
  }

  final runner = context.programRunner;
  if (runner == null) {
    return _programRunnerUnavailableError();
  }

  final bottle = repository.findBottle(request.bottleId);
  if (bottle == null) {
    return _bottleNotFoundError(request.bottleId);
  }

  final settingsResult = repository.readProgramSettings(
    ProgramSettingsRequest(
      bottleId: bottle.id,
      programPath: request.programPath,
    ),
  );
  final programSettings = switch (settingsResult) {
    ProgramSettingsRead(:final settings) => settings,
    ProgramSettingsReadMissingBottle() => const ProgramSettingsRecord(),
  };

  final programRunRequest = context.programRunPlanner.plan(
    bottle: bottle,
    programPath: request.programPath,
    programSettings: programSettings,
  );
  if (programRunRequest == null) {
    return _jsonError(
      exitCode: 65,
      code: 'unsupportedProgramType',
      message: 'Program type is not supported.',
      extra: <String, Object?>{'programPath': request.programPath},
    );
  }

  _recordExternalProgramRun(bottle: bottle, request: programRunRequest);
  _synchronizeLinuxDesktopLauncherForProgramRun(
    hostPlatform: context.programRunPlanner.hostPlatform,
    environment: context.programRunPlanner.environment,
    bottle: bottle,
    request: programRunRequest,
  );

  return _programRunResultJson(programRunRequest, runner);
}

CliResult _runWinetricksJsonResult(
  _WinetricksRunCliRequest request,
  _CliCommandContext context,
) {
  final repository = context.bottleRepository;
  if (repository == null) {
    return _bottleRepositoryUnavailableError();
  }

  final runner = context.programRunner;
  if (runner == null) {
    return _programRunnerUnavailableError();
  }

  final bottle = repository.findBottle(request.bottleId);
  if (bottle == null) {
    return _bottleNotFoundError(request.bottleId);
  }

  final programRunRequest = context.programRunPlanner.planWinetricksVerb(
    bottle: bottle,
    verb: request.verb,
  );
  if (programRunRequest == null) {
    return _jsonError(
      exitCode: 65,
      code: 'unsupportedWinetricksVerb',
      message: 'Winetricks verb is not supported.',
      extra: <String, Object?>{'verb': request.verb},
    );
  }

  final winetricksReady = _ensureWinetricksScriptForRun(
    request: programRunRequest,
    scriptInstaller: context.winetricksScriptInstaller,
  );
  if (winetricksReady != null) {
    return winetricksReady;
  }

  return _programRunResultJson(programRunRequest, runner);
}

CliResult _runBottleCommandJsonResult(
  _BottleCommandRunCliRequest request,
  _CliCommandContext context,
) {
  final repository = context.bottleRepository;
  if (repository == null) {
    return _bottleRepositoryUnavailableError();
  }

  final runner = context.programRunner;
  if (runner == null) {
    return _programRunnerUnavailableError();
  }

  final bottle = repository.findBottle(request.bottleId);
  if (bottle == null) {
    return _bottleNotFoundError(request.bottleId);
  }

  final programRunRequest = context.programRunPlanner.planBottleCommand(
    bottle: bottle,
    command: request.command,
  );
  if (programRunRequest == null) {
    return _jsonError(
      exitCode: 65,
      code: 'unsupportedBottleCommand',
      message: 'Bottle command is not supported.',
      extra: <String, Object?>{'command': request.command},
    );
  }

  final winetricksReady = _ensureWinetricksScriptForRun(
    request: programRunRequest,
    scriptInstaller: context.winetricksScriptInstaller,
  );
  if (winetricksReady != null) {
    return winetricksReady;
  }

  return _programRunResultJson(programRunRequest, runner);
}

CliResult _programRunResultJson(
  ProgramRunRequest request,
  ProgramRunner runner,
) {
  return switch (runner.run(request)) {
    ProgramRunCompleted(:final processExitCode) => _programRunJsonResult(
      request: request,
      processExitCode: processExitCode,
    ),
    ProgramRunFailed(:final message) => _programRunFailedJsonResult(
      request: request,
      message: message,
    ),
  };
}

CliResult _programRunnerUnavailableError() {
  return _unavailableJsonError(
    code: 'programRunnerUnavailable',
    subject: 'Program runner',
  );
}

CliResult? _handleLocationCommand(
  List<String> arguments,
  _CliCommandContext context,
) {
  final bottleLocationOpenCliRequest = _parseJsonBottleLocationOpenCliRequest(
    arguments,
  );
  if (bottleLocationOpenCliRequest != null) {
    return _openBottleLocationJsonResult(bottleLocationOpenCliRequest, context);
  }

  final programLocationOpenCliRequest = _parseJsonProgramLocationOpenCliRequest(
    arguments,
  );
  if (programLocationOpenCliRequest != null) {
    return _openProgramLocationJsonResult(
      programLocationOpenCliRequest,
      context,
    );
  }

  return null;
}

CliResult _openBottleLocationJsonResult(
  _BottleLocationOpenCliRequest request,
  _CliCommandContext context,
) {
  final repository = context.bottleRepository;
  if (repository == null) {
    return _bottleRepositoryUnavailableError();
  }

  final opener = context.pathOpener;
  if (opener == null) {
    return _pathOpenerUnavailableError();
  }

  final bottle = repository.findBottle(request.bottleId);
  if (bottle == null) {
    return _bottleNotFoundError(request.bottleId);
  }

  final path = _bottleLocationPath(bottle: bottle, location: request.location);
  if (path == null) {
    return _jsonError(
      exitCode: 65,
      code: 'unsupportedBottleLocation',
      message: 'Bottle location is not supported.',
      extra: <String, Object?>{'location': request.location},
    );
  }

  return switch (opener.openPath(path)) {
    PathOpenCompleted() => _jsonSuccess(<String, Object?>{
      'openedLocation': <String, Object?>{
        'bottleId': bottle.id,
        'location': request.location,
        'path': path,
      },
    }),
    PathOpenFailed(:final message) => _jsonError(
      exitCode: 75,
      code: 'bottleLocationOpenFailed',
      message: message,
      extra: <String, Object?>{
        'bottleId': bottle.id,
        'location': request.location,
        'path': path,
      },
    ),
  };
}

CliResult _openProgramLocationJsonResult(
  _ProgramLocationOpenCliRequest request,
  _CliCommandContext context,
) {
  final repository = context.bottleRepository;
  if (repository == null) {
    return _bottleRepositoryUnavailableError();
  }

  final opener = context.pathOpener;
  if (opener == null) {
    return _pathOpenerUnavailableError();
  }

  final bottle = repository.findBottle(request.bottleId);
  if (bottle == null) {
    return _bottleNotFoundError(request.bottleId);
  }

  if (!_hasPinnedProgram(bottle, request.programPath)) {
    return _jsonError(
      exitCode: 66,
      code: 'programNotPinned',
      message: 'Program is not pinned.',
      extra: <String, Object?>{'programPath': request.programPath},
    );
  }

  final path = request.programPath;
  return switch (opener.revealPath(path)) {
    PathOpenCompleted() => _jsonSuccess(<String, Object?>{
      'openedProgramLocation': <String, Object?>{
        'bottleId': bottle.id,
        'programPath': request.programPath,
        'path': path,
      },
    }),
    PathOpenFailed(:final message) => _jsonError(
      exitCode: 75,
      code: 'programLocationOpenFailed',
      message: message,
      extra: <String, Object?>{
        'bottleId': bottle.id,
        'programPath': request.programPath,
        'path': path,
      },
    ),
  };
}

CliResult _pathOpenerUnavailableError() {
  return _unavailableJsonError(
    code: 'pathOpenerUnavailable',
    subject: 'Path opener',
  );
}

CliResult? _handleWinetricksVerbCommand(
  List<String> arguments,
  _CliCommandContext context,
) {
  if (!_isJsonWinetricksVerbListCommand(arguments)) {
    return null;
  }

  return _winetricksVerbListJsonResult(
    context.winetricksVerbRepository.listVerbs(),
  );
}

CliResult _winetricksVerbListJsonResult(WinetricksVerbListResult result) {
  return switch (result) {
    WinetricksVerbListCompleted(:final categories) => _jsonSuccess(
      <String, Object?>{
        'winetricks': <String, Object?>{
          'categories': categories
              .map((category) => category.toJson())
              .toList(growable: false),
        },
      },
    ),
    WinetricksVerbListFailed(:final message) => _jsonError(
      exitCode: 75,
      code: 'winetricksVerbsUnavailable',
      message: message,
    ),
  };
}

typedef _CliCommandHandler = CliResult? Function();

CliResult? _firstCliResult(Iterable<_CliCommandHandler> handlers) {
  for (final handler in handlers) {
    final result = handler();
    if (result != null) {
      return result;
    }
  }

  return null;
}

CliResult _runCli(List<String> arguments, _CliCommandContext context) {
  final bottleCatalog = context.bottleCatalog;
  final bottleRepository = context.bottleRepository;
  final activeBottleCatalog = bottleRepository ?? bottleCatalog;

  final commandResult = _firstCliResult(<_CliCommandHandler>[
    () => _handleAppCommand(arguments, context),
    () => _handleHostIntegrationCommand(arguments, context),
    () => _handleWineProcessCommand(
      arguments,
      context: context,
      activeBottleCatalog: activeBottleCatalog,
    ),
    () => _handleBottleReadCommand(
      arguments,
      context: context,
      activeBottleCatalog: activeBottleCatalog,
    ),
    () => _handleWinetricksVerbCommand(arguments, context),
    () => _handleBottleMutationCommand(arguments, context),
    () => _handleBottleConfigurationCommand(arguments, context),
    () => _handlePinnedProgramCommand(arguments, context),
    () => _handleProgramSettingsCommand(arguments, context),
    () => _handleProgramRunCommand(arguments, context),
    () => _handleLocationCommand(arguments, context),
    () => _handleRuntimeCommand(arguments, context),
  ]);
  if (commandResult != null) {
    return commandResult;
  }

  return const CliResult(
    exitCode: 64,
    stdout: '',
    stderr: '''
Usage:
  konyak check-app-update --json
  konyak install-app-update --json
  konyak get-app-settings --json
  konyak set-app-settings --settings-json <json> --json
  konyak install-linux-file-associations --json
  konyak list-wine-processes --json
  konyak terminate-wine-process --bottle <id> --process <pid> --json
  konyak terminate-wine-processes [--bottle <id>] --json
  konyak list-bottles --json
  konyak inspect-bottle <id> --json
  konyak list-bottle-programs <id> --json
  konyak list-winetricks-verbs --json
  konyak create-bottle --name <name> [--windows-version <version>] --json
  konyak export-bottle-archive <id> --archive <path> --json
  konyak import-bottle-archive --archive <path> --json
  konyak delete-bottle <id> --json
  konyak rename-bottle <id> --name <name> --json
  konyak move-bottle <id> --path <path> --json
  konyak set-windows-version <id> --windows-version <version> --json
  konyak set-runtime-settings <id> --settings-json <json> --json
  konyak pin-program <id> --name <name> --program <path> --json
  konyak unpin-program <id> --program <path> --json
  konyak rename-pinned-program <id> --program <path> --name <name> --json
  konyak get-program-settings <id> --program <path> --json
  konyak set-program-settings <id> --program <path> --settings-json <json> --json
  konyak launch-pinned-program --manifest <path> --json
  konyak run-program <id> --program <path> --json
  konyak run-winetricks <id> --verb <verb> --json
  konyak run-bottle-command <id> --command <winecfg|regedit|control|terminal|winetricks> --json
  konyak open-bottle-location <id> --location <root|c-drive> --json
  konyak open-program-location <id> --program <path> --json
  konyak list-runtimes --json
  konyak check-macos-setup --json
  konyak install-gptk-wine --from <path> --json
  konyak open-url <https-url> --json
  konyak check-runtime-update <id> --json
  konyak install-runtime-update <id> --json
  konyak validate-runtime <id> --json
  konyak install-linux-wine [--archive <path> | --archive-url <url>] [--archive-sha256 <sha256>] [--component-archive <path> ...] [--source-manifest <path-or-url>] --json
  konyak install-macos-wine [--source-manifest <path-or-url> | --archive <path> [--archive-sha256 <sha256>] [--component-archive <path> ...] | --archive-url <url> [--component-archive <path> ...]] --json
''',
  );
}
