part of '../konyak_cli.dart';

const _macosPinnedLauncherIconFileName = 'KonyakPinnedProgram.icns';

String? _writeMacosPinnedProgramLauncherIcon({
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
      _joinPath(resourcesPath, const [_macosPinnedLauncherIconFileName]),
    );
    return _macosPinnedLauncherIconFileName;
  }

  final convertedIcon = _convertMacosLauncherIconToIcns(
    sourcePath: sourcePath,
    resourcesPath: resourcesPath,
  );
  if (convertedIcon != null) {
    return convertedIcon;
  }

  final fallbackFileName = _macosPinnedLauncherFallbackIconFileName(sourcePath);
  source.copySync(_joinPath(resourcesPath, [fallbackFileName]));
  return fallbackFileName;
}

String? _convertMacosLauncherIconToIcns({
  required String sourcePath,
  required String resourcesPath,
}) {
  final workDirectory = Directory(
    _joinPath(resourcesPath, const ['KonyakPinnedProgramIconWork']),
  );
  final iconset = Directory(
    _joinPath(workDirectory.path, const ['KonyakPinnedProgram.iconset']),
  );
  final sourcePngPath = _joinPath(workDirectory.path, const ['source.png']);
  final icnsPath = _joinPath(resourcesPath, const [
    _macosPinnedLauncherIconFileName,
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
      final resized = _joinPath(iconset.path, ['icon_${size}x$size.png']);
      final resized2x = _joinPath(iconset.path, ['icon_${size}x$size@2x.png']);
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

    return _macosPinnedLauncherIconFileName;
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

String _macosPinnedLauncherFallbackIconFileName(String sourcePath) {
  final baseName = _baseName(sourcePath);
  final extensionStart = baseName.lastIndexOf('.');
  final extension = extensionStart == -1
      ? ''
      : baseName.substring(extensionStart).toLowerCase();
  if (extension.isEmpty || !RegExp(r'^\.[a-z0-9]+$').hasMatch(extension)) {
    return 'KonyakPinnedProgramIcon';
  }

  return 'KonyakPinnedProgram$extension';
}
