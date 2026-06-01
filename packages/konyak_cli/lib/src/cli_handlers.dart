part of '../konyak_cli.dart';

CliResult? _handleAppCommand(
  List<String> arguments,
  _CliCommandContext context,
) {
  if (_isJsonAppUpdateCheckCommand(arguments)) {
    final checker = context.appUpdateChecker;
    if (checker == null) {
      return _unavailableJsonError(
        code: 'appUpdateCheckerUnavailable',
        subject: 'App update checker',
      );
    }

    return switch (checker.check()) {
      AppUpdateCheckCompleted(:final update) => _appUpdateJsonResult(update),
      AppUpdateCheckFailed(:final message) => _jsonError(
        exitCode: 75,
        code: 'appUpdateCheckFailed',
        message: message,
      ),
    };
  }

  if (_isJsonAppSettingsGetCommand(arguments)) {
    final repository = context.appSettingsRepository;
    if (repository == null) {
      return _appSettingsRepositoryUnavailableError();
    }

    return _appSettingsJsonResult(repository.read());
  }

  final appSettingsUpdate = _parseJsonAppSettingsUpdateRequest(arguments);
  if (appSettingsUpdate != null) {
    final repository = context.appSettingsRepository;
    if (repository == null) {
      return _appSettingsRepositoryUnavailableError();
    }

    return _appSettingsJsonResult(repository.write(appSettingsUpdate));
  }

  if (_isJsonAppUpdateInstallCommand(arguments)) {
    return _installAppUpdateJsonResult(
      appUpdateChecker: context.appUpdateChecker,
      appUpdateInstaller: context.appUpdateInstaller,
    );
  }

  return null;
}

CliResult? _handleHostIntegrationCommand(
  List<String> arguments,
  _CliCommandContext context,
) {
  if (!_isJsonLinuxFileAssociationInstallCommand(arguments)) {
    return null;
  }

  final result = _installLinuxFileAssociations(
    hostPlatform: context.programRunPlanner.hostPlatform,
    environment: context.programRunPlanner.environment,
  );
  return switch (result) {
    _LinuxFileAssociationsInstalled(
      :final desktopEntryPath,
      :final mimeAppsPath,
    ) =>
      _jsonSuccess(<String, Object?>{
        'linuxFileAssociations': <String, Object?>{
          'desktopEntryPath': desktopEntryPath,
          'mimeAppsPath': mimeAppsPath,
          'mimeTypes': _linuxExecutableMimeTypes,
        },
      }),
    _LinuxFileAssociationInstallFailed(:final message) => _jsonError(
      exitCode: 75,
      code: 'linuxFileAssociationInstallFailed',
      message: message,
    ),
  };
}

CliResult _appSettingsRepositoryUnavailableError() {
  return _unavailableJsonError(
    code: 'appSettingsRepositoryUnavailable',
    subject: 'App settings repository',
  );
}

