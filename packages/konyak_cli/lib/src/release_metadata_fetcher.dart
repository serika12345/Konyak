part of '../konyak_cli.dart';

class DartIoRuntimeReleaseMetadataFetcher
    implements RuntimeReleaseMetadataFetcher {
  const DartIoRuntimeReleaseMetadataFetcher();

  @override
  RuntimeReleaseMetadataFetchResult fetch(String versionUrl) {
    try {
      final result = Process.runSync('curl', [
        '--fail',
        '--location',
        '--silent',
        versionUrl,
      ], runInShell: false);
      if (result.exitCode != 0) {
        return RuntimeReleaseMetadataFetchFailed(
          _commandFailureMessage('check runtime update', result),
        );
      }

      final decoded = jsonDecode(_processOutputToString(result.stdout));
      final version = _runtimeReleaseVersion(decoded);
      if (version == null) {
        return const RuntimeReleaseMetadataFetchFailed(
          'Runtime release metadata does not contain a version.',
        );
      }

      final archiveUrl = _runtimeReleaseArchiveUrl(decoded);
      final releaseMetadataAssetUrl = _runtimeReleaseMetadataAssetUrl(decoded);
      final releaseMetadata = releaseMetadataAssetUrl == null
          ? null
          : _fetchRuntimeReleaseMetadataAsset(releaseMetadataAssetUrl);
      return RuntimeReleaseMetadataFetched(
        RuntimeReleaseMetadata(
          version: version,
          archiveUrl: archiveUrl,
          archiveSha256: _runtimeReleaseArchiveSha256(decoded, archiveUrl),
          sourceManifestUrl: _runtimeReleaseSourceManifestUrl(
            release: decoded,
            releaseMetadataAssetUrl: releaseMetadataAssetUrl,
            releaseMetadata: releaseMetadata,
          ),
          sourceManifestSignatureUrl: _runtimeReleaseSourceManifestSignatureUrl(
            release: decoded,
            releaseMetadataAssetUrl: releaseMetadataAssetUrl,
            releaseMetadata: releaseMetadata,
          ),
        ),
      );
    } on FormatException {
      return const RuntimeReleaseMetadataFetchFailed(
        'Runtime release metadata is not valid JSON.',
      );
    } on ProcessException catch (error) {
      return RuntimeReleaseMetadataFetchFailed(error.message);
    }
  }

  Map<String, dynamic>? _fetchRuntimeReleaseMetadataAsset(String assetUrl) {
    try {
      final result = Process.runSync('curl', [
        '--fail',
        '--location',
        '--silent',
        assetUrl,
      ], runInShell: false);
      if (result.exitCode != 0) {
        return null;
      }

      final decoded = jsonDecode(_processOutputToString(result.stdout));
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } on FormatException {
      return null;
    } on ProcessException {
      return null;
    }

    return null;
  }
}
