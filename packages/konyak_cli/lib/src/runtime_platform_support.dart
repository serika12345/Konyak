part of '../konyak_cli.dart';

const _linuxWineRuntimeComponentDefinitions =
    <_RuntimeStackComponentDefinition>[
      _RuntimeStackComponentDefinition(
        id: 'wine',
        name: 'Wine',
        role: 'windows-runner',
        isRequired: true,
        relativePaths: <List<String>>[
          <String>['bin', 'wine'],
          <String>['bin', 'winedbg'],
          <String>['bin', 'wineserver'],
        ],
      ),
      _RuntimeStackComponentDefinition(
        id: 'winetricks',
        name: 'winetricks',
        role: 'verb-installer',
        isRequired: true,
        relativePaths: <List<String>>[
          <String>['winetricks'],
        ],
      ),
      _RuntimeStackComponentDefinition(
        id: 'wine-mono',
        name: 'wine-mono',
        role: 'dotnet-runtime',
        isRequired: true,
        relativePaths: <List<String>>[
          <String>['share', 'wine', 'mono'],
        ],
      ),
      _RuntimeStackComponentDefinition(
        id: 'dxvk',
        name: 'DXVK',
        role: 'd3d9-d3d11-vulkan-translation',
        isRequired: true,
        relativePaths: <List<String>>[
          <String>['dxvk', 'x64', 'dxgi.dll'],
          <String>['dxvk', 'x64', 'd3d9.dll'],
          <String>['dxvk', 'x64', 'd3d10core.dll'],
          <String>['dxvk', 'x64', 'd3d11.dll'],
          <String>['dxvk', 'x86', 'dxgi.dll'],
          <String>['dxvk', 'x86', 'd3d9.dll'],
          <String>['dxvk', 'x86', 'd3d10core.dll'],
          <String>['dxvk', 'x86', 'd3d11.dll'],
        ],
      ),
      _RuntimeStackComponentDefinition(
        id: 'vkd3d-proton',
        name: 'vkd3d-proton',
        role: 'd3d12-vulkan-translation',
        isRequired: true,
        relativePaths: <List<String>>[
          <String>['vkd3d-proton', 'x64', 'd3d12.dll'],
          <String>['vkd3d-proton', 'x64', 'd3d12core.dll'],
          <String>['vkd3d-proton', 'x86', 'd3d12.dll'],
          <String>['vkd3d-proton', 'x86', 'd3d12core.dll'],
        ],
      ),
    ];

const _macosKonyakRuntimeComponentDefinitions =
    <_RuntimeStackComponentDefinition>[
      _RuntimeStackComponentDefinition(
        id: 'wine',
        name: 'Wine',
        role: 'windows-runner',
        isRequired: true,
        relativePaths: <List<String>>[
          <String>['bin', 'wine64'],
          <String>['bin', 'wineserver'],
        ],
      ),
      _RuntimeStackComponentDefinition(
        id: 'wine32on64',
        name: 'Wine32-on-64 support',
        role: '32-bit-windows-support',
        isRequired: true,
        relativePaths: <List<String>>[
          <String>['bin', 'wine'],
        ],
      ),
      _RuntimeStackComponentDefinition(
        id: 'dxvk-macos',
        name: 'DXVK-macOS',
        role: 'd3d9-d3d11-translation',
        isRequired: true,
        relativePaths: <List<String>>[
          <String>['DXVK', 'x64', 'dxgi.dll'],
          <String>['DXVK', 'x64', 'd3d9.dll'],
          <String>['DXVK', 'x64', 'd3d10core.dll'],
          <String>['DXVK', 'x64', 'd3d11.dll'],
          <String>['DXVK', 'x32', 'dxgi.dll'],
          <String>['DXVK', 'x32', 'd3d9.dll'],
          <String>['DXVK', 'x32', 'd3d10core.dll'],
          <String>['DXVK', 'x32', 'd3d11.dll'],
        ],
      ),
      _RuntimeStackComponentDefinition(
        id: 'moltenvk',
        name: 'MoltenVK',
        role: 'vulkan-metal-translation',
        isRequired: true,
        relativePaths: <List<String>>[
          <String>['lib', 'libMoltenVK.dylib'],
        ],
      ),
      _RuntimeStackComponentDefinition(
        id: 'gstreamer',
        name: 'GStreamer runtime',
        role: 'media-runtime',
        isRequired: true,
        relativePaths: <List<String>>[
          <String>['lib', 'libgstreamer-1.0.0.dylib'],
        ],
      ),
      _RuntimeStackComponentDefinition(
        id: 'wine-mono',
        name: 'wine-mono',
        role: 'dotnet-runtime',
        isRequired: true,
        relativePaths: <List<String>>[
          <String>['share', 'wine', 'mono'],
        ],
      ),
      _RuntimeStackComponentDefinition(
        id: 'winetricks',
        name: 'winetricks',
        role: 'verb-installer',
        isRequired: true,
        relativePaths: <List<String>>[
          <String>['winetricks'],
        ],
      ),
      _RuntimeStackComponentDefinition(
        id: 'gptk-d3dmetal',
        name: 'GPTK/D3DMetal',
        role: 'd3d12-metal-translation',
        isRequired: false,
        relativePaths: <List<String>>[
          <String>['lib', 'external', 'D3DMetal.framework'],
          <String>['lib', 'external', 'libd3dshared.dylib'],
          <String>['lib', 'wine', 'x86_64-windows', 'd3d12.dll'],
          <String>['lib', 'wine', 'x86_64-windows', 'dxgi.dll'],
        ],
      ),
    ];

