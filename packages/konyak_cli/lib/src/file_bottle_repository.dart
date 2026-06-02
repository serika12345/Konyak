part of '../konyak_cli.dart';

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
    if (!_fileBottleRepositoryDirectoryExists(bottleDirectory)) {
      return const <BottleRecord>[];
    }

    try {
      final bottles =
          _fileBottleRepositoryBottleDirectories(bottleDirectory)
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
    if (!_fileBottleMetadataExists(bottleDirectory: bottleDirectory, id: id)) {
      return null;
    }

    try {
      return _bottleWithPinnedProgramIcons(
        _readBottleMetadata(_fileBottlePath(bottleDirectory, id)),
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
    if (_fileBottlePathExists(bottle.path)) {
      return BottleCreateConflict(bottle.id);
    }

    try {
      _createFileBottleDirectories(bottle.path);
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
      _deleteFileBottleDirectoryIfPresent(bottle.path);
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
    if (renamed.id != bottle.id && _fileBottleDirectoryExists(renamed.path)) {
      return BottleRenameConflict(renamed.id);
    }

    try {
      _moveFileBottleDirectoryIfChanged(from: bottle.path, to: renamed.path);
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
        _fileBottleDirectoryExists(destinationPath)) {
      return BottleMoveConflict(destinationPath);
    }

    final moved = bottle.copyWith(path: destinationPath);

    try {
      _moveFileBottleDirectoryIfChanged(from: bottle.path, to: destinationPath);
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
