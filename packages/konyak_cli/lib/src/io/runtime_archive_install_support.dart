import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../domain/runtime/runtime_component_versions.dart';
import '../platform/platform_terminal_commands.dart';
import '../shared/common_helpers.dart';
import '../shared/model_constants.dart';
import 'directory_copy_support.dart';
import 'external_payload_helpers.dart';
import 'file_digest_io.dart';
import 'platform_runtime_sources.dart';
import 'runtime_install_progress_io.dart';
import 'runtime_source_archive_downloads.dart';
import 'runtime_stack_manifest_io.dart';

String? runtimeStackComponentVersion(Object? decoded, String componentId) {
  final components = runtimeStackComponentVersions(decoded);
  return components[componentId];
}

Map<String, String> runtimeStackComponentVersions(Object? decoded) {
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

Either<String, Unit> installRuntimeArchives({
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
  required RuntimeComponentVersions Function({
    required Directory existingRuntimeRoot,
    required Directory stagingRuntimeRoot,
    required RuntimeComponentVersions componentVersions,
  })?
  preserveExistingRuntimeComponents,
  void Function(Directory runtimeRoot)? normalizeStagingRoot,
  void Function(Directory runtimeRoot)? afterManifestWrite,
  RuntimeInstallProgressSink? progressSink,
}) {
  final expectedSha256 = archiveSha256;
  if (expectedSha256 != null) {
    emitRuntimeInstallProgress(
      progressSink,
      stage: 'verifying',
      message: 'Verifying $runtimeLabel archive...',
      fraction: 0.62,
    );
    try {
      final archive = File(archivePath);
      if (!archive.existsSync()) {
        return Left<String, Unit>(
          '$runtimeLabel archive `$archivePath` was not found.',
        );
      }
      final actualSha256 = sha256HexDigest(archive);
      if (actualSha256.toLowerCase() != expectedSha256.toLowerCase()) {
        return Left<String, Unit>(
          '$runtimeLabel archive checksum mismatch: expected '
          '$expectedSha256, got $actualSha256.',
        );
      }
    } on FileSystemException catch (error) {
      return Left<String, Unit>(error.message);
    }
  }

  final stagingRoot = Directory(
    runtimeSiblingPathForInstall(runtimeRoot, 'install'),
  );
  final backupRoot = Directory(
    runtimeSiblingPathForInstall(runtimeRoot, 'previous'),
  );
  final lockFile = File(runtimeInstallLockPath(runtimeRoot));
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
      return Left<String, Unit>(
        '$runtimeLabel installation is already running.',
      );
    }
    if (stagingRoot.existsSync()) {
      stagingRoot.deleteSync(recursive: true);
    }
    stagingRoot.createSync(recursive: true);

    for (var index = 0; index < archivePaths.length; index += 1) {
      final currentArchivePath = archivePaths[index];
      final archive = File(currentArchivePath);
      if (!archive.existsSync()) {
        return Left<String, Unit>(
          '$runtimeLabel archive `$currentArchivePath` was not found.',
        );
      }

      final startFraction = 0.65 + (index / archivePaths.length) * 0.25;
      final endFraction = 0.65 + ((index + 1) / archivePaths.length) * 0.25;
      emitRuntimeInstallProgress(
        progressSink,
        stage: 'extracting',
        message: 'Extracting ${basename(currentArchivePath)}...',
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
        environment: archiveExtractionEnvironment(),
      );
      if (extraction.exitCode != 0) {
        return Left<String, Unit>(
          commandFailureMessage('extract $runtimeLabel', extraction),
        );
      }

      mergeRuntimeStackManifest(
        runtimeRoot: stagingRoot,
        componentVersions: resolvedComponentVersions,
      );
      emitRuntimeInstallProgress(
        progressSink,
        stage: 'extracting',
        message: 'Extracted ${basename(currentArchivePath)}.',
        fraction: endFraction,
      );
    }

    emitRuntimeInstallProgress(
      progressSink,
      stage: 'finalizing',
      message: 'Finalizing $runtimeLabel install...',
      fraction: 0.92,
    );
    normalizeStagingRoot?.call(stagingRoot);
    if (preserveExistingRuntimeFiles && runtimeRoot.existsSync()) {
      copyDirectoryContentsReplacing(
        source: runtimeRoot,
        destination: stagingRoot,
        skipRelativePaths: preserveExistingRuntimeSkipRelativePaths,
      );
      mergeRuntimeStackManifest(
        runtimeRoot: runtimeRoot,
        componentVersions: resolvedComponentVersions,
        overwriteExisting: true,
      );
    }
    if (runtimeRoot.existsSync()) {
      final preservedComponentVersions = preserveExistingRuntimeComponents
          ?.call(
            existingRuntimeRoot: runtimeRoot,
            stagingRuntimeRoot: stagingRoot,
            componentVersions: RuntimeComponentVersions(
              resolvedComponentVersions,
            ),
          );
      if (preservedComponentVersions != null) {
        resolvedComponentVersions
          ..clear()
          ..addAll(preservedComponentVersions.toMap());
      }
    }
    writeRuntimeStackManifest(
      runtimeRoot: stagingRoot,
      componentVersions: resolvedComponentVersions,
    );
    afterManifestWrite?.call(stagingRoot);

    final stagedExecutable = File(
      joinPath(stagingRoot.path, requiredExecutableRelativePath),
    );
    if (!stagedExecutable.existsSync()) {
      return Left<String, Unit>(
        '$runtimeLabel archive did not install `$expectedExecutablePath`.',
      );
    }

    replaceRuntimeRootInPlace(
      runtimeRoot: runtimeRoot,
      stagingRoot: stagingRoot,
      backupRoot: backupRoot,
    );
    emitRuntimeInstallProgress(
      progressSink,
      stage: 'finalizing',
      message: 'Installed $runtimeLabel files.',
      fraction: 0.98,
    );
  } on ProcessException catch (error) {
    return Left<String, Unit>(error.message);
  } on FileSystemException catch (error) {
    return Left<String, Unit>(error.message);
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

  return const Right<String, Unit>(unit);
}

Map<String, String> archiveExtractionEnvironment() {
  final toolSearchPaths = <String>[
    if (Platform.environment['KONYAK_BUNDLE_RESOURCES'] case final resources?)
      if (resources.trim().isNotEmpty) resources.trim(),
    if (isPackagedKonyakCliExecutable(Platform.resolvedExecutable))
      File(Platform.resolvedExecutable).parent.path,
  ];
  if (toolSearchPaths.isEmpty) {
    return const <String, String>{};
  }

  return <String, String>{
    'PATH': prependArchiveToolPaths(
      toolSearchPaths,
      Platform.environment['PATH'],
    ),
  };
}

bool isPackagedKonyakCliExecutable(String executable) {
  return basename(executable) == 'konyak-cli';
}

String prependArchiveToolPaths(Iterable<String> paths, String? existingPath) {
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

String runtimeInstallLockPath(Directory runtimeRoot) {
  return '${runtimeRoot.path}.install.lock';
}
