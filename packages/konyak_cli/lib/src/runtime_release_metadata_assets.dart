part of '../konyak_cli.dart';

String? _runtimeReleaseArchiveUrl(Object? decoded) {
  if (decoded is! Map<String, dynamic>) {
    return null;
  }

  final assets = decoded['assets'];
  if (assets is! List<dynamic>) {
    return null;
  }

  final urls = <String>[];
  for (final asset in assets) {
    if (asset is! Map<String, dynamic>) {
      continue;
    }

    final url = asset['browser_download_url'];
    if (url is String &&
        url.trim().isNotEmpty &&
        !_isReleaseMetadataAssetUrl(url)) {
      urls.add(url);
    }
  }

  if (urls.isEmpty) {
    return null;
  }

  for (final extension in const <String>[
    '.tar.xz',
    '.tar.gz',
    '.zip',
    '.dmg',
    '.appimage',
  ]) {
    for (final url in urls) {
      if (url.toLowerCase().contains(extension)) {
        return url;
      }
    }
  }

  return urls.first;
}

String? _runtimeReleaseMetadataAssetUrl(Object? decoded) {
  if (decoded is! Map<String, dynamic>) {
    return null;
  }

  final assets = decoded['assets'];
  if (assets is! List<dynamic>) {
    return null;
  }

  for (final asset in assets) {
    if (asset is! Map<String, dynamic>) {
      continue;
    }

    final url = asset['browser_download_url'];
    if (url is String &&
        url.trim().isNotEmpty &&
        url.trim().toLowerCase().endsWith('.release.json')) {
      return url;
    }
  }

  return null;
}

String? _runtimeReleaseAssetUrlByFileName(Object? decoded, String fileName) {
  if (decoded is! Map<String, dynamic>) {
    return null;
  }

  final assets = decoded['assets'];
  if (assets is! List<dynamic>) {
    return null;
  }

  for (final asset in assets) {
    if (asset is! Map<String, dynamic>) {
      continue;
    }

    final url = asset['browser_download_url'];
    if (url is String &&
        url.trim().isNotEmpty &&
        _fileNameFromUrl(
          url,
        ).match(() => false, (value) => value == fileName)) {
      return url;
    }
  }

  return null;
}

bool _isReleaseMetadataAssetUrl(String url) {
  final normalized = url.trim().toLowerCase();
  return normalized.endsWith('.sha256') ||
      normalized.endsWith('.sha256sum') ||
      normalized.endsWith('.sha256sums') ||
      normalized.endsWith('/sha256sums') ||
      normalized.endsWith('/sha256sum') ||
      normalized.endsWith('.release.json');
}

String? _runtimeReleaseArchiveSha256(Object? decoded, String? archiveUrl) {
  if (decoded is! Map<String, dynamic>) {
    return null;
  }

  for (final key in const <String>['archiveSha256', 'archive_sha256']) {
    final value = decoded[key];
    if (value is String && _isSha256Hex(value)) {
      return value;
    }
  }

  final body = decoded['body'];
  if (body is! String || body.trim().isEmpty) {
    return null;
  }

  final archiveFileName = archiveUrl == null
      ? const Option<String>.none()
      : _fileNameFromUrl(archiveUrl);
  final digestPattern = RegExp(r'\b[0-9a-fA-F]{64}\b');
  for (final line in const LineSplitter().convert(body)) {
    if (archiveFileName.match(
      () => false,
      (fileName) => !line.contains(fileName),
    )) {
      continue;
    }

    final digest = digestPattern.firstMatch(line)?.group(0);
    if (digest != null && _isSha256Hex(digest)) {
      return digest;
    }
  }

  if (archiveFileName.isNone()) {
    return digestPattern.firstMatch(body)?.group(0);
  }

  return null;
}
