import 'package:fpdart/fpdart.dart';

import '../shared/domain_value_objects.dart';
import 'program_profile_models.dart';
import 'program_run_models.dart';

final installProfileCatalog = List<InstallProfileRecord>.unmodifiable([
  steamInstallProfile,
]);

final steamInstallProfile = InstallProfileRecord(
  id: 'steam',
  name: 'Steam',
  profileVersion: 1,
  summary: 'Install and launch Steam with Konyak-managed metadata.',
  platforms: const ['macos'],
  windowsVersion: 'win10',
  managedProgramPath: r'C:\Program Files (x86)\Steam\Steam.exe',
  dependencyWinetricksVerbs: const ['corefonts'],
  runCompletionPolicy: ProgramRunCompletionPolicy.launchOnly,
  compatibilityProfile: CompatibilityProfileRecord(
    id: 'steam',
    profileVersion: 1,
    childProcessRules: [
      ChildProcessCompatibilityRule(
        executableSuffix: 'steamwebhelper.exe',
        appendArgumentsIfMissing: const [
          '--use-angle=swiftshader-webgl',
          '--use-gl=angle',
          '--no-sandbox',
          '--in-process-gpu',
          '--disable-gpu',
        ],
      ),
    ],
  ),
);

Option<InstallProfileRecord> findInstallProfile(ProfileId profileId) {
  final matches = installProfileCatalog
      .where((profile) => profile.id == profileId)
      .toList(growable: false);
  return matches.isEmpty ? const Option.none() : Option.of(matches.first);
}

ProgramProfileRecord programProfileFromInstallProfile({
  required InstallProfileRecord installProfile,
  required ProgramPath managedProgramPath,
}) {
  return ProgramProfileRecord(
    profileId: installProfile.id.value,
    profileVersion: installProfile.profileVersion.value,
    managedProgramPath: managedProgramPath.value,
    compatibilityProfileId: installProfile.compatibilityProfile.id.value,
    compatibilityProfileVersion:
        installProfile.compatibilityProfile.profileVersion.value,
  );
}
