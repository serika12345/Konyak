import 'support/cli_contract_full_helpers.dart';

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
          defaultBottlePath: DefaultBottlePath('/Volumes/Games/Bottles'),
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
        configHome: joinTestPath(tempDirectory.path, const ['config']),
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
      AppSettingsRecord(
        defaultBottlePath: DefaultBottlePath('/Users/user/Bottles'),
      ),
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
      expectIo(repository.read()),
      AppSettingsRecord(
        terminateWineProcessesOnClose: false,
        defaultBottlePath: DefaultBottlePath('/Volumes/Games/Bottles'),
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
      AppSettingsRecord(
        defaultBottlePath: DefaultBottlePath('/Users/user/Bottles'),
      ),
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
      expectIo(repository.read()),
      AppSettingsRecord(
        terminateWineProcessesOnClose: true,
        defaultBottlePath: DefaultBottlePath('/Volumes/Games/Bottles'),
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
    final bottleDirectory = joinTestPath(tempDirectory.path, const [
      'Konyak Bottles',
    ]);
    final repository = defaultBottleRepositoryFromEnvironment(
      {'HOME': tempDirectory.path},
      hostPlatform: KonyakHostPlatform.linux,
      appSettings: AppSettingsRecord(
        defaultBottlePath: DefaultBottlePath(bottleDirectory),
      ),
    );

    final result = repository.createBottle(
      BottleCreateRequest(
        name: BottleName('Steam'),
        windowsVersion: WindowsVersion('win10'),
      ),
    );

    expect(result, isA<BottleCreated>());
    final created = result as BottleCreated;
    expect(
      created.bottle.path.value,
      joinTestPath(bottleDirectory, const ['steam']),
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
    final dataHome = joinTestPath(tempDirectory.path, const ['data']);
    final existingBottlePath = joinTestPath(dataHome, const [
      'bottles',
      'existing',
    ]);
    Directory(existingBottlePath).createSync(recursive: true);
    writeTestBottleMetadata(
      BottleRecord(
        id: 'existing',
        name: 'Existing',
        path: existingBottlePath,
        windowsVersion: 'win10',
      ),
    );
    final bottleDirectory = joinTestPath(tempDirectory.path, const [
      'Konyak Bottles',
    ]);
    final repository = defaultBottleRepositoryFromEnvironment(
      {'KONYAK_DATA_HOME': dataHome, 'HOME': tempDirectory.path},
      hostPlatform: KonyakHostPlatform.linux,
      appSettings: AppSettingsRecord(
        defaultBottlePath: DefaultBottlePath(bottleDirectory),
      ),
    );

    final result = repository.createBottle(
      BottleCreateRequest(
        name: BottleName('Steam'),
        windowsVersion: WindowsVersion('win10'),
      ),
    );

    expect(result, isA<BottleCreated>());
    expect(
      expectIo(repository.listBottles()).map((bottle) => bottle.id.value),
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
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: joinTestPath(tempDirectory.path, const ['data']),
    );
    final createResult = repository.createBottle(
      BottleCreateRequest(
        name: BottleName('Steam'),
        windowsVersion: WindowsVersion('win10'),
      ),
    );
    final bottle = (createResult as BottleCreated).bottle;
    File(joinTestPath(bottle.path.value, const ['drive_c', 'steam.txt']))
      ..createSync(recursive: true)
      ..writeAsStringSync('installed');
    final archivePath = joinTestPath(tempDirectory.path, const [
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
    final sourceBottlePath = joinTestPath(tempDirectory.path, const [
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
      joinTestPath(sourceBottlePath, const ['drive_c']),
    ).createSync(recursive: true);
    File(
      joinTestPath(sourceBottlePath, const ['drive_c', 'steam.txt']),
    ).writeAsStringSync('installed');
    writeTestBottleMetadata(sourceBottle);
    final archivePath = joinTestPath(tempDirectory.path, const [
      'steam.konyak-bottle.tar',
    ]);
    final archiveResult = Process.runSync('tar', [
      '-cf',
      archivePath,
      '-C',
      joinTestPath(tempDirectory.path, const ['archive-source']),
      'steam',
    ]);
    expect(archiveResult.exitCode, 0);
    final repository = FileBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: joinTestPath(tempDirectory.path, const ['data']),
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
    final importedPath = joinTestPath(tempDirectory.path, const [
      'data',
      'bottles',
      'steam',
    ]);
    expect(imported['id'], 'steam');
    expect(imported['name'], 'Steam');
    expect(imported['path'], importedPath);
    expect(
      File(
        joinTestPath(importedPath, const ['drive_c', 'steam.txt']),
      ).readAsStringSync(),
      'installed',
    );
    expect(
      expectFound(repository.findBottle(BottleId('steam'))).path.value,
      importedPath,
    );
  });

  test('import-bottle-archive --json reports repository lookup failures', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-bottle-import-failure-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final sourceBottlePath = joinTestPath(tempDirectory.path, const [
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
      joinTestPath(sourceBottlePath, const ['drive_c']),
    ).createSync(recursive: true);
    writeTestBottleMetadata(sourceBottle);
    final archivePath = joinTestPath(tempDirectory.path, const [
      'steam.konyak-bottle.tar',
    ]);
    final archiveResult = Process.runSync('tar', [
      '-cf',
      archivePath,
      '-C',
      joinTestPath(tempDirectory.path, const ['archive-source']),
      'steam',
    ]);
    expect(archiveResult.exitCode, 0);
    final dataHome = joinTestPath(tempDirectory.path, const ['data']);
    File(joinTestPath(dataHome, const ['bottles', 'steam', 'metadata.json']))
      ..createSync(recursive: true)
      ..writeAsStringSync('[]');
    final repository = FileBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: dataHome,
    );

    final result = runCli([
      'import-bottle-archive',
      '--archive',
      archivePath,
      '--json',
    ], bottleRepository: repository);

    expect(result.exitCode, 65);
    expect(result.stderr, isEmpty);
    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'error': {
        'code': 'invalidBottleArchive',
        'message': 'Bottle metadata must be an object.',
      },
    });
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
    expect(runner.requests.map((request) => request.arguments.value), [
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
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
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
    expect(runner.requests.map((request) => request.arguments.value), [
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
      expectFound(
        repository.findBottle(BottleId('steam')),
      ).windowsVersion.value,
      'win11',
    );
  });

  test('create-bottle --json creates a bottle in the repository', () {
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
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
    final repository = FileBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: tempDirectory.path,
    );
    final orphanedBottlePath = joinTestPath(tempDirectory.path, const [
      'bottles',
      'steam',
    ]);
    final leftoverFile = File(
      joinTestPath(orphanedBottlePath, const ['drive_c', 'leftover.txt']),
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
        joinTestPath(orphanedBottlePath, const ['metadata.json']),
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
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
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

    expect(
      expectFound(repository.findBottle(BottleId('日本語'))).name.value,
      '日本語',
    );
  });

  test('create-bottle --json initializes the Wine prefix when configured', () {
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
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
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
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
        programMetadataExtractor: const NoopProgramMetadataExtractor(),
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
      expectFound(repository.findBottle(BottleId('steam'))).runtimeSettings,
      BottleRuntimeSettings(
        enhancedSync: EnhancedSyncMode('esync'),
        metalHud: true,
        metalTrace: true,
        avxEnabled: true,
        dxrEnabled: true,
        dlssMetalFx: true,
        dxvkAsync: false,
        dxvkHud: DxvkHudMode('fps'),
        vkd3dProton: true,
        buildVersion: WindowsBuildVersion(19045),
        retinaMode: true,
        dpiScaling: WindowsDpiScaling(144),
      ),
    );
  });

  test('set-runtime-settings --json defaults legacy DLSS MetalFX to false', () {
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
      expectFound(
        repository.findBottle(BottleId('steam')),
      ).runtimeSettings.dlssMetalFx,
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
          joinTestPath(bottlePath, ['drive_c', 'windows', 'system32', dllName]),
        ).readAsStringSync(),
        'x86_64-windows/$dllName',
      );
      expect(
        File(
          joinTestPath(bottlePath, ['drive_c', 'windows', 'syswow64', dllName]),
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
          joinTestPath(bottlePath, [
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
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: joinTestPath(tempDirectory.path, const ['data']),
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
    for (final dllName in gptkD3DMetalOverrideDllNames) {
      expect(
        File(
          joinTestPath(bottlePath, ['drive_c', 'windows', 'system32', dllName]),
        ).readAsStringSync(),
        'd3dmetal/$dllName',
      );
      expect(
        File(
          joinTestPath(bottlePath, ['drive_c', 'windows', 'syswow64', dllName]),
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
          joinTestPath(bottlePath, ['drive_c', 'windows', 'system32', dllName]),
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
    final staleDxgi = File(
      joinTestPath(bottlePath, const [
        'drive_c',
        'windows',
        'system32',
        'dxgi.dll',
      ]),
    );
    staleDxgi.parent.createSync(recursive: true);
    staleDxgi.writeAsStringSync('stale dxgi.dll');

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
    for (final dllName in gptkD3DMetalOverrideDllNames) {
      expect(
        File(
          joinTestPath(bottlePath, ['drive_c', 'windows', 'system32', dllName]),
        ).readAsStringSync(),
        'd3dmetal/$dllName',
      );
    }
  });

  test('set-runtime-settings --json restores macOS WineD3D DLLs', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-dxvk-overrides-remove-test-',
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
          joinTestPath(bottlePath, [
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
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: joinTestPath(tempDirectory.path, const ['data']),
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: bottlePath,
          windowsVersion: 'win10',
          runtimeSettings: Option.of(BottleRuntimeSettings(dxvk: true)),
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
      for (final dllName in const [
        'nvapi64.dll',
        'nvngx.dll',
        'nvngx-on-metalfx.dll',
        'winemetal.dll',
      ]) {
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

  test(
    'set-runtime-settings --json restores available WineD3D DLLs without i386 Wine DLLs',
    () {
      final tempDirectory = Directory.systemTemp.createTempSync(
        'konyak-d3dmetal-disable-x64-runtime-test-',
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
      createMacosWineD3DBuiltinDlls(
        runtimeRoot,
        runtimeArchitectures: const <String>['x86_64-windows'],
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
          final file = File(
            joinTestPath(bottlePath, [
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
        expectFound(
          repository.findBottle(BottleId('steam')),
        ).runtimeSettings.dxrEnabled,
        isFalse,
      );
      for (final dllName in testMacosWineD3DBuiltinDllNames) {
        expect(
          File(
            joinTestPath(bottlePath, [
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
            joinTestPath(bottlePath, [
              'drive_c',
              'windows',
              'syswow64',
              dllName,
            ]),
          ).existsSync(),
          isFalse,
        );
      }
      for (final windowsDirectory in const ['system32', 'syswow64']) {
        for (final dllName in const [
          'nvapi64.dll',
          'nvngx.dll',
          'nvngx-on-metalfx.dll',
          'winemetal.dll',
        ]) {
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

      final runtimeRoot = joinTestPath(tempDirectory.path, const ['runtime']);
      final bottlePath = joinTestPath(tempDirectory.path, const [
        'bottles',
        'steam',
      ]);
      createMacosWineD3DBuiltinDlls(runtimeRoot);
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
            joinTestPath(bottlePath, [
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
        programMetadataExtractor: const NoopProgramMetadataExtractor(),
        dataHome: joinTestPath(tempDirectory.path, const ['data']),
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
        expect(
          File(
            joinTestPath(bottlePath, [
              'drive_c',
              'windows',
              windowsDirectory,
              'winemetal.dll',
            ]),
          ).existsSync(),
          isFalse,
        );
      }
    },
  );

  test(
    'set-runtime-settings --json makes DXVK and DXMT mutually exclusive',
    () {
      final repository = MemoryBottleRepository(
        programMetadataExtractor: const NoopProgramMetadataExtractor(),
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
      final updated = expectFound(repository.findBottle(BottleId('steam')));
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

      final runtimeRoot = joinTestPath(tempDirectory.path, const ['runtime']);
      final bottlePath = joinTestPath(tempDirectory.path, const [
        'bottles',
        'steam',
      ]);
      for (final dllName in gptkD3DMetalOverrideDllNames) {
        final file = File(
          joinTestPath(runtimeRoot, ['lib', 'wine', 'x86_64-windows', dllName]),
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
      final updated = expectFound(repository.findBottle(BottleId('steam')));
      expect(updated.runtimeSettings.dxrEnabled, isTrue);
      expect(updated.runtimeSettings.dxvk, isFalse);
      expect(updated.runtimeSettings.dxmt, isFalse);
    },
  );

  test('set-runtime-settings --json applies registry-backed settings', () {
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
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
    expect(runner.requests.map((request) => request.arguments.value), [
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
      expectFound(repository.findBottle(BottleId('steam'))).runtimeSettings,
      BottleRuntimeSettings(
        buildVersion: WindowsBuildVersion(22631),
        retinaMode: true,
        dpiScaling: WindowsDpiScaling(192),
      ),
    );
  });

  test(
    'set-runtime-settings --json restores DPI when disabling High Resolution Mode',
    () {
      final repository = MemoryBottleRepository(
        programMetadataExtractor: const NoopProgramMetadataExtractor(),
        dataHome: '/home/user/.local/share/konyak',
        bottles: [
          BottleRecord(
            id: 'steam',
            name: 'Steam',
            path:
                '/Users/user/Library/Application Support/Konyak/Bottles/Steam',
            windowsVersion: 'win10',
            runtimeSettings: Option.of(
              BottleRuntimeSettings(
                retinaMode: true,
                dpiScaling: WindowsDpiScaling(192),
              ),
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
      expect(runner.requests.map((request) => request.arguments.value), [
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
        expectFound(repository.findBottle(BottleId('steam'))).runtimeSettings,
        BottleRuntimeSettings(
          retinaMode: false,
          dpiScaling: WindowsDpiScaling(96),
        ),
      );
    },
  );

  test('set-runtime-settings --json maps build version to winecfg version', () {
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
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
      runner.requests.map((request) => request.arguments.value).toList(),
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
        programMetadataExtractor: const NoopProgramMetadataExtractor(),
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
        expectFound(repository.findBottle(BottleId('steam'))).runtimeSettings,
        BottleRuntimeSettings(),
      );
    },
  );

  test('create-bottle --json returns a machine-readable conflict', () {
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
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
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
        chmodPath(
          joinTestPath(tempDirectory.path, const [
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
      final repository = FileBottleRepository(
        programMetadataExtractor: const NoopProgramMetadataExtractor(),
        dataHome: tempDirectory.path,
      );
      final createResult = repository.createBottle(
        BottleCreateRequest(
          name: BottleName('Steam'),
          windowsVersion: WindowsVersion('win10'),
        ),
      );
      final bottle = (createResult as BottleCreated).bottle;
      final lockedDirectory = Directory(
        joinTestPath(bottle.path.value, const ['drive_c', 'locked']),
      )..createSync(recursive: true);
      File(
        joinTestPath(lockedDirectory.path, const ['file.txt']),
      ).writeAsStringSync('locked');
      chmodPath(lockedDirectory.path, '555');

      final result = runCli(const [
        'delete-bottle',
        'steam',
        '--json',
      ], bottleRepository: repository);

      expect(result.exitCode, 74);
      expect(result.stderr, isEmpty);
      expect(
        File(
          joinTestPath(bottle.path.value, const ['metadata.json']),
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
        programMetadataExtractor: const NoopProgramMetadataExtractor(),
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
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
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
    expectMissing(repository.findBottle(BottleId('steam')));
    expect(
      expectFound(repository.findBottle(BottleId('steam-games'))).name.value,
      'Steam Games',
    );
  });

  test('rename-bottle --json returns a machine-readable conflict', () {
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
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
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
      expectFound(repository.findBottle(BottleId('steam'))).path.value,
      '/mnt/games/Steam',
    );
  });

  test('set-windows-version --json updates a bottle in the repository', () {
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
        programMetadataExtractor: const NoopProgramMetadataExtractor(),
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
