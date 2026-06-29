import 'package:fpdart/fpdart.dart';

import '../domain/bottle/bottle_models.dart';
import '../domain/bottle/bottle_mutation_models.dart';
import '../domain/shared/domain_value_objects.dart';
import '../io/file_bottle_repository_io.dart';
import '../io/io_result.dart';
import '../io/repository_storage_io.dart';
import '../shared/common_helpers.dart';
import '../storage/storage_paths.dart';

class FileBottleRepositoryMutationOperations {
  const FileBottleRepositoryMutationOperations({
    required this.dataHome,
    required this.bottleDirectory,
    required this.findBottle,
  });

  final String dataHome;
  final String bottleDirectory;
  final IoResult<Option<BottleRecord>> Function(BottleId id) findBottle;

  BottleCreateResult createBottle(BottleCreateRequest request) {
    final bottle = bottleFromCreateRequest(
      request,
      dataHome,
      bottleDirectory: Option.of(bottleDirectory),
    );
    if (fileBottlePathExists(bottle.path.value)) {
      return BottleCreateConflict(bottle.id);
    }

    final writeResult = ioResult(() {
      createFileBottleDirectories(bottle.path.value);
      writeBottleMetadata(bottle);
    });
    return writeResult.fold<BottleCreateResult>(
      BottleCreateFailed.new,
      (_) => BottleCreated(bottle),
    );
  }

  BottleDeleteResult deleteBottle(BottleId id) {
    return findBottle(id).fold<BottleDeleteResult>(
      BottleDeleteFailed.new,
      (bottle) => bottle.match(() => BottleDeleteMissing(id), (bottle) {
        final deleteResult = ioResult(() {
          deleteFileBottleDirectoryIfPresent(bottle.path.value);
        });
        return deleteResult.fold<BottleDeleteResult>(
          BottleDeleteFailed.new,
          (_) => BottleDeleted(bottle),
        );
      }),
    );
  }

  BottleRenameResult renameBottle(BottleRenameRequest request) {
    return findBottle(request.bottleId).fold<BottleRenameResult>(
      BottleRenameFailed.new,
      (bottle) =>
          bottle.match(() => BottleRenameMissing(request.bottleId), (bottle) {
            final renamed = renamedFileBottle(
              bottle: bottle,
              name: request.name.value,
              dataHome: dataHome,
              bottleDirectory: Option.of(bottleDirectory),
            );
            if (renamed.id.value != bottle.id.value &&
                fileBottleDirectoryExists(renamed.path.value)) {
              return BottleRenameConflict(renamed.id);
            }

            final writeResult = ioResult(() {
              moveFileBottleDirectoryIfChanged(
                from: bottle.path.value,
                to: renamed.path.value,
              );
              writeBottleMetadata(renamed);
            });
            return writeResult.fold<BottleRenameResult>(
              BottleRenameFailed.new,
              (_) => BottleRenamed(renamed),
            );
          }),
    );
  }

  BottleMoveResult moveBottle(BottleMoveRequest request) {
    return findBottle(request.bottleId).fold<BottleMoveResult>(
      BottleMoveFailed.new,
      (bottle) =>
          bottle.match(() => BottleMoveMissing(request.bottleId), (bottle) {
            final destinationPath = request.path.value;
            if (normalizeFilesystemPath(destinationPath) !=
                    normalizeFilesystemPath(bottle.path.value) &&
                fileBottleDirectoryExists(destinationPath)) {
              return BottleMoveConflict(BottlePath(destinationPath));
            }

            final moved = bottle.copyWith(path: request.path);

            final writeResult = ioResult(() {
              moveFileBottleDirectoryIfChanged(
                from: bottle.path.value,
                to: destinationPath,
              );
              writeBottleMetadata(moved);
            });
            return writeResult.fold<BottleMoveResult>(
              BottleMoveFailed.new,
              (_) => BottleMoved(moved),
            );
          }),
    );
  }

  BottleUpdateResult setWindowsVersion(WindowsVersionUpdateRequest request) {
    return findBottle(request.bottleId).fold<BottleUpdateResult>(
      BottleUpdateFailed.new,
      (bottle) => bottle.match(() => BottleUpdateMissing(request.bottleId), (
        bottle,
      ) {
        final updated = bottle.copyWith(windowsVersion: request.windowsVersion);

        final writeResult = ioResult(() {
          writeBottleMetadata(updated);
        });
        return writeResult.fold<BottleUpdateResult>(
          BottleUpdateFailed.new,
          (_) => BottleUpdated(updated),
        );
      }),
    );
  }

  BottleUpdateResult setRuntimeSettings(RuntimeSettingsUpdateRequest request) {
    return findBottle(request.bottleId).fold<BottleUpdateResult>(
      BottleUpdateFailed.new,
      (bottle) =>
          bottle.match(() => BottleUpdateMissing(request.bottleId), (bottle) {
            final updated = bottle.copyWith(
              runtimeSettings: request.runtimeSettings,
            );

            final writeResult = ioResult(() {
              writeBottleMetadata(updated);
            });
            return writeResult.fold<BottleUpdateResult>(
              BottleUpdateFailed.new,
              (_) => BottleUpdated(updated),
            );
          }),
    );
  }
}
