import 'package:konyak_cli/src/cli/program_profile_installer.dart';

import 'support/cli_contract_full_helpers.dart';

void main() {
  test('install-program-profile returns versioned success JSON', () {
    final profile = testInstallProfile();
    final binding = programProfileFromInstallProfile(
      installProfile: profile,
      managedProgramPath: profile.managedProgramPath,
    );
    final installer = RecordingProgramProfileInstaller(
      ProgramProfileInstalled(bottleId: BottleId('test'), profile: binding),
    );

    final result = runCli(const <String>[
      'install-program-profile',
      'test-profile',
      '--bottle',
      'test',
      '--json',
    ], programProfileInstaller: installer);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(jsonDecode(result.stdout), <String, Object?>{
      'schemaVersion': 1,
      'programProfileInstall': <String, Object?>{
        'stage': 'persistence',
        'programProfile': programProfileJson(
          bottleId: 'test',
          profile: binding,
        ),
      },
    });
    expect(installer.requests, hasLength(1));
    expect(installer.requests.single.profileId, ProfileId('test-profile'));
    expect(installer.requests.single.bottleId, BottleId('test'));
  });

  test('install-program-profile failure includes typed dependency details', () {
    final installer = RecordingProgramProfileInstaller(
      ProgramProfileInstallFailed(
        stage: ProgramProfileInstallStage.dependency,
        code: 'dependencyInstallerExitNonZero',
        message: 'Dependency failed.',
        dependencyIndex: const Option.of(1),
        dependencyVerb: Option.of(WinetricksVerbId('vcrun2022')),
        processExitCode: const Option.of(37),
      ),
    );

    final result = runCli(const <String>[
      'install-program-profile',
      'test-profile',
      '--bottle',
      'test',
      '--json',
    ], programProfileInstaller: installer);

    expect(result.exitCode, 70);
    expect(result.stderr, isEmpty);
    expect(jsonDecode(result.stdout), <String, Object?>{
      'schemaVersion': 1,
      'error': <String, Object?>{
        'code': 'dependencyInstallerExitNonZero',
        'message': 'Dependency failed.',
        'programProfileInstall': <String, Object?>{
          'profileId': 'test-profile',
          'bottleId': 'test',
          'stage': 'dependency',
          'dependencyIndex': 1,
          'dependencyVerb': 'vcrun2022',
          'processExitCode': 37,
        },
      },
    });
  });

  test('apply-program-profile does not invoke installer orchestration', () {
    final profile = testInstallProfile();
    final repository = MemoryBottleRepository(
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
    final installer = RecordingProgramProfileInstaller(
      const ProgramProfileInstallFailed(
        stage: ProgramProfileInstallStage.preflight,
        code: 'mustNotRun',
        message: 'Must not run.',
      ),
    );

    final result = runCli(
      const <String>[
        'apply-program-profile',
        'test-profile',
        '--bottle',
        'test',
        '--program',
        r'C:\Test App\Test.exe',
        '--json',
      ],
      bottleRepository: repository,
      installProfileCatalog: InstallProfileCatalog(<InstallProfileRecord>[
        profile,
      ]),
      programProfileInstaller: installer,
    );

    expect(result.exitCode, 0);
    expect(installer.requests, isEmpty);
  });

  test('repair-profile does not invoke installer orchestration', () {
    final profile = testInstallProfile();
    final binding = programProfileFromInstallProfile(
      installProfile: profile,
      managedProgramPath: profile.managedProgramPath,
    );
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: '/data',
      bottles: <BottleRecord>[
        BottleRecord(
          id: 'test',
          name: 'Test',
          path: '/bottles/test',
          windowsVersion: 'win10',
          programProfiles: <ProgramProfileRecord>[binding],
        ),
      ],
    );
    final installer = RecordingProgramProfileInstaller(
      const ProgramProfileInstallFailed(
        stage: ProgramProfileInstallStage.preflight,
        code: 'mustNotRun',
        message: 'Must not run.',
      ),
    );

    final result = runCli(
      const <String>[
        'repair-profile',
        'test-profile',
        '--bottle',
        'test',
        '--json',
      ],
      bottleRepository: repository,
      installProfileCatalog: InstallProfileCatalog(<InstallProfileRecord>[
        profile,
      ]),
      programProfileInstaller: installer,
    );

    expect(result.exitCode, 0);
    expect(installer.requests, isEmpty);
  });

  test('public install command exposes the typed failure matrix', () {
    for (final kind in _InstallFailureKind.values) {
      final fixture = _installFailureFixture(kind);
      final progressOutput = StringBuffer();

      final result = runCli(
        const <String>[
          'install-program-profile',
          'test-profile',
          '--bottle',
          'test',
          '--progress-json',
          '--json',
        ],
        programProfileInstaller: fixture.installer,
        programProfileInstallProgressSink:
            JsonProgramProfileInstallProgressSink(progressOutput),
      );

      expect(result.exitCode, 70, reason: kind.name);
      expect(result.stderr, isEmpty, reason: kind.name);
      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      final error = payload['error']! as Map<String, Object?>;
      final install = error['programProfileInstall']! as Map<String, Object?>;
      expect(error['code'], kind.code, reason: kind.name);
      expect(install['stage'], kind.stage.value, reason: kind.name);
      kind.processExitCode.match(
        () => expect(
          install.containsKey('processExitCode'),
          isFalse,
          reason: kind.name,
        ),
        (exitCode) =>
            expect(install['processExitCode'], exitCode, reason: kind.name),
      );
      kind.dependencyIndex.match(
        () => expect(
          install.containsKey('dependencyIndex'),
          isFalse,
          reason: kind.name,
        ),
        (index) {
          expect(install['dependencyIndex'], index, reason: kind.name);
          expect(install['dependencyVerb'], 'corefonts', reason: kind.name);
        },
      );

      final progress = progressOutput
          .toString()
          .trim()
          .split('\n')
          .where((line) => line.isNotEmpty)
          .map(
            (line) =>
                (jsonDecode(line)
                        as Map<
                          String,
                          Object?
                        >)['programProfileInstallProgress']!
                    as Map<String, Object?>,
          )
          .toList(growable: false);
      final failedProgress = progress
          .where((event) => event['state'] == 'failed')
          .toList(growable: false);
      expect(failedProgress, hasLength(1), reason: kind.name);
      expect(progress.last, failedProgress.single, reason: kind.name);
      expect(progress.last['stage'], kind.stage.value, reason: kind.name);
      expect(progress.last['code'], kind.code, reason: kind.name);
      kind.dependencyIndex.match(
        () => expect(
          progress.last.containsKey('dependencyIndex'),
          isFalse,
          reason: kind.name,
        ),
        (index) {
          expect(progress.last['dependencyIndex'], index, reason: kind.name);
          expect(
            progress.last['dependencyVerb'],
            'corefonts',
            reason: kind.name,
          );
        },
      );

      expect(fixture.fetcher.resources, hasLength(1), reason: kind.name);
      expect(
        fixture.fetcher.releasedResources,
        hasLength(kind.expectedReleaseCalls),
        reason: kind.name,
      );
      expect(
        fixture.runner.requests,
        hasLength(kind.expectedRunnerCalls),
        reason: kind.name,
      );
      expect(
        fixture.verifier.requests,
        hasLength(kind.expectedVerifierCalls),
        reason: kind.name,
      );
      expect(
        fixture.repository.applyCalls,
        kind.expectedPersistenceCalls,
        reason: kind.name,
      );
      final bottle = fixture.repository
          .findBottle(BottleId('test'))
          .getOrElse((message) => throw TestFailure(message))
          .getOrElse(() => throw TestFailure('Expected test bottle.'));
      expect(bottle.programProfiles, isEmpty, reason: kind.name);
    }
  });

  test(
    'runCliStreaming emits versioned profile progress JSONL before final JSON',
    () async {
      final installer = RecordingProgramProfileInstaller(
        const ProgramProfileInstallFailed(
          stage: ProgramProfileInstallStage.persistence,
          code: 'programProfilePersistenceFailed',
          message: 'Persistence failed.',
        ),
        progress: const <ProgramProfileInstallProgress>[
          ProgramProfileInstallStageStarted(
            stage: ProgramProfileInstallStage.preflight,
          ),
          ProgramProfileInstallStageCompleted(
            stage: ProgramProfileInstallStage.preflight,
          ),
          ProgramProfileInstallStageStarted(
            stage: ProgramProfileInstallStage.persistence,
          ),
          ProgramProfileInstallStageFailed(
            stage: ProgramProfileInstallStage.persistence,
            code: 'programProfilePersistenceFailed',
          ),
        ],
      );
      final progressOutput = StringBuffer();

      final result = await runCliStreaming(
        const <String>[
          'install-program-profile',
          'test-profile',
          '--bottle',
          'test',
          '--progress-json',
          '--json',
        ],
        programProfileInstaller: installer,
        programProfileInstallProgressSink:
            JsonProgramProfileInstallProgressSink(progressOutput),
      );

      final jsonLines = <String>[
        ...progressOutput
            .toString()
            .trim()
            .split('\n')
            .where((line) => line.isNotEmpty),
        result.stdout,
      ].map((line) => jsonDecode(line) as Map<String, Object?>).toList();
      expect(
        jsonLines.map(
          (payload) => switch (payload['programProfileInstallProgress']) {
            final Map<String, Object?> progress =>
              '${progress['stage']}:${progress['state']}',
            _ => 'final',
          },
        ),
        <String>[
          'preflight:started',
          'preflight:completed',
          'persistence:started',
          'persistence:failed',
          'final',
        ],
      );
      expect(
        jsonLines.every((payload) => payload['schemaVersion'] == 1),
        isTrue,
      );
      expect(
        jsonLines.last['error'],
        containsPair('code', 'programProfilePersistenceFailed'),
      );
    },
  );
}

