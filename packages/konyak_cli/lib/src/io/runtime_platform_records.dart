part of '../../konyak_cli.dart';

RuntimeRecord _macosWineRuntimeRecord({
  required HostEnvironment environment,
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
      distributionKind: Option.fromNullable(
        _runtimeDistributionKind(environment, 'bootstrap'),
      ),
      archiveUrl: const Option.none(),
      versionUrl: Option.fromNullable(macosWineVersionUrl),
    ),
    installedState: InstalledRuntimeState(
      isInstalled: Option.of(isInstalled),
      applicationSupportPath: Option.of(applicationSupportPath),
      libraryPath: Option.of(libraryPath),
      executablePath: Option.of(executablePath),
    ),
    capabilities: RuntimeCapabilities(
      stack: Option.of(
        _runtimeStackForPlatform(
          platformSpec: platformSpec,
          runtimeRoot: libraryPath,
          fileStatusProbe: fileStatusProbe,
          runtimeStackVersionProbe: runtimeStackVersionProbe,
        ),
      ),
    ),
  );
}

RuntimeRecord _linuxWineRuntimeRecord({
  required HostEnvironment environment,
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
  final versionUrl = environment.nonEmptyValue('KONYAK_LINUX_WINE_VERSION_URL');
  return RuntimeRecord.fromParts(
    definition: RuntimeDefinition(
      id: platformSpec.runtimeId,
      name: platformSpec.runtimeName,
      platform: platformSpec.platform,
      architecture: platformSpec.architecture,
      runnerKind: platformSpec.runnerKind,
      isBundled: false,
      isUpdateable: archiveUrl.isSome() || versionUrl != null,
      distributionKind: Option.of(
        _runtimeDistributionKind(environment, 'managed'),
      ),
      archiveUrl: archiveUrl,
      versionUrl: Option.fromNullable(versionUrl),
    ),
    installedState: InstalledRuntimeState(
      isInstalled: Option.of(fileStatusProbe.exists(executablePath)),
      libraryPath: Option.of(runtimeRoot),
      executablePath: Option.of(executablePath),
    ),
    capabilities: RuntimeCapabilities(
      stack: Option.of(
        _runtimeStackForPlatform(
          platformSpec: platformSpec,
          runtimeRoot: runtimeRoot,
          fileStatusProbe: fileStatusProbe,
          runtimeStackVersionProbe: runtimeStackVersionProbe,
        ),
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
      _addMissingRuntimePath(missingPaths, paths.first);
    }
    if (!_looksLikeMachO(File(paths[1]))) {
      _addMissingRuntimePath(missingPaths, paths[1]);
    }
    for (final path in const <String>[
      'lib/wine/x86_64-unix/d3d11.so',
      'lib/wine/x86_64-unix/d3d12.so',
      'lib/wine/x86_64-unix/dxgi.so',
    ]) {
      final fullPath = _joinPath(runtimeRoot, path.split('/'));
      if (!_isGptkD3DMetalUnixLibraryLink(fullPath)) {
        _addMissingRuntimePath(missingPaths, fullPath);
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
    version: Option.fromNullable(
      missingPaths.isEmpty
          ? runtimeStackVersionProbe.versionFor(
              runtimeRoot: runtimeRoot,
              componentId: definition.id,
            )
          : null,
    ),
  );
}

void _addMissingRuntimePath(List<String> missingPaths, String path) {
  if (!missingPaths.contains(path)) {
    missingPaths.add(path);
  }
}

bool _isGptkD3DMetalUnixLibraryLink(String path) {
  try {
    return FileSystemEntity.typeSync(path, followLinks: false) ==
            FileSystemEntityType.link &&
        Link(path).targetSync() == '../../external/libd3dshared.dylib';
  } on FileSystemException {
    return false;
  }
}
