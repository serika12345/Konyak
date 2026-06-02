part of '../konyak_cli.dart';

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

    if (hostPlatform != KonyakHostPlatform.macos) {
      return const MacosWineInstallFailed(
        'macOS Wine installation is supported on macOS only.',
      );
    }

    final currentRuntime = _macosWineRuntimeRecord(
      environment: environment,
      fileStatusProbe: _fileStatusProbe,
      runtimeStackVersionProbe: _runtimeStackVersionProbe,
    );
    final componentArchivePaths = List<String>.unmodifiable(
      request.componentArchivePaths,
    );
    final sourceManifest =
        request.sourceManifest ??
        _runtimeSourceManifestForPlatform(
          platformSpec: _macosKonyakRuntimePlatformSpec,
          environment: environment,
        );
    final sourceManifestSignature =
        request.sourceManifestSignature ??
        _runtimeSourceManifestSignatureForPlatform(
          platformSpec: _macosKonyakRuntimePlatformSpec,
          environment: environment,
        );
    final hasExplicitInstallSource =
        request.archivePath != null ||
        request.archiveUrl != null ||
        componentArchivePaths.isNotEmpty ||
        request.sourceManifest != null;
    final shouldPreserveExistingRuntimeFiles =
        !request.force &&
        currentRuntime.isInstalled == true &&
        currentRuntime.stack?.isComplete != true &&
        !hasExplicitInstallSource;
    if (!request.force &&
        request.archivePath == null &&
        request.archiveUrl == null &&
        componentArchivePaths.isEmpty &&
        request.sourceManifest == null &&
        currentRuntime.isInstalled == true &&
        currentRuntime.stack?.isComplete == true) {
      _emitRuntimeInstallProgress(
        progress,
        stage: 'complete',
        message: 'Konyak macOS Wine is already installed.',
        fraction: 1,
      );
      return MacosWineInstallCompleted(runtime: currentRuntime);
    }
    if (!request.force &&
        currentRuntime.isInstalled == true &&
        currentRuntime.stack?.isComplete != true &&
        !hasExplicitInstallSource &&
        sourceManifest == null) {
      return const MacosWineInstallFailed(
        'Konyak macOS Wine is installed, but the runtime stack is incomplete. '
        'Configure KONYAK_DEV_MACOS_WINE_STACK_MANIFEST or '
        'KONYAK_MACOS_WINE_STACK_MANIFEST, or pass --source-manifest or '
        '--component-archive to repair it.',
      );
    }

    if (sourceManifest != null) {
      return _installMacosWineStackFromSourceManifest(
        sourceManifest,
        sourceManifestSignature: sourceManifestSignature,
        preserveExistingRuntimeFiles: shouldPreserveExistingRuntimeFiles,
        progressSink: progress,
      );
    }

    final archive = request.archivePath;
    if (archive != null) {
      return _installMacosWineArchive(
        archivePath: archive,
        archiveSha256: request.archiveSha256,
        componentArchivePaths: componentArchivePaths,
        preserveExistingRuntimeFiles: shouldPreserveExistingRuntimeFiles,
        progressSink: progress,
      );
    }

    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-macos-wine-',
    );
    final archiveUrl =
        request.archiveUrl ??
        _runtimeDefaultArchiveUrl(
          platformSpec: _macosKonyakRuntimePlatformSpec,
          environment: environment,
        )!;
    final archiveFileName =
        _fileNameFromUrl(archiveUrl) ??
        _macosKonyakRuntimePlatformSpec.defaultArchiveFileName;
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
        archiveSha256: request.archiveSha256,
        componentArchivePaths: componentArchivePaths,
        preserveExistingRuntimeFiles: shouldPreserveExistingRuntimeFiles,
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

    if (hostPlatform != KonyakHostPlatform.macos) {
      return const MacosWineInstallFailed(
        'macOS Wine installation is supported on macOS only.',
      );
    }

    final currentRuntime = _macosWineRuntimeRecord(
      environment: environment,
      fileStatusProbe: _fileStatusProbe,
      runtimeStackVersionProbe: _runtimeStackVersionProbe,
    );
    final componentArchivePaths = List<String>.unmodifiable(
      request.componentArchivePaths,
    );
    final sourceManifest =
        request.sourceManifest ??
        _runtimeSourceManifestForPlatform(
          platformSpec: _macosKonyakRuntimePlatformSpec,
          environment: environment,
        );
    final sourceManifestSignature =
        request.sourceManifestSignature ??
        _runtimeSourceManifestSignatureForPlatform(
          platformSpec: _macosKonyakRuntimePlatformSpec,
          environment: environment,
        );
    final hasExplicitInstallSource =
        request.archivePath != null ||
        request.archiveUrl != null ||
        componentArchivePaths.isNotEmpty ||
        request.sourceManifest != null;
    final shouldPreserveExistingRuntimeFiles =
        !request.force &&
        currentRuntime.isInstalled == true &&
        currentRuntime.stack?.isComplete != true &&
        !hasExplicitInstallSource;
    if (!request.force &&
        request.archivePath == null &&
        request.archiveUrl == null &&
        componentArchivePaths.isEmpty &&
        request.sourceManifest == null &&
        currentRuntime.isInstalled == true &&
        currentRuntime.stack?.isComplete == true) {
      _emitRuntimeInstallProgress(
        progress,
        stage: 'complete',
        message: 'Konyak macOS Wine is already installed.',
        fraction: 1,
      );
      return MacosWineInstallCompleted(runtime: currentRuntime);
    }
    if (!request.force &&
        currentRuntime.isInstalled == true &&
        currentRuntime.stack?.isComplete != true &&
        !hasExplicitInstallSource &&
        sourceManifest == null) {
      return const MacosWineInstallFailed(
        'Konyak macOS Wine is installed, but the runtime stack is incomplete. '
        'Configure KONYAK_DEV_MACOS_WINE_STACK_MANIFEST or '
        'KONYAK_MACOS_WINE_STACK_MANIFEST, or pass --source-manifest or '
        '--component-archive to repair it.',
      );
    }

    if (sourceManifest != null) {
      return _installMacosWineStackFromSourceManifestStreaming(
        sourceManifest,
        sourceManifestSignature: sourceManifestSignature,
        preserveExistingRuntimeFiles: shouldPreserveExistingRuntimeFiles,
        progressSink: progress,
      );
    }

    final archive = request.archivePath;
    if (archive != null) {
      return _installMacosWineArchive(
        archivePath: archive,
        archiveSha256: request.archiveSha256,
        componentArchivePaths: componentArchivePaths,
        preserveExistingRuntimeFiles: shouldPreserveExistingRuntimeFiles,
        progressSink: progress,
      );
    }

    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-macos-wine-',
    );
    final archiveUrl =
        request.archiveUrl ??
        _runtimeDefaultArchiveUrl(
          platformSpec: _macosKonyakRuntimePlatformSpec,
          environment: environment,
        )!;
    final archiveFileName =
        _fileNameFromUrl(archiveUrl) ??
        _macosKonyakRuntimePlatformSpec.defaultArchiveFileName;
    final downloadedArchivePath = _joinPath(tempDirectory.path, [
      archiveFileName,
    ]);

    try {
      final downloadFailure = await _downloadRuntimeStackSourceArchiveStreaming(
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
        archiveSha256: request.archiveSha256,
        componentArchivePaths: componentArchivePaths,
        preserveExistingRuntimeFiles: shouldPreserveExistingRuntimeFiles,
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
