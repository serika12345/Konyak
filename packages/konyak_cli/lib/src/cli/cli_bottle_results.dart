part of '../../konyak_cli.dart';

CliResult _bottleArchiveExportJsonResult(BottleArchiveExportResult result) {
  return switch (result) {
    BottleArchiveExported(:final archive) => _jsonSuccess(<String, Object?>{
      'bottleArchive': archive.toJson(),
    }),
    BottleArchiveExportMissing(:final bottleId) => _bottleNotFoundError(
      bottleId.value,
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
      extra: <String, Object?>{'bottleId': bottleId.value},
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

sealed class _CliSideEffectResult {
  const _CliSideEffectResult();
}

final class _CliSideEffectSucceeded extends _CliSideEffectResult {
  const _CliSideEffectSucceeded();
}

final class _CliSideEffectFailed extends _CliSideEffectResult {
  const _CliSideEffectFailed(this.result);

  final CliResult result;
}

_CliSideEffectResult _applyRuntimeSettingsRegistryUpdates({
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

_CliSideEffectResult _syncRuntimeSettingsDllOverrides({
  required BottleRecord bottle,
  required BottleRuntimeSettings runtimeSettings,
  required ProgramRunPlanner programRunPlanner,
}) {
  if (programRunPlanner.hostPlatform != KonyakHostPlatform.macos) {
    return const _CliSideEffectSucceeded();
  }

  final syncResult = _ioResult(() {
    _removeMacosD3DTranslationDllOverrides(bottle: bottle);
    if (runtimeSettings.dxrEnabled) {
      _syncMacosD3DMetalDllOverrides(
        bottle: bottle,
        environment: programRunPlanner.environment.toMap(),
      );
    } else if (runtimeSettings.dxvk) {
      _syncMacosDxvkDllOverrides(
        bottle: bottle,
        environment: programRunPlanner.environment.toMap(),
      );
    }
  });
  return syncResult.fold<_CliSideEffectResult>(
    (failureMessage) => _CliSideEffectFailed(
      _jsonError(
        exitCode: 74,
        code: 'runtimeSettingsDllSyncFailed',
        message: 'Failed to synchronize runtime DLL overrides.',
        extra: <String, Object?>{
          'details': <String, Object?>{'message': failureMessage},
        },
      ),
    ),
    (_) => const _CliSideEffectSucceeded(),
  );
}

_CliSideEffectResult _applyWindowsVersionRegistryUpdates({
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

_CliSideEffectResult _applyRegistryUpdateRequests({
  required Iterable<ProgramRunRequest> requests,
  required ProgramRunner? programRunner,
}) {
  final runner = programRunner;
  if (runner == null) {
    return const _CliSideEffectSucceeded();
  }

  for (final request in requests) {
    final result = runner.run(request);
    switch (result) {
      case ProgramRunCompleted(:final processExitCode)
          when processExitCode == 0:
        continue;
      case ProgramRunCompleted(:final processExitCode):
        return _CliSideEffectFailed(
          _jsonError(
            exitCode: 75,
            code: 'registryUpdateFailed',
            message:
                'Registry update `${request.arguments.join(' ')}` exited with '
                'code $processExitCode.',
            extra: <String, Object?>{'processExitCode': processExitCode},
          ),
        );
      case ProgramRunFailed(:final message):
        return _CliSideEffectFailed(
          _jsonError(
            exitCode: 75,
            code: 'registryUpdateFailed',
            message: message,
          ),
        );
    }
  }

  return const _CliSideEffectSucceeded();
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
