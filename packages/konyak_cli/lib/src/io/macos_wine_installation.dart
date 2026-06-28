part of '../../konyak_cli.dart';

class DartIoMacosWineInstaller implements MacosWineInstaller {
  DartIoMacosWineInstaller({
    required this.hostPlatform,
    required this.environment,
    FileStatusProbe fileStatusProbe = const DartIoFileStatusProbe(),
    RuntimeStackVersionProbe runtimeStackVersionProbe =
        const DartIoRuntimeStackVersionProbe(),
    RuntimePackageInstaller? runtimePackageInstaller,
  }) : _fileStatusProbe = fileStatusProbe,
       _runtimeStackVersionProbe = runtimeStackVersionProbe,
       _runtimePackageInstaller =
           runtimePackageInstaller ?? _macosRuntimePackageInstaller();

  factory DartIoMacosWineInstaller.current() {
    return DartIoMacosWineInstaller(
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
          sourceManifest.value,
          sourceManifestSignature: sourceManifestSignature.asOption
              .toNullable()
              ?.value,
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
          return _downloadRuntimeStackSourceArchive(
            source: archiveUrl.value,
            targetPath: downloadedArchivePath,
            progressSink: progress,
            stage: 'downloading',
            message: 'Downloading Konyak macOS Wine...',
            startFraction: 0.05,
            endFraction: 0.65,
          ).match(
            MacosWineInstallFailed.new,
            (_) => _installMacosWineArchive(
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
          sourceManifest.value,
          sourceManifestSignature: sourceManifestSignature.asOption
              .toNullable()
              ?.value,
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
          return (await _downloadRuntimeStackSourceArchiveStreaming(
            source: archiveUrl.value,
            targetPath: downloadedArchivePath,
            progressSink: progress,
            stage: 'downloading',
            message: 'Downloading Konyak macOS Wine...',
            startFraction: 0.05,
            endFraction: 0.65,
          )).match(
            MacosWineInstallFailed.new,
            (_) => _installMacosWineArchive(
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
          _deleteDirectoryIfPresent(tempDirectory);
        }
    }
  }
}

RuntimePackageInstaller _macosRuntimePackageInstaller() {
  return DartIoRuntimePackageInstaller(
    preserveExistingRuntimeComponents: _preserveImportedGptkD3DMetalComponent,
    normalizeStagingRoot:
        _macosKonyakRuntimePlatformSpec.layoutNormalization ==
            _RuntimeLayoutNormalization.macosWineBundle
        ? _normalizeMacosWineRuntimeLayout
        : null,
  );
}

_RuntimeWineInstallPlan _macosWineInstallPlan({
  required KonyakHostPlatform hostPlatform,
  required HostEnvironment environment,
  required MacosWineInstallRequest request,
  required RuntimeRecord currentRuntime,
}) {
  return _runtimeWineInstallPlan(
    hostPlatformSupported: hostPlatform == KonyakHostPlatform.macos,
    unsupportedPlatformMessage:
        'macOS Wine installation is supported on macOS only.',
    requestOperation: request.requestOperation,
    currentRuntime: currentRuntime,
    configuredSourceManifest: _runtimeSourceManifestForPlatform(
      platformSpec: _macosKonyakRuntimePlatformSpec,
      environment: environment,
    ),
    configuredSourceManifestSignature:
        _runtimeSourceManifestSignatureForPlatform(
          platformSpec: _macosKonyakRuntimePlatformSpec,
          environment: environment,
        ),
    defaultArchiveFileName:
        _macosKonyakRuntimePlatformSpec.defaultArchiveFileName,
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
