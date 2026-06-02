part of '../konyak_cli.dart';

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

  final bottle = repository.findBottle(request.bottleId);
  if (bottle == null) {
    return _bottleNotFoundError(request.bottleId);
  }

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
    programSettings: programSettings,
  );
  if (programRunRequest == null) {
    return _jsonError(
      exitCode: 65,
      code: 'unsupportedProgramType',
      message: 'Program type is not supported.',
      extra: <String, Object?>{'programPath': request.programPath},
    );
  }

  _recordExternalProgramRun(bottle: bottle, request: programRunRequest);
  _synchronizeLinuxDesktopLauncherForProgramRun(
    hostPlatform: context.programRunPlanner.hostPlatform,
    environment: context.programRunPlanner.environment,
    bottle: bottle,
    request: programRunRequest,
  );

  return _programRunResultJson(programRunRequest, runner);
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

  final bottle = repository.findBottle(request.bottleId);
  if (bottle == null) {
    return _bottleNotFoundError(request.bottleId);
  }

  final programRunRequest = context.programRunPlanner.planWinetricksVerb(
    bottle: bottle,
    verb: request.verb,
  );
  if (programRunRequest == null) {
    return _jsonError(
      exitCode: 65,
      code: 'unsupportedWinetricksVerb',
      message: 'Winetricks verb is not supported.',
      extra: <String, Object?>{'verb': request.verb},
    );
  }

  final winetricksReady = _ensureWinetricksScriptForRun(
    request: programRunRequest,
    scriptInstaller: context.winetricksScriptInstaller,
  );
  if (winetricksReady != null) {
    return winetricksReady;
  }

  return _programRunResultJson(programRunRequest, runner);
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

  final bottle = repository.findBottle(request.bottleId);
  if (bottle == null) {
    return _bottleNotFoundError(request.bottleId);
  }

  final programRunRequest = context.programRunPlanner.planBottleCommand(
    bottle: bottle,
    command: request.command,
  );
  if (programRunRequest == null) {
    return _jsonError(
      exitCode: 65,
      code: 'unsupportedBottleCommand',
      message: 'Bottle command is not supported.',
      extra: <String, Object?>{'command': request.command},
    );
  }

  final winetricksReady = _ensureWinetricksScriptForRun(
    request: programRunRequest,
    scriptInstaller: context.winetricksScriptInstaller,
  );
  if (winetricksReady != null) {
    return winetricksReady;
  }

  return _programRunResultJson(programRunRequest, runner);
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
