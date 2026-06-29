import 'dart:io';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import '../domain/runtime/runtime_component_versions.dart';
import '../domain/runtime/runtime_package_installation.dart';
import 'runtime_archive_install_support.dart';
import 'runtime_install_progress_io.dart';

abstract interface class RuntimePackageInstaller {
  RuntimePackageInstallResult install(
    RuntimePackageInstallRequest request, {
    RuntimeInstallProgressSink? progressSink,
  });
}

class DartIoRuntimePackageInstaller implements RuntimePackageInstaller {
  const DartIoRuntimePackageInstaller({
    this.preserveExistingRuntimeComponents,
    this.normalizeStagingRoot,
    this.afterManifestWrite,
  });

  final RuntimeComponentVersions Function({
    required Directory existingRuntimeRoot,
    required Directory stagingRuntimeRoot,
    required RuntimeComponentVersions componentVersions,
  })?
  preserveExistingRuntimeComponents;
  final void Function(Directory runtimeRoot)? normalizeStagingRoot;
  final void Function(Directory runtimeRoot)? afterManifestWrite;

  @override
  RuntimePackageInstallResult install(
    RuntimePackageInstallRequest request, {
    RuntimeInstallProgressSink? progressSink,
  }) {
    return installRuntimeArchives(
      runtimeLabel: request.runtimeLabel,
      archivePath: request.archivePath.value,
      archiveSha256: request.archiveSha256
          .map((value) => value.value)
          .toNullable(),
      componentArchivePaths: request.componentArchivePaths
          .map((value) => value.value)
          .toIList(),
      componentVersions: request.componentVersions,
      runtimeRoot: Directory(request.runtimeRoot.value),
      requiredExecutableRelativePath:
          request.requiredExecutableRelativePath.value,
      expectedExecutablePath: request.expectedExecutablePath.value,
      preserveExistingRuntimeFiles: request.preserveExistingRuntimeFiles,
      preserveExistingRuntimeSkipRelativePaths: request
          .preserveExistingRuntimeSkipRelativePaths
          .map((path) => path.value)
          .toList(growable: false),
      preserveExistingRuntimeComponents: preserveExistingRuntimeComponents,
      normalizeStagingRoot: normalizeStagingRoot,
      afterManifestWrite: afterManifestWrite,
      progressSink: progressSink,
    ).match<RuntimePackageInstallResult>(
      RuntimePackageInstallFailed.new,
      (_) => const RuntimePackageInstallCompleted(),
    );
  }
}
