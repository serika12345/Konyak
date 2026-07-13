import 'package:fpdart/fpdart.dart';
import 'package:konyak_cli/konyak_cli.dart';
import 'package:konyak_cli/src/cli/program_profile_installer.dart';
import 'package:konyak_cli/src/io/program_profile_install_progress_io.dart';
import 'package:konyak_cli/src/repository/memory_bottle_repository.dart';
import 'package:konyak_cli/src/repository/repository_interfaces.dart';
import 'package:test/test.dart';

import 'support/cli_contract_full_helpers.dart'
    show NoopProgramMetadataExtractor, RecordingProgramRunner;
import 'support/install_profile_fixtures.dart';

void main() {
  test('installs in manifest order and persists only after verification', () {
    final profile = testInstallProfile(
      dependencyWinetricksVerbs: const <String>['corefonts', 'vcrun2022'],
    );
    final repository = _repository();
    final fetcher = RecordingProfileInstallerResourceFetcher(
      ProfileInstallerResourceFetched(ProgramPath('/cache/TestSetup.exe')),
    );
    final verifier = RecordingManagedProfileProgramVerifier(
      ManagedProfileProgramVerified(
        ProgramPath('/bottles/test/drive_c/Test App/Test.exe'),
      ),
    );
    final runner = RecordingProgramRunner(
      results: const <ProgramRunResult>[
        ProgramRunCompleted(processExitCode: 0),
        ProgramRunCompleted(processExitCode: 0),
        ProgramRunCompleted(processExitCode: 0),
      ],
    );
    final progressSink = RecordingProgramProfileInstallProgressSink();
    final installer = DefaultProgramProfileInstaller(
      installProfileCatalog: InstallProfileCatalog(<InstallProfileRecord>[
        profile,
      ]),
      runtimeCatalog: StaticRuntimeCatalog(<RuntimeRecord>[_runtime()]),
      bottleRepository: repository,
      winetricksVerbRepository: _verbRepository(const <String>[
        'corefonts',
        'vcrun2022',
      ]),
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
      ),
      programRunner: runner,
      resourceFetcher: fetcher,
      managedProgramVerifier: verifier,
      progressSink: progressSink,
    );

    final result = installer.install(
      ProgramProfileInstallRequest(
        profileId: profile.id,
        bottleId: BottleId('test'),
      ),
    );

    expect(result, isA<ProgramProfileInstalled>());
    expect(fetcher.resources, <InstallerResourceRecord>[
      profile.installerResource,
    ]);
    expect(runner.requests, hasLength(3));
    expect(runner.requests[0].arguments.value, <String>[
      'start',
      '/wait',
      '/unix',
      '/cache/TestSetup.exe',
    ]);
    expect(runner.requests[1].arguments.value, contains('corefonts'));
    expect(runner.requests[2].arguments.value, contains('vcrun2022'));
    expect(verifier.requests, <ProgramPath>[profile.managedProgramPath]);
    final bottle = _expectBottle(repository, BottleId('test'));
    expect(bottle.programProfiles, hasLength(1));
    expect(
      bottle.programProfiles.single.managedProgramPath,
      profile.managedProgramPath,
    );
    expect(
      bottle.programProfiles.single.installerResource,
      profile.installerResource,
    );
    expect(
      progressSink.progress.map(programProfileInstallProgressJson),
      <Map<String, Object?>>[
        _progress('preflight', 'started'),
        _progress('preflight', 'completed'),
        _progress('download', 'started'),
        _progress('download', 'completed'),
        _progress('verification', 'started'),
        _progress('verification', 'completed'),
        _progress('installer', 'started'),
        _progress('installer', 'completed'),
        _progress('resourceCleanup', 'started'),
        _progress('resourceCleanup', 'completed'),
        _progress('dependency', 'started', index: 0, verb: 'corefonts'),
        _progress('dependency', 'completed', index: 0, verb: 'corefonts'),
        _progress('dependency', 'started', index: 1, verb: 'vcrun2022'),
        _progress('dependency', 'completed', index: 1, verb: 'vcrun2022'),
        _progress('managedProgram', 'started'),
        _progress('managedProgram', 'completed'),
        _progress('persistence', 'started'),
        _progress('persistence', 'completed'),
      ],
    );
  });

  test('preflights every dependency verb before resource fetch', () {
    final profile = testInstallProfile(
      dependencyWinetricksVerbs: const <String>['corefonts', 'vcrun2022'],
    );
    final repository = _repository();
    final fetcher = RecordingProfileInstallerResourceFetcher(
      ProfileInstallerResourceFetched(ProgramPath('/cache/TestSetup.exe')),
    );
    final verifier = RecordingManagedProfileProgramVerifier(
      ManagedProfileProgramVerified(
        ProgramPath('/bottles/test/drive_c/Test App/Test.exe'),
      ),
    );
    final runner = RecordingProgramRunner(
      result: const ProgramRunCompleted(processExitCode: 0),
    );
    final progressSink = RecordingProgramProfileInstallProgressSink();
    final installer = DefaultProgramProfileInstaller(
      installProfileCatalog: InstallProfileCatalog(<InstallProfileRecord>[
        profile,
      ]),
      runtimeCatalog: StaticRuntimeCatalog(<RuntimeRecord>[_runtime()]),
      bottleRepository: repository,
      winetricksVerbRepository: _verbRepository(const <String>['corefonts']),
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
      ),
      programRunner: runner,
      resourceFetcher: fetcher,
      managedProgramVerifier: verifier,
      progressSink: progressSink,
    );

    final result = installer.install(
      ProgramProfileInstallRequest(
        profileId: profile.id,
        bottleId: BottleId('test'),
      ),
    );

    expect(result, isA<ProgramProfileInstallFailed>());
    final failure = result as ProgramProfileInstallFailed;
    expect(failure.stage, ProgramProfileInstallStage.preflight);
    expect(failure.code, 'dependencyWinetricksVerbUnavailable');
    expect(failure.dependencyIndex, const Option.of(1));
    expect(failure.dependencyVerb, Option.of(WinetricksVerbId('vcrun2022')));
    expect(fetcher.resources, isEmpty);
    expect(runner.requests, isEmpty);
    expect(verifier.requests, isEmpty);
    expect(
      _expectBottle(repository, BottleId('test')).programProfiles,
      isEmpty,
    );
    expect(
      progressSink.progress.map(programProfileInstallProgressJson),
      <Map<String, Object?>>[
        _progress('preflight', 'started'),
        <String, Object?>{
          ..._progress('preflight', 'failed'),
          'dependencyIndex': 1,
          'dependencyVerb': 'vcrun2022',
          'code': 'dependencyWinetricksVerbUnavailable',
        },
      ],
    );
  });

  test('non-zero dependency exit stops verification and persistence', () {
    final profile = testInstallProfile(
      dependencyWinetricksVerbs: const <String>['corefonts', 'vcrun2022'],
    );
    final repository = _repository();
    final verifier = RecordingManagedProfileProgramVerifier(
      ManagedProfileProgramVerified(
        ProgramPath('/bottles/test/drive_c/Test App/Test.exe'),
      ),
    );
    final runner = RecordingProgramRunner(
      results: const <ProgramRunResult>[
        ProgramRunCompleted(processExitCode: 0),
        ProgramRunCompleted(processExitCode: 37),
      ],
    );
    final installer = DefaultProgramProfileInstaller(
      installProfileCatalog: InstallProfileCatalog(<InstallProfileRecord>[
        profile,
      ]),
      runtimeCatalog: StaticRuntimeCatalog(<RuntimeRecord>[_runtime()]),
      bottleRepository: repository,
      winetricksVerbRepository: _verbRepository(const <String>[
        'corefonts',
        'vcrun2022',
      ]),
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
      ),
      programRunner: runner,
      resourceFetcher: RecordingProfileInstallerResourceFetcher(
        ProfileInstallerResourceFetched(ProgramPath('/cache/TestSetup.exe')),
      ),
      managedProgramVerifier: verifier,
    );

    final result = installer.install(
      ProgramProfileInstallRequest(
        profileId: profile.id,
        bottleId: BottleId('test'),
      ),
    );

    expect(result, isA<ProgramProfileInstallFailed>());
    final failure = result as ProgramProfileInstallFailed;
    expect(failure.stage, ProgramProfileInstallStage.dependency);
    expect(failure.code, 'dependencyInstallerExitNonZero');
    expect(failure.dependencyIndex, const Option.of(0));
    expect(failure.dependencyVerb, Option.of(WinetricksVerbId('corefonts')));
    expect(failure.processExitCode, const Option.of(37));
    expect(runner.requests, hasLength(2));
    expect(verifier.requests, isEmpty);
    expect(
      _expectBottle(repository, BottleId('test')).programProfiles,
      isEmpty,
    );
  });

  test('rejects unsupported platforms and missing runtimes before fetch', () {
    final cases =
        <
          ({
            InstallProfileRecord profile,
            List<RuntimeRecord> runtimes,
            String code,
          })
        >[
          (
            profile: testInstallProfile(platforms: const <String>['linux']),
            runtimes: <RuntimeRecord>[_runtime()],
            code: 'installProfilePlatformUnsupported',
          ),
          (
            profile: testInstallProfile(),
            runtimes: const <RuntimeRecord>[],
            code: 'installedRuntimeUnavailable',
          ),
          (
            profile: testInstallProfile(),
            runtimes: <RuntimeRecord>[_runtimeWithStack(const Option.none())],
            code: 'installedRuntimeUnavailable',
          ),
          (
            profile: testInstallProfile(),
            runtimes: <RuntimeRecord>[_runtime(runnerKind: 'wine')],
            code: 'installedRuntimeUnavailable',
          ),
          (
            profile: testInstallProfile(),
            runtimes: <RuntimeRecord>[_runtime(stack: _incompleteStack())],
            code: 'installedRuntimeUnavailable',
          ),
        ];

    for (final testCase in cases) {
      final fetcher = RecordingProfileInstallerResourceFetcher(
        ProfileInstallerResourceFetched(ProgramPath('/cache/TestSetup.exe')),
      );
      final installer = _preflightInstaller(
        profile: testCase.profile,
        runtimes: testCase.runtimes,
        fetcher: fetcher,
        verbs: const <String>['corefonts'],
      );

      final result = installer.install(
        ProgramProfileInstallRequest(
          profileId: testCase.profile.id,
          bottleId: BottleId('test'),
        ),
      );

      expect((result as ProgramProfileInstallFailed).code, testCase.code);
      expect(fetcher.resources, isEmpty);
    }
  });

  test('preflights dependency plans before resource fetch', () {
    final profile = testInstallProfile(
      dependencyWinetricksVerbs: const <String>['unknown-plan-verb'],
    );
    final fetcher = RecordingProfileInstallerResourceFetcher(
      ProfileInstallerResourceFetched(ProgramPath('/cache/TestSetup.exe')),
    );
    final installer = _preflightInstaller(
      profile: profile,
      runtimes: <RuntimeRecord>[_runtime()],
      fetcher: fetcher,
      verbs: const <String>['unknown-plan-verb'],
      programRunPlanner: _NoDependencyPlanProgramRunPlanner(),
    );

    final result = installer.install(
      ProgramProfileInstallRequest(
        profileId: profile.id,
        bottleId: BottleId('test'),
      ),
    );

    expect(result, isA<ProgramProfileInstallFailed>());
    final failure = result as ProgramProfileInstallFailed;
    expect(failure.stage, ProgramProfileInstallStage.preflight);
    expect(failure.code, 'dependencyInstallerPlanUnavailable');
    expect(failure.dependencyIndex, const Option.of(0));
    expect(fetcher.resources, isEmpty);
  });

  test('rejects a bottle Windows version mismatch before fetch', () {
    final profile = testInstallProfile(windowsVersion: 'win11');
    final fetcher = RecordingProfileInstallerResourceFetcher(
      ProfileInstallerResourceFetched(ProgramPath('/cache/TestSetup.exe')),
    );
    final installer = _preflightInstaller(
      profile: profile,
      runtimes: <RuntimeRecord>[_runtime()],
      fetcher: fetcher,
      verbs: const <String>['corefonts'],
    );

    final result = installer.install(
      ProgramProfileInstallRequest(
        profileId: profile.id,
        bottleId: BottleId('test'),
      ),
    );

    final failure = result as ProgramProfileInstallFailed;
    expect(failure.stage, ProgramProfileInstallStage.preflight);
    expect(failure.code, 'bottleWindowsVersionMismatch');
    expect(fetcher.resources, isEmpty);
  });

  test('treats a non-zero installer completion as a typed failure', () {
    final profile = testInstallProfile(
      dependencyWinetricksVerbs: const <String>[],
    );
    final repository = _repository();
    final verifier = RecordingManagedProfileProgramVerifier(
      ManagedProfileProgramVerified(
        ProgramPath('/bottles/test/drive_c/Test App/Test.exe'),
      ),
    );
    final installer = _preflightInstaller(
      profile: profile,
      runtimes: <RuntimeRecord>[_runtime()],
      fetcher: RecordingProfileInstallerResourceFetcher(
        ProfileInstallerResourceFetched(ProgramPath('/cache/TestSetup.exe')),
      ),
      verbs: const <String>[],
      bottleRepository: repository,
      programRunner: RecordingProgramRunner(
        result: const ProgramRunCompleted(processExitCode: 19),
      ),
      managedProgramVerifier: verifier,
    );

    final result = installer.install(
      ProgramProfileInstallRequest(
        profileId: profile.id,
        bottleId: BottleId('test'),
      ),
    );

    final failure = result as ProgramProfileInstallFailed;
    expect(failure.stage, ProgramProfileInstallStage.installer);
    expect(failure.code, 'installerExitNonZero');
    expect(failure.processExitCode, const Option.of(19));
    expect(verifier.requests, isEmpty);
    expect(
      _expectBottle(repository, BottleId('test')).programProfiles,
      isEmpty,
    );
  });

  test('does not persist when the managed executable verification fails', () {
    final profile = testInstallProfile(
      dependencyWinetricksVerbs: const <String>[],
    );
    final repository = _repository();
    final installer = _preflightInstaller(
      profile: profile,
      runtimes: <RuntimeRecord>[_runtime()],
      fetcher: RecordingProfileInstallerResourceFetcher(
        ProfileInstallerResourceFetched(ProgramPath('/cache/TestSetup.exe')),
      ),
      verbs: const <String>[],
      bottleRepository: repository,
      managedProgramVerifier: RecordingManagedProfileProgramVerifier(
        const ManagedProfileProgramVerificationFailed(
          code: 'managedProgramMissing',
          message: 'Managed program executable does not exist.',
        ),
      ),
    );

    final result = installer.install(
      ProgramProfileInstallRequest(
        profileId: profile.id,
        bottleId: BottleId('test'),
      ),
    );

    final failure = result as ProgramProfileInstallFailed;
    expect(failure.stage, ProgramProfileInstallStage.managedProgram);
    expect(failure.code, 'managedProgramMissing');
    expect(
      _expectBottle(repository, BottleId('test')).programProfiles,
      isEmpty,
    );
  });
}

