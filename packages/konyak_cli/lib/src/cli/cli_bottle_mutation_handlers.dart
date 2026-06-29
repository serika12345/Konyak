import '../domain/bottle/bottle_mutation_models.dart';
import '../domain/bottle/bottle_runtime_settings_models.dart';
import '../domain/program/program_runner.dart';
import '../io/bottle_metadata_json.dart';
import 'cli_bottle_parsers.dart';
import 'cli_bottle_results.dart';
import 'cli_commands.dart';
import 'cli_json_helpers.dart';
import 'cli_result_model.dart';

CliResult? handleBottleMutationCommand(
  List<String> arguments,
  CliCommandContext context,
) {
  final createBottleRequest = parseJsonBottleCreateRequest(arguments);
  if (createBottleRequest != null) {
    final repository = context.bottleRepository;
    if (repository == null) {
      return bottleRepositoryUnavailableError();
    }

    return switch (repository.createBottle(createBottleRequest)) {
      BottleCreated(:final bottle) => createdBottleJsonResult(
        bottle: bottle,
        bottlePrefixInitializer: context.bottlePrefixInitializer,
      ),
      BottleCreateConflict(:final bottleId) => jsonError(
        exitCode: 73,
        code: 'bottleAlreadyExists',
        message: 'Bottle already exists.',
        extra: <String, Object?>{'bottleId': bottleId.value},
      ),
      BottleCreateFailed(:final message) => bottleRepositoryFailureJsonResult(
        message,
      ),
    };
  }

  final bottleArchiveExportRequest = parseJsonBottleArchiveExportRequest(
    arguments,
  );
  if (bottleArchiveExportRequest != null) {
    final repository = context.bottleRepository;
    if (repository == null) {
      return bottleRepositoryUnavailableError();
    }

    return bottleArchiveExportJsonResult(
      repository.exportBottleArchive(bottleArchiveExportRequest),
    );
  }

  final bottleArchiveImportRequest = parseJsonBottleArchiveImportRequest(
    arguments,
  );
  if (bottleArchiveImportRequest != null) {
    final repository = context.bottleRepository;
    if (repository == null) {
      return bottleRepositoryUnavailableError();
    }

    return bottleArchiveImportJsonResult(
      repository.importBottleArchive(bottleArchiveImportRequest),
    );
  }

  final deleteBottleId = parseJsonBottleDeleteCommand(arguments);
  if (deleteBottleId != null) {
    final repository = context.bottleRepository;
    if (repository == null) {
      return bottleRepositoryUnavailableError();
    }

    return switch (repository.deleteBottle(deleteBottleId)) {
      BottleDeleted(:final bottle) => jsonSuccess(<String, Object?>{
        'deletedBottle': bottleRecordJson(bottle),
      }),
      BottleDeleteMissing(:final bottleId) => bottleNotFoundError(
        bottleId.value,
      ),
      BottleDeleteFailed(:final message) => bottleRepositoryFailureJsonResult(
        message,
      ),
    };
  }

  final renameBottleRequest = parseJsonBottleRenameRequest(arguments);
  if (renameBottleRequest != null) {
    final repository = context.bottleRepository;
    if (repository == null) {
      return bottleRepositoryUnavailableError();
    }

    return switch (repository.renameBottle(renameBottleRequest)) {
      BottleRenamed(:final bottle) => bottleJsonResult(bottle),
      BottleRenameMissing(:final bottleId) => bottleNotFoundError(
        bottleId.value,
      ),
      BottleRenameConflict(:final bottleId) => jsonError(
        exitCode: 73,
        code: 'bottleAlreadyExists',
        message: 'Bottle already exists.',
        extra: <String, Object?>{'bottleId': bottleId.value},
      ),
      BottleRenameFailed(:final message) => bottleRepositoryFailureJsonResult(
        message,
      ),
    };
  }

  final moveBottleRequest = parseJsonBottleMoveRequest(arguments);
  if (moveBottleRequest != null) {
    final repository = context.bottleRepository;
    if (repository == null) {
      return bottleRepositoryUnavailableError();
    }

    return switch (repository.moveBottle(moveBottleRequest)) {
      BottleMoved(:final bottle) => bottleJsonResult(bottle),
      BottleMoveMissing(:final bottleId) => bottleNotFoundError(bottleId.value),
      BottleMoveConflict(:final path) => jsonError(
        exitCode: 73,
        code: 'bottleMoveDestinationExists',
        message: 'Bottle move destination exists.',
        extra: <String, Object?>{'path': path.value},
      ),
      BottleMoveFailed(:final message) => bottleRepositoryFailureJsonResult(
        message,
      ),
    };
  }

  return null;
}