CliResult? _handleRuntimeCommand(
  List<String> arguments,
  _CliCommandContext context,
) {
  if (_isJsonRuntimeListCommand(arguments)) {
    return _jsonSuccess(<String, Object?>{
      'runtimes': context.runtimeCatalog
          .listRuntimes()
          .map((runtime) => runtime.toJson())
          .toList(growable: false),
    });
  }

  if (_isJsonMacosSetupCheckCommand(arguments)) {
    final checker = context.macosSetupChecker;
    if (checker == null) {
      return _unavailableJsonError(
        code: 'macosSetupCheckerUnavailable',
        subject: 'macOS setup checker',
      );
    }

    return switch (checker.check()) {
      MacosSetupCheckCompleted(:final status) => _jsonSuccess(<String, Object?>{
        'macosSetup': status.toJson(),
      }),
      MacosSetupCheckFailed(:final message) => _jsonError(
        exitCode: 75,
        code: 'macosSetupCheckFailed',
        message: message,
      ),
    };
  }

  final gptkWineInstallRequest = _parseJsonGptkWineInstallRequest(arguments);
  if (gptkWineInstallRequest != null) {
    final installer = context.gptkWineInstaller;
    if (installer == null) {
      return _unavailableJsonError(
        code: 'gptkWineInstallerUnavailable',
        subject: 'GPTK-compatible Wine installer',
      );
    }

    return switch (installer.install(gptkWineInstallRequest)) {
      GptkWineInstallCompleted(:final record) => _jsonSuccess(<String, Object?>{
        'gptkWineInstall': record.toJson(),
      }),
      GptkWineInstallFailed(:final message) => _jsonError(
        exitCode: 75,
        code: 'gptkWineInstallFailed',
        message: message,
      ),
    };
  }

  final openUrl = _parseJsonOpenUrlCommand(arguments);
  if (openUrl != null) {
    return _openUrlJsonResult(openUrl, context.pathOpener);
  }

  final runtimeUpdateId = _parseJsonRuntimeIdCommand(
    arguments,
    'check-runtime-update',
  );
  if (runtimeUpdateId != null) {
    return _runtimeUpdateCheckJsonResult(
      runtimeId: runtimeUpdateId,
      runtimeUpdateChecker: context.runtimeUpdateChecker,
    );
  }

  final runtimeUpdateInstallId = _parseJsonRuntimeIdCommand(
    arguments,
    'install-runtime-update',
  );
  if (runtimeUpdateInstallId != null) {
    return _installRuntimeUpdateJsonResult(
      runtimeId: runtimeUpdateInstallId,
      runtimeUpdateChecker: context.runtimeUpdateChecker,
      macosWineInstaller: context.macosWineInstaller,
      linuxWineInstaller: context.linuxWineInstaller,
    );
  }

  final runtimeValidationId = _parseJsonRuntimeIdCommand(
    arguments,
    'validate-runtime',
  );
  if (runtimeValidationId != null) {
    return _runtimeValidationJsonResult(
      runtimeId: runtimeValidationId,
      runtimeValidator: context.runtimeValidator,
    );
  }

  final macosWineInstallRequest = _parseJsonMacosWineInstallRequest(arguments);
  if (macosWineInstallRequest != null) {
    return _macosWineInstallJsonResult(
      request: macosWineInstallRequest,
      installer: context.macosWineInstaller,
      progressSink: context.runtimeInstallProgressSink,
    );
  }

  final linuxWineInstallRequest = _parseJsonLinuxWineInstallRequest(arguments);
  if (linuxWineInstallRequest != null) {
    return _linuxWineInstallJsonResult(
      request: linuxWineInstallRequest,
      installer: context.linuxWineInstaller,
      progressSink: context.runtimeInstallProgressSink,
    );
  }

  return null;
}

CliResult _openUrlJsonResult(String openUrl, PathOpener? pathOpener) {
  if (pathOpener == null) {
    return _pathOpenerUnavailableError();
  }
  final openResult = pathOpener.openPath(openUrl);
  return switch (openResult) {
    PathOpenCompleted() => _jsonSuccess(<String, Object?>{
      'openedUrl': <String, Object?>{'url': openUrl},
    }),
    PathOpenFailed(:final message) => _jsonError(
      exitCode: 75,
      code: 'urlOpenFailed',
      message: message,
      extra: <String, Object?>{'url': openUrl},
    ),
  };
}

CliResult _runtimeUpdateCheckJsonResult({
  required String runtimeId,
  required RuntimeUpdateChecker? runtimeUpdateChecker,
}) {
  if (runtimeUpdateChecker == null) {
    return _unavailableJsonError(
      code: 'runtimeUpdateCheckerUnavailable',
      subject: 'Runtime update checker',
    );
  }

  return switch (runtimeUpdateChecker.check(runtimeId)) {
    RuntimeUpdateCheckCompleted(:final update) => _jsonSuccess(
      <String, Object?>{'runtimeUpdate': update.toJson()},
    ),
    RuntimeUpdateRuntimeNotFound(:final runtimeId) => _jsonError(
      exitCode: 66,
      code: 'runtimeNotFound',
      message: 'Runtime not found.',
      extra: <String, Object?>{'runtimeId': runtimeId},
    ),
    RuntimeUpdateCheckFailed(:final message) => _jsonError(
      exitCode: 75,
      code: 'runtimeUpdateCheckFailed',
      message: message,
    ),
  };
}

