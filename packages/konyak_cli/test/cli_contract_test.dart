import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:konyak_cli/konyak_cli.dart';
import 'package:test/test.dart';

void main() {
  test(
    'list-bottles --json returns the versioned empty bottle list contract',
    () {
      final result = runCli(const ['list-bottles', '--json']);

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);

      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      expect(payload, {'schemaVersion': 1, 'bottles': <Object?>[]});
    },
  );

  test('list-bottles --json serializes bottle records from the catalog', () {
    final result = runCli(
      const ['list-bottles', '--json'],
      bottleCatalog: const StaticBottleCatalog([
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: '/home/user/.local/share/konyak/bottles/steam',
          windowsVersion: 'win10',
        ),
      ]),
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'bottles': [
        {
          'id': 'steam',
          'name': 'Steam',
          'path': '/home/user/.local/share/konyak/bottles/steam',
          'windowsVersion': 'win10',
        },
      ],
    });
  });

  test('get-app-settings --json returns persisted application settings', () {
    final result = runCli(
      const ['get-app-settings', '--json'],
      appSettingsRepository: MemoryAppSettingsRepository(
        const AppSettingsRecord(
          terminateWineProcessesOnClose: false,
          defaultBottlePath: '/Volumes/Games/Bottles',
          appearanceMode: AppAppearanceMode.light,
          automaticallyCheckForKonyakUpdates: true,
          automaticallyCheckForWineUpdates: false,
        ),
      ),
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'appSettings': {
        'terminateWineProcessesOnClose': false,
        'defaultBottlePath': '/Volumes/Games/Bottles',
        'appearanceMode': 'light',
        'automaticallyCheckForKonyakUpdates': true,
        'automaticallyCheckForWineUpdates': false,
      },
    });
  });

  test('set-app-settings --json persists application settings', () {
    final repository = MemoryAppSettingsRepository(
      const AppSettingsRecord(defaultBottlePath: '/Users/user/Bottles'),
    );

    final result = runCli(const [
      'set-app-settings',
      '--settings-json',
      '{"terminateWineProcessesOnClose":false,"defaultBottlePath":"/Volumes/Games/Bottles","appearanceMode":"light","automaticallyCheckForKonyakUpdates":true,"automaticallyCheckForWineUpdates":false}',
      '--json',
    ], appSettingsRepository: repository);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(
      repository.read(),
      const AppSettingsRecord(
        terminateWineProcessesOnClose: false,
        defaultBottlePath: '/Volumes/Games/Bottles',
        appearanceMode: AppAppearanceMode.light,
        automaticallyCheckForKonyakUpdates: true,
        automaticallyCheckForWineUpdates: false,
      ),
    );

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload['appSettings'], {
      'terminateWineProcessesOnClose': false,
      'defaultBottlePath': '/Volumes/Games/Bottles',
      'appearanceMode': 'light',
      'automaticallyCheckForKonyakUpdates': true,
      'automaticallyCheckForWineUpdates': false,
    });
  });

  test('set-app-settings --json persists system appearance mode', () {
    final repository = MemoryAppSettingsRepository(
      const AppSettingsRecord(defaultBottlePath: '/Users/user/Bottles'),
    );

    final result = runCli(const [
      'set-app-settings',
      '--settings-json',
      '{"terminateWineProcessesOnClose":true,"defaultBottlePath":"/Volumes/Games/Bottles","appearanceMode":"system","automaticallyCheckForKonyakUpdates":false,"automaticallyCheckForWineUpdates":true}',
      '--json',
    ], appSettingsRepository: repository);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(
      repository.read(),
      const AppSettingsRecord(
        defaultBottlePath: '/Volumes/Games/Bottles',
        appearanceMode: AppAppearanceMode.system,
      ),
    );

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload['appSettings'], {
      'terminateWineProcessesOnClose': true,
      'defaultBottlePath': '/Volumes/Games/Bottles',
      'appearanceMode': 'system',
      'automaticallyCheckForKonyakUpdates': false,
      'automaticallyCheckForWineUpdates': true,
    });
  });

  test('default bottle repository creates bottles under app settings path', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-app-settings-bottle-path-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final bottleDirectory = _joinTestPath(tempDirectory.path, const [
      'Konyak Bottles',
    ]);
    final repository = defaultBottleRepositoryFromEnvironment(
      {'HOME': tempDirectory.path},
      hostPlatform: KonyakHostPlatform.linux,
      appSettings: AppSettingsRecord(defaultBottlePath: bottleDirectory),
    );

    final result = repository.createBottle(
      const BottleCreateRequest(name: 'Steam', windowsVersion: 'win10'),
    );

    expect(result, isA<BottleCreated>());
    final created = result as BottleCreated;
    expect(
      created.bottle.path,
      _joinTestPath(bottleDirectory, const ['steam']),
    );
  });

  test('custom default bottle path preserves existing local catalog', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-app-settings-catalog-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final dataHome = _joinTestPath(tempDirectory.path, const ['data']);
    final existingBottlePath = _joinTestPath(dataHome, const [
      'bottles',
      'existing',
    ]);
    Directory(existingBottlePath).createSync(recursive: true);
    _writeTestBottleMetadata(
      BottleRecord(
        id: 'existing',
        name: 'Existing',
        path: existingBottlePath,
        windowsVersion: 'win10',
      ),
    );
    final bottleDirectory = _joinTestPath(tempDirectory.path, const [
      'Konyak Bottles',
    ]);
    final repository = defaultBottleRepositoryFromEnvironment(
      {'KONYAK_DATA_HOME': dataHome, 'HOME': tempDirectory.path},
      hostPlatform: KonyakHostPlatform.linux,
      appSettings: AppSettingsRecord(defaultBottlePath: bottleDirectory),
    );

    final result = repository.createBottle(
      const BottleCreateRequest(name: 'Steam', windowsVersion: 'win10'),
    );

    expect(result, isA<BottleCreated>());
    expect(repository.listBottles().map((bottle) => bottle.id), const [
      'existing',
      'steam',
    ]);
  });

  test('export-bottle-archive --json writes a tar archive for a bottle', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-bottle-export-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final repository = FileBottleRepository(
      dataHome: _joinTestPath(tempDirectory.path, const ['data']),
    );
    final createResult = repository.createBottle(
      const BottleCreateRequest(name: 'Steam', windowsVersion: 'win10'),
    );
    final bottle = (createResult as BottleCreated).bottle;
    File(_joinTestPath(bottle.path, const ['drive_c', 'steam.txt']))
      ..createSync(recursive: true)
      ..writeAsStringSync('installed');
    final archivePath = _joinTestPath(tempDirectory.path, const [
      'steam.konyak-bottle.tar',
    ]);

    final result = runCli([
      'export-bottle-archive',
      'steam',
      '--archive',
      archivePath,
      '--json',
    ], bottleRepository: repository);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'bottleArchive': {'bottleId': 'steam', 'archivePath': archivePath},
    });
    expect(File(archivePath).existsSync(), isTrue);
    final listing = Process.runSync('tar', ['-tf', archivePath]);
    expect(listing.exitCode, 0);
    expect(listing.stdout.toString(), contains('steam/metadata.json'));
    expect(listing.stdout.toString(), contains('steam/drive_c/steam.txt'));
  });

  test('import-bottle-archive --json imports a bottle into the repository', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-bottle-import-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final sourceBottlePath = _joinTestPath(tempDirectory.path, const [
      'archive-source',
      'steam',
    ]);
    final sourceBottle = BottleRecord(
      id: 'steam',
      name: 'Steam',
      path: sourceBottlePath,
      windowsVersion: 'win10',
    );
    Directory(
      _joinTestPath(sourceBottlePath, const ['drive_c']),
    ).createSync(recursive: true);
    File(
      _joinTestPath(sourceBottlePath, const ['drive_c', 'steam.txt']),
    ).writeAsStringSync('installed');
    _writeTestBottleMetadata(sourceBottle);
    final archivePath = _joinTestPath(tempDirectory.path, const [
      'steam.konyak-bottle.tar',
    ]);
    final archiveResult = Process.runSync('tar', [
      '-cf',
      archivePath,
      '-C',
      _joinTestPath(tempDirectory.path, const ['archive-source']),
      'steam',
    ]);
    expect(archiveResult.exitCode, 0);
    final repository = FileBottleRepository(
      dataHome: _joinTestPath(tempDirectory.path, const ['data']),
    );

    final result = runCli([
      'import-bottle-archive',
      '--archive',
      archivePath,
      '--json',
    ], bottleRepository: repository);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    final imported = payload['bottle'] as Map<String, Object?>;
    final importedPath = _joinTestPath(tempDirectory.path, const [
      'data',
      'bottles',
      'steam',
    ]);
    expect(imported['id'], 'steam');
    expect(imported['name'], 'Steam');
    expect(imported['path'], importedPath);
    expect(
      File(
        _joinTestPath(importedPath, const ['drive_c', 'steam.txt']),
      ).readAsStringSync(),
      'installed',
    );
    expect(repository.findBottle('steam')?.path, importedPath);
  });

  test('inspect-bottle --json returns a versioned bottle detail contract', () {
    final result = runCli(
      const ['inspect-bottle', 'steam', '--json'],
      bottleCatalog: const StaticBottleCatalog([
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: '/home/user/.local/share/konyak/bottles/steam',
          windowsVersion: 'win10',
        ),
      ]),
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'bottle': {
        'id': 'steam',
        'name': 'Steam',
        'path': '/home/user/.local/share/konyak/bottles/steam',
        'windowsVersion': 'win10',
      },
    });
  });

  test('inspect-bottle --json reads registry-backed bottle settings', () {
    final runner = RecordingProgramRunner(
      results: const [
        ProgramRunCompleted(
          processExitCode: 0,
          stdout: '''
HKEY_CURRENT_USER\\Software\\Wine
    Version    REG_SZ    win11
''',
        ),
        ProgramRunCompleted(
          processExitCode: 0,
          stdout: '''
HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows NT\\CurrentVersion
    CurrentBuild    REG_SZ    22631
''',
        ),
        ProgramRunCompleted(
          processExitCode: 0,
          stdout: '''
HKEY_CURRENT_USER\\Software\\Wine\\Mac Driver
    RetinaMode    REG_SZ    y
''',
        ),
        ProgramRunCompleted(
          processExitCode: 0,
          stdout: '''
HKEY_CURRENT_USER\\Control Panel\\Desktop
    LogPixels    REG_DWORD    0x90
''',
        ),
      ],
    );

    final result = runCli(
      const ['inspect-bottle', 'steam', '--json'],
      bottleCatalog: const StaticBottleCatalog([
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: '/Users/user/Library/Application Support/Konyak/Bottles/Steam',
          windowsVersion: 'win10',
        ),
      ]),
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
        environment: const {'KONYAK_MACOS_WINE_ROOT': '/runtime'},
      ),
      programRunner: runner,
    );

    expect(result.exitCode, 0);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload['bottle'], {
      'id': 'steam',
      'name': 'Steam',
      'path': '/Users/user/Library/Application Support/Konyak/Bottles/Steam',
      'windowsVersion': 'win11',
      'runtimeSettings': {
        'enhancedSync': 'msync',
        'metalHud': false,
        'metalTrace': false,
        'avxEnabled': false,
        'dxrEnabled': false,
        'dxvk': false,
        'dxvkAsync': true,
        'dxvkHud': 'off',
        'buildVersion': 22631,
        'retinaMode': true,
        'dpiScaling': 144,
      },
    });
    expect(runner.requests.map((request) => request.arguments), [
      ['reg', 'query', r'HKCU\Software\Wine', '/v', 'Version'],
      [
        'reg',
        'query',
        r'HKLM\Software\Microsoft\Windows NT\CurrentVersion',
        '/v',
        'CurrentBuild',
      ],
      ['reg', 'query', r'HKCU\Software\Wine\Mac Driver', '/v', 'RetinaMode'],
      ['reg', 'query', r'HKCU\Control Panel\Desktop', '/v', 'LogPixels'],
    ]);
  });

  test('inspect-bottle --json returns a machine-readable not-found error', () {
    final result = runCli(const ['inspect-bottle', 'missing', '--json']);

    expect(result.exitCode, 66);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'error': {
        'code': 'bottleNotFound',
        'message': 'Bottle not found.',
        'bottleId': 'missing',
      },
    });
  });

  test('set-windows-version --json applies registry-backed setting', () {
    final repository = MemoryBottleRepository(
      dataHome: '/home/user/.local/share/konyak',
      bottles: const [
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
        'set-windows-version',
        'steam',
        '--windows-version',
        'win11',
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
        environment: const {'KONYAK_MACOS_WINE_ROOT': '/runtime'},
      ),
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(runner.requests.map((request) => request.arguments), [
      [
        'reg',
        'add',
        r'HKCU\Software\Wine',
        '-v',
        'Version',
        '-t',
        'REG_SZ',
        '-d',
        'win11',
        '-f',
      ],
    ]);
    expect(repository.findBottle('steam')?.windowsVersion, 'win11');
  });

  test('create-bottle --json creates a bottle in the repository', () {
    final repository = MemoryBottleRepository(
      dataHome: '/home/user/.local/share/konyak',
    );

    final result = runCli(const [
      'create-bottle',
      '--name',
      'Steam',
      '--json',
    ], bottleRepository: repository);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'bottle': {
        'id': 'steam',
        'name': 'Steam',
        'path': '/home/user/.local/share/konyak/bottles/steam',
        'windowsVersion': 'win10',
      },
    });

    final listResult = runCli(const [
      'list-bottles',
      '--json',
    ], bottleRepository: repository);
    final listPayload = jsonDecode(listResult.stdout) as Map<String, Object?>;
    expect(listPayload, {
      'schemaVersion': 1,
      'bottles': [
        {
          'id': 'steam',
          'name': 'Steam',
          'path': '/home/user/.local/share/konyak/bottles/steam',
          'windowsVersion': 'win10',
        },
      ],
    });
  });

  test('create-bottle --json supports non-ASCII bottle names', () {
    final repository = MemoryBottleRepository(
      dataHome: '/home/user/.local/share/konyak',
    );

    final result = runCli(const [
      'create-bottle',
      '--name',
      '日本語',
      '--json',
    ], bottleRepository: repository);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'bottle': {
        'id': '日本語',
        'name': '日本語',
        'path': '/home/user/.local/share/konyak/bottles/日本語',
        'windowsVersion': 'win10',
      },
    });

    expect(repository.findBottle('日本語')?.name, '日本語');
  });

  test('create-bottle --json initializes the Wine prefix when configured', () {
    final repository = MemoryBottleRepository(
      dataHome: '/home/user/.local/share/konyak',
    );
    final initializer = RecordingBottlePrefixInitializer(
      result: const BottlePrefixInitialized(),
    );

    final result = runCli(
      const ['create-bottle', '--name', 'Steam', '--json'],
      bottleRepository: repository,
      bottlePrefixInitializer: initializer,
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(initializer.lastBottle?.id, 'steam');
    expect(
      initializer.lastBottle?.path,
      '/home/user/.local/share/konyak/bottles/steam',
    );

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload['bottle'], {
      'id': 'steam',
      'name': 'Steam',
      'path': '/home/user/.local/share/konyak/bottles/steam',
      'windowsVersion': 'win10',
    });
  });

  test('create-bottle --json reports prefix initialization failures', () {
    final repository = MemoryBottleRepository(
      dataHome: '/home/user/.local/share/konyak',
    );
    final initializer = RecordingBottlePrefixInitializer(
      result: const BottlePrefixInitializationFailed('wineboot failed'),
    );

    final result = runCli(
      const ['create-bottle', '--name', 'Steam', '--json'],
      bottleRepository: repository,
      bottlePrefixInitializer: initializer,
    );

    expect(result.exitCode, 75);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'error': {
        'code': 'bottlePrefixInitializationFailed',
        'message': 'wineboot failed',
        'bottleId': 'steam',
        'bottlePath': '/home/user/.local/share/konyak/bottles/steam',
      },
    });
  });

  test('create-bottle --json accepts an explicit Windows version', () {
    final result = runCli(
      const [
        'create-bottle',
        '--name',
        'Steam',
        '--windows-version',
        'win11',
        '--json',
      ],
      bottleRepository: MemoryBottleRepository(
        dataHome: '/home/user/.local/share/konyak',
      ),
    );

    expect(result.exitCode, 0);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload['bottle'], {
      'id': 'steam',
      'name': 'Steam',
      'path': '/home/user/.local/share/konyak/bottles/steam',
      'windowsVersion': 'win11',
    });
  });

  test('set-runtime-settings --json updates bottle runtime settings', () {
    final repository = MemoryBottleRepository(
      dataHome: '/home/user/.local/share/konyak',
      bottles: const [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: '/home/user/.local/share/konyak/bottles/steam',
          windowsVersion: 'win10',
        ),
      ],
    );

    final settingsJson = jsonEncode({
      'enhancedSync': 'esync',
      'metalHud': true,
      'metalTrace': true,
      'avxEnabled': true,
      'dxrEnabled': true,
      'dxvk': true,
      'dxvkAsync': false,
      'dxvkHud': 'fps',
      'buildVersion': 19045,
      'retinaMode': true,
      'dpiScaling': 144,
    });

    final result = runCli([
      'set-runtime-settings',
      'steam',
      '--settings-json',
      settingsJson,
      '--json',
    ], bottleRepository: repository);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload['bottle'], {
      'id': 'steam',
      'name': 'Steam',
      'path': '/home/user/.local/share/konyak/bottles/steam',
      'windowsVersion': 'win10',
      'runtimeSettings': {
        'enhancedSync': 'esync',
        'metalHud': true,
        'metalTrace': true,
        'avxEnabled': true,
        'dxrEnabled': true,
        'dxvk': true,
        'dxvkAsync': false,
        'dxvkHud': 'fps',
        'buildVersion': 19045,
        'retinaMode': true,
        'dpiScaling': 144,
      },
    });
    expect(
      repository.findBottle('steam')?.runtimeSettings,
      const BottleRuntimeSettings(
        enhancedSync: 'esync',
        metalHud: true,
        metalTrace: true,
        avxEnabled: true,
        dxrEnabled: true,
        dxvk: true,
        dxvkAsync: false,
        dxvkHud: 'fps',
        buildVersion: 19045,
        retinaMode: true,
        dpiScaling: 144,
      ),
    );
  });

  test('set-runtime-settings --json applies registry-backed settings', () {
    final repository = MemoryBottleRepository(
      dataHome: '/home/user/.local/share/konyak',
      bottles: const [
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
      [
        'set-runtime-settings',
        'steam',
        '--settings-json',
        jsonEncode({
          'buildVersion': 22631,
          'retinaMode': true,
          'dpiScaling': 144,
        }),
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
        environment: const {'KONYAK_MACOS_WINE_ROOT': '/runtime'},
      ),
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(runner.requests.map((request) => request.arguments), [
      [
        'reg',
        'add',
        r'HKCU\Software\Wine',
        '-v',
        'Version',
        '-t',
        'REG_SZ',
        '-d',
        'win11',
        '-f',
      ],
      [
        'reg',
        'add',
        r'HKLM\Software\Microsoft\Windows NT\CurrentVersion',
        '-v',
        'CurrentBuild',
        '-t',
        'REG_SZ',
        '-d',
        '22631',
        '-f',
      ],
      [
        'reg',
        'add',
        r'HKLM\Software\Microsoft\Windows NT\CurrentVersion',
        '-v',
        'CurrentBuildNumber',
        '-t',
        'REG_SZ',
        '-d',
        '22631',
        '-f',
      ],
      [
        'reg',
        'add',
        r'HKCU\Software\Wine\Mac Driver',
        '-v',
        'RetinaMode',
        '-t',
        'REG_SZ',
        '-d',
        'y',
        '-f',
      ],
      [
        'reg',
        'add',
        r'HKCU\Control Panel\Desktop',
        '-v',
        'LogPixels',
        '-t',
        'REG_DWORD',
        '-d',
        '144',
        '-f',
      ],
    ]);
    expect(
      runner.requests.map((request) => request.environment['WINEPREFIX']),
      everyElement(
        '/Users/user/Library/Application Support/Konyak/Bottles/Steam',
      ),
    );
    expect(
      repository.findBottle('steam')?.runtimeSettings,
      const BottleRuntimeSettings(
        buildVersion: 22631,
        retinaMode: true,
        dpiScaling: 144,
      ),
    );
  });

  test('set-runtime-settings --json maps build version to winecfg version', () {
    final repository = MemoryBottleRepository(
      dataHome: '/home/user/.local/share/konyak',
      bottles: const [
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
      [
        'set-runtime-settings',
        'steam',
        '--settings-json',
        jsonEncode({'buildVersion': 9200}),
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
        environment: const {'KONYAK_MACOS_WINE_ROOT': '/runtime'},
      ),
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(
      runner.requests.map((request) => request.arguments).toList(),
      contains(
        equals([
          'reg',
          'add',
          r'HKCU\Software\Wine',
          '-v',
          'Version',
          '-t',
          'REG_SZ',
          '-d',
          'win8',
          '-f',
        ]),
      ),
    );
  });

  test(
    'set-runtime-settings --json does not persist failed registry writes',
    () {
      final repository = MemoryBottleRepository(
        dataHome: '/home/user/.local/share/konyak',
        bottles: const [
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
        result: const ProgramRunCompleted(processExitCode: 1),
      );

      final result = runCli(
        [
          'set-runtime-settings',
          'steam',
          '--settings-json',
          jsonEncode({'retinaMode': true}),
          '--json',
        ],
        bottleRepository: repository,
        programRunPlanner: ProgramRunPlanner(
          hostPlatform: KonyakHostPlatform.macos,
          environment: const {'KONYAK_MACOS_WINE_ROOT': '/runtime'},
        ),
        programRunner: runner,
      );

      expect(result.exitCode, 75);
      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      expect(payload['error'], containsPair('code', 'registryUpdateFailed'));
      expect(
        repository.findBottle('steam')?.runtimeSettings,
        const BottleRuntimeSettings(),
      );
    },
  );

  test('create-bottle --json returns a machine-readable conflict', () {
    final repository = MemoryBottleRepository(
      dataHome: '/home/user/.local/share/konyak',
    );
    runCli(const [
      'create-bottle',
      '--name',
      'Steam',
      '--json',
    ], bottleRepository: repository);

    final result = runCli(const [
      'create-bottle',
      '--name',
      'Steam',
      '--json',
    ], bottleRepository: repository);

    expect(result.exitCode, 73);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'error': {
        'code': 'bottleAlreadyExists',
        'message': 'Bottle already exists.',
        'bottleId': 'steam',
      },
    });
  });

  test('delete-bottle --json deletes a bottle from the repository', () {
    final repository = MemoryBottleRepository(
      dataHome: '/home/user/.local/share/konyak',
    );
    runCli(const [
      'create-bottle',
      '--name',
      'Steam',
      '--json',
    ], bottleRepository: repository);

    final result = runCli(const [
      'delete-bottle',
      'steam',
      '--json',
    ], bottleRepository: repository);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'deletedBottle': {
        'id': 'steam',
        'name': 'Steam',
        'path': '/home/user/.local/share/konyak/bottles/steam',
        'windowsVersion': 'win10',
      },
    });

    final listResult = runCli(const [
      'list-bottles',
      '--json',
    ], bottleRepository: repository);
    final listPayload = jsonDecode(listResult.stdout) as Map<String, Object?>;
    expect(listPayload, {'schemaVersion': 1, 'bottles': <Object?>[]});
  });

  test('delete-bottle --json returns not-found for missing bottles', () {
    final result = runCli(
      const ['delete-bottle', 'missing', '--json'],
      bottleRepository: MemoryBottleRepository(
        dataHome: '/home/user/.local/share/konyak',
      ),
    );

    expect(result.exitCode, 66);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'error': {
        'code': 'bottleNotFound',
        'message': 'Bottle not found.',
        'bottleId': 'missing',
      },
    });
  });

  test('rename-bottle --json renames and rekeys a bottle', () {
    final repository = MemoryBottleRepository(
      dataHome: '/home/user/.local/share/konyak',
    );
    runCli(const [
      'create-bottle',
      '--name',
      'Steam',
      '--json',
    ], bottleRepository: repository);

    final result = runCli(const [
      'rename-bottle',
      'steam',
      '--name',
      'Steam Games',
      '--json',
    ], bottleRepository: repository);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'bottle': {
        'id': 'steam-games',
        'name': 'Steam Games',
        'path': '/home/user/.local/share/konyak/bottles/steam-games',
        'windowsVersion': 'win10',
      },
    });
    expect(repository.findBottle('steam'), isNull);
    expect(repository.findBottle('steam-games')?.name, 'Steam Games');
  });

  test('rename-bottle --json returns a machine-readable conflict', () {
    final repository = MemoryBottleRepository(
      dataHome: '/home/user/.local/share/konyak',
    );
    runCli(const [
      'create-bottle',
      '--name',
      'Steam',
      '--json',
    ], bottleRepository: repository);
    runCli(const [
      'create-bottle',
      '--name',
      'Epic',
      '--json',
    ], bottleRepository: repository);

    final result = runCli(const [
      'rename-bottle',
      'steam',
      '--name',
      'Epic',
      '--json',
    ], bottleRepository: repository);

    expect(result.exitCode, 73);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'error': {
        'code': 'bottleAlreadyExists',
        'message': 'Bottle already exists.',
        'bottleId': 'epic',
      },
    });
  });

  test('move-bottle --json updates the bottle path', () {
    final repository = MemoryBottleRepository(
      dataHome: '/home/user/.local/share/konyak',
    );
    runCli(const [
      'create-bottle',
      '--name',
      'Steam',
      '--json',
    ], bottleRepository: repository);

    final result = runCli(const [
      'move-bottle',
      'steam',
      '--path',
      '/mnt/games/Steam',
      '--json',
    ], bottleRepository: repository);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'bottle': {
        'id': 'steam',
        'name': 'Steam',
        'path': '/mnt/games/Steam',
        'windowsVersion': 'win10',
      },
    });
    expect(repository.findBottle('steam')?.path, '/mnt/games/Steam');
  });

  test('set-windows-version --json updates a bottle in the repository', () {
    final repository = MemoryBottleRepository(
      dataHome: '/home/user/.local/share/konyak',
    );
    runCli(const [
      'create-bottle',
      '--name',
      'Steam',
      '--json',
    ], bottleRepository: repository);

    final result = runCli(const [
      'set-windows-version',
      'steam',
      '--windows-version',
      'win11',
      '--json',
    ], bottleRepository: repository);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'bottle': {
        'id': 'steam',
        'name': 'Steam',
        'path': '/home/user/.local/share/konyak/bottles/steam',
        'windowsVersion': 'win11',
      },
    });
  });

  test('set-windows-version --json returns not-found for missing bottles', () {
    final result = runCli(
      const [
        'set-windows-version',
        'missing',
        '--windows-version',
        'win11',
        '--json',
      ],
      bottleRepository: MemoryBottleRepository(
        dataHome: '/home/user/.local/share/konyak',
      ),
    );

    expect(result.exitCode, 66);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'error': {
        'code': 'bottleNotFound',
        'message': 'Bottle not found.',
        'bottleId': 'missing',
      },
    });
  });

  test('pin-program --json adds a pinned program to the bottle record', () {
    final repository = MemoryBottleRepository(
      dataHome: '/home/user/.local/share/konyak',
    );
    runCli(const [
      'create-bottle',
      '--name',
      'Steam',
      '--json',
    ], bottleRepository: repository);

    final result = runCli(const [
      'pin-program',
      'steam',
      '--name',
      'Steam',
      '--program',
      '/downloads/Steam.exe',
      '--json',
    ], bottleRepository: repository);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'bottle': {
        'id': 'steam',
        'name': 'Steam',
        'path': '/home/user/.local/share/konyak/bottles/steam',
        'windowsVersion': 'win10',
        'pinnedPrograms': [
          {'name': 'Steam', 'path': '/downloads/Steam.exe', 'removable': false},
        ],
      },
    });
    expect(
      repository.findBottle('steam')?.pinnedPrograms.single.path,
      '/downloads/Steam.exe',
    );
  });

  test('pin-program --json on macOS writes a Launchpad app launcher', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-macos-pinned-launcher-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final appBundle = _createTestMacosAppBundle(tempDirectory.path);
    final iconPath = _joinTestPath(tempDirectory.path, const [
      'steam-icon.icns',
    ]);
    File(iconPath).writeAsBytesSync(const <int>[0, 1, 2, 3]);
    final repository = MemoryBottleRepository(
      dataHome: _joinTestPath(tempDirectory.path, const ['data']),
      programMetadataExtractor: FixedProgramMetadataExtractor(
        programPath: '/downloads/Steam.exe',
        metadata: ProgramMetadataRecord(iconPath: iconPath),
      ),
    );
    runCli(const [
      'create-bottle',
      '--name',
      'Steam',
      '--json',
    ], bottleRepository: repository);

    final result = runCli(
      const [
        'pin-program',
        'steam',
        '--name',
        'Steam',
        '--program',
        '/downloads/Steam.exe',
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
        environment: {
          'HOME': tempDirectory.path,
          'KONYAK_APP_EXECUTABLE': _joinTestPath(appBundle.path, const [
            'Contents',
            'MacOS',
            'Konyak',
          ]),
        },
      ),
    );

    expect(result.exitCode, 0);

    final launcherBundle = _singleGeneratedMacosLauncher(tempDirectory.path);
    expect(launcherBundle.path, endsWith('/Steam.app'));

    final infoPlist = File(
      _joinTestPath(launcherBundle.path, const ['Contents', 'Info.plist']),
    ).readAsStringSync();
    expect(infoPlist, contains('<string>app.konyak.Konyak.pinned.'));
    expect(infoPlist, contains('<key>CFBundleDisplayName</key>'));
    expect(infoPlist, contains('<string>Steam</string>'));
    expect(infoPlist, contains('<key>CFBundleIconFile</key>'));
    expect(infoPlist, contains('<string>KonyakPinnedProgram.icns</string>'));
    expect(infoPlist, contains('<string>konyak-launcher</string>'));
    expect(
      File(
        _joinTestPath(launcherBundle.path, const [
          'Contents',
          'Resources',
          'KonyakPinnedProgram.icns',
        ]),
      ).readAsBytesSync(),
      const <int>[0, 1, 2, 3],
    );

    final manifest =
        jsonDecode(
              File(
                _joinTestPath(launcherBundle.path, const [
                  'Contents',
                  'Resources',
                  'konyak-launcher.json',
                ]),
              ).readAsStringSync(),
            )
            as Map<String, Object?>;
    expect(manifest['schemaVersion'], 1);
    expect(manifest['createdBy'], 'app.konyak.Konyak');
    expect(manifest['bottleId'], 'steam');
    expect(manifest['programName'], 'Steam');
    expect(manifest['programPath'], '/downloads/Steam.exe');
    expect(manifest['launcherId'], isA<String>());

    final launcherExecutable = File(
      _joinTestPath(launcherBundle.path, const [
        'Contents',
        'MacOS',
        'konyak-launcher',
      ]),
    );
    final launcherScript = launcherExecutable.readAsStringSync();
    expect(
      launcherScript,
      contains(
        _joinTestPath(appBundle.path, const [
          'Contents',
          'Resources',
          'konyak-cli',
        ]),
      ),
    );
    expect(launcherScript, contains('launch-pinned-program'));
    expect(launcherScript, contains(r'--manifest "$manifest" --json'));
    expect(launcherExecutable.statSync().mode & 0x40, isNonZero);
  });

  test('pin-program --json on macOS disambiguates duplicate app names', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-macos-pinned-duplicate-launcher-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final appBundle = _createTestMacosAppBundle(tempDirectory.path);
    final repository = MemoryBottleRepository(
      dataHome: _joinTestPath(tempDirectory.path, const ['data']),
    );
    runCli(const [
      'create-bottle',
      '--name',
      'Steam',
      '--json',
    ], bottleRepository: repository);
    runCli(const [
      'create-bottle',
      '--name',
      'Tools',
      '--json',
    ], bottleRepository: repository);
    final planner = ProgramRunPlanner(
      hostPlatform: KonyakHostPlatform.macos,
      environment: {
        'HOME': tempDirectory.path,
        'KONYAK_APP_EXECUTABLE': _joinTestPath(appBundle.path, const [
          'Contents',
          'MacOS',
          'Konyak',
        ]),
      },
    );

    runCli(
      const [
        'pin-program',
        'steam',
        '--name',
        'Steam',
        '--program',
        '/downloads/Steam.exe',
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: planner,
    );
    runCli(
      const [
        'pin-program',
        'tools',
        '--name',
        'Steam',
        '--program',
        '/downloads/ToolsSteam.exe',
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: planner,
    );

    final launcherNames = _generatedMacosLaunchers(
      tempDirectory.path,
    ).map((directory) => directory.path.split('/').last).toList();
    expect(launcherNames, const ['Steam (2).app', 'Steam.app']);
    final duplicateInfoPlist = File(
      _joinTestPath(
        _generatedMacosLaunchers(tempDirectory.path).first.path,
        const ['Contents', 'Info.plist'],
      ),
    ).readAsStringSync();
    expect(duplicateInfoPlist, contains('<string>Steam (2)</string>'));
  });

  test('pin-program --json on macOS writes a development CLI launcher', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-macos-pinned-dev-launcher-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final repository = MemoryBottleRepository(
      dataHome: _joinTestPath(tempDirectory.path, const ['data']),
    );
    runCli(const [
      'create-bottle',
      '--name',
      'Steam',
      '--json',
    ], bottleRepository: repository);

    final result = runCli(
      const [
        'pin-program',
        'steam',
        '--name',
        'Steam',
        '--program',
        '/downloads/Steam.exe',
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
        environment: {
          'HOME': tempDirectory.path,
          'KONYAK_PINNED_PROGRAM_LAUNCHER_EXECUTABLE': '/env/flutter/bin/dart',
          'KONYAK_PINNED_PROGRAM_LAUNCHER_ARGUMENTS_JSON':
              '["run","bin/konyak.dart"]',
          'KONYAK_PINNED_PROGRAM_LAUNCHER_WORKING_DIRECTORY':
              '/repo/packages/konyak_cli',
        },
      ),
    );

    expect(result.exitCode, 0);
    final launcherExecutable = File(
      _joinTestPath(
        _singleGeneratedMacosLauncher(tempDirectory.path).path,
        const ['Contents', 'MacOS', 'konyak-launcher'],
      ),
    );
    final launcherScript = launcherExecutable.readAsStringSync();
    expect(launcherScript, contains("cd '/repo/packages/konyak_cli'"));
    expect(
      launcherScript,
      contains(
        "exec '/env/flutter/bin/dart' 'run' 'bin/konyak.dart' launch-pinned-program",
      ),
    );
  });

  test('list-bottles --json on macOS refreshes app launchers', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-macos-pinned-list-refresh-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final repository = MemoryBottleRepository(
      dataHome: _joinTestPath(tempDirectory.path, const ['data']),
    );
    runCli(const [
      'create-bottle',
      '--name',
      'Steam',
      '--json',
    ], bottleRepository: repository);
    runCli(
      const [
        'pin-program',
        'steam',
        '--name',
        'Steam',
        '--program',
        '/downloads/Steam.exe',
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.linux,
        environment: {'HOME': tempDirectory.path},
      ),
    );

    final result = runCli(
      const ['list-bottles', '--json'],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
        environment: {
          'HOME': tempDirectory.path,
          'KONYAK_PINNED_PROGRAM_LAUNCHER_EXECUTABLE': '/env/bin/dart',
          'KONYAK_PINNED_PROGRAM_LAUNCHER_ARGUMENTS_JSON':
              '["run","bin/konyak.dart"]',
          'KONYAK_PINNED_PROGRAM_LAUNCHER_WORKING_DIRECTORY':
              '/repo/packages/konyak_cli',
        },
      ),
    );

    expect(result.exitCode, 0);
    final launcherScript = File(
      _joinTestPath(
        _singleGeneratedMacosLauncher(tempDirectory.path).path,
        const ['Contents', 'MacOS', 'konyak-launcher'],
      ),
    ).readAsStringSync();
    expect(launcherScript, contains("exec '/env/bin/dart' 'run'"));
  });

  test('unpin-program --json on macOS removes the Launchpad app launcher', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-macos-pinned-unpin-launcher-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final appBundle = _createTestMacosAppBundle(tempDirectory.path);
    final repository = MemoryBottleRepository(
      dataHome: _joinTestPath(tempDirectory.path, const ['data']),
    );
    runCli(const [
      'create-bottle',
      '--name',
      'Steam',
      '--json',
    ], bottleRepository: repository);
    final planner = ProgramRunPlanner(
      hostPlatform: KonyakHostPlatform.macos,
      environment: {
        'HOME': tempDirectory.path,
        'KONYAK_APP_EXECUTABLE': _joinTestPath(appBundle.path, const [
          'Contents',
          'MacOS',
          'Konyak',
        ]),
      },
    );
    runCli(
      const [
        'pin-program',
        'steam',
        '--name',
        'Steam',
        '--program',
        '/downloads/Steam.exe',
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: planner,
    );

    expect(_generatedMacosLaunchers(tempDirectory.path), hasLength(1));

    final result = runCli(
      const [
        'unpin-program',
        'steam',
        '--program',
        '/downloads/Steam.exe',
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: planner,
    );

    expect(result.exitCode, 0);
    expect(_generatedMacosLaunchers(tempDirectory.path), isEmpty);
  });

  test('launch-pinned-program --json runs the pinned program manifest', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-macos-pinned-launch-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final appBundle = _createTestMacosAppBundle(tempDirectory.path);
    final repository = MemoryBottleRepository(
      dataHome: _joinTestPath(tempDirectory.path, const ['data']),
    );
    runCli(const [
      'create-bottle',
      '--name',
      'Steam',
      '--json',
    ], bottleRepository: repository);
    final planner = ProgramRunPlanner(
      hostPlatform: KonyakHostPlatform.macos,
      environment: {
        'HOME': tempDirectory.path,
        'KONYAK_APP_EXECUTABLE': _joinTestPath(appBundle.path, const [
          'Contents',
          'MacOS',
          'Konyak',
        ]),
      },
    );
    runCli(
      const [
        'pin-program',
        'steam',
        '--name',
        'Steam',
        '--program',
        '/downloads/Steam.exe',
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: planner,
    );
    final manifestPath = _joinTestPath(
      _singleGeneratedMacosLauncher(tempDirectory.path).path,
      const ['Contents', 'Resources', 'konyak-launcher.json'],
    );
    final runner = RecordingProgramRunner(
      result: const ProgramRunCompleted(processExitCode: 0),
    );

    final result = runCli(
      ['launch-pinned-program', '--manifest', manifestPath, '--json'],
      bottleRepository: repository,
      programRunPlanner: planner,
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload['schemaVersion'], 1);
    expect(payload['run'], isA<Map<String, Object?>>());
    expect(runner.lastRequest?.bottleId, 'steam');
    expect(runner.lastRequest?.programPath, '/downloads/Steam.exe');
    expect(runner.lastRequest?.runnerKind, 'macosWine');
  });

  test('pin-program --json extracts an icon for pinned PE programs', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'konyak-pin-program-icon-test-',
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
        ),
      ],
    );

    final result = runCli([
      'pin-program',
      'steam',
      '--name',
      'Fixture',
      '--program',
      programPath,
      '--json',
    ], bottleRepository: repository);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    final bottle = payload['bottle'] as Map<String, Object?>;
    final pinnedPrograms = bottle['pinnedPrograms'] as List<Object?>;
    final pinnedProgram = pinnedPrograms.single as Map<String, Object?>;
    final iconPath = pinnedProgram['iconPath'];
    expect(iconPath, isA<String>());
    expect(iconPath as String, startsWith('$bottlePath/cache/icons/'));
    final iconBytes = File(iconPath).readAsBytesSync();
    expect(iconBytes.take(4), const [0, 0, 1, 0]);
  });

  test(
    'pin-program --json resolves Wine shortcuts before extracting icons',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'konyak-pin-shortcut-icon-test-',
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
      final shortcutPath = _joinTestPath(bottlePath, const [
        'drive_c',
        'ProgramData',
        'Microsoft',
        'Windows',
        'Start Menu',
        'Programs',
        'Fixture.lnk',
      ]);
      File(shortcutPath)
        ..createSync(recursive: true)
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

      final result = runCli([
        'pin-program',
        'steam',
        '--name',
        'Fixture',
        '--program',
        shortcutPath,
        '--json',
      ], bottleRepository: repository);

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);

      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      final bottle = payload['bottle'] as Map<String, Object?>;
      final pinnedPrograms = bottle['pinnedPrograms'] as List<Object?>;
      final pinnedProgram = pinnedPrograms.single as Map<String, Object?>;

      expect(pinnedProgram['path'], shortcutPath);
      final iconPath = pinnedProgram['iconPath'];
      expect(iconPath, isA<String>());
      expect(iconPath as String, startsWith('$bottlePath/cache/icons/'));
      final iconBytes = File(iconPath).readAsBytesSync();
      expect(iconBytes.take(4), const [0, 0, 1, 0]);
    },
  );

  test(
    'list-bottles --json extracts icons for existing pinned PE programs',
    () {
      final tempDirectory = Directory.systemTemp.createTempSync(
        'konyak-existing-pinned-program-icon-test-',
      );
      addTearDown(() {
        if (tempDirectory.existsSync()) {
          tempDirectory.deleteSync(recursive: true);
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

      final result = runCli(const [
        'list-bottles',
        '--json',
      ], bottleRepository: repository);

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);

      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      final bottles = payload['bottles'] as List<Object?>;
      final bottle = bottles.single as Map<String, Object?>;
      final pinnedPrograms = bottle['pinnedPrograms'] as List<Object?>;
      final pinnedProgram = pinnedPrograms.single as Map<String, Object?>;
      final iconPath = pinnedProgram['iconPath'];
      expect(iconPath, isA<String>());
      expect(iconPath as String, startsWith('$bottlePath/cache/icons/'));
    },
  );

  test('list-bottles --json extracts icons for existing pinned shortcuts', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-existing-pinned-shortcut-icon-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
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
    final shortcutPath = _joinTestPath(bottlePath, const [
      'drive_c',
      'ProgramData',
      'Microsoft',
      'Windows',
      'Start Menu',
      'Programs',
      'Fixture.lnk',
    ]);
    File(shortcutPath)
      ..createSync(recursive: true)
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
          pinnedPrograms: [
            PinnedProgramRecord(name: 'Fixture', path: shortcutPath),
          ],
        ),
      ],
    );

    final result = runCli(const [
      'list-bottles',
      '--json',
    ], bottleRepository: repository);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    final bottles = payload['bottles'] as List<Object?>;
    final bottle = bottles.single as Map<String, Object?>;
    final pinnedPrograms = bottle['pinnedPrograms'] as List<Object?>;
    final pinnedProgram = pinnedPrograms.single as Map<String, Object?>;

    expect(pinnedProgram['path'], shortcutPath);
    final iconPath = pinnedProgram['iconPath'];
    expect(iconPath, isA<String>());
    expect(iconPath as String, startsWith('$bottlePath/cache/icons/'));
  });

  test(
    'unpin-program --json removes a pinned program from the bottle record',
    () {
      final repository = MemoryBottleRepository(
        dataHome: '/home/user/.local/share/konyak',
        bottles: const [
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
        'unpin-program',
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
        'bottle': {
          'id': 'steam',
          'name': 'Steam',
          'path': '/home/user/.local/share/konyak/bottles/steam',
          'windowsVersion': 'win10',
        },
      });
      expect(repository.findBottle('steam')?.pinnedPrograms, isEmpty);
    },
  );

  test('rename-pinned-program --json renames a pinned program', () {
    final repository = MemoryBottleRepository(
      dataHome: '/home/user/.local/share/konyak',
      bottles: const [
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
      'rename-pinned-program',
      'steam',
      '--program',
      '/downloads/Steam.exe',
      '--name',
      'Steam Client',
      '--json',
    ], bottleRepository: repository);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'bottle': {
        'id': 'steam',
        'name': 'Steam',
        'path': '/home/user/.local/share/konyak/bottles/steam',
        'windowsVersion': 'win10',
        'pinnedPrograms': [
          {
            'name': 'Steam Client',
            'path': '/downloads/Steam.exe',
            'removable': false,
          },
        ],
      },
    });
    expect(
      repository.findBottle('steam')?.pinnedPrograms.single.name,
      'Steam Client',
    );
  });

  test('get-program-settings --json returns default program settings', () {
    final repository = MemoryBottleRepository(
      dataHome: '/home/user/.local/share/konyak',
      bottles: const [
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

  test('set-program-settings --json persists program settings', () {
    final repository = MemoryBottleRepository(
      dataHome: '/home/user/.local/share/konyak',
      bottles: const [
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
    expect(settings.settings.environment, {
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
      bottles: const [
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
      const ProgramSettingsUpdateRequest(
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
    });
  });

  test('run-program --json uses the Konyak macOS Wine startup path on macOS', () {
    final repository = MemoryBottleRepository(
      dataHome: '/Users/user/Library/Application Support/Konyak',
      bottles: const [
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
      runner.lastRequest?.workingDirectory,
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
      bottles: const [
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
  });

  test('run-bottle-command --json launches winecfg through macOS Wine', () {
    final repository = MemoryBottleRepository(
      dataHome: '/Users/user/Library/Application Support/Konyak',
      bottles: const [
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
    const bottle = BottleRecord(
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
      request.workingDirectory,
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
      bottles: const [
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
      bottles: const [
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
        environment: {'HOME': '/home/user'},
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
    const bottle = BottleRecord(
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
        'KONYAK_LINUX_WINE_HOME': '/opt/konyak/runtime/linux-wine',
      },
    ).plan(bottle: bottle, programPath: 'C:/Program Files/Steam/steam.exe');

    expect(request, isNotNull);
    expect(request?.executable, '/opt/konyak/runtime/linux-wine/bin/wine');
    expect(
      request?.environment,
      containsPair('PATH', '/opt/konyak/runtime/linux-wine/bin:/usr/bin:/bin'),
    );
    expect(
      request?.environment,
      containsPair(
        'WINEPREFIX',
        '/home/user/.local/share/konyak/bottles/steam',
      ),
    );
  });

  test('run-bottle-command --json launches winetricks with bottle env', () {
    final repository = MemoryBottleRepository(
      dataHome: '/Users/user/Library/Application Support/Konyak',
      bottles: const [
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
      runner.lastRequest?.workingDirectory,
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
      bottles: const [
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
      bottles: const [
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
      bottles: const [
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
      bottles: const [
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
      bottles: const [
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
      bottles: const [
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
      bottles: const [
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
          'Exec=env "WINEPREFIX=${repository.findBottle('steam')!.path}" wine "$programPath"',
        ),
      );
      expect(
        launcher,
        contains('Icon=${repository.findBottle('steam')!.path}/cache/icons/'),
      );
    },
  );

  test('program runner writes a Konyak completed launch log', () {
    final logDirectory = Directory.systemTemp.createTempSync('konyak-run-log-');
    addTearDown(() async {
      if (await logDirectory.exists()) {
        await logDirectory.delete(recursive: true);
      }
    });

    final logPath = _joinTestPath(logDirectory.path, const ['latest.log']);
    final result = const DartIoProgramRunner().run(
      ProgramRunRequest(
        bottleId: 'steam',
        programPath: '/downloads/setup.exe',
        runnerKind: 'macosWine',
        executable: Platform.resolvedExecutable,
        arguments: const ['--version'],
        environment: const <String, String>{'WINEPREFIX': '/bottles/steam'},
        logPath: logPath,
        workingDirectory: logDirectory.path,
      ),
    );

    expect(result, isA<ProgramRunCompleted>());

    final log = File(logPath).readAsStringSync();
    expect(log, contains('Konyak Wine Run Log'));
    expect(log, contains('[Process]'));
    expect(log, contains('Runner Kind: macosWine'));
    expect(log, contains('Executable: ${Platform.resolvedExecutable}'));
    expect(log, contains('Working Directory: ${logDirectory.path}'));
    expect(log, contains('Arguments: ["--version"]'));
    expect(log, contains('[Environment]'));
    expect(log, contains('WINEPREFIX=/bottles/steam'));
    expect(log, contains('Process Exit Code: 0'));
  });

  test('program runner reports a missing executable with the runner name', () {
    final logDirectory = Directory.systemTemp.createTempSync(
      'konyak-missing-runner-',
    );
    addTearDown(() async {
      if (await logDirectory.exists()) {
        await logDirectory.delete(recursive: true);
      }
    });
    final logPath = _joinTestPath(logDirectory.path, const ['latest.log']);

    final result = const DartIoProgramRunner().run(
      ProgramRunRequest(
        bottleId: 'steam',
        programPath: '/downloads/setup.exe',
        runnerKind: 'wine',
        executable: '/definitely/missing/konyak-runner',
        arguments: const ['/downloads/setup.exe'],
        environment: const <String, String>{},
        logPath: logPath,
      ),
    );

    expect(result, isA<ProgramRunFailed>());
    final failure = result as ProgramRunFailed;
    expect(
      failure.message,
      'Runner executable `/definitely/missing/konyak-runner` was not found.',
    );

    final log = File(logPath).readAsStringSync();
    expect(log, contains('Startup Error: Runner executable'));
    expect(log, contains('Executable: /definitely/missing/konyak-runner'));
  });

  test(
    'executable creates and lists bottles in the configured data home',
    () async {
      final dataHome = await Directory.systemTemp.createTemp(
        'konyak-cli-test-',
      );

      addTearDown(() async {
        if (await dataHome.exists()) {
          await dataHome.delete(recursive: true);
        }
      });
      final fakeRuntimeRoot = Directory(
        _joinTestPath(dataHome.path, const ['runtime']),
      );
      final fakeBin = Directory(
        _joinTestPath(fakeRuntimeRoot.path, const ['bin']),
      )..createSync(recursive: true);
      final fakeWine = File(_joinTestPath(fakeBin.path, const ['wine']))
        ..writeAsStringSync('#!/bin/sh\nexit 0\n')
        ..createSync(recursive: true);
      final fakeWine64 = File(_joinTestPath(fakeBin.path, const ['wine64']))
        ..writeAsStringSync('#!/bin/sh\nexit 0\n')
        ..createSync(recursive: true);
      final fakeWineboot = File(_joinTestPath(fakeBin.path, const ['wineboot']))
        ..writeAsStringSync('#!/bin/sh\nexit 0\n')
        ..createSync(recursive: true);
      Process.runSync('chmod', [
        '755',
        fakeWine.path,
        fakeWine64.path,
        fakeWineboot.path,
      ]);
      final cliEnvironment = <String, String>{
        'KONYAK_DATA_HOME': dataHome.path,
        'KONYAK_CONFIG_HOME': _joinTestPath(dataHome.path, const ['config']),
        'KONYAK_LINUX_WINE_HOME': fakeRuntimeRoot.path,
        'PATH': fakeBin.path,
      };

      final createProcess = await Process.run(
        Platform.resolvedExecutable,
        const [
          'run',
          'bin/konyak.dart',
          'create-bottle',
          '--name',
          'Steam',
          '--json',
        ],
        environment: cliEnvironment,
      );

      expect(createProcess.exitCode, 0);
      expect(createProcess.stderr.toString(), isEmpty);

      final updateProcess =
          await Process.run(Platform.resolvedExecutable, const [
            'run',
            'bin/konyak.dart',
            'set-windows-version',
            'steam',
            '--windows-version',
            'win11',
            '--json',
          ], environment: cliEnvironment);

      expect(updateProcess.exitCode, 0);
      expect(updateProcess.stderr.toString(), isEmpty);

      final listProcess = await Process.run(Platform.resolvedExecutable, const [
        'run',
        'bin/konyak.dart',
        'list-bottles',
        '--json',
      ], environment: cliEnvironment);

      expect(listProcess.exitCode, 0);

      final payload =
          jsonDecode(listProcess.stdout.toString()) as Map<String, Object?>;
      expect(payload, {
        'schemaVersion': 1,
        'bottles': [
          {
            'id': 'steam',
            'name': 'Steam',
            'path': '${dataHome.path}/bottles/steam',
            'windowsVersion': 'win11',
          },
        ],
      });
      expect(
        Directory(
          _joinTestPath(dataHome.path, const ['bottles', 'steam', 'drive_c']),
        ).existsSync(),
        isTrue,
      );
    },
  );

  test(
    'default macOS bottle repository ignores external plist bottle catalogs',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'konyak-external-macos-catalog-test-',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });
      final externalContainer = Directory(
        _joinTestPath(tempDirectory.path, const [
          'Library',
          'Containers',
          'com.example.ExternalBottleCatalog',
        ]),
      )..createSync(recursive: true);
      File(
        _joinTestPath(externalContainer.path, const ['BottleVM.plist']),
      ).writeAsStringSync('external bottle catalog');
      File(
          _joinTestPath(externalContainer.path, const [
            'Bottles',
            'Steam',
            'Metadata.plist',
          ]),
        )
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('external bottle metadata');

      final repository = defaultBottleRepositoryFromEnvironment({
        'HOME': tempDirectory.path,
      }, hostPlatform: KonyakHostPlatform.macos);

      expect(repository.listBottles(), isEmpty);
    },
  );

  test(
    'default macOS bottle repository writes new bottles to Konyak data',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'konyak-default-macos-create-test-',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });
      final repository = defaultBottleRepositoryFromEnvironment({
        'HOME': tempDirectory.path,
      }, hostPlatform: KonyakHostPlatform.macos);

      final result = repository.createBottle(
        const BottleCreateRequest(name: 'Created', windowsVersion: 'win10'),
      );

      expect(result, isA<BottleCreated>());
      final created = result as BottleCreated;
      expect(
        created.bottle.path,
        '${tempDirectory.path}/Library/Application Support/Konyak/Bottles/created',
      );
      expect(
        File(
          _joinTestPath(created.bottle.path, const ['metadata.json']),
        ).existsSync(),
        isTrue,
      );
      expect(
        Directory(
          _joinTestPath(created.bottle.path, const ['drive_c']),
        ).existsSync(),
        isTrue,
      );
    },
  );

  test(
    'file bottle repository ignores directories without Konyak metadata',
    () {
      final tempDirectory = Directory.systemTemp.createTempSync(
        'konyak-unmanaged-bottle-dir-test-',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });
      final bottlesDirectory = Directory(
        _joinTestPath(tempDirectory.path, const [
          'Library',
          'Application Support',
          'Konyak',
          'Bottles',
        ]),
      )..createSync(recursive: true);
      final rawPrefix = Directory(
        _joinTestPath(bottlesDirectory.path, const ['raw-prefix']),
      )..createSync(recursive: true);
      File(
        _joinTestPath(rawPrefix.path, const ['.update-timestamp']),
      ).writeAsStringSync('');

      final repository = defaultBottleRepositoryFromEnvironment({
        'HOME': tempDirectory.path,
      }, hostPlatform: KonyakHostPlatform.macos);

      expect(repository.listBottles(), isEmpty);

      final createResult = repository.createBottle(
        const BottleCreateRequest(name: 'Managed', windowsVersion: 'win10'),
      );

      expect(createResult, isA<BottleCreated>());
      expect(repository.listBottles().map((bottle) => bottle.id), const [
        'managed',
      ]);
    },
  );

  test(
    'composite bottle repository reads multiple catalogs and writes locally',
    () {
      final writableRepository = MemoryBottleRepository(
        dataHome: '/home/user/.local/share/konyak',
        bottles: const [
          BottleRecord(
            id: 'local',
            name: 'Local',
            path: '/home/user/.local/share/konyak/bottles/local',
            windowsVersion: 'win10',
          ),
        ],
      );
      final repository = CompositeBottleRepository(
        catalogs: const [
          StaticBottleCatalog([
            BottleRecord(
              id: 'imported',
              name: 'Imported',
              path: '/mnt/imported/bottles/imported',
              windowsVersion: 'win11',
            ),
          ]),
        ],
        writableRepository: writableRepository,
      );

      expect(repository.listBottles().map((bottle) => bottle.id), const [
        'imported',
        'local',
      ]);
      expect(repository.findBottle('imported')?.name, 'Imported');

      final createResult = repository.createBottle(
        const BottleCreateRequest(name: 'Created', windowsVersion: 'win10'),
      );

      expect(createResult, isA<BottleCreated>());
      expect(repository.findBottle('created')?.name, 'Created');
    },
  );

  test('composite bottle repository deletes from readable repositories', () {
    final writableRepository = MemoryBottleRepository(
      dataHome: '/home/user/.local/share/konyak',
    );
    final importedRepository = MemoryBottleRepository(
      dataHome: '/home/user/.local/share/konyak',
      bottles: const [
        BottleRecord(
          id: 'imported',
          name: 'Imported',
          path: '/home/user/.local/share/konyak/bottles/imported',
          windowsVersion: 'win10',
        ),
      ],
    );
    final repository = CompositeBottleRepository(
      catalogs: [importedRepository],
      writableRepository: writableRepository,
    );

    expect(repository.listBottles().map((bottle) => bottle.id), const [
      'imported',
    ]);

    final deleteResult = repository.deleteBottle('imported');

    expect(deleteResult, isA<BottleDeleted>());
    expect(importedRepository.listBottles(), isEmpty);
    expect(repository.listBottles(), isEmpty);
  });

  test('list-runtimes --json returns the versioned empty runtime contract', () {
    final result = runCli(const ['list-runtimes', '--json']);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {'schemaVersion': 1, 'runtimes': <Object?>[]});
  });

  test('list-runtimes --json serializes runtime records from the catalog', () {
    final result = runCli(
      const ['list-runtimes', '--json'],
      runtimeCatalog: const StaticRuntimeCatalog([
        RuntimeRecord(
          id: 'wine-stable-linux-x86_64',
          name: 'Wine Stable',
          platform: 'linux',
          architecture: 'x86_64',
          runnerKind: 'wine',
          isBundled: false,
          isUpdateable: true,
        ),
      ]),
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'runtimes': [
        {
          'id': 'wine-stable-linux-x86_64',
          'name': 'Wine Stable',
          'platform': 'linux',
          'architecture': 'x86_64',
          'runnerKind': 'wine',
          'isBundled': false,
          'isUpdateable': true,
        },
      ],
    });
  });

  test('list-runtimes --json reports the Konyak macOS Wine runtime', () {
    final result = runCli(
      const ['list-runtimes', '--json'],
      runtimeCatalog: MacosWineRuntimeCatalog(
        hostPlatform: KonyakHostPlatform.macos,
        environment: const {'HOME': '/Users/user'},
        fileStatusProbe: const StaticFileStatusProbe({
          '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wine64',
          '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wineserver',
          '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wine',
          '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/DXVK/x64/dxgi.dll',
          '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/DXVK/x32/dxgi.dll',
          '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/libMoltenVK.dylib',
          '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/libgstreamer-1.0.0.dylib',
          '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/share/wine/mono',
          '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/winetricks',
        }),
      ),
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'runtimes': [
        {
          'id': 'konyak-macos-wine',
          'name': 'Konyak macOS Wine',
          'platform': 'macos',
          'architecture': 'x86_64',
          'runnerKind': 'macosWine',
          'isBundled': false,
          'isUpdateable': true,
          'distributionKind': 'bootstrap',
          'isInstalled': true,
          'applicationSupportPath':
              '/Users/user/Library/Application Support/Konyak',
          'libraryPath':
              '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine',
          'executablePath':
              '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wine64',
          'stack': {
            'schemaVersion': 1,
            'id': 'macos-konyak-runtime-stack',
            'name': 'Konyak macOS runtime stack',
            'compatibilityTarget': 'macos-konyak-runtime-stack',
            'isComplete': true,
            'components': [
              {
                'id': 'wine',
                'name': 'Wine',
                'role': 'windows-runner',
                'isRequired': true,
                'isInstalled': true,
                'paths': [
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wine64',
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wineserver',
                ],
                'missingPaths': <Object?>[],
              },
              {
                'id': 'wine32on64',
                'name': 'Wine32-on-64 support',
                'role': '32-bit-windows-support',
                'isRequired': true,
                'isInstalled': true,
                'paths': [
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wine',
                ],
                'missingPaths': <Object?>[],
              },
              {
                'id': 'dxvk-macos',
                'name': 'DXVK-macOS',
                'role': 'd3d9-d3d11-translation',
                'isRequired': true,
                'isInstalled': true,
                'paths': [
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/DXVK/x64/dxgi.dll',
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/DXVK/x32/dxgi.dll',
                ],
                'missingPaths': <Object?>[],
              },
              {
                'id': 'moltenvk',
                'name': 'MoltenVK',
                'role': 'vulkan-metal-translation',
                'isRequired': true,
                'isInstalled': true,
                'paths': [
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/libMoltenVK.dylib',
                ],
                'missingPaths': <Object?>[],
              },
              {
                'id': 'gstreamer',
                'name': 'GStreamer runtime',
                'role': 'media-runtime',
                'isRequired': true,
                'isInstalled': true,
                'paths': [
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/libgstreamer-1.0.0.dylib',
                ],
                'missingPaths': <Object?>[],
              },
              {
                'id': 'wine-mono',
                'name': 'wine-mono',
                'role': 'dotnet-runtime',
                'isRequired': true,
                'isInstalled': true,
                'paths': [
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/share/wine/mono',
                ],
                'missingPaths': <Object?>[],
              },
              {
                'id': 'winetricks',
                'name': 'winetricks',
                'role': 'verb-installer',
                'isRequired': true,
                'isInstalled': true,
                'paths': [
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/winetricks',
                ],
                'missingPaths': <Object?>[],
              },
              {
                'id': 'gptk-d3dmetal',
                'name': 'GPTK/D3DMetal',
                'role': 'd3d12-metal-translation',
                'isRequired': false,
                'isInstalled': false,
                'paths': [
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/external/D3DMetal.framework',
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/external/libd3dshared.dylib',
                ],
                'missingPaths': [
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/external/D3DMetal.framework',
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/external/libd3dshared.dylib',
                ],
              },
            ],
          },
        },
      ],
    });
  });

  test('list-runtimes --json reports missing stack components separately', () {
    final result = runCli(
      const ['list-runtimes', '--json'],
      runtimeCatalog: MacosWineRuntimeCatalog(
        hostPlatform: KonyakHostPlatform.macos,
        environment: const {'HOME': '/Users/user'},
        fileStatusProbe: const StaticFileStatusProbe({
          '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wine64',
        }),
      ),
    );

    expect(result.exitCode, 0);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    final runtimes = payload['runtimes'] as List<Object?>;
    final runtime = runtimes.single as Map<String, Object?>;
    final stack = runtime['stack'] as Map<String, Object?>;
    final components = stack['components'] as List<Object?>;
    final wine = components.first as Map<String, Object?>;
    final dxvk = components[2] as Map<String, Object?>;

    expect(runtime['isInstalled'], isTrue);
    expect(stack['isComplete'], isFalse);
    expect(wine['id'], 'wine');
    expect(wine['isInstalled'], isFalse);
    expect(
      wine['missingPaths'],
      contains(
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wineserver',
      ),
    );
    expect(dxvk['id'], 'dxvk-macos');
    expect(dxvk['isInstalled'], isFalse);
  });

  test('list-runtimes --json omits Konyak macOS Wine outside macOS', () {
    final result = runCli(
      const ['list-runtimes', '--json'],
      runtimeCatalog: MacosWineRuntimeCatalog(
        hostPlatform: KonyakHostPlatform.linux,
        environment: const {'HOME': '/home/user'},
        fileStatusProbe: const StaticFileStatusProbe({}),
      ),
    );

    expect(result.exitCode, 0);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {'schemaVersion': 1, 'runtimes': <Object?>[]});
  });

  test('list-runtimes --json reports the Konyak Linux Wine runtime', () {
    final result = runCli(
      const ['list-runtimes', '--json'],
      runtimeCatalog: KonyakRuntimeCatalog(
        hostPlatform: KonyakHostPlatform.linux,
        environment: const {
          'HOME': '/home/user',
          'KONYAK_LINUX_WINE_ARCHIVE_URL':
              'https://example.invalid/linux-wine.tar.xz',
          'KONYAK_LINUX_WINE_VERSION_URL':
              'https://example.invalid/releases/latest',
          'KONYAK_LINUX_WINE_STACK_MANIFEST':
              'https://example.invalid/linux-runtime-stack-source.json',
        },
        fileStatusProbe: const StaticFileStatusProbe({
          '/home/user/.local/share/konyak/Runtimes/linux-wine/bin/wine',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/bin/winedbg',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/bin/wineserver',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/winetricks',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/vkd3d-proton/x64/d3d12.dll',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/vkd3d-proton/x86/d3d12.dll',
        }),
      ),
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'runtimes': [
        {
          'id': 'konyak-linux-wine',
          'name': 'Konyak Linux Wine',
          'platform': 'linux',
          'architecture': 'x86_64',
          'runnerKind': 'wine',
          'isBundled': false,
          'isUpdateable': true,
          'distributionKind': 'managed',
          'isInstalled': true,
          'libraryPath': '/home/user/.local/share/konyak/Runtimes/linux-wine',
          'executablePath':
              '/home/user/.local/share/konyak/Runtimes/linux-wine/bin/wine',
          'stack': {
            'schemaVersion': 1,
            'id': 'linux-wine-runtime-stack',
            'name': 'Linux Wine/Proton runtime stack',
            'compatibilityTarget': 'linux-wine-runtime-stack',
            'isComplete': true,
            'components': [
              {
                'id': 'wine',
                'name': 'Wine',
                'role': 'windows-runner',
                'isRequired': true,
                'isInstalled': true,
                'paths': [
                  '/home/user/.local/share/konyak/Runtimes/linux-wine/bin/wine',
                  '/home/user/.local/share/konyak/Runtimes/linux-wine/bin/winedbg',
                  '/home/user/.local/share/konyak/Runtimes/linux-wine/bin/wineserver',
                ],
                'missingPaths': <Object?>[],
              },
              {
                'id': 'winetricks',
                'name': 'winetricks',
                'role': 'verb-installer',
                'isRequired': true,
                'isInstalled': true,
                'paths': [
                  '/home/user/.local/share/konyak/Runtimes/linux-wine/winetricks',
                ],
                'missingPaths': <Object?>[],
              },
              {
                'id': 'vkd3d-proton',
                'name': 'vkd3d-proton',
                'role': 'd3d12-vulkan-translation',
                'isRequired': true,
                'isInstalled': true,
                'paths': [
                  '/home/user/.local/share/konyak/Runtimes/linux-wine/vkd3d-proton/x64/d3d12.dll',
                  '/home/user/.local/share/konyak/Runtimes/linux-wine/vkd3d-proton/x86/d3d12.dll',
                ],
                'missingPaths': <Object?>[],
              },
            ],
          },
        },
      ],
    });
  });

  test('list-runtimes --json reports the Linux development runtime profile', () {
    final result = runCli(
      const ['list-runtimes', '--json'],
      runtimeCatalog: KonyakRuntimeCatalog(
        hostPlatform: KonyakHostPlatform.linux,
        environment: const {
          'HOME': '/home/user',
          'KONYAK_RUNTIME_PROFILE': 'development',
          'KONYAK_DEV_LINUX_WINE_STACK_MANIFEST':
              'file:///workspace/fixtures/linux-runtime-stack-source.json',
        },
        fileStatusProbe: const StaticFileStatusProbe({
          '/home/user/.local/share/konyak/Runtimes/linux-wine/bin/wine',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/bin/winedbg',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/bin/wineserver',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/winetricks',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/vkd3d-proton/x64/d3d12.dll',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/vkd3d-proton/x86/d3d12.dll',
        }),
      ),
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    final runtimes = (payload['runtimes'] as List<Object?>)
        .cast<Map<String, Object?>>();
    final runtime = runtimes.single;
    expect(runtime['id'], 'konyak-linux-wine');
    expect(runtime['distributionKind'], 'development');
    expect(runtime['isInstalled'], isTrue);
    expect(runtime['isUpdateable'], isFalse);
    expect(runtime, isNot(contains('archiveUrl')));
    expect(runtime, isNot(contains('versionUrl')));
    expect(runtime, isNot(contains('sourceManifestUrl')));
  });

  test('check-runtime-update --json returns machine-readable update status', () {
    final checker = RecordingRuntimeUpdateChecker(
      result: const RuntimeUpdateCheckCompleted(
        RuntimeUpdateRecord(
          runtimeId: 'konyak-macos-wine',
          status: 'available',
          currentVersion: 'wine-devel-11.9',
          latestVersion: '12.0',
          versionUrl:
              'https://api.github.com/repos/Gcenx/macOS_Wine_builds/releases/latest',
          archiveUrl:
              'https://github.com/Gcenx/macOS_Wine_builds/releases/download/11.9/wine-devel-11.9-osx64.tar.xz',
        ),
      ),
    );

    final result = runCli(const [
      'check-runtime-update',
      'konyak-macos-wine',
      '--json',
    ], runtimeUpdateChecker: checker);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(checker.lastRuntimeId, 'konyak-macos-wine');

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'runtimeUpdate': {
        'runtimeId': 'konyak-macos-wine',
        'status': 'available',
        'currentVersion': 'wine-devel-11.9',
        'latestVersion': '12.0',
        'versionUrl':
            'https://api.github.com/repos/Gcenx/macOS_Wine_builds/releases/latest',
        'archiveUrl':
            'https://github.com/Gcenx/macOS_Wine_builds/releases/download/11.9/wine-devel-11.9-osx64.tar.xz',
      },
    });
  });

  test('check-app-update --json returns machine-readable update status', () {
    final checker = RecordingAppUpdateChecker(
      result: const AppUpdateCheckCompleted(
        AppUpdateRecord(
          appId: 'konyak',
          status: 'available',
          currentVersion: '1.0.0',
          latestVersion: '1.1.0',
          versionUrl:
              'https://api.github.com/repos/serika12345/Konyak/releases/latest',
          archiveUrl: 'https://example.invalid/Konyak.dmg',
        ),
      ),
    );

    final result = runCli(const [
      'check-app-update',
      '--json',
    ], appUpdateChecker: checker);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(checker.checkCount, 1);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'appUpdate': {
        'appId': 'konyak',
        'status': 'available',
        'currentVersion': '1.0.0',
        'latestVersion': '1.1.0',
        'versionUrl':
            'https://api.github.com/repos/serika12345/Konyak/releases/latest',
        'archiveUrl': 'https://example.invalid/Konyak.dmg',
      },
    });
  });

  test('terminate-wine-processes --json terminates each bottle prefix', () {
    final repository = MemoryBottleRepository(
      dataHome: '/data',
      bottles: const [
        BottleRecord(
          id: 'alpha',
          name: 'Alpha',
          path: '/bottles/alpha',
          windowsVersion: 'win10',
        ),
        BottleRecord(
          id: 'beta',
          name: 'Beta',
          path: '/bottles/beta',
          windowsVersion: 'win11',
        ),
      ],
    );
    final runner = RecordingProgramRunner(
      result: const ProgramRunCompleted(processExitCode: 0),
    );

    final result = runCli(
      const ['terminate-wine-processes', '--json'],
      bottleCatalog: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.linux,
      ),
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(runner.requests, hasLength(2));
    expect(runner.requests[0].executable, 'wineserver');
    expect(runner.requests[0].arguments, const ['-k']);
    expect(runner.requests[0].environment, {'WINEPREFIX': '/bottles/alpha'});
    expect(runner.requests[1].environment, {'WINEPREFIX': '/bottles/beta'});

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'wineProcessTermination': {
        'hasFailures': false,
        'bottles': [
          {
            'bottleId': 'alpha',
            'status': 'terminated',
            'runnerKind': 'wineserver',
            'executable': 'wineserver',
            'argv': ['wineserver', '-k'],
            'processExitCode': 0,
          },
          {
            'bottleId': 'beta',
            'status': 'terminated',
            'runnerKind': 'wineserver',
            'executable': 'wineserver',
            'argv': ['wineserver', '-k'],
            'processExitCode': 0,
          },
        ],
      },
    });
  });

  test('list-wine-processes --json lists process records with icons', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-process-list-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final bottlePath = _joinTestPath(tempDirectory.path, const ['a']);
    final programPath = _joinTestPath(tempDirectory.path, const [
      'Downloads',
      'Ardour-9.5.0-w64-Setup.exe',
    ]);
    Directory(
      _joinTestPath(bottlePath, const ['logs']),
    ).createSync(recursive: true);
    File(_joinTestPath(bottlePath, const ['logs', 'latest.log']))
      ..createSync(recursive: true)
      ..writeAsStringSync('Arguments: ${jsonEncode(<String>[programPath])}\n');
    final repository = MemoryBottleRepository(
      dataHome: '/data',
      bottles: [
        BottleRecord(
          id: 'a',
          name: 'a',
          path: bottlePath,
          windowsVersion: 'win11',
        ),
      ],
    );
    final runner = RecordingProgramRunner(
      result: const ProgramRunCompleted(
        processExitCode: 0,
        stdout: '''
          pid      threads  executable (all id:s are in hex)
          00000020 2        'C:\\windows\\system32\\services.exe'
          00000028 1        /_ 'winedbg.exe'
          00000034 1        /_ 'C:\\windows\\system32\\explorer.exe'
          00000038 1        rpcss.exe
          00000120 1        start.exe
          000000d8 5        Ardour-9.5.0-w64-Setup.exe
        ''',
      ),
    );

    final result = runCli(
      const ['list-wine-processes', '--json'],
      bottleCatalog: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.linux,
      ),
      programRunner: runner,
      programMetadataExtractor: FixedProgramMetadataExtractor(
        programPath: programPath,
        metadata: ProgramMetadataRecord(
          fileDescription: 'Ardour Installer',
          iconPath: _joinTestPath(bottlePath, const [
            'cache',
            'icons',
            'ardour.ico',
          ]),
        ),
      ),
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(runner.requests, hasLength(1));
    expect(runner.requests.single.executable, 'winedbg');
    expect(runner.requests.single.arguments, const ['--command', 'info proc']);
    expect(runner.requests.single.environment, {'WINEPREFIX': bottlePath});

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'wineProcesses': {
        'processes': [
          {
            'bottleId': 'a',
            'processId': '000000d8',
            'executable': 'Ardour-9.5.0-w64-Setup.exe',
            'hostPath': programPath,
            'metadata': {
              'fileDescription': 'Ardour Installer',
              'iconPath': _joinTestPath(bottlePath, const [
                'cache',
                'icons',
                'ardour.ico',
              ]),
            },
          },
        ],
      },
    });
  });

  test(
    'list-wine-processes --json strips winedbg tree prefixes before resolving metadata',
    () {
      final tempDirectory = Directory.systemTemp.createTempSync(
        'konyak-process-list-tree-prefix-test-',
      );
      addTearDown(() {
        if (tempDirectory.existsSync()) {
          tempDirectory.deleteSync(recursive: true);
        }
      });
      final bottlePath = _joinTestPath(tempDirectory.path, const ['a']);
      final programPath = _joinTestPath(tempDirectory.path, const [
        'Downloads',
        'Ardour-9.5.0-w64-Setup.exe',
      ]);
      Directory(
        _joinTestPath(bottlePath, const ['cache']),
      ).createSync(recursive: true);
      File(
        _joinTestPath(bottlePath, const [
          'cache',
          'external-program-launches.json',
        ]),
      ).writeAsStringSync(
        jsonEncode({
          'schemaVersion': 1,
          'launches': [
            {
              'programPath': programPath,
              'executableName': 'ardour-9.5.0-w64-setup.exe',
            },
          ],
        }),
      );
      final repository = MemoryBottleRepository(
        dataHome: '/data',
        bottles: [
          BottleRecord(
            id: 'a',
            name: 'a',
            path: bottlePath,
            windowsVersion: 'win11',
          ),
        ],
      );
      final runner = RecordingProgramRunner(
        result: const ProgramRunCompleted(
          processExitCode: 0,
          stdout: '''
          pid      threads  executable (all id:s are in hex)
          00000020 2        'C:\\windows\\system32\\services.exe'
          000000d8 5        \\_ 'Ardour-9.5.0-w64-Setup.exe'
        ''',
        ),
      );

      final result = runCli(
        const ['list-wine-processes', '--json'],
        bottleCatalog: repository,
        programRunPlanner: ProgramRunPlanner(
          hostPlatform: KonyakHostPlatform.linux,
        ),
        programRunner: runner,
        programMetadataExtractor: FixedProgramMetadataExtractor(
          programPath: programPath,
          metadata: ProgramMetadataRecord(
            fileDescription: 'Ardour Installer',
            iconPath: _joinTestPath(bottlePath, const [
              'cache',
              'icons',
              'ardour.ico',
            ]),
          ),
        ),
      );

      expect(result.exitCode, 0);
      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      expect(payload, {
        'schemaVersion': 1,
        'wineProcesses': {
          'processes': [
            {
              'bottleId': 'a',
              'processId': '000000d8',
              'executable': 'Ardour-9.5.0-w64-Setup.exe',
              'hostPath': programPath,
              'metadata': {
                'fileDescription': 'Ardour Installer',
                'iconPath': _joinTestPath(bottlePath, const [
                  'cache',
                  'icons',
                  'ardour.ico',
                ]),
              },
            },
          ],
        },
      });
    },
  );

  test(
    'list-wine-processes --json uses recorded external launches when latest.log is unavailable',
    () {
      final tempDirectory = Directory.systemTemp.createTempSync(
        'konyak-process-list-recorded-launch-test-',
      );
      addTearDown(() {
        if (tempDirectory.existsSync()) {
          tempDirectory.deleteSync(recursive: true);
        }
      });
      final bottlePath = _joinTestPath(tempDirectory.path, const ['a']);
      final programPath = _joinTestPath(tempDirectory.path, const [
        'Downloads',
        'Ardour-9.5.0-w64-Setup.exe',
      ]);
      final repository = MemoryBottleRepository(
        dataHome: '/data',
        bottles: [
          BottleRecord(
            id: 'a',
            name: 'a',
            path: bottlePath,
            windowsVersion: 'win11',
          ),
        ],
      );
      Directory(
        _joinTestPath(bottlePath, const ['cache']),
      ).createSync(recursive: true);
      File(
        _joinTestPath(bottlePath, const [
          'cache',
          'external-program-launches.json',
        ]),
      ).writeAsStringSync(
        jsonEncode({
          'schemaVersion': 1,
          'launches': [
            {
              'programPath': programPath,
              'executableName': 'ardour-9.5.0-w64-setup.exe',
            },
          ],
        }),
      );

      final runner = RecordingProgramRunner(
        result: const ProgramRunCompleted(
          processExitCode: 0,
          stdout: '''
          pid      threads  executable (all id:s are in hex)
          00000020 2        'C:\\windows\\system32\\services.exe'
          000000d8 5        Ardour-9.5.0-w64-Setup.exe
        ''',
        ),
      );

      final result = runCli(
        const ['list-wine-processes', '--json'],
        bottleCatalog: repository,
        programRunPlanner: ProgramRunPlanner(
          hostPlatform: KonyakHostPlatform.linux,
        ),
        programRunner: runner,
        programMetadataExtractor: FixedProgramMetadataExtractor(
          programPath: programPath,
          metadata: ProgramMetadataRecord(
            fileDescription: 'Ardour Installer',
            iconPath: _joinTestPath(bottlePath, const [
              'cache',
              'icons',
              'ardour.ico',
            ]),
          ),
        ),
      );

      expect(result.exitCode, 0);
      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      expect(payload, {
        'schemaVersion': 1,
        'wineProcesses': {
          'processes': [
            {
              'bottleId': 'a',
              'processId': '000000d8',
              'executable': 'Ardour-9.5.0-w64-Setup.exe',
              'hostPath': programPath,
              'metadata': {
                'fileDescription': 'Ardour Installer',
                'iconPath': _joinTestPath(bottlePath, const [
                  'cache',
                  'icons',
                  'ardour.ico',
                ]),
              },
            },
          ],
        },
      });
    },
  );

  test(
    'run-program --json on macOS records external launches for process icons',
    () {
      final tempDirectory = Directory.systemTemp.createTempSync(
        'konyak-process-list-macos-run-record-test-',
      );
      addTearDown(() {
        if (tempDirectory.existsSync()) {
          tempDirectory.deleteSync(recursive: true);
        }
      });
      final bottlePath = _joinTestPath(tempDirectory.path, const ['a']);
      final programPath = _joinTestPath(tempDirectory.path, const [
        'Downloads',
        'Ardour-9.5.0-w64-Setup.exe',
      ]);
      final repository = MemoryBottleRepository(
        dataHome: '/data',
        bottles: [
          BottleRecord(
            id: 'a',
            name: 'a',
            path: bottlePath,
            windowsVersion: 'win11',
          ),
        ],
      );
      final runner = RecordingProgramRunner(
        results: const [
          ProgramRunCompleted(processExitCode: 0),
          ProgramRunCompleted(
            processExitCode: 0,
            stdout: '''
          pid      threads  executable (all id:s are in hex)
          000000d8 5        Ardour-9.5.0-w64-Setup.exe
        ''',
          ),
        ],
      );
      final planner = ProgramRunPlanner(hostPlatform: KonyakHostPlatform.macos);

      final runResult = runCli(
        ['run-program', 'a', '--program', programPath, '--json'],
        bottleRepository: repository,
        programRunPlanner: planner,
        programRunner: runner,
      );

      expect(runResult.exitCode, 0);

      final result = runCli(
        const ['list-wine-processes', '--json'],
        bottleRepository: repository,
        programRunPlanner: planner,
        programRunner: runner,
        programMetadataExtractor: FixedProgramMetadataExtractor(
          programPath: programPath,
          metadata: ProgramMetadataRecord(
            fileDescription: 'Ardour Installer',
            iconPath: _joinTestPath(bottlePath, const [
              'cache',
              'icons',
              'ardour.ico',
            ]),
          ),
        ),
      );

      expect(result.exitCode, 0);
      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      expect(payload, {
        'schemaVersion': 1,
        'wineProcesses': {
          'processes': [
            {
              'bottleId': 'a',
              'processId': '000000d8',
              'executable': 'Ardour-9.5.0-w64-Setup.exe',
              'hostPath': programPath,
              'metadata': {
                'fileDescription': 'Ardour Installer',
                'iconPath': _joinTestPath(bottlePath, const [
                  'cache',
                  'icons',
                  'ardour.ico',
                ]),
              },
            },
          ],
        },
      });
    },
  );

  test('terminate-wine-process --json kills one Wine process', () {
    final repository = MemoryBottleRepository(
      dataHome: '/data',
      bottles: const [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: '/bottles/steam',
          windowsVersion: 'win10',
        ),
      ],
    );
    final runner = RecordingProgramRunner(
      result: const ProgramRunCompleted(processExitCode: 0),
    );

    final result = runCli(
      const [
        'terminate-wine-process',
        '--bottle',
        'steam',
        '--process',
        '000000d8',
        '--json',
      ],
      bottleCatalog: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.linux,
      ),
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(runner.requests, hasLength(1));
    expect(runner.requests.single.executable, 'winedbg');
    expect(runner.requests.single.arguments, const [
      '--command',
      'kill',
      '0x000000d8',
    ]);
    expect(runner.requests.single.environment, {
      'WINEPREFIX': '/bottles/steam',
    });

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'wineProcessTermination': {
        'hasFailures': false,
        'processes': [
          {
            'bottleId': 'steam',
            'processId': '000000d8',
            'status': 'terminated',
            'runnerKind': 'winedbg',
            'executable': 'winedbg',
            'argv': ['winedbg', '--command', 'kill', '0x000000d8'],
            'processExitCode': 0,
          },
        ],
      },
    });
  });

  test('app update checker compares Konyak version to release tag', () {
    final checker = DartIoAppUpdateChecker(
      appId: 'konyak',
      currentVersion: '1.0.0',
      versionUrl: 'https://example.invalid/releases/latest',
      releaseMetadataFetcher: const StaticRuntimeReleaseMetadataFetcher(
        RuntimeReleaseMetadata(version: 'v1.0.0'),
      ),
    );

    final result = checker.check();

    expect(result, isA<AppUpdateCheckCompleted>());
    final completed = result as AppUpdateCheckCompleted;
    expect(completed.update.status, 'current');
    expect(completed.update.currentVersion, '1.0.0');
    expect(completed.update.latestVersion, 'v1.0.0');
  });

  test('release metadata fetcher selects archives over checksum assets', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-release-metadata-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final metadataFile =
        File(
          _joinTestPath(tempDirectory.path, const ['release.json']),
        )..writeAsStringSync(
          jsonEncode(<String, Object?>{
            'tag_name': 'v1.1.0',
            'body':
                'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa  Konyak-1.1.0-macos-arm64.zip',
            'assets': [
              {
                'browser_download_url':
                    'https://example.invalid/Konyak-1.1.0-macos-arm64.zip.sha256',
              },
              {
                'browser_download_url':
                    'https://example.invalid/Konyak-1.1.0-macos-arm64.release.json',
              },
              {
                'browser_download_url':
                    'https://example.invalid/Konyak-1.1.0-macos-arm64.zip',
              },
            ],
          }),
        );
    const fetcher = DartIoRuntimeReleaseMetadataFetcher();

    final result = fetcher.fetch(metadataFile.uri.toString());

    expect(result, isA<RuntimeReleaseMetadataFetched>());
    final fetched = result as RuntimeReleaseMetadataFetched;
    expect(
      fetched.metadata.archiveUrl,
      'https://example.invalid/Konyak-1.1.0-macos-arm64.zip',
    );
    expect(
      fetched.metadata.archiveSha256,
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    );
  });

  test('release metadata fetcher resolves runtime stack source manifests', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-runtime-stack-release-metadata-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final metadataFile =
        File(
          _joinTestPath(tempDirectory.path, const ['release.json']),
        )..writeAsStringSync(
          jsonEncode(<String, Object?>{
            'tag_name': 'v1.1.0',
            'assets': [
              {
                'browser_download_url':
                    'https://example.invalid/Konyak-1.1.0-linux-x86_64.AppImage',
              },
              {
                'browser_download_url':
                    'https://example.invalid/Konyak-1.1.0-linux-x86_64.release.json',
              },
              {
                'browser_download_url':
                    'https://example.invalid/konyak-linux-wine-runtime-stack-source.json',
              },
              {
                'browser_download_url':
                    'https://example.invalid/konyak-linux-wine-runtime-stack-source.json.sig',
              },
            ],
          }),
        );
    final releaseAsset =
        File(
          _joinTestPath(tempDirectory.path, const [
            'Konyak-1.1.0-linux.release.json',
          ]),
        )..writeAsStringSync(
          jsonEncode(<String, Object?>{
            'schemaVersion': 1,
            'appId': 'konyak',
            'version': '1.1.0',
            'runtimeStack': {
              'runtimeId': 'konyak-linux-wine',
              'stackId': 'linux-wine-runtime-stack',
              'sourceManifestFileName':
                  'konyak-linux-wine-runtime-stack-source.json',
              'signatureFileName':
                  'konyak-linux-wine-runtime-stack-source.json.sig',
            },
          }),
        );
    final metadataPayload =
        jsonDecode(metadataFile.readAsStringSync()) as Map<String, Object?>;
    final assets = (metadataPayload['assets'] as List<Object?>)
        .cast<Map<String, Object?>>();
    assets[1] = <String, Object?>{
      'browser_download_url': releaseAsset.uri.toString(),
    };
    metadataFile.writeAsStringSync(jsonEncode(metadataPayload));

    const fetcher = DartIoRuntimeReleaseMetadataFetcher();

    final result = fetcher.fetch(metadataFile.uri.toString());

    expect(result, isA<RuntimeReleaseMetadataFetched>());
    final fetched = result as RuntimeReleaseMetadataFetched;
    expect(
      fetched.metadata.sourceManifestUrl,
      'https://example.invalid/konyak-linux-wine-runtime-stack-source.json',
    );
    expect(
      fetched.metadata.sourceManifestSignatureUrl,
      'https://example.invalid/konyak-linux-wine-runtime-stack-source.json.sig',
    );
  });

  test('app update checker includes release archive checksums', () {
    final checker = DartIoAppUpdateChecker(
      appId: 'konyak',
      currentVersion: '1.0.0',
      versionUrl: 'https://example.invalid/releases/latest',
      releaseMetadataFetcher: const StaticRuntimeReleaseMetadataFetcher(
        RuntimeReleaseMetadata(
          version: 'v1.1.0',
          archiveUrl: 'https://example.invalid/Konyak-1.1.0-macos.zip',
          archiveSha256:
              'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        ),
      ),
    );

    final result = checker.check();

    expect(result, isA<AppUpdateCheckCompleted>());
    final completed = result as AppUpdateCheckCompleted;
    expect(
      completed.update.archiveSha256,
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    );
  });

  test('install-app-update --json installs available Konyak updates', () {
    final checker = RecordingAppUpdateChecker(
      result: const AppUpdateCheckCompleted(
        AppUpdateRecord(
          appId: 'konyak',
          status: 'available',
          currentVersion: '1.0.0',
          latestVersion: '1.1.0',
          versionUrl:
              'https://api.github.com/repos/serika12345/Konyak/releases/latest',
          archiveUrl: 'https://example.invalid/Konyak-1.1.0.dmg',
        ),
      ),
    );
    final installer = RecordingAppUpdateInstaller(
      result: const AppUpdateInstallCompleted(
        AppUpdateInstallRecord(
          appId: 'konyak',
          status: 'installed',
          currentVersion: '1.0.0',
          installedVersion: '1.1.0',
          archiveUrl: 'https://example.invalid/Konyak-1.1.0.dmg',
          installPath: '/tmp/Konyak-1.1.0.dmg',
        ),
      ),
    );

    final result = runCli(
      const ['install-app-update', '--json'],
      appUpdateChecker: checker,
      appUpdateInstaller: installer,
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(checker.checkCount, 1);
    expect(installer.lastUpdate?.latestVersion, '1.1.0');

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'appUpdateInstall': {
        'appId': 'konyak',
        'status': 'installed',
        'currentVersion': '1.0.0',
        'installedVersion': '1.1.0',
        'archiveUrl': 'https://example.invalid/Konyak-1.1.0.dmg',
        'installPath': '/tmp/Konyak-1.1.0.dmg',
      },
    });
  });

  test('app update installer verifies archive checksums before opening', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-app-update-checksum-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final sourceArchive = File(
      _joinTestPath(tempDirectory.path, const ['Konyak-1.1.0-macos.zip']),
    )..writeAsStringSync('signed app update');
    final updateCache = _joinTestPath(tempDirectory.path, const ['cache']);
    final pathOpener = RecordingPathOpener(result: const PathOpenCompleted());
    final installer = DartIoAppUpdateInstaller(
      environment: {'KONYAK_APP_UPDATE_CACHE_HOME': updateCache},
      hostPlatform: KonyakHostPlatform.macos,
      pathOpener: pathOpener,
    );

    final result = installer.install(
      AppUpdateRecord(
        appId: 'konyak',
        status: 'available',
        currentVersion: '1.0.0',
        latestVersion: '1.1.0',
        archiveUrl: sourceArchive.uri.toString(),
        archiveSha256: _fileSha256(sourceArchive.path),
      ),
    );

    expect(result, isA<AppUpdateInstallCompleted>());
    final completed = result as AppUpdateInstallCompleted;
    expect(completed.install.archiveSha256, _fileSha256(sourceArchive.path));
    expect(pathOpener.lastPath, completed.install.installPath);
    expect(File(completed.install.installPath!).existsSync(), isTrue);
  });

  test('app update installer rejects updates without checksums', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-app-update-missing-checksum-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final sourceArchive = File(
      _joinTestPath(tempDirectory.path, const ['Konyak-1.1.0-macos.zip']),
    )..writeAsStringSync('unsigned app update');
    final pathOpener = RecordingPathOpener(result: const PathOpenCompleted());
    final installer = DartIoAppUpdateInstaller(
      environment: {
        'KONYAK_APP_UPDATE_CACHE_HOME': _joinTestPath(
          tempDirectory.path,
          const ['cache'],
        ),
      },
      hostPlatform: KonyakHostPlatform.macos,
      pathOpener: pathOpener,
    );

    final result = installer.install(
      AppUpdateRecord(
        appId: 'konyak',
        status: 'available',
        currentVersion: '1.0.0',
        latestVersion: '1.1.0',
        archiveUrl: sourceArchive.uri.toString(),
      ),
    );

    expect(result, isA<AppUpdateInstallFailed>());
    final failed = result as AppUpdateInstallFailed;
    expect(failed.message, contains('checksum'));
    expect(pathOpener.lastPath, isNull);
  });

  test('app update installer rejects archive checksum mismatches', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-app-update-bad-checksum-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final sourceArchive = File(
      _joinTestPath(tempDirectory.path, const ['Konyak-1.1.0-macos.zip']),
    )..writeAsStringSync('tampered app update');
    final pathOpener = RecordingPathOpener(result: const PathOpenCompleted());
    final installer = DartIoAppUpdateInstaller(
      environment: {
        'KONYAK_APP_UPDATE_CACHE_HOME': _joinTestPath(
          tempDirectory.path,
          const ['cache'],
        ),
      },
      hostPlatform: KonyakHostPlatform.macos,
      pathOpener: pathOpener,
    );

    final result = installer.install(
      AppUpdateRecord(
        appId: 'konyak',
        status: 'available',
        currentVersion: '1.0.0',
        latestVersion: '1.1.0',
        archiveUrl: sourceArchive.uri.toString(),
        archiveSha256:
            'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      ),
    );

    expect(result, isA<AppUpdateInstallFailed>());
    final failed = result as AppUpdateInstallFailed;
    expect(failed.message, contains('checksum mismatch'));
    expect(pathOpener.lastPath, isNull);
  });

  test('app update installer stages Linux AppImage replacement handoff', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-appimage-update-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final sourceArchive = File(
      _joinTestPath(tempDirectory.path, const ['Konyak-1.1.0-linux.AppImage']),
    )..writeAsStringSync('updated appimage');
    final currentAppImage = File(
      _joinTestPath(tempDirectory.path, const ['Konyak-current.AppImage']),
    )..writeAsStringSync('current appimage');
    final detachedProcessStarter = RecordingDetachedProcessStarter(
      result: const DetachedProcessStartCompleted(),
    );
    final installer = DartIoAppUpdateInstaller(
      environment: {
        'KONYAK_APP_UPDATE_CACHE_HOME': _joinTestPath(
          tempDirectory.path,
          const ['cache'],
        ),
        'KONYAK_APPIMAGE_PATH': currentAppImage.path,
        'KONYAK_APP_PID': '4242',
      },
      hostPlatform: KonyakHostPlatform.linux,
      detachedProcessStarter: detachedProcessStarter,
    );

    final result = installer.install(
      AppUpdateRecord(
        appId: 'konyak',
        status: 'available',
        currentVersion: '1.0.0',
        latestVersion: '1.1.0',
        archiveUrl: sourceArchive.uri.toString(),
        archiveSha256: _fileSha256(sourceArchive.path),
      ),
    );

    expect(result, isA<AppUpdateInstallCompleted>());
    final completed = result as AppUpdateInstallCompleted;
    expect(completed.install.installPath, currentAppImage.path);
    expect(detachedProcessStarter.lastExecutable, 'bash');
    expect(detachedProcessStarter.lastArguments, hasLength(4));
    expect(detachedProcessStarter.lastArguments[2], currentAppImage.path);
    expect(detachedProcessStarter.lastArguments[3], '4242');

    final handoffScript = File(detachedProcessStarter.lastArguments[0]);
    expect(handoffScript.existsSync(), isTrue);
    expect(
      handoffScript.readAsStringSync(),
      allOf(
        contains(r'kill -TERM "$app_pid"'),
        contains(r'mv "$staging_path" "$target_appimage"'),
        contains(r'nohup "$target_appimage"'),
      ),
    );

    final stagedArchive = File(detachedProcessStarter.lastArguments[1]);
    expect(stagedArchive.existsSync(), isTrue);
    expect(_fileSha256(stagedArchive.path), _fileSha256(sourceArchive.path));
  });

  test('app update installer stages macOS app bundle replacement handoff', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-macos-app-update-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final sourceArchive = File(
      _joinTestPath(tempDirectory.path, const ['Konyak-1.1.0-macos.zip']),
    )..writeAsStringSync('updated macOS app bundle');
    final currentBundle = Directory(
      _joinTestPath(tempDirectory.path, const ['Konyak.app']),
    )..createSync();
    File(
        _joinTestPath(currentBundle.path, const [
          'Contents',
          'MacOS',
          'Konyak',
        ]),
      )
      ..createSync(recursive: true)
      ..writeAsStringSync('current app executable');
    final detachedProcessStarter = RecordingDetachedProcessStarter(
      result: const DetachedProcessStartCompleted(),
    );
    final pathOpener = RecordingPathOpener(result: const PathOpenCompleted());
    final installer = DartIoAppUpdateInstaller(
      environment: {
        'KONYAK_APP_UPDATE_CACHE_HOME': _joinTestPath(
          tempDirectory.path,
          const ['cache'],
        ),
        'KONYAK_APP_EXECUTABLE': _joinTestPath(currentBundle.path, const [
          'Contents',
          'MacOS',
          'Konyak',
        ]),
        'KONYAK_APP_PID': '5150',
      },
      hostPlatform: KonyakHostPlatform.macos,
      pathOpener: pathOpener,
      detachedProcessStarter: detachedProcessStarter,
    );

    final result = installer.install(
      AppUpdateRecord(
        appId: 'konyak',
        status: 'available',
        currentVersion: '1.0.0',
        latestVersion: '1.1.0',
        archiveUrl: sourceArchive.uri.toString(),
        archiveSha256: _fileSha256(sourceArchive.path),
      ),
    );

    expect(result, isA<AppUpdateInstallCompleted>());
    final completed = result as AppUpdateInstallCompleted;
    expect(completed.install.installPath, currentBundle.path);
    expect(pathOpener.lastPath, isNull);
    expect(detachedProcessStarter.lastExecutable, 'bash');
    expect(detachedProcessStarter.lastArguments, hasLength(4));
    expect(detachedProcessStarter.lastArguments[2], currentBundle.path);
    expect(detachedProcessStarter.lastArguments[3], '5150');

    final handoffScript = File(detachedProcessStarter.lastArguments[0]);
    expect(handoffScript.existsSync(), isTrue);
    expect(
      handoffScript.readAsStringSync(),
      allOf(
        contains(r'ditto -x -k "$source_archive" "$extract_dir"'),
        contains(r'kill -TERM "$app_pid"'),
        contains(r'mv "$target_bundle" "$backup_path"'),
        contains(r'if [[ -w "$target_parent" ]]'),
        contains(r'with administrator privileges'),
        contains(r'nohup open "$target_bundle"'),
      ),
    );

    final stagedArchive = File(detachedProcessStarter.lastArguments[1]);
    expect(stagedArchive.existsSync(), isTrue);
    expect(_fileSha256(stagedArchive.path), _fileSha256(sourceArchive.path));
  });

  test('install-runtime-update --json installs available runtime updates', () {
    final checker = RecordingRuntimeUpdateChecker(
      result: const RuntimeUpdateCheckCompleted(
        RuntimeUpdateRecord(
          runtimeId: 'konyak-macos-wine',
          status: 'available',
          currentVersion: 'wine-devel-11.9',
          latestVersion: '12.0',
          archiveUrl: 'https://example.invalid/wine-devel-12.0-osx64.tar.xz',
        ),
      ),
    );
    final installer = RecordingMacosWineInstaller(
      result: const MacosWineInstallCompleted(
        runtime: RuntimeRecord(
          id: 'konyak-macos-wine',
          name: 'Konyak macOS Wine',
          platform: 'macos',
          architecture: 'x86_64',
          runnerKind: 'macosWine',
          isBundled: false,
          isUpdateable: true,
          isInstalled: true,
        ),
      ),
    );

    final result = runCli(
      const ['install-runtime-update', 'konyak-macos-wine', '--json'],
      runtimeUpdateChecker: checker,
      macosWineInstaller: installer,
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(checker.lastRuntimeId, 'konyak-macos-wine');
    expect(
      installer.lastRequest?.archiveUrl,
      'https://example.invalid/wine-devel-12.0-osx64.tar.xz',
    );
    expect(
      installer.lastRequest?.operation,
      RuntimeInstallOperation.updateInstall,
    );
    expect(installer.lastRequest?.force, isTrue);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload['schemaVersion'], 1);
    expect(payload['runtime'], containsPair('id', 'konyak-macos-wine'));
  });

  test('install-runtime-update uses stack source manifests when available', () {
    final checker = RecordingRuntimeUpdateChecker(
      result: const RuntimeUpdateCheckCompleted(
        RuntimeUpdateRecord(
          runtimeId: 'konyak-macos-wine',
          status: 'available',
          currentVersion: 'wine-devel-11.9',
          latestVersion: '12.0',
          archiveUrl: 'https://example.invalid/runtime-stack-source.json',
        ),
      ),
    );
    final installer = RecordingMacosWineInstaller(
      result: const MacosWineInstallCompleted(
        runtime: RuntimeRecord(
          id: 'konyak-macos-wine',
          name: 'Konyak macOS Wine',
          platform: 'macos',
          architecture: 'x86_64',
          runnerKind: 'macosWine',
          isBundled: false,
          isUpdateable: true,
          isInstalled: true,
        ),
      ),
    );

    final result = runCli(
      const ['install-runtime-update', 'konyak-macos-wine', '--json'],
      runtimeUpdateChecker: checker,
      macosWineInstaller: installer,
    );

    expect(result.exitCode, 0);
    expect(
      installer.lastRequest?.sourceManifest,
      'https://example.invalid/runtime-stack-source.json',
    );
    expect(
      installer.lastRequest?.operation,
      RuntimeInstallOperation.updateInstall,
    );
    expect(installer.lastRequest?.force, isTrue);
  });

  test('install-runtime-update installs available Linux runtime updates', () {
    final checker = RecordingRuntimeUpdateChecker(
      result: const RuntimeUpdateCheckCompleted(
        RuntimeUpdateRecord(
          runtimeId: 'konyak-linux-wine',
          status: 'available',
          currentVersion: 'wine-10.0',
          latestVersion: 'wine-10.1',
          archiveUrl: 'https://example.invalid/linux-wine-10.1.tar.xz',
        ),
      ),
    );
    final installer = RecordingLinuxWineInstaller(
      result: const LinuxWineInstallCompleted(
        runtime: RuntimeRecord(
          id: 'konyak-linux-wine',
          name: 'Konyak Linux Wine',
          platform: 'linux',
          architecture: 'x86_64',
          runnerKind: 'wine',
          isBundled: false,
          isUpdateable: true,
          isInstalled: true,
        ),
      ),
    );

    final result = runCli(
      const ['install-runtime-update', 'konyak-linux-wine', '--json'],
      runtimeUpdateChecker: checker,
      linuxWineInstaller: installer,
    );

    expect(result.exitCode, 0);
    expect(checker.lastRuntimeId, 'konyak-linux-wine');
    expect(
      installer.lastRequest?.archiveUrl,
      'https://example.invalid/linux-wine-10.1.tar.xz',
    );
    expect(
      installer.lastRequest?.operation,
      RuntimeInstallOperation.updateInstall,
    );
    expect(installer.lastRequest?.force, isTrue);
  });

  test(
    'install-runtime-update uses stack source manifests for Linux when available',
    () {
      final checker = RecordingRuntimeUpdateChecker(
        result: const RuntimeUpdateCheckCompleted(
          RuntimeUpdateRecord(
            runtimeId: 'konyak-linux-wine',
            status: 'available',
            currentVersion: 'wine-10.0',
            latestVersion: 'wine-10.1',
            sourceManifestUrl:
                'https://example.invalid/linux-runtime-stack.json',
            sourceManifestSignatureUrl:
                'https://example.invalid/linux-runtime-stack.json.sig',
            archiveUrl: 'https://example.invalid/linux-runtime-stack.json',
          ),
        ),
      );
      final installer = RecordingLinuxWineInstaller(
        result: const LinuxWineInstallCompleted(
          runtime: RuntimeRecord(
            id: 'konyak-linux-wine',
            name: 'Konyak Linux Wine',
            platform: 'linux',
            architecture: 'x86_64',
            runnerKind: 'wine',
            isBundled: false,
            isUpdateable: true,
            isInstalled: true,
          ),
        ),
      );

      final result = runCli(
        const ['install-runtime-update', 'konyak-linux-wine', '--json'],
        runtimeUpdateChecker: checker,
        linuxWineInstaller: installer,
      );

      expect(result.exitCode, 0);
      expect(
        installer.lastRequest?.sourceManifest,
        'https://example.invalid/linux-runtime-stack.json',
      );
      expect(
        installer.lastRequest?.sourceManifestSignature,
        'https://example.invalid/linux-runtime-stack.json.sig',
      );
      expect(
        installer.lastRequest?.operation,
        RuntimeInstallOperation.updateInstall,
      );
      expect(installer.lastRequest?.archiveUrl, isNull);
      expect(installer.lastRequest?.force, isTrue);
    },
  );

  test(
    'runtime update checker uses source manifests from release metadata',
    () {
      final checker = DartIoRuntimeUpdateChecker(
        runtimeCatalog: StaticRuntimeCatalog([
          RuntimeRecord(
            id: 'konyak-linux-wine',
            name: 'Konyak Linux Wine',
            platform: 'linux',
            architecture: 'x86_64',
            runnerKind: 'wine',
            isBundled: false,
            isUpdateable: true,
            versionUrl: 'https://example.invalid/releases/latest',
            stack: RuntimeStack(
              id: 'linux-wine-runtime-stack',
              name: 'Linux Wine/Proton runtime stack',
              compatibilityTarget: 'linux-wine-runtime-stack',
              components: [
                RuntimeStackComponent(
                  id: 'wine',
                  name: 'Wine',
                  role: 'windows-runner',
                  isRequired: true,
                  paths: const <String>[],
                  missingPaths: const <String>[],
                  version: 'wine-10.0',
                ),
              ],
            ),
          ),
        ]),
        releaseMetadataFetcher: const StaticRuntimeReleaseMetadataFetcher(
          RuntimeReleaseMetadata(
            version: 'wine-10.1',
            sourceManifestUrl:
                'https://example.invalid/linux-runtime-stack-source.json',
            sourceManifestSignatureUrl:
                'https://example.invalid/linux-runtime-stack-source.json.sig',
          ),
        ),
      );

      final result = checker.check('konyak-linux-wine');

      expect(result, isA<RuntimeUpdateCheckCompleted>());
      final completed = result as RuntimeUpdateCheckCompleted;
      expect(completed.update.status, 'available');
      expect(
        completed.update.sourceManifestUrl,
        'https://example.invalid/linux-runtime-stack-source.json',
      );
      expect(
        completed.update.sourceManifestSignatureUrl,
        'https://example.invalid/linux-runtime-stack-source.json.sig',
      );
      expect(completed.update.archiveUrl, isNull);
    },
  );

  test(
    'runtime update checker ignores missing source manifests in release metadata',
    () {
      final checker = DartIoRuntimeUpdateChecker(
        runtimeCatalog: StaticRuntimeCatalog([
          RuntimeRecord(
            id: 'konyak-linux-wine',
            name: 'Konyak Linux Wine',
            platform: 'linux',
            architecture: 'x86_64',
            runnerKind: 'wine',
            isBundled: false,
            isUpdateable: true,
            versionUrl: 'https://example.invalid/releases/latest',
            stack: RuntimeStack(
              id: 'linux-wine-runtime-stack',
              name: 'Linux Wine/Proton runtime stack',
              compatibilityTarget: 'linux-wine-runtime-stack',
              components: [
                RuntimeStackComponent(
                  id: 'wine',
                  name: 'Wine',
                  role: 'windows-runner',
                  isRequired: true,
                  paths: const <String>[],
                  missingPaths: const <String>[],
                  version: 'wine-10.0',
                ),
              ],
            ),
          ),
        ]),
        releaseMetadataFetcher: const StaticRuntimeReleaseMetadataFetcher(
          RuntimeReleaseMetadata(
            version: 'wine-10.1',
            archiveUrl: 'https://example.invalid/linux-wine-10.1.tar.xz',
          ),
        ),
      );

      final result = checker.check('konyak-linux-wine');

      expect(result, isA<RuntimeUpdateCheckCompleted>());
      final completed = result as RuntimeUpdateCheckCompleted;
      expect(completed.update.status, 'available');
      expect(completed.update.sourceManifestUrl, isNull);
      expect(
        completed.update.archiveUrl,
        'https://example.invalid/linux-wine-10.1.tar.xz',
      );
    },
  );

  test(
    'runtime update checker compares Wine component version to release tag',
    () {
      final checker = DartIoRuntimeUpdateChecker(
        runtimeCatalog: StaticRuntimeCatalog([
          RuntimeRecord(
            id: 'konyak-macos-wine',
            name: 'Konyak macOS Wine',
            platform: 'macos',
            architecture: 'x86_64',
            runnerKind: 'macosWine',
            isBundled: false,
            isUpdateable: true,
            versionUrl: 'https://example.invalid/releases/latest',
            archiveUrl: 'https://example.invalid/runtime.tar.xz',
            stack: RuntimeStack(
              id: 'macos-konyak-runtime-stack',
              name: 'Konyak macOS runtime stack',
              compatibilityTarget: 'macos-konyak-runtime-stack',
              components: [
                RuntimeStackComponent(
                  id: 'wine',
                  name: 'Wine',
                  role: 'windows-runner',
                  isRequired: true,
                  paths: const <String>[],
                  missingPaths: const <String>[],
                  version: 'wine-devel-11.9',
                ),
              ],
            ),
          ),
        ]),
        releaseMetadataFetcher: const StaticRuntimeReleaseMetadataFetcher(
          RuntimeReleaseMetadata(version: '11.9'),
        ),
      );

      final result = checker.check('konyak-macos-wine');

      expect(result, isA<RuntimeUpdateCheckCompleted>());
      final completed = result as RuntimeUpdateCheckCompleted;
      expect(completed.update.status, 'current');
      expect(completed.update.currentVersion, 'wine-devel-11.9');
      expect(completed.update.latestVersion, '11.9');
    },
  );

  test('validate-runtime --json returns runtime loader checks', () {
    final validator = RecordingRuntimeValidator(
      result: RuntimeValidationCompleted(
        RuntimeValidationRecord(
          runtimeId: 'konyak-macos-wine',
          isValid: true,
          checks: [
            RuntimeValidationCheck(
              id: 'wine-loader',
              name: 'Wine loader',
              isRequired: true,
              isPassed: true,
              message: 'wine64 --version completed.',
            ),
          ],
        ),
      ),
    );

    final result = runCli(const [
      'validate-runtime',
      'konyak-macos-wine',
      '--json',
    ], runtimeValidator: validator);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(validator.lastRuntimeId, 'konyak-macos-wine');

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'runtimeValidation': {
        'runtimeId': 'konyak-macos-wine',
        'isValid': true,
        'checks': [
          {
            'id': 'wine-loader',
            'name': 'Wine loader',
            'isRequired': true,
            'isPassed': true,
            'message': 'wine64 --version completed.',
          },
        ],
      },
    });
  });

  test('check-macos-setup --json returns Rosetta and runtime status', () {
    final checker = RecordingMacosSetupChecker(
      result: const MacosSetupCheckCompleted(
        MacosSetupStatus(
          isSupported: true,
          rosetta: RosettaSetupStatus(
            isRequired: true,
            isInstalled: true,
            installCommand: [
              '/usr/sbin/softwareupdate',
              '--install-rosetta',
              '--agree-to-license',
            ],
          ),
          runtime: RuntimeSetupStatus(
            runtimeId: 'konyak-macos-wine',
            isInstalled: false,
          ),
        ),
      ),
    );

    final result = runCli(const [
      'check-macos-setup',
      '--json',
    ], macosSetupChecker: checker);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'macosSetup': {
        'isSupported': true,
        'rosetta': {
          'isRequired': true,
          'isInstalled': true,
          'installCommand': [
            '/usr/sbin/softwareupdate',
            '--install-rosetta',
            '--agree-to-license',
          ],
        },
        'runtime': {'runtimeId': 'konyak-macos-wine', 'isInstalled': false},
      },
    });
  });

  test('macOS setup checker detects Rosetta and runtime prerequisites', () {
    final checker = DartIoMacosSetupChecker(
      hostPlatform: KonyakHostPlatform.macos,
      fileStatusProbe: const StaticFileStatusProbe({
        '/Library/Apple/usr/libexec/oah/libRosettaRuntime',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wine64',
      }),
      runtimeCatalog: MacosWineRuntimeCatalog(
        hostPlatform: KonyakHostPlatform.macos,
        environment: const {'HOME': '/Users/user'},
        fileStatusProbe: const StaticFileStatusProbe({
          '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wine64',
        }),
      ),
    );

    final result = checker.check();

    expect(result, isA<MacosSetupCheckCompleted>());
    final status = (result as MacosSetupCheckCompleted).status;
    expect(status.isSupported, isTrue);
    expect(status.rosetta.isRequired, isTrue);
    expect(status.rosetta.isInstalled, isTrue);
    expect(status.runtime.runtimeId, 'konyak-macos-wine');
    expect(status.runtime.isInstalled, isTrue);
  });

  test('macOS runtime validator checks dylibs before loader execution', () {
    final executableProbe = RecordingRuntimeExecutableProbe(
      result: const RuntimeExecutableProbeResult(
        exitCode: 0,
        stdout: 'wine-11.9',
        stderr: '',
      ),
    );
    final validator = DartIoMacosWineRuntimeValidator(
      runtimeCatalog: const StaticRuntimeCatalog([
        RuntimeRecord(
          id: 'konyak-macos-wine',
          name: 'Konyak macOS Wine',
          platform: 'macos',
          architecture: 'x86_64',
          runnerKind: 'macosWine',
          isBundled: false,
          isUpdateable: true,
          libraryPath: '/runtime',
          executablePath: '/runtime/bin/wine64',
        ),
      ]),
      fileStatusProbe: const StaticFileStatusProbe({
        '/runtime',
        '/runtime/bin/wine64',
      }),
      executableProbe: executableProbe,
    );

    final result = validator.validate('konyak-macos-wine');

    expect(result, isA<RuntimeValidationCompleted>());
    final validation = (result as RuntimeValidationCompleted).validation;
    expect(validation.isValid, isFalse);
    expect(
      validation.checks.where((check) => check.id == 'loader-dylibs').single,
      isA<RuntimeValidationCheck>()
          .having((check) => check.isPassed, 'isPassed', isFalse)
          .having(
            (check) => check.message,
            'message',
            contains('/runtime/lib/libwine.1.dylib'),
          ),
    );
    expect(executableProbe.lastExecutable, isNull);
  });

  test('macOS runtime validator runs wine64 with dylib search paths', () {
    final executableProbe = RecordingRuntimeExecutableProbe(
      result: const RuntimeExecutableProbeResult(
        exitCode: 0,
        stdout: 'wine-11.9',
        stderr: '',
      ),
    );
    final validator = DartIoMacosWineRuntimeValidator(
      runtimeCatalog: const StaticRuntimeCatalog([
        RuntimeRecord(
          id: 'konyak-macos-wine',
          name: 'Konyak macOS Wine',
          platform: 'macos',
          architecture: 'x86_64',
          runnerKind: 'macosWine',
          isBundled: false,
          isUpdateable: true,
          libraryPath: '/runtime',
          executablePath: '/runtime/bin/wine64',
        ),
      ]),
      fileStatusProbe: const StaticFileStatusProbe({
        '/runtime',
        '/runtime/bin/wine64',
        '/runtime/bin/wineserver',
        '/runtime/lib/libwine.1.dylib',
      }),
      executableProbe: executableProbe,
    );

    final result = validator.validate('konyak-macos-wine');

    expect(result, isA<RuntimeValidationCompleted>());
    final validation = (result as RuntimeValidationCompleted).validation;
    expect(validation.isValid, isTrue);
    expect(executableProbe.lastExecutable, '/runtime/bin/wine64');
    expect(executableProbe.lastArguments, const ['--version']);
    expect(executableProbe.lastWorkingDirectory, '/runtime/bin');
    expect(
      executableProbe.lastEnvironment,
      containsPair('DYLD_LIBRARY_PATH', '/runtime/lib'),
    );
  });

  test('install-macos-wine --json installs from a configured archive source', () {
    final installer = RecordingMacosWineInstaller(
      result: const MacosWineInstallCompleted(
        runtime: RuntimeRecord(
          id: 'konyak-macos-wine',
          name: 'Konyak macOS Wine',
          platform: 'macos',
          architecture: 'x86_64',
          runnerKind: 'macosWine',
          isBundled: false,
          isUpdateable: true,
          isInstalled: true,
          applicationSupportPath:
              '/Users/user/Library/Application Support/Konyak',
          libraryPath:
              '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine',
          executablePath:
              '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wine64',
          archiveUrl:
              'https://github.com/Gcenx/macOS_Wine_builds/releases/download/11.9/wine-devel-11.9-osx64.tar.xz',
          versionUrl:
              'https://api.github.com/repos/Gcenx/macOS_Wine_builds/releases/latest',
        ),
      ),
    );

    final result = runCli(const [
      'install-macos-wine',
      '--json',
    ], macosWineInstaller: installer);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(installer.lastRequest?.archivePath, isNull);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'runtime': {
        'id': 'konyak-macos-wine',
        'name': 'Konyak macOS Wine',
        'platform': 'macos',
        'architecture': 'x86_64',
        'runnerKind': 'macosWine',
        'isBundled': false,
        'isUpdateable': true,
        'isInstalled': true,
        'applicationSupportPath':
            '/Users/user/Library/Application Support/Konyak',
        'libraryPath':
            '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine',
        'executablePath':
            '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wine64',
      },
    });
  });

  test('install-macos-wine --json is a no-op when Konyak macOS Wine is installed', () {
    final installer = DartIoMacosWineInstaller(
      hostPlatform: KonyakHostPlatform.macos,
      environment: const {'HOME': '/Users/user'},
      fileStatusProbe: const StaticFileStatusProbe({
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wine64',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wineserver',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wine',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/DXVK/x64/dxgi.dll',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/DXVK/x32/dxgi.dll',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/libMoltenVK.dylib',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/libgstreamer-1.0.0.dylib',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/share/wine/mono',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/winetricks',
      }),
    );

    final result = runCli(const [
      'install-macos-wine',
      '--json',
    ], macosWineInstaller: installer);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload['runtime'], containsPair('isInstalled', true));
    expect(
      payload['runtime'],
      containsPair(
        'executablePath',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wine64',
      ),
    );
  });

  test(
    'install-macos-wine repairs an incomplete existing runtime from an archive',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'konyak-runtime-repair-test-',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final runtimeHome = _joinTestPath(tempDirectory.path, const [
        'Application Support',
        'Konyak',
      ]);
      final existingWine = File(
        _joinTestPath(runtimeHome, const [
          'Runtimes',
          'macos-wine',
          'bin',
          'wine64',
        ]),
      );
      existingWine.parent.createSync(recursive: true);
      existingWine.writeAsStringSync('incomplete-runtime');

      final archivePath = _createKonyakComponentRuntimeArchive(
        tempDirectory.path,
      );
      final installer = DartIoMacosWineInstaller(
        hostPlatform: KonyakHostPlatform.macos,
        environment: {'KONYAK_APPLICATION_SUPPORT': runtimeHome},
        fileStatusProbe: StaticFileStatusProbe({existingWine.path}),
      );

      final result = installer.install(
        MacosWineInstallRequest(archivePath: archivePath),
      );

      expect(result, isA<MacosWineInstallCompleted>());
      final completed = result as MacosWineInstallCompleted;
      expect(completed.runtime.stack?.isComplete, isTrue);
      expect(existingWine.readAsStringSync(), 'fixture');
    },
  );

  test('install-macos-wine normalizes a component stack archive', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'konyak-runtime-stack-test-',
    );
    addTearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    final archivePath = _createComponentRuntimeArchive(tempDirectory.path);
    final runtimeHome = _joinTestPath(tempDirectory.path, const [
      'Application Support',
      'Konyak',
    ]);
    final installer = DartIoMacosWineInstaller(
      hostPlatform: KonyakHostPlatform.macos,
      environment: {'KONYAK_APPLICATION_SUPPORT': runtimeHome},
      fileStatusProbe: const StaticFileStatusProbe({}),
    );

    final result = installer.install(
      MacosWineInstallRequest(archivePath: archivePath),
    );

    expect(result, isA<MacosWineInstallCompleted>());
    final completed = result as MacosWineInstallCompleted;
    expect(completed.runtime.isInstalled, isTrue);
    expect(completed.runtime.stack?.isComplete, isTrue);
    expect(
      completed.runtime.stack?.components.first.version,
      'wine-devel-11.9',
    );
    expect(
      completed.runtime.stack?.components[2].version,
      'dxvk-macos-fixture',
    );
    expect(
      File(
        _joinTestPath(runtimeHome, const [
          'Runtimes',
          'macos-wine',
          'bin',
          'wine64',
        ]),
      ).existsSync(),
      isTrue,
    );
    expect(
      Directory(
        _joinTestPath(runtimeHome, const ['Runtimes', 'macos-wine', 'Wine']),
      ).existsSync(),
      isFalse,
    );
  });

  test(
    'install-macos-wine keeps the existing runtime when extraction fails',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'konyak-runtime-rollback-test-',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final runtimeHome = _joinTestPath(tempDirectory.path, const [
        'Application Support',
        'Konyak',
      ]);
      final existingWine = File(
        _joinTestPath(runtimeHome, const [
          'Runtimes',
          'macos-wine',
          'bin',
          'wine64',
        ]),
      );
      existingWine.parent.createSync(recursive: true);
      existingWine.writeAsStringSync('existing-runtime');

      final badArchive = _createBrokenRuntimeArchive(tempDirectory.path);
      final installer = DartIoMacosWineInstaller(
        hostPlatform: KonyakHostPlatform.macos,
        environment: {'KONYAK_APPLICATION_SUPPORT': runtimeHome},
        fileStatusProbe: const StaticFileStatusProbe({}),
      );

      final result = installer.install(
        MacosWineInstallRequest(archivePath: badArchive),
      );

      expect(result, isA<MacosWineInstallFailed>());
      expect(existingWine.readAsStringSync(), 'existing-runtime');
    },
  );

  test(
    'install-macos-wine keeps the existing runtime when component extraction fails',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'konyak-runtime-component-rollback-test-',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final runtimeHome = _joinTestPath(tempDirectory.path, const [
        'Application Support',
        'Konyak',
      ]);
      final existingWine = File(
        _joinTestPath(runtimeHome, const [
          'Runtimes',
          'macos-wine',
          'bin',
          'wine64',
        ]),
      );
      existingWine.parent.createSync(recursive: true);
      existingWine.writeAsStringSync('existing-runtime');

      final archivePath = _createKonyakComponentRuntimeArchive(
        tempDirectory.path,
      );
      final badComponentArchive = _createInvalidRuntimeArchive(
        tempDirectory.path,
      );
      final installer = DartIoMacosWineInstaller(
        hostPlatform: KonyakHostPlatform.macos,
        environment: {'KONYAK_APPLICATION_SUPPORT': runtimeHome},
        fileStatusProbe: const StaticFileStatusProbe({}),
      );

      final result = installer.install(
        MacosWineInstallRequest(
          archivePath: archivePath,
          componentArchivePaths: [badComponentArchive],
        ),
      );

      expect(result, isA<MacosWineInstallFailed>());
      expect(existingWine.readAsStringSync(), 'existing-runtime');
    },
  );

  test('install-macos-wine refuses to mutate a locked runtime root', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'konyak-runtime-install-lock-test-',
    );
    addTearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    final runtimeHome = _joinTestPath(tempDirectory.path, const [
      'Application Support',
      'Konyak',
    ]);
    final runtimeRoot = _joinTestPath(runtimeHome, const [
      'Runtimes',
      'macos-wine',
    ]);
    final existingWine = File(
      _joinTestPath(runtimeRoot, const ['bin', 'wine64']),
    );
    existingWine.parent.createSync(recursive: true);
    existingWine.writeAsStringSync('existing-runtime');
    Directory('$runtimeRoot.install.lock').createSync(recursive: true);

    final archivePath = _createKonyakComponentRuntimeArchive(
      tempDirectory.path,
    );
    final installer = DartIoMacosWineInstaller(
      hostPlatform: KonyakHostPlatform.macos,
      environment: {'KONYAK_APPLICATION_SUPPORT': runtimeHome},
      fileStatusProbe: const StaticFileStatusProbe({}),
    );

    final result = installer.install(
      MacosWineInstallRequest(archivePath: archivePath),
    );

    expect(result, isA<MacosWineInstallFailed>());
    expect((result as MacosWineInstallFailed).message, contains('already'));
    expect(existingWine.readAsStringSync(), 'existing-runtime');
  });

  test(
    'install-macos-wine normalizes Konyak runtime component layout',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'konyak-runtime-components-test-',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final archivePath = _createKonyakComponentRuntimeArchive(
        tempDirectory.path,
      );
      final runtimeHome = _joinTestPath(tempDirectory.path, const [
        'Application Support',
        'Konyak',
      ]);
      final installer = DartIoMacosWineInstaller(
        hostPlatform: KonyakHostPlatform.macos,
        environment: {'KONYAK_APPLICATION_SUPPORT': runtimeHome},
        fileStatusProbe: const StaticFileStatusProbe({}),
      );

      final result = installer.install(
        MacosWineInstallRequest(archivePath: archivePath),
      );

      expect(result, isA<MacosWineInstallCompleted>());
      final completed = result as MacosWineInstallCompleted;
      expect(completed.runtime.stack?.isComplete, isTrue);
      expect(
        completed.runtime.stack?.components
            .where((component) => component.id == 'dxvk-macos')
            .single
            .version,
        'dxvk-macos-fixture',
      );
      expect(
        File(
          _joinTestPath(runtimeHome, const [
            'Runtimes',
            'macos-wine',
            'DXVK',
            'x64',
            'dxgi.dll',
          ]),
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          _joinTestPath(runtimeHome, const [
            'Runtimes',
            'macos-wine',
            'lib',
            'libMoltenVK.dylib',
          ]),
        ).existsSync(),
        isTrue,
      );
      expect(
        Directory(
          _joinTestPath(runtimeHome, const [
            'Runtimes',
            'macos-wine',
            'share',
            'wine',
            'mono',
          ]),
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          _joinTestPath(runtimeHome, const [
            'Runtimes',
            'macos-wine',
            'winetricks',
          ]),
        ).existsSync(),
        isTrue,
      );
      expect(
        Directory(
          _joinTestPath(runtimeHome, const [
            'Runtimes',
            'macos-wine',
            'Components',
          ]),
        ).existsSync(),
        isFalse,
      );
    },
  );

  test('install-macos-wine builds a stack from component archives', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'konyak-runtime-stack-components-test-',
    );
    addTearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    final wineArchive = _createMacosAppBundleWineArchive(tempDirectory.path);
    final dxvkArchive = _createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'dxvk-macos',
      relativePaths: const <List<String>>[
        <String>['Components', 'DXVK-macOS', 'DXVK', 'x64', 'dxgi.dll'],
        <String>['Components', 'DXVK-macOS', 'DXVK', 'x32', 'dxgi.dll'],
      ],
      versions: const <String, String>{'dxvk-macos': 'dxvk-macos-fixture'},
    );
    final moltenVkArchive = _createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'moltenvk',
      relativePaths: const <List<String>>[
        <String>['Components', 'MoltenVK', 'lib', 'libMoltenVK.dylib'],
      ],
      versions: const <String, String>{'moltenvk': 'moltenvk-fixture'},
    );
    final gstreamerArchive = _createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'gstreamer',
      relativePaths: const <List<String>>[
        <String>['Components', 'GStreamer', 'lib', 'libgstreamer-1.0.0.dylib'],
      ],
      versions: const <String, String>{'gstreamer': 'gstreamer-fixture'},
    );
    final monoArchive = _createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'wine-mono',
      relativePaths: const <List<String>>[
        <String>['Components', 'wine-mono', 'share', 'wine', 'mono', 'marker'],
      ],
      versions: const <String, String>{'wine-mono': 'wine-mono-fixture'},
    );
    final winetricksArchive = _createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'winetricks',
      relativePaths: const <List<String>>[
        <String>['Components', 'winetricks', 'winetricks'],
      ],
      versions: const <String, String>{'winetricks': 'winetricks-fixture'},
    );
    final runtimeHome = _joinTestPath(tempDirectory.path, const [
      'Application Support',
      'Konyak',
    ]);
    final installer = DartIoMacosWineInstaller(
      hostPlatform: KonyakHostPlatform.macos,
      environment: {'KONYAK_APPLICATION_SUPPORT': runtimeHome},
      fileStatusProbe: const StaticFileStatusProbe({}),
    );

    final result = installer.install(
      MacosWineInstallRequest(
        archivePath: wineArchive,
        componentArchivePaths: [
          dxvkArchive,
          moltenVkArchive,
          gstreamerArchive,
          monoArchive,
          winetricksArchive,
        ],
      ),
    );

    expect(result, isA<MacosWineInstallCompleted>());
    final completed = result as MacosWineInstallCompleted;
    expect(completed.runtime.stack?.isComplete, isTrue);
    expect(
      completed.runtime.stack?.components
          .where((component) => component.id == 'dxvk-macos')
          .single
          .version,
      'dxvk-macos-fixture',
    );
    expect(
      completed.runtime.stack?.components
          .where((component) => component.id == 'moltenvk')
          .single
          .version,
      'moltenvk-fixture',
    );
    expect(
      File(
        _joinTestPath(runtimeHome, const [
          'Runtimes',
          'macos-wine',
          'lib',
          'libgstreamer-1.0.0.dylib',
        ]),
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        _joinTestPath(runtimeHome, const [
          'Runtimes',
          'macos-wine',
          'winetricks',
        ]),
      ).existsSync(),
      isTrue,
    );
  });

  test('install-macos-wine builds a stack from a source manifest', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'konyak-runtime-stack-source-test-',
    );
    addTearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    final wineArchive = _createMacosAppBundleWineArchive(tempDirectory.path);
    final dxvkArchive = _createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'source-dxvk-macos',
      relativePaths: const <List<String>>[
        <String>['Components', 'DXVK-macOS', 'DXVK', 'x64', 'dxgi.dll'],
        <String>['Components', 'DXVK-macOS', 'DXVK', 'x32', 'dxgi.dll'],
      ],
      versions: const <String, String>{},
    );
    final moltenVkArchive = _createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'source-moltenvk',
      relativePaths: const <List<String>>[
        <String>['Components', 'MoltenVK', 'lib', 'libMoltenVK.dylib'],
      ],
      versions: const <String, String>{},
    );
    final gstreamerArchive = _createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'source-gstreamer',
      relativePaths: const <List<String>>[
        <String>['Components', 'GStreamer', 'lib', 'libgstreamer-1.0.0.dylib'],
      ],
      versions: const <String, String>{},
    );
    final monoArchive = _createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'source-wine-mono',
      relativePaths: const <List<String>>[
        <String>['Components', 'wine-mono', 'share', 'wine', 'mono', 'marker'],
      ],
      versions: const <String, String>{},
    );
    final winetricksArchive = _createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'source-winetricks',
      relativePaths: const <List<String>>[
        <String>['Components', 'winetricks', 'winetricks'],
      ],
      versions: const <String, String>{},
    );
    final sourceManifestPath = _createRuntimeStackSourceManifest(
      tempDirectory.path,
      components: <Map<String, String>>[
        _runtimeStackSourceComponent(
          id: 'wine',
          version: 'wine-devel-source',
          archivePath: wineArchive,
        ),
        _runtimeStackSourceComponent(
          id: 'dxvk-macos',
          version: 'dxvk-source',
          archivePath: dxvkArchive,
        ),
        _runtimeStackSourceComponent(
          id: 'moltenvk',
          version: 'moltenvk-source',
          archivePath: moltenVkArchive,
        ),
        _runtimeStackSourceComponent(
          id: 'gstreamer',
          version: 'gstreamer-source',
          archivePath: gstreamerArchive,
        ),
        _runtimeStackSourceComponent(
          id: 'wine-mono',
          version: 'wine-mono-source',
          archivePath: monoArchive,
        ),
        _runtimeStackSourceComponent(
          id: 'winetricks',
          version: 'winetricks-source',
          archivePath: winetricksArchive,
        ),
      ],
    );
    final runtimeHome = _joinTestPath(tempDirectory.path, const [
      'Application Support',
      'Konyak',
    ]);
    final installer = DartIoMacosWineInstaller(
      hostPlatform: KonyakHostPlatform.macos,
      environment: {'KONYAK_APPLICATION_SUPPORT': runtimeHome},
      fileStatusProbe: const StaticFileStatusProbe({}),
    );

    final result = installer.install(
      MacosWineInstallRequest(sourceManifest: sourceManifestPath),
    );

    expect(result, isA<MacosWineInstallCompleted>());
    final completed = result as MacosWineInstallCompleted;
    expect(completed.runtime.stack?.isComplete, isTrue);
    expect(
      completed.runtime.stack?.components
          .where((component) => component.id == 'wine')
          .single
          .version,
      'wine-devel-source',
    );
    expect(
      completed.runtime.stack?.components
          .where((component) => component.id == 'winetricks')
          .single
          .version,
      'winetricks-source',
    );
  });

  test(
    'install-macos-wine rejects source manifest checksum mismatches',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'konyak-runtime-stack-source-checksum-test-',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final wineArchive = _createMacosAppBundleWineArchive(tempDirectory.path);
      final sourceManifestPath = _createRuntimeStackSourceManifest(
        tempDirectory.path,
        components: <Map<String, String>>[
          <String, String>{
            ..._runtimeStackSourceComponent(
              id: 'wine',
              version: 'wine-devel-source',
              archivePath: wineArchive,
            ),
            'sha256':
                'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff',
          },
        ],
      );
      final installer = DartIoMacosWineInstaller(
        hostPlatform: KonyakHostPlatform.macos,
        environment: {'KONYAK_APPLICATION_SUPPORT': tempDirectory.path},
        fileStatusProbe: const StaticFileStatusProbe({}),
      );

      final result = installer.install(
        MacosWineInstallRequest(sourceManifest: sourceManifestPath),
      );

      expect(result, isA<MacosWineInstallFailed>());
      expect(
        (result as MacosWineInstallFailed).message,
        contains('checksum mismatch'),
      );
    },
  );

  test(
    'install-macos-wine normalizes a macOS app bundle Wine archive',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'konyak-runtime-app-bundle-test-',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final archivePath = _createMacosAppBundleWineArchive(tempDirectory.path);
      final runtimeHome = _joinTestPath(tempDirectory.path, const [
        'Application Support',
        'Konyak',
      ]);
      final installer = DartIoMacosWineInstaller(
        hostPlatform: KonyakHostPlatform.macos,
        environment: {'KONYAK_APPLICATION_SUPPORT': runtimeHome},
        fileStatusProbe: const StaticFileStatusProbe({}),
      );

      final result = installer.install(
        MacosWineInstallRequest(archivePath: archivePath),
      );

      expect(result, isA<MacosWineInstallCompleted>());
      final completed = result as MacosWineInstallCompleted;
      expect(completed.runtime.isInstalled, isTrue);
      expect(
        File(
          _joinTestPath(runtimeHome, const [
            'Runtimes',
            'macos-wine',
            'bin',
            'wine64',
          ]),
        ).existsSync(),
        isTrue,
      );
      expect(
        Link(
          _joinTestPath(runtimeHome, const [
            'Runtimes',
            'macos-wine',
            'bin',
            'wine64',
          ]),
        ).targetSync(),
        'wine',
      );
      expect(
        Directory(
          _joinTestPath(runtimeHome, const [
            'Runtimes',
            'macos-wine',
            'Contents',
            'Resources',
            'wine',
          ]),
        ).existsSync(),
        isFalse,
      );
    },
  );

  test('install-macos-wine --archive passes an explicit archive path', () {
    final installer = RecordingMacosWineInstaller(
      result: const MacosWineInstallCompleted(
        runtime: RuntimeRecord(
          id: 'konyak-macos-wine',
          name: 'Konyak macOS Wine',
          platform: 'macos',
          architecture: 'x86_64',
          runnerKind: 'macosWine',
          isBundled: false,
          isUpdateable: true,
        ),
      ),
    );

    final result = runCli(const [
      'install-macos-wine',
      '--archive',
      '/tmp/macos-wine.tar.xz',
      '--json',
    ], macosWineInstaller: installer);

    expect(result.exitCode, 0);
    expect(installer.lastRequest?.archivePath, '/tmp/macos-wine.tar.xz');
  });

  test('install-macos-wine --archive-sha256 passes an expected digest', () {
    final installer = RecordingMacosWineInstaller(
      result: const MacosWineInstallCompleted(
        runtime: RuntimeRecord(
          id: 'konyak-macos-wine',
          name: 'Konyak macOS Wine',
          platform: 'macos',
          architecture: 'x86_64',
          runnerKind: 'macosWine',
          isBundled: false,
          isUpdateable: true,
        ),
      ),
    );

    final result = runCli(const [
      'install-macos-wine',
      '--archive',
      '/tmp/macos-wine.tar.xz',
      '--archive-sha256',
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
      '--json',
    ], macosWineInstaller: installer);

    expect(result.exitCode, 0);
    expect(installer.lastRequest?.archivePath, '/tmp/macos-wine.tar.xz');
    expect(
      installer.lastRequest?.archiveSha256,
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
    );
  });

  test('install-macos-wine --component-archive passes component archives', () {
    final installer = RecordingMacosWineInstaller(
      result: const MacosWineInstallCompleted(
        runtime: RuntimeRecord(
          id: 'konyak-macos-wine',
          name: 'Konyak macOS Wine',
          platform: 'macos',
          architecture: 'x86_64',
          runnerKind: 'macosWine',
          isBundled: false,
          isUpdateable: true,
          isInstalled: true,
        ),
      ),
    );

    final result = runCli(const [
      'install-macos-wine',
      '--archive',
      '/tmp/wine.tar.xz',
      '--component-archive',
      '/tmp/dxvk.tar.xz',
      '--component-archive',
      '/tmp/moltenvk.tar.xz',
      '--json',
    ], macosWineInstaller: installer);

    expect(result.exitCode, 0);
    expect(installer.lastRequest?.archivePath, '/tmp/wine.tar.xz');
    expect(installer.lastRequest?.componentArchivePaths, [
      '/tmp/dxvk.tar.xz',
      '/tmp/moltenvk.tar.xz',
    ]);
    expect(
      installer.lastRequest?.operation,
      RuntimeInstallOperation.componentInstall,
    );
  });

  test('install-macos-wine --source-manifest passes the source manifest', () {
    final installer = RecordingMacosWineInstaller(
      result: const MacosWineInstallCompleted(
        runtime: RuntimeRecord(
          id: 'konyak-macos-wine',
          name: 'Konyak macOS Wine',
          platform: 'macos',
          architecture: 'x86_64',
          runnerKind: 'macosWine',
          isBundled: false,
          isUpdateable: true,
          isInstalled: true,
        ),
      ),
    );

    final result = runCli(const [
      'install-macos-wine',
      '--source-manifest',
      '/tmp/runtime-stack.json',
      '--json',
    ], macosWineInstaller: installer);

    expect(result.exitCode, 0);
    expect(installer.lastRequest?.sourceManifest, '/tmp/runtime-stack.json');
  });

  test('install-macos-wine rejects archive checksum mismatches', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'konyak-runtime-checksum-test-',
    );
    addTearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    final archive = File(
      _joinTestPath(tempDirectory.path, const ['runtime.tar.xz']),
    )..writeAsStringSync('not a runtime');
    final installer = DartIoMacosWineInstaller(
      hostPlatform: KonyakHostPlatform.macos,
      environment: {'KONYAK_APPLICATION_SUPPORT': tempDirectory.path},
      fileStatusProbe: const StaticFileStatusProbe({}),
    );

    final result = installer.install(
      MacosWineInstallRequest(
        archivePath: archive.path,
        archiveSha256:
            'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff',
      ),
    );

    expect(result, isA<MacosWineInstallFailed>());
    expect(
      (result as MacosWineInstallFailed).message,
      contains('checksum mismatch'),
    );
  });

  test('install-macos-wine --json returns installer failures as JSON', () {
    final result = runCli(
      const ['install-macos-wine', '--json'],
      macosWineInstaller: RecordingMacosWineInstaller(
        result: const MacosWineInstallFailed('download failed'),
      ),
    );

    expect(result.exitCode, 75);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'error': {'code': 'macosWineInstallFailed', 'message': 'download failed'},
    });
  });

  test('install-linux-wine --archive passes an explicit archive path', () {
    final installer = RecordingLinuxWineInstaller(
      result: const LinuxWineInstallCompleted(
        runtime: RuntimeRecord(
          id: 'konyak-linux-wine',
          name: 'Konyak Linux Wine',
          platform: 'linux',
          architecture: 'x86_64',
          runnerKind: 'wine',
          isBundled: false,
          isUpdateable: false,
        ),
      ),
    );

    final result = runCli(const [
      'install-linux-wine',
      '--archive',
      '/tmp/linux-wine.tar.xz',
      '--json',
    ], linuxWineInstaller: installer);

    expect(result.exitCode, 0);
    expect(installer.lastRequest?.archivePath, '/tmp/linux-wine.tar.xz');
  });

  test('install-linux-wine --component-archive passes component archives', () {
    final installer = RecordingLinuxWineInstaller(
      result: const LinuxWineInstallCompleted(
        runtime: RuntimeRecord(
          id: 'konyak-linux-wine',
          name: 'Konyak Linux Wine',
          platform: 'linux',
          architecture: 'x86_64',
          runnerKind: 'wine',
          isBundled: false,
          isUpdateable: false,
        ),
      ),
    );

    final result = runCli(const [
      'install-linux-wine',
      '--archive',
      '/tmp/linux-wine.tar.xz',
      '--component-archive',
      '/tmp/vkd3d-proton.tar.xz',
      '--json',
    ], linuxWineInstaller: installer);

    expect(result.exitCode, 0);
    expect(installer.lastRequest?.archivePath, '/tmp/linux-wine.tar.xz');
    expect(installer.lastRequest?.componentArchivePaths, const [
      '/tmp/vkd3d-proton.tar.xz',
    ]);
    expect(
      installer.lastRequest?.operation,
      RuntimeInstallOperation.componentInstall,
    );
  });

  test('install-linux-wine --source-manifest passes the source manifest', () {
    final installer = RecordingLinuxWineInstaller(
      result: const LinuxWineInstallCompleted(
        runtime: RuntimeRecord(
          id: 'konyak-linux-wine',
          name: 'Konyak Linux Wine',
          platform: 'linux',
          architecture: 'x86_64',
          runnerKind: 'wine',
          isBundled: false,
          isUpdateable: false,
        ),
      ),
    );

    final result = runCli(const [
      'install-linux-wine',
      '--source-manifest',
      '/tmp/linux-runtime-stack.json',
      '--json',
    ], linuxWineInstaller: installer);

    expect(result.exitCode, 0);
    expect(
      installer.lastRequest?.sourceManifest,
      '/tmp/linux-runtime-stack.json',
    );
  });

  test('install-linux-wine installs a managed runtime under XDG data home', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-linux-runtime-install-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    final archivePath = _createLinuxWineRuntimeArchive(tempDirectory.path);
    final installer = DartIoLinuxWineInstaller(
      hostPlatform: KonyakHostPlatform.linux,
      environment: {
        'HOME': tempDirectory.path,
        'XDG_DATA_HOME': _joinTestPath(tempDirectory.path, const ['xdg-data']),
      },
      fileStatusProbe: const DartIoFileStatusProbe(),
    );

    final result = installer.install(
      LinuxWineInstallRequest(archivePath: archivePath),
    );

    expect(result, isA<LinuxWineInstallCompleted>());
    final runtime = (result as LinuxWineInstallCompleted).runtime;
    expect(runtime.isInstalled, isTrue);
    expect(
      runtime.executablePath,
      _joinTestPath(tempDirectory.path, const [
        'xdg-data',
        'konyak',
        'Runtimes',
        'linux-wine',
        'bin',
        'wine',
      ]),
    );
    expect(File(runtime.executablePath!).existsSync(), isTrue);
    expect(
      File(
        _joinTestPath(tempDirectory.path, const [
          'xdg-data',
          'konyak',
          'Runtimes',
          'linux-wine',
          'bin',
          'wineboot',
        ]),
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        _joinTestPath(tempDirectory.path, const [
          'xdg-data',
          'konyak',
          'Runtimes',
          'linux-wine',
          'bin',
          'winedbg',
        ]),
      ).existsSync(),
      isTrue,
    );
  });

  test('install-linux-wine builds a stack from component archives', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-linux-runtime-stack-components-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    final wineArchive = _createLinuxWineRuntimeArchive(tempDirectory.path);
    final vkd3dArchive = _createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'vkd3d-proton',
      relativePaths: const <List<String>>[
        <String>['vkd3d-proton', 'x64', 'd3d12.dll'],
        <String>['vkd3d-proton', 'x86', 'd3d12.dll'],
      ],
      versions: const <String, String>{'vkd3d-proton': 'vkd3d-proton-fixture'},
    );
    final installer = DartIoLinuxWineInstaller(
      hostPlatform: KonyakHostPlatform.linux,
      environment: {
        'HOME': tempDirectory.path,
        'XDG_DATA_HOME': _joinTestPath(tempDirectory.path, const ['xdg-data']),
      },
      fileStatusProbe: const DartIoFileStatusProbe(),
    );

    final result = installer.install(
      LinuxWineInstallRequest(
        archivePath: wineArchive,
        componentArchivePaths: [vkd3dArchive],
      ),
    );

    expect(result, isA<LinuxWineInstallCompleted>());
    final runtime = (result as LinuxWineInstallCompleted).runtime;
    expect(runtime.stack?.isComplete, isTrue);
    expect(
      runtime.stack?.components
          .where((component) => component.id == 'vkd3d-proton')
          .single
          .version,
      'vkd3d-proton-fixture',
    );
    expect(
      File(
        _joinTestPath(tempDirectory.path, const [
          'xdg-data',
          'konyak',
          'Runtimes',
          'linux-wine',
          'vkd3d-proton',
          'x64',
          'd3d12.dll',
        ]),
      ).existsSync(),
      isTrue,
    );
  });

  test('install-linux-wine builds a stack from a source manifest', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-linux-runtime-stack-source-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    final wineArchive = _createLinuxWineRuntimeArchive(tempDirectory.path);
    final vkd3dArchive = _createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'source-vkd3d-proton',
      relativePaths: const <List<String>>[
        <String>['vkd3d-proton', 'x64', 'd3d12.dll'],
        <String>['vkd3d-proton', 'x86', 'd3d12.dll'],
      ],
      versions: const <String, String>{},
    );
    final sourceManifestPath = _createRuntimeStackSourceManifest(
      tempDirectory.path,
      runtimeId: 'konyak-linux-wine',
      stackId: 'linux-wine-runtime-stack',
      components: <Map<String, String>>[
        _runtimeStackSourceComponent(
          id: 'wine',
          version: 'wine-linux-source',
          archivePath: wineArchive,
        ),
        _runtimeStackSourceComponent(
          id: 'vkd3d-proton',
          version: 'vkd3d-linux-source',
          archivePath: vkd3dArchive,
        ),
      ],
    );
    final installer = DartIoLinuxWineInstaller(
      hostPlatform: KonyakHostPlatform.linux,
      environment: {
        'HOME': tempDirectory.path,
        'XDG_DATA_HOME': _joinTestPath(tempDirectory.path, const ['xdg-data']),
      },
      fileStatusProbe: const DartIoFileStatusProbe(),
    );

    final result = installer.install(
      LinuxWineInstallRequest(sourceManifest: sourceManifestPath),
    );

    expect(result, isA<LinuxWineInstallCompleted>());
    final runtime = (result as LinuxWineInstallCompleted).runtime;
    expect(runtime.stack?.isComplete, isTrue);
    expect(
      runtime.stack?.components
          .where((component) => component.id == 'vkd3d-proton')
          .single
          .version,
      'vkd3d-linux-source',
    );
  });

  test('install-linux-wine repairs an incomplete installed runtime', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-linux-runtime-repair-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    final dataHome = _joinTestPath(tempDirectory.path, const ['xdg-data']);
    final runtimeRoot = _joinTestPath(dataHome, const [
      'konyak',
      'Runtimes',
      'linux-wine',
    ]);
    final existingWine = File(
      _joinTestPath(runtimeRoot, const ['bin', 'wine']),
    );
    existingWine.parent.createSync(recursive: true);
    existingWine.writeAsStringSync('incomplete-runtime');

    final wineArchive = _createLinuxWineRuntimeArchive(tempDirectory.path);
    final vkd3dArchive = _createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'repair-vkd3d-proton',
      relativePaths: const <List<String>>[
        <String>['vkd3d-proton', 'x64', 'd3d12.dll'],
        <String>['vkd3d-proton', 'x86', 'd3d12.dll'],
      ],
      versions: const <String, String>{},
    );
    final sourceManifestPath = _createRuntimeStackSourceManifest(
      tempDirectory.path,
      runtimeId: 'konyak-linux-wine',
      stackId: 'linux-wine-runtime-stack',
      components: <Map<String, String>>[
        _runtimeStackSourceComponent(
          id: 'wine',
          version: 'wine-linux-repair',
          archivePath: wineArchive,
        ),
        _runtimeStackSourceComponent(
          id: 'vkd3d-proton',
          version: 'vkd3d-linux-repair',
          archivePath: vkd3dArchive,
        ),
      ],
    );
    final installer = DartIoLinuxWineInstaller(
      hostPlatform: KonyakHostPlatform.linux,
      environment: {
        'HOME': tempDirectory.path,
        'XDG_DATA_HOME': dataHome,
        'KONYAK_RUNTIME_PROFILE': 'development',
        'KONYAK_LINUX_WINE_STACK_MANIFEST': _joinTestPath(
          tempDirectory.path,
          const ['release-runtime-stack-source.json'],
        ),
        'KONYAK_DEV_LINUX_WINE_STACK_MANIFEST': sourceManifestPath,
      },
      fileStatusProbe: const DartIoFileStatusProbe(),
    );

    final result = installer.install(const LinuxWineInstallRequest());

    expect(result, isA<LinuxWineInstallCompleted>());
    final runtime = (result as LinuxWineInstallCompleted).runtime;
    expect(runtime.stack?.isComplete, isTrue);
    expect(existingWine.readAsStringSync(), 'fixture');
    expect(
      runtime.stack?.components
          .where((component) => component.id == 'vkd3d-proton')
          .single
          .version,
      'vkd3d-linux-repair',
    );
  });

  test('install-linux-wine verifies a signed source manifest', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-linux-runtime-stack-signed-source-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    final wineArchive = _createLinuxWineRuntimeArchive(tempDirectory.path);
    final vkd3dArchive = _createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'signed-source-vkd3d-proton',
      relativePaths: const <List<String>>[
        <String>['vkd3d-proton', 'x64', 'd3d12.dll'],
        <String>['vkd3d-proton', 'x86', 'd3d12.dll'],
      ],
      versions: const <String, String>{},
    );
    final sourceManifestPath = _createRuntimeStackSourceManifest(
      tempDirectory.path,
      runtimeId: 'konyak-linux-wine',
      stackId: 'linux-wine-runtime-stack',
      components: <Map<String, String>>[
        _runtimeStackSourceComponent(
          id: 'wine',
          version: 'wine-linux-signed-source',
          archivePath: wineArchive,
        ),
        _runtimeStackSourceComponent(
          id: 'vkd3d-proton',
          version: 'vkd3d-linux-signed-source',
          archivePath: vkd3dArchive,
        ),
      ],
    );
    final signature = _createRuntimeStackManifestSignature(
      tempDirectory.path,
      manifestPath: sourceManifestPath,
    );
    final installer = DartIoLinuxWineInstaller(
      hostPlatform: KonyakHostPlatform.linux,
      environment: {
        'HOME': tempDirectory.path,
        'XDG_DATA_HOME': _joinTestPath(tempDirectory.path, const ['xdg-data']),
        'KONYAK_RUNTIME_STACK_PUBLIC_KEY_PATH': signature.publicKeyPath,
      },
      fileStatusProbe: const DartIoFileStatusProbe(),
    );

    final result = installer.install(
      LinuxWineInstallRequest(
        sourceManifest: sourceManifestPath,
        sourceManifestSignature: signature.signaturePath,
      ),
    );

    expect(result, isA<LinuxWineInstallCompleted>());
  });

  test('install-linux-wine rejects invalid source manifest signatures', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-linux-runtime-stack-invalid-signature-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    final wineArchive = _createLinuxWineRuntimeArchive(tempDirectory.path);
    final vkd3dArchive = _createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'invalid-signed-source-vkd3d-proton',
      relativePaths: const <List<String>>[
        <String>['vkd3d-proton', 'x64', 'd3d12.dll'],
        <String>['vkd3d-proton', 'x86', 'd3d12.dll'],
      ],
      versions: const <String, String>{},
    );
    final sourceManifestPath = _createRuntimeStackSourceManifest(
      tempDirectory.path,
      runtimeId: 'konyak-linux-wine',
      stackId: 'linux-wine-runtime-stack',
      components: <Map<String, String>>[
        _runtimeStackSourceComponent(
          id: 'wine',
          version: 'wine-linux-invalid-signature',
          archivePath: wineArchive,
        ),
        _runtimeStackSourceComponent(
          id: 'vkd3d-proton',
          version: 'vkd3d-linux-invalid-signature',
          archivePath: vkd3dArchive,
        ),
      ],
    );
    final signature = _createRuntimeStackManifestSignature(
      tempDirectory.path,
      manifestPath: sourceManifestPath,
    );
    File(
      sourceManifestPath,
    ).writeAsStringSync('${File(sourceManifestPath).readAsStringSync()}\n');
    final installer = DartIoLinuxWineInstaller(
      hostPlatform: KonyakHostPlatform.linux,
      environment: {
        'HOME': tempDirectory.path,
        'XDG_DATA_HOME': _joinTestPath(tempDirectory.path, const ['xdg-data']),
        'KONYAK_RUNTIME_STACK_PUBLIC_KEY_PATH': signature.publicKeyPath,
      },
      fileStatusProbe: const DartIoFileStatusProbe(),
    );

    final result = installer.install(
      LinuxWineInstallRequest(
        sourceManifest: sourceManifestPath,
        sourceManifestSignature: signature.signaturePath,
      ),
    );

    expect(result, isA<LinuxWineInstallFailed>());
    expect(
      (result as LinuxWineInstallFailed).message,
      contains('signature verification failed'),
    );
  });

  test('executable prints the same machine-readable contract', () async {
    final dataHome = await Directory.systemTemp.createTemp('konyak-cli-test-');

    addTearDown(() async {
      if (await dataHome.exists()) {
        await dataHome.delete(recursive: true);
      }
    });

    final process = await Process.run(
      Platform.resolvedExecutable,
      const ['run', 'bin/konyak.dart', 'list-bottles', '--json'],
      environment: {
        'KONYAK_DATA_HOME': dataHome.path,
        'KONYAK_CONFIG_HOME': _joinTestPath(dataHome.path, const ['config']),
      },
    );

    expect(process.exitCode, 0);
    expect(process.stderr.toString(), isEmpty);

    final payload =
        jsonDecode(process.stdout.toString()) as Map<String, Object?>;
    expect(payload, {'schemaVersion': 1, 'bottles': <Object?>[]});
  });
}

