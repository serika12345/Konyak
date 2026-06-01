part of '../konyak_cli.dart';

RuntimeSourceManifest? _runtimeStackSourceManifestFromPayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException {
    return null;
  }

  if (decoded is! Map<String, dynamic> ||
      decoded['schemaVersion'] != runtimeStackSchemaVersion) {
    return null;
  }

  final runtimeId = decoded['runtimeId'];
  final stackId = decoded['stackId'];
  final components = decoded['components'];
  if (runtimeId is! String ||
      runtimeId.trim().isEmpty ||
      stackId is! String ||
      stackId.trim().isEmpty ||
      components is! List<dynamic>) {
    return null;
  }

  final parsedComponents = <RuntimeSourceComponent>[];
  for (final component in components) {
    final parsedComponent = _runtimeStackSourceComponent(component);
    if (parsedComponent == null) {
      return null;
    }
    parsedComponents.add(parsedComponent);
  }

  if (parsedComponents.isEmpty) {
    return null;
  }

  return RuntimeSourceManifest(
    runtimeId: runtimeId,
    stackId: stackId,
    components: parsedComponents,
  );
}

RuntimeSourceComponent? _runtimeStackSourceComponent(Object? value) {
  if (value is! Map<String, dynamic>) {
    return null;
  }

  final id = value['id'];
  final version = value['version'];
  final archiveUrl = value['archiveUrl'];
  final sha256 = value['sha256'];

  if (id is! String ||
      id.trim().isEmpty ||
      version is! String ||
      version.trim().isEmpty ||
      archiveUrl is! String ||
      archiveUrl.trim().isEmpty ||
      sha256 is! String ||
      !_isSha256Hex(sha256)) {
    return null;
  }

  return RuntimeSourceComponent(
    id: id,
    version: version,
    archiveUrl: archiveUrl,
    sha256: sha256,
  );
}

_RuntimeStackSourceArchiveBundleResult _resolveRuntimeStackSourceArchiveBundle({
  required RuntimeSourceManifest manifest,
  required _RuntimePlatformSpec platformSpec,
  required Directory tempDirectory,
  required RuntimeInstallProgressSink? progressSink,
}) {
  if (manifest.runtimeId != platformSpec.runtimeId ||
      manifest.stackId != platformSpec.stackId) {
    return const _RuntimeStackSourceArchiveBundleFailed(
      'Runtime stack source manifest targets an unsupported runtime.',
    );
  }

  final wineComponent = manifest.componentById('wine');
  if (wineComponent == null) {
    return const _RuntimeStackSourceArchiveBundleFailed(
      'Runtime stack source manifest does not contain a Wine component.',
    );
  }

  final archivePaths = <String, String>{};
  final componentCount = manifest.components.length;
  for (final component in manifest.components) {
    final fileName =
        _fileNameFromUrl(component.archiveUrl) ?? '${component.id}.tar.xz';
    final archivePath = _joinPath(tempDirectory.path, [
      '${archivePaths.length}-$fileName',
    ]);
    final componentIndex = archivePaths.length;
    final startFraction = 0.05 + (componentIndex / componentCount) * 0.55;
    final endFraction = 0.05 + ((componentIndex + 1) / componentCount) * 0.55;
    final downloadFailure = _downloadRuntimeStackSourceArchive(
      source: component.archiveUrl,
      targetPath: archivePath,
      progressSink: progressSink,
      stage: 'downloading',
      message: 'Downloading ${component.id}...',
      startFraction: startFraction,
      endFraction: endFraction,
    );
    if (downloadFailure != null) {
      return _RuntimeStackSourceArchiveBundleFailed(downloadFailure);
    }

    _emitRuntimeInstallProgress(
      progressSink,
      stage: 'verifying',
      message: 'Verifying ${component.id}...',
      fraction: endFraction,
    );
    final actualSha256 = _sha256HexDigest(File(archivePath));
    if (actualSha256.toLowerCase() != component.sha256.toLowerCase()) {
      return _RuntimeStackSourceArchiveBundleFailed(
        'Runtime stack component `${component.id}` checksum mismatch: '
        'expected ${component.sha256}, got $actualSha256.',
      );
    }

    archivePaths[component.id] = archivePath;
  }

  final wineArchivePath = archivePaths[wineComponent.id];
  if (wineArchivePath == null) {
    return const _RuntimeStackSourceArchiveBundleFailed(
      'Runtime stack source manifest did not resolve a Wine archive.',
    );
  }

  return _RuntimeStackSourceArchiveBundleResolved(
    _RuntimeStackSourceArchiveBundle(
      wineArchivePath: wineArchivePath,
      componentArchivePaths: <String>[
        for (final component in manifest.components)
          if (component.id != wineComponent.id) archivePaths[component.id]!,
      ],
      componentVersions: <String, String>{
        for (final component in manifest.components)
          component.id: component.version,
      },
    ),
  );
}
