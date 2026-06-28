import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

Map<String, Object?>? objectMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value.cast<String, Object?>();
  }

  if (value is Map<String, Object?>) {
    return value;
  }

  return null;
}

String commandFailureMessage(String action, ProcessResult result) {
  final stderr = processOutputToString(result.stderr).trim();
  final stdout = processOutputToString(result.stdout).trim();
  final details = stderr.isNotEmpty ? stderr : stdout;

  if (details.isEmpty) {
    return 'Failed to $action with exit code ${result.exitCode}.';
  }

  return 'Failed to $action with exit code ${result.exitCode}: $details';
}

String processOutputToString(Object? output) {
  if (output == null) {
    return '';
  }

  if (output is String) {
    return output;
  }

  if (output is List<int>) {
    return utf8.decode(output, allowMalformed: true);
  }

  return output.toString();
}

int? readUint16(Uint8List bytes, int offset) {
  if (offset < 0 || offset + 2 > bytes.length) {
    return null;
  }

  return bytes[offset] | bytes[offset + 1] << 8;
}

int? readUint32(Uint8List bytes, int offset) {
  if (offset < 0 || offset + 4 > bytes.length) {
    return null;
  }

  return bytes[offset] |
      bytes[offset + 1] << 8 |
      bytes[offset + 2] << 16 |
      bytes[offset + 3] << 24;
}

Option<T> nullableOption<T extends Object>(T? value) {
  if (value == null) {
    return const Option.none();
  }

  return Option.of(value);
}

Option<int> readUint16Option(Uint8List bytes, int offset) {
  return nullableOption(readUint16(bytes, offset));
}

Option<int> readUint32Option(Uint8List bytes, int offset) {
  return nullableOption(readUint32(bytes, offset));
}

String? nullTerminatedAsciiString(
  Uint8List bytes,
  int offset,
  int maximumOffset,
) {
  if (offset < 0 || offset >= bytes.length || offset >= maximumOffset) {
    return null;
  }

  final endOffset = nullByteOffset(bytes, offset, maximumOffset);
  if (endOffset == null) {
    return null;
  }

  return ascii.decode(
    Uint8List.sublistView(bytes, offset, endOffset),
    allowInvalid: true,
  );
}

String? nullTerminatedUtf16LeString(
  Uint8List bytes,
  int offset,
  int maximumOffset,
) {
  if (offset < 0 || offset + 1 >= bytes.length || offset >= maximumOffset) {
    return null;
  }

  final codeUnits = <int>[];
  for (var cursor = offset; cursor + 1 < maximumOffset; cursor += 2) {
    final codeUnit = readUint16(bytes, cursor);
    if (codeUnit == null || codeUnit == 0) {
      break;
    }
    codeUnits.add(codeUnit);
  }

  return codeUnits.isEmpty ? null : String.fromCharCodes(codeUnits);
}

Option<String> nullTerminatedAsciiStringOption(
  Uint8List bytes,
  int offset,
  int maximumOffset,
) {
  return nullableOption(
    nullTerminatedAsciiString(bytes, offset, maximumOffset),
  );
}

Option<String> nullTerminatedUtf16LeStringOption(
  Uint8List bytes,
  int offset,
  int maximumOffset,
) {
  return nullableOption(
    nullTerminatedUtf16LeString(bytes, offset, maximumOffset),
  );
}

int? nullByteOffset(Uint8List bytes, int offset, int maximumOffset) {
  final boundedMaximum = min(maximumOffset, bytes.length);
  for (var cursor = offset; cursor < boundedMaximum; cursor += 1) {
    if (bytes[cursor] == 0) {
      return cursor;
    }
  }

  return null;
}

Map<String, String>? stringMap(Object? value) {
  if (value == null) {
    return const <String, String>{};
  }

  final map = objectMap(value);
  if (map == null) {
    return null;
  }

  final result = <String, String>{};
  for (final entry in map.entries) {
    if (entry.key.trim().isEmpty ||
        entry.key.contains('=') ||
        entry.value is! String) {
      return null;
    }
    result[entry.key] = entry.value as String;
  }

  return Map.unmodifiable(result);
}
