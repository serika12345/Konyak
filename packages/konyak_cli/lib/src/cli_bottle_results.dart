part of '../konyak_cli.dart';

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

CliResult _bottleRepositoryFailureJsonResult(String message) {
  return _jsonError(
    exitCode: 74,
    code: 'bottleRepositoryError',
    message: message,
  );
}

CliResult _bottleCatalogFailureJsonResult(String message) {
  return _bottleRepositoryFailureJsonResult(message);
}

CliResult _foundBottleJsonResult({
  required IoResult<Option<BottleRecord>> result,
  required String bottleId,
  required CliResult Function(BottleRecord bottle) onFound,
}) {
  return result.fold(
    _bottleCatalogFailureJsonResult,
    (bottle) => bottle.match(() => _bottleNotFoundError(bottleId), onFound),
  );
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

  final syncResult = _ioResult(() {
    _syncMacosDxvkDllOverrides(
      bottle: bottle,
      environment: programRunPlanner.environment,
    );
  });
  final failureMessage = syncResult.fold<String?>(
    (message) => message,
    (_) => null,
  );
  if (failureMessage != null) {
    return _jsonError(
      exitCode: 74,
      code: 'runtimeSettingsDllSyncFailed',
      message: 'Failed to synchronize runtime DLL overrides.',
      extra: <String, Object?>{
        'details': <String, Object?>{'message': failureMessage},
      },
    );
  }

  return null;
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

CliResult _bottleJsonResult(BottleRecord bottle) {
  return _jsonSuccess(<String, Object?>{'bottle': bottle.toJson()});
}
