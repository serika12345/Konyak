part of '../../../konyak_cli.dart';

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
