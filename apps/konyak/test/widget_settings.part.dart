part of 'widget_test.dart';

void defineSettingsWidgetTests() {
  testWidgets('settings dialog loads and persists Konyak app settings', (
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
              "automaticallyCheckForWineUpdates": true,
              "automaticallyPinNewInstalledPrograms": true,
              "languageMode": "system"
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
      const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "appSettings": {
              "terminateWineProcessesOnClose": true,
              "defaultBottlePath": "/Volumes/Games/Bottles",
              "automaticallyCheckForKonyakUpdates": false,
              "automaticallyCheckForWineUpdates": true,
              "automaticallyPinNewInstalledPrograms": true,
              "languageMode": "system"
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
            "appSettings": {
              "terminateWineProcessesOnClose": true,
              "defaultBottlePath": "/Volumes/Games/Bottles",
              "automaticallyCheckForKonyakUpdates": true,
              "automaticallyCheckForWineUpdates": true,
              "automaticallyPinNewInstalledPrograms": true,
              "languageMode": "system"
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
            "appSettings": {
              "terminateWineProcessesOnClose": true,
              "defaultBottlePath": "/Volumes/Games/Bottles",
              "automaticallyCheckForKonyakUpdates": true,
              "automaticallyCheckForWineUpdates": true,
              "automaticallyPinNewInstalledPrograms": false,
              "languageMode": "system"
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
            "appSettings": {
              "terminateWineProcessesOnClose": true,
              "defaultBottlePath": "/Volumes/Games/Bottles",
              "automaticallyCheckForKonyakUpdates": true,
              "automaticallyCheckForWineUpdates": true,
              "automaticallyPinNewInstalledPrograms": false,
              "languageMode": "ja"
            }
          }
        ''',
        stderr: '',
      ),
    ]);

    await tester.pumpWidget(
      _testKonyakApp(
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
        directoryPicker: const _FakeDirectoryPicker(
          path: '/Volumes/Games/Bottles',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Konyak Settings'), findsOneWidget);
    expect(find.text('General'), findsOneWidget);
    expect(find.text('Programs'), findsOneWidget);
    expect(find.text('Updates'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(
      find.text('/Users/user/Library/Application Support/Konyak/Bottles'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(TextButton, 'Browse'));
    await tester.pumpAndSettle();
    expect(find.text('/Volumes/Games/Bottles'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('app-settings-check-konyak-updates-switch')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('app-settings-check-konyak-updates-switch')),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('app-settings-auto-pin-new-programs-switch')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('app-settings-auto-pin-new-programs-switch')),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('app-settings-language-selector')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Japanese'));
    await tester.pumpAndSettle();

    expect(find.text('Konyak 設定'), findsOneWidget);

    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      ['get-app-settings', '--json'],
      ['list-runtimes', '--json'],
      [
        'set-app-settings',
        '--settings-json',
        '{"terminateWineProcessesOnClose":true,"defaultBottlePath":"/Volumes/Games/Bottles","appearanceMode":"dark","languageMode":"system","automaticallyCheckForKonyakUpdates":false,"automaticallyCheckForWineUpdates":true,"automaticallyPinNewInstalledPrograms":true}',
        '--json',
      ],
      [
        'set-app-settings',
        '--settings-json',
        '{"terminateWineProcessesOnClose":true,"defaultBottlePath":"/Volumes/Games/Bottles","appearanceMode":"dark","languageMode":"system","automaticallyCheckForKonyakUpdates":true,"automaticallyCheckForWineUpdates":true,"automaticallyPinNewInstalledPrograms":true}',
        '--json',
      ],
      [
        'set-app-settings',
        '--settings-json',
        '{"terminateWineProcessesOnClose":true,"defaultBottlePath":"/Volumes/Games/Bottles","appearanceMode":"dark","languageMode":"system","automaticallyCheckForKonyakUpdates":true,"automaticallyCheckForWineUpdates":true,"automaticallyPinNewInstalledPrograms":false}',
        '--json',
      ],
      [
        'set-app-settings',
        '--settings-json',
        '{"terminateWineProcessesOnClose":true,"defaultBottlePath":"/Volumes/Games/Bottles","appearanceMode":"dark","languageMode":"ja","automaticallyCheckForKonyakUpdates":true,"automaticallyCheckForWineUpdates":true,"automaticallyPinNewInstalledPrograms":false}',
        '--json',
      ],
    ]);
  });

  testWidgets('settings dialog language selector matches golden', (
    WidgetTester tester,
  ) async {
    await _loadKonyakTestFonts();
    await tester.binding.setSurfaceSize(const Size(900, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

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
              "appearanceMode": "dark",
              "languageMode": "ja",
              "automaticallyCheckForKonyakUpdates": false,
              "automaticallyCheckForWineUpdates": true,
              "automaticallyPinNewInstalledPrograms": true
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

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    await _expectGoldenFileWithinTolerance(
      find.byKey(const ValueKey('app-settings-dialog')),
      'goldens/app_settings_dialog_language.png',
      diffTolerance: 0.03,
    );
  });

  testWidgets('macOS settings labels Konyak update switch as check', (
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

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Automatically check for Konyak updates'), findsOneWidget);
    expect(find.text('Automatically install Konyak updates'), findsNothing);
  });

  testWidgets('Linux settings labels Konyak update switch as check', (
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
              "defaultBottlePath": "/home/user/.local/share/konyak/Bottles",
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
        platform: KonyakPlatform.linux,
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Automatically check for Konyak updates'), findsOneWidget);
    expect(find.text('Automatically install Konyak updates'), findsNothing);
  });

  testWidgets('Linux settings dialog shows runtime stack component statuses', (
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
              "appearanceMode": "dark",
              "automaticallyCheckForKonyakUpdates": false,
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
            "runtimes": [
              {
                "id": "konyak-linux-wine",
                "name": "Konyak Linux Wine",
                "platform": "linux",
                "architecture": "x86_64",
                "runnerKind": "wine",
                "isBundled": false,
                "isUpdateable": true,
                "stack": {
                  "schemaVersion": 1,
                  "id": "linux-runtime-stack",
                  "name": "Konyak Linux runtime stack",
                  "compatibilityTarget": "proton-linux-runtime-stack",
                  "isComplete": false,
                  "components": [
                    {
                      "id": "wine",
                      "name": "Wine",
                      "role": "windows-runner",
                      "isRequired": true,
                      "isInstalled": true,
                      "paths": ["/runtime/bin/wine"],
                      "missingPaths": [],
                      "version": "wine-10.0"
                    },
                    {
                      "id": "wine-mono",
                      "name": "wine-mono",
                      "role": "dotnet-runtime",
                      "isRequired": true,
                      "isInstalled": true,
                      "paths": ["/runtime/share/wine/mono"],
                      "missingPaths": [],
                      "version": "wine-mono-10.0.0"
                    },
                    {
                      "id": "vkd3d-proton",
                      "name": "vkd3d-proton",
                      "role": "d3d12-vulkan-translation",
                      "isRequired": true,
                      "isInstalled": false,
                      "paths": ["/runtime/lib64/wine/x86_64-windows/d3d12.dll"],
                      "missingPaths": ["/runtime/lib64/wine/x86_64-windows/d3d12.dll"],
                      "version": "v2.14"
                    }
                  ]
                }
              }
            ]
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

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Linux Runtime'), findsOneWidget);
    expect(find.text('Konyak Linux runtime stack'), findsOneWidget);
    expect(
      find.text('Compatibility: proton-linux-runtime-stack'),
      findsOneWidget,
    );
    expect(find.text('Wine'), findsWidgets);
    expect(find.text('Installed | wine-10.0'), findsOneWidget);
    expect(find.text('wine-mono'), findsOneWidget);
    expect(find.text('Installed | wine-mono-10.0.0'), findsOneWidget);
    expect(find.text('vkd3d-proton'), findsOneWidget);
    expect(find.text('Missing | v2.14'), findsOneWidget);
    expect(
      find.text('/runtime/lib64/wine/x86_64-windows/d3d12.dll'),
      findsNothing,
    );
  });

  testWidgets('settings dialog opens before runtime list finishes loading', (
    WidgetTester tester,
  ) async {
    final runtimeCompleter = Completer<ProcessRunResult>();
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
                "terminateWineProcessesOnClose": true,
                "defaultBottlePath": "/home/user/.local/share/konyak/bottles",
                "appearanceMode": "dark",
                "automaticallyCheckForKonyakUpdates": false,
                "automaticallyCheckForWineUpdates": true
              }
            }
          ''',
          stderr: '',
        ),
      ),
      runtimeCompleter.future,
    ]);

    await tester.pumpWidget(
      _testKonyakApp(
        platform: KonyakPlatform.linux,
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Konyak Settings'), findsOneWidget);
    expect(find.text('General'), findsOneWidget);
    expect(find.text('Linux Runtime'), findsOneWidget);
    expect(find.text('Loading'), findsOneWidget);
    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      ['get-app-settings', '--json'],
      ['list-runtimes', '--json'],
    ]);

    runtimeCompleter.complete(
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
                "stack": {
                  "schemaVersion": 1,
                  "id": "linux-runtime-stack",
                  "name": "Konyak Linux runtime stack",
                  "compatibilityTarget": "proton-linux-runtime-stack",
                  "isComplete": true,
                  "components": []
                }
              }
            ]
          }
        ''',
        stderr: '',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Loading'), findsNothing);
    expect(find.text('Konyak Linux runtime stack'), findsOneWidget);
  });

  testWidgets('Linux settings dialog installs a missing runtime explicitly', (
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
              "defaultBottlePath": "/home/user/.local/share/konyak/bottles",
              "appearanceMode": "dark",
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
            "runtimes": [
              {
                "id": "konyak-linux-wine",
                "name": "Konyak Linux Wine",
                "platform": "linux",
                "architecture": "x86_64",
                "runnerKind": "wine",
                "isBundled": false,
                "isUpdateable": false,
                "isInstalled": false,
                "stack": {
                  "schemaVersion": 1,
                  "id": "linux-runtime-stack",
                  "name": "Konyak Linux runtime stack",
                  "compatibilityTarget": "proton-linux-runtime-stack",
                  "isComplete": false,
                  "components": [
                    {
                      "id": "wine",
                      "name": "Wine",
                      "role": "windows-runner",
                      "isRequired": true,
                      "isInstalled": false,
                      "paths": ["/runtime/bin/wine"],
                      "missingPaths": ["/runtime/bin/wine"]
                    }
                  ]
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
            "runtime": {
              "id": "konyak-linux-wine",
              "name": "Konyak Linux Wine",
              "platform": "linux",
              "architecture": "x86_64",
              "runnerKind": "wine",
              "isBundled": false,
              "isUpdateable": false,
              "isInstalled": true,
              "stack": {
                "schemaVersion": 1,
                "id": "linux-runtime-stack",
                "name": "Konyak Linux runtime stack",
                "compatibilityTarget": "proton-linux-runtime-stack",
                "isComplete": true,
                "components": [
                  {
                    "id": "wine",
                    "name": "Wine",
                    "role": "windows-runner",
                    "isRequired": true,
                    "isInstalled": true,
                    "paths": ["/runtime/bin/wine"],
                    "missingPaths": []
                  }
                ]
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

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Linux Runtime'), findsOneWidget);
    expect(find.text('Incomplete'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('app-settings-install-runtime-button')),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('app-settings-install-runtime-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('app-settings-install-runtime-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Complete'), findsOneWidget);
  });

  testWidgets('macOS settings dialog installs a missing runtime explicitly', (
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
              "appearanceMode": "dark",
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
            "runtimes": [
              {
                "id": "konyak-macos-wine",
                "name": "Konyak macOS Wine",
                "platform": "macos",
                "architecture": "x86_64",
                "runnerKind": "macosWine",
                "isBundled": false,
                "isUpdateable": false,
                "isInstalled": false,
                "stack": {
                  "schemaVersion": 1,
                  "id": "macos-konyak-runtime-stack",
                  "name": "Konyak macOS runtime stack",
                  "compatibilityTarget": "macos-konyak-runtime-stack",
                  "isComplete": false,
                  "components": [
                    {
                      "id": "wine",
                      "name": "Wine",
                      "role": "windows-runner",
                      "isRequired": true,
                      "isInstalled": false,
                      "paths": ["/runtime/bin/wine64"],
                      "missingPaths": ["/runtime/bin/wine64"]
                    }
                  ]
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
            "runtime": {
              "id": "konyak-macos-wine",
              "name": "Konyak macOS Wine",
              "platform": "macos",
              "architecture": "x86_64",
              "runnerKind": "macosWine",
              "isBundled": false,
              "isUpdateable": false,
              "isInstalled": true,
              "stack": {
                "schemaVersion": 1,
                "id": "macos-konyak-runtime-stack",
                "name": "Konyak macOS runtime stack",
                "compatibilityTarget": "macos-konyak-runtime-stack",
                "isComplete": true,
                "components": [
                  {
                    "id": "wine",
                    "name": "Wine",
                    "role": "windows-runner",
                    "isRequired": true,
                    "isInstalled": true,
                    "paths": ["/runtime/bin/wine64"],
                    "missingPaths": []
                  }
                ]
              }
            }
          }
        ''',
        stderr: '',
      ),
    ]);

    await tester.pumpWidget(
      _testKonyakApp(
        platform: KonyakPlatform.macos,
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('macOS Runtime'), findsOneWidget);
    expect(find.text('Incomplete'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('app-settings-install-runtime-button')),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('app-settings-install-runtime-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('app-settings-install-runtime-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Complete'), findsOneWidget);
  });

  testWidgets('macOS settings dialog imports GPTK/D3DMetal', (
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
                "appearanceMode": "dark",
                "automaticallyCheckForKonyakUpdates": false,
                "automaticallyCheckForWineUpdates": false
              }
            }
          ''',
          stderr: '',
        ),
      ),
      Future.value(
        ProcessRunResult(
          exitCode: 0,
          stdout: _macosRuntimeListPayload(gptkAvailable: true),
          stderr: '',
        ),
      ),
      Future.value(
        const ProcessRunResult(
          exitCode: 0,
          stdout:
              '{"schemaVersion":1,"openedUrl":{"url":"https://developer.apple.com/games/game-porting-toolkit/"}}',
          stderr: '',
        ),
      ),
      installCompleter.future,
      Future.value(
        ProcessRunResult(
          exitCode: 0,
          stdout: _macosRuntimeListPayload(gptkAvailable: true),
          stderr: '',
        ),
      ),
    ]);

    await tester.pumpWidget(
      _testKonyakApp(
        platform: KonyakPlatform.macos,
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
        gptkWineSourcePicker: const _FakeGptkWineSourcePicker(
          path: '/Users/user/Downloads/Game_Porting_Toolkit_3.0.dmg',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Open GPTK Source'), findsOneWidget);
    expect(find.text('Select GPTK DMG'), findsOneWidget);
    expect(find.text('GPTK version'), findsOneWidget);
    expect(find.text('Auto'), findsOneWidget);
    expect(find.text('GPTK 3'), findsOneWidget);
    expect(find.text('GPTK 4'), findsOneWidget);
    expect(find.text('Import D3DMetal'), findsNothing);
    expect(
      find.textContaining('Konyak does not bundle or redistribute it'),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('app-settings-open-gptk-page-button')),
    );
    await tester.tap(
      find.byKey(const ValueKey('app-settings-open-gptk-page-button')),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('app-settings-install-gptk-wine-button')),
    );
    await tester.tap(
      find.byKey(const ValueKey('app-settings-install-gptk-wine-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Import D3DMetal Backend?'), findsOneWidget);
    expect(
      find.textContaining('without replacing the Wine executable'),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('app-settings-confirm-gptk-wine-button')),
    );
    await tester.pump();

    expect(find.text('Importing D3DMetal'), findsOneWidget);
    expect(find.text('Adding GPTK Wine'), findsNothing);

    installCompleter.complete(
      const ProcessRunResult(
        exitCode: 0,
        stdout: '{"schemaVersion":1,"gptkWineInstall":{"componentId":"wine"}}',
        stderr: '',
      ),
    );
    await tester.pumpAndSettle();

    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      ['get-app-settings', '--json'],
      ['list-runtimes', '--json'],
      [
        'open-url',
        'https://developer.apple.com/games/game-porting-toolkit/',
        '--json',
      ],
      [
        'install-gptk-wine',
        '--from',
        '/Users/user/Downloads/Game_Porting_Toolkit_3.0.dmg',
        '--json',
      ],
      ['list-runtimes', '--json'],
    ]);
  });

  testWidgets('macOS settings dialog imports explicit GPTK4 selection', (
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
                "appearanceMode": "dark",
                "automaticallyCheckForKonyakUpdates": false,
                "automaticallyCheckForWineUpdates": false
              }
            }
          ''',
          stderr: '',
        ),
      ),
      Future.value(
        ProcessRunResult(
          exitCode: 0,
          stdout: _macosRuntimeListPayload(gptkAvailable: true),
          stderr: '',
        ),
      ),
      installCompleter.future,
      Future.value(
        ProcessRunResult(
          exitCode: 0,
          stdout: _macosRuntimeListPayload(gptkAvailable: true),
          stderr: '',
        ),
      ),
    ]);

    await tester.pumpWidget(
      _testKonyakApp(
        platform: KonyakPlatform.macos,
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
        gptkWineSourcePicker: const _FakeGptkWineSourcePicker(
          path: '/Users/user/Downloads/Game_Porting_Toolkit_4.0_beta_1.dmg',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('app-settings-gptk-version-4')),
    );
    await tester.tap(find.byKey(const ValueKey('app-settings-gptk-version-4')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('app-settings-install-gptk-wine-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('app-settings-confirm-gptk-wine-button')),
    );
    await tester.pump();

    installCompleter.complete(
      const ProcessRunResult(
        exitCode: 0,
        stdout: '{"schemaVersion":1,"gptkWineInstall":{"componentId":"wine"}}',
        stderr: '',
      ),
    );
    await tester.pumpAndSettle();

    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      ['get-app-settings', '--json'],
      ['list-runtimes', '--json'],
      [
        'install-gptk-wine',
        '--from',
        '/Users/user/Downloads/Game_Porting_Toolkit_4.0_beta_1.dmg',
        '--gptk-version',
        '4',
        '--json',
      ],
      ['list-runtimes', '--json'],
    ]);
  });

  testWidgets('macOS settings dialog imports explicit GPTK3 selection', (
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
              "appearanceMode": "dark",
              "automaticallyCheckForKonyakUpdates": false,
              "automaticallyCheckForWineUpdates": false
            }
          }
        ''',
        stderr: '',
      ),
      ProcessRunResult(
        exitCode: 0,
        stdout: _macosRuntimeListPayload(gptkAvailable: true),
        stderr: '',
      ),
      const ProcessRunResult(
        exitCode: 0,
        stdout: '{"schemaVersion":1,"gptkWineInstall":{"componentId":"wine"}}',
        stderr: '',
      ),
      ProcessRunResult(
        exitCode: 0,
        stdout: _macosRuntimeListPayload(gptkAvailable: true),
        stderr: '',
      ),
    ]);

    await tester.pumpWidget(
      _testKonyakApp(
        platform: KonyakPlatform.macos,
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
        gptkWineSourcePicker: const _FakeGptkWineSourcePicker(
          path: '/Users/user/Downloads/Game_Porting_Toolkit_3.0.dmg',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('app-settings-gptk-version-3')),
    );
    await tester.tap(find.byKey(const ValueKey('app-settings-gptk-version-3')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('app-settings-install-gptk-wine-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('app-settings-confirm-gptk-wine-button')),
    );
    await tester.pumpAndSettle();

    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      ['get-app-settings', '--json'],
      ['list-runtimes', '--json'],
      [
        'install-gptk-wine',
        '--from',
        '/Users/user/Downloads/Game_Porting_Toolkit_3.0.dmg',
        '--gptk-version',
        '3',
        '--json',
      ],
      ['list-runtimes', '--json'],
    ]);
  });

  testWidgets('macOS settings GPTK import version panel matches golden', (
    WidgetTester tester,
  ) async {
    await _loadKonyakTestFonts();
    await tester.binding.setSurfaceSize(const Size(900, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

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
              "appearanceMode": "dark",
              "languageMode": "en",
              "automaticallyCheckForKonyakUpdates": false,
              "automaticallyCheckForWineUpdates": true,
              "automaticallyPinNewInstalledPrograms": true
            }
          }
        ''',
        stderr: '',
      ),
      ProcessRunResult(
        exitCode: 0,
        stdout: _macosRuntimeListPayload(gptkAvailable: false),
        stderr: '',
      ),
    ]);

    await tester.pumpWidget(
      _testKonyakApp(
        platform: KonyakPlatform.macos,
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('app-settings-gptk-version-selector')),
    );
    await tester.pumpAndSettle();

    await _expectGoldenFileWithinTolerance(
      find.byKey(const ValueKey('app-settings-dialog')),
      'goldens/app_settings_gptk_import_version.png',
      diffTolerance: 0.03,
    );
  });

  testWidgets('macOS settings dialog keeps missing GPTK last and partial', (
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
              "appearanceMode": "dark",
              "automaticallyCheckForKonyakUpdates": false,
              "automaticallyCheckForWineUpdates": false
            }
          }
        ''',
        stderr: '',
      ),
      ProcessRunResult(
        exitCode: 0,
        stdout: _macosRuntimeListPayload(gptkAvailable: false),
        stderr: '',
      ),
    ]);

    await tester.pumpWidget(
      _testKonyakApp(
        platform: KonyakPlatform.macos,
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Partial'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('app-settings-install-runtime-button')),
      findsNothing,
    );
    expect(find.text('DXMT'), findsOneWidget);
    expect(find.text('GPTK/D3DMetal'), findsOneWidget);
    expect(find.text('Missing'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('GPTK/D3DMetal')).dy,
      greaterThan(tester.getTopLeft(find.text('DXMT')).dy),
    );
  });

  testWidgets(
    'macOS settings dialog distinguishes installed incomplete runtime',
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
              "appearanceMode": "dark",
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
            "runtimes": [
              {
                "id": "konyak-macos-wine",
                "name": "Konyak macOS Wine",
                "platform": "macos",
                "architecture": "x86_64",
                "runnerKind": "macosWine",
                "isBundled": false,
                "isUpdateable": false,
                "distributionKind": "bootstrap",
                "isInstalled": true,
                "stack": {
                  "schemaVersion": 1,
                  "id": "macos-konyak-runtime-stack",
                  "name": "Konyak macOS runtime stack",
                  "compatibilityTarget": "macos-konyak-runtime-stack",
                  "isComplete": false,
                  "components": [
                    {
                      "id": "wine",
                      "name": "Wine",
                      "role": "windows-runner",
                      "isRequired": true,
                      "isInstalled": true,
                      "paths": ["/runtime/bin/wine64"],
                      "missingPaths": []
                    },
                    {
                      "id": "winetricks",
                      "name": "winetricks",
                      "role": "verb-installer",
                      "isRequired": true,
                      "isInstalled": false,
                      "paths": ["/runtime/winetricks"],
                      "missingPaths": ["/runtime/winetricks"]
                    }
                  ]
                }
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
              "code": "macosWineInstallFailed",
              "message": "Konyak macOS Wine is installed, but the runtime stack is incomplete. Configure KONYAK_DEV_MACOS_WINE_STACK_MANIFEST or KONYAK_MACOS_WINE_STACK_MANIFEST, or pass --source-manifest to repair it."
            }
          }
        ''',
          stderr: '',
        ),
      ]);

      await tester.pumpWidget(
        _testKonyakApp(
          platform: KonyakPlatform.macos,
          cliClient: KonyakCliClient(
            executable: 'konyak',
            processRunner: runner,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('app-settings-install-runtime-button')),
      );
      await tester.pumpAndSettle();
      expect(
        (tester.getCenter(find.widgetWithText(FilledButton, 'Repair')).dy -
                tester.getCenter(find.text('Incomplete')).dy)
            .abs(),
        lessThan(24),
      );
      await tester.tap(
        find.byKey(const ValueKey('app-settings-install-runtime-button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Konyak macOS Wine'), findsOneWidget);
      expect(find.text('Installed'), findsWidgets);
      expect(find.text('Distribution: bootstrap'), findsOneWidget);
      expect(find.text('Incomplete'), findsOneWidget);
      expect(find.text('Runtime install'), findsOneWidget);
      expect(find.text('Failed'), findsOneWidget);
      expect(
        find.textContaining('KONYAK_DEV_MACOS_WINE_STACK_MANIFEST'),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilledButton, 'Repair'), findsOneWidget);
    },
  );

  testWidgets('settings dialog fits compact desktop windows without overflow', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

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
              "appearanceMode": "dark",
              "automaticallyCheckForKonyakUpdates": false,
              "automaticallyCheckForWineUpdates": true
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

    expect(tester.takeException(), isNull);
    expect(find.text('Konyak Settings'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
  });

  testWidgets('settings dialog switches and persists the app appearance', (
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
              "appearanceMode": "dark",
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
              "automaticallyCheckForWineUpdates": true
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
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold));
    expect(Theme.of(context).brightness, Brightness.light);
  });

  testWidgets('settings dialog can follow the system appearance', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

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
              "appearanceMode": "dark",
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
      const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "appSettings": {
              "terminateWineProcessesOnClose": true,
              "defaultBottlePath": "/Users/user/Library/Application Support/Konyak/Bottles",
              "appearanceMode": "system",
              "automaticallyCheckForKonyakUpdates": false,
              "automaticallyCheckForWineUpdates": true
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
    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold));
    expect(Theme.of(context).brightness, Brightness.light);
  });
}
