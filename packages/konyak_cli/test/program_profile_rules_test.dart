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
          compatibilityEnvironment: ProgramRunEnvironment({
            wineWaitChildPipeIgnoreEnvironmentVariable: 'steam.exe',
          }),
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
    expect(
      macosExe.environment[wineWaitChildPipeIgnoreEnvironmentVariable],
      const Option.of('steam.exe'),
    );
    expect(
      linuxExe.environment[wineWaitChildPipeIgnoreEnvironmentVariable],
      const Option<String>.none(),
    );

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
      preInstallActions: [
        PreInstallActionRecord.winetricks(verb: 'vcrun2022'),
        PreInstallActionRecord.winetricks(verb: 'corefonts'),
      ],
    );

    expect(
      profile.preInstallActions.whereType<WinetricksPreInstallAction>().map(
        (action) => action.verb.value,
      ),
      ['vcrun2022', 'corefonts'],
    );
  });

  test('rejects unsafe dependency winetricks verbs in the domain model', () {
    expect(
      () => testInstallProfile(
        preInstallActions: [
          PreInstallActionRecord.winetricks(verb: 'corefonts;rm'),
        ],
      ),
      throwsArgumentError,
    );
  });

  test('rejects duplicate dependency winetricks verbs in the domain model', () {
    expect(
      () => testInstallProfile(
        preInstallActions: [
          PreInstallActionRecord.winetricks(verb: 'corefonts'),
          PreInstallActionRecord.winetricks(verb: 'corefonts'),
        ],
      ),
      throwsArgumentError,
    );
  });

  test('accepts a 128-character native DLL component action identifier', () {
    final componentId = 'a' * 128;
    final action = PreInstallActionRecord.nativeDll(
      componentId: componentId,
      machine: 'x86',
      destination: 'windowsSysWow64',
      targetFileName: 'component.dll',
      resource: NativeDllResourceRecord(
        kind: 'https',
        url: 'https://downloads.example.test/component.dll',
        sha256: 'a' * 64,
        fileName: 'component.dll',
      ),
    );

    expect(preInstallActionId(action).value, componentId);
  });

  test('rejects a 129-character native DLL component action identifier', () {
    expect(
      () => PreInstallActionRecord.nativeDll(
        componentId: 'a' * 129,
        machine: 'x86',
        destination: 'windowsSysWow64',
        targetFileName: 'component.dll',
        resource: NativeDllResourceRecord(
          kind: 'https',
          url: 'https://downloads.example.test/component.dll',
          sha256: 'a' * 64,
          fileName: 'component.dll',
        ),
      ),
      throwsArgumentError,
    );
  });

  test(
    'rejects more than 64 dependency winetricks verbs in the domain model',
    () {
      expect(
        () => testInstallProfile(
          preInstallActions: [
            for (var index = 0; index < 65; index++)
              PreInstallActionRecord.winetricks(verb: 'verb$index'),
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

  test('keeps an applied profile launch policy after catalog deletion', () {
    final installProfile = testInstallProfile(
      executableSuffix: 'snapshot-helper.exe',
      appendArgumentsIfMissing: const ['--snapshot-rule'],
    );
    final bottle = BottleRecord(
      id: 'test',
      name: 'Test',
      path: '/bottles/test',
      windowsVersion: 'win10',
      programProfiles: [
        programProfileFromInstallProfile(
          installProfile: installProfile,
          managedProgramPath: installProfile.managedProgramPath,
        ),
      ],
    );
    final emptyCatalog = InstallProfileCatalog(const <InstallProfileRecord>[]);

    final completionPolicy = programRunCompletionPolicyForProfiledPath(
      installProfileCatalog: emptyCatalog,
      bottle: bottle,
      programPath: installProfile.managedProgramPath,
    );
    final environment = childProcessCompatibilityEnvironmentForProfiledPath(
      installProfileCatalog: emptyCatalog,
      bottle: bottle,
      programPath: installProfile.managedProgramPath,
    );

    expect(completionPolicy, ProgramRunCompletionPolicy.launchOnly);
    expect(environment.toMap(), {
      konyakChildProcessRulesEnvironmentVariable:
          'snapshot-helper.exe\t--snapshot-rule',
    });
  });

  test('builds installer-only environment from an unbound profile', () {
    final installProfile = testInstallProfile(
      installerCompletionChildExecutable: 'steam.exe',
      executableSuffix: 'steamwebhelper.exe',
      appendArgumentsIfMissing: const ['--no-sandbox', '--disable-gpu'],
    );

    final environment = installerCompatibilityEnvironmentForProfile(
      installProfile,
    );

    expect(environment.toMap(), {
      wineWaitChildPipeIgnoreEnvironmentVariable: 'steam.exe',
      konyakChildProcessRulesEnvironmentVariable:
          'steamwebhelper.exe\t--no-sandbox\n'
          'steamwebhelper.exe\t--disable-gpu',
    });
  });

  test('rejects macOS installer completion on a Linux profile', () {
    expect(
      () => testInstallProfile(
        platforms: const <String>['linux'],
        installerCompletionChildExecutable: 'test.exe',
      ),
      throwsArgumentError,
    );
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

  test('only profile contracts can set reserved compatibility values', () {
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
        wineWaitChildPipeIgnoreEnvironmentVariable.toLowerCase():
            'unvalidated.exe',
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
      unboundRequest.environment.toMap().keys.where(
        (name) =>
            name.toUpperCase() == wineWaitChildPipeIgnoreEnvironmentVariable,
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
