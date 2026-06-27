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
    final currentVersion = _runtimeWineVersion(runtime);
    return runtime.versionUrl.match(
      () => _unknownRuntimeUpdateRecord(
        runtime: runtime,
        currentVersion: currentVersion,
      ),
      (versionUrl) {
        if (versionUrl.value.trim().isEmpty) {
          return _unknownRuntimeUpdateRecord(
            runtime: runtime,
            currentVersion: currentVersion,
          );
        }

        final metadata = releaseMetadataFetcher.fetch(versionUrl.value);
        return switch (metadata) {
          RuntimeReleaseMetadataFetched(:final metadata) =>
            _runtimeUpdateFromMetadata(
              runtime: runtime,
              versionUrl: versionUrl.value,
              currentVersion: currentVersion,
              metadata: metadata,
            ),
          RuntimeReleaseMetadataFetchFailed(:final message) =>
            RuntimeUpdateCheckFailed(message),
        };
      },
    );
  }
}

RuntimeUpdateCheckCompleted _unknownRuntimeUpdateRecord({
  required RuntimeRecord runtime,
  required Option<RuntimeVersion> currentVersion,
}) {
  return RuntimeUpdateCheckCompleted(
    RuntimeUpdateRecord(
      runtimeId: runtime.id.value,
      status: 'unknown',
      currentVersion: currentVersion.map((version) => version.value),
      archiveUrl: runtime.archiveUrl.map((url) => url.value),
    ),
  );
}

RuntimeUpdateCheckResult _runtimeUpdateFromMetadata({
  required RuntimeRecord runtime,
  required String versionUrl,
  required Option<RuntimeVersion> currentVersion,
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
      runtimeId: runtime.id.value,
      status: _updateStatus(
        currentVersion: currentVersion.map((version) => version.value),
        latestVersion: metadata.version.value,
      ),
      currentVersion: currentVersion.map((version) => version.value),
      latestVersion: Option.of(metadata.version.value),
      versionUrl: Option.of(versionUrl),
      archiveUrl: metadata.archiveUrl.match(
        () => runtime.archiveUrl.map((url) => url.value),
        (url) => Option.of(url.value),
      ),
      sourceManifestUrl: metadata.sourceManifestUrl.map((url) => url.value),
      sourceManifestSignatureUrl: metadata.sourceManifestSignatureUrl.map(
        (url) => url.value,
      ),
    ),
  );
}

bool _requiresRuntimeStackSourceManifest(RuntimeRecord runtime) {
  return runtime.stack.isSome();
}
