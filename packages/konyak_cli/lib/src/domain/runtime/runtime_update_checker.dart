import 'package:fpdart/fpdart.dart';

import '../shared/domain_value_objects.dart';
import '../update/update_records.dart';
import 'runtime_models.dart';
import 'runtime_update_support.dart';

RuntimeUpdateCheckCompleted unknownRuntimeUpdateRecord({
  required RuntimeRecord runtime,
  required Option<RuntimeVersion> currentVersion,
}) {
  return RuntimeUpdateCheckCompleted(
    RuntimeUpdateRecord(
      runtimeId: runtime.id,
      status: UpdateCheckStatus('unknown'),
      currentVersion: currentVersion,
      archiveUrl: runtime.archiveUrl,
    ),
  );
}

RuntimeUpdateCheckResult runtimeUpdateFromMetadata({
  required RuntimeRecord runtime,
  required RuntimeVersionUrl versionUrl,
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
      runtimeId: runtime.id,
      status: updateStatus(
        currentVersion: currentVersion,
        latestVersion: metadata.version,
      ),
      currentVersion: currentVersion,
      latestVersion: Option.of(RuntimeVersion(metadata.version.value)),
      versionUrl: Option.of(versionUrl),
      archiveUrl: metadata.archiveUrl.match(
        () => runtime.archiveUrl,
        Option.of,
      ),
      sourceManifestUrl: metadata.sourceManifestUrl,
      sourceManifestSignatureUrl: metadata.sourceManifestSignatureUrl,
    ),
  );
}

bool _requiresRuntimeStackSourceManifest(RuntimeRecord runtime) {
  return runtime.stack.isSome();
}
