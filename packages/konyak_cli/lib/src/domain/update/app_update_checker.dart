part of '../../../konyak_cli.dart';

class DartIoAppUpdateChecker implements AppUpdateChecker {
  const DartIoAppUpdateChecker({
    required this.appId,
    required this.currentVersion,
    required this.versionUrl,
    this.archiveUrl = const Option.none(),
    this.archiveSha256 = const Option.none(),
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
      archiveUrl: Option.fromNullable(
        _nonEmptyEnvironmentValue(environment, 'KONYAK_APP_ARCHIVE_URL'),
      ),
      archiveSha256: Option.fromNullable(
        _nonEmptyEnvironmentValue(environment, 'KONYAK_APP_ARCHIVE_SHA256'),
      ),
    );
  }

  final String appId;
  final String currentVersion;
  final String versionUrl;
  final Option<String> archiveUrl;
  final Option<String> archiveSha256;
  final RuntimeReleaseMetadataFetcher releaseMetadataFetcher;

  @override
  AppUpdateCheckResult check() {
    if (versionUrl.trim().isEmpty) {
      return AppUpdateCheckCompleted(
        AppUpdateRecord(
          appId: appId,
          status: 'unknown',
          currentVersion: Option.of(currentVersion),
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
            currentVersion: Option.of(currentVersion),
            latestVersion: metadata.version,
          ),
          currentVersion: Option.of(currentVersion),
          latestVersion: Option.of(metadata.version),
          versionUrl: Option.of(versionUrl),
          archiveUrl: metadata.archiveUrl.match(() => archiveUrl, Option.of),
          archiveSha256: metadata.archiveSha256.match(
            () => archiveSha256,
            Option.of,
          ),
        ),
      ),
      RuntimeReleaseMetadataFetchFailed(:final message) => AppUpdateCheckFailed(
        message,
      ),
    };
  }
}
