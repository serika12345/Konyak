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
        archiveSha256: const Option.none(),
        componentArchivePaths: const [],
        componentVersions: const RuntimeComponentVersions.empty(),
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
      result: MacosWineInstallCompleted(
        runtime: RuntimeRecord(
          id: 'konyak-macos-wine',
          name: 'Konyak macOS Wine',
          platform: 'macos',
          architecture: 'x86_64',
          runnerKind: 'macosWine',
          isBundled: false,
          isUpdateable: true,
          isInstalled: Option.of(true),
          applicationSupportPath: Option.of(
            '/Users/user/Library/Application Support/Konyak',
          ),
          libraryPath: Option.of(
            '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine',
          ),
          executablePath: Option.of(
            '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wine64',
          ),
          archiveUrl: const Option.none(),
          versionUrl: Option.of(macosWineRuntimeReleaseUrl),
        ),
      ),
    );

    final result = runCli(const [
      'install-macos-wine',
      '--json',
    ], macosWineInstaller: installer);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(installer.lastRequest?.archivePath.isNone(), isTrue);

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
      environment: HostEnvironment(const {'HOME': '/Users/user'}),
      fileStatusProbe: StaticFileStatusProbe({
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wine64',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wineserver',
        ..._macosWine32On64ExistingPaths(
          '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine',
        ),
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/dxvk/x86_64-windows/dxgi.dll',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/dxvk/x86_64-windows/d3d9.dll',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/dxvk/x86_64-windows/d3d10.dll',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/dxvk/x86_64-windows/d3d10_1.dll',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/dxvk/x86_64-windows/d3d10core.dll',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/dxvk/x86_64-windows/d3d11.dll',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/dxvk/i386-windows/dxgi.dll',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/dxvk/i386-windows/d3d9.dll',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/dxvk/i386-windows/d3d10.dll',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/dxvk/i386-windows/d3d10_1.dll',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/dxvk/i386-windows/d3d10core.dll',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/dxvk/i386-windows/d3d11.dll',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/libMoltenVK.dylib',
        ..._macosGstreamerExistingPaths(
          '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine',
        ),
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/libfreetype.6.dylib',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/libfreetype.dylib',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/share/wine/mono',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/winetricks',
        ..._macosVkd3dExistingPaths(
          '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine',
        ),
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/dxmt/x86_64-windows/d3d10core.dll',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/dxmt/x86_64-windows/d3d11.dll',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/dxmt/x86_64-windows/dxgi.dll',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/dxmt/x86_64-windows/winemetal.dll',
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
        environment: HostEnvironment({
          'KONYAK_APPLICATION_SUPPORT': runtimeHome,
        }),
        fileStatusProbe: StaticFileStatusProbe({existingWine.path}),
      );

      final result = installer.install(
        MacosWineInstallRequest.fullInstall(archivePath: archivePath),
      );

      expect(result, isA<MacosWineInstallCompleted>());
      final completed = result as MacosWineInstallCompleted;
      expect(completed.runtime.stack.toNullable()?.isComplete, isTrue);
      expect(existingWine.readAsStringSync(), 'fixture');
    },
  );

  test('install-macos-wine reports macOS runtime source manifest failures', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-runtime-source-manifest-failure-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    final invalidArchivePath = _joinTestPath(tempDirectory.path, const [
      'invalid-runtime.tar.xz',
    ]);
    File(invalidArchivePath).writeAsStringSync('not a runtime archive');
    final sourceManifestPath = _createRuntimeStackSourceManifest(
      tempDirectory.path,
      fileName: macosWineRuntimeSourceManifestFileName,
      components: [
        _runtimeStackSourceComponent(
          id: 'wine',
          version: 'crossover-26.1.0-konyak.0',
          archivePath: invalidArchivePath,
        ),
      ],
    );
    final installer = DartIoMacosWineInstaller(
      hostPlatform: KonyakHostPlatform.macos,
      environment: HostEnvironment({
        'HOME': '/Users/user',
        'KONYAK_MACOS_WINE_STACK_MANIFEST': sourceManifestPath,
      }),
      fileStatusProbe: const StaticFileStatusProbe({}),
    );

    final result = installer.install(MacosWineInstallRequest.fullInstall());

    expect(result, isA<MacosWineInstallFailed>());
    expect(
      (result as MacosWineInstallFailed).message,
      contains('konyak-macos-wine-runtime-stack-source.json'),
    );
    expect(result.message, contains('Runtime stack source manifest'));
  });

  test(
    'install-macos-wine reports incomplete installed runtime without a configured stack source in development',
    () {
      final installer = DartIoMacosWineInstaller(
        hostPlatform: KonyakHostPlatform.macos,
        environment: HostEnvironment(const {
          'HOME': '/Users/user',
          'KONYAK_RUNTIME_PROFILE': 'development',
        }),
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
      environment: HostEnvironment({'KONYAK_APPLICATION_SUPPORT': runtimeHome}),
      fileStatusProbe: const StaticFileStatusProbe({}),
    );

    final result = installer.install(
      MacosWineInstallRequest.fullInstall(archivePath: archivePath),
    );

    expect(result, isA<MacosWineInstallCompleted>());
    final completed = result as MacosWineInstallCompleted;
    expect(completed.runtime.isInstalled.toNullable(), isTrue);
    expect(completed.runtime.stack.toNullable()?.isComplete, isTrue);
    expect(
      completed.runtime.stack
          .toNullable()
          ?.components
          .first
          .version
          .toNullable(),
      'wine-devel-11.9',
    );
    expect(
      completed.runtime.stack.toNullable()?.components[2].version.toNullable(),
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
        environment: HostEnvironment({
          'KONYAK_APPLICATION_SUPPORT': runtimeHome,
        }),
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
        environment: HostEnvironment({
          'KONYAK_APPLICATION_SUPPORT': runtimeHome,
        }),
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
      environment: HostEnvironment({'KONYAK_APPLICATION_SUPPORT': runtimeHome}),
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
        environment: HostEnvironment({
          'KONYAK_APPLICATION_SUPPORT': runtimeHome,
        }),
        fileStatusProbe: const StaticFileStatusProbe({}),
      );

      final result = installer.install(
        MacosWineInstallRequest.fullInstall(archivePath: archivePath),
      );

      expect(result, isA<MacosWineInstallCompleted>());
      final completed = result as MacosWineInstallCompleted;
      expect(completed.runtime.stack.toNullable()?.isComplete, isTrue);
      expect(
        completed.runtime.stack
            .toNullable()
            ?.components
            .where((component) => component.id == 'dxvk-macos')
            .single
            .version
            .toNullable(),
        'dxvk-macos-fixture',
      );
      expect(
        completed.runtime.stack
            .toNullable()
            ?.components
            .where((component) => component.id == 'gptk-d3dmetal')
            .single
            .version
            .toNullable(),
        'gptk-d3dmetal-fixture',
      );
      expect(
        File(
          _joinTestPath(runtimeHome, const [
            'Runtimes',
            'macos-wine',
            'lib',
            'dxvk',
            'x86_64-windows',
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
            'components',
            'gptk-d3dmetal',
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
            'components',
            'gptk-d3dmetal',
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
      for (final relativePath in _macosDxmtInstalledPaths) {
        expect(
          File(
            _joinTestPath(runtimeHome, [
              'Runtimes',
              'macos-wine',
              ...relativePath,
            ]),
          ).existsSync(),
          isTrue,
        );
      }
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
    final dxmtArchive = _createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'dxmt',
      relativePaths: _macosDxmtComponentPaths,
      versions: const <String, String>{'dxmt': 'dxmt-fixture'},
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
      relativePaths: _macosGstreamerComponentPaths,
      versions: const <String, String>{'gstreamer': 'gstreamer-fixture'},
    );
    final freetypeArchive = _createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'freetype',
      relativePaths: _macosFreetypeComponentPaths,
      versions: const <String, String>{'freetype': 'freetype-fixture'},
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
    final vkd3dArchive = _createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'vkd3d',
      relativePaths: _macosVkd3dComponentPaths,
      versions: const <String, String>{'vkd3d': 'vkd3d-fixture'},
    );
    final gptkD3dMetalArchive = _createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'gptk-d3dmetal',
      relativePaths: _gptkD3DMetalComponentArchivePaths,
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
      environment: HostEnvironment({'KONYAK_APPLICATION_SUPPORT': runtimeHome}),
      fileStatusProbe: const StaticFileStatusProbe({}),
    );

    final result = installer.install(
      MacosWineInstallRequest.componentInstall(
        archivePath: wineArchive,
        componentArchivePaths: [
          dxvkArchive,
          dxmtArchive,
          moltenVkArchive,
          gstreamerArchive,
          freetypeArchive,
          monoArchive,
          winetricksArchive,
          vkd3dArchive,
          gptkD3dMetalArchive,
        ],
      ),
    );

    expect(result, isA<MacosWineInstallCompleted>());
    final completed = result as MacosWineInstallCompleted;
    expect(completed.runtime.stack.toNullable()?.isComplete, isTrue);
    expect(
      completed.runtime.stack
          .toNullable()
          ?.components
          .where((component) => component.id == 'dxvk-macos')
          .single
          .version
          .toNullable(),
      'dxvk-macos-fixture',
    );
    expect(
      completed.runtime.stack
          .toNullable()
          ?.components
          .where((component) => component.id == 'dxmt')
          .single
          .version
          .toNullable(),
      'dxmt-fixture',
    );
    expect(
      completed.runtime.stack
          .toNullable()
          ?.components
          .where((component) => component.id == 'moltenvk')
          .single
          .version
          .toNullable(),
      'moltenvk-fixture',
    );
    expect(
      completed.runtime.stack
          .toNullable()
          ?.components
          .where((component) => component.id == 'gptk-d3dmetal')
          .single
          .version
          .toNullable(),
      'gptk-d3dmetal-fixture',
    );
    expect(
      completed.runtime.stack
          .toNullable()
          ?.components
          .where((component) => component.id == 'freetype')
          .single
          .version
          .toNullable(),
      'freetype-fixture',
    );
    expect(
      completed.runtime.stack
          .toNullable()
          ?.components
          .where((component) => component.id == 'vkd3d')
          .single
          .version
          .toNullable(),
      'vkd3d-fixture',
    );
    for (final relativePath in _macosDxmtInstalledPaths) {
      expect(
        File(
          _joinTestPath(runtimeHome, [
            'Runtimes',
            'macos-wine',
            ...relativePath,
          ]),
        ).existsSync(),
        isTrue,
      );
    }
    for (final relativePath in _macosGstreamerInstalledPaths) {
      expect(
        File(
          _joinTestPath(runtimeHome, [
            'Runtimes',
            'macos-wine',
            ...relativePath,
          ]),
        ).existsSync(),
        isTrue,
      );
    }
    for (final relativePath in _macosVkd3dInstalledPaths) {
      expect(
        File(
          _joinTestPath(runtimeHome, [
            'Runtimes',
            'macos-wine',
            ...relativePath,
          ]),
        ).existsSync(),
        isTrue,
      );
    }
    expect(
      File(
        _joinTestPath(runtimeHome, const [
          'Runtimes',
          'macos-wine',
          'lib',
          'libfreetype.6.dylib',
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
          'libfreetype.dylib',
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
          'components',
          'gptk-d3dmetal',
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
    final dxmtArchive = _createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'source-dxmt',
      relativePaths: _macosDxmtComponentPaths,
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
      relativePaths: _macosGstreamerComponentPaths,
      versions: const <String, String>{},
    );
    final freetypeArchive = _createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'source-freetype',
      relativePaths: _macosFreetypeComponentPaths,
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
    final vkd3dArchive = _createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'source-vkd3d',
      relativePaths: _macosVkd3dComponentPaths,
      versions: const <String, String>{},
    );
    final gptkD3dMetalArchive = _createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'source-gptk-d3dmetal',
      relativePaths: _gptkD3DMetalComponentArchivePaths,
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
          id: 'dxmt',
          version: 'dxmt-source',
          archivePath: dxmtArchive,
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
          id: 'freetype',
          version: 'freetype-source',
          archivePath: freetypeArchive,
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
          id: 'vkd3d',
          version: 'vkd3d-source',
          archivePath: vkd3dArchive,
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
      environment: HostEnvironment({'KONYAK_APPLICATION_SUPPORT': runtimeHome}),
      fileStatusProbe: const StaticFileStatusProbe({}),
    );

    final result = installer.install(
      MacosWineInstallRequest.fullInstall(sourceManifest: sourceManifestPath),
    );

    expect(result, isA<MacosWineInstallCompleted>());
    final completed = result as MacosWineInstallCompleted;
    expect(completed.runtime.stack.toNullable()?.isComplete, isTrue);
    expect(
      completed.runtime.stack
          .toNullable()
          ?.components
          .where((component) => component.id == 'wine')
          .single
          .version
          .toNullable(),
      'wine-devel-source',
    );
    expect(
      completed.runtime.stack
          .toNullable()
          ?.components
          .where((component) => component.id == 'winetricks')
          .single
          .version
          .toNullable(),
      'winetricks-source',
    );
    expect(
      completed.runtime.stack
          .toNullable()
          ?.components
          .where((component) => component.id == 'dxmt')
          .single
          .version
          .toNullable(),
      'dxmt-source',
    );
    expect(
      completed.runtime.stack
          .toNullable()
          ?.components
          .where((component) => component.id == 'freetype')
          .single
          .version
          .toNullable(),
      'freetype-source',
    );
    expect(
      completed.runtime.stack
          .toNullable()
          ?.components
          .where((component) => component.id == 'vkd3d')
          .single
          .version
          .toNullable(),
      'vkd3d-source',
    );
    expect(
      completed.runtime.stack
          .toNullable()
          ?.components
          .where((component) => component.id == 'gptk-d3dmetal')
          .single
          .version
          .toNullable(),
      'gptk-d3dmetal-source',
    );
    expect(
      completed.runtime.stack
          .toNullable()
          ?.components
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
      final dxmtArchive = _createKonyakRuntimeComponentArchive(
        tempDirectory.path,
        archiveName: 'repair-dxmt',
        relativePaths: _macosDxmtComponentPaths,
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
        relativePaths: _macosGstreamerComponentPaths,
        versions: const <String, String>{},
      );
      final freetypeArchive = _createKonyakRuntimeComponentArchive(
        tempDirectory.path,
        archiveName: 'repair-freetype',
        relativePaths: _macosFreetypeComponentPaths,
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
      final vkd3dArchive = _createKonyakRuntimeComponentArchive(
        tempDirectory.path,
        archiveName: 'repair-vkd3d',
        relativePaths: _macosVkd3dComponentPaths,
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
            id: 'dxmt',
            version: 'dxmt-source',
            archivePath: dxmtArchive,
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
            id: 'freetype',
            version: 'freetype-source',
            archivePath: freetypeArchive,
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
            id: 'vkd3d',
            version: 'vkd3d-source',
            archivePath: vkd3dArchive,
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
        ..._macosGstreamerInstalledPaths,
        <String>['lib', 'libfreetype.6.dylib'],
        <String>['lib', 'libfreetype.dylib'],
        <String>['share', 'wine', 'mono', 'wine-mono.marker'],
        ..._macosVkd3dInstalledPaths,
      ]) {
        final file = File(_joinTestPath(runtimeRoot, relativePath));
        file.parent.createSync(recursive: true);
        file.writeAsStringSync('existing-gptk-wine');
      }
      _createGptkD3DMetalSource(runtimeRoot, const ['lib', 'external']);
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
            'freetype': 'freetype-existing',
            'wine-mono': 'wine-mono-existing',
            'vkd3d': 'vkd3d-existing',
            'gptk-d3dmetal': 'user-provided',
          },
        }),
      );
      final installer = DartIoMacosWineInstaller(
        hostPlatform: KonyakHostPlatform.macos,
        environment: HostEnvironment({
          'KONYAK_RUNTIME_PROFILE': 'development',
          'KONYAK_APPLICATION_SUPPORT': runtimeHome,
          'KONYAK_DEV_MACOS_WINE_STACK_MANIFEST': sourceManifestPath,
        }),
      );

      final result = installer.install(MacosWineInstallRequest.fullInstall());

      if (result is MacosWineInstallFailed) {
        fail(result.message);
      }
      expect(result, isA<MacosWineInstallCompleted>());
      final completed = result as MacosWineInstallCompleted;
      expect(completed.runtime.stack.toNullable()?.isComplete, isTrue);
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
      final wineComponent = completed.runtime.stack
          .toNullable()
          ?.components
          .where((component) => component.id == 'wine')
          .single;
      final gptkComponent = completed.runtime.stack
          .toNullable()
          ?.components
          .where((component) => component.id == 'gptk-d3dmetal')
          .single;
      expect(wineComponent?.version.toNullable(), 'user-provided-gptk-wine');
      expect(gptkComponent?.isInstalled, isTrue);
      expect(gptkComponent?.version.toNullable(), 'user-provided');
      final dxmtComponent = completed.runtime.stack
          .toNullable()
          ?.components
          .where((component) => component.id == 'dxmt')
          .single;
      expect(dxmtComponent?.isInstalled, isTrue);
      expect(dxmtComponent?.version.toNullable(), 'dxmt-source');
    },
  );

  test(
    'install-macos-wine preserves imported GPTK as an isolated component on reinstall',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'konyak-runtime-reinstall-gptk-test-',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final wineArchive = _createMacosAppBundleWineArchive(tempDirectory.path);
      final runtimeHome = _joinTestPath(tempDirectory.path, const [
        'Application Support',
        'Konyak',
      ]);
      final runtimeRoot = _joinTestPath(runtimeHome, const [
        'Runtimes',
        'macos-wine',
      ]);
      _createInstalledMacosRuntime(runtimeRoot);
      _createGptkD3DMetalSource(runtimeRoot, const ['lib', 'external']);
      File(
        _joinTestPath(runtimeRoot, const ['.konyak-runtime-stack.json']),
      ).writeAsStringSync(
        jsonEncode(<String, Object?>{
          'schemaVersion': 1,
          'components': <String, String>{
            'wine': 'old-wine',
            'gptk-d3dmetal': 'user-provided',
          },
        }),
      );
      final installer = DartIoMacosWineInstaller(
        hostPlatform: KonyakHostPlatform.macos,
        environment: HostEnvironment({
          'KONYAK_APPLICATION_SUPPORT': runtimeHome,
        }),
      );

      final result = installer.install(
        MacosWineInstallRequest.fullInstall(
          archivePath: wineArchive,
          force: true,
        ),
      );

      if (result is MacosWineInstallFailed) {
        fail(result.message);
      }
      expect(result, isA<MacosWineInstallCompleted>());
      final completed = result as MacosWineInstallCompleted;
      final gptkComponent = completed.runtime.stack
          .toNullable()
          ?.components
          .where((component) => component.id == 'gptk-d3dmetal')
          .single;
      expect(gptkComponent?.isInstalled, isTrue);
      expect(gptkComponent?.version.toNullable(), 'user-provided');
      for (final relativePath in _gptkD3DMetalInstalledPaths) {
        expect(
          FileSystemEntity.typeSync(
            _joinTestPath(runtimeRoot, relativePath),
            followLinks: false,
          ),
          isNot(FileSystemEntityType.notFound),
        );
      }
      expect(
        Directory(
          _joinTestPath(runtimeRoot, const ['lib', 'external']),
        ).existsSync(),
        isFalse,
      );
      for (final dllName in _gptkD3DMetalOverrideDllNames) {
        expect(
          File(
            _joinTestPath(runtimeRoot, [
              'lib',
              'wine',
              'x86_64-windows',
              dllName,
            ]),
          ).existsSync(),
          isFalse,
        );
      }
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
        environment: HostEnvironment({
          'KONYAK_APPLICATION_SUPPORT': tempDirectory.path,
        }),
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
        environment: HostEnvironment({
          'KONYAK_APPLICATION_SUPPORT': runtimeHome,
        }),
        fileStatusProbe: const StaticFileStatusProbe({}),
      );

      final result = installer.install(
        MacosWineInstallRequest.fullInstall(archivePath: archivePath),
      );

      expect(result, isA<MacosWineInstallCompleted>());
      final completed = result as MacosWineInstallCompleted;
      expect(completed.runtime.isInstalled.toNullable(), isTrue);
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
      result: MacosWineInstallCompleted(
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
    expect(
      installer.lastRequest?.archivePath.toNullable(),
      '/tmp/macos-wine.tar.xz',
    );
  });

  test('install-macos-wine --archive-sha256 passes an expected digest', () {
    final installer = RecordingMacosWineInstaller(
      result: MacosWineInstallCompleted(
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
    expect(
      installer.lastRequest?.archivePath.toNullable(),
      '/tmp/macos-wine.tar.xz',
    );
    expect(
      installer.lastRequest?.archiveSha256.toNullable(),
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
    );
  });

  test('install-macos-wine --component-archive passes component archives', () {
    final installer = RecordingMacosWineInstaller(
      result: MacosWineInstallCompleted(
        runtime: RuntimeRecord(
          id: 'konyak-macos-wine',
          name: 'Konyak macOS Wine',
          platform: 'macos',
          architecture: 'x86_64',
          runnerKind: 'macosWine',
          isBundled: false,
          isUpdateable: true,
          isInstalled: Option.of(true),
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
    expect(installer.lastRequest?.archivePath.toNullable(), '/tmp/wine.tar.xz');
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

  test('install-gptk-wine rejects sources without an installed runtime', () {
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
        environment: HostEnvironment({
          'KONYAK_MACOS_WINE_HOME': runtimeRoot.path,
        }),
      ),
    );

    expect(result.exitCode, 75);
    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    final error = payload['error'] as Map<String, Object?>;
    expect(error['code'], 'gptkWineInstallFailed');
    expect(error['message'], contains('Install Konyak macOS Wine'));
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
        environment: HostEnvironment({
          'KONYAK_MACOS_WINE_HOME': runtimeRoot.path,
        }),
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
    final builtinDxgi =
        File(
            _joinTestPath(runtimeRoot.path, const [
              'lib',
              'wine',
              'x86_64-windows',
              'dxgi.dll',
            ]),
          )
          ..parent.createSync(recursive: true)
          ..writeAsStringSync('builtin dxgi');
    File(_joinTestPath(runtimeRoot.path, const ['winetricks']))
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('existing winetricks');
    for (final relativePath in _macosGstreamerInstalledPaths) {
      File(_joinTestPath(runtimeRoot.path, relativePath))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('existing gstreamer');
    }
    File(_joinTestPath(runtimeRoot.path, const ['lib', 'libfreetype.6.dylib']))
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('existing freetype');
    File(_joinTestPath(runtimeRoot.path, const ['lib', 'libfreetype.dylib']))
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('existing freetype alias');
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
        environment: HostEnvironment({
          'KONYAK_MACOS_WINE_HOME': runtimeRoot.path,
        }),
      ),
    );

    expect(result.exitCode, 0, reason: result.stderr);
    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    final install = payload['gptkWineInstall'] as Map<String, Object?>;
    expect(install['componentId'], 'gptk-d3dmetal');
    expect(
      install['sourceDirectory'],
      endsWith('Game Porting Toolkit.app/Contents/Resources/wine'),
    );
    expect(
      File(
        _joinTestPath(runtimeRoot.path, const ['bin', 'wine64']),
      ).readAsStringSync(),
      'fixture',
    );
    expect(
      File(
        _joinTestPath(runtimeRoot.path, const [
          'components',
          'gptk-d3dmetal',
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
    for (final dllName in _gptkD3DMetalWindowsFileNames) {
      expect(
        File(
          _joinTestPath(runtimeRoot.path, [
            'components',
            'gptk-d3dmetal',
            'lib',
            'wine',
            'x86_64-windows',
            dllName,
          ]),
        ).existsSync(),
        isTrue,
      );
    }
    for (final unixName in _gptkD3DMetalUnixFileNames) {
      final path = _joinTestPath(runtimeRoot.path, [
        'components',
        'gptk-d3dmetal',
        'lib',
        'wine',
        'x86_64-unix',
        unixName,
      ]);
      if (_isGptkD3DMetalUnixSymlinkPath(<String>[
        'components',
        'gptk-d3dmetal',
        'lib',
        'wine',
        'x86_64-unix',
        unixName,
      ])) {
        expect(Link(path).targetSync(), '../../external/libd3dshared.dylib');
      } else {
        expect(File(path).existsSync(), isTrue);
      }
    }
    expect(builtinDxgi.readAsStringSync(), 'builtin dxgi');
    expect(
      File(
        _joinTestPath(runtimeRoot.path, const ['winetricks']),
      ).readAsStringSync(),
      'existing winetricks',
    );
    for (final relativePath in _macosGstreamerInstalledPaths) {
      expect(
        File(_joinTestPath(runtimeRoot.path, relativePath)).readAsStringSync(),
        'existing gstreamer',
      );
    }
    expect(
      File(
        _joinTestPath(runtimeRoot.path, const ['lib', 'libfreetype.6.dylib']),
      ).readAsStringSync(),
      'existing freetype',
    );
    expect(
      File(
        _joinTestPath(runtimeRoot.path, const ['lib', 'libfreetype.dylib']),
      ).readAsStringSync(),
      'existing freetype alias',
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

  test('install-gptk-wine imports the CrossOver apple_gptk layout', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-gptk-wine-crossover-app-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    final appBundle = Directory(
      _joinTestPath(tempDirectory.path, const ['CrossOver.app']),
    );
    final appleGptkRoot = Directory(
      _joinTestPath(appBundle.path, const [
        'Contents',
        'SharedSupport',
        'CrossOver',
        'lib64',
        'apple_gptk',
      ]),
    );
    _createGptkD3DMetalSource(appleGptkRoot.path, const ['external']);
    final runtimeRoot = Directory(
      _joinTestPath(tempDirectory.path, const ['runtime']),
    );
    _createInstalledMacosRuntime(runtimeRoot.path);

    final result = runCli(
      ['install-gptk-wine', '--from', appBundle.path, '--json'],
      gptkWineInstaller: DartIoGptkWineInstaller(
        environment: HostEnvironment({
          'KONYAK_MACOS_WINE_HOME': runtimeRoot.path,
        }),
      ),
    );

    expect(result.exitCode, 0, reason: result.stderr);
    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    final install = payload['gptkWineInstall'] as Map<String, Object?>;
    expect(install['sourceDirectory'], appleGptkRoot.path);
    for (final dllName in const <String>['nvapi64.dll', 'nvngx.dll']) {
      expect(
        File(
          _joinTestPath(runtimeRoot.path, [
            'components',
            'gptk-d3dmetal',
            'lib',
            'wine',
            'x86_64-windows',
            dllName,
          ]),
        ).existsSync(),
        isTrue,
      );
    }
    for (final unixName in const <String>['nvapi64.so', 'nvngx.so']) {
      expect(
        Link(
          _joinTestPath(runtimeRoot.path, [
            'components',
            'gptk-d3dmetal',
            'lib',
            'wine',
            'x86_64-unix',
            unixName,
          ]),
        ).targetSync(),
        '../../external/libd3dshared.dylib',
      );
    }
  });

  test('install-gptk-wine rejects fixture text D3DMetal binaries as JSON', () {
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
      includeD3DMetal: true,
    );
    File(
      _joinTestPath(appBundle.path, const [
        'Contents',
        'Resources',
        'wine',
        'lib',
        'external',
        'D3DMetal.framework',
        'Versions',
        'A',
        'D3DMetal',
      ]),
    ).writeAsStringSync('fixture');
    final runtimeRoot = _joinTestPath(tempDirectory.path, const ['runtime']);
    _createInstalledMacosRuntime(runtimeRoot);
    final result = runCli(
      ['install-gptk-wine', '--from', appBundle.path, '--json'],
      gptkWineInstaller: DartIoGptkWineInstaller(
        environment: HostEnvironment({'KONYAK_MACOS_WINE_HOME': runtimeRoot}),
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
      result: MacosWineInstallCompleted(
        runtime: RuntimeRecord(
          id: 'konyak-macos-wine',
          name: 'Konyak macOS Wine',
          platform: 'macos',
          architecture: 'x86_64',
          runnerKind: 'macosWine',
          isBundled: false,
          isUpdateable: true,
          isInstalled: Option.of(true),
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
    expect(
      installer.lastRequest?.sourceManifest.toNullable(),
      '/tmp/runtime-stack.json',
    );
  });

  test('install-macos-wine --reinstall forces a full install', () {
    final installer = RecordingMacosWineInstaller(
      result: MacosWineInstallCompleted(
        runtime: RuntimeRecord(
          id: 'konyak-macos-wine',
          name: 'Konyak macOS Wine',
          platform: 'macos',
          architecture: 'x86_64',
          runnerKind: 'macosWine',
          isBundled: false,
          isUpdateable: true,
          isInstalled: Option.of(true),
        ),
      ),
    );

    final result = runCli(const [
      'install-macos-wine',
      '--reinstall',
      '--json',
    ], macosWineInstaller: installer);

    expect(result.exitCode, 0);
    expect(
      installer.lastRequest?.operation,
      RuntimeInstallOperation.fullInstall,
    );
    expect(installer.lastRequest?.force, isTrue);
  });

  test('install-macos-wine --progress-json emits progress events', () {
    final progressOutput = StringBuffer();
    final installer = RecordingMacosWineInstaller(
      result: MacosWineInstallCompleted(
        runtime: RuntimeRecord(
          id: 'konyak-macos-wine',
          name: 'Konyak macOS Wine',
          platform: 'macos',
          architecture: 'x86_64',
          runnerKind: 'macosWine',
          isBundled: false,
          isUpdateable: true,
          isInstalled: Option.of(true),
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
      environment: HostEnvironment({
        'KONYAK_APPLICATION_SUPPORT': tempDirectory.path,
      }),
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
      result: LinuxWineInstallCompleted(
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
    expect(
      installer.lastRequest?.archivePath.toNullable(),
      '/tmp/linux-wine.tar.xz',
    );
  });

  test('install-linux-wine --component-archive passes component archives', () {
    final installer = RecordingLinuxWineInstaller(
      result: LinuxWineInstallCompleted(
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
    expect(
      installer.lastRequest?.archivePath.toNullable(),
      '/tmp/linux-wine.tar.xz',
    );
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
      result: LinuxWineInstallCompleted(
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
      installer.lastRequest?.sourceManifest.toNullable(),
      '/tmp/linux-runtime-stack.json',
    );
  });

  test('install-linux-wine --progress-json emits progress events', () {
    final progressOutput = StringBuffer();
    final installer = RecordingLinuxWineInstaller(
      result: LinuxWineInstallCompleted(
        runtime: RuntimeRecord(
          id: 'konyak-linux-wine',
          name: 'Konyak Linux Wine',
          platform: 'linux',
          architecture: 'x86_64',
          runnerKind: 'wine',
          isBundled: false,
          isUpdateable: true,
          isInstalled: Option.of(true),
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
          environment: HostEnvironment({'XDG_DATA_HOME': tempDirectory.path}),
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
      environment: HostEnvironment({
        'HOME': tempDirectory.path,
        'XDG_DATA_HOME': _joinTestPath(tempDirectory.path, const ['xdg-data']),
      }),
      fileStatusProbe: const DartIoFileStatusProbe(),
    );

    final result = installer.install(
      LinuxWineInstallRequest.fullInstall(archivePath: archivePath),
    );

    expect(result, isA<LinuxWineInstallCompleted>());
    final runtime = (result as LinuxWineInstallCompleted).runtime;
    expect(runtime.isInstalled.toNullable(), isTrue);
    expect(
      runtime.executablePath.toNullable(),
      _joinTestPath(tempDirectory.path, const [
        'xdg-data',
        'konyak',
        'Runtimes',
        'linux-wine',
        'bin',
        'wine',
      ]),
    );
    expect(File(runtime.executablePath.toNullable()!).existsSync(), isTrue);
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
      environment: HostEnvironment({
        'HOME': tempDirectory.path,
        'XDG_DATA_HOME': _joinTestPath(tempDirectory.path, const ['xdg-data']),
      }),
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
    expect(runtime.stack.toNullable()?.isComplete, isTrue);
    expect(
      runtime.stack
          .toNullable()
          ?.components
          .where((component) => component.id == 'vkd3d-proton')
          .single
          .version
          .toNullable(),
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
      environment: HostEnvironment({
        'HOME': tempDirectory.path,
        'XDG_DATA_HOME': _joinTestPath(tempDirectory.path, const ['xdg-data']),
      }),
      fileStatusProbe: const DartIoFileStatusProbe(),
    );

    final result = installer.install(
      LinuxWineInstallRequest.fullInstall(sourceManifest: sourceManifestPath),
    );

    expect(result, isA<LinuxWineInstallCompleted>());
    final runtime = (result as LinuxWineInstallCompleted).runtime;
    expect(runtime.stack.toNullable()?.isComplete, isTrue);
    expect(
      runtime.stack
          .toNullable()
          ?.components
          .where((component) => component.id == 'vkd3d-proton')
          .single
          .version
          .toNullable(),
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
      environment: HostEnvironment({
        'HOME': tempDirectory.path,
        'XDG_DATA_HOME': dataHome,
        'KONYAK_RUNTIME_PROFILE': 'development',
        'KONYAK_LINUX_WINE_STACK_MANIFEST': _joinTestPath(
          tempDirectory.path,
          const ['release-runtime-stack-source.json'],
        ),
        'KONYAK_DEV_LINUX_WINE_STACK_MANIFEST': sourceManifestPath,
      }),
      fileStatusProbe: const DartIoFileStatusProbe(),
    );

    final result = installer.install(LinuxWineInstallRequest.fullInstall());

    expect(result, isA<LinuxWineInstallCompleted>());
    final runtime = (result as LinuxWineInstallCompleted).runtime;
    expect(runtime.stack.toNullable()?.isComplete, isTrue);
    expect(existingWine.readAsStringSync(), 'fixture');
    expect(
      runtime.stack
          .toNullable()
          ?.components
          .where((component) => component.id == 'vkd3d-proton')
          .single
          .version
          .toNullable(),
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
      environment: HostEnvironment({
        'HOME': tempDirectory.path,
        'XDG_DATA_HOME': _joinTestPath(tempDirectory.path, const ['xdg-data']),
        'KONYAK_RUNTIME_STACK_PUBLIC_KEY_PATH': signature.publicKeyPath,
      }),
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
      environment: HostEnvironment({
        'HOME': tempDirectory.path,
        'XDG_DATA_HOME': _joinTestPath(tempDirectory.path, const ['xdg-data']),
        'KONYAK_RUNTIME_STACK_PUBLIC_KEY_PATH': signature.publicKeyPath,
      }),
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
