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
      bottleDirectory: Option.of(bottleDirectory),
    );
    if (_fileBottlePathExists(bottle.path.value)) {
      return BottleCreateConflict(bottle.id.value);
    }

    final writeResult = _ioResult(() {
      _createFileBottleDirectories(bottle.path.value);
      _writeBottleMetadata(bottle);
    });
    return writeResult.fold<BottleCreateResult>(
      BottleCreateFailed.new,
      (_) => BottleCreated(bottle),
    );
  }

  BottleDeleteResult deleteBottle(String id) {
    return _findBottle(id).fold<BottleDeleteResult>(
      BottleDeleteFailed.new,
      (bottle) => bottle.match(() => BottleDeleteMissing(id), (bottle) {
        final deleteResult = _ioResult(() {
          _deleteFileBottleDirectoryIfPresent(bottle.path.value);
        });
        return deleteResult.fold<BottleDeleteResult>(
          BottleDeleteFailed.new,
          (_) => BottleDeleted(bottle),
        );
      }),
    );
  }

  BottleRenameResult renameBottle(BottleRenameRequest request) {
    return _findBottle(request.bottleId.value).fold<BottleRenameResult>(
      BottleRenameFailed.new,
      (bottle) => bottle.match(
        () => BottleRenameMissing(request.bottleId.value),
        (bottle) {
          final renamed = _renamedFileBottle(
            bottle: bottle,
            name: request.name.value,
            dataHome: dataHome,
            bottleDirectory: Option.of(bottleDirectory),
          );
          if (renamed.id.value != bottle.id.value &&
              _fileBottleDirectoryExists(renamed.path.value)) {
            return BottleRenameConflict(renamed.id.value);
          }

          final writeResult = _ioResult(() {
            _moveFileBottleDirectoryIfChanged(
              from: bottle.path.value,
              to: renamed.path.value,
            );
            _writeBottleMetadata(renamed);
          });
          return writeResult.fold<BottleRenameResult>(
            BottleRenameFailed.new,
            (_) => BottleRenamed(renamed),
          );
        },
      ),
    );
  }

  BottleMoveResult moveBottle(BottleMoveRequest request) {
    return _findBottle(request.bottleId.value).fold<BottleMoveResult>(
      BottleMoveFailed.new,
      (bottle) => bottle.match(
        () => BottleMoveMissing(request.bottleId.value),
        (bottle) {
          final destinationPath = request.path.value;
          if (_normalizeFilesystemPath(destinationPath) !=
                  _normalizeFilesystemPath(bottle.path.value) &&
              _fileBottleDirectoryExists(destinationPath)) {
            return BottleMoveConflict(destinationPath);
          }

          final moved = bottle.withPath(destinationPath);

          final writeResult = _ioResult(() {
            _moveFileBottleDirectoryIfChanged(
              from: bottle.path.value,
              to: destinationPath,
            );
            _writeBottleMetadata(moved);
          });
          return writeResult.fold<BottleMoveResult>(
            BottleMoveFailed.new,
            (_) => BottleMoved(moved),
          );
        },
      ),
    );
  }

  BottleUpdateResult setWindowsVersion(WindowsVersionUpdateRequest request) {
    return _findBottle(request.bottleId.value).fold<BottleUpdateResult>(
      BottleUpdateFailed.new,
      (bottle) => bottle.match(
        () => BottleUpdateMissing(request.bottleId.value),
        (bottle) {
          final updated = bottle.withWindowsVersion(
            request.windowsVersion.value,
          );

          final writeResult = _ioResult(() {
            _writeBottleMetadata(updated);
          });
          return writeResult.fold<BottleUpdateResult>(
            BottleUpdateFailed.new,
            (_) => BottleUpdated(updated),
          );
        },
      ),
    );
  }

  BottleUpdateResult setRuntimeSettings(RuntimeSettingsUpdateRequest request) {
    return _findBottle(request.bottleId.value).fold<BottleUpdateResult>(
      BottleUpdateFailed.new,
      (bottle) => bottle.match(
        () => BottleUpdateMissing(request.bottleId.value),
        (bottle) {
          final updated = bottle.withRuntimeSettings(request.runtimeSettings);

          final writeResult = _ioResult(() {
            _writeBottleMetadata(updated);
          });
          return writeResult.fold<BottleUpdateResult>(
            BottleUpdateFailed.new,
            (_) => BottleUpdated(updated),
          );
        },
      ),
    );
  }
}