final class RecordingProgramProfileInstaller
    implements ProgramProfileInstaller {
  RecordingProgramProfileInstaller(
    this.result, {
    this.progress = const <ProgramProfileInstallProgress>[],
  });

  final ProgramProfileInstallResult result;
  final List<ProgramProfileInstallProgress> progress;
  final List<ProgramProfileInstallRequest> requests =
      <ProgramProfileInstallRequest>[];
  ProgramProfileInstallProgressSink _progressSink =
      const NoopProgramProfileInstallProgressSink();

  @override
  ProgramProfileInstallResult install(ProgramProfileInstallRequest request) {
    requests.add(request);
    progress.forEach(_progressSink.report);
    return result;
  }

  @override
  ProgramProfileInstaller withProgressSink(
    ProgramProfileInstallProgressSink progressSink,
  ) {
    _progressSink = progressSink;
    return this;
  }
}

enum _InstallFailureKind {
  download,
  digest,
  installerStartup,
  installerNonzero,
  resourceCleanup,
  dependencyStartup,
  dependencyNonzero,
  managedProgram,
  persistence;

  ProgramProfileInstallStage get stage => switch (this) {
    _InstallFailureKind.download => ProgramProfileInstallStage.download,
    _InstallFailureKind.digest => ProgramProfileInstallStage.verification,
    _InstallFailureKind.installerStartup ||
    _InstallFailureKind.installerNonzero =>
      ProgramProfileInstallStage.installer,
    _InstallFailureKind.resourceCleanup =>
      ProgramProfileInstallStage.resourceCleanup,
    _InstallFailureKind.dependencyStartup ||
    _InstallFailureKind.dependencyNonzero =>
      ProgramProfileInstallStage.dependency,
    _InstallFailureKind.managedProgram =>
      ProgramProfileInstallStage.managedProgram,
    _InstallFailureKind.persistence => ProgramProfileInstallStage.persistence,
  };

