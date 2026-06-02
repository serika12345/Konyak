part of '../../konyak_cli.dart';

class _MacosPinnedProgramLauncherBundlePlan {
  const _MacosPinnedProgramLauncherBundlePlan({
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

void _writeMacosPinnedProgramLauncher({
  required String bundlePath,
  required _MacosPinnedProgramLauncherCommand launcherCommand,
  required String displayName,
  required String? iconPath,
  required _PinnedProgramLauncherManifest manifest,
}) {
  final contentsPath = _joinPath(bundlePath, const ['Contents']);
  final macosPath = _joinPath(contentsPath, const ['MacOS']);
  final resourcesPath = _joinPath(contentsPath, const ['Resources']);

  Directory(macosPath).createSync(recursive: true);
  Directory(resourcesPath).createSync(recursive: true);
  final iconFileName = _writeMacosPinnedProgramLauncherIcon(
    resourcesPath: resourcesPath,
    iconPath: iconPath,
  );
  final plan = _macosPinnedProgramLauncherBundlePlan(
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