const _linuxWineRuntimePlatformSpec = _RuntimePlatformSpec(
  runtimeId: linuxWineRuntimeId,
  runtimeName: 'Konyak Linux Wine',
  platform: 'linux',
  architecture: 'x86_64',
  runnerKind: 'wine',
  stackId: 'linux-wine-runtime-stack',
  stackName: 'Linux Wine/Proton runtime stack',
  requiredExecutableRelativePath: <String>['bin', 'wine'],
  defaultArchiveFileName: 'linux-wine.tar.xz',
  archiveUrlEnvironmentKey: 'KONYAK_LINUX_WINE_ARCHIVE_URL',
  developmentSourceManifestEnvironmentKey:
      'KONYAK_DEV_LINUX_WINE_STACK_MANIFEST',
  releaseSourceManifestEnvironmentKey: 'KONYAK_LINUX_WINE_STACK_MANIFEST',
  developmentSourceSignatureEnvironmentKey:
      'KONYAK_DEV_LINUX_WINE_STACK_SIGNATURE_URL',
  releaseSourceSignatureEnvironmentKey: 'KONYAK_LINUX_WINE_STACK_SIGNATURE_URL',
  componentDefinitions: _linuxWineRuntimeComponentDefinitions,
);

const _macosKonyakRuntimePlatformSpec = _RuntimePlatformSpec(
  runtimeId: macosWineRuntimeId,
  runtimeName: 'Konyak macOS Wine',
  platform: 'macos',
  architecture: 'x86_64',
  runnerKind: 'macosWine',
  stackId: 'macos-konyak-runtime-stack',
  stackName: 'Konyak macOS runtime stack',
  requiredExecutableRelativePath: <String>['bin', 'wine64'],
  defaultArchiveUrl: macosWineArchiveUrl,
  defaultArchiveFileName: macosWineArchiveFileName,
  developmentSourceManifestEnvironmentKey:
      'KONYAK_DEV_MACOS_WINE_STACK_MANIFEST',
  releaseSourceManifestEnvironmentKey: 'KONYAK_MACOS_WINE_STACK_MANIFEST',
  developmentSourceSignatureEnvironmentKey:
      'KONYAK_DEV_MACOS_WINE_STACK_SIGNATURE_URL',
  releaseSourceSignatureEnvironmentKey: 'KONYAK_MACOS_WINE_STACK_SIGNATURE_URL',
  layoutNormalization: _RuntimeLayoutNormalization.macosWineBundle,
  componentDefinitions: _macosKonyakRuntimeComponentDefinitions,
);

String? _runtimeSourceManifestForPlatform({
  required _RuntimePlatformSpec platformSpec,
  required Map<String, String> environment,
}) {
  return _runtimeProfileEnvironmentValue(
    environment,
    developmentKey: platformSpec.developmentSourceManifestEnvironmentKey,
    releaseKey: platformSpec.releaseSourceManifestEnvironmentKey,
  );
}

String? _runtimeSourceManifestSignatureForPlatform({
  required _RuntimePlatformSpec platformSpec,
  required Map<String, String> environment,
}) {
  return _runtimeProfileEnvironmentValue(
    environment,
    developmentKey: platformSpec.developmentSourceSignatureEnvironmentKey,
    releaseKey: platformSpec.releaseSourceSignatureEnvironmentKey,
  );
}

String? _runtimeDefaultArchiveUrl({
  required _RuntimePlatformSpec platformSpec,
  required Map<String, String> environment,
}) {
  final archiveUrlEnvironmentKey = platformSpec.archiveUrlEnvironmentKey;
  if (archiveUrlEnvironmentKey != null) {
    return _nonEmptyEnvironmentValue(environment, archiveUrlEnvironmentKey);
  }

  return platformSpec.defaultArchiveUrl;
}

