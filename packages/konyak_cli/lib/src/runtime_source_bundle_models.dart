part of '../konyak_cli.dart';

class _RuntimeStackSourceArchiveBundle {
  const _RuntimeStackSourceArchiveBundle({
    required this.wineArchivePath,
    required this.componentArchivePaths,
    required this.componentVersions,
  });

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