DefaultProgramProfileInstaller _preflightInstaller({
  required InstallProfileRecord profile,
  required List<RuntimeRecord> runtimes,
  required RecordingProfileInstallerResourceFetcher fetcher,
  required List<String> verbs,
  ProgramRunPlanner? programRunPlanner,
  BottleRepository? bottleRepository,
  ProgramRunner? programRunner,
  ManagedProfileProgramVerifier? managedProgramVerifier,
}) {
  return DefaultProgramProfileInstaller(
    installProfileCatalog: InstallProfileCatalog(<InstallProfileRecord>[
      profile,
    ]),
    runtimeCatalog: StaticRuntimeCatalog(runtimes),
    bottleRepository: bottleRepository ?? _repository(),
    winetricksVerbRepository: _verbRepository(verbs),
    programRunPlanner:
        programRunPlanner ??
        ProgramRunPlanner(hostPlatform: KonyakHostPlatform.macos),
    programRunner:
        programRunner ??
        RecordingProgramRunner(
          result: const ProgramRunCompleted(processExitCode: 0),
        ),
    resourceFetcher: fetcher,
    managedProgramVerifier:
        managedProgramVerifier ??
        RecordingManagedProfileProgramVerifier(
          ManagedProfileProgramVerified(
            ProgramPath('/bottles/test/drive_c/Test App/Test.exe'),
          ),
        ),
  );
}

