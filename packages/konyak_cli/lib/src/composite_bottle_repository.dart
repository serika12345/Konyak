part of '../konyak_cli.dart';

class CompositeBottleRepository implements BottleRepository {
  CompositeBottleRepository({
    required Iterable<BottleCatalog> catalogs,
    required this.writableRepository,
  }) : _catalogs = List.unmodifiable(catalogs);

  final List<BottleCatalog> _catalogs;
  final BottleRepository writableRepository;

  @override
  IoResult<List<BottleRecord>> listBottles() {
    final records = <String, BottleRecord>{};
    final writableBottles = writableRepository.listBottles();
    final writableFailure = writableBottles.fold<IoResult<List<BottleRecord>>?>(
      Left<String, List<BottleRecord>>.new,
      (_) => null,
    );
    if (writableFailure != null) {
      return writableFailure;
    }

    for (final bottle in writableBottles.getOrElse(
      (_) => const <BottleRecord>[],
    )) {
      records[bottle.id] = bottle;
    }

    for (final catalog in _catalogs) {
      final catalogBottles = catalog.listBottles();
      final catalogFailure = catalogBottles.fold<IoResult<List<BottleRecord>>?>(
        Left<String, List<BottleRecord>>.new,
        (_) => null,
      );
      if (catalogFailure != null) {
        return catalogFailure;
      }

      for (final bottle in catalogBottles.getOrElse(
        (_) => const <BottleRecord>[],
      )) {
        records.putIfAbsent(bottle.id, () => bottle);
      }
    }

    final bottles = records.values.toList(growable: false)
      ..sort((left, right) => left.id.compareTo(right.id));

    return Right<String, List<BottleRecord>>(List.unmodifiable(bottles));
  }

  @override
  IoResult<Option<BottleRecord>> findBottle(String id) {
    final localBottle = writableRepository.findBottle(id);
    final localFailure = localBottle.fold<IoResult<Option<BottleRecord>>?>(
      Left<String, Option<BottleRecord>>.new,
      (_) => null,
    );
    if (localFailure != null) {
      return localFailure;
    }
    final localRecord = localBottle.getOrElse((_) => const Option.none());
    if (localRecord.isSome()) {
      return Right<String, Option<BottleRecord>>(localRecord);
    }

    for (final catalog in _catalogs) {
      final bottle = catalog.findBottle(id);
      final failure = bottle.fold<IoResult<Option<BottleRecord>>?>(
        Left<String, Option<BottleRecord>>.new,
        (_) => null,
      );
      if (failure != null) {
        return failure;
      }
      final record = bottle.getOrElse((_) => const Option.none());
      if (record.isSome()) {
        return Right<String, Option<BottleRecord>>(record);
      }
    }

    return const Right<String, Option<BottleRecord>>(Option.none());
  }

  @override
  BottleCreateResult createBottle(BottleCreateRequest request) {
    return writableRepository.createBottle(request);
  }

  @override
  BottleArchiveExportResult exportBottleArchive(
    BottleArchiveExportRequest request,
  ) {
    return findBottle(request.bottleId).fold(
      BottleArchiveExportFailed.new,
      (bottle) => bottle.match(
        () => BottleArchiveExportMissing(request.bottleId),
        (bottle) => _exportBottleArchive(
          bottle: bottle,
          archivePath: request.archivePath,
        ),
      ),
    );
  }

  @override
  BottleArchiveImportResult importBottleArchive(
    BottleArchiveImportRequest request,
  ) {
    return writableRepository.importBottleArchive(request);
  }

  @override
  BottleDeleteResult deleteBottle(String id) {
    final writableDelete = writableRepository.deleteBottle(id);
    if (writableDelete is BottleDeleted) {
      return writableDelete;
    }

    for (final catalog in _catalogs) {
      if (catalog is! BottleRepository) {
        continue;
      }

      final catalogDelete = catalog.deleteBottle(id);
      if (catalogDelete is BottleDeleted) {
        return catalogDelete;
      }
    }

    return BottleDeleteMissing(id);
  }

  @override
  BottleRenameResult renameBottle(BottleRenameRequest request) {
    final writableRename = writableRepository.renameBottle(request);
    if (writableRename is BottleRenamed ||
        writableRename is BottleRenameConflict) {
      return writableRename;
    }

    for (final catalog in _catalogs) {
      if (catalog is! BottleRepository) {
        continue;
      }

      final catalogRename = catalog.renameBottle(request);
      if (catalogRename is BottleRenamed ||
          catalogRename is BottleRenameConflict) {
        return catalogRename;
      }
    }

    return BottleRenameMissing(request.bottleId);
  }