CliResult _runtimeValidationJsonResult({
  required String runtimeId,
  required RuntimeValidator? runtimeValidator,
}) {
  if (runtimeValidator == null) {
    return _unavailableJsonError(
      code: 'runtimeValidatorUnavailable',
      subject: 'Runtime validator',
    );
  }

  return switch (runtimeValidator.validate(runtimeId)) {
    RuntimeValidationCompleted(:final validation) => _jsonSuccess(
      <String, Object?>{'runtimeValidation': validation.toJson()},
      exitCode: validation.isValid ? 0 : 75,
    ),
    RuntimeValidationRuntimeNotFound(:final runtimeId) => _jsonError(
      exitCode: 66,
      code: 'runtimeNotFound',
      message: 'Runtime not found.',
      extra: <String, Object?>{'runtimeId': runtimeId},
    ),
    RuntimeValidationFailed(:final message) => _jsonError(
      exitCode: 75,
      code: 'runtimeValidationFailed',
      message: message,
    ),
  };
}

CliResult _macosWineInstallJsonResult({
  required MacosWineInstallRequest request,
  required MacosWineInstaller? installer,
  required RuntimeInstallProgressSink? progressSink,
}) {
  if (installer == null) {
    return _unavailableJsonError(
      code: 'macosWineInstallerUnavailable',
      subject: 'macOS Wine installer',
    );
  }

  return _macosWineInstallCliResult(
    installer.install(
      request,
      progressSink: request.emitProgress ? progressSink : null,
    ),
  );
}

CliResult _linuxWineInstallJsonResult({
  required LinuxWineInstallRequest request,
  required LinuxWineInstaller? installer,
  required RuntimeInstallProgressSink? progressSink,
}) {
  if (installer == null) {
    return _unavailableJsonError(
      code: 'linuxWineInstallerUnavailable',
      subject: 'Linux Wine installer',
    );
  }

  return _linuxWineInstallCliResult(
    installer.install(
      request,
      progressSink: request.emitProgress ? progressSink : null,
    ),
  );
}

CliResult? _handleWineProcessCommand(
  List<String> arguments, {
  required _CliCommandContext context,
  required BottleCatalog activeBottleCatalog,
}) {
  if (_isJsonWineProcessListCommand(arguments)) {
    return _listWineProcessesJsonResult(
      bottleCatalog: activeBottleCatalog,
      programRunPlanner: context.programRunPlanner,
      programRunner: context.programRunner,
      programMetadataExtractor: context.programMetadataExtractor,
    );
  }

  final wineProcessTerminationRequest = _parseJsonWineProcessTerminationRequest(
    arguments,
  );
  if (wineProcessTerminationRequest != null) {
    return _terminateWineProcessJsonResult(
      bottleCatalog: activeBottleCatalog,
      programRunPlanner: context.programRunPlanner,
      programRunner: context.programRunner,
      bottleId: wineProcessTerminationRequest.bottleId,
      processId: wineProcessTerminationRequest.processId,
    );
  }

  final wineProcessGroupTerminationRequest =
      _parseJsonWineProcessGroupTerminationRequest(arguments);
  if (wineProcessGroupTerminationRequest != null) {
    return _terminateWineProcessesJsonResult(
      bottleCatalog: activeBottleCatalog,
      programRunPlanner: context.programRunPlanner,
      programRunner: context.programRunner,
      bottleId: wineProcessGroupTerminationRequest.bottleId,
    );
  }

  return null;
}

