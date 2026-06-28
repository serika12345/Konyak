import 'package:fpdart/fpdart.dart';

String requiredNonBlankDomainString(String value, String fieldName) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError.value(value, fieldName, 'must not be blank');
  }
  return trimmed;
}

String domainJoinPath(String root, Iterable<String> components) {
  return components.fold(root, (path, component) {
    final normalized = component.replaceAll(RegExp(r'^/+|/+$'), '');
    return path.endsWith('/') ? '$path$normalized' : '$path/$normalized';
  });
}

String normalizeFilesystemPath(String path) {
  return path.trim().replaceAll(RegExp(r'/+$'), '');
}

bool isPathWithinRoot({required String path, required String root}) {
  final normalizedPath = path.replaceAll('\\', '/');
  final normalizedRoot = root
      .replaceAll('\\', '/')
      .replaceAll(RegExp(r'/+$'), '');
  return normalizedPath == normalizedRoot ||
      normalizedPath.startsWith('$normalizedRoot/');
}

String prependPath(String path, Option<String> existingPath) {
  return existingPath.match(() => path, (existing) {
    if (existing.trim().isEmpty) {
      return path;
    }

    return '$path:$existing';
  });
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
