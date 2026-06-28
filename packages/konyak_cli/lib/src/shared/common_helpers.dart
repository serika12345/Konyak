import 'package:fpdart/fpdart.dart';

bool isPathWithinRoot({required String path, required String root}) {
  final normalizedPath = path.replaceAll('\\', '/');
  final normalizedRoot = root
      .replaceAll('\\', '/')
      .replaceAll(RegExp(r'/+$'), '');
  return normalizedPath == normalizedRoot ||
      normalizedPath.startsWith('$normalizedRoot/');
}

Option<String> parentDirectory(String path) {
  final normalized = path.replaceAll('\\', '/').replaceAll(RegExp(r'/+$'), '');
  final index = normalized.lastIndexOf('/');
  if (index <= 0) {
    return index == 0 ? Option.of('/') : const Option.none();
  }

  return Option.of(normalized.substring(0, index));
}

String normalizeFilesystemPath(String path) {
  return path.trim().replaceAll(RegExp(r'/+$'), '');
}

String baseName(String path) {
  final normalized = path.replaceAll(RegExp(r'/+$'), '');
  final index = normalized.lastIndexOf('/');
  if (index == -1) {
    return normalized;
  }

  return normalized.substring(index + 1);
}

String joinPath(String root, Iterable<String> components) {
  var path = root;
  for (final component in components) {
    final normalized = component.replaceAll(RegExp(r'^/+|/+$'), '');
    path = path.endsWith('/') ? '$path$normalized' : '$path/$normalized';
  }

  return path;
}

Option<String> fileNameFromUrl(String url) {
  try {
    final segments = Uri.parse(url).pathSegments;
    if (segments.isEmpty) {
      return const Option.none();
    }

    final candidate = segments.last.trim();
    if (candidate.isEmpty) {
      return const Option.none();
    }

    return Option.of(candidate.replaceAll(RegExp(r'[^A-Za-z0-9._+-]'), '_'));
  } on FormatException {
    return const Option.none();
  }
}
