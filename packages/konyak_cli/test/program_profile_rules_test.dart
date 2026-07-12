import 'package:fpdart/fpdart.dart';
import 'package:konyak_cli/konyak_cli.dart';
import 'package:test/test.dart';

import 'support/install_profile_fixtures.dart';

void main() {
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
      compatibilityProfileId: 'first-profile',
      compatibilityProfileVersion: 1,
    );
    final secondBinding = ProgramProfileRecord(
      profileId: 'second-profile',
      profileVersion: 1,
      managedProgramPath: r'c:/test app/test.exe',
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
