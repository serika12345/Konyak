import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../domain/program/program_run_models.dart';
import '../domain/program/program_runner.dart';
import '../domain/runtime/host_environment.dart';
import '../domain/runtime/runtime_validation_support.dart';
import '../domain/shared/domain_value_objects.dart';
import '../domain/update/update_records.dart';
import '../shared/common_helpers.dart';
import 'app_update_handoff_installers.dart';
import 'app_update_paths.dart';
import 'external_payload_helpers.dart';
import 'file_digest_io.dart';
import 'platform_host_paths.dart';
import 'program_io_services.dart';

class DartIoAppUpdateInstaller implements AppUpdateInstaller {
  DartIoAppUpdateInstaller({
    required this.environment,
    KonyakHostPlatform? hostPlatform,
    this.pathOpener = const DartIoPathOpener(),
    this.detachedProcessStarter = const DartIoDetachedProcessStarter(),
  }) : hostPlatform = hostPlatform ?? currentHostPlatform();

  factory DartIoAppUpdateInstaller.fromEnvironment(
    Map<String, String> environment,
  ) {
    return DartIoAppUpdateInstaller(environment: HostEnvironment(environment));
  }

  final HostEnvironment environment;
  final KonyakHostPlatform hostPlatform;
  final PathOpener pathOpener;
  final DetachedProcessStarter detachedProcessStarter;

  @override
  AppUpdateInstallResult install(AppUpdateRecord update) {
    AppUpdateInstallResult installAvailableUpdate({
      required AppArchiveUrl archiveUrl,
      required AppArchiveSha256 expectedSha256,
    }) {
      final fileName = fileNameFromUrl(
        archiveUrl.value,
      ).match(() => 'Konyak-update', (value) => value);
      final updatesDirectory = Directory(appUpdateCacheDirectory(environment));
      final archivePath = joinPath(updatesDirectory.path, [fileName]);

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
            commandFailureMessage('download Konyak update', download),
          );
        }

        final archive = File(archivePath);
        final actualSha256 = sha256HexDigest(archive);
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
          KonyakHostPlatform.macos => installMacosAppBundleUpdate(
            update: update,
            archivePath: archivePath,
            actualSha256: actualSha256,
            updatesDirectory: updatesDirectory,
          ),
          KonyakHostPlatform.linux => installLinuxAppImageUpdate(
            update: update,
            archivePath: archivePath,
            actualSha256: actualSha256,
            updatesDirectory: updatesDirectory,
          ),
        };

        return handoffResult.match(() {
          final openResult = pathOpener.openPath(PathOpenTarget(archivePath));
          return switch (openResult) {
            PathOpenCompleted() => AppUpdateInstallCompleted(
              AppUpdateInstallRecord(
                appId: update.appId,
                status: UpdateInstallStatus('installed'),
                currentVersion: update.currentVersion,
                installedVersion: update.latestVersion.map(
                  (version) => AppVersion(version.value),
                ),
                archiveUrl: Option.of(archiveUrl),
                archiveSha256: Option.of(AppArchiveSha256(actualSha256)),
                installPath: Option.of(AppInstallPath(archivePath)),
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

    return update.archiveUrl.match(
      () => const AppUpdateInstallFailed(
        'Konyak update metadata does not contain an archive URL.',
      ),
      (archiveUrl) {
        if (archiveUrl.value.trim().isEmpty) {
          return const AppUpdateInstallFailed(
            'Konyak update metadata does not contain an archive URL.',
          );
        }

        return update.archiveSha256.match(
          () => const AppUpdateInstallFailed(
            'Konyak update metadata does not contain a valid archive checksum.',
          ),
          (expectedSha256) => !isSha256Hex(expectedSha256.value)
              ? const AppUpdateInstallFailed(
                  'Konyak update metadata does not contain a valid archive checksum.',
                )
              : installAvailableUpdate(
                  archiveUrl: archiveUrl,
                  expectedSha256: expectedSha256,
                ),
        );
      },
    );
  }
}
