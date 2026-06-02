part of '../../konyak_cli.dart';

CliResult? _handleProgramRunCommand(
  List<String> arguments,
  _CliCommandContext context,
) {
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
      final settingsResult = repository.readProgramSettings(
        ProgramSettingsRequest(
          bottleId: bottle.id,
          programPath: request.programPath,
        ),
      );
      final ProgramSettingsRecord programSettings;
      switch (settingsResult) {
        case ProgramSettingsRead(:final settings):
          programSettings = settings;
        case ProgramSettingsReadMissingBottle():
          programSettings = ProgramSettingsRecord();
        case ProgramSettingsReadFailed(:final message):
          return _bottleRepositoryFailureJsonResult(message);
      }

      final programRunRequest = context.programRunPlanner.plan(
        bottle: bottle,
        programPath: request.programPath,
        programSettings: Option.of(programSettings),
      );
      return programRunRequest.match(
        () => _jsonError(
          exitCode: 65,
          code: 'unsupportedProgramType',
          message: 'Program type is not supported.',
          extra: <String, Object?>{'programPath': request.programPath},
        ),
        (request) {
          _recordExternalProgramRun(bottle: bottle, request: request);
          _synchronizeLinuxDesktopLauncherForProgramRun(
            hostPlatform: context.programRunPlanner.hostPlatform,
            environment: context.programRunPlanner.environment.toMap(),
            bottle: bottle,
            request: request,
            programMetadataExtractor: context.programMetadataExtractor,
            diagnosticSink: context.linuxExternalProgramLauncherDiagnosticSink,
          );

          return _programRunResultJson(request, runner);
        },
      );
    },
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
        (request) {
          final winetricksReady = _ensureWinetricksScriptForRun(
            request: request,
            scriptInstaller: context.winetricksScriptInstaller,
          );
          if (winetricksReady != null) {
            return winetricksReady;
          }

          return _programRunResultJson(request, runner);
        },
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
        (request) {
          final winetricksReady = _ensureWinetricksScriptForRun(
            request: request,
            scriptInstaller: context.winetricksScriptInstaller,
          );
          if (winetricksReady != null) {
            return winetricksReady;
          }

          return _programRunResultJson(request, runner);
        },
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
