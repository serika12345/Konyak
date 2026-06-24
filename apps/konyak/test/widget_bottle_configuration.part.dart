part of 'widget_test.dart';

void defineBottleConfigurationWidgetTests() {
  testWidgets(
    'bottle configuration opens a settings screen and runs utilities',
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
	                "path": "/Users/user/Library/Application Support/Konyak/Bottles/Steam",
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
	              "path": "/Users/user/Library/Application Support/Konyak/Bottles/Steam",
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
	                "dpiScaling": 144
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
	              "path": "/Users/user/Library/Application Support/Konyak/Bottles/Steam",
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
	                "buildVersion": 22631,
	                "retinaMode": false,
	                "dpiScaling": 144
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
	            "bottle": {
	              "id": "steam",
	              "name": "Steam",
	              "path": "/Users/user/Library/Application Support/Konyak/Bottles/Steam",
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
	                "buildVersion": 22631,
	                "retinaMode": false,
	                "dpiScaling": 144
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
        const ProcessRunResult(
          exitCode: 0,
          stdout: '''
	          {
	            "schemaVersion": 1,
	            "bottle": {
	              "id": "steam",
	              "name": "Steam",
	              "path": "/Users/user/Library/Application Support/Konyak/Bottles/Steam",
	              "windowsVersion": "win11",
	              "runtimeSettings": {
	                "enhancedSync": "msync",
	                "metalHud": false,
	                "metalTrace": false,
	                "avxEnabled": false,
	                "dxrEnabled": false,
	                "dxvk": true,
	                "dxvkAsync": true,
	                "dxvkHud": "off",
	                "buildVersion": 26100,
	                "retinaMode": false,
	                "dpiScaling": 192
	              }
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

      await tester.tap(find.text('Bottle Configuration'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Back to bottle'), findsOneWidget);
      expect(find.text('Wine'), findsOneWidget);
      expect(find.text('Graphics'), findsOneWidget);
      expect(find.text('Graphics Backend'), findsOneWidget);
      expect(find.text('Default'), findsOneWidget);
      expect(find.text('Metal'), findsNothing);
      expect(find.text('Enhanced Sync'), findsOneWidget);
      expect(find.text('Windows Version'), findsOneWidget);
      expect(find.text('Build Version'), findsNothing);
      expect(find.text('Windows DPI'), findsOneWidget);
      expect(find.text('144 DPI'), findsOneWidget);
      expect(find.text('High Resolution Mode'), findsOneWidget);
      expect(find.text('DPI Scaling'), findsNothing);
      expect(find.text('Retina Mode'), findsNothing);
      expect(find.widgetWithText(TextButton, 'Tools'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Open C: Drive'), findsNothing);

      final graphicsBackendSize = tester.getSize(
        find.byKey(const ValueKey('config-graphics-backend')),
      );
      expect(graphicsBackendSize.width, lessThanOrEqualTo(210));
      expect(graphicsBackendSize.height, greaterThanOrEqualTo(24));

      expect(
        find.byKey(const ValueKey('config-build-version-field')),
        findsNothing,
      );
      expect(find.text('Windows 10 22H2 (19045)'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('config-windows-version')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Windows 11 23H2 (22631)').last);
      await tester.pumpAndSettle();

      await _selectGraphicsBackend(tester, 'DXVK-macOS');

      expect(runner.argumentsLog.length, 5);
      expect(runner.argumentsLog[0], const ['list-bottles', '--json']);
      expect(runner.argumentsLog[1], const [
        'inspect-bottle',
        'steam',
        '--json',
      ]);
      expect(runner.argumentsLog[2], const ['list-runtimes', '--json']);
      expect(runner.argumentsLog[3].take(3).toList(growable: false), const [
        'set-runtime-settings',
        'steam',
        '--settings-json',
      ]);
      expect(runner.argumentsLog[3].last, '--json');
      final buildSettings =
          jsonDecode(runner.argumentsLog[3][3]) as Map<String, Object?>;
      expect(buildSettings, containsPair('buildVersion', 22631));
      expect(buildSettings, containsPair('dpiScaling', 144));

      expect(runner.argumentsLog[4].take(3).toList(growable: false), const [
        'set-runtime-settings',
        'steam',
        '--settings-json',
      ]);
      expect(runner.argumentsLog[4].last, '--json');
      final settings =
          jsonDecode(runner.argumentsLog[4][3]) as Map<String, Object?>;
      expect(settings, containsPair('dxvk', true));
      expect(settings, containsPair('dxvkAsync', true));
      expect(settings, containsPair('dxvkHud', 'off'));
      expect(settings, containsPair('buildVersion', 22631));
      expect(settings, containsPair('retinaMode', false));
      expect(settings, containsPair('dpiScaling', 144));

      await tester.tap(find.widgetWithText(TextButton, 'Tools'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Wine Configuration'));
      await tester.pumpAndSettle();

      expect(runner.argumentsLog[5], const [
        'run-bottle-command',
        'steam',
        '--command',
        'winecfg',
        '--json',
      ]);
      expect(runner.argumentsLog[6], const [
        'inspect-bottle',
        'steam',
        '--json',
      ]);
      expect(find.text('Windows 11 24H2 (26100)'), findsOneWidget);
      expect(find.text('192 DPI'), findsOneWidget);
      expect(find.text('macosWine exited with code 0'), findsNothing);
      expect(find.byTooltip('View latest log'), findsOneWidget);

      await tester.tap(find.byTooltip('Back to bottle'));
      await tester.pumpAndSettle();
      expect(find.text('Pin Program'), findsOneWidget);
    },
  );

  testWidgets(
    'macOS bottle configuration selects graphics backend from one dropdown',
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
                "path": "/Users/user/Library/Application Support/Konyak/Bottles/Steam",
                "windowsVersion": "win10",
                "runtimeSettings": {
                  "enhancedSync": "msync",
                  "metalHud": false,
                  "metalTrace": false,
                  "avxEnabled": false,
                  "dxrEnabled": false,
                  "dxvk": false,
                  "dxmt": false,
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
              "path": "/Users/user/Library/Application Support/Konyak/Bottles/Steam",
              "windowsVersion": "win10",
              "runtimeSettings": {
                "enhancedSync": "msync",
                "metalHud": false,
                "metalTrace": false,
                "avxEnabled": false,
                "dxrEnabled": false,
                "dxvk": false,
                "dxmt": false,
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
              "path": "/Users/user/Library/Application Support/Konyak/Bottles/Steam",
              "windowsVersion": "win10",
              "runtimeSettings": {
                "enhancedSync": "msync",
                "metalHud": false,
                "metalTrace": false,
                "avxEnabled": false,
                "dxrEnabled": false,
                "dxvk": false,
                "dxmt": true,
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
              "runtimeSettings": {
                "enhancedSync": "msync",
                "metalHud": false,
                "metalTrace": false,
                "avxEnabled": false,
                "dxrEnabled": true,
                "dxvk": false,
                "dxmt": false,
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
              "runtimeSettings": {
                "enhancedSync": "msync",
                "metalHud": false,
                "metalTrace": false,
                "avxEnabled": false,
                "dxrEnabled": false,
                "dxvk": true,
                "dxmt": false,
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
          cliClient: KonyakCliClient(
            executable: 'konyak',
            processRunner: runner,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bottle Configuration'));
      await tester.pumpAndSettle();

      expect(find.text('Graphics'), findsOneWidget);
      expect(find.text('Graphics Backend'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('config-graphics-backend')),
        findsOneWidget,
      );
      expect(find.text('DXVK Async'), findsNothing);
      expect(find.text('DXVK HUD'), findsNothing);
      expect(find.text('Metal HUD'), findsNothing);
      expect(find.text('Metal Trace'), findsNothing);
      expect(find.text('DLSS / MetalFX'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('config-graphics-backend')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('DXMT').last);
      await tester.pumpAndSettle();

      final dxmtSettings =
          jsonDecode(runner.argumentsLog[3][3]) as Map<String, Object?>;
      expect(dxmtSettings, containsPair('dxvk', false));
      expect(dxmtSettings, containsPair('dxmt', true));
      expect(dxmtSettings, containsPair('dxrEnabled', false));
      expect(find.text('Metal HUD'), findsOneWidget);
      expect(find.text('Metal Trace'), findsOneWidget);
      expect(find.text('DLSS / MetalFX'), findsOneWidget);
      expect(find.text('DXVK Async'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('config-graphics-backend')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('GPTK/D3DMetal').last);
      await tester.pumpAndSettle();

      final d3dMetalSettings =
          jsonDecode(runner.argumentsLog[4][3]) as Map<String, Object?>;
      expect(d3dMetalSettings, containsPair('dxvk', false));
      expect(d3dMetalSettings, containsPair('dxmt', false));
      expect(d3dMetalSettings, containsPair('dxrEnabled', true));
      expect(find.text('Metal HUD'), findsOneWidget);
      expect(find.text('Metal Trace'), findsOneWidget);
      expect(find.text('DLSS / MetalFX'), findsOneWidget);
      expect(find.text('DXVK Async'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('config-graphics-backend')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('DXVK-macOS').last);
      await tester.pumpAndSettle();

      final dxvkSettings =
          jsonDecode(runner.argumentsLog[5][3]) as Map<String, Object?>;
      expect(dxvkSettings, containsPair('dxvk', true));
      expect(dxvkSettings, containsPair('dxmt', false));
      expect(dxvkSettings, containsPair('dxrEnabled', false));
      expect(find.text('DXVK Async'), findsOneWidget);
      expect(find.text('DXVK HUD'), findsOneWidget);
      expect(find.text('Metal HUD'), findsNothing);
      expect(find.text('Metal Trace'), findsNothing);
      expect(find.text('DLSS / MetalFX'), findsNothing);
    },
  );

  testWidgets('macOS bottle configuration toggles DLSS MetalFX for DXMT', (
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
                "windowsVersion": "win10",
                "runtimeSettings": {
                  "enhancedSync": "msync",
                  "metalHud": false,
                  "metalTrace": false,
                  "avxEnabled": false,
                  "dxrEnabled": false,
                  "dxvk": false,
                  "dxmt": true,
                  "dlssMetalFx": false,
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
              "path": "/Users/user/Library/Application Support/Konyak/Bottles/Steam",
              "windowsVersion": "win10",
              "runtimeSettings": {
                "enhancedSync": "msync",
                "metalHud": false,
                "metalTrace": false,
                "avxEnabled": false,
                "dxrEnabled": false,
                "dxvk": false,
                "dxmt": true,
                "dlssMetalFx": false,
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
              "path": "/Users/user/Library/Application Support/Konyak/Bottles/Steam",
              "windowsVersion": "win10",
              "runtimeSettings": {
                "enhancedSync": "msync",
                "metalHud": false,
                "metalTrace": false,
                "avxEnabled": false,
                "dxrEnabled": false,
                "dxvk": false,
                "dxmt": true,
                "dlssMetalFx": true,
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
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bottle Configuration'));
    await tester.pumpAndSettle();

    expect(find.text('DLSS / MetalFX'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('config-dlss-metalfx-switch')));
    await tester.pumpAndSettle();

    expect(runner.argumentsLog[3].take(3).toList(growable: false), const [
      'set-runtime-settings',
      'steam',
      '--settings-json',
    ]);
    final settings =
        jsonDecode(runner.argumentsLog[3][3]) as Map<String, Object?>;
    expect(settings, containsPair('dxmt', true));
    expect(settings, containsPair('dxrEnabled', false));
    expect(settings, containsPair('dlssMetalFx', true));
  });

  testWidgets(
    'right-clicking the selected bottle keeps Bottle Configuration open',
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
                "path": "/Users/user/Library/Application Support/Konyak/Bottles/Steam",
                "windowsVersion": "win10",
                "runtimeSettings": {
                  "enhancedSync": "msync",
                  "metalHud": false,
                  "metalTrace": false,
                  "avxEnabled": false,
                  "dxrEnabled": false,
                  "dxvk": false,
                  "dxmt": false,
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
              "path": "/Users/user/Library/Application Support/Konyak/Bottles/Steam",
              "windowsVersion": "win10",
              "runtimeSettings": {
                "enhancedSync": "msync",
                "metalHud": false,
                "metalTrace": false,
                "avxEnabled": false,
                "dxrEnabled": false,
                "dxvk": false,
                "dxmt": false,
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
        ProcessRunResult(
          exitCode: 0,
          stdout: _macosRuntimeListPayload(),
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

      await tester.tap(find.text('Bottle Configuration'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Back to bottle'), findsOneWidget);
      expect(find.text('Graphics Backend'), findsOneWidget);

      await tester.tapAt(
        tester.getCenter(find.byKey(const ValueKey('sidebar-bottle-steam'))),
        buttons: kSecondaryMouseButton,
      );
      await tester.pump();

      expect(find.text('Rename...'), findsOneWidget);
      expect(find.byTooltip('Back to bottle'), findsOneWidget);
      expect(find.text('Graphics Backend'), findsOneWidget);
    },
  );

  testWidgets(
    'right-clicking another bottle keeps the current Bottle Configuration open',
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
                "path": "/Users/user/Library/Application Support/Konyak/Bottles/Steam",
                "windowsVersion": "win10",
                "runtimeSettings": {
                  "enhancedSync": "msync",
                  "metalHud": false,
                  "metalTrace": false,
                  "avxEnabled": false,
                  "dxrEnabled": false,
                  "dxvk": false,
                  "dxmt": false,
                  "dxvkAsync": true,
                  "dxvkHud": "off",
                  "buildVersion": 19045,
                  "retinaMode": false,
                  "dpiScaling": 144
                }
              },
              {
                "id": "battle",
                "name": "Battle.net",
                "path": "/Users/user/Library/Application Support/Konyak/Bottles/Battle.net",
                "windowsVersion": "win10",
                "runtimeSettings": {
                  "enhancedSync": "msync",
                  "metalHud": false,
                  "metalTrace": false,
                  "avxEnabled": false,
                  "dxrEnabled": false,
                  "dxvk": false,
                  "dxmt": false,
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
              "path": "/Users/user/Library/Application Support/Konyak/Bottles/Steam",
              "windowsVersion": "win10",
              "runtimeSettings": {
                "enhancedSync": "msync",
                "metalHud": false,
                "metalTrace": false,
                "avxEnabled": false,
                "dxrEnabled": false,
                "dxvk": false,
                "dxmt": false,
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
            "openedLocation": {
              "bottleId": "battle",
              "location": "root",
              "path": "/Users/user/Library/Application Support/Konyak/Bottles/Battle.net"
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

      await tester.tap(find.text('Bottle Configuration'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Back to bottle'), findsOneWidget);
      expect(find.text('Graphics Backend'), findsOneWidget);

      await tester.tapAt(
        tester.getCenter(find.byKey(const ValueKey('sidebar-bottle-battle'))),
        buttons: kSecondaryMouseButton,
      );
      await tester.pump();

      expect(find.text('Rename...'), findsOneWidget);
      expect(find.byTooltip('Back to bottle'), findsOneWidget);
      expect(find.text('Graphics Backend'), findsOneWidget);

      await tester.tap(find.text('Show in Finder'));
      await tester.pumpAndSettle();

      expect(runner.argumentsLog[3], const [
        'open-bottle-location',
        'battle',
        '--location',
        'root',
        '--json',
      ]);
      expect(find.text('Opened bottle folder'), findsOneWidget);
      expect(find.byTooltip('Back to bottle'), findsOneWidget);
      expect(find.text('Graphics Backend'), findsOneWidget);
    },
  );

  testWidgets('bottle configuration backend shows pending state until saved', (
    WidgetTester tester,
  ) async {
    final runtimeUpdateCompleter = Completer<ProcessRunResult>();
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
                  "dpiScaling": 144
                }
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
            "bottle": {
              "id": "steam",
              "name": "Steam",
              "path": "/Users/user/Library/Application Support/Konyak/Bottles/Steam",
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
                "dpiScaling": 144
              }
            }
          }
        ''',
          stderr: '',
        ),
      ),
      Future.value(
        ProcessRunResult(
          exitCode: 0,
          stdout: _macosRuntimeListPayload(),
          stderr: '',
        ),
      ),
      runtimeUpdateCompleter.future,
    ]);

    await tester.pumpWidget(
      _testKonyakApp(
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bottle Configuration'));
    await tester.pumpAndSettle();

    expect(find.text('Default'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('config-graphics-backend')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('DXVK-macOS').last);
    await tester.pump();

    expect(_graphicsBackendDropdown(tester).value, 'dxvk');
    expect(find.text('DXVK Async'), findsOneWidget);

    expect(find.byTooltip('Back to bottle'), findsNothing);
    expect(find.text('Bottle Configuration'), findsOneWidget);

    runtimeUpdateCompleter.complete(
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
    );
    await tester.pumpAndSettle();
    expect(_graphicsBackendDropdown(tester).value, 'dxvk');
    expect(find.text('DXVK Async'), findsOneWidget);
  });

  testWidgets(
    'bottle configuration enables High Resolution Mode with 192 DPI',
    (WidgetTester tester) async {
      final semantics = tester.ensureSemantics();

      final runtimeUpdateCompleter = Completer<ProcessRunResult>();
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
            "bottle": {
              "id": "steam",
              "name": "Steam",
              "path": "/Users/user/Library/Application Support/Konyak/Bottles/Steam",
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
        ),
        Future.value(
          ProcessRunResult(
            exitCode: 0,
            stdout: _macosRuntimeListPayload(),
            stderr: '',
          ),
        ),
        runtimeUpdateCompleter.future,
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

      await tester.tap(find.text('Bottle Configuration'));
      await tester.pumpAndSettle();

      expect(find.text('96 DPI'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('config-retina-mode-switch')));
      await tester.pump();

      expect(find.text('192 DPI'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('config-retina-mode-switch-loading')),
        findsOneWidget,
      );
      expect(
        tester
            .getSemantics(
              find.byKey(const ValueKey('config-retina-mode-switch')),
            )
            .flagsCollection
            .isToggled,
        Tristate.isTrue,
      );

      expect(runner.argumentsLog[3].take(3).toList(growable: false), const [
        'set-runtime-settings',
        'steam',
        '--settings-json',
      ]);
      final settings =
          jsonDecode(runner.argumentsLog[3][3]) as Map<String, Object?>;
      expect(settings, containsPair('retinaMode', true));
      expect(settings, containsPair('dpiScaling', 192));

      runtimeUpdateCompleter.complete(
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
                "retinaMode": true,
                "dpiScaling": 192
              }
            }
          }
        ''',
          stderr: '',
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('config-retina-mode-switch-loading')),
        findsNothing,
      );
      expect(find.text('192 DPI'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets('bottle configuration restores backend state when saving fails', (
    WidgetTester tester,
  ) async {
    final runtimeUpdateCompleter = Completer<ProcessRunResult>();
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
                  "dpiScaling": 144
                }
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
            "bottle": {
              "id": "steam",
              "name": "Steam",
              "path": "/Users/user/Library/Application Support/Konyak/Bottles/Steam",
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
                "dpiScaling": 144
              }
            }
          }
        ''',
          stderr: '',
        ),
      ),
      Future.value(
        ProcessRunResult(
          exitCode: 0,
          stdout: _macosRuntimeListPayload(),
          stderr: '',
        ),
      ),
      runtimeUpdateCompleter.future,
    ]);

    await tester.pumpWidget(
      _testKonyakApp(
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bottle Configuration'));
    await tester.pumpAndSettle();

    expect(find.text('Default'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('config-graphics-backend')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('DXVK-macOS').last);
    await tester.pump();

    expect(_graphicsBackendDropdown(tester).value, 'dxvk');
    expect(find.text('DXVK Async'), findsOneWidget);

    runtimeUpdateCompleter.complete(
      const ProcessRunResult(
        exitCode: 75,
        stdout: '''
          {
            "schemaVersion": 1,
            "error": {
              "code": "runtimeSettingsFailed",
              "message": "Runtime settings update failed."
            }
          }
        ''',
        stderr: '',
      ),
    );
    await tester.pumpAndSettle();

    expect(_graphicsBackendDropdown(tester).value, 'wineDefault');
    expect(find.text('DXVK Async'), findsNothing);
    expect(find.text('Runtime settings update failed.'), findsOneWidget);
  });

  testWidgets('bottle configuration waits for capabilities before toggles', (
    WidgetTester tester,
  ) async {
    final runtimeListCompleter = Completer<ProcessRunResult>();
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
                  "dpiScaling": 144
                }
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
            "bottle": {
              "id": "steam",
              "name": "Steam",
              "path": "/Users/user/Library/Application Support/Konyak/Bottles/Steam",
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
                "dpiScaling": 144
              }
            }
          }
        ''',
          stderr: '',
        ),
      ),
      runtimeListCompleter.future,
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
      ),
    ]);

    await tester.pumpWidget(
      _testKonyakApp(
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bottle Configuration'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Bottle Configuration'), findsOneWidget);
    expect(find.byTooltip('Back to bottle'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('bottle-configuration-runtime-loading')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('config-graphics-backend')), findsNothing);

    runtimeListCompleter.complete(
      ProcessRunResult(
        exitCode: 0,
        stdout: _macosRuntimeListPayload(),
        stderr: '',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Back to bottle'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('bottle-configuration-runtime-loading')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('config-graphics-backend')),
      findsOneWidget,
    );

    await _selectGraphicsBackend(tester, 'DXVK-macOS');

    expect(runner.argumentsLog[3].take(3).toList(growable: false), const [
      'set-runtime-settings',
      'steam',
      '--settings-json',
    ]);
    final settings =
        jsonDecode(runner.argumentsLog[3][3]) as Map<String, Object?>;
    expect(settings, containsPair('dxvk', true));
    expect(settings, containsPair('dxmt', false));
  });

  testWidgets('Linux bottle configuration enables DXVK when runtime has DXVK', (
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
                  "dxvk": false,
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
                "dxvk": false,
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
      ProcessRunResult(
        exitCode: 0,
        stdout: _linuxRuntimeListPayload(),
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

    expect(_graphicsBackendDropdown(tester).onChanged, isNotNull);

    await _selectGraphicsBackend(tester, 'DXVK');

    final settings =
        jsonDecode(runner.argumentsLog[3][3]) as Map<String, Object?>;
    expect(settings, containsPair('dxvk', true));
    expect(runner.argumentsLog[3].last, '--json');
  });

  testWidgets(
    'Linux bottle configuration enables vkd3d-proton when runtime has vkd3d-proton',
    (WidgetTester tester) async {
      final semantics = tester.ensureSemantics();
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
                  "dxvk": false,
                  "dxvkAsync": true,
                  "dxvkHud": "off",
                  "vkd3dProton": false,
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
                "dxvk": false,
                "dxvkAsync": true,
                "dxvkHud": "off",
                "vkd3dProton": false,
                "buildVersion": 19045,
                "retinaMode": false,
                "dpiScaling": 144
              }
            }
          }
        ''',
          stderr: '',
        ),
        ProcessRunResult(
          exitCode: 0,
          stdout: _linuxRuntimeListPayload(),
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
                "vkd3dProton": true,
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
          cliClient: KonyakCliClient(
            executable: 'konyak',
            processRunner: runner,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bottle Configuration'));
      await tester.pumpAndSettle();

      expect(
        tester
            .getSemantics(
              find.byKey(const ValueKey('config-vkd3d-proton-switch')),
            )
            .flagsCollection
            .isEnabled,
        Tristate.isTrue,
      );

      await tester.tap(
        find.byKey(const ValueKey('config-vkd3d-proton-switch')),
      );
      await tester.pumpAndSettle();

      final settings =
          jsonDecode(runner.argumentsLog[3][3]) as Map<String, Object?>;
      expect(settings, containsPair('vkd3dProton', true));
      expect(runner.argumentsLog[3].last, '--json');
      semantics.dispose();
    },
  );

  testWidgets('Linux vkd3d-proton switch shows pending state while updating', (
    WidgetTester tester,
  ) async {
    final runtimeUpdateCompleter = Completer<ProcessRunResult>();
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
                  "vkd3dProton": false,
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
      ),
      Future.value(
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
                "vkd3dProton": false,
                "buildVersion": 19045,
                "retinaMode": false,
                "dpiScaling": 144
              }
            }
          }
        ''',
          stderr: '',
        ),
      ),
      Future.value(
        ProcessRunResult(
          exitCode: 0,
          stdout: _linuxRuntimeListPayload(),
          stderr: '',
        ),
      ),
      runtimeUpdateCompleter.future,
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

    await tester.tap(find.byKey(const ValueKey('config-vkd3d-proton-switch')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('config-vkd3d-proton-switch')),
      findsOneWidget,
    );
    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey('config-vkd3d-proton-switch')),
          )
          .flagsCollection
          .isToggled,
      Tristate.isTrue,
    );
    expect(
      find.byKey(const ValueKey('config-vkd3d-proton-switch-loading')),
      findsOneWidget,
    );

    runtimeUpdateCompleter.complete(
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
                "vkd3dProton": true,
                "buildVersion": 19045,
                "retinaMode": false,
                "dpiScaling": 144
              }
            }
          }
        ''',
        stderr: '',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('config-vkd3d-proton-switch-loading')),
      findsNothing,
    );
    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey('config-vkd3d-proton-switch')),
          )
          .flagsCollection
          .isToggled,
      Tristate.isTrue,
    );
  });

  testWidgets(
    'bottle configuration disables runtime toggles when capabilities are missing',
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
                "path": "/Users/user/Library/Application Support/Konyak/Bottles/Steam",
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
              "path": "/Users/user/Library/Application Support/Konyak/Bottles/Steam",
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
                "dpiScaling": 144
              }
            }
          }
        ''',
          stderr: '',
        ),
        ProcessRunResult(
          exitCode: 0,
          stdout: _macosRuntimeListPayload(
            dxvkAvailable: false,
            dxmtAvailable: false,
            gptkAvailable: false,
          ),
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

      await tester.tap(find.text('Bottle Configuration'));
      await tester.pumpAndSettle();

      expect(_graphicsBackendDropdown(tester).onChanged, isNull);
    },
  );
}

Future<void> _selectGraphicsBackend(
  WidgetTester tester,
  String backendLabel,
) async {
  await tester.tap(find.byKey(const ValueKey('config-graphics-backend')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(backendLabel).last);
  await tester.pumpAndSettle();
}

DropdownButton<String> _graphicsBackendDropdown(WidgetTester tester) {
  return tester.widget<DropdownButton<String>>(
    find.descendant(
      of: find.byKey(const ValueKey('config-graphics-backend')),
      matching: find.byType(DropdownButton<String>),
    ),
  );
}