final class RecordingProgramRunner implements ProgramRunner {
  RecordingProgramRunner({
    ProgramRunResult? result,
    List<ProgramRunResult>? results,
  }) : results = _recordingProgramResults(result: result, results: results) {
    if (this.results.isEmpty) {
      throw ArgumentError('At least one program run result is required.');
    }
  }

  final List<ProgramRunResult> results;
  final List<ProgramRunRequest> requests = <ProgramRunRequest>[];
  ProgramRunRequest? lastRequest;
  var _nextResultIndex = 0;

  @override
  ProgramRunResult run(ProgramRunRequest request) {
    requests.add(request);
    lastRequest = request;

    final resultIndex = min(_nextResultIndex, results.length - 1);
    _nextResultIndex += 1;

    return results[resultIndex];
  }
}

final class FixedProgramMetadataExtractor implements ProgramMetadataExtractor {
  const FixedProgramMetadataExtractor({
    required this.programPath,
    required this.metadata,
  });

  final String programPath;
  final ProgramMetadataRecord metadata;

  @override
  ProgramMetadataRecord? extract({
    required BottleRecord bottle,
    required String programPath,
  }) {
    return programPath == this.programPath ? metadata : null;
  }
}

List<ProgramRunResult> _recordingProgramResults({
  required ProgramRunResult? result,
  required List<ProgramRunResult>? results,
}) {
  final providedResults = results;
  if (providedResults != null) {
    return List.unmodifiable(providedResults);
  }

  final providedResult = result;
  if (providedResult != null) {
    return List.unmodifiable(<ProgramRunResult>[providedResult]);
  }

  return const <ProgramRunResult>[];
}

