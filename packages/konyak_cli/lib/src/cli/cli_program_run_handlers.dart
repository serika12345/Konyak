import 'package:fpdart/fpdart.dart';

import '../domain/bottle/bottle_models.dart';
import '../domain/program/program_graphics_backend_hints.dart';
import '../domain/program/program_mutation_models.dart';
import '../domain/program/program_run_environment.dart';
import '../domain/program/program_run_models.dart';
import '../domain/program/program_runner.dart';
import '../domain/program/program_settings_models.dart';
import '../domain/shared/domain_value_objects.dart';
import '../io/linux_external_program_launchers.dart';
import '../repository/repository_interfaces.dart';
import 'cli_bottle_mutation_handlers.dart';
import 'cli_bottle_results.dart';
import 'cli_commands.dart';
import 'cli_json_helpers.dart';
import 'cli_program_run_parsers.dart';
import 'cli_result_model.dart';

CliResult? handleProgramRunCommand(
  List<String> arguments,
  CliCommandContext context,
) {
  final graphicsBackendHintsCliRequest =
      parseJsonGraphicsBackendHintsCliRequest(arguments);
  if (graphicsBackendHintsCliRequest != null) {
    return graphicsBackendHintsJsonResult(
      graphicsBackendHintsCliRequest,
      context,
    );
  }

  final programRunCliRequest = parseJsonProgramRunCliRequest(arguments);
  if (programRunCliRequest != null) {
    return runProgramJsonResult(programRunCliRequest, context);
  }

  final winetricksRunCliRequest = parseJsonWinetricksRunCliRequest(arguments);
  if (winetricksRunCliRequest != null) {
    return runWinetricksJsonResult(winetricksRunCliRequest, context);
  }

  final bottleCommandRunCliRequest = parseJsonBottleCommandRunCliRequest(
    arguments,
  );
  if (bottleCommandRunCliRequest != null) {
    return runBottleCommandJsonResult(bottleCommandRunCliRequest, context);
  }

  return null;
}

CliResult graphicsBackendHintsJsonResult(
  GraphicsBackendHintsCliRequest request,
  CliCommandContext context,
) {
  final result = context.programGraphicsBackendHintsInspector.inspect(
    programPath: ProgramPath(request.programPath),
    hostPlatform: context.programRunPlanner.hostPlatform,
  );

  return switch (result) {
    ProgramGraphicsBackendHintsInspected(:final hints) => jsonSuccess(
      <String, Object?>{'graphicsBackendHints': hints.toJson()},
    ),
    ProgramGraphicsBackendHintsMissingProgram(:final programPath) => jsonError(
      exitCode: 66,
      code: 'programNotFound',
      message: 'Program file was not found.',
      extra: <String, Object?>{'programPath': programPath},
    ),
    ProgramGraphicsBackendHintsInspectionFailed(
      :final programPath,
      :final message,
    ) =>
      jsonError(
        exitCode: 74,
        code: 'programInspectionFailed',
        message: message,
        extra: <String, Object?>{'programPath': programPath},
      ),
  };
}

CliResult runProgramJsonResult(
  ProgramRunCliRequest request,
  CliCommandContext context,
) {
  final repository = context.bottleRepository;
  if (repository == null) {
    return bottleRepositoryUnavailableError();
  }

  final runner = context.programRunner;
  if (runner == null) {
    return programRunnerUnavailableError();
  }

  return foundBottleJsonResult(
    result: repository.findBottle(request.bottleId),
    bottleId: request.bottleId,
    onFound: (bottle) {
      return runProgramPathJsonResult(
        bottleRepository: repository,
        programRunPlanner: context.programRunPlanner,
        programRunner: runner,
        bottle: bottle,
        programPath: request.programPath,
        oneTimeSettings: request.settings,
        beforeRun: (programRunRequest) {
          switch (syncRuntimeSettingsDllOverrides(
            bottle: bottle,
            runtimeSettings: bottle.runtimeSettings,
            programRunPlanner: context.programRunPlanner,
          )) {
            case CliSideEffectFailed(:final result):
              return CliSideEffectFailed(result);
            case CliSideEffectSucceeded():
              break;
          }

          recordExternalProgramRun(bottle: bottle, request: programRunRequest);
          synchronizeLinuxDesktopLauncherForProgramRun(
            hostPlatform: context.programRunPlanner.hostPlatform,
            environment: context.programRunPlanner.environment.toMap(),
            bottle: bottle,
            request: programRunRequest,
            programMetadataExtractor: context.programMetadataExtractor,
            diagnosticSink: context.linuxExternalProgramLauncherDiagnosticSink,
          );

          return const CliSideEffectSucceeded();
        },
      );
    },
  );
}

typedef ProgramRunPreparation =
    CliSideEffectResult Function(ProgramRunRequest request);

