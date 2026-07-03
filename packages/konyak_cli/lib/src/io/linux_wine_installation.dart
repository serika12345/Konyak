import 'dart:async';
import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../domain/program/program_runner.dart';
import '../domain/runtime/host_environment.dart';
import '../domain/runtime/runtime_install_plans.dart';
import '../domain/runtime/runtime_models.dart';
import '../domain/runtime/runtime_platform_support.dart';
import '../domain/runtime/runtime_validation_support.dart';
import '../platform/linux/linux_wine_install_requests.dart';
import '../platform/linux/linux_wine_install_results.dart';
import '../shared/common_helpers.dart';
import 'directory_copy_support.dart';
import 'linux_wine_install_operations.dart';
import 'platform_host_paths.dart';
import 'runtime_install_progress_io.dart';
import 'runtime_package_installer_io.dart';
import 'runtime_platform_records.dart';
import 'runtime_probes.dart';
import 'runtime_source_archive_downloads.dart';

class DartIoLinuxWineInstaller implements LinuxWineStreamingInstaller {
  DartIoLinuxWineInstaller({
    required this.hostPlatform,
    required this.environment,
    this.fileStatusProbe = const DartIoFileStatusProbe(),
    this.runtimeStackVersionProbe = const DartIoRuntimeStackVersionProbe(),
    this.runtimePackageInstaller = const DartIoRuntimePackageInstaller(),
  });

