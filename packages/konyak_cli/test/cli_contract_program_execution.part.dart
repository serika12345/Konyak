part of 'cli_contract_test.dart';

void defineProgramExecutionContractTests() {
  test('get-program-settings --json returns default program settings', () {
    final repository = MemoryBottleRepository(
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
      const ProgramSettingsRequest(
        bottleId: 'steam',
        programPath: '/downloads/Steam.exe',
      ),
    );
    expect(settings, isA<ProgramSettingsRead>());
    expect((settings as ProgramSettingsRead).settings.locale, 'ja_JP.UTF-8');
    expect(settings.settings.arguments, '-silent -windowed');
    expect(settings.settings.environment.unlockView, {
      'STEAM_COMPAT_DATA_PATH': '/compat',
    });
  });

  test('run-program --json runs an EXE through the program runner', () {
    final repository = MemoryBottleRepository(
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
    expect(runner.lastRequest?.executable, 'wine');
    expect(runner.lastRequest?.arguments, const ['/downloads/setup.exe']);
    expect(runner.lastRequest?.environment['WINEPREFIX'], contains('/steam'));
    expect(runner.lastRequest?.logPath, contains('/steam/logs/latest.log'));

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'run': {
        'bottleId': 'steam',
        'programPath': '/downloads/setup.exe',
        'runnerKind': 'wine',
        'executable': 'wine',
        'workingDirectory': null,
        'argv': ['wine', '/downloads/setup.exe'],
        'logPath':
            '/home/user/.local/share/konyak/bottles/steam/logs/latest.log',
        'processExitCode': 0,
      },
    });
  });

  test('run-program --json applies persisted program settings', () {
    final repository = MemoryBottleRepository(
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
        bottleId: 'steam',
        programPath: '/downloads/Steam.exe',
        settings: ProgramSettingsRecord(
          locale: 'ja_JP.UTF-8',
          arguments: '-silent -windowed',
          environment: {'STEAM_COMPAT_DATA_PATH': '/compat'},
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
    expect(runner.lastRequest?.environment, {
      'STEAM_COMPAT_DATA_PATH': '/compat',
      'LC_ALL': 'ja_JP.UTF-8',
      'WINEPREFIX': '/home/user/.local/share/konyak/bottles/steam',
      'WINEMSYNC': '1',
      'WINEESYNC': '1',
    });
  });

  test('run-program --json uses the Konyak macOS Wine startup path on macOS', () {
    final repository = MemoryBottleRepository(
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
        environment: {'HOME': '/Users/user'},
      ),
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(
      runner.lastRequest?.executable,
      '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wine64',
    );
    expect(
      runner.lastRequest?.workingDirectory.toNullable(),
      '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin',
    );
    expect(runner.lastRequest?.arguments, const [
      'start',
      '/unix',
      '/downloads/setup.exe',
    ]);
    expect(runner.lastRequest?.runnerKind, 'macosWine');
    expect(
      runner.lastRequest?.environment,
      containsPair(
        'WINEPREFIX',
        '/Users/user/Library/Application Support/Konyak/Bottles/Steam',
      ),
    );
    expect(
      runner.lastRequest?.environment,
      containsPair('WINEDEBUG', 'fixme-all'),
    );
    expect(runner.lastRequest?.environment, containsPair('GST_DEBUG', '1'));
    expect(
      runner.lastRequest?.environment,
      containsPair(
        'DYLD_LIBRARY_PATH',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib',
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
            '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wine64',
        'workingDirectory':
            '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin',
        'argv': [
          '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wine64',
          'start',
          '/unix',
          '/downloads/setup.exe',
        ],
        'logPath':
            '/Users/user/Library/Application Support/Konyak/Bottles/Steam/logs/latest.log',
        'processExitCode': 0,
      },
    });
  });

  test('run-program --json preserves macOS bottle environment on macOS', () {
    final repository = MemoryBottleRepository(
      dataHome: '/Users/user/Library/Application Support/Konyak',
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: '/Users/user/Library/Application Support/Konyak/Bottles/Steam',
          windowsVersion: 'win10',
          runtimeSettings: BottleRuntimeSettings(
            enhancedSync: 'msync',
            metalHud: true,
            metalTrace: true,
            avxEnabled: true,
            dxrEnabled: true,
            dxvk: true,
            dxvkHud: 'partial',
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
        environment: {'HOME': '/Users/user'},
      ),
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(runner.lastRequest?.environment, containsPair('WINEMSYNC', '1'));
    expect(runner.lastRequest?.environment, containsPair('WINEESYNC', '1'));
    expect(
      runner.lastRequest?.environment,
      containsPair('MTL_HUD_ENABLED', '1'),
    );
    expect(
      runner.lastRequest?.environment,
      containsPair('METAL_CAPTURE_ENABLED', '1'),
    );
    expect(
      runner.lastRequest?.environment,
      containsPair('ROSETTA_ADVERTISE_AVX', '1'),
    );
    expect(
      runner.lastRequest?.environment,
      containsPair('D3DM_SUPPORT_DXR', '1'),
    );
    expect(
      runner.lastRequest?.environment,
      containsPair('DXVK_HUD', 'devinfo,fps,frametimes'),
    );
    expect(runner.lastRequest?.environment, containsPair('DXVK_ASYNC', '1'));
    expect(
      runner.lastRequest?.environment,
      containsPair('WINEDLLOVERRIDES', 'dxgi,d3d9,d3d10core,d3d11=n,b'),
    );
    expect(
      runner.lastRequest?.environment,
      containsPair(
        'WINEDLLPATH',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/DXVK/x64:/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/DXVK/x32',
      ),
    );
  });

  test('run-program --json applies DXVK settings on Linux', () {
    final repository = MemoryBottleRepository(
      dataHome: '/home/user/.local/share/konyak',
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: '/home/user/.local/share/konyak/bottles/steam',
          windowsVersion: 'win10',
          runtimeSettings: BottleRuntimeSettings(
            enhancedSync: 'msync',
            dxvk: true,
            dxvkHud: 'fps',
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
        environment: const {
          'HOME': '/home/user',
          'KONYAK_LINUX_WINE_HOME': '/runtime/linux-wine',
        },
      ),
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(runner.lastRequest?.environment, containsPair('WINEMSYNC', '1'));
    expect(runner.lastRequest?.environment, containsPair('WINEESYNC', '1'));
    expect(runner.lastRequest?.environment, containsPair('DXVK_HUD', 'fps'));
    expect(runner.lastRequest?.environment, containsPair('DXVK_ASYNC', '1'));
    expect(
      runner.lastRequest?.environment,
      containsPair(
        'WINEDLLOVERRIDES',
        'dxgi=n,b;d3d9=n,b;d3d10core=n,b;d3d11=n,b',
      ),
    );
    expect(
      runner.lastRequest?.environment,
      containsPair(
        'WINEDLLPATH',
        '/runtime/linux-wine/dxvk/x64:/runtime/linux-wine/dxvk/x86',
      ),
    );
  });

  test('run-program --json applies vkd3d-proton settings on Linux', () {
    final repository = MemoryBottleRepository(
      dataHome: '/home/user/.local/share/konyak',
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: '/home/user/.local/share/konyak/bottles/steam',
          windowsVersion: 'win10',
          runtimeSettings: BottleRuntimeSettings(
            enhancedSync: 'msync',
            vkd3dProton: true,
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
        environment: const {
          'HOME': '/home/user',
          'KONYAK_LINUX_WINE_HOME': '/runtime/linux-wine',
        },
      ),
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(runner.lastRequest?.environment, containsPair('WINEMSYNC', '1'));
    expect(runner.lastRequest?.environment, containsPair('WINEESYNC', '1'));
    expect(
      runner.lastRequest?.environment,
      containsPair('WINEDLLOVERRIDES', 'd3d12=n,b;d3d12core=n,b'),
    );
    expect(
      runner.lastRequest?.environment,
      containsPair(
        'WINEDLLPATH',
        '/runtime/linux-wine/vkd3d-proton/x64:/runtime/linux-wine/vkd3d-proton/x86',
      ),
    );
  });

  test('run-bottle-command --json launches winecfg through macOS Wine', () {
    final repository = MemoryBottleRepository(
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
        environment: {'HOME': '/Users/user'},
      ),
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(
      runner.lastRequest?.executable,
      '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wine64',
    );
    expect(runner.lastRequest?.arguments, const ['winecfg']);
    expect(runner.lastRequest?.programPath, 'winecfg');
    expect(runner.lastRequest?.runnerKind, 'macosWine');
    expect(
      runner.lastRequest?.environment,
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
            '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wine64',
        'workingDirectory':
            '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin',
        'argv': [
          '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wine64',
          'winecfg',
        ],
        'logPath':
            '/Users/user/Library/Application Support/Konyak/Bottles/Steam/logs/latest.log',
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
      environment: const {'HOME': '/Users/user'},
    ).planPrefixInitialization(bottle: bottle);

    expect(
      request.executable,
      '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wine64',
    );
    expect(request.arguments, const ['wineboot', '--init']);
    expect(request.programPath, 'wineboot');
    expect(request.runnerKind, 'macosWine');
    expect(
      request.workingDirectory.toNullable(),
      '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin',
    );
    expect(
      request.environment,
      containsPair(
        'WINEPREFIX',
        '/Users/user/Library/Application Support/Konyak/Bottles/Steam',
      ),
    );
    expect(
      request.logPath,
      '/Users/user/Library/Application Support/Konyak/Bottles/Steam/logs/prefix-init.log',
    );
  });

  test('run-bottle-command --json opens a macOS bottle terminal', () {
    final repository = MemoryBottleRepository(
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
        environment: {'HOME': '/Users/user'},
      ),
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(runner.lastRequest?.runnerKind, 'macosTerminal');
    expect(runner.lastRequest?.programPath, 'terminal');
    expect(runner.lastRequest?.executable, '/usr/bin/osascript');
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
        environment: {
          'HOME': '/home/user',
          'KONYAK_LINUX_WINE_HOME': '/runtime',
          'KONYAK_LINUX_WINE_LIBRARY_PATH': '/runtime-host-libs',
        },
      ),
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(runner.lastRequest?.runnerKind, 'terminal');
    expect(runner.lastRequest?.programPath, 'terminal');
    expect(runner.lastRequest?.executable, 'sh');
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

  test('Linux planner uses a configured Konyak-managed runtime', () {
    final bottle = BottleRecord(
      id: 'steam',
      name: 'Steam',
      path: '/home/user/.local/share/konyak/bottles/steam',
      windowsVersion: 'win10',
    );

    final request = ProgramRunPlanner(
      hostPlatform: KonyakHostPlatform.linux,
      environment: const {
        'HOME': '/home/user',
        'PATH': '/usr/bin:/bin',
        'LD_LIBRARY_PATH': '/host/lib',
        'KONYAK_LINUX_WINE_HOME': '/opt/konyak/runtime/linux-wine',
        'KONYAK_LINUX_WINE_LIBRARY_PATH': '/opt/konyak/runtime-host-libs',
      },
    ).plan(bottle: bottle, programPath: 'C:/Program Files/Steam/steam.exe');

    expect(request.isSome(), isTrue);
    final plannedRequest = request.toNullable();
    expect(
      plannedRequest?.executable,
      '/opt/konyak/runtime/linux-wine/bin/wine',
    );
    expect(
      plannedRequest?.environment,
      containsPair('PATH', '/opt/konyak/runtime/linux-wine/bin:/usr/bin:/bin'),
    );
    expect(
      plannedRequest?.environment,
      containsPair(
        'LD_LIBRARY_PATH',
        '/opt/konyak/runtime-host-libs:/host/lib',
      ),
    );
    expect(
      plannedRequest?.environment,
      containsPair(
        'WINEPREFIX',
        '/home/user/.local/share/konyak/bottles/steam',
      ),
    );
  });

  test('run-bottle-command --json launches winetricks with bottle env', () {
    final repository = MemoryBottleRepository(
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
        environment: {'HOME': '/Users/user'},
      ),
      programRunner: runner,
      winetricksScriptInstaller: RecordingWinetricksScriptInstaller(
        result: const WinetricksScriptInstallCompleted(),
      ),
    );

    expect(result.exitCode, 0);
    expect(runner.lastRequest?.runnerKind, 'macosWinetricks');
    expect(runner.lastRequest?.programPath, 'winetricks');
    expect(
      runner.lastRequest?.executable,
      '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/winetricks',
    );
    expect(runner.lastRequest?.arguments, isEmpty);
    expect(
      runner.lastRequest?.workingDirectory.toNullable(),
      '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine',
    );
    expect(
      runner.lastRequest?.environment,
      containsPair(
        'WINEPREFIX',
        '/Users/user/Library/Application Support/Konyak/Bottles/Steam',
      ),
    );
    expect(runner.lastRequest?.environment, containsPair('WINE', 'wine64'));
    expect(
      runner.lastRequest?.environment,
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

  test('list-winetricks-verbs --json returns parsed runtime verbs', () async {
    final runtimeRoot = await Directory.systemTemp.createTemp(
      'konyak-winetricks-verbs-test-',
    );
    addTearDown(() async {
      if (await runtimeRoot.exists()) {
        await runtimeRoot.delete(recursive: true);
      }
    });

    File(_joinTestPath(runtimeRoot.path, const ['verbs.txt']))
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

  test('list-winetricks-verbs --json falls back to winetricks list-all', () {
    final lister = RecordingWinetricksVerbLister(
      result: WinetricksVerbListCompleted(
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
        scriptInstaller: RecordingWinetricksScriptInstaller(
          result: const WinetricksScriptInstallCompleted(),
        ),
      ),
    );

    expect(result.exitCode, 0);
    expect(lister.executable, contains('/Runtimes/macos-wine/winetricks'));

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'winetricks': {
        'categories': [
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
          {
            'id': 'settings',
            'name': 'Settings',
            'verbs': [
              {
                'id': 'win10',
                'name': 'win10',
                'description': 'Set Windows version to Windows 10',
              },
            ],
          },
        ],
      },
    });
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
          _joinTestPath(home.path, const [
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

      final lister = RecordingWinetricksVerbLister(
        result: WinetricksVerbListCompleted(
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
      expect(lister.executable, 'winetricks');

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
        environment: {'HOME': '/Users/user'},
      ),
      programRunner: runner,
      winetricksScriptInstaller: RecordingWinetricksScriptInstaller(
        result: const WinetricksScriptInstallCompleted(),
      ),
    );

    expect(result.exitCode, 0);
    expect(runner.lastRequest?.runnerKind, 'macosWinetricks');
    expect(runner.lastRequest?.programPath, 'corefonts');
    expect(runner.lastRequest?.arguments, const ['corefonts']);
    expect(
      runner.lastRequest?.executable,
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

  test('run-winetricks --json reports script installation failures', () {
    final repository = MemoryBottleRepository(
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
        environment: {'HOME': '/Users/user'},
      ),
      programRunner: runner,
      winetricksScriptInstaller: RecordingWinetricksScriptInstaller(
        result: const WinetricksScriptInstallFailed(
          'Failed to download Winetricks.',
        ),
      ),
    );

    expect(result.exitCode, 75);
    expect(runner.lastRequest, isNull);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'error': {
        'code': 'winetricksUnavailable',
        'message': 'Failed to download Winetricks.',
      },
    });
  });

  test('run-winetricks --json rejects unsafe verb names', () {
    final repository = MemoryBottleRepository(
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
        environment: {'HOME': '/Users/user'},
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
      const ['run-bottle-command', 'steam', '--command', 'cmd', '--json'],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
        environment: {'HOME': '/Users/user'},
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
        'command': 'cmd',
      },
    });
  });

  test('open-bottle-location --json opens the Konyak C drive path', () {
    final repository = MemoryBottleRepository(
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
    final bottlePath = _joinTestPath(tempDirectory.path, const ['Steam']);
    final startMenuPath = _joinTestPath(bottlePath, const [
      'drive_c',
      'ProgramData',
      'Microsoft',
      'Windows',
      'Start Menu',
      'Programs',
    ]);
    Directory(startMenuPath).createSync(recursive: true);
    File(_joinTestPath(startMenuPath, const ['Steam.lnk']))
      ..createSync()
      ..writeAsStringSync('shortcut');
    File(_joinTestPath(startMenuPath, const ['Readme.txt']))
      ..createSync()
      ..writeAsStringSync('ignored');

    final repository = MemoryBottleRepository(
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
      bottleProgramRepository: const DartIoBottleProgramRepository(),
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
            'path': _joinTestPath(startMenuPath, const ['Steam.lnk']),
            'source': 'globalStartMenu',
          },
        ],
      },
    });
  });

  test('open-program-location --json reveals the pinned program path', () {
    final repository = MemoryBottleRepository(
      dataHome: '/Users/user/Library/Application Support/Konyak',
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: '/Users/user/Library/Application Support/Konyak/Bottles/Steam',
          windowsVersion: 'win10',
          pinnedPrograms: [
            PinnedProgramRecord(
              name: 'Steam',
              path:
                  '/Users/user/Library/Application Support/Konyak/Bottles/Steam/drive_c/Program Files/Steam/Steam.exe',
            ),
          ],
        ),
      ],
    );
    final pathOpener = RecordingPathOpener(result: const PathOpenCompleted());

    final result = runCli(
      const [
        'open-program-location',
        'steam',
        '--program',
        '/Users/user/Library/Application Support/Konyak/Bottles/Steam/drive_c/Program Files/Steam/Steam.exe',
        '--json',
      ],
      bottleRepository: repository,
      pathOpener: pathOpener,
    );

    expect(result.exitCode, 0);
    expect(pathOpener.lastPath, isNull);
    expect(
      pathOpener.lastRevealedPath,
      '/Users/user/Library/Application Support/Konyak/Bottles/Steam/drive_c/Program Files/Steam/Steam.exe',
    );

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'openedProgramLocation': {
        'bottleId': 'steam',
        'programPath':
            '/Users/user/Library/Application Support/Konyak/Bottles/Steam/drive_c/Program Files/Steam/Steam.exe',
        'path':
            '/Users/user/Library/Application Support/Konyak/Bottles/Steam/drive_c/Program Files/Steam/Steam.exe',
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
      final bottlePath = _joinTestPath(tempDirectory.path, const ['Steam']);
      final programPath = _joinTestPath(bottlePath, const [
        'drive_c',
        'Program Files',
        'Fixture',
        'Fixture.exe',
      ]);
      File(programPath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(_syntheticPortableExecutableBytes());
      final startMenuPath = _joinTestPath(bottlePath, const [
        'drive_c',
        'ProgramData',
        'Microsoft',
        'Windows',
        'Start Menu',
        'Programs',
      ]);
      Directory(startMenuPath).createSync(recursive: true);
      File(_joinTestPath(startMenuPath, const ['Fixture.lnk']))
        ..createSync()
        ..writeAsBytesSync(
          _syntheticShellLinkBytes(
            localBasePath: r'C:\Program Files\Fixture\Fixture.exe',
          ),
        );

      final repository = MemoryBottleRepository(
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
        bottleProgramRepository: const DartIoBottleProgramRepository(),
      );

      expect(result.exitCode, 0);

      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      final bottlePrograms = payload['bottlePrograms'] as Map<String, Object?>;
      final programs = bottlePrograms['programs'] as List<Object?>;
      final program = programs.single as Map<String, Object?>;
      final metadata = program['metadata'] as Map<String, Object?>;

      expect(
        program['path'],
        _joinTestPath(startMenuPath, const ['Fixture.lnk']),
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
      final bottlePath = _joinTestPath(tempDirectory.path, const ['Steam']);
      final programPath = _joinTestPath(bottlePath, const [
        'drive_c',
        'Program Files',
        'Fixture',
        'Fixture.exe',
      ]);
      File(programPath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(_syntheticPortableExecutableBytes());

      final repository = MemoryBottleRepository(
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
        bottleProgramRepository: const DartIoBottleProgramRepository(),
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
        expect(runner.lastRequest?.executable, 'wine');
        expect(runner.lastRequest?.arguments, entry.value);
      }
    },
  );

  test('run-program --json rejects unsupported program extensions', () {
    final repository = MemoryBottleRepository(
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
        'executable': 'wine',
        'workingDirectory': null,
        'argv': ['wine', '/downloads/setup.exe'],
        'logPath':
            '/home/user/.local/share/konyak/bottles/steam/logs/latest.log',
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

      final repository = MemoryBottleRepository(dataHome: tempDirectory.path);
      runCli(const [
        'create-bottle',
        '--name',
        'Steam',
        '--json',
      ], bottleRepository: repository);

      final programPath = _joinTestPath(tempDirectory.path, const [
        'downloads',
        'setup.exe',
      ]);
      File(programPath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(_syntheticPortableExecutableBytes());

      final runner = RecordingProgramRunner(
        result: const ProgramRunCompleted(processExitCode: 0),
      );
      final xdgDataHome = _joinTestPath(tempDirectory.path, const ['xdg-data']);

      final result = runCli(
        ['run-program', 'steam', '--program', programPath, '--json'],
        bottleRepository: repository,
        programRunPlanner: ProgramRunPlanner(
          hostPlatform: KonyakHostPlatform.linux,
          environment: {
            'HOME': tempDirectory.path,
            'XDG_DATA_HOME': xdgDataHome,
          },
        ),
        programRunner: runner,
      );

      expect(result.exitCode, 0);
      final launcherDirectory = Directory(
        _joinTestPath(xdgDataHome, const ['applications', 'konyak']),
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
          'Path=${_joinTestPath(tempDirectory.path, const ['downloads'])}',
        ),
      );
      expect(
        launcher,
        contains(
          'Exec=env "WINEPREFIX=${_expectFound(repository.findBottle('steam')).path}" wine "$programPath"',
        ),
      );
      expect(
        launcher,
        contains(
          'Icon=${_expectFound(repository.findBottle('steam')).path}/cache/icons/',
        ),
      );
    },
  );
}
