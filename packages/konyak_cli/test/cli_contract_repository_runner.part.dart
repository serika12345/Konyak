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
    final appImage = _joinTestPath(tempDirectory.path, const [
      'Konyak.AppImage',
    ]);
    final appExecutable = _joinTestPath(tempDirectory.path, const [
      'extracted-appimage',
      'usr',
      'konyak',
    ]);
    final appIcon = _joinTestPath(tempDirectory.path, const [
      'extracted-appimage',
      'app.konyak.Konyak.png',
    ]);
    File(appImage).writeAsStringSync('appimage');
    File(appExecutable)
      ..createSync(recursive: true)
      ..writeAsStringSync('runner');
    File(appIcon)
      ..createSync(recursive: true)
      ..writeAsBytesSync(const [137, 80, 78, 71, 13, 10, 26, 10]);

    final result = runCli(
      const ['install-linux-file-associations', '--json'],
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.linux,
        environment: HostEnvironment({
          'HOME': tempDirectory.path,
          'XDG_DATA_HOME': xdgDataHome,
          'XDG_CONFIG_HOME': xdgConfigHome,
          'KONYAK_APPIMAGE_PATH': appImage,
          'KONYAK_APP_EXECUTABLE': appExecutable,
          'KONYAK_APP_ICON_PATH': appIcon,
        }),
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
    expect(desktopEntry, contains('Exec="$appImage" %f'));
    expect(desktopEntry, contains('Icon=app.konyak.Konyak'));
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
    final iconPath = _joinTestPath(xdgDataHome, const [
      'icons',
      'hicolor',
      '256x256',
      'apps',
      'app.konyak.Konyak.png',
    ]);
    expect(File(iconPath).readAsBytesSync(), File(appIcon).readAsBytesSync());

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'linuxFileAssociations': {
        'desktopEntryPath': desktopPath,
        'iconPath': iconPath,
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
        bottleId: BottleId('steam'),
        programPath: ProgramPath('/downloads/setup.exe'),
        runnerKind: RunnerKind('macosWine'),
        executable: ProgramExecutable(Platform.resolvedExecutable),
        arguments: ProgramRunArguments(const ['--version']),
        environment: ProgramRunEnvironment(const <String, String>{
          'WINEPREFIX': '/bottles/steam',
        }),
        logPath: ProgramLogPath(logPath),
        workingDirectory: Option.of(
          ProgramWorkingDirectoryPath(logDirectory.path),
        ),
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

  test(
    'program runner skips launch log when log file creation is disabled',
    () {
      final logDirectory = Directory.systemTemp.createTempSync(
        'konyak-disabled-run-log-',
      );
      addTearDown(() async {
        if (await logDirectory.exists()) {
          await logDirectory.delete(recursive: true);
        }
      });

      final logPath = _joinTestPath(logDirectory.path, const ['latest.log']);
      final result = const DartIoProgramRunner().run(
        ProgramRunRequest(
          bottleId: BottleId('steam'),
          programPath: ProgramPath('/downloads/setup.exe'),
          runnerKind: RunnerKind('wine'),
          executable: ProgramExecutable(Platform.resolvedExecutable),
          arguments: ProgramRunArguments(const ['--version']),
          environment: const ProgramRunEnvironment.empty(),
          logPath: ProgramLogPath(logPath),
          createLogFile: false,
        ),
      );

      expect(result, isA<ProgramRunCompleted>());
      expect(File(logPath).existsSync(), isFalse);
    },
  );

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
        bottleId: BottleId('steam'),
        programPath: ProgramPath('/downloads/setup.exe'),
        runnerKind: RunnerKind('wine'),
        executable: ProgramExecutable('/definitely/missing/konyak-runner'),
        arguments: ProgramRunArguments(const ['/downloads/setup.exe']),
        environment: const ProgramRunEnvironment.empty(),
        logPath: ProgramLogPath(logPath),
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
      final fakeWineloader =
          File(_joinTestPath(fakeBin.path, const ['wineloader']))
            ..writeAsStringSync('#!/bin/sh\nexit 0\n')
            ..createSync(recursive: true);
      final fakeWineboot = File(_joinTestPath(fakeBin.path, const ['wineboot']))
        ..writeAsStringSync('#!/bin/sh\nexit 0\n')
        ..createSync(recursive: true);
      Process.runSync('chmod', [
        '755',
        fakeWine.path,
        fakeWineloader.path,
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

      expect(_expectIo(repository.listBottles()), isEmpty);
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
        BottleCreateRequest(name: 'Created', windowsVersion: 'win10'),
      );

      expect(result, isA<BottleCreated>());
      final created = result as BottleCreated;
      expect(
        created.bottle.path.value,
        '${tempDirectory.path}/Library/Application Support/Konyak/Bottles/created',
      );
      expect(
        File(
          _joinTestPath(created.bottle.path.value, const ['metadata.json']),
        ).existsSync(),
        isTrue,
      );
      expect(
        Directory(
          _joinTestPath(created.bottle.path.value, const ['drive_c']),
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

      expect(_expectIo(repository.listBottles()), isEmpty);

      final createResult = repository.createBottle(
        BottleCreateRequest(name: 'Managed', windowsVersion: 'win10'),
      );

      expect(createResult, isA<BottleCreated>());
      expect(
        _expectIo(repository.listBottles()).map((bottle) => bottle.id.value),
        const ['managed'],
      );
    },
  );

  test(
    'composite bottle repository reads multiple catalogs and writes locally',
    () {
      final writableRepository = MemoryBottleRepository(
        programMetadataExtractor: const NoopProgramMetadataExtractor(),
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

      expect(
        _expectIo(repository.listBottles()).map((bottle) => bottle.id.value),
        const ['imported', 'local'],
      );
      expect(
        _expectFound(repository.findBottle('imported')).name.value,
        'Imported',
      );

      final createResult = repository.createBottle(
        BottleCreateRequest(name: 'Created', windowsVersion: 'win10'),
      );

      expect(createResult, isA<BottleCreated>());
      expect(
        _expectFound(repository.findBottle('created')).name.value,
        'Created',
      );
    },
  );

  test('composite bottle repository does not mutate catalog repositories', () {
    final writableRepository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: '/home/user/.local/share/konyak',
    );
    final importedRepository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
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

    expect(
      _expectIo(repository.listBottles()).map((bottle) => bottle.id.value),
      const ['imported'],
    );

    final deleteResult = repository.deleteBottle('imported');

    expect(deleteResult, isA<BottleDeleteMissing>());

    final renameResult = repository.renameBottle(
      BottleRenameRequest(bottleId: 'imported', name: 'Renamed'),
    );
    expect(renameResult, isA<BottleRenameMissing>());

    final moveResult = repository.moveBottle(
      BottleMoveRequest(
        bottleId: 'imported',
        path: '/home/user/.local/share/konyak/bottles/moved',
      ),
    );
    expect(moveResult, isA<BottleMoveMissing>());

    final runtimeSettingsResult = repository.setRuntimeSettings(
      RuntimeSettingsUpdateRequest(
        bottleId: 'imported',
        runtimeSettings: BottleRuntimeSettings(metalHud: true),
      ),
    );
    expect(runtimeSettingsResult, isA<BottleUpdateMissing>());

    final pinResult = repository.pinProgram(
      ProgramPinRequest(
        bottleId: 'imported',
        name: 'Setup',
        programPath: '/downloads/setup.exe',
      ),
    );
    expect(pinResult, isA<ProgramPinMissing>());

    final importedBottle = _expectFound(
      importedRepository.findBottle('imported'),
    );
    expect(importedBottle.name.value, 'Imported');
    expect(
      importedBottle.path.value,
      '/home/user/.local/share/konyak/bottles/imported',
    );
    expect(importedBottle.runtimeSettings, BottleRuntimeSettings());
    expect(importedBottle.pinnedPrograms, isEmpty);
    expect(
      _expectIo(
        importedRepository.listBottles(),
      ).map((bottle) => bottle.id.value),
      const ['imported'],
    );
    expect(
      _expectIo(repository.listBottles()).map((bottle) => bottle.id.value),
      const ['imported'],
    );
  });
}
