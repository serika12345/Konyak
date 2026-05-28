import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';
import 'dart:ui' show Tristate;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:konyak/main.dart';
import 'package:konyak/src/app/app_constants.dart';
import 'package:konyak/src/cli/konyak_cli_client.dart';
import 'package:konyak/src/files/bottle_archive_picker.dart';
import 'package:konyak/src/files/directory_picker.dart';
import 'package:konyak/src/files/program_file_picker.dart';
import 'package:konyak/src/logs/log_reader.dart';

void main() {
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
    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      ['get-app-settings', '--json'],
    ]);
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

    final openDriveButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Open C: Drive'),
    );
    final openDriveStyle = openDriveButton.style?.textStyle?.resolve({
      WidgetState.disabled,
    });

    expect(openDriveStyle?.fontWeight, _regularTextWeight);
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
    for (final label in ['Open C: Drive', 'Terminal', 'Winetricks', 'Run']) {
      expect(
        tester.widget<Text>(find.text(label)).overflow,
        isNot(TextOverflow.ellipsis),
      );
    }
  });

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
    expect(find.text('Show in Finder'), findsOneWidget);
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
    await tester.tap(find.text('Show in Finder'));
    await tester.pumpAndSettle();

    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      ['open-bottle-location', 'steam', '--location', 'root', '--json'],
    ]);
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

    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      [
        'export-bottle-archive',
        'steam',
        '--archive',
        '/exports/steam.konyak-bottle.tar',
        '--json',
      ],
    ]);
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

    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      ['delete-bottle', 'steam', '--json'],
    ]);
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

    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      ['rename-bottle', 'steam', '--name', 'Steam Games', '--json'],
    ]);
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

    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      ['move-bottle', 'steam', '--path', '/mnt/games/Steam', '--json'],
    ]);
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

    expect(runner.argumentsLog.single, const ['list-bottles', '--json']);
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
    final tempDirectory = io.Directory.systemTemp.createTempSync(
      'konyak-process-manager-icon-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final iconFile = io.File('${tempDirectory.path}/steam.ico')
      ..writeAsBytesSync(_singlePixelIcoBytes());
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
      ProcessRunResult(
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
                    "iconPath": "${iconFile.path}"
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

    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      ['list-wine-processes', '--json'],
      [
        'terminate-wine-process',
        '--bottle',
        'steam',
        '--process',
        '00000034',
        '--json',
      ],
    ]);
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

    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      ['list-bottles', '--json'],
    ]);
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

    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      [
        'create-bottle',
        '--name',
        'Steam',
        '--windows-version',
        'win81',
        '--json',
      ],
    ]);
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

    expect(runner.argumentsLog.take(3).toList(growable: false), const [
      ['list-bottles', '--json'],
      ['inspect-bottle', 'steam', '--json'],
      ['list-runtimes', '--json'],
    ]);
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

    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      ['delete-bottle', 'steam', '--json'],
    ]);
    expect(find.text('Deleted Steam'), findsOneWidget);
    expect(find.text('No bottles yet'), findsOneWidget);
  });

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

    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      ['run-program', 'steam', '--program', '/downloads/setup.exe', '--json'],
    ]);
    expect(find.text('wine exited with code 0'), findsNothing);
    expect(find.byTooltip('View latest log'), findsOneWidget);

    await tester.tap(find.byTooltip('View latest log'));
    await tester.pumpAndSettle();

    expect(find.text('Latest run log'), findsOneWidget);
    expect(find.textContaining('exitCode: 0'), findsOneWidget);
  });

  testWidgets('run program dialog can choose a program file', (
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
        programFilePicker: const _FakeProgramFilePicker(
          path: '/downloads/setup.exe',
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

    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      ['run-program', 'steam', '--program', '/downloads/setup.exe', '--json'],
    ]);
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

    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      [
        'pin-program',
        'steam',
        '--name',
        'setup',
        '--program',
        '/downloads/setup.exe',
        '--json',
      ],
    ]);

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

    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      [
        'pin-program',
        'steam',
        '--name',
        'setup',
        '--program',
        '/downloads/setup.exe',
        '--json',
      ],
      ['run-program', 'steam', '--program', '/downloads/setup.exe', '--json'],
    ]);
  });

  testWidgets('pinned program tile displays the extracted executable icon', (
    WidgetTester tester,
  ) async {
    final tempDirectory = io.Directory.systemTemp.createTempSync(
      'konyak-pinned-program-icon-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final iconFile = io.File('${tempDirectory.path}/setup.ico')
      ..writeAsBytesSync(_singlePixelIcoBytes());
    final runner = _QueuedProcessRunner([
      ProcessRunResult(
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
                    "iconPath": "${iconFile.path}"
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

    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      ['run-program', 'steam', '--program', '/downloads/setup.exe', '--json'],
      [
        'open-program-location',
        'steam',
        '--program',
        '/downloads/setup.exe',
        '--json',
      ],
    ]);
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

    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      [
        'get-program-settings',
        'steam',
        '--program',
        '/downloads/setup.exe',
        '--json',
      ],
      [
        'set-program-settings',
        'steam',
        '--program',
        '/downloads/setup.exe',
        '--settings-json',
        '{"locale":"ja_JP.UTF-8","arguments":"-silent -windowed","environment":{"STEAM_COMPAT_DATA_PATH":"/compat"}}',
        '--json',
      ],
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

    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      [
        'rename-pinned-program',
        'steam',
        '--program',
        '/downloads/setup.exe',
        '--name',
        'Setup Client',
        '--json',
      ],
      ['unpin-program', 'steam', '--program', '/downloads/setup.exe', '--json'],
    ]);
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

  testWidgets('bottle configuration toggles update immediately', (
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

    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('config-dxvk-switch')))
          .flagsCollection
          .isToggled,
      Tristate.isTrue,
    );
    expect(runner.argumentsLog.length, 4);

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
    semantics.dispose();
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

      expect(runner.argumentsLog, const [
        ['list-bottles', '--json'],
        ['inspect-bottle', 'steam', '--json'],
        ['list-runtimes', '--json'],
      ]);
      semantics.dispose();
    },
  );

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
    expect(find.text('Tools'), findsNothing);
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
    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
    ]);
  });

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
    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      ['get-app-settings', '--json'],
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

    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      [
        'import-bottle-archive',
        '--archive',
        '/imports/steam.konyak-bottle.tar',
        '--json',
      ],
    ]);
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

    expect(find.text('Linux preview'), findsOneWidget);
    expect(find.text('Konyak'), findsWidgets);
    expect(find.text('Flutter desktop UI for Konyak.'), findsOneWidget);
    expect(find.text('MIT License'), findsOneWidget);
    expect(
      find.text(
        'Wine/Proton runtime binaries are downloaded after launch and remain under their own licenses.',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate((widget) {
        return widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == 'assets/icons/konyak.png';
      }),
      findsOneWidget,
    );
    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
    ]);
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
    expect(find.text('Retina Mode'), findsNothing);
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

    await tester.tap(find.widgetWithText(TextButton, 'Open C: Drive'));
    await tester.pumpAndSettle();

    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      ['open-bottle-location', 'steam', '--location', 'c-drive', '--json'],
    ]);
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

    await tester.tap(find.widgetWithText(TextButton, 'Terminal'));
    await tester.pumpAndSettle();

    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      ['run-bottle-command', 'steam', '--command', 'terminal', '--json'],
    ]);
    expect(find.text('macosTerminal exited with code 0'), findsOneWidget);
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

    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      ['list-winetricks-verbs', '--json'],
      ['run-winetricks', 'steam', '--verb', 'corefonts', '--json'],
    ]);
    expect(find.text('macosWinetricks exited with code 0'), findsNothing);
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

    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      ['list-bottle-programs', 'steam', '--json'],
    ]);
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

    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      ['list-bottle-programs', 'steam', '--json'],
      [
        'run-program',
        'steam',
        '--program',
        '/bottles/steam/drive_c/ProgramData/Microsoft/Windows/Start Menu/Programs/Steam.lnk',
        '--json',
      ],
    ]);
    expect(find.text('macosWine exited with code 0'), findsNothing);
  });

  testWidgets('installed programs dialog pins a selected shortcut', (
    WidgetTester tester,
  ) async {
    final tempDirectory = io.Directory.systemTemp.createTempSync(
      'konyak-installed-program-pin-icon-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final iconFile = io.File('${tempDirectory.path}/steam.ico')
      ..writeAsBytesSync(_singlePixelIcoBytes());
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
      ProcessRunResult(
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
                    "iconPath": "${iconFile.path}"
                  }
                }
              ]
            }
          }
        ''',
        stderr: '',
      ),
      ProcessRunResult(
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
                  "iconPath": "${iconFile.path}"
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
    await tester.tap(find.widgetWithText(TextButton, 'Pin').last);
    await tester.pumpAndSettle();

    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      ['list-bottle-programs', 'steam', '--json'],
      [
        'pin-program',
        'steam',
        '--name',
        'Steam',
        '--program',
        '/bottles/steam/drive_c/ProgramData/Microsoft/Windows/Start Menu/Programs/Steam.lnk',
        '--json',
      ],
    ]);
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
              "defaultBottlePath": "/Volumes/Games/Bottles",
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
            "appSettings": {
              "terminateWineProcessesOnClose": true,
              "defaultBottlePath": "/Volumes/Games/Bottles",
              "automaticallyCheckForKonyakUpdates": true,
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
    expect(find.text('Updates'), findsOneWidget);
    expect(
      find.text('/Users/user/Library/Application Support/Konyak/Bottles'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(TextButton, 'Browse'));
    await tester.pumpAndSettle();
    expect(find.text('/Volumes/Games/Bottles'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('app-settings-check-konyak-updates-switch')),
    );
    await tester.pumpAndSettle();

    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      ['get-app-settings', '--json'],
      ['list-runtimes', '--json'],
      [
        'set-app-settings',
        '--settings-json',
        '{"terminateWineProcessesOnClose":true,"defaultBottlePath":"/Volumes/Games/Bottles","appearanceMode":"dark","automaticallyCheckForKonyakUpdates":false,"automaticallyCheckForWineUpdates":true}',
        '--json',
      ],
      [
        'set-app-settings',
        '--settings-json',
        '{"terminateWineProcessesOnClose":true,"defaultBottlePath":"/Volumes/Games/Bottles","appearanceMode":"dark","automaticallyCheckForKonyakUpdates":true,"automaticallyCheckForWineUpdates":true}',
        '--json',
      ],
    ]);
  });

  testWidgets('Linux settings dialog shows runtime stack components', (
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
    expect(find.text('vkd3d-proton'), findsOneWidget);
    expect(find.text('Missing | v2.14'), findsOneWidget);
    expect(
      find.text('/runtime/lib64/wine/x86_64-windows/d3d12.dll'),
      findsOneWidget,
    );
    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      ['get-app-settings', '--json'],
      ['list-runtimes', '--json'],
    ]);
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
    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      ['get-app-settings', '--json'],
      ['list-runtimes', '--json'],
      ['install-linux-wine', '--json'],
    ]);
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
    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      ['get-app-settings', '--json'],
      ['list-runtimes', '--json'],
      ['install-macos-wine', '--json'],
    ]);
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
              "message": "Konyak macOS Wine is installed, but the runtime stack is incomplete. Configure KONYAK_DEV_MACOS_WINE_STACK_MANIFEST or KONYAK_MACOS_WINE_STACK_MANIFEST, or pass --source-manifest or --component-archive to repair it."
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
      expect(runner.argumentsLog, const [
        ['list-bottles', '--json'],
        ['get-app-settings', '--json'],
        ['list-runtimes', '--json'],
        ['install-macos-wine', '--json'],
      ]);
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
    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      ['get-app-settings', '--json'],
      ['list-runtimes', '--json'],
      [
        'set-app-settings',
        '--settings-json',
        '{"terminateWineProcessesOnClose":true,"defaultBottlePath":"/Users/user/Library/Application Support/Konyak/Bottles","appearanceMode":"light","automaticallyCheckForKonyakUpdates":false,"automaticallyCheckForWineUpdates":true}',
        '--json',
      ],
    ]);
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
    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      ['get-app-settings', '--json'],
      ['list-runtimes', '--json'],
      [
        'set-app-settings',
        '--settings-json',
        '{"terminateWineProcessesOnClose":true,"defaultBottlePath":"/Users/user/Library/Application Support/Konyak/Bottles","appearanceMode":"system","automaticallyCheckForKonyakUpdates":false,"automaticallyCheckForWineUpdates":true}',
        '--json',
      ],
    ]);
  });

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
    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      ['get-app-settings', '--json'],
      ['list-runtimes', '--json'],
    ]);
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

    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      [
        'import-bottle-archive',
        '--archive',
        '/imports/steam.konyak-bottle.tar',
        '--json',
      ],
    ]);
    expect(find.text('Imported Steam'), findsOneWidget);
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

    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
      [
        'create-bottle',
        '--name',
        'Games',
        '--windows-version',
        'win10',
        '--json',
      ],
      ['run-program', 'games', '--program', '/downloads/setup.EXE', '--json'],
    ]);
  });

  testWidgets(
    'enabled update checks only notify available updates on startup',
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
        find.text('Updates available: Konyak 1.1.0, Konyak Wine 12.0'),
        findsOneWidget,
      );
      expect(runner.argumentsLog, const [
        ['list-bottles', '--json'],
        ['get-app-settings', '--json'],
        ['check-app-update', '--json'],
        ['list-runtimes', '--json'],
        ['check-runtime-update', 'konyak-macos-wine', '--json'],
      ]);
    },
  );

  testWidgets(
    'macOS startup update checks do not prompt for missing managed runtime',
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

      expect(find.text('Download Konyak macOS Wine?'), findsNothing);
      expect(
        find.byKey(const ValueKey('runtime-install-progress')),
        findsNothing,
      );
      expect(runner.argumentsLog, const [
        ['list-bottles', '--json'],
        ['get-app-settings', '--json'],
        ['list-runtimes', '--json'],
      ]);
    },
  );

  testWidgets(
    'Linux startup update checks do not prompt for missing managed runtime',
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
              "defaultBottlePath": "/home/user/.local/share/konyak/bottles",
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
                "isInstalled": false
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
          cliClient: KonyakCliClient(
            executable: 'konyak',
            processRunner: runner,
          ),
          enableBackgroundServices: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Download Konyak Linux Wine?'), findsNothing);
      expect(
        find.byKey(const ValueKey('runtime-install-progress')),
        findsNothing,
      );
      expect(runner.argumentsLog, const [
        ['list-bottles', '--json'],
        ['get-app-settings', '--json'],
        ['list-runtimes', '--json'],
      ]);
    },
  );

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
    expect(runner.argumentsLog, const [
      ['list-bottles', '--json'],
    ]);
  });
}

final Matcher _regularTextWeight = anyOf(isNull, FontWeight.normal);
const _expandedSidebarWidth = 190.0;
const _collapsedSidebarWidth = 44.0;

KonyakApp _testKonyakApp({
  KonyakPlatform platform = KonyakPlatform.macos,
  KonyakCliClient? cliClient,
  LogReader? logReader,
  ProgramFilePicker? programFilePicker,
  DirectoryPicker? directoryPicker,
  BottleArchivePicker? bottleArchivePicker,
  List<String> initialExecutablePaths = const <String>[],
  bool enableBackgroundServices = false,
}) {
  return KonyakApp(
    platform: platform,
    cliClient: cliClient,
    logReader: logReader,
    programFilePicker: programFilePicker,
    directoryPicker: directoryPicker,
    bottleArchivePicker: bottleArchivePicker,
    initialExecutablePaths: initialExecutablePaths,
    enableBackgroundServices: enableBackgroundServices,
  );
}

FontWeight? _fontWeightForText(WidgetTester tester, String text) {
  return tester.widget<Text>(find.text(text)).style?.fontWeight;
}

Finder _windowControlDotFinder(Color color) {
  return find.byWidgetPredicate((widget) {
    if (widget is! DecoratedBox) {
      return false;
    }

    final decoration = widget.decoration;
    return decoration is BoxDecoration &&
        decoration.shape == BoxShape.circle &&
        decoration.color == color;
  });
}

double _sidebarWidth(WidgetTester tester) {
  return tester.getSize(find.byKey(const ValueKey('sidebar-slot'))).width;
}

Uint8List _singlePixelIcoBytes() {
  const headerLength = 6;
  const entryLength = 16;
  const imageOffset = headerLength + entryLength;
  const dibLength = 40 + 4 + 4;
  final bytes = Uint8List(imageOffset + dibLength);

  _writeU16(bytes, 2, 1);
  _writeU16(bytes, 4, 1);
  bytes[6] = 1;
  bytes[7] = 1;
  _writeU16(bytes, 10, 1);
  _writeU16(bytes, 12, 32);
  _writeU32(bytes, 14, dibLength);
  _writeU32(bytes, 18, imageOffset);

  final dibOffset = imageOffset;
  _writeU32(bytes, dibOffset, 40);
  _writeI32(bytes, dibOffset + 4, 1);
  _writeI32(bytes, dibOffset + 8, 2);
  _writeU16(bytes, dibOffset + 12, 1);
  _writeU16(bytes, dibOffset + 14, 32);
  _writeU32(bytes, dibOffset + 20, 4);

  final pixelOffset = dibOffset + 40;
  bytes[pixelOffset] = 0;
  bytes[pixelOffset + 1] = 0;
  bytes[pixelOffset + 2] = 0xff;
  bytes[pixelOffset + 3] = 0xff;

  return bytes;
}

String _macosRuntimeListPayload({bool dxvkAvailable = true}) {
  return jsonEncode(<String, Object?>{
    'schemaVersion': 1,
    'runtimes': <Object?>[
      <String, Object?>{
        'id': 'konyak-macos-wine',
        'name': 'Konyak macOS Wine',
        'platform': 'macos',
        'architecture': 'x86_64',
        'runnerKind': 'macosWine',
        'isBundled': false,
        'isUpdateable': true,
        'isInstalled': true,
        'stack': <String, Object?>{
          'schemaVersion': 1,
          'id': 'macos-konyak-runtime-stack',
          'name': 'Konyak macOS runtime stack',
          'compatibilityTarget': 'macos-konyak-runtime-stack',
          'isComplete': dxvkAvailable,
          'components': <Object?>[
            _runtimeStackComponentPayload(
              id: 'wine',
              name: 'Wine',
              role: 'windows-runner',
            ),
            _runtimeStackComponentPayload(
              id: 'wine32on64',
              name: 'Wine32-on-64 support',
              role: '32-bit-windows-support',
            ),
            _runtimeStackComponentPayload(
              id: 'dxvk-macos',
              name: 'DXVK-macOS',
              role: 'd3d9-d3d11-translation',
              missingPaths: dxvkAvailable
                  ? const <String>[]
                  : ['/runtime/DXVK'],
            ),
            _runtimeStackComponentPayload(
              id: 'moltenvk',
              name: 'MoltenVK',
              role: 'vulkan-metal-translation',
            ),
            _runtimeStackComponentPayload(
              id: 'gstreamer',
              name: 'GStreamer runtime',
              role: 'media-runtime',
            ),
            _runtimeStackComponentPayload(
              id: 'wine-mono',
              name: 'wine-mono',
              role: 'dotnet-runtime',
            ),
            _runtimeStackComponentPayload(
              id: 'winetricks',
              name: 'winetricks',
              role: 'verb-installer',
            ),
            _runtimeStackComponentPayload(
              id: 'gptk-d3dmetal',
              name: 'GPTK/D3DMetal',
              role: 'd3d12-metal-translation',
              isRequired: false,
            ),
          ],
        },
      },
    ],
  });
}

Map<String, Object?> _runtimeStackComponentPayload({
  required String id,
  required String name,
  required String role,
  bool isRequired = true,
  List<String> missingPaths = const <String>[],
}) {
  return <String, Object?>{
    'id': id,
    'name': name,
    'role': role,
    'isRequired': isRequired,
    'isInstalled': missingPaths.isEmpty,
    'paths': const <String>[],
    'missingPaths': missingPaths,
  };
}

void _writeU16(Uint8List bytes, int offset, int value) {
  ByteData.sublistView(bytes).setUint16(offset, value, Endian.little);
}

void _writeU32(Uint8List bytes, int offset, int value) {
  ByteData.sublistView(bytes).setUint32(offset, value, Endian.little);
}

void _writeI32(Uint8List bytes, int offset, int value) {
  ByteData.sublistView(bytes).setInt32(offset, value, Endian.little);
}

final class _QueuedProcessRunner implements ProcessRunner {
  _QueuedProcessRunner(List<ProcessRunResult> results)
    : _results = List.of(results);

  final List<ProcessRunResult> _results;
  final List<List<String>> argumentsLog = [];

  @override
  Future<ProcessRunResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String> environment = const <String, String>{},
  }) async {
    argumentsLog.add(List.unmodifiable(arguments));

    if (_results.isEmpty) {
      return const ProcessRunResult(
        exitCode: 1,
        stdout: '',
        stderr: 'No queued result.',
      );
    }

    return _results.removeAt(0);
  }
}

final class _FutureQueuedProcessRunner implements ProcessRunner {
  _FutureQueuedProcessRunner(List<Future<ProcessRunResult>> results)
    : _results = List.of(results);

  final List<Future<ProcessRunResult>> _results;
  final List<List<String>> argumentsLog = [];

  @override
  Future<ProcessRunResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String> environment = const <String, String>{},
  }) {
    argumentsLog.add(List.unmodifiable(arguments));

    if (_results.isEmpty) {
      return Future.value(
        const ProcessRunResult(
          exitCode: 1,
          stdout: '',
          stderr: 'No queued result.',
        ),
      );
    }

    return _results.removeAt(0);
  }
}

final class _FakeLogReader implements LogReader {
  const _FakeLogReader({required this.logs});

  final Map<String, String> logs;

  @override
  Future<LogReadResult> readLog(String path) async {
    final content = logs[path];
    if (content == null) {
      return LogReadFailure(message: 'Log not found: $path');
    }

    return ReadLog(content: content);
  }
}

final class _FakeProgramFilePicker implements ProgramFilePicker {
  const _FakeProgramFilePicker({required this.path});

  final String? path;

  @override
  Future<String?> pickProgramPath() async => path;
}

final class _FakeDirectoryPicker implements DirectoryPicker {
  const _FakeDirectoryPicker({required this.path});

  final String? path;

  @override
  Future<String?> pickDirectoryPath() async => path;
}

final class _FakeBottleArchivePicker implements BottleArchivePicker {
  const _FakeBottleArchivePicker({this.importPath, this.exportPath});

  final String? importPath;
  final String? exportPath;

  @override
  Future<String?> pickArchiveToImport() async => importPath;

  @override
  Future<String?> pickArchiveExportPath({required String suggestedName}) async {
    return exportPath;
  }
}
