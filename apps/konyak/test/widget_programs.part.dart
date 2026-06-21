part of 'widget_test.dart';

void defineProgramWidgetTests() {
  testWidgets('run program auto-pins newly installed programs when enabled', (
    WidgetTester tester,
  ) async {
    const installedShortcutPath =
        '/bottles/steam/drive_c/ProgramData/Microsoft/Windows/Start Menu/Programs/Steam.lnk';
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
                "path": "/bottles/steam",
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
            "appSettings": {
              "terminateWineProcessesOnClose": true,
              "defaultBottlePath": "/bottles",
              "automaticallyCheckForKonyakUpdates": false,
              "automaticallyCheckForWineUpdates": false,
              "automaticallyPinNewInstalledPrograms": true
            }
          }
        ''',
        stderr: '',
      ),
      ProcessRunResult(
        exitCode: 0,
        stdout: _macosRuntimeListPayload(),
        stderr: '',
      ),
      const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "bottlePrograms": {
              "bottleId": "steam",
              "programs": []
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
              "bottleId": "steam",
              "programPath": "/downloads/setup.exe",
              "runnerKind": "wine",
              "executable": "wine",
              "workingDirectory": null,
              "argv": ["wine", "/downloads/setup.exe"],
              "logPath": "/bottles/steam/logs/latest.log",
              "processExitCode": 0
            }
          }
        ''',
        stderr: '',
      ),
      const ProcessRunResult(
        exitCode: 0,
        stdout:
            '''
          {
            "schemaVersion": 1,
            "bottlePrograms": {
              "bottleId": "steam",
              "programs": [
                {
                  "id": "steam-shortcut",
                  "name": "Steam",
                  "path": "$installedShortcutPath",
                  "source": "globalStartMenu"
                }
              ]
            }
          }
        ''',
        stderr: '',
      ),
      const ProcessRunResult(
        exitCode: 0,
        stdout:
            '''
          {
            "schemaVersion": 1,
            "bottle": {
              "id": "steam",
              "name": "Steam",
              "path": "/bottles/steam",
              "windowsVersion": "win10",
              "pinnedPrograms": [
                {
                  "name": "Steam",
                  "path": "$installedShortcutPath",
                  "removable": true
                }
              ]
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

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Close'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Run'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Program path'),
      '/downloads/setup.exe',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Run'));
    await tester.pumpAndSettle();

    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      ['get-app-settings', '--json'],
      ['list-runtimes', '--json'],
      ['list-bottle-programs', 'steam', '--json'],
      ['run-program', 'steam', '--program', '/downloads/setup.exe', '--json'],
      ['list-bottle-programs', 'steam', '--json'],
      [
        'pin-program',
        'steam',
        '--name',
        'Steam',
        '--program',
        installedShortcutPath,
        '--json',
      ],
    ]);
    expect(find.text('Pinned Steam'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('pinned-program-tile-$installedShortcutPath')),
      findsOneWidget,
    );
  });

  testWidgets(
    'run program does not auto-pin installed programs when disabled',
    (WidgetTester tester) async {
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
                "path": "/bottles/steam",
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
            "appSettings": {
              "terminateWineProcessesOnClose": true,
              "defaultBottlePath": "/bottles",
              "automaticallyCheckForKonyakUpdates": false,
              "automaticallyCheckForWineUpdates": false,
              "automaticallyPinNewInstalledPrograms": false
            }
          }
        ''',
          stderr: '',
        ),
        ProcessRunResult(
          exitCode: 0,
          stdout: _macosRuntimeListPayload(),
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
              "logPath": "/bottles/steam/logs/latest.log",
              "processExitCode": 0
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
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Close'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Run'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Program path'),
        '/downloads/setup.exe',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Run'));
      await tester.pumpAndSettle();

      expect(runner.argumentsLog, const [
        ['list-bottles', '--json'],
        ['get-app-settings', '--json'],
        ['list-runtimes', '--json'],
        ['run-program', 'steam', '--program', '/downloads/setup.exe', '--json'],
      ]);
    },
  );

  testWidgets('run program dialog invokes the CLI client for a bottle', (
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
                "path": "/home/user/.local/share/konyak/bottles/steam",
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
              "logPath": "/home/user/.local/share/konyak/bottles/steam/logs/latest.log",
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
        logReader: const _FakeLogReader(
          logs: {
            '/home/user/.local/share/konyak/bottles/steam/logs/latest.log':
                'argv: ["wine","/downloads/setup.exe"]\nexitCode: 0\n',
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Run'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Program path'),
      '/downloads/setup.exe',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Run'));
    await tester.pumpAndSettle();

    expect(find.text('wine exited with code 0'), findsNothing);
    expect(find.byTooltip('View latest log'), findsOneWidget);

    await tester.tap(find.byTooltip('View latest log'));
    await tester.pumpAndSettle();

    expect(find.text('Latest run log'), findsOneWidget);
    expect(find.textContaining('exitCode: 0'), findsOneWidget);
  });

  testWidgets('run program shows launch progress while the CLI is pending', (
    WidgetTester tester,
  ) async {
    final runCompleter = Completer<ProcessRunResult>();
    final runner = _FutureQueuedProcessRunner([
      Future.value(
        const ProcessRunResult(
          exitCode: 0,
          stdout: '''
          {
            "schemaVersion": 1,
            "bottles": [
              {
                "id": "steam",
                "name": "Steam",
                "path": "/home/user/.local/share/konyak/bottles/steam",
                "windowsVersion": "win10"
              }
            ]
          }
        ''',
          stderr: '',
        ),
      ),
      runCompleter.future,
    ]);

    await tester.pumpWidget(
      _testKonyakApp(
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Run'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Program path'),
      '/downloads/setup.exe',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Run'));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Launching program...'), findsOneWidget);

    runCompleter.complete(
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
              "logPath": "/home/user/.local/share/konyak/bottles/steam/logs/latest.log",
              "processExitCode": 0
            }
          }
        ''',
        stderr: '',
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Launching program...'), findsNothing);
    expect(find.byTooltip('View latest log'), findsOneWidget);
  });

  testWidgets(
    'run program hides launch progress when a new macOS window opens',
    (WidgetTester tester) async {
      final windowProbe = _MutableProgramWindowProbe();
      final runCompleter = Completer<ProcessRunResult>();
      final runner = _FutureQueuedProcessRunner([
        Future.value(
          const ProcessRunResult(
            exitCode: 0,
            stdout: '''
          {
            "schemaVersion": 1,
            "bottles": [
              {
                "id": "steam",
                "name": "Steam",
                "path": "/home/user/.local/share/konyak/bottles/steam",
                "windowsVersion": "win10"
              }
            ]
          }
        ''',
            stderr: '',
          ),
        ),
        runCompleter.future,
      ], startedProcessId: 4242);

      await tester.pumpWidget(
        _testKonyakApp(
          cliClient: KonyakCliClient(
            executable: 'konyak',
            processRunner: runner,
          ),
          programWindowProbe: windowProbe,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Run'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Program path'),
        '/downloads/setup.exe',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Run'));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Launching program...'), findsOneWidget);

      windowProbe.visibleWindowRootProcessIds['wine-window-1'] = 4242;
      await tester.pump(const Duration(milliseconds: 400));

      expect(runCompleter.isCompleted, isFalse);
      expect(find.text('Launching program...'), findsNothing);

      runCompleter.complete(
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
              "logPath": "/home/user/.local/share/konyak/bottles/steam/logs/latest.log",
              "processExitCode": 0
            }
          }
        ''',
          stderr: '',
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byTooltip('View latest log'), findsOneWidget);
    },
  );

  testWidgets(
    'run program ignores unrelated external windows while launch is pending',
    (WidgetTester tester) async {
      final windowProbe = _MutableProgramWindowProbe();
      final runCompleter = Completer<ProcessRunResult>();
      final runner = _FutureQueuedProcessRunner([
        Future.value(
          const ProcessRunResult(
            exitCode: 0,
            stdout: '''
          {
            "schemaVersion": 1,
            "bottles": [
              {
                "id": "steam",
                "name": "Steam",
                "path": "/home/user/.local/share/konyak/bottles/steam",
                "windowsVersion": "win10"
              }
            ]
          }
        ''',
            stderr: '',
          ),
        ),
        runCompleter.future,
      ], startedProcessId: 4242);

      await tester.pumpWidget(
        _testKonyakApp(
          cliClient: KonyakCliClient(
            executable: 'konyak',
            processRunner: runner,
          ),
          programWindowProbe: windowProbe,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Run'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Program path'),
        '/downloads/setup.exe',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Run'));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Launching program...'), findsOneWidget);

      windowProbe.visibleWindowRootProcessIds['safari-window-1'] = 7777;
      await tester.pump(const Duration(milliseconds: 400));

      expect(runCompleter.isCompleted, isFalse);
      expect(find.text('Launching program...'), findsOneWidget);

      runCompleter.complete(
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
              "logPath": "/home/user/.local/share/konyak/bottles/steam/logs/latest.log",
              "processExitCode": 0
            }
          }
        ''',
          stderr: '',
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byTooltip('View latest log'), findsOneWidget);
    },
  );

  testWidgets(
    'run program hides launch progress for a new Wine process window',
    (WidgetTester tester) async {
      final windowProbe = _MutableProgramWindowProbe();
      final runCompleter = Completer<ProcessRunResult>();
      final runner = _FutureQueuedProcessRunner([
        Future.value(
          const ProcessRunResult(
            exitCode: 0,
            stdout: '''
          {
            "schemaVersion": 1,
            "bottles": [
              {
                "id": "steam",
                "name": "Steam",
                "path": "/home/user/.local/share/konyak/bottles/steam",
                "windowsVersion": "win10"
              }
            ]
          }
        ''',
            stderr: '',
          ),
        ),
        runCompleter.future,
      ], startedProcessId: 4242);

      await tester.pumpWidget(
        _testKonyakApp(
          cliClient: KonyakCliClient(
            executable: 'konyak',
            processRunner: runner,
          ),
          programWindowProbe: windowProbe,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Run'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Program path'),
        '/downloads/setup.exe',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Run'));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Launching program...'), findsOneWidget);

      windowProbe.visibleWineWindowIds.add('wine-window-1');
      await tester.pump(const Duration(milliseconds: 400));

      expect(runCompleter.isCompleted, isFalse);
      expect(find.text('Launching program...'), findsNothing);

      runCompleter.complete(
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
              "logPath": "/home/user/.local/share/konyak/bottles/steam/logs/latest.log",
              "processExitCode": 0
            }
          }
        ''',
          stderr: '',
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byTooltip('View latest log'), findsOneWidget);
    },
  );

  testWidgets(
    'Linux run program hides launch progress for a new Wine process window',
    (WidgetTester tester) async {
      final windowProbe = _MutableProgramWindowProbe();
      final runCompleter = Completer<ProcessRunResult>();
      final runner = _FutureQueuedProcessRunner([
        Future.value(
          const ProcessRunResult(
            exitCode: 0,
            stdout: '''
          {
            "schemaVersion": 1,
            "bottles": [
              {
                "id": "steam",
                "name": "Steam",
                "path": "/home/user/.local/share/konyak/bottles/steam",
                "windowsVersion": "win10"
              }
            ]
          }
        ''',
            stderr: '',
          ),
        ),
        runCompleter.future,
      ], startedProcessId: 4242);

      await tester.pumpWidget(
        _testKonyakApp(
          platform: KonyakPlatform.linux,
          cliClient: KonyakCliClient(
            executable: 'konyak',
            processRunner: runner,
          ),
          programWindowProbe: windowProbe,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Run'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Program path'),
        '/downloads/setup.exe',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Run'));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Launching program...'), findsOneWidget);

      windowProbe.visibleWineWindowIds.add('linux-wine-window-1');
      await tester.pump(const Duration(milliseconds: 400));

      expect(runCompleter.isCompleted, isFalse);
      expect(find.text('Launching program...'), findsNothing);

      runCompleter.complete(
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
              "logPath": "/home/user/.local/share/konyak/bottles/steam/logs/latest.log",
              "processExitCode": 0
            }
          }
        ''',
          stderr: '',
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byTooltip('View latest log'), findsOneWidget);
    },
  );

  testWidgets('run program ignores preexisting Wine process windows', (
    WidgetTester tester,
  ) async {
    final windowProbe = _MutableProgramWindowProbe();
    windowProbe.visibleWineWindowIds.add('existing-wine-window');
    final runCompleter = Completer<ProcessRunResult>();
    final runner = _FutureQueuedProcessRunner([
      Future.value(
        const ProcessRunResult(
          exitCode: 0,
          stdout: '''
          {
            "schemaVersion": 1,
            "bottles": [
              {
                "id": "steam",
                "name": "Steam",
                "path": "/home/user/.local/share/konyak/bottles/steam",
                "windowsVersion": "win10"
              }
            ]
          }
        ''',
          stderr: '',
        ),
      ),
      runCompleter.future,
    ], startedProcessId: 4242);

    await tester.pumpWidget(
      _testKonyakApp(
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
        programWindowProbe: windowProbe,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Run'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Program path'),
      '/downloads/setup.exe',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Run'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(runCompleter.isCompleted, isFalse);
    expect(find.text('Launching program...'), findsOneWidget);

    windowProbe.visibleWineWindowIds.add('new-wine-window');
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Launching program...'), findsNothing);

    runCompleter.complete(
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
              "logPath": "/home/user/.local/share/konyak/bottles/steam/logs/latest.log",
              "processExitCode": 0
            }
          }
        ''',
        stderr: '',
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byTooltip('View latest log'), findsOneWidget);
  });

  testWidgets('run program dialog can choose a program file', (
    WidgetTester tester,
  ) async {
    final pickerInitialDirectories = <String?>[];
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
                "path": "/home/user/.local/share/konyak/bottles/steam",
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
              "logPath": "/home/user/.local/share/konyak/bottles/steam/logs/latest.log",
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
        programFilePicker: _FakeProgramFilePicker(
          path: '/downloads/setup.exe',
          initialDirectories: pickerInitialDirectories,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Run'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Choose program file'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Run'));
    await tester.pumpAndSettle();

    expect(pickerInitialDirectories, const [
      '/home/user/.local/share/konyak/bottles/steam/drive_c',
    ]);
    expect(find.byTooltip('View latest log'), findsOneWidget);
  });

  testWidgets('pin program launches on double click after selection feedback', (
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
                "path": "/bottles/steam",
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
            "bottle": {
              "id": "steam",
              "name": "Steam",
              "path": "/bottles/steam",
              "windowsVersion": "win10",
              "pinnedPrograms": [
                {
                  "name": "Setup",
                  "path": "/downloads/setup.exe",
                  "removable": false
                }
              ]
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
              "bottleId": "steam",
              "programPath": "/downloads/setup.exe",
              "runnerKind": "wine",
              "executable": "wine",
              "workingDirectory": null,
              "argv": ["wine", "/downloads/setup.exe"],
              "logPath": "/bottles/steam/logs/latest.log",
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
        programFilePicker: const _FakeProgramFilePicker(
          path: '/downloads/setup.exe',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pin Program'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Choose program file'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Pin'));
    await tester.pumpAndSettle();

    expect(find.text('Setup'), findsOneWidget);

    await tester.tap(find.text('Setup'));
    await tester.pumpAndSettle();

    final selectedTile = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('pinned-program-tile-/downloads/setup.exe')),
    );
    final selectedDecoration = selectedTile.decoration as BoxDecoration?;
    expect(selectedDecoration?.color, const Color(0xff383838));

    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Setup'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('Setup'));
    await tester.pump(const Duration(milliseconds: 80));

    final bounce = tester.widget<ScaleTransition>(
      find.byKey(const ValueKey('pinned-program-bounce-/downloads/setup.exe')),
    );
    expect(bounce.scale.value, greaterThan(1));

    await tester.pumpAndSettle();

    expect(find.byTooltip('View latest log'), findsOneWidget);
  });

  testWidgets('pinned program tile displays the extracted executable icon', (
    WidgetTester tester,
  ) async {
    const iconPath = '/icons/setup.ico';
    final runner = _QueuedProcessRunner([
      const ProcessRunResult(
        exitCode: 0,
        stdout:
            '''
          {
            "schemaVersion": 1,
            "bottles": [
              {
                "id": "steam",
                "name": "Steam",
                "path": "/bottles/steam",
                "windowsVersion": "win10",
                "pinnedPrograms": [
                  {
                    "name": "Setup",
                    "path": "/downloads/setup.exe",
                    "removable": false,
                    "iconPath": "$iconPath"
                  }
                ]
              }
            ]
          }
        ''',
        stderr: '',
      ),
    ]);

    await tester.pumpWidget(
      _testKonyakApp(
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
        iconFileLoader: _FakeIconFileLoader(
          icons: <String, Uint8List>{iconPath: _singlePixelIcoBytes()},
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('pinned-program-icon-/downloads/setup.exe')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(
          const ValueKey('pinned-program-tile-/downloads/setup.exe'),
        ),
        matching: find.byType(RawImage),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(
          const ValueKey('pinned-program-tile-/downloads/setup.exe'),
        ),
        matching: find.byIcon(Icons.web_asset_outlined),
      ),
      findsNothing,
    );
  });

  testWidgets('pinned program context menu runs and opens the program folder', (
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
                "path": "/bottles/steam",
                "windowsVersion": "win10",
                "pinnedPrograms": [
                  {
                    "name": "Setup",
                    "path": "/downloads/setup.exe",
                    "removable": false
                  }
                ]
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
              "logPath": "/bottles/steam/logs/latest.log",
              "processExitCode": 0
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
            "openedProgramLocation": {
              "bottleId": "steam",
              "programPath": "/downloads/setup.exe",
              "path": "/downloads/setup.exe"
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

    await tester.tapAt(
      tester.getCenter(
        find.byKey(const ValueKey('pinned-program-tile-/downloads/setup.exe')),
      ),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('pinned-program-context-run')), findsOne);
    expect(
      find.byKey(const ValueKey('pinned-program-context-settings-header')),
      findsOne,
    );
    expect(
      find.byKey(const ValueKey('pinned-program-context-config')),
      findsOne,
    );
    expect(
      find.byKey(const ValueKey('pinned-program-context-unpin')),
      findsOne,
    );
    expect(
      find.byKey(const ValueKey('pinned-program-context-rename')),
      findsOne,
    );
    expect(
      find.byKey(const ValueKey('pinned-program-context-show-in-finder')),
      findsOne,
    );

    await tester.tap(find.byKey(const ValueKey('pinned-program-context-run')));
    await tester.pumpAndSettle();

    await tester.tapAt(
      tester.getCenter(
        find.byKey(const ValueKey('pinned-program-tile-/downloads/setup.exe')),
      ),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('pinned-program-context-show-in-finder')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Opened Setup location'), findsOneWidget);
  });

  testWidgets('pinned program context menu opens and saves program config', (
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
                "path": "/bottles/steam",
                "windowsVersion": "win10",
                "pinnedPrograms": [
                  {
                    "name": "Setup",
                    "path": "/downloads/setup.exe",
                    "removable": false
                  }
                ]
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
            "programSettings": {
              "bottleId": "steam",
              "programPath": "/downloads/setup.exe",
              "settings": {
                "locale": "ja_JP.UTF-8",
                "arguments": "-silent",
                "environment": {
                  "STEAM_COMPAT_DATA_PATH": "/compat"
                }
              }
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
            "programSettings": {
              "bottleId": "steam",
              "programPath": "/downloads/setup.exe",
              "settings": {
                "locale": "ja_JP.UTF-8",
                "arguments": "-silent -windowed",
                "environment": {
                  "STEAM_COMPAT_DATA_PATH": "/compat"
                }
              }
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

    await tester.tapAt(
      tester.getCenter(
        find.byKey(const ValueKey('pinned-program-tile-/downloads/setup.exe')),
      ),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('pinned-program-context-config')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Setup Configuration'), findsOneWidget);
    expect(find.byKey(const ValueKey('program-config-locale')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('program-config-arguments-field')),
      findsOneWidget,
    );
    expect(find.text('STEAM_COMPAT_DATA_PATH'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('program-config-arguments-field')),
      '-silent -windowed',
    );
    await tester.tap(find.byKey(const ValueKey('program-config-save')));
    await tester.pumpAndSettle();

    expect(find.text('Saved Setup configuration'), findsOneWidget);
  });

  testWidgets('pinned program context menu renames and unpins the program', (
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
                "path": "/bottles/steam",
                "windowsVersion": "win10",
                "pinnedPrograms": [
                  {
                    "name": "Setup",
                    "path": "/downloads/setup.exe",
                    "removable": false
                  }
                ]
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
            "bottle": {
              "id": "steam",
              "name": "Steam",
              "path": "/bottles/steam",
              "windowsVersion": "win10",
              "pinnedPrograms": [
                {
                  "name": "Setup Client",
                  "path": "/downloads/setup.exe",
                  "removable": false
                }
              ]
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
            "bottle": {
              "id": "steam",
              "name": "Steam",
              "path": "/bottles/steam",
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
      ),
    );
    await tester.pumpAndSettle();

    await tester.tapAt(
      tester.getCenter(
        find.byKey(const ValueKey('pinned-program-tile-/downloads/setup.exe')),
      ),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('pinned-program-context-rename')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('rename-pinned-program-name-field')),
      'Setup Client',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Rename'));
    await tester.pumpAndSettle();

    expect(find.text('Setup Client'), findsOneWidget);

    await tester.tapAt(
      tester.getCenter(
        find.byKey(const ValueKey('pinned-program-tile-/downloads/setup.exe')),
      ),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('pinned-program-context-unpin')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Setup Client'), findsNothing);
  });

  testWidgets('run program failure shows the CLI diagnostic', (
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
                "path": "/home/user/.local/share/konyak/bottles/steam",
                "windowsVersion": "win10"
              }
            ]
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
              "code": "programRunFailed",
              "message": "Runner executable `wine` was not found.",
              "bottleId": "steam",
              "programPath": "/downloads/setup.exe",
              "runnerKind": "wine",
              "executable": "wine",
              "workingDirectory": null,
              "argv": ["wine", "/downloads/setup.exe"],
              "logPath": "/home/user/.local/share/konyak/bottles/steam/logs/latest.log"
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

    await tester.tap(find.widgetWithText(TextButton, 'Run'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Program path'),
      '/downloads/setup.exe',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Run'));
    await tester.pumpAndSettle();

    expect(
      find.text('Runner executable `wine` was not found. (wine: wine)'),
      findsOneWidget,
    );
    expect(find.byTooltip('View latest log'), findsOneWidget);
  });
}