  String get code => switch (this) {
    _InstallFailureKind.download => 'installerResourceDownloadFailed',
    _InstallFailureKind.digest => 'installerResourceDigestMismatch',
    _InstallFailureKind.installerStartup => 'installerRunFailed',
    _InstallFailureKind.installerNonzero => 'installerExitNonZero',
    _InstallFailureKind.resourceCleanup => 'installerResourceReleaseFailed',
    _InstallFailureKind.dependencyStartup => 'dependencyInstallerRunFailed',
    _InstallFailureKind.dependencyNonzero => 'dependencyInstallerExitNonZero',
    _InstallFailureKind.managedProgram => 'managedProgramMissing',
    _InstallFailureKind.persistence => 'programProfilePersistenceFailed',
  };

  Option<int> get processExitCode => switch (this) {
    _InstallFailureKind.installerNonzero => const Option.of(19),
    _InstallFailureKind.dependencyNonzero => const Option.of(37),
    _ => const Option.none(),
  };

  Option<int> get dependencyIndex => switch (this) {
    _InstallFailureKind.dependencyStartup ||
    _InstallFailureKind.dependencyNonzero => const Option.of(0),
    _ => const Option.none(),
  };

  int get expectedReleaseCalls => switch (this) {
    _InstallFailureKind.download || _InstallFailureKind.digest => 0,
    _ => 1,
  };

