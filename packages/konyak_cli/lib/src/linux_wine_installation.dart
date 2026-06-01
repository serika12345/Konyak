part of '../konyak_cli.dart';

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

    if (hostPlatform != KonyakHostPlatform.linux) {
      return const LinuxWineInstallFailed(
        'Linux Wine installation is supported on Linux only.',
      );
    }

    final currentRuntime = _linuxWineRuntimeRecord(
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
          platformSpec: _linuxWineRuntimePlatformSpec,
          environment: environment,
        );
    final sourceManifestSignature =
        request.sourceManifestSignature ??
        _runtimeSourceManifestSignatureForPlatform(
          platformSpec: _linuxWineRuntimePlatformSpec,
          environment: environment,
        );
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
        message: 'Konyak Linux Wine is already installed.',
        fraction: 1,
      );
      return LinuxWineInstallCompleted(runtime: currentRuntime);
    }

    if (sourceManifest != null) {
      return _installLinuxWineStackFromSourceManifest(
        sourceManifest,
        sourceManifestSignature: sourceManifestSignature,
        progressSink: progress,
      );
    }

    final archivePath = request.archivePath;
    if (archivePath != null) {
      return _installLinuxWineArchive(
        archivePath: archivePath,
        archiveSha256: request.archiveSha256,
        componentArchivePaths: componentArchivePaths,
        progressSink: progress,
      );
    }

    final archiveUrl =
        request.archiveUrl ??
        _runtimeDefaultArchiveUrl(
          platformSpec: _linuxWineRuntimePlatformSpec,
          environment: environment,
        );
    if (archiveUrl == null) {
      return const LinuxWineInstallFailed(
        'Linux Wine archive is not configured.',
      );
    }

    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-linux-wine-',
    );
    final archiveFileName =
        _fileNameFromUrl(archiveUrl) ??
        _linuxWineRuntimePlatformSpec.defaultArchiveFileName;
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
        archiveSha256: request.archiveSha256,
        componentArchivePaths: componentArchivePaths,
        progressSink: progress,
      );
    } on FileSystemException catch (error) {
      return LinuxWineInstallFailed(error.message);
    } on ProcessException catch (error) {
      return LinuxWineInstallFailed(error.message);
    } finally {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
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

    if (hostPlatform != KonyakHostPlatform.linux) {
      return const LinuxWineInstallFailed(
        'Linux Wine installation is supported on Linux only.',
      );
    }

    final currentRuntime = _linuxWineRuntimeRecord(
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
          platformSpec: _linuxWineRuntimePlatformSpec,
          environment: environment,
        );
    final sourceManifestSignature =
        request.sourceManifestSignature ??
        _runtimeSourceManifestSignatureForPlatform(
          platformSpec: _linuxWineRuntimePlatformSpec,
          environment: environment,
        );
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
        message: 'Konyak Linux Wine is already installed.',
        fraction: 1,
      );
      return LinuxWineInstallCompleted(runtime: currentRuntime);
    }

    if (sourceManifest != null) {
      return _installLinuxWineStackFromSourceManifestStreaming(
        sourceManifest,
        sourceManifestSignature: sourceManifestSignature,
        progressSink: progress,
      );
    }

    final archivePath = request.archivePath;
    if (archivePath != null) {
      return _installLinuxWineArchive(
        archivePath: archivePath,
        archiveSha256: request.archiveSha256,
        componentArchivePaths: componentArchivePaths,
        progressSink: progress,
      );
    }

    final archiveUrl =
        request.archiveUrl ??
        _runtimeDefaultArchiveUrl(
          platformSpec: _linuxWineRuntimePlatformSpec,
          environment: environment,
        );
    if (archiveUrl == null) {
      return const LinuxWineInstallFailed(
        'Linux Wine archive is not configured.',
      );
    }

    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-linux-wine-',
    );
    final archiveFileName =
        _fileNameFromUrl(archiveUrl) ??
        _linuxWineRuntimePlatformSpec.defaultArchiveFileName;
    final downloadedArchivePath = _joinPath(tempDirectory.path, [
      archiveFileName,
    ]);

    try {
      final downloadFailure = await _downloadRuntimeStackSourceArchiveStreaming(
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
        archiveSha256: request.archiveSha256,
        componentArchivePaths: componentArchivePaths,
        progressSink: progress,
      );
    } on FileSystemException catch (error) {
      return LinuxWineInstallFailed(error.message);
    } on ProcessException catch (error) {
      return LinuxWineInstallFailed(error.message);
    } finally {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    }
  }
}
