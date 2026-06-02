part of '../konyak_cli.dart';

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
            archiveUrl: metadata.archiveUrl.toNullable() ?? runtime.archiveUrl,
            sourceManifestUrl: metadata.sourceManifestUrl.toNullable(),
            sourceManifestSignatureUrl: metadata.sourceManifestSignatureUrl
                .toNullable(),
          ),
        ),
      RuntimeReleaseMetadataFetchFailed(:final message) =>
        RuntimeUpdateCheckFailed(message),
    };
  }
}
