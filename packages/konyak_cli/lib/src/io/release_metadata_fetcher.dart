part of '../../konyak_cli.dart';

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
      final releaseMetadataAssetUrl = _runtimeReleaseMetadataAssetUrl(decoded);
      final releaseMetadata = releaseMetadataAssetUrl.match(
        () => null,
        _fetchRuntimeReleaseMetadataAsset,
      );
      final releaseMetadataRecord = _runtimeReleaseMetadataFromDecoded(
        release: decoded,
        releaseMetadata: releaseMetadata,
      );
      return releaseMetadataRecord.match(
        () => const RuntimeReleaseMetadataFetchFailed(
          'Runtime release metadata does not contain a version.',
        ),
        RuntimeReleaseMetadataFetched.new,
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

      return _runtimeReleaseMetadataAssetFromPayload(
        _processOutputToString(result.stdout),
      ).toNullable();
    } on FormatException {
      return null;
    } on ProcessException {
      return null;
    }
  }
}
