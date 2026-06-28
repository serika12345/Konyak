part of '../../konyak_cli.dart';

class DartIoLinuxWineInstaller implements LinuxWineInstaller {
  DartIoLinuxWineInstaller({
    required this.hostPlatform,
    required this.environment,
    FileStatusProbe fileStatusProbe = const DartIoFileStatusProbe(),
    RuntimeStackVersionProbe runtimeStackVersionProbe =
        const DartIoRuntimeStackVersionProbe(),
    RuntimePackageInstaller runtimePackageInstaller =
        const DartIoRuntimePackageInstaller(),
  }) : _fileStatusProbe = fileStatusProbe,
       _runtimeStackVersionProbe = runtimeStackVersionProbe,
       _runtimePackageInstaller = runtimePackageInstaller;

  factory DartIoLinuxWineInstaller.current() {
    return DartIoLinuxWineInstaller(
      hostPlatform: _currentHostPlatform(),
      environment: HostEnvironment(Platform.environment),
    );
  }

  final KonyakHostPlatform hostPlatform;
  final HostEnvironment environment;
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
      case RuntimeWineInstallUnsupported(:final message):
        return LinuxWineInstallFailed(message);
      case RuntimeWineInstallAlreadyInstalled(:final runtime):
        _emitRuntimeInstallProgress(
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
        return _installLinuxWineStackFromSourceManifest(
          sourceManifest.value,
          sourceManifestSignature: sourceManifestSignature.asOption
              .toNullable()
              ?.value,
          progressSink: progress,
        );
      case RuntimeWineInstallFromArchive(
        :final archivePath,
        :final archiveSha256,
        :final componentArchivePaths,
      ):
        return _installLinuxWineArchive(
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
        final downloadedArchivePath = _joinPath(tempDirectory.path, [
          archiveFileName,
        ]);

        try {
          return _downloadRuntimeStackSourceArchive(
            source: archiveUrl.value,
            targetPath: downloadedArchivePath,
            progressSink: progress,
            stage: 'downloading',
            message: 'Downloading Konyak Linux Wine...',
            startFraction: 0.05,
            endFraction: 0.65,
          ).match(
            LinuxWineInstallFailed.new,
            (_) => _installLinuxWineArchive(
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
      case RuntimeWineInstallUnsupported(:final message):
        return LinuxWineInstallFailed(message);
      case RuntimeWineInstallAlreadyInstalled(:final runtime):
        _emitRuntimeInstallProgress(
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
        return _installLinuxWineStackFromSourceManifestStreaming(
          sourceManifest.value,
          sourceManifestSignature: sourceManifestSignature.asOption
              .toNullable()
              ?.value,
          progressSink: progress,
        );
      case RuntimeWineInstallFromArchive(
        :final archivePath,
        :final archiveSha256,
        :final componentArchivePaths,
      ):
        return _installLinuxWineArchive(
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
        final downloadedArchivePath = _joinPath(tempDirectory.path, [
          archiveFileName,
        ]);

        try {
          return (await _downloadRuntimeStackSourceArchiveStreaming(
            source: archiveUrl.value,
            targetPath: downloadedArchivePath,
            progressSink: progress,
            stage: 'downloading',
            message: 'Downloading Konyak Linux Wine...',
            startFraction: 0.05,
            endFraction: 0.65,
          )).match(
            LinuxWineInstallFailed.new,
            (_) => _installLinuxWineArchive(
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
          _deleteDirectoryIfPresent(tempDirectory);
        }
    }
  }
}

RuntimeWineInstallPlan _linuxWineInstallPlan({
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
    defaultArchiveFileName: linuxWineRuntimePlatformSpec.defaultArchiveFileName,
    missingArchiveMessage: Option.of(
      'Linux Wine source manifest is not configured.',
    ),
    incompleteRuntimeMessage: const Option.none(),
  );
}
