part of '../../konyak_cli.dart';

class DartIoLinuxWineInstaller implements LinuxWineInstaller {
  DartIoLinuxWineInstaller({
    required this.hostPlatform,
    required Map<String, String> environment,
    FileStatusProbe fileStatusProbe = const DartIoFileStatusProbe(),
    RuntimeStackVersionProbe runtimeStackVersionProbe =
        const DartIoRuntimeStackVersionProbe(),
    RuntimePackageInstaller runtimePackageInstaller =
        const DartIoRuntimePackageInstaller(),
  }) : environment = Map.unmodifiable(environment),
       _fileStatusProbe = fileStatusProbe,
       _runtimeStackVersionProbe = runtimeStackVersionProbe,
       _runtimePackageInstaller = runtimePackageInstaller;

  factory DartIoLinuxWineInstaller.current() {
    return DartIoLinuxWineInstaller(
      hostPlatform: _currentHostPlatform(),
      environment: Platform.environment,
    );
  }

  final KonyakHostPlatform hostPlatform;
  final Map<String, String> environment;
  final FileStatusProbe _fileStatusProbe;
  final RuntimeStackVersionProbe _runtimeStackVersionProbe;
  final RuntimePackageInstaller _runtimePackageInstaller;

  @override
  LinuxWineInstallResult install(
    LinuxWineInstallRequest request, {
    RuntimeInstallProgressSink? progressSink,
  }) {
    final progress = request.emitProgress ? progressSink : null;
    _emitRuntimeInstallProgress(
      progress,
      stage: 'preparing',
      message: 'Preparing Konyak Linux Wine install...',
      fraction: 0,
    );

    final currentRuntime = _linuxWineRuntimeRecord(
      environment: environment,
      fileStatusProbe: _fileStatusProbe,
      runtimeStackVersionProbe: _runtimeStackVersionProbe,
    );
    final plan = _linuxWineInstallPlan(
      hostPlatform: hostPlatform,
      environment: environment,
      request: request,
      currentRuntime: currentRuntime,
    );

    switch (plan) {
      case _RuntimeWineInstallUnsupported(:final message):
        return LinuxWineInstallFailed(message);
      case _RuntimeWineInstallAlreadyInstalled(:final runtime):
        _emitRuntimeInstallProgress(
          progress,
          stage: 'complete',
          message: 'Konyak Linux Wine is already installed.',
          fraction: 1,
        );
        return LinuxWineInstallCompleted(runtime: runtime);
      case _RuntimeWineInstallIncompleteWithoutSource(:final message):
        return LinuxWineInstallFailed(message);
      case _RuntimeWineInstallFromSourceManifest(
        :final sourceManifest,
        :final sourceManifestSignature,
      ):
        return _installLinuxWineStackFromSourceManifest(
          sourceManifest,
          sourceManifestSignature: sourceManifestSignature.asOption
              .toNullable(),
          progressSink: progress,
        );
      case _RuntimeWineInstallFromArchive(
        :final archivePath,
        :final archiveSha256,
        :final componentArchivePaths,
      ):
        return _installLinuxWineArchive(
          archivePath: archivePath,
          archiveSha256: archiveSha256.asOption,
          componentArchivePaths: componentArchivePaths,
          progressSink: progress,
        );
      case _RuntimeWineInstallMissingArchiveSource(:final message):
        return LinuxWineInstallFailed(message);
      case _RuntimeWineInstallDownloadArchive(
        :final archiveUrl,
        :final archiveFileName,
        :final archiveSha256,
        :final componentArchivePaths,
      ):
        final tempDirectory = Directory.systemTemp.createTempSync(
          'konyak-linux-wine-',
        );
        final downloadedArchivePath = _joinPath(tempDirectory.path, [
          archiveFileName,
        ]);

        try {
          final downloadFailure = _downloadRuntimeStackSourceArchive(
            source: archiveUrl,
            targetPath: downloadedArchivePath,
            progressSink: progress,
            stage: 'downloading',
            message: 'Downloading Konyak Linux Wine...',
            startFraction: 0.05,
            endFraction: 0.65,
          );
          if (downloadFailure != null) {
            return LinuxWineInstallFailed(downloadFailure);
          }

          return _installLinuxWineArchive(
            archivePath: downloadedArchivePath,
            archiveSha256: archiveSha256.asOption,
            componentArchivePaths: componentArchivePaths,
            progressSink: progress,
          );
        } on FileSystemException catch (error) {
          return LinuxWineInstallFailed(error.message);
        } on ProcessException catch (error) {
          return LinuxWineInstallFailed(error.message);
        } finally {
          _deleteDirectoryIfPresent(tempDirectory);
        }
    }
  }

