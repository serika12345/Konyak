import 'dart:convert';

import 'package:fpdart/fpdart.dart';

import '../domain/update/update_records.dart';
import 'runtime_release_metadata_assets.dart';
import 'runtime_release_metadata_source_manifests.dart';

Option<RuntimeReleaseMetadata> runtimeReleaseMetadataFromDecoded({
  required Object? release,
  required Object? releaseMetadata,
  bool Function(String url)? archiveUrlPredicate,
}) {
  final version = runtimeReleaseVersion(release);
  final archiveUrl = runtimeReleaseArchiveUrl(
    release,
    archiveUrlPredicate: archiveUrlPredicate,
  );
  final releaseMetadataAssetUrl = runtimeReleaseMetadataAssetUrl(release);
  return version.map(
    (value) => RuntimeReleaseMetadata(
      version: value,
      archiveUrl: archiveUrl,
      archiveSha256: runtimeReleaseArchiveSha256(release, archiveUrl),
      sourceManifestUrl: runtimeReleaseSourceManifestUrl(
        release: release,
        releaseMetadataAssetUrl: releaseMetadataAssetUrl,
        releaseMetadata: releaseMetadata,
      ),
      sourceManifestSignatureUrl: runtimeReleaseSourceManifestSignatureUrl(
        release: release,
        releaseMetadataAssetUrl: releaseMetadataAssetUrl,
        releaseMetadata: releaseMetadata,
      ),
    ),
  );
}

Option<Map<String, dynamic>> runtimeReleaseMetadataAssetFromPayload(
  String payload,
) {
  final decoded = jsonDecode(payload);
  if (decoded is Map<String, dynamic>) {
    return Option.of(decoded);
  }

  return const Option.none();
}

Option<String> runtimeReleaseVersion(Object? decoded) {
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
