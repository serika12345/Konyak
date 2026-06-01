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
      expect(find.text('DXVK'), findsWidgets);
      expect(find.text('Metal'), findsOneWidget);
      expect(find.text('Enhanced Sync'), findsOneWidget);
      expect(find.text('Windows Version'), findsOneWidget);
      expect(find.text('Build Version'), findsNothing);
      expect(find.text('DPI Scaling'), findsOneWidget);
      expect(find.text('144 DPI'), findsOneWidget);
      expect(find.text('Retina Mode'), findsOneWidget);
      expect(find.text('Open Wine Configuration'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Open C: Drive'), findsNothing);

      final dxvkToggleSize = tester.getSize(
        find.byKey(const ValueKey('config-dxvk-switch')),
      );
      expect(dxvkToggleSize.width, lessThanOrEqualTo(38));
      expect(dxvkToggleSize.height, lessThanOrEqualTo(22));

      expect(
        find.byKey(const ValueKey('config-build-version-field')),
        findsNothing,
      );
      expect(find.text('Windows 10 22H2 (19045)'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('config-windows-version')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Windows 11 23H2 (22631)').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('config-dxvk-switch')));
      await tester.pumpAndSettle();

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

  testWidgets('bottle configuration toggles show pending state until saved', (
    WidgetTester tester,
  ) async {
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

    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('config-dxvk-switch')))
          .flagsCollection
          .isToggled,
      Tristate.isFalse,
    );

    await tester.tap(find.byKey(const ValueKey('config-dxvk-switch')));
    await tester.pump();

    expect(find.byKey(const ValueKey('config-dxvk-switch')), findsNothing);
    expect(
      find.byKey(const ValueKey('config-dxvk-switch-loading')),
      findsOneWidget,
    );

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
    expect(
      find.byKey(const ValueKey('config-dxvk-switch-loading')),
      findsNothing,
    );
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('config-dxvk-switch')))
          .flagsCollection
          .isToggled,
      Tristate.isTrue,
    );
    semantics.dispose();
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
    expect(find.byKey(const ValueKey('config-dxvk-switch')), findsNothing);

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
    expect(find.byKey(const ValueKey('config-dxvk-switch')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('config-dxvk-switch')));
    await tester.pumpAndSettle();

    expect(runner.argumentsLog[3].take(3).toList(growable: false), const [
      'set-runtime-settings',
      'steam',
      '--settings-json',
    ]);
    final settings =
        jsonDecode(runner.argumentsLog[3][3]) as Map<String, Object?>;
    expect(settings, containsPair('dxvk', true));
  });

  testWidgets('Linux bottle configuration enables DXVK when runtime has DXVK', (
    WidgetTester tester,
  ) async {
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

    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('config-dxvk-switch')))
          .flagsCollection
          .isEnabled,
      Tristate.isTrue,
    );

    await tester.tap(find.byKey(const ValueKey('config-dxvk-switch')));
    await tester.pumpAndSettle();

    final settings =
        jsonDecode(runner.argumentsLog[3][3]) as Map<String, Object?>;
    expect(settings, containsPair('dxvk', true));
    expect(runner.argumentsLog[3].last, '--json');
    semantics.dispose();
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
      findsNothing,
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
          stdout: _macosRuntimeListPayload(dxvkAvailable: false),
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

      expect(
        tester
            .getSemantics(find.byKey(const ValueKey('config-dxvk-switch')))
            .flagsCollection
            .isEnabled,
        Tristate.isFalse,
      );

      await tester.tap(find.byKey(const ValueKey('config-dxvk-switch')));
      await tester.pumpAndSettle();

      semantics.dispose();
    },
  );
}