  Future<LinuxWineInstallResult> installStreaming(
    LinuxWineInstallRequest request, {
    RuntimeInstallProgressSink? progressSink,
  }) async {
    final progress = request.emitProgress ? progressSink : null;
    _emitRuntimeInstallProgress(
      progress,
      stage: 'preparing',
      message: 'Preparing Konyak Linux Wine install...',
      fraction: 0,
    );

    final currentRuntime = _linuxWineRuntimeRecord(
      environment: environment,
      fileStatusProbe: _fileStatusProbe,
      runtimeStackVersionProbe: _runtimeStackVersionProbe,
    );
    final plan = _linuxWineInstallPlan(
      hostPlatform: hostPlatform,
      environment: environment,
      request: request,
      currentRuntime: currentRuntime,
    );

    switch (plan) {
      case _RuntimeWineInstallUnsupported(:final message):
        return LinuxWineInstallFailed(message);
      case _RuntimeWineInstallAlreadyInstalled(:final runtime):
        _emitRuntimeInstallProgress(
          progress,
          stage: 'complete',
          message: 'Konyak Linux Wine is already installed.',
          fraction: 1,
        );
        return LinuxWineInstallCompleted(runtime: runtime);
      case _RuntimeWineInstallIncompleteWithoutSource(:final message):
        return LinuxWineInstallFailed(message);
      case _RuntimeWineInstallFromSourceManifest(
        :final sourceManifest,
        :final sourceManifestSignature,
      ):
        return _installLinuxWineStackFromSourceManifestStreaming(
          sourceManifest,
          sourceManifestSignature: sourceManifestSignature.asOption
              .toNullable(),
          progressSink: progress,
        );
      case _RuntimeWineInstallFromArchive(
        :final archivePath,
        :final archiveSha256,
        :final componentArchivePaths,
      ):
        return _installLinuxWineArchive(
          archivePath: archivePath,
          archiveSha256: archiveSha256.asOption,
          componentArchivePaths: componentArchivePaths,
          progressSink: progress,
        );
      case _RuntimeWineInstallMissingArchiveSource(:final message):
        return LinuxWineInstallFailed(message);
      case _RuntimeWineInstallDownloadArchive(
        :final archiveUrl,
        :final archiveFileName,
        :final archiveSha256,
        :final componentArchivePaths,
      ):
        final tempDirectory = Directory.systemTemp.createTempSync(
          'konyak-linux-wine-',
        );
        final downloadedArchivePath = _joinPath(tempDirectory.path, [
          archiveFileName,
        ]);

        try {
          final downloadFailure =
              await _downloadRuntimeStackSourceArchiveStreaming(
                source: archiveUrl,
                targetPath: downloadedArchivePath,
                progressSink: progress,
                stage: 'downloading',
                message: 'Downloading Konyak Linux Wine...',
                startFraction: 0.05,
                endFraction: 0.65,
              );
          if (downloadFailure != null) {
            return LinuxWineInstallFailed(downloadFailure);
          }

          return _installLinuxWineArchive(
            archivePath: downloadedArchivePath,
            archiveSha256: archiveSha256.asOption,
            componentArchivePaths: componentArchivePaths,
            progressSink: progress,
          );
        } on FileSystemException catch (error) {
          return LinuxWineInstallFailed(error.message);
        } on ProcessException catch (error) {
          return LinuxWineInstallFailed(error.message);
        } finally {
          _deleteDirectoryIfPresent(tempDirectory);
        }
    }
  }
}

_RuntimeWineInstallPlan _linuxWineInstallPlan({
  required KonyakHostPlatform hostPlatform,
  required Map<String, String> environment,
  required LinuxWineInstallRequest request,
  required RuntimeRecord currentRuntime,
}) {
  final hostEnvironment = HostEnvironment(environment);
  return _runtimeWineInstallPlan(
    hostPlatformSupported: hostPlatform == KonyakHostPlatform.linux,
    unsupportedPlatformMessage:
        'Linux Wine installation is supported on Linux only.',
    requestOperation: request.requestOperation,
    currentRuntime: currentRuntime,
    configuredSourceManifest: _runtimeSourceManifestForPlatform(
      platformSpec: _linuxWineRuntimePlatformSpec,
      environment: hostEnvironment,
    ),
    configuredSourceManifestSignature:
        _runtimeSourceManifestSignatureForPlatform(
          platformSpec: _linuxWineRuntimePlatformSpec,
          environment: hostEnvironment,
        ),
    defaultArchiveUrl: _runtimeDefaultArchiveUrl(
      platformSpec: _linuxWineRuntimePlatformSpec,
      environment: hostEnvironment,
    ),
    defaultArchiveFileName:
        _linuxWineRuntimePlatformSpec.defaultArchiveFileName,
    missingArchiveMessage: Option.of('Linux Wine archive is not configured.'),
    incompleteRuntimeMessage: const Option.none(),
  );
}
