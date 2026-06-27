part of 'cli_contract_test.dart';

void defineAppAndBottleContractTests() {
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
      bottleCatalog: StaticBottleCatalog([
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
        AppSettingsRecord(
          terminateWineProcessesOnClose: false,
          defaultBottlePath: '/Volumes/Games/Bottles',
          appearanceMode: AppAppearanceMode.light,
          languageMode: AppLanguageMode.japanese,
          automaticallyCheckForKonyakUpdates: true,
          automaticallyCheckForWineUpdates: false,
          automaticallyPinNewInstalledPrograms: false,
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
        'languageMode': 'ja',
        'automaticallyCheckForKonyakUpdates': true,
        'automaticallyCheckForWineUpdates': false,
        'automaticallyPinNewInstalledPrograms': false,
      },
    });
  });

  test('get-app-settings --json defaults Wine close termination off', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-app-settings-default-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    final result = runCli(
      const ['get-app-settings', '--json'],
      appSettingsRepository: FileAppSettingsRepository(
        configHome: _joinTestPath(tempDirectory.path, const ['config']),
        fallbackDefaultBottlePath: '/Volumes/Games/Bottles',
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
        'appearanceMode': 'dark',
        'languageMode': 'system',
        'automaticallyCheckForKonyakUpdates': false,
        'automaticallyCheckForWineUpdates': true,
        'automaticallyPinNewInstalledPrograms': true,
      },
    });
  });

  test('set-app-settings --json persists application settings', () {
    final repository = MemoryAppSettingsRepository(
      AppSettingsRecord(defaultBottlePath: '/Users/user/Bottles'),
    );

    final result = runCli(const [
      'set-app-settings',
      '--settings-json',
      '{"terminateWineProcessesOnClose":false,"defaultBottlePath":"/Volumes/Games/Bottles","appearanceMode":"light","languageMode":"ja","automaticallyCheckForKonyakUpdates":true,"automaticallyCheckForWineUpdates":false,"automaticallyPinNewInstalledPrograms":false}',
      '--json',
    ], appSettingsRepository: repository);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(
      _expectIo(repository.read()),
      AppSettingsRecord(
        terminateWineProcessesOnClose: false,
        defaultBottlePath: '/Volumes/Games/Bottles',
        appearanceMode: AppAppearanceMode.light,
        languageMode: AppLanguageMode.japanese,
        automaticallyCheckForKonyakUpdates: true,
        automaticallyCheckForWineUpdates: false,
        automaticallyPinNewInstalledPrograms: false,
      ),
    );

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload['appSettings'], {
      'terminateWineProcessesOnClose': false,
      'defaultBottlePath': '/Volumes/Games/Bottles',
      'appearanceMode': 'light',
      'languageMode': 'ja',
      'automaticallyCheckForKonyakUpdates': true,
      'automaticallyCheckForWineUpdates': false,
      'automaticallyPinNewInstalledPrograms': false,
    });
  });

  test('set-app-settings --json defaults automatic pinning for old payloads', () {
    final repository = MemoryAppSettingsRepository(
      AppSettingsRecord(defaultBottlePath: '/Users/user/Bottles'),
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
      _expectIo(repository.read()),
      AppSettingsRecord(
        terminateWineProcessesOnClose: true,
        defaultBottlePath: '/Volumes/Games/Bottles',
        appearanceMode: AppAppearanceMode.system,
        automaticallyPinNewInstalledPrograms: true,
      ),
    );

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload['appSettings'], {
      'terminateWineProcessesOnClose': true,
      'defaultBottlePath': '/Volumes/Games/Bottles',
      'appearanceMode': 'system',
      'languageMode': 'system',
      'automaticallyCheckForKonyakUpdates': false,
      'automaticallyCheckForWineUpdates': true,
      'automaticallyPinNewInstalledPrograms': true,
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
      BottleCreateRequest(name: 'Steam', windowsVersion: 'win10'),
    );

    expect(result, isA<BottleCreated>());
    final created = result as BottleCreated;
    expect(
      created.bottle.path.value,
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
      BottleCreateRequest(name: 'Steam', windowsVersion: 'win10'),
    );

    expect(result, isA<BottleCreated>());
    expect(
      _expectIo(repository.listBottles()).map((bottle) => bottle.id.value),
      const ['existing', 'steam'],
    );
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
      BottleCreateRequest(name: 'Steam', windowsVersion: 'win10'),
    );
    final bottle = (createResult as BottleCreated).bottle;
    File(_joinTestPath(bottle.path.value, const ['drive_c', 'steam.txt']))
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
    expect(
      _expectFound(repository.findBottle('steam')).path.value,
      importedPath,
    );
  });

  test('inspect-bottle --json returns a versioned bottle detail contract', () {
    final result = runCli(
      const ['inspect-bottle', 'steam', '--json'],
      bottleCatalog: StaticBottleCatalog([
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
      bottleCatalog: StaticBottleCatalog([
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: '/Users/user/Library/Application Support/Konyak/Bottles/Steam',
          windowsVersion: 'win10',
        ),
      ]),
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
        environment: HostEnvironment(const {
          'KONYAK_MACOS_WINE_ROOT': '/runtime',
        }),
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
        'dxmt': false,
        'dlssMetalFx': false,
        'dxvkAsync': true,
        'dxvkHud': 'off',
        'vkd3dProton': false,
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
        'set-windows-version',
        'steam',
        '--windows-version',
        'win11',
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
        environment: HostEnvironment(const {
          'KONYAK_MACOS_WINE_ROOT': '/runtime',
        }),
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
    expect(
      _expectFound(repository.findBottle('steam')).windowsVersion.value,
      'win11',
    );
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

  test('create-bottle --json reports repository I/O failures as JSON', () {
    final result = runCli(
      const ['create-bottle', '--name', 'Steam', '--json'],
      bottleRepository: FailingBottleRepository(
        dataHome: '/home/user/.local/share/konyak',
        message: 'disk is full',
      ),
    );

    expect(result.exitCode, 74);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'error': {'code': 'bottleRepositoryError', 'message': 'disk is full'},
    });
  });

  test('create-bottle --json reclaims a metadata-less bottle directory', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-orphaned-bottle-create-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final repository = FileBottleRepository(dataHome: tempDirectory.path);
    final orphanedBottlePath = _joinTestPath(tempDirectory.path, const [
      'bottles',
      'steam',
    ]);
    final leftoverFile = File(
      _joinTestPath(orphanedBottlePath, const ['drive_c', 'leftover.txt']),
    )..createSync(recursive: true);
    leftoverFile.writeAsStringSync('leftover');

    final listBefore = runCli(const [
      'list-bottles',
      '--json',
    ], bottleRepository: repository);
    expect(jsonDecode(listBefore.stdout), {
      'schemaVersion': 1,
      'bottles': <Object?>[],
    });

    final result = runCli(const [
      'create-bottle',
      '--name',
      'Steam',
      '--json',
    ], bottleRepository: repository);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(leftoverFile.readAsStringSync(), 'leftover');
    expect(
      File(
        _joinTestPath(orphanedBottlePath, const ['metadata.json']),
      ).existsSync(),
      isTrue,
    );

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'bottle': {
        'id': 'steam',
        'name': 'Steam',
        'path': orphanedBottlePath,
        'windowsVersion': 'win10',
      },
    });

    final listAfter = runCli(const [
      'list-bottles',
      '--json',
    ], bottleRepository: repository);
    final listPayload = jsonDecode(listAfter.stdout) as Map<String, Object?>;
    expect(listPayload['bottles'], hasLength(1));
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

    expect(_expectFound(repository.findBottle('日本語')).name.value, '日本語');
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
    expect(initializer.lastBottle?.id.value, 'steam');
    expect(
      initializer.lastBottle?.path.value,
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
      bottles: [
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
      'dxmt': false,
      'dlssMetalFx': true,
      'dxvkAsync': false,
      'dxvkHud': 'fps',
      'vkd3dProton': true,
      'buildVersion': 19045,
      'retinaMode': true,
      'dpiScaling': 144,
    });

    final result = runCli(
      [
        'set-runtime-settings',
        'steam',
        '--settings-json',
        settingsJson,
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.linux,
      ),
    );

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
        'dxvk': false,
        'dxmt': false,
        'dlssMetalFx': true,
        'dxvkAsync': false,
        'dxvkHud': 'fps',
        'vkd3dProton': true,
        'buildVersion': 19045,
        'retinaMode': true,
        'dpiScaling': 144,
      },
    });
    expect(
      _expectFound(repository.findBottle('steam')).runtimeSettings,
      BottleRuntimeSettings(
        enhancedSync: 'esync',
        metalHud: true,
        metalTrace: true,
        avxEnabled: true,
        dxrEnabled: true,
        dlssMetalFx: true,
        dxvkAsync: false,
        dxvkHud: 'fps',
        vkd3dProton: true,
        buildVersion: 19045,
        retinaMode: true,
        dpiScaling: 144,
      ),
    );
  });

  test('set-runtime-settings --json defaults legacy DLSS MetalFX to false', () {
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

    final result = runCli(
      [
        'set-runtime-settings',
        'steam',
        '--settings-json',
        jsonEncode({'metalHud': true}),
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.linux,
      ),
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    final bottle = payload['bottle'] as Map<String, Object?>;
    final runtimeSettings = bottle['runtimeSettings'] as Map<String, Object?>;
    expect(runtimeSettings, containsPair('metalHud', true));
    expect(runtimeSettings, containsPair('dlssMetalFx', false));
    expect(
      _expectFound(repository.findBottle('steam')).runtimeSettings.dlssMetalFx,
      isFalse,
    );
  });

  test('set-runtime-settings --json installs macOS DXVK DLL overrides', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-dxvk-overrides-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    final runtimeRoot = _joinTestPath(tempDirectory.path, const ['runtime']);
    final bottlePath = _joinTestPath(tempDirectory.path, const [
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
          _joinTestPath(runtimeRoot, ['lib', 'dxvk', arch, dllName]),
        );
        file.parent.createSync(recursive: true);
        file.writeAsStringSync('$arch/$dllName');
      }
    }
    final repository = MemoryBottleRepository(
      dataHome: _joinTestPath(tempDirectory.path, const ['data']),
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
      [
        'set-runtime-settings',
        'steam',
        '--settings-json',
        jsonEncode({'dxvk': true}),
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
        environment: HostEnvironment({'KONYAK_MACOS_WINE_HOME': runtimeRoot}),
      ),
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    for (final dllName in const [
      'dxgi.dll',
      'd3d9.dll',
      'd3d10.dll',
      'd3d10_1.dll',
      'd3d10core.dll',
      'd3d11.dll',
    ]) {
      expect(
        File(
          _joinTestPath(bottlePath, [
            'drive_c',
            'windows',
            'system32',
            dllName,
          ]),
        ).readAsStringSync(),
        'x86_64-windows/$dllName',
      );
      expect(
        File(
          _joinTestPath(bottlePath, [
            'drive_c',
            'windows',
            'syswow64',
            dllName,
          ]),
        ).readAsStringSync(),
        'i386-windows/$dllName',
      );
    }
  });

  test('set-runtime-settings --json installs macOS D3DMetal DLL overrides', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-d3dmetal-overrides-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    final runtimeRoot = _joinTestPath(tempDirectory.path, const ['runtime']);
    final bottlePath = _joinTestPath(tempDirectory.path, const [
      'bottles',
      'steam',
    ]);
    for (final dllName in _gptkD3DMetalOverrideDllNames) {
      final file = File(
        _joinTestPath(runtimeRoot, [
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
    for (final windowsDirectory in const ['system32', 'syswow64']) {
      for (final dllName in const [
        'dxgi.dll',
        'd3d9.dll',
        'd3d10.dll',
        'd3d10core.dll',
        'd3d11.dll',
        'd3d12.dll',
        'nvapi64.dll',
        'nvngx.dll',
        'nvngx-on-metalfx.dll',
        'winemetal.dll',
      ]) {
        final file = File(
          _joinTestPath(bottlePath, [
            'drive_c',
            'windows',
            windowsDirectory,
            dllName,
          ]),
        );
        file.parent.createSync(recursive: true);
        file.writeAsStringSync('stale $dllName');
      }
    }
    final repository = MemoryBottleRepository(
      dataHome: _joinTestPath(tempDirectory.path, const ['data']),
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
      [
        'set-runtime-settings',
        'steam',
        '--settings-json',
        jsonEncode({'dxrEnabled': true}),
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
        environment: HostEnvironment({'KONYAK_MACOS_WINE_HOME': runtimeRoot}),
      ),
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    for (final dllName in _gptkD3DMetalOverrideDllNames) {
      expect(
        File(
          _joinTestPath(bottlePath, [
            'drive_c',
            'windows',
            'system32',
            dllName,
          ]),
        ).readAsStringSync(),
        'd3dmetal/$dllName',
      );
      expect(
        File(
          _joinTestPath(bottlePath, [
            'drive_c',
            'windows',
            'syswow64',
            dllName,
          ]),
        ).existsSync(),
        isFalse,
      );
    }
    for (final dllName in const [
      'd3d9.dll',
      'd3d10.dll',
      'd3d10core.dll',
      'nvngx-on-metalfx.dll',
      'winemetal.dll',
    ]) {
      expect(
        File(
          _joinTestPath(bottlePath, [
            'drive_c',
            'windows',
            'system32',
            dllName,
          ]),
        ).existsSync(),
        isFalse,
      );
    }
  });

  test('set-runtime-settings --json repairs macOS D3DMetal DLL overrides', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-d3dmetal-overrides-repair-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    final runtimeRoot = _joinTestPath(tempDirectory.path, const ['runtime']);
    final bottlePath = _joinTestPath(tempDirectory.path, const [
      'bottles',
      'steam',
    ]);
    for (final dllName in _gptkD3DMetalOverrideDllNames) {
      final file = File(
        _joinTestPath(runtimeRoot, [
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
    final staleDxgi = File(
      _joinTestPath(bottlePath, const [
        'drive_c',
        'windows',
        'system32',
        'dxgi.dll',
      ]),
    );
    staleDxgi.parent.createSync(recursive: true);
    staleDxgi.writeAsStringSync('stale dxgi.dll');

    final repository = MemoryBottleRepository(
      dataHome: _joinTestPath(tempDirectory.path, const ['data']),
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: bottlePath,
          windowsVersion: 'win10',
          runtimeSettings: BottleRuntimeSettings(dxrEnabled: true),
        ),
      ],
    );

    final result = runCli(
      [
        'set-runtime-settings',
        'steam',
        '--settings-json',
        jsonEncode({'dxrEnabled': true}),
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
        environment: HostEnvironment({'KONYAK_MACOS_WINE_HOME': runtimeRoot}),
      ),
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    for (final dllName in _gptkD3DMetalOverrideDllNames) {
      expect(
        File(
          _joinTestPath(bottlePath, [
            'drive_c',
            'windows',
            'system32',
            dllName,
          ]),
        ).readAsStringSync(),
        'd3dmetal/$dllName',
      );
    }
  });

  test('set-runtime-settings --json removes macOS D3D DLL overrides', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-dxvk-overrides-remove-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    final runtimeRoot = _joinTestPath(tempDirectory.path, const ['runtime']);
    final bottlePath = _joinTestPath(tempDirectory.path, const [
      'bottles',
      'steam',
    ]);
    for (final windowsDirectory in const ['system32', 'syswow64']) {
      for (final dllName in const [
        'dxgi.dll',
        'd3d9.dll',
        'd3d10.dll',
        'd3d10core.dll',
        'd3d11.dll',
        'd3d12.dll',
        'nvapi64.dll',
        'nvngx.dll',
        'nvngx-on-metalfx.dll',
        'winemetal.dll',
      ]) {
        final file = File(
          _joinTestPath(bottlePath, [
            'drive_c',
            'windows',
            windowsDirectory,
            dllName,
          ]),
        );
        file.parent.createSync(recursive: true);
        file.writeAsStringSync('stale $dllName');
      }
    }
    final repository = MemoryBottleRepository(
      dataHome: _joinTestPath(tempDirectory.path, const ['data']),
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: bottlePath,
          windowsVersion: 'win10',
          runtimeSettings: BottleRuntimeSettings(dxvk: true),
        ),
      ],
    );

    final result = runCli(
      [
        'set-runtime-settings',
        'steam',
        '--settings-json',
        jsonEncode({'dxvk': false, 'dxmt': false}),
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
        environment: HostEnvironment({'KONYAK_MACOS_WINE_HOME': runtimeRoot}),
      ),
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    for (final windowsDirectory in const ['system32', 'syswow64']) {
      for (final dllName in const [
        'dxgi.dll',
        'd3d9.dll',
        'd3d10.dll',
        'd3d10core.dll',
        'd3d11.dll',
        'd3d12.dll',
        'nvapi64.dll',
        'nvngx.dll',
        'nvngx-on-metalfx.dll',
        'winemetal.dll',
      ]) {
        expect(
          File(
            _joinTestPath(bottlePath, [
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

  test(
    'set-runtime-settings --json disables macOS D3DMetal without i386 Wine DLLs',
    () {
      final tempDirectory = Directory.systemTemp.createTempSync(
        'konyak-d3dmetal-disable-x64-runtime-test-',
      );
      addTearDown(() {
        if (tempDirectory.existsSync()) {
          tempDirectory.deleteSync(recursive: true);
        }
      });

      final runtimeRoot = _joinTestPath(tempDirectory.path, const ['runtime']);
      final bottlePath = _joinTestPath(tempDirectory.path, const [
        'bottles',
        'steam',
      ]);
      for (final windowsDirectory in const ['system32', 'syswow64']) {
        for (final dllName in const [
          'dxgi.dll',
          'd3d9.dll',
          'd3d10.dll',
          'd3d10core.dll',
          'd3d11.dll',
          'd3d12.dll',
          'nvapi64.dll',
          'nvngx.dll',
          'nvngx-on-metalfx.dll',
          'winemetal.dll',
        ]) {
          final file = File(
            _joinTestPath(bottlePath, [
              'drive_c',
              'windows',
              windowsDirectory,
              dllName,
            ]),
          );
          file.parent.createSync(recursive: true);
          file.writeAsStringSync('stale $dllName');
        }
      }
      final repository = MemoryBottleRepository(
        dataHome: _joinTestPath(tempDirectory.path, const ['data']),
        bottles: [
          BottleRecord(
            id: 'steam',
            name: 'Steam',
            path: bottlePath,
            windowsVersion: 'win10',
            runtimeSettings: BottleRuntimeSettings(dxrEnabled: true),
          ),
        ],
      );

      final result = runCli(
        [
          'set-runtime-settings',
          'steam',
          '--settings-json',
          jsonEncode({'dxrEnabled': false}),
          '--json',
        ],
        bottleRepository: repository,
        programRunPlanner: ProgramRunPlanner(
          hostPlatform: KonyakHostPlatform.macos,
          environment: HostEnvironment({'KONYAK_MACOS_WINE_HOME': runtimeRoot}),
        ),
      );

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);
      expect(
        _expectFound(repository.findBottle('steam')).runtimeSettings.dxrEnabled,
        isFalse,
      );
      for (final windowsDirectory in const ['system32', 'syswow64']) {
        for (final dllName in const [
          'dxgi.dll',
          'd3d9.dll',
          'd3d10.dll',
          'd3d10core.dll',
          'd3d11.dll',
          'd3d12.dll',
          'nvapi64.dll',
          'nvngx.dll',
          'nvngx-on-metalfx.dll',
          'winemetal.dll',
        ]) {
          expect(
            File(
              _joinTestPath(bottlePath, [
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
    },
  );

  test(
    'set-runtime-settings --json repairs stale macOS D3D overrides when disabled',
    () {
      final tempDirectory = Directory.systemTemp.createTempSync(
        'konyak-d3d-overrides-disabled-repair-test-',
      );
      addTearDown(() {
        if (tempDirectory.existsSync()) {
          tempDirectory.deleteSync(recursive: true);
        }
      });

      final runtimeRoot = _joinTestPath(tempDirectory.path, const ['runtime']);
      final bottlePath = _joinTestPath(tempDirectory.path, const [
        'bottles',
        'steam',
      ]);
      for (final windowsDirectory in const ['system32', 'syswow64']) {
        for (final dllName in const [
          'dxgi.dll',
          'd3d9.dll',
          'd3d10.dll',
          'd3d10core.dll',
          'd3d11.dll',
          'd3d12.dll',
          'winemetal.dll',
        ]) {
          final file = File(
            _joinTestPath(bottlePath, [
              'drive_c',
              'windows',
              windowsDirectory,
              dllName,
            ]),
          );
          file.parent.createSync(recursive: true);
          file.writeAsStringSync('stale $dllName');
        }
      }
      final repository = MemoryBottleRepository(
        dataHome: _joinTestPath(tempDirectory.path, const ['data']),
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
        [
          'set-runtime-settings',
          'steam',
          '--settings-json',
          jsonEncode({'dxrEnabled': false}),
          '--json',
        ],
        bottleRepository: repository,
        programRunPlanner: ProgramRunPlanner(
          hostPlatform: KonyakHostPlatform.macos,
          environment: HostEnvironment({'KONYAK_MACOS_WINE_HOME': runtimeRoot}),
        ),
      );

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);
      for (final windowsDirectory in const ['system32', 'syswow64']) {
        for (final dllName in const [
          'dxgi.dll',
          'd3d9.dll',
          'd3d10.dll',
          'd3d10_1.dll',
          'd3d10core.dll',
          'd3d11.dll',
          'd3d12.dll',
          'winemetal.dll',
        ]) {
          expect(
            File(
              _joinTestPath(bottlePath, [
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
    },
  );

  test(
    'set-runtime-settings --json makes DXVK and DXMT mutually exclusive',
    () {
      final repository = MemoryBottleRepository(
        dataHome: '/home/user/.local/share/konyak',
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

      final result = runCli(
        [
          'set-runtime-settings',
          'steam',
          '--settings-json',
          jsonEncode({'dxvk': true, 'dxmt': true}),
          '--json',
        ],
        bottleRepository: repository,
        programRunPlanner: ProgramRunPlanner(
          hostPlatform: KonyakHostPlatform.macos,
          environment: HostEnvironment(const {'HOME': '/Users/user'}),
        ),
      );

      expect(result.exitCode, 0);
      final updated = _expectFound(repository.findBottle('steam'));
      expect(updated.runtimeSettings.dxvk, isFalse);
      expect(updated.runtimeSettings.dxmt, isTrue);
    },
  );

  test(
    'set-runtime-settings --json makes D3DMetal mutually exclusive with DXVK and DXMT',
    () {
      final tempDirectory = Directory.systemTemp.createTempSync(
        'konyak-d3dmetal-mutual-exclusion-test-',
      );
      addTearDown(() {
        if (tempDirectory.existsSync()) {
          tempDirectory.deleteSync(recursive: true);
        }
      });

      final runtimeRoot = _joinTestPath(tempDirectory.path, const ['runtime']);
      final bottlePath = _joinTestPath(tempDirectory.path, const [
        'bottles',
        'steam',
      ]);
      for (final dllName in _gptkD3DMetalOverrideDllNames) {
        final file = File(
          _joinTestPath(runtimeRoot, [
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
        dataHome: _joinTestPath(tempDirectory.path, const ['data']),
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
        [
          'set-runtime-settings',
          'steam',
          '--settings-json',
          jsonEncode({'dxrEnabled': true, 'dxvk': true, 'dxmt': true}),
          '--json',
        ],
        bottleRepository: repository,
        programRunPlanner: ProgramRunPlanner(
          hostPlatform: KonyakHostPlatform.macos,
          environment: HostEnvironment({'KONYAK_MACOS_WINE_HOME': runtimeRoot}),
        ),
      );

      expect(result.exitCode, 0);
      final updated = _expectFound(repository.findBottle('steam'));
      expect(updated.runtimeSettings.dxrEnabled, isTrue);
      expect(updated.runtimeSettings.dxvk, isFalse);
      expect(updated.runtimeSettings.dxmt, isFalse);
    },
  );

  test('set-runtime-settings --json applies registry-backed settings', () {
    final repository = MemoryBottleRepository(
      dataHome: '/home/user/.local/share/konyak',
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
        environment: HostEnvironment(const {
          'KONYAK_MACOS_WINE_ROOT': '/runtime',
        }),
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
        '192',
        '-f',
      ],
    ]);
    expect(
      runner.requests.map((request) => request.environment['WINEPREFIX']),
      everyElement(
        Option.of(
          '/Users/user/Library/Application Support/Konyak/Bottles/Steam',
        ),
      ),
    );
    expect(
      _expectFound(repository.findBottle('steam')).runtimeSettings,
      BottleRuntimeSettings(
        buildVersion: 22631,
        retinaMode: true,
        dpiScaling: 192,
      ),
    );
  });

  test(
    'set-runtime-settings --json restores DPI when disabling High Resolution Mode',
    () {
      final repository = MemoryBottleRepository(
        dataHome: '/home/user/.local/share/konyak',
        bottles: [
          BottleRecord(
            id: 'steam',
            name: 'Steam',
            path:
                '/Users/user/Library/Application Support/Konyak/Bottles/Steam',
            windowsVersion: 'win10',
            runtimeSettings: BottleRuntimeSettings(
              retinaMode: true,
              dpiScaling: 192,
            ),
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
          jsonEncode({'retinaMode': false, 'dpiScaling': 192}),
          '--json',
        ],
        bottleRepository: repository,
        programRunPlanner: ProgramRunPlanner(
          hostPlatform: KonyakHostPlatform.macos,
          environment: HostEnvironment(const {
            'KONYAK_MACOS_WINE_ROOT': '/runtime',
          }),
        ),
        programRunner: runner,
      );

      expect(result.exitCode, 0);
      expect(runner.requests.map((request) => request.arguments), [
        [
          'reg',
          'add',
          r'HKCU\Software\Wine\Mac Driver',
          '-v',
          'RetinaMode',
          '-t',
          'REG_SZ',
          '-d',
          'n',
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
          '96',
          '-f',
        ],
      ]);
      expect(
        _expectFound(repository.findBottle('steam')).runtimeSettings,
        BottleRuntimeSettings(retinaMode: false, dpiScaling: 96),
      );
    },
  );

  test('set-runtime-settings --json maps build version to winecfg version', () {
    final repository = MemoryBottleRepository(
      dataHome: '/home/user/.local/share/konyak',
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
        environment: HostEnvironment(const {
          'KONYAK_MACOS_WINE_ROOT': '/runtime',
        }),
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
          environment: HostEnvironment(const {
            'KONYAK_MACOS_WINE_ROOT': '/runtime',
          }),
        ),
        programRunner: runner,
      );

      expect(result.exitCode, 75);
      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      expect(payload['error'], containsPair('code', 'registryUpdateFailed'));
      expect(
        _expectFound(repository.findBottle('steam')).runtimeSettings,
        BottleRuntimeSettings(),
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

  test(
    'delete-bottle --json keeps metadata when recursive deletion fails',
    () {
      final tempDirectory = Directory.systemTemp.createTempSync(
        'konyak-bottle-delete-failure-test-',
      );
      addTearDown(() {
        _chmodPath(
          _joinTestPath(tempDirectory.path, const [
            'bottles',
            'steam',
            'drive_c',
            'locked',
          ]),
          '755',
        );
        if (tempDirectory.existsSync()) {
          tempDirectory.deleteSync(recursive: true);
        }
      });
      final repository = FileBottleRepository(dataHome: tempDirectory.path);
      final createResult = repository.createBottle(
        BottleCreateRequest(name: 'Steam', windowsVersion: 'win10'),
      );
      final bottle = (createResult as BottleCreated).bottle;
      final lockedDirectory = Directory(
        _joinTestPath(bottle.path.value, const ['drive_c', 'locked']),
      )..createSync(recursive: true);
      File(
        _joinTestPath(lockedDirectory.path, const ['file.txt']),
      ).writeAsStringSync('locked');
      _chmodPath(lockedDirectory.path, '555');

      final result = runCli(const [
        'delete-bottle',
        'steam',
        '--json',
      ], bottleRepository: repository);

      expect(result.exitCode, 74);
      expect(result.stderr, isEmpty);
      expect(
        File(
          _joinTestPath(bottle.path.value, const ['metadata.json']),
        ).existsSync(),
        isTrue,
      );

      final listResult = runCli(const [
        'list-bottles',
        '--json',
      ], bottleRepository: repository);
      final listPayload = jsonDecode(listResult.stdout) as Map<String, Object?>;
      expect(listPayload['bottles'], hasLength(1));
    },
    skip: Platform.isWindows
        ? 'POSIX directory permissions are required for this regression.'
        : false,
  );

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
    _expectMissing(repository.findBottle('steam'));
    expect(
      _expectFound(repository.findBottle('steam-games')).name.value,
      'Steam Games',
    );
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
    expect(
      _expectFound(repository.findBottle('steam')).path.value,
      '/mnt/games/Steam',
    );
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
}
