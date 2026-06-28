import 'dart:async';
import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../domain/runtime/runtime_package_installation.dart';
import '../shared/model_constants.dart';
import 'external_payload_helpers.dart';
import 'platform_runtime_sources.dart';
import 'runtime_install_progress_io.dart';

typedef RuntimeStackSourceArchiveDownloadResult = Either<String, Unit>;

RuntimeStackSourceArchiveDownloadResult downloadRuntimeStackSourceArchive({
  required String source,
  required String targetPath,
  required RuntimeInstallProgressSink? progressSink,
  required String stage,
  required String message,
  required double startFraction,
  required double endFraction,
}) {
  final localPath = localSourcePath(source);
  if (localPath != null) {
    emitRuntimeInstallProgress(
      progressSink,
      stage: stage,
      message: message,
      fraction: startFraction,
    );
    File(targetPath).parent.createSync(recursive: true);
    File(localPath).copySync(targetPath);
    emitRuntimeInstallProgress(
      progressSink,
      stage: stage,
      message: message,
      fraction: endFraction,
    );
    return const Right<String, Unit>(unit);
  }

  emitRuntimeInstallProgress(
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
    return Left<String, Unit>(
      commandFailureMessage('download runtime stack component', result),
    );
  }
  emitRuntimeInstallProgress(
    progressSink,
    stage: stage,
    message: message,
    fraction: endFraction,
  );
  return const Right<String, Unit>(unit);
}

Future<RuntimeStackSourceArchiveDownloadResult>
downloadRuntimeStackSourceArchiveStreaming({
  required String source,
  required String targetPath,
  required RuntimeInstallProgressSink? progressSink,
  required String stage,
  required String message,
  required double startFraction,
  required double endFraction,
}) {
  final localPath = localSourcePath(source);
  if (localPath != null) {
    return copyRuntimeStackSourceArchiveStreaming(
      sourcePath: localPath,
      targetPath: targetPath,
      progressSink: progressSink,
      stage: stage,
      message: message,
      startFraction: startFraction,
      endFraction: endFraction,
    );
  }

  return downloadRuntimeStackSourceUriStreaming(
    source: source,
    targetPath: targetPath,
    progressSink: progressSink,
    stage: stage,
    message: message,
    startFraction: startFraction,
    endFraction: endFraction,
  );
}

Future<RuntimeStackSourceArchiveDownloadResult>
copyRuntimeStackSourceArchiveStreaming({
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

    emitRuntimeInstallProgress(
      progressSink,
      stage: stage,
      message: message,
      fraction: startFraction,
    );
    try {
      await for (final chunk in source.openRead()) {
        copiedBytes += chunk.length;
        sink.add(chunk);
        emitRuntimeInstallByteProgress(
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

    emitRuntimeInstallProgress(
      progressSink,
      stage: stage,
      message: message,
      fraction: endFraction,
    );
    return const Right<String, Unit>(unit);
  } on FileSystemException catch (error) {
    return Left<String, Unit>(error.message);
  }
}

Future<RuntimeStackSourceArchiveDownloadResult>
downloadRuntimeStackSourceUriStreaming({
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
    return Left<String, Unit>(
      'Runtime stack component URL is invalid: $source',
    );
  }

  final client = HttpClient();
  try {
    emitRuntimeInstallProgress(
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
      return Left<String, Unit>(
        'download runtime stack component failed with HTTP status '
        '${response.statusCode}.',
      );
    }

    final totalBytes = response.contentLength;
    var receivedBytes = 0;
    File(targetPath).parent.createSync(recursive: true);
    final sink = File(targetPath).openWrite();
    try {
      await for (final chunk in response) {
        receivedBytes += chunk.length;
        sink.add(chunk);
        emitRuntimeInstallByteProgress(
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

    emitRuntimeInstallProgress(
      progressSink,
      stage: stage,
      message: message,
      fraction: endFraction,
    );
    return const Right<String, Unit>(unit);
  } on HttpException catch (error) {
    return Left<String, Unit>(error.message);
  } on IOException catch (error) {
    return Left<String, Unit>(error.toString());
  } finally {
    client.close(force: true);
  }
}

void emitRuntimeInstallByteProgress(
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
  emitRuntimeInstallProgress(
    progressSink,
    stage: stage,
    message: message,
    fraction: startFraction + (endFraction - startFraction) * byteFraction,
  );
}

void emitRuntimeInstallProgress(
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
