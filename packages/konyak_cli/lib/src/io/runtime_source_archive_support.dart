import 'dart:async';
import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../domain/runtime/runtime_models.dart';
import '../domain/runtime/runtime_source_archive_planning.dart';
import '../domain/runtime/runtime_source_bundle_models.dart';
import '../domain/runtime/runtime_validation_models.dart';
import 'file_digest_io.dart';
import 'runtime_install_progress_io.dart';
import 'runtime_source_archive_downloads.dart';

RuntimeStackSourceArchiveBundleResult resolveRuntimeStackSourceArchiveBundle({
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
      return resolveRuntimeStackSourceArchiveBundleFromPlan(
        plan: plan,
        progressSink: progressSink,
      );
    case RuntimeStackSourceArchivePlanFailed(:final message):
      return RuntimeStackSourceArchiveBundleFailed(message);
  }
}

RuntimeStackSourceArchiveBundleResult
resolveRuntimeStackSourceArchiveBundleFromPlan({
  required RuntimeStackSourceArchivePlan plan,
  required RuntimeInstallProgressSink? progressSink,
}) {
  for (final componentPlan in plan.components) {
    switch (downloadRuntimeStackSourceArchive(
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

    emitRuntimeInstallProgress(
      progressSink,
      stage: 'verifying',
      message: componentPlan.verifyingMessage,
      fraction: componentPlan.endFraction.value,
    );
    final actualSha256 = sha256HexDigest(File(componentPlan.archivePath.value));
    if (actualSha256.toLowerCase() !=
        componentPlan.component.sha256.value.toLowerCase()) {
      return RuntimeStackSourceArchiveBundleFailed(
        'Runtime stack component `${componentPlan.component.id.value}` checksum '
        'mismatch: expected ${componentPlan.component.sha256.value}, '
        'got $actualSha256.',
      );
    }
  }

  return plan.toBundle();
}

Future<RuntimeStackSourceArchiveBundleResult>
resolveRuntimeStackSourceArchiveBundleStreaming({
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
      return resolveRuntimeStackSourceArchiveBundleFromPlanStreaming(
        plan: plan,
        progressSink: progressSink,
      );
    case RuntimeStackSourceArchivePlanFailed(:final message):
      return RuntimeStackSourceArchiveBundleFailed(message);
  }
}

Future<RuntimeStackSourceArchiveBundleResult>
resolveRuntimeStackSourceArchiveBundleFromPlanStreaming({
  required RuntimeStackSourceArchivePlan plan,
  required RuntimeInstallProgressSink? progressSink,
}) async {
  for (final componentPlan in plan.components) {
    switch (await downloadRuntimeStackSourceArchiveStreaming(
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

    emitRuntimeInstallProgress(
      progressSink,
      stage: 'verifying',
      message: componentPlan.verifyingMessage,
      fraction: componentPlan.endFraction.value,
    );
    final actualSha256 = sha256HexDigest(File(componentPlan.archivePath.value));
    if (actualSha256.toLowerCase() !=
        componentPlan.component.sha256.value.toLowerCase()) {
      return RuntimeStackSourceArchiveBundleFailed(
        'Runtime stack component `${componentPlan.component.id.value}` checksum '
        'mismatch: expected ${componentPlan.component.sha256.value}, '
        'got $actualSha256.',
      );
    }
  }

  return plan.toBundle();
}
