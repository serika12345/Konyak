part of '../konyak_cli.dart';

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

String? _downloadRuntimeStackSourceArchive({
  required String source,
  required String targetPath,
  required RuntimeInstallProgressSink? progressSink,
  required String stage,
  required String message,
  required double startFraction,
  required double endFraction,
}) {
  final localPath = _localSourcePath(source);
  if (localPath != null) {
    _emitRuntimeInstallProgress(
      progressSink,
      stage: stage,
      message: message,
      fraction: startFraction,
    );
    File(targetPath).parent.createSync(recursive: true);
    File(localPath).copySync(targetPath);
    _emitRuntimeInstallProgress(
      progressSink,
      stage: stage,
      message: message,
      fraction: endFraction,
    );
    return null;
  }

  _emitRuntimeInstallProgress(
    progressSink,
    stage: stage,
    message: message,
    fraction: startFraction,
  );
  final result = Process.runSync('curl', [
    '--fail',
    '--location',
    '--output',
    targetPath,
    source,
  ], runInShell: false);
  if (result.exitCode != 0) {
    return _commandFailureMessage('download runtime stack component', result);
  }
  _emitRuntimeInstallProgress(
    progressSink,
    stage: stage,
    message: message,
    fraction: endFraction,
  );
  return null;
}

Future<String?> _downloadRuntimeStackSourceArchiveStreaming({
  required String source,
  required String targetPath,
  required RuntimeInstallProgressSink? progressSink,
  required String stage,
  required String message,
  required double startFraction,
  required double endFraction,
}) {
  final localPath = _localSourcePath(source);
  if (localPath != null) {
    return _copyRuntimeStackSourceArchiveStreaming(
      sourcePath: localPath,
      targetPath: targetPath,
      progressSink: progressSink,
      stage: stage,
      message: message,
      startFraction: startFraction,
      endFraction: endFraction,
    );
  }

  return _downloadRuntimeStackSourceUriStreaming(
    source: source,
    targetPath: targetPath,
    progressSink: progressSink,
    stage: stage,
    message: message,
    startFraction: startFraction,
    endFraction: endFraction,
  );
}

Future<String?> _copyRuntimeStackSourceArchiveStreaming({
  required String sourcePath,
  required String targetPath,
  required RuntimeInstallProgressSink? progressSink,
  required String stage,
  required String message,
  required double startFraction,
  required double endFraction,
}) async {
  try {
    final source = File(sourcePath);
    final totalBytes = await source.length();
    var copiedBytes = 0;
    File(targetPath).parent.createSync(recursive: true);
    final sink = File(targetPath).openWrite();

    _emitRuntimeInstallProgress(
      progressSink,
      stage: stage,
      message: message,
      fraction: startFraction,
    );
    try {
      await for (final chunk in source.openRead()) {
        copiedBytes += chunk.length;
        sink.add(chunk);
        _emitRuntimeInstallByteProgress(
          progressSink,
          stage: stage,
          message: message,
          copiedBytes: copiedBytes,
          totalBytes: totalBytes,
          startFraction: startFraction,
          endFraction: endFraction,
        );
      }
    } finally {
      await sink.close();
    }

    _emitRuntimeInstallProgress(
      progressSink,
      stage: stage,
      message: message,
      fraction: endFraction,
    );
    return null;
  } on FileSystemException catch (error) {
    return error.message;
  }
}

Future<String?> _downloadRuntimeStackSourceUriStreaming({
  required String source,
  required String targetPath,
  required RuntimeInstallProgressSink? progressSink,
  required String stage,
  required String message,
  required double startFraction,
  required double endFraction,
}) async {
  final uri = Uri.tryParse(source);
  if (uri == null || !uri.hasScheme) {
    return 'Runtime stack component URL is invalid: $source';
  }

  final client = HttpClient();
  try {
    _emitRuntimeInstallProgress(
      progressSink,
      stage: stage,
      message: message,
      fraction: startFraction,
    );

    final request = await client.getUrl(uri);
    request.headers.set(
      HttpHeaders.userAgentHeader,
      'Konyak/$konyakAppVersion',
    );
    final response = await request.close();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return 'download runtime stack component failed with HTTP status '
          '${response.statusCode}.';
    }

    final totalBytes = response.contentLength;
    var receivedBytes = 0;
    File(targetPath).parent.createSync(recursive: true);
    final sink = File(targetPath).openWrite();
    try {
      await for (final chunk in response) {
        receivedBytes += chunk.length;
        sink.add(chunk);
        _emitRuntimeInstallByteProgress(
          progressSink,
          stage: stage,
          message: message,
          copiedBytes: receivedBytes,
          totalBytes: totalBytes,
          startFraction: startFraction,
          endFraction: endFraction,
        );
      }
    } finally {
      await sink.close();
    }

    _emitRuntimeInstallProgress(
      progressSink,
      stage: stage,
      message: message,
      fraction: endFraction,
    );
    return null;
  } on HttpException catch (error) {
    return error.message;
  } on IOException catch (error) {
    return error.toString();
  } finally {
    client.close(force: true);
  }
}

void _emitRuntimeInstallByteProgress(
  RuntimeInstallProgressSink? progressSink, {
  required String stage,
  required String message,
  required int copiedBytes,
  required int totalBytes,
  required double startFraction,
  required double endFraction,
}) {
  if (totalBytes <= 0) {
    return;
  }

  final byteFraction = copiedBytes / totalBytes;
  _emitRuntimeInstallProgress(
    progressSink,
    stage: stage,
    message: message,
    fraction: startFraction + (endFraction - startFraction) * byteFraction,
  );
}

void _emitRuntimeInstallProgress(
  RuntimeInstallProgressSink? progressSink, {
  required String stage,
  required String message,
  required double fraction,
}) {
  final normalizedFraction = fraction.clamp(0, 1).toDouble();
  progressSink?.emit(
    RuntimeInstallProgress(
      stage: stage,
      message: message,
      fraction: normalizedFraction,
    ),
  );
}
