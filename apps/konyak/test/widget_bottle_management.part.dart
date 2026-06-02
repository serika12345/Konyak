part of 'widget_test.dart';

void defineBottleManagementWidgetTests() {
  testWidgets('right-clicking a bottle row shows the Konyak context menu', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _testKonyakApp(
        cliClient: KonyakCliClient(
          executable: 'konyak',
          processRunner: _QueuedProcessRunner([
            const ProcessRunResult(
              exitCode: 0,
              stdout: '''
                {
                  "schemaVersion": 1,
                  "bottles": [
                    {
                      "id": "steam",
                      "name": "Steam",
                      "path": "/Users/user/Library/Application Support/Konyak/Bottles/Steam",
                      "windowsVersion": "win10"
                    }
                  ]
                }
              ''',
              stderr: '',
            ),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey('sidebar-bottle-steam'))),
      buttons: kSecondaryMouseButton,
    );
    await tester.pump();

    expect(find.text('Rename...'), findsOneWidget);
    expect(find.text('Remove...'), findsOneWidget);
    expect(find.text('Move...'), findsOneWidget);
    expect(find.text('Export as Archive...'), findsOneWidget);
    expect(find.text('Stop All Processes'), findsOneWidget);
    expect(find.text('Show in Finder'), findsOneWidget);
  });

  testWidgets('bottle context menu stops all Wine processes in the bottle', (
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
                "path": "/Users/user/Library/Application Support/Konyak/Bottles/Steam",
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
            "wineProcessTermination": {
              "hasFailures": false,
              "bottles": [
                {
                  "bottleId": "steam",
                  "status": "terminated",
                  "runnerKind": "wineserver",
                  "executable": "wineserver",
                  "argv": ["wineserver", "-k"],
                  "processExitCode": 0
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

    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey('sidebar-bottle-steam'))),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stop All Processes'));
    await tester.pumpAndSettle();

    expect(find.text('Stopped processes in Steam'), findsOneWidget);
  });

  testWidgets('bottle context menu opens the bottle folder', (
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
                "path": "/Users/user/Library/Application Support/Konyak/Bottles/Steam",
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
            "openedLocation": {
              "bottleId": "steam",
              "location": "root",
              "path": "/Users/user/Library/Application Support/Konyak/Bottles/Steam"
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
      tester.getCenter(find.byKey(const ValueKey('sidebar-bottle-steam'))),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show in Finder'));
    await tester.pumpAndSettle();

    expect(find.text('Opened bottle folder'), findsOneWidget);
  });

  testWidgets('bottle context menu exports a bottle archive', (
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
            "bottleArchive": {
              "bottleId": "steam",
              "archivePath": "/exports/steam.konyak-bottle.tar"
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
          exportPath: '/exports/steam.konyak-bottle.tar',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey('sidebar-bottle-steam'))),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Export as Archive...'));
    await tester.pumpAndSettle();

    expect(find.text('Exported Steam'), findsOneWidget);
  });

  testWidgets('bottle context menu removes a bottle through confirmation', (
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
            "deletedBottle": {
              "id": "steam",
              "name": "Steam",
              "path": "/home/user/.local/share/konyak/bottles/steam",
              "windowsVersion": "win10"
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

    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey('sidebar-bottle-steam'))),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove...'));
    await tester.pumpAndSettle();

    expect(find.text('Delete Steam?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Deleted Steam'), findsOneWidget);
  });

  testWidgets('bottle context menu renames a bottle', (
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
            "bottle": {
              "id": "steam-games",
              "name": "Steam Games",
              "path": "/home/user/.local/share/konyak/bottles/steam-games",
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
      tester.getCenter(find.byKey(const ValueKey('sidebar-bottle-steam'))),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename...'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('rename-bottle-name-field')),
      'Steam Games',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Rename'));
    await tester.pumpAndSettle();

    expect(find.text('Steam'), findsNothing);
    expect(find.text('Steam Games'), findsWidgets);
  });

  testWidgets('bottle context menu moves a bottle', (
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
            "bottle": {
              "id": "steam",
              "name": "Steam",
              "path": "/mnt/games/Steam",
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
        directoryPicker: const _FakeDirectoryPicker(path: null),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey('sidebar-bottle-steam'))),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move...'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('move-bottle-path-field')),
      '/mnt/games/Steam',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Move'));
    await tester.pumpAndSettle();

    expect(find.text('Moved Steam'), findsOneWidget);
  });

  testWidgets('loads bottle rows through the CLI client', (
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
    ]);

    await tester.pumpWidget(
      _testKonyakApp(
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Steam'), findsWidgets);
    expect(find.text('Windows 10'), findsNothing);
    expect(find.text('No bottles yet'), findsNothing);
    expect(find.text('Pin Program'), findsOneWidget);
    expect(find.text('Installed Programs'), findsOneWidget);
    expect(find.text('Bottle Configuration'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Open C: Drive'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Run'), findsOneWidget);
  });

  testWidgets('process manager lists Wine processes with icons and kills one', (
    WidgetTester tester,
  ) async {
    const iconPath = '/icons/steam.ico';
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
              },
              {
                "id": "tools",
                "name": "Tools",
                "path": "/home/user/.local/share/konyak/bottles/tools",
                "windowsVersion": "win10"
              }
            ]
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
            "wineProcesses": {
              "processes": [
                {
                  "bottleId": "steam",
                  "processId": "00000034",
                  "executable": "C:\\\\Program Files\\\\Steam\\\\steam.exe",
                  "hostPath": "/home/user/.local/share/konyak/bottles/steam/drive_c/Program Files/Steam/steam.exe",
                  "metadata": {
                    "fileDescription": "Steam Client",
                    "iconPath": "$iconPath"
                  }
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
            "wineProcessTermination": {
              "hasFailures": false,
              "processes": [
                {
                  "bottleId": "steam",
                  "processId": "00000034",
                  "status": "terminated",
                  "runnerKind": "winedbg",
                  "executable": "winedbg",
                  "argv": ["winedbg", "--command", "kill", "00000034"],
                  "processExitCode": 0
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
        iconFileLoader: _FakeIconFileLoader(
          icons: <String, Uint8List>{iconPath: _singlePixelIcoBytes()},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Process Manager'), findsNothing);
    expect(find.byTooltip('Process Manager'), findsOneWidget);
    await tester.tap(find.byTooltip('Process Manager'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('process-manager-dialog')),
      findsOneWidget,
    );
    expect(find.text('Steam Client'), findsOneWidget);
    expect(find.textContaining('Steam - 00000034'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(
          const ValueKey('process-manager-process-steam-00000034'),
        ),
        matching: find.byType(RawImage),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('process-manager-kill-steam-00000034')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Terminated Steam Client'), findsOneWidget);
  });

  testWidgets('refresh reloads the bottle list through the CLI client', (
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
    ]);

    await tester.pumpWidget(
      _testKonyakApp(
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No bottles yet'), findsOneWidget);

    await tester.tap(find.byTooltip('Refresh bottles'));
    await tester.pumpAndSettle();

    expect(find.text('Steam'), findsWidgets);
  });

  testWidgets('create bottle dialog invokes the CLI and adds the bottle', (
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
              "path": "/home/user/.local/share/konyak/bottles/steam",
              "windowsVersion": "win81"
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

    await tester.tap(find.byTooltip('Create bottle'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Steam');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Windows 10'));
    await tester.pumpAndSettle();
    expect(find.text('Windows XP'), findsOneWidget);
    expect(find.text('Windows 7'), findsOneWidget);
    expect(find.text('Windows 8'), findsOneWidget);
    expect(find.text('Windows 8.1'), findsOneWidget);
    expect(find.text('Windows 10'), findsWidgets);
    expect(find.text('Windows 11'), findsOneWidget);
    await tester.tap(find.text('Windows 8.1').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();

    expect(find.text('Steam'), findsWidgets);
  });

  testWidgets('create bottle shows progress while the CLI is running', (
    WidgetTester tester,
  ) async {
    final createBottleCompleter = Completer<ProcessRunResult>();
    final runner = _FutureQueuedProcessRunner([
      Future.value(
        const ProcessRunResult(
          exitCode: 0,
          stdout: '{"schemaVersion":1,"bottles":[]}',
          stderr: '',
        ),
      ),
      createBottleCompleter.future,
    ]);

    await tester.pumpWidget(
      _testKonyakApp(
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Create bottle'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Steam');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('create-bottle-progress')),
      findsOneWidget,
    );
    expect(find.text('Creating bottle...'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('Creating bottle...'),
        matching: find.byType(Material),
      ),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);

    createBottleCompleter.complete(
      const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "bottle": {
              "id": "steam",
              "name": "Steam",
              "path": "/home/user/.local/share/konyak/bottles/steam",
              "windowsVersion": "win10"
            }
          }
        ''',
        stderr: '',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('create-bottle-progress')), findsNothing);
    expect(find.text('Steam'), findsWidgets);
  });

  testWidgets('changes a bottle Windows version through runtime settings', (
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
            "bottle": {
              "id": "steam",
              "name": "Steam",
              "path": "/home/user/.local/share/konyak/bottles/steam",
              "windowsVersion": "win10",
              "runtimeSettings": {
                "enhancedSync": "msync",
                "metalHud": false,
                "metalTrace": false,
                "avxEnabled": false,
                "dxrEnabled": false,
                "dxvk": false,
                "dxvkAsync": true,
                "dxvkHud": "off",
                "buildVersion": 19045,
                "retinaMode": false,
                "dpiScaling": 96
              }
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
            "bottle": {
              "id": "steam",
              "name": "Steam",
              "path": "/home/user/.local/share/konyak/bottles/steam",
              "windowsVersion": "win10",
              "runtimeSettings": {
                "enhancedSync": "msync",
                "metalHud": false,
                "metalTrace": false,
                "avxEnabled": false,
                "dxrEnabled": false,
                "dxvk": false,
                "dxvkAsync": true,
                "dxvkHud": "off",
                "buildVersion": 7601,
                "retinaMode": false,
                "dpiScaling": 96
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

    await tester.tap(find.text('Bottle Configuration'));
    await tester.pumpAndSettle();
    expect(find.text('Windows Version'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('config-windows-version')));
    await tester.pumpAndSettle();
    expect(find.text('Windows XP x64 (3790)'), findsOneWidget);
    expect(find.text('Windows 7 SP1 (7601)'), findsOneWidget);
    expect(find.text('Windows 8 (9200)'), findsOneWidget);
    expect(find.text('Windows 8.1 (9600)'), findsOneWidget);
    expect(find.text('Windows 10 22H2 (19045)'), findsWidgets);
    expect(find.text('Windows 11 24H2 (26100)'), findsOneWidget);
    await tester.tap(find.text('Windows 7 SP1 (7601)').last);
    await tester.pumpAndSettle();

    expect(runner.argumentsLog[3].take(3).toList(growable: false), const [
      'set-runtime-settings',
      'steam',
      '--settings-json',
    ]);
    expect(runner.argumentsLog[3].last, '--json');
    final settings =
        jsonDecode(runner.argumentsLog[3][3]) as Map<String, Object?>;
    expect(settings, containsPair('buildVersion', 7601));
    expect(find.text('Windows 7 SP1 (7601)'), findsOneWidget);
  });

  testWidgets('delete bottle confirms and removes the bottle', (
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
            "deletedBottle": {
              "id": "steam",
              "name": "Steam",
              "path": "/home/user/.local/share/konyak/bottles/steam",
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
      tester.getCenter(find.byKey(const ValueKey('sidebar-bottle-steam'))),
      buttons: kSecondaryMouseButton,
    );
    await tester.pump();
    await tester.tap(find.text('Remove...'));
    await tester.pumpAndSettle();

    expect(find.text('Delete Steam?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Deleted Steam'), findsOneWidget);
    expect(find.text('No bottles yet'), findsOneWidget);
  });
}
