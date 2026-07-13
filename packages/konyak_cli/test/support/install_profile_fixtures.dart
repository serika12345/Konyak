import 'package:konyak_cli/konyak_cli.dart';

InstallerResourceRecord testInstallerResource() {
  return InstallerResourceRecord(
    kind: 'https',
    url: 'https://downloads.example.test/TestSetup.exe',
    sha256: '0123456789abcdef' * 4,
    fileName: 'TestSetup.exe',
  );
}

InstallProfileRecord testInstallProfile({
  String id = 'test-profile',
  String name = 'Test Profile',
  String managedProgramPath = r'C:\Test App\Test.exe',
  Iterable<String> platforms = const <String>['macos'],
  String windowsVersion = 'win10',
  Iterable<String> dependencyWinetricksVerbs = const ['corefonts'],
  String executableSuffix = 'test-helper.exe',
  Iterable<String> appendArgumentsIfMissing = const ['--test-compat'],
}) {
  return InstallProfileRecord(
    id: id,
    sourceId: '$id.json',
    manifestDigest: 'fedcba9876543210' * 4,
    name: name,
    profileVersion: 1,
    summary: 'A deterministic compatibility profile used by CLI tests.',
    platforms: platforms,
    windowsVersion: windowsVersion,
    managedProgramPath: managedProgramPath,
    installerResource: testInstallerResource(),
    dependencyWinetricksVerbs: dependencyWinetricksVerbs,
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
