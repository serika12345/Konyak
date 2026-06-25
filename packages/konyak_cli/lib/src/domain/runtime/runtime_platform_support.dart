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

const _linuxWineRuntimeBackendDefinitions = <_RuntimeBackendDefinition>[
  _RuntimeBackendDefinition(
    id: 'dxvk',
    name: 'DXVK',
    role: 'd3d9-d3d11-vulkan-translation',
    componentIds: <String>['dxvk'],
  ),
  _RuntimeBackendDefinition(
    id: 'vkd3d-proton',
    name: 'vkd3d-proton',
    role: 'd3d12-vulkan-translation',
    componentIds: <String>['vkd3d-proton'],
  ),
];

const _macosGptkD3DMetalComponentPaths = <List<String>>[
  <String>[
    'components',
    'gptk-d3dmetal',
    'lib',
    'external',
    'D3DMetal.framework',
  ],
  <String>[
    'components',
    'gptk-d3dmetal',
    'lib',
    'external',
    'libd3dshared.dylib',
  ],
  <String>[
    'components',
    'gptk-d3dmetal',
    'lib',
    'wine',
    'x86_64-windows',
    'atidxx64.dll',
  ],
  <String>[
    'components',
    'gptk-d3dmetal',
    'lib',
    'wine',
    'x86_64-windows',
    'd3d11.dll',
  ],
  <String>[
    'components',
    'gptk-d3dmetal',
    'lib',
    'wine',
    'x86_64-windows',
    'd3d12.dll',
  ],
  <String>[
    'components',
    'gptk-d3dmetal',
    'lib',
    'wine',
    'x86_64-windows',
    'dxgi.dll',
  ],
  <String>[
    'components',
    'gptk-d3dmetal',
    'lib',
    'wine',
    'x86_64-windows',
    'nvapi64.dll',
  ],
  <String>[
    'components',
    'gptk-d3dmetal',
    'lib',
    'wine',
    'x86_64-windows',
    'nvngx.dll',
  ],
  <String>[
    'components',
    'gptk-d3dmetal',
    'lib',
    'wine',
    'x86_64-unix',
    'atidxx64.so',
  ],
  <String>[
    'components',
    'gptk-d3dmetal',
    'lib',
    'wine',
    'x86_64-unix',
    'd3d11.so',
  ],
  <String>[
    'components',
    'gptk-d3dmetal',
    'lib',
    'wine',
    'x86_64-unix',
    'd3d12.so',
  ],
  <String>[
    'components',
    'gptk-d3dmetal',
    'lib',
    'wine',
    'x86_64-unix',
    'dxgi.so',
  ],
  <String>[
    'components',
    'gptk-d3dmetal',
    'lib',
    'wine',
    'x86_64-unix',
    'nvapi64.so',
  ],
  <String>[
    'components',
    'gptk-d3dmetal',
    'lib',
    'wine',
    'x86_64-unix',
    'nvngx.so',
  ],
];

const _macosWine32On64ComponentPaths = <List<String>>[
  <String>['lib', 'wine', 'i386-windows', 'ntdll.dll'],
  <String>['lib', 'wine', 'x86_64-windows', 'wow64.dll'],
  <String>['lib', 'wine', 'x86_64-windows', 'wow64cpu.dll'],
  <String>['lib', 'wine', 'x86_64-windows', 'wow64win.dll'],
  <String>['lib', 'wine', 'x86_64-unix', 'ntdll.so'],
];

const _macosWineEntryPointComponentPaths = <List<String>>[
  <String>['bin', 'wine'],
  <String>['bin', 'wineloader'],
  <String>['bin', 'wineserver'],
  <String>['Konyak Wine Hosted Application', 'wine'],
  <String>['Konyak Wine Hosted Application', 'wineloader'],
  <String>['Konyak Wine Hosted Application', 'wineserver'],
  <String>['lib', 'wine', 'x86_64-unix', 'wine'],
];

