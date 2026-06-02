part of '../konyak_cli.dart';

class _RuntimeStackSourceArchiveBundle {
  _RuntimeStackSourceArchiveBundle({
    required this.wineArchivePath,
    required Iterable<String> componentArchivePaths,
    required Map<String, String> componentVersions,
  }) : componentArchivePaths = componentArchivePaths.toIList(),
       componentVersions = componentVersions.lock;

  final String wineArchivePath;
  final IList<String> componentArchivePaths;
  final IMap<String, String> componentVersions;
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
