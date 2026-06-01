part of '../konyak_cli.dart';

class RuntimeUpdateRecord {
  const RuntimeUpdateRecord({
    required this.runtimeId,
    required this.status,
    this.currentVersion,
    this.latestVersion,
    this.versionUrl,
    this.archiveUrl,
    this.sourceManifestUrl,
    this.sourceManifestSignatureUrl,
  });

  final String runtimeId;
  final String status;
  final String? currentVersion;
  final String? latestVersion;
  final String? versionUrl;
  final String? archiveUrl;
  final String? sourceManifestUrl;
  final String? sourceManifestSignatureUrl;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'runtimeId': runtimeId,
      'status': status,
      if (currentVersion != null) 'currentVersion': currentVersion,
      if (latestVersion != null) 'latestVersion': latestVersion,
      if (versionUrl != null) 'versionUrl': versionUrl,
      if (archiveUrl != null) 'archiveUrl': archiveUrl,
      if (sourceManifestUrl != null) 'sourceManifestUrl': sourceManifestUrl,
      if (sourceManifestSignatureUrl != null)
        'sourceManifestSignatureUrl': sourceManifestSignatureUrl,
    };
  }
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
  const AppUpdateRecord({
    required this.appId,
    required this.status,
    this.currentVersion,
    this.latestVersion,
    this.versionUrl,
    this.archiveUrl,
    this.archiveSha256,
  });

  final String appId;
  final String status;
  final String? currentVersion;
  final String? latestVersion;
  final String? versionUrl;
  final String? archiveUrl;
  final String? archiveSha256;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'appId': appId,
      'status': status,
      if (currentVersion != null) 'currentVersion': currentVersion,
      if (latestVersion != null) 'latestVersion': latestVersion,
      if (versionUrl != null) 'versionUrl': versionUrl,
      if (archiveUrl != null) 'archiveUrl': archiveUrl,
      if (archiveSha256 != null) 'archiveSha256': archiveSha256,
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
  const RuntimeReleaseMetadata({
    required this.version,
    this.archiveUrl,
    this.archiveSha256,
    this.sourceManifestUrl,
    this.sourceManifestSignatureUrl,
  });

  final String version;
  final String? archiveUrl;
  final String? archiveSha256;
  final String? sourceManifestUrl;
  final String? sourceManifestSignatureUrl;
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

class DartIoRuntimeReleaseMetadataFetcher
    implements RuntimeReleaseMetadataFetcher {
  const DartIoRuntimeReleaseMetadataFetcher();

  @override
  RuntimeReleaseMetadataFetchResult fetch(String versionUrl) {
    try {
      final result = Process.runSync('curl', [
        '--fail',
        '--location',
        '--silent',
        versionUrl,
      ], runInShell: false);
      if (result.exitCode != 0) {
        return RuntimeReleaseMetadataFetchFailed(
          _commandFailureMessage('check runtime update', result),
        );
      }

      final decoded = jsonDecode(_processOutputToString(result.stdout));
      final version = _runtimeReleaseVersion(decoded);
      if (version == null) {
        return const RuntimeReleaseMetadataFetchFailed(
          'Runtime release metadata does not contain a version.',
        );
      }

      final archiveUrl = _runtimeReleaseArchiveUrl(decoded);
      return RuntimeReleaseMetadataFetched(
        RuntimeReleaseMetadata(
          version: version,
          archiveUrl: archiveUrl,
          archiveSha256: _runtimeReleaseArchiveSha256(decoded, archiveUrl),
          sourceManifestUrl: _runtimeReleaseSourceManifestUrl(decoded),
          sourceManifestSignatureUrl: _runtimeReleaseSourceManifestSignatureUrl(
            decoded,
          ),
        ),
      );
    } on FormatException {
      return const RuntimeReleaseMetadataFetchFailed(
        'Runtime release metadata is not valid JSON.',
      );
    } on ProcessException catch (error) {
      return RuntimeReleaseMetadataFetchFailed(error.message);
    }
  }
}

class DartIoRuntimeUpdateChecker implements RuntimeUpdateChecker {
  const DartIoRuntimeUpdateChecker({
    required this.runtimeCatalog,
    this.releaseMetadataFetcher = const DartIoRuntimeReleaseMetadataFetcher(),
  });

  final RuntimeCatalog runtimeCatalog;
  final RuntimeReleaseMetadataFetcher releaseMetadataFetcher;

