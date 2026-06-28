import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'platform_runtime_sources.dart';

String sha256HexDigest(File file) {
  final outputSink = DigestSink();
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

  return switch (outputSink.digest) {
    final Digest digest => digest.toString(),
    _ => throw const FormatException('SHA-256 digest was not produced.'),
  };
}