CliResult bottleRepositoryUnavailableError() {
  return unavailableJsonError(
    code: 'bottleRepositoryUnavailable',
    subject: 'Bottle repository',
  );
}

CliResult? handleBottleConfigurationCommand(
  List<String> arguments,
  CliCommandContext context,
) {
  final windowsVersionUpdateRequest = parseJsonWindowsVersionUpdateRequest(
    arguments,
  );
  if (windowsVersionUpdateRequest != null) {
    final repository = context.bottleRepository;
    if (repository == null) {
      return bottleRepositoryUnavailableError();
    }

    return foundBottleJsonResult(
      result: repository.findBottle(windowsVersionUpdateRequest.bottleId),
      bottleId: windowsVersionUpdateRequest.bottleId,
      onFound: (bottle) {
        switch (applyWindowsVersionRegistryUpdates(
          bottle: bottle,
          windowsVersion: windowsVersionUpdateRequest.windowsVersion.value,
          programRunPlanner: context.programRunPlanner,
          programRunner: context.programRunner,
        )) {
          case CliSideEffectFailed(:final result):
            return result;
          case CliSideEffectSucceeded():
            return bottleUpdateJsonResult(
              repository.setWindowsVersion(windowsVersionUpdateRequest),
            );
        }
      },
    );
  }

  final runtimeSettingsUpdateRequest = parseJsonRuntimeSettingsUpdateRequest(
    arguments,
  );
  if (runtimeSettingsUpdateRequest != null) {
    final repository = context.bottleRepository;
    if (repository == null) {
      return bottleRepositoryUnavailableError();
    }

    return foundBottleJsonResult(
      result: repository.findBottle(runtimeSettingsUpdateRequest.bottleId),
      bottleId: runtimeSettingsUpdateRequest.bottleId,
      onFound: (bottle) {
        final runtimeSettings = effectiveRuntimeSettingsForUpdate(
          currentRuntimeSettings: bottle.runtimeSettings,
          runtimeSettings: runtimeSettingsUpdateRequest.runtimeSettings,
          hostPlatform: context.programRunPlanner.hostPlatform,
        );
        switch (applyRuntimeSettingsRegistryUpdates(
          bottle: bottle,
          runtimeSettings: runtimeSettings,
          programRunPlanner: context.programRunPlanner,
          programRunner: context.programRunner,
        )) {
          case CliSideEffectFailed(:final result):
            return result;
          case CliSideEffectSucceeded():
            break;
        }

        switch (syncRuntimeSettingsDllOverrides(
          bottle: bottle,
          runtimeSettings: runtimeSettings,
          programRunPlanner: context.programRunPlanner,
        )) {
          case CliSideEffectFailed(:final result):
            return result;
          case CliSideEffectSucceeded():
            return bottleUpdateJsonResult(
              repository.setRuntimeSettings(
                RuntimeSettingsUpdateRequest(
                  bottleId: runtimeSettingsUpdateRequest.bottleId.value,
                  runtimeSettings: runtimeSettings,
                ),
              ),
            );
        }
      },
    );
  }

  return null;
}

BottleRuntimeSettings effectiveRuntimeSettingsForUpdate({
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

CliResult bottleUpdateJsonResult(BottleUpdateResult result) {
  return switch (result) {
    BottleUpdated(:final bottle) => bottleJsonResult(bottle),
    BottleUpdateMissing(:final bottleId) => bottleNotFoundError(bottleId.value),
    BottleUpdateFailed(:final message) => bottleRepositoryFailureJsonResult(
      message,
    ),
  };
}
