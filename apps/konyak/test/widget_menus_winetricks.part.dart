part of 'widget_test.dart';

void defineMenuWinetricksAndInstalledProgramWidgetTests() {
  testWidgets('Profile Manager automatic install action matches golden', (
    WidgetTester tester,
  ) async {
    await _loadKonyakTestFonts();
    final goldenKey = GlobalKey();
    await tester.binding.setSurfaceSize(const Size(1040, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: konyakThemeData(konyakDarkColors),
        supportedLocales: KonyakLocalizations.supportedLocales,
        localizationsDelegates: KonyakLocalizations.localizationsDelegates,
        home: RepaintBoundary(
          key: goldenKey,
          child: Scaffold(
            body: Center(
              child: ProfileManagerDialog(
                bottleName: 'Steam',
                profiles: const [
                  InstallProfileListItem(
                    id: 'steam',
                    name: 'Steam',
                    profileVersion: 1,
                  ),
                ],
                programFilePicker: const _FakeProgramFilePicker(
                  path: '/bottles/steam/drive_c/Steam.exe',
                ),
                installProfileManifestPicker:
                    const _FakeInstallProfileManifestPicker(),
                initialDirectory: '/bottles/steam/drive_c',
                validateManifest: _acceptProfileManagerManifest,
                executeAction: (_) async =>
                    const UnchangedProfileManagerCatalog(),
                inspectProfile: (_) async => InspectedInstallProfile(
                  InstallProfileDetails(
                    id: 'steam',
                    name: 'Steam',
                    profileVersion: 1,
                    profileSourceKind: 'builtin',
                    profileSourceId: 'steam.json',
                    profileDigest:
                        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
                        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
                    summary: 'Install Steam with Konyak compatibility rules.',
                    platforms: const ['macos'],
                    windowsVersion: 'win10',
                    managedProgramPath:
                        r'C:\Program Files (x86)\Steam\Steam.exe',
                    installerResource: InstallerResourceSummary(
                      kind: 'https',
                      url:
                          'https://cdn.cloudflare.steamstatic.com/client/'
                          'installer/SteamSetup.exe',
                      sha256:
                          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
                          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
                      fileName: 'SteamSetup.exe',
                    ),
                    preInstallActions: [
                      const WinetricksPreInstallActionSummary('corefonts'),
                      const WinetricksPreInstallActionSummary('vcrun2022'),
                      NativeDllPreInstallActionSummary(
                        componentId: 'd3dcompiler_47-x86',
                        machine: 'x86',
                        destination: 'windowsSysWow64',
                        targetFileName: 'd3dcompiler_47.dll',
                        resource: NativeDllResourceSummary(
                          kind: 'https',
                          url: 'https://downloads.example.test/d3d-x86.dll',
                          sha256: 'c' * 64,
                          fileName: 'd3dcompiler_47_32.dll',
                        ),
                      ),
                      NativeDllPreInstallActionSummary(
                        componentId: 'd3dcompiler_47-x64',
                        machine: 'x64',
                        destination: 'windowsSystem32',
                        targetFileName: 'd3dcompiler_47.dll',
                        resource: NativeDllResourceSummary(
                          kind: 'https',
                          url: 'https://downloads.example.test/d3d-x64.dll',
                          sha256: 'd' * 64,
                          fileName: 'd3dcompiler_47.dll',
                        ),
                      ),
                      const WinetricksPreInstallActionSummary('fakejapanese'),
                    ],
                    runCompletionPolicy: 'waitForExit',
                    compatibilityProfile: CompatibilityProfileSummary(
                      id: 'steam',
                      profileVersion: 1,
                      childProcessRules: const [],
                    ),
                    manifestJson: '{"schemaVersion":1,"id":"steam"}',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Install automatically'), findsOneWidget);
    expect(find.text('Apply to existing program'), findsOneWidget);
    expect(find.text('Import...'), findsOneWidget);
    expect(find.text('Duplicate'), findsOneWidget);
    expect(find.text('Export...'), findsOneWidget);
    final deleteButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Delete'),
    );
    expect(deleteButton.onPressed, isNull);
    expect(find.textContaining('builtin / steam.json'), findsOneWidget);
    expect(
      find.textContaining('3. nativeDll x86 → windowsSysWow64'),
      findsOneWidget,
    );
    expect(
      find.textContaining('4. nativeDll x64 → windowsSystem32'),
      findsOneWidget,
    );
    final dependencyTooltip = tester.widget<Tooltip>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Tooltip &&
            (widget.message ?? '').contains('d3dcompiler_47-x86'),
      ),
    );
    expect(
      dependencyTooltip.message,
      allOf(
        contains('d3dcompiler_47-x86'),
        contains('https://downloads.example.test/d3d-x86.dll'),
        contains('SHA-256: ${'c' * 64}'),
        contains('d3dcompiler_47-x64'),
        contains('https://downloads.example.test/d3d-x64.dll'),
        contains('SHA-256: ${'d' * 64}'),
      ),
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('profile-manager-program-path-field')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('profile-manager-program-path-field')),
      findsOneWidget,
    );

    await _expectGoldenFileWithinTolerance(
      find.byKey(goldenKey),
      'goldens/profile_manager_automatic_install.png',
      diffTolerance: 0.05,
    );
  });

  testWidgets('Profile Manager edits and deletes only user profiles', (
    WidgetTester tester,
  ) async {
    await _loadKonyakTestFonts();
    final goldenKey = GlobalKey();
    await tester.binding.setSurfaceSize(const Size(1100, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    ProfileManagerActionRequest? actionRequest;
    await tester.pumpWidget(
      RepaintBoundary(
        key: goldenKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: konyakThemeData(konyakDarkColors),
          supportedLocales: KonyakLocalizations.supportedLocales,
          localizationsDelegates: KonyakLocalizations.localizationsDelegates,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () {
                  unawaited(
                    showDialog<ProfileManagerDecision>(
                      context: context,
                      builder: (context) => ProfileManagerDialog(
                        bottleName: 'Synthetic',
                        profiles: const [
                          InstallProfileListItem(
                            id: 'synthetic',
                            name: 'Synthetic',
                            profileVersion: 1,
                            profileSourceKind: 'user',
                            profileDigest:
                                'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
                                'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
                            canEdit: true,
                            canDelete: true,
                          ),
                        ],
                        programFilePicker: const _FakeProgramFilePicker(
                          path: null,
                        ),
                        installProfileManifestPicker:
                            const _FakeInstallProfileManifestPicker(),
                        initialDirectory: '/bottles/synthetic/drive_c',
                        validateManifest: (request) async =>
                            request.manifestJson == '{'
                            ? const InvalidProfileManagerManifest(
                                'The profile manifest is invalid.',
                              )
                            : const ValidProfileManagerManifest(),
                        executeAction: (request) async {
                          actionRequest = request;
                          return const UnchangedProfileManagerCatalog();
                        },
                        inspectProfile: (_) async => InspectedInstallProfile(
                          _profileManagerTestDetails(sourceKind: 'user'),
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('Open manager'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open manager'));
    await tester.pumpAndSettle();

    expect(find.text('Edit'), findsOneWidget);
    final deleteButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Delete'),
    );
    expect(deleteButton.onPressed, isNotNull);

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('profile-manifest-editor-field')),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey('profile-manifest-editor-field')),
      '{',
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
          .onPressed,
      isNull,
    );
    expect(actionRequest, isNull);
    await _expectGoldenFileWithinTolerance(
      find.byKey(goldenKey),
      'goldens/profile_manifest_editor_invalid.png',
      diffTolerance: 0.01,
    );

    await tester.enterText(
      find.byKey(const ValueKey('profile-manifest-editor-field')),
      '{"schemaVersion":1,"id":"synthetic","name":"Updated"}',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(actionRequest, isA<EditProfileManagerActionRequest>());
    final editRequest = actionRequest as EditProfileManagerActionRequest;
    expect(editRequest.manifestJson, contains('Updated'));
    expect(editRequest.expectedDigest, 'a' * 64);
    expect(find.byType(ProfileManagerDialog), findsOneWidget);
  });

  testWidgets('Profile editor closes only after a successful save', (
    WidgetTester tester,
  ) async {
    final rejectedAction = Completer<ProfileManagerActionResult>();
    final completedAction = Completer<ProfileManagerActionResult>();
    var actionCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: konyakThemeData(konyakDarkColors),
        supportedLocales: KonyakLocalizations.supportedLocales,
        localizationsDelegates: KonyakLocalizations.localizationsDelegates,
        home: Scaffold(
          body: ProfileManagerDialog(
            bottleName: 'Synthetic',
            profiles: const [
              InstallProfileListItem(
                id: 'synthetic',
                name: 'Synthetic',
                profileVersion: 1,
                profileSourceKind: 'user',
                profileDigest:
                    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
                    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
                canEdit: true,
                canDelete: true,
              ),
            ],
            programFilePicker: const _FakeProgramFilePicker(path: null),
            installProfileManifestPicker:
                const _FakeInstallProfileManifestPicker(),
            initialDirectory: '/bottles/synthetic/drive_c',
            validateManifest: _acceptProfileManagerManifest,
            executeAction: (_) {
              actionCount += 1;
              return actionCount == 1
                  ? rejectedAction.future
                  : completedAction.future;
            },
            inspectProfile: (_) async => InspectedInstallProfile(
              _profileManagerTestDetails(sourceKind: 'user'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('profile-manifest-editor-field')),
      findsOneWidget,
    );

    rejectedAction.complete(
      const UnchangedProfileManagerCatalog(
        feedback: ShowProfileManagerActionFeedback(
          'The profile manifest is invalid.',
        ),
        disposition: RejectedProfileManagerAction(),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('profile-manifest-editor-field')),
      findsOneWidget,
    );
    expect(find.text('The profile manifest is invalid.'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('profile-manifest-editor-field')),
      findsOneWidget,
    );

    completedAction.complete(const UnchangedProfileManagerCatalog());
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('profile-manifest-editor-field')),
      findsNothing,
    );
  });

  testWidgets('Profile Manager imports a manifest and reloads the catalog', (
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
      ProcessRunResult(
        exitCode: 0,
        stdout: _profileManagerListPayload(
          id: 'builtin-synthetic',
          name: 'Built-in Synthetic',
          sourceKind: 'builtin',
        ),
        stderr: '',
      ),
      ProcessRunResult(
        exitCode: 0,
        stdout: _profileManagerInspectPayload(
          id: 'builtin-synthetic',
          name: 'Built-in Synthetic',
          sourceKind: 'builtin',
        ),
        stderr: '',
      ),
      ProcessRunResult(
        exitCode: 0,
        stdout: _profileManagerMutationPayload(
          operation: 'import',
          id: 'user-synthetic',
          name: 'User Synthetic',
        ),
        stderr: '',
      ),
      ProcessRunResult(
        exitCode: 0,
        stdout: _profileManagerListPayload(
          id: 'user-synthetic',
          name: 'User Synthetic',
          sourceKind: 'user',
        ),
        stderr: '',
      ),
      ProcessRunResult(
        exitCode: 0,
        stdout: _profileManagerInspectPayload(
          id: 'user-synthetic',
          name: 'User Synthetic',
          sourceKind: 'user',
        ),
        stderr: '',
      ),
    ]);

    await tester.pumpWidget(
      _testKonyakApp(
        cliClient: KonyakCliClient(executable: 'konyak', processRunner: runner),
        installProfileManifestPicker: const _FakeInstallProfileManifestPicker(
          importPath: '/tmp/user-synthetic.json',
          exportPath: '/tmp/user-synthetic-export.json',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Profile Manager'));
    await tester.pumpAndSettle();
    final programPathField = find.byKey(
      const ValueKey('profile-manager-program-path-field'),
    );
    await tester.ensureVisible(programPathField);
    await tester.enterText(programPathField, r'C:\Games\Preserved.exe');
    await tester.tap(find.text('Import...'));
    await tester.pumpAndSettle();

    expect(runner.argumentsLog[3], const [
      'import-install-profile',
      '--from',
      '/tmp/user-synthetic.json',
      '--json',
    ]);
    expect(find.text('Imported User Synthetic'), findsOneWidget);
    expect(find.text('User Synthetic'), findsWidgets);
    expect(find.text('Edit'), findsOneWidget);
    expect(
      tester.widget<TextField>(programPathField).controller?.text,
      r'C:\Games\Preserved.exe',
    );
  });

  testWidgets('Profile Manager shows delete feedback above the dialog', (
    WidgetTester tester,
  ) async {
    await _loadKonyakTestFonts();
    final goldenKey = GlobalKey();
    await tester.binding.setSurfaceSize(const Size(1100, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
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
        stdout: _profileManagerListPayload(
          id: 'user-synthetic',
          name: 'User Synthetic',
          sourceKind: 'user',
        ),
        stderr: '',
      ),
      ProcessRunResult(
        exitCode: 0,
        stdout: _profileManagerInspectPayload(
          id: 'user-synthetic',
          name: 'User Synthetic',
          sourceKind: 'user',
        ),
        stderr: '',
      ),
      ProcessRunResult(
        exitCode: 0,
        stdout: jsonEncode(<String, Object?>{
          'schemaVersion': 1,
          'installProfileMutation': <String, Object?>{
            'operation': 'delete',
            'profileId': 'user-synthetic',
            'profileDigest': 'a' * 64,
          },
        }),
        stderr: '',
      ),
      ProcessRunResult(
        exitCode: 0,
        stdout: jsonEncode(<String, Object?>{
          'schemaVersion': 1,
          'installProfiles': <Object?>[],
        }),
        stderr: '',
      ),
    ]);

    await tester.pumpWidget(
      RepaintBoundary(
        key: goldenKey,
        child: _testKonyakApp(
          cliClient: KonyakCliClient(
            executable: 'konyak',
            processRunner: runner,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Profile Manager'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('profile-manager-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    final feedback = find.text('Deleted user-synthetic');
    expect(feedback, findsOneWidget);
    expect(
      find.ancestor(of: feedback, matching: find.byType(ProfileManagerDialog)),
      findsOneWidget,
    );
    await _expectGoldenFileWithinTolerance(
      find.byKey(goldenKey),
      _goldenPathWithLinuxVariant('profile_manager_delete_feedback.png'),
      diffTolerance: 0.01,
    );
  });

  testWidgets(
    'Profile Manager exports duplicates and deletes without reopening',
    (WidgetTester tester) async {
      const builtinProfile = InstallProfileListItem(
        id: 'builtin-synthetic',
        name: 'Built-in Synthetic',
        profileVersion: 1,
        profileSourceKind: 'builtin',
        profileDigest:
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      );
      const duplicatedProfile = InstallProfileListItem(
        id: 'builtin-synthetic-copy',
        name: 'Built-in Synthetic Copy',
        profileVersion: 1,
        profileSourceKind: 'user',
        profileDigest:
            'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
            'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
        canEdit: true,
        canDelete: true,
      );
      final actionRequests = <ProfileManagerActionRequest>[];

      await tester.pumpWidget(
        MaterialApp(
          theme: konyakThemeData(konyakDarkColors),
          supportedLocales: KonyakLocalizations.supportedLocales,
          localizationsDelegates: KonyakLocalizations.localizationsDelegates,
          home: Scaffold(
            body: ProfileManagerDialog(
              bottleName: 'Synthetic',
              profiles: const [builtinProfile],
              programFilePicker: const _FakeProgramFilePicker(path: null),
              installProfileManifestPicker:
                  const _FakeInstallProfileManifestPicker(
                    exportPath: '/tmp/builtin-synthetic.json',
                  ),
              initialDirectory: '/bottles/synthetic/drive_c',
              inspectProfile: (profileId) async => InspectedInstallProfile(
                _profileManagerTestDetails(
                  id: profileId,
                  name: profileId == duplicatedProfile.id
                      ? duplicatedProfile.name
                      : builtinProfile.name,
                  sourceKind: profileId == duplicatedProfile.id
                      ? 'user'
                      : 'builtin',
                ),
              ),
              validateManifest: _acceptProfileManagerManifest,
              executeAction: (request) async {
                actionRequests.add(request);
                return switch (request) {
                  ExportProfileManagerActionRequest() =>
                    const UnchangedProfileManagerCatalog(),
                  DuplicateProfileManagerActionRequest() =>
                    const ReloadedProfileManagerCatalog(
                      profiles: [builtinProfile, duplicatedProfile],
                      selection: SelectProfileManagerCatalogProfile(
                        'builtin-synthetic-copy',
                      ),
                    ),
                  DeleteProfileManagerActionRequest() =>
                    const ReloadedProfileManagerCatalog(
                      profiles: [builtinProfile],
                      selection: SelectFirstProfileManagerCatalogProfile(),
                    ),
                  ImportProfileManagerActionRequest() ||
                  EditProfileManagerActionRequest() =>
                    const UnchangedProfileManagerCatalog(),
                };
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final programPathField = find.byKey(
        const ValueKey('profile-manager-program-path-field'),
      );
      await tester.ensureVisible(programPathField);
      await tester.enterText(programPathField, r'C:\Games\Preserved.exe');

      await tester.tap(find.text('Export...'));
      await tester.pumpAndSettle();
      expect(actionRequests.single, isA<ExportProfileManagerActionRequest>());
      expect(find.byType(ProfileManagerDialog), findsOneWidget);
      expect(
        tester.widget<TextField>(programPathField).controller?.text,
        r'C:\Games\Preserved.exe',
      );

      await tester.tap(find.text('Duplicate'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(actionRequests[1], isA<DuplicateProfileManagerActionRequest>());
      expect(
        tester
            .widget<ListTile>(
              find.byKey(
                const ValueKey(
                  'profile-manager-profile-builtin-synthetic-copy',
                ),
              ),
            )
            .selected,
        isTrue,
      );
      expect(
        tester.widget<TextField>(programPathField).controller?.text,
        r'C:\Games\Preserved.exe',
      );

      await tester.tap(find.byKey(const ValueKey('profile-manager-delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(actionRequests[2], isA<DeleteProfileManagerActionRequest>());
      expect(find.byType(ProfileManagerDialog), findsOneWidget);
      expect(find.text('Built-in Synthetic Copy'), findsNothing);
      expect(
        tester.widget<TextField>(programPathField).controller?.text,
        r'C:\Games\Preserved.exe',
      );
    },
  );

  testWidgets('Profile Manager cancellations preserve visible state', (
    WidgetTester tester,
  ) async {
    const builtinProfile = InstallProfileListItem(
      id: 'builtin-synthetic',
      name: 'Built-in Synthetic',
      profileVersion: 1,
      profileSourceKind: 'builtin',
      profileDigest:
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    );
    const userProfile = InstallProfileListItem(
      id: 'user-synthetic',
      name: 'User Synthetic',
      profileVersion: 1,
      profileSourceKind: 'user',
      profileDigest:
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      canEdit: true,
      canDelete: true,
    );
    final actionRequests = <ProfileManagerActionRequest>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: konyakThemeData(konyakDarkColors),
        supportedLocales: KonyakLocalizations.supportedLocales,
        localizationsDelegates: KonyakLocalizations.localizationsDelegates,
        home: Scaffold(
          body: ProfileManagerDialog(
            bottleName: 'Synthetic',
            profiles: const [builtinProfile, userProfile],
            programFilePicker: const _FakeProgramFilePicker(path: null),
            installProfileManifestPicker:
                const _FakeInstallProfileManifestPicker(),
            initialDirectory: '/bottles/synthetic/drive_c',
            inspectProfile: (profileId) async => InspectedInstallProfile(
              _profileManagerTestDetails(
                id: profileId,
                name: profileId == userProfile.id
                    ? userProfile.name
                    : builtinProfile.name,
                sourceKind: profileId == userProfile.id ? 'user' : 'builtin',
              ),
            ),
            validateManifest: _acceptProfileManagerManifest,
            executeAction: (request) async {
              actionRequests.add(request);
              return const UnchangedProfileManagerCatalog();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final programPathField = find.byKey(
      const ValueKey('profile-manager-program-path-field'),
    );
    await tester.ensureVisible(programPathField);
    await tester.enterText(programPathField, r'C:\Games\Preserved.exe');

    await tester.tap(find.text('Import...'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Export...'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Duplicate'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel').last);
    await tester.pumpAndSettle();

    expect(actionRequests, isEmpty);
    expect(
      tester
          .widget<ListTile>(
            find.byKey(
              const ValueKey('profile-manager-profile-builtin-synthetic'),
            ),
          )
          .selected,
      isTrue,
    );

    await tester.tap(
      find.byKey(const ValueKey('profile-manager-profile-user-synthetic')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('profile-manager-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel').last);
    await tester.pumpAndSettle();

    expect(actionRequests, isEmpty);
    expect(find.byType(ProfileManagerDialog), findsOneWidget);
    expect(
      tester
          .widget<ListTile>(
            find.byKey(
              const ValueKey('profile-manager-profile-user-synthetic'),
            ),
          )
          .selected,
      isTrue,
    );
    expect(
      tester.widget<TextField>(programPathField).controller?.text,
      r'C:\Games\Preserved.exe',
    );
  });

  testWidgets('Profile Manager confirms deletion of a user profile', (
    WidgetTester tester,
  ) async {
    ProfileManagerActionRequest? actionRequest;
    await tester.pumpWidget(
      MaterialApp(
        theme: konyakThemeData(konyakDarkColors),
        supportedLocales: KonyakLocalizations.supportedLocales,
        localizationsDelegates: KonyakLocalizations.localizationsDelegates,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                unawaited(
                  showDialog<ProfileManagerDecision>(
                    context: context,
                    builder: (context) => ProfileManagerDialog(
                      bottleName: 'Synthetic',
                      profiles: const [
                        InstallProfileListItem(
                          id: 'synthetic',
                          name: 'Synthetic',
                          profileVersion: 1,
                          profileSourceKind: 'user',
                          profileDigest:
                              'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
                              'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
                          canEdit: true,
                          canDelete: true,
                        ),
                      ],
                      programFilePicker: const _FakeProgramFilePicker(
                        path: null,
                      ),
                      installProfileManifestPicker:
                          const _FakeInstallProfileManifestPicker(),
                      initialDirectory: '/bottles/synthetic/drive_c',
                      validateManifest: _acceptProfileManagerManifest,
                      executeAction: (request) async {
                        actionRequest = request;
                        return const UnchangedProfileManagerCatalog();
                      },
                      inspectProfile: (_) async => InspectedInstallProfile(
                        _profileManagerTestDetails(sourceKind: 'user'),
                      ),
                    ),
                  ),
                );
              },
              child: const Text('Open manager'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open manager'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('profile-manager-delete')));
    await tester.pumpAndSettle();

    expect(find.text('Delete Synthetic?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(actionRequest, isA<DeleteProfileManagerActionRequest>());
    final deleteRequest = actionRequest as DeleteProfileManagerActionRequest;
    expect(deleteRequest.profileId, 'synthetic');
    expect(deleteRequest.expectedDigest, 'a' * 64);
    expect(find.byType(ProfileManagerDialog), findsOneWidget);
  });

  testWidgets('bottom bar Profile Manager action matches golden', (
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
                  showProfileManagerAction:
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
      'goldens/bottom_bar_profile_manager.png',
      diffTolerance: 0.05,
    );
  });

  testWidgets('Profile Manager installs a selected profile automatically', (
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
                  "path": "/bottles/steam",
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
              "installProfiles": [
                {"id": "steam", "name": "Steam", "profileVersion": 1}
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
              "installProfile": {
                "id": "steam",
                "name": "Steam",
                "profileVersion": 1,
                "profileSourceKind": "builtin",
                "profileSourceId": "steam.json",
                "profileDigest": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
                "summary": "Install Steam automatically.",
                "platforms": ["macos"],
                "bottleTemplate": {"windowsVersion": "win10"},
                "managedProgramPath": "C:\\\\Program Files (x86)\\\\Steam\\\\Steam.exe",
                "installerResource": {
                  "kind": "https",
                  "url": "https://cdn.example.test/SteamSetup.exe",
                  "sha256": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
                  "fileName": "SteamSetup.exe"
                },
                "preInstallActions": [{"kind":"winetricks","verb":"corefonts"}],
                "runCompletionPolicy": "waitForExit",
                "compatibilityProfile": {
                  "id": "steam",
                  "profileVersion": 1,
                  "childProcessRules": []
                }
              }
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
                "path": "/bottles/steam",
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
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Profile Manager'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Install automatically'));
    await tester.pump();

    expect(runner.argumentsLog.last, const [
      'install-program-profile',
      'steam',
      '--bottle',
      'steam',
      '--progress-json',
      '--json',
    ]);
    expect(find.text('Applying Steam...'), findsOneWidget);

    runner.emitStdoutLine(
      '{"schemaVersion":1,"programProfileInstallProgress":'
      '{"stage":"download","state":"started"}}',
    );
    await tester.pump();

    expect(find.text('Downloading Steam...'), findsOneWidget);

    installCompleter.complete(
      const ProcessRunResult(
        exitCode: 0,
        stdout:
            '{"schemaVersion":1,"programProfileInstall":'
            '{"stage":"persistence","programProfile":'
            '{"bottleId":"steam","profileId":"steam",'
            '"profileVersion":1,"managedProgramPath":'
            '"C:\\\\Program Files (x86)\\\\Steam\\\\Steam.exe",'
            '"compatibilityProfileId":"steam",'
            '"compatibilityProfileVersion":1}}}',
        stderr: '',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Installed Steam'), findsOneWidget);
    expect(runner.argumentsLog.last, const [
      'inspect-bottle',
      'steam',
      '--json',
    ]);
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

  testWidgets('bottom bar applies a selected program profile to an exe path', (
    WidgetTester tester,
  ) async {
    const selectedProgramPath =
        '/Users/user/Library/Application Support/Konyak/Bottles/Steam/drive_c/'
        'Program Files (x86)/Steam/Steam.exe';
    final listProfilesCompleter = Completer<ProcessRunResult>();
    final applyCompleter = Completer<ProcessRunResult>();
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
      listProfilesCompleter.future,
      Future.value(
        const ProcessRunResult(
          exitCode: 0,
          stdout: '''
            {
              "schemaVersion": 1,
              "installProfile": {
                "id": "steam",
              "name": "Steam",
              "profileVersion": 1,
              "profileSourceKind": "builtin",
              "profileSourceId": "steam.json",
              "profileDigest": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
              "summary": "Apply Konyak compatibility rules to an installed Steam executable.",
                "platforms": ["macos"],
                "bottleTemplate": {
                  "windowsVersion": "win10"
                },
                "managedProgramPath": "C:\\\\Program Files (x86)\\\\Steam\\\\Steam.exe",
                "installerResource": {
                  "kind": "https",
                  "url": "https://cdn.example.test/SteamSetup.exe",
                  "sha256": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
                  "fileName": "SteamSetup.exe"
                },
                "preInstallActions": [{"kind":"winetricks","verb":"corefonts"}],
                "runCompletionPolicy": "launchOnly",
                "compatibilityProfile": {
                  "id": "steam",
                  "profileVersion": 1,
                  "childProcessRules": [
                    {
                      "executableSuffix": "steamwebhelper.exe",
                      "appendArgumentsIfMissing": ["--no-sandbox", "--in-process-gpu", "--disable-gpu"]
                    }
                  ]
                }
              }
            }
          ''',
          stderr: '',
        ),
      ),
      applyCompleter.future,
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
          path: selectedProgramPath,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Profile Manager'));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('profile-manager-progress')),
      findsOneWidget,
    );
    expect(find.text('Loading install profiles...'), findsOneWidget);
    expect(runner.argumentsLog, [
      ['list-bottles', '--json'],
      ['list-install-profiles', '--json'],
    ]);

    listProfilesCompleter.complete(
      const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "installProfiles": [
              {
                "id": "steam",
                "name": "Steam",
                "profileVersion": 1
              }
            ]
          }
        ''',
        stderr: '',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Profile Manager in Steam'), findsOneWidget);
    expect(find.text('Steam'), findsWidgets);
    expect(find.text('launchOnly'), findsOneWidget);
    expect(runner.argumentsLog, [
      ['list-bottles', '--json'],
      ['list-install-profiles', '--json'],
      ['inspect-install-profile', 'steam', '--json'],
    ]);

    final chooseProgramButton = find.byTooltip('Choose program file');
    await tester.ensureVisible(chooseProgramButton);
    await tester.tap(chooseProgramButton);
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Apply to existing program'),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('profile-manager-progress')),
      findsOneWidget,
    );
    expect(find.text('Applying Steam...'), findsOneWidget);
    expect(runner.argumentsLog.last, [
      'apply-program-profile',
      'steam',
      '--bottle',
      'steam',
      '--program',
      selectedProgramPath,
      '--json',
    ]);

    applyCompleter.complete(
      const ProcessRunResult(
        exitCode: 0,
        stdout: '''
          {
            "schemaVersion": 1,
            "programProfile": {
              "bottleId": "steam",
              "profileId": "steam",
              "profileVersion": 1,
              "managedProgramPath": "C:\\\\Program Files (x86)\\\\Steam\\\\Steam.exe",
              "compatibilityProfileId": "steam",
              "compatibilityProfileVersion": 1
            }
          }
        ''',
        stderr: '',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('profile-manager-progress')),
      findsNothing,
    );
    expect(find.text('Applied Steam'), findsOneWidget);
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

Future<ProfileManagerManifestValidationResult> _acceptProfileManagerManifest(
  ProfileManagerManifestValidationRequest _,
) async {
  return const ValidProfileManagerManifest();
}

InstallProfileDetails _profileManagerTestDetails({
  required String sourceKind,
  String id = 'synthetic',
  String name = 'Synthetic',
}) {
  return InstallProfileDetails(
    id: id,
    name: name,
    profileVersion: 1,
    profileSourceKind: sourceKind,
    profileSourceId: 'synthetic.json',
    profileDigest: 'a' * 64,
    summary: 'Synthetic profile.',
    platforms: const ['macos'],
    windowsVersion: 'win10',
    managedProgramPath: r'C:\Synthetic\Synthetic.exe',
    installerResource: InstallerResourceSummary(
      kind: 'https',
      url: 'https://downloads.example.test/Setup.exe',
      sha256: 'b' * 64,
      fileName: 'Setup.exe',
    ),
    preInstallActions: const [],
    runCompletionPolicy: 'launchOnly',
    compatibilityProfile: CompatibilityProfileSummary(
      id: id,
      profileVersion: 1,
      childProcessRules: const [],
    ),
    manifestJson:
        '''{
  "schemaVersion": 1,
  "id": "$id",
  "name": "$name",
  "compatibilityProfile": {
    "id": "$id",
    "profileVersion": 1
  }
}''',
  );
}

String _profileManagerListPayload({
  required String id,
  required String name,
  required String sourceKind,
}) {
  return jsonEncode(<String, Object?>{
    'schemaVersion': 1,
    'installProfiles': <Object?>[
      <String, Object?>{
        'id': id,
        'name': name,
        'profileVersion': 1,
        'profileSourceKind': sourceKind,
        'profileDigest': 'a' * 64,
        'canEdit': sourceKind == 'user',
        'canDelete': sourceKind == 'user',
      },
    ],
  });
}

String _profileManagerInspectPayload({
  required String id,
  required String name,
  required String sourceKind,
}) {
  return jsonEncode(<String, Object?>{
    'schemaVersion': 1,
    'installProfile': <String, Object?>{
      ..._profileManagerProfilePayload(
        id: id,
        name: name,
        sourceKind: sourceKind,
      ),
      'manifest': _profileManagerManifestPayload(id: id, name: name),
    },
  });
}

String _profileManagerMutationPayload({
  required String operation,
  required String id,
  required String name,
}) {
  return jsonEncode(<String, Object?>{
    'schemaVersion': 1,
    'installProfileMutation': <String, Object?>{
      'operation': operation,
      'installProfile': _profileManagerProfilePayload(
        id: id,
        name: name,
        sourceKind: 'user',
      ),
    },
  });
}

Map<String, Object?> _profileManagerProfilePayload({
  required String id,
  required String name,
  required String sourceKind,
}) {
  return <String, Object?>{
    'id': id,
    'name': name,
    'profileVersion': 1,
    'profileSourceKind': sourceKind,
    'profileSourceId': '$id.json',
    'profileDigest': 'a' * 64,
    'summary': 'Synthetic profile.',
    'platforms': <String>['macos'],
    'bottleTemplate': <String, Object?>{'windowsVersion': 'win10'},
    'managedProgramPath': r'C:\Synthetic\Synthetic.exe',
    'installerResource': <String, Object?>{
      'kind': 'https',
      'url': 'https://downloads.example.test/Setup.exe',
      'sha256': 'b' * 64,
      'fileName': 'Setup.exe',
    },
    'preInstallActions': <Object?>[],
    'runCompletionPolicy': 'launchOnly',
    'compatibilityProfile': <String, Object?>{
      'id': id,
      'profileVersion': 1,
      'childProcessRules': <Object?>[],
    },
  };
}

Map<String, Object?> _profileManagerManifestPayload({
  required String id,
  required String name,
}) {
  return <String, Object?>{
    r'$schema': 'https://konyak.app/schemas/profile-v1.schema.json',
    'schemaVersion': 1,
    'id': id,
    'name': name,
    'profileVersion': 1,
    'summary': 'Synthetic profile.',
    'platforms': <String>['macos'],
    'windowsVersion': 'win10',
    'managedProgramPath': r'C:\Synthetic\Synthetic.exe',
    'installerResource': <String, Object?>{
      'kind': 'https',
      'url': 'https://downloads.example.test/Setup.exe',
      'sha256': 'b' * 64,
      'fileName': 'Setup.exe',
    },
    'preInstallActions': <Object?>[],
    'runCompletionPolicy': 'launchOnly',
    'compatibilityProfile': <String, Object?>{
      'id': id,
      'profileVersion': 1,
      'childProcessRules': <Object?>[],
    },
  };
}