  @override
  RuntimeUpdateCheckResult check(String runtimeId) {
    final runtime = _runtimeById(runtimeCatalog.listRuntimes(), runtimeId);
    if (runtime == null) {
      return RuntimeUpdateRuntimeNotFound(runtimeId);
    }

    final versionUrl = runtime.versionUrl;
    if (versionUrl == null || versionUrl.trim().isEmpty) {
      return RuntimeUpdateCheckCompleted(
        RuntimeUpdateRecord(
          runtimeId: runtime.id,
          status: 'unknown',
          currentVersion: _runtimeWineVersion(runtime),
          archiveUrl: runtime.archiveUrl,
        ),
      );
    }

    final metadata = releaseMetadataFetcher.fetch(versionUrl);
    return switch (metadata) {
      RuntimeReleaseMetadataFetched(:final metadata) =>
        RuntimeUpdateCheckCompleted(
          RuntimeUpdateRecord(
            runtimeId: runtime.id,
            status: _updateStatus(
              currentVersion: _runtimeWineVersion(runtime),
              latestVersion: metadata.version,
            ),
            currentVersion: _runtimeWineVersion(runtime),
            latestVersion: metadata.version,
            versionUrl: versionUrl,
            archiveUrl: metadata.archiveUrl ?? runtime.archiveUrl,
            sourceManifestUrl: metadata.sourceManifestUrl,
            sourceManifestSignatureUrl: metadata.sourceManifestSignatureUrl,
          ),
        ),
      RuntimeReleaseMetadataFetchFailed(:final message) =>
        RuntimeUpdateCheckFailed(message),
    };
  }
}

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
          archiveUrl: metadata.archiveUrl ?? archiveUrl,
          archiveSha256: metadata.archiveSha256 ?? archiveSha256,
        ),
      ),
      RuntimeReleaseMetadataFetchFailed(:final message) => AppUpdateCheckFailed(
        message,
      ),
    };
  }
}

class DartIoAppUpdateInstaller implements AppUpdateInstaller {
  DartIoAppUpdateInstaller({
    required Map<String, String> environment,
    KonyakHostPlatform? hostPlatform,
    PathOpener pathOpener = const DartIoPathOpener(),
    DetachedProcessStarter detachedProcessStarter =
        const DartIoDetachedProcessStarter(),
  }) : environment = Map.unmodifiable(environment),
       hostPlatform = hostPlatform ?? _currentHostPlatform(),
       _pathOpener = pathOpener,
       _detachedProcessStarter = detachedProcessStarter;

  factory DartIoAppUpdateInstaller.fromEnvironment(
    Map<String, String> environment,
  ) {
    return DartIoAppUpdateInstaller(environment: environment);
  }

  final Map<String, String> environment;
  final KonyakHostPlatform hostPlatform;
  final PathOpener _pathOpener;
  final DetachedProcessStarter _detachedProcessStarter;

  @override
  AppUpdateInstallResult install(AppUpdateRecord update) {
    final archiveUrl = update.archiveUrl;
    if (archiveUrl == null || archiveUrl.trim().isEmpty) {
      return const AppUpdateInstallFailed(
        'Konyak update metadata does not contain an archive URL.',
      );
    }
    final expectedSha256 = update.archiveSha256;
    if (expectedSha256 == null || !_isSha256Hex(expectedSha256)) {
      return const AppUpdateInstallFailed(
        'Konyak update metadata does not contain a valid archive checksum.',
      );
    }

    final fileName = _fileNameFromUrl(archiveUrl) ?? 'Konyak-update';
    final updatesDirectory = Directory(_appUpdateCacheDirectory(environment));
    final archivePath = _joinPath(updatesDirectory.path, [fileName]);

    try {
      updatesDirectory.createSync(recursive: true);
      final download = Process.runSync('curl', [
        '--fail',
        '--location',
        '--output',
        archivePath,
        archiveUrl,
      ], runInShell: false);
      if (download.exitCode != 0) {
        return AppUpdateInstallFailed(
          _commandFailureMessage('download Konyak update', download),
        );
      }

      final archive = File(archivePath);
      final actualSha256 = _sha256HexDigest(archive);
      if (actualSha256.toLowerCase() != expectedSha256.toLowerCase()) {
        if (archive.existsSync()) {
          archive.deleteSync();
        }
        return AppUpdateInstallFailed(
          'Konyak update archive checksum mismatch: expected '
          '$expectedSha256, got $actualSha256.',
        );
      }

      if (hostPlatform == KonyakHostPlatform.macos) {
        final macosResult = _installMacosAppBundleUpdate(
          update: update,
          archivePath: archivePath,
          actualSha256: actualSha256,
          updatesDirectory: updatesDirectory,
        );
        if (macosResult != null) {
          return macosResult;
        }
      }

      if (hostPlatform == KonyakHostPlatform.linux) {
        final linuxResult = _installLinuxAppImageUpdate(
          update: update,
          archivePath: archivePath,
          actualSha256: actualSha256,
          updatesDirectory: updatesDirectory,
        );
        if (linuxResult != null) {
          return linuxResult;
        }
      }

      final openResult = _pathOpener.openPath(archivePath);
      return switch (openResult) {
        PathOpenCompleted() => AppUpdateInstallCompleted(
          AppUpdateInstallRecord(
            appId: update.appId,
            status: 'installed',
            currentVersion: update.currentVersion,
            installedVersion: update.latestVersion,
            archiveUrl: archiveUrl,
            archiveSha256: actualSha256,
            installPath: archivePath,
          ),
        ),
        PathOpenFailed(:final message) => AppUpdateInstallFailed(message),
      };
    } on FileSystemException catch (error) {
      return AppUpdateInstallFailed(error.message);
    } on ProcessException catch (error) {
      return AppUpdateInstallFailed(error.message);
    }
  }

