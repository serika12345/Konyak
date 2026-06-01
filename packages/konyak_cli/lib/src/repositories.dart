part of '../konyak_cli.dart';

BottleRepository defaultBottleRepositoryFromEnvironment(
  Map<String, String> environment, {
  KonyakHostPlatform? hostPlatform,
  AppSettingsRecord? appSettings,
}) {
  final platform = hostPlatform ?? _currentHostPlatform();
  return _defaultFileBottleRepository(
    dataHome: _resolveBottleDataHome(environment, hostPlatform: platform),
    defaultBottlePath:
        appSettings?.defaultBottlePath ??
        _defaultBottlePath(environment, hostPlatform: platform),
  );
}

AppSettingsRepository defaultAppSettingsRepositoryFromEnvironment(
  Map<String, String> environment, {
  KonyakHostPlatform? hostPlatform,
}) {
  final platform = hostPlatform ?? _currentHostPlatform();
  return FileAppSettingsRepository.fromEnvironment(
    environment,
    hostPlatform: platform,
  );
}

BottleRepository _defaultFileBottleRepository({
  required String dataHome,
  String? defaultBottlePath,
}) {
  final defaultBottleDirectory = _joinPath(dataHome, const ['bottles']);
  if (defaultBottlePath == null ||
      _normalizeFilesystemPath(defaultBottlePath) ==
          _normalizeFilesystemPath(defaultBottleDirectory)) {
    return FileBottleRepository(
      dataHome: dataHome,
      bottleDirectory: defaultBottlePath,
    );
  }

  return CompositeBottleRepository(
    catalogs: <BottleCatalog>[FileBottleRepository(dataHome: dataHome)],
    writableRepository: FileBottleRepository(
      dataHome: dataHome,
      bottleDirectory: defaultBottlePath,
    ),
  );
}

class MemoryAppSettingsRepository implements AppSettingsRepository {
  MemoryAppSettingsRepository(this._settings);

  AppSettingsRecord _settings;

  @override
  AppSettingsRecord read() {
    return _settings;
  }

  @override
  AppSettingsRecord write(AppSettingsRecord settings) {
    _settings = settings;
    return _settings;
  }
}

class FileAppSettingsRepository implements AppSettingsRepository {
  const FileAppSettingsRepository({
    required this.configHome,
    required this.fallbackDefaultBottlePath,
  });

  factory FileAppSettingsRepository.fromEnvironment(
    Map<String, String> environment, {
    KonyakHostPlatform? hostPlatform,
  }) {
    final platform = hostPlatform ?? _currentHostPlatform();
    return FileAppSettingsRepository(
      configHome: _resolveConfigHome(environment, hostPlatform: platform),
      fallbackDefaultBottlePath: _defaultBottlePath(
        environment,
        hostPlatform: platform,
      ),
    );
  }

  final String configHome;
  final String fallbackDefaultBottlePath;

  @override
  AppSettingsRecord read() {
    final file = File(_appSettingsJsonPath(configHome));
    if (!file.existsSync()) {
      return AppSettingsRecord(defaultBottlePath: fallbackDefaultBottlePath);
    }

    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, Object?> ||
          decoded['schemaVersion'] != cliSchemaVersion) {
        throw const FormatException('Unsupported app settings schema.');
      }

      final settings = AppSettingsRecord.fromJson(
        decoded['appSettings'],
        fallbackDefaultBottlePath: fallbackDefaultBottlePath,
      );
      if (settings == null) {
        throw const FormatException('Invalid app settings record.');
      }

      return settings;
    } on FileSystemException catch (error) {
      throw AppSettingsRepositoryException(error.message);
    } on FormatException catch (error) {
      throw AppSettingsRepositoryException(error.message);
    }
  }

  @override
  AppSettingsRecord write(AppSettingsRecord settings) {
    try {
      final file = File(_appSettingsJsonPath(configHome));
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(<String, Object?>{
          'schemaVersion': cliSchemaVersion,
          'appSettings': settings.toJson(),
        }),
      );
      return settings;
    } on FileSystemException catch (error) {
      throw AppSettingsRepositoryException(error.message);
    }
  }
}

