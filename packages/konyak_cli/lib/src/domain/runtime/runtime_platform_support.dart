part of '../../../konyak_cli.dart';

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

const _macosGptkD3DMetalComponentPaths = <List<String>>[
  <String>['lib', 'external', 'D3DMetal.framework'],
  <String>['lib', 'external', 'libd3dshared.dylib'],
  <String>['lib', 'wine', 'x86_64-windows', 'atidxx64.dll'],
  <String>['lib', 'wine', 'x86_64-windows', 'd3d10.dll'],
  <String>['lib', 'wine', 'x86_64-windows', 'd3d11.dll'],
  <String>['lib', 'wine', 'x86_64-windows', 'd3d12.dll'],
  <String>['lib', 'wine', 'x86_64-windows', 'dxgi.dll'],
  <String>['lib', 'wine', 'x86_64-windows', 'nvapi64.dll'],
  <String>['lib', 'wine', 'x86_64-windows', 'nvngx-on-metalfx.dll'],
  <String>['lib', 'wine', 'x86_64-unix', 'atidxx64.so'],
  <String>['lib', 'wine', 'x86_64-unix', 'd3d10.so'],
  <String>['lib', 'wine', 'x86_64-unix', 'd3d11.so'],
  <String>['lib', 'wine', 'x86_64-unix', 'd3d12.so'],
  <String>['lib', 'wine', 'x86_64-unix', 'dxgi.so'],
  <String>['lib', 'wine', 'x86_64-unix', 'nvapi64.so'],
  <String>['lib', 'wine', 'x86_64-unix', 'nvngx-on-metalfx.so'],
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
          <String>['lib', 'dxvk', 'x86_64-windows', 'dxgi.dll'],
          <String>['lib', 'dxvk', 'x86_64-windows', 'd3d9.dll'],
          <String>['lib', 'dxvk', 'x86_64-windows', 'd3d10core.dll'],
          <String>['lib', 'dxvk', 'x86_64-windows', 'd3d11.dll'],
          <String>['lib', 'dxvk', 'i386-windows', 'dxgi.dll'],
          <String>['lib', 'dxvk', 'i386-windows', 'd3d9.dll'],
          <String>['lib', 'dxvk', 'i386-windows', 'd3d10core.dll'],
          <String>['lib', 'dxvk', 'i386-windows', 'd3d11.dll'],
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
        id: 'freetype',
        name: 'FreeType font runtime',
        role: 'font-rendering',
        isRequired: true,
        relativePaths: <List<String>>[
          <String>['lib', 'libfreetype.6.dylib'],
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
        relativePaths: _macosGptkD3DMetalComponentPaths,
      ),
      _RuntimeStackComponentDefinition(
        id: 'dxmt',
        name: 'DXMT',
        role: 'd3d10-d3d11-metal-translation',
        isRequired: true,
        relativePaths: <List<String>>[
          <String>['lib', 'dxmt', 'x86_64-windows', 'd3d10core.dll'],
          <String>['lib', 'dxmt', 'x86_64-windows', 'd3d11.dll'],
          <String>['lib', 'dxmt', 'x86_64-windows', 'dxgi.dll'],
          <String>['lib', 'dxmt', 'x86_64-windows', 'winemetal.dll'],
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
  archiveUrlEnvironmentKey: Option.of('KONYAK_LINUX_WINE_ARCHIVE_URL'),
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
  defaultSourceManifestUrl: Option.of(macosWineRuntimeSourceManifestUrl),
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

Option<String> _runtimeSourceManifestForPlatform({
  required _RuntimePlatformSpec platformSpec,
  required HostEnvironment environment,
}) {
  final configuredManifest = _runtimeProfileEnvironmentValue(
    environment,
    developmentKey: platformSpec.developmentSourceManifestEnvironmentKey,
    releaseKey: platformSpec.releaseSourceManifestEnvironmentKey,
  );
  if (_isDevelopmentRuntimeProfile(environment)) {
    return configuredManifest;
  }

  return configuredManifest.alt(() => platformSpec.defaultSourceManifestUrl);
}

Option<String> _runtimeSourceManifestSignatureForPlatform({
  required _RuntimePlatformSpec platformSpec,
  required HostEnvironment environment,
}) {
  return _runtimeProfileEnvironmentValue(
    environment,
    developmentKey: platformSpec.developmentSourceSignatureEnvironmentKey,
    releaseKey: platformSpec.releaseSourceSignatureEnvironmentKey,
  );
}

Option<String> _runtimeDefaultArchiveUrl({
  required _RuntimePlatformSpec platformSpec,
  required HostEnvironment environment,
}) {
  return platformSpec.archiveUrlEnvironmentKey.match(
    () => const Option.none(),
    (archiveUrlEnvironmentKey) => Option.fromNullable(
      environment.nonEmptyValue(archiveUrlEnvironmentKey),
    ),
  );
}
