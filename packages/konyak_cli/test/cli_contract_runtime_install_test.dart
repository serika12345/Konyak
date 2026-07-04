import 'support/cli_contract_full_helpers.dart';

void main() {
  test('runtime package installer stages and replaces runtime roots', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-runtime-package-installer-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    final archivePath = createLinuxWineRuntimeArchive(tempDirectory.path);
    final runtimeRoot = Directory(
      joinTestPath(tempDirectory.path, const ['runtime']),
    );
    final executablePath = joinTestPath(runtimeRoot.path, const [
      'bin',
      'wine',
    ]);

    final result = const DartIoRuntimePackageInstaller().install(
      RuntimePackageInstallRequest(
        runtimeLabel: 'Linux Wine',
        archivePath: RuntimeArchivePath(archivePath),
        archiveSha256: const Option.none(),
        componentArchivePaths: const <RuntimeArchivePath>[],
        componentVersions: const RuntimeComponentVersions.empty(),
        runtimeRoot: RuntimeRootPath(runtimeRoot.path),
        requiredExecutableRelativePath: RuntimeRelativePath(['bin', 'wine']),
        expectedExecutablePath: RuntimeComponentPath(executablePath),
      ),
    );

    expect(result, isA<RuntimePackageInstallCompleted>());
    expect(File(executablePath).existsSync(), isTrue);
    expect(File('${runtimeRoot.path}.install.lock').existsSync(), isFalse);
  });

  test('install-macos-wine --json installs from a configured manifest source', () {
    final installer = RecordingMacosWineInstaller(
      result: MacosWineInstallCompleted(
        runtime: runtimeRecordFixture(
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
            '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wineloader',
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
            '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wineloader',
      },
    });
  });

  test(
    'install-macos-wine --json is a no-op when Konyak macOS Wine is installed',
    () {
      final tempDirectory = Directory.systemTemp.createTempSync(
        'konyak-installed-runtime-test-',
      );
      addTearDown(() {
        if (tempDirectory.existsSync()) {
          tempDirectory.deleteSync(recursive: true);
        }
      });
      final runtimeHome = joinTestPath(tempDirectory.path, const [
        'Application Support',
        'Konyak',
      ]);
      final runtimeRoot = joinTestPath(runtimeHome, const [
        'Runtimes',
        'macos-wine',
      ]);
      createCompleteMacosRuntime(runtimeRoot);

      final installer = DartIoMacosWineInstaller(
        hostPlatform: KonyakHostPlatform.macos,
        environment: HostEnvironment({
          'KONYAK_APPLICATION_SUPPORT': runtimeHome,
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
          joinTestPath(runtimeRoot, const ['bin', 'wineloader']),
        ),
      );
    },
  );

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

      final runtimeHome = joinTestPath(tempDirectory.path, const [
        'Application Support',
        'Konyak',
      ]);
      final existingWine = File(
        joinTestPath(runtimeHome, const [
          'Runtimes',
          'macos-wine',
          'bin',
          'wineloader',
        ]),
      );
      existingWine.parent.createSync(recursive: true);
      existingWine.writeAsStringSync('incomplete-runtime');

      final archivePath = createKonyakComponentRuntimeArchive(
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
        macosWineFullInstallRequestFixture(archivePath: archivePath),
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

    final invalidArchivePath = joinTestPath(tempDirectory.path, const [
      'invalid-runtime.tar.xz',
    ]);
    File(invalidArchivePath).writeAsStringSync('not a runtime archive');
    final sourceManifestPath = createRuntimeStackSourceManifest(
      tempDirectory.path,
      fileName: macosWineRuntimeSourceManifestFileName,
      components: [
        runtimeStackSourceComponent(
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

    final result = installer.install(macosWineFullInstallRequestFixture());

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
          '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wineloader',
          '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wineserver',
          '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wine',
        }),
      );

      final result = installer.install(macosWineFullInstallRequestFixture());

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

    final archivePath = createComponentRuntimeArchive(tempDirectory.path);
    final runtimeHome = joinTestPath(tempDirectory.path, const [
      'Application Support',
      'Konyak',
    ]);
    final installer = DartIoMacosWineInstaller(
      hostPlatform: KonyakHostPlatform.macos,
      environment: HostEnvironment({'KONYAK_APPLICATION_SUPPORT': runtimeHome}),
      fileStatusProbe: const StaticFileStatusProbe({}),
    );

    final result = installer.install(
      macosWineFullInstallRequestFixture(archivePath: archivePath),
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
          .toNullable()
          ?.value,
      'wine-devel-11.9',
    );
    expect(
      completed.runtime.stack
          .toNullable()
          ?.components[2]
          .version
          .toNullable()
          ?.value,
      'dxvk-macos-fixture',
    );
    expect(
      File(
        joinTestPath(runtimeHome, const [
          'Runtimes',
          'macos-wine',
          'bin',
          'wineloader',
        ]),
      ).existsSync(),
      isTrue,
    );
    expect(
      Directory(
        joinTestPath(runtimeHome, const ['Runtimes', 'macos-wine', 'Wine']),
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

      final runtimeHome = joinTestPath(tempDirectory.path, const [
        'Application Support',
        'Konyak',
      ]);
      final existingWine = File(
        joinTestPath(runtimeHome, const [
          'Runtimes',
          'macos-wine',
          'bin',
          'wineloader',
        ]),
      );
      existingWine.parent.createSync(recursive: true);
      existingWine.writeAsStringSync('existing-runtime');

      final badArchive = createBrokenRuntimeArchive(tempDirectory.path);
      final installer = DartIoMacosWineInstaller(
        hostPlatform: KonyakHostPlatform.macos,
        environment: HostEnvironment({
          'KONYAK_APPLICATION_SUPPORT': runtimeHome,
        }),
        fileStatusProbe: const StaticFileStatusProbe({}),
      );

      final result = installer.install(
        macosWineFullInstallRequestFixture(archivePath: badArchive),
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

      final runtimeHome = joinTestPath(tempDirectory.path, const [
        'Application Support',
        'Konyak',
      ]);
      final existingWine = File(
        joinTestPath(runtimeHome, const [
          'Runtimes',
          'macos-wine',
          'bin',
          'wineloader',
        ]),
      );
      existingWine.parent.createSync(recursive: true);
      existingWine.writeAsStringSync('existing-runtime');

      final archivePath = createKonyakComponentRuntimeArchive(
        tempDirectory.path,
      );
      final badComponentArchive = createInvalidRuntimeArchive(
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
        macosWineComponentInstallRequestFixture(
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

    final runtimeHome = joinTestPath(tempDirectory.path, const [
      'Application Support',
      'Konyak',
    ]);
    final runtimeRoot = joinTestPath(runtimeHome, const [
      'Runtimes',
      'macos-wine',
    ]);
    final existingWine = File(
      joinTestPath(runtimeRoot, const ['bin', 'wineloader']),
    );
    existingWine.parent.createSync(recursive: true);
    existingWine.writeAsStringSync('existing-runtime');
    Directory('$runtimeRoot.install.lock').createSync(recursive: true);

    final archivePath = createKonyakComponentRuntimeArchive(tempDirectory.path);
    final installer = DartIoMacosWineInstaller(
      hostPlatform: KonyakHostPlatform.macos,
      environment: HostEnvironment({'KONYAK_APPLICATION_SUPPORT': runtimeHome}),
      fileStatusProbe: const StaticFileStatusProbe({}),
    );

    final result = installer.install(
      macosWineFullInstallRequestFixture(archivePath: archivePath),
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

      final archivePath = createKonyakComponentRuntimeArchive(
        tempDirectory.path,
      );
      final runtimeHome = joinTestPath(tempDirectory.path, const [
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
        macosWineFullInstallRequestFixture(archivePath: archivePath),
      );

      expect(result, isA<MacosWineInstallCompleted>());
      final completed = result as MacosWineInstallCompleted;
      expect(completed.runtime.stack.toNullable()?.isComplete, isTrue);
      expect(
        completed.runtime.stack
            .toNullable()
            ?.components
            .where((component) => component.id.value == 'dxvk-macos')
            .single
            .version
            .toNullable()
            ?.value,
        'dxvk-macos-fixture',
      );
      expect(
        completed.runtime.stack
            .toNullable()
            ?.components
            .where((component) => component.id.value == 'gptk-d3dmetal')
            .single
            .isInstalled,
        isFalse,
      );
      expect(
        File(
          joinTestPath(runtimeHome, const [
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
          joinTestPath(runtimeHome, const [
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
          joinTestPath(runtimeHome, const [
            'Runtimes',
            'macos-wine',
            'components',
            'gptk-d3dmetal',
          ]),
        ).existsSync(),
        isFalse,
      );
      expect(
        Directory(
          joinTestPath(runtimeHome, const [
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
          joinTestPath(runtimeHome, const [
            'Runtimes',
            'macos-wine',
            'winetricks',
          ]),
        ).existsSync(),
        isTrue,
      );
      for (final relativePath in macosDxmtInstalledPaths) {
        expect(
          File(
            joinTestPath(runtimeHome, [
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

    final wineArchive = createMacosAppBundleWineArchive(tempDirectory.path);
    final dxvkArchive = createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'dxvk-macos',
      relativePaths: macosDxvkComponentPaths,
      versions: const <String, String>{'dxvk-macos': 'dxvk-macos-fixture'},
    );
    final dxmtArchive = createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'dxmt',
      relativePaths: macosDxmtComponentPaths,
      versions: const <String, String>{'dxmt': 'dxmt-fixture'},
    );
    final moltenVkArchive = createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'moltenvk',
      relativePaths: const <List<String>>[
        <String>['Components', 'MoltenVK', 'lib', 'libMoltenVK.dylib'],
      ],
      versions: const <String, String>{'moltenvk': 'moltenvk-fixture'},
    );
    final gstreamerArchive = createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'gstreamer',
      relativePaths: macosGstreamerComponentPaths,
      versions: const <String, String>{'gstreamer': 'gstreamer-fixture'},
    );
    final freetypeArchive = createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'freetype',
      relativePaths: macosFreetypeComponentPaths,
      versions: const <String, String>{'freetype': 'freetype-fixture'},
    );
    final monoArchive = createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'wine-mono',
      relativePaths: macosWineMonoComponentPaths,
      versions: const <String, String>{'wine-mono': 'wine-mono-fixture'},
    );
    final geckoArchive = createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'wine-gecko',
      relativePaths: macosWineGeckoComponentPaths,
      versions: const <String, String>{'wine-gecko': 'wine-gecko-fixture'},
    );
    final winetricksArchive = createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'winetricks',
      relativePaths: macosWinetricksComponentPaths,
      versions: const <String, String>{'winetricks': 'winetricks-fixture'},
    );
    final vkd3dArchive = createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'vkd3d',
      relativePaths: macosVkd3dComponentPaths,
      versions: const <String, String>{'vkd3d': 'vkd3d-fixture'},
    );
    final runtimeHome = joinTestPath(tempDirectory.path, const [
      'Application Support',
      'Konyak',
    ]);
    final installer = DartIoMacosWineInstaller(
      hostPlatform: KonyakHostPlatform.macos,
      environment: HostEnvironment({'KONYAK_APPLICATION_SUPPORT': runtimeHome}),
      fileStatusProbe: const StaticFileStatusProbe({}),
    );

    final result = installer.install(
      macosWineComponentInstallRequestFixture(
        archivePath: wineArchive,
        componentArchivePaths: [
          dxvkArchive,
          dxmtArchive,
          moltenVkArchive,
          gstreamerArchive,
          freetypeArchive,
          monoArchive,
          geckoArchive,
          winetricksArchive,
          vkd3dArchive,
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
          .where((component) => component.id.value == 'dxvk-macos')
          .single
          .version
          .toNullable()
          ?.value,
      'dxvk-macos-fixture',
    );
    expect(
      completed.runtime.stack
          .toNullable()
          ?.components
          .where((component) => component.id.value == 'dxmt')
          .single
          .version
          .toNullable()
          ?.value,
      'dxmt-fixture',
    );
    expect(
      completed.runtime.stack
          .toNullable()
          ?.components
          .where((component) => component.id.value == 'moltenvk')
          .single
          .version
          .toNullable()
          ?.value,
      'moltenvk-fixture',
    );
    expect(
      completed.runtime.stack
          .toNullable()
          ?.components
          .where((component) => component.id.value == 'gptk-d3dmetal')
          .single
          .isInstalled,
      isFalse,
    );
    expect(
      completed.runtime.stack
          .toNullable()
          ?.components
          .where((component) => component.id.value == 'freetype')
          .single
          .version
          .toNullable()
          ?.value,
      'freetype-fixture',
    );
    expect(
      completed.runtime.stack
          .toNullable()
          ?.components
          .where((component) => component.id.value == 'vkd3d')
          .single
          .version
          .toNullable()
          ?.value,
      'vkd3d-fixture',
    );
    for (final relativePath in macosDxmtInstalledPaths) {
      expect(
        File(
          joinTestPath(runtimeHome, [
            'Runtimes',
            'macos-wine',
            ...relativePath,
          ]),
        ).existsSync(),
        isTrue,
      );
    }
    for (final relativePath in macosGstreamerInstalledPaths) {
      expect(
        File(
          joinTestPath(runtimeHome, [
            'Runtimes',
            'macos-wine',
            ...relativePath,
          ]),
        ).existsSync(),
        isTrue,
      );
    }
    for (final relativePath in macosVkd3dInstalledPaths) {
      expect(
        File(
          joinTestPath(runtimeHome, [
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
        joinTestPath(runtimeHome, const [
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
        joinTestPath(runtimeHome, const [
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
        joinTestPath(runtimeHome, const [
          'Runtimes',
          'macos-wine',
          'winetricks',
        ]),
      ).existsSync(),
      isTrue,
    );
    expect(
      Directory(
        joinTestPath(runtimeHome, const [
          'Runtimes',
          'macos-wine',
          'components',
          'gptk-d3dmetal',
        ]),
      ).existsSync(),
      isFalse,
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

    final wineArchive = createMacosAppBundleWineArchive(tempDirectory.path);
    final dxvkArchive = createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'source-dxvk-macos',
      relativePaths: macosDxvkComponentPaths,
      versions: const <String, String>{},
    );
    final dxmtArchive = createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'source-dxmt',
      relativePaths: macosDxmtComponentPaths,
      versions: const <String, String>{},
    );
    final moltenVkArchive = createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'source-moltenvk',
      relativePaths: const <List<String>>[
        <String>['Components', 'MoltenVK', 'lib', 'libMoltenVK.dylib'],
      ],
      versions: const <String, String>{},
    );
    final gstreamerArchive = createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'source-gstreamer',
      relativePaths: macosGstreamerComponentPaths,
      versions: const <String, String>{},
    );
    final freetypeArchive = createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'source-freetype',
      relativePaths: macosFreetypeComponentPaths,
      versions: const <String, String>{},
    );
    final monoArchive = createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'source-wine-mono',
      relativePaths: macosWineMonoComponentPaths,
      versions: const <String, String>{},
    );
    final geckoArchive = createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'source-wine-gecko',
      relativePaths: macosWineGeckoComponentPaths,
      versions: const <String, String>{},
    );
    final winetricksArchive = createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'source-winetricks',
      relativePaths: macosWinetricksComponentPaths,
      versions: const <String, String>{},
    );
    final vkd3dArchive = createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'source-vkd3d',
      relativePaths: macosVkd3dComponentPaths,
      versions: const <String, String>{},
    );
    final gptkD3dMetalArchive = createKonyakRuntimeComponentArchive(
      tempDirectory.path,
      archiveName: 'source-gptk-d3dmetal',
      relativePaths: gptkD3DMetalComponentArchivePaths,
      versions: const <String, String>{},
    );
    final sourceManifestPath = createRuntimeStackSourceManifest(
      tempDirectory.path,
      components: <Map<String, String>>[
        runtimeStackSourceComponent(
          id: 'wine',
          version: 'wine-devel-source',
          archivePath: wineArchive,
        ),
        runtimeStackSourceComponent(
          id: 'dxvk-macos',
          version: 'dxvk-source',
          archivePath: dxvkArchive,
        ),
        runtimeStackSourceComponent(
          id: 'dxmt',
          version: 'dxmt-source',
          archivePath: dxmtArchive,
        ),
        runtimeStackSourceComponent(
          id: 'moltenvk',
          version: 'moltenvk-source',
          archivePath: moltenVkArchive,
        ),
        runtimeStackSourceComponent(
          id: 'gstreamer',
          version: 'gstreamer-source',
          archivePath: gstreamerArchive,
        ),
        runtimeStackSourceComponent(
          id: 'freetype',
          version: 'freetype-source',
          archivePath: freetypeArchive,
        ),
        runtimeStackSourceComponent(
          id: 'wine-mono',
          version: 'wine-mono-source',
          archivePath: monoArchive,
        ),
        runtimeStackSourceComponent(
          id: 'wine-gecko',
          version: 'wine-gecko-source',
          archivePath: geckoArchive,
        ),
        runtimeStackSourceComponent(
          id: 'winetricks',
          version: 'winetricks-source',
          archivePath: winetricksArchive,
        ),
        runtimeStackSourceComponent(
          id: 'vkd3d',
          version: 'vkd3d-source',
          archivePath: vkd3dArchive,
        ),
        runtimeStackSourceComponent(
          id: 'gptk-d3dmetal',
          version: 'gptk-d3dmetal-source',
          archivePath: gptkD3dMetalArchive,
        ),
      ],
    );
    final runtimeHome = joinTestPath(tempDirectory.path, const [
      'Application Support',
      'Konyak',
    ]);
    final installer = DartIoMacosWineInstaller(
      hostPlatform: KonyakHostPlatform.macos,
      environment: HostEnvironment({'KONYAK_APPLICATION_SUPPORT': runtimeHome}),
      fileStatusProbe: const StaticFileStatusProbe({}),
    );

    final result = installer.install(
      macosWineFullInstallRequestFixture(sourceManifest: sourceManifestPath),
    );

    expect(result, isA<MacosWineInstallCompleted>());
    final completed = result as MacosWineInstallCompleted;
    expect(completed.runtime.stack.toNullable()?.isComplete, isTrue);
    expect(
      completed.runtime.stack
          .toNullable()
          ?.components
          .where((component) => component.id.value == 'wine')
          .single
          .version
          .toNullable()
          ?.value,
      'wine-devel-source',
    );
    expect(
      completed.runtime.stack
          .toNullable()
          ?.components
          .where((component) => component.id.value == 'winetricks')
          .single
          .version
          .toNullable()
          ?.value,
      'winetricks-source',
    );
    expect(
      completed.runtime.stack
          .toNullable()
          ?.components
          .where((component) => component.id.value == 'dxmt')
          .single
          .version
          .toNullable()
          ?.value,
      'dxmt-source',
    );
    expect(
      completed.runtime.stack
          .toNullable()
          ?.components
          .where((component) => component.id.value == 'freetype')
          .single
          .version
          .toNullable()
          ?.value,
      'freetype-source',
    );
    expect(
      completed.runtime.stack
          .toNullable()
          ?.components
          .where((component) => component.id.value == 'vkd3d')
          .single
          .version
          .toNullable()
          ?.value,
      'vkd3d-source',
    );
    expect(
      completed.runtime.stack
          .toNullable()
          ?.components
          .where((component) => component.id.value == 'gptk-d3dmetal')
          .single
          .version
          .toNullable()
          ?.value,
      'gptk-d3dmetal-source',
    );
    expect(
      completed.runtime.stack
          .toNullable()
          ?.components
          .where((component) => component.id.value == 'gptk-d3dmetal')
          .single
          .isInstalled,
      isTrue,
    );
  });

  test(
    'install-macos-wine downloads a single-archive source manifest once',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'konyak-runtime-single-stack-source-test-',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final stackArchive = createKonyakComponentRuntimeArchive(
        tempDirectory.path,
      );
      final sourceManifestPath = createRuntimeStackSourceManifest(
        tempDirectory.path,
        components: <Map<String, String>>[
          runtimeStackSourceComponent(
            id: 'wine',
            version: 'wine-devel-source',
            archivePath: stackArchive,
          ),
          runtimeStackSourceComponent(
            id: 'dxvk-macos',
            version: 'dxvk-source',
            archivePath: stackArchive,
          ),
          runtimeStackSourceComponent(
            id: 'dxmt',
            version: 'dxmt-source',
            archivePath: stackArchive,
          ),
          runtimeStackSourceComponent(
            id: 'moltenvk',
            version: 'moltenvk-source',
            archivePath: stackArchive,
          ),
          runtimeStackSourceComponent(
            id: 'gstreamer',
            version: 'gstreamer-source',
            archivePath: stackArchive,
          ),
          runtimeStackSourceComponent(
            id: 'freetype',
            version: 'freetype-source',
            archivePath: stackArchive,
          ),
          runtimeStackSourceComponent(
            id: 'wine-mono',
            version: 'wine-mono-source',
            archivePath: stackArchive,
          ),
          runtimeStackSourceComponent(
            id: 'wine-gecko',
            version: 'wine-gecko-source',
            archivePath: stackArchive,
          ),
          runtimeStackSourceComponent(
            id: 'winetricks',
            version: 'winetricks-source',
            archivePath: stackArchive,
          ),
          runtimeStackSourceComponent(
            id: 'vkd3d',
            version: 'vkd3d-source',
            archivePath: stackArchive,
          ),
        ],
      );
      final runtimeHome = joinTestPath(tempDirectory.path, const [
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
      final progressSink = RecordingRuntimeInstallProgressSink();

      final result = installer.install(
        macosWineFullInstallRequestFixture(
          sourceManifest: sourceManifestPath,
          emitProgress: true,
        ),
        progressSink: progressSink,
      );

      expect(result, isA<MacosWineInstallCompleted>());
      final downloadingEvents = progressSink.events
          .where((event) => event.stage.value == 'downloading')
          .toList();
      expect(downloadingEvents, hasLength(2));
      expect(downloadingEvents.map((event) => event.message).toSet(), {
        'Downloading wine...',
      });
      final completed = result as MacosWineInstallCompleted;
      final stack = completed.runtime.stack.toNullable();
      expect(stack?.isComplete, isTrue);
      expect(
        stack?.components
            .where((component) => component.id.value == 'dxmt')
            .single
            .version
            .toNullable()
            ?.value,
        'dxmt-source',
      );
      expect(
        stack?.components
            .where((component) => component.id.value == 'vkd3d')
            .single
            .version
            .toNullable()
            ?.value,
        'vkd3d-source',
      );
    },
  );

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

      final wineArchive = createKonyakComponentRuntimeArchive(
        tempDirectory.path,
      );
      final dxvkArchive = createKonyakRuntimeComponentArchive(
        tempDirectory.path,
        archiveName: 'repair-dxvk-macos',
        relativePaths: macosDxvkComponentPaths,
        versions: const <String, String>{},
      );
      final dxmtArchive = createKonyakRuntimeComponentArchive(
        tempDirectory.path,
        archiveName: 'repair-dxmt',
        relativePaths: macosDxmtComponentPaths,
        versions: const <String, String>{},
      );
      final moltenVkArchive = createKonyakRuntimeComponentArchive(
        tempDirectory.path,
        archiveName: 'repair-moltenvk',
        relativePaths: const <List<String>>[
          <String>['Components', 'MoltenVK', 'lib', 'libMoltenVK.dylib'],
        ],
        versions: const <String, String>{},
      );
      final gstreamerArchive = createKonyakRuntimeComponentArchive(
        tempDirectory.path,
        archiveName: 'repair-gstreamer',
        relativePaths: macosGstreamerComponentPaths,
        versions: const <String, String>{},
      );
      final freetypeArchive = createKonyakRuntimeComponentArchive(
        tempDirectory.path,
        archiveName: 'repair-freetype',
        relativePaths: macosFreetypeComponentPaths,
        versions: const <String, String>{},
      );
      final monoArchive = createKonyakRuntimeComponentArchive(
        tempDirectory.path,
        archiveName: 'repair-wine-mono',
        relativePaths: macosWineMonoComponentPaths,
        versions: const <String, String>{},
      );
      final geckoArchive = createKonyakRuntimeComponentArchive(
        tempDirectory.path,
        archiveName: 'repair-wine-gecko',
        relativePaths: macosWineGeckoComponentPaths,
        versions: const <String, String>{},
      );
      final winetricksArchive = createKonyakRuntimeComponentArchive(
        tempDirectory.path,
        archiveName: 'repair-winetricks',
        relativePaths: macosWinetricksComponentPaths,
        versions: const <String, String>{},
      );
      final vkd3dArchive = createKonyakRuntimeComponentArchive(
        tempDirectory.path,
        archiveName: 'repair-vkd3d',
        relativePaths: macosVkd3dComponentPaths,
        versions: const <String, String>{},
      );
      final sourceManifestPath = createRuntimeStackSourceManifest(
        tempDirectory.path,
        components: <Map<String, String>>[
          runtimeStackSourceComponent(
            id: 'wine',
            version: 'wine-devel-source',
            archivePath: wineArchive,
          ),
          runtimeStackSourceComponent(
            id: 'dxvk-macos',
            version: 'dxvk-source',
            archivePath: dxvkArchive,
          ),
          runtimeStackSourceComponent(
            id: 'dxmt',
            version: 'dxmt-source',
            archivePath: dxmtArchive,
          ),
          runtimeStackSourceComponent(
            id: 'moltenvk',
            version: 'moltenvk-source',
            archivePath: moltenVkArchive,
          ),
          runtimeStackSourceComponent(
            id: 'gstreamer',
            version: 'gstreamer-source',
            archivePath: gstreamerArchive,
          ),
          runtimeStackSourceComponent(
            id: 'freetype',
            version: 'freetype-source',
            archivePath: freetypeArchive,
          ),
          runtimeStackSourceComponent(
            id: 'wine-mono',
            version: 'wine-mono-source',
            archivePath: monoArchive,
          ),
          runtimeStackSourceComponent(
            id: 'wine-gecko',
            version: 'wine-gecko-source',
            archivePath: geckoArchive,
          ),
          runtimeStackSourceComponent(
            id: 'winetricks',
            version: 'winetricks-source',
            archivePath: winetricksArchive,
          ),
          runtimeStackSourceComponent(
            id: 'vkd3d',
            version: 'vkd3d-source',
            archivePath: vkd3dArchive,
          ),
        ],
      );
      final runtimeHome = joinTestPath(tempDirectory.path, const [
        'Application Support',
        'Konyak',
      ]);
      final runtimeRoot = joinTestPath(runtimeHome, const [
        'Runtimes',
        'macos-wine',
      ]);
      for (final relativePath in const <List<String>>[
        <String>['bin', 'wineloader'],
        <String>['bin', 'wineserver'],
        <String>['bin', 'wine'],
        <String>['lib', 'libwine.1.dylib'],
        ...macosDxvkInstalledPaths,
        <String>['lib', 'libMoltenVK.dylib'],
        ...macosGstreamerInstalledPaths,
        <String>['lib', 'libfreetype.6.dylib'],
        <String>['lib', 'libfreetype.dylib'],
        ...macosWineMonoInstalledPaths,
        ...macosWineGeckoInstalledPaths,
        ...macosVkd3dInstalledPaths,
      ]) {
        final file = File(joinTestPath(runtimeRoot, relativePath));
        file.parent.createSync(recursive: true);
        file.writeAsStringSync('existing-gptk-wine');
      }
      createGptkD3DMetalSource(runtimeRoot, const [
        'components',
        'gptk-d3dmetal',
        'lib',
        'external',
      ]);
      File(
        joinTestPath(runtimeRoot, const ['.konyak-runtime-stack.json']),
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
            'wine-gecko': 'wine-gecko-existing',
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

      final result = installer.install(macosWineFullInstallRequestFixture());

      if (result is MacosWineInstallFailed) {
        fail(result.message);
      }
      expect(result, isA<MacosWineInstallCompleted>());
      final completed = result as MacosWineInstallCompleted;
      expect(completed.runtime.stack.toNullable()?.isComplete, isTrue);
      expect(
        File(joinTestPath(runtimeRoot, const ['winetricks'])).existsSync(),
        isTrue,
      );
      expect(
        File(joinTestPath(runtimeRoot, const ['verbs.txt'])).existsSync(),
        isTrue,
      );
      expect(
        File(
          joinTestPath(runtimeRoot, const ['bin', 'wine']),
        ).readAsStringSync(),
        'existing-gptk-wine',
      );
      final wineComponent = completed.runtime.stack
          .toNullable()
          ?.components
          .where((component) => component.id.value == 'wine')
          .single;
      final gptkComponent = completed.runtime.stack
          .toNullable()
          ?.components
          .where((component) => component.id.value == 'gptk-d3dmetal')
          .single;
      expect(
        wineComponent?.version.toNullable()?.value,
        'user-provided-gptk-wine',
      );
      expect(gptkComponent?.isInstalled, isTrue);
      expect(gptkComponent?.version.toNullable()?.value, 'user-provided');
      final dxmtComponent = completed.runtime.stack
          .toNullable()
          ?.components
          .where((component) => component.id.value == 'dxmt')
          .single;
      expect(dxmtComponent?.isInstalled, isTrue);
      expect(dxmtComponent?.version.toNullable()?.value, 'dxmt-source');
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

      final wineArchive = createKonyakComponentRuntimeArchive(
        tempDirectory.path,
      );
      final runtimeHome = joinTestPath(tempDirectory.path, const [
        'Application Support',
        'Konyak',
      ]);
      final runtimeRoot = joinTestPath(runtimeHome, const [
        'Runtimes',
        'macos-wine',
      ]);
      createInstalledMacosRuntime(runtimeRoot);
      createGptkD3DMetalSource(runtimeRoot, const [
        'components',
        'gptk-d3dmetal',
        'lib',
        'external',
      ]);
      File(
        joinTestPath(runtimeRoot, const ['.konyak-runtime-stack.json']),
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
        macosWineFullInstallRequestFixture(
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
          .where((component) => component.id.value == 'gptk-d3dmetal')
          .single;
      expect(gptkComponent?.isInstalled, isTrue);
      expect(gptkComponent?.version.toNullable()?.value, 'user-provided');
      for (final relativePath in gptkD3DMetalInstalledPaths) {
        expect(
          FileSystemEntity.typeSync(
            joinTestPath(runtimeRoot, relativePath),
            followLinks: false,
          ),
          isNot(FileSystemEntityType.notFound),
        );
      }
      expect(
        Directory(
          joinTestPath(runtimeRoot, const ['lib', 'external']),
        ).existsSync(),
        isFalse,
      );
      for (final dllName in gptkD3DMetalOverrideDllNames) {
        expect(
          File(
            joinTestPath(runtimeRoot, [
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

      final wineArchive = createMacosAppBundleWineArchive(tempDirectory.path);
      final sourceManifestPath = createRuntimeStackSourceManifest(
        tempDirectory.path,
        components: <Map<String, String>>[
          <String, String>{
            ...runtimeStackSourceComponent(
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
        macosWineFullInstallRequestFixture(sourceManifest: sourceManifestPath),
      );

      expect(result, isA<MacosWineInstallFailed>());
      expect(
        (result as MacosWineInstallFailed).message,
        contains('checksum mismatch'),
      );
    },
  );

  test(
    'install-macos-wine rejects archives that leave required stack components missing',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'konyak-runtime-incomplete-install-test-',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final archivePath = createMacosAppBundleWineArchive(tempDirectory.path);
      final runtimeHome = joinTestPath(tempDirectory.path, const [
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
        macosWineFullInstallRequestFixture(archivePath: archivePath),
      );

      expect(result, isA<MacosWineInstallFailed>());
      expect(
        (result as MacosWineInstallFailed).message,
        contains('runtime stack is incomplete'),
      );
      expect(result.message, contains('dxvk-macos'));
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

      final archivePath = createKonyakComponentRuntimeArchive(
        tempDirectory.path,
      );
      final runtimeHome = joinTestPath(tempDirectory.path, const [
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
        macosWineFullInstallRequestFixture(archivePath: archivePath),
      );

      expect(result, isA<MacosWineInstallCompleted>());
      final completed = result as MacosWineInstallCompleted;
      expect(completed.runtime.isInstalled.toNullable(), isTrue);
      expect(
        File(
          joinTestPath(runtimeHome, const [
            'Runtimes',
            'macos-wine',
            'bin',
            'wineloader',
          ]),
        ).existsSync(),
        isTrue,
      );
      expect(
        Directory(
          joinTestPath(runtimeHome, const [
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

  test('install-macos-wine rejects legacy archive install options', () {
    final installer = RecordingMacosWineInstaller(
      result: MacosWineInstallCompleted(
        runtime: runtimeRecordFixture(
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
      '/tmp/macos-wine.tar.xz',
      '--component-archive',
      '/tmp/dxvk.tar.xz',
      '--json',
    ], macosWineInstaller: installer);

    expect(result.exitCode, 64);
    expect(result.stdout, isEmpty);
    expect(result.stderr, contains('install-macos-wine'));
    expect(installer.lastRequest, isNull);
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

    final sourceRoot = createGptkWineRoot(
      tempDirectory.path,
      includeD3DMetal: true,
    );
    final runtimeRoot = Directory(
      joinTestPath(tempDirectory.path, const ['runtime']),
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

    final appBundle = createGptkWineAppBundle(tempDirectory.path);
    final runtimeRoot = Directory(
      joinTestPath(tempDirectory.path, const ['runtime']),
    );
    createInstalledMacosRuntime(runtimeRoot.path);

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

    final appBundle = createGptkWineAppBundle(
      tempDirectory.path,
      includeD3DMetal: true,
    );
    final runtimeRoot = Directory(
      joinTestPath(tempDirectory.path, const ['runtime']),
    );
    createInstalledMacosRuntime(runtimeRoot.path);
    final builtinDxgi =
        File(
            joinTestPath(runtimeRoot.path, const [
              'lib',
              'wine',
              'x86_64-windows',
              'dxgi.dll',
            ]),
          )
          ..parent.createSync(recursive: true)
          ..writeAsStringSync('builtin dxgi');
    File(joinTestPath(runtimeRoot.path, const ['winetricks']))
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('existing winetricks');
    for (final relativePath in macosGstreamerInstalledPaths) {
      File(joinTestPath(runtimeRoot.path, relativePath))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('existing gstreamer');
    }
    File(joinTestPath(runtimeRoot.path, const ['lib', 'libfreetype.6.dylib']))
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('existing freetype');
    File(joinTestPath(runtimeRoot.path, const ['lib', 'libfreetype.dylib']))
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('existing freetype alias');
    File(
        joinTestPath(appBundle.path, <String>[
          'Contents',
          'Resources',
          'wine',
          ...macosWineMonoInstalledPaths.first,
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
        joinTestPath(runtimeRoot.path, const ['bin', 'wineloader']),
      ).readAsStringSync(),
      'fixture',
    );
    expect(
      File(
        joinTestPath(runtimeRoot.path, const [
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
    for (final dllName in gptkD3DMetalWindowsFileNames) {
      expect(
        File(
          joinTestPath(runtimeRoot.path, [
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
    for (final unixName in gptkD3DMetalUnixFileNames) {
      final path = joinTestPath(runtimeRoot.path, [
        'components',
        'gptk-d3dmetal',
        'lib',
        'wine',
        'x86_64-unix',
        unixName,
      ]);
      if (isGptkD3DMetalUnixSymlinkPath(<String>[
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
        joinTestPath(runtimeRoot.path, const ['winetricks']),
      ).readAsStringSync(),
      'existing winetricks',
    );
    for (final relativePath in macosGstreamerInstalledPaths) {
      expect(
        File(joinTestPath(runtimeRoot.path, relativePath)).readAsStringSync(),
        'existing gstreamer',
      );
    }
    expect(
      File(
        joinTestPath(runtimeRoot.path, const ['lib', 'libfreetype.6.dylib']),
      ).readAsStringSync(),
      'existing freetype',
    );
    expect(
      File(
        joinTestPath(runtimeRoot.path, const ['lib', 'libfreetype.dylib']),
      ).readAsStringSync(),
      'existing freetype alias',
    );
    expect(
      File(
        joinTestPath(runtimeRoot.path, macosWineMonoInstalledPaths.first),
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
      joinTestPath(tempDirectory.path, const ['CrossOver.app']),
    );
    final appleGptkRoot = Directory(
      joinTestPath(appBundle.path, const [
        'Contents',
        'SharedSupport',
        'CrossOver',
        'lib64',
        'apple_gptk',
      ]),
    );
    createGptkD3DMetalSource(appleGptkRoot.path, const ['external']);
    final runtimeRoot = Directory(
      joinTestPath(tempDirectory.path, const ['runtime']),
    );
    createInstalledMacosRuntime(runtimeRoot.path);

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
          joinTestPath(runtimeRoot.path, [
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
          joinTestPath(runtimeRoot.path, [
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

    final appBundle = createGptkWineAppBundle(
      tempDirectory.path,
      includeD3DMetal: true,
    );
    File(
      joinTestPath(appBundle.path, const [
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
    final runtimeRoot = joinTestPath(tempDirectory.path, const ['runtime']);
    createInstalledMacosRuntime(runtimeRoot);
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
        runtime: runtimeRecordFixture(
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
        runtime: runtimeRecordFixture(
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
        runtime: runtimeRecordFixture(
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
      joinTestPath(tempDirectory.path, const ['runtime.tar.xz']),
    )..writeAsStringSync('not a runtime');
    final installer = DartIoMacosWineInstaller(
      hostPlatform: KonyakHostPlatform.macos,
      environment: HostEnvironment({
        'KONYAK_APPLICATION_SUPPORT': tempDirectory.path,
      }),
      fileStatusProbe: const StaticFileStatusProbe({}),
    );

    final result = installer.install(
      macosWineFullInstallRequestFixture(
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

  test('install-linux-wine rejects legacy archive install options', () {
    final installer = RecordingLinuxWineInstaller(
      result: LinuxWineInstallCompleted(
        runtime: runtimeRecordFixture(
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

    expect(result.exitCode, 64);
    expect(result.stdout, isEmpty);
    expect(result.stderr, contains('install-linux-wine'));
    expect(installer.lastRequest, isNull);
  });

  test('install-linux-wine --source-manifest passes the source manifest', () {
    final installer = RecordingLinuxWineInstaller(
      result: LinuxWineInstallCompleted(
        runtime: runtimeRecordFixture(
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

  test('install-linux-wine --reinstall forces a full install', () {
    final installer = RecordingLinuxWineInstaller(
      result: LinuxWineInstallCompleted(
        runtime: runtimeRecordFixture(
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

    final result = runCli(const [
      'install-linux-wine',
      '--reinstall',
      '--json',
    ], linuxWineInstaller: installer);

    expect(result.exitCode, 0);
    expect(
      installer.lastRequest?.operation,
      RuntimeInstallOperation.fullInstall,
    );
    expect(installer.lastRequest?.force, isTrue);
  });

  test('install-linux-wine --progress-json emits progress events', () {
    final progressOutput = StringBuffer();
    final installer = RecordingLinuxWineInstaller(
      result: LinuxWineInstallCompleted(
        runtime: runtimeRecordFixture(
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
    'runCliStreaming streams source manifest archive copy progress before final JSON',
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
        joinTestPath(tempDirectory.path, const ['linux-wine.tar.xz']),
      )..writeAsBytesSync(List<int>.filled(128 * 1024, 1));
      final sourceManifest =
          File(
            joinTestPath(tempDirectory.path, const [
              'linux-runtime-stack.json',
            ]),
          )..writeAsStringSync(
            jsonEncode(<String, Object?>{
              'schemaVersion': 1,
              'runtimeId': 'konyak-linux-wine',
              'stackId': 'linux-wine-runtime-stack',
              'components': [
                <String, Object?>{
                  'id': 'wine',
                  'version': 'wine-progress-test',
                  'archiveUrl': sourceArchive.uri.toString(),
                  'sha256': fileSha256(sourceArchive.path),
                },
              ],
            }),
          );
      final progressOutput = StringBuffer();

      final result = await runCliStreaming(
        [
          'install-linux-wine',
          '--source-manifest',
          sourceManifest.path,
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

    final archivePath = createLinuxWineRuntimeArchive(tempDirectory.path);
    final installer = DartIoLinuxWineInstaller(
      hostPlatform: KonyakHostPlatform.linux,
      environment: HostEnvironment({
        'HOME': tempDirectory.path,
        'XDG_DATA_HOME': joinTestPath(tempDirectory.path, const ['xdg-data']),
      }),
      fileStatusProbe: const DartIoFileStatusProbe(),
    );

    final result = installer.install(
      linuxWineFullInstallRequestFixture(archivePath: archivePath),
    );

    expect(result, isA<LinuxWineInstallCompleted>());
    final runtime = (result as LinuxWineInstallCompleted).runtime;
    expect(runtime.isInstalled.toNullable(), isTrue);
    expect(
      runtime.executablePath.toNullable()?.value,
      joinTestPath(tempDirectory.path, const [
        'xdg-data',
        'konyak',
        'Runtimes',
        'linux-wine',
        'bin',
        'wine',
      ]),
    );
    expect(
      File(runtime.executablePath.toNullable()!.value).existsSync(),
      isTrue,
    );
    expect(
      File(
        joinTestPath(tempDirectory.path, const [
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
        joinTestPath(tempDirectory.path, const [
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

    final wineArchive = createLinuxWineRuntimeArchive(tempDirectory.path);
    final vkd3dArchive = createKonyakRuntimeComponentArchive(
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
        'XDG_DATA_HOME': joinTestPath(tempDirectory.path, const ['xdg-data']),
      }),
      fileStatusProbe: const DartIoFileStatusProbe(),
    );

    final result = installer.install(
      linuxWineComponentInstallRequestFixture(
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
          .where((component) => component.id.value == 'vkd3d-proton')
          .single
          .version
          .toNullable()
          ?.value,
      'vkd3d-proton-fixture',
    );
    expect(
      File(
        joinTestPath(tempDirectory.path, const [
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

    final wineArchive = createLinuxWineRuntimeArchive(tempDirectory.path);
    final vkd3dArchive = createKonyakRuntimeComponentArchive(
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
    final sourceManifestPath = createRuntimeStackSourceManifest(
      tempDirectory.path,
      runtimeId: 'konyak-linux-wine',
      stackId: 'linux-wine-runtime-stack',
      components: <Map<String, String>>[
        runtimeStackSourceComponent(
          id: 'wine',
          version: 'wine-linux-source',
          archivePath: wineArchive,
        ),
        runtimeStackSourceComponent(
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
        'XDG_DATA_HOME': joinTestPath(tempDirectory.path, const ['xdg-data']),
      }),
      fileStatusProbe: const DartIoFileStatusProbe(),
    );

    final result = installer.install(
      linuxWineFullInstallRequestFixture(sourceManifest: sourceManifestPath),
    );

    expect(result, isA<LinuxWineInstallCompleted>());
    final runtime = (result as LinuxWineInstallCompleted).runtime;
    expect(runtime.stack.toNullable()?.isComplete, isTrue);
    expect(
      runtime.stack
          .toNullable()
          ?.components
          .where((component) => component.id.value == 'vkd3d-proton')
          .single
          .version
          .toNullable()
          ?.value,
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

    final dataHome = joinTestPath(tempDirectory.path, const ['xdg-data']);
    final runtimeRoot = joinTestPath(dataHome, const [
      'konyak',
      'Runtimes',
      'linux-wine',
    ]);
    final existingWine = File(joinTestPath(runtimeRoot, const ['bin', 'wine']));
    existingWine.parent.createSync(recursive: true);
    existingWine.writeAsStringSync('incomplete-runtime');

    final wineArchive = createLinuxWineRuntimeArchive(tempDirectory.path);
    final vkd3dArchive = createKonyakRuntimeComponentArchive(
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
    final sourceManifestPath = createRuntimeStackSourceManifest(
      tempDirectory.path,
      runtimeId: 'konyak-linux-wine',
      stackId: 'linux-wine-runtime-stack',
      components: <Map<String, String>>[
        runtimeStackSourceComponent(
          id: 'wine',
          version: 'wine-linux-repair',
          archivePath: wineArchive,
        ),
        runtimeStackSourceComponent(
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
        'KONYAK_LINUX_WINE_STACK_MANIFEST': joinTestPath(
          tempDirectory.path,
          const ['release-runtime-stack-source.json'],
        ),
        'KONYAK_DEV_LINUX_WINE_STACK_SOURCE_MANIFEST': sourceManifestPath,
      }),
      fileStatusProbe: const DartIoFileStatusProbe(),
    );

    final result = installer.install(linuxWineFullInstallRequestFixture());

    expect(result, isA<LinuxWineInstallCompleted>());
    final runtime = (result as LinuxWineInstallCompleted).runtime;
    expect(runtime.stack.toNullable()?.isComplete, isTrue);
    expect(existingWine.readAsStringSync(), 'fixture');
    expect(
      runtime.stack
          .toNullable()
          ?.components
          .where((component) => component.id.value == 'vkd3d-proton')
          .single
          .version
          .toNullable()
          ?.value,
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

    final wineArchive = createLinuxWineRuntimeArchive(tempDirectory.path);
    final vkd3dArchive = createKonyakRuntimeComponentArchive(
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
    final sourceManifestPath = createRuntimeStackSourceManifest(
      tempDirectory.path,
      runtimeId: 'konyak-linux-wine',
      stackId: 'linux-wine-runtime-stack',
      components: <Map<String, String>>[
        runtimeStackSourceComponent(
          id: 'wine',
          version: 'wine-linux-signed-source',
          archivePath: wineArchive,
        ),
        runtimeStackSourceComponent(
          id: 'vkd3d-proton',
          version: 'vkd3d-linux-signed-source',
          archivePath: vkd3dArchive,
        ),
      ],
    );
    final signature = createRuntimeStackManifestSignature(
      tempDirectory.path,
      manifestPath: sourceManifestPath,
    );
    final installer = DartIoLinuxWineInstaller(
      hostPlatform: KonyakHostPlatform.linux,
      environment: HostEnvironment({
        'HOME': tempDirectory.path,
        'XDG_DATA_HOME': joinTestPath(tempDirectory.path, const ['xdg-data']),
        'KONYAK_RUNTIME_STACK_PUBLIC_KEY_PATH': signature.publicKeyPath,
      }),
      fileStatusProbe: const DartIoFileStatusProbe(),
    );

    final result = installer.install(
      linuxWineFullInstallRequestFixture(
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

    final wineArchive = createLinuxWineRuntimeArchive(tempDirectory.path);
    final vkd3dArchive = createKonyakRuntimeComponentArchive(
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
    final sourceManifestPath = createRuntimeStackSourceManifest(
      tempDirectory.path,
      runtimeId: 'konyak-linux-wine',
      stackId: 'linux-wine-runtime-stack',
      components: <Map<String, String>>[
        runtimeStackSourceComponent(
          id: 'wine',
          version: 'wine-linux-invalid-signature',
          archivePath: wineArchive,
        ),
        runtimeStackSourceComponent(
          id: 'vkd3d-proton',
          version: 'vkd3d-linux-invalid-signature',
          archivePath: vkd3dArchive,
        ),
      ],
    );
    final signature = createRuntimeStackManifestSignature(
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
        'XDG_DATA_HOME': joinTestPath(tempDirectory.path, const ['xdg-data']),
        'KONYAK_RUNTIME_STACK_PUBLIC_KEY_PATH': signature.publicKeyPath,
      }),
      fileStatusProbe: const DartIoFileStatusProbe(),
    );

    final result = installer.install(
      linuxWineFullInstallRequestFixture(
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
