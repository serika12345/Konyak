part of '../../konyak_cli.dart';

class StaticBottleCatalog implements BottleCatalog {
  StaticBottleCatalog(Iterable<BottleRecord> bottles)
    : _bottles = List.unmodifiable(bottles);

  final List<BottleRecord> _bottles;

  @override
  IoResult<List<BottleRecord>> listBottles() {
    return Right<String, List<BottleRecord>>(List.unmodifiable(_bottles));
  }

  @override
  IoResult<Option<BottleRecord>> findBottle(String id) {
    for (final bottle in _bottles) {
      if (bottle.id.value == id) {
        return Right<String, Option<BottleRecord>>(Option.of(bottle));
      }
    }

    return const Right<String, Option<BottleRecord>>(Option.none());
  }
}

class MemoryBottleRepository implements BottleRepository {
  MemoryBottleRepository({
    required this.dataHome,
    Iterable<BottleRecord> bottles = const <BottleRecord>[],
    Map<String, ProgramSettingsRecord> programSettings =
        const <String, ProgramSettingsRecord>{},
    ProgramMetadataExtractor programMetadataExtractor =
        const DartIoProgramMetadataExtractor(),
  }) : _bottles = <String, BottleRecord>{
         for (final bottle in bottles) bottle.id.value: bottle,
       },
       _programSettings = Map<String, ProgramSettingsRecord>.of(
         programSettings,
       ),
       _programMetadataExtractor = programMetadataExtractor;

  final String dataHome;
  final Map<String, BottleRecord> _bottles;
  final Map<String, ProgramSettingsRecord> _programSettings;
  final ProgramMetadataExtractor _programMetadataExtractor;

  @override
  IoResult<List<BottleRecord>> listBottles() {
    final bottles =
        _bottles.values
            .toList(growable: false)
            .map((bottle) {
              final updated = _bottleWithPinnedProgramIcons(
                _bottleWithoutMissingBottleLocalPinnedProgramFiles(bottle),
                programMetadataExtractor: _programMetadataExtractor,
              );
              if (updated != bottle) {
                _bottles[bottle.id.value] = updated;
              }
              return updated;
            })
            .toList(growable: false)
          ..sort((left, right) => left.id.value.compareTo(right.id.value));

    return Right<String, List<BottleRecord>>(List.unmodifiable(bottles));
  }

  @override
  IoResult<Option<BottleRecord>> findBottle(String id) {
    final bottle = _bottles[id];
    if (bottle == null) {
      return const Right<String, Option<BottleRecord>>(Option.none());
    }

    final updated = _bottleWithPinnedProgramIcons(
      _bottleWithoutMissingBottleLocalPinnedProgramFiles(bottle),
      programMetadataExtractor: _programMetadataExtractor,
    );
    if (updated != bottle) {
      _bottles[id] = updated;
    }

    return Right<String, Option<BottleRecord>>(Option.of(updated));
  }

  @override
  BottleCreateResult createBottle(BottleCreateRequest request) {
    final bottle = _bottleFromCreateRequest(request, dataHome);

    if (_bottles.containsKey(bottle.id.value)) {
      return BottleCreateConflict(bottle.id.value);
    }

    _bottles[bottle.id.value] = bottle;

    return BottleCreated(bottle);
  }

  @override
  BottleArchiveExportResult exportBottleArchive(
    BottleArchiveExportRequest request,
  ) {
    return findBottle(request.bottleId.value).fold(
      BottleArchiveExportFailed.new,
      (bottle) => bottle.match(
        () => BottleArchiveExportMissing(request.bottleId.value),
        (bottle) => _exportBottleArchive(
          bottle: bottle,
          archivePath: request.archivePath.value,
        ),
      ),
    );
  }

  @override
  BottleArchiveImportResult importBottleArchive(
    BottleArchiveImportRequest request,
  ) {
    return _importBottleArchive(
      archivePath: request.archivePath.value,
      bottleDirectory: _joinPath(dataHome, const ['bottles']),
      hasBottle: _bottles.containsKey,
      onImported: (bottle) {
        _bottles[bottle.id.value] = bottle;
      },
    );
  }

  @override
  BottleDeleteResult deleteBottle(String id) {
    final bottle = _bottles.remove(id);
    if (bottle == null) {
      return BottleDeleteMissing(id);
    }

    return BottleDeleted(bottle);
  }

