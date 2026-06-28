import 'dart:io';

import '../shared/common_helpers.dart';
import 'macos_pinned_launcher_manifest_io.dart';
import 'macos_pinned_launchers.dart';

void deleteStaleMacosPinnedProgramLaunchers({
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

    final manifest = readPinnedProgramLauncherManifest(
      joinPath(entity.path, const [
        'Contents',
        'Resources',
        macosPinnedLauncherManifestFileName,
      ]),
    );
    final shouldKeep = manifest.match(() => true, (value) {
      final launcherId = value.launcherId.value;
      return desiredLauncherIds.contains(launcherId) &&
          desiredLauncherPaths[launcherId] ==
              normalizeFilesystemPath(entity.path);
    });
    if (shouldKeep) {
      continue;
    }

    entity.deleteSync(recursive: true);
  }
}

Set<String> unmanagedMacosLauncherBundleNames(String launcherHome) {
  final launcherDirectory = Directory(launcherHome);
  if (!launcherDirectory.existsSync()) {
    return <String>{};
  }

  final bundleNames = <String>{};
  for (final entity in launcherDirectory.listSync(followLinks: false)) {
    if (entity is! Directory || !entity.path.endsWith('.app')) {
      continue;
    }

    final manifest = readPinnedProgramLauncherManifest(
      joinPath(entity.path, const [
        'Contents',
        'Resources',
        macosPinnedLauncherManifestFileName,
      ]),
    );
    if (manifest.isNone()) {
      bundleNames.add(baseName(entity.path).toLowerCase());
    }
  }

  return bundleNames;
}
