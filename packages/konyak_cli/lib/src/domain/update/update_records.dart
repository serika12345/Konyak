import 'package:fpdart/fpdart.dart';

import '../shared/domain_value_objects.dart';

class RuntimeUpdateRecord {
  RuntimeUpdateRecord({
    required String runtimeId,
    required String status,
    Option<String> currentVersion = const Option.none(),
    Option<String> latestVersion = const Option.none(),
    Option<String> versionUrl = const Option.none(),
    Option<String> archiveUrl = const Option.none(),
    Option<String> sourceManifestUrl = const Option.none(),
    Option<String> sourceManifestSignatureUrl = const Option.none(),
  }) : runtimeId = RuntimeId(runtimeId),
       status = UpdateCheckStatus(status),
       currentVersion = currentVersion.map(RuntimeVersion.new),
       latestVersion = latestVersion.map(RuntimeVersion.new),
       versionUrl = versionUrl.map(RuntimeVersionUrl.new),
       archiveUrl = archiveUrl.map(RuntimeArchiveUrl.new),
       sourceManifestUrl = sourceManifestUrl.map(RuntimeSourceManifestUrl.new),
       sourceManifestSignatureUrl = sourceManifestSignatureUrl.map(
         RuntimeSourceManifestSignatureUrl.new,
       );

  final RuntimeId runtimeId;
  final UpdateCheckStatus status;
  final Option<RuntimeVersion> currentVersion;
  final Option<RuntimeVersion> latestVersion;
  final Option<RuntimeVersionUrl> versionUrl;
  final Option<RuntimeArchiveUrl> archiveUrl;
  final Option<RuntimeSourceManifestUrl> sourceManifestUrl;
  final Option<RuntimeSourceManifestSignatureUrl> sourceManifestSignatureUrl;
}

sealed class RuntimeUpdateCheckResult {
  const RuntimeUpdateCheckResult();
}

class RuntimeUpdateCheckCompleted extends RuntimeUpdateCheckResult {
  const RuntimeUpdateCheckCompleted(this.update);

  final RuntimeUpdateRecord update;
}

class RuntimeUpdateCheckFailed extends RuntimeUpdateCheckResult {
  const RuntimeUpdateCheckFailed(this.message);

  final String message;
}

class RuntimeUpdateRuntimeNotFound extends RuntimeUpdateCheckResult {
  RuntimeUpdateRuntimeNotFound(String runtimeId)
    : runtimeId = RuntimeId(runtimeId);

  final RuntimeId runtimeId;
}

abstract interface class RuntimeUpdateChecker {
  RuntimeUpdateCheckResult check(String runtimeId);
}

class AppUpdateRecord {
  AppUpdateRecord({
    required String appId,
    required String status,
    Option<String> currentVersion = const Option.none(),
    Option<String> latestVersion = const Option.none(),
    Option<String> versionUrl = const Option.none(),
    Option<String> archiveUrl = const Option.none(),
    Option<String> archiveSha256 = const Option.none(),
  }) : appId = AppId(appId),
       status = UpdateCheckStatus(status),
       currentVersion = currentVersion.map(AppVersion.new),
       latestVersion = latestVersion.map(ReleaseVersion.new),
       versionUrl = versionUrl.map(RuntimeVersionUrl.new),
       archiveUrl = archiveUrl.map(AppArchiveUrl.new),
       archiveSha256 = archiveSha256.map(AppArchiveSha256.new);

  final AppId appId;
  final UpdateCheckStatus status;
  final Option<AppVersion> currentVersion;
  final Option<ReleaseVersion> latestVersion;
  final Option<RuntimeVersionUrl> versionUrl;
  final Option<AppArchiveUrl> archiveUrl;
  final Option<AppArchiveSha256> archiveSha256;
}

sealed class AppUpdateCheckResult {
  const AppUpdateCheckResult();
}

class AppUpdateCheckCompleted extends AppUpdateCheckResult {
  const AppUpdateCheckCompleted(this.update);

  final AppUpdateRecord update;
}

