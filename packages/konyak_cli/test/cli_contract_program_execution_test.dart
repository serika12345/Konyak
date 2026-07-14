import 'support/cli_contract_full_helpers.dart';

void main() {
  test('suggest-graphics-backend --json uses the injected inspector', () {
    final inspector = RecordingProgramGraphicsBackendHintsInspector(
      ProgramGraphicsBackendHintsInspected(
        ProgramGraphicsBackendHints(
          programPath: ProgramPath('/games/injected.exe'),
          hostPlatform: KonyakHostPlatform.macos,
          signals: const [],
          suggestions: [
            ProgramGraphicsBackendSuggestion(
              backend: GraphicsBackendKind('dxvk'),
              confidence: GraphicsBackendConfidence('low'),
              reason: 'Injected inspector result.',
            ),
          ],
        ),
      ),
    );

    final result = runCli(
      const [
        'suggest-graphics-backend',
        '--program',
        '/games/injected.exe',
        '--json',
      ],
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
      ),
      programGraphicsBackendHintsInspector: inspector,
    );

    expect(result.exitCode, 0);
    expect(inspector.requests, [
      (
        programPath: ProgramPath('/games/injected.exe'),
        hostPlatform: KonyakHostPlatform.macos,
      ),
    ]);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(
      (payload['graphicsBackendHints'] as Map<String, Object?>)['suggestions'],
      [
        {
          'backend': 'dxvk',
          'confidence': 'low',
          'reason': 'Injected inspector result.',
        },
      ],
    );
  });

  test(
    'suggest-graphics-backend --json recommends D3DMetal for D3D12 on macOS',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'konyak-graphics-hints-test-',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });
      final programPath = joinTestPath(tempDirectory.path, const ['game.exe']);
      File(programPath).writeAsBytesSync(
        syntheticPortableExecutableBytes(
          importDllNames: const ['d3d12.dll', 'dxgi.dll'],
        ),
      );

      final result = runCli(
        ['suggest-graphics-backend', '--program', programPath, '--json'],
        programRunPlanner: ProgramRunPlanner(
          hostPlatform: KonyakHostPlatform.macos,
        ),
        programGraphicsBackendHintsInspector:
            const DartIoProgramGraphicsBackendHintsInspector(),
      );

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);

      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      expect(payload, {
        'schemaVersion': 1,
        'graphicsBackendHints': {
          'programPath': programPath,
          'hostPlatform': 'macos',
          'signals': [
            {'kind': 'peImport', 'value': 'd3d12.dll'},
            {'kind': 'peImport', 'value': 'dxgi.dll'},
          ],
          'suggestions': [
            {
              'backend': 'd3dMetal',
              'confidence': 'high',
              'reason': 'D3D12 API usage was detected.',
            },
          ],
        },
      });
    },
  );

  test(
    'suggest-graphics-backend --json recommends DXVK for D3D10 on macOS',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'konyak-graphics-hints-d3d10-test-',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });
      final programPath = joinTestPath(tempDirectory.path, const ['game.exe']);
      File(programPath).writeAsBytesSync(
        syntheticPortableExecutableBytes(importDllNames: const ['d3d10.dll']),
      );

      final result = runCli(
        ['suggest-graphics-backend', '--program', programPath, '--json'],
        programRunPlanner: ProgramRunPlanner(
          hostPlatform: KonyakHostPlatform.macos,
        ),
        programGraphicsBackendHintsInspector:
            const DartIoProgramGraphicsBackendHintsInspector(),
      );

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);

      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      expect(
        (payload['graphicsBackendHints']
            as Map<String, Object?>)['suggestions'],
        [
          {
            'backend': 'dxvk',
            'confidence': 'high',
            'reason': 'D3D10 API usage was detected.',
          },
          {
            'backend': 'wineDefault',
            'confidence': 'medium',
            'reason':
                'GPTK/D3DMetal does not provide native D3D10; use WineD3D/'
                'Vulkan fallback when D3DMetal is selected.',
          },
        ],
      );
    },
  );

  test(
    'suggest-graphics-backend --json keeps DXMT first for D3D11 on macOS',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'konyak-graphics-hints-d3d11-test-',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });
      final programPath = joinTestPath(tempDirectory.path, const ['game.exe']);
      File(programPath).writeAsBytesSync(
        syntheticPortableExecutableBytes(importDllNames: const ['d3d11.dll']),
      );

      final result = runCli(
        ['suggest-graphics-backend', '--program', programPath, '--json'],
        programRunPlanner: ProgramRunPlanner(
          hostPlatform: KonyakHostPlatform.macos,
        ),
        programGraphicsBackendHintsInspector:
            const DartIoProgramGraphicsBackendHintsInspector(),
      );

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);

      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      expect(
        (payload['graphicsBackendHints']
            as Map<String, Object?>)['suggestions'],
        [
          {
            'backend': 'dxmt',
            'confidence': 'medium',
            'reason': 'D3D11 API usage was detected.',
          },
          {
            'backend': 'dxvk',
            'confidence': 'medium',
            'reason': 'D3D11 API usage was detected.',
          },
        ],
      );
    },
  );

  test(
    'suggest-graphics-backend --json recommends vkd3d-proton for D3D12 on Linux',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'konyak-graphics-hints-linux-test-',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });
      final programPath = joinTestPath(tempDirectory.path, const ['game.exe']);
      File(programPath).writeAsBytesSync(
        syntheticPortableExecutableBytes(importDllNames: const ['d3d12.dll']),
      );

      final result = runCli(
        ['suggest-graphics-backend', '--program', programPath, '--json'],
        programRunPlanner: ProgramRunPlanner(
          hostPlatform: KonyakHostPlatform.linux,
        ),
        programGraphicsBackendHintsInspector:
            const DartIoProgramGraphicsBackendHintsInspector(),
      );

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);

      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      expect(
        (payload['graphicsBackendHints']
            as Map<String, Object?>)['suggestions'],
        [
          {
            'backend': 'vkd3dProton',
            'confidence': 'high',
            'reason': 'D3D12 API usage was detected.',
          },
        ],
      );
    },
  );

  test('get-program-settings --json returns default program settings', () {
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: '/home/user/.local/share/konyak',
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: '/home/user/.local/share/konyak/bottles/steam',
          windowsVersion: 'win10',
          pinnedPrograms: [
            PinnedProgramRecord(name: 'Steam', path: '/downloads/Steam.exe'),
          ],
        ),
      ],
    );

    final result = runCli(const [
      'get-program-settings',
      'steam',
      '--program',
      '/downloads/Steam.exe',
      '--json',
    ], bottleRepository: repository);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'programSettings': {
        'bottleId': 'steam',
        'programPath': '/downloads/Steam.exe',
        'settings': {
          'locale': '',
          'arguments': '',
          'environment': <String, Object?>{},
        },
      },
    });
  });

  test(
    'get-program-settings --json reports repository I/O failures as JSON',
    () {
      final result = runCli(
        const [
          'get-program-settings',
          'steam',
          '--program',
          '/downloads/Steam.exe',
          '--json',
        ],
        bottleRepository: FailingBottleRepository(
          dataHome: '/home/user/.local/share/konyak',
          message: 'settings file is unreadable',
          bottles: [
            BottleRecord(
              id: 'steam',
              name: 'Steam',
              path: '/home/user/.local/share/konyak/bottles/steam',
              windowsVersion: 'win10',
            ),
          ],
        ),
      );

      expect(result.exitCode, 74);
      expect(result.stderr, isEmpty);

      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      expect(payload, {
        'schemaVersion': 1,
        'error': {
          'code': 'bottleRepositoryError',
          'message': 'settings file is unreadable',
        },
      });
    },
  );

  test('set-program-settings --json persists program settings', () {
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: '/home/user/.local/share/konyak',
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: '/home/user/.local/share/konyak/bottles/steam',
          windowsVersion: 'win10',
          pinnedPrograms: [
            PinnedProgramRecord(name: 'Steam', path: '/downloads/Steam.exe'),
          ],
        ),
      ],
    );

    final result = runCli([
      'set-program-settings',
      'steam',
      '--program',
      '/downloads/Steam.exe',
      '--settings-json',
      jsonEncode({
        'locale': 'ja_JP.UTF-8',
        'arguments': '-silent -windowed',
        'environment': {'STEAM_COMPAT_DATA_PATH': '/compat'},
      }),
      '--json',
    ], bottleRepository: repository);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'programSettings': {
        'bottleId': 'steam',
        'programPath': '/downloads/Steam.exe',
        'settings': {
          'locale': 'ja_JP.UTF-8',
          'arguments': '-silent -windowed',
          'environment': {'STEAM_COMPAT_DATA_PATH': '/compat'},
        },
      },
    });

    final settings = repository.readProgramSettings(
      ProgramSettingsRequest(
        bottleId: BottleId('steam'),
        programPath: ProgramPath('/downloads/Steam.exe'),
      ),
    );
    expect(settings, isA<ProgramSettingsRead>());
    expect(
      (settings as ProgramSettingsRead).settings.locale.value,
      'ja_JP.UTF-8',
    );
    expect(settings.settings.arguments.value, '-silent -windowed');
    expect(settings.settings.environment.toMap(), {
      'STEAM_COMPAT_DATA_PATH': '/compat',
    });
  });

  test('set-program-settings --json persists program logging settings', () {
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: '/home/user/.local/share/konyak',
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: '/home/user/.local/share/konyak/bottles/steam',
          windowsVersion: 'win10',
          pinnedPrograms: [
            PinnedProgramRecord(name: 'Steam', path: '/downloads/Steam.exe'),
          ],
        ),
      ],
    );

    final result = runCli([
      'set-program-settings',
      'steam',
      '--program',
      '/downloads/Steam.exe',
      '--settings-json',
      jsonEncode({
        'logging': {
          'createLogFile': true,
          'additionalWineLoggingChannels': '+relay,+file',
          'logFilePath': '/tmp/steam.cxlog',
        },
      }),
      '--json',
    ], bottleRepository: repository);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'programSettings': {
        'bottleId': 'steam',
        'programPath': '/downloads/Steam.exe',
        'settings': {
          'locale': '',
          'arguments': '',
          'environment': <String, Object?>{},
          'logging': {
            'createLogFile': true,
            'additionalWineLoggingChannels': '+relay,+file',
            'logFilePath': '/tmp/steam.cxlog',
          },
        },
      },
    });

    final settings = repository.readProgramSettings(
      ProgramSettingsRequest(
        bottleId: BottleId('steam'),
        programPath: ProgramPath('/downloads/Steam.exe'),
      ),
    );
    expect(settings, isA<ProgramSettingsRead>());
    final logging = (settings as ProgramSettingsRead).settings.logging
        .toNullable();
    expect(logging?.createLogFile, isTrue);
    expect(logging?.additionalWineLoggingChannels.value, '+relay,+file');
    expect(logging?.logFilePath.value, '/tmp/steam.cxlog');
  });

  test('list-install-profiles --json returns profile summaries', () {
    final result = runCli(const [
      'list-install-profiles',
      '--json',
    ], installProfileCatalog: testInstallProfileCatalog());

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'installProfiles': [
        {'id': 'test-profile', 'name': 'Test Profile', 'profileVersion': 1},
      ],
    });
  });

  test('inspect-install-profile --json returns complete profile details', () {
    final installProfile = testInstallProfile().copyWith(
      installerCompletion: Option.of(
        InstallerCompletionRecord(ignoreChildExecutable: 'launcher.exe'),
      ),
    );
    final result = runCli(
      const ['inspect-install-profile', 'test-profile', '--json'],
      installProfileCatalog: testInstallProfileCatalog(
        profiles: [installProfile],
      ),
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    final profile = payload['installProfile'] as Map<String, Object?>;
    expect(payload['schemaVersion'], 1);
    expect(profile, {
      'id': 'test-profile',
      'name': 'Test Profile',
      'profileVersion': 1,
      'profileSourceKind': 'builtin',
      'profileSourceId': 'test-profile.json',
      'profileDigest': 'fedcba9876543210' * 4,
      'summary': 'A deterministic compatibility profile used by CLI tests.',
      'platforms': ['macos'],
      'bottleTemplate': {'windowsVersion': 'win10'},
      'managedProgramPath': r'C:\Test App\Test.exe',
      'installerResource': {
        'kind': 'https',
        'url': 'https://downloads.example.test/TestSetup.exe',
        'sha256': '0123456789abcdef' * 4,
        'fileName': 'TestSetup.exe',
      },
      'installerCompletion': {'ignoreChildExecutable': 'launcher.exe'},
      'preInstallActions': <Object?>[],
      'runCompletionPolicy': 'launchOnly',
      'compatibilityProfile': {
        'id': 'test-profile',
        'profileVersion': 1,
        'childProcessRules': [
          {
            'executableSuffix': 'test-helper.exe',
            'appendArgumentsIfMissing': ['--test-compat'],
          },
        ],
      },
    });
  });

  test('inspect-install-profile --json rejects unknown profiles', () {
    final result = runCli(const [
      'inspect-install-profile',
      'unknown',
      '--json',
    ], installProfileCatalog: testInstallProfileCatalog());

    expect(result.exitCode, 66);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'error': {
        'code': 'installProfileNotFound',
        'message': 'Install profile was not found.',
        'profileId': 'unknown',
      },
    });
  });

  test('apply-program-profile --json persists profile metadata', () {
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: '/home/user/.local/share/konyak',
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: '/home/user/.local/share/konyak/bottles/steam',
          windowsVersion: 'win10',
        ),
      ],
    );

    final result = runCli(
      const [
        'apply-program-profile',
        'test-profile',
        '--bottle',
        'steam',
        '--program',
        r'C:\Test App\Test.exe',
        '--json',
      ],
      bottleRepository: repository,
      installProfileCatalog: testInstallProfileCatalog(),
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'programProfile': {
        'bottleId': 'steam',
        'profileSchemaVersion': 1,
        'profileId': 'test-profile',
        'profileVersion': 1,
        'profileSourceKind': 'builtin',
        'profileSourceId': 'test-profile.json',
        'profileDigest': 'fedcba9876543210' * 4,
        'managedProgramPath': r'C:\Test App\Test.exe',
        'compatibilityProfileId': 'test-profile',
        'compatibilityProfileVersion': 1,
        'installerResource': {
          'kind': 'https',
          'url': 'https://downloads.example.test/TestSetup.exe',
          'sha256': '0123456789abcdef' * 4,
          'fileName': 'TestSetup.exe',
        },
        'preInstallActions': <Object?>[],
      },
    });

    final updated = expectFound(repository.findBottle(BottleId('steam')));
    expect(updated.programProfiles, hasLength(1));
    expect(updated.programProfiles.single.profileId.value, 'test-profile');
    expect(
      updated.programProfiles.single.managedProgramPath.value,
      r'C:\Test App\Test.exe',
    );
    expect(updated.pinnedPrograms, hasLength(1));
    expect(updated.pinnedPrograms.single.name.value, 'Test Profile');
  });

  test('repair-profile --json returns persisted profile metadata', () {
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: '/home/user/.local/share/konyak',
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: '/home/user/.local/share/konyak/bottles/steam',
          windowsVersion: 'win10',
          programProfiles: [
            ProgramProfileRecord(
              profileId: 'test-profile',
              profileVersion: 1,
              managedProgramPath: r'C:\Test App\Test.exe',
              installerResource: testInstallerResource(),
              profileSourceId: 'test-profile.json',
              profileDigest: 'fedcba9876543210' * 4,
              compatibilityProfileId: 'test-profile',
              compatibilityProfileVersion: 1,
            ),
          ],
        ),
      ],
    );

    final result = runCli(
      const ['repair-profile', 'test-profile', '--bottle', 'steam', '--json'],
      bottleRepository: repository,
      installProfileCatalog: testInstallProfileCatalog(),
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'programProfile': {
        'bottleId': 'steam',
        'profileSchemaVersion': 1,
        'profileId': 'test-profile',
        'profileVersion': 1,
        'profileSourceKind': 'builtin',
        'profileSourceId': 'test-profile.json',
        'profileDigest': 'fedcba9876543210' * 4,
        'managedProgramPath': r'C:\Test App\Test.exe',
        'compatibilityProfileId': 'test-profile',
        'compatibilityProfileVersion': 1,
        'installerResource': {
          'kind': 'https',
          'url': 'https://downloads.example.test/TestSetup.exe',
          'sha256': '0123456789abcdef' * 4,
          'fileName': 'TestSetup.exe',
        },
        'preInstallActions': <Object?>[],
      },
    });
  });

  test('run-program --json runs an EXE through the program runner', () {
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: '/home/user/.local/share/konyak',
    );
    final runner = RecordingProgramRunner(
      result: const ProgramRunCompleted(processExitCode: 0),
    );
    runCli(const [
      'create-bottle',
      '--name',
      'Steam',
      '--json',
    ], bottleRepository: repository);

    final result = runCli(
      const [
        'run-program',
        'steam',
        '--program',
        '/downloads/setup.exe',
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.linux,
      ),
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(
      runner.lastRequest?.executable.value,
      'Konyak/Runtimes/linux-wine/bin/wine',
    );
    expect(runner.lastRequest?.arguments, const ['/downloads/setup.exe']);
    expect(
      runner.lastRequest?.environment.toMap()['WINEPREFIX'],
      contains('/steam'),
    );
    expect(
      runner.lastRequest?.logPath.value,
      contains('/steam/logs/latest.log'),
    );

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'run': {
        'bottleId': 'steam',
        'programPath': '/downloads/setup.exe',
        'runnerKind': 'wine',
        'executable': 'Konyak/Runtimes/linux-wine/bin/wine',
        'workingDirectory': null,
        'argv': ['Konyak/Runtimes/linux-wine/bin/wine', '/downloads/setup.exe'],
        'logPath':
            '/home/user/.local/share/konyak/bottles/steam/logs/latest.log',
        'logFileCreated': true,
        'processExitCode': 0,
      },
    });
  });

  test('run-program --json applies persisted program settings', () {
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: '/home/user/.local/share/konyak',
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: '/home/user/.local/share/konyak/bottles/steam',
          windowsVersion: 'win10',
          pinnedPrograms: [
            PinnedProgramRecord(name: 'Steam', path: '/downloads/Steam.exe'),
          ],
        ),
      ],
    );
    repository.setProgramSettings(
      ProgramSettingsUpdateRequest(
        bottleId: BottleId('steam'),
        programPath: ProgramPath('/downloads/Steam.exe'),
        settings: ProgramSettingsRecord(
          locale: ProgramLocale('ja_JP.UTF-8'),
          arguments: ProgramArguments('-silent -windowed'),
          environment: ProgramEnvironmentOverrides(const {
            'STEAM_COMPAT_DATA_PATH': '/compat',
          }),
        ),
      ),
    );
    final runner = RecordingProgramRunner(
      result: const ProgramRunCompleted(processExitCode: 0),
    );

    final result = runCli(
      const [
        'run-program',
        'steam',
        '--program',
        '/downloads/Steam.exe',
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.linux,
      ),
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(runner.lastRequest?.arguments, const [
      '/downloads/Steam.exe',
      '-silent',
      '-windowed',
    ]);
    expect(runner.lastRequest?.environment.toMap(), {
      'PATH': 'Konyak/Runtimes/linux-wine/bin',
      'STEAM_COMPAT_DATA_PATH': '/compat',
      'LC_ALL': 'ja_JP.UTF-8',
      'WINEPREFIX': '/home/user/.local/share/konyak/bottles/steam',
      'WINEMSYNC': '1',
      'EGL_LOG_LEVEL': 'fatal',
      'MESA_LOG_LEVEL': 'fatal',
      'MESA_DEBUG': 'silent',
    });
  });

  test('run-program --json on Linux ignores macOS-only runtime settings', () {
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: '/home/user/.local/share/konyak',
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: '/home/user/.local/share/konyak/bottles/steam',
          windowsVersion: 'win10',
          runtimeSettings: Option.of(
            BottleRuntimeSettings(
              dxrEnabled: true,
              metalHud: true,
              metalTrace: true,
              avxEnabled: true,
            ),
          ),
        ),
      ],
    );
    final runner = RecordingProgramRunner(
      result: const ProgramRunCompleted(processExitCode: 0),
    );

    final result = runCli(
      const [
        'run-program',
        'steam',
        '--program',
        '/downloads/Steam.exe',
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.linux,
      ),
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    final environment = runner.lastRequest?.environment.toMap();
    expect(
      environment,
      containsPair(
        'WINEPREFIX',
        '/home/user/.local/share/konyak/bottles/steam',
      ),
    );
    expect(environment, containsPair('WINEMSYNC', '1'));
    expect(environment, isNot(contains('MTL_HUD_ENABLED')));
    expect(environment, isNot(contains('METAL_CAPTURE_ENABLED')));
    expect(environment, isNot(contains('ROSETTA_ADVERTISE_AVX')));
    expect(
      environment,
      isNot(containsPair('WINEDLLOVERRIDES', contains('nvapi64'))),
    );
  });

  test('run-program --json uses the Konyak macOS Wine startup path on macOS', () {
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: '/Users/user/Library/Application Support/Konyak',
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: '/Users/user/Library/Application Support/Konyak/Bottles/Steam',
          windowsVersion: 'win10',
        ),
      ],
    );
    final runner = RecordingProgramRunner(
      result: const ProgramRunCompleted(processExitCode: 0),
    );

    final result = runCli(
      const [
        'run-program',
        'steam',
        '--program',
        '/downloads/setup.exe',
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
        environment: HostEnvironment({'HOME': '/Users/user'}),
      ),
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(
      runner.lastRequest?.executable.value,
      '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wineloader',
    );
    expect(
      runner.lastRequest?.workingDirectory.toNullable()?.value,
      '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin',
    );
    expect(runner.lastRequest?.arguments, const [
      'start',
      '/unix',
      '/downloads/setup.exe',
    ]);
    expect(
      runner.lastRequest?.completionPolicy,
      ProgramRunCompletionPolicy.waitForExit,
    );
    expect(runner.lastRequest?.runnerKind.value, 'macosWine');
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair(
        'WINEPREFIX',
        '/Users/user/Library/Application Support/Konyak/Bottles/Steam',
      ),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair('WINEDEBUG', 'fixme-all'),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair('GST_DEBUG', '1'),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair('MVK_CONFIG_LOG_LEVEL', '0'),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair(
        'GST_PLUGIN_SYSTEM_PATH',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/gstreamer-1.0',
      ),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair(
        'GST_PLUGIN_SCANNER',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/libexec/gstreamer-1.0/gst-plugin-scanner',
      ),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair(
        'GST_REGISTRY',
        '/Users/user/Library/Application Support/Konyak/Bottles/Steam/gstreamer-1.0-registry.x86_64.bin',
      ),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair(
        'DYLD_LIBRARY_PATH',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib',
      ),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair(
        'WINEDLLPATH',
        macosManagedWineDllPath(
          '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine',
        ),
      ),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair(
        'WINEPATH',
        macosManagedWinePath(
          '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine',
        ),
      ),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair(
        'WINELOADER',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wineloader',
      ),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair(
        'WINESERVER',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wineserver',
      ),
    );

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'run': {
        'bottleId': 'steam',
        'programPath': '/downloads/setup.exe',
        'runnerKind': 'macosWine',
        'executable':
            '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wineloader',
        'workingDirectory':
            '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin',
        'argv': [
          '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wineloader',
          'start',
          '/unix',
          '/downloads/setup.exe',
        ],
        'logPath':
            '/Users/user/Library/Application Support/Konyak/Bottles/Steam/logs/latest.log',
        'logFileCreated': true,
        'processExitCode': 0,
      },
    });
  });

  test('run-program --json launches a managed profile without waiting', () {
    final installProfile = testInstallProfile(
      executableSuffix: 'synthetic-helper.exe',
      appendArgumentsIfMissing: const ['--first', '--second=value'],
    );
    final profiledProgramPath = installProfile.managedProgramPath.value;
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-profile-run-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final dataHome = joinTestPath(tempDirectory.path, const ['data']);
    final bottlePath = joinTestPath(dataHome, const ['Bottles', 'bottle']);
    final programPath = joinTestPath(bottlePath, const [
      'drive_c',
      'Test App',
      'Test.exe',
    ]);
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: dataHome,
      bottles: [
        BottleRecord(
          id: 'bottle',
          name: 'Bottle',
          path: bottlePath,
          windowsVersion: 'win10',
          programProfiles: [
            ProgramProfileRecord(
              profileId: installProfile.id.value,
              profileVersion: installProfile.profileVersion.value,
              managedProgramPath: profiledProgramPath,
              installerResource: installProfile.installerResource,
              profileSourceId: installProfile.sourceId.value,
              profileDigest: installProfile.manifestDigest.value,
              compatibilityProfileId:
                  installProfile.compatibilityProfile.id.value,
              compatibilityProfileVersion:
                  installProfile.compatibilityProfile.profileVersion.value,
            ),
          ],
        ),
      ],
    );
    final runner = RecordingProgramRunner(
      result: const ProgramRunCompleted(processExitCode: 0),
    );

    final result = runCli(
      ['run-program', 'bottle', '--program', programPath, '--json'],
      bottleRepository: repository,
      installProfileCatalog: InstallProfileCatalog([installProfile]),
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
        environment: HostEnvironment({'HOME': '/Users/user'}),
      ),
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(
      runner.lastRequest?.completionPolicy,
      ProgramRunCompletionPolicy.launchOnly,
    );
    expect(runner.requests, hasLength(1));
    expect(runner.lastRequest?.arguments, [profiledProgramPath]);

    final environment = runner.lastRequest?.environment.toMap();
    expect(
      environment,
      containsPair(
        konyakChildProcessRulesEnvironmentVariable,
        'synthetic-helper.exe\t--first\n'
        'synthetic-helper.exe\t--second=value',
      ),
    );
  });

  test(
    'run-program --json resolves shortcut targets for profile compatibility',
    () {
      final installProfile = testInstallProfile(
        executableSuffix: 'synthetic-helper.exe',
        appendArgumentsIfMissing: const ['--test-compat'],
      );
      final profiledProgramPath = installProfile.managedProgramPath.value;
      final tempDirectory = Directory.systemTemp.createTempSync(
        'konyak-profile-shortcut-run-test-',
      );
      addTearDown(() {
        if (tempDirectory.existsSync()) {
          tempDirectory.deleteSync(recursive: true);
        }
      });
      final dataHome = joinTestPath(tempDirectory.path, const ['data']);
      final bottlePath = joinTestPath(dataHome, const ['Bottles', 'bottle']);
      final shortcutPath = joinTestPath(bottlePath, const [
        'drive_c',
        'ProgramData',
        'Microsoft',
        'Windows',
        'Start Menu',
        'Programs',
        'Test App',
        'Test.lnk',
      ]);
      File(shortcutPath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(
          syntheticShellLinkBytes(localBasePath: profiledProgramPath),
        );
      final repository = MemoryBottleRepository(
        programMetadataExtractor: const NoopProgramMetadataExtractor(),
        dataHome: dataHome,
        bottles: [
          BottleRecord(
            id: 'bottle',
            name: 'Bottle',
            path: bottlePath,
            windowsVersion: 'win10',
            programProfiles: [
              ProgramProfileRecord(
                profileId: installProfile.id.value,
                profileVersion: installProfile.profileVersion.value,
                managedProgramPath: profiledProgramPath,
                installerResource: installProfile.installerResource,
                profileSourceId: installProfile.sourceId.value,
                profileDigest: installProfile.manifestDigest.value,
                compatibilityProfileId:
                    installProfile.compatibilityProfile.id.value,
                compatibilityProfileVersion:
                    installProfile.compatibilityProfile.profileVersion.value,
              ),
            ],
          ),
        ],
      );
      final runner = RecordingProgramRunner(
        result: const ProgramRunCompleted(processExitCode: 0),
      );

      final result = runCli(
        ['run-program', 'bottle', '--program', shortcutPath, '--json'],
        bottleRepository: repository,
        installProfileCatalog: InstallProfileCatalog([installProfile]),
        programRunPlanner: ProgramRunPlanner(
          hostPlatform: KonyakHostPlatform.macos,
          environment: HostEnvironment({'HOME': '/Users/user'}),
        ),
        programRunner: runner,
      );

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);
      expect(runner.lastRequest?.arguments, ['start', '/unix', shortcutPath]);
      expect(
        runner.lastRequest?.completionPolicy,
        ProgramRunCompletionPolicy.launchOnly,
      );
      expect(
        runner.lastRequest?.environment.toMap(),
        containsPair(
          konyakChildProcessRulesEnvironmentVariable,
          'synthetic-helper.exe\t--test-compat',
        ),
      );
    },
  );

  test('run-program --json preserves macOS bottle environment on macOS', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-macos-run-env-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    final runtimeRoot = joinTestPath(tempDirectory.path, const ['runtime']);
    final bottlePath = joinTestPath(tempDirectory.path, const [
      'bottles',
      'steam',
    ]);
    for (final arch in const ['x86_64-windows', 'i386-windows']) {
      for (final dllName in const [
        'dxgi.dll',
        'd3d9.dll',
        'd3d10.dll',
        'd3d10_1.dll',
        'd3d10core.dll',
        'd3d11.dll',
      ]) {
        final file = File(
          joinTestPath(runtimeRoot, ['lib', 'dxvk', arch, dllName]),
        );
        file.parent.createSync(recursive: true);
        file.writeAsStringSync('$arch/$dllName');
      }
    }

    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: joinTestPath(tempDirectory.path, const ['data']),
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: bottlePath,
          windowsVersion: 'win10',
          runtimeSettings: Option.of(
            BottleRuntimeSettings(
              enhancedSync: EnhancedSyncMode('msync'),
              metalHud: true,
              metalTrace: true,
              avxEnabled: true,
              dxvk: true,
              dxvkHud: DxvkHudMode('partial'),
            ),
          ),
        ),
      ],
    );
    final runner = RecordingProgramRunner(
      result: const ProgramRunCompleted(processExitCode: 0),
    );

    final result = runCli(
      const [
        'run-program',
        'steam',
        '--program',
        '/downloads/setup.exe',
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
        environment: HostEnvironment({'KONYAK_MACOS_WINE_HOME': runtimeRoot}),
      ),
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair('WINEMSYNC', '1'),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      isNot(containsPair('WINEESYNC', '1')),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair('MTL_HUD_ENABLED', '1'),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair('METAL_CAPTURE_ENABLED', '1'),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair('ROSETTA_ADVERTISE_AVX', '1'),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair('DXVK_HUD', 'devinfo,fps,frametimes'),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair('DXVK_ASYNC', '1'),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair(
        'WINEDLLOVERRIDES',
        'dxgi,d3d9,d3d10,d3d10_1,d3d10core,d3d11=n,b',
      ),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair(
        'WINEDLLPATH',
        macosManagedWineDllPathWithOverrides(runtimeRoot, const [
          ['lib', 'dxvk', 'x86_64-windows'],
          ['lib', 'dxvk', 'i386-windows'],
        ]),
      ),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair(
        'WINEPATH',
        macosManagedWinePathWithOverrides(runtimeRoot, const [
          ['lib', 'dxvk', 'x86_64-windows'],
          ['lib', 'dxvk', 'i386-windows'],
        ]),
      ),
    );
  });

  test('run-program --json applies D3DMetal settings on macOS', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-d3dmetal-run-env-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    final runtimeRoot = joinTestPath(tempDirectory.path, const ['runtime']);
    final bottlePath = joinTestPath(tempDirectory.path, const [
      'bottles',
      'steam',
    ]);
    for (final dllName in gptkD3DMetalOverrideDllNames) {
      final file = File(
        joinTestPath(runtimeRoot, [
          'components',
          'gptk-d3dmetal',
          'lib',
          'wine',
          'x86_64-windows',
          dllName,
        ]),
      );
      file.parent.createSync(recursive: true);
      file.writeAsStringSync('d3dmetal/$dllName');
    }

    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: joinTestPath(tempDirectory.path, const ['data']),
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: bottlePath,
          windowsVersion: 'win10',
          runtimeSettings: Option.of(BottleRuntimeSettings(dxrEnabled: true)),
        ),
      ],
    );
    final runner = RecordingProgramRunner(
      result: const ProgramRunCompleted(processExitCode: 0),
    );

    final result = runCli(
      const [
        'run-program',
        'steam',
        '--program',
        '/downloads/setup.exe',
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
        environment: HostEnvironment({'KONYAK_MACOS_WINE_HOME': runtimeRoot}),
      ),
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair('WINEDLLOVERRIDES', 'dxgi,d3d11,d3d12,nvapi64,nvngx=n,b'),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair(
        'WINEDLLPATH',
        macosManagedWineDllPathWithOverrides(runtimeRoot, const [
          <String>[
            'components',
            'gptk-d3dmetal',
            'lib',
            'wine',
            'x86_64-windows',
          ],
        ]),
      ),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair(
        'WINEPATH',
        macosManagedWinePathWithOverrides(runtimeRoot, const [
          <String>[
            'components',
            'gptk-d3dmetal',
            'lib',
            'wine',
            'x86_64-windows',
          ],
        ]),
      ),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair(
        'DYLD_LIBRARY_PATH',
        '$runtimeRoot/components/gptk-d3dmetal/lib/external:'
            '$runtimeRoot/components/gptk-d3dmetal/lib/wine/x86_64-unix:'
            '$runtimeRoot/lib',
      ),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair(
        'DYLD_FRAMEWORK_PATH',
        '$runtimeRoot/components/gptk-d3dmetal/lib/external',
      ),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair(
        'CX_APPLEGPTK_LIBD3DSHARED_PATH',
        '$runtimeRoot/components/gptk-d3dmetal/lib/external/'
            'libd3dshared.dylib',
      ),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair('D3DM_SUPPORT_DXR', '1'),
    );
  });

  test('run-program --json falls back to WineD3D for D3D10 with D3DMetal', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-d3dmetal-d3d10-fallback-run-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    final runtimeRoot = joinTestPath(tempDirectory.path, const ['runtime']);
    final bottlePath = joinTestPath(tempDirectory.path, const [
      'bottles',
      'steam',
    ]);
    createMacosWineD3DBuiltinDlls(runtimeRoot);
    final programPath = joinTestPath(tempDirectory.path, const ['game.exe']);
    File(programPath).writeAsBytesSync(
      syntheticPortableExecutableBytes(importDllNames: const ['d3d10.dll']),
    );
    for (final dllName in gptkD3DMetalOverrideDllNames) {
      final runtimeFile = File(
        joinTestPath(runtimeRoot, [
          'components',
          'gptk-d3dmetal',
          'lib',
          'wine',
          'x86_64-windows',
          dllName,
        ]),
      );
      runtimeFile.parent.createSync(recursive: true);
      runtimeFile.writeAsStringSync('d3dmetal/$dllName');
      final staleFile = File(
        joinTestPath(bottlePath, ['drive_c', 'windows', 'system32', dllName]),
      );
      staleFile.parent.createSync(recursive: true);
      staleFile.writeAsStringSync('stale $dllName');
    }

    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: joinTestPath(tempDirectory.path, const ['data']),
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: bottlePath,
          windowsVersion: 'win10',
          runtimeSettings: Option.of(BottleRuntimeSettings(dxrEnabled: true)),
        ),
      ],
    );
    final runner = RecordingProgramRunner(
      result: const ProgramRunCompleted(processExitCode: 0),
    );

    final result = runCli(
      ['run-program', 'steam', '--program', programPath, '--json'],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
        environment: HostEnvironment({'KONYAK_MACOS_WINE_HOME': runtimeRoot}),
      ),
      programGraphicsBackendHintsInspector:
          const DartIoProgramGraphicsBackendHintsInspector(),
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    final environment = runner.lastRequest?.environment.toMap();
    expect(
      environment?['WINEDLLPATH'],
      macosManagedWineDllPathWithOverrides(runtimeRoot, const []),
    );
    expect(
      environment?['WINEPATH'],
      macosManagedWinePathWithOverrides(runtimeRoot, const []),
    );
    expect(environment, isNot(containsPair('WINEDLLOVERRIDES', anything)));
    expect(environment, isNot(containsPair('DYLD_FRAMEWORK_PATH', anything)));
    expect(
      environment,
      isNot(containsPair('CX_APPLEGPTK_LIBD3DSHARED_PATH', anything)),
    );
    expect(environment, isNot(containsPair('D3DM_SUPPORT_DXR', anything)));
    expect(
      environment,
      containsPair('KONYAK_GRAPHICS_BACKEND_REQUESTED', 'gptk-d3dmetal'),
    );
    expect(
      environment,
      containsPair('KONYAK_GRAPHICS_BACKEND_SELECTED', 'wined3d-vulkan'),
    );
    expect(
      environment,
      containsPair(
        'KONYAK_GRAPHICS_BACKEND_FALLBACK_REASON',
        'gptkD3d10Unsupported',
      ),
    );
    for (final arch in const <(String, String)>[
      ('x86_64-windows', 'system32'),
      ('i386-windows', 'syswow64'),
    ]) {
      final (runtimeArchitecture, windowsDirectory) = arch;
      for (final dllName in testMacosWineD3DBuiltinDllNames) {
        expect(
          File(
            joinTestPath(bottlePath, [
              'drive_c',
              'windows',
              windowsDirectory,
              dllName,
            ]),
          ).readAsStringSync(),
          '$runtimeArchitecture/$dllName',
        );
      }
      for (final dllName in const <String>['nvapi64.dll', 'nvngx.dll']) {
        expect(
          File(
            joinTestPath(bottlePath, [
              'drive_c',
              'windows',
              windowsDirectory,
              dllName,
            ]),
          ).existsSync(),
          isFalse,
        );
      }
    }
  });

  test('run-program --json keeps D3DMetal for D3D12 imports on macOS', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-d3dmetal-d3d12-run-env-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    final runtimeRoot = joinTestPath(tempDirectory.path, const ['runtime']);
    final bottlePath = joinTestPath(tempDirectory.path, const [
      'bottles',
      'steam',
    ]);
    final programPath = joinTestPath(tempDirectory.path, const ['game.exe']);
    File(programPath).writeAsBytesSync(
      syntheticPortableExecutableBytes(
        importDllNames: const ['d3d12.dll', 'd3d10.dll'],
      ),
    );
    for (final dllName in gptkD3DMetalOverrideDllNames) {
      final file = File(
        joinTestPath(runtimeRoot, [
          'components',
          'gptk-d3dmetal',
          'lib',
          'wine',
          'x86_64-windows',
          dllName,
        ]),
      );
      file.parent.createSync(recursive: true);
      file.writeAsStringSync('d3dmetal/$dllName');
    }

    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: joinTestPath(tempDirectory.path, const ['data']),
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: bottlePath,
          windowsVersion: 'win10',
          runtimeSettings: Option.of(BottleRuntimeSettings(dxrEnabled: true)),
        ),
      ],
    );
    final runner = RecordingProgramRunner(
      result: const ProgramRunCompleted(processExitCode: 0),
    );

    final result = runCli(
      ['run-program', 'steam', '--program', programPath, '--json'],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
        environment: HostEnvironment({'KONYAK_MACOS_WINE_HOME': runtimeRoot}),
      ),
      programGraphicsBackendHintsInspector:
          const DartIoProgramGraphicsBackendHintsInspector(),
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    final environment = runner.lastRequest?.environment.toMap();
    expect(
      environment?['WINEDLLPATH'],
      macosManagedWineDllPathWithOverrides(runtimeRoot, const [
        <String>[
          'components',
          'gptk-d3dmetal',
          'lib',
          'wine',
          'x86_64-windows',
        ],
      ]),
    );
    expect(environment, containsPair('D3DM_SUPPORT_DXR', '1'));
    expect(
      environment,
      isNot(containsPair('KONYAK_GRAPHICS_BACKEND_FALLBACK_REASON', anything)),
    );
  });

  test(
    'run-program --json keeps D3DMetal for D3D12 string signals on macOS',
    () {
      final tempDirectory = Directory.systemTemp.createTempSync(
        'konyak-d3dmetal-d3d12-string-run-env-test-',
      );
      addTearDown(() {
        if (tempDirectory.existsSync()) {
          tempDirectory.deleteSync(recursive: true);
        }
      });

      final runtimeRoot = joinTestPath(tempDirectory.path, const ['runtime']);
      final bottlePath = joinTestPath(tempDirectory.path, const [
        'bottles',
        'steam',
      ]);
      final programPath = joinTestPath(tempDirectory.path, const ['game.exe']);
      File(programPath).writeAsBytesSync(
        syntheticPortableExecutableBytes(
          importDllNames: const ['d3d10.dll'],
          asciiStrings: const ['D3D12CreateDevice'],
        ),
      );
      for (final dllName in gptkD3DMetalOverrideDllNames) {
        final file = File(
          joinTestPath(runtimeRoot, [
            'components',
            'gptk-d3dmetal',
            'lib',
            'wine',
            'x86_64-windows',
            dllName,
          ]),
        );
        file.parent.createSync(recursive: true);
        file.writeAsStringSync('d3dmetal/$dllName');
      }

      final repository = MemoryBottleRepository(
        programMetadataExtractor: const NoopProgramMetadataExtractor(),
        dataHome: joinTestPath(tempDirectory.path, const ['data']),
        bottles: [
          BottleRecord(
            id: 'steam',
            name: 'Steam',
            path: bottlePath,
            windowsVersion: 'win10',
            runtimeSettings: Option.of(BottleRuntimeSettings(dxrEnabled: true)),
          ),
        ],
      );
      final runner = RecordingProgramRunner(
        result: const ProgramRunCompleted(processExitCode: 0),
      );

      final result = runCli(
        ['run-program', 'steam', '--program', programPath, '--json'],
        bottleRepository: repository,
        programRunPlanner: ProgramRunPlanner(
          hostPlatform: KonyakHostPlatform.macos,
          environment: HostEnvironment({'KONYAK_MACOS_WINE_HOME': runtimeRoot}),
        ),
        programGraphicsBackendHintsInspector:
            const DartIoProgramGraphicsBackendHintsInspector(),
        programRunner: runner,
      );

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);
      final environment = runner.lastRequest?.environment.toMap();
      expect(
        environment?['WINEDLLPATH'],
        macosManagedWineDllPathWithOverrides(runtimeRoot, const [
          <String>[
            'components',
            'gptk-d3dmetal',
            'lib',
            'wine',
            'x86_64-windows',
          ],
        ]),
      );
      expect(environment, containsPair('D3DM_SUPPORT_DXR', '1'));
      expect(
        environment,
        isNot(
          containsPair('KONYAK_GRAPHICS_BACKEND_FALLBACK_REASON', anything),
        ),
      );
    },
  );

  test(
    'run-program --json prefers D3DMetal over stale DXMT settings on macOS',
    () {
      final tempDirectory = Directory.systemTemp.createTempSync(
        'konyak-d3dmetal-run-stale-dxmt-test-',
      );
      addTearDown(() {
        if (tempDirectory.existsSync()) {
          tempDirectory.deleteSync(recursive: true);
        }
      });

      final runtimeRoot = joinTestPath(tempDirectory.path, const ['runtime']);
      final bottlePath = joinTestPath(tempDirectory.path, const [
        'bottles',
        'steam',
      ]);
      for (final dllName in gptkD3DMetalOverrideDllNames) {
        final file = File(
          joinTestPath(runtimeRoot, [
            'components',
            'gptk-d3dmetal',
            'lib',
            'wine',
            'x86_64-windows',
            dllName,
          ]),
        );
        file.parent.createSync(recursive: true);
        file.writeAsStringSync('d3dmetal/$dllName');
      }

      final repository = MemoryBottleRepository(
        programMetadataExtractor: const NoopProgramMetadataExtractor(),
        dataHome: joinTestPath(tempDirectory.path, const ['data']),
        bottles: [
          BottleRecord(
            id: 'steam',
            name: 'Steam',
            path: bottlePath,
            windowsVersion: 'win10',
            runtimeSettings: Option.of(
              BottleRuntimeSettings(dxrEnabled: true, dxmt: true),
            ),
          ),
        ],
      );
      final runner = RecordingProgramRunner(
        result: const ProgramRunCompleted(processExitCode: 0),
      );

      final result = runCli(
        [
          'run-program',
          'steam',
          '--program',
          '/Applications/Steam/steam.exe',
          '--json',
        ],
        bottleRepository: repository,
        programRunPlanner: ProgramRunPlanner(
          hostPlatform: KonyakHostPlatform.macos,
          environment: HostEnvironment({'KONYAK_MACOS_WINE_HOME': runtimeRoot}),
        ),
        programRunner: runner,
      );

      expect(result.exitCode, 0);
      final environment = runner.lastRequest?.environment.toMap();
      expect(
        environment?['WINEDLLOVERRIDES'],
        'dxgi,d3d11,d3d12,nvapi64,nvngx=n,b',
      );
      expect(
        environment?['WINEDLLPATH'],
        macosManagedWineDllPathWithOverrides(runtimeRoot, const [
          <String>[
            'components',
            'gptk-d3dmetal',
            'lib',
            'wine',
            'x86_64-windows',
          ],
        ]),
      );
      expect(
        environment?['WINEPATH'],
        macosManagedWinePathWithOverrides(runtimeRoot, const [
          <String>[
            'components',
            'gptk-d3dmetal',
            'lib',
            'wine',
            'x86_64-windows',
          ],
        ]),
      );
      expect(
        environment?['DYLD_LIBRARY_PATH'],
        '$runtimeRoot/components/gptk-d3dmetal/lib/external:'
        '$runtimeRoot/components/gptk-d3dmetal/lib/wine/x86_64-unix:'
        '$runtimeRoot/lib',
      );
      expect(
        environment?['DYLD_FRAMEWORK_PATH'],
        '$runtimeRoot/components/gptk-d3dmetal/lib/external',
      );
      expect(
        environment?['CX_APPLEGPTK_LIBD3DSHARED_PATH'],
        '$runtimeRoot/components/gptk-d3dmetal/lib/external/'
        'libd3dshared.dylib',
      );
    },
  );

  test('run-program --json repairs stale macOS D3DMetal DLL overrides', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-d3dmetal-run-repair-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    final runtimeRoot = joinTestPath(tempDirectory.path, const ['runtime']);
    final bottlePath = joinTestPath(tempDirectory.path, const [
      'bottles',
      'steam',
    ]);
    for (final dllName in gptkD3DMetalOverrideDllNames) {
      final file = File(
        joinTestPath(runtimeRoot, [
          'components',
          'gptk-d3dmetal',
          'lib',
          'wine',
          'x86_64-windows',
          dllName,
        ]),
      );
      file.parent.createSync(recursive: true);
      file.writeAsStringSync('d3dmetal/$dllName');
    }
    for (final dllName in gptkD3DMetalOverrideDllNames) {
      final file = File(
        joinTestPath(bottlePath, ['drive_c', 'windows', 'system32', dllName]),
      );
      file.parent.createSync(recursive: true);
      file.writeAsStringSync('stale $dllName');
    }

    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: joinTestPath(tempDirectory.path, const ['data']),
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: bottlePath,
          windowsVersion: 'win10',
          runtimeSettings: Option.of(BottleRuntimeSettings(dxrEnabled: true)),
        ),
      ],
    );
    final runner = RecordingProgramRunner(
      result: const ProgramRunCompleted(processExitCode: 0),
    );

    final result = runCli(
      const [
        'run-program',
        'steam',
        '--program',
        '/downloads/setup.exe',
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
        environment: HostEnvironment({'KONYAK_MACOS_WINE_HOME': runtimeRoot}),
      ),
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    for (final dllName in gptkD3DMetalOverrideDllNames) {
      expect(
        File(
          joinTestPath(bottlePath, ['drive_c', 'windows', 'system32', dllName]),
        ).readAsStringSync(),
        'd3dmetal/$dllName',
      );
    }
  });

  test('run-program --json enables D3DMetal DLSS MetalFX on macOS 16', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-d3dmetal-dlss-metalfx-run-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    final runtimeRoot = joinTestPath(tempDirectory.path, const ['runtime']);
    final bottlePath = joinTestPath(tempDirectory.path, const [
      'bottles',
      'steam',
    ]);
    for (final dllName in gptkD3DMetalOverrideDllNames) {
      final file = File(
        joinTestPath(runtimeRoot, [
          'components',
          'gptk-d3dmetal',
          'lib',
          'wine',
          'x86_64-windows',
          dllName,
        ]),
      );
      file.parent.createSync(recursive: true);
      file.writeAsStringSync('d3dmetal/$dllName');
    }

    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: joinTestPath(tempDirectory.path, const ['data']),
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: bottlePath,
          windowsVersion: 'win10',
          runtimeSettings: Option.of(
            BottleRuntimeSettings(dxrEnabled: true, dlssMetalFx: true),
          ),
        ),
      ],
    );
    final runner = RecordingProgramRunner(
      result: const ProgramRunCompleted(processExitCode: 0),
    );

    final result = runCli(
      const [
        'run-program',
        'steam',
        '--program',
        '/downloads/setup.exe',
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
        environment: HostEnvironment({'KONYAK_MACOS_WINE_HOME': runtimeRoot}),
        macosMajorVersion: Option.of(MacosMajorVersion(16)),
      ),
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair('D3DM_ENABLE_METALFX', '1'),
    );
  });

  test('run-program --json skips D3DMetal DLSS MetalFX before macOS 16', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-d3dmetal-dlss-metalfx-macos15-run-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    final runtimeRoot = joinTestPath(tempDirectory.path, const ['runtime']);
    final bottlePath = joinTestPath(tempDirectory.path, const [
      'bottles',
      'steam',
    ]);
    for (final dllName in gptkD3DMetalOverrideDllNames) {
      final file = File(
        joinTestPath(runtimeRoot, [
          'components',
          'gptk-d3dmetal',
          'lib',
          'wine',
          'x86_64-windows',
          dllName,
        ]),
      );
      file.parent.createSync(recursive: true);
      file.writeAsStringSync('d3dmetal/$dllName');
    }

    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: joinTestPath(tempDirectory.path, const ['data']),
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: bottlePath,
          windowsVersion: 'win10',
          runtimeSettings: Option.of(
            BottleRuntimeSettings(dxrEnabled: true, dlssMetalFx: true),
          ),
        ),
      ],
    );
    final runner = RecordingProgramRunner(
      result: const ProgramRunCompleted(processExitCode: 0),
    );

    final result = runCli(
      const [
        'run-program',
        'steam',
        '--program',
        '/downloads/setup.exe',
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
        environment: HostEnvironment({'KONYAK_MACOS_WINE_HOME': runtimeRoot}),
        macosMajorVersion: Option.of(MacosMajorVersion(15)),
      ),
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(
      runner.lastRequest?.environment.toMap(),
      isNot(containsPair('D3DM_ENABLE_METALFX', '1')),
    );
  });

  test('run-program --json applies DXMT settings on macOS', () {
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: '/Users/user/Library/Application Support/Konyak',
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: '/Users/user/Library/Application Support/Konyak/Bottles/Steam',
          windowsVersion: 'win10',
          runtimeSettings: Option.of(BottleRuntimeSettings(dxmt: true)),
        ),
      ],
    );
    final runner = RecordingProgramRunner(
      result: const ProgramRunCompleted(processExitCode: 0),
    );

    final result = runCli(
      const [
        'run-program',
        'steam',
        '--program',
        '/downloads/setup.exe',
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
        environment: HostEnvironment({'HOME': '/Users/user'}),
      ),
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair('WINEDLLOVERRIDES', 'dxgi,d3d10core,d3d11,winemetal=n,b'),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair(
        'WINEDLLPATH',
        macosManagedWineDllPathWithOverrides(
          '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine',
          const [
            ['lib', 'dxmt', 'x86_64-windows'],
            ['lib', 'dxmt', 'i386-windows'],
          ],
        ),
      ),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair(
        'WINEPATH',
        macosManagedWinePathWithOverrides(
          '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine',
          const [
            ['lib', 'dxmt', 'x86_64-windows'],
            ['lib', 'dxmt', 'i386-windows'],
          ],
        ),
      ),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair(
        'DYLD_LIBRARY_PATH',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/dxmt/x86_64-unix:'
            '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib',
      ),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      isNot(containsPair('DXMT_ENABLE_NVEXT', '1')),
    );
  });

  test('run-program --json enables DXMT NVEXT for DLSS MetalFX on macOS', () {
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: '/Users/user/Library/Application Support/Konyak',
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: '/Users/user/Library/Application Support/Konyak/Bottles/Steam',
          windowsVersion: 'win10',
          runtimeSettings: Option.of(
            BottleRuntimeSettings(dxmt: true, dlssMetalFx: true),
          ),
        ),
      ],
    );
    final runner = RecordingProgramRunner(
      result: const ProgramRunCompleted(processExitCode: 0),
    );

    final result = runCli(
      const [
        'run-program',
        'steam',
        '--program',
        '/downloads/setup.exe',
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
        environment: HostEnvironment({'HOME': '/Users/user'}),
      ),
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair('DXMT_ENABLE_NVEXT', '1'),
    );
  });

  test('run-program --json applies DXVK settings on Linux', () {
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: '/home/user/.local/share/konyak',
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: '/home/user/.local/share/konyak/bottles/steam',
          windowsVersion: 'win10',
          runtimeSettings: Option.of(
            BottleRuntimeSettings(
              enhancedSync: EnhancedSyncMode('msync'),
              dxvk: true,
              dlssMetalFx: true,
              dxvkHud: DxvkHudMode('fps'),
            ),
          ),
        ),
      ],
    );
    final runner = RecordingProgramRunner(
      result: const ProgramRunCompleted(processExitCode: 0),
    );

    final result = runCli(
      const [
        'run-program',
        'steam',
        '--program',
        '/downloads/setup.exe',
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.linux,
        environment: HostEnvironment(const {
          'HOME': '/home/user',
          'KONYAK_LINUX_WINE_HOME': '/runtime/linux-wine',
        }),
      ),
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair('WINEMSYNC', '1'),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      isNot(containsPair('WINEESYNC', '1')),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair('DXVK_HUD', 'fps'),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      isNot(containsPair('DXMT_ENABLE_NVEXT', '1')),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      isNot(containsPair('D3DM_ENABLE_METALFX', '1')),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair('DXVK_ASYNC', '1'),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair(
        'WINEDLLOVERRIDES',
        'dxgi=n,b;d3d9=n,b;d3d10=n,b;d3d10_1=n,b;d3d10core=n,b;d3d11=n,b',
      ),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair(
        'WINEDLLPATH',
        '/runtime/linux-wine/dxvk/x64:/runtime/linux-wine/dxvk/x86',
      ),
    );
  });

  test('run-program --json applies vkd3d-proton settings on Linux', () {
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: '/home/user/.local/share/konyak',
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: '/home/user/.local/share/konyak/bottles/steam',
          windowsVersion: 'win10',
          runtimeSettings: Option.of(
            BottleRuntimeSettings(
              enhancedSync: EnhancedSyncMode('msync'),
              vkd3dProton: true,
            ),
          ),
        ),
      ],
    );
    final runner = RecordingProgramRunner(
      result: const ProgramRunCompleted(processExitCode: 0),
    );

    final result = runCli(
      const [
        'run-program',
        'steam',
        '--program',
        '/downloads/setup.exe',
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.linux,
        environment: HostEnvironment(const {
          'HOME': '/home/user',
          'KONYAK_LINUX_WINE_HOME': '/runtime/linux-wine',
        }),
      ),
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair('WINEMSYNC', '1'),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      isNot(containsPair('WINEESYNC', '1')),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair('WINEDLLOVERRIDES', 'd3d12=n,b;d3d12core=n,b'),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair(
        'WINEDLLPATH',
        '/runtime/linux-wine/vkd3d-proton/x64:/runtime/linux-wine/vkd3d-proton/x86',
      ),
    );
  });

  test('run-bottle-command --json launches winecfg through macOS Wine', () {
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: '/Users/user/Library/Application Support/Konyak',
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: '/Users/user/Library/Application Support/Konyak/Bottles/Steam',
          windowsVersion: 'win10',
        ),
      ],
    );
    final runner = RecordingProgramRunner(
      result: const ProgramRunCompleted(processExitCode: 0),
    );

    final result = runCli(
      const ['run-bottle-command', 'steam', '--command', 'winecfg', '--json'],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
        environment: HostEnvironment({'HOME': '/Users/user'}),
      ),
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(
      runner.lastRequest?.executable.value,
      '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wineloader',
    );
    expect(runner.lastRequest?.arguments, const ['winecfg']);
    expect(runner.lastRequest?.programPath.value, 'winecfg');
    expect(runner.lastRequest?.runnerKind.value, 'macosWine');
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair(
        'WINEPREFIX',
        '/Users/user/Library/Application Support/Konyak/Bottles/Steam',
      ),
    );

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'run': {
        'bottleId': 'steam',
        'programPath': 'winecfg',
        'runnerKind': 'macosWine',
        'executable':
            '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wineloader',
        'workingDirectory':
            '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin',
        'argv': [
          '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wineloader',
          'winecfg',
        ],
        'logPath':
            '/Users/user/Library/Application Support/Konyak/Bottles/Steam/logs/latest.log',
        'logFileCreated': true,
        'processExitCode': 0,
      },
    });
  });

  test('prefix initialization uses Konyak macOS Wine on macOS', () {
    final bottle = BottleRecord(
      id: 'steam',
      name: 'Steam',
      path: '/Users/user/Library/Application Support/Konyak/Bottles/Steam',
      windowsVersion: 'win10',
    );
    final request = ProgramRunPlanner(
      hostPlatform: KonyakHostPlatform.macos,
      environment: HostEnvironment(const {'HOME': '/Users/user'}),
    ).planPrefixInitialization(bottle: bottle);

    expect(
      request.executable.value,
      '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wineloader',
    );
    expect(request.arguments.value, const ['wineboot', '--init']);
    expect(request.programPath.value, 'wineboot');
    expect(request.runnerKind.value, 'macosWine');
    expect(
      request.workingDirectory.toNullable()?.value,
      '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin',
    );
    expect(
      request.environment.toMap(),
      containsPair(
        'WINEPREFIX',
        '/Users/user/Library/Application Support/Konyak/Bottles/Steam',
      ),
    );
    expect(
      request.environment.toMap(),
      containsPair(
        'WINEDATADIR',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/share/wine',
      ),
    );
    expect(
      request.environment.toMap(),
      isNot(containsPair('WINEDLLOVERRIDES', 'mscoree,mshtml=')),
    );
    expect(
      request.logPath.value,
      '/Users/user/Library/Application Support/Konyak/Bottles/Steam/logs/prefix-init.log',
    );
  });

  test('macOS prefix bootstrap silently installs Wine Mono before wineboot', () {
    final bottle = BottleRecord(
      id: 'steam',
      name: 'Steam',
      path: '/Users/user/Library/Application Support/Konyak/Bottles/Steam',
      windowsVersion: 'win10',
    );
    final requests = ProgramRunPlanner(
      hostPlatform: KonyakHostPlatform.macos,
      environment: HostEnvironment(const {'HOME': '/Users/user'}),
    ).planPrefixBootstrap(bottle: bottle);

    expect(requests, hasLength(2));

    final monoInstall = requests.first;
    expect(
      monoInstall.executable.value,
      '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wineloader',
    );
    expect(monoInstall.arguments, const [
      'msiexec',
      '/i',
      r'Z:\Users\user\Library\Application Support\Konyak\Runtimes\macos-wine\share\wine\mono\wine-mono-10.4.1-x86.msi',
      '/qn',
      '/norestart',
    ]);
    expect(monoInstall.programPath.value, 'wine-mono');
    expect(monoInstall.runnerKind.value, 'macosWine');
    expect(
      monoInstall.workingDirectory.toNullable()?.value,
      '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin',
    );
    expect(
      monoInstall.environment.toMap(),
      containsPair(
        'WINEPREFIX',
        '/Users/user/Library/Application Support/Konyak/Bottles/Steam',
      ),
    );
    expect(
      monoInstall.environment.toMap(),
      containsPair(
        'WINEDATADIR',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/share/wine',
      ),
    );
    expect(
      monoInstall.environment.toMap(),
      isNot(containsPair('WINEDLLOVERRIDES', 'mscoree,mshtml=')),
    );
    expect(
      monoInstall.logPath.value,
      '/Users/user/Library/Application Support/Konyak/Bottles/Steam/logs/wine-mono-install.log',
    );

    final wineboot = requests.last;
    expect(wineboot.programPath.value, 'wineboot');
    expect(wineboot.arguments, const ['wineboot', '--init']);
    expect(
      wineboot.logPath.value,
      '/Users/user/Library/Application Support/Konyak/Bottles/Steam/logs/prefix-init.log',
    );
  });

  test('bottle prefix initializer runs bootstrap requests in order', () {
    final bottle = BottleRecord(
      id: 'steam',
      name: 'Steam',
      path: '/Users/user/Library/Application Support/Konyak/Bottles/Steam',
      windowsVersion: 'win10',
    );
    final runner = RecordingProgramRunner(
      results: const [
        ProgramRunCompleted(processExitCode: 0),
        ProgramRunCompleted(processExitCode: 0),
      ],
    );
    final initializer = DartIoBottlePrefixInitializer(
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
        environment: HostEnvironment(const {'HOME': '/Users/user'}),
      ),
      programRunner: runner,
    );

    final result = initializer.initialize(bottle);

    expect(result, isA<BottlePrefixInitialized>());
    expect(runner.requests.map((request) => request.programPath.value), const [
      'wine-mono',
      'wineboot',
    ]);
  });

  test('bottle prefix initializer stops when Wine Mono install fails', () {
    final bottle = BottleRecord(
      id: 'steam',
      name: 'Steam',
      path: '/Users/user/Library/Application Support/Konyak/Bottles/Steam',
      windowsVersion: 'win10',
    );
    final runner = RecordingProgramRunner(
      results: const [
        ProgramRunCompleted(processExitCode: 42),
        ProgramRunCompleted(processExitCode: 0),
      ],
    );
    final initializer = DartIoBottlePrefixInitializer(
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
        environment: HostEnvironment(const {'HOME': '/Users/user'}),
      ),
      programRunner: runner,
    );

    final result = initializer.initialize(bottle);

    final failure = result as BottlePrefixInitializationFailed;
    expect(
      failure.message,
      'wine-mono exited with code 42. '
      'See /Users/user/Library/Application Support/Konyak/Bottles/Steam/logs/wine-mono-install.log.',
    );
    expect(runner.requests, hasLength(1));
    expect(runner.requests.single.programPath.value, 'wine-mono');
  });

  test('run-bottle-command --json opens a macOS bottle terminal', () {
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: '/Users/user/Library/Application Support/Konyak',
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: '/Users/user/Library/Application Support/Konyak/Bottles/Steam',
          windowsVersion: 'win10',
        ),
      ],
    );
    final runner = RecordingProgramRunner(
      result: const ProgramRunCompleted(processExitCode: 0),
    );

    final result = runCli(
      const ['run-bottle-command', 'steam', '--command', 'terminal', '--json'],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
        environment: HostEnvironment({'HOME': '/Users/user'}),
      ),
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(runner.lastRequest?.runnerKind.value, 'macosTerminal');
    expect(runner.lastRequest?.programPath.value, 'terminal');
    expect(runner.lastRequest?.executable.value, '/usr/bin/osascript');
    expect(runner.lastRequest?.arguments.first, '-e');
    expect(runner.lastRequest?.arguments.last, contains('Terminal'));
    expect(runner.lastRequest?.arguments.last, contains('WINEPREFIX'));
    expect(
      runner.lastRequest?.arguments.last,
      contains('/Users/user/Library/Application Support/Konyak/Bottles/Steam'),
    );
    expect(
      runner.lastRequest?.arguments.last,
      contains(
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin',
      ),
    );
    expect(runner.lastRequest?.arguments.last, contains('alias wine'));
    expect(
      runner.lastRequest?.arguments.last,
      contains(
        "export WINE='/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wineloader'",
      ),
    );
    expect(runner.lastRequest?.arguments.last, contains('set setupText to "'));
    expect(
      runner.lastRequest?.arguments.last,
      contains(
        "GST_REGISTRY='/Users/user/Library/Application Support/Konyak/Bottles/Steam/gstreamer-1.0-registry.x86_64.bin'",
      ),
    );
    expect(
      runner.lastRequest?.arguments.last,
      contains("MVK_CONFIG_LOG_LEVEL='0'"),
    );
    expect(runner.lastRequest?.arguments.last, contains('do script "source '));
    final terminalCommand = singleAppleScriptDoScriptCommand(
      runner.lastRequest!.arguments.last,
    );
    expect(terminalCommand, contains('konyak-terminal-setup.zsh'));
    expect(terminalCommand, isNot(contains('GST_REGISTRY')));

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    final run = payload['run'] as Map<String, Object?>;
    expect(payload['schemaVersion'], 1);
    expect(run['bottleId'], 'steam');
    expect(run['programPath'], 'terminal');
    expect(run['runnerKind'], 'macosTerminal');
    expect(run['executable'], '/usr/bin/osascript');
    expect(run['processExitCode'], 0);
  });

  test('run-bottle-command --json opens a Linux bottle terminal', () {
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: '/home/user/.local/share/konyak',
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: '/home/user/.local/share/konyak/bottles/steam',
          windowsVersion: 'win10',
        ),
      ],
    );
    final runner = RecordingProgramRunner(
      result: const ProgramRunCompleted(processExitCode: 0),
    );

    final result = runCli(
      const ['run-bottle-command', 'steam', '--command', 'terminal', '--json'],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.linux,
        environment: HostEnvironment({
          'HOME': '/home/user',
          'KONYAK_LINUX_WINE_HOME': '/runtime',
          'KONYAK_LINUX_WINE_LIBRARY_PATH': '/runtime-host-libs',
        }),
      ),
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(runner.lastRequest?.runnerKind.value, 'terminal');
    expect(runner.lastRequest?.programPath.value, 'terminal');
    expect(runner.lastRequest?.executable.value, 'sh');
    expect(runner.lastRequest?.arguments, hasLength(3));
    expect(runner.lastRequest?.arguments.first, '-lc');
    expect(runner.lastRequest?.arguments[1], contains('x-terminal-emulator'));
    expect(runner.lastRequest?.arguments[1], contains('kgx'));
    expect(runner.lastRequest?.arguments[1], contains('gnome-terminal'));
    expect(runner.lastRequest?.arguments[1], contains('konsole'));
    expect(runner.lastRequest?.arguments[1], isNot(contains('fi if')));
    expect(runner.lastRequest?.arguments[1], contains('fi\nif'));
    expect(
      runner.lastRequest?.arguments.last,
      contains('/home/user/.local/share/konyak/bottles/steam'),
    );
    expect(runner.lastRequest?.arguments.last, contains('WINEPREFIX'));
    expect(
      runner.lastRequest?.arguments.last,
      contains("export WINE='/runtime/bin/wine'"),
    );
    expect(
      runner.lastRequest?.arguments.last,
      contains("export PATH='/runtime/bin':\$PATH"),
    );
    expect(
      runner.lastRequest?.arguments.last,
      contains("alias wine64='/runtime/bin/wine'"),
    );
    expect(
      runner.lastRequest?.arguments.last,
      contains("LD_LIBRARY_PATH='/runtime-host-libs'"),
    );
    expect(
      runner.lastRequest?.arguments.last,
      contains("export EGL_LOG_LEVEL='fatal'"),
    );
    expect(
      runner.lastRequest?.arguments.last,
      contains("export MESA_LOG_LEVEL='fatal'"),
    );
    expect(
      runner.lastRequest?.arguments.last,
      contains("export MESA_DEBUG='silent'"),
    );
    expect(
      runner.lastRequest?.arguments.last,
      contains('exec bash --noprofile --rcfile'),
    );
    expect(runner.lastRequest?.arguments.last, isNot(contains('exec bash -l')));

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    final run = payload['run'] as Map<String, Object?>;
    expect(payload['schemaVersion'], 1);
    expect(run['bottleId'], 'steam');
    expect(run['programPath'], 'terminal');
    expect(run['runnerKind'], 'terminal');
    expect(run['executable'], 'sh');
    expect(run['processExitCode'], 0);
  });

  test(
    'run-bottle-command --json opens Command Prompt in a Linux terminal',
    () {
      final repository = MemoryBottleRepository(
        programMetadataExtractor: const NoopProgramMetadataExtractor(),
        dataHome: '/home/user/.local/share/konyak',
        bottles: [
          BottleRecord(
            id: 'steam',
            name: 'Steam',
            path: '/home/user/.local/share/konyak/bottles/steam',
            windowsVersion: 'win10',
          ),
        ],
      );
      final runner = RecordingProgramRunner(
        result: const ProgramRunCompleted(processExitCode: 0),
      );

      final result = runCli(
        const ['run-bottle-command', 'steam', '--command', 'cmd', '--json'],
        bottleRepository: repository,
        programRunPlanner: ProgramRunPlanner(
          hostPlatform: KonyakHostPlatform.linux,
          environment: HostEnvironment({
            'HOME': '/home/user',
            'KONYAK_LINUX_WINE_HOME': '/runtime',
            'KONYAK_LINUX_WINE_LIBRARY_PATH': '/runtime-host-libs',
          }),
        ),
        programRunner: runner,
      );

      expect(result.exitCode, 0);
      expect(runner.lastRequest?.runnerKind.value, 'terminal');
      expect(runner.lastRequest?.programPath.value, 'cmd');
      expect(runner.lastRequest?.executable.value, 'sh');
      expect(runner.lastRequest?.arguments.last, contains('/runtime/bin/wine'));
      expect(runner.lastRequest?.arguments.last, contains("'cmd'"));
      expect(
        runner.lastRequest?.arguments.last,
        contains("export EGL_LOG_LEVEL='fatal'"),
      );
      expect(
        runner.lastRequest?.arguments.last,
        contains("export MESA_LOG_LEVEL='fatal'"),
      );
      expect(
        runner.lastRequest?.arguments.last,
        contains("export MESA_DEBUG='silent'"),
      );

      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      final run = payload['run'] as Map<String, Object?>;
      expect(payload['schemaVersion'], 1);
      expect(run['bottleId'], 'steam');
      expect(run['programPath'], 'cmd');
      expect(run['runnerKind'], 'terminal');
      expect(run['executable'], 'sh');
      expect(run['processExitCode'], 0);
    },
  );

  test('Linux planner uses a configured Konyak-managed runtime', () {
    final bottle = BottleRecord(
      id: 'steam',
      name: 'Steam',
      path: '/home/user/.local/share/konyak/bottles/steam',
      windowsVersion: 'win10',
    );

    final request =
        ProgramRunPlanner(
          hostPlatform: KonyakHostPlatform.linux,
          environment: HostEnvironment(const {
            'HOME': '/home/user',
            'PATH': '/usr/bin:/bin',
            'LD_LIBRARY_PATH': '/host/lib',
            'KONYAK_LINUX_WINE_HOME': '/opt/konyak/runtime/linux-wine',
            'KONYAK_LINUX_WINE_LIBRARY_PATH': '/opt/konyak/runtime-host-libs',
          }),
        ).plan(
          bottle: bottle,
          programPath: ProgramPath('C:/Program Files/Steam/steam.exe'),
        );

    expect(request.isSome(), isTrue);
    final plannedRequest = request.toNullable();
    expect(
      plannedRequest?.executable.value,
      '/opt/konyak/runtime/linux-wine/bin/wine',
    );
    expect(
      plannedRequest?.environment.toMap(),
      containsPair('PATH', '/opt/konyak/runtime/linux-wine/bin:/usr/bin:/bin'),
    );
    expect(
      plannedRequest?.environment.toMap(),
      containsPair(
        'LD_LIBRARY_PATH',
        '/opt/konyak/runtime-host-libs:/host/lib',
      ),
    );
    expect(
      plannedRequest?.environment.toMap(),
      containsPair(
        'WINEPREFIX',
        '/home/user/.local/share/konyak/bottles/steam',
      ),
    );
    expect(
      plannedRequest?.environment.toMap(),
      containsPair('EGL_LOG_LEVEL', 'fatal'),
    );
    expect(
      plannedRequest?.environment.toMap(),
      containsPair('MESA_LOG_LEVEL', 'fatal'),
    );
    expect(
      plannedRequest?.environment.toMap(),
      containsPair('MESA_DEBUG', 'silent'),
    );
  });

  test('run-bottle-command --json launches winetricks with bottle env', () {
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: '/Users/user/Library/Application Support/Konyak',
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: '/Users/user/Library/Application Support/Konyak/Bottles/Steam',
          windowsVersion: 'win10',
        ),
      ],
    );
    final runner = RecordingProgramRunner(
      result: const ProgramRunCompleted(processExitCode: 0),
    );

    final result = runCli(
      const [
        'run-bottle-command',
        'steam',
        '--command',
        'winetricks',
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
        environment: HostEnvironment({'HOME': '/Users/user'}),
      ),
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(runner.lastRequest?.runnerKind.value, 'macosWinetricks');
    expect(runner.lastRequest?.programPath.value, 'winetricks');
    expect(
      runner.lastRequest?.executable.value,
      '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/winetricks',
    );
    expect(runner.lastRequest?.arguments, isEmpty);
    expect(
      runner.lastRequest?.workingDirectory.toNullable()?.value,
      '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine',
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair(
        'WINEPREFIX',
        '/Users/user/Library/Application Support/Konyak/Bottles/Steam',
      ),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair(
        'WINE',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wineloader',
      ),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair(
        'PATH',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin',
      ),
    );

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    final run = payload['run'] as Map<String, Object?>;
    expect(payload['schemaVersion'], 1);
    expect(run['bottleId'], 'steam');
    expect(run['programPath'], 'winetricks');
    expect(run['runnerKind'], 'macosWinetricks');
    expect(
      run['executable'],
      '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/winetricks',
    );
    expect(run['processExitCode'], 0);
  });

  test('run-bottle-command --json launches allowlisted Wine utilities', () {
    const commandIds = <String>['uninstaller', 'taskmgr', 'explorer', 'winver'];

    for (final commandId in commandIds) {
      final repository = MemoryBottleRepository(
        programMetadataExtractor: const NoopProgramMetadataExtractor(),
        dataHome: '/Users/user/Library/Application Support/Konyak',
        bottles: [
          BottleRecord(
            id: 'steam',
            name: 'Steam',
            path:
                '/Users/user/Library/Application Support/Konyak/Bottles/Steam',
            windowsVersion: 'win10',
          ),
        ],
      );
      final runner = RecordingProgramRunner(
        result: const ProgramRunCompleted(processExitCode: 0),
      );

      final result = runCli(
        ['run-bottle-command', 'steam', '--command', commandId, '--json'],
        bottleRepository: repository,
        programRunPlanner: ProgramRunPlanner(
          hostPlatform: KonyakHostPlatform.macos,
          environment: HostEnvironment({'HOME': '/Users/user'}),
        ),
        programRunner: runner,
      );

      expect(result.exitCode, 0, reason: commandId);
      expect(
        runner.lastRequest?.runnerKind.value,
        'macosWine',
        reason: commandId,
      );
      expect(
        runner.lastRequest?.programPath.value,
        commandId,
        reason: commandId,
      );
      expect(runner.lastRequest?.arguments, [commandId], reason: commandId);
    }
  });

  test('run-bottle-command --json simulates a Windows reboot on macOS', () {
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: '/Users/user/Library/Application Support/Konyak',
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: '/Users/user/Library/Application Support/Konyak/Bottles/Steam',
          windowsVersion: 'win10',
        ),
      ],
    );
    final runner = RecordingProgramRunner(
      result: const ProgramRunCompleted(processExitCode: 0),
    );

    final result = runCli(
      const [
        'run-bottle-command',
        'steam',
        '--command',
        'simulate-reboot',
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
        environment: HostEnvironment({'HOME': '/Users/user'}),
      ),
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(runner.lastRequest?.programPath.value, 'wineboot');
    expect(runner.lastRequest?.runnerKind.value, 'macosWine');
    expect(runner.lastRequest?.arguments, const ['wineboot', '--restart']);
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair(
        'WINEPREFIX',
        '/Users/user/Library/Application Support/Konyak/Bottles/Steam',
      ),
    );

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload['schemaVersion'], 1);
    final run = payload['run'] as Map<String, Object?>;
    expect(run['programPath'], 'wineboot');
    expect(run['runnerKind'], 'macosWine');
    expect(run['argv'], [
      '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wineloader',
      'wineboot',
      '--restart',
    ]);
    expect(run['processExitCode'], 0);
  });

  test('run-bottle-command --json simulates a Windows reboot on Linux', () {
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: '/home/user/.local/share/konyak',
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: '/home/user/.local/share/konyak/bottles/steam',
          windowsVersion: 'win10',
        ),
      ],
    );
    final runner = RecordingProgramRunner(
      result: const ProgramRunCompleted(processExitCode: 0),
    );

    final result = runCli(
      const [
        'run-bottle-command',
        'steam',
        '--command',
        'simulate-reboot',
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.linux,
        environment: HostEnvironment({
          'HOME': '/home/user',
          'KONYAK_LINUX_WINE_HOME': '/runtime/linux-wine',
        }),
      ),
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(runner.lastRequest?.programPath.value, 'wineboot');
    expect(runner.lastRequest?.runnerKind.value, 'wineboot');
    expect(runner.lastRequest?.arguments, const ['--restart']);
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair(
        'WINEPREFIX',
        '/home/user/.local/share/konyak/bottles/steam',
      ),
    );
  });

  test('run-bottle-command --json opens the DirectX diagnostic report', () {
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: '/Users/user/Library/Application Support/Konyak',
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: '/Users/user/Library/Application Support/Konyak/Bottles/Steam',
          windowsVersion: 'win10',
        ),
      ],
    );
    final runner = RecordingProgramRunner(
      result: const ProgramRunCompleted(processExitCode: 0),
    );

    final result = runCli(
      const ['run-bottle-command', 'steam', '--command', 'dxdiag', '--json'],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
        environment: HostEnvironment({'HOME': '/Users/user'}),
      ),
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(runner.lastRequest?.runnerKind.value, 'macosWine');
    expect(runner.lastRequest?.programPath.value, 'dxdiag');
    expect(runner.lastRequest?.arguments, const [
      'cmd',
      '/c',
      'dxdiag /t C:\\konyak-dxdiag.txt && start "" notepad C:\\konyak-dxdiag.txt',
    ]);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    final run = payload['run'] as Map<String, Object?>;
    expect(payload['schemaVersion'], 1);
    expect(run['bottleId'], 'steam');
    expect(run['programPath'], 'dxdiag');
    expect(run['runnerKind'], 'macosWine');
    expect(run['processExitCode'], 0);
  });

  test(
    'run-bottle-command --json opens Command Prompt in a macOS terminal',
    () {
      final repository = MemoryBottleRepository(
        programMetadataExtractor: const NoopProgramMetadataExtractor(),
        dataHome: '/Users/user/Library/Application Support/Konyak',
        bottles: [
          BottleRecord(
            id: 'steam',
            name: 'Steam',
            path:
                '/Users/user/Library/Application Support/Konyak/Bottles/Steam',
            windowsVersion: 'win10',
          ),
        ],
      );
      final runner = RecordingProgramRunner(
        result: const ProgramRunCompleted(processExitCode: 0),
      );

      final result = runCli(
        const ['run-bottle-command', 'steam', '--command', 'cmd', '--json'],
        bottleRepository: repository,
        programRunPlanner: ProgramRunPlanner(
          hostPlatform: KonyakHostPlatform.macos,
          environment: HostEnvironment({'HOME': '/Users/user'}),
        ),
        programRunner: runner,
      );

      expect(result.exitCode, 0);
      expect(runner.lastRequest?.runnerKind.value, 'macosTerminal');
      expect(runner.lastRequest?.programPath.value, 'cmd');
      expect(runner.lastRequest?.executable.value, '/usr/bin/osascript');
      expect(runner.lastRequest?.arguments.first, '-e');
      expect(runner.lastRequest?.arguments.last, contains('Terminal'));
      expect(runner.lastRequest?.arguments.last, contains('WINEPREFIX'));
      expect(
        runner.lastRequest?.arguments.last,
        contains(
          '/Users/user/Library/Application Support/Konyak/Bottles/Steam',
        ),
      );
      expect(runner.lastRequest?.arguments.last, contains('wineloader'));
      expect(runner.lastRequest?.arguments.last, contains('cmd'));
      expect(
        runner.lastRequest?.arguments.last,
        contains("MVK_CONFIG_LOG_LEVEL='0'"),
      );

      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      final run = payload['run'] as Map<String, Object?>;
      expect(payload['schemaVersion'], 1);
      expect(run['bottleId'], 'steam');
      expect(run['programPath'], 'cmd');
      expect(run['runnerKind'], 'macosTerminal');
      expect(run['executable'], '/usr/bin/osascript');
      expect(run['processExitCode'], 0);
    },
  );

  test('list-winetricks-verbs --json returns parsed runtime verbs', () async {
    final runtimeRoot = await Directory.systemTemp.createTemp(
      'konyak-winetricks-verbs-test-',
    );
    addTearDown(() async {
      if (await runtimeRoot.exists()) {
        await runtimeRoot.delete(recursive: true);
      }
    });

    File(joinTestPath(runtimeRoot.path, const ['verbs.txt']))
      ..createSync(recursive: true)
      ..writeAsStringSync('''
===== apps =====
steam                    Steam Client

===== dlls =====
corefonts                Microsoft Core Fonts
d3dx9                    DirectX 9 libraries
===== unknown =====
ignored                  Should not be listed
''');

    final result = runCli(
      const ['list-winetricks-verbs', '--json'],
      winetricksVerbRepository: DartIoWinetricksVerbRepository(
        runtimeRoot: runtimeRoot.path,
      ),
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'winetricks': {
        'categories': [
          {
            'id': 'apps',
            'name': 'Apps',
            'verbs': [
              {'id': 'steam', 'name': 'steam', 'description': 'Steam Client'},
            ],
          },
          {
            'id': 'dlls',
            'name': 'DLLs',
            'verbs': [
              {
                'id': 'corefonts',
                'name': 'corefonts',
                'description': 'Microsoft Core Fonts',
              },
              {
                'id': 'd3dx9',
                'name': 'd3dx9',
                'description': 'DirectX 9 libraries',
              },
            ],
          },
        ],
      },
    });
  });

  test('list-winetricks-verbs --json exposes Steam on macOS', () {
    final runtimeRoot = Directory.systemTemp.createTempSync(
      'konyak-winetricks-filter-test-',
    );
    addTearDown(() {
      if (runtimeRoot.existsSync()) {
        runtimeRoot.deleteSync(recursive: true);
      }
    });
    File(joinTestPath(runtimeRoot.path, const ['verbs.txt']))
      ..createSync(recursive: true)
      ..writeAsStringSync('''
===== apps =====
steam                    Steam Client
ubisoftconnect           Ubisoft Connect

===== fonts =====
corefonts                Microsoft Core Fonts
''');

    final result = runCli(
      const ['list-winetricks-verbs', '--json'],
      winetricksVerbRepository: DartIoWinetricksVerbRepository(
        runtimeRoot: runtimeRoot.path,
        hostPlatform: KonyakHostPlatform.macos,
      ),
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'winetricks': {
        'categories': [
          {
            'id': 'apps',
            'name': 'Apps',
            'verbs': [
              {'id': 'steam', 'name': 'steam', 'description': 'Steam Client'},
              {
                'id': 'ubisoftconnect',
                'name': 'ubisoftconnect',
                'description': 'Ubisoft Connect',
              },
            ],
          },
          {
            'id': 'fonts',
            'name': 'Fonts',
            'verbs': [
              {
                'id': 'corefonts',
                'name': 'corefonts',
                'description': 'Microsoft Core Fonts',
              },
            ],
          },
        ],
      },
    });
  });

  test('list-winetricks-verbs --json exposes Steam on Linux', () {
    final runtimeRoot = Directory.systemTemp.createTempSync(
      'konyak-linux-winetricks-steam-test-',
    );
    addTearDown(() {
      if (runtimeRoot.existsSync()) {
        runtimeRoot.deleteSync(recursive: true);
      }
    });
    File(joinTestPath(runtimeRoot.path, const ['winetricks']))
      ..createSync(recursive: true)
      ..writeAsStringSync('#!/bin/sh\n');
    final lister = RecordingWinetricksVerbLister(
      result: WinetricksVerbListResult.completed(
        categories: parseWinetricksVerbs('''
===== apps =====
steam                    Steam Client
ubisoftconnect           Ubisoft Connect

===== fonts =====
corefonts                Microsoft Core Fonts
'''),
      ),
    );

    final result = runCli(
      const ['list-winetricks-verbs', '--json'],
      winetricksVerbRepository: DartIoWinetricksVerbRepository(
        runtimeRoot: runtimeRoot.path,
        hostPlatform: KonyakHostPlatform.linux,
        lister: lister,
      ),
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'winetricks': {
        'categories': [
          {
            'id': 'apps',
            'name': 'Apps',
            'verbs': [
              {'id': 'steam', 'name': 'steam', 'description': 'Steam Client'},
              {
                'id': 'ubisoftconnect',
                'name': 'ubisoftconnect',
                'description': 'Ubisoft Connect',
              },
            ],
          },
          {
            'id': 'fonts',
            'name': 'Fonts',
            'verbs': [
              {
                'id': 'corefonts',
                'name': 'corefonts',
                'description': 'Microsoft Core Fonts',
              },
            ],
          },
        ],
      },
    });
  });

  test('list-winetricks-verbs --json fails when runtime verbs are missing', () {
    final lister = RecordingWinetricksVerbLister(
      result: WinetricksVerbListResult.completed(
        categories: parseWinetricksVerbs('''
===== fonts =====
corefonts                Microsoft Core Fonts
===== settings =====
win10                    Set Windows version to Windows 10
'''),
      ),
    );

    final result = runCli(
      const ['list-winetricks-verbs', '--json'],
      winetricksVerbRepository: DartIoWinetricksVerbRepository(
        runtimeRoot:
            '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine',
        lister: lister,
      ),
    );

    expect(result.exitCode, 75);
    expect(lister.executable, isNull);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload['schemaVersion'], 1);
    final error = payload['error'] as Map<String, Object?>;
    expect(error['code'], 'winetricksVerbsUnavailable');
    expect(
      error['message'],
      contains('Managed Winetricks verb catalog is missing'),
    );
  });

  test(
    'list-winetricks-verbs --json on Linux ignores stale macOS runtime verbs',
    () async {
      final home = await Directory.systemTemp.createTemp(
        'konyak-linux-winetricks-home-',
      );
      addTearDown(() async {
        if (await home.exists()) {
          await home.delete(recursive: true);
        }
      });

      File(
          joinTestPath(home.path, const [
            'Library',
            'Application Support',
            'Konyak',
            'Runtimes',
            'macos-wine',
            'verbs.txt',
          ]),
        )
        ..createSync(recursive: true)
        ..writeAsStringSync('''
===== dlls =====
dotnetdesktop10         MS .NET Desktop Runtime 10.0 LTS
''');

      final runtimeRoot = joinTestPath(home.path, const [
        '.local',
        'share',
        'konyak',
        'Runtimes',
        'linux-wine',
      ]);
      File(joinTestPath(runtimeRoot, const ['winetricks']))
        ..createSync(recursive: true)
        ..writeAsStringSync('#!/bin/sh\n');
      final lister = RecordingWinetricksVerbLister(
        result: WinetricksVerbListResult.completed(
          categories: parseWinetricksVerbs('''
===== dlls =====
corefonts                Microsoft Core Fonts
'''),
        ),
      );

      final result = runCli(
        const ['list-winetricks-verbs', '--json'],
        winetricksVerbRepository: DartIoWinetricksVerbRepository.current(
          hostPlatform: KonyakHostPlatform.linux,
          environment: {'HOME': home.path},
          lister: lister,
        ),
      );

      expect(result.exitCode, 0);
      expect(
        lister.executable,
        joinTestPath(runtimeRoot, const ['winetricks']),
      );

      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      expect(payload, {
        'schemaVersion': 1,
        'winetricks': {
          'categories': [
            {
              'id': 'dlls',
              'name': 'DLLs',
              'verbs': [
                {
                  'id': 'corefonts',
                  'name': 'corefonts',
                  'description': 'Microsoft Core Fonts',
                },
              ],
            },
          ],
        },
      });
    },
  );

  test('run-winetricks --json launches a selected verb', () {
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: '/Users/user/Library/Application Support/Konyak',
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: '/Users/user/Library/Application Support/Konyak/Bottles/Steam',
          windowsVersion: 'win10',
        ),
      ],
    );
    final runner = RecordingProgramRunner(
      result: const ProgramRunCompleted(processExitCode: 0),
    );

    final result = runCli(
      const ['run-winetricks', 'steam', '--verb', 'corefonts', '--json'],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
        environment: HostEnvironment({'HOME': '/Users/user'}),
      ),
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(runner.lastRequest?.runnerKind.value, 'macosWinetricks');
    expect(runner.lastRequest?.programPath.value, 'corefonts');
    expect(runner.lastRequest?.arguments, const ['corefonts']);
    expect(
      runner.lastRequest?.executable.value,
      '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/winetricks',
    );

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    final run = payload['run'] as Map<String, Object?>;
    expect(payload['schemaVersion'], 1);
    expect(run['bottleId'], 'steam');
    expect(run['programPath'], 'corefonts');
    expect(run['runnerKind'], 'macosWinetricks');
    expect(run['argv'], [
      '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/winetricks',
      'corefonts',
    ]);
  });

  test('run-winetricks --json launches Steam install verb on Linux', () {
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: '/home/user/.local/share/konyak',
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: '/home/user/.local/share/konyak/bottles/steam',
          windowsVersion: 'win10',
        ),
      ],
    );
    final runner = RecordingProgramRunner(
      result: const ProgramRunCompleted(processExitCode: 0),
    );

    final result = runCli(
      const ['run-winetricks', 'steam', '--verb', 'steam', '--json'],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.linux,
        environment: HostEnvironment({'HOME': '/home/user'}),
      ),
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(runner.lastRequest?.runnerKind.value, 'winetricks');
    expect(runner.lastRequest?.programPath.value, 'steam');
    expect(runner.lastRequest?.arguments, const ['steam']);
    expect(
      runner.lastRequest?.executable.value,
      '/home/user/.local/share/konyak/Runtimes/linux-wine/winetricks',
    );

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    final run = payload['run'] as Map<String, Object?>;
    expect(payload['schemaVersion'], 1);
    expect(run['bottleId'], 'steam');
    expect(run['programPath'], 'steam');
    expect(run['runnerKind'], 'winetricks');
    expect(run['argv'], [
      '/home/user/.local/share/konyak/Runtimes/linux-wine/winetricks',
      'steam',
    ]);
  });

  test('run-winetricks --json rejects unsafe verb names', () {
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: '/Users/user/Library/Application Support/Konyak',
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: '/Users/user/Library/Application Support/Konyak/Bottles/Steam',
          windowsVersion: 'win10',
        ),
      ],
    );
    final runner = RecordingProgramRunner(
      result: const ProgramRunCompleted(processExitCode: 0),
    );

    final result = runCli(
      const ['run-winetricks', 'steam', '--verb', 'corefonts;rm', '--json'],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
        environment: HostEnvironment({'HOME': '/Users/user'}),
      ),
      programRunner: runner,
    );

    expect(result.exitCode, 65);
    expect(runner.lastRequest, isNull);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'error': {
        'code': 'unsupportedWinetricksVerb',
        'message': 'Winetricks verb is not supported.',
        'verb': 'corefonts;rm',
      },
    });
  });

  test('run-bottle-command --json rejects unsupported commands', () {
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: '/Users/user/Library/Application Support/Konyak',
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: '/Users/user/Library/Application Support/Konyak/Bottles/Steam',
          windowsVersion: 'win10',
        ),
      ],
    );
    final runner = RecordingProgramRunner(
      result: const ProgramRunCompleted(processExitCode: 0),
    );

    final result = runCli(
      const [
        'run-bottle-command',
        'steam',
        '--command',
        'powershell -nop',
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
        environment: HostEnvironment({'HOME': '/Users/user'}),
      ),
      programRunner: runner,
    );

    expect(result.exitCode, 65);
    expect(runner.lastRequest, isNull);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'error': {
        'code': 'unsupportedBottleCommand',
        'message': 'Bottle command is not supported.',
        'command': 'powershell -nop',
      },
    });
  });

  test('open-bottle-location --json opens the Konyak C drive path', () {
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: '/Users/user/Library/Application Support/Konyak',
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: '/Users/user/Library/Application Support/Konyak/Bottles/Steam',
          windowsVersion: 'win10',
        ),
      ],
    );
    final pathOpener = RecordingPathOpener(result: const PathOpenCompleted());

    final result = runCli(
      const [
        'open-bottle-location',
        'steam',
        '--location',
        'c-drive',
        '--json',
      ],
      bottleRepository: repository,
      pathOpener: pathOpener,
    );

    expect(result.exitCode, 0);
    expect(
      pathOpener.lastPath,
      '/Users/user/Library/Application Support/Konyak/Bottles/Steam/drive_c',
    );

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'openedLocation': {
        'bottleId': 'steam',
        'location': 'c-drive',
        'path':
            '/Users/user/Library/Application Support/Konyak/Bottles/Steam/drive_c',
      },
    });
  });

  test('open-bottle-location --json rejects unsupported locations', () {
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: '/Users/user/Library/Application Support/Konyak',
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: '/Users/user/Library/Application Support/Konyak/Bottles/Steam',
          windowsVersion: 'win10',
        ),
      ],
    );
    final pathOpener = RecordingPathOpener(result: const PathOpenCompleted());

    final result = runCli(
      const ['open-bottle-location', 'steam', '--location', 'logs', '--json'],
      bottleRepository: repository,
      pathOpener: pathOpener,
    );

    expect(result.exitCode, 65);
    expect(pathOpener.lastPath, isNull);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'error': {
        'code': 'unsupportedBottleLocation',
        'message': 'Bottle location is not supported.',
        'location': 'logs',
      },
    });
  });

  test('list-bottle-programs --json returns Start Menu shortcuts', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'konyak-bottle-programs-test-',
    );
    addTearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });
    final bottlePath = joinTestPath(tempDirectory.path, const ['Steam']);
    final startMenuPath = joinTestPath(bottlePath, const [
      'drive_c',
      'ProgramData',
      'Microsoft',
      'Windows',
      'Start Menu',
      'Programs',
    ]);
    Directory(startMenuPath).createSync(recursive: true);
    File(joinTestPath(startMenuPath, const ['Steam.lnk']))
      ..createSync()
      ..writeAsStringSync('shortcut');
    File(joinTestPath(startMenuPath, const ['Readme.txt']))
      ..createSync()
      ..writeAsStringSync('ignored');

    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: tempDirectory.path,
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: bottlePath,
          windowsVersion: 'win10',
        ),
      ],
    );

    final result = runCli(
      const ['list-bottle-programs', 'steam', '--json'],
      bottleRepository: repository,
      bottleProgramRepository: const DartIoBottleProgramRepository(
        metadataExtractor: DartIoProgramMetadataExtractor(),
      ),
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'bottlePrograms': {
        'bottleId': 'steam',
        'programs': [
          {
            'id': 'steam',
            'name': 'Steam',
            'path': joinTestPath(startMenuPath, const ['Steam.lnk']),
            'source': 'globalStartMenu',
          },
        ],
      },
    });
  });

  test(
    'list-bottle-programs --json does not duplicate pinned Start Menu shortcuts',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'konyak-bottle-programs-pinned-shortcut-test-',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });
      final bottlePath = joinTestPath(tempDirectory.path, const ['Steam']);
      final startMenuPath = joinTestPath(bottlePath, const [
        'drive_c',
        'ProgramData',
        'Microsoft',
        'Windows',
        'Start Menu',
        'Programs',
      ]);
      Directory(startMenuPath).createSync(recursive: true);
      final shortcutPath = joinTestPath(startMenuPath, const ['Steam.lnk']);
      File(shortcutPath)
        ..createSync()
        ..writeAsStringSync('shortcut');

      final repository = MemoryBottleRepository(
        programMetadataExtractor: const NoopProgramMetadataExtractor(),
        dataHome: tempDirectory.path,
        bottles: [
          BottleRecord(
            id: 'steam',
            name: 'Steam',
            path: bottlePath,
            windowsVersion: 'win10',
            pinnedPrograms: [
              PinnedProgramRecord(name: 'Steam', path: shortcutPath),
            ],
          ),
        ],
      );

      final result = runCli(
        const ['list-bottle-programs', 'steam', '--json'],
        bottleRepository: repository,
        bottleProgramRepository: const DartIoBottleProgramRepository(
          metadataExtractor: DartIoProgramMetadataExtractor(),
        ),
      );

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);

      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      expect(payload, {
        'schemaVersion': 1,
        'bottlePrograms': {
          'bottleId': 'steam',
          'programs': [
            {
              'id': 'steam',
              'name': 'Steam',
              'path': shortcutPath,
              'source': 'globalStartMenu',
            },
          ],
        },
      });
    },
  );

  test('open-program-location --json reveals the pinned program path', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-open-pinned-program-location-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final bottlePath = joinTestPath(tempDirectory.path, const [
      'Bottles',
      'Steam',
    ]);
    final programPath = joinTestPath(bottlePath, const [
      'drive_c',
      'Program Files',
      'Steam',
      'Steam.exe',
    ]);
    File(programPath)
      ..createSync(recursive: true)
      ..writeAsStringSync('steam');
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: tempDirectory.path,
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: bottlePath,
          windowsVersion: 'win10',
          pinnedPrograms: [
            PinnedProgramRecord(name: 'Steam', path: programPath),
          ],
        ),
      ],
    );
    final pathOpener = RecordingPathOpener(result: const PathOpenCompleted());

    final result = runCli(
      ['open-program-location', 'steam', '--program', programPath, '--json'],
      bottleRepository: repository,
      pathOpener: pathOpener,
    );

    expect(result.exitCode, 0);
    expect(pathOpener.lastPath, isNull);
    expect(pathOpener.lastRevealedPath, programPath);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'openedProgramLocation': {
        'bottleId': 'steam',
        'programPath': programPath,
        'path': programPath,
      },
    });
  });

  test(
    'list-bottle-programs --json resolves Wine shortcut targets for PE metadata',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'konyak-bottle-shortcut-pe-test-',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });
      final bottlePath = joinTestPath(tempDirectory.path, const ['Steam']);
      final programPath = joinTestPath(bottlePath, const [
        'drive_c',
        'Program Files',
        'Fixture',
        'Fixture.exe',
      ]);
      File(programPath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(syntheticPortableExecutableBytes());
      final startMenuPath = joinTestPath(bottlePath, const [
        'drive_c',
        'ProgramData',
        'Microsoft',
        'Windows',
        'Start Menu',
        'Programs',
      ]);
      Directory(startMenuPath).createSync(recursive: true);
      File(joinTestPath(startMenuPath, const ['Fixture.lnk']))
        ..createSync()
        ..writeAsBytesSync(
          syntheticShellLinkBytes(
            localBasePath: r'C:\Program Files\Fixture\Fixture.exe',
          ),
        );

      final repository = MemoryBottleRepository(
        programMetadataExtractor: const NoopProgramMetadataExtractor(),
        dataHome: tempDirectory.path,
        bottles: [
          BottleRecord(
            id: 'steam',
            name: 'Steam',
            path: bottlePath,
            windowsVersion: 'win10',
          ),
        ],
      );

      final result = runCli(
        const ['list-bottle-programs', 'steam', '--json'],
        bottleRepository: repository,
        bottleProgramRepository: const DartIoBottleProgramRepository(
          metadataExtractor: DartIoProgramMetadataExtractor(),
        ),
      );

      expect(result.exitCode, 0);

      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      final bottlePrograms = payload['bottlePrograms'] as Map<String, Object?>;
      final programs = bottlePrograms['programs'] as List<Object?>;
      final program = programs.single as Map<String, Object?>;
      final metadata = program['metadata'] as Map<String, Object?>;

      expect(
        program['path'],
        joinTestPath(startMenuPath, const ['Fixture.lnk']),
      );
      expect(metadata['architecture'], 'x86_64');
      expect(metadata['fileDescription'], 'Fixture App');
      expect(metadata['iconPath'], isA<String>());
    },
  );

  test(
    'list-bottle-programs --json includes pinned PE metadata and extracted icons',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'konyak-bottle-pe-programs-test-',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });
      final bottlePath = joinTestPath(tempDirectory.path, const ['Steam']);
      final programPath = joinTestPath(bottlePath, const [
        'drive_c',
        'Program Files',
        'Fixture',
        'Fixture.exe',
      ]);
      File(programPath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(syntheticPortableExecutableBytes());

      final repository = MemoryBottleRepository(
        programMetadataExtractor: const NoopProgramMetadataExtractor(),
        dataHome: tempDirectory.path,
        bottles: [
          BottleRecord(
            id: 'steam',
            name: 'Steam',
            path: bottlePath,
            windowsVersion: 'win10',
            pinnedPrograms: [
              PinnedProgramRecord(name: 'Fixture', path: programPath),
            ],
          ),
        ],
      );

      final result = runCli(
        const ['list-bottle-programs', 'steam', '--json'],
        bottleRepository: repository,
        bottleProgramRepository: const DartIoBottleProgramRepository(
          metadataExtractor: DartIoProgramMetadataExtractor(),
        ),
      );

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);

      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      final bottlePrograms = payload['bottlePrograms'] as Map<String, Object?>;
      final programs = bottlePrograms['programs'] as List<Object?>;
      final program = programs.single as Map<String, Object?>;
      final metadata = program['metadata'] as Map<String, Object?>;

      expect(program['id'], 'fixture');
      expect(program['name'], 'Fixture');
      expect(program['path'], programPath);
      expect(program['source'], 'pinned');
      expect(metadata, containsPair('architecture', 'x86_64'));
      expect(metadata, containsPair('fileDescription', 'Fixture App'));
      expect(metadata, containsPair('productName', 'Fixture Suite'));
      expect(metadata, containsPair('companyName', 'Example Co'));
      expect(metadata, containsPair('fileVersion', '1.2.3'));
      expect(metadata, containsPair('productVersion', '4.5.6'));

      final iconPath = metadata['iconPath'];
      expect(iconPath, isA<String>());
      expect(iconPath as String, startsWith('$bottlePath/cache/icons/'));
      final iconBytes = File(iconPath).readAsBytesSync();
      expect(iconBytes.take(4), const [0, 0, 1, 0]);
    },
  );

  test(
    'run-program --json builds MSI, BAT, and LNK argv without shell strings',
    () {
      final cases = <String, List<String>>{
        '/downloads/setup.msi': ['msiexec', '/i', '/downloads/setup.msi'],
        '/downloads/install.bat': ['cmd', '/c', '/downloads/install.bat'],
        '/downloads/install.cmd': ['cmd', '/c', '/downloads/install.cmd'],
        '/downloads/Steam.lnk': ['start', '/unix', '/downloads/Steam.lnk'],
      };

      for (final entry in cases.entries) {
        final repository = MemoryBottleRepository(
          programMetadataExtractor: const NoopProgramMetadataExtractor(),
          dataHome: '/home/user/.local/share/konyak',
        );
        final runner = RecordingProgramRunner(
          result: const ProgramRunCompleted(processExitCode: 0),
        );
        runCli(const [
          'create-bottle',
          '--name',
          'Steam',
          '--json',
        ], bottleRepository: repository);

        final result = runCli(
          ['run-program', 'steam', '--program', entry.key, '--json'],
          bottleRepository: repository,
          programRunPlanner: ProgramRunPlanner(
            hostPlatform: KonyakHostPlatform.linux,
          ),
          programRunner: runner,
        );

        expect(result.exitCode, 0);
        expect(
          runner.lastRequest?.executable.value,
          'Konyak/Runtimes/linux-wine/bin/wine',
        );
        expect(runner.lastRequest?.arguments, entry.value);
      }
    },
  );

  test('run-program --json applies one-time program settings', () {
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: '/home/user/.local/share/konyak',
    );
    final runner = RecordingProgramRunner(
      result: const ProgramRunCompleted(processExitCode: 0),
    );
    runCli(const [
      'create-bottle',
      '--name',
      'Steam',
      '--json',
    ], bottleRepository: repository);
    runCli(const [
      'set-program-settings',
      'steam',
      '--program',
      '/downloads/setup.exe',
      '--settings-json',
      '{"locale":"ja_JP.UTF-8","arguments":"-silent","environment":{"STEAM_COMPAT_DATA_PATH":"/compat"}}',
      '--json',
    ], bottleRepository: repository);

    final result = runCli(
      const [
        'run-program',
        'steam',
        '--program',
        '/downloads/setup.exe',
        '--settings-json',
        '{"arguments":"-windowed","environment":{"WINEDEBUG":"+seh"}}',
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.linux,
      ),
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(runner.lastRequest?.arguments, const [
      '/downloads/setup.exe',
      '-windowed',
    ]);
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair('STEAM_COMPAT_DATA_PATH', '/compat'),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair('WINEDEBUG', '+seh'),
    );
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair('LC_ALL', 'ja_JP.UTF-8'),
    );
  });

  test('run-program --json applies one-time logging settings', () {
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: '/home/user/.local/share/konyak',
    );
    final runner = RecordingProgramRunner(
      result: const ProgramRunCompleted(processExitCode: 0),
    );
    runCli(const [
      'create-bottle',
      '--name',
      'Steam',
      '--json',
    ], bottleRepository: repository);
    runCli(const [
      'set-program-settings',
      'steam',
      '--program',
      '/downloads/setup.exe',
      '--settings-json',
      '{"environment":{"WINEDEBUG":"+seh"}}',
      '--json',
    ], bottleRepository: repository);

    final result = runCli(
      [
        'run-program',
        'steam',
        '--program',
        '/downloads/setup.exe',
        '--settings-json',
        jsonEncode({
          'logging': {
            'createLogFile': true,
            'additionalWineLoggingChannels': '+relay',
            'logFilePath': '/tmp/steam.cxlog',
          },
        }),
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.linux,
      ),
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(runner.lastRequest?.createLogFile, isTrue);
    expect(runner.lastRequest?.logPath.value, '/tmp/steam.cxlog');
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair('WINEDEBUG', '+seh,+relay'),
    );
    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect((payload['run'] as Map<String, Object?>)['logFileCreated'], isTrue);
  });

  test('run-program --json rejects unsupported program extensions', () {
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: '/home/user/.local/share/konyak',
    );
    runCli(const [
      'create-bottle',
      '--name',
      'Steam',
      '--json',
    ], bottleRepository: repository);

    final result = runCli(
      const [
        'run-program',
        'steam',
        '--program',
        '/downloads/readme.txt',
        '--json',
      ],
      bottleRepository: repository,
      programRunner: RecordingProgramRunner(
        result: const ProgramRunCompleted(processExitCode: 0),
      ),
    );

    expect(result.exitCode, 65);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'error': {
        'code': 'unsupportedProgramType',
        'message': 'Program type is not supported.',
        'programPath': '/downloads/readme.txt',
      },
    });
  });

  test('run-program --json returns a machine-readable runner failure', () {
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: '/home/user/.local/share/konyak',
    );
    runCli(const [
      'create-bottle',
      '--name',
      'Steam',
      '--json',
    ], bottleRepository: repository);

    final result = runCli(
      const [
        'run-program',
        'steam',
        '--program',
        '/downloads/setup.exe',
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.linux,
      ),
      programRunner: RecordingProgramRunner(
        result: const ProgramRunFailed(message: 'wine not found'),
      ),
    );

    expect(result.exitCode, 75);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'error': {
        'code': 'programRunFailed',
        'message': 'wine not found',
        'bottleId': 'steam',
        'programPath': '/downloads/setup.exe',
        'runnerKind': 'wine',
        'executable': 'Konyak/Runtimes/linux-wine/bin/wine',
        'workingDirectory': null,
        'argv': ['Konyak/Runtimes/linux-wine/bin/wine', '/downloads/setup.exe'],
        'logPath':
            '/home/user/.local/share/konyak/bottles/steam/logs/latest.log',
        'logFileCreated': true,
      },
    });
  });

  test(
    'run-program --json on Linux writes a desktop launcher for external executables',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'konyak-linux-external-launcher-test-',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final repository = MemoryBottleRepository(
        programMetadataExtractor: const NoopProgramMetadataExtractor(),
        dataHome: tempDirectory.path,
      );
      runCli(const [
        'create-bottle',
        '--name',
        'Steam',
        '--json',
      ], bottleRepository: repository);

      final programPath = joinTestPath(tempDirectory.path, const [
        'downloads',
        'setup.exe',
      ]);
      File(programPath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(syntheticPortableExecutableBytes());

      final runner = RecordingProgramRunner(
        result: const ProgramRunCompleted(processExitCode: 0),
      );
      final xdgDataHome = joinTestPath(tempDirectory.path, const ['xdg-data']);

      final result = runCli(
        ['run-program', 'steam', '--program', programPath, '--json'],
        bottleRepository: repository,
        programMetadataExtractor: const DartIoProgramMetadataExtractor(),
        programRunPlanner: ProgramRunPlanner(
          hostPlatform: KonyakHostPlatform.linux,
          environment: HostEnvironment({
            'HOME': tempDirectory.path,
            'XDG_DATA_HOME': xdgDataHome,
          }),
        ),
        programRunner: runner,
      );

      expect(result.exitCode, 0);
      final launcherDirectory = Directory(
        joinTestPath(xdgDataHome, const ['applications', 'konyak']),
      );
      expect(launcherDirectory.existsSync(), isTrue);

      final launcherFiles = launcherDirectory
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.desktop'))
          .toList(growable: false);
      expect(launcherFiles, hasLength(1));

      final launcher = launcherFiles.single.readAsStringSync();
      expect(launcher, contains('[Desktop Entry]'));
      expect(launcher, contains('Type=Application'));
      expect(launcher, contains('Name=Fixture Suite'));
      expect(launcher, contains('StartupWMClass=setup.exe'));
      expect(
        launcher,
        contains(
          'Path=${joinTestPath(tempDirectory.path, const ['downloads'])}',
        ),
      );
      expect(
        launcher,
        contains(
          'Exec=env "WINEPREFIX=${expectFound(repository.findBottle(BottleId('steam'))).path.value}" '
          '"${joinTestPath(xdgDataHome, const ['konyak', 'Runtimes', 'linux-wine', 'bin', 'wine'])}" "$programPath"',
        ),
      );
      expect(
        launcher,
        contains(
          'Icon=${expectFound(repository.findBottle(BottleId('steam'))).path.value}/cache/icons/',
        ),
      );
    },
  );

  test(
    'run-program --json on Linux records desktop launcher sync diagnostics',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'konyak-linux-external-launcher-diagnostic-test-',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final repository = MemoryBottleRepository(
        programMetadataExtractor: const NoopProgramMetadataExtractor(),
        dataHome: tempDirectory.path,
      );
      runCli(const [
        'create-bottle',
        '--name',
        'Steam',
        '--json',
      ], bottleRepository: repository);

      final programPath = joinTestPath(tempDirectory.path, const [
        'downloads',
        'setup.exe',
      ]);
      File(programPath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(syntheticPortableExecutableBytes());

      final runner = RecordingProgramRunner(
        result: const ProgramRunCompleted(processExitCode: 0),
      );
      final diagnosticSink =
          RecordingLinuxExternalProgramLauncherDiagnosticSink();
      final xdgDataHome = joinTestPath(tempDirectory.path, const ['xdg-data']);

      final result = runCli(
        ['run-program', 'steam', '--program', programPath, '--json'],
        bottleRepository: repository,
        programMetadataExtractor: ThrowingProgramMetadataExtractor(
          StateError('metadata unavailable'),
        ),
        programRunPlanner: ProgramRunPlanner(
          hostPlatform: KonyakHostPlatform.linux,
          environment: HostEnvironment({
            'HOME': tempDirectory.path,
            'XDG_DATA_HOME': xdgDataHome,
          }),
        ),
        programRunner: runner,
        linuxExternalProgramLauncherDiagnosticSink: diagnosticSink,
      );

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);
      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      expect(payload.keys, containsAll(const ['schemaVersion', 'run']));
      expect(payload.keys, isNot(contains('diagnostic')));
      final run = payload['run'] as Map<String, Object?>;
      expect(run['programPath'], programPath);
      expect(run['processExitCode'], 0);

      expect(diagnosticSink.failures, hasLength(1));
      final failure = diagnosticSink.failures.single;
      expect(
        failure.kind,
        LinuxExternalProgramLauncherSyncFailureKind.invalidState,
      );
      expect(failure.bottleId, 'steam');
      expect(failure.programPath, programPath);
      expect(failure.message, 'metadata unavailable');
    },
  );
}

String singleAppleScriptDoScriptCommand(String appleScript) {
  final commandLines = appleScript
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.startsWith('do script '))
      .toList(growable: false);
  expect(commandLines, hasLength(1));

  final commandLine = commandLines.single;
  final match = RegExp(r'^do script "(.+)"$').firstMatch(commandLine);
  expect(match, isNotNull);

  return match!.group(1)!;
}
