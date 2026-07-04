import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../shared/domain_helpers.dart';
import '../shared/domain_value_objects.dart';
import 'runtime_component_versions.dart';
import 'runtime_models.dart';
import 'runtime_source_bundle_models.dart';
import 'runtime_validation_models.dart';

part 'runtime_source_archive_planning.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class RuntimeStackSourceArchivePlanResult
    with _$RuntimeStackSourceArchivePlanResult {
  const RuntimeStackSourceArchivePlanResult._();

  const factory RuntimeStackSourceArchivePlanResult.resolved(
    RuntimeStackSourceArchivePlan plan,
  ) = RuntimeStackSourceArchivePlanResolved;

  const factory RuntimeStackSourceArchivePlanResult.failed(String message) =
      RuntimeStackSourceArchivePlanFailed;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeStackSourceArchivePlan
    with _$RuntimeStackSourceArchivePlan {
  const RuntimeStackSourceArchivePlan._();

  factory RuntimeStackSourceArchivePlan({
    required RuntimeSourceComponent wineComponent,
    required Iterable<RuntimeSourceComponent> sourceComponents,
    required Iterable<RuntimeStackSourceArchiveComponentPlan> components,
  }) {
    return RuntimeStackSourceArchivePlan._validated(
      wineComponent: wineComponent,
      sourceComponents: List.unmodifiable(sourceComponents),
      components: List.unmodifiable(components),
    );
  }

  const factory RuntimeStackSourceArchivePlan._validated({
    required RuntimeSourceComponent wineComponent,
    required List<RuntimeSourceComponent> sourceComponents,
    required List<RuntimeStackSourceArchiveComponentPlan> components,
  }) = _RuntimeStackSourceArchivePlan;

  RuntimeStackSourceArchiveBundleResult toBundle() {
    return _archivePathForComponent(wineComponent).match(
      () => RuntimeStackSourceArchiveBundleFailed(
        'Runtime stack source archive plan does not contain ${wineComponent.id.value}.',
      ),
      (wineArchivePath) {
        final componentArchivePaths = components.fold<List<RuntimeArchivePath>>(
          const <RuntimeArchivePath>[],
          (paths, component) {
            final archivePath = component.archivePath;
            return archivePath != wineArchivePath &&
                    !paths.contains(archivePath)
                ? List<RuntimeArchivePath>.unmodifiable([...paths, archivePath])
                : paths;
          },
        );

        return RuntimeStackSourceArchiveBundleResolved(
          RuntimeStackSourceArchiveBundle(
            wineArchivePath: wineArchivePath,
            componentArchivePaths: componentArchivePaths,
            componentVersions: RuntimeComponentVersions(<String, String>{
              for (final component in sourceComponents)
                component.id.value: component.version.value,
            }),
          ),
        );
      },
    );
  }

  Option<RuntimeArchivePath> _archivePathForComponent(
    RuntimeSourceComponent sourceComponent,
  ) {
    return firstWhereOption(
      components,
      (component) => _runtimeStackSourceArchiveMatches(
        component.component,
        sourceComponent,
      ),
    ).map((component) => component.archivePath);
  }
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeStackSourceArchiveComponentPlan
    with _$RuntimeStackSourceArchiveComponentPlan {
  const RuntimeStackSourceArchiveComponentPlan._();

  factory RuntimeStackSourceArchiveComponentPlan({
    required RuntimeSourceComponent component,
    required RuntimeArchivePath archivePath,
    required num startFraction,
    required num endFraction,
  }) {
    return RuntimeStackSourceArchiveComponentPlan._validated(
      component: component,
      archivePath: archivePath,
      startFraction: RuntimeInstallProgressFraction(startFraction),
      endFraction: RuntimeInstallProgressFraction(endFraction),
    );
  }

  const factory RuntimeStackSourceArchiveComponentPlan._validated({
    required RuntimeSourceComponent component,
    required RuntimeArchivePath archivePath,
    required RuntimeInstallProgressFraction startFraction,
    required RuntimeInstallProgressFraction endFraction,
  }) = _RuntimeStackSourceArchiveComponentPlan;

  String get downloadingMessage {
    return 'Downloading ${component.id.value}...';
  }

  String get verifyingMessage {
    return 'Verifying ${component.id.value}...';
  }
}

RuntimeStackSourceArchivePlanResult runtimeStackSourceArchivePlan({
  required RuntimeSourceManifest manifest,
  required RuntimePlatformSpec platformSpec,
  required String tempDirectoryPath,
}) {
  if (manifest.runtimeId != platformSpec.runtimeId ||
      manifest.stackId != platformSpec.stackId) {
    return const RuntimeStackSourceArchivePlanResult.failed(
      'Runtime stack source manifest targets an unsupported runtime.',
    );
  }

  final wineComponentResult = manifest.componentById(
    RuntimeSourceComponentId('wine'),
  );

  final archiveComponents = _uniqueRuntimeStackSourceArchiveComponents(
    manifest.components,
  );
  final componentCount = archiveComponents.length;
  return wineComponentResult.match(
    () => const RuntimeStackSourceArchivePlanResult.failed(
      'Runtime stack source manifest does not contain a Wine component.',
    ),
    (wineComponent) => RuntimeStackSourceArchivePlanResult.resolved(
      RuntimeStackSourceArchivePlan(
        wineComponent: wineComponent,
        sourceComponents: manifest.components,
        components: <RuntimeStackSourceArchiveComponentPlan>[
          for (final (index, component) in archiveComponents.indexed)
            _runtimeStackSourceArchiveComponentPlan(
              component: component,
              componentIndex: index,
              componentCount: componentCount,
              tempDirectoryPath: tempDirectoryPath,
            ),
        ],
      ),
    ),
  );
}

List<RuntimeSourceComponent> _uniqueRuntimeStackSourceArchiveComponents(
  Iterable<RuntimeSourceComponent> components,
) {
  return List.unmodifiable(
    components.fold<List<RuntimeSourceComponent>>(
      const <RuntimeSourceComponent>[],
      (uniqueComponents, component) {
        final archiveKey = _runtimeStackSourceArchiveKey(component);
        final alreadySeen = uniqueComponents.any(
          (uniqueComponent) =>
              _runtimeStackSourceArchiveKey(uniqueComponent) == archiveKey,
        );
        return alreadySeen
            ? uniqueComponents
            : List<RuntimeSourceComponent>.unmodifiable([
                ...uniqueComponents,
                component,
              ]);
      },
    ),
  );
}

bool _runtimeStackSourceArchiveMatches(
  RuntimeSourceComponent left,
  RuntimeSourceComponent right,
) {
  return _runtimeStackSourceArchiveKey(left) ==
      _runtimeStackSourceArchiveKey(right);
}

String _runtimeStackSourceArchiveKey(RuntimeSourceComponent component) {
  return '${component.archiveUrl.value}\u0000${component.sha256.value.toLowerCase()}';
}

RuntimeStackSourceArchiveComponentPlan _runtimeStackSourceArchiveComponentPlan({
  required RuntimeSourceComponent component,
  required int componentIndex,
  required int componentCount,
  required String tempDirectoryPath,
}) {
  final fileName = fileNameFromUrl(
    component.archiveUrl.value,
  ).match(() => '${component.id.value}.tar.xz', (value) => value);
  return RuntimeStackSourceArchiveComponentPlan(
    component: component,
    archivePath: RuntimeArchivePath(
      domainJoinPath(tempDirectoryPath, ['$componentIndex-$fileName']),
    ),
    startFraction: 0.05 + (componentIndex / componentCount) * 0.55,
    endFraction: 0.05 + ((componentIndex + 1) / componentCount) * 0.55,
  );
}
