part of '../konyak_cli.dart';

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