final class _NoDependencyPlanProgramRunPlanner extends ProgramRunPlanner {
  _NoDependencyPlanProgramRunPlanner()
    : super(hostPlatform: KonyakHostPlatform.macos);

  @override
  Option<ProgramRunRequest> planWinetricksVerb({
    required BottleRecord bottle,
    required WinetricksVerbId verb,
  }) {
    return const Option.none();
  }
}

Map<String, Object?> _progress(
  String stage,
  String state, {
  int? index,
  String? verb,
}) {
  return <String, Object?>{
    'stage': stage,
    'state': state,
    ...switch (index) {
      final int value => <String, Object?>{'dependencyIndex': value},
      _ => const <String, Object?>{},
    },
    ...switch (verb) {
      final String value => <String, Object?>{'dependencyVerb': value},
      _ => const <String, Object?>{},
    },
  };
}

MemoryBottleRepository _repository() {
  return MemoryBottleRepository(
    programMetadataExtractor: const NoopProgramMetadataExtractor(),
    dataHome: '/data',
    bottles: <BottleRecord>[
      BottleRecord(
        id: 'test',
        name: 'Test',
        path: '/bottles/test',
        windowsVersion: 'win10',
      ),
    ],
  );
}

BottleRecord _expectBottle(BottleRepository repository, BottleId id) {
  return repository
      .findBottle(id)
      .fold(
        (message) => throw TestFailure(message),
        (bottle) => bottle.getOrElse(
          () => throw TestFailure('Expected bottle ${id.value}.'),
        ),
      );
}

