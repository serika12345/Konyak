part of '../konyak_cli.dart';

extension _AppUpdateHandoffInstallers on DartIoAppUpdateInstaller {
  AppUpdateInstallResult? _installMacosAppBundleUpdate({
    required AppUpdateRecord update,
    required String archivePath,
    required String actualSha256,
    required Directory updatesDirectory,
  }) {
    final targetBundlePath = _macosAppBundlePath(environment);
    final appPid = _konyakAppPid(environment);
    if (targetBundlePath == null || appPid == null) {
      return null;
    }

    final targetBundle = Directory(targetBundlePath);
    if (!targetBundle.existsSync()) {
      return AppUpdateInstallFailed(
        'Current Konyak app bundle does not exist: $targetBundlePath',
      );
    }

    final stagedArchivePath = _joinPath(updatesDirectory.path, [
      'Konyak-update-${DateTime.now().microsecondsSinceEpoch}.zip',
    ]);
    final stagedArchive = File(stagedArchivePath);
    stagedArchive.parent.createSync(recursive: true);
    File(archivePath).copySync(stagedArchivePath);
    stagedArchive.setLastModifiedSync(DateTime.now());

    final handoffScriptPath = _joinPath(updatesDirectory.path, [
      'install-macos-app-update-${DateTime.now().microsecondsSinceEpoch}.sh',
    ]);
    final handoffScript = File(handoffScriptPath);
    handoffScript.writeAsStringSync(_macosAppBundleUpdateHandoffScript());
    handoffScript.setLastModifiedSync(DateTime.now());
    Process.runSync('chmod', ['755', handoffScriptPath], runInShell: false);

    final startResult = _detachedProcessStarter.start(
      executable: 'bash',
      arguments: [
        handoffScriptPath,
        stagedArchivePath,
        targetBundlePath,
        '$appPid',
      ],
    );
    return switch (startResult) {
      DetachedProcessStartCompleted() => AppUpdateInstallCompleted(
        AppUpdateInstallRecord(
          appId: update.appId,
          status: 'installed',
          currentVersion: update.currentVersion,
          installedVersion: update.latestVersion,
          archiveUrl: update.archiveUrl,
          archiveSha256: actualSha256,
          installPath: targetBundlePath,
        ),
      ),
      DetachedProcessStartFailed(:final message) => AppUpdateInstallFailed(
        message,
      ),
    };
  }

  AppUpdateInstallResult? _installLinuxAppImageUpdate({
    required AppUpdateRecord update,
    required String archivePath,
    required String actualSha256,
    required Directory updatesDirectory,
  }) {
    final targetPath = _linuxAppImageTargetPath(environment);
    final appPid = _konyakAppPid(environment);
    if (targetPath == null || appPid == null) {
      return null;
    }

    final stagedArchivePath = _joinPath(updatesDirectory.path, [
      'Konyak-update-${DateTime.now().microsecondsSinceEpoch}.AppImage',
    ]);
    final stagedArchive = File(stagedArchivePath);
    stagedArchive.parent.createSync(recursive: true);
    File(archivePath).copySync(stagedArchivePath);
    stagedArchive.setLastModifiedSync(DateTime.now());

    final handoffScriptPath = _joinPath(updatesDirectory.path, [
      'install-appimage-update-${DateTime.now().microsecondsSinceEpoch}.sh',
    ]);
    final handoffScript = File(handoffScriptPath);
    handoffScript.writeAsStringSync(_linuxAppImageUpdateHandoffScript());
    handoffScript.setLastModifiedSync(DateTime.now());
    Process.runSync('chmod', ['755', handoffScriptPath], runInShell: false);

    final startResult = _detachedProcessStarter.start(
      executable: 'bash',
      arguments: [handoffScriptPath, stagedArchivePath, targetPath, '$appPid'],
    );
    return switch (startResult) {
      DetachedProcessStartCompleted() => AppUpdateInstallCompleted(
        AppUpdateInstallRecord(
          appId: update.appId,
          status: 'installed',
          currentVersion: update.currentVersion,
          installedVersion: update.latestVersion,
          archiveUrl: update.archiveUrl,
          archiveSha256: actualSha256,
          installPath: targetPath,
        ),
      ),
      DetachedProcessStartFailed(:final message) => AppUpdateInstallFailed(
        message,
      ),
    };
  }
}
