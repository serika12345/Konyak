part of '../../konyak_cli.dart';

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
      records[bottle.id.value] = bottle;
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
        records.putIfAbsent(bottle.id.value, () => bottle);
      }
    }

    final bottles = records.values.toList(growable: false)
      ..sort((left, right) => left.id.value.compareTo(right.id.value));

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
    return writableRepository.importBottleArchive(request);
  }

  @override
  BottleDeleteResult deleteBottle(String id) {
    return writableRepository.deleteBottle(id);
  }

  @override
  BottleRenameResult renameBottle(BottleRenameRequest request) {
    return writableRepository.renameBottle(request);
  }

  @override
  BottleMoveResult moveBottle(BottleMoveRequest request) {
    return writableRepository.moveBottle(request);
  }

  @override
  BottleUpdateResult setWindowsVersion(WindowsVersionUpdateRequest request) {
    return writableRepository.setWindowsVersion(request);
  }

  @override
  BottleUpdateResult setRuntimeSettings(RuntimeSettingsUpdateRequest request) {
    return writableRepository.setRuntimeSettings(request);
  }

  @override
  ProgramPinResult pinProgram(ProgramPinRequest request) {
    return writableRepository.pinProgram(request);
  }

  @override
  ProgramUpdateResult unpinProgram(ProgramUnpinRequest request) {
    return writableRepository.unpinProgram(request);
  }

  @override
  ProgramUpdateResult renamePinnedProgram(ProgramRenameRequest request) {
    return writableRepository.renamePinnedProgram(request);
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

    return ProgramSettingsReadMissingBottle(request.bottleId.value);
  }

  @override
  ProgramSettingsUpdateResult setProgramSettings(
    ProgramSettingsUpdateRequest request,
  ) {
    return writableRepository.setProgramSettings(request);
  }
}