final class RecordingBottlePrefixInitializer
    implements BottlePrefixInitializer {
  RecordingBottlePrefixInitializer({required this.result});

  final BottlePrefixInitializationResult result;
  BottleRecord? lastBottle;

  @override
  BottlePrefixInitializationResult initialize(BottleRecord bottle) {
    lastBottle = bottle;

    return result;
  }
}

final class RecordingPathOpener implements PathOpener {
  RecordingPathOpener({required this.result});

  final PathOpenResult result;
  String? lastPath;
  String? lastRevealedPath;

  @override
  PathOpenResult openPath(String path) {
    lastPath = path;

    return result;
  }

  @override
  PathOpenResult revealPath(String path) {
    lastRevealedPath = path;

    return result;
  }
}

final class RecordingWinetricksVerbLister implements WinetricksVerbLister {
  RecordingWinetricksVerbLister({required this.result});

  final WinetricksVerbListResult result;
  String? executable;

  @override
  WinetricksVerbListResult listVerbs({required String executable}) {
    this.executable = executable;

    return result;
  }
}

final class RecordingWinetricksScriptInstaller
    implements WinetricksScriptInstaller {
  RecordingWinetricksScriptInstaller({required this.result});

  final WinetricksScriptInstallResult result;
  String? executable;

  @override
  WinetricksScriptInstallResult installIfMissing({required String executable}) {
    this.executable = executable;

    return result;
  }
}

