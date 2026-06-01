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
      return RuntimeReleaseMetadataFetched(
        RuntimeReleaseMetadata(
          version: version,
          archiveUrl: archiveUrl,
          archiveSha256: _runtimeReleaseArchiveSha256(decoded, archiveUrl),
          sourceManifestUrl: _runtimeReleaseSourceManifestUrl(decoded),
          sourceManifestSignatureUrl: _runtimeReleaseSourceManifestSignatureUrl(
            decoded,
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
}
