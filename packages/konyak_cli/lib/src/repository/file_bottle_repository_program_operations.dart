part of '../../konyak_cli.dart';

class _FileBottleRepositoryProgramOperations {
  const _FileBottleRepositoryProgramOperations({
    required ProgramMetadataExtractor programMetadataExtractor,
    required IoResult<Option<BottleRecord>> Function(String id) findBottle,
  }) : _programMetadataExtractor = programMetadataExtractor,
       _findBottle = findBottle;

  final ProgramMetadataExtractor _programMetadataExtractor;
  final IoResult<Option<BottleRecord>> Function(String id) _findBottle;

  ProgramPinResult pinProgram(ProgramPinRequest request) {
    return _findBottle(request.bottleId.value).fold<ProgramPinResult>(
      ProgramPinFailed.new,
      (bottle) => bottle.match(
        () => ProgramPinMissing(request.bottleId.value),
        (bottle) {
          if (_hasPinnedProgram(bottle, request.programPath.value)) {
            return ProgramPinConflict(request.programPath.value);
          }

          final updated = _bottleWithPinnedProgram(
            bottle,
            request,
            programMetadataExtractor: _programMetadataExtractor,
          );

          final writeResult = _ioResult(() {
            _writeBottleMetadata(updated);
          });
          return writeResult.fold<ProgramPinResult>(
            ProgramPinFailed.new,
            (_) => ProgramPinned(updated),
          );
        },
      ),
    );
  }

  ProgramUpdateResult unpinProgram(ProgramUnpinRequest request) {
    return _findBottle(request.bottleId.value).fold<ProgramUpdateResult>(
      ProgramUpdateFailed.new,
      (bottle) => bottle.match(
        () => ProgramUpdateMissingBottle(request.bottleId.value),
        (bottle) {
          if (!_hasPinnedProgram(bottle, request.programPath.value)) {
            return ProgramUpdateMissingProgram(request.programPath.value);
          }

          final updated = _bottleWithoutPinnedProgram(
            bottle,
            request.programPath.value,
          );

          final writeResult = _ioResult(() {
            _writeBottleMetadata(updated);
          });
          return writeResult.fold<ProgramUpdateResult>(
            ProgramUpdateFailed.new,
            (_) => ProgramUpdated(updated),
          );
        },
      ),
    );
  }

  ProgramUpdateResult renamePinnedProgram(ProgramRenameRequest request) {
    return _findBottle(request.bottleId.value).fold<ProgramUpdateResult>(
      ProgramUpdateFailed.new,
      (bottle) => bottle.match(
        () => ProgramUpdateMissingBottle(request.bottleId.value),
        (bottle) {
          if (!_hasPinnedProgram(bottle, request.programPath.value)) {
            return ProgramUpdateMissingProgram(request.programPath.value);
          }

          final updated = _bottleWithRenamedPinnedProgram(bottle, request);

          final writeResult = _ioResult(() {
            _writeBottleMetadata(updated);
          });
          return writeResult.fold<ProgramUpdateResult>(
            ProgramUpdateFailed.new,
            (_) => ProgramUpdated(updated),
          );
        },
      ),
    );
  }

  ProgramSettingsReadResult readProgramSettings(
    ProgramSettingsRequest request,
  ) {
    return _findBottle(request.bottleId.value).fold<ProgramSettingsReadResult>(
      ProgramSettingsReadFailed.new,
      (bottle) => bottle.match(
        () => ProgramSettingsReadMissingBottle(request.bottleId.value),
        (bottle) {
          final readResult = _ioResult(
            () => _readProgramSettingsJson(
              _programSettingsJsonPath(
                bottle: bottle,
                programPath: request.programPath.value,
              ),
            ),
          );
          return readResult.fold<ProgramSettingsReadResult>(
            ProgramSettingsReadFailed.new,
            ProgramSettingsRead.new,
          );
        },
      ),
    );
  }

  ProgramSettingsUpdateResult setProgramSettings(
    ProgramSettingsUpdateRequest request,
  ) {
    return _findBottle(
      request.bottleId.value,
    ).fold<ProgramSettingsUpdateResult>(
      ProgramSettingsUpdateFailed.new,
      (bottle) => bottle.match(
        () => ProgramSettingsUpdateMissingBottle(request.bottleId.value),
        (bottle) {
          final writeResult = _ioResult(() {
            _writeProgramSettingsJson(
              path: _programSettingsJsonPath(
                bottle: bottle,
                programPath: request.programPath.value,
              ),
              settings: request.settings,
            );
          });
          return writeResult.fold<ProgramSettingsUpdateResult>(
            ProgramSettingsUpdateFailed.new,
            (_) => ProgramSettingsUpdated(request.settings),
          );
        },
      ),
    );
  }
}