final class RecordingMacosWineInstaller implements MacosWineInstaller {
  RecordingMacosWineInstaller({required this.result});

  final MacosWineInstallResult result;
  MacosWineInstallRequest? lastRequest;

  @override
  MacosWineInstallResult install(MacosWineInstallRequest request) {
    lastRequest = request;

    return result;
  }
}

final class RecordingLinuxWineInstaller implements LinuxWineInstaller {
  RecordingLinuxWineInstaller({required this.result});

  final LinuxWineInstallResult result;
  LinuxWineInstallRequest? lastRequest;

  @override
  LinuxWineInstallResult install(LinuxWineInstallRequest request) {
    lastRequest = request;

    return result;
  }
}

final class RecordingRuntimeUpdateChecker implements RuntimeUpdateChecker {
  RecordingRuntimeUpdateChecker({required this.result});

  final RuntimeUpdateCheckResult result;
  String? lastRuntimeId;

  @override
  RuntimeUpdateCheckResult check(String runtimeId) {
    lastRuntimeId = runtimeId;

    return result;
  }
}

final class RecordingAppUpdateChecker implements AppUpdateChecker {
  RecordingAppUpdateChecker({required this.result});

  final AppUpdateCheckResult result;
  var checkCount = 0;

  @override
  AppUpdateCheckResult check() {
    checkCount += 1;

    return result;
  }
}