  int get expectedRunnerCalls => switch (this) {
    _InstallFailureKind.download || _InstallFailureKind.digest => 0,
    _InstallFailureKind.dependencyStartup ||
    _InstallFailureKind.dependencyNonzero => 2,
    _ => 1,
  };

  int get expectedVerifierCalls => switch (this) {
    _InstallFailureKind.managedProgram || _InstallFailureKind.persistence => 1,
    _ => 0,
  };

  int get expectedPersistenceCalls => switch (this) {
    _InstallFailureKind.persistence => 1,
    _ => 0,
  };
}

final class _InstallFailureFixture {
  const _InstallFailureFixture({
    required this.installer,
    required this.repository,
    required this.fetcher,
    required this.runner,
    required this.verifier,
  });

  final DefaultProgramProfileInstaller installer;
  final _RecordingProfileBottleRepository repository;
  final _MatrixProfileInstallerResourceFetcher fetcher;
  final RecordingProgramRunner runner;
  final _MatrixManagedProgramVerifier verifier;
}

_InstallFailureFixture _installFailureFixture(_InstallFailureKind kind) {
  final hasDependency =
      kind == _InstallFailureKind.dependencyStartup ||
      kind == _InstallFailureKind.dependencyNonzero;
  final profile = testInstallProfile(
    dependencyWinetricksVerbs: hasDependency
        ? const <String>['corefonts']
        : const <String>[],
  );
  final repository = _RecordingProfileBottleRepository(
    failPersistence: kind == _InstallFailureKind.persistence,
  );
  final fetcher = _MatrixProfileInstallerResourceFetcher(
    fetchResult: switch (kind) {
      _InstallFailureKind.download =>
        const ProfileInstallerResourceDownloadFailed('Download failed.'),
      _InstallFailureKind.digest => ProfileInstallerResourceDigestMismatch(
        expected: profile.installerResource.sha256,
        actual: '0' * 64,
      ),
      _ => ProfileInstallerResourceFetched(ProgramPath('/cache/TestSetup.exe')),
    },
    releaseResult: kind == _InstallFailureKind.resourceCleanup
        ? const ProfileInstallerResourceReleaseFailed(
            code: 'installerResourceReleaseFailed',
            message: 'Resource cleanup failed.',
          )
        : const ProfileInstallerResourceReleased(),
  );
  final runner = RecordingProgramRunner(
    results: switch (kind) {
      _InstallFailureKind.installerStartup => const <ProgramRunResult>[
        ProgramRunFailed(message: 'Installer startup failed.'),
      ],
      _InstallFailureKind.installerNonzero => const <ProgramRunResult>[
        ProgramRunCompleted(processExitCode: 19),
      ],
      _InstallFailureKind.dependencyStartup => const <ProgramRunResult>[
        ProgramRunCompleted(processExitCode: 0),
        ProgramRunFailed(message: 'Dependency startup failed.'),
      ],
      _InstallFailureKind.dependencyNonzero => const <ProgramRunResult>[
        ProgramRunCompleted(processExitCode: 0),
        ProgramRunCompleted(processExitCode: 37),
      ],
      _ => const <ProgramRunResult>[ProgramRunCompleted(processExitCode: 0)],
    },
  );
  final verifier = _MatrixManagedProgramVerifier(
    result: kind == _InstallFailureKind.managedProgram
        ? const ManagedProfileProgramVerificationFailed(
            code: 'managedProgramMissing',
            message: 'Managed program is missing.',
          )
        : ManagedProfileProgramVerified(profile.managedProgramPath),
  );
  final installer = DefaultProgramProfileInstaller(
    installProfileCatalog: InstallProfileCatalog(<InstallProfileRecord>[
      profile,
    ]),
    runtimeCatalog: StaticRuntimeCatalog(<RuntimeRecord>[
      runtimeRecordFixture(
        id: 'macos-wine',
        name: 'macOS Wine',
        platform: 'macos',
        architecture: 'arm64',
        runnerKind: 'macosWine',
        isBundled: true,
        isUpdateable: true,
        isInstalled: const Option.of(true),
        libraryPath: const Option.of('/runtime'),
        executablePath: const Option.of('/runtime/bin/wine'),
        stack: Option.of(
          runtimeStackFixture(
            id: 'macos-runtime-stack',
            name: 'macOS Runtime Stack',
            compatibilityTarget: 'macos-runtime-stack',
            components: <RuntimeStackComponent>[
              runtimeStackComponentFixture(
                id: 'wine',
                name: 'Wine',
                role: 'windows-runner',
                isRequired: true,
                paths: const <String>['/runtime/bin/wine'],
                missingPaths: const <String>[],
              ),
            ],
          ),
        ),
      ),
    ]),
    bottleRepository: repository,
    winetricksVerbRepository: const _MatrixWinetricksVerbRepository(),
    programRunPlanner: ProgramRunPlanner(
      hostPlatform: KonyakHostPlatform.macos,
    ),
    programRunner: runner,
    resourceFetcher: fetcher,
    managedProgramVerifier: verifier,
  );
  return _InstallFailureFixture(
    installer: installer,
    repository: repository,
    fetcher: fetcher,
    runner: runner,
    verifier: verifier,
  );
}

