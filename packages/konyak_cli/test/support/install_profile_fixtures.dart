import 'package:konyak_cli/konyak_cli.dart';

InstallProfileRecord testInstallProfile({
  String id = 'test-profile',
  String name = 'Test Profile',
  String managedProgramPath = r'C:\Test App\Test.exe',
  String executableSuffix = 'test-helper.exe',
  Iterable<String> appendArgumentsIfMissing = const ['--test-compat'],
}) {
  return InstallProfileRecord(
    id: id,
    name: name,
    profileVersion: 1,
    summary: 'A deterministic compatibility profile used by CLI tests.',
    platforms: const ['macos'],
    windowsVersion: 'win10',
    managedProgramPath: managedProgramPath,
    dependencyWinetricksVerbs: const ['corefonts'],
    runCompletionPolicy: ProgramRunCompletionPolicy.launchOnly,
    compatibilityProfile: CompatibilityProfileRecord(
      id: id,
      profileVersion: 1,
      childProcessRules: [
        ChildProcessCompatibilityRule(
          executableSuffix: executableSuffix,
          appendArgumentsIfMissing: appendArgumentsIfMissing,
        ),
      ],
    ),
  );
}

InstallProfileCatalog testInstallProfileCatalog({
  Iterable<InstallProfileRecord>? profiles,
}) {
  return InstallProfileCatalog(profiles ?? [testInstallProfile()]);
}
