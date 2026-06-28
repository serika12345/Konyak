import 'dart:async';
import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../domain/program/program_runner.dart';
import '../domain/runtime/host_environment.dart';
import '../domain/runtime/runtime_install_plans.dart';
import '../domain/runtime/runtime_models.dart';
import '../domain/runtime/runtime_platform_support.dart';
import '../domain/runtime/runtime_validation_models.dart';
import '../domain/runtime/runtime_validation_support.dart';
import '../platform/macos/macos_wine_install_requests.dart';
import '../platform/macos/macos_wine_install_results.dart';
import '../shared/common_helpers.dart';
import 'directory_copy_support.dart';
import 'macos_wine_archive_installation.dart';
import 'macos_wine_layout_normalization.dart';
import 'platform_host_paths.dart';
import 'runtime_install_progress_io.dart';
import 'runtime_package_installer_io.dart';
import 'runtime_platform_records.dart';
import 'runtime_probes.dart';
import 'runtime_source_archive_downloads.dart';

class DartIoMacosWineInstaller implements MacosWineStreamingInstaller {
  DartIoMacosWineInstaller({
    required this.hostPlatform,
    required this.environment,
    this.fileStatusProbe = const DartIoFileStatusProbe(),
    this.runtimeStackVersionProbe = const DartIoRuntimeStackVersionProbe(),
    RuntimePackageInstaller? runtimePackageInstaller,
  }) : runtimePackageInstaller =
           runtimePackageInstaller ?? macosRuntimePackageInstaller();

  factory DartIoMacosWineInstaller.current() {
    return DartIoMacosWineInstaller(
      hostPlatform: currentHostPlatform(),
      environment: HostEnvironment(Platform.environment),
    );
  }

  final KonyakHostPlatform hostPlatform;
  final HostEnvironment environment;
  final FileStatusProbe fileStatusProbe;
  final RuntimeStackVersionProbe runtimeStackVersionProbe;
  final RuntimePackageInstaller runtimePackageInstaller;

