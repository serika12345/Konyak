part of '../../konyak_cli.dart';

RuntimeStackSourceArchiveBundleResult _resolveRuntimeStackSourceArchiveBundle({
  required RuntimeSourceManifest manifest,
  required RuntimePlatformSpec platformSpec,
  required Directory tempDirectory,
  required RuntimeInstallProgressSink? progressSink,
}) {
  final planResult = runtimeStackSourceArchivePlan(
    manifest: manifest,
    platformSpec: platformSpec,
    tempDirectoryPath: tempDirectory.path,
  );
  switch (planResult) {
    case RuntimeStackSourceArchivePlanResolved(:final plan):
      return _resolveRuntimeStackSourceArchiveBundleFromPlan(
        plan: plan,
        progressSink: progressSink,
      );
    case RuntimeStackSourceArchivePlanFailed(:final message):
      return RuntimeStackSourceArchiveBundleFailed(message);
  }
}

RuntimeStackSourceArchiveBundleResult
_resolveRuntimeStackSourceArchiveBundleFromPlan({
  required RuntimeStackSourceArchivePlan plan,
  required RuntimeInstallProgressSink? progressSink,
}) {
  for (final componentPlan in plan.components) {
    switch (_downloadRuntimeStackSourceArchive(
      source: componentPlan.component.archiveUrl.value,
      targetPath: componentPlan.archivePath.value,
      progressSink: progressSink,
      stage: 'downloading',
      message: componentPlan.downloadingMessage,
      startFraction: componentPlan.startFraction.value,
      endFraction: componentPlan.endFraction.value,
    )) {
      case Left<String, Unit>(:final value):
        return RuntimeStackSourceArchiveBundleFailed(value);
      case Right<String, Unit>():
        break;
    }

    _emitRuntimeInstallProgress(
      progressSink,
      stage: 'verifying',
      message: componentPlan.verifyingMessage,
      fraction: componentPlan.endFraction.value,
    );
    final actualSha256 = _sha256HexDigest(
      File(componentPlan.archivePath.value),
    );
    if (actualSha256.toLowerCase() !=
        componentPlan.component.sha256.value.toLowerCase()) {
      return RuntimeStackSourceArchiveBundleFailed(
        'Runtime stack component `${componentPlan.component.id.value}` checksum '
        'mismatch: expected ${componentPlan.component.sha256.value}, '
        'got $actualSha256.',
      );
    }
  }

  return RuntimeStackSourceArchiveBundleResolved(plan.toBundle());
}

Future<RuntimeStackSourceArchiveBundleResult>
_resolveRuntimeStackSourceArchiveBundleStreaming({
  required RuntimeSourceManifest manifest,
  required RuntimePlatformSpec platformSpec,
  required Directory tempDirectory,
  required RuntimeInstallProgressSink? progressSink,
}) async {
  final planResult = runtimeStackSourceArchivePlan(
    manifest: manifest,
    platformSpec: platformSpec,
    tempDirectoryPath: tempDirectory.path,
  );
  switch (planResult) {
    case RuntimeStackSourceArchivePlanResolved(:final plan):
      return _resolveRuntimeStackSourceArchiveBundleFromPlanStreaming(
        plan: plan,
        progressSink: progressSink,
      );
    case RuntimeStackSourceArchivePlanFailed(:final message):
      return RuntimeStackSourceArchiveBundleFailed(message);
  }
}

Future<RuntimeStackSourceArchiveBundleResult>
_resolveRuntimeStackSourceArchiveBundleFromPlanStreaming({
  required RuntimeStackSourceArchivePlan plan,
  required RuntimeInstallProgressSink? progressSink,
}) async {
  for (final componentPlan in plan.components) {
    switch (await _downloadRuntimeStackSourceArchiveStreaming(
      source: componentPlan.component.archiveUrl.value,
      targetPath: componentPlan.archivePath.value,
      progressSink: progressSink,
      stage: 'downloading',
      message: componentPlan.downloadingMessage,
      startFraction: componentPlan.startFraction.value,
      endFraction: componentPlan.endFraction.value,
    )) {
      case Left<String, Unit>(:final value):
        return RuntimeStackSourceArchiveBundleFailed(value);
      case Right<String, Unit>():
        break;
    }

    _emitRuntimeInstallProgress(
      progressSink,
      stage: 'verifying',
      message: componentPlan.verifyingMessage,
      fraction: componentPlan.endFraction.value,
    );
    final actualSha256 = _sha256HexDigest(
      File(componentPlan.archivePath.value),
    );
    if (actualSha256.toLowerCase() !=
        componentPlan.component.sha256.value.toLowerCase()) {
      return RuntimeStackSourceArchiveBundleFailed(
        'Runtime stack component `${componentPlan.component.id.value}` checksum '
        'mismatch: expected ${componentPlan.component.sha256.value}, '
        'got $actualSha256.',
      );
    }
  }

  return RuntimeStackSourceArchiveBundleResolved(plan.toBundle());
}
