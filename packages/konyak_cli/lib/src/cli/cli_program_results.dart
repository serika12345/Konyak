import '../domain/program/pinned_programs.dart';
import '../domain/program/program_mutation_models.dart';
import '../domain/program/program_runner.dart';
import '../domain/program/program_settings_models.dart';
import '../io/macos_pinned_launcher_manifest_io.dart';
import '../io/macos_pinned_launchers.dart';
import '../io/program_settings_json.dart';
import '../repository/repository_interfaces.dart';
import 'cli_bottle_mutation_handlers.dart';
import 'cli_bottle_results.dart';
import 'cli_json_helpers.dart';
import 'cli_program_mutation_parsers.dart';
import 'cli_program_run_handlers.dart';
import 'cli_result_model.dart';

CliResult programUpdateJsonResult(ProgramUpdateResult result) {
  return switch (result) {
    ProgramUpdated(:final bottle) => bottleJsonResult(bottle),
    ProgramUpdateMissingBottle(:final bottleId) => bottleNotFoundError(
      bottleId.value,
    ),
    ProgramUpdateMissingProgram(:final programPath) => jsonError(
      exitCode: 66,
      code: 'programNotPinned',
      message: 'Program is not pinned.',
      extra: <String, Object?>{'programPath': programPath.value},
    ),
    ProgramUpdateFailed(:final message) => bottleRepositoryFailureJsonResult(
      message,
    ),
  };
}

CliResult runPinnedProgramLauncherCli({
  required PinnedProgramLaunchCliRequest request,
  required BottleRepository? bottleRepository,
  required ProgramRunPlanner programRunPlanner,
  required ProgramRunner? programRunner,
}) {
  final launcherManifest = readPinnedProgramLauncherManifest(
    request.manifestPath,
  );
  return launcherManifest.match(
    () => jsonError(
      exitCode: 65,
      code: 'invalidPinnedProgramLauncher',
      message: 'Pinned program launcher manifest is invalid.',
      extra: <String, Object?>{'manifestPath': request.manifestPath},
    ),
    (manifest) {
      if (bottleRepository == null) {
        return bottleRepositoryUnavailableError();
      }

      if (programRunner == null) {
        return programRunnerUnavailableError();
      }

      return foundBottleJsonResult(
        result: bottleRepository.findBottle(manifest.bottleId),
        bottleId: manifest.bottleId,
        onFound: (bottle) {
          final expectedLauncherId = pinnedProgramLauncherId(
            bottleId: manifest.bottleId.value,
            programPath: manifest.programPath.value,
          );
          if (manifest.launcherId.value != expectedLauncherId ||
              !hasPinnedProgram(bottle, manifest.programPath.value)) {
            return jsonError(
              exitCode: 66,
              code: 'programNotPinned',
              message: 'Program is not pinned.',
              extra: <String, Object?>{
                'programPath': manifest.programPath.value,
              },
            );
          }

          return runProgramPathJsonResult(
            bottleRepository: bottleRepository,
            programRunPlanner: programRunPlanner,
            programRunner: programRunner,
            bottle: bottle,
            programPath: manifest.programPath.value,
          );
        },
      );
    },
  );
}

CliResult programSettingsReadJsonResult({
  required ProgramSettingsRequest request,
  required ProgramSettingsReadResult result,
}) {
  return switch (result) {
    ProgramSettingsRead(:final settings) => programSettingsJsonResult(
      bottleId: request.bottleId.value,
      programPath: request.programPath.value,
      settings: settings,
    ),
    ProgramSettingsReadMissingBottle(:final bottleId) => bottleNotFoundError(
      bottleId.value,
    ),
    ProgramSettingsReadFailed(:final message) =>
      bottleRepositoryFailureJsonResult(message),
  };
}

CliResult programSettingsUpdateJsonResult({
  required ProgramSettingsUpdateRequest request,
  required ProgramSettingsUpdateResult result,
}) {
  return switch (result) {
    ProgramSettingsUpdated(:final settings) => programSettingsJsonResult(
      bottleId: request.bottleId.value,
      programPath: request.programPath.value,
      settings: settings,
    ),
    ProgramSettingsUpdateMissingBottle(:final bottleId) => bottleNotFoundError(
      bottleId.value,
    ),
    ProgramSettingsUpdateFailed(:final message) =>
      bottleRepositoryFailureJsonResult(message),
  };
}

CliResult programSettingsJsonResult({
  required String bottleId,
  required String programPath,
  required ProgramSettingsRecord settings,
}) {
  return jsonSuccess(<String, Object?>{
    'programSettings': <String, Object?>{
      'bottleId': bottleId,
      'programPath': programPath,
      'settings': programSettingsRecordJson(settings),
    },
  });
}
