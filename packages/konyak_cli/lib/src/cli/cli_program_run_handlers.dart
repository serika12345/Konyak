import 'package:fpdart/fpdart.dart';

import '../domain/bottle/bottle_models.dart';
import '../domain/bottle/bottle_runtime_settings_models.dart';
import '../domain/program/program_graphics_backend_hints.dart';
import '../domain/program/program_mutation_models.dart';
import '../domain/program/program_profile_catalog.dart';
import '../domain/program/program_profiles.dart';
import '../domain/program/program_run_environment.dart';
import '../domain/program/program_run_models.dart';
import '../domain/program/program_runner.dart';
import '../domain/program/program_settings_models.dart';
import '../domain/shared/domain_value_objects.dart';
import '../io/linux_external_program_launchers.dart';
import '../io/program_shortcut_metadata_io.dart';
import '../io/program_working_directory_io.dart';
import '../repository/repository_interfaces.dart';
import 'cli_bottle_mutation_handlers.dart';
import 'cli_bottle_results.dart';
import 'cli_commands.dart';
import 'cli_json_helpers.dart';
import 'cli_program_graphics_backend_hints_json.dart';
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

  if (isProgramRunWithSettingsJsonCommand(arguments)) {
    return jsonError(
      exitCode: 65,
      code: 'invalidProgramSettings',
      message: 'Program settings are invalid.',
    );
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
      <String, Object?>{
        'graphicsBackendHints': programGraphicsBackendHintsJson(hints),
      },
    ),
    ProgramGraphicsBackendHintsMissingProgram(:final programPath) => jsonError(
      exitCode: 66,
      code: 'programNotFound',
      message: 'Program file was not found.',
      extra: <String, Object?>{'programPath': programPath.value},
    ),
    ProgramGraphicsBackendHintsInspectionFailed(
      :final programPath,
      :final message,
    ) =>
      jsonError(
        exitCode: 74,
        code: 'programInspectionFailed',
        message: message,
        extra: <String, Object?>{'programPath': programPath.value},
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
        programGraphicsBackendHintsInspector:
            context.programGraphicsBackendHintsInspector,
        programRunner: runner,
        bottle: bottle,
        programPath: ProgramPath(request.programPath),
        installProfileCatalog: context.installProfileCatalog,
        oneTimeSettings: request.settings,
        oneTimeWorkingDirectoryOverride: request.workingDirectoryOverride,
        beforeRun:
            ({
              required BottleRecord effectiveBottle,
              required ProgramRunRequest programRunRequest,
            }) {
              switch (syncRuntimeSettingsDllOverrides(
                bottle: effectiveBottle,
                runtimeSettings: effectiveBottle.runtimeSettings,
                programRunPlanner: context.programRunPlanner,
              )) {
                case CliSideEffectFailed(:final result):
                  return CliSideEffectFailed(result);
                case CliSideEffectSucceeded():
                  break;
              }

              recordExternalProgramRun(
                bottle: bottle,
                request: programRunRequest,
              );
              synchronizeLinuxDesktopLauncherForProgramRun(
                hostPlatform: context.programRunPlanner.hostPlatform,
                environment: context.programRunPlanner.environment.toMap(),
                bottle: bottle,
                request: programRunRequest,
                programMetadataExtractor: context.programMetadataExtractor,
                diagnosticSink:
                    context.linuxExternalProgramLauncherDiagnosticSink,
              );

              return const CliSideEffectSucceeded();
            },
      );
    },
  );
}

typedef ProgramRunPreparation =
    CliSideEffectResult Function({
      required BottleRecord effectiveBottle,
      required ProgramRunRequest programRunRequest,
    });