final class RecordingAppUpdateInstaller implements AppUpdateInstaller {
  RecordingAppUpdateInstaller({required this.result});

  final AppUpdateInstallResult result;
  AppUpdateRecord? lastUpdate;

  @override
  AppUpdateInstallResult install(AppUpdateRecord update) {
    lastUpdate = update;

    return result;
  }
}

final class RecordingDetachedProcessStarter implements DetachedProcessStarter {
  RecordingDetachedProcessStarter({required this.result});

  final DetachedProcessStartResult result;
  String? lastExecutable;
  List<String> lastArguments = const <String>[];

  @override
  DetachedProcessStartResult start({
    required String executable,
    required List<String> arguments,
  }) {
    lastExecutable = executable;
    lastArguments = List.unmodifiable(arguments);

    return result;
  }
}

final class RecordingRuntimeValidator implements RuntimeValidator {
  RecordingRuntimeValidator({required this.result});

  final RuntimeValidationResult result;
  String? lastRuntimeId;

  @override
  RuntimeValidationResult validate(String runtimeId) {
    lastRuntimeId = runtimeId;

    return result;
  }
}

final class RecordingMacosSetupChecker implements MacosSetupChecker {
  RecordingMacosSetupChecker({required this.result});

  final MacosSetupCheckResult result;

