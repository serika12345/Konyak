part of '../../../konyak_cli.dart';

String _konyakApplicationSupportFolder(HostEnvironment environment) {
  return environment
      .nonEmptyValue('KONYAK_APPLICATION_SUPPORT')
      .match(
        () => environment
            .nonEmptyValue('HOME')
            .match(
              () => 'Konyak',
              (home) => _joinPath(home, const [
                'Library',
                'Application Support',
                'Konyak',
              ]),
            ),
        (override) => override,
      );
}

String _macosWineRuntimeRoot(HostEnvironment environment) {
  return environment
      .nonEmptyValue('KONYAK_MACOS_WINE_HOME')
      .match(
        () => _joinPath(_konyakApplicationSupportFolder(environment), const [
          'Runtimes',
          'macos-wine',
        ]),
        (override) => override,
      );
}

String _linuxWineRuntimeRoot(HostEnvironment environment) {
  return environment.nonEmptyValue('KONYAK_LINUX_WINE_HOME').match(() {
    final dataHome = environment
        .nonEmptyValue('KONYAK_DATA_HOME')
        .match(
          () => environment
              .nonEmptyValue('XDG_DATA_HOME')
              .match(
                () => environment
                    .nonEmptyValue('HOME')
                    .match(
                      () => 'Konyak',
                      (home) =>
                          _joinPath(home, const ['.local', 'share', 'konyak']),
                    ),
                (xdgDataHome) => _joinPath(xdgDataHome, const ['konyak']),
              ),
          (dataHomeOverride) => dataHomeOverride,
        );

    return _joinPath(dataHome, const ['Runtimes', 'linux-wine']);
  }, (override) => override);
}

String _macosWineBinFolder(HostEnvironment environment) {
  return _joinPath(_macosWineRuntimeRoot(environment), const ['bin']);
}

String _linuxManagedRuntimeBinFolder(HostEnvironment environment) {
  return _joinPath(_linuxWineRuntimeRoot(environment), const ['bin']);
}

String _macosWineExecutable(HostEnvironment environment) {
  return _joinPath(_macosWineBinFolder(environment), const ['wineloader']);
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

  return ProgramRunEnvironment(<String, String>{
    'PATH': _prependPath(runtimeBin, environment['PATH']),
    ...wineLibraryPath.match(
      () => const <String, String>{},
      (path) => <String, String>{
        'LD_LIBRARY_PATH': _prependPath(path, environment['LD_LIBRARY_PATH']),
      },
    ),
  });
}
