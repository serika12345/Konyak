part of 'cli_contract_test.dart';

void defineRepositoryAndRunnerContractTests() {
  test('install-linux-file-associations --json writes XDG MIME associations', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-linux-file-association-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    final xdgDataHome = _joinTestPath(tempDirectory.path, const ['xdg-data']);
    final xdgConfigHome = _joinTestPath(tempDirectory.path, const [
      'xdg-config',
    ]);
    final appExecutable = _joinTestPath(tempDirectory.path, const [
      'Konyak.AppImage',
    ]);
    File(appExecutable).writeAsStringSync('appimage');

    final result = runCli(
      const ['install-linux-file-associations', '--json'],
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.linux,
        environment: {
          'HOME': tempDirectory.path,
          'XDG_DATA_HOME': xdgDataHome,
          'XDG_CONFIG_HOME': xdgConfigHome,
          'KONYAK_APP_EXECUTABLE': appExecutable,
        },
      ),
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final desktopPath = _joinTestPath(xdgDataHome, const [
      'applications',
      'app.konyak.Konyak.desktop',
    ]);
    final desktopEntry = File(desktopPath).readAsStringSync();
    expect(desktopEntry, contains('Name=Konyak'));
    expect(desktopEntry, contains('Exec="$appExecutable" %f'));
    expect(desktopEntry, contains('MimeType=application/x-ms-dos-executable;'));
    expect(desktopEntry, contains('application/x-msdownload;'));
    expect(
      desktopEntry,
      contains('application/vnd.microsoft.portable-executable;'),
    );
    expect(desktopEntry, contains('application/x-msi;'));
    expect(desktopEntry, contains('application/x-ms-installer;'));
    expect(desktopEntry, contains('application/x-ms-shortcut;'));
    expect(desktopEntry, contains('application/x-msdos-program;'));
    expect(desktopEntry, contains('text/x-msdos-batch;'));

    final mimeAppsPath = _joinTestPath(xdgConfigHome, const ['mimeapps.list']);
    final mimeApps = File(mimeAppsPath).readAsStringSync();
    expect(mimeApps, contains('[Default Applications]'));
    expect(
      mimeApps,
      contains('application/x-ms-dos-executable=app.konyak.Konyak.desktop'),
    );
    expect(
      mimeApps,
      contains('application/x-msdownload=app.konyak.Konyak.desktop'),
    );
    expect(
      mimeApps,
      contains(
        'application/vnd.microsoft.portable-executable=app.konyak.Konyak.desktop',
      ),
    );
    expect(mimeApps, contains('application/x-msi=app.konyak.Konyak.desktop'));
    expect(
      mimeApps,
      contains('application/x-ms-installer=app.konyak.Konyak.desktop'),
    );
    expect(
      mimeApps,
      contains('application/x-ms-shortcut=app.konyak.Konyak.desktop'),
    );
    expect(
      mimeApps,
      contains('application/x-msdos-program=app.konyak.Konyak.desktop'),
    );
    expect(mimeApps, contains('text/x-msdos-batch=app.konyak.Konyak.desktop'));

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'linuxFileAssociations': {
        'desktopEntryPath': desktopPath,
        'mimeAppsPath': mimeAppsPath,
        'mimeTypes': [
          'application/x-ms-dos-executable',
          'application/x-msdownload',
          'application/vnd.microsoft.portable-executable',
          'application/x-msi',
          'application/x-ms-installer',
          'application/x-ms-shortcut',
          'application/x-msdos-program',
          'text/x-msdos-batch',
        ],
      },
    });
  });

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
        'KONYAK_MACOS_WINE_HOME': fakeRuntimeRoot.path,
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
        bottles: [
          BottleRecord(
            id: 'local',
            name: 'Local',
            path: '/home/user/.local/share/konyak/bottles/local',
            windowsVersion: 'win10',
          ),
        ],
      );
      final repository = CompositeBottleRepository(
        catalogs: [
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
      bottles: [
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
}
