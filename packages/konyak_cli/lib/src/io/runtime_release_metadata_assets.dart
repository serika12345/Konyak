import 'dart:convert';

import 'package:fpdart/fpdart.dart';

import '../domain/runtime/runtime_validation_support.dart';
import '../shared/common_helpers.dart';

Option<String> runtimeReleaseArchiveUrl(
  Object? decoded, {
  bool Function(String url)? archiveUrlPredicate,
}) {
  if (decoded is! Map<String, dynamic>) {
    return const Option.none();
  }

  final assets = decoded['assets'];
  if (assets is! List<dynamic>) {
    return const Option.none();
  }

  final urls = <String>[];
  for (final asset in assets) {
    if (asset is! Map<String, dynamic>) {
      continue;
    }

    final url = asset['browser_download_url'];
    final normalizedUrl = url is String ? url.trim() : null;
    if (normalizedUrl != null &&
        normalizedUrl.isNotEmpty &&
        !isReleaseMetadataAssetUrl(normalizedUrl) &&
        (archiveUrlPredicate == null || archiveUrlPredicate(normalizedUrl))) {
      urls.add(normalizedUrl);
    }
  }

  if (urls.isEmpty) {
    return const Option.none();
  }

  const archiveExtensions = <String>[
    '.tar.xz',
    '.tar.gz',
    '.zip',
    '.dmg',
    '.appimage',
  ];
  for (final url in urls) {
    final archiveUrl = fileNameFromUrl(url)
        .map((fileName) => fileName.toLowerCase())
        .flatMap(
          (fileName) => archiveExtensions.any(fileName.endsWith)
              ? Option.of(url)
              : const Option<String>.none(),
        );
    if (archiveUrl.isSome()) {
      return archiveUrl;
    }
  }

  return const Option.none();
}

Option<String> runtimeReleaseMetadataAssetUrl(Object? decoded) {
  if (decoded is! Map<String, dynamic>) {
    return const Option.none();
  }

  final assets = decoded['assets'];
  if (assets is! List<dynamic>) {
    return const Option.none();
  }

  for (final asset in assets) {
    if (asset is! Map<String, dynamic>) {
      continue;
    }

    final url = asset['browser_download_url'];
    if (url is String &&
        url.trim().isNotEmpty &&
        url.trim().toLowerCase().endsWith('.release.json')) {
      return Option.of(url);
    }
  }

  return const Option.none();
}

Option<String> runtimeReleaseAssetUrlByFileName(
  Object? decoded,
  String fileName,
) {
  if (decoded is! Map<String, dynamic>) {
    return const Option.none();
  }

  final assets = decoded['assets'];
  if (assets is! List<dynamic>) {
    return const Option.none();
  }

  for (final asset in assets) {
    if (asset is! Map<String, dynamic>) {
      continue;
    }

    final url = asset['browser_download_url'];
    if (url is String &&
        url.trim().isNotEmpty &&
        fileNameFromUrl(url).match(() => false, (value) => value == fileName)) {
      return Option.of(url);
    }
  }

  return const Option.none();
}

bool isReleaseMetadataAssetUrl(String url) {
  final normalized = url.trim().toLowerCase();
  return normalized.endsWith('.sha256') ||
      normalized.endsWith('.sha256sum') ||
      normalized.endsWith('.sha256sums') ||
      normalized.endsWith('/sha256sums') ||
      normalized.endsWith('/sha256sum') ||
      normalized.endsWith('.release.json');
}

Option<String> runtimeReleaseArchiveSha256(
  Object? decoded,
  Option<String> archiveUrl,
) {
  if (decoded is! Map<String, dynamic>) {
    return const Option.none();
  }

  for (final key in const <String>['archiveSha256', 'archive_sha256']) {
    final value = decoded[key];
    if (value is String && isSha256Hex(value)) {
      return Option.of(value);
    }
  }

  final body = decoded['body'];
  if (body is! String || body.trim().isEmpty) {
    return const Option.none();
  }

  final archiveFileName = archiveUrl.flatMap(fileNameFromUrl);
  final digestPattern = RegExp(r'\b[0-9a-fA-F]{64}\b');
  for (final line in const LineSplitter().convert(body)) {
    if (archiveFileName.match(
      () => false,
      (fileName) => !line.contains(fileName),
    )) {
      continue;
    }

    final digest = digestPattern.firstMatch(line)?.group(0);
    if (digest != null && isSha256Hex(digest)) {
      return Option.of(digest);
    }
  }

  if (archiveFileName.isNone()) {
    return Option.fromNullable(digestPattern.firstMatch(body)?.group(0));
  }

  return const Option.none();
}
