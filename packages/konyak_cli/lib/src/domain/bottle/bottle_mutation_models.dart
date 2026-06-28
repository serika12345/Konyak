import '../shared/domain_value_objects.dart';
import 'bottle_models.dart';
import 'bottle_runtime_settings_models.dart';

class BottleCreateRequest {
  BottleCreateRequest({required String name, required String windowsVersion})
    : name = BottleName(name),
      windowsVersion = WindowsVersion(windowsVersion);

  final BottleName name;
  final WindowsVersion windowsVersion;
}

class BottleArchiveExportRequest {
  BottleArchiveExportRequest({
    required String bottleId,
    required String archivePath,
  }) : bottleId = BottleId(bottleId),
       archivePath = BottleArchivePath(archivePath);

  final BottleId bottleId;
  final BottleArchivePath archivePath;
}

class BottleArchiveImportRequest {
  BottleArchiveImportRequest({required String archivePath})
    : archivePath = BottleArchivePath(archivePath);

  final BottleArchivePath archivePath;
}

class BottleArchiveRecord {
  BottleArchiveRecord({required String bottleId, required String archivePath})
    : bottleId = BottleId(bottleId),
      archivePath = BottleArchivePath(archivePath);

  final BottleId bottleId;
  final BottleArchivePath archivePath;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'bottleId': bottleId.value,
      'archivePath': archivePath.value,
    };
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
  BottleCreateConflict(String bottleId) : bottleId = BottleId(bottleId);

  final BottleId bottleId;
}

class BottleCreateFailed extends BottleCreateResult {
  const BottleCreateFailed(this.message);

  final String message;
}

sealed class BottleArchiveExportResult {
  const BottleArchiveExportResult();
}

class BottleArchiveExported extends BottleArchiveExportResult {
  const BottleArchiveExported(this.archive);

  final BottleArchiveRecord archive;
}

class BottleArchiveExportMissing extends BottleArchiveExportResult {
  BottleArchiveExportMissing(String bottleId) : bottleId = BottleId(bottleId);

  final BottleId bottleId;
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
  BottleArchiveImportConflict(String bottleId) : bottleId = BottleId(bottleId);

  final BottleId bottleId;
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
  BottleDeleteMissing(String bottleId) : bottleId = BottleId(bottleId);

  final BottleId bottleId;
}

class BottleDeleteFailed extends BottleDeleteResult {
  const BottleDeleteFailed(this.message);

  final String message;
}

class BottleRenameRequest {
  BottleRenameRequest({required String bottleId, required String name})
    : bottleId = BottleId(bottleId),
      name = BottleName(name);

  final BottleId bottleId;
  final BottleName name;
}

sealed class BottleRenameResult {
  const BottleRenameResult();
}

class BottleRenamed extends BottleRenameResult {
  const BottleRenamed(this.bottle);

  final BottleRecord bottle;
}

class BottleRenameMissing extends BottleRenameResult {
  BottleRenameMissing(String bottleId) : bottleId = BottleId(bottleId);

  final BottleId bottleId;
}

class BottleRenameConflict extends BottleRenameResult {
  BottleRenameConflict(String bottleId) : bottleId = BottleId(bottleId);

  final BottleId bottleId;
}

class BottleRenameFailed extends BottleRenameResult {
  const BottleRenameFailed(this.message);

  final String message;
}

class BottleMoveRequest {
  BottleMoveRequest({required String bottleId, required String path})
    : bottleId = BottleId(bottleId),
      path = BottlePath(path);

  final BottleId bottleId;
  final BottlePath path;
}

sealed class BottleMoveResult {
  const BottleMoveResult();
}

class BottleMoved extends BottleMoveResult {
  const BottleMoved(this.bottle);

  final BottleRecord bottle;
}

class BottleMoveMissing extends BottleMoveResult {
  BottleMoveMissing(String bottleId) : bottleId = BottleId(bottleId);

  final BottleId bottleId;
}

class BottleMoveConflict extends BottleMoveResult {
  BottleMoveConflict(String path) : path = BottlePath(path);

  final BottlePath path;
}

class BottleMoveFailed extends BottleMoveResult {
  const BottleMoveFailed(this.message);

  final String message;
}

class WindowsVersionUpdateRequest {
  WindowsVersionUpdateRequest({
    required String bottleId,
    required String windowsVersion,
  }) : bottleId = BottleId(bottleId),
       windowsVersion = WindowsVersion(windowsVersion);

  final BottleId bottleId;
  final WindowsVersion windowsVersion;
}

class RuntimeSettingsUpdateRequest {
  RuntimeSettingsUpdateRequest({
    required String bottleId,
    required this.runtimeSettings,
  }) : bottleId = BottleId(bottleId);

  final BottleId bottleId;
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
  BottleUpdateMissing(String bottleId) : bottleId = BottleId(bottleId);

  final BottleId bottleId;
}

class BottleUpdateFailed extends BottleUpdateResult {
  const BottleUpdateFailed(this.message);

  final String message;
}
