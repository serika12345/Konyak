part of '../../konyak_cli.dart';

String? _runtimeStackComponentVersion(Object? decoded, String componentId) {
  final components = _runtimeStackComponentVersions(decoded);
  return components[componentId];
}

Map<String, String> _runtimeStackComponentVersions(Object? decoded) {
  if (decoded is! Map<String, dynamic>) {
    return const <String, String>{};
  }
  if (decoded['schemaVersion'] != runtimeStackSchemaVersion) {
    return const <String, String>{};
  }

  final components = decoded['components'];
  if (components is! Map<String, dynamic>) {
    return const <String, String>{};
  }

  final versions = <String, String>{};
  for (final entry in components.entries) {
    final version = entry.value;
    if (version is String && version.isNotEmpty) {
      versions[entry.key] = version;
    }
  }

  return Map.unmodifiable(versions);
}

String? _installRuntimeArchives({
  required String runtimeLabel,
  required String archivePath,
  required String? archiveSha256,
  required Iterable<String> componentArchivePaths,
  required RuntimeComponentVersions componentVersions,
  required Directory runtimeRoot,
  required List<String> requiredExecutableRelativePath,
  required String expectedExecutablePath,
  required bool preserveExistingRuntimeFiles,
  required List<List<String>> preserveExistingRuntimeSkipRelativePaths,
  required void Function({
    required Directory existingRuntimeRoot,
    required Directory stagingRuntimeRoot,
    required Map<String, String> componentVersions,
  })?
  preserveExistingRuntimeComponents,
  void Function(Directory runtimeRoot)? normalizeStagingRoot,
  void Function(Directory runtimeRoot)? afterManifestWrite,
  RuntimeInstallProgressSink? progressSink,
}) {
  final expectedSha256 = archiveSha256;
  if (expectedSha256 != null) {
    _emitRuntimeInstallProgress(
      progressSink,
      stage: 'verifying',
      message: 'Verifying $runtimeLabel archive...',
      fraction: 0.62,
    );
    try {
      final archive = File(archivePath);
      if (!archive.existsSync()) {
        return '$runtimeLabel archive `$archivePath` was not found.';
      }
      final actualSha256 = _sha256HexDigest(archive);
      if (actualSha256.toLowerCase() != expectedSha256.toLowerCase()) {
        return '$runtimeLabel archive checksum mismatch: expected '
            '$expectedSha256, got $actualSha256.';
      }
    } on FileSystemException catch (error) {
      return error.message;
    }
  }

  final stagingRoot = Directory(
    _runtimeSiblingPathForInstall(runtimeRoot, 'install'),
  );
  final backupRoot = Directory(
    _runtimeSiblingPathForInstall(runtimeRoot, 'previous'),
  );
  final lockFile = File(_runtimeInstallLockPath(runtimeRoot));
  final resolvedComponentVersions = <String, String>{
    ...componentVersions.toMap(),
  };
  final archivePaths = <String>[archivePath, ...componentArchivePaths];
  var lockCreated = false;

  try {
    runtimeRoot.parent.createSync(recursive: true);
    try {
      lockFile.createSync(exclusive: true);
      lockCreated = true;
    } on FileSystemException {
      return '$runtimeLabel installation is already running.';
    }
    if (stagingRoot.existsSync()) {
      stagingRoot.deleteSync(recursive: true);
    }
    stagingRoot.createSync(recursive: true);

    for (var index = 0; index < archivePaths.length; index += 1) {
      final currentArchivePath = archivePaths[index];
      final archive = File(currentArchivePath);
      if (!archive.existsSync()) {
        return '$runtimeLabel archive `$currentArchivePath` was not found.';
      }

      final startFraction = 0.65 + (index / archivePaths.length) * 0.25;
      final endFraction = 0.65 + ((index + 1) / archivePaths.length) * 0.25;
      _emitRuntimeInstallProgress(
        progressSink,
        stage: 'extracting',
        message: 'Extracting ${_basename(currentArchivePath)}...',
        fraction: startFraction,
      );
      final extraction = Process.runSync(
        'tar',
        [
          '-xf',
          currentArchivePath,
          '-C',
          stagingRoot.path,
          '--strip-components',
          '1',
        ],
        runInShell: false,
        environment: _archiveExtractionEnvironment(),
      );
      if (extraction.exitCode != 0) {
        return _commandFailureMessage('extract $runtimeLabel', extraction);
      }

      _mergeRuntimeStackManifest(
        runtimeRoot: stagingRoot,
        componentVersions: resolvedComponentVersions,
      );
      _emitRuntimeInstallProgress(
        progressSink,
        stage: 'extracting',
        message: 'Extracted ${_basename(currentArchivePath)}.',
        fraction: endFraction,
      );
    }

    _emitRuntimeInstallProgress(
      progressSink,
      stage: 'finalizing',
      message: 'Finalizing $runtimeLabel install...',
      fraction: 0.92,
    );
    normalizeStagingRoot?.call(stagingRoot);
    if (preserveExistingRuntimeFiles && runtimeRoot.existsSync()) {
      _copyDirectoryContentsReplacing(
        source: runtimeRoot,
        destination: stagingRoot,
        skipRelativePaths: preserveExistingRuntimeSkipRelativePaths,
      );
      _mergeRuntimeStackManifest(
        runtimeRoot: runtimeRoot,
        componentVersions: resolvedComponentVersions,
        overwriteExisting: true,
      );
    }
    if (runtimeRoot.existsSync()) {
      preserveExistingRuntimeComponents?.call(
        existingRuntimeRoot: runtimeRoot,
        stagingRuntimeRoot: stagingRoot,
        componentVersions: resolvedComponentVersions,
      );
    }
    _writeRuntimeStackManifest(
      runtimeRoot: stagingRoot,
      componentVersions: resolvedComponentVersions,
    );
    afterManifestWrite?.call(stagingRoot);

    final stagedExecutable = File(
      _joinPath(stagingRoot.path, requiredExecutableRelativePath),
    );
    if (!stagedExecutable.existsSync()) {
      return '$runtimeLabel archive did not install `$expectedExecutablePath`.';
    }

    _replaceRuntimeRootInPlace(
      runtimeRoot: runtimeRoot,
      stagingRoot: stagingRoot,
      backupRoot: backupRoot,
    );
    _emitRuntimeInstallProgress(
      progressSink,
      stage: 'finalizing',
      message: 'Installed $runtimeLabel files.',
      fraction: 0.98,
    );
  } on ProcessException catch (error) {
    return error.message;
  } on FileSystemException catch (error) {
    return error.message;
  } finally {
    if (stagingRoot.existsSync()) {
      stagingRoot.deleteSync(recursive: true);
    }
    if (backupRoot.existsSync()) {
      backupRoot.deleteSync(recursive: true);
    }
    if (lockCreated && lockFile.existsSync()) {
      lockFile.deleteSync();
    }
  }

  return null;
}