  @override
  MacosSetupCheckResult check() {
    return result;
  }
}

final class RecordingRuntimeExecutableProbe implements RuntimeExecutableProbe {
  RecordingRuntimeExecutableProbe({required this.result});

  final RuntimeExecutableProbeResult result;
  String? lastExecutable;
  List<String> lastArguments = const <String>[];
  Map<String, String> lastEnvironment = const <String, String>{};
  String? lastWorkingDirectory;

  @override
  RuntimeExecutableProbeResult run({
    required String executable,
    required List<String> arguments,
    required Map<String, String> environment,
    required String workingDirectory,
  }) {
    lastExecutable = executable;
    lastArguments = List.unmodifiable(arguments);
    lastEnvironment = Map.unmodifiable(environment);
    lastWorkingDirectory = workingDirectory;

    return result;
  }
}

final class StaticFileStatusProbe implements FileStatusProbe {
  const StaticFileStatusProbe(this._existingPaths);

  final Set<String> _existingPaths;

  @override
  bool exists(String path) {
    return _existingPaths.contains(path);
  }
}

String _createComponentRuntimeArchive(String tempPath) {
  final sourceRoot = Directory(_joinTestPath(tempPath, const ['source']));
  final librariesRoot = Directory(
    _joinTestPath(sourceRoot.path, const ['Libraries']),
  );
  final wineRoot = Directory(_joinTestPath(librariesRoot.path, const ['Wine']));

  for (final relativePath in const <List<String>>[
    <String>['Wine', 'bin', 'wine64'],
    <String>['Wine', 'bin', 'wineserver'],
    <String>['Wine', 'bin', 'wine'],
    <String>['DXVK', 'x64', 'dxgi.dll'],
    <String>['DXVK', 'x32', 'dxgi.dll'],
    <String>['Wine', 'lib', 'libMoltenVK.dylib'],
    <String>['Wine', 'lib', 'libgstreamer-1.0.0.dylib'],
    <String>['Wine', 'share', 'wine', 'mono', 'wine-mono.marker'],
    <String>['winetricks'],
  ]) {
    final file = File(_joinTestPath(librariesRoot.path, relativePath));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('fixture');
  }
  File(
    _joinTestPath(librariesRoot.path, const ['.konyak-runtime-stack.json']),
  ).writeAsStringSync(
    jsonEncode({
      'schemaVersion': 1,
      'components': {
        'wine': 'wine-devel-11.9',
        'dxvk-macos': 'dxvk-macos-fixture',
      },
    }),
  );

  expect(wineRoot.existsSync(), isTrue);

  final archivePath = _joinTestPath(tempPath, const ['runtime.tar.gz']);
  final result = Process.runSync('tar', [
    '-czf',
    archivePath,
    '-C',
    sourceRoot.path,
    'Libraries',
  ]);
  expect(result.exitCode, 0, reason: result.stderr.toString());

  return archivePath;
}