RuntimeRecord _runtime({
  Option<RuntimeStack>? stack,
  String runnerKind = 'macosWine',
}) {
  return RuntimeRecord(
    id: RuntimeId('macos-wine'),
    name: RuntimeName('macOS Wine'),
    platform: RuntimePlatformName('macos'),
    architecture: RuntimeArchitecture('arm64'),
    runnerKind: RunnerKind(runnerKind),
    isBundled: true,
    isUpdateable: true,
    isInstalled: const Option.of(true),
    libraryPath: Option.of(RuntimeComponentPath('/runtime')),
    executablePath: Option.of(RuntimeComponentPath('/runtime/bin/wine')),
    stack: stack ?? _completeStack(),
  );
}

RuntimeRecord _runtimeWithStack(Option<RuntimeStack> stack) {
  return _runtime(stack: stack);
}

Option<RuntimeStack> _completeStack() {
  return Option.of(
    RuntimeStack(
      id: RuntimeStackId('macos-runtime-stack'),
      name: RuntimeStackName('macOS Runtime Stack'),
      compatibilityTarget: RuntimeCompatibilityTarget('macos-runtime-stack'),
      components: <RuntimeStackComponent>[
        RuntimeStackComponent(
          id: RuntimeComponentId('wine'),
          name: RuntimeName('Wine'),
          role: RuntimeRole('windows-runner'),
          isRequired: true,
          paths: <RuntimeComponentPath>[
            RuntimeComponentPath('/runtime/bin/wine'),
          ],
          missingPaths: const <RuntimeMissingPath>[],
        ),
      ],
    ),
  );
}

