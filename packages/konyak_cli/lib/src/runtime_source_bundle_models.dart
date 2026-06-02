part of '../konyak_cli.dart';

class _RuntimeStackSourceArchiveBundle {
  _RuntimeStackSourceArchiveBundle({
    required this.wineArchivePath,
    required List<String> componentArchivePaths,
    required Map<String, String> componentVersions,
  }) : componentArchivePaths = List.unmodifiable(componentArchivePaths),
       componentVersions = Map.unmodifiable(componentVersions);

  final String wineArchivePath;
  final List<String> componentArchivePaths;
  final Map<String, String> componentVersions;
}

sealed class _RuntimeStackSourceArchiveBundleResult {
  const _RuntimeStackSourceArchiveBundleResult();
}

class _RuntimeStackSourceArchiveBundleResolved
    extends _RuntimeStackSourceArchiveBundleResult {
  const _RuntimeStackSourceArchiveBundleResolved(this.bundle);

  final _RuntimeStackSourceArchiveBundle bundle;
}

class _RuntimeStackSourceArchiveBundleFailed
    extends _RuntimeStackSourceArchiveBundleResult {
  const _RuntimeStackSourceArchiveBundleFailed(this.message);

  final String message;
}