String _createKonyakComponentRuntimeArchive(String tempPath) {
  final sourceRoot = Directory(
    _joinTestPath(tempPath, const ['component-source']),
  );
  final runtimeRoot = Directory(
    _joinTestPath(sourceRoot.path, const ['Runtime']),
  );

  for (final relativePath in const <List<String>>[
    <String>['Wine Devel.app', 'Contents', 'Resources', 'wine', 'bin', 'wine'],
    <String>[
      'Wine Devel.app',
      'Contents',
      'Resources',
      'wine',
      'bin',
      'wineserver',
    ],
    <String>[
      'Wine Devel.app',
      'Contents',
      'Resources',
      'wine',
      'lib',
      'libwine.1.dylib',
    ],
    <String>['Components', 'DXVK-macOS', 'DXVK', 'x64', 'dxgi.dll'],
    <String>['Components', 'DXVK-macOS', 'DXVK', 'x32', 'dxgi.dll'],
    <String>['Components', 'MoltenVK', 'lib', 'libMoltenVK.dylib'],
    <String>['Components', 'GStreamer', 'lib', 'libgstreamer-1.0.0.dylib'],
    <String>['Components', 'wine-mono', 'share', 'wine', 'mono', 'marker'],
    <String>['Components', 'winetricks', 'winetricks'],
  ]) {
    final file = File(_joinTestPath(runtimeRoot.path, relativePath));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('fixture');
  }
  File(
    _joinTestPath(runtimeRoot.path, const ['.konyak-runtime-stack.json']),
  ).writeAsStringSync(
    jsonEncode({
      'schemaVersion': 1,
      'components': {
        'wine': 'wine-devel-11.9',
        'dxvk-macos': 'dxvk-macos-fixture',
        'moltenvk': 'moltenvk-fixture',
        'gstreamer': 'gstreamer-fixture',
        'wine-mono': 'wine-mono-fixture',
        'winetricks': 'winetricks-fixture',
      },
    }),
  );

  final archivePath = _joinTestPath(tempPath, const [
    'component-runtime.tar.xz',
  ]);
  final result = Process.runSync('tar', [
    '-cJf',
    archivePath,
    '-C',
    sourceRoot.path,
    'Runtime',
  ]);
  expect(result.exitCode, 0, reason: result.stderr.toString());

  return archivePath;
}

