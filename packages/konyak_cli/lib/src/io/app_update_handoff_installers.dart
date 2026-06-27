part of '../../konyak_cli.dart';

extension _AppUpdateHandoffInstallers on DartIoAppUpdateInstaller {
  Option<AppUpdateInstallResult> _installMacosAppBundleUpdate({
    required AppUpdateRecord update,
    required String archivePath,
    required String actualSha256,
    required Directory updatesDirectory,
  }) {
    return _macosAppBundlePath(environment).match(
      () => const Option.none(),
      (targetBundlePath) => _konyakAppPid(environment).match(
        () => const Option.none(),
        (appPid) {
          final targetBundle = Directory(targetBundlePath);
          if (!targetBundle.existsSync()) {
            return Option.of(
              AppUpdateInstallFailed(
                'Current Konyak app bundle does not exist: $targetBundlePath',
              ),
            );
          }

          final archiveExtension = _macosAppUpdateArchiveExtension(archivePath);
          final stagedArchivePath = _joinPath(updatesDirectory.path, [
            'Konyak-update-${DateTime.now().microsecondsSinceEpoch}'
                '$archiveExtension',
          ]);
          final stagedArchive = File(stagedArchivePath);
          stagedArchive.parent.createSync(recursive: true);
          File(archivePath).copySync(stagedArchivePath);
          stagedArchive.setLastModifiedSync(DateTime.now());

          final handoffScriptPath = _joinPath(updatesDirectory.path, [
            'install-macos-app-update-'
                '${DateTime.now().microsecondsSinceEpoch}.sh',
          ]);
          final handoffScript = File(handoffScriptPath);
          handoffScript.writeAsStringSync(_macosAppBundleUpdateHandoffScript());
          handoffScript.setLastModifiedSync(DateTime.now());
          Process.runSync('chmod', [
            '755',
            handoffScriptPath,
          ], runInShell: false);

          final startResult = _detachedProcessStarter.start(
            executable: 'bash',
            arguments: [
              handoffScriptPath,
              stagedArchivePath,
              targetBundlePath,
              '$appPid',
            ],
          );
          return Option.of(switch (startResult) {
            DetachedProcessStartCompleted() => AppUpdateInstallCompleted(
              AppUpdateInstallRecord(
                appId: update.appId.value,
                status: 'installed',
                currentVersion: update.currentVersion.map(
                  (version) => version.value,
                ),
                installedVersion: update.latestVersion.map(
                  (version) => version.value,
                ),
                archiveUrl: update.archiveUrl.map((url) => url.value),
                archiveSha256: Option.of(actualSha256),
                installPath: Option.of(targetBundlePath),
              ),
            ),
            DetachedProcessStartFailed(:final message) =>
              AppUpdateInstallFailed(message),
          });
        },
      ),
    );
  }

  Option<AppUpdateInstallResult> _installLinuxAppImageUpdate({
    required AppUpdateRecord update,
    required String archivePath,
    required String actualSha256,
    required Directory updatesDirectory,
  }) {
    return _linuxAppImageTargetPath(environment).match(
      () => const Option.none(),
      (
        targetPath,
      ) => _konyakAppPid(environment).match(() => const Option.none(), (
        appPid,
      ) {
        final preflightResult = switch (_linuxAppImageUpdatePreflight(
          targetPath,
        )) {
          Left<String, Unit>(:final value) => Option.of(
            AppUpdateInstallFailed(value),
          ),
          Right<String, Unit>() => const Option<AppUpdateInstallResult>.none(),
        };
        if (preflightResult.isSome()) {
          return preflightResult;
        }

        final stagedArchivePath = _joinPath(updatesDirectory.path, [
          'Konyak-update-${DateTime.now().microsecondsSinceEpoch}.AppImage',
        ]);
        final stagedArchive = File(stagedArchivePath);
        stagedArchive.parent.createSync(recursive: true);
        File(archivePath).copySync(stagedArchivePath);
        stagedArchive.setLastModifiedSync(DateTime.now());

        final handoffScriptPath = _joinPath(updatesDirectory.path, [
          'install-appimage-update-'
              '${DateTime.now().microsecondsSinceEpoch}.sh',
        ]);
        final handoffScript = File(handoffScriptPath);
        handoffScript.writeAsStringSync(_linuxAppImageUpdateHandoffScript());
        handoffScript.setLastModifiedSync(DateTime.now());
        Process.runSync('chmod', ['755', handoffScriptPath], runInShell: false);

        final startResult = _detachedProcessStarter.start(
          executable: 'bash',
          arguments: [
            handoffScriptPath,
            stagedArchivePath,
            targetPath,
            '$appPid',
          ],
        );
        return Option.of(switch (startResult) {
          DetachedProcessStartCompleted() => AppUpdateInstallCompleted(
            AppUpdateInstallRecord(
              appId: update.appId.value,
              status: 'installed',
              currentVersion: update.currentVersion.map(
                (version) => version.value,
              ),
              installedVersion: update.latestVersion.map(
                (version) => version.value,
              ),
              archiveUrl: update.archiveUrl.map((url) => url.value),
              archiveSha256: Option.of(actualSha256),
              installPath: Option.of(targetPath),
            ),
          ),
          DetachedProcessStartFailed(:final message) => AppUpdateInstallFailed(
            message,
          ),
        });
      }),
    );
  }
}

String _macosAppUpdateArchiveExtension(String archivePath) {
  final fileName = archivePath.split(Platform.pathSeparator).last.toLowerCase();
  if (fileName.endsWith('.dmg')) {
    return '.dmg';
  }

  return '.zip';
}

Either<String, Unit> _linuxAppImageUpdatePreflight(String targetPath) {
  final target = File(targetPath);
  if (!target.existsSync()) {
    return Left<String, Unit>(
      'Current Konyak AppImage does not exist: $targetPath',
    );
  }

  final parent = target.parent;
  if (!parent.existsSync()) {
    return Left<String, Unit>(
      'Current Konyak AppImage directory does not exist: ${parent.path}',
    );
  }

  final probe = File(
    _joinPath(parent.path, [
      '.konyak-update-write-test-${DateTime.now().microsecondsSinceEpoch}',
    ]),
  );
  try {
    probe.createSync(exclusive: true);
    probe.deleteSync();
  } on FileSystemException {
    if (probe.existsSync()) {
      try {
        probe.deleteSync();
      } on FileSystemException {
        // The original failure is more useful to the user.
      }
    }
    return Left<String, Unit>(
      'Current Konyak AppImage directory is not writable: ${parent.path}',
    );
  }

  return const Right<String, Unit>(unit);
}