Option<RuntimeStack> _incompleteStack() {
  return Option.of(
    RuntimeStack(
      id: RuntimeStackId('macos-runtime-stack'),
      name: RuntimeStackName('macOS Runtime Stack'),
      compatibilityTarget: RuntimeCompatibilityTarget('macos-runtime-stack'),
      components: <RuntimeStackComponent>[
        RuntimeStackComponent(
          id: RuntimeComponentId('wine'),
          name: RuntimeName('Wine'),
          role: RuntimeRole('windows-runner'),
          isRequired: true,
          paths: <RuntimeComponentPath>[
            RuntimeComponentPath('/runtime/bin/wine'),
          ],
          missingPaths: <RuntimeMissingPath>[
            RuntimeMissingPath('/runtime/bin/wine'),
          ],
        ),
      ],
    ),
  );
}

WinetricksVerbRepository _verbRepository(List<String> verbs) {
  return FixedWinetricksVerbRepository(
    WinetricksVerbListResult.completed(
      categories: <WinetricksCategoryRecord>[
        WinetricksCategoryRecord(
          id: WinetricksCategoryId('dlls'),
          name: WinetricksCategoryName('DLLs'),
          verbs: verbs
              .map(
                (verb) => WinetricksVerbRecord(
                  id: WinetricksVerbId(verb),
                  name: WinetricksVerbName(verb),
                  description: WinetricksVerbDescription('$verb dependency'),
                ),
              )
              .toList(growable: false),
        ),
      ],
    ),
  );
}

