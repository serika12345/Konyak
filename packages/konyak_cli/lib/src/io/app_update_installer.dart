part of '../../konyak_cli.dart';

class DartIoAppUpdateInstaller implements AppUpdateInstaller {
  DartIoAppUpdateInstaller({
    required Map<String, String> environment,
    KonyakHostPlatform? hostPlatform,
    PathOpener pathOpener = const DartIoPathOpener(),
    DetachedProcessStarter detachedProcessStarter =
        const DartIoDetachedProcessStarter(),
  }) : environment = Map.unmodifiable(environment),
       hostPlatform = hostPlatform ?? _currentHostPlatform(),
       _pathOpener = pathOpener,
       _detachedProcessStarter = detachedProcessStarter;

  factory DartIoAppUpdateInstaller.fromEnvironment(
    Map<String, String> environment,
  ) {
    return DartIoAppUpdateInstaller(environment: environment);
  }

  final Map<String, String> environment;
  final KonyakHostPlatform hostPlatform;
  final PathOpener _pathOpener;
  final DetachedProcessStarter _detachedProcessStarter;

  @override
  AppUpdateInstallResult install(AppUpdateRecord update) {
    final archiveUrl = update.archiveUrl;
    if (archiveUrl == null || archiveUrl.trim().isEmpty) {
      return const AppUpdateInstallFailed(
        'Konyak update metadata does not contain an archive URL.',
      );
    }
    final expectedSha256 = update.archiveSha256;
    if (expectedSha256 == null || !_isSha256Hex(expectedSha256)) {
      return const AppUpdateInstallFailed(
        'Konyak update metadata does not contain a valid archive checksum.',
      );
    }

    final fileName = _fileNameFromUrl(archiveUrl) ?? 'Konyak-update';
    final updatesDirectory = Directory(_appUpdateCacheDirectory(environment));
    final archivePath = _joinPath(updatesDirectory.path, [fileName]);

    try {
      updatesDirectory.createSync(recursive: true);
      final download = Process.runSync('curl', [
        '--fail',
        '--location',
        '--output',
        archivePath,
        archiveUrl,
      ], runInShell: false);
      if (download.exitCode != 0) {
        return AppUpdateInstallFailed(
          _commandFailureMessage('download Konyak update', download),
        );
      }

      final archive = File(archivePath);
      final actualSha256 = _sha256HexDigest(archive);
      if (actualSha256.toLowerCase() != expectedSha256.toLowerCase()) {
        if (archive.existsSync()) {
          archive.deleteSync();
        }
        return AppUpdateInstallFailed(
          'Konyak update archive checksum mismatch: expected '
          '$expectedSha256, got $actualSha256.',
        );
      }

      if (hostPlatform == KonyakHostPlatform.macos) {
        final macosResult = _installMacosAppBundleUpdate(
          update: update,
          archivePath: archivePath,
          actualSha256: actualSha256,
          updatesDirectory: updatesDirectory,
        );
        if (macosResult != null) {
          return macosResult;
        }
      }

      if (hostPlatform == KonyakHostPlatform.linux) {
        final linuxResult = _installLinuxAppImageUpdate(
          update: update,
          archivePath: archivePath,
          actualSha256: actualSha256,
          updatesDirectory: updatesDirectory,
        );
        if (linuxResult != null) {
          return linuxResult;
        }
      }

      final openResult = _pathOpener.openPath(archivePath);
      return switch (openResult) {
        PathOpenCompleted() => AppUpdateInstallCompleted(
          AppUpdateInstallRecord(
            appId: update.appId,
            status: 'installed',
            currentVersion: update.currentVersion,
            installedVersion: update.latestVersion,
            archiveUrl: archiveUrl,
            archiveSha256: actualSha256,
            installPath: archivePath,
          ),
        ),
        PathOpenFailed(:final message) => AppUpdateInstallFailed(message),
      };
    } on FileSystemException catch (error) {
      return AppUpdateInstallFailed(error.message);
    } on ProcessException catch (error) {
      return AppUpdateInstallFailed(error.message);
    }
  }
}