  @override
  BottleRenameResult renameBottle(BottleRenameRequest request) {
    final bottle = _bottles[request.bottleId.value];
    if (bottle == null) {
      return BottleRenameMissing(request.bottleId.value);
    }

    final renamed = _renamedMemoryBottle(
      bottle: bottle,
      name: request.name.value,
      dataHome: dataHome,
    );
    final conflictingBottle = _bottles[renamed.id.value];
    if (conflictingBottle != null &&
        conflictingBottle.id.value != bottle.id.value) {
      return BottleRenameConflict(renamed.id.value);
    }

    _bottles.remove(bottle.id.value);
    _bottles[renamed.id.value] = renamed;

    return BottleRenamed(renamed);
  }

  @override
  BottleMoveResult moveBottle(BottleMoveRequest request) {
    final bottle = _bottles[request.bottleId.value];
    if (bottle == null) {
      return BottleMoveMissing(request.bottleId.value);
    }

    if (_hasBottleAtPath(
      _bottles.values,
      request.path.value,
      exceptId: bottle.id.value,
    )) {
      return BottleMoveConflict(request.path.value);
    }

    final moved = bottle.withPath(request.path.value);
    _bottles[bottle.id.value] = moved;

    return BottleMoved(moved);
  }

  @override
  BottleUpdateResult setWindowsVersion(WindowsVersionUpdateRequest request) {
    final bottle = _bottles[request.bottleId.value];
    if (bottle == null) {
      return BottleUpdateMissing(request.bottleId.value);
    }

    final updated = bottle.withWindowsVersion(request.windowsVersion.value);
    _bottles[request.bottleId.value] = updated;

    return BottleUpdated(updated);
  }

  @override
  BottleUpdateResult setRuntimeSettings(RuntimeSettingsUpdateRequest request) {
    final bottle = _bottles[request.bottleId.value];
    if (bottle == null) {
      return BottleUpdateMissing(request.bottleId.value);
    }

    final updated = bottle.withRuntimeSettings(request.runtimeSettings);
    _bottles[request.bottleId.value] = updated;

    return BottleUpdated(updated);
  }

  @override
  ProgramPinResult pinProgram(ProgramPinRequest request) {
    final bottle = _bottles[request.bottleId.value];
    if (bottle == null) {
      return ProgramPinMissing(request.bottleId.value);
    }

    if (_hasPinnedProgram(bottle, request.programPath.value)) {
      return ProgramPinConflict(request.programPath.value);
    }

    final updated = _bottleWithPinnedProgram(
      bottle,
      request,
      programMetadataExtractor: _programMetadataExtractor,
    );
    _bottles[request.bottleId.value] = updated;

    return ProgramPinned(updated);
  }

  @override
  ProgramUpdateResult unpinProgram(ProgramUnpinRequest request) {
    final bottle = _bottles[request.bottleId.value];
    if (bottle == null) {
      return ProgramUpdateMissingBottle(request.bottleId.value);
    }

    if (!_hasPinnedProgram(bottle, request.programPath.value)) {
      return ProgramUpdateMissingProgram(request.programPath.value);
    }

    final updated = _bottleWithoutPinnedProgram(
      bottle,
      request.programPath.value,
    );
    _bottles[request.bottleId.value] = updated;

    return ProgramUpdated(updated);
  }

  @override
  ProgramUpdateResult renamePinnedProgram(ProgramRenameRequest request) {
    final bottle = _bottles[request.bottleId.value];
    if (bottle == null) {
      return ProgramUpdateMissingBottle(request.bottleId.value);
    }

    if (!_hasPinnedProgram(bottle, request.programPath.value)) {
      return ProgramUpdateMissingProgram(request.programPath.value);
    }

    final updated = _bottleWithRenamedPinnedProgram(bottle, request);
    _bottles[request.bottleId.value] = updated;

    return ProgramUpdated(updated);
  }

  @override
  ProgramSettingsReadResult readProgramSettings(
    ProgramSettingsRequest request,
  ) {
    final bottle = _bottles[request.bottleId.value];
    if (bottle == null) {
      return ProgramSettingsReadMissingBottle(request.bottleId.value);
    }

    return ProgramSettingsRead(
      _programSettings[_programSettingsKey(
            bottleId: request.bottleId.value,
            programPath: request.programPath.value,
          )] ??
          ProgramSettingsRecord(),
    );
  }

  @override
  ProgramSettingsUpdateResult setProgramSettings(
    ProgramSettingsUpdateRequest request,
  ) {
    final bottle = _bottles[request.bottleId.value];
    if (bottle == null) {
      return ProgramSettingsUpdateMissingBottle(request.bottleId.value);
    }

    _programSettings[_programSettingsKey(
          bottleId: request.bottleId.value,
          programPath: request.programPath.value,
        )] =
        request.settings;

    return ProgramSettingsUpdated(request.settings);
  }
}
