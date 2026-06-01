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
    for (final label in ['Open C: Drive', 'Terminal', 'Winetricks', 'Run']) {
      expect(
        tester.widget<Text>(find.text(label)).overflow,
        isNot(TextOverflow.ellipsis),
      );
    }
  });
}
