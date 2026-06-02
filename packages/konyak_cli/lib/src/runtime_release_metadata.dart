part of '../konyak_cli.dart';

RuntimeReleaseMetadata? _runtimeReleaseMetadataFromDecoded({
  required Object? release,
  required Object? releaseMetadata,
}) {
  final version = _runtimeReleaseVersion(release);
  if (version == null) {
    return null;
  }

  final archiveUrl = _runtimeReleaseArchiveUrl(release);
  final releaseMetadataAssetUrl = _runtimeReleaseMetadataAssetUrl(release);
  return RuntimeReleaseMetadata(
    version: version,
    archiveUrl: Option.fromNullable(archiveUrl),
    archiveSha256: Option.fromNullable(
      _runtimeReleaseArchiveSha256(release, archiveUrl),
    ),
    sourceManifestUrl: Option.fromNullable(
      _runtimeReleaseSourceManifestUrl(
        release: release,
        releaseMetadataAssetUrl: releaseMetadataAssetUrl,
        releaseMetadata: releaseMetadata,
      ),
    ),
    sourceManifestSignatureUrl: Option.fromNullable(
      _runtimeReleaseSourceManifestSignatureUrl(
        release: release,
        releaseMetadataAssetUrl: releaseMetadataAssetUrl,
        releaseMetadata: releaseMetadata,
      ),
    ),
  );
}

Map<String, dynamic>? _runtimeReleaseMetadataAssetFromPayload(String payload) {
  final decoded = jsonDecode(payload);
  if (decoded is Map<String, dynamic>) {
    return decoded;
  }

  return null;
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
