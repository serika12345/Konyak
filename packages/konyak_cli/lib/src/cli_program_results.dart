part of '../konyak_cli.dart';

CliResult _programUpdateJsonResult(ProgramUpdateResult result) {
  return switch (result) {
    ProgramUpdated(:final bottle) => _bottleJsonResult(bottle),
    ProgramUpdateMissingBottle(:final bottleId) => _bottleNotFoundError(
      bottleId,
    ),
    ProgramUpdateMissingProgram(:final programPath) => _jsonError(
      exitCode: 66,
      code: 'programNotPinned',
      message: 'Program is not pinned.',
      extra: <String, Object?>{'programPath': programPath},
    ),
    ProgramUpdateFailed(:final message) => _bottleRepositoryFailureJsonResult(
      message,
    ),
  };
}

CliResult _runPinnedProgramLauncherCli({
  required _PinnedProgramLaunchCliRequest request,
  required BottleRepository? bottleRepository,
  required ProgramRunPlanner programRunPlanner,
  required ProgramRunner? programRunner,
}) {
  final launcherManifest = _readPinnedProgramLauncherManifest(
    request.manifestPath,
  );
  return launcherManifest.match(
    () => _jsonError(
      exitCode: 65,
      code: 'invalidPinnedProgramLauncher',
      message: 'Pinned program launcher manifest is invalid.',
      extra: <String, Object?>{'manifestPath': request.manifestPath},
    ),
    (manifest) {
      if (bottleRepository == null) {
        return _bottleRepositoryUnavailableError();
      }

      if (programRunner == null) {
        return _programRunnerUnavailableError();
      }

      return _foundBottleJsonResult(
        result: bottleRepository.findBottle(manifest.bottleId),
        bottleId: manifest.bottleId,
        onFound: (bottle) {
          final expectedLauncherId = _pinnedProgramLauncherId(
            bottleId: manifest.bottleId,
            programPath: manifest.programPath,
          );
          if (manifest.launcherId != expectedLauncherId ||
              !_hasPinnedProgram(bottle, manifest.programPath)) {
            return _jsonError(
              exitCode: 66,
              code: 'programNotPinned',
              message: 'Program is not pinned.',
              extra: <String, Object?>{'programPath': manifest.programPath},
            );
          }

          final settingsResult = bottleRepository.readProgramSettings(
            ProgramSettingsRequest(
              bottleId: bottle.id,
              programPath: manifest.programPath,
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
          final programRunRequest = programRunPlanner.plan(
            bottle: bottle,
            programPath: manifest.programPath,
            programSettings: Option.of(programSettings),
          );
          return programRunRequest.match(
            () => _jsonError(
              exitCode: 65,
              code: 'unsupportedProgramType',
              message: 'Program type is not supported.',
              extra: <String, Object?>{'programPath': manifest.programPath},
            ),
            (request) {
              final runResult = programRunner.run(request);

              return switch (runResult) {
                ProgramRunCompleted(:final processExitCode) =>
                  _programRunJsonResult(
                    request: request,
                    processExitCode: processExitCode,
                  ),
                ProgramRunFailed(:final message) => _programRunFailedJsonResult(
                  request: request,
                  message: message,
                ),
              };
            },
          );
        },
      );
    },
  );
}

CliResult _programSettingsReadJsonResult({
  required ProgramSettingsRequest request,
  required ProgramSettingsReadResult result,
}) {
  return switch (result) {
    ProgramSettingsRead(:final settings) => _programSettingsJsonResult(
      bottleId: request.bottleId,
      programPath: request.programPath,
      settings: settings,
    ),
    ProgramSettingsReadMissingBottle(:final bottleId) => _bottleNotFoundError(
      bottleId,
    ),
    ProgramSettingsReadFailed(:final message) =>
      _bottleRepositoryFailureJsonResult(message),
  };
}

CliResult _programSettingsUpdateJsonResult({
  required ProgramSettingsUpdateRequest request,
  required ProgramSettingsUpdateResult result,
}) {
  return switch (result) {
    ProgramSettingsUpdated(:final settings) => _programSettingsJsonResult(
      bottleId: request.bottleId,
      programPath: request.programPath,
      settings: settings,
    ),
    ProgramSettingsUpdateMissingBottle(:final bottleId) => _bottleNotFoundError(
      bottleId,
    ),
    ProgramSettingsUpdateFailed(:final message) =>
      _bottleRepositoryFailureJsonResult(message),
  };
}

CliResult _programSettingsJsonResult({
  required String bottleId,
  required String programPath,
  required ProgramSettingsRecord settings,
}) {
  return _jsonSuccess(<String, Object?>{
    'programSettings': <String, Object?>{
      'bottleId': bottleId,
      'programPath': programPath,
      'settings': settings.toJson(),
    },
  });
}