const _macosWineMonoComponentPaths = <List<String>>[
  <String>['share', 'wine', 'mono', 'wine-mono-10.4.1-x86.msi'],
];

const _macosWineGeckoComponentPaths = <List<String>>[
  <String>['share', 'wine', 'gecko', 'wine-gecko-2.47.4-x86.msi'],
  <String>['share', 'wine', 'gecko', 'wine-gecko-2.47.4-x86_64.msi'],
];

const _macosVkd3dComponentPaths = <List<String>>[
  <String>['lib', 'wine', 'x86_64-windows', 'libvkd3d-1.dll'],
  <String>['lib', 'wine', 'x86_64-windows', 'libvkd3d-shader-1.dll'],
  <String>['lib', 'wine', 'x86_64-windows', 'libvkd3d-utils-1.dll'],
  <String>['lib', 'wine', 'i386-windows', 'libvkd3d-1.dll'],
  <String>['lib', 'wine', 'i386-windows', 'libvkd3d-shader-1.dll'],
  <String>['lib', 'wine', 'i386-windows', 'libvkd3d-utils-1.dll'],
];

const _macosKonyakRuntimeComponentDefinitions =
    <_RuntimeStackComponentDefinition>[
      _RuntimeStackComponentDefinition(
        id: 'wine',
        name: 'Wine',
        role: 'windows-runner',
        isRequired: true,
        relativePaths: _macosWineEntryPointComponentPaths,
      ),
      _RuntimeStackComponentDefinition(
        id: 'wine32on64',
        name: 'Wine32-on-64 support',
        role: '32-bit-windows-support',
        isRequired: true,
        relativePaths: _macosWine32On64ComponentPaths,
      ),
      _RuntimeStackComponentDefinition(
        id: 'dxvk-macos',
        name: 'DXVK-macOS',
        role: 'd3d9-d3d11-translation',
        isRequired: true,
        relativePaths: <List<String>>[
          <String>['lib', 'dxvk', 'x86_64-windows', 'dxgi.dll'],
          <String>['lib', 'dxvk', 'x86_64-windows', 'd3d9.dll'],
          <String>['lib', 'dxvk', 'x86_64-windows', 'd3d10.dll'],
          <String>['lib', 'dxvk', 'x86_64-windows', 'd3d10_1.dll'],
          <String>['lib', 'dxvk', 'x86_64-windows', 'd3d10core.dll'],
          <String>['lib', 'dxvk', 'x86_64-windows', 'd3d11.dll'],
          <String>['lib', 'dxvk', 'i386-windows', 'dxgi.dll'],
          <String>['lib', 'dxvk', 'i386-windows', 'd3d9.dll'],
          <String>['lib', 'dxvk', 'i386-windows', 'd3d10.dll'],
          <String>['lib', 'dxvk', 'i386-windows', 'd3d10_1.dll'],
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
          <String>['lib', 'gstreamer-1.0', 'libgstcoreelements.dylib'],
          <String>['lib', 'gstreamer-1.0', 'libgstplayback.dylib'],
          <String>['lib', 'gstreamer-1.0', 'libgsttypefindfunctions.dylib'],
          <String>['lib', 'gstreamer-1.0', 'libgstisomp4.dylib'],
          <String>['lib', 'gstreamer-1.0', 'libgstwavparse.dylib'],
          <String>['lib', 'gstreamer-1.0', 'libgstapplemedia.dylib'],
          <String>['libexec', 'gstreamer-1.0', 'gst-plugin-scanner'],
        ],
      ),
      _RuntimeStackComponentDefinition(
        id: 'freetype',
        name: 'FreeType font runtime',
        role: 'font-rendering',
        isRequired: true,
        relativePaths: <List<String>>[
          <String>['lib', 'libfreetype.6.dylib'],
          <String>['lib', 'libfreetype.dylib'],
        ],
      ),
      _RuntimeStackComponentDefinition(
        id: 'wine-mono',
        name: 'wine-mono',
        role: 'dotnet-runtime',
        isRequired: true,
        relativePaths: _macosWineMonoComponentPaths,
      ),
      _RuntimeStackComponentDefinition(
        id: 'wine-gecko',
        name: 'wine-gecko',
        role: 'html-runtime',
        isRequired: true,
        relativePaths: _macosWineGeckoComponentPaths,
      ),
      _RuntimeStackComponentDefinition(
        id: 'winetricks',
        name: 'winetricks',
        role: 'verb-installer',
        isRequired: true,
        relativePaths: <List<String>>[
          <String>['winetricks'],
          <String>['verbs.txt'],
        ],
      ),
      _RuntimeStackComponentDefinition(
        id: 'vkd3d',
        name: 'vkd3d',
        role: 'd3d12-vulkan-runtime',
        isRequired: true,
        relativePaths: _macosVkd3dComponentPaths,
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
          <String>['lib', 'dxmt', 'x86_64-windows', 'winemetal.so'],
          <String>['lib', 'dxmt', 'x86_64-windows', 'nvapi64.dll'],
          <String>['lib', 'dxmt', 'x86_64-windows', 'nvngx.dll'],
          <String>['lib', 'dxmt', 'x86_64-unix', 'winemetal.so'],
        ],
      ),
      _RuntimeStackComponentDefinition(
        id: 'gptk-d3dmetal',
        name: 'GPTK/D3DMetal',
        role: 'd3d12-metal-translation',
        isRequired: false,
        relativePaths: _macosGptkD3DMetalComponentPaths,
      ),
    ];

