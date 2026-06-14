part of '../../../konyak_cli.dart';

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
    return runtime.match(
      () => RuntimeUpdateRuntimeNotFound(runtimeId),
      _checkRuntime,
    );
  }

  RuntimeUpdateCheckResult _checkRuntime(RuntimeRecord runtime) {
    final versionUrl = runtime.versionUrl.toNullable();
    if (versionUrl == null || versionUrl.trim().isEmpty) {
      final currentVersion = _runtimeWineVersion(runtime);
      return RuntimeUpdateCheckCompleted(
        RuntimeUpdateRecord(
          runtimeId: runtime.id,
          status: 'unknown',
          currentVersion: currentVersion,
          archiveUrl: runtime.archiveUrl,
        ),
      );
    }

    final currentVersion = _runtimeWineVersion(runtime);
    final metadata = releaseMetadataFetcher.fetch(versionUrl);
    return switch (metadata) {
      RuntimeReleaseMetadataFetched(:final metadata) =>
        _runtimeUpdateFromMetadata(
          runtime: runtime,
          versionUrl: versionUrl,
          currentVersion: currentVersion,
          metadata: metadata,
        ),
      RuntimeReleaseMetadataFetchFailed(:final message) =>
        RuntimeUpdateCheckFailed(message),
    };
  }
}

RuntimeUpdateCheckResult _runtimeUpdateFromMetadata({
  required RuntimeRecord runtime,
  required String versionUrl,
  required Option<String> currentVersion,
  required RuntimeReleaseMetadata metadata,
}) {
  if (_requiresRuntimeStackSourceManifest(runtime) &&
      metadata.sourceManifestUrl.isNone()) {
    return RuntimeUpdateCheckFailed(
      '${runtime.id} release metadata must include a runtime stack '
      'source manifest.',
    );
  }

  return RuntimeUpdateCheckCompleted(
    RuntimeUpdateRecord(
      runtimeId: runtime.id,
      status: _updateStatus(
        currentVersion: currentVersion,
        latestVersion: metadata.version,
      ),
      currentVersion: currentVersion,
      latestVersion: Option.of(metadata.version),
      versionUrl: Option.of(versionUrl),
      archiveUrl: Option.fromNullable(
        metadata.archiveUrl.toNullable() ?? runtime.archiveUrl.toNullable(),
      ),
      sourceManifestUrl: metadata.sourceManifestUrl,
      sourceManifestSignatureUrl: metadata.sourceManifestSignatureUrl,
    ),
  );
}

bool _requiresRuntimeStackSourceManifest(RuntimeRecord runtime) {
  return runtime.id == macosWineRuntimeId && runtime.stack.isSome();
}
