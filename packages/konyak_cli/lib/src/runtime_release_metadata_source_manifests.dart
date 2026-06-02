part of '../konyak_cli.dart';

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
