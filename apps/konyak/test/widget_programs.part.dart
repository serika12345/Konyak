part of 'widget_test.dart';

void defineProgramWidgetTests() {
  testWidgets('Japanese pin program action keeps the requested line break', (
    WidgetTester tester,
  ) async {
    await _loadKonyakTestFonts();
    await tester.binding.setSurfaceSize(const Size(180, 180));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final goldenKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ja'),
        supportedLocales: KonyakLocalizations.supportedLocales,
        localizationsDelegates: KonyakLocalizations.localizationsDelegates,
        theme: konyakThemeData(konyakDarkColors),
        home: Scaffold(
          backgroundColor: konyakDarkColors.windowBackground,
          body: Center(
            child: RepaintBoundary(
              key: goldenKey,
              child: PinProgramAction(
                bottle: BottleSummary(
                  id: 'steam',
                  name: 'Steam',
                  path: '/bottles/steam',
                  windowsVersion: 'win10',
                ),
                pinProgramAction: BottleSummaryActionAvailability.available(
                  (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('プログラムを\nピン留め'), findsOneWidget);
    await _expectGoldenFileWithinTolerance(
      find.byKey(goldenKey),
      'goldens/pin_program_action_ja.png',
      diffTolerance: 0.11,
    );
  });

  testWidgets('run program dialog shows expandable launch options', (
    WidgetTester tester,
  ) async {
    await _loadKonyakTestFonts();
    await tester.binding.setSurfaceSize(const Size(640, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final goldenKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        supportedLocales: KonyakLocalizations.supportedLocales,
        localizationsDelegates: KonyakLocalizations.localizationsDelegates,
        theme: konyakThemeData(konyakDarkColors),
        home: Scaffold(
          backgroundColor: konyakDarkColors.windowBackground,
          body: Center(
            child: RepaintBoundary(
              key: goldenKey,
              child: const RunProgramDialog(
                bottleName: 'Steam',
                programFilePicker: _FakeProgramFilePicker(path: null),
                initialDirectory: '/bottles/steam/drive_c',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Options'), findsOneWidget);
    expect(find.text('Details'), findsNothing);
    expect(find.text('Arguments'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('run-program-options-toggle')));
    await tester.pumpAndSettle();

    expect(find.text('Arguments'), findsOneWidget);
    expect(find.text('Locale'), findsOneWidget);
    expect(find.text('Working directory'), findsOneWidget);
    expect(find.byKey(const ValueKey('run-program-locale')), findsOneWidget);
    expect(find.text('Environment'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('run-program-arguments-field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('run-program-add-environment')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('run-program-create-log-file')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('run-program-wine-logging-channels-field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('run-program-log-file-path-field')),
      findsOneWidget,
    );
    await _expectGoldenFileWithinTolerance(
      find.byKey(goldenKey),
      'goldens/run_program_dialog_options.png',
      diffTolerance: 0.11,
    );
  });

  testWidgets('run program dialog displays graphics backend hints', (
    WidgetTester tester,
  ) async {
    await _loadKonyakTestFonts();
    await tester.binding.setSurfaceSize(const Size(640, 520));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final goldenKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        supportedLocales: KonyakLocalizations.supportedLocales,
        localizationsDelegates: KonyakLocalizations.localizationsDelegates,
        theme: konyakThemeData(konyakDarkColors),
        home: Scaffold(
          backgroundColor: konyakDarkColors.windowBackground,
          body: Center(
            child: RepaintBoundary(
              key: goldenKey,
              child: RunProgramDialog(
                bottleName: 'Steam',
                programFilePicker: const _FakeProgramFilePicker(path: null),
                initialDirectory: '/bottles/steam/drive_c',
                graphicsBackendHintsLoader: (_) async =>
                    LoadedGraphicsBackendHints(
                      ProgramGraphicsBackendHintsSummary(
                        programPath: '/downloads/game.exe',
                        hostPlatform: 'macos',
                        signals: const [
                          ProgramGraphicsBackendSignalSummary(
                            kind: 'peImport',
                            value: 'd3d12.dll',
                          ),
                          ProgramGraphicsBackendSignalSummary(
                            kind: 'peImport',
                            value: 'dxgi.dll',
                          ),
                        ],
                        suggestions: const [
                          ProgramGraphicsBackendSuggestionSummary(
                            backend: 'd3dMetal',
                            confidence: 'high',
                            reason: 'D3D12 API usage was detected.',
                          ),
                        ],
                      ),
                    ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Program path'),
      '/downloads/game.exe',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('run-program-graphics-hint-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Graphics backend hint'), findsOneWidget);
    expect(find.text('Recommended: GPTK/D3DMetal'), findsOneWidget);
    expect(find.text('Detected: d3d12.dll, dxgi.dll'), findsOneWidget);
    await _expectGoldenFileWithinTolerance(
      find.byKey(goldenKey),
      'goldens/run_program_dialog_graphics_hint.png',
      diffTolerance: 0.11,
    );
  });

  testWidgets('run program refreshes removed pinned programs after completion', (
    WidgetTester tester,
  ) async {
    const pinnedShortcutPath =
        '/bottles/steam/drive_c/ProgramData/Microsoft/Windows/Start Menu/Programs/Uninstall Steam.lnk';
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
        stdout:
            '''
          {
            "schemaVersion": 1,
            "run": {
              "bottleId": "steam",
              "programPath": "$pinnedShortcutPath",
              "runnerKind": "wine",
              "executable": "wine",
              "workingDirectory": null,
              "argv": ["wine", "$pinnedShortcutPath"],
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

    expect(
      find.byKey(const ValueKey('pinned-program-tile-$pinnedShortcutPath')),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(TextButton, 'Run'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Program path'),
      pinnedShortcutPath,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Run'));
    await tester.pumpAndSettle();

    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      ['run-program', 'steam', '--program', pinnedShortcutPath, '--json'],
      ['inspect-bottle', 'steam', '--json'],
    ]);
    expect(
      find.byKey(const ValueKey('pinned-program-tile-$pinnedShortcutPath')),
      findsNothing,
    );
  });

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

  testWidgets(
    'run program dialog requests graphics backend hints from the CLI',
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
            "graphicsBackendHints": {
              "programPath": "/downloads/game.exe",
              "hostPlatform": "macos",
              "signals": [
                {"kind": "peImport", "value": "d3d12.dll"}
              ],
              "suggestions": [
                {
                  "backend": "d3dMetal",
                  "confidence": "high",
                  "reason": "D3D12 API usage was detected."
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
          cliClient: KonyakCliClient(
            executable: 'konyak',
            processRunner: runner,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Run'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Program path'),
        '/downloads/game.exe',
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('run-program-graphics-hint-button')),
      );
      await tester.pumpAndSettle();

      expect(runner.argumentsLog, const [
        ['list-bottles', '--json'],
        [
          'suggest-graphics-backend',
          '--program',
          '/downloads/game.exe',
          '--json',
        ],
      ]);
      expect(find.text('Recommended: GPTK/D3DMetal'), findsOneWidget);
    },
  );

  testWidgets('run program dialog sends one-time arguments and environment', (
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
              "argv": ["wine", "/downloads/setup.exe", "-windowed"],
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
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Run'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Program path'),
      '/downloads/setup.exe',
    );
    await tester.tap(find.byKey(const ValueKey('run-program-options-toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('run-program-locale')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Japanese').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('run-program-arguments-field')),
      '-windowed',
    );
    final addEnvironment = find.byKey(
      const ValueKey('run-program-add-environment'),
    );
    await tester.ensureVisible(addEnvironment);
    await tester.tap(addEnvironment);
    await tester.pumpAndSettle();
    final environmentName = find.byKey(const ValueKey('run-program-env-key-0'));
    await tester.ensureVisible(environmentName);
    await tester.enterText(environmentName, 'WINEDEBUG');
    await tester.enterText(
      find.byKey(const ValueKey('run-program-env-value-0')),
      '+seh',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Run'));
    await tester.pumpAndSettle();

    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      [
        'run-program',
        'steam',
        '--program',
        '/downloads/setup.exe',
        '--settings-json',
        '{"locale":"ja_JP.UTF-8","arguments":"-windowed","environment":{"WINEDEBUG":"+seh"}}',
        '--json',
      ],
    ]);
  });

  testWidgets('run program passes one-time logging options to the CLI', (
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
              "logPath": "/tmp/setup.cxlog",
              "logFileCreated": true,
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

    await tester.tap(find.widgetWithText(TextButton, 'Run'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Program path'),
      '/downloads/setup.exe',
    );
    await tester.tap(find.byKey(const ValueKey('run-program-options-toggle')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('run-program-wine-logging-channels-field')),
      '+relay',
    );
    await tester.enterText(
      find.byKey(const ValueKey('run-program-log-file-path-field')),
      '/tmp/setup.cxlog',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Run'));
    await tester.pumpAndSettle();

    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      [
        'run-program',
        'steam',
        '--program',
        '/downloads/setup.exe',
        '--settings-json',
        '{"locale":"","arguments":"","environment":{},"logging":{"createLogFile":true,"additionalWineLoggingChannels":"+relay","logFilePath":"/tmp/setup.cxlog"}}',
        '--json',
      ],
    ]);
  });

  testWidgets('program configuration view displays logging controls', (
    WidgetTester tester,
  ) async {
    await _loadKonyakTestFonts();
    await tester.binding.setSurfaceSize(const Size(820, 680));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final goldenKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        supportedLocales: KonyakLocalizations.supportedLocales,
        localizationsDelegates: KonyakLocalizations.localizationsDelegates,
        theme: konyakThemeData(konyakDarkColors),
        home: Scaffold(
          backgroundColor: konyakDarkColors.windowBackground,
          body: Center(
            child: SizedBox(
              width: 620,
              height: 620,
              child: RepaintBoundary(
                key: goldenKey,
                child: ProgramConfigurationView(
                  bottle: BottleSummary(
                    id: 'steam',
                    name: 'Steam',
                    path: '/bottles/steam',
                    windowsVersion: 'win10',
                  ),
                  program: const PinnedProgramSummary(
                    name: 'Setup',
                    path: '/downloads/setup.exe',
                    removable: false,
                  ),
                  settingsState: ProgramConfigurationSettingsState.ready(
                    ProgramSettingsSummary(
                      arguments: '-silent',
                      workingDirectory:
                          const ProgramWorkingDirectorySummary.custom(
                            r'C:\Games\Touhou',
                          ),
                      environment: const {'STEAM_COMPAT_DATA_PATH': '/compat'},
                      logging: const ProgramLoggingSettingsSummary(
                        additionalWineLoggingChannels: '+seh',
                        logFilePath: '/tmp/setup.cxlog',
                      ),
                    ),
                  ),
                  programSettingsChangeAction:
                      ProgramSettingsChangeAvailability.available((_, _, _) {}),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Logging'), findsOneWidget);
    expect(find.text('Working directory'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('program-config-working-directory-kind')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('program-config-working-directory-path-field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('program-config-create-log-file')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('program-config-wine-logging-channels-field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('program-config-log-file-path-field')),
      findsOneWidget,
    );
    await _expectGoldenFileWithinTolerance(
      find.byKey(goldenKey),
      'goldens/program_configuration_logging.png',
      diffTolerance: 0.11,
    );
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

  testWidgets(
    'Linux run program hides launch progress after a new Wine process survives',
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

      windowProbe.runningWineProcessIdSet.add(777);
      await tester.pump(const Duration(milliseconds: 260));

      expect(find.text('Launching program...'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 300));

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

  testWidgets('Linux run program ignores preexisting Wine processes', (
    WidgetTester tester,
  ) async {
    final windowProbe = _MutableProgramWindowProbe()
      ..runningWineProcessIdSet.add(777);
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
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Launching program...'), findsOneWidget);

    windowProbe.runningWineProcessIdSet.add(888);
    await tester.pump(const Duration(milliseconds: 600));

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
  });

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
    final pickerInitialDirectories = <FilePickerInitialDirectory>[];
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
      FilePickerInitialDirectory.path(
        '/home/user/.local/share/konyak/bottles/steam/drive_c',
      ),
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

  testWidgets('pinned program selection moves to the latest clicked tile', (
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
                  },
                  {
                    "name": "Game",
                    "path": "/games/game.exe",
                    "removable": false
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
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Setup'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Game'));
    await tester.pumpAndSettle();

    final firstTile = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('pinned-program-tile-/downloads/setup.exe')),
    );
    final secondTile = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('pinned-program-tile-/games/game.exe')),
    );
    final firstDecoration = firstTile.decoration as BoxDecoration?;
    final secondDecoration = secondTile.decoration as BoxDecoration?;

    expect(firstDecoration?.color, Colors.transparent);
    expect(secondDecoration?.color, const Color(0xff383838));
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
        platform: KonyakPlatform.linux,
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
    expect(find.text('Show in File Manager'), findsOneWidget);
    expect(find.text('Show in Finder'), findsNothing);

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
                },
                "logging": {
                  "createLogFile": true,
                  "additionalWineLoggingChannels": "+seh",
                  "logFilePath": "/tmp/setup.cxlog"
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
                },
                "logging": {
                  "createLogFile": true,
                  "additionalWineLoggingChannels": "+relay,+file",
                  "logFilePath": "/tmp/setup-debug.cxlog"
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
        platform: KonyakPlatform.linux,
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
    expect(find.text('Show in File Manager'), findsOneWidget);
    expect(find.text('Show in Finder'), findsNothing);
    expect(find.byKey(const ValueKey('program-config-locale')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('program-config-arguments-field')),
      findsOneWidget,
    );
    expect(find.text('STEAM_COMPAT_DATA_PATH'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('program-config-create-log-file')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('program-config-wine-logging-channels-field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('program-config-log-file-path-field')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('program-config-arguments-field')),
      '-silent -windowed',
    );
    await tester.enterText(
      find.byKey(const ValueKey('program-config-wine-logging-channels-field')),
      '+relay,+file',
    );
    await tester.enterText(
      find.byKey(const ValueKey('program-config-log-file-path-field')),
      '/tmp/setup-debug.cxlog',
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('program-config-save')),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const ValueKey('program-config-save')));
    await tester.pumpAndSettle();

    expect(find.text('Saved Setup configuration'), findsOneWidget);
    expect(runner.argumentsLog.last, const [
      'set-program-settings',
      'steam',
      '--program',
      '/downloads/setup.exe',
      '--settings-json',
      '{"locale":"ja_JP.UTF-8","arguments":"-silent -windowed","environment":{"STEAM_COMPAT_DATA_PATH":"/compat"},"logging":{"createLogFile":true,"additionalWineLoggingChannels":"+relay,+file","logFilePath":"/tmp/setup-debug.cxlog"}}',
      '--json',
    ]);
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

  testWidgets('long snackbar messages stay above bottom actions and show detail', (
    WidgetTester tester,
  ) async {
    final longMessage = [
      'Runner executable `wine` was not found.',
      'The configured runtime path is missing from the development build.',
      'Reinstall the managed runtime or update the development runtime path.',
      'Checked path: /very/long/path/that/would/not/fit/in/the/snackbar/area/wine',
    ].join(' ');
    final feedbackMessage = '$longMessage (wine: wine)';
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
      ProcessRunResult(
        exitCode: 75,
        stdout: jsonEncode({
          'schemaVersion': 1,
          'error': {
            'code': 'programRunFailed',
            'message': longMessage,
            'bottleId': 'steam',
            'programPath': '/downloads/setup.exe',
            'runnerKind': 'wine',
            'executable': 'wine',
            'workingDirectory': null,
            'argv': ['wine', '/downloads/setup.exe'],
            'logPath':
                '/home/user/.local/share/konyak/bottles/steam/logs/latest.log',
          },
        }),
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

    final snackBarTextRect = tester.getRect(find.text(feedbackMessage));
    final bottomBarRect = tester.getRect(
      find.byKey(const ValueKey('bottom-bar')),
    );
    final toolsButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Tools'),
    );
    final toolsButtonTextStyle = toolsButton.style?.textStyle?.resolve(
      <WidgetState>{},
    );

    expect(snackBarTextRect.bottom <= bottomBarRect.top, isTrue);
    expect(toolsButtonTextStyle?.fontFamily, 'Inter');
    expect(find.text('Show detail'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);

    await tester.tap(find.text('Show detail'));
    await tester.pumpAndSettle();

    expect(find.text('Details'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is SelectableText && widget.data == feedbackMessage,
      ),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(TextButton, 'Close'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text(feedbackMessage), findsNothing);
    expect(find.text('Show detail'), findsNothing);
  });
}
