import 'package:fpdart/fpdart.dart';
import 'package:konyak_cli/konyak_cli.dart';
import 'package:test/test.dart';

import 'support/install_profile_fixtures.dart';

void main() {
  test('plans profile installers with blocking platform-specific argv', () {
    final bottle = BottleRecord(
      id: 'test',
      name: 'Test',
      path: '/bottles/test',
      windowsVersion: 'win10',
    );
    final macosPlanner = ProgramRunPlanner(
      hostPlatform: KonyakHostPlatform.macos,
      environment: HostEnvironment({'HOME': '/Users/test'}),
    );
    final linuxPlanner = ProgramRunPlanner(
      hostPlatform: KonyakHostPlatform.linux,
      environment: HostEnvironment({
        'HOME': '/home/test',
        'KONYAK_LINUX_WINE_HOME': '/runtime',
      }),
    );

    final macosExe = macosPlanner
        .planInstaller(
          bottle: bottle,
          installerPath: ProgramPath('/downloads/Setup.exe'),
        )
        .getOrElse(() => throw TestFailure('Expected macOS EXE plan.'));
    final macosMsi = macosPlanner
        .planInstaller(
          bottle: bottle,
          installerPath: ProgramPath('/downloads/Setup.msi'),
        )
        .getOrElse(() => throw TestFailure('Expected macOS MSI plan.'));
    final linuxExe = linuxPlanner
        .planInstaller(
          bottle: bottle,
          installerPath: ProgramPath('/downloads/Setup.exe'),
        )
        .getOrElse(() => throw TestFailure('Expected Linux EXE plan.'));

    expect(macosExe.arguments.value, [
      'start',
      '/wait',
      '/unix',
      '/downloads/Setup.exe',
    ]);
    expect(macosMsi.arguments.value, ['msiexec', '/i', '/downloads/Setup.msi']);
    expect(linuxExe.arguments.value, ['/downloads/Setup.exe']);
    expect(macosExe.completionPolicy, ProgramRunCompletionPolicy.waitForExit);

    final normalMacosExe = macosPlanner
        .plan(bottle: bottle, programPath: ProgramPath('/downloads/Setup.exe'))
        .getOrElse(() => throw TestFailure('Expected normal macOS EXE plan.'));
    expect(normalMacosExe.arguments.value, [
      'start',
      '/unix',
      '/downloads/Setup.exe',
    ]);
  });

  test('preserves dependency winetricks order in the domain model', () {
    final profile = testInstallProfile(
      dependencyWinetricksVerbs: const ['vcrun2022', 'corefonts'],
    );

    expect(profile.dependencyWinetricksVerbs.map((verb) => verb.value), [
      'vcrun2022',
      'corefonts',
    ]);
  });

  test('rejects unsafe dependency winetricks verbs in the domain model', () {
    expect(
      () =>
          testInstallProfile(dependencyWinetricksVerbs: const ['corefonts;rm']),
      throwsArgumentError,
    );
  });

  test('rejects duplicate dependency winetricks verbs in the domain model', () {
    expect(
      () => testInstallProfile(
        dependencyWinetricksVerbs: const ['corefonts', 'corefonts'],
      ),
      throwsArgumentError,
    );
  });

  test(
    'rejects more than 64 dependency winetricks verbs in the domain model',
    () {
      expect(
        () => testInstallProfile(
          dependencyWinetricksVerbs: [
            for (var index = 0; index < 65; index++) 'verb$index',
          ],
        ),
        throwsArgumentError,
      );
    },
  );

  for (final invalidManagedProgramPath in <String>[
    'Steam.exe',
    r'D:\Program Files\Steam\Steam.exe',
    r'C:\Program Files\\Steam.exe',
    r'C:\Program Files\.\Steam.exe',
    r'C:\Program Files\..\Steam.exe',
    '${r'C:\Program Files\Steam'}\u0000.exe',
    r'C:\Program Files\Steam\Steam.msi',
  ]) {
    test(
      'rejects unsafe managed program path $invalidManagedProgramPath in the '
      'domain model',
      () {
        expect(
          () =>
              testInstallProfile(managedProgramPath: invalidManagedProgramPath),
          throwsArgumentError,
        );
      },
    );
  }

  test('serializes child-process rules for a bound synthetic profile', () {
    final installProfile = testInstallProfile(
      executableSuffix: 'synthetic-helper.exe',
      appendArgumentsIfMissing: const ['--first', '--second=value'],
    );
    final bottle = BottleRecord(
      id: 'test',
      name: 'Test',
      path: '/bottles/test',
      windowsVersion: 'win10',
      programProfiles: [
        ProgramProfileRecord(
          profileId: installProfile.id.value,
          profileVersion: installProfile.profileVersion.value,
          managedProgramPath: installProfile.managedProgramPath.value,
          installerResource: installProfile.installerResource,
          profileSourceId: installProfile.sourceId.value,
          profileDigest: installProfile.manifestDigest.value,
          compatibilityProfileId: installProfile.compatibilityProfile.id.value,
          compatibilityProfileVersion:
              installProfile.compatibilityProfile.profileVersion.value,
        ),
      ],
    );

    final environment = childProcessCompatibilityEnvironmentForProfiledPath(
      installProfileCatalog: InstallProfileCatalog([installProfile]),
      bottle: bottle,
      programPath: installProfile.managedProgramPath,
    );

    expect(environment.toMap(), {
      konyakChildProcessRulesEnvironmentVariable:
          'synthetic-helper.exe\t--first\n'
          'synthetic-helper.exe\t--second=value',
    });
  });

  test('does not add child-process rules to an unbound program', () {
    final installProfile = testInstallProfile();
    final bottle = BottleRecord(
      id: 'test',
      name: 'Test',
      path: '/bottles/test',
      windowsVersion: 'win10',
    );

    final environment = childProcessCompatibilityEnvironmentForProfiledPath(
      installProfileCatalog: InstallProfileCatalog([installProfile]),
      bottle: bottle,
      programPath: installProfile.managedProgramPath,
    );

    expect(environment.toMap(), isEmpty);
  });

  test('reapplying a profile replaces the binding for the same program', () {
    final bottle = BottleRecord(
      id: 'test',
      name: 'Test',
      path: '/bottles/test',
      windowsVersion: 'win10',
    );
    final firstBinding = ProgramProfileRecord(
      profileId: 'first-profile',
      profileVersion: 1,
      managedProgramPath: r'C:\Test App\Test.exe',
      installerResource: testInstallerResource(),
      profileSourceId: 'first-profile.json',
      profileDigest: 'fedcba9876543210' * 4,
      compatibilityProfileId: 'first-profile',
      compatibilityProfileVersion: 1,
    );
    final secondBinding = ProgramProfileRecord(
      profileId: 'second-profile',
      profileVersion: 1,
      managedProgramPath: r'c:/test app/test.exe',
      installerResource: testInstallerResource(),
      profileSourceId: 'second-profile.json',
      profileDigest: 'fedcba9876543210' * 4,
      compatibilityProfileId: 'second-profile',
      compatibilityProfileVersion: 1,
    );

    final updated = bottleWithProgramProfile(
      bottle: bottleWithProgramProfile(bottle: bottle, profile: firstBinding),
      profile: secondBinding,
    );

    expect(updated.programProfiles, [secondBinding]);
  });

  test('only compatibility profiles can set child-process rules', () {
    final bottle = BottleRecord(
      id: 'test',
      name: 'Test',
      path: '/bottles/test',
      windowsVersion: 'win10',
    );
    final planner = ProgramRunPlanner(
      hostPlatform: KonyakHostPlatform.macos,
      environment: HostEnvironment({'HOME': '/Users/test'}),
    );
    final settings = ProgramSettingsRecord(
      environment: ProgramEnvironmentOverrides({
        konyakChildProcessRulesEnvironmentVariable.toLowerCase():
            'unvalidated-rule',
      }),
    );
    final unboundRequest = planner
        .plan(
          bottle: bottle,
          programPath: ProgramPath('/Applications/Test.exe'),
          programSettings: Option.of(settings),
        )
        .getOrElse(() => throw TestFailure('Expected a macOS run request.'));
    final boundRequest = planner
        .plan(
          bottle: bottle,
          programPath: ProgramPath('/Applications/Test.exe'),
          programSettings: Option.of(settings),
          compatibilityEnvironment: ProgramRunEnvironment({
            konyakChildProcessRulesEnvironmentVariable:
                'validated-helper.exe\t--validated',
          }),
        )
        .getOrElse(() => throw TestFailure('Expected a macOS run request.'));

    expect(
      unboundRequest.environment.toMap().keys.where(
        (name) =>
            name.toUpperCase() == konyakChildProcessRulesEnvironmentVariable,
      ),
      isEmpty,
    );
    expect(
      boundRequest.environment.toMap(),
      containsPair(
        konyakChildProcessRulesEnvironmentVariable,
        'validated-helper.exe\t--validated',
      ),
    );
  });

  test('rejects child-process values outside the version 1 protocol', () {
    expect(
      () => ChildProcessCompatibilityRule(
        executableSuffix: 'helper.exe\nother.exe',
        appendArgumentsIfMissing: const ['--valid'],
      ),
      throwsArgumentError,
    );
    expect(
      () => ChildProcessCompatibilityRule(
        executableSuffix: 'h\u00e9lper.exe',
        appendArgumentsIfMissing: const ['--valid'],
      ),
      throwsArgumentError,
    );
    expect(
      () => ChildProcessCompatibilityRule(
        executableSuffix: 'helper.exe\u0000ignored.exe',
        appendArgumentsIfMissing: const ['--valid'],
      ),
      throwsArgumentError,
    );
    expect(
      () => ChildProcessCompatibilityRule(
        executableSuffix: 'helper.exe',
        appendArgumentsIfMissing: const ['--value\u0000ignored'],
      ),
      throwsArgumentError,
    );
    expect(
      () => ChildProcessCompatibilityRule(
        executableSuffix: 'helper.exe',
        appendArgumentsIfMissing: const ['--value with-space'],
      ),
      throwsArgumentError,
    );
    expect(
      () => CompatibilityProfileRecord(
        id: 'too-many',
        profileVersion: 1,
        childProcessRules: [
          ChildProcessCompatibilityRule(
            executableSuffix: 'first.exe',
            appendArgumentsIfMissing: [
              for (var index = 0; index < 33; index++) '--first-$index',
            ],
          ),
          ChildProcessCompatibilityRule(
            executableSuffix: 'second.exe',
            appendArgumentsIfMissing: [
              for (var index = 0; index < 32; index++) '--second-$index',
            ],
          ),
        ],
      ),
      throwsArgumentError,
    );
  });
}
