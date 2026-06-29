import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../bottle/bottle_models.dart';
import '../shared/domain_value_objects.dart';
import 'program_settings_models.dart';

part 'program_mutation_models.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProgramPinRequest with _$ProgramPinRequest {
  const ProgramPinRequest._();

  factory ProgramPinRequest({
    required String bottleId,
    required String name,
    required String programPath,
  }) {
    return ProgramPinRequest._validated(
      bottleId: BottleId(bottleId),
      name: ProgramName(name),
      programPath: ProgramPath(programPath),
    );
  }

  const factory ProgramPinRequest._validated({
    required BottleId bottleId,
    required ProgramName name,
    required ProgramPath programPath,
  }) = _ProgramPinRequest;
}

sealed class ProgramPinResult {
  const ProgramPinResult();
}

class ProgramPinned extends ProgramPinResult {
  const ProgramPinned(this.bottle);

  final BottleRecord bottle;
}

class ProgramPinMissing extends ProgramPinResult {
  ProgramPinMissing(String bottleId) : bottleId = BottleId(bottleId);

  final BottleId bottleId;
}

class ProgramPinConflict extends ProgramPinResult {
  ProgramPinConflict(String programPath)
    : programPath = ProgramPath(programPath);

  final ProgramPath programPath;
}

class ProgramPinFailed extends ProgramPinResult {
  const ProgramPinFailed(this.message);

  final String message;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProgramUnpinRequest with _$ProgramUnpinRequest {
  const ProgramUnpinRequest._();

  factory ProgramUnpinRequest({
    required String bottleId,
    required String programPath,
  }) {
    return ProgramUnpinRequest._validated(
      bottleId: BottleId(bottleId),
      programPath: ProgramPath(programPath),
    );
  }

  const factory ProgramUnpinRequest._validated({
    required BottleId bottleId,
    required ProgramPath programPath,
  }) = _ProgramUnpinRequest;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProgramRenameRequest with _$ProgramRenameRequest {
  const ProgramRenameRequest._();

  factory ProgramRenameRequest({
    required String bottleId,
    required String programPath,
    required String name,
  }) {
    return ProgramRenameRequest._validated(
      bottleId: BottleId(bottleId),
      programPath: ProgramPath(programPath),
      name: ProgramName(name),
    );
  }

  const factory ProgramRenameRequest._validated({
    required BottleId bottleId,
    required ProgramPath programPath,
    required ProgramName name,
  }) = _ProgramRenameRequest;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class PinnedProgramLauncherManifest
    with _$PinnedProgramLauncherManifest {
  const PinnedProgramLauncherManifest._();

  factory PinnedProgramLauncherManifest({
    required String launcherId,
    required String bottleId,
    required String programPath,
    required String programName,
  }) {
    return PinnedProgramLauncherManifest._validated(
      launcherId: ProgramLauncherId(launcherId),
      bottleId: BottleId(bottleId),
      programPath: ProgramPath(programPath),
      programName: ProgramName(programName),
    );
  }

  const factory PinnedProgramLauncherManifest._validated({
    required ProgramLauncherId launcherId,
    required BottleId bottleId,
    required ProgramPath programPath,
    required ProgramName programName,
  }) = _PinnedProgramLauncherManifest;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class WineProcessTerminationRequest
    with _$WineProcessTerminationRequest {
  const WineProcessTerminationRequest._();

  factory WineProcessTerminationRequest({
    required String bottleId,
    required String processId,
  }) {
    return WineProcessTerminationRequest._validated(
      bottleId: BottleId(bottleId),
      processId: WineProcessId(processId),
    );
  }

  const factory WineProcessTerminationRequest._validated({
    required BottleId bottleId,
    required WineProcessId processId,
  }) = _WineProcessTerminationRequest;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class WineProcessGroupTerminationRequest
    with _$WineProcessGroupTerminationRequest {
  const WineProcessGroupTerminationRequest._();

  factory WineProcessGroupTerminationRequest({
    Option<String> bottleId = const Option.none(),
  }) {
    return WineProcessGroupTerminationRequest._validated(
      bottleId: bottleId.map(BottleId.new),
    );
  }

  const factory WineProcessGroupTerminationRequest._validated({
    required Option<BottleId> bottleId,
  }) = _WineProcessGroupTerminationRequest;
}

sealed class ProgramUpdateResult {
  const ProgramUpdateResult();
}

class ProgramUpdated extends ProgramUpdateResult {
  const ProgramUpdated(this.bottle);

  final BottleRecord bottle;
}

class ProgramUpdateMissingBottle extends ProgramUpdateResult {
  ProgramUpdateMissingBottle(String bottleId) : bottleId = BottleId(bottleId);

  final BottleId bottleId;
}

class ProgramUpdateMissingProgram extends ProgramUpdateResult {
  ProgramUpdateMissingProgram(String programPath)
    : programPath = ProgramPath(programPath);

  final ProgramPath programPath;
}

class ProgramUpdateFailed extends ProgramUpdateResult {
  const ProgramUpdateFailed(this.message);

  final String message;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProgramSettingsRequest with _$ProgramSettingsRequest {
  const ProgramSettingsRequest._();

  factory ProgramSettingsRequest({
    required String bottleId,
    required String programPath,
  }) {
    return ProgramSettingsRequest._validated(
      bottleId: BottleId(bottleId),
      programPath: ProgramPath(programPath),
    );
  }

  const factory ProgramSettingsRequest._validated({
    required BottleId bottleId,
    required ProgramPath programPath,
  }) = _ProgramSettingsRequest;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProgramSettingsUpdateRequest
    with _$ProgramSettingsUpdateRequest {
  const ProgramSettingsUpdateRequest._();

  factory ProgramSettingsUpdateRequest({
    required String bottleId,
    required String programPath,
    required ProgramSettingsRecord settings,
  }) {
    return ProgramSettingsUpdateRequest._validated(
      bottleId: BottleId(bottleId),
      programPath: ProgramPath(programPath),
      settings: settings,
    );
  }

  const factory ProgramSettingsUpdateRequest._validated({
    required BottleId bottleId,
    required ProgramPath programPath,
    required ProgramSettingsRecord settings,
  }) = _ProgramSettingsUpdateRequest;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class ProgramSettingsReadResult with _$ProgramSettingsReadResult {
  const ProgramSettingsReadResult._();

  const factory ProgramSettingsReadResult.read(ProgramSettingsRecord settings) =
      ProgramSettingsRead;

  factory ProgramSettingsReadResult.missingBottle(String bottleId) {
    return ProgramSettingsReadResult._missingBottle(
      bottleId: BottleId(bottleId),
    );
  }

  const factory ProgramSettingsReadResult._missingBottle({
    required BottleId bottleId,
  }) = ProgramSettingsReadMissingBottle;

  const factory ProgramSettingsReadResult.failed(String message) =
      ProgramSettingsReadFailed;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class ProgramSettingsUpdateResult with _$ProgramSettingsUpdateResult {
  const ProgramSettingsUpdateResult._();

  const factory ProgramSettingsUpdateResult.updated(
    ProgramSettingsRecord settings,
  ) = ProgramSettingsUpdated;

  factory ProgramSettingsUpdateResult.missingBottle(String bottleId) {
    return ProgramSettingsUpdateResult._missingBottle(
      bottleId: BottleId(bottleId),
    );
  }

  const factory ProgramSettingsUpdateResult._missingBottle({
    required BottleId bottleId,
  }) = ProgramSettingsUpdateMissingBottle;

  const factory ProgramSettingsUpdateResult.failed(String message) =
      ProgramSettingsUpdateFailed;
}
