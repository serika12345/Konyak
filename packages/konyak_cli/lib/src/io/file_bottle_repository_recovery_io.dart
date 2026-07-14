import 'dart:io';

import '../domain/bottle/bottle_metadata_recovery_models.dart';
import '../domain/shared/domain_value_objects.dart';
import '../shared/common_helpers.dart';
import 'bottle_metadata_recovery_io.dart';
import 'file_bottle_repository_io.dart';
import 'io_result.dart';

class FileBottleRepositoryRecoveryOperations {
  const FileBottleRepositoryRecoveryOperations({required this.bottleDirectory});

  final String bottleDirectory;

  BottleMetadataRepairResult repairBottleMetadata(
    BottleMetadataRepairRequest request,
  ) {
    final result = ioResult(() => _repairBottleMetadata(request));
    return result.fold(
      (message) => BottleMetadataRepairFailed(
        storageId: request.storageId,
        message: message,
      ),
      (repairResult) => repairResult,
    );
  }

  BottleMetadataRepairResult _repairBottleMetadata(
    BottleMetadataRepairRequest request,
  ) {
    final bottleRoot = Directory(bottleDirectory);
    if (!bottleRoot.existsSync()) {
      return BottleMetadataRepairMissing(request.storageId);
    }

    final bottlePath = fileBottlePath(bottleDirectory, request.storageId.value);
    final bottleType = FileSystemEntity.typeSync(
      bottlePath,
      followLinks: false,
    );
    if (bottleType == FileSystemEntityType.notFound) {
      return BottleMetadataRepairMissing(request.storageId);
    }
    if (bottleType == FileSystemEntityType.link) {
      return BottleMetadataRepairNotRepairable(
        storageId: request.storageId,
        message: symlinkedBottleStorageMessage,
      );
    }
    if (bottleType != FileSystemEntityType.directory ||
        !_isContainedBottleDirectory(
          bottleRoot: bottleRoot,
          bottlePath: bottlePath,
        )) {
      return BottleMetadataRepairNotRepairable(
        storageId: request.storageId,
        message: bottleMetadataNotRepairableMessage,
      );
    }

    final metadataPath = fileBottleMetadataPath(bottlePath);
    final metadataType = FileSystemEntity.typeSync(
      metadataPath,
      followLinks: false,
    );
    if (metadataType == FileSystemEntityType.notFound) {
      return BottleMetadataRepairMissing(request.storageId);
    }
    if (metadataType == FileSystemEntityType.link) {
      return BottleMetadataRepairNotRepairable(
        storageId: request.storageId,
        message: symlinkedBottleMetadataMessage,
      );
    }
    if (metadataType != FileSystemEntityType.file) {
      return BottleMetadataRepairNotRepairable(
        storageId: request.storageId,
        message: bottleMetadataNotRepairableMessage,
      );
    }

    final inspection = inspectBottleMetadata(
      bottlePath: bottlePath,
      storageId: request.storageId,
    );
    return switch (inspection) {
      ValidBottleMetadata() => BottleMetadataRepairNotRepairable(
        storageId: request.storageId,
        message: bottleMetadataNotRepairableMessage,
      ),
      InvalidBottleMetadata(:final summary, :final recovery) =>
        switch (recovery) {
          NoBottleMetadataRecovery() => BottleMetadataRepairNotRepairable(
            storageId: request.storageId,
            message: summary.message == symlinkedBottleMetadataMessage
                ? summary.message
                : bottleMetadataNotRepairableMessage,
          ),
          DiscardInvalidProgramProfilesRecovery(
            :final bottle,
            :final originalMetadata,
          ) =>
            () {
              final backupPath = atomicallyReplaceBottleMetadataWithBackup(
                bottlePath: bottlePath,
                bottle: bottle,
                expectedOriginalMetadata: originalMetadata,
              );
              return BottleMetadataRepaired(
                BottleMetadataRepairRecord(
                  storageId: request.storageId,
                  action: request.action,
                  backupPath: BottlePath(backupPath),
                  bottle: bottle,
                ),
              );
            }(),
        },
    };
  }
}

bool _isContainedBottleDirectory({
  required Directory bottleRoot,
  required String bottlePath,
}) {
  final resolvedRoot = normalizeFilesystemPath(
    bottleRoot.resolveSymbolicLinksSync(),
  );
  final resolvedBottle = normalizeFilesystemPath(
    Directory(bottlePath).resolveSymbolicLinksSync(),
  );
  return resolvedBottle != resolvedRoot &&
      isPathWithinRoot(path: resolvedBottle, root: resolvedRoot);
}