CliResult? _handleBottleReadCommand(
  List<String> arguments, {
  required _CliCommandContext context,
  required BottleCatalog activeBottleCatalog,
}) {
  if (_isJsonBottleListCommand(arguments)) {
    final bottles = activeBottleCatalog.listBottles();
    _synchronizeMacosPinnedProgramLaunchers(
      hostPlatform: context.programRunPlanner.hostPlatform,
      environment: context.programRunPlanner.environment,
      bottles: bottles,
    );
    return _jsonSuccess(<String, Object?>{
      'bottles': bottles
          .map((bottle) => bottle.toJson())
          .toList(growable: false),
    });
  }

  if (_isJsonBottleInspectCommand(arguments)) {
    final bottleId = arguments[1];
    final bottle = activeBottleCatalog.findBottle(bottleId);
    if (bottle == null) {
      return _bottleNotFoundError(bottleId);
    }

    final inspectedBottle = _bottleWithRegistrySettings(
      bottle: bottle,
      programRunPlanner: context.programRunPlanner,
      programRunner: context.programRunner,
    );
    return _bottleJsonResult(inspectedBottle);
  }

  final bottleProgramsListId = _parseJsonBottleProgramsListCommand(arguments);
  if (bottleProgramsListId != null) {
    final bottle = activeBottleCatalog.findBottle(bottleProgramsListId);
    if (bottle == null) {
      return _bottleNotFoundError(bottleProgramsListId);
    }

    return _jsonSuccess(<String, Object?>{
      'bottlePrograms': <String, Object?>{
        'bottleId': bottle.id,
        'programs': context.bottleProgramRepository
            .listPrograms(bottle)
            .map((program) => program.toJson())
            .toList(growable: false),
      },
    });
  }

  return null;
}

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

    final bottle = repository.findBottle(windowsVersionUpdateRequest.bottleId);
    if (bottle == null) {
      return _bottleNotFoundError(windowsVersionUpdateRequest.bottleId);
    }

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
  }

  final runtimeSettingsUpdateRequest = _parseJsonRuntimeSettingsUpdateRequest(
    arguments,
  );
  if (runtimeSettingsUpdateRequest != null) {
    final repository = context.bottleRepository;
    if (repository == null) {
      return _bottleRepositoryUnavailableError();
    }

    final bottle = repository.findBottle(runtimeSettingsUpdateRequest.bottleId);
    if (bottle == null) {
      return _bottleNotFoundError(runtimeSettingsUpdateRequest.bottleId);
    }

    final registryUpdateFailure = _applyRuntimeSettingsRegistryUpdates(
      bottle: bottle,
      runtimeSettings: runtimeSettingsUpdateRequest.runtimeSettings,
      programRunPlanner: context.programRunPlanner,
      programRunner: context.programRunner,
    );
    if (registryUpdateFailure != null) {
      return registryUpdateFailure;
    }

    final dllSyncFailure = _syncRuntimeSettingsDllOverrides(
      bottle: bottle,
      runtimeSettings: runtimeSettingsUpdateRequest.runtimeSettings,
      programRunPlanner: context.programRunPlanner,
    );
    if (dllSyncFailure != null) {
      return dllSyncFailure;
    }

    return _bottleUpdateJsonResult(
      repository.setRuntimeSettings(runtimeSettingsUpdateRequest),
    );
  }

  return null;
}

CliResult _bottleUpdateJsonResult(BottleUpdateResult result) {
  return switch (result) {
    BottleUpdated(:final bottle) => _bottleJsonResult(bottle),
    BottleUpdateMissing(:final bottleId) => _bottleNotFoundError(bottleId),
  };
}

