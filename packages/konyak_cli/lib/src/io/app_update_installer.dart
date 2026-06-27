part of '../../konyak_cli.dart';

class DartIoAppUpdateInstaller implements AppUpdateInstaller {
  DartIoAppUpdateInstaller({
    required this.environment,
    KonyakHostPlatform? hostPlatform,
    PathOpener pathOpener = const DartIoPathOpener(),
    DetachedProcessStarter detachedProcessStarter =
        const DartIoDetachedProcessStarter(),
  }) : hostPlatform = hostPlatform ?? _currentHostPlatform(),
       _pathOpener = pathOpener,
       _detachedProcessStarter = detachedProcessStarter;

  factory DartIoAppUpdateInstaller.fromEnvironment(
    Map<String, String> environment,
  ) {
    return DartIoAppUpdateInstaller(environment: HostEnvironment(environment));
  }

  final HostEnvironment environment;
  final KonyakHostPlatform hostPlatform;
  final PathOpener _pathOpener;
  final DetachedProcessStarter _detachedProcessStarter;

  @override
  AppUpdateInstallResult install(AppUpdateRecord update) {
    final archiveUrl = update.archiveUrl.toNullable();
    if (archiveUrl == null || archiveUrl.value.trim().isEmpty) {
      return const AppUpdateInstallFailed(
        'Konyak update metadata does not contain an archive URL.',
      );
    }
    final expectedSha256 = update.archiveSha256.toNullable();
    if (expectedSha256 == null || !_isSha256Hex(expectedSha256.value)) {
      return const AppUpdateInstallFailed(
        'Konyak update metadata does not contain a valid archive checksum.',
      );
    }

    final fileName = _fileNameFromUrl(
      archiveUrl.value,
    ).match(() => 'Konyak-update', (value) => value);
    final updatesDirectory = Directory(_appUpdateCacheDirectory(environment));
    final archivePath = _joinPath(updatesDirectory.path, [fileName]);

    try {
      updatesDirectory.createSync(recursive: true);
      final download = Process.runSync('curl', [
        '--fail',
        '--location',
        '--output',
        archivePath,
        archiveUrl.value,
      ], runInShell: false);
      if (download.exitCode != 0) {
        return AppUpdateInstallFailed(
          _commandFailureMessage('download Konyak update', download),
        );
      }

      final archive = File(archivePath);
      final actualSha256 = _sha256HexDigest(archive);
      if (actualSha256.toLowerCase() != expectedSha256.value.toLowerCase()) {
        if (archive.existsSync()) {
          archive.deleteSync();
        }
        return AppUpdateInstallFailed(
          'Konyak update archive checksum mismatch: expected '
          '${expectedSha256.value}, got $actualSha256.',
        );
      }

      final handoffResult = switch (hostPlatform) {
        KonyakHostPlatform.macos => _installMacosAppBundleUpdate(
          update: update,
          archivePath: archivePath,
          actualSha256: actualSha256,
          updatesDirectory: updatesDirectory,
        ),
        KonyakHostPlatform.linux => _installLinuxAppImageUpdate(
          update: update,
          archivePath: archivePath,
          actualSha256: actualSha256,
          updatesDirectory: updatesDirectory,
        ),
      };

      return handoffResult.match(() {
        final openResult = _pathOpener.openPath(archivePath);
        return switch (openResult) {
          PathOpenCompleted() => AppUpdateInstallCompleted(
            AppUpdateInstallRecord(
              appId: update.appId.value,
              status: 'installed',
              currentVersion: update.currentVersion.map(
                (version) => version.value,
              ),
              installedVersion: update.latestVersion.map(
                (version) => version.value,
              ),
              archiveUrl: Option.of(archiveUrl.value),
              archiveSha256: Option.of(actualSha256),
              installPath: Option.of(archivePath),
            ),
          ),
          PathOpenFailed(:final message) => AppUpdateInstallFailed(message),
        };
      }, (result) => result);
    } on FileSystemException catch (error) {
      return AppUpdateInstallFailed(error.message);
    } on ProcessException catch (error) {
      return AppUpdateInstallFailed(error.message);
    }
  }
}
