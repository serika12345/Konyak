part of '../home_loader/home_loader.dart';

const _macosMenuChannel = MethodChannel('konyak/menu');

List<String> _validExecutableOpenPathsFromChannel(Object? arguments) {
  if (arguments is! List<Object?>) {
    return const <String>[];
  }

  return _validExecutableOpenPaths(arguments.whereType<String>());
}

List<String> _validExecutableOpenPaths(Iterable<String> paths) {
  final validPaths = <String>[];
  for (final path in paths) {
    final trimmedPath = path.trim();
    if (_isWindowsExecutablePath(trimmedPath)) {
      validPaths.add(trimmedPath);
    }
  }

  return validPaths;
}

bool _isWindowsExecutablePath(String path) {
  return path.isNotEmpty && path.toLowerCase().endsWith('.exe');
}

String _installGptkFailureMessage(
  ProcessRunResult result, {
  required String command,
}) {
  final message = _jsonErrorMessage(result.stdout);
  if (message != null) {
    return message;
  }
  final diagnostic = result.stderr.trim();
  if (diagnostic.isEmpty) {
    return '$command failed with exit code ${result.exitCode}.';
  }
  return '$command failed with exit code ${result.exitCode}: $diagnostic';
}

String _openUrlFailureMessage(ProcessRunResult result) {
  final message = _jsonErrorMessage(result.stdout);
  if (message != null) {
    return message;
  }
  final diagnostic = result.stderr.trim();
  if (diagnostic.isEmpty) {
    return 'open-url failed with exit code ${result.exitCode}.';
  }
  return 'open-url failed with exit code ${result.exitCode}: $diagnostic';
}

String? _jsonErrorMessage(String payload) {
  try {
    final decoded = jsonDecode(payload);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    final error = decoded['error'];
    if (error is! Map<String, dynamic>) {
      return null;
    }
    final message = error['message'];
    return message is String && message.isNotEmpty ? message : null;
  } on FormatException {
    return null;
  }
}