CliResult? _handlePinnedProgramCommand(
  List<String> arguments,
  _CliCommandContext context,
) {
  final programPinRequest = _parseJsonProgramPinRequest(arguments);
  if (programPinRequest != null) {
    if (!_isSupportedProgramPath(programPinRequest.programPath)) {
      return _jsonError(
        exitCode: 65,
        code: 'unsupportedProgramType',
        message: 'Program type is not supported.',
        extra: <String, Object?>{'programPath': programPinRequest.programPath},
      );
    }

    final repository = context.bottleRepository;
    if (repository == null) {
      return _bottleRepositoryUnavailableError();
    }

    final pinResult = repository.pinProgram(programPinRequest);
    if (pinResult is ProgramPinned) {
      _synchronizeMacosPinnedProgramLaunchers(
        hostPlatform: context.programRunPlanner.hostPlatform,
        environment: context.programRunPlanner.environment,
        bottles: repository.listBottles(),
      );
    }

    return switch (pinResult) {
      ProgramPinned(:final bottle) => _bottleJsonResult(bottle),
      ProgramPinMissing(:final bottleId) => _bottleNotFoundError(bottleId),
      ProgramPinConflict(:final programPath) => _jsonError(
        exitCode: 73,
        code: 'programAlreadyPinned',
        message: 'Program is already pinned.',
        extra: <String, Object?>{'programPath': programPath},
      ),
    };
  }

  final programUnpinRequest = _parseJsonProgramUnpinRequest(arguments);
  if (programUnpinRequest != null) {
    final repository = context.bottleRepository;
    if (repository == null) {
      return _bottleRepositoryUnavailableError();
    }

    final updateResult = repository.unpinProgram(programUnpinRequest);
    if (updateResult is ProgramUpdated) {
      _synchronizeMacosPinnedProgramLaunchers(
        hostPlatform: context.programRunPlanner.hostPlatform,
        environment: context.programRunPlanner.environment,
        bottles: repository.listBottles(),
      );
    }

    return _programUpdateJsonResult(updateResult);
  }

  final programRenameRequest = _parseJsonProgramRenameRequest(arguments);
  if (programRenameRequest != null) {
    final repository = context.bottleRepository;
    if (repository == null) {
      return _bottleRepositoryUnavailableError();
    }

    final updateResult = repository.renamePinnedProgram(programRenameRequest);
    if (updateResult is ProgramUpdated) {
      _synchronizeMacosPinnedProgramLaunchers(
        hostPlatform: context.programRunPlanner.hostPlatform,
        environment: context.programRunPlanner.environment,
        bottles: repository.listBottles(),
      );
    }

    return _programUpdateJsonResult(updateResult);
  }

  final pinnedProgramLaunchCliRequest = _parseJsonPinnedProgramLaunchCliRequest(
    arguments,
  );
  if (pinnedProgramLaunchCliRequest != null) {
    return _runPinnedProgramLauncherCli(
      request: pinnedProgramLaunchCliRequest,
      bottleRepository: context.bottleRepository,
      programRunPlanner: context.programRunPlanner,
      programRunner: context.programRunner,
    );
  }

  return null;
}

CliResult? _handleProgramSettingsCommand(
  List<String> arguments,
  _CliCommandContext context,
) {
  final programSettingsRequest = _parseJsonProgramSettingsRequest(arguments);
  if (programSettingsRequest != null) {
    final repository = context.bottleRepository;
    if (repository == null) {
      return _bottleRepositoryUnavailableError();
    }

    return _programSettingsReadJsonResult(
      request: programSettingsRequest,
      result: repository.readProgramSettings(programSettingsRequest),
    );
  }

  final programSettingsUpdateRequest = _parseJsonProgramSettingsUpdateRequest(
    arguments,
  );
  if (programSettingsUpdateRequest != null) {
    final repository = context.bottleRepository;
    if (repository == null) {
      return _bottleRepositoryUnavailableError();
    }

    return _programSettingsUpdateJsonResult(
      request: programSettingsUpdateRequest,
      result: repository.setProgramSettings(programSettingsUpdateRequest),
    );
  }

  return null;
}

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
  final programSettings = switch (settingsResult) {
    ProgramSettingsRead(:final settings) => settings,
    ProgramSettingsReadMissingBottle() => const ProgramSettingsRecord(),
  };

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

CliResult? _handleLocationCommand(
  List<String> arguments,
  _CliCommandContext context,
) {
  final bottleLocationOpenCliRequest = _parseJsonBottleLocationOpenCliRequest(
    arguments,
  );
  if (bottleLocationOpenCliRequest != null) {
    return _openBottleLocationJsonResult(bottleLocationOpenCliRequest, context);
  }

  final programLocationOpenCliRequest = _parseJsonProgramLocationOpenCliRequest(
    arguments,
  );
  if (programLocationOpenCliRequest != null) {
    return _openProgramLocationJsonResult(
      programLocationOpenCliRequest,
      context,
    );
  }

  return null;
}

