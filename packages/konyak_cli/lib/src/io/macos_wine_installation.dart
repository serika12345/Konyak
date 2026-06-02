part of '../../konyak_cli.dart';

class DartIoMacosWineInstaller implements MacosWineInstaller {
  DartIoMacosWineInstaller({
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

  factory DartIoMacosWineInstaller.current() {
    return DartIoMacosWineInstaller(
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
  MacosWineInstallResult install(
    MacosWineInstallRequest request, {
    RuntimeInstallProgressSink? progressSink,
  }) {
    final progress = request.emitProgress ? progressSink : null;
    _emitRuntimeInstallProgress(
      progress,
      stage: 'preparing',
      message: 'Preparing Konyak macOS Wine install...',
      fraction: 0,
    );

    final currentRuntime = _macosWineRuntimeRecord(
      environment: environment,
      fileStatusProbe: _fileStatusProbe,
      runtimeStackVersionProbe: _runtimeStackVersionProbe,
    );
    final plan = _macosWineInstallPlan(
      hostPlatform: hostPlatform,
      environment: environment,
      request: request,
      currentRuntime: currentRuntime,
    );

    switch (plan) {
      case _RuntimeWineInstallUnsupported(:final message):
        return MacosWineInstallFailed(message);
      case _RuntimeWineInstallAlreadyInstalled(:final runtime):
        _emitRuntimeInstallProgress(
          progress,
          stage: 'complete',
          message: 'Konyak macOS Wine is already installed.',
          fraction: 1,
        );
        return MacosWineInstallCompleted(runtime: runtime);
      case _RuntimeWineInstallIncompleteWithoutSource(:final message):
        return MacosWineInstallFailed(message);
      case _RuntimeWineInstallFromSourceManifest(
        :final sourceManifest,
        :final sourceManifestSignature,
        :final preserveExistingRuntimeFiles,
      ):
        return _installMacosWineStackFromSourceManifest(
          sourceManifest,
          sourceManifestSignature: sourceManifestSignature.toNullable(),
          preserveExistingRuntimeFiles: preserveExistingRuntimeFiles,
          progressSink: progress,
        );
      case _RuntimeWineInstallFromArchive(
        :final archivePath,
        :final archiveSha256,
        :final componentArchivePaths,
        :final preserveExistingRuntimeFiles,
      ):
        return _installMacosWineArchive(
          archivePath: archivePath,
          archiveSha256: archiveSha256.toNullable(),
          componentArchivePaths: componentArchivePaths,
          preserveExistingRuntimeFiles: preserveExistingRuntimeFiles,
          progressSink: progress,
        );
      case _RuntimeWineInstallMissingArchiveSource(:final message):
        return MacosWineInstallFailed(message);
      case _RuntimeWineInstallDownloadArchive(
        :final archiveUrl,
        :final archiveFileName,
        :final archiveSha256,
        :final componentArchivePaths,
        :final preserveExistingRuntimeFiles,
      ):
        final tempDirectory = Directory.systemTemp.createTempSync(
          'konyak-macos-wine-',
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
            message: 'Downloading Konyak macOS Wine...',
            startFraction: 0.05,
            endFraction: 0.65,
          );
          if (downloadFailure != null) {
            return MacosWineInstallFailed(downloadFailure);
          }

          return _installMacosWineArchive(
            archivePath: downloadedArchivePath,
            archiveSha256: archiveSha256.toNullable(),
            componentArchivePaths: componentArchivePaths,
            preserveExistingRuntimeFiles: preserveExistingRuntimeFiles,
            progressSink: progress,
          );
        } on FileSystemException catch (error) {
          return MacosWineInstallFailed(error.message);
        } on ProcessException catch (error) {
          return MacosWineInstallFailed(error.message);
        } finally {
          _deleteDirectoryIfPresent(tempDirectory);
        }
    }
  }

  Future<MacosWineInstallResult> installStreaming(
    MacosWineInstallRequest request, {
    RuntimeInstallProgressSink? progressSink,
  }) async {
    final progress = request.emitProgress ? progressSink : null;
    _emitRuntimeInstallProgress(
      progress,
      stage: 'preparing',
      message: 'Preparing Konyak macOS Wine install...',
      fraction: 0,
    );

    final currentRuntime = _macosWineRuntimeRecord(
      environment: environment,
      fileStatusProbe: _fileStatusProbe,
      runtimeStackVersionProbe: _runtimeStackVersionProbe,
    );
    final plan = _macosWineInstallPlan(
      hostPlatform: hostPlatform,
      environment: environment,
      request: request,
      currentRuntime: currentRuntime,
    );

    switch (plan) {
      case _RuntimeWineInstallUnsupported(:final message):
        return MacosWineInstallFailed(message);
      case _RuntimeWineInstallAlreadyInstalled(:final runtime):
        _emitRuntimeInstallProgress(
          progress,
          stage: 'complete',
          message: 'Konyak macOS Wine is already installed.',
          fraction: 1,
        );
        return MacosWineInstallCompleted(runtime: runtime);
      case _RuntimeWineInstallIncompleteWithoutSource(:final message):
        return MacosWineInstallFailed(message);
      case _RuntimeWineInstallFromSourceManifest(
        :final sourceManifest,
        :final sourceManifestSignature,
        :final preserveExistingRuntimeFiles,
      ):
        return _installMacosWineStackFromSourceManifestStreaming(
          sourceManifest,
          sourceManifestSignature: sourceManifestSignature.toNullable(),
          preserveExistingRuntimeFiles: preserveExistingRuntimeFiles,
          progressSink: progress,
        );
      case _RuntimeWineInstallFromArchive(
        :final archivePath,
        :final archiveSha256,
        :final componentArchivePaths,
        :final preserveExistingRuntimeFiles,
      ):
        return _installMacosWineArchive(
          archivePath: archivePath,
          archiveSha256: archiveSha256.toNullable(),
          componentArchivePaths: componentArchivePaths,
          preserveExistingRuntimeFiles: preserveExistingRuntimeFiles,
          progressSink: progress,
        );
      case _RuntimeWineInstallMissingArchiveSource(:final message):
        return MacosWineInstallFailed(message);
      case _RuntimeWineInstallDownloadArchive(
        :final archiveUrl,
        :final archiveFileName,
        :final archiveSha256,
        :final componentArchivePaths,
        :final preserveExistingRuntimeFiles,
      ):
        final tempDirectory = Directory.systemTemp.createTempSync(
          'konyak-macos-wine-',
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
                message: 'Downloading Konyak macOS Wine...',
                startFraction: 0.05,
                endFraction: 0.65,
              );
          if (downloadFailure != null) {
            return MacosWineInstallFailed(downloadFailure);
          }

          return _installMacosWineArchive(
            archivePath: downloadedArchivePath,
            archiveSha256: archiveSha256.toNullable(),
            componentArchivePaths: componentArchivePaths,
            preserveExistingRuntimeFiles: preserveExistingRuntimeFiles,
            progressSink: progress,
          );
        } on FileSystemException catch (error) {
          return MacosWineInstallFailed(error.message);
        } on ProcessException catch (error) {
          return MacosWineInstallFailed(error.message);
        } finally {
          _deleteDirectoryIfPresent(tempDirectory);
        }
    }
  }
}

_RuntimeWineInstallPlan _macosWineInstallPlan({
  required KonyakHostPlatform hostPlatform,
  required Map<String, String> environment,
  required MacosWineInstallRequest request,
  required RuntimeRecord currentRuntime,
}) {
  return _runtimeWineInstallPlan(
    hostPlatformSupported: hostPlatform == KonyakHostPlatform.macos,
    unsupportedPlatformMessage:
        'macOS Wine installation is supported on macOS only.',
    requestOperation: request.requestOperation,
    currentRuntime: currentRuntime,
    configuredSourceManifest: Option.fromNullable(
      _runtimeSourceManifestForPlatform(
        platformSpec: _macosKonyakRuntimePlatformSpec,
        environment: environment,
      ),
    ),
    configuredSourceManifestSignature: Option.fromNullable(
      _runtimeSourceManifestSignatureForPlatform(
        platformSpec: _macosKonyakRuntimePlatformSpec,
        environment: environment,
      ),
    ),
    defaultArchiveUrl: Option.fromNullable(
      _runtimeDefaultArchiveUrl(
        platformSpec: _macosKonyakRuntimePlatformSpec,
        environment: environment,
      ),
    ),
    defaultArchiveFileName:
        _macosKonyakRuntimePlatformSpec.defaultArchiveFileName,
    missingArchiveMessage: Option.of('macOS Wine archive is not configured.'),
    incompleteRuntimeMessage: Option.of(
      'Konyak macOS Wine is installed, but the runtime stack is incomplete. '
      'Configure KONYAK_DEV_MACOS_WINE_STACK_MANIFEST or '
      'KONYAK_MACOS_WINE_STACK_MANIFEST, or pass --source-manifest or '
      '--component-archive to repair it.',
    ),
  );
}
