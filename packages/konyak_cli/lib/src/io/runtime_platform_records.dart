import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../domain/runtime/host_environment.dart';
import '../domain/runtime/runtime_models.dart';
import '../domain/runtime/runtime_platform_support.dart';
import '../domain/runtime/runtime_profile_environment.dart';
import '../domain/runtime/runtime_validation_models.dart';
import '../domain/runtime/runtime_validation_support.dart';
import '../domain/runtime/wine_runtime_paths.dart';
import '../domain/shared/domain_value_objects.dart';
import '../shared/common_helpers.dart';
import '../shared/model_constants.dart';
import 'runtime_gptk_support.dart';

RuntimeRecord macosWineRuntimeRecord({
  required HostEnvironment environment,
  required FileStatusProbe fileStatusProbe,
  required RuntimeStackVersionProbe runtimeStackVersionProbe,
}) {
  final platformSpec = macosKonyakRuntimePlatformSpec;
  final applicationSupportPath = konyakApplicationSupportFolder(environment);
  final libraryPath = macosWineRuntimeRoot(environment);
  final executablePath = macosWineExecutable(environment);
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
      distributionKind: Option.of(
        RuntimeDistributionKind(
          runtimeDistributionKind(environment, 'bootstrap'),
        ),
      ),
      archiveUrl: const Option.none(),
      versionUrl: Option.of(RuntimeVersionUrl(macosWineVersionUrl)),
    ),
    installedState: InstalledRuntimeState(
      isInstalled: Option.of(isInstalled),
      applicationSupportPath: Option.of(applicationSupportPath),
      libraryPath: Option.of(libraryPath),
      executablePath: Option.of(executablePath),
    ),
    capabilities: RuntimeCapabilities(
      stack: Option.of(
        runtimeStackForPlatform(
          platformSpec: platformSpec,
          runtimeRoot: libraryPath,
          fileStatusProbe: fileStatusProbe,
          runtimeStackVersionProbe: runtimeStackVersionProbe,
        ),
      ),
    ),
  );
}

RuntimeRecord linuxWineRuntimeRecord({
  required HostEnvironment environment,
  required FileStatusProbe fileStatusProbe,
  required RuntimeStackVersionProbe runtimeStackVersionProbe,
}) {
  final platformSpec = linuxWineRuntimePlatformSpec;
  final runtimeRoot = linuxWineRuntimeRoot(environment);
  final executablePath = joinPath(runtimeRoot, const ['bin', 'wine']);
  final versionUrl = environment.nonEmptyValue('KONYAK_LINUX_WINE_VERSION_URL');
  return RuntimeRecord.fromParts(
    definition: RuntimeDefinition(
      id: platformSpec.runtimeId,
      name: platformSpec.runtimeName,
      platform: platformSpec.platform,
      architecture: platformSpec.architecture,
      runnerKind: platformSpec.runnerKind,
      isBundled: false,
      isUpdateable: versionUrl.isSome(),
      distributionKind: Option.of(
        RuntimeDistributionKind(
          runtimeDistributionKind(environment, 'managed'),
        ),
      ),
      archiveUrl: const Option.none(),
      versionUrl: versionUrl.map(RuntimeVersionUrl.new),
    ),
    installedState: InstalledRuntimeState(
      isInstalled: Option.of(fileStatusProbe.exists(executablePath)),
      libraryPath: Option.of(runtimeRoot),
      executablePath: Option.of(executablePath),
    ),
    capabilities: RuntimeCapabilities(
      stack: Option.of(
        runtimeStackForPlatform(
          platformSpec: platformSpec,
          runtimeRoot: runtimeRoot,
          fileStatusProbe: fileStatusProbe,
          runtimeStackVersionProbe: runtimeStackVersionProbe,
        ),
      ),
    ),
  );
}

