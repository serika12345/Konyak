part of '../../konyak_cli.dart';

extension _DartIoLinuxWineInstallerOperations on DartIoLinuxWineInstaller {
  LinuxWineInstallResult _installLinuxWineArchive({
    required String archivePath,
    required Option<String> archiveSha256,
    Iterable<String> componentArchivePaths = const <String>[],
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
    if (runtime.isInstalled.toNullable() != true) {
      return LinuxWineInstallFailed(
        'Linux Wine archive did not install '
        '`${runtime.executablePath.toNullable()}`.',
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
      if (manifest.isNone()) {
        return const LinuxWineInstallFailed(
          'Runtime stack source manifest is invalid.',
        );
      }
      final bundleResult = _resolveRuntimeStackSourceArchiveBundle(
        manifest: manifest.getOrElse(
          () => throw StateError('Expected runtime stack source manifest.'),
        ),
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
            archiveSha256: const Option.none(),
            componentArchivePaths: bundle.componentArchivePaths,
            componentVersions: bundle.componentVersions.unlockView,
            progressSink: progressSink,
          ),
      };
    } on FileSystemException catch (error) {
      return LinuxWineInstallFailed(error.message);
    } on ProcessException catch (error) {
      return LinuxWineInstallFailed(error.message);
    } finally {
      _deleteDirectoryIfPresent(tempDirectory);
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
      if (manifest.isNone()) {
        return const LinuxWineInstallFailed(
          'Runtime stack source manifest is invalid.',
        );
      }
      final bundleResult =
          await _resolveRuntimeStackSourceArchiveBundleStreaming(
            manifest: manifest.getOrElse(
              () => throw StateError('Expected runtime stack source manifest.'),
            ),
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
            archiveSha256: const Option.none(),
            componentArchivePaths: bundle.componentArchivePaths,
            componentVersions: bundle.componentVersions.unlockView,
            progressSink: progressSink,
          ),
      };
    } on FileSystemException catch (error) {
      return LinuxWineInstallFailed(error.message);
    } on ProcessException catch (error) {
      return LinuxWineInstallFailed(error.message);
    } finally {
      _deleteDirectoryIfPresent(tempDirectory);
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
