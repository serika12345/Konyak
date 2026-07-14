import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:konyak_cli/konyak_cli.dart';
import 'package:konyak_cli/src/cli/program_profile_installer.dart';
import 'package:konyak_cli/src/io/program_profile_install_progress_io.dart';
import 'package:konyak_cli/src/repository/memory_bottle_repository.dart';
import 'package:konyak_cli/src/repository/repository_interfaces.dart';
import 'package:test/test.dart';

import 'support/cli_contract_full_helpers.dart'
    show
        ImmediateAsyncProgramRunner,
        NoopProgramMetadataExtractor,
        RecordingProgramRunner;
import 'support/install_profile_fixtures.dart';

void main() {
  test(
    'fetches every resource before ordered mixed pre-install actions',
    () async {
      final actions = _mixedPreInstallActions();
      final profile = testInstallProfile(preInstallActions: actions);
      final events = <String>[];
      final fetcher = _SequencedResourceFetcher(
        events: events,
        results: <ProfileInstallerResourceFetchResult>[
          ProfileInstallerResourceFetched(ProgramPath('/cache/TestSetup.exe')),
          ProfileInstallerResourceFetched(ProgramPath('/cache/d3d-x86.dll')),
          ProfileInstallerResourceFetched(ProgramPath('/cache/d3d-x64.dll')),
        ],
      );
      final runner = _EventProgramRunner(events);
      final nativeInstaller = _EventNativeDllInstaller(events);
      final installer = DefaultProgramProfileInstaller(
        installProfileCatalog: InstallProfileCatalog([profile]),
        runtimeCatalog: StaticRuntimeCatalog([_runtime()]),
        bottleRepository: _repository(),
        winetricksVerbRepository: _verbRepository([
          'corefonts',
          'vcrun2022',
          'fakejapanese',
        ]),
        programRunPlanner: ProgramRunPlanner(
          hostPlatform: KonyakHostPlatform.macos,
        ),
        programRunner: runner,
        installerProgramRunner: ImmediateAsyncProgramRunner(runner),
        resourceFetcher: fetcher,
        nativeDllInstaller: nativeInstaller,
        managedProgramVerifier: RecordingManagedProfileProgramVerifier(
          ManagedProfileProgramVerified(ProgramPath('/bottles/test/Test.exe')),
        ),
      );

      expect(
        await installer.install(
          ProgramProfileInstallRequest(
            profileId: profile.id,
            bottleId: BottleId('test'),
          ),
        ),
        isA<ProgramProfileInstalled>(),
      );
      expect(events.take(3), [
        'fetch:TestSetup.exe',
        'fetch:d3d-x86.dll',
        'fetch:d3d-x64.dll',
      ]);
      expect(events.skip(3).take(6), [
        'run:corefonts',
        'run:vcrun2022',
        'native:d3dcompiler_47-x86',
        'native:d3dcompiler_47-x64',
        'run:fakejapanese',
        'run:installer',
      ]);
    },
  );

  test(
    'each native DLL action failure stops later actions and releases resources',
    () async {
      for (final failureCase in const <(int, int, String)>[
        (1, 2, 'd3dcompiler_47-x86'),
        (2, 3, 'd3dcompiler_47-x64'),
      ]) {
        final (failAtCall, expectedIndex, expectedId) = failureCase;
        final profile = testInstallProfile(
          preInstallActions: _mixedPreInstallActions(),
        );
        final events = <String>[];
        final fetcher = _SequencedResourceFetcher(
          events: events,
          results: <ProfileInstallerResourceFetchResult>[
            ProfileInstallerResourceFetched(
              ProgramPath('/cache/TestSetup.exe'),
            ),
            ProfileInstallerResourceFetched(ProgramPath('/cache/d3d-x86.dll')),
            ProfileInstallerResourceFetched(ProgramPath('/cache/d3d-x64.dll')),
          ],
        );
        final runner = _EventProgramRunner(events);
        final repository = _repository();
        final installer = DefaultProgramProfileInstaller(
          installProfileCatalog: InstallProfileCatalog([profile]),
          runtimeCatalog: StaticRuntimeCatalog([_runtime()]),
          bottleRepository: repository,
          winetricksVerbRepository: _verbRepository([
            'corefonts',
            'vcrun2022',
            'fakejapanese',
          ]),
          programRunPlanner: ProgramRunPlanner(
            hostPlatform: KonyakHostPlatform.macos,
          ),
          programRunner: runner,
          installerProgramRunner: ImmediateAsyncProgramRunner(runner),
          resourceFetcher: fetcher,
          nativeDllInstaller: _EventNativeDllInstaller(
            events,
            failAtCall: failAtCall,
          ),
          managedProgramVerifier: RecordingManagedProfileProgramVerifier(
            ManagedProfileProgramVerified(
              ProgramPath('/bottles/test/Test.exe'),
            ),
          ),
        );

        final result = await installer.install(
          ProgramProfileInstallRequest(
            profileId: profile.id,
            bottleId: BottleId('test'),
          ),
        );
        expect(result, isA<ProgramProfileInstallFailed>());
        final failure = result as ProgramProfileInstallFailed;
        expect(failure.actionIndex, Option.of(expectedIndex));
        expect(failure.actionId, Option.of(PreInstallActionId(expectedId)));
        expect(
          failure.actionKind,
          const Option.of(PreInstallActionKind.nativeDll),
        );
        expect(fetcher.released, hasLength(3));
        expect(events, isNot(contains('run:fakejapanese')));
        expect(events, isNot(contains('run:installer')));
        expect(
          _expectBottle(repository, BottleId('test')).programProfiles,
          isEmpty,
        );
      }
    },
  );

  test(
    'a maximum-length native action failure is typed and releases resources',
    () async {
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
      final profile = testInstallProfile(preInstallActions: [action]);
      final events = <String>[];
      final fetcher = _SequencedResourceFetcher(
        events: events,
        results: <ProfileInstallerResourceFetchResult>[
          ProfileInstallerResourceFetched(ProgramPath('/cache/TestSetup.exe')),
          ProfileInstallerResourceFetched(ProgramPath('/cache/component.dll')),
        ],
      );
      final repository = _repository();
      final runner = _EventProgramRunner(events);
      final installer = DefaultProgramProfileInstaller(
        installProfileCatalog: InstallProfileCatalog([profile]),
        runtimeCatalog: StaticRuntimeCatalog([_runtime()]),
        bottleRepository: repository,
        winetricksVerbRepository: _verbRepository(const <String>[]),
        programRunPlanner: ProgramRunPlanner(
          hostPlatform: KonyakHostPlatform.macos,
        ),
        programRunner: runner,
        installerProgramRunner: ImmediateAsyncProgramRunner(runner),
        resourceFetcher: fetcher,
        nativeDllInstaller: _EventNativeDllInstaller(events, failAtCall: 1),
        managedProgramVerifier: RecordingManagedProfileProgramVerifier(
          ManagedProfileProgramVerified(ProgramPath('/bottles/test/Test.exe')),
        ),
      );

      final result = await installer.install(
        ProgramProfileInstallRequest(
          profileId: profile.id,
          bottleId: BottleId('test'),
        ),
      );

      expect(result, isA<ProgramProfileInstallFailed>());
      final failure = result as ProgramProfileInstallFailed;
      expect(failure.actionId, Option.of(PreInstallActionId(componentId)));
      expect(fetcher.released, hasLength(2));
      expect(
        _expectBottle(repository, BottleId('test')).programProfiles,
        isEmpty,
      );
    },
  );

  test(
    'installs in manifest order and persists only after verification',
    () async {
      final profile = testInstallProfile(
        preInstallActions: [
          PreInstallActionRecord.winetricks(verb: 'corefonts'),
          PreInstallActionRecord.winetricks(verb: 'vcrun2022'),
        ],
        installerCompletionChildExecutable: 'test.exe',
        executableSuffix: 'test-helper.exe',
        appendArgumentsIfMissing: const <String>[
          '--first-compatibility-argument',
          '--second-compatibility-argument',
        ],
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
        installerProgramRunner: ImmediateAsyncProgramRunner(runner),
        resourceFetcher: fetcher,
        managedProgramVerifier: verifier,
        progressSink: progressSink,
      );

      final result = await installer.install(
        ProgramProfileInstallRequest(
          profileId: profile.id,
          bottleId: BottleId('test'),
        ),
      );

      expect(result, isA<ProgramProfileInstalled>());
      expect(fetcher.resources, <ProfileResourceFetchRequest>[
        ProfileResourceFetchRequest.installer(profile.installerResource),
      ]);
      expect(runner.requests, hasLength(3));
      expect(runner.requests[0].arguments.value, contains('corefonts'));
      expect(runner.requests[1].arguments.value, contains('vcrun2022'));
      expect(
        runner.requests[0].environment.toMap(),
        isNot(contains(wineWaitChildPipeIgnoreEnvironmentVariable)),
      );
      expect(
        runner.requests[1].environment.toMap(),
        isNot(contains(wineWaitChildPipeIgnoreEnvironmentVariable)),
      );
      expect(runner.requests[2].arguments.value, <String>[
        'start',
        '/wait',
        '/unix',
        '/cache/TestSetup.exe',
      ]);
      expect(
        runner.requests[2].environment.toMap(),
        containsPair(wineWaitChildPipeIgnoreEnvironmentVariable, 'test.exe'),
      );
      expect(
        runner.requests[2].environment.toMap(),
        containsPair(
          konyakChildProcessRulesEnvironmentVariable,
          'test-helper.exe\t--first-compatibility-argument\n'
          'test-helper.exe\t--second-compatibility-argument',
        ),
      );
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
        bottle.programProfiles.single.preInstallActions,
        profile.preInstallActions,
      );
      expect(progressSink.progress.map(programProfileInstallProgressJson), <
        Map<String, Object?>
      >[
        _progress('preflight', 'started'),
        _progress('preflight', 'completed'),
        _progress('download', 'started'),
        _progress('download', 'completed'),
        _progress('verification', 'started'),
        _progress('verification', 'completed'),
        _progress('preInstallAction', 'started', index: 0, verb: 'corefonts'),
        _progress('preInstallAction', 'completed', index: 0, verb: 'corefonts'),
        _progress('preInstallAction', 'started', index: 1, verb: 'vcrun2022'),
        _progress('preInstallAction', 'completed', index: 1, verb: 'vcrun2022'),
        _progress('installer', 'started'),
        _progress('installer', 'completed'),
        _progress('resourceCleanup', 'started'),
        _progress('resourceCleanup', 'completed'),
        _progress('managedProgram', 'started'),
        _progress('managedProgram', 'completed'),
        _progress('persistence', 'started'),
        _progress('persistence', 'completed'),
      ]);
    },
  );

  test(
    'persists only after the asynchronous installer process exits',
    () async {
      final profile = testInstallProfile(
        preInstallActions: const <PreInstallActionRecord>[],
      );
      final repository = _repository();
      final verifier = RecordingManagedProfileProgramVerifier(
        ManagedProfileProgramVerified(profile.managedProgramPath),
      );
      final installerRunner = _DeferredAsyncProgramRunner();
      final installer = DefaultProgramProfileInstaller(
        installProfileCatalog: InstallProfileCatalog(<InstallProfileRecord>[
          profile,
        ]),
        runtimeCatalog: StaticRuntimeCatalog(<RuntimeRecord>[_runtime()]),
        bottleRepository: repository,
        winetricksVerbRepository: _verbRepository(const <String>[]),
        programRunPlanner: ProgramRunPlanner(
          hostPlatform: KonyakHostPlatform.macos,
        ),
        programRunner: RecordingProgramRunner(
          result: const ProgramRunCompleted(processExitCode: 0),
        ),
        installerProgramRunner: installerRunner,
        resourceFetcher: RecordingProfileInstallerResourceFetcher(
          ProfileInstallerResourceFetched(ProgramPath('/cache/TestSetup.exe')),
        ),
        managedProgramVerifier: verifier,
      );

      final installFuture = installer.install(
        ProgramProfileInstallRequest(
          profileId: profile.id,
          bottleId: BottleId('test'),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(installerRunner.requests, hasLength(1));
      expect(verifier.requests, isEmpty);
      expect(
        _expectBottle(repository, BottleId('test')).programProfiles,
        isEmpty,
      );

      installerRunner.complete(const ProgramRunCompleted(processExitCode: 0));
      expect(await installFuture, isA<ProgramProfileInstalled>());
      expect(verifier.requests, <ProgramPath>[profile.managedProgramPath]);
      expect(
        _expectBottle(repository, BottleId('test')).programProfiles,
        hasLength(1),
      );
    },
  );

  test('preflights every dependency verb before resource fetch', () async {
    final profile = testInstallProfile(
      preInstallActions: [
        PreInstallActionRecord.winetricks(verb: 'corefonts'),
        PreInstallActionRecord.winetricks(verb: 'vcrun2022'),
      ],
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
      installerProgramRunner: ImmediateAsyncProgramRunner(runner),
      resourceFetcher: fetcher,
      managedProgramVerifier: verifier,
      progressSink: progressSink,
    );

    final result = await installer.install(
      ProgramProfileInstallRequest(
        profileId: profile.id,
        bottleId: BottleId('test'),
      ),
    );

    expect(result, isA<ProgramProfileInstallFailed>());
    final failure = result as ProgramProfileInstallFailed;
    expect(failure.stage, ProgramProfileInstallStage.preflight);
    expect(failure.code, 'dependencyWinetricksVerbUnavailable');
    expect(failure.actionIndex, const Option.of(1));
    expect(failure.actionId, Option.of(PreInstallActionId('vcrun2022')));
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
          'actionIndex': 1,
          'actionKind': 'winetricks',
          'actionId': 'vcrun2022',
          'code': 'dependencyWinetricksVerbUnavailable',
        },
      ],
    );
  });

  test(
    'non-zero dependency exit stops installer, verification, and persistence',
    () async {
      final profile = testInstallProfile(
        preInstallActions: [
          PreInstallActionRecord.winetricks(verb: 'corefonts'),
          PreInstallActionRecord.winetricks(verb: 'vcrun2022'),
        ],
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
      final fetcher = RecordingProfileInstallerResourceFetcher(
        ProfileInstallerResourceFetched(ProgramPath('/cache/TestSetup.exe')),
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
        installerProgramRunner: ImmediateAsyncProgramRunner(runner),
        resourceFetcher: fetcher,
        managedProgramVerifier: verifier,
      );

      final result = await installer.install(
        ProgramProfileInstallRequest(
          profileId: profile.id,
          bottleId: BottleId('test'),
        ),
      );

      expect(result, isA<ProgramProfileInstallFailed>());
      final failure = result as ProgramProfileInstallFailed;
      expect(failure.stage, ProgramProfileInstallStage.preInstallAction);
      expect(failure.code, 'dependencyInstallerExitNonZero');
      expect(failure.actionIndex, const Option.of(1));
      expect(failure.actionId, Option.of(PreInstallActionId('vcrun2022')));
      expect(failure.processExitCode, const Option.of(37));
      expect(runner.requests, hasLength(2));
      expect(
        runner.requests.every(
          (request) => request.runnerKind == RunnerKind.macosWinetricks,
        ),
        isTrue,
      );
      expect(fetcher.releasedResources, hasLength(1));
      expect(verifier.requests, isEmpty);
      expect(
        _expectBottle(repository, BottleId('test')).programProfiles,
        isEmpty,
      );
    },
  );

  test(
    'rejects unsupported platforms and missing runtimes before fetch',
    () async {
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

        final result = await installer.install(
          ProgramProfileInstallRequest(
            profileId: testCase.profile.id,
            bottleId: BottleId('test'),
          ),
        );

        expect((result as ProgramProfileInstallFailed).code, testCase.code);
        expect(fetcher.resources, isEmpty);
      }
    },
  );

  test('preflights dependency plans before resource fetch', () async {
    final profile = testInstallProfile(
      preInstallActions: [
        PreInstallActionRecord.winetricks(verb: 'unknown-plan-verb'),
      ],
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

    final result = await installer.install(
      ProgramProfileInstallRequest(
        profileId: profile.id,
        bottleId: BottleId('test'),
      ),
    );

    expect(result, isA<ProgramProfileInstallFailed>());
    final failure = result as ProgramProfileInstallFailed;
    expect(failure.stage, ProgramProfileInstallStage.preflight);
    expect(failure.code, 'dependencyInstallerPlanUnavailable');
    expect(failure.actionIndex, const Option.of(0));
    expect(fetcher.resources, isEmpty);
  });

  test('rejects a bottle Windows version mismatch before fetch', () async {
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

    final result = await installer.install(
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

  test('treats a non-zero installer completion as a typed failure', () async {
    final profile = testInstallProfile(
      preInstallActions: const <PreInstallActionRecord>[],
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

    final result = await installer.install(
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

  test(
    'does not persist when the managed executable verification fails',
    () async {
      final profile = testInstallProfile(
        preInstallActions: const <PreInstallActionRecord>[],
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

      final result = await installer.install(
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
    },
  );
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
  final activeProgramRunner =
      programRunner ??
      RecordingProgramRunner(
        result: const ProgramRunCompleted(processExitCode: 0),
      );
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
    programRunner: activeProgramRunner,
    installerProgramRunner: ImmediateAsyncProgramRunner(activeProgramRunner),
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
      final int value => <String, Object?>{'actionIndex': value},
      _ => const <String, Object?>{},
    },
    ...switch (verb) {
      final String value => <String, Object?>{
        'actionKind': 'winetricks',
        'actionId': value,
      },
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
  final List<ProfileResourceFetchRequest> resources =
      <ProfileResourceFetchRequest>[];
  final List<ProfileInstallerResourceFetched> releasedResources =
      <ProfileInstallerResourceFetched>[];

  @override
  ProfileInstallerResourceFetchResult fetch(
    ProfileResourceFetchRequest resource,
  ) {
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

List<PreInstallActionRecord> _mixedPreInstallActions() {
  NativeDllResourceRecord resource(String fileName, String digest) =>
      NativeDllResourceRecord(
        kind: 'https',
        url: 'https://downloads.example.test/$fileName',
        sha256: digest,
        fileName: fileName,
      );
  return <PreInstallActionRecord>[
    PreInstallActionRecord.winetricks(verb: 'corefonts'),
    PreInstallActionRecord.winetricks(verb: 'vcrun2022'),
    PreInstallActionRecord.nativeDll(
      componentId: 'd3dcompiler_47-x86',
      machine: 'x86',
      destination: 'windowsSysWow64',
      targetFileName: 'd3dcompiler_47.dll',
      resource: resource('d3d-x86.dll', 'a' * 64),
    ),
    PreInstallActionRecord.nativeDll(
      componentId: 'd3dcompiler_47-x64',
      machine: 'x64',
      destination: 'windowsSystem32',
      targetFileName: 'd3dcompiler_47.dll',
      resource: resource('d3d-x64.dll', 'b' * 64),
    ),
    PreInstallActionRecord.winetricks(verb: 'fakejapanese'),
  ];
}

final class _SequencedResourceFetcher
    implements ProfileInstallerResourceFetcher {
  _SequencedResourceFetcher({required this.events, required this.results});

  final List<String> events;
  final List<ProfileInstallerResourceFetchResult> results;
  final List<ProfileInstallerResourceFetched> released = [];
  var _index = 0;

  @override
  ProfileInstallerResourceFetchResult fetch(
    ProfileResourceFetchRequest request,
  ) {
    events.add('fetch:${request.fileName}');
    return results[_index++];
  }

  @override
  ProfileInstallerResourceReleaseResult release(
    ProfileInstallerResourceFetched resource,
  ) {
    released.add(resource);
    return const ProfileInstallerResourceReleased();
  }
}

final class _EventProgramRunner implements ProgramRunner {
  _EventProgramRunner(this.events);

  final List<String> events;

  @override
  ProgramRunResult run(ProgramRunRequest request) {
    final action = [
      'corefonts',
      'vcrun2022',
      'fakejapanese',
    ].firstWhere(request.arguments.value.contains, orElse: () => 'installer');
    events.add('run:$action');
    return const ProgramRunCompleted(processExitCode: 0);
  }
}

final class _EventNativeDllInstaller implements NativeDllInstaller {
  _EventNativeDllInstaller(this.events, {this.failAtCall});

  final List<String> events;
  final int? failAtCall;
  var _calls = 0;

  @override
  NativeDllInstallResult install({
    required BottleRecord bottle,
    required NativeDllPreInstallAction action,
    required ProgramPath resourcePath,
  }) {
    _calls += 1;
    events.add('native:${action.componentId.value}');
    if (_calls == failAtCall) {
      return const NativeDllInstallFailed(
        code: 'nativeDllInstallFailed',
        message: 'Injected failure.',
      );
    }
    return const NativeDllInstalled(changed: true);
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

final class _DeferredAsyncProgramRunner implements AsyncProgramRunner {
  final Completer<ProgramRunResult> _result = Completer<ProgramRunResult>();
  final List<ProgramRunRequest> requests = <ProgramRunRequest>[];

  @override
  Future<ProgramRunResult> run(ProgramRunRequest request) {
    requests.add(request);
    return _result.future;
  }

  void complete(ProgramRunResult result) {
    _result.complete(result);
  }
}
