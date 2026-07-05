import 'package:fpdart/fpdart.dart';

import '../../shared/model_constants.dart';
import '../shared/domain_value_objects.dart';
import 'host_environment.dart';
import 'runtime_profile_environment.dart';
import 'runtime_validation_models.dart';

List<RuntimeRelativePath> _runtimeRelativePaths(List<List<String>> paths) {
  return paths.map(RuntimeRelativePath.new).toList(growable: false);
}

List<RuntimeComponentId> _runtimeComponentIds(List<String> ids) {
  return ids.map(RuntimeComponentId.new).toList(growable: false);
}

final _linuxWineRuntimeComponentDefinitions = <RuntimeStackComponentDefinition>[
  RuntimeStackComponentDefinition(
    id: RuntimeComponentId('wine'),
    name: RuntimeName('Wine'),
    role: RuntimeRole('windows-runner'),
    isRequired: true,
    relativePaths: _runtimeRelativePaths(const <List<String>>[
      <String>['bin', 'wine'],
      <String>['bin', 'winedbg'],
      <String>['bin', 'wineserver'],
    ]),
  ),
  RuntimeStackComponentDefinition(
    id: RuntimeComponentId('winetricks'),
    name: RuntimeName('winetricks'),
    role: RuntimeRole('verb-installer'),
    isRequired: true,
    relativePaths: _runtimeRelativePaths(const <List<String>>[
      <String>['winetricks'],
    ]),
  ),
  RuntimeStackComponentDefinition(
    id: RuntimeComponentId('wine-mono'),
    name: RuntimeName('wine-mono'),
    role: RuntimeRole('dotnet-runtime'),
    isRequired: true,
    relativePaths: _runtimeRelativePaths(const <List<String>>[
      <String>['share', 'wine', 'mono'],
    ]),
  ),
  RuntimeStackComponentDefinition(
    id: RuntimeComponentId('dxvk'),
    name: RuntimeName('DXVK'),
    role: RuntimeRole('d3d9-d3d11-vulkan-translation'),
    isRequired: true,
    relativePaths: _runtimeRelativePaths(const <List<String>>[
      <String>['dxvk', 'x64', 'dxgi.dll'],
      <String>['dxvk', 'x64', 'd3d9.dll'],
      <String>['dxvk', 'x64', 'd3d10core.dll'],
      <String>['dxvk', 'x64', 'd3d11.dll'],
      <String>['dxvk', 'x86', 'dxgi.dll'],
      <String>['dxvk', 'x86', 'd3d9.dll'],
      <String>['dxvk', 'x86', 'd3d10core.dll'],
      <String>['dxvk', 'x86', 'd3d11.dll'],
    ]),
  ),
  RuntimeStackComponentDefinition(
    id: RuntimeComponentId('vkd3d-proton'),
    name: RuntimeName('vkd3d-proton'),
    role: RuntimeRole('d3d12-vulkan-translation'),
    isRequired: true,
    relativePaths: _runtimeRelativePaths(const <List<String>>[
      <String>['vkd3d-proton', 'x64', 'd3d12.dll'],
      <String>['vkd3d-proton', 'x64', 'd3d12core.dll'],
      <String>['vkd3d-proton', 'x86', 'd3d12.dll'],
      <String>['vkd3d-proton', 'x86', 'd3d12core.dll'],
    ]),
  ),
];

