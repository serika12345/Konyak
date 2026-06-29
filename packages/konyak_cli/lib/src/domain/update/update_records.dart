import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../shared/domain_value_objects.dart';

part 'update_records.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeUpdateRecord with _$RuntimeUpdateRecord {
  const RuntimeUpdateRecord._();

  factory RuntimeUpdateRecord({
    required String runtimeId,
    required String status,
    Option<String> currentVersion = const Option.none(),
    Option<String> latestVersion = const Option.none(),
    Option<String> versionUrl = const Option.none(),
    Option<String> archiveUrl = const Option.none(),
    Option<String> sourceManifestUrl = const Option.none(),
    Option<String> sourceManifestSignatureUrl = const Option.none(),
  }) {
    return RuntimeUpdateRecord._validated(
      runtimeId: RuntimeId(runtimeId),
      status: UpdateCheckStatus(status),
      currentVersion: currentVersion.map(RuntimeVersion.new),
      latestVersion: latestVersion.map(RuntimeVersion.new),
      versionUrl: versionUrl.map(RuntimeVersionUrl.new),
      archiveUrl: archiveUrl.map(RuntimeArchiveUrl.new),
      sourceManifestUrl: sourceManifestUrl.map(RuntimeSourceManifestUrl.new),
      sourceManifestSignatureUrl: sourceManifestSignatureUrl.map(
        RuntimeSourceManifestSignatureUrl.new,
      ),
    );
  }

  const factory RuntimeUpdateRecord._validated({
    required RuntimeId runtimeId,
    required UpdateCheckStatus status,
    required Option<RuntimeVersion> currentVersion,
    required Option<RuntimeVersion> latestVersion,
    required Option<RuntimeVersionUrl> versionUrl,
    required Option<RuntimeArchiveUrl> archiveUrl,
    required Option<RuntimeSourceManifestUrl> sourceManifestUrl,
    required Option<RuntimeSourceManifestSignatureUrl>
    sourceManifestSignatureUrl,
  }) = _RuntimeUpdateRecord;
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

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class AppUpdateRecord with _$AppUpdateRecord {
  const AppUpdateRecord._();

  factory AppUpdateRecord({
    required String appId,
    required String status,
    Option<String> currentVersion = const Option.none(),
    Option<String> latestVersion = const Option.none(),
    Option<String> versionUrl = const Option.none(),
    Option<String> archiveUrl = const Option.none(),
    Option<String> archiveSha256 = const Option.none(),
  }) {
    return AppUpdateRecord._validated(
      appId: AppId(appId),
      status: UpdateCheckStatus(status),
      currentVersion: currentVersion.map(AppVersion.new),
      latestVersion: latestVersion.map(ReleaseVersion.new),
      versionUrl: versionUrl.map(RuntimeVersionUrl.new),
      archiveUrl: archiveUrl.map(AppArchiveUrl.new),
      archiveSha256: archiveSha256.map(AppArchiveSha256.new),
    );
  }

  const factory AppUpdateRecord._validated({
    required AppId appId,
    required UpdateCheckStatus status,
    required Option<AppVersion> currentVersion,
    required Option<ReleaseVersion> latestVersion,
    required Option<RuntimeVersionUrl> versionUrl,
    required Option<AppArchiveUrl> archiveUrl,
    required Option<AppArchiveSha256> archiveSha256,
  }) = _AppUpdateRecord;
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

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class AppUpdateInstallRecord with _$AppUpdateInstallRecord {
  const AppUpdateInstallRecord._();

  factory AppUpdateInstallRecord({
    required String appId,
    required String status,
    Option<String> currentVersion = const Option.none(),
    Option<String> installedVersion = const Option.none(),
    Option<String> archiveUrl = const Option.none(),
    Option<String> archiveSha256 = const Option.none(),
    Option<String> installPath = const Option.none(),
  }) {
    return AppUpdateInstallRecord._validated(
      appId: AppId(appId),
      status: UpdateInstallStatus(status),
      currentVersion: currentVersion.map(AppVersion.new),
      installedVersion: installedVersion.map(AppVersion.new),
      archiveUrl: archiveUrl.map(AppArchiveUrl.new),
      archiveSha256: archiveSha256.map(AppArchiveSha256.new),
      installPath: installPath.map(AppInstallPath.new),
    );
  }

  const factory AppUpdateInstallRecord._validated({
    required AppId appId,
    required UpdateInstallStatus status,
    required Option<AppVersion> currentVersion,
    required Option<AppVersion> installedVersion,
    required Option<AppArchiveUrl> archiveUrl,
    required Option<AppArchiveSha256> archiveSha256,
    required Option<AppInstallPath> installPath,
  }) = _AppUpdateInstallRecord;
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

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class RuntimeReleaseMetadata with _$RuntimeReleaseMetadata {
  const RuntimeReleaseMetadata._();

  factory RuntimeReleaseMetadata({
    required String version,
    Option<String> archiveUrl = const Option.none(),
    Option<String> archiveSha256 = const Option.none(),
    Option<String> sourceManifestUrl = const Option.none(),
    Option<String> sourceManifestSignatureUrl = const Option.none(),
  }) {
    return RuntimeReleaseMetadata._validated(
      version: ReleaseVersion(version),
      archiveUrl: archiveUrl.map(RuntimeArchiveUrl.new),
      archiveSha256: archiveSha256.map(RuntimeArchiveChecksumValue.new),
      sourceManifestUrl: sourceManifestUrl.map(RuntimeSourceManifestUrl.new),
      sourceManifestSignatureUrl: sourceManifestSignatureUrl.map(
        RuntimeSourceManifestSignatureUrl.new,
      ),
    );
  }

  const factory RuntimeReleaseMetadata._validated({
    required ReleaseVersion version,
    required Option<RuntimeArchiveUrl> archiveUrl,
    required Option<RuntimeArchiveChecksumValue> archiveSha256,
    required Option<RuntimeSourceManifestUrl> sourceManifestUrl,
    required Option<RuntimeSourceManifestSignatureUrl>
    sourceManifestSignatureUrl,
  }) = _RuntimeReleaseMetadata;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class RuntimeReleaseMetadataFetchResult
    with _$RuntimeReleaseMetadataFetchResult {
  const factory RuntimeReleaseMetadataFetchResult.fetched(
    RuntimeReleaseMetadata metadata,
  ) = RuntimeReleaseMetadataFetched;

  const factory RuntimeReleaseMetadataFetchResult.failed(String message) =
      RuntimeReleaseMetadataFetchFailed;
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