Map<String, String> _archiveExtractionEnvironment() {
  final toolSearchPaths = <String>[
    if (Platform.environment['KONYAK_BUNDLE_RESOURCES'] case final resources?)
      if (resources.trim().isNotEmpty) resources.trim(),
    if (_isPackagedKonyakCliExecutable(Platform.resolvedExecutable))
      File(Platform.resolvedExecutable).parent.path,
  ];
  if (toolSearchPaths.isEmpty) {
    return const <String, String>{};
  }

  return <String, String>{
    'PATH': _prependArchiveToolPaths(
      toolSearchPaths,
      Platform.environment['PATH'],
    ),
  };
}

bool _isPackagedKonyakCliExecutable(String executable) {
  return _basename(executable) == 'konyak-cli';
}

String _prependArchiveToolPaths(Iterable<String> paths, String? existingPath) {
  final filteredPaths = paths
      .map((path) => path.trim())
      .where((path) => path.isNotEmpty)
      .toList(growable: false);
  final trimmedExistingPath = existingPath?.trim();
  return <String>[
    ...filteredPaths,
    if (trimmedExistingPath != null && trimmedExistingPath.isNotEmpty)
      trimmedExistingPath,
  ].join(':');
}

String _runtimeInstallLockPath(Directory runtimeRoot) {
  return '${runtimeRoot.path}.install.lock';
}
