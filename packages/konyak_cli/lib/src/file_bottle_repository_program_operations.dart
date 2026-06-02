part of '../konyak_cli.dart';

class _FileBottleRepositoryProgramOperations {
  const _FileBottleRepositoryProgramOperations({
    required ProgramMetadataExtractor programMetadataExtractor,
    required BottleRecord? Function(String id) findBottle,
  }) : _programMetadataExtractor = programMetadataExtractor,
       _findBottle = findBottle;

  final ProgramMetadataExtractor _programMetadataExtractor;
  final BottleRecord? Function(String id) _findBottle;

  ProgramPinResult pinProgram(ProgramPinRequest request) {
    final bottle = _findBottle(request.bottleId);
    if (bottle == null) {
      return ProgramPinMissing(request.bottleId);
    }

    if (_hasPinnedProgram(bottle, request.programPath)) {
      return ProgramPinConflict(request.programPath);
    }

    final updated = _bottleWithPinnedProgram(
      bottle,
      request,
      programMetadataExtractor: _programMetadataExtractor,
    );

    final writeResult = _repositoryIoResult(() {
      _writeBottleMetadata(updated);
    });
    final failure = writeResult.fold<ProgramPinResult?>(
      ProgramPinFailed.new,
      (_) => null,
    );
    if (failure != null) {
      return failure;
    }

    return ProgramPinned(updated);
  }

  ProgramUpdateResult unpinProgram(ProgramUnpinRequest request) {
    final bottle = _findBottle(request.bottleId);
    if (bottle == null) {
      return ProgramUpdateMissingBottle(request.bottleId);
    }

    if (!_hasPinnedProgram(bottle, request.programPath)) {
      return ProgramUpdateMissingProgram(request.programPath);
    }

    final updated = _bottleWithoutPinnedProgram(bottle, request.programPath);

    final writeResult = _repositoryIoResult(() {
      _writeBottleMetadata(updated);
    });
    final failure = writeResult.fold<ProgramUpdateResult?>(
      ProgramUpdateFailed.new,
      (_) => null,
    );
    if (failure != null) {
      return failure;
    }

    return ProgramUpdated(updated);
  }

  ProgramUpdateResult renamePinnedProgram(ProgramRenameRequest request) {
    final bottle = _findBottle(request.bottleId);
    if (bottle == null) {
      return ProgramUpdateMissingBottle(request.bottleId);
    }

    if (!_hasPinnedProgram(bottle, request.programPath)) {
      return ProgramUpdateMissingProgram(request.programPath);
    }

    final updated = _bottleWithRenamedPinnedProgram(bottle, request);

    final writeResult = _repositoryIoResult(() {
      _writeBottleMetadata(updated);
    });
    final failure = writeResult.fold<ProgramUpdateResult?>(
      ProgramUpdateFailed.new,
      (_) => null,
    );
    if (failure != null) {
      return failure;
    }

    return ProgramUpdated(updated);
  }

  ProgramSettingsReadResult readProgramSettings(
    ProgramSettingsRequest request,
  ) {
    final bottle = _findBottle(request.bottleId);
    if (bottle == null) {
      return ProgramSettingsReadMissingBottle(request.bottleId);
    }

    final readResult = _repositoryIoResult(
      () => _readProgramSettingsJson(
        _programSettingsJsonPath(
          bottle: bottle,
          programPath: request.programPath,
        ),
      ),
    );
    return readResult.fold<ProgramSettingsReadResult>(
      ProgramSettingsReadFailed.new,
      ProgramSettingsRead.new,
    );
  }

  ProgramSettingsUpdateResult setProgramSettings(
    ProgramSettingsUpdateRequest request,
  ) {
    final bottle = _findBottle(request.bottleId);
    if (bottle == null) {
      return ProgramSettingsUpdateMissingBottle(request.bottleId);
    }

    final writeResult = _repositoryIoResult(() {
      _writeProgramSettingsJson(
        path: _programSettingsJsonPath(
          bottle: bottle,
          programPath: request.programPath,
        ),
        settings: request.settings,
      );
    });
    final failure = writeResult.fold<ProgramSettingsUpdateResult?>(
      ProgramSettingsUpdateFailed.new,
      (_) => null,
    );
    if (failure != null) {
      return failure;
    }

    return ProgramSettingsUpdated(request.settings);
  }
}
