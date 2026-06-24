part of 'widget_test.dart';

void defineMacosStartupAndRuntimeWidgetTests() {
  testWidgets('macOS app menu command opens settings', (
    WidgetTester tester,
  ) async {
    final runner = _QueuedProcessRunner([
      const ProcessRunResult(
        exitCode: 0,
        stdout: '{"schemaVersion":1,"bottles":[]}',
        stderr: '',
      ),
      const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "appSettings": {
              "terminateWineProcessesOnClose": true,
              "defaultBottlePath": "/Users/user/Library/Application Support/Konyak/Bottles",
              "automaticallyCheckForKonyakUpdates": false,
              "automaticallyCheckForWineUpdates": true
            }
          }
        ''',
        stderr: '',
      ),
      const ProcessRunResult(
        exitCode: 0,
        stdout: '{"schemaVersion":1,"runtimes":[]}',
        stderr: '',
      ),
    ]);

    await tester.pumpWidget(
      _testKonyakApp(
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
      ),
    );
    await tester.pumpAndSettle();

    final result = Completer<ByteData?>();
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'konyak/menu',
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall('openSettings'),
      ),
      result.complete,
    );
    await result.future;
    await tester.pumpAndSettle();

    expect(find.text('Konyak Settings'), findsOneWidget);
  });

  testWidgets('macOS File menu command imports a bottle archive', (
    WidgetTester tester,
  ) async {
    final runner = _QueuedProcessRunner([
      const ProcessRunResult(
        exitCode: 0,
        stdout: '{"schemaVersion":1,"bottles":[]}',
        stderr: '',
      ),
      const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "bottle": {
              "id": "steam",
              "name": "Steam",
              "path": "/Users/user/Library/Application Support/Konyak/Bottles/steam",
              "windowsVersion": "win10"
            }
          }
        ''',
        stderr: '',
      ),
    ]);

    await tester.pumpWidget(
      _testKonyakApp(
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
        bottleArchivePicker: const _FakeBottleArchivePicker(
          importPath: '/imports/steam.konyak-bottle.tar',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final result = Completer<ByteData?>();
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'konyak/menu',
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall('importBottleArchive'),
      ),
      result.complete,
    );
    await result.future;
    await tester.pumpAndSettle();

    expect(find.text('Imported Steam'), findsOneWidget);
  });

  testWidgets('macOS app menu command reinstalls the managed runtime', (
    WidgetTester tester,
  ) async {
    final runner = _QueuedProcessRunner([
      const ProcessRunResult(
        exitCode: 0,
        stdout: '{"schemaVersion":1,"bottles":[]}',
        stderr: '',
      ),
      const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "runtime": {
              "id": "konyak-macos-wine",
              "name": "Konyak macOS Wine",
              "platform": "macos",
              "architecture": "x86_64",
              "runnerKind": "macosWine",
              "isBundled": false,
              "isUpdateable": true,
              "isInstalled": true
            }
          }
        ''',
        stderr: '',
      ),
    ]);

    await tester.pumpWidget(
      _testKonyakApp(
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
      ),
    );
    await tester.pumpAndSettle();

    final result = Completer<ByteData?>();
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'konyak/menu',
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall('reinstallMacosRuntime'),
      ),
      result.complete,
    );
    await result.future;
    await tester.pumpAndSettle();

    expect(find.text('Reinstalled Konyak macOS Wine'), findsOneWidget);
    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      ['install-macos-wine', '--reinstall', '--progress-json', '--json'],
    ]);
  });

  testWidgets('macOS open executable event asks for a bottle before running', (
    WidgetTester tester,
  ) async {
    final runner = _QueuedProcessRunner([
      const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "bottles": [
              {
                "id": "steam",
                "name": "Steam",
                "path": "/Users/user/Library/Application Support/Konyak/Bottles/steam",
                "windowsVersion": "win10"
              }
            ]
          }
        ''',
        stderr: '',
      ),
      const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "run": {
              "bottleId": "steam",
              "programPath": "/downloads/setup.exe",
              "runnerKind": "wine",
              "executable": "wine",
              "workingDirectory": null,
              "argv": ["wine", "/downloads/setup.exe"],
              "logPath": "/Users/user/Library/Application Support/Konyak/Bottles/steam/logs/latest.log",
              "processExitCode": 0
            }
          }
        ''',
        stderr: '',
      ),
    ]);

    await tester.pumpWidget(
      _testKonyakApp(
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
      ),
    );
    await tester.pumpAndSettle();

    final result = Completer<ByteData?>();
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'konyak/menu',
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall('openExecutableFiles', [
          '/downloads/setup.exe',
          '/downloads/readme.txt',
          '',
          42,
        ]),
      ),
      result.complete,
    );
    await result.future;
    await tester.pumpAndSettle();

    expect(find.text('Open executable'), findsOneWidget);
    expect(find.text('/downloads/setup.exe'), findsOneWidget);
    expect(find.text('/downloads/readme.txt'), findsNothing);
    expect(find.text('Steam'), findsWidgets);

    await tester.tap(find.widgetWithText(FilledButton, 'Run'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('View latest log'), findsOneWidget);
    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      ['run-program', 'steam', '--program', '/downloads/setup.exe', '--json'],
    ]);
  });

  testWidgets('macOS startup drains pending native executable files', (
    WidgetTester tester,
  ) async {
    final nativeCalls = <String>[];
    const macosMenuChannel = MethodChannel('konyak/menu');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      macosMenuChannel,
      (call) async {
        nativeCalls.add(call.method);
        if (call.method == 'takePendingExecutableOpenPaths') {
          return const ['/downloads/setup.exe', '/downloads/readme.txt'];
        }

        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        macosMenuChannel,
        null,
      );
    });

    final runner = _QueuedProcessRunner([
      const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "bottles": [
              {
                "id": "steam",
                "name": "Steam",
                "path": "/Users/user/Library/Application Support/Konyak/Bottles/steam",
                "windowsVersion": "win10"
              }
            ]
          }
        ''',
        stderr: '',
      ),
      const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "run": {
              "bottleId": "steam",
              "programPath": "/downloads/setup.exe",
              "runnerKind": "wine",
              "executable": "wine",
              "workingDirectory": null,
              "argv": ["wine", "/downloads/setup.exe"],
              "logPath": "/Users/user/Library/Application Support/Konyak/Bottles/steam/logs/latest.log",
              "processExitCode": 0
            }
          }
        ''',
        stderr: '',
      ),
    ]);

    await tester.pumpWidget(
      _testKonyakApp(
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
      ),
    );
    await tester.pumpAndSettle();

    expect(nativeCalls, contains('takePendingExecutableOpenPaths'));
    expect(find.text('Open executable'), findsOneWidget);
    expect(find.text('/downloads/setup.exe'), findsOneWidget);
    expect(find.text('/downloads/readme.txt'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'Run'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('View latest log'), findsOneWidget);
    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      ['run-program', 'steam', '--program', '/downloads/setup.exe', '--json'],
    ]);
  });

  testWidgets('macOS startup can auto-run pending executable files for smoke', (
    WidgetTester tester,
  ) async {
    final runner = _QueuedProcessRunner([
      const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "bottles": [
              {
                "id": "steam",
                "name": "Steam",
                "path": "/Users/user/Library/Application Support/Konyak/Bottles/steam",
                "windowsVersion": "win10"
              }
            ]
          }
        ''',
        stderr: '',
      ),
      const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "run": {
              "bottleId": "steam",
              "programPath": "/downloads/setup.exe",
              "runnerKind": "macosWine",
              "executable": "/runtime/bin/wineloader",
              "workingDirectory": "/runtime/bin",
              "argv": ["/runtime/bin/wineloader", "start", "/unix", "/downloads/setup.exe"],
              "logPath": "/Users/user/Library/Application Support/Konyak/Bottles/steam/logs/latest.log",
              "processExitCode": 0
            }
          }
        ''',
        stderr: '',
      ),
    ]);

    await tester.pumpWidget(
      _testKonyakApp(
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
        initialExecutablePaths: const ['/downloads/setup.exe'],
        executableOpenAutoRunBottleId: 'steam',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open executable'), findsNothing);
    expect(find.byTooltip('View latest log'), findsOneWidget);
    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      ['run-program', 'steam', '--program', '/downloads/setup.exe', '--json'],
    ]);
  });

  testWidgets('launch executable argument can create a bottle before running', (
    WidgetTester tester,
  ) async {
    final runner = _QueuedProcessRunner([
      const ProcessRunResult(
        exitCode: 0,
        stdout: '{"schemaVersion":1,"bottles":[]}',
        stderr: '',
      ),
      const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "bottle": {
              "id": "games",
              "name": "Games",
              "path": "/Users/user/Library/Application Support/Konyak/Bottles/games",
              "windowsVersion": "win10"
            }
          }
        ''',
        stderr: '',
      ),
      const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "run": {
              "bottleId": "games",
              "programPath": "/downloads/setup.EXE",
              "runnerKind": "wine",
              "executable": "wine",
              "workingDirectory": null,
              "argv": ["wine", "/downloads/setup.EXE"],
              "logPath": "/Users/user/Library/Application Support/Konyak/Bottles/games/logs/latest.log",
              "processExitCode": 0
            }
          }
        ''',
        stderr: '',
      ),
    ]);

    await tester.pumpWidget(
      _testKonyakApp(
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
        initialExecutablePaths: const ['/downloads/setup.EXE'],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open executable'), findsOneWidget);
    expect(find.text('/downloads/setup.EXE'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Create Bottle'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Games');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('View latest log'), findsOneWidget);
  });

  testWidgets('macOS installs available Konyak app updates on startup', (
    WidgetTester tester,
  ) async {
    final runner = _QueuedProcessRunner([
      const ProcessRunResult(
        exitCode: 0,
        stdout: '{"schemaVersion":1,"bottles":[]}',
        stderr: '',
      ),
      const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "appSettings": {
              "terminateWineProcessesOnClose": false,
              "defaultBottlePath": "/Users/user/Library/Application Support/Konyak/Bottles",
              "automaticallyCheckForKonyakUpdates": true,
              "automaticallyCheckForWineUpdates": true
            }
          }
        ''',
        stderr: '',
      ),
      const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "appUpdate": {
              "appId": "konyak",
              "status": "available",
              "currentVersion": "1.0.0",
              "latestVersion": "1.1.0"
            }
          }
        ''',
        stderr: '',
      ),
      const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "runtimes": [
              {
                "id": "konyak-macos-wine",
                "name": "Konyak macOS Wine",
                "platform": "macos",
                "architecture": "x86_64",
                "runnerKind": "macosWine",
                "isBundled": false,
                "isUpdateable": true,
                "isInstalled": true
              }
            ]
          }
        ''',
        stderr: '',
      ),
      const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "runtimeUpdate": {
              "runtimeId": "konyak-macos-wine",
              "status": "available",
              "currentVersion": "wine-devel-11.9",
              "latestVersion": "12.0"
            }
          }
        ''',
        stderr: '',
      ),
      const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "appUpdateInstall": {
              "appId": "konyak",
              "status": "installed",
              "currentVersion": "1.0.0",
              "installedVersion": "1.1.0",
              "installPath": "/Applications/Konyak.app"
            }
          }
        ''',
        stderr: '',
      ),
    ]);

    await tester.pumpWidget(
      _testKonyakApp(
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
        enableBackgroundServices: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      runner.argumentsLog,
      containsAllInOrder([
        const ['get-app-settings', '--json'],
        const ['check-app-update', '--json'],
        const ['list-runtimes', '--json'],
        const ['check-runtime-update', 'konyak-macos-wine', '--json'],
        const ['install-app-update', '--json'],
      ]),
    );
    expect(
      find.text('Installing Konyak 1.1.0 update. Konyak will restart.'),
      findsOneWidget,
    );
    expect(find.textContaining('Updates available:'), findsNothing);
  });

  testWidgets(
    'macOS notifies available runtime updates when the app is current',
    (WidgetTester tester) async {
      final runner = _QueuedProcessRunner([
        const ProcessRunResult(
          exitCode: 0,
          stdout: '{"schemaVersion":1,"bottles":[]}',
          stderr: '',
        ),
        const ProcessRunResult(
          exitCode: 0,
          stdout: '''
          {
            "schemaVersion": 1,
            "appSettings": {
              "terminateWineProcessesOnClose": false,
              "defaultBottlePath": "/Users/user/Library/Application Support/Konyak/Bottles",
              "automaticallyCheckForKonyakUpdates": true,
              "automaticallyCheckForWineUpdates": true
            }
          }
        ''',
          stderr: '',
        ),
        const ProcessRunResult(
          exitCode: 0,
          stdout: '''
          {
            "schemaVersion": 1,
            "appUpdate": {
              "appId": "konyak",
              "status": "current",
              "currentVersion": "1.1.0",
              "latestVersion": "1.1.0"
            }
          }
        ''',
          stderr: '',
        ),
        const ProcessRunResult(
          exitCode: 0,
          stdout: '''
          {
            "schemaVersion": 1,
            "runtimes": [
              {
                "id": "konyak-macos-wine",
                "name": "Konyak macOS Wine",
                "platform": "macos",
                "architecture": "x86_64",
                "runnerKind": "macosWine",
                "isBundled": false,
                "isUpdateable": true,
                "isInstalled": true
              }
            ]
          }
        ''',
          stderr: '',
        ),
        const ProcessRunResult(
          exitCode: 0,
          stdout: '''
          {
            "schemaVersion": 1,
            "runtimeUpdate": {
              "runtimeId": "konyak-macos-wine",
              "status": "available",
              "currentVersion": "wine-devel-11.9",
              "latestVersion": "12.0"
            }
          }
        ''',
          stderr: '',
        ),
      ]);

      await tester.pumpWidget(
        _testKonyakApp(
          cliClient: KonyakCliClient(
            executable: 'konyak',
            processRunner: runner,
          ),
          enableBackgroundServices: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Updates available: Konyak macOS Wine 12.0'),
        findsOneWidget,
      );
    },
  );

  testWidgets('macOS warns when automatic Konyak update install fails', (
    WidgetTester tester,
  ) async {
    final runner = _QueuedProcessRunner([
      const ProcessRunResult(
        exitCode: 0,
        stdout: '{"schemaVersion":1,"bottles":[]}',
        stderr: '',
      ),
      const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "appSettings": {
              "terminateWineProcessesOnClose": false,
              "defaultBottlePath": "/Users/user/Library/Application Support/Konyak/Bottles",
              "automaticallyCheckForKonyakUpdates": true,
              "automaticallyCheckForWineUpdates": false
            }
          }
        ''',
        stderr: '',
      ),
      const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "appUpdate": {
              "appId": "konyak",
              "status": "available",
              "currentVersion": "1.0.0",
              "latestVersion": "1.1.0"
            }
          }
        ''',
        stderr: '',
      ),
      const ProcessRunResult(
        exitCode: 75,
        stdout: '''
          {
            "schemaVersion": 1,
            "error": {
              "code": "appUpdateInstallFailed",
              "message": "Current Konyak app bundle does not exist."
            }
          }
        ''',
        stderr: '',
      ),
    ]);

    await tester.pumpWidget(
      _testKonyakApp(
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
        enableBackgroundServices: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Konyak update install failed: Current Konyak app bundle does not exist.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Linux installs available Konyak AppImage updates on startup', (
    WidgetTester tester,
  ) async {
    final runner = _QueuedProcessRunner([
      const ProcessRunResult(
        exitCode: 0,
        stdout: '{"schemaVersion":1,"bottles":[]}',
        stderr: '',
      ),
      const ProcessRunResult(
        exitCode: 0,
        stdout:
            '{"schemaVersion":1,"linuxFileAssociations":{"status":"installed"}}',
        stderr: '',
      ),
      const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "appSettings": {
              "terminateWineProcessesOnClose": false,
              "defaultBottlePath": "/home/user/.local/share/konyak/Bottles",
              "automaticallyCheckForKonyakUpdates": true,
              "automaticallyCheckForWineUpdates": false
            }
          }
        ''',
        stderr: '',
      ),
      const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "appUpdate": {
              "appId": "konyak",
              "status": "available",
              "currentVersion": "1.0.0",
              "latestVersion": "1.1.0"
            }
          }
        ''',
        stderr: '',
      ),
      const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "appUpdateInstall": {
              "appId": "konyak",
              "status": "installed",
              "currentVersion": "1.0.0",
              "installedVersion": "1.1.0",
              "installPath": "/home/user/Applications/Konyak.AppImage"
            }
          }
        ''',
        stderr: '',
      ),
    ]);

    await tester.pumpWidget(
      _testKonyakApp(
        platform: KonyakPlatform.linux,
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
        enableBackgroundServices: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      runner.argumentsLog,
      containsAllInOrder([
        const ['install-linux-file-associations', '--json'],
        const ['get-app-settings', '--json'],
        const ['check-app-update', '--json'],
        const ['install-app-update', '--json'],
      ]),
    );
    expect(
      find.text('Installing Konyak 1.1.0 update. Konyak will restart.'),
      findsOneWidget,
    );
  });

  testWidgets('Linux warns when automatic Konyak update install fails', (
    WidgetTester tester,
  ) async {
    final runner = _QueuedProcessRunner([
      const ProcessRunResult(
        exitCode: 0,
        stdout: '{"schemaVersion":1,"bottles":[]}',
        stderr: '',
      ),
      const ProcessRunResult(
        exitCode: 0,
        stdout:
            '{"schemaVersion":1,"linuxFileAssociations":{"status":"installed"}}',
        stderr: '',
      ),
      const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "appSettings": {
              "terminateWineProcessesOnClose": false,
              "defaultBottlePath": "/home/user/.local/share/konyak/Bottles",
              "automaticallyCheckForKonyakUpdates": true,
              "automaticallyCheckForWineUpdates": false
            }
          }
        ''',
        stderr: '',
      ),
      const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "appUpdate": {
              "appId": "konyak",
              "status": "available",
              "currentVersion": "1.0.0",
              "latestVersion": "1.1.0"
            }
          }
        ''',
        stderr: '',
      ),
      const ProcessRunResult(
        exitCode: 75,
        stdout: '''
          {
            "schemaVersion": 1,
            "error": {
              "code": "appUpdateInstallFailed",
              "message": "Current Konyak AppImage directory is not writable."
            }
          }
        ''',
        stderr: '',
      ),
    ]);

    await tester.pumpWidget(
      _testKonyakApp(
        platform: KonyakPlatform.linux,
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
        enableBackgroundServices: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Konyak update install failed: Current Konyak AppImage directory is not writable.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('macOS prompts to install a missing managed runtime on launch', (
    WidgetTester tester,
  ) async {
    final installCompleter = Completer<ProcessRunResult>();
    final runner = _FutureQueuedProcessRunner([
      Future.value(
        const ProcessRunResult(
          exitCode: 0,
          stdout: '{"schemaVersion":1,"bottles":[]}',
          stderr: '',
        ),
      ),
      Future.value(
        const ProcessRunResult(
          exitCode: 0,
          stdout: '''
          {
            "schemaVersion": 1,
            "appSettings": {
              "terminateWineProcessesOnClose": false,
              "defaultBottlePath": "/Users/user/Library/Application Support/Konyak/Bottles",
              "automaticallyCheckForKonyakUpdates": false,
              "automaticallyCheckForWineUpdates": false
            }
          }
        ''',
          stderr: '',
        ),
      ),
      Future.value(
        const ProcessRunResult(
          exitCode: 0,
          stdout: '''
          {
            "schemaVersion": 1,
            "runtimes": [
              {
                "id": "konyak-macos-wine",
                "name": "Konyak macOS Wine",
                "platform": "macos",
                "architecture": "x86_64",
                "runnerKind": "macosWine",
                "isBundled": false,
                "isUpdateable": true,
                "isInstalled": false
              }
            ]
          }
        ''',
          stderr: '',
        ),
      ),
      installCompleter.future,
    ]);

    await tester.pumpWidget(
      _testKonyakApp(
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
        enableBackgroundServices: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Download Konyak macOS Wine?'), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);

    await tester.tap(find.text('Download'));
    await tester.pump();
    runner.emitStdoutLine(
      '{"schemaVersion":1,"runtimeInstallProgress":{"stage":"downloading","message":"Downloading Konyak macOS Wine...","fraction":0.42}}',
    );
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      find.byKey(const ValueKey('runtime-install-progress')),
      findsOneWidget,
    );
    expect(find.text('Downloading Konyak macOS Wine...'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    final progress = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(progress.value, 0.42);
    expect(find.text('42%'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    installCompleter.complete(
      const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "runtime": {
              "id": "konyak-macos-wine",
              "name": "Konyak macOS Wine",
              "platform": "macos",
              "architecture": "x86_64",
              "runnerKind": "macosWine",
              "isBundled": false,
              "isUpdateable": true,
              "isInstalled": true
            }
          }
        ''',
        stderr: '',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Installed Konyak macOS Wine'), findsOneWidget);
  });

  testWidgets('Linux prompts to install a missing managed runtime on launch', (
    WidgetTester tester,
  ) async {
    final installCompleter = Completer<ProcessRunResult>();
    final runner = _FutureQueuedProcessRunner([
      Future.value(
        const ProcessRunResult(
          exitCode: 0,
          stdout: '{"schemaVersion":1,"bottles":[]}',
          stderr: '',
        ),
      ),
      Future.value(
        const ProcessRunResult(
          exitCode: 0,
          stdout:
              '{"schemaVersion":1,"linuxFileAssociations":{"desktopEntryPath":"/apps/app.konyak.Konyak.desktop","mimeAppsPath":"/config/mimeapps.list","mimeTypes":["application/x-ms-dos-executable"]}}',
          stderr: '',
        ),
      ),
      Future.value(
        const ProcessRunResult(
          exitCode: 0,
          stdout: '''
          {
            "schemaVersion": 1,
            "appSettings": {
              "terminateWineProcessesOnClose": false,
              "defaultBottlePath": "/home/user/.local/share/konyak/bottles",
              "automaticallyCheckForKonyakUpdates": false,
              "automaticallyCheckForWineUpdates": false
            }
          }
        ''',
          stderr: '',
        ),
      ),
      Future.value(
        const ProcessRunResult(
          exitCode: 0,
          stdout: '''
          {
            "schemaVersion": 1,
            "runtimes": [
              {
                "id": "konyak-linux-wine",
                "name": "Konyak Linux Wine",
                "platform": "linux",
                "architecture": "x86_64",
                "runnerKind": "wine",
                "isBundled": false,
                "isUpdateable": true,
                "isInstalled": false
              }
            ]
          }
        ''',
          stderr: '',
        ),
      ),
      installCompleter.future,
    ]);

    await tester.pumpWidget(
      _testKonyakApp(
        platform: KonyakPlatform.linux,
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
        enableBackgroundServices: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Download Konyak Linux Wine?'), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);

    await tester.tap(find.text('Download'));
    await tester.pump();
    runner.emitStdoutLine(
      '{"schemaVersion":1,"runtimeInstallProgress":{"stage":"downloading","message":"Downloading Konyak Linux Wine...","fraction":0.37}}',
    );
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      find.byKey(const ValueKey('runtime-install-progress')),
      findsOneWidget,
    );
    expect(find.text('Downloading Konyak Linux Wine...'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    final progress = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(progress.value, 0.37);
    expect(find.text('37%'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    installCompleter.complete(
      const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "runtime": {
              "id": "konyak-linux-wine",
              "name": "Konyak Linux Wine",
              "platform": "linux",
              "architecture": "x86_64",
              "runnerKind": "wine",
              "isBundled": false,
              "isUpdateable": true,
              "isInstalled": true
            }
          }
        ''',
        stderr: '',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Installed Konyak Linux Wine'), findsOneWidget);
  });

  testWidgets('enabled close behavior terminates Wine processes on dispose', (
    WidgetTester tester,
  ) async {
    final runner = _QueuedProcessRunner([
      const ProcessRunResult(
        exitCode: 0,
        stdout: '{"schemaVersion":1,"bottles":[]}',
        stderr: '',
      ),
      const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "appSettings": {
              "terminateWineProcessesOnClose": true,
              "defaultBottlePath": "/Users/user/Library/Application Support/Konyak/Bottles",
              "automaticallyCheckForKonyakUpdates": false,
              "automaticallyCheckForWineUpdates": false
            }
          }
        ''',
        stderr: '',
      ),
      const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "wineProcessTermination": {
              "hasFailures": false,
              "bottles": []
            }
          }
        ''',
        stderr: '',
      ),
    ]);

    await tester.pumpWidget(
      _testKonyakApp(
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
        enableBackgroundServices: true,
      ),
    );
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      ['get-app-settings', '--json'],
      ['list-runtimes', '--json'],
      ['terminate-wine-processes', '--json'],
    ]);
  });

  testWidgets('macOS runtime install is not exposed as a toolbar action', (
    WidgetTester tester,
  ) async {
    final runner = _QueuedProcessRunner([
      const ProcessRunResult(
        exitCode: 0,
        stdout: '{"schemaVersion":1,"bottles":[]}',
        stderr: '',
      ),
    ]);

    await tester.pumpWidget(
      _testKonyakApp(
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Install macOS Wine'), findsNothing);
  });
}
