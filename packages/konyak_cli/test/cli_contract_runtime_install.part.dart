part of 'cli_contract_test.dart';

void defineRuntimeInstallContractTests() {
  test('runtime package installer stages and replaces runtime roots', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-runtime-package-installer-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    final archivePath = _createLinuxWineRuntimeArchive(tempDirectory.path);
    final runtimeRoot = Directory(
      _joinTestPath(tempDirectory.path, const ['runtime']),
    );
    final executablePath = _joinTestPath(runtimeRoot.path, const [
      'bin',
      'wine',
    ]);

    final result = const DartIoRuntimePackageInstaller().install(
      RuntimePackageInstallRequest(
        runtimeLabel: 'Linux Wine',
        archivePath: archivePath,
        archiveSha256: null,
        componentArchivePaths: const [],
        componentVersions: const {},
        runtimeRoot: runtimeRoot,
        requiredExecutableRelativePath: const ['bin', 'wine'],
        expectedExecutablePath: executablePath,
      ),
    );

    expect(result, isA<RuntimePackageInstallCompleted>());
    expect(File(executablePath).existsSync(), isTrue);
    expect(File('${runtimeRoot.path}.install.lock').existsSync(), isFalse);
  });

  test('install-macos-wine --json installs from a configured archive source', () {
    final installer = RecordingMacosWineInstaller(
      result: const MacosWineInstallCompleted(
        runtime: RuntimeRecord(
          id: 'konyak-macos-wine',
          name: 'Konyak macOS Wine',
          platform: 'macos',
          architecture: 'x86_64',
          runnerKind: 'macosWine',
          isBundled: false,
          isUpdateable: true,
          isInstalled: true,
          applicationSupportPath:
              '/Users/user/Library/Application Support/Konyak',
          libraryPath:
              '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine',
          executablePath:
              '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wine64',
          archiveUrl:
              'https://github.com/Gcenx/macOS_Wine_builds/releases/download/11.9/wine-devel-11.9-osx64.tar.xz',
          versionUrl:
              'https://api.github.com/repos/Gcenx/macOS_Wine_builds/releases/latest',
        ),
      ),
    );

    final result = runCli(const [
      'install-macos-wine',
      '--json',
    ], macosWineInstaller: installer);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(installer.lastRequest?.archivePath, isNull);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'runtime': {
        'id': 'konyak-macos-wine',
        'name': 'Konyak macOS Wine',
        'platform': 'macos',
        'architecture': 'x86_64',
        'runnerKind': 'macosWine',
        'isBundled': false,
        'isUpdateable': true,
        'isInstalled': true,
        'applicationSupportPath':
            '/Users/user/Library/Application Support/Konyak',
        'libraryPath':
            '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine',
        'executablePath':
            '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wine64',
      },
    });
  });

  test('install-macos-wine --json is a no-op when Konyak macOS Wine is installed', () {
    final installer = DartIoMacosWineInstaller(
      hostPlatform: KonyakHostPlatform.macos,
      environment: const {'HOME': '/Users/user'},
      fileStatusProbe: const StaticFileStatusProbe({
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wine64',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wineserver',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wine',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/DXVK/x64/dxgi.dll',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/DXVK/x64/d3d9.dll',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/DXVK/x64/d3d10core.dll',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/DXVK/x64/d3d11.dll',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/DXVK/x32/dxgi.dll',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/DXVK/x32/d3d9.dll',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/DXVK/x32/d3d10core.dll',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/DXVK/x32/d3d11.dll',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/libMoltenVK.dylib',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/libgstreamer-1.0.0.dylib',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/share/wine/mono',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/winetricks',
      }),
    );

    final result = runCli(const [
      'install-macos-wine',
      '--json',
    ], macosWineInstaller: installer);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload['runtime'], containsPair('isInstalled', true));
    expect(
      payload['runtime'],
      containsPair(
        'executablePath',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wine64',
      ),
    );
  });

  test(
    'install-macos-wine repairs an incomplete existing runtime from an archive',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'konyak-runtime-repair-test-',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final runtimeHome = _joinTestPath(tempDirectory.path, const [
        'Application Support',
        'Konyak',
      ]);
      final existingWine = File(
        _joinTestPath(runtimeHome, const [
          'Runtimes',
          'macos-wine',
          'bin',
          'wine64',
        ]),
      );
      existingWine.parent.createSync(recursive: true);
      existingWine.writeAsStringSync('incomplete-runtime');

      final archivePath = _createKonyakComponentRuntimeArchive(
        tempDirectory.path,
      );
      final installer = DartIoMacosWineInstaller(
        hostPlatform: KonyakHostPlatform.macos,
        environment: {'KONYAK_APPLICATION_SUPPORT': runtimeHome},
        fileStatusProbe: StaticFileStatusProbe({existingWine.path}),
      );

      final result = installer.install(
        MacosWineInstallRequest.fullInstall(archivePath: archivePath),
      );

      expect(result, isA<MacosWineInstallCompleted>());
      final completed = result as MacosWineInstallCompleted;
      expect(completed.runtime.stack?.isComplete, isTrue);
      expect(existingWine.readAsStringSync(), 'fixture');
    },
  );

  test(
    'install-macos-wine reports incomplete installed runtime without a full stack source',
    () {
      final installer = DartIoMacosWineInstaller(
        hostPlatform: KonyakHostPlatform.macos,
        environment: const {'HOME': '/Users/user'},
        fileStatusProbe: const StaticFileStatusProbe({
          '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wine64',
          '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wineserver',
          '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wine',
        }),
      );

      final result = installer.install(MacosWineInstallRequest.fullInstall());

      expect(result, isA<MacosWineInstallFailed>());
      expect(
        (result as MacosWineInstallFailed).message,
        contains('runtime stack is incomplete'),
      );
      expect(result.message, contains('KONYAK_MACOS_WINE_STACK_MANIFEST'));
    },
  );

  test('install-macos-wine normalizes a component stack archive', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'konyak-runtime-stack-test-',
    );
    addTearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    final archivePath = _createComponentRuntimeArchive(tempDirectory.path);
    final runtimeHome = _joinTestPath(tempDirectory.path, const [
      'Application Support',
      'Konyak',
    ]);
    final installer = DartIoMacosWineInstaller(
      hostPlatform: KonyakHostPlatform.macos,
      environment: {'KONYAK_APPLICATION_SUPPORT': runtimeHome},
      fileStatusProbe: const StaticFileStatusProbe({}),
    );

    final result = installer.install(
      MacosWineInstallRequest.fullInstall(archivePath: archivePath),
    );

    expect(result, isA<MacosWineInstallCompleted>());
    final completed = result as MacosWineInstallCompleted;
    expect(completed.runtime.isInstalled, isTrue);
    expect(completed.runtime.stack?.isComplete, isTrue);
    expect(
      completed.runtime.stack?.components.first.version,
      'wine-devel-11.9',
    );
    expect(
      completed.runtime.stack?.components[2].version,
      'dxvk-macos-fixture',
    );
    expect(
      File(
        _joinTestPath(runtimeHome, const [
          'Runtimes',
          'macos-wine',
          'bin',
          'wine64',
        ]),
      ).existsSync(),
      isTrue,
    );
    expect(
      Directory(
        _joinTestPath(runtimeHome, const ['Runtimes', 'macos-wine', 'Wine']),
      ).existsSync(),
      isFalse,
    );
  });

  test(
    'install-macos-wine keeps the existing runtime when extraction fails',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'konyak-runtime-rollback-test-',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final runtimeHome = _joinTestPath(tempDirectory.path, const [
        'Application Support',
        'Konyak',
      ]);
      final existingWine = File(
        _joinTestPath(runtimeHome, const [
          'Runtimes',
          'macos-wine',
          'bin',
          'wine64',
        ]),
      );
      existingWine.parent.createSync(recursive: true);
      existingWine.writeAsStringSync('existing-runtime');

      final badArchive = _createBrokenRuntimeArchive(tempDirectory.path);
      final installer = DartIoMacosWineInstaller(
        hostPlatform: KonyakHostPlatform.macos,
        environment: {'KONYAK_APPLICATION_SUPPORT': runtimeHome},
        fileStatusProbe: const StaticFileStatusProbe({}),
      );

      final result = installer.install(
        MacosWineInstallRequest.fullInstall(archivePath: badArchive),
      );

      expect(result, isA<MacosWineInstallFailed>());
      expect(existingWine.readAsStringSync(), 'existing-runtime');
    },
  );

  test(
    'install-macos-wine keeps the existing runtime when component extraction fails',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'konyak-runtime-component-rollback-test-',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final runtimeHome = _joinTestPath(tempDirectory.path, const [
        'Application Support',
        'Konyak',
      ]);
      final existingWine = File(
        _joinTestPath(runtimeHome, const [
          'Runtimes',
          'macos-wine',
          'bin',
          'wine64',
        ]),
      );
      existingWine.parent.createSync(recursive: true);
      existingWine.writeAsStringSync('existing-runtime');

      final archivePath = _createKonyakComponentRuntimeArchive(
        tempDirectory.path,
      );
      final badComponentArchive = _createInvalidRuntimeArchive(
        tempDirectory.path,
      );
      final installer = DartIoMacosWineInstaller(
        hostPlatform: KonyakHostPlatform.macos,
        environment: {'KONYAK_APPLICATION_SUPPORT': runtimeHome},
        fileStatusProbe: const StaticFileStatusProbe({}),
      );

      final result = installer.install(
        MacosWineInstallRequest.componentInstall(
          archivePath: archivePath,
          componentArchivePaths: [badComponentArchive],
        ),
      );

      expect(result, isA<MacosWineInstallFailed>());
      expect(existingWine.readAsStringSync(), 'existing-runtime');
    },
  );

  test('install-macos-wine refuses to mutate a locked runtime root', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'konyak-runtime-install-lock-test-',
    );
    addTearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    final runtimeHome = _joinTestPath(tempDirectory.path, const [
      'Application Support',
      'Konyak',
    ]);
    final runtimeRoot = _joinTestPath(runtimeHome, const [
      'Runtimes',
      'macos-wine',
    ]);
    final existingWine = File(
      _joinTestPath(runtimeRoot, const ['bin', 'wine64']),
    );
    existingWine.parent.createSync(recursive: true);
    existingWine.writeAsStringSync('existing-runtime');
    Directory('$runtimeRoot.install.lock').createSync(recursive: true);

    final archivePath = _createKonyakComponentRuntimeArchive(
      tempDirectory.path,
    );
    final installer = DartIoMacosWineInstaller(
      hostPlatform: KonyakHostPlatform.macos,
      environment: {'KONYAK_APPLICATION_SUPPORT': runtimeHome},
      fileStatusProbe: const StaticFileStatusProbe({}),
    );

    final result = installer.install(
      MacosWineInstallRequest.fullInstall(archivePath: archivePath),
    );

    expect(result, isA<MacosWineInstallFailed>());
    expect((result as MacosWineInstallFailed).message, contains('already'));
    expect(existingWine.readAsStringSync(), 'existing-runtime');
  });

  test(
    'install-macos-wine normalizes Konyak runtime component layout',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'konyak-runtime-components-test-',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final archivePath = _createKonyakComponentRuntimeArchive(
        tempDirectory.path,
      );
      final runtimeHome = _joinTestPath(tempDirectory.path, const [
        'Application Support',
        'Konyak',
      ]);
      final installer = DartIoMacosWineInstaller(
        hostPlatform: KonyakHostPlatform.macos,
        environment: {'KONYAK_APPLICATION_SUPPORT': runtimeHome},
        fileStatusProbe: const StaticFileStatusProbe({}),
      );

      final result = installer.install(
        MacosWineInstallRequest.fullInstall(archivePath: archivePath),
      );

      expect(result, isA<MacosWineInstallCompleted>());
      final completed = result as MacosWineInstallCompleted;
      expect(completed.runtime.stack?.isComplete, isTrue);
      expect(
        completed.runtime.stack?.components
            .where((component) => component.id == 'dxvk-macos')
            .single
            .version,
        'dxvk-macos-fixture',
      );
      expect(
        completed.runtime.stack?.components
            .where((component) => component.id == 'gptk-d3dmetal')
            .single
            .version,
        'gptk-d3dmetal-fixture',
      );
      expect(
        File(
          _joinTestPath(runtimeHome, const [
            'Runtimes',
            'macos-wine',
            'DXVK',
            'x64',
            'dxgi.dll',
          ]),
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          _joinTestPath(runtimeHome, const [
            'Runtimes',
            'macos-wine',
            'lib',
            'libMoltenVK.dylib',
          ]),
        ).existsSync(),
        isTrue,
      );
      expect(
        Directory(
          _joinTestPath(runtimeHome, const [
            'Runtimes',
            'macos-wine',
            'lib',
            'external',
            'D3DMetal.framework',
          ]),
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          _joinTestPath(runtimeHome, const [
            'Runtimes',
            'macos-wine',
            'lib',
            'external',
            'libd3dshared.dylib',
          ]),
        ).existsSync(),
        isTrue,
      );
      expect(
        Directory(
          _joinTestPath(runtimeHome, const [
            'Runtimes',
            'macos-wine',
            'share',
            'wine',
            'mono',
          ]),
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          _joinTestPath(runtimeHome, const [
            'Runtimes',
            'macos-wine',
            'winetricks',
          ]),
        ).existsSync(),
        isTrue,
      );
      expect(
        Directory(
          _joinTestPath(runtimeHome, const [
            'Runtimes',
            'macos-wine',
            'Components',
          ]),
        ).existsSync(),
        isFalse,
      );
    },
  );

  test('install-macos-wine builds a stack from component archives', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'konyak-runtime-stack-components-test-',
    );
    addTearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    final wineArchive = _createMacosAppBundleWineArchive(tempDirectory.path);
    final dxvkArchive = _createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'dxvk-macos',
      relativePaths: _macosDxvkComponentPaths,
      versions: const <String, String>{'dxvk-macos': 'dxvk-macos-fixture'},
    );
    final moltenVkArchive = _createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'moltenvk',
      relativePaths: const <List<String>>[
        <String>['Components', 'MoltenVK', 'lib', 'libMoltenVK.dylib'],
      ],
      versions: const <String, String>{'moltenvk': 'moltenvk-fixture'},
    );
    final gstreamerArchive = _createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'gstreamer',
      relativePaths: const <List<String>>[
        <String>['Components', 'GStreamer', 'lib', 'libgstreamer-1.0.0.dylib'],
      ],
      versions: const <String, String>{'gstreamer': 'gstreamer-fixture'},
    );
    final monoArchive = _createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'wine-mono',
      relativePaths: const <List<String>>[
        <String>['Components', 'wine-mono', 'share', 'wine', 'mono', 'marker'],
      ],
      versions: const <String, String>{'wine-mono': 'wine-mono-fixture'},
    );
    final winetricksArchive = _createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'winetricks',
      relativePaths: const <List<String>>[
        <String>['Components', 'winetricks', 'winetricks'],
      ],
      versions: const <String, String>{'winetricks': 'winetricks-fixture'},
    );
    final gptkD3dMetalArchive = _createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'gptk-d3dmetal',
      relativePaths: const <List<String>>[
        <String>[
          'Components',
          'GPTK-D3DMetal',
          'lib',
          'external',
          'D3DMetal.framework',
          'D3DMetal',
        ],
        <String>[
          'Components',
          'GPTK-D3DMetal',
          'lib',
          'external',
          'libd3dshared.dylib',
        ],
        <String>[
          'Components',
          'GPTK-D3DMetal',
          'lib',
          'wine',
          'x86_64-windows',
          'd3d12.dll',
        ],
        <String>[
          'Components',
          'GPTK-D3DMetal',
          'lib',
          'wine',
          'x86_64-windows',
          'dxgi.dll',
        ],
      ],
      versions: const <String, String>{
        'gptk-d3dmetal': 'gptk-d3dmetal-fixture',
      },
    );
    final runtimeHome = _joinTestPath(tempDirectory.path, const [
      'Application Support',
      'Konyak',
    ]);
    final installer = DartIoMacosWineInstaller(
      hostPlatform: KonyakHostPlatform.macos,
      environment: {'KONYAK_APPLICATION_SUPPORT': runtimeHome},
      fileStatusProbe: const StaticFileStatusProbe({}),
    );

    final result = installer.install(
      MacosWineInstallRequest.componentInstall(
        archivePath: wineArchive,
        componentArchivePaths: [
          dxvkArchive,
          moltenVkArchive,
          gstreamerArchive,
          monoArchive,
          winetricksArchive,
          gptkD3dMetalArchive,
        ],
      ),
    );

    expect(result, isA<MacosWineInstallCompleted>());
    final completed = result as MacosWineInstallCompleted;
    expect(completed.runtime.stack?.isComplete, isTrue);
    expect(
      completed.runtime.stack?.components
          .where((component) => component.id == 'dxvk-macos')
          .single
          .version,
      'dxvk-macos-fixture',
    );
    expect(
      completed.runtime.stack?.components
          .where((component) => component.id == 'moltenvk')
          .single
          .version,
      'moltenvk-fixture',
    );
    expect(
      completed.runtime.stack?.components
          .where((component) => component.id == 'gptk-d3dmetal')
          .single
          .version,
      'gptk-d3dmetal-fixture',
    );
    expect(
      File(
        _joinTestPath(runtimeHome, const [
          'Runtimes',
          'macos-wine',
          'lib',
          'libgstreamer-1.0.0.dylib',
        ]),
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        _joinTestPath(runtimeHome, const [
          'Runtimes',
          'macos-wine',
          'winetricks',
        ]),
      ).existsSync(),
      isTrue,
    );
    expect(
      Directory(
        _joinTestPath(runtimeHome, const [
          'Runtimes',
          'macos-wine',
          'lib',
          'external',
          'D3DMetal.framework',
        ]),
      ).existsSync(),
      isTrue,
    );
  });

  test('install-macos-wine builds a stack from a source manifest', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'konyak-runtime-stack-source-test-',
    );
    addTearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    final wineArchive = _createMacosAppBundleWineArchive(tempDirectory.path);
    final dxvkArchive = _createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'source-dxvk-macos',
      relativePaths: _macosDxvkComponentPaths,
      versions: const <String, String>{},
    );
    final moltenVkArchive = _createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'source-moltenvk',
      relativePaths: const <List<String>>[
        <String>['Components', 'MoltenVK', 'lib', 'libMoltenVK.dylib'],
      ],
      versions: const <String, String>{},
    );
    final gstreamerArchive = _createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'source-gstreamer',
      relativePaths: const <List<String>>[
        <String>['Components', 'GStreamer', 'lib', 'libgstreamer-1.0.0.dylib'],
      ],
      versions: const <String, String>{},
    );
    final monoArchive = _createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'source-wine-mono',
      relativePaths: const <List<String>>[
        <String>['Components', 'wine-mono', 'share', 'wine', 'mono', 'marker'],
      ],
      versions: const <String, String>{},
    );
    final winetricksArchive = _createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'source-winetricks',
      relativePaths: const <List<String>>[
        <String>['Components', 'winetricks', 'winetricks'],
      ],
      versions: const <String, String>{},
    );
    final gptkD3dMetalArchive = _createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'source-gptk-d3dmetal',
      relativePaths: const <List<String>>[
        <String>[
          'Components',
          'GPTK-D3DMetal',
          'lib',
          'external',
          'D3DMetal.framework',
          'D3DMetal',
        ],
        <String>[
          'Components',
          'GPTK-D3DMetal',
          'lib',
          'external',
          'libd3dshared.dylib',
        ],
        <String>[
          'Components',
          'GPTK-D3DMetal',
          'lib',
          'wine',
          'x86_64-windows',
          'd3d12.dll',
        ],
        <String>[
          'Components',
          'GPTK-D3DMetal',
          'lib',
          'wine',
          'x86_64-windows',
          'dxgi.dll',
        ],
      ],
      versions: const <String, String>{},
    );
    final sourceManifestPath = _createRuntimeStackSourceManifest(
      tempDirectory.path,
      components: <Map<String, String>>[
        _runtimeStackSourceComponent(
          id: 'wine',
          version: 'wine-devel-source',
          archivePath: wineArchive,
        ),
        _runtimeStackSourceComponent(
          id: 'dxvk-macos',
          version: 'dxvk-source',
          archivePath: dxvkArchive,
        ),
        _runtimeStackSourceComponent(
          id: 'moltenvk',
          version: 'moltenvk-source',
          archivePath: moltenVkArchive,
        ),
        _runtimeStackSourceComponent(
          id: 'gstreamer',
          version: 'gstreamer-source',
          archivePath: gstreamerArchive,
        ),
        _runtimeStackSourceComponent(
          id: 'wine-mono',
          version: 'wine-mono-source',
          archivePath: monoArchive,
        ),
        _runtimeStackSourceComponent(
          id: 'winetricks',
          version: 'winetricks-source',
          archivePath: winetricksArchive,
        ),
        _runtimeStackSourceComponent(
          id: 'gptk-d3dmetal',
          version: 'gptk-d3dmetal-source',
          archivePath: gptkD3dMetalArchive,
        ),
      ],
    );
    final runtimeHome = _joinTestPath(tempDirectory.path, const [
      'Application Support',
      'Konyak',
    ]);
    final installer = DartIoMacosWineInstaller(
      hostPlatform: KonyakHostPlatform.macos,
      environment: {'KONYAK_APPLICATION_SUPPORT': runtimeHome},
      fileStatusProbe: const StaticFileStatusProbe({}),
    );

    final result = installer.install(
      MacosWineInstallRequest.fullInstall(sourceManifest: sourceManifestPath),
    );

    expect(result, isA<MacosWineInstallCompleted>());
    final completed = result as MacosWineInstallCompleted;
    expect(completed.runtime.stack?.isComplete, isTrue);
    expect(
      completed.runtime.stack?.components
          .where((component) => component.id == 'wine')
          .single
          .version,
      'wine-devel-source',
    );
    expect(
      completed.runtime.stack?.components
          .where((component) => component.id == 'winetricks')
          .single
          .version,
      'winetricks-source',
    );
    expect(
      completed.runtime.stack?.components
          .where((component) => component.id == 'gptk-d3dmetal')
          .single
          .version,
      'gptk-d3dmetal-source',
    );
    expect(
      completed.runtime.stack?.components
          .where((component) => component.id == 'gptk-d3dmetal')
          .single
          .isInstalled,
      isTrue,
    );
  });

  test(
    'install-macos-wine repairs required components without removing GPTK',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'konyak-runtime-stack-repair-gptk-test-',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final wineArchive = _createMacosAppBundleWineArchive(tempDirectory.path);
      final dxvkArchive = _createKonyakRuntimeComponentArchive(
        tempDirectory.path,
        archiveName: 'repair-dxvk-macos',
        relativePaths: _macosDxvkComponentPaths,
        versions: const <String, String>{},
      );
      final moltenVkArchive = _createKonyakRuntimeComponentArchive(
        tempDirectory.path,
        archiveName: 'repair-moltenvk',
        relativePaths: const <List<String>>[
          <String>['Components', 'MoltenVK', 'lib', 'libMoltenVK.dylib'],
        ],
        versions: const <String, String>{},
      );
      final gstreamerArchive = _createKonyakRuntimeComponentArchive(
        tempDirectory.path,
        archiveName: 'repair-gstreamer',
        relativePaths: const <List<String>>[
          <String>[
            'Components',
            'GStreamer',
            'lib',
            'libgstreamer-1.0.0.dylib',
          ],
        ],
        versions: const <String, String>{},
      );
      final monoArchive = _createKonyakRuntimeComponentArchive(
        tempDirectory.path,
        archiveName: 'repair-wine-mono',
        relativePaths: const <List<String>>[
          <String>[
            'Components',
            'wine-mono',
            'share',
            'wine',
            'mono',
            'marker',
          ],
        ],
        versions: const <String, String>{},
      );
      final winetricksArchive = _createKonyakRuntimeComponentArchive(
        tempDirectory.path,
        archiveName: 'repair-winetricks',
        relativePaths: const <List<String>>[
          <String>['Components', 'winetricks', 'winetricks'],
        ],
        versions: const <String, String>{},
      );
      final sourceManifestPath = _createRuntimeStackSourceManifest(
        tempDirectory.path,
        components: <Map<String, String>>[
          _runtimeStackSourceComponent(
            id: 'wine',
            version: 'wine-devel-source',
            archivePath: wineArchive,
          ),
          _runtimeStackSourceComponent(
            id: 'dxvk-macos',
            version: 'dxvk-source',
            archivePath: dxvkArchive,
          ),
          _runtimeStackSourceComponent(
            id: 'moltenvk',
            version: 'moltenvk-source',
            archivePath: moltenVkArchive,
          ),
          _runtimeStackSourceComponent(
            id: 'gstreamer',
            version: 'gstreamer-source',
            archivePath: gstreamerArchive,
          ),
          _runtimeStackSourceComponent(
            id: 'wine-mono',
            version: 'wine-mono-source',
            archivePath: monoArchive,
          ),
          _runtimeStackSourceComponent(
            id: 'winetricks',
            version: 'winetricks-source',
            archivePath: winetricksArchive,
          ),
        ],
      );
      final runtimeHome = _joinTestPath(tempDirectory.path, const [
        'Application Support',
        'Konyak',
      ]);
      final runtimeRoot = _joinTestPath(runtimeHome, const [
        'Runtimes',
        'macos-wine',
      ]);
      for (final relativePath in const <List<String>>[
        <String>['bin', 'wine64'],
        <String>['bin', 'wineserver'],
        <String>['bin', 'wine'],
        <String>['lib', 'libwine.1.dylib'],
        ..._macosDxvkInstalledPaths,
        <String>['lib', 'libMoltenVK.dylib'],
        <String>['lib', 'libgstreamer-1.0.0.dylib'],
        <String>['share', 'wine', 'mono', 'wine-mono.marker'],
      ]) {
        final file = File(_joinTestPath(runtimeRoot, relativePath));
        file.parent.createSync(recursive: true);
        file.writeAsStringSync('existing-gptk-wine');
      }
      _createMachOFile(
        _joinTestPath(runtimeRoot, const [
          'lib',
          'external',
          'D3DMetal.framework',
          'Versions',
          'A',
          'D3DMetal',
        ]),
      );
      _createMachOFile(
        _joinTestPath(runtimeRoot, const [
          'lib',
          'external',
          'libd3dshared.dylib',
        ]),
      );
      _createPEFile(
        _joinTestPath(runtimeRoot, const [
          'lib',
          'wine',
          'x86_64-windows',
          'd3d12.dll',
        ]),
      );
      _createPEFile(
        _joinTestPath(runtimeRoot, const [
          'lib',
          'wine',
          'x86_64-windows',
          'dxgi.dll',
        ]),
      );
      File(
        _joinTestPath(runtimeRoot, const ['.konyak-runtime-stack.json']),
      ).writeAsStringSync(
        jsonEncode(<String, Object?>{
          'schemaVersion': 1,
          'components': <String, String>{
            'wine': 'user-provided-gptk-wine',
            'dxvk-macos': 'dxvk-existing',
            'moltenvk': 'moltenvk-existing',
            'gstreamer': 'gstreamer-existing',
            'wine-mono': 'wine-mono-existing',
            'gptk-d3dmetal': 'user-provided',
          },
        }),
      );
      final installer = DartIoMacosWineInstaller(
        hostPlatform: KonyakHostPlatform.macos,
        environment: {
          'KONYAK_RUNTIME_PROFILE': 'development',
          'KONYAK_APPLICATION_SUPPORT': runtimeHome,
          'KONYAK_DEV_MACOS_WINE_STACK_MANIFEST': sourceManifestPath,
        },
      );

      final result = installer.install(MacosWineInstallRequest.fullInstall());

      if (result is MacosWineInstallFailed) {
        fail(result.message);
      }
      expect(result, isA<MacosWineInstallCompleted>());
      final completed = result as MacosWineInstallCompleted;
      expect(completed.runtime.stack?.isComplete, isTrue);
      expect(
        File(_joinTestPath(runtimeRoot, const ['winetricks'])).existsSync(),
        isTrue,
      );
      expect(
        File(
          _joinTestPath(runtimeRoot, const ['bin', 'wine']),
        ).readAsStringSync(),
        'existing-gptk-wine',
      );
      final wineComponent = completed.runtime.stack?.components
          .where((component) => component.id == 'wine')
          .single;
      final gptkComponent = completed.runtime.stack?.components
          .where((component) => component.id == 'gptk-d3dmetal')
          .single;
      expect(wineComponent?.version, 'user-provided-gptk-wine');
      expect(gptkComponent?.isInstalled, isTrue);
      expect(gptkComponent?.version, 'user-provided');
    },
  );

  test(
    'install-macos-wine rejects source manifest checksum mismatches',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'konyak-runtime-stack-source-checksum-test-',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final wineArchive = _createMacosAppBundleWineArchive(tempDirectory.path);
      final sourceManifestPath = _createRuntimeStackSourceManifest(
        tempDirectory.path,
        components: <Map<String, String>>[
          <String, String>{
            ..._runtimeStackSourceComponent(
              id: 'wine',
              version: 'wine-devel-source',
              archivePath: wineArchive,
            ),
            'sha256':
                'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff',
          },
        ],
      );
      final installer = DartIoMacosWineInstaller(
        hostPlatform: KonyakHostPlatform.macos,
        environment: {'KONYAK_APPLICATION_SUPPORT': tempDirectory.path},
        fileStatusProbe: const StaticFileStatusProbe({}),
      );

      final result = installer.install(
        MacosWineInstallRequest.fullInstall(sourceManifest: sourceManifestPath),
      );

      expect(result, isA<MacosWineInstallFailed>());
      expect(
        (result as MacosWineInstallFailed).message,
        contains('checksum mismatch'),
      );
    },
  );

  test(
    'install-macos-wine normalizes a macOS app bundle Wine archive',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'konyak-runtime-app-bundle-test-',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final archivePath = _createMacosAppBundleWineArchive(tempDirectory.path);
      final runtimeHome = _joinTestPath(tempDirectory.path, const [
        'Application Support',
        'Konyak',
      ]);
      final installer = DartIoMacosWineInstaller(
        hostPlatform: KonyakHostPlatform.macos,
        environment: {'KONYAK_APPLICATION_SUPPORT': runtimeHome},
        fileStatusProbe: const StaticFileStatusProbe({}),
      );

      final result = installer.install(
        MacosWineInstallRequest.fullInstall(archivePath: archivePath),
      );

      expect(result, isA<MacosWineInstallCompleted>());
      final completed = result as MacosWineInstallCompleted;
      expect(completed.runtime.isInstalled, isTrue);
      expect(
        File(
          _joinTestPath(runtimeHome, const [
            'Runtimes',
            'macos-wine',
            'bin',
            'wine64',
          ]),
        ).existsSync(),
        isTrue,
      );
      expect(
        Link(
          _joinTestPath(runtimeHome, const [
            'Runtimes',
            'macos-wine',
            'bin',
            'wine64',
          ]),
        ).targetSync(),
        'wine',
      );
      expect(
        Directory(
          _joinTestPath(runtimeHome, const [
            'Runtimes',
            'macos-wine',
            'Contents',
            'Resources',
            'wine',
          ]),
        ).existsSync(),
        isFalse,
      );
    },
  );

  test('install-macos-wine --archive passes an explicit archive path', () {
    final installer = RecordingMacosWineInstaller(
      result: const MacosWineInstallCompleted(
        runtime: RuntimeRecord(
          id: 'konyak-macos-wine',
          name: 'Konyak macOS Wine',
          platform: 'macos',
          architecture: 'x86_64',
          runnerKind: 'macosWine',
          isBundled: false,
          isUpdateable: true,
        ),
      ),
    );

    final result = runCli(const [
      'install-macos-wine',
      '--archive',
      '/tmp/macos-wine.tar.xz',
      '--json',
    ], macosWineInstaller: installer);

    expect(result.exitCode, 0);
    expect(installer.lastRequest?.archivePath, '/tmp/macos-wine.tar.xz');
  });

  test('install-macos-wine --archive-sha256 passes an expected digest', () {
    final installer = RecordingMacosWineInstaller(
      result: const MacosWineInstallCompleted(
        runtime: RuntimeRecord(
          id: 'konyak-macos-wine',
          name: 'Konyak macOS Wine',
          platform: 'macos',
          architecture: 'x86_64',
          runnerKind: 'macosWine',
          isBundled: false,
          isUpdateable: true,
        ),
      ),
    );

    final result = runCli(const [
      'install-macos-wine',
      '--archive',
      '/tmp/macos-wine.tar.xz',
      '--archive-sha256',
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
      '--json',
    ], macosWineInstaller: installer);

    expect(result.exitCode, 0);
    expect(installer.lastRequest?.archivePath, '/tmp/macos-wine.tar.xz');
    expect(
      installer.lastRequest?.archiveSha256,
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
    );
  });

  test('install-macos-wine --component-archive passes component archives', () {
    final installer = RecordingMacosWineInstaller(
      result: const MacosWineInstallCompleted(
        runtime: RuntimeRecord(
          id: 'konyak-macos-wine',
          name: 'Konyak macOS Wine',
          platform: 'macos',
          architecture: 'x86_64',
          runnerKind: 'macosWine',
          isBundled: false,
          isUpdateable: true,
          isInstalled: true,
        ),
      ),
    );

    final result = runCli(const [
      'install-macos-wine',
      '--archive',
      '/tmp/wine.tar.xz',
      '--component-archive',
      '/tmp/dxvk.tar.xz',
      '--component-archive',
      '/tmp/moltenvk.tar.xz',
      '--json',
    ], macosWineInstaller: installer);

    expect(result.exitCode, 0);
    expect(installer.lastRequest?.archivePath, '/tmp/wine.tar.xz');
    expect(installer.lastRequest?.componentArchivePaths, [
      '/tmp/dxvk.tar.xz',
      '/tmp/moltenvk.tar.xz',
    ]);
    expect(
      installer.lastRequest?.operation,
      RuntimeInstallOperation.componentInstall,
    );
    expect(
      installer.lastRequest?.requestOperation,
      isA<RuntimeComponentInstallOperation>(),
    );
  });

  test('install-gptk-wine rejects non-app sources', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-gptk-wine-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    final sourceRoot = _createGptkWineRoot(
      tempDirectory.path,
      includeD3DMetal: true,
    );
    final runtimeRoot = Directory(
      _joinTestPath(tempDirectory.path, const ['runtime']),
    );

    final result = runCli(
      ['install-gptk-wine', '--from', sourceRoot.path, '--json'],
      gptkWineInstaller: DartIoGptkWineInstaller(
        environment: {'KONYAK_MACOS_WINE_HOME': runtimeRoot.path},
      ),
    );

    expect(result.exitCode, 75);
    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    final error = payload['error'] as Map<String, Object?>;
    expect(error['code'], 'gptkWineInstallFailed');
    expect(error['message'], contains('Game Porting Toolkit.app'));
  });

  test('install-gptk-wine requires D3DMetal in the selected app', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-gptk-wine-missing-d3dmetal-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    final appBundle = _createGptkWineAppBundle(tempDirectory.path);
    final runtimeRoot = Directory(
      _joinTestPath(tempDirectory.path, const ['runtime']),
    );
    _createInstalledMacosRuntime(runtimeRoot.path);

    final result = runCli(
      ['install-gptk-wine', '--from', appBundle.path, '--json'],
      gptkWineInstaller: DartIoGptkWineInstaller(
        environment: {'KONYAK_MACOS_WINE_HOME': runtimeRoot.path},
      ),
    );

    expect(result.exitCode, 75);
    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    final error = payload['error'] as Map<String, Object?>;
    expect(error['message'], contains('D3DMetal.framework'));
  });

  test('install-gptk-wine imports a Game Porting Toolkit app bundle', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-gptk-wine-app-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    final appBundle = _createGptkWineAppBundle(
      tempDirectory.path,
      includeD3DMetal: true,
    );
    final runtimeRoot = Directory(
      _joinTestPath(tempDirectory.path, const ['runtime']),
    );
    _createInstalledMacosRuntime(runtimeRoot.path);
    File(_joinTestPath(runtimeRoot.path, const ['winetricks']))
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('existing winetricks');
    File(
        _joinTestPath(runtimeRoot.path, const [
          'lib',
          'libgstreamer-1.0.0.dylib',
        ]),
      )
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('existing gstreamer');
    File(
        _joinTestPath(appBundle.path, const [
          'Contents',
          'Resources',
          'wine',
          'share',
          'wine',
          'mono',
          'wine-mono.marker',
        ]),
      )
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('source mono');

    final result = runCli(
      ['install-gptk-wine', '--from', appBundle.path, '--json'],
      gptkWineInstaller: DartIoGptkWineInstaller(
        environment: {'KONYAK_MACOS_WINE_HOME': runtimeRoot.path},
      ),
    );

    expect(result.exitCode, 0, reason: result.stderr);
    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    final install = payload['gptkWineInstall'] as Map<String, Object?>;
    expect(
      install['sourceDirectory'],
      endsWith('Game Porting Toolkit.app/Contents/Resources/wine'),
    );
    expect(
      File(
        _joinTestPath(runtimeRoot.path, const ['bin', 'wine64']),
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        _joinTestPath(runtimeRoot.path, const [
          'lib',
          'external',
          'D3DMetal.framework',
          'Versions',
          'A',
          'D3DMetal',
        ]),
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        _joinTestPath(runtimeRoot.path, const ['winetricks']),
      ).readAsStringSync(),
      'existing winetricks',
    );
    expect(
      File(
        _joinTestPath(runtimeRoot.path, const [
          'lib',
          'libgstreamer-1.0.0.dylib',
        ]),
      ).readAsStringSync(),
      'existing gstreamer',
    );
    expect(
      File(
        _joinTestPath(runtimeRoot.path, const [
          'share',
          'wine',
          'mono',
          'wine-mono.marker',
        ]),
      ).readAsStringSync(),
      'fixture',
    );
  });

  test('install-gptk-wine rejects fixture text binaries as JSON', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-gptk-wine-fixture-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    final appBundle = _createGptkWineAppBundle(
      tempDirectory.path,
      validBinaries: false,
      includeD3DMetal: true,
    );
    final result = runCli(
      ['install-gptk-wine', '--from', appBundle.path, '--json'],
      gptkWineInstaller: DartIoGptkWineInstaller(
        environment: {
          'KONYAK_MACOS_WINE_HOME': _joinTestPath(tempDirectory.path, const [
            'runtime',
          ]),
        },
      ),
    );

    expect(result.exitCode, 75);
    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    final error = payload['error'] as Map<String, Object?>;
    expect(error['code'], 'gptkWineInstallFailed');
    expect(error['message'], contains('not a Mach-O'));
  });

  test('install-macos-wine --source-manifest passes the source manifest', () {
    final installer = RecordingMacosWineInstaller(
      result: const MacosWineInstallCompleted(
        runtime: RuntimeRecord(
          id: 'konyak-macos-wine',
          name: 'Konyak macOS Wine',
          platform: 'macos',
          architecture: 'x86_64',
          runnerKind: 'macosWine',
          isBundled: false,
          isUpdateable: true,
          isInstalled: true,
        ),
      ),
    );

    final result = runCli(const [
      'install-macos-wine',
      '--source-manifest',
      '/tmp/runtime-stack.json',
      '--json',
    ], macosWineInstaller: installer);

    expect(result.exitCode, 0);
    expect(installer.lastRequest?.sourceManifest, '/tmp/runtime-stack.json');
  });

  test('install-macos-wine --progress-json emits progress events', () {
    final progressOutput = StringBuffer();
    final installer = RecordingMacosWineInstaller(
      result: const MacosWineInstallCompleted(
        runtime: RuntimeRecord(
          id: 'konyak-macos-wine',
          name: 'Konyak macOS Wine',
          platform: 'macos',
          architecture: 'x86_64',
          runnerKind: 'macosWine',
          isBundled: false,
          isUpdateable: true,
          isInstalled: true,
        ),
      ),
    );

    final result = runCli(
      const ['install-macos-wine', '--progress-json', '--json'],
      macosWineInstaller: installer,
      runtimeInstallProgressSink: JsonRuntimeInstallProgressSink(
        progressOutput,
      ),
    );

    expect(result.exitCode, 0);
    expect(installer.lastRequest?.emitProgress, isTrue);

    final progress =
        jsonDecode(progressOutput.toString().trim()) as Map<String, Object?>;
    expect(progress['schemaVersion'], 1);
    expect(
      progress['runtimeInstallProgress'],
      containsPair('message', 'Installing test runtime...'),
    );

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload['runtime'], containsPair('id', 'konyak-macos-wine'));
  });

  test('install-macos-wine rejects archive checksum mismatches', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'konyak-runtime-checksum-test-',
    );
    addTearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    final archive = File(
      _joinTestPath(tempDirectory.path, const ['runtime.tar.xz']),
    )..writeAsStringSync('not a runtime');
    final installer = DartIoMacosWineInstaller(
      hostPlatform: KonyakHostPlatform.macos,
      environment: {'KONYAK_APPLICATION_SUPPORT': tempDirectory.path},
      fileStatusProbe: const StaticFileStatusProbe({}),
    );

    final result = installer.install(
      MacosWineInstallRequest.fullInstall(
        archivePath: archive.path,
        archiveSha256:
            'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff',
      ),
    );

    expect(result, isA<MacosWineInstallFailed>());
    expect(
      (result as MacosWineInstallFailed).message,
      contains('checksum mismatch'),
    );
  });

  test('install-macos-wine --json returns installer failures as JSON', () {
    final result = runCli(
      const ['install-macos-wine', '--json'],
      macosWineInstaller: RecordingMacosWineInstaller(
        result: const MacosWineInstallFailed('download failed'),
      ),
    );

    expect(result.exitCode, 75);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'error': {'code': 'macosWineInstallFailed', 'message': 'download failed'},
    });
  });

  test('install-linux-wine --archive passes an explicit archive path', () {
    final installer = RecordingLinuxWineInstaller(
      result: const LinuxWineInstallCompleted(
        runtime: RuntimeRecord(
          id: 'konyak-linux-wine',
          name: 'Konyak Linux Wine',
          platform: 'linux',
          architecture: 'x86_64',
          runnerKind: 'wine',
          isBundled: false,
          isUpdateable: false,
        ),
      ),
    );

    final result = runCli(const [
      'install-linux-wine',
      '--archive',
      '/tmp/linux-wine.tar.xz',
      '--json',
    ], linuxWineInstaller: installer);

    expect(result.exitCode, 0);
    expect(installer.lastRequest?.archivePath, '/tmp/linux-wine.tar.xz');
  });

  test('install-linux-wine --component-archive passes component archives', () {
    final installer = RecordingLinuxWineInstaller(
      result: const LinuxWineInstallCompleted(
        runtime: RuntimeRecord(
          id: 'konyak-linux-wine',
          name: 'Konyak Linux Wine',
          platform: 'linux',
          architecture: 'x86_64',
          runnerKind: 'wine',
          isBundled: false,
          isUpdateable: false,
        ),
      ),
    );

    final result = runCli(const [
      'install-linux-wine',
      '--archive',
      '/tmp/linux-wine.tar.xz',
      '--component-archive',
      '/tmp/vkd3d-proton.tar.xz',
      '--json',
    ], linuxWineInstaller: installer);

    expect(result.exitCode, 0);
    expect(installer.lastRequest?.archivePath, '/tmp/linux-wine.tar.xz');
    expect(installer.lastRequest?.componentArchivePaths, const [
      '/tmp/vkd3d-proton.tar.xz',
    ]);
    expect(
      installer.lastRequest?.operation,
      RuntimeInstallOperation.componentInstall,
    );
  });

  test('install-linux-wine --source-manifest passes the source manifest', () {
    final installer = RecordingLinuxWineInstaller(
      result: const LinuxWineInstallCompleted(
        runtime: RuntimeRecord(
          id: 'konyak-linux-wine',
          name: 'Konyak Linux Wine',
          platform: 'linux',
          architecture: 'x86_64',
          runnerKind: 'wine',
          isBundled: false,
          isUpdateable: false,
        ),
      ),
    );

    final result = runCli(const [
      'install-linux-wine',
      '--source-manifest',
      '/tmp/linux-runtime-stack.json',
      '--json',
    ], linuxWineInstaller: installer);

    expect(result.exitCode, 0);
    expect(
      installer.lastRequest?.sourceManifest,
      '/tmp/linux-runtime-stack.json',
    );
  });

  test('install-linux-wine --progress-json emits progress events', () {
    final progressOutput = StringBuffer();
    final installer = RecordingLinuxWineInstaller(
      result: const LinuxWineInstallCompleted(
        runtime: RuntimeRecord(
          id: 'konyak-linux-wine',
          name: 'Konyak Linux Wine',
          platform: 'linux',
          architecture: 'x86_64',
          runnerKind: 'wine',
          isBundled: false,
          isUpdateable: true,
          isInstalled: true,
        ),
      ),
    );

    final result = runCli(
      const ['install-linux-wine', '--progress-json', '--json'],
      linuxWineInstaller: installer,
      runtimeInstallProgressSink: JsonRuntimeInstallProgressSink(
        progressOutput,
      ),
    );

    expect(result.exitCode, 0);
    expect(installer.lastRequest?.emitProgress, isTrue);

    final progress =
        jsonDecode(progressOutput.toString().trim()) as Map<String, Object?>;
    expect(progress['schemaVersion'], 1);
    expect(
      progress['runtimeInstallProgress'],
      containsPair('message', 'Installing test runtime...'),
    );

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload['runtime'], containsPair('id', 'konyak-linux-wine'));
  });

  test(
    'runCliStreaming streams archive copy progress before final JSON',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'konyak-runtime-progress-test-',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });
      final sourceArchive = File(
        _joinTestPath(tempDirectory.path, const ['linux-wine.tar.xz']),
      )..writeAsBytesSync(List<int>.filled(128 * 1024, 1));
      final progressOutput = StringBuffer();

      final result = await runCliStreaming(
        [
          'install-linux-wine',
          '--archive-url',
          sourceArchive.uri.toString(),
          '--progress-json',
          '--json',
        ],
        linuxWineInstaller: DartIoLinuxWineInstaller(
          hostPlatform: KonyakHostPlatform.linux,
          environment: {'XDG_DATA_HOME': tempDirectory.path},
        ),
        runtimeInstallProgressSink: JsonRuntimeInstallProgressSink(
          progressOutput,
        ),
      );

      expect(result.exitCode, 75);
      final progressLines = progressOutput
          .toString()
          .trim()
          .split('\n')
          .where((line) => line.isNotEmpty)
          .toList(growable: false);
      expect(progressLines.length, greaterThanOrEqualTo(3));

      final fractions = progressLines
          .map((line) => jsonDecode(line) as Map<String, Object?>)
          .map((payload) {
            final progress =
                payload['runtimeInstallProgress'] as Map<String, Object?>;
            return progress['fraction'] as num;
          })
          .toList(growable: false);
      expect(fractions, contains(0));
      expect(fractions.any((fraction) => fraction > 0.05), isTrue);

      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      expect(payload['error'], containsPair('code', 'linuxWineInstallFailed'));
    },
  );

  test('install-linux-wine installs a managed runtime under XDG data home', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-linux-runtime-install-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    final archivePath = _createLinuxWineRuntimeArchive(tempDirectory.path);
    final installer = DartIoLinuxWineInstaller(
      hostPlatform: KonyakHostPlatform.linux,
      environment: {
        'HOME': tempDirectory.path,
        'XDG_DATA_HOME': _joinTestPath(tempDirectory.path, const ['xdg-data']),
      },
      fileStatusProbe: const DartIoFileStatusProbe(),
    );

    final result = installer.install(
      LinuxWineInstallRequest.fullInstall(archivePath: archivePath),
    );

    expect(result, isA<LinuxWineInstallCompleted>());
    final runtime = (result as LinuxWineInstallCompleted).runtime;
    expect(runtime.isInstalled, isTrue);
    expect(
      runtime.executablePath,
      _joinTestPath(tempDirectory.path, const [
        'xdg-data',
        'konyak',
        'Runtimes',
        'linux-wine',
        'bin',
        'wine',
      ]),
    );
    expect(File(runtime.executablePath!).existsSync(), isTrue);
    expect(
      File(
        _joinTestPath(tempDirectory.path, const [
          'xdg-data',
          'konyak',
          'Runtimes',
          'linux-wine',
          'bin',
          'wineboot',
        ]),
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        _joinTestPath(tempDirectory.path, const [
          'xdg-data',
          'konyak',
          'Runtimes',
          'linux-wine',
          'bin',
          'winedbg',
        ]),
      ).existsSync(),
      isTrue,
    );
  });

  test('install-linux-wine builds a stack from component archives', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-linux-runtime-stack-components-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    final wineArchive = _createLinuxWineRuntimeArchive(tempDirectory.path);
    final vkd3dArchive = _createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'vkd3d-proton',
      relativePaths: const <List<String>>[
        <String>['vkd3d-proton', 'x64', 'd3d12.dll'],
        <String>['vkd3d-proton', 'x64', 'd3d12core.dll'],
        <String>['vkd3d-proton', 'x86', 'd3d12.dll'],
        <String>['vkd3d-proton', 'x86', 'd3d12core.dll'],
      ],
      versions: const <String, String>{'vkd3d-proton': 'vkd3d-proton-fixture'},
    );
    final installer = DartIoLinuxWineInstaller(
      hostPlatform: KonyakHostPlatform.linux,
      environment: {
        'HOME': tempDirectory.path,
        'XDG_DATA_HOME': _joinTestPath(tempDirectory.path, const ['xdg-data']),
      },
      fileStatusProbe: const DartIoFileStatusProbe(),
    );

    final result = installer.install(
      LinuxWineInstallRequest.componentInstall(
        archivePath: wineArchive,
        componentArchivePaths: [vkd3dArchive],
      ),
    );

    expect(result, isA<LinuxWineInstallCompleted>());
    final runtime = (result as LinuxWineInstallCompleted).runtime;
    expect(runtime.stack?.isComplete, isTrue);
    expect(
      runtime.stack?.components
          .where((component) => component.id == 'vkd3d-proton')
          .single
          .version,
      'vkd3d-proton-fixture',
    );
    expect(
      File(
        _joinTestPath(tempDirectory.path, const [
          'xdg-data',
          'konyak',
          'Runtimes',
          'linux-wine',
          'vkd3d-proton',
          'x64',
          'd3d12.dll',
        ]),
      ).existsSync(),
      isTrue,
    );
  });

  test('install-linux-wine builds a stack from a source manifest', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-linux-runtime-stack-source-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    final wineArchive = _createLinuxWineRuntimeArchive(tempDirectory.path);
    final vkd3dArchive = _createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'source-vkd3d-proton',
      relativePaths: const <List<String>>[
        <String>['vkd3d-proton', 'x64', 'd3d12.dll'],
        <String>['vkd3d-proton', 'x64', 'd3d12core.dll'],
        <String>['vkd3d-proton', 'x86', 'd3d12.dll'],
        <String>['vkd3d-proton', 'x86', 'd3d12core.dll'],
      ],
      versions: const <String, String>{},
    );
    final sourceManifestPath = _createRuntimeStackSourceManifest(
      tempDirectory.path,
      runtimeId: 'konyak-linux-wine',
      stackId: 'linux-wine-runtime-stack',
      components: <Map<String, String>>[
        _runtimeStackSourceComponent(
          id: 'wine',
          version: 'wine-linux-source',
          archivePath: wineArchive,
        ),
        _runtimeStackSourceComponent(
          id: 'vkd3d-proton',
          version: 'vkd3d-linux-source',
          archivePath: vkd3dArchive,
        ),
      ],
    );
    final installer = DartIoLinuxWineInstaller(
      hostPlatform: KonyakHostPlatform.linux,
      environment: {
        'HOME': tempDirectory.path,
        'XDG_DATA_HOME': _joinTestPath(tempDirectory.path, const ['xdg-data']),
      },
      fileStatusProbe: const DartIoFileStatusProbe(),
    );

    final result = installer.install(
      LinuxWineInstallRequest.fullInstall(sourceManifest: sourceManifestPath),
    );

    expect(result, isA<LinuxWineInstallCompleted>());
    final runtime = (result as LinuxWineInstallCompleted).runtime;
    expect(runtime.stack?.isComplete, isTrue);
    expect(
      runtime.stack?.components
          .where((component) => component.id == 'vkd3d-proton')
          .single
          .version,
      'vkd3d-linux-source',
    );
  });

  test('install-linux-wine repairs an incomplete installed runtime', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-linux-runtime-repair-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    final dataHome = _joinTestPath(tempDirectory.path, const ['xdg-data']);
    final runtimeRoot = _joinTestPath(dataHome, const [
      'konyak',
      'Runtimes',
      'linux-wine',
    ]);
    final existingWine = File(
      _joinTestPath(runtimeRoot, const ['bin', 'wine']),
    );
    existingWine.parent.createSync(recursive: true);
    existingWine.writeAsStringSync('incomplete-runtime');

    final wineArchive = _createLinuxWineRuntimeArchive(tempDirectory.path);
    final vkd3dArchive = _createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'repair-vkd3d-proton',
      relativePaths: const <List<String>>[
        <String>['vkd3d-proton', 'x64', 'd3d12.dll'],
        <String>['vkd3d-proton', 'x64', 'd3d12core.dll'],
        <String>['vkd3d-proton', 'x86', 'd3d12.dll'],
        <String>['vkd3d-proton', 'x86', 'd3d12core.dll'],
      ],
      versions: const <String, String>{},
    );
    final sourceManifestPath = _createRuntimeStackSourceManifest(
      tempDirectory.path,
      runtimeId: 'konyak-linux-wine',
      stackId: 'linux-wine-runtime-stack',
      components: <Map<String, String>>[
        _runtimeStackSourceComponent(
          id: 'wine',
          version: 'wine-linux-repair',
          archivePath: wineArchive,
        ),
        _runtimeStackSourceComponent(
          id: 'vkd3d-proton',
          version: 'vkd3d-linux-repair',
          archivePath: vkd3dArchive,
        ),
      ],
    );
    final installer = DartIoLinuxWineInstaller(
      hostPlatform: KonyakHostPlatform.linux,
      environment: {
        'HOME': tempDirectory.path,
        'XDG_DATA_HOME': dataHome,
        'KONYAK_RUNTIME_PROFILE': 'development',
        'KONYAK_LINUX_WINE_STACK_MANIFEST': _joinTestPath(
          tempDirectory.path,
          const ['release-runtime-stack-source.json'],
        ),
        'KONYAK_DEV_LINUX_WINE_STACK_MANIFEST': sourceManifestPath,
      },
      fileStatusProbe: const DartIoFileStatusProbe(),
    );

    final result = installer.install(LinuxWineInstallRequest.fullInstall());

    expect(result, isA<LinuxWineInstallCompleted>());
    final runtime = (result as LinuxWineInstallCompleted).runtime;
    expect(runtime.stack?.isComplete, isTrue);
    expect(existingWine.readAsStringSync(), 'fixture');
    expect(
      runtime.stack?.components
          .where((component) => component.id == 'vkd3d-proton')
          .single
          .version,
      'vkd3d-linux-repair',
    );
  });

  test('install-linux-wine verifies a signed source manifest', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-linux-runtime-stack-signed-source-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    final wineArchive = _createLinuxWineRuntimeArchive(tempDirectory.path);
    final vkd3dArchive = _createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'signed-source-vkd3d-proton',
      relativePaths: const <List<String>>[
        <String>['vkd3d-proton', 'x64', 'd3d12.dll'],
        <String>['vkd3d-proton', 'x64', 'd3d12core.dll'],
        <String>['vkd3d-proton', 'x86', 'd3d12.dll'],
        <String>['vkd3d-proton', 'x86', 'd3d12core.dll'],
      ],
      versions: const <String, String>{},
    );
    final sourceManifestPath = _createRuntimeStackSourceManifest(
      tempDirectory.path,
      runtimeId: 'konyak-linux-wine',
      stackId: 'linux-wine-runtime-stack',
      components: <Map<String, String>>[
        _runtimeStackSourceComponent(
          id: 'wine',
          version: 'wine-linux-signed-source',
          archivePath: wineArchive,
        ),
        _runtimeStackSourceComponent(
          id: 'vkd3d-proton',
          version: 'vkd3d-linux-signed-source',
          archivePath: vkd3dArchive,
        ),
      ],
    );
    final signature = _createRuntimeStackManifestSignature(
      tempDirectory.path,
      manifestPath: sourceManifestPath,
    );
    final installer = DartIoLinuxWineInstaller(
      hostPlatform: KonyakHostPlatform.linux,
      environment: {
        'HOME': tempDirectory.path,
        'XDG_DATA_HOME': _joinTestPath(tempDirectory.path, const ['xdg-data']),
        'KONYAK_RUNTIME_STACK_PUBLIC_KEY_PATH': signature.publicKeyPath,
      },
      fileStatusProbe: const DartIoFileStatusProbe(),
    );

    final result = installer.install(
      LinuxWineInstallRequest.fullInstall(
        sourceManifest: sourceManifestPath,
        sourceManifestSignature: signature.signaturePath,
      ),
    );

    expect(result, isA<LinuxWineInstallCompleted>());
  });

  test('install-linux-wine rejects invalid source manifest signatures', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-linux-runtime-stack-invalid-signature-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    final wineArchive = _createLinuxWineRuntimeArchive(tempDirectory.path);
    final vkd3dArchive = _createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'invalid-signed-source-vkd3d-proton',
      relativePaths: const <List<String>>[
        <String>['vkd3d-proton', 'x64', 'd3d12.dll'],
        <String>['vkd3d-proton', 'x64', 'd3d12core.dll'],
        <String>['vkd3d-proton', 'x86', 'd3d12.dll'],
        <String>['vkd3d-proton', 'x86', 'd3d12core.dll'],
      ],
      versions: const <String, String>{},
    );
    final sourceManifestPath = _createRuntimeStackSourceManifest(
      tempDirectory.path,
      runtimeId: 'konyak-linux-wine',
      stackId: 'linux-wine-runtime-stack',
      components: <Map<String, String>>[
        _runtimeStackSourceComponent(
          id: 'wine',
          version: 'wine-linux-invalid-signature',
          archivePath: wineArchive,
        ),
        _runtimeStackSourceComponent(
          id: 'vkd3d-proton',
          version: 'vkd3d-linux-invalid-signature',
          archivePath: vkd3dArchive,
        ),
      ],
    );
    final signature = _createRuntimeStackManifestSignature(
      tempDirectory.path,
      manifestPath: sourceManifestPath,
    );
    File(
      sourceManifestPath,
    ).writeAsStringSync('${File(sourceManifestPath).readAsStringSync()}\n');
    final installer = DartIoLinuxWineInstaller(
      hostPlatform: KonyakHostPlatform.linux,
      environment: {
        'HOME': tempDirectory.path,
        'XDG_DATA_HOME': _joinTestPath(tempDirectory.path, const ['xdg-data']),
        'KONYAK_RUNTIME_STACK_PUBLIC_KEY_PATH': signature.publicKeyPath,
      },
      fileStatusProbe: const DartIoFileStatusProbe(),
    );

    final result = installer.install(
      LinuxWineInstallRequest.fullInstall(
        sourceManifest: sourceManifestPath,
        sourceManifestSignature: signature.signaturePath,
      ),
    );

    expect(result, isA<LinuxWineInstallFailed>());
    expect(
      (result as LinuxWineInstallFailed).message,
      contains('signature verification failed'),
    );
  });
}
