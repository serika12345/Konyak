part of '../konyak_cli.dart';

RuntimeRecord? _runtimeById(List<RuntimeRecord> runtimes, String runtimeId) {
  for (final runtime in runtimes) {
    if (runtime.id == runtimeId) {
      return runtime;
    }
  }

  return null;
}

String? _runtimeWineVersion(RuntimeRecord runtime) {
  final stack = runtime.stack;
  if (stack == null) {
    return null;
  }

  for (final component in stack.components) {
    if (component.id == 'wine') {
      return component.version;
    }
  }

  return null;
}

String _updateStatus({
  required String? currentVersion,
  required String latestVersion,
}) {
  if (currentVersion == null || currentVersion.trim().isEmpty) {
    return 'unknown';
  }

  if (_normalizeRuntimeVersion(currentVersion) ==
      _normalizeRuntimeVersion(latestVersion)) {
    return 'current';
  }

  return 'available';
}

String _normalizeRuntimeVersion(String version) {
  return version
      .trim()
      .toLowerCase()
      .replaceFirst(RegExp(r'^wine-devel-'), '')
      .replaceFirst(RegExp(r'^v'), '');
}

String? _runtimeReleaseVersion(Object? decoded) {
  if (decoded is! Map<String, dynamic>) {
    return null;
  }

  final tagName = decoded['tag_name'];
  if (tagName is String && tagName.trim().isNotEmpty) {
    return tagName;
  }

  final name = decoded['name'];
  if (name is String && name.trim().isNotEmpty) {
    return name;
  }

  return null;
}

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

String? _runtimeReleaseSourceManifestUrl({
  required Object? release,
  required String? releaseMetadataAssetUrl,
  required Object? releaseMetadata,
}) {
  if (release is! Map<String, dynamic> || releaseMetadataAssetUrl == null) {
    return null;
  }

  if (releaseMetadata == null) {
    return null;
  }

  final fileName = _runtimeReleaseSourceManifestFileName(releaseMetadata);
  if (fileName == null) {
    return null;
  }

  final assetUrl = _runtimeReleaseAssetUrlByFileName(release, fileName);
  if (assetUrl != null) {
    return assetUrl;
  }

  return _resolveReleaseMetadataAssetUrl(releaseMetadataAssetUrl, fileName);
}

String? _runtimeReleaseSourceManifestSignatureUrl({
  required Object? release,
  required String? releaseMetadataAssetUrl,
  required Object? releaseMetadata,
}) {
  if (release is! Map<String, dynamic> || releaseMetadataAssetUrl == null) {
    return null;
  }

  if (releaseMetadata == null) {
    return null;
  }

  final fileName = _runtimeReleaseSourceManifestSignatureFileName(
    releaseMetadata,
  );
  if (fileName == null) {
    return null;
  }

  final assetUrl = _runtimeReleaseAssetUrlByFileName(release, fileName);
  if (assetUrl != null) {
    return assetUrl;
  }

  return _resolveReleaseMetadataAssetUrl(releaseMetadataAssetUrl, fileName);
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

String? _runtimeReleaseSourceManifestFileName(Object? decoded) {
  if (decoded is! Map<String, dynamic>) {
    return null;
  }

  final runtimeStack = decoded['runtimeStack'];
  if (runtimeStack is! Map<String, dynamic>) {
    return null;
  }

  final fileName = runtimeStack['sourceManifestFileName'];
  if (fileName is String && fileName.trim().isNotEmpty) {
    return fileName;
  }

  return null;
}

String? _runtimeReleaseSourceManifestSignatureFileName(Object? decoded) {
  if (decoded is! Map<String, dynamic>) {
    return null;
  }

  final runtimeStack = decoded['runtimeStack'];
  if (runtimeStack is! Map<String, dynamic>) {
    return null;
  }

  final fileName = runtimeStack['signatureFileName'];
  if (fileName is String && fileName.trim().isNotEmpty) {
    return fileName;
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
        _fileNameFromUrl(url) == fileName) {
      return url;
    }
  }

  return null;
}

String? _resolveReleaseMetadataAssetUrl(String metadataUrl, String fileName) {
  final metadataUri = Uri.tryParse(metadataUrl);
  if (metadataUri == null) {
    return null;
  }

  final segments = List<String>.from(metadataUri.pathSegments);
  if (segments.isEmpty) {
    return null;
  }

  segments[segments.length - 1] = fileName;
  return metadataUri.replace(pathSegments: segments).toString();
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
      ? null
      : _fileNameFromUrl(archiveUrl);
  final digestPattern = RegExp(r'\b[0-9a-fA-F]{64}\b');
  for (final line in const LineSplitter().convert(body)) {
    if (archiveFileName != null && !line.contains(archiveFileName)) {
      continue;
    }

    final digest = digestPattern.firstMatch(line)?.group(0);
    if (digest != null && _isSha256Hex(digest)) {
      return digest;
    }
  }

  if (archiveFileName == null) {
    return digestPattern.firstMatch(body)?.group(0);
  }

  return null;
}
