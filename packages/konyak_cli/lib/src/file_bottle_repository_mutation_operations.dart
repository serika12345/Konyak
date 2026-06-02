part of '../konyak_cli.dart';

class _FileBottleRepositoryMutationOperations {
  const _FileBottleRepositoryMutationOperations({
    required this.dataHome,
    required this.bottleDirectory,
    required BottleRecord? Function(String id) findBottle,
  }) : _findBottle = findBottle;

  final String dataHome;
  final String bottleDirectory;
  final BottleRecord? Function(String id) _findBottle;

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

  BottleDeleteResult deleteBottle(String id) {
    final bottle = _findBottle(id);
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

  BottleRenameResult renameBottle(BottleRenameRequest request) {
    final bottle = _findBottle(request.bottleId);
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

  BottleMoveResult moveBottle(BottleMoveRequest request) {
    final bottle = _findBottle(request.bottleId);
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

  BottleUpdateResult setWindowsVersion(WindowsVersionUpdateRequest request) {
    final bottle = _findBottle(request.bottleId);
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

  BottleUpdateResult setRuntimeSettings(RuntimeSettingsUpdateRequest request) {
    final bottle = _findBottle(request.bottleId);
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
}
