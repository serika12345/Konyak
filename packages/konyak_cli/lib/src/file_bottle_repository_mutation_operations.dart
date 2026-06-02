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

    final writeResult = _repositoryIoResult(() {
      _createFileBottleDirectories(bottle.path);
      _writeBottleMetadata(bottle);
    });
    final failure = writeResult.fold<BottleCreateResult?>(
      BottleCreateFailed.new,
      (_) => null,
    );
    if (failure != null) {
      return failure;
    }

    return BottleCreated(bottle);
  }

  BottleDeleteResult deleteBottle(String id) {
    final bottle = _findBottle(id);
    if (bottle == null) {
      return BottleDeleteMissing(id);
    }

    final deleteResult = _repositoryIoResult(() {
      _deleteFileBottleDirectoryIfPresent(bottle.path);
    });
    final failure = deleteResult.fold<BottleDeleteResult?>(
      BottleDeleteFailed.new,
      (_) => null,
    );
    if (failure != null) {
      return failure;
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

    final writeResult = _repositoryIoResult(() {
      _moveFileBottleDirectoryIfChanged(from: bottle.path, to: renamed.path);
      _writeBottleMetadata(renamed);
    });
    final failure = writeResult.fold<BottleRenameResult?>(
      BottleRenameFailed.new,
      (_) => null,
    );
    if (failure != null) {
      return failure;
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

    final writeResult = _repositoryIoResult(() {
      _moveFileBottleDirectoryIfChanged(from: bottle.path, to: destinationPath);
      _writeBottleMetadata(moved);
    });
    final failure = writeResult.fold<BottleMoveResult?>(
      BottleMoveFailed.new,
      (_) => null,
    );
    if (failure != null) {
      return failure;
    }

    return BottleMoved(moved);
  }

  BottleUpdateResult setWindowsVersion(WindowsVersionUpdateRequest request) {
    final bottle = _findBottle(request.bottleId);
    if (bottle == null) {
      return BottleUpdateMissing(request.bottleId);
    }

    final updated = bottle.copyWith(windowsVersion: request.windowsVersion);

    final writeResult = _repositoryIoResult(() {
      _writeBottleMetadata(updated);
    });
    final failure = writeResult.fold<BottleUpdateResult?>(
      BottleUpdateFailed.new,
      (_) => null,
    );
    if (failure != null) {
      return failure;
    }

    return BottleUpdated(updated);
  }

  BottleUpdateResult setRuntimeSettings(RuntimeSettingsUpdateRequest request) {
    final bottle = _findBottle(request.bottleId);
    if (bottle == null) {
      return BottleUpdateMissing(request.bottleId);
    }

    final updated = bottle.copyWith(runtimeSettings: request.runtimeSettings);

    final writeResult = _repositoryIoResult(() {
      _writeBottleMetadata(updated);
    });
    final failure = writeResult.fold<BottleUpdateResult?>(
      BottleUpdateFailed.new,
      (_) => null,
    );
    if (failure != null) {
      return failure;
    }

    return BottleUpdated(updated);
  }
}
