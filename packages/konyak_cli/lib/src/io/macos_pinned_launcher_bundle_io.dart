import 'dart:io';

import '../domain/program/program_mutation_models.dart';
import '../shared/common_helpers.dart';
import 'macos_pinned_launcher_icons.dart';
import 'macos_pinned_launchers.dart';

class MacosPinnedProgramLauncherBundlePlan {
  const MacosPinnedProgramLauncherBundlePlan({
    required this.infoPlistPath,
    required this.manifestPath,
    required this.executablePath,
    required this.infoPlist,
    required this.manifestJson,
    required this.launcherScript,
  });

  final String infoPlistPath;
  final String manifestPath;
  final String executablePath;
  final String infoPlist;
  final String manifestJson;
  final String launcherScript;
}

void writeMacosPinnedProgramLauncher({
  required String bundlePath,
  required MacosPinnedProgramLauncherCommand launcherCommand,
  required String displayName,
  required String? iconPath,
  required PinnedProgramLauncherManifest manifest,
}) {
  final contentsPath = joinPath(bundlePath, const ['Contents']);
  final macosPath = joinPath(contentsPath, const ['MacOS']);
  final resourcesPath = joinPath(contentsPath, const ['Resources']);

  Directory(macosPath).createSync(recursive: true);
  Directory(resourcesPath).createSync(recursive: true);
  final iconFileName = writeMacosPinnedProgramLauncherIcon(
    resourcesPath: resourcesPath,
    iconPath: iconPath,
  );
  final plan = macosPinnedProgramLauncherBundlePlan(
    bundlePath: bundlePath,
    launcherCommand: launcherCommand,
    displayName: displayName,
    iconFileName: iconFileName,
    manifest: manifest,
  );

  File(plan.infoPlistPath).writeAsStringSync(plan.infoPlist);
  File(plan.manifestPath).writeAsStringSync(plan.manifestJson);
  File(plan.executablePath).writeAsStringSync(plan.launcherScript);
  final executableChmodResult = Process.runSync('chmod', <String>[
    '755',
    plan.executablePath,
  ], runInShell: false);
  if (executableChmodResult.exitCode != 0) {
    throw FileSystemException(
      'Unable to mark launcher executable.',
      plan.executablePath,
    );
  }
}
