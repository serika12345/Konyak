import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../bottle/bottle_models.dart';
import '../shared/domain_value_objects.dart';
import 'program_profile_models.dart';

part 'program_profile_install_models.freezed.dart';

enum ProgramProfileInstallStage {
  preflight('preflight'),
  download('download'),
  verification('verification'),
  installer('installer'),
  preInstallAction('preInstallAction'),
  managedProgram('managedProgram'),
  persistence('persistence'),
  resourceCleanup('resourceCleanup');

  const ProgramProfileInstallStage(this.value);

  final String value;
}

abstract interface class ProgramProfileInstallProgressSink {
  void report(ProgramProfileInstallProgress progress);
}

final class NoopProgramProfileInstallProgressSink
    implements ProgramProfileInstallProgressSink {
  const NoopProgramProfileInstallProgressSink();

  @override
  void report(ProgramProfileInstallProgress progress) {}
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class ProgramProfileInstallProgress
    with _$ProgramProfileInstallProgress {
  const ProgramProfileInstallProgress._();

  const factory ProgramProfileInstallProgress.started({
    required ProgramProfileInstallStage stage,
    @Default(Option<int>.none()) Option<int> actionIndex,
    @Default(Option<PreInstallActionKind>.none())
    Option<PreInstallActionKind> actionKind,
    @Default(Option<PreInstallActionId>.none())
    Option<PreInstallActionId> actionId,
  }) = ProgramProfileInstallStageStarted;

  const factory ProgramProfileInstallProgress.completed({
    required ProgramProfileInstallStage stage,
    @Default(Option<int>.none()) Option<int> actionIndex,
    @Default(Option<PreInstallActionKind>.none())
    Option<PreInstallActionKind> actionKind,
    @Default(Option<PreInstallActionId>.none())
    Option<PreInstallActionId> actionId,
  }) = ProgramProfileInstallStageCompleted;

  const factory ProgramProfileInstallProgress.failed({
    required ProgramProfileInstallStage stage,
    required String code,
    @Default(Option<int>.none()) Option<int> actionIndex,
    @Default(Option<PreInstallActionKind>.none())
    Option<PreInstallActionKind> actionKind,
    @Default(Option<PreInstallActionId>.none())
    Option<PreInstallActionId> actionId,
  }) = ProgramProfileInstallStageFailed;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProgramProfileInstallRequest
    with _$ProgramProfileInstallRequest {
  const ProgramProfileInstallRequest._();

  const factory ProgramProfileInstallRequest({
    required ProfileId profileId,
    required BottleId bottleId,
  }) = _ProgramProfileInstallRequest;
}

abstract interface class ProgramProfileInstaller {
  Future<ProgramProfileInstallResult> install(
    ProgramProfileInstallRequest request,
  );

  ProgramProfileInstaller withProgressSink(
    ProgramProfileInstallProgressSink progressSink,
  );
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class ProgramProfileInstallResult with _$ProgramProfileInstallResult {
  const ProgramProfileInstallResult._();

  const factory ProgramProfileInstallResult.installed({
    required BottleId bottleId,
    required ProgramProfileRecord profile,
  }) = ProgramProfileInstalled;

  const factory ProgramProfileInstallResult.failed({
    required ProgramProfileInstallStage stage,
    required String code,
    required String message,
    @Default(Option<int>.none()) Option<int> actionIndex,
    @Default(Option<PreInstallActionKind>.none())
    Option<PreInstallActionKind> actionKind,
    @Default(Option<PreInstallActionId>.none())
    Option<PreInstallActionId> actionId,
    @Default(Option<int>.none()) Option<int> processExitCode,
  }) = ProgramProfileInstallFailed;
}

abstract interface class ProfileInstallerResourceFetcher {
  ProfileInstallerResourceFetchResult fetch(
    ProfileResourceFetchRequest request,
  );

  ProfileInstallerResourceReleaseResult release(
    ProfileInstallerResourceFetched resource,
  );
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProfileResourceFetchRequest with _$ProfileResourceFetchRequest {
  const ProfileResourceFetchRequest._();

  factory ProfileResourceFetchRequest.installer(
    InstallerResourceRecord resource,
  ) {
    return ProfileResourceFetchRequest._validated(
      url: resource.url,
      sha256: resource.sha256,
      fileName: resource.fileName.value,
    );
  }

  factory ProfileResourceFetchRequest.nativeDll(
    NativeDllResourceRecord resource,
  ) {
    return ProfileResourceFetchRequest._validated(
      url: resource.url,
      sha256: resource.sha256,
      fileName: resource.fileName.value,
    );
  }

  const factory ProfileResourceFetchRequest._validated({
    required InstallerResourceUrl url,
    required InstallerResourceSha256 sha256,
    required String fileName,
  }) = _ProfileResourceFetchRequest;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class ProfileInstallerResourceFetchResult
    with _$ProfileInstallerResourceFetchResult {
  const ProfileInstallerResourceFetchResult._();

  const factory ProfileInstallerResourceFetchResult.fetched(ProgramPath path) =
      ProfileInstallerResourceFetched;

  const factory ProfileInstallerResourceFetchResult.downloadFailed(
    String message,
  ) = ProfileInstallerResourceDownloadFailed;

  const factory ProfileInstallerResourceFetchResult.digestMismatch({
    required InstallerResourceSha256 expected,
    required String actual,
  }) = ProfileInstallerResourceDigestMismatch;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class ProfileInstallerResourceReleaseResult
    with _$ProfileInstallerResourceReleaseResult {
  const ProfileInstallerResourceReleaseResult._();

  const factory ProfileInstallerResourceReleaseResult.released() =
      ProfileInstallerResourceReleased;

  const factory ProfileInstallerResourceReleaseResult.failed({
    required String code,
    required String message,
  }) = ProfileInstallerResourceReleaseFailed;
}

abstract interface class ManagedProfileProgramVerifier {
  ManagedProfileProgramVerificationResult verify({
    required BottleRecord bottle,
    required ProgramPath managedProgramPath,
  });
}

abstract interface class NativeDllInstaller {
  NativeDllInstallResult install({
    required BottleRecord bottle,
    required NativeDllPreInstallAction action,
    required ProgramPath resourcePath,
  });
}

final class UnsupportedNativeDllInstaller implements NativeDllInstaller {
  const UnsupportedNativeDllInstaller();

  @override
  NativeDllInstallResult install({
    required BottleRecord bottle,
    required NativeDllPreInstallAction action,
    required ProgramPath resourcePath,
  }) {
    return const NativeDllInstallFailed(
      code: 'nativeDllInstallerUnavailable',
      message: 'Native DLL installation is unavailable.',
    );
  }
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class NativeDllInstallResult with _$NativeDllInstallResult {
  const NativeDllInstallResult._();

  const factory NativeDllInstallResult.installed({required bool changed}) =
      NativeDllInstalled;

  const factory NativeDllInstallResult.failed({
    required String code,
    required String message,
  }) = NativeDllInstallFailed;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class ManagedProfileProgramVerificationResult
    with _$ManagedProfileProgramVerificationResult {
  const ManagedProfileProgramVerificationResult._();

  const factory ManagedProfileProgramVerificationResult.verified(
    ProgramPath path,
  ) = ManagedProfileProgramVerified;

  const factory ManagedProfileProgramVerificationResult.failed({
    required String code,
    required String message,
  }) = ManagedProfileProgramVerificationFailed;
}