CliResult runProgramPathJsonResult({
  required BottleRepository bottleRepository,
  required ProgramRunPlanner programRunPlanner,
  required ProgramRunner programRunner,
  required BottleRecord bottle,
  required ProgramPath programPath,
  required InstallProfileCatalog installProfileCatalog,
  Option<ProgramSettingsRecord> oneTimeSettings = const Option.none(),
  Option<ProgramWorkingDirectorySetting> oneTimeWorkingDirectoryOverride =
      const Option.none(),
  ProgramGraphicsBackendHintsInspector? programGraphicsBackendHintsInspector,
  ProgramRunPreparation? beforeRun,
}) {
  final profileProgramPath = metadataProgramPath(
    bottle: bottle,
    programPath: programPath,
  );
  final settingsResult = bottleRepository.readProgramSettings(
    ProgramSettingsRequest(bottleId: bottle.id, programPath: programPath),
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
    oneTimeWorkingDirectoryOverride: oneTimeWorkingDirectoryOverride,
  );
  final launchFallback = macosD3DMetalD3D10Fallback(
    bottle: bottle,
    programPath: programPath,
    programRunPlanner: programRunPlanner,
    programGraphicsBackendHintsInspector: programGraphicsBackendHintsInspector,
  );
  final effectiveBottle = launchFallback.match(
    () => bottle,
    (_) => bottle.copyWith(
      runtimeSettings: wineD3DVulkanFallbackRuntimeSettings(
        bottle.runtimeSettings,
      ),
    ),
  );
  final effectiveProgramSettingsWithDiagnostics = launchFallback.match(
    () => effectiveProgramSettings,
    (_) => programSettingsWithEnvironmentOverrides(
      settings: effectiveProgramSettings,
      environment: const <String, String>{
        'KONYAK_GRAPHICS_BACKEND_REQUESTED': 'gptk-d3dmetal',
        'KONYAK_GRAPHICS_BACKEND_SELECTED': 'wined3d-vulkan',
        'KONYAK_GRAPHICS_BACKEND_FALLBACK_REASON': 'gptkD3d10Unsupported',
      },
    ),
  );
  final missingWorkingDirectory = missingCustomProgramWorkingDirectory(
    bottle: effectiveBottle,
    setting: effectiveProgramSettingsWithDiagnostics.workingDirectory,
  );
  return missingWorkingDirectory.match(
    () {
      final programRunRequest = programRunPlanner.plan(
        bottle: effectiveBottle,
        programPath: programPath,
        compatibilityEnvironment:
            childProcessCompatibilityEnvironmentForProfiledPath(
              installProfileCatalog: installProfileCatalog,
              bottle: effectiveBottle,
              programPath: profileProgramPath,
            ),
        programSettings: Option.of(effectiveProgramSettingsWithDiagnostics),
        executableHostPath: Option.of(profileProgramPath),
      );
      return programRunRequest.match(
        () => jsonError(
          exitCode: 65,
          code: 'unsupportedProgramType',
          message: 'Program type is not supported.',
          extra: <String, Object?>{'programPath': programPath.value},
        ),
        (request) {
          return request.workingDirectory.match(
            () => jsonError(
              exitCode: 65,
              code: 'programWorkingDirectoryUnresolvable',
              message: 'Program working directory could not be resolved.',
              extra: <String, Object?>{'programPath': programPath.value},
            ),
            (_) {
              final launchRequest = request.withCompletionPolicy(
                programRunCompletionPolicyForProfiledPath(
                  installProfileCatalog: installProfileCatalog,
                  bottle: effectiveBottle,
                  programPath: profileProgramPath,
                ),
              );
              final preparationResult = beforeRun == null
                  ? const CliSideEffectSucceeded()
                  : beforeRun(
                      effectiveBottle: effectiveBottle,
                      programRunRequest: launchRequest,
                    );
              return switch (preparationResult) {
                CliSideEffectFailed(:final result) => result,
                CliSideEffectSucceeded() => programRunResultJson(
                  launchRequest,
                  programRunner,
                ),
              };
            },
          );
        },
      );
    },
    (workingDirectory) => jsonError(
      exitCode: 66,
      code: 'programWorkingDirectoryNotFound',
      message: 'Program working directory was not found.',
      extra: <String, Object?>{'workingDirectory': workingDirectory.value},
    ),
  );
}