String _createKonyakRuntimeComponentArchive(
  String tempPath, {
  required String archiveName,
  required List<List<String>> relativePaths,
  required Map<String, String> versions,
}) {
  final sourceRoot = Directory(
    _joinTestPath(tempPath, ['component-source-$archiveName']),
  );
  final runtimeRoot = Directory(
    _joinTestPath(sourceRoot.path, const ['Runtime']),
  );

  for (final relativePath in relativePaths) {
    final file = File(_joinTestPath(runtimeRoot.path, relativePath));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('fixture');
  }
  File(
    _joinTestPath(runtimeRoot.path, const ['.konyak-runtime-stack.json']),
  ).writeAsStringSync(jsonEncode({'schemaVersion': 1, 'components': versions}));

  final archivePath = _joinTestPath(tempPath, ['$archiveName.tar.xz']);
  final result = Process.runSync('tar', [
    '-cJf',
    archivePath,
    '-C',
    sourceRoot.path,
    'Runtime',
  ]);
  expect(result.exitCode, 0, reason: result.stderr.toString());

  return archivePath;
}

String _createRuntimeStackSourceManifest(
  String tempPath, {
  String runtimeId = 'konyak-macos-wine',
  String stackId = 'macos-konyak-runtime-stack',
  required List<Map<String, String>> components,
}) {
  final manifestPath = _joinTestPath(tempPath, const [
    'runtime-stack-source.json',
  ]);
  File(manifestPath).writeAsStringSync(
    jsonEncode(<String, Object?>{
      'schemaVersion': 1,
      'runtimeId': runtimeId,
      'stackId': stackId,
      'components': components,
    }),
  );

  return manifestPath;
}

final class _RuntimeStackManifestSignature {
  const _RuntimeStackManifestSignature({
    required this.publicKeyPath,
    required this.signaturePath,
  });

  final String publicKeyPath;
  final String signaturePath;
}

_RuntimeStackManifestSignature _createRuntimeStackManifestSignature(
  String tempPath, {
  required String manifestPath,
}) {
  final privateKeyPath = _joinTestPath(tempPath, const [
    'runtime-stack-key.pem',
  ]);
  final publicKeyPath = _joinTestPath(tempPath, const [
    'runtime-stack-key.pub.pem',
  ]);
  final signaturePath = '$manifestPath.sig';

  final privateKeyResult = Process.runSync('openssl', [
    'genpkey',
    '-algorithm',
    'RSA',
    '-pkeyopt',
    'rsa_keygen_bits:2048',
    '-out',
    privateKeyPath,
  ]);
  expect(
    privateKeyResult.exitCode,
    0,
    reason: privateKeyResult.stderr.toString(),
  );

  final publicKeyResult = Process.runSync('openssl', [
    'pkey',
    '-in',
    privateKeyPath,
    '-pubout',
    '-out',
    publicKeyPath,
  ]);
  expect(
    publicKeyResult.exitCode,
    0,
    reason: publicKeyResult.stderr.toString(),
  );

  final signatureResult = Process.runSync('openssl', [
    'dgst',
    '-sha256',
    '-sign',
    privateKeyPath,
    '-out',
    signaturePath,
    manifestPath,
  ]);
  expect(
    signatureResult.exitCode,
    0,
    reason: signatureResult.stderr.toString(),
  );

  return _RuntimeStackManifestSignature(
    publicKeyPath: publicKeyPath,
    signaturePath: signaturePath,
  );
}

Map<String, String> _runtimeStackSourceComponent({
  required String id,
  required String version,
  required String archivePath,
}) {
  return <String, String>{
    'id': id,
    'version': version,
    'archiveUrl': archivePath,
    'sha256': _fileSha256(archivePath),
  };
}

String _fileSha256(String path) {
  return sha256.convert(File(path).readAsBytesSync()).toString();
}

String _createMacosAppBundleWineArchive(String tempPath) {
  final sourceRoot = Directory(_joinTestPath(tempPath, const ['source']));
  final wineRoot = Directory(
    _joinTestPath(sourceRoot.path, const [
      'Wine Devel.app',
      'Contents',
      'Resources',
      'wine',
    ]),
  );

  for (final relativePath in const <List<String>>[
    <String>['bin', 'wineserver'],
    <String>['bin', 'wine'],
    <String>['lib', 'libwine.1.dylib'],
    <String>['share', 'wine', 'mono', 'wine-mono.marker'],
  ]) {
    final file = File(_joinTestPath(wineRoot.path, relativePath));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('fixture');
  }

  final archivePath = _joinTestPath(tempPath, const [
    'app-bundle-runtime.tar.xz',
  ]);
  final result = Process.runSync('tar', [
    '-cJf',
    archivePath,
    '-C',
    sourceRoot.path,
    'Wine Devel.app',
  ]);
  expect(result.exitCode, 0, reason: result.stderr.toString());

  return archivePath;
}

String _createBrokenRuntimeArchive(String tempPath) {
  final sourceRoot = Directory(_joinTestPath(tempPath, const ['broken']));
  final file = File(_joinTestPath(sourceRoot.path, const ['README.txt']));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync('not a runtime');

  final archivePath = _joinTestPath(tempPath, const ['broken-runtime.tar.gz']);
  final result = Process.runSync('tar', [
    '-czf',
    archivePath,
    '-C',
    sourceRoot.path,
    'README.txt',
  ]);
  expect(result.exitCode, 0, reason: result.stderr.toString());

  return archivePath;
}

String _createInvalidRuntimeArchive(String tempPath) {
  final archivePath = _joinTestPath(tempPath, const ['invalid-runtime.tar.xz']);
  File(archivePath).writeAsStringSync('not a tar archive');

  return archivePath;
}

String _createLinuxWineRuntimeArchive(String tempPath) {
  final sourceRoot = Directory(_joinTestPath(tempPath, const ['linux-source']));
  final runtimeRoot = Directory(
    _joinTestPath(sourceRoot.path, const ['Runtime']),
  );

  for (final relativePath in const <List<String>>[
    <String>['bin', 'wine'],
    <String>['bin', 'wineboot'],
    <String>['bin', 'winedbg'],
    <String>['bin', 'wineserver'],
    <String>['winetricks'],
  ]) {
    final file = File(_joinTestPath(runtimeRoot.path, relativePath));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('fixture');
  }

  final archivePath = _joinTestPath(tempPath, const ['linux-runtime.tar.xz']);
  final result = Process.runSync('tar', [
    '-cJf',
    archivePath,
    '-C',
    sourceRoot.path,
    'Runtime',
  ]);
  expect(result.exitCode, 0, reason: result.stderr.toString());

  return archivePath;
}

Directory _createTestMacosAppBundle(String tempPath) {
  final appBundle = Directory(_joinTestPath(tempPath, const ['Konyak.app']));
  File(_joinTestPath(appBundle.path, const ['Contents', 'MacOS', 'Konyak']))
    ..createSync(recursive: true)
    ..writeAsStringSync('app executable');
  File(
      _joinTestPath(appBundle.path, const [
        'Contents',
        'Resources',
        'konyak-cli',
      ]),
    )
    ..createSync(recursive: true)
    ..writeAsStringSync('cli executable');

  return appBundle;
}

List<Directory> _generatedMacosLaunchers(String home) {
  final launcherDirectory = Directory(
    _joinTestPath(home, const ['Applications', 'Konyak']),
  );
  if (!launcherDirectory.existsSync()) {
    return const <Directory>[];
  }

  final launchers = launcherDirectory
      .listSync(followLinks: false)
      .whereType<Directory>()
      .where((directory) => directory.path.endsWith('.app'))
      .toList(growable: false);
  launchers.sort((left, right) => left.path.compareTo(right.path));

  return launchers;
}

Directory _singleGeneratedMacosLauncher(String home) {
  final launchers = _generatedMacosLaunchers(home);
  expect(launchers, hasLength(1));

  return launchers.single;
}

String _joinTestPath(String root, List<String> segments) {
  return <String>[root, ...segments].join('/');
}

Uint8List _syntheticPortableExecutableBytes() {
  final iconImage = Uint8List.fromList(const <int>[1, 2, 3, 4]);
  final groupIcon = _syntheticGroupIconBytes(
    iconId: 1,
    iconByteLength: iconImage.length,
  );
  final versionInfo = _utf16LeBytes(
    [
      'VS_VERSION_INFO',
      'StringFileInfo',
      'FileDescription',
      'Fixture App',
      'ProductName',
      'Fixture Suite',
      'CompanyName',
      'Example Co',
      'FileVersion',
      '1.2.3',
      'ProductVersion',
      '4.5.6',
    ].join('\u0000'),
  );

  const peOffset = 0x80;
  const sectionHeaderOffset = peOffset + 4 + 20 + 0xf0;
  const resourceRva = 0x1000;
  const resourceRawOffset = 0x200;
  const iconDataOffset = 0x100;
  final groupDataOffset = iconDataOffset + iconImage.length;
  final versionDataOffset = groupDataOffset + groupIcon.length;
  final resourceSize = versionDataOffset + versionInfo.length;
  final bytes = Uint8List(resourceRawOffset + resourceSize + 0x100);

  bytes[0] = 0x4d;
  bytes[1] = 0x5a;
  _writeU32(bytes, 0x3c, peOffset);
  bytes[peOffset] = 0x50;
  bytes[peOffset + 1] = 0x45;
  _writeU16(bytes, peOffset + 4, 0x8664);
  _writeU16(bytes, peOffset + 6, 1);
  _writeU16(bytes, peOffset + 20, 0xf0);
  _writeU16(bytes, peOffset + 24, 0x020b);
  _writeU32(bytes, peOffset + 24 + 128, resourceRva);
  _writeU32(bytes, peOffset + 24 + 132, resourceSize);

  _writeAscii(bytes, sectionHeaderOffset, '.rsrc');
  _writeU32(bytes, sectionHeaderOffset + 8, resourceSize);
  _writeU32(bytes, sectionHeaderOffset + 12, resourceRva);
  _writeU32(bytes, sectionHeaderOffset + 16, resourceSize);
  _writeU32(bytes, sectionHeaderOffset + 20, resourceRawOffset);

  _writeResourceDirectory(bytes, resourceRawOffset, [
    _ResourceDirectoryEntry(id: 3, directoryOffset: 0x028),
    _ResourceDirectoryEntry(id: 14, directoryOffset: 0x040),
    _ResourceDirectoryEntry(id: 16, directoryOffset: 0x058),
  ]);
  _writeResourceDirectory(bytes, resourceRawOffset + 0x028, [
    _ResourceDirectoryEntry(id: 1, directoryOffset: 0x070),
  ]);
  _writeResourceDirectory(bytes, resourceRawOffset + 0x040, [
    _ResourceDirectoryEntry(id: 1, directoryOffset: 0x088),
  ]);
  _writeResourceDirectory(bytes, resourceRawOffset + 0x058, [
    _ResourceDirectoryEntry(id: 1, directoryOffset: 0x0a0),
  ]);
  _writeResourceDirectory(bytes, resourceRawOffset + 0x070, [
    _ResourceDirectoryEntry(id: 1033, dataEntryOffset: 0x0b8),
  ]);
  _writeResourceDirectory(bytes, resourceRawOffset + 0x088, [
    _ResourceDirectoryEntry(id: 1033, dataEntryOffset: 0x0c8),
  ]);
  _writeResourceDirectory(bytes, resourceRawOffset + 0x0a0, [
    _ResourceDirectoryEntry(id: 1033, dataEntryOffset: 0x0d8),
  ]);

  _writeResourceDataEntry(
    bytes,
    resourceRawOffset + 0x0b8,
    resourceRva + iconDataOffset,
    iconImage.length,
  );
  _writeResourceDataEntry(
    bytes,
    resourceRawOffset + 0x0c8,
    resourceRva + groupDataOffset,
    groupIcon.length,
  );
  _writeResourceDataEntry(
    bytes,
    resourceRawOffset + 0x0d8,
    resourceRva + versionDataOffset,
    versionInfo.length,
  );

  bytes.setRange(
    resourceRawOffset + iconDataOffset,
    resourceRawOffset + iconDataOffset + iconImage.length,
    iconImage,
  );
  bytes.setRange(
    resourceRawOffset + groupDataOffset,
    resourceRawOffset + groupDataOffset + groupIcon.length,
    groupIcon,
  );
  bytes.setRange(
    resourceRawOffset + versionDataOffset,
    resourceRawOffset + versionDataOffset + versionInfo.length,
    versionInfo,
  );

  return bytes;
}

Uint8List _syntheticShellLinkBytes({required String localBasePath}) {
  final localBasePathBytes = ascii.encode(localBasePath);
  const shellLinkHeaderSize = 0x4c;
  const linkInfoOffset = shellLinkHeaderSize;
  const linkInfoHeaderSize = 0x24;
  final linkInfoSize = linkInfoHeaderSize + localBasePathBytes.length + 1;
  final bytes = Uint8List(shellLinkHeaderSize + linkInfoSize);

  _writeU32(bytes, 0, shellLinkHeaderSize);
  _writeU32(bytes, 0x14, 0x00000002);
  _writeU32(bytes, linkInfoOffset, linkInfoSize);
  _writeU32(bytes, linkInfoOffset + 4, linkInfoHeaderSize);
  _writeU32(bytes, linkInfoOffset + 8, 0x00000001);
  _writeU32(bytes, linkInfoOffset + 16, linkInfoHeaderSize);
  bytes.setRange(
    linkInfoOffset + linkInfoHeaderSize,
    linkInfoOffset + linkInfoHeaderSize + localBasePathBytes.length,
    localBasePathBytes,
  );

  return bytes;
}

Uint8List _syntheticGroupIconBytes({
  required int iconId,
  required int iconByteLength,
}) {
  final bytes = Uint8List(20);
  _writeU16(bytes, 2, 1);
  _writeU16(bytes, 4, 1);
  bytes[6] = 1;
  bytes[7] = 1;
  _writeU16(bytes, 10, 1);
  _writeU16(bytes, 12, 32);
  _writeU32(bytes, 14, iconByteLength);
  _writeU16(bytes, 18, iconId);

  return bytes;
}

Uint8List _utf16LeBytes(String value) {
  final bytes = Uint8List((value.length + 1) * 2);
  for (var index = 0; index < value.length; index += 1) {
    _writeU16(bytes, index * 2, value.codeUnitAt(index));
  }

  return bytes;
}

void _writeResourceDirectory(
  Uint8List bytes,
  int offset,
  List<_ResourceDirectoryEntry> entries,
) {
  _writeU16(bytes, offset + 14, entries.length);
  for (var index = 0; index < entries.length; index += 1) {
    final entry = entries[index];
    final entryOffset = offset + 16 + index * 8;
    _writeU32(bytes, entryOffset, entry.id);
    final directoryOffset = entry.directoryOffset;
    if (directoryOffset != null) {
      _writeU32(bytes, entryOffset + 4, 0x80000000 | directoryOffset);
    } else {
      _writeU32(bytes, entryOffset + 4, entry.dataEntryOffset!);
    }
  }
}

void _writeResourceDataEntry(
  Uint8List bytes,
  int offset,
  int dataRva,
  int size,
) {
  _writeU32(bytes, offset, dataRva);
  _writeU32(bytes, offset + 4, size);
}

void _writeAscii(Uint8List bytes, int offset, String value) {
  final codes = ascii.encode(value);
  bytes.setRange(offset, offset + codes.length, codes);
}

void _writeTestBottleMetadata(BottleRecord bottle) {
  File(_joinTestPath(bottle.path, const ['metadata.json']))
    ..createSync(recursive: true)
    ..writeAsStringSync(
      jsonEncode(<String, Object?>{
        'schemaVersion': cliSchemaVersion,
        'bottle': bottle.toJson(),
      }),
    );
}

void _writeU16(Uint8List bytes, int offset, int value) {
  bytes[offset] = value & 0xff;
  bytes[offset + 1] = value >> 8 & 0xff;
}

void _writeU32(Uint8List bytes, int offset, int value) {
  bytes[offset] = value & 0xff;
  bytes[offset + 1] = value >> 8 & 0xff;
  bytes[offset + 2] = value >> 16 & 0xff;
  bytes[offset + 3] = value >> 24 & 0xff;
}

final class _ResourceDirectoryEntry {
  const _ResourceDirectoryEntry({
    required this.id,
    this.directoryOffset,
    this.dataEntryOffset,
  }) : assert(
         (directoryOffset == null) != (dataEntryOffset == null),
         'Exactly one resource target must be provided.',
       );

  final int id;
  final int? directoryOffset;
  final int? dataEntryOffset;
}
