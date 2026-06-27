part of '../../konyak_cli.dart';

CliResult? _handleProgramRunCommand(
  List<String> arguments,
  _CliCommandContext context,
) {
  final graphicsBackendHintsCliRequest =
      _parseJsonGraphicsBackendHintsCliRequest(arguments);
  if (graphicsBackendHintsCliRequest != null) {
    return _graphicsBackendHintsJsonResult(
      graphicsBackendHintsCliRequest,
      context,
    );
  }

  final programRunCliRequest = _parseJsonProgramRunCliRequest(arguments);
  if (programRunCliRequest != null) {
    return _runProgramJsonResult(programRunCliRequest, context);
  }

  final winetricksRunCliRequest = _parseJsonWinetricksRunCliRequest(arguments);
  if (winetricksRunCliRequest != null) {
    return _runWinetricksJsonResult(winetricksRunCliRequest, context);
  }

  final bottleCommandRunCliRequest = _parseJsonBottleCommandRunCliRequest(
    arguments,
  );
  if (bottleCommandRunCliRequest != null) {
    return _runBottleCommandJsonResult(bottleCommandRunCliRequest, context);
  }

  return null;
}

CliResult _graphicsBackendHintsJsonResult(
  _GraphicsBackendHintsCliRequest request,
  _CliCommandContext context,
) {
  final result = const DartIoProgramGraphicsBackendHintsInspector().inspect(
    programPath: request.programPath,
    hostPlatform: context.programRunPlanner.hostPlatform,
  );

  return switch (result) {
    ProgramGraphicsBackendHintsInspected(:final hints) => _jsonSuccess(
      <String, Object?>{'graphicsBackendHints': hints.toJson()},
    ),
    ProgramGraphicsBackendHintsMissingProgram(:final programPath) => _jsonError(
      exitCode: 66,
      code: 'programNotFound',
      message: 'Program file was not found.',
      extra: <String, Object?>{'programPath': programPath},
    ),
    ProgramGraphicsBackendHintsInspectionFailed(
      :final programPath,
      :final message,
    ) =>
      _jsonError(
        exitCode: 74,
        code: 'programInspectionFailed',
        message: message,
        extra: <String, Object?>{'programPath': programPath},
      ),
  };
}

CliResult _runProgramJsonResult(
  _ProgramRunCliRequest request,
  _CliCommandContext context,
) {
  final repository = context.bottleRepository;
  if (repository == null) {
    return _bottleRepositoryUnavailableError();
  }

  final runner = context.programRunner;
  if (runner == null) {
    return _programRunnerUnavailableError();
  }

  return _foundBottleJsonResult(
    result: repository.findBottle(request.bottleId),
    bottleId: request.bottleId,
    onFound: (bottle) {
      return _runProgramPathJsonResult(
        bottleRepository: repository,
        programRunPlanner: context.programRunPlanner,
        programRunner: runner,
        bottle: bottle,
        programPath: request.programPath,
        oneTimeSettings: request.settings,
        beforeRun: (programRunRequest) {
          final dllSyncFailure = _syncRuntimeSettingsDllOverrides(
            bottle: bottle,
            runtimeSettings: bottle.runtimeSettings,
            programRunPlanner: context.programRunPlanner,
          );
          if (dllSyncFailure != null) {
            return dllSyncFailure;
          }

          _recordExternalProgramRun(bottle: bottle, request: programRunRequest);
          _synchronizeLinuxDesktopLauncherForProgramRun(
            hostPlatform: context.programRunPlanner.hostPlatform,
            environment: context.programRunPlanner.environment.toMap(),
            bottle: bottle,
            request: programRunRequest,
            programMetadataExtractor: context.programMetadataExtractor,
            diagnosticSink: context.linuxExternalProgramLauncherDiagnosticSink,
          );

          return null;
        },
      );
    },
  );
}

typedef _ProgramRunPreparation = CliResult? Function(ProgramRunRequest request);

CliResult _runProgramPathJsonResult({
  required BottleRepository bottleRepository,
  required ProgramRunPlanner programRunPlanner,
  required ProgramRunner programRunner,
  required BottleRecord bottle,
  required String programPath,
  Option<ProgramSettingsRecord> oneTimeSettings = const Option.none(),
  _ProgramRunPreparation? beforeRun,
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
      return _bottleRepositoryFailureJsonResult(message);
  }

  final effectiveProgramSettings = _programRunSettings(
    storedSettings: storedSettings,
    oneTimeSettings: oneTimeSettings,
  );
  final programRunRequest = programRunPlanner.plan(
    bottle: bottle,
    programPath: programPath,
    programSettings: Option.of(effectiveProgramSettings),
  );
  return programRunRequest.match(
    () => _jsonError(
      exitCode: 65,
      code: 'unsupportedProgramType',
      message: 'Program type is not supported.',
      extra: <String, Object?>{'programPath': programPath},
    ),
    (request) {
      final preparationFailure = beforeRun?.call(request);
      if (preparationFailure != null) {
        return preparationFailure;
      }

      return _programRunResultJson(request, programRunner);
    },
  );
}

ProgramSettingsRecord _programRunSettings({
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

CliResult _runWinetricksJsonResult(
  _WinetricksRunCliRequest request,
  _CliCommandContext context,
) {
  final repository = context.bottleRepository;
  if (repository == null) {
    return _bottleRepositoryUnavailableError();
  }

  final runner = context.programRunner;
  if (runner == null) {
    return _programRunnerUnavailableError();
  }

  return _foundBottleJsonResult(
    result: repository.findBottle(request.bottleId),
    bottleId: request.bottleId,
    onFound: (bottle) {
      final programRunRequest = context.programRunPlanner.planWinetricksVerb(
        bottle: bottle,
        verb: request.verb,
      );
      return programRunRequest.match(
        () => _jsonError(
          exitCode: 65,
          code: 'unsupportedWinetricksVerb',
          message: 'Winetricks verb is not supported.',
          extra: <String, Object?>{'verb': request.verb},
        ),
        (request) => _programRunResultJson(request, runner),
      );
    },
  );
}

CliResult _runBottleCommandJsonResult(
  _BottleCommandRunCliRequest request,
  _CliCommandContext context,
) {
  final repository = context.bottleRepository;
  if (repository == null) {
    return _bottleRepositoryUnavailableError();
  }

  final runner = context.programRunner;
  if (runner == null) {
    return _programRunnerUnavailableError();
  }

  return _foundBottleJsonResult(
    result: repository.findBottle(request.bottleId),
    bottleId: request.bottleId,
    onFound: (bottle) {
      final programRunRequest = context.programRunPlanner.planBottleCommand(
        bottle: bottle,
        command: request.command,
      );
      return programRunRequest.match(
        () => _jsonError(
          exitCode: 65,
          code: 'unsupportedBottleCommand',
          message: 'Bottle command is not supported.',
          extra: <String, Object?>{'command': request.command},
        ),
        (request) => _programRunResultJson(request, runner),
      );
    },
  );
}

CliResult _programRunResultJson(
  ProgramRunRequest request,
  ProgramRunner runner,
) {
  return switch (runner.run(request)) {
    ProgramRunCompleted(:final processExitCode) => _programRunJsonResult(
      request: request,
      processExitCode: processExitCode,
    ),
    ProgramRunFailed(:final message) => _programRunFailedJsonResult(
      request: request,
      message: message,
    ),
  };
}

CliResult _programRunnerUnavailableError() {
  return _unavailableJsonError(
    code: 'programRunnerUnavailable',
    subject: 'Program runner',
  );
}