  @override
  MacosWineInstallResult install(
    MacosWineInstallRequest request, {
    RuntimeInstallProgressSink? progressSink,
  }) {
    final progress = request.emitProgress ? progressSink : null;
    emitRuntimeInstallProgress(
      progress,
      stage: 'preparing',
      message: 'Preparing Konyak macOS Wine install...',
      fraction: 0,
    );

    final currentRuntime = macosWineRuntimeRecord(
      environment: environment,
      fileStatusProbe: fileStatusProbe,
      runtimeStackVersionProbe: runtimeStackVersionProbe,
    );
    final plan = macosWineInstallPlan(
      hostPlatform: hostPlatform,
      environment: environment,
      request: request,
      currentRuntime: currentRuntime,
    );

    switch (plan) {
      case RuntimeWineInstallUnsupported(:final message):
        return MacosWineInstallFailed(message);
      case RuntimeWineInstallAlreadyInstalled(:final runtime):
        emitRuntimeInstallProgress(
          progress,
          stage: 'complete',
          message: 'Konyak macOS Wine is already installed.',
          fraction: 1,
        );
        return MacosWineInstallCompleted(runtime: runtime);
      case RuntimeWineInstallIncompleteWithoutSource(:final message):
        return MacosWineInstallFailed(message);
      case RuntimeWineInstallFromSourceManifest(
        :final sourceManifest,
        :final sourceManifestSignature,
        :final preserveExistingRuntimeFiles,
      ):
        return installMacosWineStackFromSourceManifest(
          sourceManifest.value,
          sourceManifestSignature: sourceManifestSignature.asOption
              .toNullable()
              ?.value,
          preserveExistingRuntimeFiles: preserveExistingRuntimeFiles,
          progressSink: progress,
        );
      case RuntimeWineInstallFromArchive(
        :final archivePath,
        :final archiveSha256,
        :final componentArchivePaths,
        :final preserveExistingRuntimeFiles,
      ):
        return installMacosWineArchive(
          archivePath: archivePath.value,
          archiveSha256: archiveSha256.asOption.map(
            (checksum) => checksum.value,
          ),
          componentArchivePaths: componentArchivePaths.map(
            (path) => path.value,
          ),
          preserveExistingRuntimeFiles: preserveExistingRuntimeFiles,
          progressSink: progress,
        );
      case RuntimeWineInstallMissingArchiveSource(:final message):
        return MacosWineInstallFailed(message);
      case RuntimeWineInstallDownloadArchive(
        :final archiveUrl,
        :final archiveFileName,
        :final archiveSha256,
        :final componentArchivePaths,
        :final preserveExistingRuntimeFiles,
      ):
        final tempDirectory = Directory.systemTemp.createTempSync(
          'konyak-macos-wine-',
        );
        final downloadedArchivePath = joinPath(tempDirectory.path, [
          archiveFileName,
        ]);

        try {
          return downloadRuntimeStackSourceArchive(
            source: archiveUrl.value,
            targetPath: downloadedArchivePath,
            progressSink: progress,
            stage: 'downloading',
            message: 'Downloading Konyak macOS Wine...',
            startFraction: 0.05,
            endFraction: 0.65,
          ).match(
            MacosWineInstallFailed.new,
            (_) => installMacosWineArchive(
              archivePath: downloadedArchivePath,
              archiveSha256: archiveSha256.asOption.map(
                (checksum) => checksum.value,
              ),
              componentArchivePaths: componentArchivePaths.map(
                (path) => path.value,
              ),
              preserveExistingRuntimeFiles: preserveExistingRuntimeFiles,
              progressSink: progress,
            ),
          );
        } on FileSystemException catch (error) {
          return MacosWineInstallFailed(error.message);
        } on ProcessException catch (error) {
          return MacosWineInstallFailed(error.message);
        } finally {
          deleteDirectoryIfPresent(tempDirectory);
        }
    }
  }