RuntimeRecord _macosWineRuntimeRecord({
  required Map<String, String> environment,
  required FileStatusProbe fileStatusProbe,
  required RuntimeStackVersionProbe runtimeStackVersionProbe,
}) {
  const platformSpec = _macosKonyakRuntimePlatformSpec;
  final applicationSupportPath = _konyakApplicationSupportFolder(environment);
  final libraryPath = _macosWineRuntimeRoot(environment);
  final executablePath = _macosWineExecutable(environment);
  final isInstalled = fileStatusProbe.exists(executablePath);

  return RuntimeRecord.fromParts(
    definition: RuntimeDefinition(
      id: platformSpec.runtimeId,
      name: platformSpec.runtimeName,
      platform: platformSpec.platform,
      architecture: platformSpec.architecture,
      runnerKind: platformSpec.runnerKind,
      isBundled: false,
      isUpdateable: true,
      distributionKind: _runtimeDistributionKind(environment, 'bootstrap'),
      archiveUrl: platformSpec.defaultArchiveUrl,
      versionUrl: macosWineVersionUrl,
    ),
    installedState: InstalledRuntimeState(
      isInstalled: isInstalled,
      applicationSupportPath: applicationSupportPath,
      libraryPath: libraryPath,
      executablePath: executablePath,
    ),
    capabilities: RuntimeCapabilities(
      stack: _runtimeStackForPlatform(
        platformSpec: platformSpec,
        runtimeRoot: libraryPath,
        fileStatusProbe: fileStatusProbe,
        runtimeStackVersionProbe: runtimeStackVersionProbe,
      ),
    ),
  );
}

RuntimeRecord _linuxWineRuntimeRecord({
  required Map<String, String> environment,
  required FileStatusProbe fileStatusProbe,
  required RuntimeStackVersionProbe runtimeStackVersionProbe,
}) {
  const platformSpec = _linuxWineRuntimePlatformSpec;
  final runtimeRoot = _linuxWineRuntimeRoot(environment);
  final executablePath = _joinPath(runtimeRoot, const ['bin', 'wine']);
  final archiveUrl = _runtimeDefaultArchiveUrl(
    platformSpec: platformSpec,
    environment: environment,
  );
  final versionUrl = _nonEmptyEnvironmentValue(
    environment,
    'KONYAK_LINUX_WINE_VERSION_URL',
  );
  return RuntimeRecord.fromParts(
    definition: RuntimeDefinition(
      id: platformSpec.runtimeId,
      name: platformSpec.runtimeName,
      platform: platformSpec.platform,
      architecture: platformSpec.architecture,
      runnerKind: platformSpec.runnerKind,
      isBundled: false,
      isUpdateable: archiveUrl != null || versionUrl != null,
      distributionKind: _runtimeDistributionKind(environment, 'managed'),
      archiveUrl: archiveUrl,
      versionUrl: versionUrl,
    ),
    installedState: InstalledRuntimeState(
      isInstalled: fileStatusProbe.exists(executablePath),
      libraryPath: runtimeRoot,
      executablePath: executablePath,
    ),
    capabilities: RuntimeCapabilities(
      stack: _runtimeStackForPlatform(
        platformSpec: platformSpec,
        runtimeRoot: runtimeRoot,
        fileStatusProbe: fileStatusProbe,
        runtimeStackVersionProbe: runtimeStackVersionProbe,
      ),
    ),
  );
}

RuntimeStack _runtimeStackForPlatform({
  required _RuntimePlatformSpec platformSpec,
  required String runtimeRoot,
  required FileStatusProbe fileStatusProbe,
  required RuntimeStackVersionProbe runtimeStackVersionProbe,
}) {
  return RuntimeStack(
    id: platformSpec.stackId,
    name: platformSpec.stackName,
    compatibilityTarget: platformSpec.stackId,
    components: platformSpec.componentDefinitions
        .map(
          (definition) => _runtimeStackComponent(
            runtimeRoot: runtimeRoot,
            fileStatusProbe: fileStatusProbe,
            runtimeStackVersionProbe: runtimeStackVersionProbe,
            definition: definition,
          ),
        )
        .toList(growable: false),
  );
}

RuntimeStackComponent _runtimeStackComponent({
  required String runtimeRoot,
  required FileStatusProbe fileStatusProbe,
  required RuntimeStackVersionProbe runtimeStackVersionProbe,
  required _RuntimeStackComponentDefinition definition,
}) {
  final paths = definition.relativePaths
      .map((pathSegments) => _joinPath(runtimeRoot, pathSegments))
      .toList(growable: false);
  final missingPaths = paths
      .where((path) => !fileStatusProbe.exists(path))
      .toList();
  if (definition.id == 'gptk-d3dmetal') {
    final frameworkBinary = _d3dMetalFrameworkBinary(paths.first);
    if (frameworkBinary == null || !_looksLikeMachO(File(frameworkBinary))) {
      if (!missingPaths.contains(paths.first)) {
        missingPaths.add(paths.first);
      }
    }
    if (!_looksLikeMachO(File(paths[1]))) {
      if (!missingPaths.contains(paths[1])) {
        missingPaths.add(paths[1]);
      }
    }
  }

  return RuntimeStackComponent(
    id: definition.id,
    name: definition.name,
    role: definition.role,
    isRequired: definition.isRequired,
    paths: paths,
    missingPaths: missingPaths,
    version: missingPaths.isEmpty
        ? runtimeStackVersionProbe.versionFor(
            runtimeRoot: runtimeRoot,
            componentId: definition.id,
          )
        : null,
  );
}
