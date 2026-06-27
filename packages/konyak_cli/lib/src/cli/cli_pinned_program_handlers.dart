part of '../../konyak_cli.dart';

CliResult? _handlePinnedProgramCommand(
  List<String> arguments,
  _CliCommandContext context,
) {
  final programPinRequest = _parseJsonProgramPinRequest(arguments);
  if (programPinRequest != null) {
    if (!_isSupportedProgramPath(programPinRequest.programPath.value)) {
      return _jsonError(
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
      return _bottleRepositoryUnavailableError();
    }

    final pinResult = repository.pinProgram(programPinRequest);
    if (pinResult is ProgramPinned) {
      final bottlesResult = repository.listBottles();
      final failure = bottlesResult.fold<CliResult?>(
        _bottleCatalogFailureJsonResult,
        (_) => null,
      );
      if (failure != null) {
        return failure;
      }
      _synchronizePinnedProgramLaunchers(
        hostPlatform: context.programRunPlanner.hostPlatform,
        environment: context.programRunPlanner.environment.toMap(),
        bottles: bottlesResult.getOrElse((_) => const <BottleRecord>[]),
      );
    }

    return switch (pinResult) {
      ProgramPinned(:final bottle) => _bottleJsonResult(bottle),
      ProgramPinMissing(:final bottleId) => _bottleNotFoundError(
        bottleId.value,
      ),
      ProgramPinConflict(:final programPath) => _jsonError(
        exitCode: 73,
        code: 'programAlreadyPinned',
        message: 'Program is already pinned.',
        extra: <String, Object?>{'programPath': programPath.value},
      ),
      ProgramPinFailed(:final message) => _bottleRepositoryFailureJsonResult(
        message,
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
      final bottlesResult = repository.listBottles();
      final failure = bottlesResult.fold<CliResult?>(
        _bottleCatalogFailureJsonResult,
        (_) => null,
      );
      if (failure != null) {
        return failure;
      }
      _synchronizePinnedProgramLaunchers(
        hostPlatform: context.programRunPlanner.hostPlatform,
        environment: context.programRunPlanner.environment.toMap(),
        bottles: bottlesResult.getOrElse((_) => const <BottleRecord>[]),
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
      final bottlesResult = repository.listBottles();
      final failure = bottlesResult.fold<CliResult?>(
        _bottleCatalogFailureJsonResult,
        (_) => null,
      );
      if (failure != null) {
        return failure;
      }
      _synchronizePinnedProgramLaunchers(
        hostPlatform: context.programRunPlanner.hostPlatform,
        environment: context.programRunPlanner.environment.toMap(),
        bottles: bottlesResult.getOrElse((_) => const <BottleRecord>[]),
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
