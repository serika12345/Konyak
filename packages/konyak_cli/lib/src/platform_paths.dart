part of '../konyak_cli.dart';

String? _bottleLocationPath({
  required BottleRecord bottle,
  required String location,
}) {
  final normalized = location.trim().toLowerCase();
  return switch (normalized) {
    'root' => bottle.path,
    'c-drive' => _joinPath(bottle.path, const ['drive_c']),
    _ => null,
  };
}

String _programLocationPath(String programPath) {
  final normalized = _normalizeFilesystemPath(programPath);
  final separator = normalized.lastIndexOf('/');
  if (separator <= 0) {
    return normalized;
  }

  return normalized.substring(0, separator);
}

KonyakHostPlatform _currentHostPlatform() {
  return switch (Platform.operatingSystem) {
    'macos' => KonyakHostPlatform.macos,
    _ => KonyakHostPlatform.linux,
  };
}

String _pathOpenExecutable() {
  return switch (_currentHostPlatform()) {
    KonyakHostPlatform.macos =>
      File('/usr/bin/open').existsSync() ? '/usr/bin/open' : 'open',
    KonyakHostPlatform.linux => 'xdg-open',
  };
}

String _konyakApplicationSupportFolder(Map<String, String> environment) {
  final override = environment['KONYAK_APPLICATION_SUPPORT'];
  if (override != null && override.trim().isNotEmpty) {
    return override;
  }

  final home = environment['HOME'];
  if (home != null && home.trim().isNotEmpty) {
    return _joinPath(home, const ['Library', 'Application Support', 'Konyak']);
  }

  return 'Konyak';
}

String _macosWineRuntimeRoot(Map<String, String> environment) {
  final override = environment['KONYAK_MACOS_WINE_HOME'];
  if (override != null && override.trim().isNotEmpty) {
    return override;
  }

  return _joinPath(_konyakApplicationSupportFolder(environment), const [
    'Runtimes',
    'macos-wine',
  ]);
}

String _linuxWineRuntimeRoot(Map<String, String> environment) {
  final override = environment['KONYAK_LINUX_WINE_HOME'];
  if (override != null && override.trim().isNotEmpty) {
    return override;
  }

  return _joinPath(_resolveDataHome(environment), const [
    'Runtimes',
    'linux-wine',
  ]);
}

String _macosWineBinFolder(Map<String, String> environment) {
  return _joinPath(_macosWineRuntimeRoot(environment), const ['bin']);
}

String? _linuxManagedRuntimeBinFolder(Map<String, String> environment) {
  final override = environment['KONYAK_LINUX_WINE_HOME'];
  if (override == null || override.trim().isEmpty) {
    return null;
  }

  return _joinPath(override, const ['bin']);
}

String _macosWineExecutable(Map<String, String> environment) {
  return _joinPath(_macosWineBinFolder(environment), const ['wine64']);
}

String _linuxWineExecutable(Map<String, String> environment) {
  final runtimeBin = _linuxManagedRuntimeBinFolder(environment);
  if (runtimeBin != null) {
    return _joinPath(runtimeBin, const ['wine']);
  }

  return 'wine';
}

String _linuxWinebootExecutable(Map<String, String> environment) {
  final runtimeBin = _linuxManagedRuntimeBinFolder(environment);
  if (runtimeBin != null) {
    return _joinPath(runtimeBin, const ['wineboot']);
  }

  return 'wineboot';
}

String _linuxWineserverExecutable(Map<String, String> environment) {
  final runtimeBin = _linuxManagedRuntimeBinFolder(environment);
  if (runtimeBin != null) {
    return _joinPath(runtimeBin, const ['wineserver']);
  }

  return 'wineserver';
}

String _linuxWinedbgExecutable(Map<String, String> environment) {
  final runtimeBin = _linuxManagedRuntimeBinFolder(environment);
  if (runtimeBin != null) {
    return _joinPath(runtimeBin, const ['winedbg']);
  }

  return 'winedbg';
}

String _macosWineserverExecutable(Map<String, String> environment) {
  return _joinPath(_macosWineBinFolder(environment), const ['wineserver']);
}

String _macosWinetricksExecutable(Map<String, String> environment) {
  return _joinPath(_macosWineRuntimeRoot(environment), const ['winetricks']);
}

String _linuxWinetricksExecutable(Map<String, String> environment) {
  final override = environment['KONYAK_LINUX_WINE_HOME'];
  if (override != null && override.trim().isNotEmpty) {
    return _joinPath(override, const ['winetricks']);
  }

  return 'winetricks';
}

Map<String, String> _linuxRuntimeEnvironment(Map<String, String> environment) {
  final runtimeBin = _linuxManagedRuntimeBinFolder(environment);
  final wineLibraryPath = environment['KONYAK_LINUX_WINE_LIBRARY_PATH'];
  final hasWineLibraryPath =
      wineLibraryPath != null && wineLibraryPath.trim().isNotEmpty;
  if (runtimeBin == null && !hasWineLibraryPath) {
    return const <String, String>{};
  }

  final runtimeEnvironment = <String, String>{};
  if (runtimeBin != null) {
    runtimeEnvironment['PATH'] = _prependPath(runtimeBin, environment['PATH']);
  }
  if (hasWineLibraryPath) {
    runtimeEnvironment['LD_LIBRARY_PATH'] = _prependPath(
      wineLibraryPath.trim(),
      environment['LD_LIBRARY_PATH'],
    );
  }

  return Map.unmodifiable(runtimeEnvironment);
}

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

String? _fileNameFromUrl(String url) {
  final parsed = Uri.tryParse(url);
  final segments = parsed?.pathSegments;
  final candidate = segments == null || segments.isEmpty
      ? null
      : segments.last.trim();
  if (candidate == null || candidate.isEmpty) {
    return null;
  }

  return candidate.replaceAll(RegExp(r'[^A-Za-z0-9._+-]'), '_');
}