CliResult runProgramPathJsonResult({
  required BottleRepository bottleRepository,
  required ProgramRunPlanner programRunPlanner,
  required ProgramRunner programRunner,
  required BottleRecord bottle,
  required String programPath,
  Option<ProgramSettingsRecord> oneTimeSettings = const Option.none(),
  ProgramRunPreparation? beforeRun,
}) {
  final settingsResult = bottleRepository.readProgramSettings(
    ProgramSettingsRequest(bottleId: bottle.id.value, programPath: programPath),
  );
  final ProgramSettingsRecord storedSettings;
  switch (settingsResult) {
    case ProgramSettingsRead(:final settings):
      storedSettings = settings;
    case ProgramSettingsReadMissingBottle():
      storedSettings = ProgramSettingsRecord();
    case ProgramSettingsReadFailed(:final message):
      return bottleRepositoryFailureJsonResult(message);
  }

  final effectiveProgramSettings = programRunSettings(
    storedSettings: storedSettings,
    oneTimeSettings: oneTimeSettings,
  );
  final typedProgramPath = ProgramPath(programPath);
  final programRunRequest = programRunPlanner.plan(
    bottle: bottle,
    programPath: typedProgramPath,
    programSettings: Option.of(effectiveProgramSettings),
  );
  return programRunRequest.match(
    () => jsonError(
      exitCode: 65,
      code: 'unsupportedProgramType',
      message: 'Program type is not supported.',
      extra: <String, Object?>{'programPath': programPath},
    ),
    (request) {
      final preparationResult = beforeRun == null
          ? const CliSideEffectSucceeded()
          : beforeRun(request);
      return switch (preparationResult) {
        CliSideEffectFailed(:final result) => result,
        CliSideEffectSucceeded() => programRunResultJson(
          request,
          programRunner,
        ),
      };
    },
  );
}

ProgramSettingsRecord programRunSettings({
  required ProgramSettingsRecord storedSettings,
  required Option<ProgramSettingsRecord> oneTimeSettings,
}) {
  return oneTimeSettings.match(
    () => storedSettings,
    (settings) => ProgramSettingsRecord(
      locale: settings.locale.value.trim().isEmpty
          ? storedSettings.locale.value
          : settings.locale.value,
      arguments: settings.arguments.value.trim().isEmpty
          ? storedSettings.arguments.value
          : settings.arguments.value,
      environment: ProgramEnvironmentOverrides(<String, String>{
        ...storedSettings.environment.toMap(),
        ...settings.environment.toMap(),
      }),
      logging: settings.logging.match(() => storedSettings.logging, Option.of),
    ),
  );
}

CliResult runWinetricksJsonResult(
  WinetricksRunCliRequest request,
  CliCommandContext context,
) {
  final repository = context.bottleRepository;
  if (repository == null) {
    return bottleRepositoryUnavailableError();
  }

  final runner = context.programRunner;
  if (runner == null) {
    return programRunnerUnavailableError();
  }

  return foundBottleJsonResult(
    result: repository.findBottle(request.bottleId),
    bottleId: request.bottleId,
    onFound: (bottle) {
      final programRunRequest = context.programRunPlanner.planWinetricksVerb(
        bottle: bottle,
        verb: request.verb,
      );
      return programRunRequest.match(
        () => jsonError(
          exitCode: 65,
          code: 'unsupportedWinetricksVerb',
          message: 'Winetricks verb is not supported.',
          extra: <String, Object?>{'verb': request.verb},
        ),
        (request) => programRunResultJson(request, runner),
      );
    },
  );
}

CliResult runBottleCommandJsonResult(
  BottleCommandRunCliRequest request,
  CliCommandContext context,
) {
  final repository = context.bottleRepository;
  if (repository == null) {
    return bottleRepositoryUnavailableError();
  }

  final runner = context.programRunner;
  if (runner == null) {
    return programRunnerUnavailableError();
  }

  return foundBottleJsonResult(
    result: repository.findBottle(request.bottleId),
    bottleId: request.bottleId,
    onFound: (bottle) {
      final programRunRequest = context.programRunPlanner.planBottleCommand(
        bottle: bottle,
        command: request.command,
      );
      return programRunRequest.match(
        () => jsonError(
          exitCode: 65,
          code: 'unsupportedBottleCommand',
          message: 'Bottle command is not supported.',
          extra: <String, Object?>{'command': request.command},
        ),
        (request) => programRunResultJson(request, runner),
      );
    },
  );
}

CliResult programRunResultJson(
  ProgramRunRequest request,
  ProgramRunner runner,
) {
  return switch (runner.run(request)) {
    ProgramRunCompleted(:final processExitCode) => programRunJsonResult(
      request: request,
      processExitCode: processExitCode,
    ),
    ProgramRunFailed(:final message) => programRunFailedJsonResult(
      request: request,
      message: message,
    ),
  };
}

CliResult programRunnerUnavailableError() {
  return unavailableJsonError(
    code: 'programRunnerUnavailable',
    subject: 'Program runner',
  );
}
