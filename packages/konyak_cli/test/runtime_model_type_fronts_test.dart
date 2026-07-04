import 'package:konyak_cli/src/io/runtime_source_manifest_support.dart';

import 'support/cli_contract_full_helpers.dart';

void main() {
  group('runtime model type fronts', () {
    test('runtime definition constructor accepts typed domain values', () {
      final definition = RuntimeDefinition(
        id: RuntimeId('konyak-linux-wine'),
        name: RuntimeName('Konyak Linux Wine'),
        platform: RuntimePlatformName('linux'),
        architecture: RuntimeArchitecture('x86_64'),
        runnerKind: RunnerKind.wine,
        isBundled: false,
        isUpdateable: true,
        distributionKind: Option.of(RuntimeDistributionKind('managed')),
        archiveUrl: Option.of(
          RuntimeArchiveUrl('https://example.invalid/linux-wine.tar.xz'),
        ),
        versionUrl: Option.of(
          RuntimeVersionUrl('https://example.invalid/releases/latest'),
        ),
      );

      expect(definition.id, RuntimeId('konyak-linux-wine'));
      expect(definition.name, RuntimeName('Konyak Linux Wine'));
      expect(definition.platform, RuntimePlatformName('linux'));
      expect(definition.architecture, RuntimeArchitecture('x86_64'));
      expect(definition.runnerKind, RunnerKind.wine);
      expect(
        definition.distributionKind.toNullable(),
        RuntimeDistributionKind('managed'),
      );
      expect(
        definition.archiveUrl.toNullable(),
        RuntimeArchiveUrl('https://example.invalid/linux-wine.tar.xz'),
      );
      expect(
        definition.versionUrl.toNullable(),
        RuntimeVersionUrl('https://example.invalid/releases/latest'),
      );
    });

    test('runtime stack constructors accept typed ids, roles, and paths', () {
      final component = RuntimeStackComponent(
        id: RuntimeComponentId('wine'),
        name: RuntimeName('Wine'),
        role: RuntimeRole('windows-runner'),
        isRequired: true,
        paths: [
          RuntimeComponentPath('/runtime/bin/wine'),
          RuntimeComponentPath('/runtime/bin/wineserver'),
        ],
        missingPaths: [RuntimeMissingPath('/runtime/bin/winedbg')],
        version: Option.of(RuntimeVersion('10.0')),
      );
      final backend = RuntimeStackBackend(
        id: RuntimeBackendId('dxvk'),
        name: RuntimeName('DXVK'),
        role: RuntimeRole('d3d9-d3d11-vulkan-translation'),
        componentIds: [RuntimeComponentId('dxvk')],
        missingComponentIds: [RuntimeComponentId('dxvk')],
        missingPaths: [RuntimeMissingPath('/runtime/dxvk/x64/dxgi.dll')],
      );
      final stack = RuntimeStack(
        id: RuntimeStackId('linux-wine-runtime-stack'),
        name: RuntimeStackName('Linux Wine/Proton runtime stack'),
        compatibilityTarget: RuntimeCompatibilityTarget(
          'linux-wine-runtime-stack',
        ),
        components: [component],
        backends: [backend],
      );

      expect(component.id, RuntimeComponentId('wine'));
      expect(component.paths, [
        RuntimeComponentPath('/runtime/bin/wine'),
        RuntimeComponentPath('/runtime/bin/wineserver'),
      ]);
      expect(component.missingPaths, [
        RuntimeMissingPath('/runtime/bin/winedbg'),
      ]);
      expect(component.version.toNullable(), RuntimeVersion('10.0'));
      expect(backend.componentIds, [RuntimeComponentId('dxvk')]);
      expect(backend.missingComponentIds, [RuntimeComponentId('dxvk')]);
      expect(stack.id, RuntimeStackId('linux-wine-runtime-stack'));
      expect(stack.isComplete, isFalse);
    });

    test('runtime record JSON preserves public schema strings', () {
      final runtime = RuntimeRecord(
        id: RuntimeId('konyak-linux-wine'),
        name: RuntimeName('Konyak Linux Wine'),
        platform: RuntimePlatformName('linux'),
        architecture: RuntimeArchitecture('x86_64'),
        runnerKind: RunnerKind.wine,
        isBundled: false,
        isUpdateable: true,
        distributionKind: Option.of(RuntimeDistributionKind('managed')),
        isInstalled: Option.of(true),
        libraryPath: Option.of(RuntimeComponentPath('/runtime')),
        executablePath: Option.of(RuntimeComponentPath('/runtime/bin/wine')),
        archiveUrl: Option.of(
          RuntimeArchiveUrl('https://example.invalid/linux-wine.tar.xz'),
        ),
        versionUrl: Option.of(
          RuntimeVersionUrl('https://example.invalid/releases/latest'),
        ),
        stack: Option.of(
          RuntimeStack(
            id: RuntimeStackId('linux-wine-runtime-stack'),
            name: RuntimeStackName('Linux Wine/Proton runtime stack'),
            compatibilityTarget: RuntimeCompatibilityTarget(
              'linux-wine-runtime-stack',
            ),
            components: [
              RuntimeStackComponent(
                id: RuntimeComponentId('wine'),
                name: RuntimeName('Wine'),
                role: RuntimeRole('windows-runner'),
                isRequired: true,
                paths: [RuntimeComponentPath('/runtime/bin/wine')],
                missingPaths: const <RuntimeMissingPath>[],
              ),
            ],
          ),
        ),
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
        'libraryPath': '/runtime',
        'executablePath': '/runtime/bin/wine',
        'stack': {
          'schemaVersion': runtimeStackSchemaVersion,
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
              'paths': ['/runtime/bin/wine'],
              'missingPaths': <Object?>[],
            },
          ],
        },
      });
    });

    test('source manifest parser remains the primitive adapter boundary', () {
      final payload = jsonEncode({
        'schemaVersion': runtimeStackSchemaVersion,
        'runtimeId': 'konyak-linux-wine',
        'stackId': 'linux-wine-runtime-stack',
        'components': [
          {
            'id': 'wine',
            'version': '10.0',
            'archiveUrl': 'https://example.invalid/wine.tar.xz',
            'sha256':
                '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
          },
        ],
      });

      final manifest = runtimeStackSourceManifestFromPayload(
        payload,
      ).toNullable();
      final component = manifest
          ?.componentById(RuntimeSourceComponentId('wine'))
          .toNullable();

      expect(manifest?.runtimeId, RuntimeId('konyak-linux-wine'));
      expect(manifest?.stackId, RuntimeStackId('linux-wine-runtime-stack'));
      expect(component?.id, RuntimeSourceComponentId('wine'));
      expect(component?.version, RuntimeSourceComponentVersion('10.0'));
      expect(
        component?.archiveUrl,
        RuntimeArchiveUrl('https://example.invalid/wine.tar.xz'),
      );
      expect(
        component?.sha256,
        RuntimeArchiveChecksumValue(
          '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
        ),
      );
    });
  });
}
