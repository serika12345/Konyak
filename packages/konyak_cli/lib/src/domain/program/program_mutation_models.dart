import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../bottle/bottle_models.dart';
import '../shared/domain_value_objects.dart';
import 'program_profile_models.dart';
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
    required BottleId bottleId,
    required ProgramName name,
    required ProgramPath programPath,
  }) {
    return ProgramPinRequest._validated(
      bottleId: bottleId,
      name: name,
      programPath: programPath,
    );
  }

  const factory ProgramPinRequest._validated({
    required BottleId bottleId,
    required ProgramName name,
    required ProgramPath programPath,
  }) = _ProgramPinRequest;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class ProgramPinResult with _$ProgramPinResult {
  const ProgramPinResult._();

  const factory ProgramPinResult.pinned(BottleRecord bottle) = ProgramPinned;

  factory ProgramPinResult.missing(BottleId bottleId) {
    return ProgramPinResult._missing(bottleId: bottleId);
  }

  const factory ProgramPinResult._missing({required BottleId bottleId}) =
      ProgramPinMissing;

  factory ProgramPinResult.conflict(ProgramPath programPath) {
    return ProgramPinResult._conflict(programPath: programPath);
  }

  const factory ProgramPinResult._conflict({required ProgramPath programPath}) =
      ProgramPinConflict;

  const factory ProgramPinResult.failed(String message) = ProgramPinFailed;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProgramUnpinRequest with _$ProgramUnpinRequest {
  const ProgramUnpinRequest._();

  factory ProgramUnpinRequest({
    required BottleId bottleId,
    required ProgramPath programPath,
  }) {
    return ProgramUnpinRequest._validated(
      bottleId: bottleId,
      programPath: programPath,
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
    required BottleId bottleId,
    required ProgramPath programPath,
    required ProgramName name,
  }) {
    return ProgramRenameRequest._validated(
      bottleId: bottleId,
      programPath: programPath,
      name: name,
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
    required ProgramLauncherId launcherId,
    required BottleId bottleId,
    required ProgramPath programPath,
    required ProgramName programName,
  }) {
    return PinnedProgramLauncherManifest._validated(
      launcherId: launcherId,
      bottleId: bottleId,
      programPath: programPath,
      programName: programName,
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
    required BottleId bottleId,
    required WineProcessId processId,
  }) {
    return WineProcessTerminationRequest._validated(
      bottleId: bottleId,
      processId: processId,
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
    Option<BottleId> bottleId = const Option.none(),
  }) {
    return WineProcessGroupTerminationRequest._validated(bottleId: bottleId);
  }

  const factory WineProcessGroupTerminationRequest._validated({
    required Option<BottleId> bottleId,
  }) = _WineProcessGroupTerminationRequest;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class ProgramUpdateResult with _$ProgramUpdateResult {
  const ProgramUpdateResult._();

  const factory ProgramUpdateResult.updated(BottleRecord bottle) =
      ProgramUpdated;

  factory ProgramUpdateResult.missingBottle(BottleId bottleId) {
    return ProgramUpdateResult._missingBottle(bottleId: bottleId);
  }

  const factory ProgramUpdateResult._missingBottle({
    required BottleId bottleId,
  }) = ProgramUpdateMissingBottle;

  factory ProgramUpdateResult.missingProgram(ProgramPath programPath) {
    return ProgramUpdateResult._missingProgram(programPath: programPath);
  }

  const factory ProgramUpdateResult._missingProgram({
    required ProgramPath programPath,
  }) = ProgramUpdateMissingProgram;

  const factory ProgramUpdateResult.failed(String message) =
      ProgramUpdateFailed;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProgramSettingsRequest with _$ProgramSettingsRequest {
  const ProgramSettingsRequest._();

  factory ProgramSettingsRequest({
    required BottleId bottleId,
    required ProgramPath programPath,
  }) {
    return ProgramSettingsRequest._validated(
      bottleId: bottleId,
      programPath: programPath,
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
    required BottleId bottleId,
    required ProgramPath programPath,
    required ProgramSettingsRecord settings,
  }) {
    return ProgramSettingsUpdateRequest._validated(
      bottleId: bottleId,
      programPath: programPath,
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

  factory ProgramSettingsReadResult.missingBottle(BottleId bottleId) {
    return ProgramSettingsReadResult._missingBottle(bottleId: bottleId);
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

  factory ProgramSettingsUpdateResult.missingBottle(BottleId bottleId) {
    return ProgramSettingsUpdateResult._missingBottle(bottleId: bottleId);
  }

  const factory ProgramSettingsUpdateResult._missingBottle({
    required BottleId bottleId,
  }) = ProgramSettingsUpdateMissingBottle;

  const factory ProgramSettingsUpdateResult.failed(String message) =
      ProgramSettingsUpdateFailed;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProgramProfileApplyRequest with _$ProgramProfileApplyRequest {
  const ProgramProfileApplyRequest._();

  factory ProgramProfileApplyRequest({
    required BottleId bottleId,
    required InstallProfileRecord installProfile,
    required ProgramPath programPath,
  }) {
    return ProgramProfileApplyRequest._validated(
      bottleId: bottleId,
      installProfile: installProfile,
      programPath: programPath,
    );
  }

  const factory ProgramProfileApplyRequest._validated({
    required BottleId bottleId,
    required InstallProfileRecord installProfile,
    required ProgramPath programPath,
  }) = _ProgramProfileApplyRequest;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProgramProfileRepairRequest with _$ProgramProfileRepairRequest {
  const ProgramProfileRepairRequest._();

  factory ProgramProfileRepairRequest({
    required BottleId bottleId,
    required InstallProfileRecord installProfile,
  }) {
    return ProgramProfileRepairRequest._validated(
      bottleId: bottleId,
      installProfile: installProfile,
    );
  }

  const factory ProgramProfileRepairRequest._validated({
    required BottleId bottleId,
    required InstallProfileRecord installProfile,
  }) = _ProgramProfileRepairRequest;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class ProgramProfileUpdateResult with _$ProgramProfileUpdateResult {
  const ProgramProfileUpdateResult._();

  const factory ProgramProfileUpdateResult.updated({
    required BottleId bottleId,
    required ProgramProfileRecord profile,
  }) = ProgramProfileUpdated;

  factory ProgramProfileUpdateResult.missingBottle(BottleId bottleId) {
    return ProgramProfileUpdateResult._missingBottle(bottleId: bottleId);
  }

  const factory ProgramProfileUpdateResult._missingBottle({
    required BottleId bottleId,
  }) = ProgramProfileUpdateMissingBottle;

  factory ProgramProfileUpdateResult.profileNotApplied(ProfileId profileId) {
    return ProgramProfileUpdateResult._profileNotApplied(profileId: profileId);
  }

  const factory ProgramProfileUpdateResult._profileNotApplied({
    required ProfileId profileId,
  }) = ProgramProfileUpdateProfileNotApplied;

  const factory ProgramProfileUpdateResult.failed(String message) =
      ProgramProfileUpdateFailed;
}
