import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../shared/domain_value_objects.dart';
import 'bottle_models.dart';

part 'bottle_metadata_recovery_models.freezed.dart';

enum InvalidBottleMetadataCode {
  invalidProgramProfiles('invalidProgramProfiles'),
  invalidBottleMetadata('invalidBottleMetadata');

  const InvalidBottleMetadataCode(this.value);

  final String value;
}

enum BottleMetadataRecoveryAction {
  discardInvalidProfiles(
    cliValue: 'discard-invalid-profiles',
    jsonValue: 'discardInvalidProfiles',
  );

  const BottleMetadataRecoveryAction({
    required this.cliValue,
    required this.jsonValue,
  });

  final String cliValue;
  final String jsonValue;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleStorageId with _$BottleStorageId {
  const BottleStorageId._();

  factory BottleStorageId(String value) {
    final normalized = value.trim();
    if (!_isValidBottleStorageId(normalized)) {
      throw ArgumentError.value(value, 'storageId', 'Invalid storage ID.');
    }
    return BottleStorageId._validated(normalized);
  }

  const factory BottleStorageId._validated(String value) = _BottleStorageId;
}

bool isValidBottleStorageId(String value) {
  return _isValidBottleStorageId(value.trim());
}

bool _isValidBottleStorageId(String value) {
  return value.isNotEmpty &&
      value != '.' &&
      value != '..' &&
      !value.contains('/') &&
      !value.contains(r'\') &&
      !value.contains('\u0000');
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class InvalidBottleSummary with _$InvalidBottleSummary {
  const InvalidBottleSummary._();

  factory InvalidBottleSummary({
    required BottleStorageId storageId,
    required BottlePath path,
    required InvalidBottleMetadataCode code,
    required String message,
    Iterable<BottleMetadataRecoveryAction> recoveryActions =
        const <BottleMetadataRecoveryAction>[],
  }) {
    return InvalidBottleSummary._validated(
      storageId: storageId,
      path: path,
      code: code,
      message: message,
      recoveryActions: recoveryActions.toIList(),
    );
  }

  const factory InvalidBottleSummary._validated({
    required BottleStorageId storageId,
    required BottlePath path,
    required InvalidBottleMetadataCode code,
    required String message,
    required IList<BottleMetadataRecoveryAction> recoveryActions,
  }) = _InvalidBottleSummary;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleCatalogSnapshot with _$BottleCatalogSnapshot {
  const BottleCatalogSnapshot._();

  factory BottleCatalogSnapshot({
    Iterable<BottleRecord> bottles = const <BottleRecord>[],
    Iterable<InvalidBottleSummary> invalidBottles =
        const <InvalidBottleSummary>[],
  }) {
    return BottleCatalogSnapshot._validated(
      bottles: bottles.toIList(),
      invalidBottles: invalidBottles.toIList(),
    );
  }

  const factory BottleCatalogSnapshot._validated({
    required IList<BottleRecord> bottles,
    required IList<InvalidBottleSummary> invalidBottles,
  }) = _BottleCatalogSnapshot;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleMetadataRepairRequest with _$BottleMetadataRepairRequest {
  const BottleMetadataRepairRequest._();

  const factory BottleMetadataRepairRequest({
    required BottleStorageId storageId,
    required BottleMetadataRecoveryAction action,
  }) = _BottleMetadataRepairRequest;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleMetadataRepairRecord with _$BottleMetadataRepairRecord {
  const BottleMetadataRepairRecord._();

  const factory BottleMetadataRepairRecord({
    required BottleStorageId storageId,
    required BottleMetadataRecoveryAction action,
    required BottlePath backupPath,
    required BottleRecord bottle,
  }) = _BottleMetadataRepairRecord;
}

sealed class BottleMetadataRepairResult {
  const BottleMetadataRepairResult();
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleMetadataRepaired extends BottleMetadataRepairResult
    with _$BottleMetadataRepaired {
  const BottleMetadataRepaired._() : super();

  const factory BottleMetadataRepaired(BottleMetadataRepairRecord repair) =
      _BottleMetadataRepaired;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleMetadataRepairMissing extends BottleMetadataRepairResult
    with _$BottleMetadataRepairMissing {
  const BottleMetadataRepairMissing._() : super();

  const factory BottleMetadataRepairMissing(BottleStorageId storageId) =
      _BottleMetadataRepairMissing;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleMetadataRepairNotRepairable
    extends BottleMetadataRepairResult
    with _$BottleMetadataRepairNotRepairable {
  const BottleMetadataRepairNotRepairable._() : super();

  const factory BottleMetadataRepairNotRepairable({
    required BottleStorageId storageId,
    required String message,
  }) = _BottleMetadataRepairNotRepairable;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class BottleMetadataRepairFailed extends BottleMetadataRepairResult
    with _$BottleMetadataRepairFailed {
  const BottleMetadataRepairFailed._() : super();

  const factory BottleMetadataRepairFailed({
    required BottleStorageId storageId,
    required String message,
  }) = _BottleMetadataRepairFailed;
}
