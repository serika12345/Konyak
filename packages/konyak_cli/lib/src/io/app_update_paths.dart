part of '../../konyak_cli.dart';

String _appUpdateCacheDirectory(Map<String, String> environment) {
  final override = environment['KONYAK_APP_UPDATE_CACHE_HOME'];
  if (override != null && override.trim().isNotEmpty) {
    return override;
  }

  final xdgCache = environment['XDG_CACHE_HOME'];
  if (_currentHostPlatform() == KonyakHostPlatform.linux &&
      xdgCache != null &&
      xdgCache.trim().isNotEmpty) {
    return _joinPath(xdgCache, const ['konyak', 'updates']);
  }

  final home = environment['HOME'];
  if (home != null && home.trim().isNotEmpty) {
    return switch (_currentHostPlatform()) {
      KonyakHostPlatform.macos => _joinPath(home, const [
        'Library',
        'Caches',
        'Konyak',
        'Updates',
      ]),
      KonyakHostPlatform.linux => _joinPath(home, const [
        '.cache',
        'konyak',
        'updates',
      ]),
    };
  }

  return _joinPath(Directory.systemTemp.path, const ['konyak', 'updates']);
}

String? _linuxAppImageTargetPath(Map<String, String> environment) {
  final override = environment['KONYAK_APPIMAGE_PATH'];
  if (override != null && override.trim().isNotEmpty) {
    return override.trim();
  }

  final appImage = environment['APPIMAGE'];
  if (appImage != null && appImage.trim().isNotEmpty) {
    return appImage.trim();
  }

  return null;
}

String? _macosAppBundlePath(Map<String, String> environment) {
  final override = environment['KONYAK_APP_BUNDLE_PATH'];
  if (override != null && override.trim().isNotEmpty) {
    return override.trim();
  }

  final executable = environment['KONYAK_APP_EXECUTABLE'];
  if (executable == null || executable.trim().isEmpty) {
    return null;
  }

  return _macosAppBundlePathFromExecutable(executable.trim());
}

String? _macosAppBundlePathFromExecutable(String executable) {
  final normalized = executable.replaceAll('\\', '/');
  const marker = '.app/Contents/MacOS/';
  final markerIndex = normalized.indexOf(marker);
  if (markerIndex < 0) {
    return null;
  }

  return normalized.substring(0, markerIndex + '.app'.length);
}

int? _konyakAppPid(Map<String, String> environment) {
  final raw = environment['KONYAK_APP_PID'];
  if (raw == null || raw.trim().isEmpty) {
    return null;
  }

  final pid = int.tryParse(raw.trim());
  if (pid == null || pid <= 0) {
    return null;
  }

  return pid;
}
