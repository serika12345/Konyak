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

  LinuxWineInstallResult _installLinuxWineArchive({
    required String archivePath,
    required String? archiveSha256,
    List<String> componentArchivePaths = const <String>[],
    Map<String, String> componentVersions = const <String, String>{},
    RuntimeInstallProgressSink? progressSink,
  }) {
    final installResult = _runtimePackageInstaller.install(
      RuntimePackageInstallRequest(
        runtimeLabel: 'Linux Wine',
        archivePath: archivePath,
        archiveSha256: archiveSha256,
        componentArchivePaths: componentArchivePaths,
        componentVersions: componentVersions,
        runtimeRoot: Directory(_linuxWineRuntimeRoot(environment)),
        requiredExecutableRelativePath:
            _linuxWineRuntimePlatformSpec.requiredExecutableRelativePath,
        expectedExecutablePath: _linuxWineExecutable(environment),
        progressSink: progressSink,
      ),
    );
    switch (installResult) {
      case RuntimePackageInstallFailed(:final message):
        return LinuxWineInstallFailed(message);
      case RuntimePackageInstallCompleted():
        break;
    }

    final runtime = _linuxWineRuntimeRecord(
      environment: environment,
      fileStatusProbe: const DartIoFileStatusProbe(),
      runtimeStackVersionProbe: _runtimeStackVersionProbe,
    );
    if (runtime.isInstalled != true) {
      return LinuxWineInstallFailed(
        'Linux Wine archive did not install `${runtime.executablePath}`.',
      );
    }

    _emitRuntimeInstallProgress(
      progressSink,
      stage: 'complete',
      message: 'Installed Konyak Linux Wine.',
      fraction: 1,
    );

    return LinuxWineInstallCompleted(runtime: runtime);
  }

  LinuxWineInstallResult _installLinuxWineStackFromSourceManifest(
    String sourceManifest, {
    required String? sourceManifestSignature,
    required RuntimeInstallProgressSink? progressSink,
  }) {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-linux-wine-stack-',
    );
    try {
      _emitRuntimeInstallProgress(
        progressSink,
        stage: 'readingManifest',
        message: 'Reading Konyak Linux Wine manifest...',
        fraction: 0.02,
      );
      final manifestPayload = _readRuntimeStackSourceText(
        sourceManifest,
        signatureSource: sourceManifestSignature,
      );
      final manifest = _runtimeStackSourceManifestFromPayload(manifestPayload);
      if (manifest == null) {
        return const LinuxWineInstallFailed(
          'Runtime stack source manifest is invalid.',
        );
      }
      final bundleResult = _resolveRuntimeStackSourceArchiveBundle(
        manifest: manifest,
        platformSpec: _linuxWineRuntimePlatformSpec,
        tempDirectory: tempDirectory,
        progressSink: progressSink,
      );
      return switch (bundleResult) {
        _RuntimeStackSourceArchiveBundleFailed(:final message) =>
          LinuxWineInstallFailed(message),
        _RuntimeStackSourceArchiveBundleResolved(:final bundle) =>
          _installLinuxWineArchive(
            archivePath: bundle.wineArchivePath,
            archiveSha256: null,
            componentArchivePaths: bundle.componentArchivePaths,
            componentVersions: bundle.componentVersions,
            progressSink: progressSink,
          ),
      };
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

  Future<LinuxWineInstallResult>
  _installLinuxWineStackFromSourceManifestStreaming(
    String sourceManifest, {
    required String? sourceManifestSignature,
    required RuntimeInstallProgressSink? progressSink,
  }) async {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-linux-wine-stack-',
    );
    try {
      _emitRuntimeInstallProgress(
        progressSink,
        stage: 'readingManifest',
        message: 'Reading Konyak Linux Wine manifest...',
        fraction: 0.02,
      );
      final manifestPayload = _readRuntimeStackSourceText(
        sourceManifest,
        signatureSource: sourceManifestSignature,
      );
      final manifest = _runtimeStackSourceManifestFromPayload(manifestPayload);
      if (manifest == null) {
        return const LinuxWineInstallFailed(
          'Runtime stack source manifest is invalid.',
        );
      }
      final bundleResult =
          await _resolveRuntimeStackSourceArchiveBundleStreaming(
            manifest: manifest,
            platformSpec: _linuxWineRuntimePlatformSpec,
            tempDirectory: tempDirectory,
            progressSink: progressSink,
          );
      return switch (bundleResult) {
        _RuntimeStackSourceArchiveBundleFailed(:final message) =>
          LinuxWineInstallFailed(message),
        _RuntimeStackSourceArchiveBundleResolved(:final bundle) =>
          _installLinuxWineArchive(
            archivePath: bundle.wineArchivePath,
            archiveSha256: null,
            componentArchivePaths: bundle.componentArchivePaths,
            componentVersions: bundle.componentVersions,
            progressSink: progressSink,
          ),
      };
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

  String _readRuntimeStackSourceText(
    String source, {
    required String? signatureSource,
  }) {
    return _readAndVerifyRuntimeStackSourceText(
      source: source,
      signatureSource: signatureSource,
      publicKeyPath:
          _nonEmptyEnvironmentValue(
            environment,
            'KONYAK_RUNTIME_STACK_PUBLIC_KEY_PATH',
          ) ??
          _nonEmptyEnvironmentValue(
            environment,
            'KONYAK_LINUX_WINE_STACK_PUBLIC_KEY_PATH',
          ),
      publicKeyText:
          _nonEmptyEnvironmentValue(
            environment,
            'KONYAK_RUNTIME_STACK_PUBLIC_KEY',
          ) ??
          _nonEmptyEnvironmentValue(
            environment,
            'KONYAK_LINUX_WINE_STACK_PUBLIC_KEY',
          ),
    );
  }
}
