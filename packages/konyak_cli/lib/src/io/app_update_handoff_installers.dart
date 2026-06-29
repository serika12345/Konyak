import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../domain/program/program_run_models.dart';
import '../domain/shared/domain_value_objects.dart';
import '../domain/update/update_records.dart';
import '../platform/platform_update_handoff.dart';
import '../shared/common_helpers.dart';
import 'app_update_installer.dart';
import 'app_update_paths.dart';

extension AppUpdateHandoffInstallers on DartIoAppUpdateInstaller {
  Option<AppUpdateInstallResult> installMacosAppBundleUpdate({
    required AppUpdateRecord update,
    required String archivePath,
    required String actualSha256,
    required Directory updatesDirectory,
  }) {
    return macosAppBundlePath(environment).match(
      () => const Option.none(),
      (
        targetBundlePath,
      ) => konyakAppPid(environment).match(() => const Option.none(), (appPid) {
        final targetBundle = Directory(targetBundlePath);
        if (!targetBundle.existsSync()) {
          return Option.of(
            AppUpdateInstallFailed(
              'Current Konyak app bundle does not exist: $targetBundlePath',
            ),
          );
        }

        final archiveExtension = macosAppUpdateArchiveExtension(archivePath);
        final stagedArchivePath = joinPath(updatesDirectory.path, [
          'Konyak-update-${DateTime.now().microsecondsSinceEpoch}'
              '$archiveExtension',
        ]);
        final stagedArchive = File(stagedArchivePath);
        stagedArchive.parent.createSync(recursive: true);
        File(archivePath).copySync(stagedArchivePath);
        stagedArchive.setLastModifiedSync(DateTime.now());

        final handoffScriptPath = joinPath(updatesDirectory.path, [
          'install-macos-app-update-'
              '${DateTime.now().microsecondsSinceEpoch}.sh',
        ]);
        final handoffScript = File(handoffScriptPath);
        handoffScript.writeAsStringSync(macosAppBundleUpdateHandoffScript());
        handoffScript.setLastModifiedSync(DateTime.now());
        Process.runSync('chmod', ['755', handoffScriptPath], runInShell: false);

        final startResult = detachedProcessStarter.start(
          executable: ProgramExecutable('bash'),
          arguments: ProgramRunArguments(<String>[
            handoffScriptPath,
            stagedArchivePath,
            targetBundlePath,
            '$appPid',
          ]),
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
          DetachedProcessStartFailed(:final message) => AppUpdateInstallFailed(
            message,
          ),
        });
      }),
    );
  }

  Option<AppUpdateInstallResult> installLinuxAppImageUpdate({
    required AppUpdateRecord update,
    required String archivePath,
    required String actualSha256,
    required Directory updatesDirectory,
  }) {
    return linuxAppImageTargetPath(environment).match(
      () => const Option.none(),
      (
        targetPath,
      ) => konyakAppPid(environment).match(() => const Option.none(), (appPid) {
        final preflightResult = switch (linuxAppImageUpdatePreflight(
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

        final stagedArchivePath = joinPath(updatesDirectory.path, [
          'Konyak-update-${DateTime.now().microsecondsSinceEpoch}.AppImage',
        ]);
        final stagedArchive = File(stagedArchivePath);
        stagedArchive.parent.createSync(recursive: true);
        File(archivePath).copySync(stagedArchivePath);
        stagedArchive.setLastModifiedSync(DateTime.now());

        final handoffScriptPath = joinPath(updatesDirectory.path, [
          'install-appimage-update-'
              '${DateTime.now().microsecondsSinceEpoch}.sh',
        ]);
        final handoffScript = File(handoffScriptPath);
        handoffScript.writeAsStringSync(linuxAppImageUpdateHandoffScript());
        handoffScript.setLastModifiedSync(DateTime.now());
        Process.runSync('chmod', ['755', handoffScriptPath], runInShell: false);

        final startResult = detachedProcessStarter.start(
          executable: ProgramExecutable('bash'),
          arguments: ProgramRunArguments(<String>[
            handoffScriptPath,
            stagedArchivePath,
            targetPath,
            '$appPid',
          ]),
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

String macosAppUpdateArchiveExtension(String archivePath) {
  final fileName = archivePath.split(Platform.pathSeparator).last.toLowerCase();
  if (fileName.endsWith('.dmg')) {
    return '.dmg';
  }

  return '.zip';
}

Either<String, Unit> linuxAppImageUpdatePreflight(String targetPath) {
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
    joinPath(parent.path, [
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
