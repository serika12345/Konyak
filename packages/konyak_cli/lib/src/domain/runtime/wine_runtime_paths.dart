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

  return _joinPath(_resolveDataHome(environment), const [
    'Runtimes',
    'linux-wine',
  ]);
}

String _macosWineBinFolder(HostEnvironment environment) {
  return _joinPath(_macosWineRuntimeRoot(environment), const ['bin']);
}

Option<String> _linuxManagedRuntimeBinFolder(HostEnvironment environment) {
  final override = environment.nonEmptyValue('KONYAK_LINUX_WINE_HOME');
  if (override == null) {
    return const Option.none();
  }

  return Option.of(_joinPath(override, const ['bin']));
}

String _macosWineExecutable(HostEnvironment environment) {
  return _joinPath(_macosWineBinFolder(environment), const ['wine64']);
}

String _linuxWineExecutable(HostEnvironment environment) {
  return _linuxManagedRuntimeBinFolder(
    environment,
  ).match(() => 'wine', (runtimeBin) => _joinPath(runtimeBin, const ['wine']));
}

String _linuxWinebootExecutable(HostEnvironment environment) {
  return _linuxManagedRuntimeBinFolder(environment).match(
    () => 'wineboot',
    (runtimeBin) => _joinPath(runtimeBin, const ['wineboot']),
  );
}

String _linuxWineserverExecutable(HostEnvironment environment) {
  return _linuxManagedRuntimeBinFolder(environment).match(
    () => 'wineserver',
    (runtimeBin) => _joinPath(runtimeBin, const ['wineserver']),
  );
}

String _linuxWinedbgExecutable(HostEnvironment environment) {
  return _linuxManagedRuntimeBinFolder(environment).match(
    () => 'winedbg',
    (runtimeBin) => _joinPath(runtimeBin, const ['winedbg']),
  );
}

String _macosWineserverExecutable(HostEnvironment environment) {
  return _joinPath(_macosWineBinFolder(environment), const ['wineserver']);
}

String _macosWinetricksExecutable(HostEnvironment environment) {
  return _joinPath(_macosWineRuntimeRoot(environment), const ['winetricks']);
}

String _linuxWinetricksExecutable(HostEnvironment environment) {
  final override = environment.nonEmptyValue('KONYAK_LINUX_WINE_HOME');
  if (override != null) {
    return _joinPath(override, const ['winetricks']);
  }

  return 'winetricks';
}

ProgramRunEnvironment _linuxRuntimeEnvironment(HostEnvironment environment) {
  final runtimeBin = _linuxManagedRuntimeBinFolder(environment);
  final wineLibraryPath = environment.nonEmptyValue(
    'KONYAK_LINUX_WINE_LIBRARY_PATH',
  );
  if (runtimeBin.isNone() && wineLibraryPath == null) {
    return const ProgramRunEnvironment.empty();
  }

  final runtimeEnvironment = <String, String>{};
  runtimeBin.match(() {}, (path) {
    runtimeEnvironment['PATH'] = _prependPath(
      path,
      Option.fromNullable(environment['PATH']),
    );
  });
  if (wineLibraryPath != null) {
    runtimeEnvironment['LD_LIBRARY_PATH'] = _prependPath(
      wineLibraryPath,
      Option.fromNullable(environment['LD_LIBRARY_PATH']),
    );
  }

  return ProgramRunEnvironment(runtimeEnvironment);
}
