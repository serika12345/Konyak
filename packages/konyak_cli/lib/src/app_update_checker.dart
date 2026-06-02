part of '../konyak_cli.dart';

class DartIoAppUpdateChecker implements AppUpdateChecker {
  const DartIoAppUpdateChecker({
    required this.appId,
    required this.currentVersion,
    required this.versionUrl,
    this.archiveUrl,
    this.archiveSha256,
    this.releaseMetadataFetcher = const DartIoRuntimeReleaseMetadataFetcher(),
  });

  factory DartIoAppUpdateChecker.fromEnvironment(
    Map<String, String> environment,
  ) {
    return DartIoAppUpdateChecker(
      appId:
          _nonEmptyEnvironmentValue(environment, 'KONYAK_APP_ID') ??
          konyakAppId,
      currentVersion:
          _nonEmptyEnvironmentValue(environment, 'KONYAK_APP_VERSION') ??
          konyakAppVersion,
      versionUrl:
          _nonEmptyEnvironmentValue(environment, 'KONYAK_APP_VERSION_URL') ??
          konyakAppVersionUrl,
      archiveUrl: _nonEmptyEnvironmentValue(
        environment,
        'KONYAK_APP_ARCHIVE_URL',
      ),
      archiveSha256: _nonEmptyEnvironmentValue(
        environment,
        'KONYAK_APP_ARCHIVE_SHA256',
      ),
    );
  }

  final String appId;
  final String currentVersion;
  final String versionUrl;
  final String? archiveUrl;
  final String? archiveSha256;
  final RuntimeReleaseMetadataFetcher releaseMetadataFetcher;

  @override
  AppUpdateCheckResult check() {
    if (versionUrl.trim().isEmpty) {
      return AppUpdateCheckCompleted(
        AppUpdateRecord(
          appId: appId,
          status: 'unknown',
          currentVersion: currentVersion,
          archiveUrl: archiveUrl,
          archiveSha256: archiveSha256,
        ),
      );
    }

    final metadata = releaseMetadataFetcher.fetch(versionUrl);
    return switch (metadata) {
      RuntimeReleaseMetadataFetched(:final metadata) => AppUpdateCheckCompleted(
        AppUpdateRecord(
          appId: appId,
          status: _updateStatus(
            currentVersion: currentVersion,
            latestVersion: metadata.version,
          ),
          currentVersion: currentVersion,
          latestVersion: metadata.version,
          versionUrl: versionUrl,
          archiveUrl: metadata.archiveUrl.toNullable() ?? archiveUrl,
          archiveSha256: metadata.archiveSha256.toNullable() ?? archiveSha256,
        ),
      ),
      RuntimeReleaseMetadataFetchFailed(:final message) => AppUpdateCheckFailed(
        message,
      ),
    };
  }
}
