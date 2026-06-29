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
    required RuntimeId runtimeId,
    required UpdateCheckStatus status,
    Option<RuntimeVersion> currentVersion = const Option.none(),
    Option<RuntimeVersion> latestVersion = const Option.none(),
    Option<RuntimeVersionUrl> versionUrl = const Option.none(),
    Option<RuntimeArchiveUrl> archiveUrl = const Option.none(),
    Option<RuntimeSourceManifestUrl> sourceManifestUrl = const Option.none(),
    Option<RuntimeSourceManifestSignatureUrl> sourceManifestSignatureUrl =
        const Option.none(),
  }) {
    return RuntimeUpdateRecord._validated(
      runtimeId: runtimeId,
      status: status,
      currentVersion: currentVersion,
      latestVersion: latestVersion,
      versionUrl: versionUrl,
      archiveUrl: archiveUrl,
      sourceManifestUrl: sourceManifestUrl,
      sourceManifestSignatureUrl: sourceManifestSignatureUrl,
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

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class RuntimeUpdateCheckResult with _$RuntimeUpdateCheckResult {
  const RuntimeUpdateCheckResult._();

  const factory RuntimeUpdateCheckResult.completed(RuntimeUpdateRecord update) =
      RuntimeUpdateCheckCompleted;

  const factory RuntimeUpdateCheckResult.failed(String message) =
      RuntimeUpdateCheckFailed;

  factory RuntimeUpdateCheckResult.runtimeNotFound(RuntimeId runtimeId) {
    return RuntimeUpdateCheckResult._runtimeNotFound(runtimeId);
  }

  const factory RuntimeUpdateCheckResult._runtimeNotFound(RuntimeId runtimeId) =
      RuntimeUpdateRuntimeNotFound;
}

abstract interface class RuntimeUpdateChecker {
  RuntimeUpdateCheckResult check(RuntimeId runtimeId);
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class AppUpdateRecord with _$AppUpdateRecord {
  const AppUpdateRecord._();

  factory AppUpdateRecord({
    required AppId appId,
    required UpdateCheckStatus status,
    Option<AppVersion> currentVersion = const Option.none(),
    Option<ReleaseVersion> latestVersion = const Option.none(),
    Option<RuntimeVersionUrl> versionUrl = const Option.none(),
    Option<AppArchiveUrl> archiveUrl = const Option.none(),
    Option<AppArchiveSha256> archiveSha256 = const Option.none(),
  }) {
    return AppUpdateRecord._validated(
      appId: appId,
      status: status,
      currentVersion: currentVersion,
      latestVersion: latestVersion,
      versionUrl: versionUrl,
      archiveUrl: archiveUrl,
      archiveSha256: archiveSha256,
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

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class AppUpdateCheckResult with _$AppUpdateCheckResult {
  const factory AppUpdateCheckResult.completed(AppUpdateRecord update) =
      AppUpdateCheckCompleted;

  const factory AppUpdateCheckResult.failed(String message) =
      AppUpdateCheckFailed;
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
    required AppId appId,
    required UpdateInstallStatus status,
    Option<AppVersion> currentVersion = const Option.none(),
    Option<AppVersion> installedVersion = const Option.none(),
    Option<AppArchiveUrl> archiveUrl = const Option.none(),
    Option<AppArchiveSha256> archiveSha256 = const Option.none(),
    Option<AppInstallPath> installPath = const Option.none(),
  }) {
    return AppUpdateInstallRecord._validated(
      appId: appId,
      status: status,
      currentVersion: currentVersion,
      installedVersion: installedVersion,
      archiveUrl: archiveUrl,
      archiveSha256: archiveSha256,
      installPath: installPath,
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

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class AppUpdateInstallResult with _$AppUpdateInstallResult {
  const factory AppUpdateInstallResult.completed(
    AppUpdateInstallRecord install,
  ) = AppUpdateInstallCompleted;

  const factory AppUpdateInstallResult.failed(String message) =
      AppUpdateInstallFailed;
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
    required ReleaseVersion version,
    Option<RuntimeArchiveUrl> archiveUrl = const Option.none(),
    Option<RuntimeArchiveChecksumValue> archiveSha256 = const Option.none(),
    Option<RuntimeSourceManifestUrl> sourceManifestUrl = const Option.none(),
    Option<RuntimeSourceManifestSignatureUrl> sourceManifestSignatureUrl =
        const Option.none(),
  }) {
    return RuntimeReleaseMetadata._validated(
      version: version,
      archiveUrl: archiveUrl,
      archiveSha256: archiveSha256,
      sourceManifestUrl: sourceManifestUrl,
      sourceManifestSignatureUrl: sourceManifestSignatureUrl,
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
  RuntimeReleaseMetadataFetchResult fetch(RuntimeVersionUrl versionUrl);
}

class StaticRuntimeReleaseMetadataFetcher
    implements RuntimeReleaseMetadataFetcher {
  const StaticRuntimeReleaseMetadataFetcher(this.metadata);

  final RuntimeReleaseMetadata metadata;

  @override
  RuntimeReleaseMetadataFetchResult fetch(RuntimeVersionUrl versionUrl) {
    return RuntimeReleaseMetadataFetched(metadata);
  }
}
