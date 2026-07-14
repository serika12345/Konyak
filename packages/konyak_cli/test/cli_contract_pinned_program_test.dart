import 'support/cli_contract_full_helpers.dart';

void main() {
  test('pin-program --json adds a pinned program to the bottle record', () {
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const DartIoProgramMetadataExtractor(),
      dataHome: '/home/user/.local/share/konyak',
    );
    runCli(const [
      'create-bottle',
      '--name',
      'Steam',
      '--json',
    ], bottleRepository: repository);

    final result = runCli(const [
      'pin-program',
      'steam',
      '--name',
      'Steam',
      '--program',
      '/downloads/Steam.exe',
      '--json',
    ], bottleRepository: repository);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'bottle': {
        'id': 'steam',
        'name': 'Steam',
        'path': '/home/user/.local/share/konyak/bottles/steam',
        'windowsVersion': 'win10',
        'pinnedPrograms': [
          {'name': 'Steam', 'path': '/downloads/Steam.exe', 'removable': false},
        ],
      },
    });
    expect(
      expectFound(
        repository.findBottle(BottleId('steam')),
      ).pinnedPrograms.single.path.value,
      '/downloads/Steam.exe',
    );
  });

  test('pin-program --json on macOS writes a Launchpad app launcher', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-macos-pinned-launcher-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final appBundle = createTestMacosAppBundle(tempDirectory.path);
    final iconPath = joinTestPath(tempDirectory.path, const [
      'steam-icon.icns',
    ]);
    File(iconPath).writeAsBytesSync(const <int>[0, 1, 2, 3]);
    final repository = MemoryBottleRepository(
      dataHome: joinTestPath(tempDirectory.path, const ['data']),
      programMetadataExtractor: FixedProgramMetadataExtractor(
        programPath: '/downloads/Steam.exe',
        metadata: ProgramMetadataRecord(
          iconPath: Option.of(ProgramIconPath(iconPath)),
        ),
      ),
    );
    runCli(const [
      'create-bottle',
      '--name',
      'Steam',
      '--json',
    ], bottleRepository: repository);

    final result = runCli(
      const [
        'pin-program',
        'steam',
        '--name',
        'Steam',
        '--program',
        '/downloads/Steam.exe',
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
        environment: HostEnvironment({
          'HOME': tempDirectory.path,
          'KONYAK_APP_EXECUTABLE': joinTestPath(appBundle.path, const [
            'Contents',
            'MacOS',
            'Konyak',
          ]),
        }),
      ),
    );

    expect(result.exitCode, 0);

    final launcherBundle = singleGeneratedMacosLauncher(tempDirectory.path);
    expect(launcherBundle.path, endsWith('/Steam.app'));

    final infoPlist = File(
      joinTestPath(launcherBundle.path, const ['Contents', 'Info.plist']),
    ).readAsStringSync();
    expect(infoPlist, contains('<string>app.konyak.Konyak.pinned.'));
    expect(infoPlist, contains('<key>CFBundleDisplayName</key>'));
    expect(infoPlist, contains('<string>Steam</string>'));
    expect(infoPlist, contains('<key>CFBundleIconFile</key>'));
    expect(infoPlist, contains('<string>KonyakPinnedProgram.icns</string>'));
    expect(infoPlist, contains('<string>konyak-launcher</string>'));
    expect(
      File(
        joinTestPath(launcherBundle.path, const [
          'Contents',
          'Resources',
          'KonyakPinnedProgram.icns',
        ]),
      ).readAsBytesSync(),
      const <int>[0, 1, 2, 3],
    );

    final manifest =
        jsonDecode(
              File(
                joinTestPath(launcherBundle.path, const [
                  'Contents',
                  'Resources',
                  'konyak-launcher.json',
                ]),
              ).readAsStringSync(),
            )
            as Map<String, Object?>;
    expect(manifest['schemaVersion'], 1);
    expect(manifest['createdBy'], 'app.konyak.Konyak');
    expect(manifest['bottleId'], 'steam');
    expect(manifest['programName'], 'Steam');
    expect(manifest['programPath'], '/downloads/Steam.exe');
    expect(manifest['launcherId'], isA<String>());

    final launcherExecutable = File(
      joinTestPath(launcherBundle.path, const [
        'Contents',
        'MacOS',
        'konyak-launcher',
      ]),
    );
    final launcherScript = launcherExecutable.readAsStringSync();
    expect(
      launcherScript,
      contains(
        joinTestPath(appBundle.path, const [
          'Contents',
          'Resources',
          'konyak-cli',
        ]),
      ),
    );
    expect(launcherScript, contains('launch-pinned-program'));
    expect(launcherScript, contains(r'--manifest "$manifest" --json'));
    expect(launcherExecutable.statSync().mode & 0x40, isNonZero);
  });

  test('pin-program --json on macOS disambiguates duplicate app names', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-macos-pinned-duplicate-launcher-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final appBundle = createTestMacosAppBundle(tempDirectory.path);
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: joinTestPath(tempDirectory.path, const ['data']),
    );
    runCli(const [
      'create-bottle',
      '--name',
      'Steam',
      '--json',
    ], bottleRepository: repository);
    runCli(const [
      'create-bottle',
      '--name',
      'Tools',
      '--json',
    ], bottleRepository: repository);
    final planner = ProgramRunPlanner(
      hostPlatform: KonyakHostPlatform.macos,
      environment: HostEnvironment({
        'HOME': tempDirectory.path,
        'KONYAK_APP_EXECUTABLE': joinTestPath(appBundle.path, const [
          'Contents',
          'MacOS',
          'Konyak',
        ]),
      }),
    );

    runCli(
      const [
        'pin-program',
        'steam',
        '--name',
        'Steam',
        '--program',
        '/downloads/Steam.exe',
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: planner,
    );
    runCli(
      const [
        'pin-program',
        'tools',
        '--name',
        'Steam',
        '--program',
        '/downloads/ToolsSteam.exe',
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: planner,
    );

    final launcherNames = generatedMacosLaunchers(
      tempDirectory.path,
    ).map((directory) => directory.path.split('/').last).toList();
    expect(launcherNames, const ['Steam (2).app', 'Steam.app']);
    final duplicateInfoPlist = File(
      joinTestPath(
        generatedMacosLaunchers(tempDirectory.path).first.path,
        const ['Contents', 'Info.plist'],
      ),
    ).readAsStringSync();
    expect(duplicateInfoPlist, contains('<string>Steam (2)</string>'));
  });

  test('pin-program --json on macOS writes a development CLI launcher', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-macos-pinned-dev-launcher-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: joinTestPath(tempDirectory.path, const ['data']),
    );
    runCli(const [
      'create-bottle',
      '--name',
      'Steam',
      '--json',
    ], bottleRepository: repository);

    final result = runCli(
      const [
        'pin-program',
        'steam',
        '--name',
        'Steam',
        '--program',
        '/downloads/Steam.exe',
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
        environment: HostEnvironment({
          'HOME': tempDirectory.path,
          'KONYAK_PINNED_PROGRAM_LAUNCHER_EXECUTABLE': '/env/flutter/bin/dart',
          'KONYAK_PINNED_PROGRAM_LAUNCHER_ARGUMENTS_JSON':
              '["run","bin/konyak.dart"]',
          'KONYAK_PINNED_PROGRAM_LAUNCHER_WORKING_DIRECTORY':
              '/repo/packages/konyak_cli',
        }),
      ),
    );

    expect(result.exitCode, 0);
    final launcherExecutable = File(
      joinTestPath(
        singleGeneratedMacosLauncher(tempDirectory.path).path,
        const ['Contents', 'MacOS', 'konyak-launcher'],
      ),
    );
    final launcherScript = launcherExecutable.readAsStringSync();
    expect(launcherScript, contains("cd '/repo/packages/konyak_cli'"));
    expect(
      launcherScript,
      contains(
        "exec '/env/flutter/bin/dart' 'run' 'bin/konyak.dart' launch-pinned-program",
      ),
    );
  });

  test('pin-program --json on Linux writes an app launcher entry', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-linux-pinned-launcher-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final xdgDataHome = joinTestPath(tempDirectory.path, const ['xdg-data']);
    final iconPath = joinTestPath(tempDirectory.path, const ['steam-icon.png']);
    File(iconPath).writeAsBytesSync(const <int>[137, 80, 78, 71]);
    final repository = MemoryBottleRepository(
      dataHome: joinTestPath(tempDirectory.path, const ['data']),
      programMetadataExtractor: FixedProgramMetadataExtractor(
        programPath: '/downloads/Steam.exe',
        metadata: ProgramMetadataRecord(
          iconPath: Option.of(ProgramIconPath(iconPath)),
        ),
      ),
    );
    runCli(const [
      'create-bottle',
      '--name',
      'Steam',
      '--json',
    ], bottleRepository: repository);

    final result = runCli(
      const [
        'pin-program',
        'steam',
        '--name',
        'Steam',
        '--program',
        '/downloads/Steam.exe',
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.linux,
        environment: HostEnvironment({
          'HOME': tempDirectory.path,
          'XDG_DATA_HOME': xdgDataHome,
          'KONYAK_PINNED_PROGRAM_LAUNCHER_EXECUTABLE': '/env/flutter/bin/dart',
          'KONYAK_PINNED_PROGRAM_LAUNCHER_ARGUMENTS_JSON':
              '["run","bin/konyak.dart"]',
          'KONYAK_PINNED_PROGRAM_LAUNCHER_WORKING_DIRECTORY':
              '/repo/packages/konyak_cli',
        }),
      ),
    );

    expect(result.exitCode, 0);

    final launcherEntry = singleGeneratedLinuxPinnedLauncher(xdgDataHome);
    expect(launcherEntry.path, contains('/applications/'));
    expect(launcherEntry.path, endsWith('.desktop'));
    final desktopEntry = launcherEntry.readAsStringSync();
    expect(desktopEntry, contains('Type=Application'));
    expect(desktopEntry, contains('Name=Steam'));
    expect(desktopEntry, isNot(contains('NoDisplay=true')));
    expect(desktopEntry, contains('Icon=$iconPath'));
    expect(desktopEntry, contains('StartupWMClass=steam.exe'));
    expect(desktopEntry, contains('Categories=Utility;'));

    final manifest = singleGeneratedLinuxPinnedManifest(xdgDataHome);
    final manifestPayload =
        jsonDecode(manifest.readAsStringSync()) as Map<String, Object?>;
    expect(manifestPayload['schemaVersion'], 1);
    expect(manifestPayload['createdBy'], 'app.konyak.Konyak');
    expect(manifestPayload['bottleId'], 'steam');
    expect(manifestPayload['programName'], 'Steam');
    expect(manifestPayload['programPath'], '/downloads/Steam.exe');
    expect(manifestPayload['launcherId'], isA<String>());

    final launcherScript = singleGeneratedLinuxPinnedScript(
      xdgDataHome,
    ).readAsStringSync();
    expect(launcherScript, contains("cd '/repo/packages/konyak_cli'"));
    expect(
      launcherScript,
      contains(
        "exec '/env/flutter/bin/dart' 'run' 'bin/konyak.dart' launch-pinned-program",
      ),
    );
    expect(launcherScript, contains(r'--manifest "$manifest" --json'));
  });

  test('pin-program --json on Linux writes a bundled CLI launcher', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-linux-pinned-bundled-launcher-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final xdgDataHome = joinTestPath(tempDirectory.path, const ['xdg-data']);
    final bundleResources = joinTestPath(tempDirectory.path, const [
      'AppDir',
      'usr',
      'share',
      'konyak',
    ]);
    final cliExecutable = joinTestPath(bundleResources, const ['konyak-cli']);
    File(cliExecutable)
      ..createSync(recursive: true)
      ..writeAsStringSync('cli');
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: joinTestPath(tempDirectory.path, const ['data']),
    );
    runCli(const [
      'create-bottle',
      '--name',
      'Steam',
      '--json',
    ], bottleRepository: repository);

    final result = runCli(
      const [
        'pin-program',
        'steam',
        '--name',
        'Steam',
        '--program',
        '/downloads/Steam.exe',
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.linux,
        environment: HostEnvironment({
          'HOME': tempDirectory.path,
          'XDG_DATA_HOME': xdgDataHome,
          'KONYAK_BUNDLE_RESOURCES': bundleResources,
        }),
      ),
    );

    expect(result.exitCode, 0);
    final launcherScript = singleGeneratedLinuxPinnedScript(
      xdgDataHome,
    ).readAsStringSync();
    expect(
      launcherScript,
      contains("exec '$cliExecutable' launch-pinned-program"),
    );
  });

  test(
    'pin-program --json on Linux prefers stable AppImage launcher dispatch',
    () {
      final tempDirectory = Directory.systemTemp.createTempSync(
        'konyak-linux-pinned-appimage-launcher-test-',
      );
      addTearDown(() {
        if (tempDirectory.existsSync()) {
          tempDirectory.deleteSync(recursive: true);
        }
      });
      final xdgDataHome = joinTestPath(tempDirectory.path, const ['xdg-data']);
      final appImage = joinTestPath(tempDirectory.path, const [
        'Konyak.AppImage',
      ]);
      File(appImage).writeAsStringSync('appimage');
      final repository = MemoryBottleRepository(
        programMetadataExtractor: const DartIoProgramMetadataExtractor(),
        dataHome: joinTestPath(tempDirectory.path, const ['data']),
      );
      runCli(const [
        'create-bottle',
        '--name',
        'Steam',
        '--json',
      ], bottleRepository: repository);

      final result = runCli(
        const [
          'pin-program',
          'steam',
          '--name',
          'Steam',
          '--program',
          '/downloads/Steam.exe',
          '--json',
        ],
        bottleRepository: repository,
        programRunPlanner: ProgramRunPlanner(
          hostPlatform: KonyakHostPlatform.linux,
          environment: HostEnvironment({
            'HOME': tempDirectory.path,
            'XDG_DATA_HOME': xdgDataHome,
            'KONYAK_APPIMAGE_PATH': appImage,
            'KONYAK_PINNED_PROGRAM_LAUNCHER_EXECUTABLE':
                '/tmp/.mount_Konyak/usr/share/konyak/konyak-cli',
            'KONYAK_PINNED_PROGRAM_LAUNCHER_ARGUMENTS_JSON': '[]',
          }),
        ),
      );

      expect(result.exitCode, 0);
      final launcherScript = singleGeneratedLinuxPinnedScript(
        xdgDataHome,
      ).readAsStringSync();
      expect(
        launcherScript,
        contains("exec '$appImage' '--konyak-cli' launch-pinned-program"),
      );
      expect(launcherScript, isNot(contains('/tmp/.mount_Konyak')));
    },
  );

  test('list-bottles --json on Linux refreshes app launchers', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-linux-pinned-list-refresh-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final xdgDataHome = joinTestPath(tempDirectory.path, const ['xdg-data']);
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: joinTestPath(tempDirectory.path, const ['data']),
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: joinTestPath(tempDirectory.path, const ['data', 'steam']),
          windowsVersion: 'win10',
          pinnedPrograms: [
            PinnedProgramRecord(name: 'Steam', path: '/downloads/Steam.exe'),
          ],
        ),
      ],
    );
    final staleDesktopEntry = File(
      joinTestPath(xdgDataHome, const [
        'applications',
        'app.konyak.Konyak.pinned.stale.desktop',
      ]),
    );
    staleDesktopEntry
      ..createSync(recursive: true)
      ..writeAsStringSync('[Desktop Entry]\nName=Stale\n');
    final staleManifest = File(
      joinTestPath(xdgDataHome, const [
        'konyak',
        'launchers',
        'linux-pinned',
        'stale',
        'konyak-launcher.json',
      ]),
    );
    staleManifest
      ..createSync(recursive: true)
      ..writeAsStringSync(
        jsonEncode({
          'schemaVersion': 1,
          'createdBy': 'app.konyak.Konyak',
          'launcherId': 'stale',
          'bottleId': 'stale',
          'programPath': '/stale.exe',
          'programName': 'Stale',
        }),
      );

    final result = runCli(
      const ['list-bottles', '--json'],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.linux,
        environment: HostEnvironment({
          'HOME': tempDirectory.path,
          'XDG_DATA_HOME': xdgDataHome,
          'KONYAK_PINNED_PROGRAM_LAUNCHER_EXECUTABLE': '/env/bin/dart',
          'KONYAK_PINNED_PROGRAM_LAUNCHER_ARGUMENTS_JSON':
              '["run","bin/konyak.dart"]',
          'KONYAK_PINNED_PROGRAM_LAUNCHER_WORKING_DIRECTORY':
              '/repo/packages/konyak_cli',
        }),
      ),
    );

    expect(result.exitCode, 0);
    expect(generatedLinuxPinnedLaunchers(xdgDataHome), hasLength(1));
    expect(generatedLinuxPinnedManifests(xdgDataHome), hasLength(1));
    expect(staleDesktopEntry.existsSync(), isFalse);
    expect(staleManifest.parent.existsSync(), isFalse);
  });

  test('list-bottles --json prunes missing bottle-local pinned programs', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-pinned-prune-list-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final bottlePath = joinTestPath(tempDirectory.path, const ['Steam']);
    final shortcutPath = joinTestPath(bottlePath, const [
      'drive_c',
      'ProgramData',
      'Microsoft',
      'Windows',
      'Start Menu',
      'Programs',
      'Steam.lnk',
    ]);
    File(shortcutPath)
      ..createSync(recursive: true)
      ..writeAsStringSync('shortcut');
    final externalPath = joinTestPath(tempDirectory.path, const [
      'Downloads',
      'portable.exe',
    ]);
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const DartIoProgramMetadataExtractor(),
      dataHome: tempDirectory.path,
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: bottlePath,
          windowsVersion: 'win10',
          pinnedPrograms: [
            PinnedProgramRecord(name: 'Steam', path: shortcutPath),
            PinnedProgramRecord(name: 'Portable', path: externalPath),
          ],
        ),
      ],
    );
    File(shortcutPath).deleteSync();

    final result = runCli(const [
      'list-bottles',
      '--json',
    ], bottleRepository: repository);

    expect(result.exitCode, 0);
    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    final bottles = payload['bottles'] as List<Object?>;
    final bottle = bottles.single as Map<String, Object?>;
    final pinnedPrograms = bottle['pinnedPrograms'] as List<Object?>;
    expect(pinnedPrograms, hasLength(1));
    expect(pinnedPrograms.single, containsPair('path', externalPath));
  });

  test('list-bottle-programs --json omits stale bottle-local pins', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-pinned-prune-program-list-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final bottlePath = joinTestPath(tempDirectory.path, const ['Steam']);
    final shortcutPath = joinTestPath(bottlePath, const [
      'drive_c',
      'ProgramData',
      'Microsoft',
      'Windows',
      'Start Menu',
      'Programs',
      'Steam.lnk',
    ]);
    File(shortcutPath)
      ..createSync(recursive: true)
      ..writeAsStringSync('shortcut');
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const DartIoProgramMetadataExtractor(),
      dataHome: tempDirectory.path,
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: bottlePath,
          windowsVersion: 'win10',
          pinnedPrograms: [
            PinnedProgramRecord(name: 'Steam', path: shortcutPath),
          ],
        ),
      ],
    );
    File(shortcutPath).deleteSync();

    final result = runCli(const [
      'list-bottle-programs',
      'steam',
      '--json',
    ], bottleRepository: repository);

    expect(result.exitCode, 0);
    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    final bottlePrograms = payload['bottlePrograms'] as Map<String, Object?>;
    expect(bottlePrograms['programs'], isEmpty);
  });

  test('list-bottles --json prunes pinned shortcuts with missing targets', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-pinned-prune-shortcut-target-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final bottlePath = joinTestPath(tempDirectory.path, const ['Steam']);
    final programPath = joinTestPath(bottlePath, const [
      'drive_c',
      'Program Files',
      'Steam',
      'Steam.exe',
    ]);
    File(programPath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(syntheticPortableExecutableBytes());
    final shortcutPath = joinTestPath(bottlePath, const [
      'drive_c',
      'ProgramData',
      'Microsoft',
      'Windows',
      'Start Menu',
      'Programs',
      'Steam.lnk',
    ]);
    File(shortcutPath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(
        syntheticShellLinkBytes(
          localBasePath: r'C:\Program Files\Steam\Steam.exe',
        ),
      );
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: tempDirectory.path,
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: bottlePath,
          windowsVersion: 'win10',
          pinnedPrograms: [
            PinnedProgramRecord(name: 'Steam', path: shortcutPath),
          ],
        ),
      ],
    );
    File(programPath).deleteSync();

    final result = runCli(const [
      'list-bottles',
      '--json',
    ], bottleRepository: repository);

    expect(result.exitCode, 0);
    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    final bottles = payload['bottles'] as List<Object?>;
    final bottle = bottles.single as Map<String, Object?>;
    expect(bottle['pinnedPrograms'] ?? const <Object?>[], isEmpty);
  });

  test('list-bottles --json repairs stale bottle-local pinned metadata', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-pinned-prune-file-repair-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final repository = FileBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: tempDirectory.path,
    );
    final createResult = repository.createBottle(
      BottleCreateRequest(
        name: BottleName('Steam'),
        windowsVersion: WindowsVersion('win10'),
      ),
    );
    expect(createResult, isA<BottleCreated>());
    final bottle = (createResult as BottleCreated).bottle;
    final shortcutPath = joinTestPath(bottle.path.value, const [
      'drive_c',
      'ProgramData',
      'Microsoft',
      'Windows',
      'Start Menu',
      'Programs',
      'Steam.lnk',
    ]);
    File(shortcutPath)
      ..createSync(recursive: true)
      ..writeAsStringSync('shortcut');
    final pinResult = repository.pinProgram(
      ProgramPinRequest(
        bottleId: bottle.id,
        name: ProgramName('Steam'),
        programPath: ProgramPath(shortcutPath),
      ),
    );
    expect(pinResult, isA<ProgramPinned>());
    File(shortcutPath).deleteSync();

    final result = runCli(const [
      'list-bottles',
      '--json',
    ], bottleRepository: repository);

    expect(result.exitCode, 0);
    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    final bottles = payload['bottles'] as List<Object?>;
    final listedBottle = bottles.single as Map<String, Object?>;
    expect(listedBottle['pinnedPrograms'] ?? const <Object?>[], isEmpty);

    final metadata =
        jsonDecode(
              File(
                joinTestPath(bottle.path.value, const ['metadata.json']),
              ).readAsStringSync(),
            )
            as Map<String, Object?>;
    final metadataBottle = metadata['bottle'] as Map<String, Object?>;
    expect(metadataBottle['pinnedPrograms'] ?? const <Object?>[], isEmpty);
  });

  test('rename-pinned-program --json on Linux updates the app launcher', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-linux-pinned-rename-launcher-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final xdgDataHome = joinTestPath(tempDirectory.path, const ['xdg-data']);
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: joinTestPath(tempDirectory.path, const ['data']),
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: joinTestPath(tempDirectory.path, const ['data', 'steam']),
          windowsVersion: 'win10',
          pinnedPrograms: [
            PinnedProgramRecord(name: 'Steam', path: '/downloads/Steam.exe'),
          ],
        ),
      ],
    );
    final planner = ProgramRunPlanner(
      hostPlatform: KonyakHostPlatform.linux,
      environment: HostEnvironment({
        'HOME': tempDirectory.path,
        'XDG_DATA_HOME': xdgDataHome,
        'KONYAK_PINNED_PROGRAM_LAUNCHER_EXECUTABLE': '/env/bin/dart',
        'KONYAK_PINNED_PROGRAM_LAUNCHER_ARGUMENTS_JSON':
            '["run","bin/konyak.dart"]',
        'KONYAK_PINNED_PROGRAM_LAUNCHER_WORKING_DIRECTORY':
            '/repo/packages/konyak_cli',
      }),
    );
    runCli(
      const ['list-bottles', '--json'],
      bottleRepository: repository,
      programRunPlanner: planner,
    );

    final result = runCli(
      const [
        'rename-pinned-program',
        'steam',
        '--program',
        '/downloads/Steam.exe',
        '--name',
        'Steam Client',
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: planner,
    );

    expect(result.exitCode, 0);
    final desktopEntry = singleGeneratedLinuxPinnedLauncher(
      xdgDataHome,
    ).readAsStringSync();
    expect(desktopEntry, contains('Name=Steam Client'));
  });

  test('unpin-program --json on Linux removes the app launcher', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-linux-pinned-unpin-launcher-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final xdgDataHome = joinTestPath(tempDirectory.path, const ['xdg-data']);
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: joinTestPath(tempDirectory.path, const ['data']),
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: joinTestPath(tempDirectory.path, const ['data', 'steam']),
          windowsVersion: 'win10',
          pinnedPrograms: [
            PinnedProgramRecord(name: 'Steam', path: '/downloads/Steam.exe'),
          ],
        ),
      ],
    );
    final planner = ProgramRunPlanner(
      hostPlatform: KonyakHostPlatform.linux,
      environment: HostEnvironment({
        'HOME': tempDirectory.path,
        'XDG_DATA_HOME': xdgDataHome,
        'KONYAK_PINNED_PROGRAM_LAUNCHER_EXECUTABLE': '/env/bin/dart',
        'KONYAK_PINNED_PROGRAM_LAUNCHER_ARGUMENTS_JSON':
            '["run","bin/konyak.dart"]',
        'KONYAK_PINNED_PROGRAM_LAUNCHER_WORKING_DIRECTORY':
            '/repo/packages/konyak_cli',
      }),
    );
    runCli(
      const ['list-bottles', '--json'],
      bottleRepository: repository,
      programRunPlanner: planner,
    );
    expect(generatedLinuxPinnedLaunchers(xdgDataHome), hasLength(1));

    final result = runCli(
      const [
        'unpin-program',
        'steam',
        '--program',
        '/downloads/Steam.exe',
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: planner,
    );

    expect(result.exitCode, 0);
    expect(generatedLinuxPinnedLaunchers(xdgDataHome), isEmpty);
    expect(generatedLinuxPinnedManifests(xdgDataHome), isEmpty);
  });

  test('list-bottles --json on macOS refreshes app launchers', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-macos-pinned-list-refresh-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: joinTestPath(tempDirectory.path, const ['data']),
    );
    runCli(const [
      'create-bottle',
      '--name',
      'Steam',
      '--json',
    ], bottleRepository: repository);
    runCli(
      const [
        'pin-program',
        'steam',
        '--name',
        'Steam',
        '--program',
        '/downloads/Steam.exe',
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.linux,
        environment: HostEnvironment({'HOME': tempDirectory.path}),
      ),
    );

    final result = runCli(
      const ['list-bottles', '--json'],
      bottleRepository: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.macos,
        environment: HostEnvironment({
          'HOME': tempDirectory.path,
          'KONYAK_PINNED_PROGRAM_LAUNCHER_EXECUTABLE': '/env/bin/dart',
          'KONYAK_PINNED_PROGRAM_LAUNCHER_ARGUMENTS_JSON':
              '["run","bin/konyak.dart"]',
          'KONYAK_PINNED_PROGRAM_LAUNCHER_WORKING_DIRECTORY':
              '/repo/packages/konyak_cli',
        }),
      ),
    );

    expect(result.exitCode, 0);
    final launcherScript = File(
      joinTestPath(
        singleGeneratedMacosLauncher(tempDirectory.path).path,
        const ['Contents', 'MacOS', 'konyak-launcher'],
      ),
    ).readAsStringSync();
    expect(launcherScript, contains("exec '/env/bin/dart' 'run'"));
  });

  test('unpin-program --json on macOS removes the Launchpad app launcher', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-macos-pinned-unpin-launcher-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final appBundle = createTestMacosAppBundle(tempDirectory.path);
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: joinTestPath(tempDirectory.path, const ['data']),
    );
    runCli(const [
      'create-bottle',
      '--name',
      'Steam',
      '--json',
    ], bottleRepository: repository);
    final planner = ProgramRunPlanner(
      hostPlatform: KonyakHostPlatform.macos,
      environment: HostEnvironment({
        'HOME': tempDirectory.path,
        'KONYAK_APP_EXECUTABLE': joinTestPath(appBundle.path, const [
          'Contents',
          'MacOS',
          'Konyak',
        ]),
      }),
    );
    runCli(
      const [
        'pin-program',
        'steam',
        '--name',
        'Steam',
        '--program',
        '/downloads/Steam.exe',
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: planner,
    );

    expect(generatedMacosLaunchers(tempDirectory.path), hasLength(1));

    final result = runCli(
      const [
        'unpin-program',
        'steam',
        '--program',
        '/downloads/Steam.exe',
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: planner,
    );

    expect(result.exitCode, 0);
    expect(generatedMacosLaunchers(tempDirectory.path), isEmpty);
  });

  test('launch-pinned-program --json runs the pinned program manifest', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-macos-pinned-launch-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final appBundle = createTestMacosAppBundle(tempDirectory.path);
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: joinTestPath(tempDirectory.path, const ['data']),
    );
    runCli(const [
      'create-bottle',
      '--name',
      'Steam',
      '--json',
    ], bottleRepository: repository);
    final planner = ProgramRunPlanner(
      hostPlatform: KonyakHostPlatform.macos,
      environment: HostEnvironment({
        'HOME': tempDirectory.path,
        'KONYAK_APP_EXECUTABLE': joinTestPath(appBundle.path, const [
          'Contents',
          'MacOS',
          'Konyak',
        ]),
      }),
    );
    runCli(
      const [
        'pin-program',
        'steam',
        '--name',
        'Steam',
        '--program',
        '/downloads/Steam.exe',
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: planner,
    );
    runCli(
      [
        'set-program-settings',
        'steam',
        '--program',
        '/downloads/Steam.exe',
        '--settings-json',
        jsonEncode({
          'logging': {
            'createLogFile': true,
            'additionalWineLoggingChannels': '+relay',
            'logFilePath': '/tmp/pinned-steam.cxlog',
          },
        }),
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: planner,
    );
    final manifestPath = joinTestPath(
      singleGeneratedMacosLauncher(tempDirectory.path).path,
      const ['Contents', 'Resources', 'konyak-launcher.json'],
    );
    final runner = RecordingProgramRunner(
      result: const ProgramRunCompleted(processExitCode: 0),
    );

    final result = runCli(
      ['launch-pinned-program', '--manifest', manifestPath, '--json'],
      bottleRepository: repository,
      programRunPlanner: planner,
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload['schemaVersion'], 1);
    expect(payload['run'], isA<Map<String, Object?>>());
    expect(runner.lastRequest?.bottleId.value, 'steam');
    expect(runner.lastRequest?.programPath.value, '/downloads/Steam.exe');
    expect(runner.lastRequest?.runnerKind.value, 'macosWine');
    expect(runner.lastRequest?.createLogFile, isTrue);
    expect(runner.lastRequest?.logPath.value, '/tmp/pinned-steam.cxlog');
    expect(
      runner.lastRequest?.environment.toMap(),
      containsPair('WINEDEBUG', '+relay'),
    );
  });

  test('launch-pinned-program --json falls back from D3DMetal for D3D10', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-macos-pinned-d3d10-fallback-launch-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    final appBundle = createTestMacosAppBundle(tempDirectory.path);
    final runtimeRoot = joinTestPath(tempDirectory.path, const ['runtime']);
    final bottlePath = joinTestPath(tempDirectory.path, const [
      'bottles',
      'steam',
    ]);
    final programPath = joinTestPath(bottlePath, const [
      'drive_c',
      'Games',
      'D3D10Game.exe',
    ]);
    File(programPath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(
        syntheticPortableExecutableBytes(importDllNames: const ['d3d10.dll']),
      );
    for (final dllName in gptkD3DMetalOverrideDllNames) {
      final runtimeFile = File(
        joinTestPath(runtimeRoot, [
          'components',
          'gptk-d3dmetal',
          'lib',
          'wine',
          'x86_64-windows',
          dllName,
        ]),
      );
      runtimeFile.parent.createSync(recursive: true);
      runtimeFile.writeAsStringSync('d3dmetal/$dllName');
      final staleFile = File(
        joinTestPath(bottlePath, ['drive_c', 'windows', 'system32', dllName]),
      );
      staleFile.parent.createSync(recursive: true);
      staleFile.writeAsStringSync('stale $dllName');
    }

    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: joinTestPath(tempDirectory.path, const ['data']),
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: bottlePath,
          windowsVersion: 'win10',
          runtimeSettings: Option.of(BottleRuntimeSettings(dxrEnabled: true)),
        ),
      ],
    );
    final planner = ProgramRunPlanner(
      hostPlatform: KonyakHostPlatform.macos,
      environment: HostEnvironment({
        'HOME': tempDirectory.path,
        'KONYAK_APP_EXECUTABLE': joinTestPath(appBundle.path, const [
          'Contents',
          'MacOS',
          'Konyak',
        ]),
        'KONYAK_MACOS_WINE_HOME': runtimeRoot,
      }),
    );

    final pinResult = runCli(
      [
        'pin-program',
        'steam',
        '--name',
        'D3D10 Game',
        '--program',
        programPath,
        '--json',
      ],
      bottleRepository: repository,
      programRunPlanner: planner,
    );
    expect(pinResult.exitCode, 0);
    expect(pinResult.stderr, isEmpty);
    final manifestPath = joinTestPath(
      singleGeneratedMacosLauncher(tempDirectory.path).path,
      const ['Contents', 'Resources', 'konyak-launcher.json'],
    );
    final runner = RecordingProgramRunner(
      result: const ProgramRunCompleted(processExitCode: 0),
    );

    final result = runCli(
      ['launch-pinned-program', '--manifest', manifestPath, '--json'],
      bottleRepository: repository,
      programRunPlanner: planner,
      programGraphicsBackendHintsInspector:
          const DartIoProgramGraphicsBackendHintsInspector(),
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    final environment = runner.lastRequest?.environment.toMap();
    expect(
      environment?['WINEDLLPATH'],
      macosManagedWineDllPathWithOverrides(runtimeRoot, const []),
    );
    expect(
      environment,
      containsPair('KONYAK_GRAPHICS_BACKEND_REQUESTED', 'gptk-d3dmetal'),
    );
    expect(
      environment,
      containsPair('KONYAK_GRAPHICS_BACKEND_SELECTED', 'wined3d-vulkan'),
    );
    expect(
      environment,
      containsPair(
        'KONYAK_GRAPHICS_BACKEND_FALLBACK_REASON',
        'gptkD3d10Unsupported',
      ),
    );
    for (final dllName in gptkD3DMetalOverrideDllNames) {
      expect(
        File(
          joinTestPath(bottlePath, ['drive_c', 'windows', 'system32', dllName]),
        ).existsSync(),
        isFalse,
      );
    }
  });

  test('pin-program --json extracts an icon for pinned PE programs', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'konyak-pin-program-icon-test-',
    );
    addTearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });
    final bottlePath = joinTestPath(tempDirectory.path, const ['Steam']);
    final programPath = joinTestPath(bottlePath, const [
      'drive_c',
      'Program Files',
      'Fixture',
      'Fixture.exe',
    ]);
    File(programPath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(syntheticPortableExecutableBytes());
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const DartIoProgramMetadataExtractor(),
      dataHome: tempDirectory.path,
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: bottlePath,
          windowsVersion: 'win10',
        ),
      ],
    );

    final result = runCli([
      'pin-program',
      'steam',
      '--name',
      'Fixture',
      '--program',
      programPath,
      '--json',
    ], bottleRepository: repository);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    final bottle = payload['bottle'] as Map<String, Object?>;
    final pinnedPrograms = bottle['pinnedPrograms'] as List<Object?>;
    final pinnedProgram = pinnedPrograms.single as Map<String, Object?>;
    final iconPath = pinnedProgram['iconPath'];
    expect(iconPath, isA<String>());
    expect(iconPath as String, startsWith('$bottlePath/cache/icons/'));
    final iconBytes = File(iconPath).readAsBytesSync();
    expect(iconBytes.take(4), const [0, 0, 1, 0]);
  });

  test(
    'pin-program --json extracts an icon for Windows-path PE programs',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'konyak-pin-windows-program-icon-test-',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });
      final bottlePath = joinTestPath(tempDirectory.path, const ['Steam']);
      final programPath = joinTestPath(bottlePath, const [
        'drive_c',
        'Program Files',
        'Fixture',
        'Fixture.exe',
      ]);
      File(programPath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(syntheticPortableExecutableBytes());
      final repository = MemoryBottleRepository(
        programMetadataExtractor: const DartIoProgramMetadataExtractor(),
        dataHome: tempDirectory.path,
        bottles: [
          BottleRecord(
            id: 'steam',
            name: 'Steam',
            path: bottlePath,
            windowsVersion: 'win10',
          ),
        ],
      );
      const windowsProgramPath = r'C:\Program Files\Fixture\Fixture.exe';

      final result = runCli(const [
        'pin-program',
        'steam',
        '--name',
        'Fixture',
        '--program',
        windowsProgramPath,
        '--json',
      ], bottleRepository: repository);

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);

      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      final bottle = payload['bottle'] as Map<String, Object?>;
      final pinnedPrograms = bottle['pinnedPrograms'] as List<Object?>;
      final pinnedProgram = pinnedPrograms.single as Map<String, Object?>;
      expect(pinnedProgram['path'], windowsProgramPath);
      final iconPath = pinnedProgram['iconPath'];
      expect(iconPath, isA<String>());
      expect(iconPath as String, startsWith('$bottlePath/cache/icons/'));
      final iconBytes = File(iconPath).readAsBytesSync();
      expect(iconBytes.take(4), const [0, 0, 1, 0]);
    },
  );

  test(
    'pin-program --json resolves Wine shortcuts before extracting icons',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'konyak-pin-shortcut-icon-test-',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });
      final bottlePath = joinTestPath(tempDirectory.path, const ['Steam']);
      final programPath = joinTestPath(bottlePath, const [
        'drive_c',
        'Program Files',
        'Fixture',
        'Fixture.exe',
      ]);
      File(programPath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(syntheticPortableExecutableBytes());
      final shortcutPath = joinTestPath(bottlePath, const [
        'drive_c',
        'ProgramData',
        'Microsoft',
        'Windows',
        'Start Menu',
        'Programs',
        'Fixture.lnk',
      ]);
      File(shortcutPath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(
          syntheticShellLinkBytes(
            localBasePath: r'C:\Program Files\Fixture\Fixture.exe',
          ),
        );
      final repository = MemoryBottleRepository(
        programMetadataExtractor: const DartIoProgramMetadataExtractor(),
        dataHome: tempDirectory.path,
        bottles: [
          BottleRecord(
            id: 'steam',
            name: 'Steam',
            path: bottlePath,
            windowsVersion: 'win10',
          ),
        ],
      );

      final result = runCli([
        'pin-program',
        'steam',
        '--name',
        'Fixture',
        '--program',
        shortcutPath,
        '--json',
      ], bottleRepository: repository);

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);

      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      final bottle = payload['bottle'] as Map<String, Object?>;
      final pinnedPrograms = bottle['pinnedPrograms'] as List<Object?>;
      final pinnedProgram = pinnedPrograms.single as Map<String, Object?>;

      expect(pinnedProgram['path'], shortcutPath);
      final iconPath = pinnedProgram['iconPath'];
      expect(iconPath, isA<String>());
      expect(iconPath as String, startsWith('$bottlePath/cache/icons/'));
      final iconBytes = File(iconPath).readAsBytesSync();
      expect(iconBytes.take(4), const [0, 0, 1, 0]);
    },
  );

  test(
    'list-bottles --json extracts icons for existing pinned PE programs',
    () {
      final tempDirectory = Directory.systemTemp.createTempSync(
        'konyak-existing-pinned-program-icon-test-',
      );
      addTearDown(() {
        if (tempDirectory.existsSync()) {
          tempDirectory.deleteSync(recursive: true);
        }
      });
      final bottlePath = joinTestPath(tempDirectory.path, const ['Steam']);
      final programPath = joinTestPath(bottlePath, const [
        'drive_c',
        'Program Files',
        'Fixture',
        'Fixture.exe',
      ]);
      File(programPath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(syntheticPortableExecutableBytes());
      final repository = MemoryBottleRepository(
        programMetadataExtractor: const DartIoProgramMetadataExtractor(),
        dataHome: tempDirectory.path,
        bottles: [
          BottleRecord(
            id: 'steam',
            name: 'Steam',
            path: bottlePath,
            windowsVersion: 'win10',
            pinnedPrograms: [
              PinnedProgramRecord(name: 'Fixture', path: programPath),
            ],
          ),
        ],
      );

      final result = runCli(const [
        'list-bottles',
        '--json',
      ], bottleRepository: repository);

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);

      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      final bottles = payload['bottles'] as List<Object?>;
      final bottle = bottles.single as Map<String, Object?>;
      final pinnedPrograms = bottle['pinnedPrograms'] as List<Object?>;
      final pinnedProgram = pinnedPrograms.single as Map<String, Object?>;
      final iconPath = pinnedProgram['iconPath'];
      expect(iconPath, isA<String>());
      expect(iconPath as String, startsWith('$bottlePath/cache/icons/'));
    },
  );

  test('list-bottles --json extracts icons for existing Windows-path pins', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-existing-windows-pinned-program-icon-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final bottlePath = joinTestPath(tempDirectory.path, const ['Steam']);
    final programPath = joinTestPath(bottlePath, const [
      'drive_c',
      'Program Files',
      'Fixture',
      'Fixture.exe',
    ]);
    File(programPath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(syntheticPortableExecutableBytes());
    const windowsProgramPath = r'C:\Program Files\Fixture\Fixture.exe';
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const DartIoProgramMetadataExtractor(),
      dataHome: tempDirectory.path,
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: bottlePath,
          windowsVersion: 'win10',
          pinnedPrograms: [
            PinnedProgramRecord(name: 'Fixture', path: windowsProgramPath),
          ],
        ),
      ],
    );

    final result = runCli(const [
      'list-bottles',
      '--json',
    ], bottleRepository: repository);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    final bottles = payload['bottles'] as List<Object?>;
    final bottle = bottles.single as Map<String, Object?>;
    final pinnedPrograms = bottle['pinnedPrograms'] as List<Object?>;
    final pinnedProgram = pinnedPrograms.single as Map<String, Object?>;
    expect(pinnedProgram['path'], windowsProgramPath);
    final iconPath = pinnedProgram['iconPath'];
    expect(iconPath, isA<String>());
    expect(iconPath as String, startsWith('$bottlePath/cache/icons/'));
  });

  test(
    'list-bottles --json preserves a malformed persisted Windows-path pin without an icon',
    () {
      final tempDirectory = Directory.systemTemp.createTempSync(
        'konyak-malformed-windows-pinned-program-test-',
      );
      addTearDown(() {
        if (tempDirectory.existsSync()) {
          tempDirectory.deleteSync(recursive: true);
        }
      });
      const malformedDotPath = r'C:\..\outside.exe';
      final repository = FileBottleRepository(
        programMetadataExtractor: const DartIoProgramMetadataExtractor(),
        dataHome: tempDirectory.path,
      );
      final createResult = repository.createBottle(
        BottleCreateRequest(
          name: BottleName('Steam'),
          windowsVersion: WindowsVersion('win10'),
        ),
      );
      expect(createResult, isA<BottleCreated>());
      final bottle = (createResult as BottleCreated).bottle;
      final malformedPaths = <String, String>{
        'Malformed Dot': malformedDotPath,
        'Malformed Control': 'C:\\Games\\\u0000outside.exe',
      };
      for (final entry in malformedPaths.entries) {
        final pinResult = repository.pinProgram(
          ProgramPinRequest(
            bottleId: bottle.id,
            name: ProgramName(entry.key),
            programPath: ProgramPath(entry.value),
          ),
        );
        expect(pinResult, isA<ProgramPinned>());
      }

      final result = runCli(const [
        'list-bottles',
        '--json',
      ], bottleRepository: repository);

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);
      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      final bottles = payload['bottles'] as List<Object?>;
      final listedBottle = bottles.single as Map<String, Object?>;
      final pinnedPrograms = listedBottle['pinnedPrograms'] as List<Object?>;
      expect(pinnedPrograms, hasLength(malformedPaths.length));
      final listedPrograms = pinnedPrograms.cast<Map<String, Object?>>();
      final listedByPath = <String, Map<String, Object?>>{
        for (final item in listedPrograms) item['path']! as String: item,
      };
      for (final malformedPath in malformedPaths.values) {
        expect(listedByPath, contains(malformedPath));
        expect(listedByPath[malformedPath], isNot(contains('iconPath')));
      }

      final storedBottle = expectFound(repository.findBottle(bottle.id));
      expect(storedBottle.pinnedPrograms, hasLength(malformedPaths.length));
      for (final storedPin in storedBottle.pinnedPrograms) {
        expect(malformedPaths.values, contains(storedPin.path.value));
        expect(storedPin.iconPath, const Option<ProgramIconPath>.none());
      }
    },
  );

  test('metadata extraction never accesses malformed pins as host files', () {
    final bottle = BottleRecord(
      id: 'steam',
      name: 'Steam',
      path: '/tmp/konyak-malformed-pin-bottle',
      windowsVersion: 'win10',
    );
    final fallbackFile = File('/tmp/konyak-malformed-pin-missing.exe');
    final malformedPaths = <String>[
      r'C:\..\outside.exe',
      'C:\\Games\\\u0000outside.exe',
    ];

    for (final malformedPath in malformedPaths) {
      final requestedPaths = <String>[];
      final metadata = IOOverrides.runZoned(
        () => const DartIoProgramMetadataExtractor().extract(
          bottle: bottle,
          programPath: ProgramPath(malformedPath),
        ),
        createFile: (path) {
          requestedPaths.add(path);
          return fallbackFile;
        },
      );

      expect(metadata, const Option<ProgramMetadataRecord>.none());
      expect(requestedPaths, isEmpty, reason: malformedPath);
    }
  });

  test('list-bottles --json extracts icons for existing pinned shortcuts', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-existing-pinned-shortcut-icon-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final bottlePath = joinTestPath(tempDirectory.path, const ['Steam']);
    final programPath = joinTestPath(bottlePath, const [
      'drive_c',
      'Program Files',
      'Fixture',
      'Fixture.exe',
    ]);
    File(programPath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(syntheticPortableExecutableBytes());
    final shortcutPath = joinTestPath(bottlePath, const [
      'drive_c',
      'ProgramData',
      'Microsoft',
      'Windows',
      'Start Menu',
      'Programs',
      'Fixture.lnk',
    ]);
    File(shortcutPath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(
        syntheticShellLinkBytes(
          localBasePath: r'C:\Program Files\Fixture\Fixture.exe',
        ),
      );
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const DartIoProgramMetadataExtractor(),
      dataHome: tempDirectory.path,
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: bottlePath,
          windowsVersion: 'win10',
          pinnedPrograms: [
            PinnedProgramRecord(name: 'Fixture', path: shortcutPath),
          ],
        ),
      ],
    );

    final result = runCli(const [
      'list-bottles',
      '--json',
    ], bottleRepository: repository);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    final bottles = payload['bottles'] as List<Object?>;
    final bottle = bottles.single as Map<String, Object?>;
    final pinnedPrograms = bottle['pinnedPrograms'] as List<Object?>;
    final pinnedProgram = pinnedPrograms.single as Map<String, Object?>;

    expect(pinnedProgram['path'], shortcutPath);
    final iconPath = pinnedProgram['iconPath'];
    expect(iconPath, isA<String>());
    expect(iconPath as String, startsWith('$bottlePath/cache/icons/'));
  });

  test(
    'unpin-program --json removes a pinned program from the bottle record',
    () {
      final repository = MemoryBottleRepository(
        programMetadataExtractor: const NoopProgramMetadataExtractor(),
        dataHome: '/home/user/.local/share/konyak',
        bottles: [
          BottleRecord(
            id: 'steam',
            name: 'Steam',
            path: '/home/user/.local/share/konyak/bottles/steam',
            windowsVersion: 'win10',
            pinnedPrograms: [
              PinnedProgramRecord(name: 'Steam', path: '/downloads/Steam.exe'),
            ],
          ),
        ],
      );

      final result = runCli(const [
        'unpin-program',
        'steam',
        '--program',
        '/downloads/Steam.exe',
        '--json',
      ], bottleRepository: repository);

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);

      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      expect(payload, {
        'schemaVersion': 1,
        'bottle': {
          'id': 'steam',
          'name': 'Steam',
          'path': '/home/user/.local/share/konyak/bottles/steam',
          'windowsVersion': 'win10',
        },
      });
      expect(
        expectFound(repository.findBottle(BottleId('steam'))).pinnedPrograms,
        isEmpty,
      );
    },
  );

  test('rename-pinned-program --json renames a pinned program', () {
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: '/home/user/.local/share/konyak',
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: '/home/user/.local/share/konyak/bottles/steam',
          windowsVersion: 'win10',
          pinnedPrograms: [
            PinnedProgramRecord(name: 'Steam', path: '/downloads/Steam.exe'),
          ],
        ),
      ],
    );

    final result = runCli(const [
      'rename-pinned-program',
      'steam',
      '--program',
      '/downloads/Steam.exe',
      '--name',
      'Steam Client',
      '--json',
    ], bottleRepository: repository);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'bottle': {
        'id': 'steam',
        'name': 'Steam',
        'path': '/home/user/.local/share/konyak/bottles/steam',
        'windowsVersion': 'win10',
        'pinnedPrograms': [
          {
            'name': 'Steam Client',
            'path': '/downloads/Steam.exe',
            'removable': false,
          },
        ],
      },
    });
    expect(
      expectFound(
        repository.findBottle(BottleId('steam')),
      ).pinnedPrograms.single.name.value,
      'Steam Client',
    );
  });
}
