part of '../konyak_cli.dart';

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