  AppUpdateInstallResult? _installMacosAppBundleUpdate({
    required AppUpdateRecord update,
    required String archivePath,
    required String actualSha256,
    required Directory updatesDirectory,
  }) {
    final targetBundlePath = _macosAppBundlePath(environment);
    final appPid = _konyakAppPid(environment);
    if (targetBundlePath == null || appPid == null) {
      return null;
    }

    final targetBundle = Directory(targetBundlePath);
    if (!targetBundle.existsSync()) {
      return AppUpdateInstallFailed(
        'Current Konyak app bundle does not exist: $targetBundlePath',
      );
    }

    final stagedArchivePath = _joinPath(updatesDirectory.path, [
      'Konyak-update-${DateTime.now().microsecondsSinceEpoch}.zip',
    ]);
    final stagedArchive = File(stagedArchivePath);
    stagedArchive.parent.createSync(recursive: true);
    File(archivePath).copySync(stagedArchivePath);
    stagedArchive.setLastModifiedSync(DateTime.now());

    final handoffScriptPath = _joinPath(updatesDirectory.path, [
      'install-macos-app-update-${DateTime.now().microsecondsSinceEpoch}.sh',
    ]);
    final handoffScript = File(handoffScriptPath);
    handoffScript.writeAsStringSync(_macosAppBundleUpdateHandoffScript());
    handoffScript.setLastModifiedSync(DateTime.now());
    Process.runSync('chmod', ['755', handoffScriptPath], runInShell: false);

    final startResult = _detachedProcessStarter.start(
      executable: 'bash',
      arguments: [
        handoffScriptPath,
        stagedArchivePath,
        targetBundlePath,
        '$appPid',
      ],
    );
    return switch (startResult) {
      DetachedProcessStartCompleted() => AppUpdateInstallCompleted(
        AppUpdateInstallRecord(
          appId: update.appId,
          status: 'installed',
          currentVersion: update.currentVersion,
          installedVersion: update.latestVersion,
          archiveUrl: update.archiveUrl,
          archiveSha256: actualSha256,
          installPath: targetBundlePath,
        ),
      ),
      DetachedProcessStartFailed(:final message) => AppUpdateInstallFailed(
        message,
      ),
    };
  }

  AppUpdateInstallResult? _installLinuxAppImageUpdate({
    required AppUpdateRecord update,
    required String archivePath,
    required String actualSha256,
    required Directory updatesDirectory,
  }) {
    final targetPath = _linuxAppImageTargetPath(environment);
    final appPid = _konyakAppPid(environment);
    if (targetPath == null || appPid == null) {
      return null;
    }

    final stagedArchivePath = _joinPath(updatesDirectory.path, [
      'Konyak-update-${DateTime.now().microsecondsSinceEpoch}.AppImage',
    ]);
    final stagedArchive = File(stagedArchivePath);
    stagedArchive.parent.createSync(recursive: true);
    File(archivePath).copySync(stagedArchivePath);
    stagedArchive.setLastModifiedSync(DateTime.now());

    final handoffScriptPath = _joinPath(updatesDirectory.path, [
      'install-appimage-update-${DateTime.now().microsecondsSinceEpoch}.sh',
    ]);
    final handoffScript = File(handoffScriptPath);
    handoffScript.writeAsStringSync(_linuxAppImageUpdateHandoffScript());
    handoffScript.setLastModifiedSync(DateTime.now());
    Process.runSync('chmod', ['755', handoffScriptPath], runInShell: false);

    final startResult = _detachedProcessStarter.start(
      executable: 'bash',
      arguments: [handoffScriptPath, stagedArchivePath, targetPath, '$appPid'],
    );
    return switch (startResult) {
      DetachedProcessStartCompleted() => AppUpdateInstallCompleted(
        AppUpdateInstallRecord(
          appId: update.appId,
          status: 'installed',
          currentVersion: update.currentVersion,
          installedVersion: update.latestVersion,
          archiveUrl: update.archiveUrl,
          archiveSha256: actualSha256,
          installPath: targetPath,
        ),
      ),
      DetachedProcessStartFailed(:final message) => AppUpdateInstallFailed(
        message,
      ),
    };
  }
}
