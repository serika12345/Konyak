import '../domain/program/program_argument_support.dart';
import '../domain/program/program_mutation_models.dart';
import '../io/linux_pinned_launchers.dart';
import 'cli_bottle_mutation_handlers.dart';
import 'cli_bottle_results.dart';
import 'cli_commands.dart';
import 'cli_json_helpers.dart';
import 'cli_program_mutation_parsers.dart';
import 'cli_program_results.dart';
import 'cli_result_model.dart';

CliResult? handlePinnedProgramCommand(
  List<String> arguments,
  CliCommandContext context,
) {
  final programPinRequest = parseJsonProgramPinRequest(arguments);
  if (programPinRequest != null) {
    if (!isSupportedProgramPath(programPinRequest.programPath)) {
      return jsonError(
        exitCode: 65,
        code: 'unsupportedProgramType',
        message: 'Program type is not supported.',
        extra: <String, Object?>{
          'programPath': programPinRequest.programPath.value,
        },
      );
    }

    final repository = context.bottleRepository;
    if (repository == null) {
      return bottleRepositoryUnavailableError();
    }

    final pinResult = repository.pinProgram(programPinRequest);
    if (pinResult is ProgramPinned) {
      return repository.listBottles().match<CliResult>(
        bottleCatalogFailureJsonResult,
        (bottles) {
          synchronizePinnedProgramLaunchers(
            hostPlatform: context.programRunPlanner.hostPlatform,
            environment: context.programRunPlanner.environment.toMap(),
            bottles: bottles,
          );
          return bottleJsonResult(pinResult.bottle);
        },
      );
    }

    return switch (pinResult) {
      ProgramPinned(:final bottle) => bottleJsonResult(bottle),
      ProgramPinMissing(:final bottleId) => bottleNotFoundError(bottleId.value),
      ProgramPinConflict(:final programPath) => jsonError(
        exitCode: 73,
        code: 'programAlreadyPinned',
        message: 'Program is already pinned.',
        extra: <String, Object?>{'programPath': programPath.value},
      ),
      ProgramPinFailed(:final message) => bottleRepositoryFailureJsonResult(
        message,
      ),
    };
  }

  final programUnpinRequest = parseJsonProgramUnpinRequest(arguments);
  if (programUnpinRequest != null) {
    final repository = context.bottleRepository;
    if (repository == null) {
      return bottleRepositoryUnavailableError();
    }

    final updateResult = repository.unpinProgram(programUnpinRequest);
    if (updateResult is ProgramUpdated) {
      return repository.listBottles().match<CliResult>(
        bottleCatalogFailureJsonResult,
        (bottles) {
          synchronizePinnedProgramLaunchers(
            hostPlatform: context.programRunPlanner.hostPlatform,
            environment: context.programRunPlanner.environment.toMap(),
            bottles: bottles,
          );
          return programUpdateJsonResult(updateResult);
        },
      );
    }

    return programUpdateJsonResult(updateResult);
  }

  final programRenameRequest = parseJsonProgramRenameRequest(arguments);
  if (programRenameRequest != null) {
    final repository = context.bottleRepository;
    if (repository == null) {
      return bottleRepositoryUnavailableError();
    }

    final updateResult = repository.renamePinnedProgram(programRenameRequest);
    if (updateResult is ProgramUpdated) {
      return repository.listBottles().match<CliResult>(
        bottleCatalogFailureJsonResult,
        (bottles) {
          synchronizePinnedProgramLaunchers(
            hostPlatform: context.programRunPlanner.hostPlatform,
            environment: context.programRunPlanner.environment.toMap(),
            bottles: bottles,
          );
          return programUpdateJsonResult(updateResult);
        },
      );
    }

    return programUpdateJsonResult(updateResult);
  }

  final pinnedProgramLaunchCliRequest = parseJsonPinnedProgramLaunchCliRequest(
    arguments,
  );
  if (pinnedProgramLaunchCliRequest != null) {
    return runPinnedProgramLauncherCli(
      request: pinnedProgramLaunchCliRequest,
      bottleRepository: context.bottleRepository,
      programRunPlanner: context.programRunPlanner,
      programGraphicsBackendHintsInspector:
          context.programGraphicsBackendHintsInspector,
      programRunner: context.programRunner,
      installProfileCatalog: context.installProfileCatalog,
    );
  }

  return null;
}

CliResult? handleProgramSettingsCommand(
  List<String> arguments,
  CliCommandContext context,
) {
  final programSettingsRequest = parseJsonProgramSettingsRequest(arguments);
  if (programSettingsRequest != null) {
    final repository = context.bottleRepository;
    if (repository == null) {
      return bottleRepositoryUnavailableError();
    }

    return programSettingsReadJsonResult(
      request: programSettingsRequest,
      result: repository.readProgramSettings(programSettingsRequest),
    );
  }

  final programSettingsUpdateRequest = parseJsonProgramSettingsUpdateRequest(
    arguments,
  );
  if (programSettingsUpdateRequest != null) {
    final repository = context.bottleRepository;
    if (repository == null) {
      return bottleRepositoryUnavailableError();
    }

    return programSettingsUpdateJsonResult(
      request: programSettingsUpdateRequest,
      result: repository.setProgramSettings(programSettingsUpdateRequest),
    );
  }

  return null;
}
