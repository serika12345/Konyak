import 'dart:io';

import 'package:crypto/crypto.dart';

import '../shared/common_helpers.dart';
import 'external_payload_helpers.dart';

String runtimeSiblingPathForInstall(Directory runtimeRoot, String suffix) {
  return '${runtimeRoot.path}.$suffix-${DateTime.now().microsecondsSinceEpoch}';
}

void replaceRuntimeRootInPlace({
  required Directory runtimeRoot,
  required Directory stagingRoot,
  required Directory backupRoot,
}) {
  var backupCreated = false;
  if (runtimeRoot.existsSync()) {
    if (backupRoot.existsSync()) {
      backupRoot.deleteSync(recursive: true);
    }
    runtimeRoot.renameSync(backupRoot.path);
    backupCreated = true;
  }

  try {
    stagingRoot.renameSync(runtimeRoot.path);
    if (backupCreated && backupRoot.existsSync()) {
      backupRoot.deleteSync(recursive: true);
    }
  } on FileSystemException {
    if (FileSystemEntity.typeSync(runtimeRoot.path) !=
        FileSystemEntityType.notFound) {
      runtimeRoot.deleteSync(recursive: true);
    }
    if (backupCreated && backupRoot.existsSync()) {
      backupRoot.renameSync(runtimeRoot.path);
    }
    rethrow;
  }
}

String? localSourcePath(String source) {
  final uri = Uri.tryParse(source);
  if (uri != null && uri.scheme == 'file') {
    return uri.toFilePath();
  }

  if (uri == null || uri.scheme.isEmpty) {
    return source;
  }

  return null;
}

String readAndVerifyRuntimeStackSourceText({
  required String source,
  required String? signatureSource,
  required String? publicKeyPath,
  required String? publicKeyText,
}) {
  final payload = readTextSource(
    source,
    action: 'download runtime stack source manifest',
  );
  final normalizedPublicKeyPath = publicKeyPath?.trim();
  final normalizedPublicKeyText = publicKeyText?.trim();
  final hasPublicKeyPath =
      normalizedPublicKeyPath != null && normalizedPublicKeyPath.isNotEmpty;
  final hasPublicKeyText =
      normalizedPublicKeyText != null && normalizedPublicKeyText.isNotEmpty;
  final normalizedSignatureSource = signatureSource?.trim();

  if (!hasPublicKeyPath && !hasPublicKeyText) {
    if (normalizedSignatureSource != null &&
        normalizedSignatureSource.isNotEmpty) {
      throw const FileSystemException(
        'Runtime stack source signature was provided without a public key.',
      );
    }
    return payload;
  }

  final effectiveSignatureSource =
      normalizedSignatureSource == null || normalizedSignatureSource.isEmpty
      ? '$source.sig'
      : normalizedSignatureSource;
  final tempDirectory = Directory.systemTemp.createTempSync(
    'konyak-runtime-stack-verify-',
  );
  try {
    final payloadPath = joinPath(tempDirectory.path, const ['manifest.json']);
    File(payloadPath).writeAsStringSync(payload);

    final signaturePath = joinPath(tempDirectory.path, const ['manifest.sig']);
    writeSourceBytes(
      source: effectiveSignatureSource,
      targetPath: signaturePath,
      action: 'download runtime stack source signature',
    );

    final resolvedPublicKeyPath = hasPublicKeyPath
        ? normalizedPublicKeyPath
        : joinPath(tempDirectory.path, const ['runtime-stack-public-key.pem']);
    if (!hasPublicKeyPath) {
      File(
        resolvedPublicKeyPath,
      ).writeAsStringSync('$normalizedPublicKeyText\n');
    }

    final result = Process.runSync('openssl', [
      'dgst',
      '-sha256',
      '-verify',
      resolvedPublicKeyPath,
      '-signature',
      signaturePath,
      payloadPath,
    ], runInShell: false);
    if (result.exitCode != 0) {
      throw ProcessException(
        'openssl',
        const <String>[],
        'Runtime stack source manifest signature verification failed: '
            '${commandFailureMessage("verify runtime stack source manifest signature", result)}',
        result.exitCode,
      );
    }

    return payload;
  } finally {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  }
}

String readTextSource(String source, {required String action}) {
  final localPath = localSourcePath(source);
  if (localPath != null) {
    return File(localPath).readAsStringSync();
  }

  final result = Process.runSync('curl', [
    '--fail',
    '--location',
    '--silent',
    source,
  ], runInShell: false);
  if (result.exitCode != 0) {
    throw ProcessException(
      'curl',
      const <String>[],
      '${commandFailureMessage(action, result)} Source: $source',
      result.exitCode,
    );
  }

  return processOutputToString(result.stdout);
}

void writeSourceBytes({
  required String source,
  required String targetPath,
  required String action,
}) {
  final localPath = localSourcePath(source);
  if (localPath != null) {
    File(targetPath).parent.createSync(recursive: true);
    File(localPath).copySync(targetPath);
    return;
  }

  final result = Process.runSync('curl', [
    '--fail',
    '--location',
    '--silent',
    '--output',
    targetPath,
    source,
  ], runInShell: false);
  if (result.exitCode != 0) {
    throw ProcessException(
      'curl',
      const <String>[],
      '${commandFailureMessage(action, result)} Source: $source',
      result.exitCode,
    );
  }
}

final class DigestSink implements Sink<Digest> {
  Digest? digest;

  @override
  void add(Digest data) {
    digest = data;
  }

  @override
  void close() {}
}