class AppUpdateCheckFailed extends AppUpdateCheckResult {
  const AppUpdateCheckFailed(this.message);

  final String message;
}

abstract interface class AppUpdateChecker {
  AppUpdateCheckResult check();
}

class AppUpdateInstallRecord {
  AppUpdateInstallRecord({
    required String appId,
    required String status,
    Option<String> currentVersion = const Option.none(),
    Option<String> installedVersion = const Option.none(),
    Option<String> archiveUrl = const Option.none(),
    Option<String> archiveSha256 = const Option.none(),
    Option<String> installPath = const Option.none(),
  }) : appId = AppId(appId),
       status = UpdateInstallStatus(status),
       currentVersion = currentVersion.map(AppVersion.new),
       installedVersion = installedVersion.map(AppVersion.new),
       archiveUrl = archiveUrl.map(AppArchiveUrl.new),
       archiveSha256 = archiveSha256.map(AppArchiveSha256.new),
       installPath = installPath.map(AppInstallPath.new);

  final AppId appId;
  final UpdateInstallStatus status;
  final Option<AppVersion> currentVersion;
  final Option<AppVersion> installedVersion;
  final Option<AppArchiveUrl> archiveUrl;
  final Option<AppArchiveSha256> archiveSha256;
  final Option<AppInstallPath> installPath;
}

sealed class AppUpdateInstallResult {
  const AppUpdateInstallResult();
}

class AppUpdateInstallCompleted extends AppUpdateInstallResult {
  const AppUpdateInstallCompleted(this.install);

  final AppUpdateInstallRecord install;
}

class AppUpdateInstallFailed extends AppUpdateInstallResult {
  const AppUpdateInstallFailed(this.message);

  final String message;
}

abstract interface class AppUpdateInstaller {
  AppUpdateInstallResult install(AppUpdateRecord update);
}

class RuntimeReleaseMetadata {
  RuntimeReleaseMetadata({
    required String version,
    Option<String> archiveUrl = const Option.none(),
    Option<String> archiveSha256 = const Option.none(),
    Option<String> sourceManifestUrl = const Option.none(),
    Option<String> sourceManifestSignatureUrl = const Option.none(),
  }) : version = ReleaseVersion(version),
       archiveUrl = archiveUrl.map(RuntimeArchiveUrl.new),
       archiveSha256 = archiveSha256.map(RuntimeArchiveChecksumValue.new),
       sourceManifestUrl = sourceManifestUrl.map(RuntimeSourceManifestUrl.new),
       sourceManifestSignatureUrl = sourceManifestSignatureUrl.map(
         RuntimeSourceManifestSignatureUrl.new,
       );

  final ReleaseVersion version;
  final Option<RuntimeArchiveUrl> archiveUrl;
  final Option<RuntimeArchiveChecksumValue> archiveSha256;
  final Option<RuntimeSourceManifestUrl> sourceManifestUrl;
  final Option<RuntimeSourceManifestSignatureUrl> sourceManifestSignatureUrl;
}

sealed class RuntimeReleaseMetadataFetchResult {
  const RuntimeReleaseMetadataFetchResult();
}

class RuntimeReleaseMetadataFetched extends RuntimeReleaseMetadataFetchResult {
  const RuntimeReleaseMetadataFetched(this.metadata);

  final RuntimeReleaseMetadata metadata;
}

class RuntimeReleaseMetadataFetchFailed
    extends RuntimeReleaseMetadataFetchResult {
  const RuntimeReleaseMetadataFetchFailed(this.message);

  final String message;
}

abstract interface class RuntimeReleaseMetadataFetcher {
  RuntimeReleaseMetadataFetchResult fetch(String versionUrl);
}

class StaticRuntimeReleaseMetadataFetcher
    implements RuntimeReleaseMetadataFetcher {
  const StaticRuntimeReleaseMetadataFetcher(this.metadata);

  final RuntimeReleaseMetadata metadata;

  @override
  RuntimeReleaseMetadataFetchResult fetch(String versionUrl) {
    return RuntimeReleaseMetadataFetched(metadata);
  }
}
