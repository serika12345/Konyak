part of '../../../konyak_cli.dart';

class _RuntimeStackSourceArchiveBundle {
  _RuntimeStackSourceArchiveBundle({
    required String wineArchivePath,
    required Iterable<String> componentArchivePaths,
    required this.componentVersions,
  }) : wineArchivePath = RuntimeArchivePath(wineArchivePath),
       componentArchivePaths = componentArchivePaths
           .map(RuntimeArchivePath.new)
           .toIList();

  final RuntimeArchivePath wineArchivePath;
  final IList<RuntimeArchivePath> componentArchivePaths;
  final RuntimeComponentVersions componentVersions;
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
