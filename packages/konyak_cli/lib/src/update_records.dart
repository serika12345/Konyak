part of '../konyak_cli.dart';

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
  }) : runtimeId = _requiredNonBlankDomainString(runtimeId, 'runtimeId'),
       status = _requiredNonBlankDomainString(status, 'status'),
       currentVersion = _requiredNonBlankUpdateOption(
         currentVersion,
         'currentVersion',
       ),
       latestVersion = _requiredNonBlankUpdateOption(
         latestVersion,
         'latestVersion',
       ),
       versionUrl = _requiredNonBlankUpdateOption(versionUrl, 'versionUrl'),
       archiveUrl = _requiredNonBlankUpdateOption(archiveUrl, 'archiveUrl'),
       sourceManifestUrl = _requiredNonBlankUpdateOption(
         sourceManifestUrl,
         'sourceManifestUrl',
       ),
       sourceManifestSignatureUrl = _requiredNonBlankUpdateOption(
         sourceManifestSignatureUrl,
         'sourceManifestSignatureUrl',
       );

  final String runtimeId;
  final String status;
  final Option<String> currentVersion;
  final Option<String> latestVersion;
  final Option<String> versionUrl;
  final Option<String> archiveUrl;
  final Option<String> sourceManifestUrl;
  final Option<String> sourceManifestSignatureUrl;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'runtimeId': runtimeId,
      'status': status,
      ..._updateJsonField('currentVersion', currentVersion),
      ..._updateJsonField('latestVersion', latestVersion),
      ..._updateJsonField('versionUrl', versionUrl),
      ..._updateJsonField('archiveUrl', archiveUrl),
      ..._updateJsonField('sourceManifestUrl', sourceManifestUrl),
      ..._updateJsonField(
        'sourceManifestSignatureUrl',
        sourceManifestSignatureUrl,
      ),
    };
  }
}

Map<String, Object?> _updateJsonField(String key, Option<String> value) {
  return value.match(
    () => const <String, Object?>{},
    (item) => <String, Object?>{key: item},
  );
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
  const RuntimeUpdateRuntimeNotFound(this.runtimeId);

  final String runtimeId;
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
  }) : appId = _requiredNonBlankDomainString(appId, 'appId'),
       status = _requiredNonBlankDomainString(status, 'status'),
       currentVersion = _requiredNonBlankUpdateOption(
         currentVersion,
         'currentVersion',
       ),
       latestVersion = _requiredNonBlankUpdateOption(
         latestVersion,
         'latestVersion',
       ),
       versionUrl = _requiredNonBlankUpdateOption(versionUrl, 'versionUrl'),
       archiveUrl = _requiredNonBlankUpdateOption(archiveUrl, 'archiveUrl'),
       archiveSha256 = _requiredNonBlankUpdateOption(
         archiveSha256,
         'archiveSha256',
       );

  final String appId;
  final String status;
  final Option<String> currentVersion;
  final Option<String> latestVersion;
  final Option<String> versionUrl;
  final Option<String> archiveUrl;
  final Option<String> archiveSha256;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'appId': appId,
      'status': status,
      ..._updateJsonField('currentVersion', currentVersion),
      ..._updateJsonField('latestVersion', latestVersion),
      ..._updateJsonField('versionUrl', versionUrl),
      ..._updateJsonField('archiveUrl', archiveUrl),
      ..._updateJsonField('archiveSha256', archiveSha256),
    };
  }
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
  const AppUpdateInstallRecord({
    required this.appId,
    required this.status,
    this.currentVersion,
    this.installedVersion,
    this.archiveUrl,
    this.archiveSha256,
    this.installPath,
  });

  final String appId;
  final String status;
  final String? currentVersion;
  final String? installedVersion;
  final String? archiveUrl;
  final String? archiveSha256;
  final String? installPath;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'appId': appId,
      'status': status,
      if (currentVersion != null) 'currentVersion': currentVersion,
      if (installedVersion != null) 'installedVersion': installedVersion,
      if (archiveUrl != null) 'archiveUrl': archiveUrl,
      if (archiveSha256 != null) 'archiveSha256': archiveSha256,
      if (installPath != null) 'installPath': installPath,
    };
  }
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
  }) : version = _requiredNonBlankDomainString(version, 'version'),
       archiveUrl = _requiredNonBlankUpdateOption(archiveUrl, 'archiveUrl'),
       archiveSha256 = _requiredNonBlankUpdateOption(
         archiveSha256,
         'archiveSha256',
       ),
       sourceManifestUrl = _requiredNonBlankUpdateOption(
         sourceManifestUrl,
         'sourceManifestUrl',
       ),
       sourceManifestSignatureUrl = _requiredNonBlankUpdateOption(
         sourceManifestSignatureUrl,
         'sourceManifestSignatureUrl',
       );

  final String version;
  final Option<String> archiveUrl;
  final Option<String> archiveSha256;
  final Option<String> sourceManifestUrl;
  final Option<String> sourceManifestSignatureUrl;
}

Option<String> _requiredNonBlankUpdateOption(
  Option<String> value,
  String fieldName,
) {
  return value.map((item) => _requiredNonBlankDomainString(item, fieldName));
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
