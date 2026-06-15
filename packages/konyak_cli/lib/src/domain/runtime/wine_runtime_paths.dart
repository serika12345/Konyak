part of '../../../konyak_cli.dart';

String _konyakApplicationSupportFolder(HostEnvironment environment) {
  final override = environment.nonEmptyValue('KONYAK_APPLICATION_SUPPORT');
  if (override != null) {
    return override;
  }

  final home = environment.nonEmptyValue('HOME');
  if (home != null) {
    return _joinPath(home, const ['Library', 'Application Support', 'Konyak']);
  }

  return 'Konyak';
}

String _macosWineRuntimeRoot(HostEnvironment environment) {
  final override = environment.nonEmptyValue('KONYAK_MACOS_WINE_HOME');
  if (override != null) {
    return override;
  }

  return _joinPath(_konyakApplicationSupportFolder(environment), const [
    'Runtimes',
    'macos-wine',
  ]);
}

String _linuxWineRuntimeRoot(HostEnvironment environment) {
  final override = environment.nonEmptyValue('KONYAK_LINUX_WINE_HOME');
  if (override != null) {
    return override;
  }

  final dataHomeOverride = environment.nonEmptyValue('KONYAK_DATA_HOME');
  final xdgDataHome = environment.nonEmptyValue('XDG_DATA_HOME');
  final home = environment.nonEmptyValue('HOME');
  final dataHome =
      dataHomeOverride ??
      (xdgDataHome == null ? null : _joinPath(xdgDataHome, const ['konyak'])) ??
      (home == null
          ? 'Konyak'
          : _joinPath(home, const ['.local', 'share', 'konyak']));

  return _joinPath(dataHome, const ['Runtimes', 'linux-wine']);
}

String _macosWineBinFolder(HostEnvironment environment) {
  return _joinPath(_macosWineRuntimeRoot(environment), const ['bin']);
}

String _linuxManagedRuntimeBinFolder(HostEnvironment environment) {
  return _joinPath(_linuxWineRuntimeRoot(environment), const ['bin']);
}

String _macosWineExecutable(HostEnvironment environment) {
  return _joinPath(_macosWineBinFolder(environment), const ['wine64']);
}

String _linuxWineExecutable(HostEnvironment environment) {
  return _joinPath(_linuxManagedRuntimeBinFolder(environment), const ['wine']);
}

String _linuxWinebootExecutable(HostEnvironment environment) {
  return _joinPath(_linuxManagedRuntimeBinFolder(environment), const [
    'wineboot',
  ]);
}

String _linuxWineserverExecutable(HostEnvironment environment) {
  return _joinPath(_linuxManagedRuntimeBinFolder(environment), const [
    'wineserver',
  ]);
}

String _linuxWinedbgExecutable(HostEnvironment environment) {
  return _joinPath(_linuxManagedRuntimeBinFolder(environment), const [
    'winedbg',
  ]);
}

String _macosWineserverExecutable(HostEnvironment environment) {
  return _joinPath(_macosWineBinFolder(environment), const ['wineserver']);
}

String _macosWinetricksExecutable(HostEnvironment environment) {
  return _joinPath(_macosWineRuntimeRoot(environment), const ['winetricks']);
}

String _linuxWinetricksExecutable(HostEnvironment environment) {
  return _joinPath(_linuxWineRuntimeRoot(environment), const ['winetricks']);
}

ProgramRunEnvironment _linuxRuntimeEnvironment(HostEnvironment environment) {
  final runtimeBin = _linuxManagedRuntimeBinFolder(environment);
  final wineLibraryPath = environment.nonEmptyValue(
    'KONYAK_LINUX_WINE_LIBRARY_PATH',
  );

  final runtimeEnvironment = <String, String>{
    'PATH': _prependPath(runtimeBin, Option.fromNullable(environment['PATH'])),
  };
  if (wineLibraryPath != null) {
    runtimeEnvironment['LD_LIBRARY_PATH'] = _prependPath(
      wineLibraryPath,
      Option.fromNullable(environment['LD_LIBRARY_PATH']),
    );
  }

  return ProgramRunEnvironment(runtimeEnvironment);
}
