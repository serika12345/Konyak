part of '../../konyak_cli.dart';

_RuntimeStackSourceArchiveBundleResult _resolveRuntimeStackSourceArchiveBundle({
  required RuntimeSourceManifest manifest,
  required _RuntimePlatformSpec platformSpec,
  required Directory tempDirectory,
  required RuntimeInstallProgressSink? progressSink,
}) {
  final planResult = _runtimeStackSourceArchivePlan(
    manifest: manifest,
    platformSpec: platformSpec,
    tempDirectoryPath: tempDirectory.path,
  );
  switch (planResult) {
    case _RuntimeStackSourceArchivePlanResolved(:final plan):
      return _resolveRuntimeStackSourceArchiveBundleFromPlan(
        plan: plan,
        progressSink: progressSink,
      );
    case _RuntimeStackSourceArchivePlanFailed(:final message):
      return _RuntimeStackSourceArchiveBundleFailed(message);
  }
}

_RuntimeStackSourceArchiveBundleResult
_resolveRuntimeStackSourceArchiveBundleFromPlan({
  required _RuntimeStackSourceArchivePlan plan,
  required RuntimeInstallProgressSink? progressSink,
}) {
  for (final componentPlan in plan.components) {
    final downloadFailure = _downloadRuntimeStackSourceArchive(
      source: componentPlan.component.archiveUrl,
      targetPath: componentPlan.archivePath,
      progressSink: progressSink,
      stage: 'downloading',
      message: componentPlan.downloadingMessage,
      startFraction: componentPlan.startFraction,
      endFraction: componentPlan.endFraction,
    );
    if (downloadFailure != null) {
      return _RuntimeStackSourceArchiveBundleFailed(downloadFailure);
    }

    _emitRuntimeInstallProgress(
      progressSink,
      stage: 'verifying',
      message: componentPlan.verifyingMessage,
      fraction: componentPlan.endFraction,
    );
    final actualSha256 = _sha256HexDigest(File(componentPlan.archivePath));
    if (actualSha256.toLowerCase() !=
        componentPlan.component.sha256.toLowerCase()) {
      return _RuntimeStackSourceArchiveBundleFailed(
        'Runtime stack component `${componentPlan.component.id}` checksum '
        'mismatch: expected ${componentPlan.component.sha256}, '
        'got $actualSha256.',
      );
    }
  }

  return _RuntimeStackSourceArchiveBundleResolved(plan.toBundle());
}

Future<_RuntimeStackSourceArchiveBundleResult>
_resolveRuntimeStackSourceArchiveBundleStreaming({
  required RuntimeSourceManifest manifest,
  required _RuntimePlatformSpec platformSpec,
  required Directory tempDirectory,
  required RuntimeInstallProgressSink? progressSink,
}) async {
  final planResult = _runtimeStackSourceArchivePlan(
    manifest: manifest,
    platformSpec: platformSpec,
    tempDirectoryPath: tempDirectory.path,
  );
  switch (planResult) {
    case _RuntimeStackSourceArchivePlanResolved(:final plan):
      return _resolveRuntimeStackSourceArchiveBundleFromPlanStreaming(
        plan: plan,
        progressSink: progressSink,
      );
    case _RuntimeStackSourceArchivePlanFailed(:final message):
      return _RuntimeStackSourceArchiveBundleFailed(message);
  }
}

Future<_RuntimeStackSourceArchiveBundleResult>
_resolveRuntimeStackSourceArchiveBundleFromPlanStreaming({
  required _RuntimeStackSourceArchivePlan plan,
  required RuntimeInstallProgressSink? progressSink,
}) async {
  for (final componentPlan in plan.components) {
    final downloadFailure = await _downloadRuntimeStackSourceArchiveStreaming(
      source: componentPlan.component.archiveUrl,
      targetPath: componentPlan.archivePath,
      progressSink: progressSink,
      stage: 'downloading',
      message: componentPlan.downloadingMessage,
      startFraction: componentPlan.startFraction,
      endFraction: componentPlan.endFraction,
    );
    if (downloadFailure != null) {
      return _RuntimeStackSourceArchiveBundleFailed(downloadFailure);
    }

    _emitRuntimeInstallProgress(
      progressSink,
      stage: 'verifying',
      message: componentPlan.verifyingMessage,
      fraction: componentPlan.endFraction,
    );
    final actualSha256 = _sha256HexDigest(File(componentPlan.archivePath));
    if (actualSha256.toLowerCase() !=
        componentPlan.component.sha256.toLowerCase()) {
      return _RuntimeStackSourceArchiveBundleFailed(
        'Runtime stack component `${componentPlan.component.id}` checksum '
        'mismatch: expected ${componentPlan.component.sha256}, '
        'got $actualSha256.',
      );
    }
  }

  return _RuntimeStackSourceArchiveBundleResolved(plan.toBundle());
}