  factory DartIoLinuxWineInstaller.current() {
    return DartIoLinuxWineInstaller(
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
  LinuxWineInstallResult install(
    LinuxWineInstallRequest request, {
    RuntimeInstallProgressSink? progressSink,
  }) {
    final progress = request.emitProgress ? progressSink : null;
    emitRuntimeInstallProgress(
      progress,
      stage: 'preparing',
      message: 'Preparing Konyak Linux Wine install...',
      fraction: 0,
    );

    final currentRuntime = linuxWineRuntimeRecord(
      environment: environment,
      fileStatusProbe: fileStatusProbe,
      runtimeStackVersionProbe: runtimeStackVersionProbe,
    );
    final plan = linuxWineInstallPlan(
      hostPlatform: hostPlatform,
      environment: environment,
      request: request,
      currentRuntime: currentRuntime,
    );

    switch (plan) {
      case RuntimeWineInstallUnsupported(:final message):
        return LinuxWineInstallFailed(message);
      case RuntimeWineInstallAlreadyInstalled(:final runtime):
        emitRuntimeInstallProgress(
          progress,
          stage: 'complete',
          message: 'Konyak Linux Wine is already installed.',
          fraction: 1,
        );
        return LinuxWineInstallCompleted(runtime: runtime);
      case RuntimeWineInstallIncompleteWithoutSource(:final message):
        return LinuxWineInstallFailed(message);
      case RuntimeWineInstallFromSourceManifest(
        :final sourceManifest,
        :final sourceManifestSignature,
      ):
        return installLinuxWineStackFromSourceManifest(
          sourceManifest.value,
          sourceManifestSignature: sourceManifestSignature.asOption
              .map((signature) => signature.value)
              .match(() => null, (value) => value),
          progressSink: progress,
        );
      case RuntimeWineInstallFromArchive(
        :final archivePath,
        :final archiveSha256,
        :final componentArchivePaths,
      ):
        return installLinuxWineArchive(
          archivePath: archivePath.value,
          archiveSha256: archiveSha256.asOption.map(
            (checksum) => checksum.value,
          ),
          componentArchivePaths: componentArchivePaths.map(
            (path) => path.value,
          ),
          progressSink: progress,
        );
      case RuntimeWineInstallMissingArchiveSource(:final message):
        return LinuxWineInstallFailed(message);
      case RuntimeWineInstallDownloadArchive(
        :final archiveUrl,
        :final archiveFileName,
        :final archiveSha256,
        :final componentArchivePaths,
      ):
        final tempDirectory = Directory.systemTemp.createTempSync(
          'konyak-linux-wine-',
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
            message: 'Downloading Konyak Linux Wine...',
            startFraction: 0.05,
            endFraction: 0.65,
          ).match(
            LinuxWineInstallFailed.new,
            (_) => installLinuxWineArchive(
              archivePath: downloadedArchivePath,
              archiveSha256: archiveSha256.asOption.map(
                (checksum) => checksum.value,
              ),
              componentArchivePaths: componentArchivePaths.map(
                (path) => path.value,
              ),
              progressSink: progress,
            ),
          );
        } on FileSystemException catch (error) {
          return LinuxWineInstallFailed(error.message);
        } on ProcessException catch (error) {
          return LinuxWineInstallFailed(error.message);
        } finally {
          deleteDirectoryIfPresent(tempDirectory);
        }
    }
  }

  @override
  Future<LinuxWineInstallResult> installStreaming(
    LinuxWineInstallRequest request, {
    RuntimeInstallProgressSink? progressSink,
  }) async {
    final progress = request.emitProgress ? progressSink : null;
    emitRuntimeInstallProgress(
      progress,
      stage: 'preparing',
      message: 'Preparing Konyak Linux Wine install...',
      fraction: 0,
    );

    final currentRuntime = linuxWineRuntimeRecord(
      environment: environment,
      fileStatusProbe: fileStatusProbe,
      runtimeStackVersionProbe: runtimeStackVersionProbe,
    );
    final plan = linuxWineInstallPlan(
      hostPlatform: hostPlatform,
      environment: environment,
      request: request,
      currentRuntime: currentRuntime,
    );

    switch (plan) {
      case RuntimeWineInstallUnsupported(:final message):
        return LinuxWineInstallFailed(message);
      case RuntimeWineInstallAlreadyInstalled(:final runtime):
        emitRuntimeInstallProgress(
          progress,
          stage: 'complete',
          message: 'Konyak Linux Wine is already installed.',
          fraction: 1,
        );
        return LinuxWineInstallCompleted(runtime: runtime);
      case RuntimeWineInstallIncompleteWithoutSource(:final message):
        return LinuxWineInstallFailed(message);
      case RuntimeWineInstallFromSourceManifest(
        :final sourceManifest,
        :final sourceManifestSignature,
      ):
        return installLinuxWineStackFromSourceManifestStreaming(
          sourceManifest.value,
          sourceManifestSignature: sourceManifestSignature.asOption
              .map((signature) => signature.value)
              .match(() => null, (value) => value),
          progressSink: progress,
        );
      case RuntimeWineInstallFromArchive(
        :final archivePath,
        :final archiveSha256,
        :final componentArchivePaths,
      ):
        return installLinuxWineArchive(
          archivePath: archivePath.value,
          archiveSha256: archiveSha256.asOption.map(
            (checksum) => checksum.value,
          ),
          componentArchivePaths: componentArchivePaths.map(
            (path) => path.value,
          ),
          progressSink: progress,
        );
      case RuntimeWineInstallMissingArchiveSource(:final message):
        return LinuxWineInstallFailed(message);
      case RuntimeWineInstallDownloadArchive(
        :final archiveUrl,
        :final archiveFileName,
        :final archiveSha256,
        :final componentArchivePaths,
      ):
        final tempDirectory = Directory.systemTemp.createTempSync(
          'konyak-linux-wine-',
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
            message: 'Downloading Konyak Linux Wine...',
            startFraction: 0.05,
            endFraction: 0.65,
          )).match(
            LinuxWineInstallFailed.new,
            (_) => installLinuxWineArchive(
              archivePath: downloadedArchivePath,
              archiveSha256: archiveSha256.asOption.map(
                (checksum) => checksum.value,
              ),
              componentArchivePaths: componentArchivePaths.map(
                (path) => path.value,
              ),
              progressSink: progress,
            ),
          );
        } on FileSystemException catch (error) {
          return LinuxWineInstallFailed(error.message);
        } on ProcessException catch (error) {
          return LinuxWineInstallFailed(error.message);
        } finally {
          deleteDirectoryIfPresent(tempDirectory);
        }
    }
  }
}

RuntimeWineInstallPlan linuxWineInstallPlan({
  required KonyakHostPlatform hostPlatform,
  required HostEnvironment environment,
  required LinuxWineInstallRequest request,
  required RuntimeRecord currentRuntime,
}) {
  return runtimeWineInstallPlan(
    hostPlatformSupported: hostPlatform == KonyakHostPlatform.linux,
    unsupportedPlatformMessage:
        'Linux Wine installation is supported on Linux only.',
    requestOperation: request.requestOperation,
    currentRuntime: currentRuntime,
    configuredSourceManifest: runtimeSourceManifestForPlatform(
      platformSpec: linuxWineRuntimePlatformSpec,
      environment: environment,
    ),
    configuredSourceManifestSignature:
        runtimeSourceManifestSignatureForPlatform(
          platformSpec: linuxWineRuntimePlatformSpec,
          environment: environment,
        ),
    defaultArchiveFileName:
        linuxWineRuntimePlatformSpec.defaultArchiveFileName.value,
    missingArchiveMessage: Option.of(
      'Linux Wine source manifest is not configured.',
    ),
    incompleteRuntimeMessage: const Option.none(),
  );
}