  @override
  BottleMoveResult moveBottle(BottleMoveRequest request) {
    final writableMove = writableRepository.moveBottle(request);
    if (writableMove is BottleMoved || writableMove is BottleMoveConflict) {
      return writableMove;
    }

    for (final catalog in _catalogs) {
      if (catalog is! BottleRepository) {
        continue;
      }

      final catalogMove = catalog.moveBottle(request);
      if (catalogMove is BottleMoved || catalogMove is BottleMoveConflict) {
        return catalogMove;
      }
    }

    return BottleMoveMissing(request.bottleId);
  }

  @override
  BottleUpdateResult setWindowsVersion(WindowsVersionUpdateRequest request) {
    return writableRepository.setWindowsVersion(request);
  }

  @override
  BottleUpdateResult setRuntimeSettings(RuntimeSettingsUpdateRequest request) {
    final writableUpdate = writableRepository.setRuntimeSettings(request);
    if (writableUpdate is BottleUpdated) {
      return writableUpdate;
    }

    for (final catalog in _catalogs) {
      if (catalog is! BottleRepository) {
        continue;
      }

      final catalogUpdate = catalog.setRuntimeSettings(request);
      if (catalogUpdate is BottleUpdated) {
        return catalogUpdate;
      }
    }

    return BottleUpdateMissing(request.bottleId);
  }

  @override
  ProgramPinResult pinProgram(ProgramPinRequest request) {
    final writablePin = writableRepository.pinProgram(request);
    if (writablePin is ProgramPinned || writablePin is ProgramPinConflict) {
      return writablePin;
    }

    for (final catalog in _catalogs) {
      if (catalog is! BottleRepository) {
        continue;
      }

      final catalogPin = catalog.pinProgram(request);
      if (catalogPin is ProgramPinned || catalogPin is ProgramPinConflict) {
        return catalogPin;
      }
    }

    return ProgramPinMissing(request.bottleId);
  }

  @override
  ProgramUpdateResult unpinProgram(ProgramUnpinRequest request) {
    final writableUpdate = writableRepository.unpinProgram(request);
    if (writableUpdate is ProgramUpdated ||
        writableUpdate is ProgramUpdateMissingProgram) {
      return writableUpdate;
    }

    for (final catalog in _catalogs) {
      if (catalog is! BottleRepository) {
        continue;
      }

      final catalogUpdate = catalog.unpinProgram(request);
      if (catalogUpdate is ProgramUpdated ||
          catalogUpdate is ProgramUpdateMissingProgram) {
        return catalogUpdate;
      }
    }

    return ProgramUpdateMissingBottle(request.bottleId);
  }

  @override
  ProgramUpdateResult renamePinnedProgram(ProgramRenameRequest request) {
    final writableUpdate = writableRepository.renamePinnedProgram(request);
    if (writableUpdate is ProgramUpdated ||
        writableUpdate is ProgramUpdateMissingProgram) {
      return writableUpdate;
    }

    for (final catalog in _catalogs) {
      if (catalog is! BottleRepository) {
        continue;
      }

      final catalogUpdate = catalog.renamePinnedProgram(request);
      if (catalogUpdate is ProgramUpdated ||
          catalogUpdate is ProgramUpdateMissingProgram) {
        return catalogUpdate;
      }
    }

    return ProgramUpdateMissingBottle(request.bottleId);
  }

  @override
  ProgramSettingsReadResult readProgramSettings(
    ProgramSettingsRequest request,
  ) {
    final writableRead = writableRepository.readProgramSettings(request);
    if (writableRead is ProgramSettingsRead) {
      return writableRead;
    }

    for (final catalog in _catalogs) {
      if (catalog is! BottleRepository) {
        continue;
      }

      final catalogRead = catalog.readProgramSettings(request);
      if (catalogRead is ProgramSettingsRead) {
        return catalogRead;
      }
    }

    return ProgramSettingsReadMissingBottle(request.bottleId);
  }

  @override
  ProgramSettingsUpdateResult setProgramSettings(
    ProgramSettingsUpdateRequest request,
  ) {
    final writableUpdate = writableRepository.setProgramSettings(request);
    if (writableUpdate is ProgramSettingsUpdated) {
      return writableUpdate;
    }

    for (final catalog in _catalogs) {
      if (catalog is! BottleRepository) {
        continue;
      }

      final catalogUpdate = catalog.setProgramSettings(request);
      if (catalogUpdate is ProgramSettingsUpdated) {
        return catalogUpdate;
      }
    }

    return ProgramSettingsUpdateMissingBottle(request.bottleId);
  }
}
