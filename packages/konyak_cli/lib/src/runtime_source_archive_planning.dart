part of '../konyak_cli.dart';

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
    required Iterable<_RuntimeStackSourceArchiveComponentPlan> components,
  }) : components = List.unmodifiable(components);

  final RuntimeSourceComponent wineComponent;
  final List<_RuntimeStackSourceArchiveComponentPlan> components;

  _RuntimeStackSourceArchiveBundle toBundle() {
    return _RuntimeStackSourceArchiveBundle(
      wineArchivePath: _archivePathFor(wineComponent.id),
      componentArchivePaths: <String>[
        for (final component in components)
          if (component.component.id != wineComponent.id) component.archivePath,
      ],
      componentVersions: <String, String>{
        for (final component in components)
          component.component.id: component.component.version,
      },
    );
  }

  String _archivePathFor(String componentId) {
    for (final component in components) {
      if (component.component.id == componentId) {
        return component.archivePath;
      }
    }

    throw StateError(
      'Runtime stack source archive plan does not contain $componentId.',
    );
  }
}

final class _RuntimeStackSourceArchiveComponentPlan {
  const _RuntimeStackSourceArchiveComponentPlan({
    required this.component,
    required this.archivePath,
    required this.startFraction,
    required this.endFraction,
  });

  final RuntimeSourceComponent component;
  final String archivePath;
  final double startFraction;
  final double endFraction;

  String get downloadingMessage {
    return 'Downloading ${component.id}...';
  }

  String get verifyingMessage {
    return 'Verifying ${component.id}...';
  }
}

_RuntimeStackSourceArchivePlanResult _runtimeStackSourceArchivePlan({
  required RuntimeSourceManifest manifest,
  required _RuntimePlatformSpec platformSpec,
  required String tempDirectoryPath,
}) {
  if (manifest.runtimeId != platformSpec.runtimeId ||
      manifest.stackId != platformSpec.stackId) {
    return const _RuntimeStackSourceArchivePlanFailed(
      'Runtime stack source manifest targets an unsupported runtime.',
    );
  }

  final wineComponent = manifest.componentById('wine');
  if (wineComponent == null) {
    return const _RuntimeStackSourceArchivePlanFailed(
      'Runtime stack source manifest does not contain a Wine component.',
    );
  }

  final componentCount = manifest.components.length;
  return _RuntimeStackSourceArchivePlanResolved(
    _RuntimeStackSourceArchivePlan(
      wineComponent: wineComponent,
      components: <_RuntimeStackSourceArchiveComponentPlan>[
        for (var index = 0; index < componentCount; index += 1)
          _runtimeStackSourceArchiveComponentPlan(
            component: manifest.components[index],
            componentIndex: index,
            componentCount: componentCount,
            tempDirectoryPath: tempDirectoryPath,
          ),
      ],
    ),
  );
}

_RuntimeStackSourceArchiveComponentPlan
_runtimeStackSourceArchiveComponentPlan({
  required RuntimeSourceComponent component,
  required int componentIndex,
  required int componentCount,
  required String tempDirectoryPath,
}) {
  final fileName =
      _fileNameFromUrl(component.archiveUrl) ?? '${component.id}.tar.xz';
  return _RuntimeStackSourceArchiveComponentPlan(
    component: component,
    archivePath: _joinPath(tempDirectoryPath, ['$componentIndex-$fileName']),
    startFraction: 0.05 + (componentIndex / componentCount) * 0.55,
    endFraction: 0.05 + ((componentIndex + 1) / componentCount) * 0.55,
  );
}