final class _RecordingProfileBottleRepository extends MemoryBottleRepository {
  _RecordingProfileBottleRepository({required this.failPersistence})
    : super(
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

  final bool failPersistence;
  int applyCalls = 0;

  @override
  ProgramProfileUpdateResult applyProgramProfile(
    ProgramProfileApplyRequest request,
  ) {
    applyCalls += 1;
    return failPersistence
        ? const ProgramProfileUpdateResult.failed('Persistence failed.')
        : super.applyProgramProfile(request);
  }
}

final class _MatrixProfileInstallerResourceFetcher
    implements ProfileInstallerResourceFetcher {
  _MatrixProfileInstallerResourceFetcher({
    required this.fetchResult,
    required this.releaseResult,
  });

  final ProfileInstallerResourceFetchResult fetchResult;
  final ProfileInstallerResourceReleaseResult releaseResult;
  final List<InstallerResourceRecord> resources = <InstallerResourceRecord>[];
  final List<ProfileInstallerResourceFetched> releasedResources =
      <ProfileInstallerResourceFetched>[];

  @override
  ProfileInstallerResourceFetchResult fetch(InstallerResourceRecord resource) {
    resources.add(resource);
    return fetchResult;
  }

  @override
  ProfileInstallerResourceReleaseResult release(
    ProfileInstallerResourceFetched resource,
  ) {
    releasedResources.add(resource);
    return releaseResult;
  }
}

final class _MatrixManagedProgramVerifier
    implements ManagedProfileProgramVerifier {
  _MatrixManagedProgramVerifier({required this.result});

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

final class _MatrixWinetricksVerbRepository
    implements WinetricksVerbRepository {
  const _MatrixWinetricksVerbRepository();

  @override
  WinetricksVerbListResult listVerbs() {
    return WinetricksVerbListResult.completed(
      categories: <WinetricksCategoryRecord>[
        WinetricksCategoryRecord(
          id: WinetricksCategoryId('dlls'),
          name: WinetricksCategoryName('DLLs'),
          verbs: <WinetricksVerbRecord>[
            WinetricksVerbRecord(
              id: WinetricksVerbId('corefonts'),
              name: WinetricksVerbName('corefonts'),
              description: WinetricksVerbDescription('Core fonts'),
            ),
          ],
        ),
      ],
    );
  }
}
