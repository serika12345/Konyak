import 'dart:async';
import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../domain/runtime/runtime_component_versions.dart';
import '../domain/runtime/runtime_package_installation.dart';
import '../domain/runtime/runtime_platform_support.dart';
import '../domain/runtime/runtime_source_bundle_models.dart';
import '../domain/runtime/wine_runtime_paths.dart';
import '../domain/shared/domain_value_objects.dart';
import '../platform/linux/linux_wine_install_results.dart';
import 'directory_copy_support.dart';
import 'linux_wine_installation.dart';
import 'platform_runtime_sources.dart';
import 'runtime_install_progress_io.dart';
import 'runtime_platform_records.dart';
import 'runtime_probes.dart';
import 'runtime_source_archive_downloads.dart';
import 'runtime_source_archive_support.dart';
import 'runtime_source_manifest_support.dart';

extension DartIoLinuxWineInstallerOperations on DartIoLinuxWineInstaller {
  LinuxWineInstallResult installLinuxWineArchive({
    required String archivePath,
    required Option<String> archiveSha256,
    Iterable<String> componentArchivePaths = const <String>[],
    RuntimeComponentVersions componentVersions =
        const RuntimeComponentVersions.empty(),
    RuntimeInstallProgressSink? progressSink,
  }) {
    final installResult = runtimePackageInstaller.install(
      RuntimePackageInstallRequest(
        runtimeLabel: 'Linux Wine',
        archivePath: RuntimeArchivePath(archivePath),
        archiveSha256: archiveSha256.map(RuntimeArchiveChecksumValue.new),
        componentArchivePaths: componentArchivePaths.map(
          RuntimeArchivePath.new,
        ),
        componentVersions: componentVersions,
        runtimeRoot: RuntimeRootPath(linuxWineRuntimeRoot(environment)),
        requiredExecutableRelativePath: RuntimeRelativePath(
          linuxWineRuntimePlatformSpec.requiredExecutableRelativePath,
        ),
        expectedExecutablePath: RuntimeComponentPath(
          linuxWineExecutable(environment),
        ),
      ),
      progressSink: progressSink,
    );
    switch (installResult) {
      case RuntimePackageInstallFailed(:final message):
        return LinuxWineInstallFailed(message);
      case RuntimePackageInstallCompleted():
        break;
    }

    final runtime = linuxWineRuntimeRecord(
      environment: environment,
      fileStatusProbe: const DartIoFileStatusProbe(),
      runtimeStackVersionProbe: runtimeStackVersionProbe,
    );
    if (runtime.isInstalled.toNullable() != true) {
      return LinuxWineInstallFailed(
        'Linux Wine archive did not install '
        '`${runtime.executablePath.toNullable()}`.',
      );
    }

    emitRuntimeInstallProgress(
      progressSink,
      stage: 'complete',
      message: 'Installed Konyak Linux Wine.',
      fraction: 1,
    );

    return LinuxWineInstallCompleted(runtime: runtime);
  }

  LinuxWineInstallResult installLinuxWineStackFromSourceManifest(
    String sourceManifest, {
    required String? sourceManifestSignature,
    required RuntimeInstallProgressSink? progressSink,
  }) {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-linux-wine-stack-',
    );
    try {
      emitRuntimeInstallProgress(
        progressSink,
        stage: 'readingManifest',
        message: 'Reading Konyak Linux Wine manifest...',
        fraction: 0.02,
      );
      final manifestPayload = readRuntimeStackSourceText(
        sourceManifest,
        signatureSource: sourceManifestSignature,
      );
      return runtimeStackSourceManifestFromPayload(manifestPayload).match(
        () => const LinuxWineInstallFailed(
          'Runtime stack source manifest is invalid.',
        ),
        (manifest) {
          final bundleResult = resolveRuntimeStackSourceArchiveBundle(
            manifest: manifest,
            platformSpec: linuxWineRuntimePlatformSpec,
            tempDirectory: tempDirectory,
            progressSink: progressSink,
          );
          return switch (bundleResult) {
            RuntimeStackSourceArchiveBundleFailed(:final message) =>
              LinuxWineInstallFailed(message),
            RuntimeStackSourceArchiveBundleResolved(:final bundle) =>
              installLinuxWineArchive(
                archivePath: bundle.wineArchivePath.value,
                archiveSha256: const Option.none(),
                componentArchivePaths: bundle.componentArchivePaths.map(
                  (path) => path.value,
                ),
                componentVersions: bundle.componentVersions,
                progressSink: progressSink,
              ),
          };
        },
      );
    } on FileSystemException catch (error) {
      return LinuxWineInstallFailed(error.message);
    } on ProcessException catch (error) {
      return LinuxWineInstallFailed(error.message);
    } finally {
      deleteDirectoryIfPresent(tempDirectory);
    }
  }

  Future<LinuxWineInstallResult>
  installLinuxWineStackFromSourceManifestStreaming(
    String sourceManifest, {
    required String? sourceManifestSignature,
    required RuntimeInstallProgressSink? progressSink,
  }) async {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-linux-wine-stack-',
    );
    try {
      emitRuntimeInstallProgress(
        progressSink,
        stage: 'readingManifest',
        message: 'Reading Konyak Linux Wine manifest...',
        fraction: 0.02,
      );
      final manifestPayload = readRuntimeStackSourceText(
        sourceManifest,
        signatureSource: sourceManifestSignature,
      );
      return await runtimeStackSourceManifestFromPayload(manifestPayload).match(
        () async => const LinuxWineInstallFailed(
          'Runtime stack source manifest is invalid.',
        ),
        (manifest) async {
          final bundleResult =
              await resolveRuntimeStackSourceArchiveBundleStreaming(
                manifest: manifest,
                platformSpec: linuxWineRuntimePlatformSpec,
                tempDirectory: tempDirectory,
                progressSink: progressSink,
              );
          return switch (bundleResult) {
            RuntimeStackSourceArchiveBundleFailed(:final message) =>
              LinuxWineInstallFailed(message),
            RuntimeStackSourceArchiveBundleResolved(:final bundle) =>
              installLinuxWineArchive(
                archivePath: bundle.wineArchivePath.value,
                archiveSha256: const Option.none(),
                componentArchivePaths: bundle.componentArchivePaths.map(
                  (path) => path.value,
                ),
                componentVersions: bundle.componentVersions,
                progressSink: progressSink,
              ),
          };
        },
      );
    } on FileSystemException catch (error) {
      return LinuxWineInstallFailed(error.message);
    } on ProcessException catch (error) {
      return LinuxWineInstallFailed(error.message);
    } finally {
      deleteDirectoryIfPresent(tempDirectory);
    }
  }

  String readRuntimeStackSourceText(
    String source, {
    required String? signatureSource,
  }) {
    return readAndVerifyRuntimeStackSourceText(
      source: source,
      signatureSource: signatureSource,
      publicKeyPath: environment
          .nonEmptyValue('KONYAK_RUNTIME_STACK_PUBLIC_KEY_PATH')
          .match(
            () => environment
                .nonEmptyValue('KONYAK_LINUX_WINE_STACK_PUBLIC_KEY_PATH')
                .toNullable(),
            (value) => value,
          ),
      publicKeyText: environment
          .nonEmptyValue('KONYAK_RUNTIME_STACK_PUBLIC_KEY')
          .match(
            () => environment
                .nonEmptyValue('KONYAK_LINUX_WINE_STACK_PUBLIC_KEY')
                .toNullable(),
            (value) => value,
          ),
    );
  }
}
