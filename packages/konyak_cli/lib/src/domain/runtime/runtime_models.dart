import 'package:fpdart/fpdart.dart';

import '../shared/domain_value_objects.dart';

class RuntimeDefinition {
  RuntimeDefinition({
    required String id,
    required String name,
    required String platform,
    required String architecture,
    required String runnerKind,
    required this.isBundled,
    required this.isUpdateable,
    Option<String> distributionKind = const Option.none(),
    Option<String> archiveUrl = const Option.none(),
    Option<String> versionUrl = const Option.none(),
  }) : id = RuntimeId(id),
       name = RuntimeName(name),
       platform = RuntimePlatformName(platform),
       architecture = RuntimeArchitecture(architecture),
       runnerKind = RunnerKind(runnerKind),
       distributionKind = distributionKind.map(RuntimeDistributionKind.new),
       archiveUrl = archiveUrl.map(RuntimeArchiveUrl.new),
       versionUrl = versionUrl.map(RuntimeVersionUrl.new);

  final RuntimeId id;
  final RuntimeName name;
  final RuntimePlatformName platform;
  final RuntimeArchitecture architecture;
  final RunnerKind runnerKind;
  final bool isBundled;
  final bool isUpdateable;
  final Option<RuntimeDistributionKind> distributionKind;
  final Option<RuntimeArchiveUrl> archiveUrl;
  final Option<RuntimeVersionUrl> versionUrl;
}

class InstalledRuntimeState {
  InstalledRuntimeState({
    this.isInstalled = const Option.none(),
    Option<String> applicationSupportPath = const Option.none(),
    Option<String> libraryPath = const Option.none(),
    Option<String> executablePath = const Option.none(),
  }) : applicationSupportPath = applicationSupportPath.map(
         RuntimeComponentPath.new,
       ),
       libraryPath = libraryPath.map(RuntimeComponentPath.new),
       executablePath = executablePath.map(RuntimeComponentPath.new);

  const InstalledRuntimeState.unknown()
    : isInstalled = const Option.none(),
      applicationSupportPath = const Option.none(),
      libraryPath = const Option.none(),
      executablePath = const Option.none();

  final Option<bool> isInstalled;
  final Option<RuntimeComponentPath> applicationSupportPath;
  final Option<RuntimeComponentPath> libraryPath;
  final Option<RuntimeComponentPath> executablePath;
}

class RuntimeCapabilities {
  const RuntimeCapabilities({this.stack = const Option.none()});

  const RuntimeCapabilities.empty() : stack = const Option.none();

  final Option<RuntimeStack> stack;
}

class RuntimeRecord {
  RuntimeRecord({
    required String id,
    required String name,
    required String platform,
    required String architecture,
    required String runnerKind,
    required this.isBundled,
    required this.isUpdateable,
    Option<String> distributionKind = const Option.none(),
    this.isInstalled = const Option.none(),
    Option<String> applicationSupportPath = const Option.none(),
    Option<String> libraryPath = const Option.none(),
    Option<String> executablePath = const Option.none(),
    Option<String> archiveUrl = const Option.none(),
    Option<String> versionUrl = const Option.none(),
    this.stack = const Option.none(),
  }) : id = RuntimeId(id),
       name = RuntimeName(name),
       platform = RuntimePlatformName(platform),
       architecture = RuntimeArchitecture(architecture),
       runnerKind = RunnerKind(runnerKind),
       distributionKind = distributionKind.map(RuntimeDistributionKind.new),
       applicationSupportPath = applicationSupportPath.map(
         RuntimeComponentPath.new,
       ),
       libraryPath = libraryPath.map(RuntimeComponentPath.new),
       executablePath = executablePath.map(RuntimeComponentPath.new),
       archiveUrl = archiveUrl.map(RuntimeArchiveUrl.new),
       versionUrl = versionUrl.map(RuntimeVersionUrl.new);

  RuntimeRecord.fromParts({
    required RuntimeDefinition definition,
    InstalledRuntimeState installedState =
        const InstalledRuntimeState.unknown(),
    RuntimeCapabilities capabilities = const RuntimeCapabilities.empty(),
  }) : id = definition.id,
       name = definition.name,
       platform = definition.platform,
       architecture = definition.architecture,
       runnerKind = definition.runnerKind,
       isBundled = definition.isBundled,
       isUpdateable = definition.isUpdateable,
       distributionKind = definition.distributionKind,
       isInstalled = installedState.isInstalled,
       applicationSupportPath = installedState.applicationSupportPath,
       libraryPath = installedState.libraryPath,
       executablePath = installedState.executablePath,
       archiveUrl = definition.archiveUrl,
       versionUrl = definition.versionUrl,
       stack = capabilities.stack;

