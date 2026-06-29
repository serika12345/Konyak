import 'package:freezed_annotation/freezed_annotation.dart';

import '../shared/domain_value_objects.dart';
import 'bottle_models.dart';
import 'bottle_runtime_settings_models.dart';

part 'bottle_mutation_models.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleCreateRequest with _$BottleCreateRequest {
  const BottleCreateRequest._();

  factory BottleCreateRequest({
    required BottleName name,
    required WindowsVersion windowsVersion,
  }) {
    return BottleCreateRequest._validated(
      name: name,
      windowsVersion: windowsVersion,
    );
  }

  const factory BottleCreateRequest._validated({
    required BottleName name,
    required WindowsVersion windowsVersion,
  }) = _BottleCreateRequest;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleArchiveExportRequest with _$BottleArchiveExportRequest {
  const BottleArchiveExportRequest._();

  factory BottleArchiveExportRequest({
    required BottleId bottleId,
    required BottleArchivePath archivePath,
  }) {
    return BottleArchiveExportRequest._validated(
      bottleId: bottleId,
      archivePath: archivePath,
    );
  }

  const factory BottleArchiveExportRequest._validated({
    required BottleId bottleId,
    required BottleArchivePath archivePath,
  }) = _BottleArchiveExportRequest;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleArchiveImportRequest with _$BottleArchiveImportRequest {
  const BottleArchiveImportRequest._();

  factory BottleArchiveImportRequest({required BottleArchivePath archivePath}) {
    return BottleArchiveImportRequest._validated(archivePath: archivePath);
  }

  const factory BottleArchiveImportRequest._validated({
    required BottleArchivePath archivePath,
  }) = _BottleArchiveImportRequest;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleArchiveRecord with _$BottleArchiveRecord {
  const BottleArchiveRecord._();

  factory BottleArchiveRecord({
    required BottleId bottleId,
    required BottleArchivePath archivePath,
  }) {
    return BottleArchiveRecord._validated(
      bottleId: bottleId,
      archivePath: archivePath,
    );
  }

  const factory BottleArchiveRecord._validated({
    required BottleId bottleId,
    required BottleArchivePath archivePath,
  }) = _BottleArchiveRecord;
}

sealed class BottleCreateResult {
  const BottleCreateResult();
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleCreated extends BottleCreateResult with _$BottleCreated {
  const BottleCreated._() : super();

  const factory BottleCreated(BottleRecord bottle) = _BottleCreated;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleCreateConflict extends BottleCreateResult
    with _$BottleCreateConflict {
  const BottleCreateConflict._() : super();

  factory BottleCreateConflict(BottleId bottleId) {
    return BottleCreateConflict._validated(bottleId);
  }

  const factory BottleCreateConflict._validated(BottleId bottleId) =
      _BottleCreateConflict;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleCreateFailed extends BottleCreateResult
    with _$BottleCreateFailed {
  const BottleCreateFailed._() : super();

  const factory BottleCreateFailed(String message) = _BottleCreateFailed;
}

sealed class BottleArchiveExportResult {
  const BottleArchiveExportResult();
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleArchiveExported extends BottleArchiveExportResult
    with _$BottleArchiveExported {
  const BottleArchiveExported._() : super();

  const factory BottleArchiveExported(BottleArchiveRecord archive) =
      _BottleArchiveExported;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleArchiveExportMissing extends BottleArchiveExportResult
    with _$BottleArchiveExportMissing {
  const BottleArchiveExportMissing._() : super();

  factory BottleArchiveExportMissing(BottleId bottleId) {
    return BottleArchiveExportMissing._validated(bottleId);
  }

  const factory BottleArchiveExportMissing._validated(BottleId bottleId) =
      _BottleArchiveExportMissing;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleArchiveExportFailed extends BottleArchiveExportResult
    with _$BottleArchiveExportFailed {
  const BottleArchiveExportFailed._() : super();

  const factory BottleArchiveExportFailed(String message) =
      _BottleArchiveExportFailed;
}

sealed class BottleArchiveImportResult {
  const BottleArchiveImportResult();
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleArchiveImported extends BottleArchiveImportResult
    with _$BottleArchiveImported {
  const BottleArchiveImported._() : super();

  const factory BottleArchiveImported(BottleRecord bottle) =
      _BottleArchiveImported;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleArchiveImportConflict extends BottleArchiveImportResult
    with _$BottleArchiveImportConflict {
  const BottleArchiveImportConflict._() : super();

  factory BottleArchiveImportConflict(BottleId bottleId) {
    return BottleArchiveImportConflict._validated(bottleId);
  }

  const factory BottleArchiveImportConflict._validated(BottleId bottleId) =
      _BottleArchiveImportConflict;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleArchiveImportFailed extends BottleArchiveImportResult
    with _$BottleArchiveImportFailed {
  const BottleArchiveImportFailed._() : super();

  const factory BottleArchiveImportFailed(String message) =
      _BottleArchiveImportFailed;
}

sealed class BottleDeleteResult {
  const BottleDeleteResult();
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleDeleted extends BottleDeleteResult with _$BottleDeleted {
  const BottleDeleted._() : super();

  const factory BottleDeleted(BottleRecord bottle) = _BottleDeleted;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleDeleteMissing extends BottleDeleteResult
    with _$BottleDeleteMissing {
  const BottleDeleteMissing._() : super();

  factory BottleDeleteMissing(BottleId bottleId) {
    return BottleDeleteMissing._validated(bottleId);
  }

  const factory BottleDeleteMissing._validated(BottleId bottleId) =
      _BottleDeleteMissing;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleDeleteFailed extends BottleDeleteResult
    with _$BottleDeleteFailed {
  const BottleDeleteFailed._() : super();

  const factory BottleDeleteFailed(String message) = _BottleDeleteFailed;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleRenameRequest with _$BottleRenameRequest {
  const BottleRenameRequest._();

  factory BottleRenameRequest({
    required BottleId bottleId,
    required BottleName name,
  }) {
    return BottleRenameRequest._validated(bottleId: bottleId, name: name);
  }

  const factory BottleRenameRequest._validated({
    required BottleId bottleId,
    required BottleName name,
  }) = _BottleRenameRequest;
}

sealed class BottleRenameResult {
  const BottleRenameResult();
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleRenamed extends BottleRenameResult with _$BottleRenamed {
  const BottleRenamed._() : super();

  const factory BottleRenamed(BottleRecord bottle) = _BottleRenamed;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleRenameMissing extends BottleRenameResult
    with _$BottleRenameMissing {
  const BottleRenameMissing._() : super();

  factory BottleRenameMissing(BottleId bottleId) {
    return BottleRenameMissing._validated(bottleId);
  }

  const factory BottleRenameMissing._validated(BottleId bottleId) =
      _BottleRenameMissing;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleRenameConflict extends BottleRenameResult
    with _$BottleRenameConflict {
  const BottleRenameConflict._() : super();

  factory BottleRenameConflict(BottleId bottleId) {
    return BottleRenameConflict._validated(bottleId);
  }

  const factory BottleRenameConflict._validated(BottleId bottleId) =
      _BottleRenameConflict;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleRenameFailed extends BottleRenameResult
    with _$BottleRenameFailed {
  const BottleRenameFailed._() : super();

  const factory BottleRenameFailed(String message) = _BottleRenameFailed;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleMoveRequest with _$BottleMoveRequest {
  const BottleMoveRequest._();

  factory BottleMoveRequest({
    required BottleId bottleId,
    required BottlePath path,
  }) {
    return BottleMoveRequest._validated(bottleId: bottleId, path: path);
  }

  const factory BottleMoveRequest._validated({
    required BottleId bottleId,
    required BottlePath path,
  }) = _BottleMoveRequest;
}

sealed class BottleMoveResult {
  const BottleMoveResult();
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleMoved extends BottleMoveResult with _$BottleMoved {
  const BottleMoved._() : super();

  const factory BottleMoved(BottleRecord bottle) = _BottleMoved;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleMoveMissing extends BottleMoveResult
    with _$BottleMoveMissing {
  const BottleMoveMissing._() : super();

  factory BottleMoveMissing(BottleId bottleId) {
    return BottleMoveMissing._validated(bottleId);
  }

  const factory BottleMoveMissing._validated(BottleId bottleId) =
      _BottleMoveMissing;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleMoveConflict extends BottleMoveResult
    with _$BottleMoveConflict {
  const BottleMoveConflict._() : super();

  factory BottleMoveConflict(BottlePath path) {
    return BottleMoveConflict._validated(path);
  }

  const factory BottleMoveConflict._validated(BottlePath path) =
      _BottleMoveConflict;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleMoveFailed extends BottleMoveResult
    with _$BottleMoveFailed {
  const BottleMoveFailed._() : super();

  const factory BottleMoveFailed(String message) = _BottleMoveFailed;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class WindowsVersionUpdateRequest with _$WindowsVersionUpdateRequest {
  const WindowsVersionUpdateRequest._();

  factory WindowsVersionUpdateRequest({
    required BottleId bottleId,
    required WindowsVersion windowsVersion,
  }) {
    return WindowsVersionUpdateRequest._validated(
      bottleId: bottleId,
      windowsVersion: windowsVersion,
    );
  }

  const factory WindowsVersionUpdateRequest._validated({
    required BottleId bottleId,
    required WindowsVersion windowsVersion,
  }) = _WindowsVersionUpdateRequest;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeSettingsUpdateRequest
    with _$RuntimeSettingsUpdateRequest {
  const RuntimeSettingsUpdateRequest._();

  factory RuntimeSettingsUpdateRequest({
    required BottleId bottleId,
    required BottleRuntimeSettings runtimeSettings,
  }) {
    return RuntimeSettingsUpdateRequest._validated(
      bottleId: bottleId,
      runtimeSettings: runtimeSettings,
    );
  }

  const factory RuntimeSettingsUpdateRequest._validated({
    required BottleId bottleId,
    required BottleRuntimeSettings runtimeSettings,
  }) = _RuntimeSettingsUpdateRequest;
}

sealed class BottleUpdateResult {
  const BottleUpdateResult();
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleUpdated extends BottleUpdateResult with _$BottleUpdated {
  const BottleUpdated._() : super();

  const factory BottleUpdated(BottleRecord bottle) = _BottleUpdated;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleUpdateMissing extends BottleUpdateResult
    with _$BottleUpdateMissing {
  const BottleUpdateMissing._() : super();

  factory BottleUpdateMissing(BottleId bottleId) {
    return BottleUpdateMissing._validated(bottleId);
  }

  const factory BottleUpdateMissing._validated(BottleId bottleId) =
      _BottleUpdateMissing;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleUpdateFailed extends BottleUpdateResult
    with _$BottleUpdateFailed {
  const BottleUpdateFailed._() : super();

  const factory BottleUpdateFailed(String message) = _BottleUpdateFailed;
}
