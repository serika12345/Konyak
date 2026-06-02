part of '../../konyak_cli.dart';

Option<RuntimeReleaseMetadata> _runtimeReleaseMetadataFromDecoded({
  required Object? release,
  required Object? releaseMetadata,
}) {
  final version = _runtimeReleaseVersion(release);
  final archiveUrl = _runtimeReleaseArchiveUrl(release);
  final releaseMetadataAssetUrl = _runtimeReleaseMetadataAssetUrl(release);
  return version.map(
    (value) => RuntimeReleaseMetadata(
      version: value,
      archiveUrl: archiveUrl,
      archiveSha256: _runtimeReleaseArchiveSha256(release, archiveUrl),
      sourceManifestUrl: _runtimeReleaseSourceManifestUrl(
        release: release,
        releaseMetadataAssetUrl: releaseMetadataAssetUrl,
        releaseMetadata: releaseMetadata,
      ),
      sourceManifestSignatureUrl: _runtimeReleaseSourceManifestSignatureUrl(
        release: release,
        releaseMetadataAssetUrl: releaseMetadataAssetUrl,
        releaseMetadata: releaseMetadata,
      ),
    ),
  );
}

Option<Map<String, dynamic>> _runtimeReleaseMetadataAssetFromPayload(
  String payload,
) {
  final decoded = jsonDecode(payload);
  if (decoded is Map<String, dynamic>) {
    return Option.of(decoded);
  }

  return const Option.none();
}

Option<String> _runtimeReleaseVersion(Object? decoded) {
  if (decoded is! Map<String, dynamic>) {
    return const Option.none();
  }

  final tagName = decoded['tag_name'];
  if (tagName is String && tagName.trim().isNotEmpty) {
    return Option.of(tagName);
  }

  final name = decoded['name'];
  if (name is String && name.trim().isNotEmpty) {
    return Option.of(name);
  }

  return const Option.none();
}
