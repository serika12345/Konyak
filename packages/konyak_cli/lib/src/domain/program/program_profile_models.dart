import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../shared/domain_value_objects.dart';

part 'program_profile_models.freezed.dart';

@Freezed(map: FreezedMapOptions.none, when: FreezedWhenOptions.none)
abstract class InstallProfileRecord with _$InstallProfileRecord {
  const InstallProfileRecord._();

  factory InstallProfileRecord({
    required String id,
    required String name,
    required int profileVersion,
    required String summary,
    required Iterable<String> platforms,
    required String windowsVersion,
    required String managedProgramPath,
    required Iterable<String> dependencyWinetricksVerbs,
    required CompatibilityProfileRecord compatibilityProfile,
  }) {
    return InstallProfileRecord._validated(
      id: ProfileId(id),
      name: ProfileName(name),
      profileVersion: ProfileVersion(profileVersion),
      summary: ProfileSummary(summary),
      platforms: platforms.map(RuntimePlatformName.new).toIList(),
      windowsVersion: WindowsVersion(windowsVersion),
      managedProgramPath: ProgramPath(managedProgramPath),
      dependencyWinetricksVerbs: dependencyWinetricksVerbs
          .map(WinetricksVerbId.new)
          .toIList(),
      compatibilityProfile: compatibilityProfile,
    );
  }

  const factory InstallProfileRecord._validated({
    required ProfileId id,
    required ProfileName name,
    required ProfileVersion profileVersion,
    required ProfileSummary summary,
    required IList<RuntimePlatformName> platforms,
    required WindowsVersion windowsVersion,
    required ProgramPath managedProgramPath,
    required IList<WinetricksVerbId> dependencyWinetricksVerbs,
    required CompatibilityProfileRecord compatibilityProfile,
  }) = _InstallProfileRecord;
}

@Freezed(map: FreezedMapOptions.none, when: FreezedWhenOptions.none)
abstract class CompatibilityProfileRecord with _$CompatibilityProfileRecord {
  const CompatibilityProfileRecord._();

  factory CompatibilityProfileRecord({
    required String id,
    required int profileVersion,
    required Iterable<ChildProcessCompatibilityRule> childProcessRules,
  }) {
    return CompatibilityProfileRecord._validated(
      id: ProfileId(id),
      profileVersion: ProfileVersion(profileVersion),
      childProcessRules: childProcessRules.toIList(),
    );
  }

  const factory CompatibilityProfileRecord._validated({
    required ProfileId id,
    required ProfileVersion profileVersion,
    required IList<ChildProcessCompatibilityRule> childProcessRules,
  }) = _CompatibilityProfileRecord;
}

@Freezed(map: FreezedMapOptions.none, when: FreezedWhenOptions.none)
abstract class ChildProcessCompatibilityRule
    with _$ChildProcessCompatibilityRule {
  const ChildProcessCompatibilityRule._();

  factory ChildProcessCompatibilityRule({
    required String executableSuffix,
    required Iterable<String> appendArgumentsIfMissing,
  }) {
    return ChildProcessCompatibilityRule._validated(
      executableSuffix: ProgramExecutable(executableSuffix),
      appendArgumentsIfMissing: ProgramRunArguments(appendArgumentsIfMissing),
    );
  }

  const factory ChildProcessCompatibilityRule._validated({
    required ProgramExecutable executableSuffix,
    required ProgramRunArguments appendArgumentsIfMissing,
  }) = _ChildProcessCompatibilityRule;
}

@Freezed(map: FreezedMapOptions.none, when: FreezedWhenOptions.none)
abstract class ProgramProfileRecord with _$ProgramProfileRecord {
  const ProgramProfileRecord._();

  factory ProgramProfileRecord({
    required String profileId,
    required int profileVersion,
    required String managedProgramPath,
    required String compatibilityProfileId,
    required int compatibilityProfileVersion,
  }) {
    return ProgramProfileRecord._validated(
      profileId: ProfileId(profileId),
      profileVersion: ProfileVersion(profileVersion),
      managedProgramPath: ProgramPath(managedProgramPath),
      compatibilityProfileId: ProfileId(compatibilityProfileId),
      compatibilityProfileVersion: ProfileVersion(compatibilityProfileVersion),
    );
  }

  const factory ProgramProfileRecord._validated({
    required ProfileId profileId,
    required ProfileVersion profileVersion,
    required ProgramPath managedProgramPath,
    required ProfileId compatibilityProfileId,
    required ProfileVersion compatibilityProfileVersion,
  }) = _ProgramProfileRecord;
}
