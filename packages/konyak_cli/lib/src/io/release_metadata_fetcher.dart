import 'dart:convert';
import 'dart:io';

import '../domain/update/update_records.dart';
import 'external_payload_helpers.dart';
import 'runtime_release_metadata.dart';
import 'runtime_release_metadata_assets.dart';

class DartIoRuntimeReleaseMetadataFetcher
    implements RuntimeReleaseMetadataFetcher {
  const DartIoRuntimeReleaseMetadataFetcher({this.archiveUrlPredicate});

  final bool Function(String url)? archiveUrlPredicate;

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
          commandFailureMessage('check runtime update', result),
        );
      }

      final decoded = jsonDecode(processOutputToString(result.stdout));
      final releaseMetadataAssetUrl = runtimeReleaseMetadataAssetUrl(decoded);
      final releaseMetadataAsset = releaseMetadataAssetUrl.toNullable();
      final releaseMetadata = releaseMetadataAsset == null
          ? null
          : fetchRuntimeReleaseMetadataAsset(releaseMetadataAsset);
      if (releaseMetadataAsset != null && releaseMetadata == null) {
        return RuntimeReleaseMetadataFetchFailed(
          'Runtime release metadata asset could not be fetched or parsed: '
          '$releaseMetadataAsset',
        );
      }
      final releaseMetadataRecord = runtimeReleaseMetadataFromDecoded(
        release: decoded,
        releaseMetadata: releaseMetadata,
        archiveUrlPredicate: archiveUrlPredicate,
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

  Map<String, dynamic>? fetchRuntimeReleaseMetadataAsset(String assetUrl) {
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

      return runtimeReleaseMetadataAssetFromPayload(
        processOutputToString(result.stdout),
      ).toNullable();
    } on FormatException {
      return null;
    } on ProcessException {
      return null;
    }
  }
}