Option<Unit> macosD3DMetalD3D10Fallback({
  required BottleRecord bottle,
  required ProgramPath programPath,
  required ProgramRunPlanner programRunPlanner,
  required ProgramGraphicsBackendHintsInspector?
  programGraphicsBackendHintsInspector,
}) {
  if (programRunPlanner.hostPlatform != KonyakHostPlatform.macos ||
      !bottle.runtimeSettings.dxrEnabled ||
      programGraphicsBackendHintsInspector == null) {
    return const Option.none();
  }

  final result = programGraphicsBackendHintsInspector.inspect(
    programPath: programPath,
    hostPlatform: programRunPlanner.hostPlatform,
  );
  return switch (result) {
    ProgramGraphicsBackendHintsInspected(:final hints)
        when hasD3D10Signal(hints) && !hasD3D12Signal(hints) =>
      Option.of(unit),
    _ => const Option.none(),
  };
}

bool hasD3D10Signal(ProgramGraphicsBackendHints hints) {
  return _hasSignalValue(hints, const <String>{
    'd3d10.dll',
    'd3d10_1.dll',
    'd3d10core.dll',
  });
}

bool hasD3D12Signal(ProgramGraphicsBackendHints hints) {
  return _hasSignalValue(hints, const <String>{
    'd3d12.dll',
    'd3d12core.dll',
    'd3d12createdevice',
  });
}

bool _hasSignalValue(ProgramGraphicsBackendHints hints, Set<String> values) {
  return hints.signals.any((signal) => values.contains(signal.value.value));
}

BottleRuntimeSettings wineD3DVulkanFallbackRuntimeSettings(
  BottleRuntimeSettings settings,
) {
  return BottleRuntimeSettings(
    enhancedSync: settings.enhancedSync,
    metalHud: settings.metalHud,
    metalTrace: settings.metalTrace,
    avxEnabled: settings.avxEnabled,
    dxvkAsync: settings.dxvkAsync,
    dxvkHud: settings.dxvkHud,
    buildVersion: settings.buildVersion,
    retinaMode: settings.retinaMode,
    dpiScaling: settings.dpiScaling,
  );
}

ProgramSettingsRecord programSettingsWithEnvironmentOverrides({
  required ProgramSettingsRecord settings,
  required Map<String, String> environment,
}) {
  return ProgramSettingsRecord(
    locale: settings.locale,
    arguments: settings.arguments,
    environment: ProgramEnvironmentOverrides(<String, String>{
      ...settings.environment.toMap(),
      ...environment,
    }),
    workingDirectory: settings.workingDirectory,
    logging: settings.logging,
  );
}

ProgramSettingsRecord programRunSettings({
  required ProgramSettingsRecord storedSettings,
  required Option<ProgramSettingsRecord> oneTimeSettings,
  Option<ProgramWorkingDirectorySetting> oneTimeWorkingDirectoryOverride =
      const Option.none(),
}) {
  return oneTimeSettings.match(
    () => storedSettings,
    (settings) => ProgramSettingsRecord(
      locale: settings.locale.value.trim().isEmpty
          ? storedSettings.locale
          : settings.locale,
      arguments: settings.arguments.value.trim().isEmpty
          ? storedSettings.arguments
          : settings.arguments,
      environment: ProgramEnvironmentOverrides(<String, String>{
        ...storedSettings.environment.toMap(),
        ...settings.environment.toMap(),
      }),
      workingDirectory: oneTimeWorkingDirectoryOverride.getOrElse(
        () => storedSettings.workingDirectory,
      ),
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
      final winetricksVerb = WinetricksVerbId(request.verb);
      final programRunRequest = context.programRunPlanner.planWinetricksVerb(
        bottle: bottle,
        verb: winetricksVerb,
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
      final bottleCommand = BottleCommand(request.command);
      final programRunRequest = context.programRunPlanner.planBottleCommand(
        bottle: bottle,
        command: bottleCommand,
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
