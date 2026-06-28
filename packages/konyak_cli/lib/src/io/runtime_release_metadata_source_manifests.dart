import 'package:fpdart/fpdart.dart';

import 'runtime_release_metadata_assets.dart';

Option<String> runtimeReleaseSourceManifestUrl({
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

  return runtimeReleaseSourceManifestFileName(releaseMetadata).flatMap(
    (fileName) => runtimeReleaseAssetUrlByFileName(release, fileName).alt(
      () => releaseMetadataAssetUrl.flatMap(
        (metadataUrl) => resolveReleaseMetadataAssetUrl(metadataUrl, fileName),
      ),
    ),
  );
}

Option<String> runtimeReleaseSourceManifestSignatureUrl({
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

  return runtimeReleaseSourceManifestSignatureFileName(releaseMetadata).flatMap(
    (fileName) => runtimeReleaseAssetUrlByFileName(release, fileName).alt(
      () => releaseMetadataAssetUrl.flatMap(
        (metadataUrl) => resolveReleaseMetadataAssetUrl(metadataUrl, fileName),
      ),
    ),
  );
}

Option<String> runtimeReleaseSourceManifestFileName(Object? decoded) {
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

Option<String> runtimeReleaseSourceManifestSignatureFileName(Object? decoded) {
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

Option<String> resolveReleaseMetadataAssetUrl(
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