CliResult _openBottleLocationJsonResult(
  _BottleLocationOpenCliRequest request,
  _CliCommandContext context,
) {
  final repository = context.bottleRepository;
  if (repository == null) {
    return _bottleRepositoryUnavailableError();
  }

  final opener = context.pathOpener;
  if (opener == null) {
    return _pathOpenerUnavailableError();
  }

  final bottle = repository.findBottle(request.bottleId);
  if (bottle == null) {
    return _bottleNotFoundError(request.bottleId);
  }

  final path = _bottleLocationPath(bottle: bottle, location: request.location);
  if (path == null) {
    return _jsonError(
      exitCode: 65,
      code: 'unsupportedBottleLocation',
      message: 'Bottle location is not supported.',
      extra: <String, Object?>{'location': request.location},
    );
  }

  return switch (opener.openPath(path)) {
    PathOpenCompleted() => _jsonSuccess(<String, Object?>{
      'openedLocation': <String, Object?>{
        'bottleId': bottle.id,
        'location': request.location,
        'path': path,
      },
    }),
    PathOpenFailed(:final message) => _jsonError(
      exitCode: 75,
      code: 'bottleLocationOpenFailed',
      message: message,
      extra: <String, Object?>{
        'bottleId': bottle.id,
        'location': request.location,
        'path': path,
      },
    ),
  };
}

CliResult _openProgramLocationJsonResult(
  _ProgramLocationOpenCliRequest request,
  _CliCommandContext context,
) {
  final repository = context.bottleRepository;
  if (repository == null) {
    return _bottleRepositoryUnavailableError();
  }

  final opener = context.pathOpener;
  if (opener == null) {
    return _pathOpenerUnavailableError();
  }

  final bottle = repository.findBottle(request.bottleId);
  if (bottle == null) {
    return _bottleNotFoundError(request.bottleId);
  }

  if (!_hasPinnedProgram(bottle, request.programPath)) {
    return _jsonError(
      exitCode: 66,
      code: 'programNotPinned',
      message: 'Program is not pinned.',
      extra: <String, Object?>{'programPath': request.programPath},
    );
  }

  final path = request.programPath;
  return switch (opener.revealPath(path)) {
    PathOpenCompleted() => _jsonSuccess(<String, Object?>{
      'openedProgramLocation': <String, Object?>{
        'bottleId': bottle.id,
        'programPath': request.programPath,
        'path': path,
      },
    }),
    PathOpenFailed(:final message) => _jsonError(
      exitCode: 75,
      code: 'programLocationOpenFailed',
      message: message,
      extra: <String, Object?>{
        'bottleId': bottle.id,
        'programPath': request.programPath,
        'path': path,
      },
    ),
  };
}

CliResult _pathOpenerUnavailableError() {
  return _unavailableJsonError(
    code: 'pathOpenerUnavailable',
    subject: 'Path opener',
  );
}

CliResult? _handleWinetricksVerbCommand(
  List<String> arguments,
  _CliCommandContext context,
) {
  if (!_isJsonWinetricksVerbListCommand(arguments)) {
    return null;
  }

  return _winetricksVerbListJsonResult(
    context.winetricksVerbRepository.listVerbs(),
  );
}

CliResult _winetricksVerbListJsonResult(WinetricksVerbListResult result) {
  return switch (result) {
    WinetricksVerbListCompleted(:final categories) => _jsonSuccess(
      <String, Object?>{
        'winetricks': <String, Object?>{
          'categories': categories
              .map((category) => category.toJson())
              .toList(growable: false),
        },
      },
    ),
    WinetricksVerbListFailed(:final message) => _jsonError(
      exitCode: 75,
      code: 'winetricksVerbsUnavailable',
      message: message,
    ),
  };
}
