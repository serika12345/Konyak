part of 'widget_test.dart';

void defineMenuWinetricksAndInstalledProgramWidgetTests() {
  testWidgets('bottom bar Steam install action matches golden', (
    WidgetTester tester,
  ) async {
    await _loadKonyakTestFonts();
    final goldenKey = GlobalKey();
    final bottle = BottleSummary(
      id: 'steam',
      name: 'Steam',
      path: '/bottles/steam',
      windowsVersion: 'win10',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: konyakThemeData(konyakDarkColors),
        supportedLocales: KonyakLocalizations.supportedLocales,
        localizationsDelegates: KonyakLocalizations.localizationsDelegates,
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: RepaintBoundary(
              key: goldenKey,
              child: SizedBox(
                width: 520,
                child: KonyakBottomBar(
                  target: BottleActionTarget.bottle(bottle),
                  runProgramAction: BottleSummaryActionAvailability.available(
                    (_) {},
                  ),
                  installSteamProfileAction:
                      BottleSummaryActionAvailability.available((_) {}),
                  toolsAction: BottleToolsActionAvailability.command((_, _) {}),
                  showWinetricksAction:
                      BottleSummaryActionAvailability.available((_) {}),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await _expectGoldenFileWithinTolerance(
      find.byKey(goldenKey),
      'goldens/bottom_bar_steam_install.png',
      diffTolerance: 0.05,
    );
  });

  testWidgets('bottle utilities menu is not shown in the top bar', (
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

    expect(find.byTooltip('Bottle utilities for Steam'), findsNothing);
    expect(find.text('Installed programs'), findsNothing);
    expect(find.text('Open C drive'), findsNothing);
    expect(find.text('Open bottle folder'), findsNothing);
    expect(find.text('Wine configuration'), findsNothing);
    expect(find.text('Delete bottle'), findsNothing);
  });

  testWidgets('Linux shows File and app menus in a screen-top menu bar', (
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
              "programPath": "terminal",
              "runnerKind": "linuxTerminal",
              "executable": "sh",
              "workingDirectory": "/home/user/.local/share/konyak/bottles/steam",
              "argv": ["sh", "-lc"],
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
        platform: KonyakPlatform.linux,
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('linux-menu-bar')), findsOneWidget);
    expect(find.text('File'), findsOneWidget);
    expect(find.text('Konyak'), findsOneWidget);
    expect(find.text('Bottle'), findsNothing);
    expect(find.widgetWithText(TextButton, 'Tools'), findsOneWidget);
    final konyakMenuLeft = tester.getTopLeft(find.text('Konyak')).dx;
    final fileMenuLeft = tester.getTopLeft(find.text('File')).dx;
    expect(konyakMenuLeft, lessThan(fileMenuLeft));
    expect(find.byKey(const ValueKey('bottom-bar')), findsOneWidget);
    expect(find.byTooltip('Install macOS Wine'), findsNothing);

    final menuBottom = tester
        .getBottomLeft(find.byKey(const ValueKey('linux-menu-bar')))
        .dy;
    final sidebarTop = tester
        .getTopLeft(find.byKey(const ValueKey('sidebar-slot')))
        .dy;
    expect(menuBottom, lessThanOrEqualTo(sidebarTop));
    expect(find.byTooltip('Install macOS Wine'), findsNothing);
  });

  testWidgets(
    'Linux menu bar hosts window controls and draggable empty space',
    (WidgetTester tester) async {
      final methodCalls = <MethodCall>[];
      const channel = MethodChannel('konyak/linux_window');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            methodCalls.add(call);
            return null;
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });

      await tester.pumpWidget(
        _testKonyakApp(
          platform: KonyakPlatform.linux,
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

      final menuBar = find.byKey(const ValueKey('linux-menu-bar'));
      final dragRegion = find.byKey(const ValueKey('linux-menu-drag-region'));
      final minimizeButton = find.byTooltip('Minimize window');
      final maximizeButton = find.byTooltip('Maximize or restore window');
      final closeButton = find.byTooltip('Close window');
      final minimizeButtonFrame = find.byKey(
        const ValueKey('linux-window-minimize-button'),
      );
      final maximizeButtonFrame = find.byKey(
        const ValueKey('linux-window-maximize-button'),
      );
      final closeButtonFrame = find.byKey(
        const ValueKey('linux-window-close-button'),
      );

      expect(menuBar, findsOneWidget);
      expect(dragRegion, findsOneWidget);
      expect(minimizeButton, findsOneWidget);
      expect(maximizeButton, findsOneWidget);
      expect(closeButton, findsOneWidget);
      expect(minimizeButtonFrame, findsOneWidget);
      expect(maximizeButtonFrame, findsOneWidget);
      expect(closeButtonFrame, findsOneWidget);

      final menuTop = tester.getTopLeft(menuBar).dy;
      expect(tester.getTopLeft(dragRegion).dy, menuTop);
      expect(tester.getTopLeft(minimizeButtonFrame).dy, menuTop);
      expect(tester.getTopLeft(maximizeButtonFrame).dy, menuTop);
      expect(tester.getTopLeft(closeButtonFrame).dy, menuTop);
      expect(
        tester.getTopLeft(dragRegion).dx,
        greaterThan(tester.getTopRight(find.text('File')).dx),
      );
      expect(
        tester.getTopRight(closeButtonFrame).dx,
        tester.getTopRight(menuBar).dx,
      );
      final regionRegistrations = methodCalls
          .where((call) => call.method == 'setWindowDragRegion')
          .toList();
      expect(regionRegistrations, isNotEmpty);
      final registeredRegion =
          regionRegistrations.last.arguments as Map<Object?, Object?>;
      expect(registeredRegion['left'], tester.getTopLeft(dragRegion).dx);
      expect(registeredRegion['top'], tester.getTopLeft(dragRegion).dy);
      expect(registeredRegion['right'], tester.getBottomRight(dragRegion).dx);
      expect(registeredRegion['bottom'], tester.getBottomRight(dragRegion).dy);

      methodCalls.clear();
      final firstDrag = await tester.startGesture(tester.getCenter(dragRegion));
      await firstDrag.up();
      final secondDrag = await tester.startGesture(
        tester.getCenter(dragRegion),
      );
      await secondDrag.up();
      await tester.tap(minimizeButton);
      await tester.tap(maximizeButton);
      await tester.tap(closeButton);

      expect(methodCalls.map((call) => call.method), [
        'minimizeWindow',
        'toggleMaximizeWindow',
        'closeWindow',
      ]);
    },
  );

  testWidgets('Linux screen menu exposes the app settings command', (
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
              "defaultBottlePath": "/home/user/.local/share/konyak/bottles",
              "automaticallyCheckForKonyakUpdates": false,
              "automaticallyCheckForWineUpdates": false
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
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('linux-menu-bar')),
        matching: find.text('Konyak'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings…').last);
    await tester.pumpAndSettle();

    expect(find.text('Konyak Settings'), findsOneWidget);
  });

  testWidgets('Linux app menu command reinstalls the managed runtime', (
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
    ]);

    await tester.pumpWidget(
      _testKonyakApp(
        platform: KonyakPlatform.linux,
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('linux-menu-bar')),
        matching: find.text('Konyak'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reinstall Linux Runtime').last);
    await tester.pumpAndSettle();

    expect(find.text('Reinstalled Konyak Linux Wine'), findsOneWidget);
    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      ['install-linux-wine', '--reinstall', '--progress-json', '--json'],
    ]);
  });

  testWidgets('Linux app menu command manually checks for Konyak updates', (
    WidgetTester tester,
  ) async {
    final checkCompleter = Completer<ProcessRunResult>();
    final runner = _FutureQueuedProcessRunner([
      Future.value(
        const ProcessRunResult(
          exitCode: 0,
          stdout: '{"schemaVersion":1,"bottles":[]}',
          stderr: '',
        ),
      ),
      checkCompleter.future,
      Future.value(
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
      ),
    ]);

    await tester.pumpWidget(
      _testKonyakApp(
        platform: KonyakPlatform.linux,
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('linux-menu-bar')),
        matching: find.text('Konyak'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check for Updates…').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Checking for Konyak updates...'), findsOneWidget);
    expect(find.text('Install Konyak 1.1.0 update?'), findsNothing);

    checkCompleter.complete(
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
    );
    await tester.pumpAndSettle();

    expect(find.text('Checking for Konyak updates...'), findsNothing);
    expect(find.text('Install Konyak 1.1.0 update?'), findsOneWidget);
    expect(
      runner.argumentsLog,
      containsAllInOrder([
        const ['list-bottles', '--json'],
        const ['check-app-update', '--json'],
      ]),
    );
    expect(
      runner.argumentsLog,
      isNot(anyElement(equals(const ['install-app-update', '--json']))),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Install'));
    await tester.pumpAndSettle();

    expect(
      runner.argumentsLog,
      anyElement(equals(const ['install-app-update', '--json'])),
    );
    expect(
      find.text('Installing Konyak 1.1.0 update. Konyak will restart.'),
      findsOneWidget,
    );
  });

  testWidgets('Linux manual Konyak update check reports current status', (
    WidgetTester tester,
  ) async {
    final checkCompleter = Completer<ProcessRunResult>();
    final runner = _FutureQueuedProcessRunner([
      Future.value(
        const ProcessRunResult(
          exitCode: 0,
          stdout: '{"schemaVersion":1,"bottles":[]}',
          stderr: '',
        ),
      ),
      checkCompleter.future,
      Future.value(
        const ProcessRunResult(
          exitCode: 0,
          stdout: '{"schemaVersion":1,"runtimes":[]}',
          stderr: '',
        ),
      ),
    ]);

    await tester.pumpWidget(
      _testKonyakApp(
        platform: KonyakPlatform.linux,
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('linux-menu-bar')),
        matching: find.text('Konyak'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check for Updates…').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Checking for Konyak updates...'), findsOneWidget);
    expect(find.text('Konyak is up to date.'), findsNothing);

    checkCompleter.complete(
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
    );
    await tester.pumpAndSettle();

    expect(find.text('Checking for Konyak updates...'), findsNothing);
    expect(find.text('Konyak is up to date.'), findsOneWidget);
    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      ['check-app-update', '--json'],
      ['list-runtimes', '--json'],
    ]);
  });

  testWidgets('Linux File menu imports a bottle archive', (
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
              "windowsVersion": "win10"
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
        bottleArchivePicker: const _FakeBottleArchivePicker(
          importPath: '/imports/steam.konyak-bottle.tar',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('linux-menu-bar')),
        matching: find.text('File'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import Bottle').last);
    await tester.pumpAndSettle();

    expect(find.text('Steam'), findsWidgets);
    expect(find.text('Imported Steam'), findsOneWidget);
  });

  testWidgets('Linux screen menu exposes the about dialog', (
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
        platform: KonyakPlatform.linux,
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('linux-menu-bar')),
        matching: find.text('Konyak'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('About Konyak').last);
    await tester.pumpAndSettle();

    expect(find.text('Konyak'), findsWidgets);
    expect(find.text('Linux preview'), findsNothing);
    expect(find.text('Flutter desktop UI for Konyak.'), findsNothing);
    expect(find.text('MIT License'), findsOneWidget);
    expect(
      find.text(
        'Wine/Proton runtime binaries are downloaded after launch and remain under their own licenses.',
      ),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.text('MIT License')).dy,
      greaterThan(
        tester
            .getTopLeft(
              find.text(
                'Wine/Proton runtime binaries are downloaded after launch and remain under their own licenses.',
              ),
            )
            .dy,
      ),
    );
    expect(
      find.byWidgetPredicate((widget) {
        return widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == 'assets/icons/konyak.png';
      }),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('linux-menu-bar')), findsOneWidget);
  });

  testWidgets('Linux hides macOS runtime controls', (
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
                "windowsVersion": "win10",
                "runtimeSettings": {
                  "enhancedSync": "msync",
                  "metalHud": false,
                  "metalTrace": false,
                  "avxEnabled": false,
                  "dxrEnabled": false,
                  "dxvk": true,
                  "dxvkAsync": true,
                  "dxvkHud": "off",
                  "buildVersion": 19045,
                  "retinaMode": false,
                  "dpiScaling": 144
                }
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
                "dxvk": true,
                "dxvkAsync": true,
                "dxvkHud": "off",
                "buildVersion": 19045,
                "retinaMode": false,
                "dpiScaling": 144
              }
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
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bottle Configuration'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('linux-menu-bar')), findsOneWidget);
    expect(find.text('Wine'), findsOneWidget);
    expect(find.text('DXVK'), findsWidgets);
    expect(find.text('vkd3d-proton'), findsOneWidget);
    expect(find.text('Metal'), findsNothing);
    expect(find.text('Metal HUD'), findsNothing);
    expect(find.text('Metal Trace'), findsNothing);
    expect(find.text('High Resolution Mode'), findsNothing);
    expect(find.text('Advertise AVX Support'), findsNothing);
    expect(find.text('DXR'), findsNothing);
    expect(find.byTooltip('Install macOS Wine'), findsNothing);
    expect(
      find.byKey(const ValueKey('bottle-configuration-bottom-bar')),
      findsOneWidget,
    );
  });

  testWidgets('bottom bar opens the C drive location', (
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
              "location": "c-drive",
              "path": "/Users/user/Library/Application Support/Konyak/Bottles/Steam/drive_c"
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

    await tester.tap(find.widgetWithText(TextButton, 'Tools'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Open C: Drive'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open C: Drive'));
    await tester.pumpAndSettle();

    expect(find.text('Opened C drive'), findsOneWidget);
  });

  testWidgets('bottom bar opens a bottle terminal', (
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
              "programPath": "terminal",
              "runnerKind": "macosTerminal",
              "executable": "/usr/bin/osascript",
              "workingDirectory": null,
              "argv": ["/usr/bin/osascript", "-e", "tell application \\"Terminal\\""],
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
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Tools'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Terminal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terminal'));
    await tester.pumpAndSettle();

    expect(find.text('macosTerminal exited with code 0'), findsNothing);
  });

  testWidgets('bottom bar launches a selected winetricks verb for a bottle', (
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
            "winetricks": {
              "categories": [
                {
                  "id": "dlls",
                  "name": "DLLs",
                  "verbs": [
                    {
                      "id": "corefonts",
                      "name": "corefonts",
                      "description": "Microsoft Core Fonts"
                    }
                  ]
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
              "programPath": "corefonts",
              "runnerKind": "macosWinetricks",
              "executable": "/runtime/winetricks",
              "workingDirectory": "/runtime",
              "argv": ["/runtime/winetricks", "corefonts"],
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
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Winetricks'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('corefonts'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Run'));
    await tester.pumpAndSettle();

    expect(find.text('macosWinetricks exited with code 0'), findsNothing);
  });

  testWidgets('bottom bar installs Steam profile from a selected installer', (
    WidgetTester tester,
  ) async {
    final installCompleter = Completer<ProcessRunResult>();
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
      installCompleter.future,
      Future.value(
        const ProcessRunResult(
          exitCode: 0,
          stdout: '''
            {
              "schemaVersion": 1,
              "bottle": {
                "id": "steam",
                "name": "Steam",
                "path": "/Users/user/Library/Application Support/Konyak/Bottles/Steam",
                "windowsVersion": "win10",
                "pinnedPrograms": [
                  {
                    "name": "Steam",
                    "path": "C:\\\\Program Files (x86)\\\\Steam\\\\Steam.exe",
                    "removable": false
                  }
                ]
              }
            }
          ''',
          stderr: '',
        ),
      ),
    ]);

    await tester.pumpWidget(
      _testKonyakApp(
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
        programFilePicker: const _FakeProgramFilePicker(
          path: '/downloads/SteamSetup.exe',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Install Steam'));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('install-profile-progress')),
      findsOneWidget,
    );
    expect(find.text('Installing Steam...'), findsOneWidget);
    expect(runner.argumentsLog, [
      ['list-bottles', '--json'],
      [
        'install-profile',
        'steam',
        '--bottle',
        'steam',
        '--installer',
        '/downloads/SteamSetup.exe',
        '--json',
      ],
    ]);

    installCompleter.complete(
      const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "installedProfile": {
              "bottleId": "steam",
              "profileId": "steam",
              "profileVersion": 1,
              "installerSource": {
                "kind": "localFile",
                "path": "/downloads/SteamSetup.exe"
              },
              "steps": [
                {
                  "kind": "winetricks",
                  "id": "corefonts",
                  "runnerKind": "macosWinetricks",
                  "argv": ["/runtime/winetricks", "corefonts"],
                  "logPath": "/bottles/steam/logs/winetricks.log",
                  "processExitCode": 0
                },
                {
                  "kind": "installer",
                  "id": "/downloads/SteamSetup.exe",
                  "runnerKind": "macosWine",
                  "argv": ["/runtime/bin/wine64", "start", "/unix", "/downloads/SteamSetup.exe"],
                  "logPath": "/bottles/steam/logs/installer.log",
                  "processExitCode": 0
                }
              ],
              "programProfile": {
                "bottleId": "steam",
                "profileId": "steam",
                "profileVersion": 1,
                "managedProgramPath": "C:\\\\Program Files (x86)\\\\Steam\\\\Steam.exe",
                "compatibilityProfileId": "steam",
                "compatibilityProfileVersion": 1
              }
            }
          }
        ''',
        stderr: '',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('install-profile-progress')),
      findsNothing,
    );
    expect(find.text('Installed Steam'), findsOneWidget);
    expect(find.text('Steam'), findsWidgets);
    expect(runner.argumentsLog.last, ['inspect-bottle', 'steam', '--json']);
  });

  testWidgets('winetricks shows progress while loading the verb catalog', (
    WidgetTester tester,
  ) async {
    final listWinetricksCompleter = Completer<ProcessRunResult>();
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
      listWinetricksCompleter.future,
    ]);

    await tester.pumpWidget(
      _testKonyakApp(
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Winetricks'));
    await tester.pump();

    expect(find.byKey(const ValueKey('winetricks-progress')), findsOneWidget);
    expect(find.text('Loading winetricks packages...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);

    listWinetricksCompleter.complete(
      const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "winetricks": {
              "categories": [
                {
                  "id": "dlls",
                  "name": "DLLs",
                  "verbs": [
                    {
                      "id": "corefonts",
                      "name": "corefonts",
                      "description": "Microsoft Core Fonts"
                    }
                  ]
                }
              ]
            }
          }
        ''',
        stderr: '',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('winetricks-progress')), findsNothing);
    expect(find.text('Winetricks in Steam'), findsOneWidget);
    expect(find.text('corefonts'), findsOneWidget);
  });

  testWidgets('winetricks shows progress while installing a selected verb', (
    WidgetTester tester,
  ) async {
    final installCompleter = Completer<ProcessRunResult>();
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
      Future.value(
        const ProcessRunResult(
          exitCode: 0,
          stdout: '''
          {
            "schemaVersion": 1,
            "winetricks": {
              "categories": [
                {
                  "id": "fonts",
                  "name": "Fonts",
                  "verbs": [
                    {
                      "id": "corefonts",
                      "name": "corefonts",
                      "description": "Microsoft Core Fonts"
                    }
                  ]
                }
              ]
            }
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
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Winetricks'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('corefonts'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Run'));
    await tester.pump();

    expect(find.byKey(const ValueKey('winetricks-progress')), findsOneWidget);
    expect(find.text('Installing corefonts...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    installCompleter.complete(
      const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "run": {
              "bottleId": "steam",
              "programPath": "corefonts",
              "runnerKind": "macosWinetricks",
              "executable": "/runtime/winetricks",
              "workingDirectory": "/runtime",
              "argv": ["/runtime/winetricks", "corefonts"],
              "logPath": "/bottles/steam/logs/latest.log",
              "processExitCode": 0
            }
          }
        ''',
        stderr: '',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('winetricks-progress')), findsNothing);
  });

  testWidgets('winetricks dialog filters verbs by search query', (
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
            "winetricks": {
              "categories": [
                {
                  "id": "dlls",
                  "name": "DLLs",
                  "verbs": [
                    {
                      "id": "corefonts",
                      "name": "corefonts",
                      "description": "Microsoft Core Fonts"
                    },
                    {
                      "id": "vcrun2022",
                      "name": "vcrun2022",
                      "description": "Microsoft Visual C++ 2022 runtime"
                    }
                  ]
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

    await tester.tap(find.widgetWithText(TextButton, 'Winetricks'));
    await tester.pumpAndSettle();

    expect(find.text('corefonts'), findsOneWidget);
    expect(find.text('vcrun2022'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('winetricks-search-field')),
      'visual',
    );
    await tester.pumpAndSettle();

    expect(find.text('corefonts'), findsNothing);
    expect(find.text('vcrun2022'), findsOneWidget);
    expect(find.text('Microsoft Visual C++ 2022 runtime'), findsOneWidget);
  });

  testWidgets('action panel shows installed programs', (
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
            "bottlePrograms": {
              "bottleId": "steam",
              "programs": [
                {
                  "id": "steam-shortcut",
                  "name": "Steam",
                  "path": "/Users/user/Library/Application Support/Konyak/Bottles/Steam/drive_c/ProgramData/Microsoft/Windows/Start Menu/Programs/Steam.lnk",
                  "source": "globalStartMenu"
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

    await tester.tap(find.text('Installed Programs'));
    await tester.pumpAndSettle();

    expect(find.text('Installed programs in Steam'), findsOneWidget);
    expect(find.text('Steam'), findsWidgets);
  });

  testWidgets('installed programs dialog launches a selected shortcut', (
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
            "bottlePrograms": {
              "bottleId": "steam",
              "programs": [
                {
                  "id": "steam-shortcut",
                  "name": "Steam",
                  "path": "/bottles/steam/drive_c/ProgramData/Microsoft/Windows/Start Menu/Programs/Steam.lnk",
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
        stdout: '''
          {
            "schemaVersion": 1,
            "run": {
              "bottleId": "steam",
              "programPath": "/bottles/steam/drive_c/ProgramData/Microsoft/Windows/Start Menu/Programs/Steam.lnk",
              "runnerKind": "macosWine",
              "executable": "/runtime/bin/wine64",
              "workingDirectory": "/runtime/bin",
              "argv": ["/runtime/bin/wine64", "start", "/unix", "/bottles/steam/drive_c/ProgramData/Microsoft/Windows/Start Menu/Programs/Steam.lnk"],
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
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Installed Programs'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Run').last);
    await tester.pumpAndSettle();

    expect(find.text('macosWine exited with code 0'), findsNothing);
  });

  testWidgets('installed programs dialog pins a selected shortcut', (
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
                  "path": "/bottles/steam/drive_c/ProgramData/Microsoft/Windows/Start Menu/Programs/Steam.lnk",
                  "source": "globalStartMenu",
                  "metadata": {
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
                  "path": "/bottles/steam/drive_c/ProgramData/Microsoft/Windows/Start Menu/Programs/Steam.lnk",
                  "removable": true,
                  "iconPath": "$iconPath"
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

    await tester.tap(find.text('Installed Programs'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Pin').last);
    await tester.pumpAndSettle();

    expect(find.text('Pinned Steam'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey(
          'pinned-program-tile-/bottles/steam/drive_c/ProgramData/Microsoft/Windows/Start Menu/Programs/Steam.lnk',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey(
          'pinned-program-icon-/bottles/steam/drive_c/ProgramData/Microsoft/Windows/Start Menu/Programs/Steam.lnk',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(
          const ValueKey(
            'pinned-program-tile-/bottles/steam/drive_c/ProgramData/Microsoft/Windows/Start Menu/Programs/Steam.lnk',
          ),
        ),
        matching: find.byType(RawImage),
      ),
      findsOneWidget,
    );
  });
}
