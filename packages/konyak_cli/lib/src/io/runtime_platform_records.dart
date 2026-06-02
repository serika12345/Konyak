part of '../../konyak_cli.dart';

RuntimeRecord _macosWineRuntimeRecord({
  required Map<String, String> environment,
  required FileStatusProbe fileStatusProbe,
  required RuntimeStackVersionProbe runtimeStackVersionProbe,
}) {
  const platformSpec = _macosKonyakRuntimePlatformSpec;
  final hostEnvironment = HostEnvironment(environment);
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
        _runtimeDistributionKind(hostEnvironment, 'bootstrap'),
      ),
      archiveUrl: platformSpec.defaultArchiveUrl,
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
  required Map<String, String> environment,
  required FileStatusProbe fileStatusProbe,
  required RuntimeStackVersionProbe runtimeStackVersionProbe,
}) {
  const platformSpec = _linuxWineRuntimePlatformSpec;
  final hostEnvironment = HostEnvironment(environment);
  final runtimeRoot = _linuxWineRuntimeRoot(environment);
  final executablePath = _joinPath(runtimeRoot, const ['bin', 'wine']);
  final archiveUrl = _runtimeDefaultArchiveUrl(
    platformSpec: platformSpec,
    environment: hostEnvironment,
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
      isUpdateable: archiveUrl.isSome() || versionUrl != null,
      distributionKind: Option.of(
        _runtimeDistributionKind(hostEnvironment, 'managed'),
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