  @override
  Future<MacosWineInstallResult> installStreaming(
    MacosWineInstallRequest request, {
    RuntimeInstallProgressSink? progressSink,
  }) async {
    final progress = request.emitProgress ? progressSink : null;
    emitRuntimeInstallProgress(
      progress,
      stage: 'preparing',
      message: 'Preparing Konyak macOS Wine install...',
      fraction: 0,
    );

    final currentRuntime = macosWineRuntimeRecord(
      environment: environment,
      fileStatusProbe: fileStatusProbe,
      runtimeStackVersionProbe: runtimeStackVersionProbe,
    );
    final plan = macosWineInstallPlan(
      hostPlatform: hostPlatform,
      environment: environment,
      request: request,
      currentRuntime: currentRuntime,
    );

    switch (plan) {
      case RuntimeWineInstallUnsupported(:final message):
        return MacosWineInstallFailed(message);
      case RuntimeWineInstallAlreadyInstalled(:final runtime):
        emitRuntimeInstallProgress(
          progress,
          stage: 'complete',
          message: 'Konyak macOS Wine is already installed.',
          fraction: 1,
        );
        return MacosWineInstallCompleted(runtime: runtime);
      case RuntimeWineInstallIncompleteWithoutSource(:final message):
        return MacosWineInstallFailed(message);
      case RuntimeWineInstallFromSourceManifest(
        :final sourceManifest,
        :final sourceManifestSignature,
        :final preserveExistingRuntimeFiles,
      ):
        return installMacosWineStackFromSourceManifestStreaming(
          sourceManifest.value,
          sourceManifestSignature: sourceManifestSignature.asOption
              .toNullable()
              ?.value,
          preserveExistingRuntimeFiles: preserveExistingRuntimeFiles,
          progressSink: progress,
        );
      case RuntimeWineInstallFromArchive(
        :final archivePath,
        :final archiveSha256,
        :final componentArchivePaths,
        :final preserveExistingRuntimeFiles,
      ):
        return installMacosWineArchive(
          archivePath: archivePath.value,
          archiveSha256: archiveSha256.asOption.map(
            (checksum) => checksum.value,
          ),
          componentArchivePaths: componentArchivePaths.map(
            (path) => path.value,
          ),
          preserveExistingRuntimeFiles: preserveExistingRuntimeFiles,
          progressSink: progress,
        );
      case RuntimeWineInstallMissingArchiveSource(:final message):
        return MacosWineInstallFailed(message);
      case RuntimeWineInstallDownloadArchive(
        :final archiveUrl,
        :final archiveFileName,
        :final archiveSha256,
        :final componentArchivePaths,
        :final preserveExistingRuntimeFiles,
      ):
        final tempDirectory = Directory.systemTemp.createTempSync(
          'konyak-macos-wine-',
        );
        final downloadedArchivePath = joinPath(tempDirectory.path, [
          archiveFileName,
        ]);

        try {
          return (await downloadRuntimeStackSourceArchiveStreaming(
            source: archiveUrl.value,
            targetPath: downloadedArchivePath,
            progressSink: progress,
            stage: 'downloading',
            message: 'Downloading Konyak macOS Wine...',
            startFraction: 0.05,
            endFraction: 0.65,
          )).match(
            MacosWineInstallFailed.new,
            (_) => installMacosWineArchive(
              archivePath: downloadedArchivePath,
              archiveSha256: archiveSha256.asOption.map(
                (checksum) => checksum.value,
              ),
              componentArchivePaths: componentArchivePaths.map(
                (path) => path.value,
              ),
              preserveExistingRuntimeFiles: preserveExistingRuntimeFiles,
              progressSink: progress,
            ),
          );
        } on FileSystemException catch (error) {
          return MacosWineInstallFailed(error.message);
        } on ProcessException catch (error) {
          return MacosWineInstallFailed(error.message);
        } finally {
          deleteDirectoryIfPresent(tempDirectory);
        }
    }
  }
}

RuntimePackageInstaller macosRuntimePackageInstaller() {
  return DartIoRuntimePackageInstaller(
    preserveExistingRuntimeComponents: preserveImportedGptkD3DMetalComponent,
    normalizeStagingRoot:
        macosKonyakRuntimePlatformSpec.layoutNormalization ==
            RuntimeLayoutNormalization.macosWineBundle
        ? normalizeMacosWineRuntimeLayout
        : null,
  );
}

RuntimeWineInstallPlan macosWineInstallPlan({
  required KonyakHostPlatform hostPlatform,
  required HostEnvironment environment,
  required MacosWineInstallRequest request,
  required RuntimeRecord currentRuntime,
}) {
  return runtimeWineInstallPlan(
    hostPlatformSupported: hostPlatform == KonyakHostPlatform.macos,
    unsupportedPlatformMessage:
        'macOS Wine installation is supported on macOS only.',
    requestOperation: request.requestOperation,
    currentRuntime: currentRuntime,
    configuredSourceManifest: runtimeSourceManifestForPlatform(
      platformSpec: macosKonyakRuntimePlatformSpec,
      environment: environment,
    ),
    configuredSourceManifestSignature:
        runtimeSourceManifestSignatureForPlatform(
          platformSpec: macosKonyakRuntimePlatformSpec,
          environment: environment,
        ),
    defaultArchiveFileName:
        macosKonyakRuntimePlatformSpec.defaultArchiveFileName,
    missingArchiveMessage: Option.of(
      'macOS Wine source manifest is not configured.',
    ),
    incompleteRuntimeMessage: Option.of(
      'Konyak macOS Wine is installed, but the runtime stack is incomplete. '
      'Configure KONYAK_DEV_MACOS_WINE_STACK_MANIFEST or '
      'KONYAK_MACOS_WINE_STACK_MANIFEST, or pass --source-manifest to '
      'repair it.',
    ),
  );
}
