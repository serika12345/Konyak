part of '../konyak_cli.dart';

bool _isPathWithinRoot({required String path, required String root}) {
  final normalizedPath = path.replaceAll('\\', '/');
  final normalizedRoot = root
      .replaceAll('\\', '/')
      .replaceAll(RegExp(r'/+$'), '');
  return normalizedPath == normalizedRoot ||
      normalizedPath.startsWith('$normalizedRoot/');
}

Option<String> _parentDirectory(String path) {
  final normalized = path.replaceAll('\\', '/').replaceAll(RegExp(r'/+$'), '');
  final index = normalized.lastIndexOf('/');
  if (index <= 0) {
    return index == 0 ? Option.of('/') : const Option.none();
  }

  return Option.of(normalized.substring(0, index));
}

String _normalizeFilesystemPath(String path) {
  return path.trim().replaceAll(RegExp(r'/+$'), '');
}

String? _nonEmptyEnvironmentValue(Map<String, String> environment, String key) {
  final value = environment[key];
  if (value == null || value.trim().isEmpty) {
    return null;
  }

  return value;
}

Map<String, Object?>? _objectMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value.cast<String, Object?>();
  }

  if (value is Map<String, Object?>) {
    return value;
  }

  return null;
}

String _baseName(String path) {
  final normalized = path.replaceAll(RegExp(r'/+$'), '');
  final index = normalized.lastIndexOf('/');
  if (index == -1) {
    return normalized;
  }

  return normalized.substring(index + 1);
}

String _commandFailureMessage(String action, ProcessResult result) {
  final stderr = _processOutputToString(result.stderr).trim();
  final stdout = _processOutputToString(result.stdout).trim();
  final details = stderr.isNotEmpty ? stderr : stdout;

  if (details.isEmpty) {
    return 'Failed to $action with exit code ${result.exitCode}.';
  }

  return 'Failed to $action with exit code ${result.exitCode}: $details';
}

String _processOutputToString(Object? output) {
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

int? _readUint16(Uint8List bytes, int offset) {
  if (offset < 0 || offset + 2 > bytes.length) {
    return null;
  }

  return bytes[offset] | bytes[offset + 1] << 8;
}

int? _readUint32(Uint8List bytes, int offset) {
  if (offset < 0 || offset + 4 > bytes.length) {
    return null;
  }

  return bytes[offset] |
      bytes[offset + 1] << 8 |
      bytes[offset + 2] << 16 |
      bytes[offset + 3] << 24;
}

void _writeUint16(Uint8List bytes, int offset, int value) {
  bytes[offset] = value & 0xff;
  bytes[offset + 1] = value >> 8 & 0xff;
}

void _writeUint32(Uint8List bytes, int offset, int value) {
  bytes[offset] = value & 0xff;
  bytes[offset + 1] = value >> 8 & 0xff;
  bytes[offset + 2] = value >> 16 & 0xff;
  bytes[offset + 3] = value >> 24 & 0xff;
}

String? _nullTerminatedAsciiString(
  Uint8List bytes,
  int offset,
  int maximumOffset,
) {
  if (offset < 0 || offset >= bytes.length || offset >= maximumOffset) {
    return null;
  }

  final endOffset = _nullByteOffset(bytes, offset, maximumOffset);
  if (endOffset == null) {
    return null;
  }

  return ascii.decode(
    Uint8List.sublistView(bytes, offset, endOffset),
    allowInvalid: true,
  );
}

String? _nullTerminatedUtf16LeString(
  Uint8List bytes,
  int offset,
  int maximumOffset,
) {
  if (offset < 0 || offset + 1 >= bytes.length || offset >= maximumOffset) {
    return null;
  }

  final codeUnits = <int>[];
  for (var cursor = offset; cursor + 1 < maximumOffset; cursor += 2) {
    final codeUnit = _readUint16(bytes, cursor);
    if (codeUnit == null || codeUnit == 0) {
      break;
    }
    codeUnits.add(codeUnit);
  }

  return codeUnits.isEmpty ? null : String.fromCharCodes(codeUnits);
}

int? _nullByteOffset(Uint8List bytes, int offset, int maximumOffset) {
  final boundedMaximum = min(maximumOffset, bytes.length);
  for (var cursor = offset; cursor < boundedMaximum; cursor += 1) {
    if (bytes[cursor] == 0) {
      return cursor;
    }
  }

  return null;
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (identical(left, right)) {
    return true;
  }

  if (left.length != right.length) {
    return false;
  }

  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) {
      return false;
    }
  }

  return true;
}

bool _mapEquals<K, V>(Map<K, V> left, Map<K, V> right) {
  if (identical(left, right)) {
    return true;
  }

  if (left.length != right.length) {
    return false;
  }

  for (final entry in left.entries) {
    if (!right.containsKey(entry.key) || right[entry.key] != entry.value) {
      return false;
    }
  }

  return true;
}

Map<String, String>? _stringMap(Object? value) {
  if (value == null) {
    return const <String, String>{};
  }

  final map = _objectMap(value);
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

String _joinPath(String root, Iterable<String> components) {
  var path = root;
  for (final component in components) {
    final normalized = component.replaceAll(RegExp(r'^/+|/+$'), '');
    path = path.endsWith('/') ? '$path$normalized' : '$path/$normalized';
  }

  return path;
}

Option<String> _fileNameFromUrl(String url) {
  final parsed = Uri.tryParse(url);
  final segments = parsed?.pathSegments;
  final candidate = segments == null || segments.isEmpty
      ? null
      : segments.last.trim();
  if (candidate == null || candidate.isEmpty) {
    return const Option.none();
  }

  return Option.of(candidate.replaceAll(RegExp(r'[^A-Za-z0-9._+-]'), '_'));
}
