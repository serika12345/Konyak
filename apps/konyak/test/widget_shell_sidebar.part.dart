part of 'widget_test.dart';

void defineShellAndSidebarWidgetTests() {
  testWidgets('renders the initial Konyak desktop shell', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _testKonyakApp(
        cliClient: KonyakCliClient(
          executable: 'konyak',
          processRunner: _QueuedProcessRunner([
            const ProcessRunResult(
              exitCode: 0,
              stdout: '{"schemaVersion":1,"bottles":[]}',
              stderr: '',
            ),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Toggle sidebar'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Search'), findsOneWidget);
    expect(find.text('Bottles'), findsOneWidget);
    expect(find.text('No bottles yet'), findsOneWidget);
    expect(find.byTooltip('Create bottle'), findsOneWidget);
    expect(find.byTooltip('Refresh bottles'), findsOneWidget);

    expect(find.text('Flutter Demo'), findsNothing);
  });

  testWidgets('uses Inter as the bundled UI font', (WidgetTester tester) async {
    await tester.pumpWidget(
      _testKonyakApp(
        cliClient: KonyakCliClient(
          executable: 'konyak',
          processRunner: _QueuedProcessRunner([
            const ProcessRunResult(
              exitCode: 0,
              stdout: '{"schemaVersion":1,"bottles":[]}',
              stderr: '',
            ),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold));

    expect(Theme.of(context).textTheme.bodyMedium?.fontFamily, 'Inter');
  });

  testWidgets(
    'uses the current Konyak colors as the dark appearance by default',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _testKonyakApp(
          cliClient: KonyakCliClient(
            executable: 'konyak',
            processRunner: _QueuedProcessRunner([
              const ProcessRunResult(
                exitCode: 0,
                stdout: '{"schemaVersion":1,"bottles":[]}',
                stderr: '',
              ),
            ]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold));
      final colors = KonyakThemeColors.of(context);

      expect(Theme.of(context).brightness, Brightness.dark);
      expect(colors.windowBackground, const Color(0xff282828));
      expect(colors.sidebarBackground, const Color(0xff444443));
      expect(colors.text, const Color(0xffe6e6e6));
    },
  );

  testWidgets('applies the persisted light appearance at startup', (
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
              "appearanceMode": "light",
              "automaticallyCheckForKonyakUpdates": false,
              "automaticallyCheckForWineUpdates": false
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
        enableBackgroundServices: true,
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold));
    final colors = KonyakThemeColors.of(context);

    expect(Theme.of(context).brightness, Brightness.light);
    expect(colors.windowBackground, const Color(0xfff7f7f5));
    expect(colors.sidebarBackground, const Color(0xffe9e9e4));
    expect(colors.text, const Color(0xff24211f));
  });

  testWidgets('keeps primary shell labels at regular text weight', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _testKonyakApp(
        cliClient: KonyakCliClient(
          executable: 'konyak',
          processRunner: _QueuedProcessRunner([
            const ProcessRunResult(
              exitCode: 0,
              stdout: '{"schemaVersion":1,"bottles":[]}',
              stderr: '',
            ),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(_fontWeightForText(tester, 'Konyak'), _regularTextWeight);
    expect(_fontWeightForText(tester, 'Bottles'), _regularTextWeight);
    expect(_fontWeightForText(tester, 'No Bottles'), _regularTextWeight);
    expect(_fontWeightForText(tester, 'No bottles yet'), _regularTextWeight);

    final toolsButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Tools'),
    );
    final toolsStyle = toolsButton.style?.textStyle?.resolve({
      WidgetState.disabled,
    });

    expect(toolsStyle?.fontWeight, _regularTextWeight);
  });

  testWidgets(
    'places sidebar toggle before search without fake window buttons',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _testKonyakApp(
          cliClient: KonyakCliClient(
            executable: 'konyak',
            processRunner: _QueuedProcessRunner([
              const ProcessRunResult(
                exitCode: 0,
                stdout: '{"schemaVersion":1,"bottles":[]}',
                stderr: '',
              ),
            ]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_windowControlDotFinder(const Color(0xffff5f57)), findsNothing);
      expect(_windowControlDotFinder(const Color(0xffffbd2e)), findsNothing);
      expect(_windowControlDotFinder(const Color(0xff28c840)), findsNothing);

      final searchCenter = tester.getCenter(
        find.widgetWithText(TextField, 'Search'),
      );
      final toggleCenter = tester.getCenter(find.byTooltip('Toggle sidebar'));

      expect((searchCenter.dy - toggleCenter.dy).abs(), lessThan(4));
      expect(toggleCenter.dx, lessThan(searchCenter.dx));
    },
  );

  testWidgets('macOS sidebar reserves titlebar control space', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _testSidebar(reserveLeadingWindowControlsSpace: true),
    );

    expect(
      tester.getTopLeft(find.byTooltip('Toggle sidebar')).dy,
      greaterThanOrEqualTo(52),
    );
    expect(
      tester.getTopLeft(find.widgetWithText(TextField, 'Search')).dy,
      greaterThanOrEqualTo(52),
    );
  });

  testWidgets('default sidebar keeps compact top padding', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _testSidebar(reserveLeadingWindowControlsSpace: false),
    );

    expect(
      tester.getTopLeft(find.byTooltip('Toggle sidebar')).dy,
      lessThan(32),
    );
    expect(
      tester.getTopLeft(find.widgetWithText(TextField, 'Search')).dy,
      lessThan(32),
    );
  });

  testWidgets('sidebar toggle hides and restores the sidebar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _testKonyakApp(
        cliClient: KonyakCliClient(
          executable: 'konyak',
          processRunner: _QueuedProcessRunner([
            const ProcessRunResult(
              exitCode: 0,
              stdout: '{"schemaVersion":1,"bottles":[]}',
              stderr: '',
            ),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Search'), findsOneWidget);
    expect(find.text('Bottles'), findsOneWidget);

    await tester.tap(find.byTooltip('Toggle sidebar'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Search'), findsNothing);
    expect(find.text('Bottles'), findsNothing);
    expect(find.byTooltip('Toggle sidebar'), findsOneWidget);

    await tester.tap(find.byTooltip('Toggle sidebar'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Search'), findsOneWidget);
    expect(find.text('Bottles'), findsOneWidget);
  });

  testWidgets('animates sidebar width when toggled', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _testKonyakApp(
        cliClient: KonyakCliClient(
          executable: 'konyak',
          processRunner: _QueuedProcessRunner([
            const ProcessRunResult(
              exitCode: 0,
              stdout: '{"schemaVersion":1,"bottles":[]}',
              stderr: '',
            ),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(_sidebarWidth(tester), _expandedSidebarWidth);

    await tester.tap(find.byTooltip('Toggle sidebar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));

    expect(_sidebarWidth(tester), lessThan(_expandedSidebarWidth));
    expect(_sidebarWidth(tester), greaterThan(_collapsedSidebarWidth));

    await tester.pumpAndSettle();

    expect(_sidebarWidth(tester), _collapsedSidebarWidth);

    await tester.tap(find.byTooltip('Toggle sidebar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));

    expect(_sidebarWidth(tester), greaterThan(_collapsedSidebarWidth));
    expect(_sidebarWidth(tester), lessThan(_expandedSidebarWidth));

    await tester.pumpAndSettle();

    expect(_sidebarWidth(tester), _expandedSidebarWidth);
  });

  testWidgets('active bottle layout fits within the Konyak minimum window', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(600, 316);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

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
                      "path": "/home/user/.local/share/konyak/bottles/steam",
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

    expect(tester.takeException(), isNull);
    expect(find.text('Pin Program'), findsOneWidget);
    expect(find.text('Bottle Configuration'), findsOneWidget);

    final actionPanelBottom = tester
        .getBottomLeft(find.byKey(const ValueKey('bottle-action-panel')))
        .dy;
    final bottomBarTop = tester
        .getTopLeft(find.byKey(const ValueKey('bottom-bar')))
        .dy;

    expect(actionPanelBottom, lessThanOrEqualTo(bottomBarTop));
    expect(
      tester.getTopRight(find.widgetWithText(TextButton, 'Run')).dx,
      lessThanOrEqualTo(tester.view.physicalSize.width),
    );
    for (final label in ['Tools', 'Winetricks', 'Run']) {
      expect(
        tester.widget<Text>(find.text(label)).overflow,
        isNot(TextOverflow.ellipsis),
      );
    }
  });

  testWidgets('Bottle Tools groups bottle utility launchers', (
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
            "run": {
              "bottleId": "steam",
              "programPath": "wineboot",
              "runnerKind": "macosWine",
              "executable": "/runtime/bin/wineloader",
              "workingDirectory": "/runtime/bin",
              "argv": ["/runtime/bin/wineloader", "wineboot", "--restart"],
              "logPath": "/Users/user/Library/Application Support/Konyak/Bottles/Steam/logs/latest.log",
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
            "run": {
              "bottleId": "steam",
              "programPath": "cmd",
              "runnerKind": "macosTerminal",
              "executable": "/usr/bin/osascript",
              "workingDirectory": null,
              "argv": ["/usr/bin/osascript", "-e", "tell application \\"Terminal\\""],
              "logPath": "/Users/user/Library/Application Support/Konyak/Bottles/Steam/logs/latest.log",
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

    expect(find.widgetWithText(TextButton, 'Tools'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Open C: Drive'), findsNothing);
    expect(find.widgetWithText(TextButton, 'Terminal'), findsNothing);
    expect(find.widgetWithText(TextButton, 'Winetricks'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Tools'));
    await tester.pumpAndSettle();

    expect(find.text('Tools for Steam'), findsOneWidget);
    expect(find.text('Open Wine Configuration'), findsOneWidget);
    expect(find.text('Registry Editor'), findsOneWidget);
    expect(find.text('Control Panel'), findsOneWidget);
    expect(find.text('Terminal'), findsOneWidget);
    expect(find.text('Command Prompt'), findsOneWidget);
    expect(find.text('Uninstall Programs'), findsOneWidget);
    expect(find.text('Simulate Reboot'), findsOneWidget);
    expect(find.text('DirectX Diagnostic Report'), findsOneWidget);
    expect(find.text('Open C: Drive'), findsOneWidget);
    expect(find.text('Open Bottle Folder'), findsOneWidget);

    await tester.tap(find.text('Command Prompt'));
    await tester.pumpAndSettle();

    expect(runner.argumentsLog[1], const [
      'run-bottle-command',
      'steam',
      '--command',
      'cmd',
      '--json',
    ]);
    ScaffoldMessenger.of(
      tester.element(find.byType(Scaffold)),
    ).hideCurrentSnackBar();
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Tools'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simulate Reboot'));
    await tester.pumpAndSettle();

    expect(runner.argumentsLog[2], const [
      'run-bottle-command',
      'steam',
      '--command',
      'simulate-reboot',
      '--json',
    ]);
    ScaffoldMessenger.of(
      tester.element(find.byType(Scaffold)),
    ).hideCurrentSnackBar();
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Tools'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Open Bottle Folder'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open Bottle Folder'));
    await tester.pumpAndSettle();

    expect(runner.argumentsLog[3], const [
      'open-bottle-location',
      'steam',
      '--location',
      'root',
      '--json',
    ]);
    expect(find.text('Opened bottle folder'), findsOneWidget);
  });

  testWidgets('Uninstall Programs refreshes removed pinned programs', (
    WidgetTester tester,
  ) async {
    const pinnedShortcutPath =
        '/Users/user/Library/Application Support/Konyak/Bottles/Steam/drive_c/ProgramData/Microsoft/Windows/Start Menu/Programs/Uninstall Steam.lnk';
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
                "path": "/Users/user/Library/Application Support/Konyak/Bottles/Steam",
                "windowsVersion": "win10",
                "pinnedPrograms": [
                  {
                    "name": "Uninstall Steam",
                    "path": "$pinnedShortcutPath",
                    "removable": true
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
              "programPath": "uninstaller",
              "runnerKind": "macosWine",
              "executable": "/runtime/bin/wine64",
              "workingDirectory": "/runtime/bin",
              "argv": ["/runtime/bin/wine64", "uninstaller"],
              "logPath": "/Users/user/Library/Application Support/Konyak/Bottles/Steam/logs/latest.log",
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
            "bottle": {
              "id": "steam",
              "name": "Steam",
              "path": "/Users/user/Library/Application Support/Konyak/Bottles/Steam",
              "windowsVersion": "win10"
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
    ]);

    await tester.pumpWidget(
      _testKonyakApp(
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('pinned-program-tile-$pinnedShortcutPath')),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(TextButton, 'Tools'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uninstall Programs'));
    await tester.pumpAndSettle();

    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      ['run-bottle-command', 'steam', '--command', 'uninstaller', '--json'],
      ['inspect-bottle', 'steam', '--json'],
      ['list-runtimes', '--json'],
    ]);
    expect(
      find.byKey(const ValueKey('pinned-program-tile-$pinnedShortcutPath')),
      findsNothing,
    );
  });

  testWidgets('Bottle Tools shows progress while launching a GUI utility', (
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
                "path": "/Users/user/Library/Application Support/Konyak/Bottles/Steam",
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

    await tester.tap(find.widgetWithText(TextButton, 'Tools'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open Wine Configuration'));
    await tester.pump(const Duration(milliseconds: 250));

    expect(runner.argumentsLog[1], const [
      'run-bottle-command',
      'steam',
      '--command',
      'winecfg',
      '--json',
    ]);
    expect(
      find.byKey(const ValueKey('program-launch-progress')),
      findsOneWidget,
    );
    expect(find.text('Launching program...'), findsOneWidget);

    runCompleter.complete(
      const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "run": {
              "bottleId": "steam",
              "programPath": "winecfg",
              "runnerKind": "macosWine",
              "executable": "/runtime/bin/wine64",
              "workingDirectory": "/runtime/bin",
              "argv": ["/runtime/bin/wine64", "winecfg"],
              "logPath": "/Users/user/Library/Application Support/Konyak/Bottles/Steam/logs/latest.log",
              "processExitCode": 0
            }
          }
        ''',
        stderr: '',
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('program-launch-progress')), findsNothing);
    expect(find.byTooltip('View latest log'), findsOneWidget);
  });
}
