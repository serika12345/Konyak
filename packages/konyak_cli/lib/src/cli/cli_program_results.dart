part of '../../konyak_cli.dart';

CliResult _programUpdateJsonResult(ProgramUpdateResult result) {
  return switch (result) {
    ProgramUpdated(:final bottle) => _bottleJsonResult(bottle),
    ProgramUpdateMissingBottle(:final bottleId) => _bottleNotFoundError(
      bottleId.value,
    ),
    ProgramUpdateMissingProgram(:final programPath) => _jsonError(
      exitCode: 66,
      code: 'programNotPinned',
      message: 'Program is not pinned.',
      extra: <String, Object?>{'programPath': programPath.value},
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
        result: bottleRepository.findBottle(manifest.bottleId.value),
        bottleId: manifest.bottleId.value,
        onFound: (bottle) {
          final expectedLauncherId = _pinnedProgramLauncherId(
            bottleId: manifest.bottleId.value,
            programPath: manifest.programPath.value,
          );
          if (manifest.launcherId.value != expectedLauncherId ||
              !_hasPinnedProgram(bottle, manifest.programPath.value)) {
            return _jsonError(
              exitCode: 66,
              code: 'programNotPinned',
              message: 'Program is not pinned.',
              extra: <String, Object?>{
                'programPath': manifest.programPath.value,
              },
            );
          }

          return _runProgramPathJsonResult(
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

CliResult _programSettingsReadJsonResult({
  required ProgramSettingsRequest request,
  required ProgramSettingsReadResult result,
}) {
  return switch (result) {
    ProgramSettingsRead(:final settings) => _programSettingsJsonResult(
      bottleId: request.bottleId.value,
      programPath: request.programPath.value,
      settings: settings,
    ),
    ProgramSettingsReadMissingBottle(:final bottleId) => _bottleNotFoundError(
      bottleId.value,
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
      bottleId: request.bottleId.value,
      programPath: request.programPath.value,
      settings: settings,
    ),
    ProgramSettingsUpdateMissingBottle(:final bottleId) => _bottleNotFoundError(
      bottleId.value,
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
