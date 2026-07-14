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
  dependency('dependency'),
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
    @Default(Option<int>.none()) Option<int> dependencyIndex,
    @Default(Option<WinetricksVerbId>.none())
    Option<WinetricksVerbId> dependencyVerb,
  }) = ProgramProfileInstallStageStarted;

  const factory ProgramProfileInstallProgress.completed({
    required ProgramProfileInstallStage stage,
    @Default(Option<int>.none()) Option<int> dependencyIndex,
    @Default(Option<WinetricksVerbId>.none())
    Option<WinetricksVerbId> dependencyVerb,
  }) = ProgramProfileInstallStageCompleted;

  const factory ProgramProfileInstallProgress.failed({
    required ProgramProfileInstallStage stage,
    required String code,
    @Default(Option<int>.none()) Option<int> dependencyIndex,
    @Default(Option<WinetricksVerbId>.none())
    Option<WinetricksVerbId> dependencyVerb,
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
  ProgramProfileInstallResult install(ProgramProfileInstallRequest request);

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
    @Default(Option<int>.none()) Option<int> dependencyIndex,
    @Default(Option<WinetricksVerbId>.none())
    Option<WinetricksVerbId> dependencyVerb,
    @Default(Option<int>.none()) Option<int> processExitCode,
  }) = ProgramProfileInstallFailed;
}

abstract interface class ProfileInstallerResourceFetcher {
  ProfileInstallerResourceFetchResult fetch(InstallerResourceRecord resource);

  ProfileInstallerResourceReleaseResult release(
    ProfileInstallerResourceFetched resource,
  );
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