  final RuntimeId id;
  final RuntimeName name;
  final RuntimePlatformName platform;
  final RuntimeArchitecture architecture;
  final RunnerKind runnerKind;
  final bool isBundled;
  final bool isUpdateable;
  final Option<RuntimeDistributionKind> distributionKind;
  final Option<bool> isInstalled;
  final Option<RuntimeComponentPath> applicationSupportPath;
  final Option<RuntimeComponentPath> libraryPath;
  final Option<RuntimeComponentPath> executablePath;
  final Option<RuntimeArchiveUrl> archiveUrl;
  final Option<RuntimeVersionUrl> versionUrl;
  final Option<RuntimeStack> stack;
}

class RuntimeStack {
  RuntimeStack({
    required String id,
    required String name,
    required String compatibilityTarget,
    required Iterable<RuntimeStackComponent> components,
    Iterable<RuntimeStackBackend> backends = const <RuntimeStackBackend>[],
  }) : id = RuntimeStackId(id),
       name = RuntimeStackName(name),
       compatibilityTarget = RuntimeCompatibilityTarget(compatibilityTarget),
       components = List.unmodifiable(components),
       backends = List.unmodifiable(backends);

  final RuntimeStackId id;
  final RuntimeStackName name;
  final RuntimeCompatibilityTarget compatibilityTarget;
  final List<RuntimeStackComponent> components;
  final List<RuntimeStackBackend> backends;

  bool get isComplete {
    return components
        .where((component) => component.isRequired)
        .every((component) => component.isInstalled);
  }
}

class RuntimeStackBackend {
  RuntimeStackBackend({
    required String id,
    required String name,
    required String role,
    required Iterable<String> componentIds,
    required Iterable<String> missingComponentIds,
    required Iterable<String> missingPaths,
  }) : id = RuntimeBackendId(id),
       name = RuntimeName(name),
       role = RuntimeRole(role),
       componentIds = List.unmodifiable(
         componentIds.map(RuntimeComponentId.new),
       ),
       missingComponentIds = List.unmodifiable(
         missingComponentIds.map(RuntimeComponentId.new),
       ),
       missingPaths = List.unmodifiable(
         missingPaths.map(RuntimeMissingPath.new),
       );

  final RuntimeBackendId id;
  final RuntimeName name;
  final RuntimeRole role;
  final List<RuntimeComponentId> componentIds;
  final List<RuntimeComponentId> missingComponentIds;
  final List<RuntimeMissingPath> missingPaths;

  bool get isAvailable {
    return missingComponentIds.isEmpty && missingPaths.isEmpty;
  }
}

class RuntimeStackComponent {
  RuntimeStackComponent({
    required String id,
    required String name,
    required String role,
    required this.isRequired,
    required Iterable<String> paths,
    required Iterable<String> missingPaths,
    Option<String> version = const Option.none(),
  }) : id = RuntimeComponentId(id),
       name = RuntimeName(name),
       role = RuntimeRole(role),
       paths = List.unmodifiable(paths.map(RuntimeComponentPath.new)),
       missingPaths = List.unmodifiable(
         missingPaths.map(RuntimeMissingPath.new),
       ),
       version = version.map(RuntimeVersion.new);

  final RuntimeComponentId id;
  final RuntimeName name;
  final RuntimeRole role;
  final bool isRequired;
  final List<RuntimeComponentPath> paths;
  final List<RuntimeMissingPath> missingPaths;
  final Option<RuntimeVersion> version;

  bool get isInstalled {
    return missingPaths.isEmpty;
  }
}

class RuntimeSourceManifest {
  RuntimeSourceManifest({
    required String runtimeId,
    required String stackId,
    required Iterable<RuntimeSourceComponent> components,
  }) : runtimeId = RuntimeId(runtimeId),
       stackId = RuntimeStackId(stackId),
       components = List.unmodifiable(components);

  final RuntimeId runtimeId;
  final RuntimeStackId stackId;
  final List<RuntimeSourceComponent> components;

  Option<RuntimeSourceComponent> componentById(String id) {
    for (final component in components) {
      if (component.id.value == id) {
        return Option.of(component);
      }
    }

    return const Option.none();
  }
}

class RuntimeSourceComponent {
  RuntimeSourceComponent({
    required String id,
    required String version,
    required String archiveUrl,
    required String sha256,
  }) : id = RuntimeSourceComponentId(id),
       version = RuntimeSourceComponentVersion(version),
       archiveUrl = RuntimeArchiveUrl(archiveUrl),
       sha256 = RuntimeArchiveChecksumValue(sha256);

  final RuntimeSourceComponentId id;
  final RuntimeSourceComponentVersion version;
  final RuntimeArchiveUrl archiveUrl;
  final RuntimeArchiveChecksumValue sha256;
}
