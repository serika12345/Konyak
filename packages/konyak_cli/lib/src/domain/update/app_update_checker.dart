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
      appId: AppId(appId),
      currentVersion: AppVersion(currentVersion),
      versionUrl: RuntimeVersionUrl(versionUrl),
      archiveUrl: archiveUrl.map(AppArchiveUrl.new),
      archiveSha256: archiveSha256.map(AppArchiveSha256.new),
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
      appId: environment
          .nonEmptyValue('KONYAK_APP_ID')
          .match(() => konyakAppId, (value) => value),
      currentVersion: environment
          .nonEmptyValue('KONYAK_APP_VERSION')
          .match(() => konyakAppVersion, (value) => value),
      versionUrl: environment
          .nonEmptyValue('KONYAK_APP_VERSION_URL')
          .match(() => konyakAppVersionUrl, (value) => value),
      archiveUrl: environment.nonEmptyValue('KONYAK_APP_ARCHIVE_URL'),
      archiveSha256: environment.nonEmptyValue('KONYAK_APP_ARCHIVE_SHA256'),
    );
  }

  final AppId appId;
  final AppVersion currentVersion;
  final RuntimeVersionUrl versionUrl;
  final Option<AppArchiveUrl> archiveUrl;
  final Option<AppArchiveSha256> archiveSha256;
  final KonyakHostPlatform hostPlatform;
  final RuntimeReleaseMetadataFetcher releaseMetadataFetcher;

  @override
  AppUpdateCheckResult check() {
    if (versionUrl.value.trim().isEmpty) {
      return AppUpdateCheckCompleted(
        AppUpdateRecord(
          appId: appId.value,
          status: 'unknown',
          currentVersion: Option.of(currentVersion.value),
          archiveUrl: archiveUrl.map((value) => value.value),
          archiveSha256: archiveSha256.map((value) => value.value),
        ),
      );
    }

    final metadata = releaseMetadataFetcher.fetch(versionUrl.value);
    return switch (metadata) {
      RuntimeReleaseMetadataFetched(:final metadata) => AppUpdateCheckCompleted(
        AppUpdateRecord(
          appId: appId.value,
          status: _updateStatus(
            currentVersion: Option.of(currentVersion.value),
            latestVersion: metadata.version.value,
          ),
          currentVersion: Option.of(currentVersion.value),
          latestVersion: Option.of(metadata.version.value),
          versionUrl: Option.of(versionUrl.value),
          archiveUrl: metadata.archiveUrl.match(
            () => archiveUrl.map((value) => value.value),
            (value) => Option.of(value.value),
          ),
          archiveSha256: metadata.archiveSha256.match(
            () => archiveSha256.map((value) => value.value),
            (value) => Option.of(value.value),
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
    return _fileNameFromUrl(url).match(() => false, (fileName) {
      final normalizedFileName = fileName.toLowerCase();
      return switch (hostPlatform) {
        KonyakHostPlatform.macos =>
          normalizedFileName.contains('-macos-') &&
              normalizedFileName.endsWith('.dmg'),
        KonyakHostPlatform.linux =>
          normalizedFileName.contains('-linux-') &&
              normalizedFileName.endsWith('.appimage'),
      };
    });
  };
}
