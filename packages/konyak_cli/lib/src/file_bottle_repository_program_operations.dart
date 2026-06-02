part of '../konyak_cli.dart';

mixin _FileBottleRepositoryProgramOperations {
  ProgramMetadataExtractor get _programMetadataExtractor;

  BottleRecord? findBottle(String id);
  ProgramPinResult pinProgram(ProgramPinRequest request) {
    final bottle = findBottle(request.bottleId);
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

    try {
      _writeBottleMetadata(updated);
    } on FileSystemException catch (error) {
      throw BottleRepositoryException(error.message);
    }

    return ProgramPinned(updated);
  }

  ProgramUpdateResult unpinProgram(ProgramUnpinRequest request) {
    final bottle = findBottle(request.bottleId);
    if (bottle == null) {
      return ProgramUpdateMissingBottle(request.bottleId);
    }

    if (!_hasPinnedProgram(bottle, request.programPath)) {
      return ProgramUpdateMissingProgram(request.programPath);
    }

    final updated = _bottleWithoutPinnedProgram(bottle, request.programPath);

    try {
      _writeBottleMetadata(updated);
    } on FileSystemException catch (error) {
      throw BottleRepositoryException(error.message);
    }

    return ProgramUpdated(updated);
  }

  ProgramUpdateResult renamePinnedProgram(ProgramRenameRequest request) {
    final bottle = findBottle(request.bottleId);
    if (bottle == null) {
      return ProgramUpdateMissingBottle(request.bottleId);
    }

    if (!_hasPinnedProgram(bottle, request.programPath)) {
      return ProgramUpdateMissingProgram(request.programPath);
    }

    final updated = _bottleWithRenamedPinnedProgram(bottle, request);

    try {
      _writeBottleMetadata(updated);
    } on FileSystemException catch (error) {
      throw BottleRepositoryException(error.message);
    }

    return ProgramUpdated(updated);
  }

  ProgramSettingsReadResult readProgramSettings(
    ProgramSettingsRequest request,
  ) {
    final bottle = findBottle(request.bottleId);
    if (bottle == null) {
      return ProgramSettingsReadMissingBottle(request.bottleId);
    }

    try {
      return ProgramSettingsRead(
        _readProgramSettingsJson(
          _programSettingsJsonPath(
            bottle: bottle,
            programPath: request.programPath,
          ),
        ),
      );
    } on FileSystemException catch (error) {
      throw BottleRepositoryException(error.message);
    } on FormatException catch (error) {
      throw BottleRepositoryException(error.message);
    }
  }

  ProgramSettingsUpdateResult setProgramSettings(
    ProgramSettingsUpdateRequest request,
  ) {
    final bottle = findBottle(request.bottleId);
    if (bottle == null) {
      return ProgramSettingsUpdateMissingBottle(request.bottleId);
    }

    try {
      _writeProgramSettingsJson(
        path: _programSettingsJsonPath(
          bottle: bottle,
          programPath: request.programPath,
        ),
        settings: request.settings,
      );
    } on FileSystemException catch (error) {
      throw BottleRepositoryException(error.message);
    }

    return ProgramSettingsUpdated(request.settings);
  }
}
