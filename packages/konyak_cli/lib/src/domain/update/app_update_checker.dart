part of '../../../konyak_cli.dart';

class DartIoAppUpdateChecker implements AppUpdateChecker {
  factory DartIoAppUpdateChecker({
    required String appId,
    required String currentVersion,
    required String versionUrl,
    Option<String> archiveUrl = const Option.none(),
    Option<String> archiveSha256 = const Option.none(),
    KonyakHostPlatform? hostPlatform,
    RuntimeReleaseMetadataFetcher? releaseMetadataFetcher,
  }) {
    final resolvedHostPlatform = hostPlatform ?? _currentHostPlatform();
    return DartIoAppUpdateChecker._(
      appId: appId,
      currentVersion: currentVersion,
      versionUrl: versionUrl,
      archiveUrl: archiveUrl,
      archiveSha256: archiveSha256,
      hostPlatform: resolvedHostPlatform,
      releaseMetadataFetcher:
          releaseMetadataFetcher ??
          DartIoRuntimeReleaseMetadataFetcher(
            archiveUrlPredicate: _appUpdateArchiveUrlPredicate(
              resolvedHostPlatform,
            ),
          ),
    );
  }

  const DartIoAppUpdateChecker._({
    required this.appId,
    required this.currentVersion,
    required this.versionUrl,
    required this.archiveUrl,
    required this.archiveSha256,
    required this.hostPlatform,
    required this.releaseMetadataFetcher,
  });

  factory DartIoAppUpdateChecker.fromEnvironment(HostEnvironment environment) {
    return DartIoAppUpdateChecker(
      appId: environment.nonEmptyValue('KONYAK_APP_ID') ?? konyakAppId,
      currentVersion:
          environment.nonEmptyValue('KONYAK_APP_VERSION') ?? konyakAppVersion,
      versionUrl:
          environment.nonEmptyValue('KONYAK_APP_VERSION_URL') ??
          konyakAppVersionUrl,
      archiveUrl: Option.fromNullable(
        environment.nonEmptyValue('KONYAK_APP_ARCHIVE_URL'),
      ),
      archiveSha256: Option.fromNullable(
        environment.nonEmptyValue('KONYAK_APP_ARCHIVE_SHA256'),
      ),
    );
  }

  final String appId;
  final String currentVersion;
  final String versionUrl;
  final Option<String> archiveUrl;
  final Option<String> archiveSha256;
  final KonyakHostPlatform hostPlatform;
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

bool Function(String url) _appUpdateArchiveUrlPredicate(
  KonyakHostPlatform hostPlatform,
) {
  return (url) {
    final fileName = _fileNameFromUrl(url).toNullable()?.toLowerCase();
    if (fileName == null) {
      return false;
    }

    return switch (hostPlatform) {
      KonyakHostPlatform.macos =>
        fileName.contains('-macos-') && fileName.endsWith('.zip'),
      KonyakHostPlatform.linux =>
        fileName.contains('-linux-') && fileName.endsWith('.appimage'),
    };
  };
}
