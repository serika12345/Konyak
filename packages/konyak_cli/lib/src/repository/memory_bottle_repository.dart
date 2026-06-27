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
    return _mapValue(_bottles, id).match(
      () => const Right<String, Option<BottleRecord>>(Option.none()),
      (bottle) {
        final updated = _bottleWithPinnedProgramIcons(
          _bottleWithoutMissingBottleLocalPinnedProgramFiles(bottle),
          programMetadataExtractor: _programMetadataExtractor,
        );
        if (updated != bottle) {
          _bottles[id] = updated;
        }

        return Right<String, Option<BottleRecord>>(Option.of(updated));
      },
    );
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
    return _removeMapValue(
      _bottles,
      id,
    ).match(() => BottleDeleteMissing(id), BottleDeleted.new);
  }

  @override
  BottleRenameResult renameBottle(BottleRenameRequest request) {
    return _mapValue(_bottles, request.bottleId.value).match(
      () => BottleRenameMissing(request.bottleId.value),
      (bottle) {
        final renamed = _renamedMemoryBottle(
          bottle: bottle,
          name: request.name.value,
          dataHome: dataHome,
        );
        final hasConflict = _mapValue(_bottles, renamed.id.value).match(
          () => false,
          (conflictingBottle) => conflictingBottle.id.value != bottle.id.value,
        );
        if (hasConflict) {
          return BottleRenameConflict(renamed.id.value);
        }

        _bottles.remove(bottle.id.value);
        _bottles[renamed.id.value] = renamed;

        return BottleRenamed(renamed);
      },
    );
  }

  @override
  BottleMoveResult moveBottle(BottleMoveRequest request) {
    return _mapValue(_bottles, request.bottleId.value).match(
      () => BottleMoveMissing(request.bottleId.value),
      (bottle) {
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
      },
    );
  }

  @override
  BottleUpdateResult setWindowsVersion(WindowsVersionUpdateRequest request) {
    return _mapValue(_bottles, request.bottleId.value).match(
      () => BottleUpdateMissing(request.bottleId.value),
      (bottle) {
        final updated = bottle.withWindowsVersion(request.windowsVersion.value);
        _bottles[request.bottleId.value] = updated;

        return BottleUpdated(updated);
      },
    );
  }

  @override
  BottleUpdateResult setRuntimeSettings(RuntimeSettingsUpdateRequest request) {
    return _mapValue(_bottles, request.bottleId.value).match(
      () => BottleUpdateMissing(request.bottleId.value),
      (bottle) {
        final updated = bottle.withRuntimeSettings(request.runtimeSettings);
        _bottles[request.bottleId.value] = updated;

        return BottleUpdated(updated);
      },
    );
  }

  @override
  ProgramPinResult pinProgram(ProgramPinRequest request) {
    return _mapValue(_bottles, request.bottleId.value).match(
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
        _bottles[request.bottleId.value] = updated;

        return ProgramPinned(updated);
      },
    );
  }

  @override
  ProgramUpdateResult unpinProgram(ProgramUnpinRequest request) {
    return _mapValue(_bottles, request.bottleId.value).match(
      () => ProgramUpdateMissingBottle(request.bottleId.value),
      (bottle) {
        if (!_hasPinnedProgram(bottle, request.programPath.value)) {
          return ProgramUpdateMissingProgram(request.programPath.value);
        }

        final updated = _bottleWithoutPinnedProgram(
          bottle,
          request.programPath.value,
        );
        _bottles[request.bottleId.value] = updated;

        return ProgramUpdated(updated);
      },
    );
  }

  @override
  ProgramUpdateResult renamePinnedProgram(ProgramRenameRequest request) {
    return _mapValue(_bottles, request.bottleId.value).match(
      () => ProgramUpdateMissingBottle(request.bottleId.value),
      (bottle) {
        if (!_hasPinnedProgram(bottle, request.programPath.value)) {
          return ProgramUpdateMissingProgram(request.programPath.value);
        }

        final updated = _bottleWithRenamedPinnedProgram(bottle, request);
        _bottles[request.bottleId.value] = updated;

        return ProgramUpdated(updated);
      },
    );
  }

  @override
  ProgramSettingsReadResult readProgramSettings(
    ProgramSettingsRequest request,
  ) {
    return _mapValue(_bottles, request.bottleId.value).match(
      () => ProgramSettingsReadMissingBottle(request.bottleId.value),
      (bottle) => ProgramSettingsRead(
        _mapValue(
          _programSettings,
          _programSettingsKey(
            bottleId: bottle.id.value,
            programPath: request.programPath.value,
          ),
        ).match(ProgramSettingsRecord.new, (settings) => settings),
      ),
    );
  }

  @override
  ProgramSettingsUpdateResult setProgramSettings(
    ProgramSettingsUpdateRequest request,
  ) {
    return _mapValue(_bottles, request.bottleId.value).match(
      () => ProgramSettingsUpdateMissingBottle(request.bottleId.value),
      (bottle) {
        _programSettings[_programSettingsKey(
              bottleId: bottle.id.value,
              programPath: request.programPath.value,
            )] =
            request.settings;

        return ProgramSettingsUpdated(request.settings);
      },
    );
  }
}

Option<V> _mapValue<K, V>(Map<K, V> map, K key) {
  if (!map.containsKey(key)) {
    return const Option.none();
  }

  return Option.of(map[key] as V);
}

Option<V> _removeMapValue<K, V>(Map<K, V> map, K key) {
  if (!map.containsKey(key)) {
    return const Option.none();
  }

  return Option.of(map.remove(key) as V);
}