final _linuxWineRuntimeBackendDefinitions = <RuntimeBackendDefinition>[
  RuntimeBackendDefinition(
    id: RuntimeBackendId('dxvk'),
    name: RuntimeName('DXVK'),
    role: RuntimeRole('d3d9-d3d11-vulkan-translation'),
    componentIds: _runtimeComponentIds(const <String>['dxvk']),
  ),
  RuntimeBackendDefinition(
    id: RuntimeBackendId('vkd3d-proton'),
    name: RuntimeName('vkd3d-proton'),
    role: RuntimeRole('d3d12-vulkan-translation'),
    componentIds: _runtimeComponentIds(const <String>['vkd3d-proton']),
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
    'd3d10.dll',
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
    'd3d10.so',
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

const macosWineMonoComponentPaths = <List<String>>[
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

final _macosKonyakRuntimeComponentDefinitions =
    <RuntimeStackComponentDefinition>[
      RuntimeStackComponentDefinition(
        id: RuntimeComponentId('wine'),
        name: RuntimeName('Wine'),
        role: RuntimeRole('windows-runner'),
        isRequired: true,
        relativePaths: _runtimeRelativePaths(
          _macosWineEntryPointComponentPaths,
        ),
      ),
      RuntimeStackComponentDefinition(
        id: RuntimeComponentId('wine32on64'),
        name: RuntimeName('Wine32-on-64 support'),
        role: RuntimeRole('32-bit-windows-support'),
        isRequired: true,
        relativePaths: _runtimeRelativePaths(_macosWine32On64ComponentPaths),
      ),
      RuntimeStackComponentDefinition(
        id: RuntimeComponentId('dxvk-macos'),
        name: RuntimeName('DXVK-macOS'),
        role: RuntimeRole('d3d9-d3d11-translation'),
        isRequired: true,
        relativePaths: _runtimeRelativePaths(const <List<String>>[
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
        ]),
      ),
      RuntimeStackComponentDefinition(
        id: RuntimeComponentId('moltenvk'),
        name: RuntimeName('MoltenVK'),
        role: RuntimeRole('vulkan-metal-translation'),
        isRequired: true,
        relativePaths: _runtimeRelativePaths(const <List<String>>[
          <String>['lib', 'libMoltenVK.dylib'],
        ]),
      ),
      RuntimeStackComponentDefinition(
        id: RuntimeComponentId('gstreamer'),
        name: RuntimeName('GStreamer runtime'),
        role: RuntimeRole('media-runtime'),
        isRequired: true,
        relativePaths: _runtimeRelativePaths(const <List<String>>[
          <String>['lib', 'libgstreamer-1.0.0.dylib'],
          <String>['lib', 'gstreamer-1.0', 'libgstcoreelements.dylib'],
          <String>['lib', 'gstreamer-1.0', 'libgstplayback.dylib'],
          <String>['lib', 'gstreamer-1.0', 'libgsttypefindfunctions.dylib'],
          <String>['lib', 'gstreamer-1.0', 'libgstisomp4.dylib'],
          <String>['lib', 'gstreamer-1.0', 'libgstwavparse.dylib'],
          <String>['lib', 'gstreamer-1.0', 'libgstapplemedia.dylib'],
          <String>['libexec', 'gstreamer-1.0', 'gst-plugin-scanner'],
        ]),
      ),
      RuntimeStackComponentDefinition(
        id: RuntimeComponentId('freetype'),
        name: RuntimeName('FreeType font runtime'),
        role: RuntimeRole('font-rendering'),
        isRequired: true,
        relativePaths: _runtimeRelativePaths(const <List<String>>[
          <String>['lib', 'libfreetype.6.dylib'],
          <String>['lib', 'libfreetype.dylib'],
        ]),
      ),
      RuntimeStackComponentDefinition(
        id: RuntimeComponentId('wine-mono'),
        name: RuntimeName('wine-mono'),
        role: RuntimeRole('dotnet-runtime'),
        isRequired: true,
        relativePaths: _runtimeRelativePaths(macosWineMonoComponentPaths),
      ),
      RuntimeStackComponentDefinition(
        id: RuntimeComponentId('wine-gecko'),
        name: RuntimeName('wine-gecko'),
        role: RuntimeRole('html-runtime'),
        isRequired: true,
        relativePaths: _runtimeRelativePaths(_macosWineGeckoComponentPaths),
      ),
      RuntimeStackComponentDefinition(
        id: RuntimeComponentId('winetricks'),
        name: RuntimeName('winetricks'),
        role: RuntimeRole('verb-installer'),
        isRequired: true,
        relativePaths: _runtimeRelativePaths(const <List<String>>[
          <String>['winetricks'],
          <String>['verbs.txt'],
        ]),
      ),
      RuntimeStackComponentDefinition(
        id: RuntimeComponentId('vkd3d'),
        name: RuntimeName('vkd3d'),
        role: RuntimeRole('d3d12-vulkan-runtime'),
        isRequired: true,
        relativePaths: _runtimeRelativePaths(_macosVkd3dComponentPaths),
      ),
      RuntimeStackComponentDefinition(
        id: RuntimeComponentId('dxmt'),
        name: RuntimeName('DXMT'),
        role: RuntimeRole('d3d10-d3d11-metal-translation'),
        isRequired: true,
        relativePaths: _runtimeRelativePaths(const <List<String>>[
          <String>['lib', 'dxmt', 'x86_64-windows', 'd3d10core.dll'],
          <String>['lib', 'dxmt', 'x86_64-windows', 'd3d11.dll'],
          <String>['lib', 'dxmt', 'x86_64-windows', 'dxgi.dll'],
          <String>['lib', 'dxmt', 'x86_64-windows', 'winemetal.dll'],
          <String>['lib', 'dxmt', 'x86_64-windows', 'winemetal.so'],
          <String>['lib', 'dxmt', 'x86_64-windows', 'nvapi64.dll'],
          <String>['lib', 'dxmt', 'x86_64-windows', 'nvngx.dll'],
          <String>['lib', 'dxmt', 'x86_64-unix', 'winemetal.so'],
        ]),
      ),
      RuntimeStackComponentDefinition(
        id: RuntimeComponentId('gptk-d3dmetal'),
        name: RuntimeName('GPTK/D3DMetal'),
        role: RuntimeRole('d3d12-metal-translation'),
        isRequired: false,
        relativePaths: _runtimeRelativePaths(_macosGptkD3DMetalComponentPaths),
      ),
    ];

final _macosKonyakRuntimeBackendDefinitions = <RuntimeBackendDefinition>[
  RuntimeBackendDefinition(
    id: RuntimeBackendId('dxvk-macos'),
    name: RuntimeName('DXVK-macOS'),
    role: RuntimeRole('d3d9-d3d11-metal-translation'),
    componentIds: _runtimeComponentIds(const <String>[
      'dxvk-macos',
      'moltenvk',
    ]),
  ),
  RuntimeBackendDefinition(
    id: RuntimeBackendId('dxmt'),
    name: RuntimeName('DXMT'),
    role: RuntimeRole('d3d10-d3d11-metal-translation'),
    componentIds: _runtimeComponentIds(const <String>['dxmt']),
  ),
  RuntimeBackendDefinition(
    id: RuntimeBackendId('vkd3d'),
    name: RuntimeName('vkd3d'),
    role: RuntimeRole('d3d12-vulkan-metal-translation'),
    componentIds: _runtimeComponentIds(const <String>['vkd3d', 'moltenvk']),
  ),
  RuntimeBackendDefinition(
    id: RuntimeBackendId('gptk-d3dmetal'),
    name: RuntimeName('GPTK/D3DMetal'),
    role: RuntimeRole('d3d12-metal-translation'),
    componentIds: _runtimeComponentIds(const <String>['gptk-d3dmetal']),
  ),
];

final linuxWineRuntimePlatformSpec = RuntimePlatformSpec(
  runtimeId: RuntimeId(linuxWineRuntimeId),
  runtimeName: RuntimeName('Konyak Linux Wine'),
  platform: RuntimePlatformName('linux'),
  architecture: RuntimeArchitecture('x86_64'),
  runnerKind: RunnerKind.wine,
  stackId: RuntimeStackId('linux-wine-runtime-stack'),
  stackName: RuntimeStackName('Linux Wine/Proton runtime stack'),
  requiredExecutableRelativePath: RuntimeRelativePath(['bin', 'wine']),
  defaultArchiveFileName: RuntimeArchivePath('linux-wine.tar.xz'),
  developmentSourceManifestEnvironmentKey: ProgramEnvironmentVariableName(
    'KONYAK_DEV_LINUX_WINE_STACK_SOURCE_MANIFEST',
  ),
  releaseSourceManifestEnvironmentKey: ProgramEnvironmentVariableName(
    'KONYAK_LINUX_WINE_STACK_MANIFEST',
  ),
  developmentSourceSignatureEnvironmentKey: ProgramEnvironmentVariableName(
    'KONYAK_DEV_LINUX_WINE_STACK_SIGNATURE_URL',
  ),
  releaseSourceSignatureEnvironmentKey: ProgramEnvironmentVariableName(
    'KONYAK_LINUX_WINE_STACK_SIGNATURE_URL',
  ),
  componentDefinitions: _linuxWineRuntimeComponentDefinitions,
  backendDefinitions: _linuxWineRuntimeBackendDefinitions,
);

final macosKonyakRuntimePlatformSpec = RuntimePlatformSpec(
  runtimeId: RuntimeId(macosWineRuntimeId),
  runtimeName: RuntimeName('Konyak macOS Wine'),
  platform: RuntimePlatformName('macos'),
  architecture: RuntimeArchitecture('x86_64'),
  runnerKind: RunnerKind.macosWine,
  stackId: RuntimeStackId('macos-konyak-runtime-stack'),
  stackName: RuntimeStackName('Konyak macOS runtime stack'),
  requiredExecutableRelativePath: RuntimeRelativePath(['bin', 'wineloader']),
  defaultSourceManifestUrl: Option.of(
    RuntimeSourceManifestUrl(macosWineRuntimeSourceManifestUrl),
  ),
  defaultArchiveFileName: RuntimeArchivePath(macosWineArchiveFileName),
  developmentSourceManifestEnvironmentKey: ProgramEnvironmentVariableName(
    'KONYAK_DEV_MACOS_WINE_STACK_MANIFEST',
  ),
  releaseSourceManifestEnvironmentKey: ProgramEnvironmentVariableName(
    'KONYAK_MACOS_WINE_STACK_MANIFEST',
  ),
  developmentSourceSignatureEnvironmentKey: ProgramEnvironmentVariableName(
    'KONYAK_DEV_MACOS_WINE_STACK_SIGNATURE_URL',
  ),
  releaseSourceSignatureEnvironmentKey: ProgramEnvironmentVariableName(
    'KONYAK_MACOS_WINE_STACK_SIGNATURE_URL',
  ),
  layoutNormalization: RuntimeLayoutNormalization.macosWineBundle,
  componentDefinitions: _macosKonyakRuntimeComponentDefinitions,
  backendDefinitions: _macosKonyakRuntimeBackendDefinitions,
);

Option<RuntimeSourceManifestUrl> runtimeSourceManifestForPlatform({
  required RuntimePlatformSpec platformSpec,
  required HostEnvironment environment,
}) {
  final configuredManifest = runtimeProfileEnvironmentValue(
    environment,
    developmentKey: platformSpec.developmentSourceManifestEnvironmentKey,
    releaseKey: platformSpec.releaseSourceManifestEnvironmentKey,
  ).map(RuntimeSourceManifestUrl.new);
  if (isDevelopmentRuntimeProfile(environment)) {
    return configuredManifest;
  }

  return configuredManifest.alt(() => platformSpec.defaultSourceManifestUrl);
}

Option<RuntimeSourceManifestSignatureUrl>
runtimeSourceManifestSignatureForPlatform({
  required RuntimePlatformSpec platformSpec,
  required HostEnvironment environment,
}) {
  return runtimeProfileEnvironmentValue(
    environment,
    developmentKey: platformSpec.developmentSourceSignatureEnvironmentKey,
    releaseKey: platformSpec.releaseSourceSignatureEnvironmentKey,
  ).map(RuntimeSourceManifestSignatureUrl.new);
}
