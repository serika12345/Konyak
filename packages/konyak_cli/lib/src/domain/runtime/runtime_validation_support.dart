part of '../../../konyak_cli.dart';

RuntimeValidationCheck _runtimePathCheck({
  required String id,
  required String name,
  required String path,
  required FileStatusProbe fileStatusProbe,
}) {
  final exists = fileStatusProbe.exists(path);
  return RuntimeValidationCheck(
    id: id,
    name: name,
    isRequired: true,
    isPassed: exists,
    message: exists ? 'Found $path.' : 'Missing $path.',
  );
}

RuntimeValidationCheck _runtimeAnyPathCheck({
  required String id,
  required String name,
  required List<String> paths,
  required FileStatusProbe fileStatusProbe,
}) {
  final existingPath = paths
      .where((path) => fileStatusProbe.exists(path))
      .cast<String?>()
      .firstWhere((path) => path != null, orElse: () => null);

  return RuntimeValidationCheck(
    id: id,
    name: name,
    isRequired: true,
    isPassed: existingPath != null,
    message: existingPath != null
        ? 'Found $existingPath.'
        : 'Missing one of: ${paths.join(', ')}.',
  );
}

List<String> _macosWineLoaderLibraryPaths(String runtimeRoot) {
  return <String>[
    _joinPath(runtimeRoot, const ['lib']),
    _joinPath(runtimeRoot, const ['lib64']),
  ];
}

String _runtimeLoaderFailureMessage(RuntimeExecutableProbeResult result) {
  final stderr = result.stderr.trim();
  if (stderr.isNotEmpty) {
    return stderr;
  }

  final stdout = result.stdout.trim();
  if (stdout.isNotEmpty) {
    return stdout;
  }

  return 'wine64 --version exited with code ${result.exitCode}.';
}

bool _isSha256Hex(String value) {
  return RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(value);
}

String _sha256HexDigest(File file) {
  final outputSink = _DigestSink();
  final inputSink = sha256.startChunkedConversion(outputSink);
  final inputFile = file.openSync();

  try {
    final buffer = Uint8List(64 * 1024);
    while (true) {
      final length = inputFile.readIntoSync(buffer);
      if (length == 0) {
        break;
      }
      inputSink.add(Uint8List.sublistView(buffer, 0, length));
    }
    inputSink.close();
  } finally {
    inputFile.closeSync();
  }

  final digest = outputSink.digest;
  if (digest == null) {
    throw const FormatException('SHA-256 digest was not produced.');
  }

  return digest.toString();
}
