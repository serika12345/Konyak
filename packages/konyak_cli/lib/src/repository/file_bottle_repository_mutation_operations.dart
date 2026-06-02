part of '../../konyak_cli.dart';

class _FileBottleRepositoryMutationOperations {
  const _FileBottleRepositoryMutationOperations({
    required this.dataHome,
    required this.bottleDirectory,
    required IoResult<Option<BottleRecord>> Function(String id) findBottle,
  }) : _findBottle = findBottle;

  final String dataHome;
  final String bottleDirectory;
  final IoResult<Option<BottleRecord>> Function(String id) _findBottle;

  BottleCreateResult createBottle(BottleCreateRequest request) {
    final bottle = _bottleFromCreateRequest(
      request,
      dataHome,
      bottleDirectory: bottleDirectory,
    );
    if (_fileBottlePathExists(bottle.path)) {
      return BottleCreateConflict(bottle.id);
    }

    final writeResult = _ioResult(() {
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
    final bottleResult = _findBottle(id);
    final failure = bottleResult.fold<BottleDeleteResult?>(
      BottleDeleteFailed.new,
      (_) => null,
    );
    if (failure != null) {
      return failure;
    }
    return bottleResult.getOrElse((_) => const Option.none()).match(
      () => BottleDeleteMissing(id),
      (bottle) {
        final deleteResult = _ioResult(() {
          _deleteFileBottleDirectoryIfPresent(bottle.path);
        });
        final deleteFailure = deleteResult.fold<BottleDeleteResult?>(
          BottleDeleteFailed.new,
          (_) => null,
        );
        if (deleteFailure != null) {
          return deleteFailure;
        }

        return BottleDeleted(bottle);
      },
    );
  }

  BottleRenameResult renameBottle(BottleRenameRequest request) {
    final bottleResult = _findBottle(request.bottleId);
    final readFailure = bottleResult.fold<BottleRenameResult?>(
      BottleRenameFailed.new,
      (_) => null,
    );
    if (readFailure != null) {
      return readFailure;
    }
    return bottleResult.getOrElse((_) => const Option.none()).match(
      () => BottleRenameMissing(request.bottleId),
      (bottle) {
        final renamed = _renamedFileBottle(
          bottle: bottle,
          name: request.name,
          dataHome: dataHome,
          bottleDirectory: bottleDirectory,
        );
        if (renamed.id != bottle.id &&
            _fileBottleDirectoryExists(renamed.path)) {
          return BottleRenameConflict(renamed.id);
        }

        final writeResult = _ioResult(() {
          _moveFileBottleDirectoryIfChanged(
            from: bottle.path,
            to: renamed.path,
          );
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
      },
    );
  }

  BottleMoveResult moveBottle(BottleMoveRequest request) {
    final bottleResult = _findBottle(request.bottleId);
    final readFailure = bottleResult.fold<BottleMoveResult?>(
      BottleMoveFailed.new,
      (_) => null,
    );
    if (readFailure != null) {
      return readFailure;
    }
    return bottleResult.getOrElse((_) => const Option.none()).match(
      () => BottleMoveMissing(request.bottleId),
      (bottle) {
        final destinationPath = request.path;
        if (_normalizeFilesystemPath(destinationPath) !=
                _normalizeFilesystemPath(bottle.path) &&
            _fileBottleDirectoryExists(destinationPath)) {
          return BottleMoveConflict(destinationPath);
        }

        final moved = bottle.withPath(destinationPath);

        final writeResult = _ioResult(() {
          _moveFileBottleDirectoryIfChanged(
            from: bottle.path,
            to: destinationPath,
          );
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
      },
    );
  }

  BottleUpdateResult setWindowsVersion(WindowsVersionUpdateRequest request) {
    final bottleResult = _findBottle(request.bottleId);
    final readFailure = bottleResult.fold<BottleUpdateResult?>(
      BottleUpdateFailed.new,
      (_) => null,
    );
    if (readFailure != null) {
      return readFailure;
    }
    return bottleResult.getOrElse((_) => const Option.none()).match(
      () => BottleUpdateMissing(request.bottleId),
      (bottle) {
        final updated = bottle.withWindowsVersion(request.windowsVersion);

        final writeResult = _ioResult(() {
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
      },
    );
  }

  BottleUpdateResult setRuntimeSettings(RuntimeSettingsUpdateRequest request) {
    final bottleResult = _findBottle(request.bottleId);
    final readFailure = bottleResult.fold<BottleUpdateResult?>(
      BottleUpdateFailed.new,
      (_) => null,
    );
    if (readFailure != null) {
      return readFailure;
    }
    return bottleResult.getOrElse((_) => const Option.none()).match(
      () => BottleUpdateMissing(request.bottleId),
      (bottle) {
        final updated = bottle.withRuntimeSettings(request.runtimeSettings);

        final writeResult = _ioResult(() {
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
      },
    );
  }
}
