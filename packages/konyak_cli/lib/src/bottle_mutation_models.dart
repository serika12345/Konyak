part of '../konyak_cli.dart';

class BottleCreateRequest {
  const BottleCreateRequest({required this.name, required this.windowsVersion});

  final String name;
  final String windowsVersion;
}

class BottleArchiveExportRequest {
  const BottleArchiveExportRequest({
    required this.bottleId,
    required this.archivePath,
  });

  final String bottleId;
  final String archivePath;
}

class BottleArchiveImportRequest {
  const BottleArchiveImportRequest({required this.archivePath});

  final String archivePath;
}

class BottleArchiveRecord {
  const BottleArchiveRecord({
    required this.bottleId,
    required this.archivePath,
  });

  final String bottleId;
  final String archivePath;

  Map<String, Object?> toJson() {
    return <String, Object?>{'bottleId': bottleId, 'archivePath': archivePath};
  }
}

sealed class BottleCreateResult {
  const BottleCreateResult();
}

class BottleCreated extends BottleCreateResult {
  const BottleCreated(this.bottle);

  final BottleRecord bottle;
}

class BottleCreateConflict extends BottleCreateResult {
  const BottleCreateConflict(this.bottleId);

  final String bottleId;
}

sealed class BottleArchiveExportResult {
  const BottleArchiveExportResult();
}

class BottleArchiveExported extends BottleArchiveExportResult {
  const BottleArchiveExported(this.archive);

  final BottleArchiveRecord archive;
}

class BottleArchiveExportMissing extends BottleArchiveExportResult {
  const BottleArchiveExportMissing(this.bottleId);

  final String bottleId;
}

class BottleArchiveExportFailed extends BottleArchiveExportResult {
  const BottleArchiveExportFailed(this.message);

  final String message;
}

sealed class BottleArchiveImportResult {
  const BottleArchiveImportResult();
}

class BottleArchiveImported extends BottleArchiveImportResult {
  const BottleArchiveImported(this.bottle);

  final BottleRecord bottle;
}

class BottleArchiveImportConflict extends BottleArchiveImportResult {
  const BottleArchiveImportConflict(this.bottleId);

  final String bottleId;
}

class BottleArchiveImportFailed extends BottleArchiveImportResult {
  const BottleArchiveImportFailed(this.message);

  final String message;
}

sealed class BottleDeleteResult {
  const BottleDeleteResult();
}

class BottleDeleted extends BottleDeleteResult {
  const BottleDeleted(this.bottle);

  final BottleRecord bottle;
}

class BottleDeleteMissing extends BottleDeleteResult {
  const BottleDeleteMissing(this.bottleId);

  final String bottleId;
}

class BottleRenameRequest {
  const BottleRenameRequest({required this.bottleId, required this.name});

  final String bottleId;
  final String name;
}

sealed class BottleRenameResult {
  const BottleRenameResult();
}

class BottleRenamed extends BottleRenameResult {
  const BottleRenamed(this.bottle);

  final BottleRecord bottle;
}

class BottleRenameMissing extends BottleRenameResult {
  const BottleRenameMissing(this.bottleId);

  final String bottleId;
}

class BottleRenameConflict extends BottleRenameResult {
  const BottleRenameConflict(this.bottleId);

  final String bottleId;
}

class BottleMoveRequest {
  const BottleMoveRequest({required this.bottleId, required this.path});

  final String bottleId;
  final String path;
}

sealed class BottleMoveResult {
  const BottleMoveResult();
}

class BottleMoved extends BottleMoveResult {
  const BottleMoved(this.bottle);

  final BottleRecord bottle;
}

class BottleMoveMissing extends BottleMoveResult {
  const BottleMoveMissing(this.bottleId);

  final String bottleId;
}

class BottleMoveConflict extends BottleMoveResult {
  const BottleMoveConflict(this.path);

  final String path;
}

class WindowsVersionUpdateRequest {
  const WindowsVersionUpdateRequest({
    required this.bottleId,
    required this.windowsVersion,
  });

  final String bottleId;
  final String windowsVersion;
}

class RuntimeSettingsUpdateRequest {
  const RuntimeSettingsUpdateRequest({
    required this.bottleId,
    required this.runtimeSettings,
  });

  final String bottleId;
  final BottleRuntimeSettings runtimeSettings;
}

sealed class BottleUpdateResult {
  const BottleUpdateResult();
}

class BottleUpdated extends BottleUpdateResult {
  const BottleUpdated(this.bottle);

  final BottleRecord bottle;
}

class BottleUpdateMissing extends BottleUpdateResult {
  const BottleUpdateMissing(this.bottleId);

  final String bottleId;
}
