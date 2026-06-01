part of '../konyak_cli.dart';

void _deleteStaleMacosPinnedProgramLaunchers({
  required String launcherHome,
  required Set<String> desiredLauncherIds,
  required Map<String, String> desiredLauncherPaths,
}) {
  final launcherDirectory = Directory(launcherHome);
  if (!launcherDirectory.existsSync()) {
    return;
  }

  for (final entity in launcherDirectory.listSync(followLinks: false)) {
    if (entity is! Directory || !entity.path.endsWith('.app')) {
      continue;
    }

    final manifest = _readPinnedProgramLauncherManifest(
      _joinPath(entity.path, const [
        'Contents',
        'Resources',
        _macosPinnedLauncherManifestFileName,
      ]),
    );
    final desiredPath = manifest == null
        ? null
        : desiredLauncherPaths[manifest.launcherId];
    if (manifest == null ||
        (desiredLauncherIds.contains(manifest.launcherId) &&
            desiredPath == _normalizeFilesystemPath(entity.path))) {
      continue;
    }

    entity.deleteSync(recursive: true);
  }
}

Set<String> _unmanagedMacosLauncherBundleNames(String launcherHome) {
  final launcherDirectory = Directory(launcherHome);
  if (!launcherDirectory.existsSync()) {
    return <String>{};
  }

  final bundleNames = <String>{};
  for (final entity in launcherDirectory.listSync(followLinks: false)) {
    if (entity is! Directory || !entity.path.endsWith('.app')) {
      continue;
    }

    final manifest = _readPinnedProgramLauncherManifest(
      _joinPath(entity.path, const [
        'Contents',
        'Resources',
        _macosPinnedLauncherManifestFileName,
      ]),
    );
    if (manifest == null) {
      bundleNames.add(_baseName(entity.path).toLowerCase());
    }
  }

  return bundleNames;
}
