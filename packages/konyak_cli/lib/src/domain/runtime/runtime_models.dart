import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../shared/domain_value_objects.dart';

part 'runtime_models.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeDefinition with _$RuntimeDefinition {
  const RuntimeDefinition._();

  factory RuntimeDefinition({
    required String id,
    required String name,
    required String platform,
    required String architecture,
    required String runnerKind,
    required bool isBundled,
    required bool isUpdateable,
    Option<String> distributionKind = const Option.none(),
    Option<String> archiveUrl = const Option.none(),
    Option<String> versionUrl = const Option.none(),
  }) {
    return RuntimeDefinition._validated(
      id: RuntimeId(id),
      name: RuntimeName(name),
      platform: RuntimePlatformName(platform),
      architecture: RuntimeArchitecture(architecture),
      runnerKind: RunnerKind(runnerKind),
      isBundled: isBundled,
      isUpdateable: isUpdateable,
      distributionKind: distributionKind.map(RuntimeDistributionKind.new),
      archiveUrl: archiveUrl.map(RuntimeArchiveUrl.new),
      versionUrl: versionUrl.map(RuntimeVersionUrl.new),
    );
  }

  const factory RuntimeDefinition._validated({
    required RuntimeId id,
    required RuntimeName name,
    required RuntimePlatformName platform,
    required RuntimeArchitecture architecture,
    required RunnerKind runnerKind,
    required bool isBundled,
    required bool isUpdateable,
    required Option<RuntimeDistributionKind> distributionKind,
    required Option<RuntimeArchiveUrl> archiveUrl,
    required Option<RuntimeVersionUrl> versionUrl,
  }) = _RuntimeDefinition;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class InstalledRuntimeState with _$InstalledRuntimeState {
  const InstalledRuntimeState._();

  factory InstalledRuntimeState({
    Option<bool> isInstalled = const Option.none(),
    Option<String> applicationSupportPath = const Option.none(),
    Option<String> libraryPath = const Option.none(),
    Option<String> executablePath = const Option.none(),
  }) {
    return InstalledRuntimeState._validated(
      isInstalled: isInstalled,
      applicationSupportPath: applicationSupportPath.map(
        RuntimeComponentPath.new,
      ),
      libraryPath: libraryPath.map(RuntimeComponentPath.new),
      executablePath: executablePath.map(RuntimeComponentPath.new),
    );
  }

  const factory InstalledRuntimeState.unknown({
    @Default(Option<bool>.none()) Option<bool> isInstalled,
    @Default(Option<RuntimeComponentPath>.none())
    Option<RuntimeComponentPath> applicationSupportPath,
    @Default(Option<RuntimeComponentPath>.none())
    Option<RuntimeComponentPath> libraryPath,
    @Default(Option<RuntimeComponentPath>.none())
    Option<RuntimeComponentPath> executablePath,
  }) = _UnknownInstalledRuntimeState;

  const factory InstalledRuntimeState._validated({
    required Option<bool> isInstalled,
    required Option<RuntimeComponentPath> applicationSupportPath,
    required Option<RuntimeComponentPath> libraryPath,
    required Option<RuntimeComponentPath> executablePath,
  }) = _InstalledRuntimeState;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeCapabilities with _$RuntimeCapabilities {
  const RuntimeCapabilities._();

  const factory RuntimeCapabilities({
    @Default(Option<RuntimeStack>.none()) Option<RuntimeStack> stack,
  }) = _RuntimeCapabilities;

  const factory RuntimeCapabilities.empty({
    @Default(Option<RuntimeStack>.none()) Option<RuntimeStack> stack,
  }) = _EmptyRuntimeCapabilities;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeRecord with _$RuntimeRecord {
  const RuntimeRecord._();

  factory RuntimeRecord({
    required String id,
    required String name,
    required String platform,
    required String architecture,
    required String runnerKind,
    required bool isBundled,
    required bool isUpdateable,
    Option<String> distributionKind = const Option.none(),
    Option<bool> isInstalled = const Option.none(),
    Option<String> applicationSupportPath = const Option.none(),
    Option<String> libraryPath = const Option.none(),
    Option<String> executablePath = const Option.none(),
    Option<String> archiveUrl = const Option.none(),
    Option<String> versionUrl = const Option.none(),
    Option<RuntimeStack> stack = const Option.none(),
  }) {
    return RuntimeRecord._validated(
      id: RuntimeId(id),
      name: RuntimeName(name),
      platform: RuntimePlatformName(platform),
      architecture: RuntimeArchitecture(architecture),
      runnerKind: RunnerKind(runnerKind),
      isBundled: isBundled,
      isUpdateable: isUpdateable,
      distributionKind: distributionKind.map(RuntimeDistributionKind.new),
      isInstalled: isInstalled,
      applicationSupportPath: applicationSupportPath.map(
        RuntimeComponentPath.new,
      ),
      libraryPath: libraryPath.map(RuntimeComponentPath.new),
      executablePath: executablePath.map(RuntimeComponentPath.new),
      archiveUrl: archiveUrl.map(RuntimeArchiveUrl.new),
      versionUrl: versionUrl.map(RuntimeVersionUrl.new),
      stack: stack,
    );
  }

  factory RuntimeRecord.fromParts({
    required RuntimeDefinition definition,
    InstalledRuntimeState installedState =
        const InstalledRuntimeState.unknown(),
    RuntimeCapabilities capabilities = const RuntimeCapabilities.empty(),
  }) {
    return RuntimeRecord._validated(
      id: definition.id,
      name: definition.name,
      platform: definition.platform,
      architecture: definition.architecture,
      runnerKind: definition.runnerKind,
      isBundled: definition.isBundled,
      isUpdateable: definition.isUpdateable,
      distributionKind: definition.distributionKind,
      isInstalled: installedState.isInstalled,
      applicationSupportPath: installedState.applicationSupportPath,
      libraryPath: installedState.libraryPath,
      executablePath: installedState.executablePath,
      archiveUrl: definition.archiveUrl,
      versionUrl: definition.versionUrl,
      stack: capabilities.stack,
    );
  }

  const factory RuntimeRecord._validated({
    required RuntimeId id,
    required RuntimeName name,
    required RuntimePlatformName platform,
    required RuntimeArchitecture architecture,
    required RunnerKind runnerKind,
    required bool isBundled,
    required bool isUpdateable,
    required Option<RuntimeDistributionKind> distributionKind,
    required Option<bool> isInstalled,
    required Option<RuntimeComponentPath> applicationSupportPath,
    required Option<RuntimeComponentPath> libraryPath,
    required Option<RuntimeComponentPath> executablePath,
    required Option<RuntimeArchiveUrl> archiveUrl,
    required Option<RuntimeVersionUrl> versionUrl,
    required Option<RuntimeStack> stack,
  }) = _RuntimeRecord;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeStack with _$RuntimeStack {
  const RuntimeStack._();

  factory RuntimeStack({
    required String id,
    required String name,
    required String compatibilityTarget,
    required Iterable<RuntimeStackComponent> components,
    Iterable<RuntimeStackBackend> backends = const <RuntimeStackBackend>[],
  }) {
    return RuntimeStack._validated(
      id: RuntimeStackId(id),
      name: RuntimeStackName(name),
      compatibilityTarget: RuntimeCompatibilityTarget(compatibilityTarget),
      components: List.unmodifiable(components),
      backends: List.unmodifiable(backends),
    );
  }

  const factory RuntimeStack._validated({
    required RuntimeStackId id,
    required RuntimeStackName name,
    required RuntimeCompatibilityTarget compatibilityTarget,
    required List<RuntimeStackComponent> components,
    required List<RuntimeStackBackend> backends,
  }) = _RuntimeStack;

  bool get isComplete {
    return components
        .where((component) => component.isRequired)
        .every((component) => component.isInstalled);
  }
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeStackBackend with _$RuntimeStackBackend {
  const RuntimeStackBackend._();

  factory RuntimeStackBackend({
    required String id,
    required String name,
    required String role,
    required Iterable<String> componentIds,
    required Iterable<String> missingComponentIds,
    required Iterable<String> missingPaths,
  }) {
    return RuntimeStackBackend._validated(
      id: RuntimeBackendId(id),
      name: RuntimeName(name),
      role: RuntimeRole(role),
      componentIds: List.unmodifiable(componentIds.map(RuntimeComponentId.new)),
      missingComponentIds: List.unmodifiable(
        missingComponentIds.map(RuntimeComponentId.new),
      ),
      missingPaths: List.unmodifiable(missingPaths.map(RuntimeMissingPath.new)),
    );
  }

  const factory RuntimeStackBackend._validated({
    required RuntimeBackendId id,
    required RuntimeName name,
    required RuntimeRole role,
    required List<RuntimeComponentId> componentIds,
    required List<RuntimeComponentId> missingComponentIds,
    required List<RuntimeMissingPath> missingPaths,
  }) = _RuntimeStackBackend;

  bool get isAvailable {
    return missingComponentIds.isEmpty && missingPaths.isEmpty;
  }
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeStackComponent with _$RuntimeStackComponent {
  const RuntimeStackComponent._();

  factory RuntimeStackComponent({
    required String id,
    required String name,
    required String role,
    required bool isRequired,
    required Iterable<String> paths,
    required Iterable<String> missingPaths,
    Option<String> version = const Option.none(),
  }) {
    return RuntimeStackComponent._validated(
      id: RuntimeComponentId(id),
      name: RuntimeName(name),
      role: RuntimeRole(role),
      isRequired: isRequired,
      paths: List.unmodifiable(paths.map(RuntimeComponentPath.new)),
      missingPaths: List.unmodifiable(missingPaths.map(RuntimeMissingPath.new)),
      version: version.map(RuntimeVersion.new),
    );
  }

  const factory RuntimeStackComponent._validated({
    required RuntimeComponentId id,
    required RuntimeName name,
    required RuntimeRole role,
    required bool isRequired,
    required List<RuntimeComponentPath> paths,
    required List<RuntimeMissingPath> missingPaths,
    required Option<RuntimeVersion> version,
  }) = _RuntimeStackComponent;

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
