part of '../../../konyak_cli.dart';

sealed class _RuntimeStackSourceArchivePlanResult {
  const _RuntimeStackSourceArchivePlanResult();
}

final class _RuntimeStackSourceArchivePlanResolved
    extends _RuntimeStackSourceArchivePlanResult {
  const _RuntimeStackSourceArchivePlanResolved(this.plan);

  final _RuntimeStackSourceArchivePlan plan;
}

final class _RuntimeStackSourceArchivePlanFailed
    extends _RuntimeStackSourceArchivePlanResult {
  const _RuntimeStackSourceArchivePlanFailed(this.message);

  final String message;
}

final class _RuntimeStackSourceArchivePlan {
  _RuntimeStackSourceArchivePlan({
    required this.wineComponent,
    required Iterable<RuntimeSourceComponent> sourceComponents,
    required Iterable<_RuntimeStackSourceArchiveComponentPlan> components,
  }) : sourceComponents = List.unmodifiable(sourceComponents),
       components = List.unmodifiable(components);

  final RuntimeSourceComponent wineComponent;
  final List<RuntimeSourceComponent> sourceComponents;
  final List<_RuntimeStackSourceArchiveComponentPlan> components;

  _RuntimeStackSourceArchiveBundle toBundle() {
    final wineArchivePath = _archivePathForComponent(wineComponent);
    final componentArchivePaths = <RuntimeArchivePath>[];
    for (final component in components) {
      final archivePath = component.archivePath;
      if (archivePath != wineArchivePath &&
          !componentArchivePaths.contains(archivePath)) {
        componentArchivePaths.add(archivePath);
      }
    }

    return _RuntimeStackSourceArchiveBundle(
      wineArchivePath: wineArchivePath.value,
      componentArchivePaths: componentArchivePaths.map((value) => value.value),
      componentVersions: RuntimeComponentVersions(<String, String>{
        for (final component in sourceComponents)
          component.id.value: component.version.value,
      }),
    );
  }

  RuntimeArchivePath _archivePathForComponent(
    RuntimeSourceComponent sourceComponent,
  ) {
    for (final component in components) {
      if (_runtimeStackSourceArchiveMatches(
        component.component,
        sourceComponent,
      )) {
        return component.archivePath;
      }
    }

    throw StateError(
      'Runtime stack source archive plan does not contain ${sourceComponent.id.value}.',
    );
  }
}

final class _RuntimeStackSourceArchiveComponentPlan {
  _RuntimeStackSourceArchiveComponentPlan({
    required this.component,
    required String archivePath,
    required num startFraction,
    required num endFraction,
  }) : archivePath = RuntimeArchivePath(archivePath),
       startFraction = RuntimeInstallProgressFraction(startFraction),
       endFraction = RuntimeInstallProgressFraction(endFraction);

  final RuntimeSourceComponent component;
  final RuntimeArchivePath archivePath;
  final RuntimeInstallProgressFraction startFraction;
  final RuntimeInstallProgressFraction endFraction;

  String get downloadingMessage {
    return 'Downloading ${component.id.value}...';
  }

  String get verifyingMessage {
    return 'Verifying ${component.id.value}...';
  }
}

_RuntimeStackSourceArchivePlanResult _runtimeStackSourceArchivePlan({
  required RuntimeSourceManifest manifest,
  required _RuntimePlatformSpec platformSpec,
  required String tempDirectoryPath,
}) {
  if (manifest.runtimeId.value != platformSpec.runtimeId ||
      manifest.stackId.value != platformSpec.stackId) {
    return const _RuntimeStackSourceArchivePlanFailed(
      'Runtime stack source manifest targets an unsupported runtime.',
    );
  }

  final wineComponentResult = manifest.componentById('wine');

  final archiveComponents = _uniqueRuntimeStackSourceArchiveComponents(
    manifest.components,
  );
  final componentCount = archiveComponents.length;
  return wineComponentResult.match(
    () => const _RuntimeStackSourceArchivePlanFailed(
      'Runtime stack source manifest does not contain a Wine component.',
    ),
    (wineComponent) => _RuntimeStackSourceArchivePlanResolved(
      _RuntimeStackSourceArchivePlan(
        wineComponent: wineComponent,
        sourceComponents: manifest.components,
        components: <_RuntimeStackSourceArchiveComponentPlan>[
          for (var index = 0; index < componentCount; index += 1)
            _runtimeStackSourceArchiveComponentPlan(
              component: archiveComponents[index],
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
  final seenArchiveKeys = <String>{};
  final uniqueComponents = <RuntimeSourceComponent>[];
  for (final component in components) {
    final archiveKey = _runtimeStackSourceArchiveKey(component);
    if (!seenArchiveKeys.add(archiveKey)) {
      continue;
    }
    uniqueComponents.add(component);
  }

  return List.unmodifiable(uniqueComponents);
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

_RuntimeStackSourceArchiveComponentPlan
_runtimeStackSourceArchiveComponentPlan({
  required RuntimeSourceComponent component,
  required int componentIndex,
  required int componentCount,
  required String tempDirectoryPath,
}) {
  final fileName = _fileNameFromUrl(
    component.archiveUrl.value,
  ).match(() => '${component.id.value}.tar.xz', (value) => value);
  return _RuntimeStackSourceArchiveComponentPlan(
    component: component,
    archivePath: _joinPath(tempDirectoryPath, ['$componentIndex-$fileName']),
    startFraction: 0.05 + (componentIndex / componentCount) * 0.55,
    endFraction: 0.05 + ((componentIndex + 1) / componentCount) * 0.55,
  );
}