class StaticBottleCatalog implements BottleCatalog {
  const StaticBottleCatalog(this._bottles);

  final List<BottleRecord> _bottles;

  @override
  List<BottleRecord> listBottles() {
    return List.unmodifiable(_bottles);
  }

  @override
  BottleRecord? findBottle(String id) {
    for (final bottle in _bottles) {
      if (bottle.id == id) {
        return bottle;
      }
    }

    return null;
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
         for (final bottle in bottles) bottle.id: bottle,
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
  List<BottleRecord> listBottles() {
    final bottles =
        _bottles.values
            .toList(growable: false)
            .map((bottle) {
              final updated = _bottleWithPinnedProgramIcons(
                bottle,
                programMetadataExtractor: _programMetadataExtractor,
              );
              if (updated != bottle) {
                _bottles[bottle.id] = updated;
              }
              return updated;
            })
            .toList(growable: false)
          ..sort((left, right) => left.id.compareTo(right.id));

    return List.unmodifiable(bottles);
  }

  @override
  BottleRecord? findBottle(String id) {
    final bottle = _bottles[id];
    if (bottle == null) {
      return null;
    }

    final updated = _bottleWithPinnedProgramIcons(
      bottle,
      programMetadataExtractor: _programMetadataExtractor,
    );
    if (updated != bottle) {
      _bottles[id] = updated;
    }

    return updated;
  }

  @override
  BottleCreateResult createBottle(BottleCreateRequest request) {
    final bottle = _bottleFromCreateRequest(request, dataHome);

    if (_bottles.containsKey(bottle.id)) {
      return BottleCreateConflict(bottle.id);
    }

    _bottles[bottle.id] = bottle;

    return BottleCreated(bottle);
  }

  @override
  BottleArchiveExportResult exportBottleArchive(
    BottleArchiveExportRequest request,
  ) {
    final bottle = findBottle(request.bottleId);
    if (bottle == null) {
      return BottleArchiveExportMissing(request.bottleId);
    }

    return _exportBottleArchive(
      bottle: bottle,
      archivePath: request.archivePath,
    );
  }

  @override
  BottleArchiveImportResult importBottleArchive(
    BottleArchiveImportRequest request,
  ) {
    return _importBottleArchive(
      archivePath: request.archivePath,
      bottleDirectory: _joinPath(dataHome, const ['bottles']),
      hasBottle: _bottles.containsKey,
      onImported: (bottle) {
        _bottles[bottle.id] = bottle;
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
    final bottle = _bottles[request.bottleId];
    if (bottle == null) {
      return BottleRenameMissing(request.bottleId);
    }

    final renamed = _renamedMemoryBottle(
      bottle: bottle,
      name: request.name,
      dataHome: dataHome,
    );
    final conflictingBottle = _bottles[renamed.id];
    if (conflictingBottle != null && conflictingBottle.id != bottle.id) {
      return BottleRenameConflict(renamed.id);
    }

    _bottles.remove(bottle.id);
    _bottles[renamed.id] = renamed;

    return BottleRenamed(renamed);
  }

  @override
  BottleMoveResult moveBottle(BottleMoveRequest request) {
    final bottle = _bottles[request.bottleId];
    if (bottle == null) {
      return BottleMoveMissing(request.bottleId);
    }

    if (_hasBottleAtPath(_bottles.values, request.path, exceptId: bottle.id)) {
      return BottleMoveConflict(request.path);
    }

    final moved = bottle.copyWith(path: request.path);
    _bottles[bottle.id] = moved;

    return BottleMoved(moved);
  }

  @override
  BottleUpdateResult setWindowsVersion(WindowsVersionUpdateRequest request) {
    final bottle = _bottles[request.bottleId];
    if (bottle == null) {
      return BottleUpdateMissing(request.bottleId);
    }

    final updated = bottle.copyWith(windowsVersion: request.windowsVersion);
    _bottles[request.bottleId] = updated;

    return BottleUpdated(updated);
  }

  @override
  BottleUpdateResult setRuntimeSettings(RuntimeSettingsUpdateRequest request) {
    final bottle = _bottles[request.bottleId];
    if (bottle == null) {
      return BottleUpdateMissing(request.bottleId);
    }

    final updated = bottle.copyWith(runtimeSettings: request.runtimeSettings);
    _bottles[request.bottleId] = updated;

    return BottleUpdated(updated);
  }

  @override
  ProgramPinResult pinProgram(ProgramPinRequest request) {
    final bottle = _bottles[request.bottleId];
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
    _bottles[request.bottleId] = updated;

    return ProgramPinned(updated);
  }

  @override
  ProgramUpdateResult unpinProgram(ProgramUnpinRequest request) {
    final bottle = _bottles[request.bottleId];
    if (bottle == null) {
      return ProgramUpdateMissingBottle(request.bottleId);
    }

    if (!_hasPinnedProgram(bottle, request.programPath)) {
      return ProgramUpdateMissingProgram(request.programPath);
    }

    final updated = _bottleWithoutPinnedProgram(bottle, request.programPath);
    _bottles[request.bottleId] = updated;

    return ProgramUpdated(updated);
  }

  @override
  ProgramUpdateResult renamePinnedProgram(ProgramRenameRequest request) {
    final bottle = _bottles[request.bottleId];
    if (bottle == null) {
      return ProgramUpdateMissingBottle(request.bottleId);
    }

    if (!_hasPinnedProgram(bottle, request.programPath)) {
      return ProgramUpdateMissingProgram(request.programPath);
    }

    final updated = _bottleWithRenamedPinnedProgram(bottle, request);
    _bottles[request.bottleId] = updated;

    return ProgramUpdated(updated);
  }

  @override
  ProgramSettingsReadResult readProgramSettings(
    ProgramSettingsRequest request,
  ) {
    final bottle = _bottles[request.bottleId];
    if (bottle == null) {
      return ProgramSettingsReadMissingBottle(request.bottleId);
    }

    return ProgramSettingsRead(
      _programSettings[_programSettingsKey(
            bottleId: request.bottleId,
            programPath: request.programPath,
          )] ??
          const ProgramSettingsRecord(),
    );
  }

  @override
  ProgramSettingsUpdateResult setProgramSettings(
    ProgramSettingsUpdateRequest request,
  ) {
    final bottle = _bottles[request.bottleId];
    if (bottle == null) {
      return ProgramSettingsUpdateMissingBottle(request.bottleId);
    }

    _programSettings[_programSettingsKey(
          bottleId: request.bottleId,
          programPath: request.programPath,
        )] =
        request.settings;

    return ProgramSettingsUpdated(request.settings);
  }
}

class CompositeBottleRepository implements BottleRepository {
  CompositeBottleRepository({
    required Iterable<BottleCatalog> catalogs,
    required this.writableRepository,
  }) : _catalogs = List.unmodifiable(catalogs);

  final List<BottleCatalog> _catalogs;
  final BottleRepository writableRepository;

  @override
  List<BottleRecord> listBottles() {
    final records = <String, BottleRecord>{};
    for (final bottle in writableRepository.listBottles()) {
      records[bottle.id] = bottle;
    }

    for (final catalog in _catalogs) {
      for (final bottle in catalog.listBottles()) {
        records.putIfAbsent(bottle.id, () => bottle);
      }
    }

    final bottles = records.values.toList(growable: false)
      ..sort((left, right) => left.id.compareTo(right.id));

    return List.unmodifiable(bottles);
  }

  @override
  BottleRecord? findBottle(String id) {
    final localBottle = writableRepository.findBottle(id);
    if (localBottle != null) {
      return localBottle;
    }

    for (final catalog in _catalogs) {
      final bottle = catalog.findBottle(id);
      if (bottle != null) {
        return bottle;
      }
    }

    return null;
  }

  @override
  BottleCreateResult createBottle(BottleCreateRequest request) {
    return writableRepository.createBottle(request);
  }

  @override
  BottleArchiveExportResult exportBottleArchive(
    BottleArchiveExportRequest request,
  ) {
    final bottle = findBottle(request.bottleId);
    if (bottle == null) {
      return BottleArchiveExportMissing(request.bottleId);
    }

    return _exportBottleArchive(
      bottle: bottle,
      archivePath: request.archivePath,
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

class FileBottleRepository implements BottleRepository {
  FileBottleRepository({
    required this.dataHome,
    String? bottleDirectory,
    ProgramMetadataExtractor programMetadataExtractor =
        const DartIoProgramMetadataExtractor(),
  }) : bottleDirectory =
           bottleDirectory ?? _joinPath(dataHome, const ['bottles']),
       _programMetadataExtractor = programMetadataExtractor;

  factory FileBottleRepository.fromEnvironment(
    Map<String, String> environment, {
    String? bottleDirectory,
  }) {
    return FileBottleRepository(
      dataHome: _resolveDataHome(environment),
      bottleDirectory: bottleDirectory,
    );
  }

  final String dataHome;
  final String bottleDirectory;
  final ProgramMetadataExtractor _programMetadataExtractor;

  @override
  List<BottleRecord> listBottles() {
    final directory = Directory(bottleDirectory);
    if (!directory.existsSync()) {
      return const <BottleRecord>[];
    }

    try {
      final bottles =
          directory
              .listSync()
              .whereType<Directory>()
              .where((entry) {
                return File(
                  _joinPath(entry.path, const ['metadata.json']),
                ).existsSync();
              })
              .map((entry) => _readBottleMetadata(entry.path))
              .map(
                (bottle) => _bottleWithPinnedProgramIcons(
                  bottle,
                  programMetadataExtractor: _programMetadataExtractor,
                ),
              )
              .toList(growable: false)
            ..sort((left, right) => left.id.compareTo(right.id));

      return List.unmodifiable(bottles);
    } on FileSystemException catch (error) {
      throw BottleRepositoryException(error.message);
    } on FormatException catch (error) {
      throw BottleRepositoryException(error.message);
    }
  }

  @override
  BottleRecord? findBottle(String id) {
    final directory = Directory(bottleDirectory);
    final metadata = File(_joinPath(directory.path, [id, 'metadata.json']));

    if (!metadata.existsSync()) {
      return null;
    }

    try {
      return _bottleWithPinnedProgramIcons(
        _readBottleMetadata(_joinPath(directory.path, [id])),
        programMetadataExtractor: _programMetadataExtractor,
      );
    } on FileSystemException catch (error) {
      throw BottleRepositoryException(error.message);
    } on FormatException catch (error) {
      throw BottleRepositoryException(error.message);
    }
  }

  @override
  BottleCreateResult createBottle(BottleCreateRequest request) {
    final bottle = _bottleFromCreateRequest(
      request,
      dataHome,
      bottleDirectory: bottleDirectory,
    );
    final bottlePathDirectory = Directory(bottle.path);
    final metadata = File(_joinPath(bottle.path, const ['metadata.json']));

    if (bottlePathDirectory.existsSync() || metadata.existsSync()) {
      return BottleCreateConflict(bottle.id);
    }

    try {
      bottlePathDirectory.createSync(recursive: true);
      Directory(
        _joinPath(bottle.path, const ['drive_c']),
      ).createSync(recursive: true);
      _writeBottleMetadata(bottle);
    } on FileSystemException catch (error) {
      throw BottleRepositoryException(error.message);
    }

    return BottleCreated(bottle);
  }

  @override
  BottleArchiveExportResult exportBottleArchive(
    BottleArchiveExportRequest request,
  ) {
    final bottle = findBottle(request.bottleId);
    if (bottle == null) {
      return BottleArchiveExportMissing(request.bottleId);
    }

    return _exportBottleArchive(
      bottle: bottle,
      archivePath: request.archivePath,
    );
  }

  @override
  BottleArchiveImportResult importBottleArchive(
    BottleArchiveImportRequest request,
  ) {
    return _importBottleArchive(
      archivePath: request.archivePath,
      bottleDirectory: bottleDirectory,
      hasBottle: (bottleId) => findBottle(bottleId) != null,
    );
  }

  @override
  BottleDeleteResult deleteBottle(String id) {
    final bottle = findBottle(id);
    if (bottle == null) {
      return BottleDeleteMissing(id);
    }

    try {
      final bottleDirectory = Directory(bottle.path);
      if (bottleDirectory.existsSync()) {
        bottleDirectory.deleteSync(recursive: true);
      }
    } on FileSystemException catch (error) {
      throw BottleRepositoryException(error.message);
    }

    return BottleDeleted(bottle);
  }

  @override
  BottleRenameResult renameBottle(BottleRenameRequest request) {
    final bottle = findBottle(request.bottleId);
    if (bottle == null) {
      return BottleRenameMissing(request.bottleId);
    }

    final renamed = _renamedFileBottle(
      bottle: bottle,
      name: request.name,
      dataHome: dataHome,
      bottleDirectory: bottleDirectory,
    );
    if (renamed.id != bottle.id && Directory(renamed.path).existsSync()) {
      return BottleRenameConflict(renamed.id);
    }

    try {
      if (renamed.path != bottle.path) {
        _moveDirectory(from: bottle.path, to: renamed.path);
      }
      _writeBottleMetadata(renamed);
    } on FileSystemException catch (error) {
      throw BottleRepositoryException(error.message);
    }

    return BottleRenamed(renamed);
  }

  @override
  BottleMoveResult moveBottle(BottleMoveRequest request) {
    final bottle = findBottle(request.bottleId);
    if (bottle == null) {
      return BottleMoveMissing(request.bottleId);
    }

    final destinationPath = request.path;
    if (_normalizeFilesystemPath(destinationPath) !=
            _normalizeFilesystemPath(bottle.path) &&
        Directory(destinationPath).existsSync()) {
      return BottleMoveConflict(destinationPath);
    }

    final moved = bottle.copyWith(path: destinationPath);

    try {
      if (_normalizeFilesystemPath(destinationPath) !=
          _normalizeFilesystemPath(bottle.path)) {
        _moveDirectory(from: bottle.path, to: destinationPath);
      }
      _writeBottleMetadata(moved);
    } on FileSystemException catch (error) {
      throw BottleRepositoryException(error.message);
    }

    return BottleMoved(moved);
  }

  @override
  BottleUpdateResult setWindowsVersion(WindowsVersionUpdateRequest request) {
    final bottle = findBottle(request.bottleId);
    if (bottle == null) {
      return BottleUpdateMissing(request.bottleId);
    }

    final updated = bottle.copyWith(windowsVersion: request.windowsVersion);

    try {
      _writeBottleMetadata(updated);
    } on FileSystemException catch (error) {
      throw BottleRepositoryException(error.message);
    }

    return BottleUpdated(updated);
  }

  @override
  BottleUpdateResult setRuntimeSettings(RuntimeSettingsUpdateRequest request) {
    final bottle = findBottle(request.bottleId);
    if (bottle == null) {
      return BottleUpdateMissing(request.bottleId);
    }

    final updated = bottle.copyWith(runtimeSettings: request.runtimeSettings);

    try {
      _writeBottleMetadata(updated);
    } on FileSystemException catch (error) {
      throw BottleRepositoryException(error.message);
    }

    return BottleUpdated(updated);
  }

  @override
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

  @override
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

  @override
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

  @override
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

  @override
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
