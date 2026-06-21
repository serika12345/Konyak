part of '../../konyak_cli.dart';

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
      BottleCreateFailed(:final message) => _bottleRepositoryFailureJsonResult(
        message,
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
      BottleDeleteFailed(:final message) => _bottleRepositoryFailureJsonResult(
        message,
      ),
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
      BottleRenameFailed(:final message) => _bottleRepositoryFailureJsonResult(
        message,
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
      BottleMoveFailed(:final message) => _bottleRepositoryFailureJsonResult(
        message,
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

    return _foundBottleJsonResult(
      result: repository.findBottle(windowsVersionUpdateRequest.bottleId),
      bottleId: windowsVersionUpdateRequest.bottleId,
      onFound: (bottle) {
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
      },
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

    return _foundBottleJsonResult(
      result: repository.findBottle(runtimeSettingsUpdateRequest.bottleId),
      bottleId: runtimeSettingsUpdateRequest.bottleId,
      onFound: (bottle) {
        final runtimeSettings = _effectiveRuntimeSettingsForUpdate(
          currentRuntimeSettings: bottle.runtimeSettings,
          runtimeSettings: runtimeSettingsUpdateRequest.runtimeSettings,
          hostPlatform: context.programRunPlanner.hostPlatform,
        );
        final registryUpdateFailure = _applyRuntimeSettingsRegistryUpdates(
          bottle: bottle,
          runtimeSettings: runtimeSettings,
          programRunPlanner: context.programRunPlanner,
          programRunner: context.programRunner,
        );
        if (registryUpdateFailure != null) {
          return registryUpdateFailure;
        }

        final dllSyncFailure = _syncRuntimeSettingsDllOverrides(
          bottle: bottle,
          runtimeSettings: runtimeSettings,
          programRunPlanner: context.programRunPlanner,
        );
        if (dllSyncFailure != null) {
          return dllSyncFailure;
        }

        return _bottleUpdateJsonResult(
          repository.setRuntimeSettings(
            RuntimeSettingsUpdateRequest(
              bottleId: runtimeSettingsUpdateRequest.bottleId,
              runtimeSettings: runtimeSettings,
            ),
          ),
        );
      },
    );
  }

  return null;
}

BottleRuntimeSettings _effectiveRuntimeSettingsForUpdate({
  required BottleRuntimeSettings currentRuntimeSettings,
  required BottleRuntimeSettings runtimeSettings,
  required KonyakHostPlatform hostPlatform,
}) {
  return switch (hostPlatform) {
    KonyakHostPlatform.macos =>
      runtimeSettings.withHighResolutionModeWindowsDpiAdjustment(
        currentRuntimeSettings,
      ),
    KonyakHostPlatform.linux => runtimeSettings,
  };
}

CliResult _bottleUpdateJsonResult(BottleUpdateResult result) {
  return switch (result) {
    BottleUpdated(:final bottle) => _bottleJsonResult(bottle),
    BottleUpdateMissing(:final bottleId) => _bottleNotFoundError(bottleId),
    BottleUpdateFailed(:final message) => _bottleRepositoryFailureJsonResult(
      message,
    ),
  };
}