const _macosKonyakRuntimeBackendDefinitions = <_RuntimeBackendDefinition>[
  _RuntimeBackendDefinition(
    id: 'dxvk-macos',
    name: 'DXVK-macOS',
    role: 'd3d9-d3d11-metal-translation',
    componentIds: <String>['dxvk-macos', 'moltenvk'],
  ),
  _RuntimeBackendDefinition(
    id: 'dxmt',
    name: 'DXMT',
    role: 'd3d10-d3d11-metal-translation',
    componentIds: <String>['dxmt'],
  ),
  _RuntimeBackendDefinition(
    id: 'vkd3d',
    name: 'vkd3d',
    role: 'd3d12-vulkan-metal-translation',
    componentIds: <String>['vkd3d', 'moltenvk'],
  ),
  _RuntimeBackendDefinition(
    id: 'gptk-d3dmetal',
    name: 'GPTK/D3DMetal',
    role: 'd3d12-metal-translation',
    componentIds: <String>['gptk-d3dmetal'],
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
  developmentSourceManifestEnvironmentKey:
      'KONYAK_DEV_LINUX_WINE_STACK_SOURCE_MANIFEST',
  releaseSourceManifestEnvironmentKey: 'KONYAK_LINUX_WINE_STACK_MANIFEST',
  developmentSourceSignatureEnvironmentKey:
      'KONYAK_DEV_LINUX_WINE_STACK_SIGNATURE_URL',
  releaseSourceSignatureEnvironmentKey: 'KONYAK_LINUX_WINE_STACK_SIGNATURE_URL',
  componentDefinitions: _linuxWineRuntimeComponentDefinitions,
  backendDefinitions: _linuxWineRuntimeBackendDefinitions,
);

const _macosKonyakRuntimePlatformSpec = _RuntimePlatformSpec(
  runtimeId: macosWineRuntimeId,
  runtimeName: 'Konyak macOS Wine',
  platform: 'macos',
  architecture: 'x86_64',
  runnerKind: 'macosWine',
  stackId: 'macos-konyak-runtime-stack',
  stackName: 'Konyak macOS runtime stack',
  requiredExecutableRelativePath: <String>['bin', 'wineloader'],
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
  backendDefinitions: _macosKonyakRuntimeBackendDefinitions,
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
