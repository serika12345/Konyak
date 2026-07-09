import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:fpdart/fpdart.dart';

import '../bottle/bottle_models.dart';
import '../shared/domain_value_objects.dart';
import 'pinned_programs.dart';
import 'program_catalog_models.dart';
import 'program_mutation_models.dart';
import 'program_profile_catalog.dart';
import 'program_profile_models.dart';

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

  if (hasPinnedProgram(profiledBottle, programPath)) {
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
        (existing) => !isSameProgramProfile(existing, profile.profileId),
      ),
      profile,
    ].toIList(),
  );
}

bool isSameProgramProfile(ProgramProfileRecord profile, ProfileId profileId) {
  return profile.profileId == profileId;
}
