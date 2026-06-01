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
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
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
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    }
  }

  MacosWineInstallResult _installMacosWineArchive({
    required String archivePath,
    required String? archiveSha256,
    List<String> componentArchivePaths = const <String>[],
    Map<String, String> componentVersions = const <String, String>{},
    bool preserveExistingRuntimeFiles = false,
    RuntimeInstallProgressSink? progressSink,
  }) {
    final installResult = _runtimePackageInstaller.install(
      RuntimePackageInstallRequest(
        runtimeLabel: 'macOS Wine',
        archivePath: archivePath,
        archiveSha256: archiveSha256,
        componentArchivePaths: componentArchivePaths,
        componentVersions: componentVersions,
        runtimeRoot: Directory(_macosWineRuntimeRoot(environment)),
        requiredExecutableRelativePath:
            _macosKonyakRuntimePlatformSpec.requiredExecutableRelativePath,
        expectedExecutablePath: _macosWineExecutable(environment),
        preserveExistingRuntimeFiles: preserveExistingRuntimeFiles,
        normalizeStagingRoot:
            _macosKonyakRuntimePlatformSpec.layoutNormalization ==
                _RuntimeLayoutNormalization.macosWineBundle
            ? _normalizeMacosWineRuntimeLayout
            : null,
        afterManifestWrite:
            _macosKonyakRuntimePlatformSpec.layoutNormalization ==
                _RuntimeLayoutNormalization.macosWineBundle
            ? _ensureMacosWine64Alias
            : null,
        progressSink: progressSink,
      ),
    );
    switch (installResult) {
      case RuntimePackageInstallFailed(:final message):
        return MacosWineInstallFailed(message);
      case RuntimePackageInstallCompleted():
        break;
    }

    final runtime = _macosWineRuntimeRecord(
      environment: environment,
      fileStatusProbe: const DartIoFileStatusProbe(),
      runtimeStackVersionProbe: _runtimeStackVersionProbe,
    );

    if (runtime.isInstalled != true) {
      return MacosWineInstallFailed(
        'macOS Wine archive did not install `${runtime.executablePath}`.',
      );
    }

    _emitRuntimeInstallProgress(
      progressSink,
      stage: 'complete',
      message: 'Installed Konyak macOS Wine.',
      fraction: 1,
    );

    return MacosWineInstallCompleted(runtime: runtime);
  }

  MacosWineInstallResult _installMacosWineStackFromSourceManifest(
    String sourceManifest, {
    required String? sourceManifestSignature,
    required bool preserveExistingRuntimeFiles,
    required RuntimeInstallProgressSink? progressSink,
  }) {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-macos-wine-stack-',
    );
    try {
      _emitRuntimeInstallProgress(
        progressSink,
        stage: 'readingManifest',
        message: 'Reading Konyak macOS Wine manifest...',
        fraction: 0.02,
      );
      final manifestPayload = _readRuntimeStackSourceText(
        sourceManifest,
        signatureSource: sourceManifestSignature,
      );
      final manifest = _runtimeStackSourceManifestFromPayload(manifestPayload);
      if (manifest == null) {
        return const MacosWineInstallFailed(
          'Runtime stack source manifest is invalid.',
        );
      }
      final bundleResult = _resolveRuntimeStackSourceArchiveBundle(
        manifest: manifest,
        platformSpec: _macosKonyakRuntimePlatformSpec,
        tempDirectory: tempDirectory,
        progressSink: progressSink,
      );
      return switch (bundleResult) {
        _RuntimeStackSourceArchiveBundleFailed(:final message) =>
          MacosWineInstallFailed(message),
        _RuntimeStackSourceArchiveBundleResolved(:final bundle) =>
          _installMacosWineArchive(
            archivePath: bundle.wineArchivePath,
            archiveSha256: null,
            componentArchivePaths: bundle.componentArchivePaths,
            componentVersions: bundle.componentVersions,
            preserveExistingRuntimeFiles: preserveExistingRuntimeFiles,
            progressSink: progressSink,
          ),
      };
    } on FileSystemException catch (error) {
      return MacosWineInstallFailed(error.message);
    } on ProcessException catch (error) {
      return MacosWineInstallFailed(error.message);
    } finally {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    }
  }

  Future<MacosWineInstallResult>
  _installMacosWineStackFromSourceManifestStreaming(
    String sourceManifest, {
    required String? sourceManifestSignature,
    required bool preserveExistingRuntimeFiles,
    required RuntimeInstallProgressSink? progressSink,
  }) async {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-macos-wine-stack-',
    );
    try {
      _emitRuntimeInstallProgress(
        progressSink,
        stage: 'readingManifest',
        message: 'Reading Konyak macOS Wine manifest...',
        fraction: 0.02,
      );
      final manifestPayload = _readRuntimeStackSourceText(
        sourceManifest,
        signatureSource: sourceManifestSignature,
      );
      final manifest = _runtimeStackSourceManifestFromPayload(manifestPayload);
      if (manifest == null) {
        return const MacosWineInstallFailed(
          'Runtime stack source manifest is invalid.',
        );
      }
      final bundleResult =
          await _resolveRuntimeStackSourceArchiveBundleStreaming(
            manifest: manifest,
            platformSpec: _macosKonyakRuntimePlatformSpec,
            tempDirectory: tempDirectory,
            progressSink: progressSink,
          );
      return switch (bundleResult) {
        _RuntimeStackSourceArchiveBundleFailed(:final message) =>
          MacosWineInstallFailed(message),
        _RuntimeStackSourceArchiveBundleResolved(:final bundle) =>
          _installMacosWineArchive(
            archivePath: bundle.wineArchivePath,
            archiveSha256: null,
            componentArchivePaths: bundle.componentArchivePaths,
            componentVersions: bundle.componentVersions,
            preserveExistingRuntimeFiles: preserveExistingRuntimeFiles,
            progressSink: progressSink,
          ),
      };
    } on FileSystemException catch (error) {
      return MacosWineInstallFailed(error.message);
    } on ProcessException catch (error) {
      return MacosWineInstallFailed(error.message);
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
            'KONYAK_MACOS_WINE_STACK_PUBLIC_KEY_PATH',
          ),
      publicKeyText:
          _nonEmptyEnvironmentValue(
            environment,
            'KONYAK_RUNTIME_STACK_PUBLIC_KEY',
          ) ??
          _nonEmptyEnvironmentValue(
            environment,
            'KONYAK_MACOS_WINE_STACK_PUBLIC_KEY',
          ),
    );
  }

  void _normalizeMacosWineRuntimeLayout(Directory runtimeRoot) {
    _moveRuntimeLayoutChildrenToRoot(
      runtimeRoot: runtimeRoot,
      sourceRoot: Directory(_joinPath(runtimeRoot.path, const ['Wine'])),
    );
    _moveRuntimeLayoutChildrenToRoot(
      runtimeRoot: runtimeRoot,
      sourceRoot: Directory(
        _joinPath(runtimeRoot.path, const ['Contents', 'Resources', 'wine']),
      ),
    );
    for (final entry in runtimeRoot.listSync()) {
      if (entry is! Directory || !_basename(entry.path).endsWith('.app')) {
        continue;
      }
      _moveRuntimeLayoutChildrenToRoot(
        runtimeRoot: runtimeRoot,
        sourceRoot: Directory(
          _joinPath(entry.path, const ['Contents', 'Resources', 'wine']),
        ),
      );
      if (entry.existsSync()) {
        entry.deleteSync(recursive: true);
      }
    }
    _normalizeMacosRuntimeComponents(runtimeRoot);
  }

  void _normalizeMacosRuntimeComponents(Directory runtimeRoot) {
    final componentsRoot = Directory(
      _joinPath(runtimeRoot.path, const ['Components']),
    );
    if (!componentsRoot.existsSync()) {
      return;
    }

    for (final componentId in const <String>[
      'DXVK-macOS',
      'DXVK',
      'MoltenVK',
      'GStreamer',
      'wine-mono',
      'winetricks',
      'GPTK-D3DMetal',
      'gptk-d3dmetal',
      'D3DMetal',
    ]) {
      _moveRuntimeLayoutChildrenToRoot(
        runtimeRoot: runtimeRoot,
        sourceRoot: Directory(_joinPath(componentsRoot.path, [componentId])),
      );
    }

    if (componentsRoot.existsSync() && componentsRoot.listSync().isEmpty) {
      componentsRoot.deleteSync(recursive: true);
    }
  }

  void _moveRuntimeLayoutChildrenToRoot({
    required Directory runtimeRoot,
    required Directory sourceRoot,
  }) {
    if (!sourceRoot.existsSync()) {
      return;
    }

    for (final entry in sourceRoot.listSync()) {
      final targetPath = _joinPath(runtimeRoot.path, [_basename(entry.path)]);
      _moveFileSystemEntity(entry, targetPath);
    }

    sourceRoot.deleteSync(recursive: true);
  }

  void _moveFileSystemEntity(FileSystemEntity entry, String targetPath) {
    final sourceType = FileSystemEntity.typeSync(entry.path);
    final targetType = FileSystemEntity.typeSync(targetPath);
    if (sourceType == FileSystemEntityType.directory &&
        targetType == FileSystemEntityType.directory) {
      for (final child in Directory(entry.path).listSync()) {
        _moveFileSystemEntity(
          child,
          _joinPath(targetPath, [_basename(child.path)]),
        );
      }
      Directory(entry.path).deleteSync();
      return;
    }

    if (targetType != FileSystemEntityType.notFound) {
      _deleteFileSystemEntity(targetPath, targetType);
    }
    entry.renameSync(targetPath);
  }

  void _ensureMacosWine64Alias(Directory runtimeRoot) {
    final binPath = _joinPath(runtimeRoot.path, const ['bin']);
    final winePath = _joinPath(binPath, const ['wine']);
    final wine64Path = _joinPath(binPath, const ['wine64']);

    if (FileSystemEntity.typeSync(wine64Path) !=
        FileSystemEntityType.notFound) {
      return;
    }
    if (FileSystemEntity.typeSync(winePath) == FileSystemEntityType.notFound) {
      return;
    }

    Link(wine64Path).createSync('wine');
  }

  void _deleteFileSystemEntity(String path, FileSystemEntityType type) {
    switch (type) {
      case FileSystemEntityType.directory:
        Directory(path).deleteSync(recursive: true);
      case FileSystemEntityType.file:
      case FileSystemEntityType.link:
      case FileSystemEntityType.pipe:
      case FileSystemEntityType.unixDomainSock:
        File(path).deleteSync();
      case FileSystemEntityType.notFound:
        break;
    }
  }
}
