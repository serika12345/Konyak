part of '../../konyak_cli.dart';

String _runtimeSiblingPathForInstall(Directory runtimeRoot, String suffix) {
  return '${runtimeRoot.path}.$suffix-${DateTime.now().microsecondsSinceEpoch}';
}

void _replaceRuntimeRootInPlace({
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

String? _localSourcePath(String source) {
  final uri = Uri.tryParse(source);
  if (uri != null && uri.scheme == 'file') {
    return uri.toFilePath();
  }

  if (uri == null || uri.scheme.isEmpty) {
    return source;
  }

  return null;
}

String _readAndVerifyRuntimeStackSourceText({
  required String source,
  required String? signatureSource,
  required String? publicKeyPath,
  required String? publicKeyText,
}) {
  final payload = _readTextSource(
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
    final payloadPath = _joinPath(tempDirectory.path, const ['manifest.json']);
    File(payloadPath).writeAsStringSync(payload);

    final signaturePath = _joinPath(tempDirectory.path, const ['manifest.sig']);
    _writeSourceBytes(
      source: effectiveSignatureSource,
      targetPath: signaturePath,
      action: 'download runtime stack source signature',
    );

    final resolvedPublicKeyPath = hasPublicKeyPath
        ? normalizedPublicKeyPath
        : _joinPath(tempDirectory.path, const ['runtime-stack-public-key.pem']);
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
            '${_commandFailureMessage("verify runtime stack source manifest signature", result)}',
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

String _readTextSource(String source, {required String action}) {
  final localPath = _localSourcePath(source);
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
      _commandFailureMessage(action, result),
      result.exitCode,
    );
  }

  return _processOutputToString(result.stdout);
}

void _writeSourceBytes({
  required String source,
  required String targetPath,
  required String action,
}) {
  final localPath = _localSourcePath(source);
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
      _commandFailureMessage(action, result),
      result.exitCode,
    );
  }
}

final class _DigestSink implements Sink<Digest> {
  Digest? digest;

  @override
  void add(Digest data) {
    digest = data;
  }

  @override
  void close() {}
}
