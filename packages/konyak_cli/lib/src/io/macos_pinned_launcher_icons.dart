import 'dart:io';

import '../shared/common_helpers.dart';

const macosPinnedLauncherIconFileName = 'KonyakPinnedProgram.icns';

String? writeMacosPinnedProgramLauncherIcon({
  required String resourcesPath,
  required String? iconPath,
}) {
  final sourcePath = iconPath?.trim();
  if (sourcePath == null || sourcePath.isEmpty) {
    return null;
  }

  final source = File(sourcePath);
  if (!source.existsSync()) {
    return null;
  }

  if (sourcePath.toLowerCase().endsWith('.icns')) {
    source.copySync(
      joinPath(resourcesPath, const [macosPinnedLauncherIconFileName]),
    );
    return macosPinnedLauncherIconFileName;
  }

  final convertedIcon = convertMacosLauncherIconToIcns(
    sourcePath: sourcePath,
    resourcesPath: resourcesPath,
  );
  if (convertedIcon != null) {
    return convertedIcon;
  }

  final fallbackFileName = macosPinnedLauncherFallbackIconFileName(sourcePath);
  source.copySync(joinPath(resourcesPath, [fallbackFileName]));
  return fallbackFileName;
}

String? convertMacosLauncherIconToIcns({
  required String sourcePath,
  required String resourcesPath,
}) {
  final workDirectory = Directory(
    joinPath(resourcesPath, const ['KonyakPinnedProgramIconWork']),
  );
  final iconset = Directory(
    joinPath(workDirectory.path, const ['KonyakPinnedProgram.iconset']),
  );
  final sourcePngPath = joinPath(workDirectory.path, const ['source.png']);
  final icnsPath = joinPath(resourcesPath, const [
    macosPinnedLauncherIconFileName,
  ]);

  try {
    if (workDirectory.existsSync()) {
      workDirectory.deleteSync(recursive: true);
    }
    iconset.createSync(recursive: true);

    final convertResult = Process.runSync('sips', <String>[
      '-s',
      'format',
      'png',
      sourcePath,
      '--out',
      sourcePngPath,
    ], runInShell: false);
    if (convertResult.exitCode != 0 || !File(sourcePngPath).existsSync()) {
      return null;
    }

    for (final size in const <int>[16, 32, 128, 256, 512]) {
      final resized = joinPath(iconset.path, ['icon_${size}x$size.png']);
      final resized2x = joinPath(iconset.path, ['icon_${size}x$size@2x.png']);
      final resizeResult = Process.runSync('sips', <String>[
        '-z',
        '$size',
        '$size',
        sourcePngPath,
        '--out',
        resized,
      ], runInShell: false);
      final resize2xResult = Process.runSync('sips', <String>[
        '-z',
        '${size * 2}',
        '${size * 2}',
        sourcePngPath,
        '--out',
        resized2x,
      ], runInShell: false);
      if (resizeResult.exitCode != 0 || resize2xResult.exitCode != 0) {
        return null;
      }
    }

    final iconutilResult = Process.runSync('iconutil', <String>[
      '-c',
      'icns',
      iconset.path,
      '-o',
      icnsPath,
    ], runInShell: false);
    if (iconutilResult.exitCode != 0 || !File(icnsPath).existsSync()) {
      return null;
    }

    return macosPinnedLauncherIconFileName;
  } on FileSystemException {
    return null;
  } on ProcessException {
    return null;
  } finally {
    if (workDirectory.existsSync()) {
      workDirectory.deleteSync(recursive: true);
    }
  }
}

String macosPinnedLauncherFallbackIconFileName(String sourcePath) {
  final sourceBaseName = baseName(sourcePath);
  final extensionStart = sourceBaseName.lastIndexOf('.');
  final extension = extensionStart == -1
      ? ''
      : sourceBaseName.substring(extensionStart).toLowerCase();
  if (extension.isEmpty || !RegExp(r'^\.[a-z0-9]+$').hasMatch(extension)) {
    return 'KonyakPinnedProgramIcon';
  }

  return 'KonyakPinnedProgram$extension';
}
