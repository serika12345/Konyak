part of '../../konyak_cli.dart';

String _appUpdateCacheDirectory(HostEnvironment environment) {
  final override = environment.nonEmptyValue('KONYAK_APP_UPDATE_CACHE_HOME');
  if (override != null) {
    return override;
  }

  final xdgCache = environment.nonEmptyValue('XDG_CACHE_HOME');
  if (_currentHostPlatform() == KonyakHostPlatform.linux && xdgCache != null) {
    return _joinPath(xdgCache, const ['konyak', 'updates']);
  }

  final home = environment.nonEmptyValue('HOME');
  if (home != null) {
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

String? _linuxAppImageTargetPath(HostEnvironment environment) {
  final override = environment.nonEmptyValue('KONYAK_APPIMAGE_PATH');
  if (override != null) {
    return override;
  }

  final appImage = environment.nonEmptyValue('APPIMAGE');
  if (appImage != null) {
    return appImage;
  }

  return null;
}

String? _macosAppBundlePath(HostEnvironment environment) {
  final override = environment.nonEmptyValue('KONYAK_APP_BUNDLE_PATH');
  if (override != null) {
    return override;
  }

  final executable = environment.nonEmptyValue('KONYAK_APP_EXECUTABLE');
  if (executable == null) {
    return null;
  }

  return _macosAppBundlePathFromExecutable(executable);
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

int? _konyakAppPid(HostEnvironment environment) {
  final raw = environment.nonEmptyValue('KONYAK_APP_PID');
  if (raw == null) {
    return null;
  }

  final pid = int.tryParse(raw);
  if (pid == null || pid <= 0) {
    return null;
  }

  return pid;
}
