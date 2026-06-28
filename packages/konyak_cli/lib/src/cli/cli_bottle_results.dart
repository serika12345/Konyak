import 'package:fpdart/fpdart.dart';

import '../domain/bottle/bottle_models.dart';
import '../domain/bottle/bottle_mutation_models.dart';
import '../domain/bottle/bottle_runtime_settings_models.dart';
import '../domain/program/program_run_models.dart';
import '../domain/program/program_runner.dart';
import '../io/io_result.dart';
import '../io/program_registry_parsers.dart';
import '../io/wine_run_requests.dart';
import 'cli_json_helpers.dart';
import 'cli_result_model.dart';

CliResult bottleArchiveExportJsonResult(BottleArchiveExportResult result) {
  return switch (result) {
    BottleArchiveExported(:final archive) => jsonSuccess(<String, Object?>{
      'bottleArchive': archive.toJson(),
    }),
    BottleArchiveExportMissing(:final bottleId) => bottleNotFoundError(
      bottleId.value,
    ),
    BottleArchiveExportFailed(:final message) => jsonError(
      exitCode: 75,
      code: 'bottleArchiveExportFailed',
      message: message,
    ),
  };
}

CliResult bottleArchiveImportJsonResult(BottleArchiveImportResult result) {
  return switch (result) {
    BottleArchiveImported(:final bottle) => bottleJsonResult(bottle),
    BottleArchiveImportConflict(:final bottleId) => jsonError(
      exitCode: 73,
      code: 'bottleAlreadyExists',
      message: 'Bottle already exists.',
      extra: <String, Object?>{'bottleId': bottleId.value},
    ),
    BottleArchiveImportFailed(:final message) => jsonError(
      exitCode: 65,
      code: 'invalidBottleArchive',
      message: message,
    ),
  };
}

CliResult bottleRepositoryFailureJsonResult(String message) {
  return jsonError(
    exitCode: 74,
    code: 'bottleRepositoryError',
    message: message,
  );
}

CliResult bottleCatalogFailureJsonResult(String message) {
  return bottleRepositoryFailureJsonResult(message);
}

CliResult foundBottleJsonResult({
  required IoResult<Option<BottleRecord>> result,
  required String bottleId,
  required CliResult Function(BottleRecord bottle) onFound,
}) {
  return result.fold(
    bottleCatalogFailureJsonResult,
    (bottle) => bottle.match(() => bottleNotFoundError(bottleId), onFound),
  );
}

sealed class CliSideEffectResult {
  const CliSideEffectResult();
}

final class CliSideEffectSucceeded extends CliSideEffectResult {
  const CliSideEffectSucceeded();
}

final class CliSideEffectFailed extends CliSideEffectResult {
  const CliSideEffectFailed(this.result);

  final CliResult result;
}

CliSideEffectResult applyRuntimeSettingsRegistryUpdates({
  required BottleRecord bottle,
  required BottleRuntimeSettings runtimeSettings,
  required ProgramRunPlanner programRunPlanner,
  required ProgramRunner? programRunner,
}) {
  return applyRegistryUpdateRequests(
    requests: programRunPlanner.planRuntimeSettingsRegistryUpdates(
      bottle: bottle,
      currentRuntimeSettings: bottle.runtimeSettings,
      runtimeSettings: runtimeSettings,
    ),
    programRunner: programRunner,
  );
}

CliSideEffectResult syncRuntimeSettingsDllOverrides({
  required BottleRecord bottle,
  required BottleRuntimeSettings runtimeSettings,
  required ProgramRunPlanner programRunPlanner,
}) {
  if (programRunPlanner.hostPlatform != KonyakHostPlatform.macos) {
    return const CliSideEffectSucceeded();
  }

  final syncResult = ioResult(() {
    removeMacosD3DTranslationDllOverrides(bottle: bottle);
    if (runtimeSettings.dxrEnabled) {
      syncMacosD3DMetalDllOverrides(
        bottle: bottle,
        environment: programRunPlanner.environment.toMap(),
      );
    } else if (runtimeSettings.dxvk) {
      syncMacosDxvkDllOverrides(
        bottle: bottle,
        environment: programRunPlanner.environment.toMap(),
      );
    }
  });
  return syncResult.fold<CliSideEffectResult>(
    (failureMessage) => CliSideEffectFailed(
      jsonError(
        exitCode: 74,
        code: 'runtimeSettingsDllSyncFailed',
        message: 'Failed to synchronize runtime DLL overrides.',
        extra: <String, Object?>{
          'details': <String, Object?>{'message': failureMessage},
        },
      ),
    ),
    (_) => const CliSideEffectSucceeded(),
  );
}

CliSideEffectResult applyWindowsVersionRegistryUpdates({
  required BottleRecord bottle,
  required String windowsVersion,
  required ProgramRunPlanner programRunPlanner,
  required ProgramRunner? programRunner,
}) {
  return applyRegistryUpdateRequests(
    requests: programRunPlanner.planWindowsVersionRegistryUpdates(
      bottle: bottle,
      windowsVersion: windowsVersion,
    ),
    programRunner: programRunner,
  );
}

CliSideEffectResult applyRegistryUpdateRequests({
  required Iterable<ProgramRunRequest> requests,
  required ProgramRunner? programRunner,
}) {
  final runner = programRunner;
  if (runner == null) {
    return const CliSideEffectSucceeded();
  }

  for (final request in requests) {
    final result = runner.run(request);
    switch (result) {
      case ProgramRunCompleted(:final processExitCode)
          when processExitCode == 0:
        continue;
      case ProgramRunCompleted(:final processExitCode):
        return CliSideEffectFailed(
          jsonError(
            exitCode: 75,
            code: 'registryUpdateFailed',
            message:
                'Registry update `${request.arguments.value.join(' ')}` exited with '
                'code $processExitCode.',
            extra: <String, Object?>{'processExitCode': processExitCode},
          ),
        );
      case ProgramRunFailed(:final message):
        return CliSideEffectFailed(
          jsonError(
            exitCode: 75,
            code: 'registryUpdateFailed',
            message: message,
          ),
        );
    }
  }

  return const CliSideEffectSucceeded();
}

BottleRecord bottleWithRegistrySettings({
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
        currentBottle = bottleWithRegistryValue(
          bottle: currentBottle,
          arguments: request.arguments.value,
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

CliResult bottleJsonResult(BottleRecord bottle) {
  return jsonSuccess(<String, Object?>{'bottle': bottle.toJson()});
}