final class FixedWinetricksVerbRepository implements WinetricksVerbRepository {
  const FixedWinetricksVerbRepository(this.result);

  final WinetricksVerbListResult result;

  @override
  WinetricksVerbListResult listVerbs() => result;
}

final class RecordingProfileInstallerResourceFetcher
    implements ProfileInstallerResourceFetcher {
  RecordingProfileInstallerResourceFetcher(
    this.result, {
    this.releaseResult = const ProfileInstallerResourceReleased(),
  });

  final ProfileInstallerResourceFetchResult result;
  final ProfileInstallerResourceReleaseResult releaseResult;
  final List<InstallerResourceRecord> resources = <InstallerResourceRecord>[];
  final List<ProfileInstallerResourceFetched> releasedResources =
      <ProfileInstallerResourceFetched>[];

  @override
  ProfileInstallerResourceFetchResult fetch(InstallerResourceRecord resource) {
    resources.add(resource);
    return result;
  }

  @override
  ProfileInstallerResourceReleaseResult release(
    ProfileInstallerResourceFetched resource,
  ) {
    releasedResources.add(resource);
    return releaseResult;
  }
}

final class RecordingManagedProfileProgramVerifier
    implements ManagedProfileProgramVerifier {
  RecordingManagedProfileProgramVerifier(this.result);

  final ManagedProfileProgramVerificationResult result;
  final List<ProgramPath> requests = <ProgramPath>[];

  @override
  ManagedProfileProgramVerificationResult verify({
    required BottleRecord bottle,
    required ProgramPath managedProgramPath,
  }) {
    requests.add(managedProgramPath);
    return result;
  }
}

final class RecordingProgramProfileInstallProgressSink
    implements ProgramProfileInstallProgressSink {
  final List<ProgramProfileInstallProgress> progress =
      <ProgramProfileInstallProgress>[];

  @override
  void report(ProgramProfileInstallProgress progress) {
    this.progress.add(progress);
  }
}
