part of '../../konyak_cli.dart';

Option<String> _runtimeReleaseSourceManifestUrl({
  required Object? release,
  required Option<String> releaseMetadataAssetUrl,
  required Object? releaseMetadata,
}) {
  if (release is! Map<String, dynamic> || releaseMetadataAssetUrl.isNone()) {
    return const Option.none();
  }

  if (releaseMetadata == null) {
    return const Option.none();
  }

  return _runtimeReleaseSourceManifestFileName(releaseMetadata).flatMap(
    (fileName) => _runtimeReleaseAssetUrlByFileName(release, fileName).alt(
      () => releaseMetadataAssetUrl.flatMap(
        (metadataUrl) => _resolveReleaseMetadataAssetUrl(metadataUrl, fileName),
      ),
    ),
  );
}

Option<String> _runtimeReleaseSourceManifestSignatureUrl({
  required Object? release,
  required Option<String> releaseMetadataAssetUrl,
  required Object? releaseMetadata,
}) {
  if (release is! Map<String, dynamic> || releaseMetadataAssetUrl.isNone()) {
    return const Option.none();
  }

  if (releaseMetadata == null) {
    return const Option.none();
  }

  return _runtimeReleaseSourceManifestSignatureFileName(
    releaseMetadata,
  ).flatMap(
    (fileName) => _runtimeReleaseAssetUrlByFileName(release, fileName).alt(
      () => releaseMetadataAssetUrl.flatMap(
        (metadataUrl) => _resolveReleaseMetadataAssetUrl(metadataUrl, fileName),
      ),
    ),
  );
}

Option<String> _runtimeReleaseSourceManifestFileName(Object? decoded) {
  if (decoded is! Map<String, dynamic>) {
    return const Option.none();
  }

  final runtimeStack = decoded['runtimeStack'];
  if (runtimeStack is! Map<String, dynamic>) {
    return const Option.none();
  }

  final fileName = runtimeStack['sourceManifestFileName'];
  if (fileName is String && fileName.trim().isNotEmpty) {
    return Option.of(fileName);
  }

  return const Option.none();
}

Option<String> _runtimeReleaseSourceManifestSignatureFileName(Object? decoded) {
  if (decoded is! Map<String, dynamic>) {
    return const Option.none();
  }

  final runtimeStack = decoded['runtimeStack'];
  if (runtimeStack is! Map<String, dynamic>) {
    return const Option.none();
  }

  final fileName = runtimeStack['signatureFileName'];
  if (fileName is String && fileName.trim().isNotEmpty) {
    return Option.of(fileName);
  }

  return const Option.none();
}

Option<String> _resolveReleaseMetadataAssetUrl(
  String metadataUrl,
  String fileName,
) {
  final metadataUri = Uri.tryParse(metadataUrl);
  if (metadataUri == null) {
    return const Option.none();
  }

  final segments = List<String>.from(metadataUri.pathSegments);
  if (segments.isEmpty) {
    return const Option.none();
  }

  segments[segments.length - 1] = fileName;
  return Option.of(metadataUri.replace(pathSegments: segments).toString());
}
