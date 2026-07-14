import 'support/cli_contract_full_helpers.dart';

void main() {
  group('runtime platform definition type fronts', () {
    test('platform catalog stores stable identities as value objects', () {
      final linux = linuxWineRuntimePlatformSpec;
      final macos = macosKonyakRuntimePlatformSpec;

      expect(linux.runtimeId, RuntimeId(linuxWineRuntimeId));
      expect(linux.runtimeName, RuntimeName('Konyak Linux Wine'));
      expect(linux.platform, RuntimePlatformName('linux'));
      expect(linux.architecture, RuntimeArchitecture('x86_64'));
      expect(linux.runnerKind, RunnerKind.wine);
      expect(linux.stackId, RuntimeStackId('linux-wine-runtime-stack'));
      expect(
        linux.stackName,
        RuntimeStackName('Linux Wine/Proton runtime stack'),
      );
      expect(
        linux.requiredExecutableRelativePath,
        RuntimeRelativePath(['bin', 'wine']),
      );
      expect(
        linux.defaultArchiveFileName,
        RuntimeArchivePath('linux-wine.tar.xz'),
      );
      expect(
        linux.developmentSourceManifestEnvironmentKey,
        ProgramEnvironmentVariableName(
          'KONYAK_DEV_LINUX_WINE_STACK_SOURCE_MANIFEST',
        ),
      );
      expect(
        linux.releaseSourceManifestEnvironmentKey,
        ProgramEnvironmentVariableName('KONYAK_LINUX_WINE_STACK_MANIFEST'),
      );
      expect(linux.defaultSourceManifestUrl.isNone(), isTrue);

      expect(macos.runtimeId, RuntimeId(macosWineRuntimeId));
      expect(macos.platform, RuntimePlatformName('macos'));
      expect(macos.runnerKind, RunnerKind.macosWine);
      expect(
        macos.defaultSourceManifestUrl.toNullable(),
        RuntimeSourceManifestUrl(macosWineRuntimeSourceManifestUrl),
      );
    });

    test('development macOS manifest falls back to the platform default', () {
      final environments = [
        HostEnvironment({'KONYAK_RUNTIME_PROFILE': 'development'}),
        HostEnvironment({
          'KONYAK_RUNTIME_PROFILE': 'development',
          'KONYAK_DEV_MACOS_WINE_STACK_MANIFEST': '   ',
        }),
      ];

      final manifests = environments.map(
        (environment) => runtimeSourceManifestForPlatform(
          platformSpec: macosKonyakRuntimePlatformSpec,
          environment: environment,
        ).toNullable(),
      );

      expect(
        manifests,
        everyElement(
          RuntimeSourceManifestUrl(macosWineRuntimeSourceManifestUrl),
        ),
      );
    });

    test('development macOS manifest override has highest priority', () {
      final configuredManifest = runtimeSourceManifestForPlatform(
        platformSpec: macosKonyakRuntimePlatformSpec,
        environment: HostEnvironment({
          'KONYAK_RUNTIME_PROFILE': 'development',
          'KONYAK_DEV_MACOS_WINE_STACK_MANIFEST':
              ' \thttps://example.invalid/rollback-source.json\n ',
        }),
      );

      expect(
        configuredManifest.toNullable(),
        RuntimeSourceManifestUrl(
          'https://example.invalid/rollback-source.json',
        ),
      );
    });

    test('component and backend catalogs store typed ids and paths', () {
      final linuxWine = linuxWineRuntimePlatformSpec.componentDefinitions.first;
      final linuxDxvk = linuxWineRuntimePlatformSpec.backendDefinitions.first;
      final macosGptk = macosKonyakRuntimePlatformSpec.componentDefinitions
          .where(
            (definition) =>
                definition.id == RuntimeComponentId('gptk-d3dmetal'),
          )
          .single;
      final macosDxmt = macosKonyakRuntimePlatformSpec.backendDefinitions
          .where((definition) => definition.id == RuntimeBackendId('dxmt'))
          .single;

      expect(linuxWine.id, RuntimeComponentId('wine'));
      expect(linuxWine.name, RuntimeName('Wine'));
      expect(linuxWine.role, RuntimeRole('windows-runner'));
      expect(linuxWine.relativePaths, [
        RuntimeRelativePath(['bin', 'wine']),
        RuntimeRelativePath(['bin', 'winedbg']),
        RuntimeRelativePath(['bin', 'wineserver']),
      ]);

      expect(linuxDxvk.id, RuntimeBackendId('dxvk'));
      expect(linuxDxvk.name, RuntimeName('DXVK'));
      expect(linuxDxvk.role, RuntimeRole('d3d9-d3d11-vulkan-translation'));
      expect(linuxDxvk.componentIds, [RuntimeComponentId('dxvk')]);

      expect(macosGptk.id, RuntimeComponentId('gptk-d3dmetal'));
      expect(
        macosGptk.relativePaths.first,
        RuntimeRelativePath([
          'components',
          'gptk-d3dmetal',
          'lib',
          'external',
          'D3DMetal.framework',
        ]),
      );
      expect(
        macosGptk.relativePaths,
        isNot(
          contains(
            RuntimeRelativePath([
              'components',
              'gptk-d3dmetal',
              'lib',
              'wine',
              'x86_64-windows',
              'd3d10.dll',
            ]),
          ),
        ),
      );
      expect(
        macosGptk.relativePaths,
        isNot(
          contains(
            RuntimeRelativePath([
              'components',
              'gptk-d3dmetal',
              'lib',
              'wine',
              'x86_64-unix',
              'd3d10.so',
            ]),
          ),
        ),
      );
      expect(
        macosGptk.relativePaths,
        isNot(
          contains(
            RuntimeRelativePath([
              'components',
              'gptk-d3dmetal',
              'lib',
              'wine',
              'x86_64-windows',
              'atidxx64.dll',
            ]),
          ),
        ),
      );
      expect(
        macosGptk.relativePaths,
        isNot(
          contains(
            RuntimeRelativePath([
              'components',
              'gptk-d3dmetal',
              'lib',
              'wine',
              'x86_64-unix',
              'atidxx64.so',
            ]),
          ),
        ),
      );
      expect(macosDxmt.role, RuntimeRole('d3d11-metal-translation'));
    });

    test('source manifest planning still accepts public manifest strings', () {
      final result = runtimeStackSourceArchivePlan(
        manifest: RuntimeSourceManifest(
          runtimeId: RuntimeId(linuxWineRuntimeId),
          stackId: RuntimeStackId('linux-wine-runtime-stack'),
          components: [
            RuntimeSourceComponent(
              id: RuntimeSourceComponentId('wine'),
              version: RuntimeSourceComponentVersion('1.0.0'),
              archiveUrl: RuntimeArchiveUrl(
                'https://example.invalid/wine.tar.xz',
              ),
              sha256: RuntimeArchiveChecksumValue('wine-digest'),
            ),
          ],
        ),
        platformSpec: linuxWineRuntimePlatformSpec,
        tempDirectoryPath: '/tmp/konyak-runtime',
      );

      expect(result, isA<RuntimeStackSourceArchivePlanResolved>());
      final resolved = result as RuntimeStackSourceArchivePlanResolved;
      expect(resolved.plan.wineComponent.id, RuntimeSourceComponentId('wine'));
      expect(
        resolved.plan.components.single.archivePath,
        RuntimeArchivePath('/tmp/konyak-runtime/0-wine.tar.xz'),
      );
    });

    test('list-runtimes JSON preserves public schema strings', () {
      final result = runCli(
        const ['list-runtimes', '--json'],
        runtimeCatalog: KonyakRuntimeCatalog(
          hostPlatform: KonyakHostPlatform.linux,
          environment: HostEnvironment(const {'HOME': '/home/user'}),
          fileStatusProbe: const StaticFileStatusProbe({}),
          runtimeStackVersionProbe: const EmptyRuntimeStackVersionProbe(),
        ),
      );

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);

      final payload = jsonDecode(result.stdout) as Map<String, Object?>;
      final runtimes = payload['runtimes'] as List<Object?>;
      final runtime = runtimes.single as Map<String, Object?>;
      final stack = runtime['stack'] as Map<String, Object?>;
      final components = stack['components'] as List<Object?>;
      final wineComponent = components.first as Map<String, Object?>;

      expect(runtime['id'], linuxWineRuntimeId);
      expect(runtime['name'], 'Konyak Linux Wine');
      expect(runtime['platform'], 'linux');
      expect(runtime['architecture'], 'x86_64');
      expect(runtime['runnerKind'], 'wine');
      expect(stack['id'], 'linux-wine-runtime-stack');
      expect(wineComponent['id'], 'wine');
      expect(wineComponent['role'], 'windows-runner');
    });
  });
}