RuntimeStack runtimeStackForPlatform({
  required RuntimePlatformSpec platformSpec,
  required String runtimeRoot,
  required FileStatusProbe fileStatusProbe,
  required RuntimeStackVersionProbe runtimeStackVersionProbe,
}) {
  final components = platformSpec.componentDefinitions
      .map(
        (definition) => runtimeStackComponent(
          runtimeRoot: runtimeRoot,
          fileStatusProbe: fileStatusProbe,
          runtimeStackVersionProbe: runtimeStackVersionProbe,
          definition: definition,
        ),
      )
      .toList(growable: false);
  return RuntimeStack(
    id: platformSpec.stackId,
    name: platformSpec.stackName,
    compatibilityTarget: RuntimeCompatibilityTarget(platformSpec.stackId.value),
    components: components,
    backends: platformSpec.backendDefinitions
        .map(
          (definition) => runtimeStackBackend(
            definition: definition,
            components: components,
          ),
        )
        .toList(growable: false),
  );
}

RuntimeStackBackend runtimeStackBackend({
  required RuntimeBackendDefinition definition,
  required List<RuntimeStackComponent> components,
}) {
  final componentsById = <RuntimeComponentId, RuntimeStackComponent>{
    for (final component in components) component.id: component,
  };
  final missingComponentIds = <RuntimeComponentId>[];
  final missingPaths = <RuntimeMissingPath>[];

  for (final componentId in definition.componentIds) {
    final component = componentsById[componentId];
    if (component == null) {
      missingComponentIds.add(componentId);
      continue;
    }

    if (!component.isInstalled) {
      missingComponentIds.add(componentId);
      missingPaths.addAll(component.missingPaths);
    }
  }

  return RuntimeStackBackend(
    id: definition.id,
    name: definition.name,
    role: definition.role,
    componentIds: definition.componentIds,
    missingComponentIds: missingComponentIds,
    missingPaths: missingPaths,
  );
}

RuntimeStackComponent runtimeStackComponent({
  required String runtimeRoot,
  required FileStatusProbe fileStatusProbe,
  required RuntimeStackVersionProbe runtimeStackVersionProbe,
  required RuntimeStackComponentDefinition definition,
}) {
  final paths = definition.relativePaths
      .map((pathSegments) => joinPath(runtimeRoot, pathSegments.value))
      .toList(growable: false);
  final missingPaths = paths
      .where((path) => !fileStatusProbe.exists(path))
      .toList();
  if (definition.id == RuntimeComponentId('gptk-d3dmetal')) {
    final frameworkBinary = d3dMetalFrameworkBinary(paths.first);
    if (frameworkBinary == null || !looksLikeMachO(File(frameworkBinary))) {
      addMissingRuntimePath(missingPaths, paths.first);
    }
    if (!looksLikeMachO(File(paths[1]))) {
      addMissingRuntimePath(missingPaths, paths[1]);
    }
    for (final path in const <String>[
      'components/gptk-d3dmetal/lib/wine/x86_64-unix/d3d10.so',
      'components/gptk-d3dmetal/lib/wine/x86_64-unix/d3d11.so',
      'components/gptk-d3dmetal/lib/wine/x86_64-unix/d3d12.so',
      'components/gptk-d3dmetal/lib/wine/x86_64-unix/dxgi.so',
    ]) {
      final fullPath = joinPath(runtimeRoot, path.split('/'));
      if (!isGptkD3DMetalUnixLibraryLink(fullPath)) {
        addMissingRuntimePath(missingPaths, fullPath);
      }
    }
  }

  return RuntimeStackComponent(
    id: definition.id,
    name: definition.name,
    role: definition.role,
    isRequired: definition.isRequired,
    paths: paths.map(RuntimeComponentPath.new),
    missingPaths: missingPaths.map(RuntimeMissingPath.new),
    version: missingPaths.isEmpty
        ? runtimeStackVersionProbe.versionFor(
            runtimeRoot: RuntimeRootPath(runtimeRoot),
            componentId: definition.id,
          )
        : const Option.none(),
  );
}

void addMissingRuntimePath(List<String> missingPaths, String path) {
  if (!missingPaths.contains(path)) {
    missingPaths.add(path);
  }
}

bool isGptkD3DMetalUnixLibraryLink(String path) {
  try {
    return FileSystemEntity.typeSync(path, followLinks: false) ==
            FileSystemEntityType.link &&
        Link(path).targetSync() == '../../external/libd3dshared.dylib';
  } on FileSystemException {
    return false;
  }
}
