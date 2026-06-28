part of 'cli_contract_test.dart';

void defineRuntimeProcessAndUpdateContractTests() {
  test('list-runtimes --json returns the versioned empty runtime contract', () {
    final result = runCli(const ['list-runtimes', '--json']);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {'schemaVersion': 1, 'runtimes': <Object?>[]});
  });

  test('list-runtimes --json serializes runtime records from the catalog', () {
    final result = runCli(
      const ['list-runtimes', '--json'],
      runtimeCatalog: StaticRuntimeCatalog([
        RuntimeRecord(
          id: 'wine-stable-linux-x86_64',
          name: 'Wine Stable',
          platform: 'linux',
          architecture: 'x86_64',
          runnerKind: 'wine',
          isBundled: false,
          isUpdateable: true,
        ),
      ]),
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'runtimes': [
        {
          'id': 'wine-stable-linux-x86_64',
          'name': 'Wine Stable',
          'platform': 'linux',
          'architecture': 'x86_64',
          'runnerKind': 'wine',
          'isBundled': false,
          'isUpdateable': true,
        },
      ],
    });
  });

  test('runtime records compose definition state and capabilities', () {
    final runtime = RuntimeRecord.fromParts(
      definition: RuntimeDefinition(
        id: 'konyak-linux-wine',
        name: 'Konyak Linux Wine',
        platform: 'linux',
        architecture: 'x86_64',
        runnerKind: 'wine',
        isBundled: false,
        isUpdateable: true,
        distributionKind: Option.of('managed'),
        archiveUrl: Option.of('https://example.invalid/linux-wine.tar.xz'),
        versionUrl: Option.of('https://example.invalid/releases/latest'),
      ),
      installedState: InstalledRuntimeState(
        isInstalled: Option.of(true),
        libraryPath: Option.of(
          '/home/user/.local/share/konyak/Runtimes/linux-wine',
        ),
        executablePath: Option.of(
          '/home/user/.local/share/konyak/Runtimes/linux-wine/bin/wine',
        ),
      ),
      capabilities: RuntimeCapabilities(
        stack: Option.of(
          RuntimeStack(
            id: 'linux-wine-runtime-stack',
            name: 'Linux Wine/Proton runtime stack',
            compatibilityTarget: 'linux-wine-runtime-stack',
            backends: [
              RuntimeStackBackend(
                id: 'dxvk',
                name: 'DXVK',
                role: 'd3d9-d3d11-vulkan-translation',
                componentIds: const <String>['dxvk'],
                missingComponentIds: const <String>[],
                missingPaths: const <String>[],
              ),
            ],
            components: [
              RuntimeStackComponent(
                id: 'wine',
                name: 'Wine',
                role: 'windows-runner',
                isRequired: true,
                paths: const [
                  '/home/user/.local/share/konyak/Runtimes/linux-wine/bin/wine',
                ],
                missingPaths: const [],
              ),
            ],
          ),
        ),
      ),
    );

    expect(
      runtime.archiveUrl.toNullable()?.value,
      'https://example.invalid/linux-wine.tar.xz',
    );
    expect(
      runtime.versionUrl.toNullable()?.value,
      'https://example.invalid/releases/latest',
    );
    expect(runtimeRecordJson(runtime), {
      'id': 'konyak-linux-wine',
      'name': 'Konyak Linux Wine',
      'platform': 'linux',
      'architecture': 'x86_64',
      'runnerKind': 'wine',
      'isBundled': false,
      'isUpdateable': true,
      'distributionKind': 'managed',
      'isInstalled': true,
      'libraryPath': '/home/user/.local/share/konyak/Runtimes/linux-wine',
      'executablePath':
          '/home/user/.local/share/konyak/Runtimes/linux-wine/bin/wine',
      'stack': {
        'schemaVersion': 1,
        'id': 'linux-wine-runtime-stack',
        'name': 'Linux Wine/Proton runtime stack',
        'compatibilityTarget': 'linux-wine-runtime-stack',
        'isComplete': true,
        'components': [
          {
            'id': 'wine',
            'name': 'Wine',
            'role': 'windows-runner',
            'isRequired': true,
            'isInstalled': true,
            'paths': [
              '/home/user/.local/share/konyak/Runtimes/linux-wine/bin/wine',
            ],
            'missingPaths': <Object?>[],
          },
        ],
        'backends': [
          {
            'id': 'dxvk',
            'name': 'DXVK',
            'role': 'd3d9-d3d11-vulkan-translation',
            'isAvailable': true,
            'componentIds': ['dxvk'],
            'missingComponentIds': <Object?>[],
            'missingPaths': <Object?>[],
          },
        ],
      },
    });
  });

  test('list-runtimes --json reports the Konyak macOS Wine runtime', () {
    final result = runCli(
      const ['list-runtimes', '--json'],
      runtimeCatalog: MacosWineRuntimeCatalog(
        hostPlatform: KonyakHostPlatform.macos,
        environment: HostEnvironment(const {'HOME': '/Users/user'}),
        fileStatusProbe: StaticFileStatusProbe({
          ..._macosWineEntryPointExistingPaths(
            '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine',
          ),
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
          ..._macosWineMonoExistingPaths(
            '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine',
          ),
          ..._macosWineGeckoExistingPaths(
            '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine',
          ),
          ..._macosWinetricksExistingPaths(
            '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine',
          ),
          ..._macosVkd3dExistingPaths(
            '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine',
          ),
        }),
        runtimeStackVersionProbe: const EmptyRuntimeStackVersionProbe(),
      ),
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'runtimes': [
        {
          'id': 'konyak-macos-wine',
          'name': 'Konyak macOS Wine',
          'platform': 'macos',
          'architecture': 'x86_64',
          'runnerKind': 'macosWine',
          'isBundled': false,
          'isUpdateable': true,
          'distributionKind': 'bootstrap',
          'isInstalled': true,
          'applicationSupportPath':
              '/Users/user/Library/Application Support/Konyak',
          'libraryPath':
              '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine',
          'executablePath':
              '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wineloader',
          'stack': {
            'schemaVersion': 1,
            'id': 'macos-konyak-runtime-stack',
            'name': 'Konyak macOS runtime stack',
            'compatibilityTarget': 'macos-konyak-runtime-stack',
            'isComplete': false,
            'components': [
              {
                'id': 'wine',
                'name': 'Wine',
                'role': 'windows-runner',
                'isRequired': true,
                'isInstalled': true,
                'paths': _macosWineEntryPointExpectedPaths(
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine',
                ),
                'missingPaths': <Object?>[],
              },
              {
                'id': 'wine32on64',
                'name': 'Wine32-on-64 support',
                'role': '32-bit-windows-support',
                'isRequired': true,
                'isInstalled': true,
                'paths': _macosWine32On64ExpectedPaths(
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine',
                ),
                'missingPaths': <Object?>[],
              },
              {
                'id': 'dxvk-macos',
                'name': 'DXVK-macOS',
                'role': 'd3d9-d3d11-translation',
                'isRequired': true,
                'isInstalled': true,
                'paths': [
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
                ],
                'missingPaths': <Object?>[],
              },
              {
                'id': 'moltenvk',
                'name': 'MoltenVK',
                'role': 'vulkan-metal-translation',
                'isRequired': true,
                'isInstalled': true,
                'paths': [
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/libMoltenVK.dylib',
                ],
                'missingPaths': <Object?>[],
              },
              {
                'id': 'gstreamer',
                'name': 'GStreamer runtime',
                'role': 'media-runtime',
                'isRequired': true,
                'isInstalled': true,
                'paths': _macosGstreamerExpectedPaths(
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine',
                ),
                'missingPaths': <Object?>[],
              },
              {
                'id': 'freetype',
                'name': 'FreeType font runtime',
                'role': 'font-rendering',
                'isRequired': true,
                'isInstalled': true,
                'paths': [
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/libfreetype.6.dylib',
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/libfreetype.dylib',
                ],
                'missingPaths': <Object?>[],
              },
              {
                'id': 'wine-mono',
                'name': 'wine-mono',
                'role': 'dotnet-runtime',
                'isRequired': true,
                'isInstalled': true,
                'paths': _macosWineMonoExpectedPaths(
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine',
                ),
                'missingPaths': <Object?>[],
              },
              {
                'id': 'wine-gecko',
                'name': 'wine-gecko',
                'role': 'html-runtime',
                'isRequired': true,
                'isInstalled': true,
                'paths': _macosWineGeckoExpectedPaths(
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine',
                ),
                'missingPaths': <Object?>[],
              },
              {
                'id': 'winetricks',
                'name': 'winetricks',
                'role': 'verb-installer',
                'isRequired': true,
                'isInstalled': true,
                'paths': _macosWinetricksExpectedPaths(
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine',
                ),
                'missingPaths': <Object?>[],
              },
              {
                'id': 'vkd3d',
                'name': 'vkd3d',
                'role': 'd3d12-vulkan-runtime',
                'isRequired': true,
                'isInstalled': true,
                'paths': _macosVkd3dExpectedPaths(
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine',
                ),
                'missingPaths': <Object?>[],
              },
              {
                'id': 'dxmt',
                'name': 'DXMT',
                'role': 'd3d10-d3d11-metal-translation',
                'isRequired': true,
                'isInstalled': false,
                'paths': [
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/dxmt/x86_64-windows/d3d10core.dll',
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/dxmt/x86_64-windows/d3d11.dll',
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/dxmt/x86_64-windows/dxgi.dll',
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/dxmt/x86_64-windows/winemetal.dll',
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/dxmt/x86_64-windows/winemetal.so',
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/dxmt/x86_64-windows/nvapi64.dll',
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/dxmt/x86_64-windows/nvngx.dll',
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/dxmt/x86_64-unix/winemetal.so',
                ],
                'missingPaths': [
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/dxmt/x86_64-windows/d3d10core.dll',
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/dxmt/x86_64-windows/d3d11.dll',
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/dxmt/x86_64-windows/dxgi.dll',
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/dxmt/x86_64-windows/winemetal.dll',
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/dxmt/x86_64-windows/winemetal.so',
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/dxmt/x86_64-windows/nvapi64.dll',
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/dxmt/x86_64-windows/nvngx.dll',
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/dxmt/x86_64-unix/winemetal.so',
                ],
              },
              {
                'id': 'gptk-d3dmetal',
                'name': 'GPTK/D3DMetal',
                'role': 'd3d12-metal-translation',
                'isRequired': false,
                'isInstalled': false,
                'paths': _gptkD3DMetalExpectedPaths(
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine',
                ),
                'missingPaths': _gptkD3DMetalExpectedPaths(
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine',
                ),
              },
            ],
            'backends': [
              {
                'id': 'dxvk-macos',
                'name': 'DXVK-macOS',
                'role': 'd3d9-d3d11-metal-translation',
                'isAvailable': true,
                'componentIds': ['dxvk-macos', 'moltenvk'],
                'missingComponentIds': <Object?>[],
                'missingPaths': <Object?>[],
              },
              {
                'id': 'dxmt',
                'name': 'DXMT',
                'role': 'd3d10-d3d11-metal-translation',
                'isAvailable': false,
                'componentIds': ['dxmt'],
                'missingComponentIds': ['dxmt'],
                'missingPaths': [
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/dxmt/x86_64-windows/d3d10core.dll',
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/dxmt/x86_64-windows/d3d11.dll',
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/dxmt/x86_64-windows/dxgi.dll',
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/dxmt/x86_64-windows/winemetal.dll',
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/dxmt/x86_64-windows/winemetal.so',
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/dxmt/x86_64-windows/nvapi64.dll',
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/dxmt/x86_64-windows/nvngx.dll',
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/lib/dxmt/x86_64-unix/winemetal.so',
                ],
              },
              {
                'id': 'vkd3d',
                'name': 'vkd3d',
                'role': 'd3d12-vulkan-metal-translation',
                'isAvailable': true,
                'componentIds': ['vkd3d', 'moltenvk'],
                'missingComponentIds': <Object?>[],
                'missingPaths': <Object?>[],
              },
              {
                'id': 'gptk-d3dmetal',
                'name': 'GPTK/D3DMetal',
                'role': 'd3d12-metal-translation',
                'isAvailable': false,
                'componentIds': ['gptk-d3dmetal'],
                'missingComponentIds': ['gptk-d3dmetal'],
                'missingPaths': _gptkD3DMetalExpectedPaths(
                  '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine',
                ),
              },
            ],
          },
        },
      ],
    });
  });

  test('list-runtimes --json reports missing stack components separately', () {
    final result = runCli(
      const ['list-runtimes', '--json'],
      runtimeCatalog: MacosWineRuntimeCatalog(
        hostPlatform: KonyakHostPlatform.macos,
        environment: HostEnvironment(const {'HOME': '/Users/user'}),
        fileStatusProbe: const StaticFileStatusProbe({
          '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wineloader',
        }),
        runtimeStackVersionProbe: const EmptyRuntimeStackVersionProbe(),
      ),
    );

    expect(result.exitCode, 0);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    final runtimes = payload['runtimes'] as List<Object?>;
    final runtime = runtimes.single as Map<String, Object?>;
    final stack = runtime['stack'] as Map<String, Object?>;
    final components = stack['components'] as List<Object?>;
    final wine = components.first as Map<String, Object?>;
    final dxvk = components[2] as Map<String, Object?>;

    expect(runtime['isInstalled'], isTrue);
    expect(stack['isComplete'], isFalse);
    expect(wine['id'], 'wine');
    expect(wine['isInstalled'], isFalse);
    expect(
      wine['missingPaths'],
      contains(
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wineserver',
      ),
    );
    expect(dxvk['id'], 'dxvk-macos');
    expect(dxvk['isInstalled'], isFalse);
  });

  test('list-runtimes --json requires the macOS Winetricks verb catalog', () {
    const runtimeRoot =
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine';
    final existingPaths = <String>{
      ..._macosWineEntryPointExistingPaths(runtimeRoot),
      ..._macosWine32On64ExistingPaths(runtimeRoot),
      for (final relativePath in _macosDxvkInstalledPaths)
        _joinTestPath(runtimeRoot, <String>[
          'lib',
          'dxvk',
          ...relativePath.skip(1),
        ]),
      _joinTestPath(runtimeRoot, const ['lib', 'libMoltenVK.dylib']),
      ..._macosGstreamerExistingPaths(runtimeRoot),
      _joinTestPath(runtimeRoot, const ['lib', 'libfreetype.6.dylib']),
      _joinTestPath(runtimeRoot, const ['lib', 'libfreetype.dylib']),
      ..._macosWineMonoExistingPaths(runtimeRoot),
      ..._macosWineGeckoExistingPaths(runtimeRoot),
      _joinTestPath(runtimeRoot, const ['winetricks']),
      ..._macosVkd3dExistingPaths(runtimeRoot),
      for (final relativePath in _macosDxmtInstalledPaths)
        _joinTestPath(runtimeRoot, relativePath),
    };
    final result = runCli(
      const ['list-runtimes', '--json'],
      runtimeCatalog: MacosWineRuntimeCatalog(
        hostPlatform: KonyakHostPlatform.macos,
        environment: HostEnvironment(const {'HOME': '/Users/user'}),
        fileStatusProbe: StaticFileStatusProbe(existingPaths),
        runtimeStackVersionProbe: const EmptyRuntimeStackVersionProbe(),
      ),
    );

    expect(result.exitCode, 0);
    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    final runtimes = payload['runtimes'] as List<Object?>;
    final runtime = runtimes.single as Map<String, Object?>;
    final stack = runtime['stack'] as Map<String, Object?>;
    final components = stack['components'] as List<Object?>;
    final winetricks = components.cast<Map<String, Object?>>().singleWhere(
      (component) => component['id'] == 'winetricks',
    );

    expect(stack['isComplete'], isFalse);
    expect(winetricks['isInstalled'], isFalse);
    expect(
      winetricks['missingPaths'],
      contains(_joinTestPath(runtimeRoot, const ['verbs.txt'])),
    );
  });

  test(
    'list-runtimes --json reports missing GPTK/D3DMetal as optional last',
    () {
      const runtimeRoot =
          '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine';
      final existingPaths = <String>{
        ..._macosWineEntryPointExistingPaths(runtimeRoot),
        ..._macosWine32On64ExistingPaths(runtimeRoot),
        ..._macosDxvkExistingPaths(runtimeRoot),
        _joinTestPath(runtimeRoot, const ['lib', 'libMoltenVK.dylib']),
        ..._macosGstreamerExistingPaths(runtimeRoot),
        _joinTestPath(runtimeRoot, const ['lib', 'libfreetype.6.dylib']),
        _joinTestPath(runtimeRoot, const ['lib', 'libfreetype.dylib']),
        ..._macosWineMonoExistingPaths(runtimeRoot),
        ..._macosWineGeckoExistingPaths(runtimeRoot),
        ..._macosWinetricksExistingPaths(runtimeRoot),
        ..._macosVkd3dExistingPaths(runtimeRoot),
        for (final relativePath in _macosDxmtInstalledPaths)
          _joinTestPath(runtimeRoot, relativePath),
      };
      final result = runCli(
        const ['list-runtimes', '--json'],
        runtimeCatalog: MacosWineRuntimeCatalog(
          hostPlatform: KonyakHostPlatform.macos,
          environment: HostEnvironment(const {'HOME': '/Users/user'}),
          fileStatusProbe: StaticFileStatusProbe(existingPaths),
          runtimeStackVersionProbe: const EmptyRuntimeStackVersionProbe(),
        ),
      );

      expect(result.exitCode, 0);
      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      final runtime =
          (payload['runtimes'] as List<Object?>).single as Map<String, Object?>;
      final stack = runtime['stack'] as Map<String, Object?>;
      final components = (stack['components'] as List<Object?>)
          .cast<Map<String, Object?>>();
      final gptk = components.last;

      expect(stack['isComplete'], isTrue);
      expect(gptk['id'], 'gptk-d3dmetal');
      expect(gptk['isRequired'], isFalse);
      expect(gptk['isInstalled'], isFalse);
    },
  );

  test(
    'list-runtimes --json does not treat GPTK fixture text as installed',
    () {
      final tempDirectory = Directory.systemTemp.createTempSync(
        'konyak-gptk-runtime-fixture-test-',
      );
      addTearDown(() {
        if (tempDirectory.existsSync()) {
          tempDirectory.deleteSync(recursive: true);
        }
      });
      final runtimeHome = _joinTestPath(tempDirectory.path, const ['runtime']);
      _createInstalledMacosRuntime(runtimeHome);
      for (final relativePath in _macosDxvkComponentPaths) {
        final file = File(
          _joinTestPath(runtimeHome, relativePath.skip(2).toList()),
        );
        file.parent.createSync(recursive: true);
        file.writeAsStringSync('fixture');
      }
      for (final relativePath in const <List<String>>[
        <String>['lib', 'libMoltenVK.dylib'],
        ..._macosGstreamerInstalledPaths,
        <String>['lib', 'libfreetype.6.dylib'],
        <String>['lib', 'libfreetype.dylib'],
        ..._macosWinetricksInstalledPaths,
      ]) {
        final file = File(_joinTestPath(runtimeHome, relativePath));
        file.parent.createSync(recursive: true);
        file.writeAsStringSync('fixture');
      }
      final frameworkBinary = File(
        _joinTestPath(runtimeHome, const [
          'components',
          'gptk-d3dmetal',
          'lib',
          'external',
          'D3DMetal.framework',
          'Versions',
          'A',
          'D3DMetal',
        ]),
      );
      frameworkBinary.parent.createSync(recursive: true);
      frameworkBinary.writeAsStringSync('Konyak macOS dev runtime fixture');
      File(
        _joinTestPath(runtimeHome, const [
          'components',
          'gptk-d3dmetal',
          'lib',
          'external',
          'libd3dshared.dylib',
        ]),
      ).writeAsStringSync('fixture');
      File(
        _joinTestPath(runtimeHome, const [runtimeStackManifestFileName]),
      ).writeAsStringSync(
        jsonEncode({
          'schemaVersion': 1,
          'components': {'gptk-d3dmetal': 'local-gptk-d3dmetal'},
        }),
      );

      final result = runCli(
        const ['list-runtimes', '--json'],
        runtimeCatalog: MacosWineRuntimeCatalog(
          hostPlatform: KonyakHostPlatform.macos,
          environment: HostEnvironment({'KONYAK_MACOS_WINE_HOME': runtimeHome}),
          fileStatusProbe: DartIoFileStatusProbe(),
          runtimeStackVersionProbe: const DartIoRuntimeStackVersionProbe(),
        ),
      );

      expect(result.exitCode, 0);
      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      final runtimes = payload['runtimes'] as List<Object?>;
      final runtime = runtimes.single as Map<String, Object?>;
      final stack = runtime['stack'] as Map<String, Object?>;
      final components = stack['components'] as List<Object?>;
      final gptk = components.cast<Map<String, Object?>>().singleWhere(
        (component) => component['id'] == 'gptk-d3dmetal',
      );

      expect(gptk['isInstalled'], isFalse);
      expect(gptk.containsKey('version'), isFalse);
      expect(gptk['missingPaths'], contains(contains('D3DMetal.framework')));
    },
  );

  test('list-runtimes --json omits Konyak macOS Wine outside macOS', () {
    final result = runCli(
      const ['list-runtimes', '--json'],
      runtimeCatalog: MacosWineRuntimeCatalog(
        hostPlatform: KonyakHostPlatform.linux,
        environment: HostEnvironment(const {'HOME': '/home/user'}),
        fileStatusProbe: const StaticFileStatusProbe({}),
        runtimeStackVersionProbe: const EmptyRuntimeStackVersionProbe(),
      ),
    );

    expect(result.exitCode, 0);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {'schemaVersion': 1, 'runtimes': <Object?>[]});
  });

  test('list-runtimes --json reports the Konyak Linux Wine runtime', () {
    final result = runCli(
      const ['list-runtimes', '--json'],
      runtimeCatalog: KonyakRuntimeCatalog(
        hostPlatform: KonyakHostPlatform.linux,
        environment: HostEnvironment(const {
          'HOME': '/home/user',
          'KONYAK_LINUX_WINE_VERSION_URL':
              'https://example.invalid/releases/latest',
          'KONYAK_LINUX_WINE_STACK_MANIFEST':
              'https://example.invalid/linux-runtime-stack-source.json',
        }),
        fileStatusProbe: const StaticFileStatusProbe({
          '/home/user/.local/share/konyak/Runtimes/linux-wine/bin/wine',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/bin/winedbg',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/bin/wineserver',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/winetricks',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/share/wine/mono',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/dxvk/x64/dxgi.dll',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/dxvk/x64/d3d9.dll',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/dxvk/x64/d3d10core.dll',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/dxvk/x64/d3d11.dll',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/dxvk/x86/dxgi.dll',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/dxvk/x86/d3d9.dll',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/dxvk/x86/d3d10core.dll',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/dxvk/x86/d3d11.dll',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/vkd3d-proton/x64/d3d12.dll',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/vkd3d-proton/x64/d3d12core.dll',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/vkd3d-proton/x86/d3d12.dll',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/vkd3d-proton/x86/d3d12core.dll',
        }),
        runtimeStackVersionProbe: const EmptyRuntimeStackVersionProbe(),
      ),
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'runtimes': [
        {
          'id': 'konyak-linux-wine',
          'name': 'Konyak Linux Wine',
          'platform': 'linux',
          'architecture': 'x86_64',
          'runnerKind': 'wine',
          'isBundled': false,
          'isUpdateable': true,
          'distributionKind': 'managed',
          'isInstalled': true,
          'libraryPath': '/home/user/.local/share/konyak/Runtimes/linux-wine',
          'executablePath':
              '/home/user/.local/share/konyak/Runtimes/linux-wine/bin/wine',
          'stack': {
            'schemaVersion': 1,
            'id': 'linux-wine-runtime-stack',
            'name': 'Linux Wine/Proton runtime stack',
            'compatibilityTarget': 'linux-wine-runtime-stack',
            'isComplete': true,
            'components': [
              {
                'id': 'wine',
                'name': 'Wine',
                'role': 'windows-runner',
                'isRequired': true,
                'isInstalled': true,
                'paths': [
                  '/home/user/.local/share/konyak/Runtimes/linux-wine/bin/wine',
                  '/home/user/.local/share/konyak/Runtimes/linux-wine/bin/winedbg',
                  '/home/user/.local/share/konyak/Runtimes/linux-wine/bin/wineserver',
                ],
                'missingPaths': <Object?>[],
              },
              {
                'id': 'winetricks',
                'name': 'winetricks',
                'role': 'verb-installer',
                'isRequired': true,
                'isInstalled': true,
                'paths': [
                  '/home/user/.local/share/konyak/Runtimes/linux-wine/winetricks',
                ],
                'missingPaths': <Object?>[],
              },
              {
                'id': 'wine-mono',
                'name': 'wine-mono',
                'role': 'dotnet-runtime',
                'isRequired': true,
                'isInstalled': true,
                'paths': [
                  '/home/user/.local/share/konyak/Runtimes/linux-wine/share/wine/mono',
                ],
                'missingPaths': <Object?>[],
              },
              {
                'id': 'dxvk',
                'name': 'DXVK',
                'role': 'd3d9-d3d11-vulkan-translation',
                'isRequired': true,
                'isInstalled': true,
                'paths': [
                  '/home/user/.local/share/konyak/Runtimes/linux-wine/dxvk/x64/dxgi.dll',
                  '/home/user/.local/share/konyak/Runtimes/linux-wine/dxvk/x64/d3d9.dll',
                  '/home/user/.local/share/konyak/Runtimes/linux-wine/dxvk/x64/d3d10core.dll',
                  '/home/user/.local/share/konyak/Runtimes/linux-wine/dxvk/x64/d3d11.dll',
                  '/home/user/.local/share/konyak/Runtimes/linux-wine/dxvk/x86/dxgi.dll',
                  '/home/user/.local/share/konyak/Runtimes/linux-wine/dxvk/x86/d3d9.dll',
                  '/home/user/.local/share/konyak/Runtimes/linux-wine/dxvk/x86/d3d10core.dll',
                  '/home/user/.local/share/konyak/Runtimes/linux-wine/dxvk/x86/d3d11.dll',
                ],
                'missingPaths': <Object?>[],
              },
              {
                'id': 'vkd3d-proton',
                'name': 'vkd3d-proton',
                'role': 'd3d12-vulkan-translation',
                'isRequired': true,
                'isInstalled': true,
                'paths': [
                  '/home/user/.local/share/konyak/Runtimes/linux-wine/vkd3d-proton/x64/d3d12.dll',
                  '/home/user/.local/share/konyak/Runtimes/linux-wine/vkd3d-proton/x64/d3d12core.dll',
                  '/home/user/.local/share/konyak/Runtimes/linux-wine/vkd3d-proton/x86/d3d12.dll',
                  '/home/user/.local/share/konyak/Runtimes/linux-wine/vkd3d-proton/x86/d3d12core.dll',
                ],
                'missingPaths': <Object?>[],
              },
            ],
            'backends': [
              {
                'id': 'dxvk',
                'name': 'DXVK',
                'role': 'd3d9-d3d11-vulkan-translation',
                'isAvailable': true,
                'componentIds': ['dxvk'],
                'missingComponentIds': <Object?>[],
                'missingPaths': <Object?>[],
              },
              {
                'id': 'vkd3d-proton',
                'name': 'vkd3d-proton',
                'role': 'd3d12-vulkan-translation',
                'isAvailable': true,
                'componentIds': ['vkd3d-proton'],
                'missingComponentIds': <Object?>[],
                'missingPaths': <Object?>[],
              },
            ],
          },
        },
      ],
    });
  });

  test('list-runtimes --json requires every Linux DXVK override DLL', () {
    final result = runCli(
      const ['list-runtimes', '--json'],
      runtimeCatalog: KonyakRuntimeCatalog(
        hostPlatform: KonyakHostPlatform.linux,
        environment: HostEnvironment(const {'HOME': '/home/user'}),
        fileStatusProbe: const StaticFileStatusProbe({
          '/home/user/.local/share/konyak/Runtimes/linux-wine/bin/wine',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/bin/winedbg',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/bin/wineserver',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/winetricks',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/share/wine/mono',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/dxvk/x64/dxgi.dll',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/dxvk/x64/d3d11.dll',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/dxvk/x86/dxgi.dll',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/dxvk/x86/d3d11.dll',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/vkd3d-proton/x64/d3d12.dll',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/vkd3d-proton/x64/d3d12core.dll',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/vkd3d-proton/x86/d3d12.dll',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/vkd3d-proton/x86/d3d12core.dll',
        }),
        runtimeStackVersionProbe: const EmptyRuntimeStackVersionProbe(),
      ),
    );

    expect(result.exitCode, 0);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    final runtime =
        (payload['runtimes'] as List<Object?>).single as Map<String, Object?>;
    final stack = runtime['stack'] as Map<String, Object?>;
    final components = stack['components'] as List<Object?>;
    final dxvk = components.cast<Map<String, Object?>>().singleWhere(
      (component) => component['id'] == 'dxvk',
    );

    expect(stack['isComplete'], isFalse);
    expect(dxvk['isInstalled'], isFalse);
    expect(
      dxvk['missingPaths'],
      containsAll(<String>[
        '/home/user/.local/share/konyak/Runtimes/linux-wine/dxvk/x64/d3d9.dll',
        '/home/user/.local/share/konyak/Runtimes/linux-wine/dxvk/x64/d3d10core.dll',
        '/home/user/.local/share/konyak/Runtimes/linux-wine/dxvk/x86/d3d9.dll',
        '/home/user/.local/share/konyak/Runtimes/linux-wine/dxvk/x86/d3d10core.dll',
      ]),
    );
  });

  test('list-runtimes --json reports the Linux development runtime profile', () {
    final result = runCli(
      const ['list-runtimes', '--json'],
      runtimeCatalog: KonyakRuntimeCatalog(
        hostPlatform: KonyakHostPlatform.linux,
        environment: HostEnvironment(const {
          'HOME': '/home/user',
          'KONYAK_RUNTIME_PROFILE': 'development',
          'KONYAK_DEV_LINUX_WINE_STACK_SOURCE_MANIFEST':
              'file:///workspace/fixtures/linux-runtime-stack-source.json',
        }),
        fileStatusProbe: const StaticFileStatusProbe({
          '/home/user/.local/share/konyak/Runtimes/linux-wine/bin/wine',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/bin/winedbg',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/bin/wineserver',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/winetricks',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/share/wine/mono',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/dxvk/x64/dxgi.dll',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/dxvk/x64/d3d11.dll',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/dxvk/x86/dxgi.dll',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/dxvk/x86/d3d11.dll',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/vkd3d-proton/x64/d3d12.dll',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/vkd3d-proton/x64/d3d12core.dll',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/vkd3d-proton/x86/d3d12.dll',
          '/home/user/.local/share/konyak/Runtimes/linux-wine/vkd3d-proton/x86/d3d12core.dll',
        }),
        runtimeStackVersionProbe: const EmptyRuntimeStackVersionProbe(),
      ),
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    final runtimes = (payload['runtimes'] as List<Object?>)
        .cast<Map<String, Object?>>();
    final runtime = runtimes.single;
    expect(runtime['id'], 'konyak-linux-wine');
    expect(runtime['distributionKind'], 'development');
    expect(runtime['isInstalled'], isTrue);
    expect(runtime['isUpdateable'], isFalse);
    expect(runtime, isNot(contains('archiveUrl')));
    expect(runtime, isNot(contains('versionUrl')));
    expect(runtime, isNot(contains('sourceManifestUrl')));
  });
  test(
    'check-runtime-update --json returns machine-readable update status',
    () {
      final checker = RecordingRuntimeUpdateChecker(
        result: RuntimeUpdateCheckCompleted(
          RuntimeUpdateRecord(
            runtimeId: 'konyak-macos-wine',
            status: 'available',
            currentVersion: Option.of('wine-devel-11.9'),
            latestVersion: Option.of('12.0'),
            versionUrl: Option.of(macosWineRuntimeReleaseUrl),
            sourceManifestUrl: Option.of(macosWineRuntimeSourceManifestUrl),
          ),
        ),
      );

      final result = runCli(const [
        'check-runtime-update',
        'konyak-macos-wine',
        '--json',
      ], runtimeUpdateChecker: checker);

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);
      expect(checker.lastRuntimeId, 'konyak-macos-wine');

      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      expect(payload, {
        'schemaVersion': 1,
        'runtimeUpdate': {
          'runtimeId': 'konyak-macos-wine',
          'status': 'available',
          'currentVersion': 'wine-devel-11.9',
          'latestVersion': '12.0',
          'versionUrl': macosWineRuntimeReleaseUrl,
          'sourceManifestUrl': macosWineRuntimeSourceManifestUrl,
        },
      });
    },
  );

  test('check-app-update --json returns machine-readable update status', () {
    final checker = RecordingAppUpdateChecker(
      result: AppUpdateCheckCompleted(
        AppUpdateRecord(
          appId: 'konyak',
          status: 'available',
          currentVersion: Option.of('1.0.0'),
          latestVersion: Option.of('1.1.0'),
          versionUrl: Option.of(
            'https://api.github.com/repos/serika12345/Konyak/releases/latest',
          ),
          archiveUrl: Option.of('https://example.invalid/Konyak.dmg'),
        ),
      ),
    );

    final result = runCli(const [
      'check-app-update',
      '--json',
    ], appUpdateChecker: checker);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(checker.checkCount, 1);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'appUpdate': {
        'appId': 'konyak',
        'status': 'available',
        'currentVersion': '1.0.0',
        'latestVersion': '1.1.0',
        'versionUrl':
            'https://api.github.com/repos/serika12345/Konyak/releases/latest',
        'archiveUrl': 'https://example.invalid/Konyak.dmg',
      },
    });
  });

  test('terminate-wine-processes --json terminates each bottle prefix', () {
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: '/data',
      bottles: [
        BottleRecord(
          id: 'alpha',
          name: 'Alpha',
          path: '/bottles/alpha',
          windowsVersion: 'win10',
        ),
        BottleRecord(
          id: 'beta',
          name: 'Beta',
          path: '/bottles/beta',
          windowsVersion: 'win11',
        ),
      ],
    );
    final runner = RecordingProgramRunner(
      result: const ProgramRunCompleted(processExitCode: 0),
    );

    final result = runCli(
      const ['terminate-wine-processes', '--json'],
      bottleCatalog: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.linux,
      ),
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(runner.requests, hasLength(2));
    expect(
      runner.requests[0].executable.value,
      'Konyak/Runtimes/linux-wine/bin/wineserver',
    );
    expect(runner.requests[0].arguments, const ['-k']);
    expect(runner.requests[0].environment.toMap(), {
      'PATH': 'Konyak/Runtimes/linux-wine/bin',
      'WINEPREFIX': '/bottles/alpha',
    });
    expect(runner.requests[1].environment.toMap(), {
      'PATH': 'Konyak/Runtimes/linux-wine/bin',
      'WINEPREFIX': '/bottles/beta',
    });

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'wineProcessTermination': {
        'hasFailures': false,
        'bottles': [
          {
            'bottleId': 'alpha',
            'status': 'terminated',
            'runnerKind': 'wineserver',
            'executable': 'Konyak/Runtimes/linux-wine/bin/wineserver',
            'argv': ['Konyak/Runtimes/linux-wine/bin/wineserver', '-k'],
            'processExitCode': 0,
          },
          {
            'bottleId': 'beta',
            'status': 'terminated',
            'runnerKind': 'wineserver',
            'executable': 'Konyak/Runtimes/linux-wine/bin/wineserver',
            'argv': ['Konyak/Runtimes/linux-wine/bin/wineserver', '-k'],
            'processExitCode': 0,
          },
        ],
      },
    });
  });

  test(
    'terminate-wine-processes --bottle --json terminates one bottle prefix',
    () {
      final repository = MemoryBottleRepository(
        programMetadataExtractor: const NoopProgramMetadataExtractor(),
        dataHome: '/data',
        bottles: [
          BottleRecord(
            id: 'alpha',
            name: 'Alpha',
            path: '/bottles/alpha',
            windowsVersion: 'win10',
          ),
          BottleRecord(
            id: 'beta',
            name: 'Beta',
            path: '/bottles/beta',
            windowsVersion: 'win11',
          ),
        ],
      );
      final runner = RecordingProgramRunner(
        result: const ProgramRunCompleted(processExitCode: 0),
      );

      final result = runCli(
        const ['terminate-wine-processes', '--bottle', 'beta', '--json'],
        bottleCatalog: repository,
        programRunPlanner: ProgramRunPlanner(
          hostPlatform: KonyakHostPlatform.linux,
        ),
        programRunner: runner,
      );

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);
      expect(runner.requests, hasLength(1));
      expect(
        runner.requests.single.executable.value,
        'Konyak/Runtimes/linux-wine/bin/wineserver',
      );
      expect(runner.requests.single.arguments, const ['-k']);
      expect(runner.requests.single.environment.toMap(), {
        'PATH': 'Konyak/Runtimes/linux-wine/bin',
        'WINEPREFIX': '/bottles/beta',
      });

      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      expect(payload, {
        'schemaVersion': 1,
        'wineProcessTermination': {
          'hasFailures': false,
          'bottles': [
            {
              'bottleId': 'beta',
              'status': 'terminated',
              'runnerKind': 'wineserver',
              'executable': 'Konyak/Runtimes/linux-wine/bin/wineserver',
              'argv': ['Konyak/Runtimes/linux-wine/bin/wineserver', '-k'],
              'processExitCode': 0,
            },
          ],
        },
      });
    },
  );

  test(
    'terminate-wine-processes --bottle --json treats no running processes as success',
    () {
      final repository = MemoryBottleRepository(
        programMetadataExtractor: const NoopProgramMetadataExtractor(),
        dataHome: '/data',
        bottles: [
          BottleRecord(
            id: 'steam',
            name: 'Steam',
            path: '/bottles/steam',
            windowsVersion: 'win10',
          ),
        ],
      );
      final runner = RecordingProgramRunner(
        result: const ProgramRunCompleted(processExitCode: 1),
      );

      final result = runCli(
        const ['terminate-wine-processes', '--bottle', 'steam', '--json'],
        bottleCatalog: repository,
        programRunPlanner: ProgramRunPlanner(
          hostPlatform: KonyakHostPlatform.linux,
        ),
        programRunner: runner,
      );

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);

      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      expect(payload, {
        'schemaVersion': 1,
        'wineProcessTermination': {
          'hasFailures': false,
          'bottles': [
            {
              'bottleId': 'steam',
              'status': 'terminated',
              'runnerKind': 'wineserver',
              'executable': 'Konyak/Runtimes/linux-wine/bin/wineserver',
              'argv': ['Konyak/Runtimes/linux-wine/bin/wineserver', '-k'],
              'processExitCode': 1,
            },
          ],
        },
      });
    },
  );

  test('list-wine-processes --json lists process records with icons', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-process-list-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final bottlePath = _joinTestPath(tempDirectory.path, const ['a']);
    final programPath = _joinTestPath(tempDirectory.path, const [
      'Downloads',
      'Ardour-9.5.0-w64-Setup.exe',
    ]);
    Directory(
      _joinTestPath(bottlePath, const ['logs']),
    ).createSync(recursive: true);
    File(_joinTestPath(bottlePath, const ['logs', 'latest.log']))
      ..createSync(recursive: true)
      ..writeAsStringSync('Arguments: ${jsonEncode(<String>[programPath])}\n');
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: '/data',
      bottles: [
        BottleRecord(
          id: 'a',
          name: 'a',
          path: bottlePath,
          windowsVersion: 'win11',
        ),
      ],
    );
    final runner = RecordingProgramRunner(
      result: const ProgramRunCompleted(
        processExitCode: 0,
        stdout: '''
          pid      threads  executable (all id:s are in hex)
          00000020 2        'C:\\windows\\system32\\services.exe'
          00000028 1        /_ 'winedbg.exe'
          00000034 1        /_ 'C:\\windows\\system32\\explorer.exe'
          00000038 1        rpcss.exe
          00000120 1        start.exe
          000000d8 5        Ardour-9.5.0-w64-Setup.exe
        ''',
      ),
    );

    final result = runCli(
      const ['list-wine-processes', '--json'],
      bottleCatalog: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.linux,
      ),
      programRunner: runner,
      programMetadataExtractor: FixedProgramMetadataExtractor(
        programPath: programPath,
        metadata: ProgramMetadataRecord(
          fileDescription: Option.of('Ardour Installer'),
          iconPath: Option.of(
            _joinTestPath(bottlePath, const ['cache', 'icons', 'ardour.ico']),
          ),
        ),
      ),
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(runner.requests, hasLength(1));
    expect(
      runner.requests.single.executable.value,
      'Konyak/Runtimes/linux-wine/bin/winedbg',
    );
    expect(runner.requests.single.arguments, const ['--command', 'info proc']);
    expect(runner.requests.single.environment.toMap(), {
      'PATH': 'Konyak/Runtimes/linux-wine/bin',
      'WINEPREFIX': bottlePath,
    });

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'wineProcesses': {
        'processes': [
          {
            'bottleId': 'a',
            'processId': '000000d8',
            'executable': 'Ardour-9.5.0-w64-Setup.exe',
            'hostPath': programPath,
            'metadata': {
              'fileDescription': 'Ardour Installer',
              'iconPath': _joinTestPath(bottlePath, const [
                'cache',
                'icons',
                'ardour.ico',
              ]),
            },
          },
        ],
      },
    });
  });

  test(
    'runCliStreaming list-wine-processes starts bottle probes concurrently and preserves order',
    () async {
      final repository = MemoryBottleRepository(
        programMetadataExtractor: const NoopProgramMetadataExtractor(),
        dataHome: '/data',
        bottles: [
          BottleRecord(
            id: 'a',
            name: 'A',
            path: '/bottles/a',
            windowsVersion: 'win11',
          ),
          BottleRecord(
            id: 'b',
            name: 'B',
            path: '/bottles/b',
            windowsVersion: 'win11',
          ),
          BottleRecord(
            id: 'c',
            name: 'C',
            path: '/bottles/c',
            windowsVersion: 'win11',
          ),
        ],
      );
      final runner = ControlledAsyncProgramRunner();

      final resultFuture = runCliStreaming(
        const ['list-wine-processes', '--json'],
        bottleCatalog: repository,
        programRunPlanner: ProgramRunPlanner(
          hostPlatform: KonyakHostPlatform.linux,
        ),
        asyncProgramRunner: runner,
        hostProcessSnapshotReader: const FixedHostProcessSnapshotReader('''
          wine64 WINEPREFIX=/bottles/a
          wine64 WINEPREFIX=/bottles/b
          wine64 WINEPREFIX=/bottles/c
        '''),
      );

      await runner.waitForRequestCount(3);
      expect(runner.requests.map((request) => request.bottleId.value), [
        'a',
        'b',
        'c',
      ]);

      runner.complete(
        'c',
        const ProgramRunCompleted(
          processExitCode: 0,
          stdout: '000000c0 1 CApp.exe',
        ),
      );
      runner.complete(
        'a',
        const ProgramRunCompleted(
          processExitCode: 0,
          stdout: '000000a0 1 AApp.exe',
        ),
      );
      runner.complete(
        'b',
        const ProgramRunCompleted(
          processExitCode: 0,
          stdout: '000000b0 1 BApp.exe',
        ),
      );

      final result = await resultFuture;

      expect(result.exitCode, 0);
      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      expect(payload, {
        'schemaVersion': 1,
        'wineProcesses': {
          'processes': [
            {
              'bottleId': 'a',
              'processId': '000000a0',
              'executable': 'AApp.exe',
            },
            {
              'bottleId': 'b',
              'processId': '000000b0',
              'executable': 'BApp.exe',
            },
            {
              'bottleId': 'c',
              'processId': '000000c0',
              'executable': 'CApp.exe',
            },
          ],
        },
      });
    },
  );

  test(
    'runCliStreaming list-wine-processes reuses metadata extraction for duplicate host paths',
    () async {
      final tempDirectory = Directory.systemTemp.createTempSync(
        'konyak-process-list-metadata-cache-test-',
      );
      addTearDown(() {
        if (tempDirectory.existsSync()) {
          tempDirectory.deleteSync(recursive: true);
        }
      });
      final bottlePath = _joinTestPath(tempDirectory.path, const ['a']);
      final programPath = _joinTestPath(tempDirectory.path, const [
        'Downloads',
        'Setup.exe',
      ]);
      Directory(
        _joinTestPath(bottlePath, const ['logs']),
      ).createSync(recursive: true);
      File(_joinTestPath(bottlePath, const ['logs', 'latest.log']))
        ..createSync(recursive: true)
        ..writeAsStringSync(
          'Arguments: ${jsonEncode(<String>[programPath])}\n',
        );
      final repository = MemoryBottleRepository(
        programMetadataExtractor: const NoopProgramMetadataExtractor(),
        dataHome: '/data',
        bottles: [
          BottleRecord(
            id: 'a',
            name: 'A',
            path: bottlePath,
            windowsVersion: 'win11',
          ),
        ],
      );
      final runner = ControlledAsyncProgramRunner();
      final metadataExtractor = CountingAsyncProgramMetadataExtractor(
        programPath: programPath,
        metadata: ProgramMetadataRecord(
          fileDescription: Option.of('Setup'),
          iconPath: Option.of(
            _joinTestPath(bottlePath, const ['cache', 'icons', 'setup.ico']),
          ),
        ),
      );

      final resultFuture = runCliStreaming(
        const ['list-wine-processes', '--json'],
        bottleCatalog: repository,
        programRunPlanner: ProgramRunPlanner(
          hostPlatform: KonyakHostPlatform.linux,
        ),
        asyncProgramRunner: runner,
        asyncProgramMetadataExtractor: metadataExtractor,
        hostProcessSnapshotReader: FixedHostProcessSnapshotReader(
          'wine64 WINEPREFIX=$bottlePath',
        ),
      );

      await runner.waitForRequestCount(1);
      runner.complete(
        'a',
        const ProgramRunCompleted(
          processExitCode: 0,
          stdout: '''
          000000d8 5 Setup.exe
          000000e0 3 Setup.exe
        ''',
        ),
      );

      final result = await resultFuture;

      expect(result.exitCode, 0);
      expect(metadataExtractor.requestedProgramPaths, [programPath]);
      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      final wineProcesses = payload['wineProcesses'] as Map<String, Object?>;
      final processes = wineProcesses['processes'] as List<Object?>;
      expect(processes, hasLength(2));
      for (final process in processes.cast<Map<String, Object?>>()) {
        expect(process['metadata'], {
          'fileDescription': 'Setup',
          'iconPath': _joinTestPath(bottlePath, const [
            'cache',
            'icons',
            'setup.ico',
          ]),
        });
      }
    },
  );

  test(
    'runCliStreaming list-wine-processes resolves shortcut targets for process icons',
    () async {
      final tempDirectory = Directory.systemTemp.createTempSync(
        'konyak-process-list-shortcut-icon-test-',
      );
      addTearDown(() {
        if (tempDirectory.existsSync()) {
          tempDirectory.deleteSync(recursive: true);
        }
      });
      final bottlePath = _joinTestPath(tempDirectory.path, const ['a']);
      final programPath = _joinTestPath(bottlePath, const [
        'drive_c',
        'Program Files',
        'Ardour',
        'Ardour.exe',
      ]);
      final shortcutPath = _joinTestPath(bottlePath, const [
        'drive_c',
        'ProgramData',
        'Microsoft',
        'Windows',
        'Start Menu',
        'Programs',
        'Ardour.lnk',
      ]);
      File(shortcutPath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(
          _syntheticShellLinkBytes(
            localBasePath: r'C:\Program Files\Ardour\Ardour.exe',
          ),
        );
      Directory(
        _joinTestPath(bottlePath, const ['logs']),
      ).createSync(recursive: true);
      File(_joinTestPath(bottlePath, const ['logs', 'latest.log']))
        ..createSync(recursive: true)
        ..writeAsStringSync(
          'Arguments: ${jsonEncode(<String>['start', '/unix', shortcutPath])}\n',
        );
      final repository = MemoryBottleRepository(
        programMetadataExtractor: const NoopProgramMetadataExtractor(),
        dataHome: '/data',
        bottles: [
          BottleRecord(
            id: 'a',
            name: 'A',
            path: bottlePath,
            windowsVersion: 'win11',
          ),
        ],
      );
      final runner = ControlledAsyncProgramRunner();
      final metadataExtractor = CountingAsyncProgramMetadataExtractor(
        programPath: programPath,
        metadata: ProgramMetadataRecord(
          fileDescription: Option.of('Ardour'),
          iconPath: Option.of(
            _joinTestPath(bottlePath, const ['cache', 'icons', 'ardour.ico']),
          ),
        ),
      );

      final resultFuture = runCliStreaming(
        const ['list-wine-processes', '--json'],
        bottleCatalog: repository,
        programRunPlanner: ProgramRunPlanner(
          hostPlatform: KonyakHostPlatform.linux,
        ),
        asyncProgramRunner: runner,
        asyncProgramMetadataExtractor: metadataExtractor,
        hostProcessSnapshotReader: FixedHostProcessSnapshotReader(
          'wine64 WINEPREFIX=$bottlePath',
        ),
      );

      await runner.waitForRequestCount(1);
      runner.complete(
        'a',
        const ProgramRunCompleted(
          processExitCode: 0,
          stdout: '''
          00000128 5 Ardour.exe
        ''',
        ),
      );

      final result = await resultFuture;

      expect(result.exitCode, 0);
      expect(metadataExtractor.requestedProgramPaths, [programPath]);
      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      expect(payload, {
        'schemaVersion': 1,
        'wineProcesses': {
          'processes': [
            {
              'bottleId': 'a',
              'processId': '00000128',
              'executable': 'Ardour.exe',
              'hostPath': programPath,
              'metadata': {
                'fileDescription': 'Ardour',
                'iconPath': _joinTestPath(bottlePath, const [
                  'cache',
                  'icons',
                  'ardour.ico',
                ]),
              },
            },
          ],
        },
      });
    },
  );

  test(
    'runCliStreaming list-wine-processes skips bottles missing from the host process snapshot',
    () async {
      final repository = MemoryBottleRepository(
        programMetadataExtractor: const NoopProgramMetadataExtractor(),
        dataHome: '/data',
        bottles: [
          BottleRecord(
            id: 'a',
            name: 'A',
            path: '/bottles/a',
            windowsVersion: 'win11',
          ),
          BottleRecord(
            id: 'b',
            name: 'B',
            path: '/bottles/b',
            windowsVersion: 'win11',
          ),
          BottleRecord(
            id: 'c',
            name: 'C',
            path: '/bottles/c',
            windowsVersion: 'win11',
          ),
        ],
      );
      final runner = ControlledAsyncProgramRunner();

      final resultFuture = runCliStreaming(
        const ['list-wine-processes', '--json'],
        bottleCatalog: repository,
        programRunPlanner: ProgramRunPlanner(
          hostPlatform: KonyakHostPlatform.linux,
        ),
        asyncProgramRunner: runner,
        hostProcessSnapshotReader: const FixedHostProcessSnapshotReader(
          'wine64 WINEPREFIX=/bottles/b',
        ),
      );

      await runner.waitForRequestCount(1);
      expect(runner.requests.single.bottleId.value, 'b');
      runner.complete(
        'b',
        const ProgramRunCompleted(
          processExitCode: 0,
          stdout: '000000b0 1 BApp.exe',
        ),
      );

      final result = await resultFuture;

      expect(result.exitCode, 0);
      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      expect(payload, {
        'schemaVersion': 1,
        'wineProcesses': {
          'processes': [
            {
              'bottleId': 'b',
              'processId': '000000b0',
              'executable': 'BApp.exe',
            },
          ],
        },
      });
    },
  );

  test(
    'runCliStreaming list-wine-processes returns empty without probing when no bottle is active',
    () async {
      final repository = MemoryBottleRepository(
        programMetadataExtractor: const NoopProgramMetadataExtractor(),
        dataHome: '/data',
        bottles: [
          BottleRecord(
            id: 'a',
            name: 'A',
            path: '/bottles/a',
            windowsVersion: 'win11',
          ),
        ],
      );
      final runner = ControlledAsyncProgramRunner();

      final result = await runCliStreaming(
        const ['list-wine-processes', '--json'],
        bottleCatalog: repository,
        programRunPlanner: ProgramRunPlanner(
          hostPlatform: KonyakHostPlatform.linux,
        ),
        asyncProgramRunner: runner,
        hostProcessSnapshotReader: const FixedHostProcessSnapshotReader(
          'Finder\nKonyak',
        ),
      );

      expect(result.exitCode, 0);
      expect(runner.requests, isEmpty);
      expect(jsonDecode(result.stdout), {
        'schemaVersion': 1,
        'wineProcesses': {'processes': <Object?>[]},
      });
    },
  );

  test(
    'runCliStreaming list-wine-processes does not match bottle path prefixes',
    () async {
      final repository = MemoryBottleRepository(
        programMetadataExtractor: const NoopProgramMetadataExtractor(),
        dataHome: '/data',
        bottles: [
          BottleRecord(
            id: 'a',
            name: 'A',
            path: '/bottles/a',
            windowsVersion: 'win11',
          ),
        ],
      );
      final runner = ControlledAsyncProgramRunner();

      final result = await runCliStreaming(
        const ['list-wine-processes', '--json'],
        bottleCatalog: repository,
        programRunPlanner: ProgramRunPlanner(
          hostPlatform: KonyakHostPlatform.linux,
        ),
        asyncProgramRunner: runner,
        hostProcessSnapshotReader: const FixedHostProcessSnapshotReader(
          'wine64 WINEPREFIX=/bottles/a2',
        ),
      );

      expect(result.exitCode, 0);
      expect(runner.requests, isEmpty);
      expect(jsonDecode(result.stdout), {
        'schemaVersion': 1,
        'wineProcesses': {'processes': <Object?>[]},
      });
    },
  );

  test(
    'list-wine-processes --json strips winedbg tree prefixes before resolving metadata',
    () {
      final tempDirectory = Directory.systemTemp.createTempSync(
        'konyak-process-list-tree-prefix-test-',
      );
      addTearDown(() {
        if (tempDirectory.existsSync()) {
          tempDirectory.deleteSync(recursive: true);
        }
      });
      final bottlePath = _joinTestPath(tempDirectory.path, const ['a']);
      final programPath = _joinTestPath(tempDirectory.path, const [
        'Downloads',
        'Ardour-9.5.0-w64-Setup.exe',
      ]);
      Directory(
        _joinTestPath(bottlePath, const ['cache']),
      ).createSync(recursive: true);
      File(
        _joinTestPath(bottlePath, const [
          'cache',
          'external-program-launches.json',
        ]),
      ).writeAsStringSync(
        jsonEncode({
          'schemaVersion': 1,
          'launches': [
            {
              'programPath': programPath,
              'executableName': 'ardour-9.5.0-w64-setup.exe',
            },
          ],
        }),
      );
      final repository = MemoryBottleRepository(
        programMetadataExtractor: const NoopProgramMetadataExtractor(),
        dataHome: '/data',
        bottles: [
          BottleRecord(
            id: 'a',
            name: 'a',
            path: bottlePath,
            windowsVersion: 'win11',
          ),
        ],
      );
      final runner = RecordingProgramRunner(
        result: const ProgramRunCompleted(
          processExitCode: 0,
          stdout: '''
          pid      threads  executable (all id:s are in hex)
          00000020 2        'C:\\windows\\system32\\services.exe'
          000000d8 5        \\_ 'Ardour-9.5.0-w64-Setup.exe'
        ''',
        ),
      );

      final result = runCli(
        const ['list-wine-processes', '--json'],
        bottleCatalog: repository,
        programRunPlanner: ProgramRunPlanner(
          hostPlatform: KonyakHostPlatform.linux,
        ),
        programRunner: runner,
        programMetadataExtractor: FixedProgramMetadataExtractor(
          programPath: programPath,
          metadata: ProgramMetadataRecord(
            fileDescription: Option.of('Ardour Installer'),
            iconPath: Option.of(
              _joinTestPath(bottlePath, const ['cache', 'icons', 'ardour.ico']),
            ),
          ),
        ),
      );

      expect(result.exitCode, 0);
      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      expect(payload, {
        'schemaVersion': 1,
        'wineProcesses': {
          'processes': [
            {
              'bottleId': 'a',
              'processId': '000000d8',
              'executable': 'Ardour-9.5.0-w64-Setup.exe',
              'hostPath': programPath,
              'metadata': {
                'fileDescription': 'Ardour Installer',
                'iconPath': _joinTestPath(bottlePath, const [
                  'cache',
                  'icons',
                  'ardour.ico',
                ]),
              },
            },
          ],
        },
      });
    },
  );

  test(
    'list-wine-processes --json uses recorded external launches when latest.log is unavailable',
    () {
      final tempDirectory = Directory.systemTemp.createTempSync(
        'konyak-process-list-recorded-launch-test-',
      );
      addTearDown(() {
        if (tempDirectory.existsSync()) {
          tempDirectory.deleteSync(recursive: true);
        }
      });
      final bottlePath = _joinTestPath(tempDirectory.path, const ['a']);
      final programPath = _joinTestPath(tempDirectory.path, const [
        'Downloads',
        'Ardour-9.5.0-w64-Setup.exe',
      ]);
      final repository = MemoryBottleRepository(
        programMetadataExtractor: const NoopProgramMetadataExtractor(),
        dataHome: '/data',
        bottles: [
          BottleRecord(
            id: 'a',
            name: 'a',
            path: bottlePath,
            windowsVersion: 'win11',
          ),
        ],
      );
      Directory(
        _joinTestPath(bottlePath, const ['cache']),
      ).createSync(recursive: true);
      File(
        _joinTestPath(bottlePath, const [
          'cache',
          'external-program-launches.json',
        ]),
      ).writeAsStringSync(
        jsonEncode({
          'schemaVersion': 1,
          'launches': [
            {
              'programPath': programPath,
              'executableName': 'ardour-9.5.0-w64-setup.exe',
            },
          ],
        }),
      );

      final runner = RecordingProgramRunner(
        result: const ProgramRunCompleted(
          processExitCode: 0,
          stdout: '''
          pid      threads  executable (all id:s are in hex)
          00000020 2        'C:\\windows\\system32\\services.exe'
          000000d8 5        Ardour-9.5.0-w64-Setup.exe
        ''',
        ),
      );

      final result = runCli(
        const ['list-wine-processes', '--json'],
        bottleCatalog: repository,
        programRunPlanner: ProgramRunPlanner(
          hostPlatform: KonyakHostPlatform.linux,
        ),
        programRunner: runner,
        programMetadataExtractor: FixedProgramMetadataExtractor(
          programPath: programPath,
          metadata: ProgramMetadataRecord(
            fileDescription: Option.of('Ardour Installer'),
            iconPath: Option.of(
              _joinTestPath(bottlePath, const ['cache', 'icons', 'ardour.ico']),
            ),
          ),
        ),
      );

      expect(result.exitCode, 0);
      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      expect(payload, {
        'schemaVersion': 1,
        'wineProcesses': {
          'processes': [
            {
              'bottleId': 'a',
              'processId': '000000d8',
              'executable': 'Ardour-9.5.0-w64-Setup.exe',
              'hostPath': programPath,
              'metadata': {
                'fileDescription': 'Ardour Installer',
                'iconPath': _joinTestPath(bottlePath, const [
                  'cache',
                  'icons',
                  'ardour.ico',
                ]),
              },
            },
          ],
        },
      });
    },
  );

  test(
    'list-wine-processes --json resolves recorded shortcut launches to target metadata',
    () {
      final tempDirectory = Directory.systemTemp.createTempSync(
        'konyak-process-list-recorded-shortcut-launch-test-',
      );
      addTearDown(() {
        if (tempDirectory.existsSync()) {
          tempDirectory.deleteSync(recursive: true);
        }
      });
      final bottlePath = _joinTestPath(tempDirectory.path, const ['a']);
      final programPath = _joinTestPath(bottlePath, const [
        'drive_c',
        'Program Files',
        'Ardour',
        'Ardour.exe',
      ]);
      final shortcutPath = _joinTestPath(bottlePath, const [
        'drive_c',
        'ProgramData',
        'Microsoft',
        'Windows',
        'Start Menu',
        'Programs',
        'Ardour.lnk',
      ]);
      File(shortcutPath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(
          _syntheticShellLinkBytes(
            localBasePath: r'C:\Program Files\Ardour\Ardour.exe',
          ),
        );
      final repository = MemoryBottleRepository(
        programMetadataExtractor: const NoopProgramMetadataExtractor(),
        dataHome: '/data',
        bottles: [
          BottleRecord(
            id: 'a',
            name: 'a',
            path: bottlePath,
            windowsVersion: 'win11',
          ),
        ],
      );
      Directory(
        _joinTestPath(bottlePath, const ['cache']),
      ).createSync(recursive: true);
      File(
        _joinTestPath(bottlePath, const [
          'cache',
          'external-program-launches.json',
        ]),
      ).writeAsStringSync(
        jsonEncode({
          'schemaVersion': 1,
          'launches': [
            {'programPath': shortcutPath, 'executableName': 'ardour.lnk'},
          ],
        }),
      );

      final runner = RecordingProgramRunner(
        result: const ProgramRunCompleted(
          processExitCode: 0,
          stdout: '''
          pid      threads  executable (all id:s are in hex)
          00000128 5        Ardour.exe
        ''',
        ),
      );

      final result = runCli(
        const ['list-wine-processes', '--json'],
        bottleCatalog: repository,
        programRunPlanner: ProgramRunPlanner(
          hostPlatform: KonyakHostPlatform.linux,
        ),
        programRunner: runner,
        programMetadataExtractor: FixedProgramMetadataExtractor(
          programPath: programPath,
          metadata: ProgramMetadataRecord(
            fileDescription: Option.of('Ardour'),
            iconPath: Option.of(
              _joinTestPath(bottlePath, const ['cache', 'icons', 'ardour.ico']),
            ),
          ),
        ),
      );

      expect(result.exitCode, 0);
      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      expect(payload, {
        'schemaVersion': 1,
        'wineProcesses': {
          'processes': [
            {
              'bottleId': 'a',
              'processId': '00000128',
              'executable': 'Ardour.exe',
              'hostPath': programPath,
              'metadata': {
                'fileDescription': 'Ardour',
                'iconPath': _joinTestPath(bottlePath, const [
                  'cache',
                  'icons',
                  'ardour.ico',
                ]),
              },
            },
          ],
        },
      });
    },
  );

  test(
    'run-program --json on macOS records external launches for process icons',
    () {
      final tempDirectory = Directory.systemTemp.createTempSync(
        'konyak-process-list-macos-run-record-test-',
      );
      addTearDown(() {
        if (tempDirectory.existsSync()) {
          tempDirectory.deleteSync(recursive: true);
        }
      });
      final bottlePath = _joinTestPath(tempDirectory.path, const ['a']);
      final programPath = _joinTestPath(tempDirectory.path, const [
        'Downloads',
        'Ardour-9.5.0-w64-Setup.exe',
      ]);
      final repository = MemoryBottleRepository(
        programMetadataExtractor: const NoopProgramMetadataExtractor(),
        dataHome: '/data',
        bottles: [
          BottleRecord(
            id: 'a',
            name: 'a',
            path: bottlePath,
            windowsVersion: 'win11',
          ),
        ],
      );
      final runner = RecordingProgramRunner(
        results: const [
          ProgramRunCompleted(processExitCode: 0),
          ProgramRunCompleted(
            processExitCode: 0,
            stdout: '''
          pid      threads  executable (all id:s are in hex)
          000000d8 5        Ardour-9.5.0-w64-Setup.exe
        ''',
          ),
        ],
      );
      final planner = ProgramRunPlanner(hostPlatform: KonyakHostPlatform.macos);

      final runResult = runCli(
        ['run-program', 'a', '--program', programPath, '--json'],
        bottleRepository: repository,
        programRunPlanner: planner,
        programRunner: runner,
      );

      expect(runResult.exitCode, 0);

      final result = runCli(
        const ['list-wine-processes', '--json'],
        bottleRepository: repository,
        programRunPlanner: planner,
        programRunner: runner,
        programMetadataExtractor: FixedProgramMetadataExtractor(
          programPath: programPath,
          metadata: ProgramMetadataRecord(
            fileDescription: Option.of('Ardour Installer'),
            iconPath: Option.of(
              _joinTestPath(bottlePath, const ['cache', 'icons', 'ardour.ico']),
            ),
          ),
        ),
      );

      expect(result.exitCode, 0);
      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      expect(payload, {
        'schemaVersion': 1,
        'wineProcesses': {
          'processes': [
            {
              'bottleId': 'a',
              'processId': '000000d8',
              'executable': 'Ardour-9.5.0-w64-Setup.exe',
              'hostPath': programPath,
              'metadata': {
                'fileDescription': 'Ardour Installer',
                'iconPath': _joinTestPath(bottlePath, const [
                  'cache',
                  'icons',
                  'ardour.ico',
                ]),
              },
            },
          ],
        },
      });
    },
  );

  test('terminate-wine-process --json kills one Wine process', () {
    final repository = MemoryBottleRepository(
      programMetadataExtractor: const NoopProgramMetadataExtractor(),
      dataHome: '/data',
      bottles: [
        BottleRecord(
          id: 'steam',
          name: 'Steam',
          path: '/bottles/steam',
          windowsVersion: 'win10',
        ),
      ],
    );
    final runner = RecordingProgramRunner(
      result: const ProgramRunCompleted(processExitCode: 0),
    );

    final result = runCli(
      const [
        'terminate-wine-process',
        '--bottle',
        'steam',
        '--process',
        '000000d8',
        '--json',
      ],
      bottleCatalog: repository,
      programRunPlanner: ProgramRunPlanner(
        hostPlatform: KonyakHostPlatform.linux,
      ),
      programRunner: runner,
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(runner.requests, hasLength(1));
    expect(
      runner.requests.single.executable.value,
      'Konyak/Runtimes/linux-wine/bin/winedbg',
    );
    expect(runner.requests.single.arguments, const [
      '--command',
      'kill',
      '0x000000d8',
    ]);
    expect(runner.requests.single.environment.toMap(), {
      'PATH': 'Konyak/Runtimes/linux-wine/bin',
      'WINEPREFIX': '/bottles/steam',
    });

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'wineProcessTermination': {
        'hasFailures': false,
        'processes': [
          {
            'bottleId': 'steam',
            'processId': '000000d8',
            'status': 'terminated',
            'runnerKind': 'winedbg',
            'executable': 'Konyak/Runtimes/linux-wine/bin/winedbg',
            'argv': [
              'Konyak/Runtimes/linux-wine/bin/winedbg',
              '--command',
              'kill',
              '0x000000d8',
            ],
            'processExitCode': 0,
          },
        ],
      },
    });
  });

  test('app update checker compares Konyak version to release tag', () {
    final checker = DartIoAppUpdateChecker(
      appId: 'konyak',
      currentVersion: '1.0.0',
      versionUrl: 'https://example.invalid/releases/latest',
      releaseMetadataFetcher: StaticRuntimeReleaseMetadataFetcher(
        RuntimeReleaseMetadata(version: 'v1.0.0'),
      ),
    );

    final result = checker.check();

    expect(result, isA<AppUpdateCheckCompleted>());
    final completed = result as AppUpdateCheckCompleted;
    expect(completed.update.status.value, 'current');
    expect(completed.update.currentVersion.toNullable()?.value, '1.0.0');
    expect(completed.update.latestVersion.toNullable()?.value, 'v1.0.0');
  });

  test('app update checker defaults to the packaged Konyak app version', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-app-version-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final metadataFile =
        File(_joinTestPath(tempDirectory.path, const ['release.json']))
          ..writeAsStringSync(
            jsonEncode(<String, Object?>{
              'tag_name': 'v$konyakAppVersion',
              'assets': [],
            }),
          );
    final checker = DartIoAppUpdateChecker.fromEnvironment(
      HostEnvironment({'KONYAK_APP_VERSION_URL': metadataFile.uri.toString()}),
    );

    final result = checker.check();

    expect(result, isA<AppUpdateCheckCompleted>());
    final completed = result as AppUpdateCheckCompleted;
    expect(completed.update.status.value, 'current');
    expect(
      completed.update.currentVersion.toNullable()?.value,
      konyakAppVersion,
    );
  });

  test('app update checker selects the macOS archive from shared releases', () {
    final metadataFile = _writeMultiPlatformAppReleaseMetadata();
    final checker = DartIoAppUpdateChecker(
      appId: 'konyak',
      currentVersion: '1.0.0',
      versionUrl: metadataFile.uri.toString(),
      hostPlatform: KonyakHostPlatform.macos,
    );

    final result = checker.check();

    expect(result, isA<AppUpdateCheckCompleted>());
    final completed = result as AppUpdateCheckCompleted;
    expect(
      completed.update.archiveUrl.toNullable()?.value,
      'https://example.invalid/Konyak-1.1.0-macos-arm64.dmg',
    );
    expect(
      completed.update.archiveSha256.toNullable()?.value,
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    );
  });

  test('app update checker selects the Linux archive from shared releases', () {
    final metadataFile = _writeMultiPlatformAppReleaseMetadata();
    final checker = DartIoAppUpdateChecker(
      appId: 'konyak',
      currentVersion: '1.0.0',
      versionUrl: metadataFile.uri.toString(),
      hostPlatform: KonyakHostPlatform.linux,
    );

    final result = checker.check();

    expect(result, isA<AppUpdateCheckCompleted>());
    final completed = result as AppUpdateCheckCompleted;
    expect(
      completed.update.archiveUrl.toNullable()?.value,
      'https://example.invalid/Konyak-1.1.0-linux-x86_64.AppImage',
    );
    expect(
      completed.update.archiveSha256.toNullable()?.value,
      'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
    );
  });

  test('release metadata fetcher selects archives over checksum assets', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-release-metadata-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final metadataFile =
        File(
          _joinTestPath(tempDirectory.path, const ['release.json']),
        )..writeAsStringSync(
          jsonEncode(<String, Object?>{
            'tag_name': 'v1.1.0',
            'body':
                'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa  Konyak-1.1.0-macos-arm64.dmg',
            'assets': [
              {
                'browser_download_url':
                    'https://example.invalid/Konyak-1.1.0-macos-arm64.dmg.sha256',
              },
              {
                'browser_download_url':
                    'https://example.invalid/Konyak-1.1.0-macos-arm64.dmg',
              },
            ],
          }),
        );
    const fetcher = DartIoRuntimeReleaseMetadataFetcher();

    final result = fetcher.fetch(metadataFile.uri.toString());

    expect(result, isA<RuntimeReleaseMetadataFetched>());
    final fetched = result as RuntimeReleaseMetadataFetched;
    expect(
      fetched.metadata.archiveUrl.toNullable()?.value,
      'https://example.invalid/Konyak-1.1.0-macos-arm64.dmg',
    );
    expect(
      fetched.metadata.archiveSha256.toNullable()?.value,
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    );
  });

  test('release metadata fetcher does not fall back to non-archive assets', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-release-metadata-non-archive-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final metadataFile =
        File(_joinTestPath(tempDirectory.path, const ['release.json']))
          ..writeAsStringSync(
            jsonEncode(<String, Object?>{
              'tag_name': 'v1.1.0',
              'assets': [
                {
                  'browser_download_url':
                      'https://example.invalid/releases/Konyak.zip/notes.txt',
                },
                {'browser_download_url': 'https://example.invalid/README.txt'},
              ],
            }),
          );
    const fetcher = DartIoRuntimeReleaseMetadataFetcher();

    final result = fetcher.fetch(metadataFile.uri.toString());

    expect(result, isA<RuntimeReleaseMetadataFetched>());
    final fetched = result as RuntimeReleaseMetadataFetched;
    expect(fetched.metadata.archiveUrl.isNone(), isTrue);
  });

  test(
    'release metadata fetcher rejects unreadable release metadata assets',
    () {
      final tempDirectory = Directory.systemTemp.createTempSync(
        'konyak-release-metadata-asset-failure-test-',
      );
      addTearDown(() {
        if (tempDirectory.existsSync()) {
          tempDirectory.deleteSync(recursive: true);
        }
      });
      final missingAsset = File(
        _joinTestPath(tempDirectory.path, const ['missing.release.json']),
      );
      final metadataFile =
          File(_joinTestPath(tempDirectory.path, const ['release.json']))
            ..writeAsStringSync(
              jsonEncode(<String, Object?>{
                'tag_name': 'v1.1.0',
                'assets': [
                  {
                    'browser_download_url':
                        'https://example.invalid/Konyak-1.1.0-macos-arm64.dmg',
                  },
                  {'browser_download_url': missingAsset.uri.toString()},
                ],
              }),
            );
      const fetcher = DartIoRuntimeReleaseMetadataFetcher();

      final result = fetcher.fetch(metadataFile.uri.toString());

      expect(result, isA<RuntimeReleaseMetadataFetchFailed>());
      expect(
        (result as RuntimeReleaseMetadataFetchFailed).message,
        contains('release metadata asset'),
      );
    },
  );

  test('release metadata fetcher resolves runtime stack source manifests', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-runtime-stack-release-metadata-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final metadataFile =
        File(
          _joinTestPath(tempDirectory.path, const ['release.json']),
        )..writeAsStringSync(
          jsonEncode(<String, Object?>{
            'tag_name': 'v1.1.0',
            'assets': [
              {
                'browser_download_url':
                    'https://example.invalid/Konyak-1.1.0-linux-x86_64.AppImage',
              },
              {
                'browser_download_url':
                    'https://example.invalid/Konyak-1.1.0-linux-x86_64.release.json',
              },
              {
                'browser_download_url':
                    'https://example.invalid/konyak-linux-wine-runtime-stack-source.json',
              },
              {
                'browser_download_url':
                    'https://example.invalid/konyak-linux-wine-runtime-stack-source.json.sig',
              },
            ],
          }),
        );
    final releaseAsset =
        File(
          _joinTestPath(tempDirectory.path, const [
            'Konyak-1.1.0-linux.release.json',
          ]),
        )..writeAsStringSync(
          jsonEncode(<String, Object?>{
            'schemaVersion': 1,
            'appId': 'konyak',
            'version': '1.1.0',
            'runtimeStack': {
              'runtimeId': 'konyak-linux-wine',
              'stackId': 'linux-wine-runtime-stack',
              'sourceManifestFileName':
                  'konyak-linux-wine-runtime-stack-source.json',
              'signatureFileName':
                  'konyak-linux-wine-runtime-stack-source.json.sig',
            },
          }),
        );
    final metadataPayload =
        jsonDecode(metadataFile.readAsStringSync()) as Map<String, Object?>;
    final assets = (metadataPayload['assets'] as List<Object?>)
        .cast<Map<String, Object?>>();
    assets[1] = <String, Object?>{
      'browser_download_url': releaseAsset.uri.toString(),
    };
    metadataFile.writeAsStringSync(jsonEncode(metadataPayload));

    const fetcher = DartIoRuntimeReleaseMetadataFetcher();

    final result = fetcher.fetch(metadataFile.uri.toString());

    expect(result, isA<RuntimeReleaseMetadataFetched>());
    final fetched = result as RuntimeReleaseMetadataFetched;
    expect(
      fetched.metadata.sourceManifestUrl.toNullable()?.value,
      'https://example.invalid/konyak-linux-wine-runtime-stack-source.json',
    );
    expect(
      fetched.metadata.sourceManifestSignatureUrl.toNullable()?.value,
      'https://example.invalid/konyak-linux-wine-runtime-stack-source.json.sig',
    );
  });

  test('app update checker includes release archive checksums', () {
    final checker = DartIoAppUpdateChecker(
      appId: 'konyak',
      currentVersion: '1.0.0',
      versionUrl: 'https://example.invalid/releases/latest',
      releaseMetadataFetcher: StaticRuntimeReleaseMetadataFetcher(
        RuntimeReleaseMetadata(
          version: 'v1.1.0',
          archiveUrl: Option.of(
            'https://example.invalid/Konyak-1.1.0-macos.dmg',
          ),
          archiveSha256: Option.of(
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
          ),
        ),
      ),
    );

    final result = checker.check();

    expect(result, isA<AppUpdateCheckCompleted>());
    final completed = result as AppUpdateCheckCompleted;
    expect(
      completed.update.archiveSha256.toNullable()?.value,
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    );
  });

  test('install-app-update --json installs available Konyak updates', () {
    final checker = RecordingAppUpdateChecker(
      result: AppUpdateCheckCompleted(
        AppUpdateRecord(
          appId: 'konyak',
          status: 'available',
          currentVersion: Option.of('1.0.0'),
          latestVersion: Option.of('1.1.0'),
          versionUrl: Option.of(
            'https://api.github.com/repos/serika12345/Konyak/releases/latest',
          ),
          archiveUrl: Option.of('https://example.invalid/Konyak-1.1.0.dmg'),
        ),
      ),
    );
    final installer = RecordingAppUpdateInstaller(
      result: AppUpdateInstallCompleted(
        AppUpdateInstallRecord(
          appId: 'konyak',
          status: 'installed',
          currentVersion: Option.of('1.0.0'),
          installedVersion: Option.of('1.1.0'),
          archiveUrl: Option.of('https://example.invalid/Konyak-1.1.0.dmg'),
          installPath: Option.of('/tmp/Konyak-1.1.0.dmg'),
        ),
      ),
    );

    final result = runCli(
      const ['install-app-update', '--json'],
      appUpdateChecker: checker,
      appUpdateInstaller: installer,
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(checker.checkCount, 1);
    expect(installer.lastUpdate?.latestVersion.toNullable()?.value, '1.1.0');

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'appUpdateInstall': {
        'appId': 'konyak',
        'status': 'installed',
        'currentVersion': '1.0.0',
        'installedVersion': '1.1.0',
        'archiveUrl': 'https://example.invalid/Konyak-1.1.0.dmg',
        'installPath': '/tmp/Konyak-1.1.0.dmg',
      },
    });
  });

  test('app update installer verifies archive checksums before opening', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-app-update-checksum-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final sourceArchive = File(
      _joinTestPath(tempDirectory.path, const ['Konyak-1.1.0-macos.dmg']),
    )..writeAsStringSync('signed app update');
    final updateCache = _joinTestPath(tempDirectory.path, const ['cache']);
    final pathOpener = RecordingPathOpener(result: const PathOpenCompleted());
    final installer = DartIoAppUpdateInstaller(
      environment: HostEnvironment({
        'KONYAK_APP_UPDATE_CACHE_HOME': updateCache,
      }),
      hostPlatform: KonyakHostPlatform.macos,
      pathOpener: pathOpener,
    );

    final result = installer.install(
      AppUpdateRecord(
        appId: 'konyak',
        status: 'available',
        currentVersion: Option.of('1.0.0'),
        latestVersion: Option.of('1.1.0'),
        archiveUrl: Option.of(sourceArchive.uri.toString()),
        archiveSha256: Option.of(_fileSha256(sourceArchive.path)),
      ),
    );

    expect(result, isA<AppUpdateInstallCompleted>());
    final completed = result as AppUpdateInstallCompleted;
    expect(
      completed.install.archiveSha256.toNullable()?.value,
      _fileSha256(sourceArchive.path),
    );
    expect(
      pathOpener.lastPath,
      completed.install.installPath.toNullable()?.value,
    );
    expect(
      File(completed.install.installPath.toNullable()!.value).existsSync(),
      isTrue,
    );
  });

  test('app update installer rejects updates without checksums', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-app-update-missing-checksum-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final sourceArchive = File(
      _joinTestPath(tempDirectory.path, const ['Konyak-1.1.0-macos.dmg']),
    )..writeAsStringSync('unsigned app update');
    final pathOpener = RecordingPathOpener(result: const PathOpenCompleted());
    final installer = DartIoAppUpdateInstaller(
      environment: HostEnvironment({
        'KONYAK_APP_UPDATE_CACHE_HOME': _joinTestPath(
          tempDirectory.path,
          const ['cache'],
        ),
      }),
      hostPlatform: KonyakHostPlatform.macos,
      pathOpener: pathOpener,
    );

    final result = installer.install(
      AppUpdateRecord(
        appId: 'konyak',
        status: 'available',
        currentVersion: Option.of('1.0.0'),
        latestVersion: Option.of('1.1.0'),
        archiveUrl: Option.of(sourceArchive.uri.toString()),
      ),
    );

    expect(result, isA<AppUpdateInstallFailed>());
    final failed = result as AppUpdateInstallFailed;
    expect(failed.message, contains('checksum'));
    expect(pathOpener.lastPath, isNull);
  });

  test('app update installer rejects archive checksum mismatches', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-app-update-bad-checksum-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final sourceArchive = File(
      _joinTestPath(tempDirectory.path, const ['Konyak-1.1.0-macos.dmg']),
    )..writeAsStringSync('tampered app update');
    final pathOpener = RecordingPathOpener(result: const PathOpenCompleted());
    final installer = DartIoAppUpdateInstaller(
      environment: HostEnvironment({
        'KONYAK_APP_UPDATE_CACHE_HOME': _joinTestPath(
          tempDirectory.path,
          const ['cache'],
        ),
      }),
      hostPlatform: KonyakHostPlatform.macos,
      pathOpener: pathOpener,
    );

    final result = installer.install(
      AppUpdateRecord(
        appId: 'konyak',
        status: 'available',
        currentVersion: Option.of('1.0.0'),
        latestVersion: Option.of('1.1.0'),
        archiveUrl: Option.of(sourceArchive.uri.toString()),
        archiveSha256: Option.of(
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
        ),
      ),
    );

    expect(result, isA<AppUpdateInstallFailed>());
    final failed = result as AppUpdateInstallFailed;
    expect(failed.message, contains('checksum mismatch'));
    expect(pathOpener.lastPath, isNull);
  });

  test('app update installer stages Linux AppImage replacement handoff', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-appimage-update-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final sourceArchive = File(
      _joinTestPath(tempDirectory.path, const ['Konyak-1.1.0-linux.AppImage']),
    )..writeAsStringSync('updated appimage');
    final currentAppImage = File(
      _joinTestPath(tempDirectory.path, const ['Konyak-current.AppImage']),
    )..writeAsStringSync('current appimage');
    final detachedProcessStarter = RecordingDetachedProcessStarter(
      result: const DetachedProcessStartCompleted(),
    );
    final installer = DartIoAppUpdateInstaller(
      environment: HostEnvironment({
        'KONYAK_APP_UPDATE_CACHE_HOME': _joinTestPath(
          tempDirectory.path,
          const ['cache'],
        ),
        'KONYAK_APPIMAGE_PATH': currentAppImage.path,
        'KONYAK_APP_PID': '4242',
      }),
      hostPlatform: KonyakHostPlatform.linux,
      detachedProcessStarter: detachedProcessStarter,
    );

    final result = installer.install(
      AppUpdateRecord(
        appId: 'konyak',
        status: 'available',
        currentVersion: Option.of('1.0.0'),
        latestVersion: Option.of('1.1.0'),
        archiveUrl: Option.of(sourceArchive.uri.toString()),
        archiveSha256: Option.of(_fileSha256(sourceArchive.path)),
      ),
    );

    expect(result, isA<AppUpdateInstallCompleted>());
    final completed = result as AppUpdateInstallCompleted;
    expect(
      completed.install.installPath.toNullable()?.value,
      currentAppImage.path,
    );
    expect(detachedProcessStarter.lastExecutable, 'bash');
    expect(detachedProcessStarter.lastArguments, hasLength(4));
    expect(detachedProcessStarter.lastArguments[2], currentAppImage.path);
    expect(detachedProcessStarter.lastArguments[3], '4242');

    final handoffScript = File(detachedProcessStarter.lastArguments[0]);
    expect(handoffScript.existsSync(), isTrue);
    expect(
      handoffScript.readAsStringSync(),
      allOf(
        contains(r'kill -TERM "$app_pid"'),
        contains(r'mv "$staging_path" "$target_appimage"'),
        contains(r'nohup "$target_appimage"'),
      ),
    );

    final stagedArchive = File(detachedProcessStarter.lastArguments[1]);
    expect(stagedArchive.existsSync(), isTrue);
    expect(_fileSha256(stagedArchive.path), _fileSha256(sourceArchive.path));
  });

  test(
    'app update installer rejects missing Linux AppImage before handoff',
    () {
      final tempDirectory = Directory.systemTemp.createTempSync(
        'konyak-appimage-update-missing-target-test-',
      );
      addTearDown(() {
        if (tempDirectory.existsSync()) {
          tempDirectory.deleteSync(recursive: true);
        }
      });
      final sourceArchive = File(
        _joinTestPath(tempDirectory.path, const [
          'Konyak-1.1.0-linux.AppImage',
        ]),
      )..writeAsStringSync('updated appimage');
      final missingAppImagePath = _joinTestPath(tempDirectory.path, const [
        'missing',
        'Konyak-current.AppImage',
      ]);
      final detachedProcessStarter = RecordingDetachedProcessStarter(
        result: const DetachedProcessStartCompleted(),
      );
      final pathOpener = RecordingPathOpener(result: const PathOpenCompleted());
      final installer = DartIoAppUpdateInstaller(
        environment: HostEnvironment({
          'KONYAK_APP_UPDATE_CACHE_HOME': _joinTestPath(
            tempDirectory.path,
            const ['cache'],
          ),
          'KONYAK_APPIMAGE_PATH': missingAppImagePath,
          'KONYAK_APP_PID': '4242',
        }),
        hostPlatform: KonyakHostPlatform.linux,
        pathOpener: pathOpener,
        detachedProcessStarter: detachedProcessStarter,
      );

      final result = installer.install(
        AppUpdateRecord(
          appId: 'konyak',
          status: 'available',
          currentVersion: Option.of('1.0.0'),
          latestVersion: Option.of('1.1.0'),
          archiveUrl: Option.of(sourceArchive.uri.toString()),
          archiveSha256: Option.of(_fileSha256(sourceArchive.path)),
        ),
      );

      expect(result, isA<AppUpdateInstallFailed>());
      final failed = result as AppUpdateInstallFailed;
      expect(
        failed.message,
        contains('Current Konyak AppImage does not exist'),
      );
      expect(detachedProcessStarter.lastExecutable, isNull);
      expect(pathOpener.lastPath, isNull);
    },
  );

  test('app update installer stages macOS app bundle replacement handoff', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-macos-app-update-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final sourceArchive = File(
      _joinTestPath(tempDirectory.path, const ['Konyak-1.1.0-macos.zip']),
    )..writeAsStringSync('updated macOS app bundle');
    final currentBundle = Directory(
      _joinTestPath(tempDirectory.path, const ['Konyak.app']),
    )..createSync();
    File(
        _joinTestPath(currentBundle.path, const [
          'Contents',
          'MacOS',
          'Konyak',
        ]),
      )
      ..createSync(recursive: true)
      ..writeAsStringSync('current app executable');
    final detachedProcessStarter = RecordingDetachedProcessStarter(
      result: const DetachedProcessStartCompleted(),
    );
    final pathOpener = RecordingPathOpener(result: const PathOpenCompleted());
    final installer = DartIoAppUpdateInstaller(
      environment: HostEnvironment({
        'KONYAK_APP_UPDATE_CACHE_HOME': _joinTestPath(
          tempDirectory.path,
          const ['cache'],
        ),
        'KONYAK_APP_EXECUTABLE': _joinTestPath(currentBundle.path, const [
          'Contents',
          'MacOS',
          'Konyak',
        ]),
        'KONYAK_APP_PID': '5150',
      }),
      hostPlatform: KonyakHostPlatform.macos,
      pathOpener: pathOpener,
      detachedProcessStarter: detachedProcessStarter,
    );

    final result = installer.install(
      AppUpdateRecord(
        appId: 'konyak',
        status: 'available',
        currentVersion: Option.of('1.0.0'),
        latestVersion: Option.of('1.1.0'),
        archiveUrl: Option.of(sourceArchive.uri.toString()),
        archiveSha256: Option.of(_fileSha256(sourceArchive.path)),
      ),
    );

    expect(result, isA<AppUpdateInstallCompleted>());
    final completed = result as AppUpdateInstallCompleted;
    expect(
      completed.install.installPath.toNullable()?.value,
      currentBundle.path,
    );
    expect(pathOpener.lastPath, isNull);
    expect(detachedProcessStarter.lastExecutable, 'bash');
    expect(detachedProcessStarter.lastArguments, hasLength(4));
    expect(detachedProcessStarter.lastArguments[2], currentBundle.path);
    expect(detachedProcessStarter.lastArguments[3], '5150');

    final handoffScript = File(detachedProcessStarter.lastArguments[0]);
    expect(handoffScript.existsSync(), isTrue);
    expect(
      handoffScript.readAsStringSync(),
      allOf(
        contains(r'ditto -x -k "$source_archive" "$extract_dir"'),
        contains(r'kill -TERM "$app_pid"'),
        contains(r'mv "$target_bundle" "$backup_path"'),
        contains(r'if [[ -w "$target_parent" ]]'),
        contains(r'with administrator privileges'),
        contains(r'nohup open "$target_bundle"'),
      ),
    );

    final stagedArchive = File(detachedProcessStarter.lastArguments[1]);
    expect(stagedArchive.existsSync(), isTrue);
    expect(_fileSha256(stagedArchive.path), _fileSha256(sourceArchive.path));
  });

  test('app update installer stages macOS DMG replacement handoff', () {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-macos-dmg-app-update-test-',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });
    final sourceArchive = File(
      _joinTestPath(tempDirectory.path, const ['Konyak-1.1.0-macos.dmg']),
    )..writeAsStringSync('updated macOS app bundle dmg');
    final currentBundle = Directory(
      _joinTestPath(tempDirectory.path, const ['Konyak.app']),
    )..createSync();
    File(
        _joinTestPath(currentBundle.path, const [
          'Contents',
          'MacOS',
          'Konyak',
        ]),
      )
      ..createSync(recursive: true)
      ..writeAsStringSync('current app executable');
    final detachedProcessStarter = RecordingDetachedProcessStarter(
      result: const DetachedProcessStartCompleted(),
    );
    final pathOpener = RecordingPathOpener(result: const PathOpenCompleted());
    final installer = DartIoAppUpdateInstaller(
      environment: HostEnvironment({
        'KONYAK_APP_UPDATE_CACHE_HOME': _joinTestPath(
          tempDirectory.path,
          const ['cache'],
        ),
        'KONYAK_APP_EXECUTABLE': _joinTestPath(currentBundle.path, const [
          'Contents',
          'MacOS',
          'Konyak',
        ]),
        'KONYAK_APP_PID': '5150',
      }),
      hostPlatform: KonyakHostPlatform.macos,
      pathOpener: pathOpener,
      detachedProcessStarter: detachedProcessStarter,
    );

    final result = installer.install(
      AppUpdateRecord(
        appId: 'konyak',
        status: 'available',
        currentVersion: Option.of('1.0.0'),
        latestVersion: Option.of('1.1.0'),
        archiveUrl: Option.of(sourceArchive.uri.toString()),
        archiveSha256: Option.of(_fileSha256(sourceArchive.path)),
      ),
    );

    expect(result, isA<AppUpdateInstallCompleted>());
    final completed = result as AppUpdateInstallCompleted;
    expect(
      completed.install.installPath.toNullable()?.value,
      currentBundle.path,
    );
    expect(pathOpener.lastPath, isNull);
    expect(detachedProcessStarter.lastExecutable, 'bash');
    expect(detachedProcessStarter.lastArguments, hasLength(4));
    expect(detachedProcessStarter.lastArguments[1], endsWith('.dmg'));
    expect(detachedProcessStarter.lastArguments[2], currentBundle.path);
    expect(detachedProcessStarter.lastArguments[3], '5150');

    final handoffScript = File(detachedProcessStarter.lastArguments[0]);
    expect(handoffScript.existsSync(), isTrue);
    expect(
      handoffScript.readAsStringSync(),
      allOf(
        contains(r'hdiutil attach "$source_archive"'),
        contains(r'hdiutil detach "$mount_dir"'),
        contains(r'kill -TERM "$app_pid"'),
        contains(r'mv "$target_bundle" "$backup_path"'),
        contains(r'nohup open "$target_bundle"'),
      ),
    );

    final stagedArchive = File(detachedProcessStarter.lastArguments[1]);
    expect(stagedArchive.existsSync(), isTrue);
    expect(_fileSha256(stagedArchive.path), _fileSha256(sourceArchive.path));
  });

  test(
    'install-runtime-update --json installs available runtime source manifests',
    () {
      final checker = RecordingRuntimeUpdateChecker(
        result: RuntimeUpdateCheckCompleted(
          RuntimeUpdateRecord(
            runtimeId: 'konyak-macos-wine',
            status: 'available',
            currentVersion: Option.of('wine-devel-11.9'),
            latestVersion: Option.of('12.0'),
            sourceManifestUrl: Option.of(
              'https://example.invalid/runtime-stack-source.json',
            ),
          ),
        ),
      );
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
        const ['install-runtime-update', 'konyak-macos-wine', '--json'],
        runtimeUpdateChecker: checker,
        macosWineInstaller: installer,
      );

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);
      expect(checker.lastRuntimeId, 'konyak-macos-wine');
      expect(
        installer.lastRequest?.sourceManifest.toNullable(),
        'https://example.invalid/runtime-stack-source.json',
      );
      expect(installer.lastRequest?.archiveUrl.isNone(), isTrue);
      expect(
        installer.lastRequest?.operation,
        RuntimeInstallOperation.updateInstall,
      );
      expect(
        installer.lastRequest?.requestOperation,
        isA<RuntimeUpdateInstallOperation>(),
      );
      expect(installer.lastRequest?.force, isTrue);

      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      expect(payload['schemaVersion'], 1);
      expect(payload['runtime'], containsPair('id', 'konyak-macos-wine'));
    },
  );

  test('install-runtime-update uses stack source manifests when available', () {
    final checker = RecordingRuntimeUpdateChecker(
      result: RuntimeUpdateCheckCompleted(
        RuntimeUpdateRecord(
          runtimeId: 'konyak-macos-wine',
          status: 'available',
          currentVersion: Option.of('wine-devel-11.9'),
          latestVersion: Option.of('12.0'),
          sourceManifestUrl: Option.of(
            'https://example.invalid/runtime-stack-source.json',
          ),
        ),
      ),
    );
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
      const ['install-runtime-update', 'konyak-macos-wine', '--json'],
      runtimeUpdateChecker: checker,
      macosWineInstaller: installer,
    );

    expect(result.exitCode, 0);
    expect(
      installer.lastRequest?.sourceManifest.toNullable(),
      'https://example.invalid/runtime-stack-source.json',
    );
    expect(
      installer.lastRequest?.operation,
      RuntimeInstallOperation.updateInstall,
    );
    expect(installer.lastRequest?.force, isTrue);
  });

  test(
    'install-runtime-update installs available Linux runtime source manifests',
    () {
      final checker = RecordingRuntimeUpdateChecker(
        result: RuntimeUpdateCheckCompleted(
          RuntimeUpdateRecord(
            runtimeId: 'konyak-linux-wine',
            status: 'available',
            currentVersion: Option.of('wine-10.0'),
            latestVersion: Option.of('wine-10.1'),
            sourceManifestUrl: Option.of(
              'https://example.invalid/linux-runtime-stack.json',
            ),
          ),
        ),
      );
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
        const ['install-runtime-update', 'konyak-linux-wine', '--json'],
        runtimeUpdateChecker: checker,
        linuxWineInstaller: installer,
      );

      expect(result.exitCode, 0);
      expect(checker.lastRuntimeId, 'konyak-linux-wine');
      expect(
        installer.lastRequest?.sourceManifest.toNullable(),
        'https://example.invalid/linux-runtime-stack.json',
      );
      expect(installer.lastRequest?.archiveUrl.isNone(), isTrue);
      expect(
        installer.lastRequest?.operation,
        RuntimeInstallOperation.updateInstall,
      );
      expect(installer.lastRequest?.force, isTrue);
    },
  );

  test(
    'install-runtime-update uses stack source manifests for Linux when available',
    () {
      final checker = RecordingRuntimeUpdateChecker(
        result: RuntimeUpdateCheckCompleted(
          RuntimeUpdateRecord(
            runtimeId: 'konyak-linux-wine',
            status: 'available',
            currentVersion: Option.of('wine-10.0'),
            latestVersion: Option.of('wine-10.1'),
            sourceManifestUrl: Option.of(
              'https://example.invalid/linux-runtime-stack.json',
            ),
            sourceManifestSignatureUrl: Option.of(
              'https://example.invalid/linux-runtime-stack.json.sig',
            ),
            archiveUrl: Option.of(
              'https://example.invalid/linux-runtime-stack.json',
            ),
          ),
        ),
      );
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
        const ['install-runtime-update', 'konyak-linux-wine', '--json'],
        runtimeUpdateChecker: checker,
        linuxWineInstaller: installer,
      );

      expect(result.exitCode, 0);
      expect(
        installer.lastRequest?.sourceManifest.toNullable(),
        'https://example.invalid/linux-runtime-stack.json',
      );
      expect(
        installer.lastRequest?.sourceManifestSignature.toNullable(),
        'https://example.invalid/linux-runtime-stack.json.sig',
      );
      expect(
        installer.lastRequest?.operation,
        RuntimeInstallOperation.updateInstall,
      );
      expect(installer.lastRequest?.archiveUrl.isNone(), isTrue);
      expect(installer.lastRequest?.force, isTrue);
    },
  );

  test(
    'runtime update checker uses source manifests from release metadata',
    () {
      final checker = DartIoRuntimeUpdateChecker(
        runtimeCatalog: StaticRuntimeCatalog([
          RuntimeRecord(
            id: 'konyak-linux-wine',
            name: 'Konyak Linux Wine',
            platform: 'linux',
            architecture: 'x86_64',
            runnerKind: 'wine',
            isBundled: false,
            isUpdateable: true,
            versionUrl: Option.of('https://example.invalid/releases/latest'),
            stack: Option.of(
              RuntimeStack(
                id: 'linux-wine-runtime-stack',
                name: 'Linux Wine/Proton runtime stack',
                compatibilityTarget: 'linux-wine-runtime-stack',
                components: [
                  RuntimeStackComponent(
                    id: 'wine',
                    name: 'Wine',
                    role: 'windows-runner',
                    isRequired: true,
                    paths: const <String>[],
                    missingPaths: const <String>[],
                    version: Option.of('wine-10.0'),
                  ),
                ],
              ),
            ),
          ),
        ]),
        releaseMetadataFetcher: StaticRuntimeReleaseMetadataFetcher(
          RuntimeReleaseMetadata(
            version: 'wine-10.1',
            sourceManifestUrl: Option.of(
              'https://example.invalid/linux-runtime-stack-source.json',
            ),
            sourceManifestSignatureUrl: Option.of(
              'https://example.invalid/linux-runtime-stack-source.json.sig',
            ),
          ),
        ),
      );

      final result = checker.check('konyak-linux-wine');

      expect(result, isA<RuntimeUpdateCheckCompleted>());
      final completed = result as RuntimeUpdateCheckCompleted;
      expect(completed.update.status.value, 'available');
      expect(
        completed.update.sourceManifestUrl.toNullable()?.value,
        'https://example.invalid/linux-runtime-stack-source.json',
      );
      expect(
        completed.update.sourceManifestSignatureUrl.toNullable()?.value,
        'https://example.invalid/linux-runtime-stack-source.json.sig',
      );
      expect(completed.update.archiveUrl.isNone(), isTrue);
    },
  );

  test(
    'runtime update checker rejects Linux stack releases without source manifests',
    () {
      final checker = DartIoRuntimeUpdateChecker(
        runtimeCatalog: StaticRuntimeCatalog([
          RuntimeRecord(
            id: 'konyak-linux-wine',
            name: 'Konyak Linux Wine',
            platform: 'linux',
            architecture: 'x86_64',
            runnerKind: 'wine',
            isBundled: false,
            isUpdateable: true,
            versionUrl: Option.of('https://example.invalid/releases/latest'),
            stack: Option.of(
              RuntimeStack(
                id: 'linux-wine-runtime-stack',
                name: 'Linux Wine/Proton runtime stack',
                compatibilityTarget: 'linux-wine-runtime-stack',
                components: [
                  RuntimeStackComponent(
                    id: 'wine',
                    name: 'Wine',
                    role: 'windows-runner',
                    isRequired: true,
                    paths: const <String>[],
                    missingPaths: const <String>[],
                    version: Option.of('wine-10.0'),
                  ),
                ],
              ),
            ),
          ),
        ]),
        releaseMetadataFetcher: StaticRuntimeReleaseMetadataFetcher(
          RuntimeReleaseMetadata(
            version: 'wine-10.1',
            archiveUrl: Option.of(
              'https://example.invalid/linux-wine-10.1.tar.xz',
            ),
          ),
        ),
      );

      final result = checker.check('konyak-linux-wine');

      expect(result, isA<RuntimeUpdateCheckFailed>());
      expect(
        (result as RuntimeUpdateCheckFailed).message,
        contains('source manifest'),
      );
    },
  );

  test(
    'runtime update checker rejects macOS releases without source manifests',
    () {
      final checker = DartIoRuntimeUpdateChecker(
        runtimeCatalog: StaticRuntimeCatalog([
          RuntimeRecord(
            id: 'konyak-macos-wine',
            name: 'Konyak macOS Wine',
            platform: 'macos',
            architecture: 'x86_64',
            runnerKind: 'macosWine',
            isBundled: false,
            isUpdateable: true,
            versionUrl: Option.of('https://example.invalid/releases/latest'),
            archiveUrl: Option.of('https://example.invalid/runtime.tar.xz'),
            stack: Option.of(
              RuntimeStack(
                id: 'macos-konyak-runtime-stack',
                name: 'Konyak macOS runtime stack',
                compatibilityTarget: 'macos-konyak-runtime-stack',
                components: [
                  RuntimeStackComponent(
                    id: 'wine',
                    name: 'Wine',
                    role: 'windows-runner',
                    isRequired: true,
                    paths: const <String>[],
                    missingPaths: const <String>[],
                    version: Option.of('wine-devel-11.9'),
                  ),
                ],
              ),
            ),
          ),
        ]),
        releaseMetadataFetcher: StaticRuntimeReleaseMetadataFetcher(
          RuntimeReleaseMetadata(
            version: '11.10',
            archiveUrl: Option.of('https://example.invalid/runtime.tar.xz'),
          ),
        ),
      );

      final result = checker.check('konyak-macos-wine');

      expect(result, isA<RuntimeUpdateCheckFailed>());
      expect(
        (result as RuntimeUpdateCheckFailed).message,
        contains('source manifest'),
      );
    },
  );

  test(
    'runtime update checker compares Wine component version to release tag',
    () {
      final checker = DartIoRuntimeUpdateChecker(
        runtimeCatalog: StaticRuntimeCatalog([
          RuntimeRecord(
            id: 'konyak-macos-wine',
            name: 'Konyak macOS Wine',
            platform: 'macos',
            architecture: 'x86_64',
            runnerKind: 'macosWine',
            isBundled: false,
            isUpdateable: true,
            versionUrl: Option.of('https://example.invalid/releases/latest'),
            archiveUrl: Option.of('https://example.invalid/runtime.tar.xz'),
            stack: Option.of(
              RuntimeStack(
                id: 'macos-konyak-runtime-stack',
                name: 'Konyak macOS runtime stack',
                compatibilityTarget: 'macos-konyak-runtime-stack',
                components: [
                  RuntimeStackComponent(
                    id: 'wine',
                    name: 'Wine',
                    role: 'windows-runner',
                    isRequired: true,
                    paths: const <String>[],
                    missingPaths: const <String>[],
                    version: Option.of('wine-devel-11.9'),
                  ),
                ],
              ),
            ),
          ),
        ]),
        releaseMetadataFetcher: StaticRuntimeReleaseMetadataFetcher(
          RuntimeReleaseMetadata(
            version: '11.9',
            sourceManifestUrl: Option.of(
              'https://example.invalid/macos-runtime-stack-source.json',
            ),
          ),
        ),
      );

      final result = checker.check('konyak-macos-wine');

      expect(result, isA<RuntimeUpdateCheckCompleted>());
      final completed = result as RuntimeUpdateCheckCompleted;
      expect(completed.update.status.value, 'current');
      expect(
        completed.update.currentVersion.toNullable()?.value,
        'wine-devel-11.9',
      );
      expect(completed.update.latestVersion.toNullable()?.value, '11.9');
    },
  );

  test('validate-runtime --json returns runtime loader checks', () {
    final validator = RecordingRuntimeValidator(
      result: RuntimeValidationCompleted(
        RuntimeValidationRecord(
          runtimeId: 'konyak-macos-wine',
          isValid: true,
          checks: [
            RuntimeValidationCheck(
              id: 'wine-loader',
              name: 'Wine loader',
              isRequired: true,
              isPassed: true,
              message: 'wineloader --version completed.',
            ),
          ],
        ),
      ),
    );

    final result = runCli(const [
      'validate-runtime',
      'konyak-macos-wine',
      '--json',
    ], runtimeValidator: validator);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
    expect(validator.lastRuntimeId, 'konyak-macos-wine');

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'runtimeValidation': {
        'runtimeId': 'konyak-macos-wine',
        'isValid': true,
        'checks': [
          {
            'id': 'wine-loader',
            'name': 'Wine loader',
            'isRequired': true,
            'isPassed': true,
            'message': 'wineloader --version completed.',
          },
        ],
      },
    });
  });

  test('check-macos-setup --json returns Rosetta and runtime status', () {
    final checker = RecordingMacosSetupChecker(
      result: MacosSetupCheckCompleted(
        MacosSetupStatus(
          isSupported: true,
          rosetta: RosettaSetupStatus(
            isRequired: true,
            isInstalled: true,
            installCommand: [
              '/usr/sbin/softwareupdate',
              '--install-rosetta',
              '--agree-to-license',
            ],
          ),
          runtime: RuntimeSetupStatus(
            runtimeId: 'konyak-macos-wine',
            isInstalled: false,
          ),
        ),
      ),
    );

    final result = runCli(const [
      'check-macos-setup',
      '--json',
    ], macosSetupChecker: checker);

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);

    final payload = jsonDecode(result.stdout) as Map<String, Object?>;
    expect(payload, {
      'schemaVersion': 1,
      'macosSetup': {
        'isSupported': true,
        'rosetta': {
          'isRequired': true,
          'isInstalled': true,
          'installCommand': [
            '/usr/sbin/softwareupdate',
            '--install-rosetta',
            '--agree-to-license',
          ],
        },
        'runtime': {'runtimeId': 'konyak-macos-wine', 'isInstalled': false},
      },
    });
  });

  test('macOS setup checker detects Rosetta and runtime prerequisites', () {
    final checker = DartIoMacosSetupChecker(
      hostPlatform: KonyakHostPlatform.macos,
      fileStatusProbe: const StaticFileStatusProbe({
        '/Library/Apple/usr/libexec/oah/libRosettaRuntime',
        '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wineloader',
      }),
      runtimeCatalog: MacosWineRuntimeCatalog(
        hostPlatform: KonyakHostPlatform.macos,
        environment: HostEnvironment(const {'HOME': '/Users/user'}),
        fileStatusProbe: const StaticFileStatusProbe({
          '/Users/user/Library/Application Support/Konyak/Runtimes/macos-wine/bin/wineloader',
        }),
        runtimeStackVersionProbe: const EmptyRuntimeStackVersionProbe(),
      ),
    );

    final result = checker.check();

    expect(result, isA<MacosSetupCheckCompleted>());
    final status = (result as MacosSetupCheckCompleted).status;
    expect(status.isSupported, isTrue);
    expect(status.rosetta.isRequired, isTrue);
    expect(status.rosetta.isInstalled, isTrue);
    expect(status.runtime.runtimeId, 'konyak-macos-wine');
    expect(status.runtime.isInstalled, isTrue);
  });

  test(
    'macOS runtime validator checks library paths before loader execution',
    () {
      final executableProbe = RecordingRuntimeExecutableProbe(
        result: const RuntimeExecutableProbeResult(
          exitCode: 0,
          stdout: 'wine-11.9',
          stderr: '',
        ),
      );
      final validator = DartIoMacosWineRuntimeValidator(
        runtimeCatalog: StaticRuntimeCatalog([
          RuntimeRecord(
            id: 'konyak-macos-wine',
            name: 'Konyak macOS Wine',
            platform: 'macos',
            architecture: 'x86_64',
            runnerKind: 'macosWine',
            isBundled: false,
            isUpdateable: true,
            libraryPath: Option.of('/runtime'),
            executablePath: Option.of('/runtime/bin/wineloader'),
          ),
        ]),
        fileStatusProbe: const StaticFileStatusProbe({
          '/runtime',
          '/runtime/bin/wineloader',
        }),
        executableProbe: executableProbe,
      );

      final result = validator.validate('konyak-macos-wine');

      expect(result, isA<RuntimeValidationCompleted>());
      final validation = (result as RuntimeValidationCompleted).validation;
      expect(validation.isValid, isFalse);
      expect(
        validation.checks.where((check) => check.id == 'loader-dylibs').single,
        isA<RuntimeValidationCheck>()
            .having((check) => check.isPassed, 'isPassed', isFalse)
            .having(
              (check) => check.message,
              'message',
              contains('/runtime/lib'),
            ),
      );
      expect(executableProbe.lastExecutable, isNull);
    },
  );

  test('macOS runtime validator rejects incomplete runtime stacks', () {
    final executableProbe = RecordingRuntimeExecutableProbe(
      result: const RuntimeExecutableProbeResult(
        exitCode: 0,
        stdout: 'wine-11.9',
        stderr: '',
      ),
    );
    final validator = DartIoMacosWineRuntimeValidator(
      runtimeCatalog: StaticRuntimeCatalog([
        RuntimeRecord(
          id: 'konyak-macos-wine',
          name: 'Konyak macOS Wine',
          platform: 'macos',
          architecture: 'x86_64',
          runnerKind: 'macosWine',
          isBundled: false,
          isUpdateable: true,
          libraryPath: Option.of('/runtime'),
          executablePath: Option.of('/runtime/bin/wineloader'),
          stack: Option.of(
            RuntimeStack(
              id: 'macos-konyak-runtime-stack',
              name: 'Konyak macOS runtime stack',
              compatibilityTarget: 'macos-konyak-runtime-stack',
              components: [
                RuntimeStackComponent(
                  id: 'wine-gecko',
                  name: 'wine-gecko',
                  role: 'html-runtime',
                  isRequired: true,
                  paths: const [
                    '/runtime/share/wine/gecko/wine-gecko-2.47.4-x86.msi',
                  ],
                  missingPaths: const [
                    '/runtime/share/wine/gecko/wine-gecko-2.47.4-x86.msi',
                  ],
                ),
              ],
            ),
          ),
        ),
      ]),
      fileStatusProbe: const StaticFileStatusProbe({
        '/runtime',
        '/runtime/bin/wineloader',
        '/runtime/lib',
      }),
      executableProbe: executableProbe,
    );

    final result = validator.validate('konyak-macos-wine');

    expect(result, isA<RuntimeValidationCompleted>());
    final validation = (result as RuntimeValidationCompleted).validation;
    expect(validation.isValid, isFalse);
    expect(
      validation.checks.where((check) => check.id == 'runtime-stack').single,
      isA<RuntimeValidationCheck>()
          .having((check) => check.isPassed, 'isPassed', isFalse)
          .having((check) => check.message, 'message', contains('wine-gecko')),
    );
    expect(executableProbe.lastExecutable, isNull);
  });

  test('Linux runtime validator checks the Wine loader with Linux env', () {
    final executableProbe = RecordingRuntimeExecutableProbe(
      result: const RuntimeExecutableProbeResult(
        exitCode: 0,
        stdout: 'wine-11.9',
        stderr: '',
      ),
    );
    final environment = HostEnvironment(const {
      'HOME': '/home/user',
      'PATH': '/usr/bin:/bin',
      'KONYAK_LINUX_WINE_HOME': '/runtime/linux-wine',
      'KONYAK_LINUX_WINE_LIBRARY_PATH': '/host-libs',
    });
    final validator = DartIoMacosWineRuntimeValidator(
      runtimeCatalog: KonyakRuntimeCatalog(
        hostPlatform: KonyakHostPlatform.linux,
        environment: environment,
        fileStatusProbe: const StaticFileStatusProbe({
          '/runtime/linux-wine/bin/wine',
          '/runtime/linux-wine/bin/winedbg',
          '/runtime/linux-wine/bin/wineserver',
          '/runtime/linux-wine/winetricks',
          '/runtime/linux-wine/share/wine/mono',
          '/runtime/linux-wine/dxvk/x64/dxgi.dll',
          '/runtime/linux-wine/dxvk/x64/d3d9.dll',
          '/runtime/linux-wine/dxvk/x64/d3d10core.dll',
          '/runtime/linux-wine/dxvk/x64/d3d11.dll',
          '/runtime/linux-wine/dxvk/x86/dxgi.dll',
          '/runtime/linux-wine/dxvk/x86/d3d9.dll',
          '/runtime/linux-wine/dxvk/x86/d3d10core.dll',
          '/runtime/linux-wine/dxvk/x86/d3d11.dll',
          '/runtime/linux-wine/vkd3d-proton/x64/d3d12.dll',
          '/runtime/linux-wine/vkd3d-proton/x64/d3d12core.dll',
          '/runtime/linux-wine/vkd3d-proton/x86/d3d12.dll',
          '/runtime/linux-wine/vkd3d-proton/x86/d3d12core.dll',
        }),
        runtimeStackVersionProbe: const EmptyRuntimeStackVersionProbe(),
      ),
      environment: environment,
      fileStatusProbe: const StaticFileStatusProbe({
        '/runtime/linux-wine',
        '/runtime/linux-wine/bin/wine',
      }),
      executableProbe: executableProbe,
    );

    final result = validator.validate('konyak-linux-wine');

    expect(result, isA<RuntimeValidationCompleted>());
    final validation = (result as RuntimeValidationCompleted).validation;
    expect(validation.isValid, isTrue);
    expect(executableProbe.lastExecutable, '/runtime/linux-wine/bin/wine');
    expect(executableProbe.lastArguments, ['--version']);
    expect(executableProbe.lastWorkingDirectory, '/runtime/linux-wine/bin');
    expect(executableProbe.lastEnvironment, {
      'PATH': '/runtime/linux-wine/bin:/usr/bin:/bin',
      'LD_LIBRARY_PATH': '/host-libs',
    });
  });

  test('macOS runtime validator runs wineloader with dylib search paths', () {
    final executableProbe = RecordingRuntimeExecutableProbe(
      result: const RuntimeExecutableProbeResult(
        exitCode: 0,
        stdout: 'wine-11.9',
        stderr: '',
      ),
    );
    final validator = DartIoMacosWineRuntimeValidator(
      runtimeCatalog: StaticRuntimeCatalog([
        RuntimeRecord(
          id: 'konyak-macos-wine',
          name: 'Konyak macOS Wine',
          platform: 'macos',
          architecture: 'x86_64',
          runnerKind: 'macosWine',
          isBundled: false,
          isUpdateable: true,
          libraryPath: Option.of('/runtime'),
          executablePath: Option.of('/runtime/bin/wineloader'),
          stack: Option.of(
            RuntimeStack(
              id: 'macos-konyak-runtime-stack',
              name: 'Konyak macOS runtime stack',
              compatibilityTarget: 'macos-konyak-runtime-stack',
              components: [
                RuntimeStackComponent(
                  id: 'wine',
                  name: 'Wine',
                  role: 'windows-runner',
                  isRequired: true,
                  paths: const ['/runtime/bin/wineloader'],
                  missingPaths: const [],
                ),
              ],
            ),
          ),
        ),
      ]),
      fileStatusProbe: const StaticFileStatusProbe({
        '/runtime',
        '/runtime/bin/wineloader',
        '/runtime/bin/wineserver',
        '/runtime/lib',
      }),
      executableProbe: executableProbe,
    );

    final result = validator.validate('konyak-macos-wine');

    expect(result, isA<RuntimeValidationCompleted>());
    final validation = (result as RuntimeValidationCompleted).validation;
    expect(validation.isValid, isTrue);
    expect(executableProbe.lastExecutable, '/runtime/bin/wineloader');
    expect(executableProbe.lastArguments, const ['--version']);
    expect(executableProbe.lastWorkingDirectory, '/runtime/bin');
    expect(
      executableProbe.lastEnvironment,
      containsPair('DYLD_LIBRARY_PATH', '/runtime/lib'),
    );
    expect(
      executableProbe.lastEnvironment,
      containsPair('WINELOADER', '/runtime/bin/wineloader'),
    );
    expect(
      executableProbe.lastEnvironment,
      containsPair('WINESERVER', '/runtime/bin/wineserver'),
    );
    expect(
      executableProbe.lastEnvironment,
      containsPair(
        'WINEDLLPATH',
        '/runtime/lib/wine/x86_64-windows:/runtime/lib/wine/i386-windows:/runtime/lib/wine',
      ),
    );
  });
}

File _writeMultiPlatformAppReleaseMetadata() {
  final tempDirectory = Directory.systemTemp.createTempSync(
    'konyak-app-release-metadata-test-',
  );
  addTearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  return File(_joinTestPath(tempDirectory.path, const ['release.json']))
    ..writeAsStringSync(
      jsonEncode(<String, Object?>{
        'tag_name': 'v1.1.0',
        'body': '''
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa  Konyak-1.1.0-macos-arm64.dmg
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb  Konyak-1.1.0-linux-x86_64.AppImage
''',
        'assets': [
          {
            'browser_download_url':
                'https://example.invalid/Konyak-1.1.0-linux-x86_64.AppImage',
          },
          {
            'browser_download_url':
                'https://example.invalid/Konyak-1.1.0-macos-arm64.dmg',
          },
        ],
      }),
    );
}
