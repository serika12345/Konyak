import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:fpdart/fpdart.dart';

import '../bottle/bottle_models.dart';
import '../shared/domain_value_objects.dart';
import 'pinned_programs.dart';
import 'program_catalog_models.dart';
import 'program_mutation_models.dart';
import 'program_profile_catalog.dart';
import 'program_profile_models.dart';
import 'program_run_environment.dart';
import 'program_run_models.dart';

Option<ProgramProfileRecord> findProgramProfile(
  BottleRecord bottle,
  ProfileId profileId,
) {
  final matches = bottle.programProfiles
      .where((profile) => profile.profileId == profileId)
      .toList(growable: false);
  return matches.isEmpty ? const Option.none() : Option.of(matches.first);
}

BottleRecord bottleWithAppliedProgramProfile({
  required BottleRecord bottle,
  required InstallProfileRecord installProfile,
  required ProgramPath programPath,
  required ProgramMetadataExtractor programMetadataExtractor,
}) {
  final profile = programProfileFromInstallProfile(
    installProfile: installProfile,
    managedProgramPath: programPath,
  );
  final profiledBottle = bottleWithProgramProfile(
    bottle: bottle,
    profile: profile,
  );

  if (_hasEquivalentPinnedProgram(profiledBottle, programPath)) {
    return profiledBottle;
  }

  return bottleWithPinnedProgram(
    profiledBottle,
    ProgramPinRequest(
      bottleId: bottle.id,
      name: ProgramName(installProfile.name.value),
      programPath: programPath,
    ),
    programMetadataExtractor: programMetadataExtractor,
  );
}

BottleRecord bottleWithRepairedProgramProfile({
  required BottleRecord bottle,
  required InstallProfileRecord installProfile,
  required ProgramMetadataExtractor programMetadataExtractor,
}) {
  final existingProfile = findProgramProfile(bottle, installProfile.id)
      .getOrElse(
        () => programProfileFromInstallProfile(
          installProfile: installProfile,
          managedProgramPath: installProfile.managedProgramPath,
        ),
      );
  return bottleWithAppliedProgramProfile(
    bottle: bottle,
    installProfile: installProfile,
    programPath: existingProfile.managedProgramPath,
    programMetadataExtractor: programMetadataExtractor,
  );
}

BottleRecord bottleWithProgramProfile({
  required BottleRecord bottle,
  required ProgramProfileRecord profile,
}) {
  return bottle.copyWith(
    programProfiles: <ProgramProfileRecord>[
      ...bottle.programProfiles.where(
        (existing) =>
            !isSameProgramProfile(existing, profile.profileId) &&
            !_hasEquivalentProgramPath(
              bottle: bottle,
              left: existing.managedProgramPath,
              right: profile.managedProgramPath,
            ),
      ),
      profile,
    ].toIList(),
  );
}

bool isSameProgramProfile(ProgramProfileRecord profile, ProfileId profileId) {
  return profile.profileId == profileId;
}

Option<ProgramProfileRecord> findProgramProfileForPath(
  BottleRecord bottle,
  ProgramPath programPath,
) {
  final matches = bottle.programProfiles
      .where(
        (profile) => _hasEquivalentProgramPath(
          bottle: bottle,
          left: profile.managedProgramPath,
          right: programPath,
        ),
      )
      .toList(growable: false);
  return matches.isEmpty ? const Option.none() : Option.of(matches.first);
}

bool _hasEquivalentPinnedProgram(BottleRecord bottle, ProgramPath programPath) {
  return bottle.pinnedPrograms.any(
    (pinnedProgram) => _hasEquivalentProgramPath(
      bottle: bottle,
      left: pinnedProgram.path,
      right: programPath,
    ),
  );
}

bool _hasEquivalentProgramPath({
  required BottleRecord bottle,
  required ProgramPath left,
  required ProgramPath right,
}) {
  return _programPathKey(bottle, left) == _programPathKey(bottle, right);
}

String _programPathKey(BottleRecord bottle, ProgramPath programPath) {
  final path = programPath.value;
  return _normalizedWindowsProgramPath(path).getOrElse(() {
    final driveCPrefix = '${bottle.path.value}/drive_c/';
    if (path.startsWith(driveCPrefix)) {
      final relativePath = path.substring(driveCPrefix.length);
      return 'c:\\${relativePath.replaceAll('/', '\\')}'.toLowerCase();
    }

    return path;
  });
}

Option<String> _normalizedWindowsProgramPath(String path) {
  return Option.fromPredicate(
    path,
    (value) => RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(value),
  ).map((value) => value.replaceAll('/', '\\').toLowerCase());
}

ProgramRunCompletionPolicy programRunCompletionPolicyForProfiledPath({
  required InstallProfileCatalog installProfileCatalog,
  required BottleRecord bottle,
  required ProgramPath programPath,
}) {
  return installProfileForProgramPath(
        installProfileCatalog: installProfileCatalog,
        bottle: bottle,
        programPath: programPath,
      )
      .map((profile) => profile.runCompletionPolicy)
      .getOrElse(() => ProgramRunCompletionPolicy.waitForExit);
}

Option<InstallProfileRecord> installProfileForProgramPath({
  required InstallProfileCatalog installProfileCatalog,
  required BottleRecord bottle,
  required ProgramPath programPath,
}) {
  return findProgramProfileForPath(
    bottle,
    programPath,
  ).flatMap((profile) => installProfileCatalog.find(profile.profileId));
}

ProgramRunEnvironment childProcessCompatibilityEnvironmentForProfiledPath({
  required InstallProfileCatalog installProfileCatalog,
  required BottleRecord bottle,
  required ProgramPath programPath,
}) {
  final rules = installProfileForProgramPath(
    installProfileCatalog: installProfileCatalog,
    bottle: bottle,
    programPath: programPath,
  ).map((profile) => profile.compatibilityProfile.childProcessRules);
  return rules
      .map(_serializedChildProcessRules)
      .match(
        () => const ProgramRunEnvironment.empty(),
        (value) => value.isEmpty
            ? const ProgramRunEnvironment.empty()
            : ProgramRunEnvironment(<String, String>{
                konyakChildProcessRulesEnvironmentVariable: value,
              }),
      );
}

String _serializedChildProcessRules(
  IList<ChildProcessCompatibilityRule> rules,
) {
  return rules
      .expand(
        (rule) => rule.appendArgumentsIfMissing.value.map(
          (argument) => '${rule.executableSuffix.value}\t$argument',
        ),
      )
      .join('\n');
}
