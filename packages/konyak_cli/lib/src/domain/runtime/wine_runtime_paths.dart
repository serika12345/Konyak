import '../program/program_run_environment.dart';
import '../shared/domain_helpers.dart';
import 'host_environment.dart';

String konyakApplicationSupportFolder(HostEnvironment environment) {
  return environment
      .nonEmptyValue('KONYAK_APPLICATION_SUPPORT')
      .match(
        () => environment
            .nonEmptyValue('HOME')
            .match(
              () => 'Konyak',
              (home) => domainJoinPath(home, const [
                'Library',
                'Application Support',
                'Konyak',
              ]),
            ),
        (override) => override,
      );
}

String macosWineRuntimeRoot(HostEnvironment environment) {
  return environment
      .nonEmptyValue('KONYAK_MACOS_WINE_HOME')
      .match(
        () => domainJoinPath(
          konyakApplicationSupportFolder(environment),
          const ['Runtimes', 'macos-wine'],
        ),
        (override) => override,
      );
}

String linuxWineRuntimeRoot(HostEnvironment environment) {
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
                      (home) => domainJoinPath(home, const [
                        '.local',
                        'share',
                        'konyak',
                      ]),
                    ),
                (xdgDataHome) => domainJoinPath(xdgDataHome, const ['konyak']),
              ),
          (dataHomeOverride) => dataHomeOverride,
        );

    return domainJoinPath(dataHome, const ['Runtimes', 'linux-wine']);
  }, (override) => override);
}

String macosWineBinFolder(HostEnvironment environment) {
  return domainJoinPath(macosWineRuntimeRoot(environment), const ['bin']);
}

String linuxManagedRuntimeBinFolder(HostEnvironment environment) {
  return domainJoinPath(linuxWineRuntimeRoot(environment), const ['bin']);
}

String macosWineExecutable(HostEnvironment environment) {
  return domainJoinPath(macosWineBinFolder(environment), const ['wineloader']);
}

String linuxWineExecutable(HostEnvironment environment) {
  return domainJoinPath(linuxManagedRuntimeBinFolder(environment), const [
    'wine',
  ]);
}

String linuxWinebootExecutable(HostEnvironment environment) {
  return domainJoinPath(linuxManagedRuntimeBinFolder(environment), const [
    'wineboot',
  ]);
}

String linuxWineserverExecutable(HostEnvironment environment) {
  return domainJoinPath(linuxManagedRuntimeBinFolder(environment), const [
    'wineserver',
  ]);
}

String linuxWinedbgExecutable(HostEnvironment environment) {
  return domainJoinPath(linuxManagedRuntimeBinFolder(environment), const [
    'winedbg',
  ]);
}

String macosWineserverExecutable(HostEnvironment environment) {
  return domainJoinPath(macosWineBinFolder(environment), const ['wineserver']);
}

String macosWinetricksExecutable(HostEnvironment environment) {
  return domainJoinPath(macosWineRuntimeRoot(environment), const [
    'winetricks',
  ]);
}

String linuxWinetricksExecutable(HostEnvironment environment) {
  return domainJoinPath(linuxWineRuntimeRoot(environment), const [
    'winetricks',
  ]);
}

ProgramRunEnvironment linuxRuntimeEnvironment(HostEnvironment environment) {
  final runtimeBin = linuxManagedRuntimeBinFolder(environment);
  final wineLibraryPath = environment.nonEmptyValue(
    'KONYAK_LINUX_WINE_LIBRARY_PATH',
  );

  return ProgramRunEnvironment(<String, String>{
    'PATH': prependPath(runtimeBin, environment['PATH']),
    ...wineLibraryPath.match(
      () => const <String, String>{},
      (path) => <String, String>{
        'LD_LIBRARY_PATH': prependPath(path, environment['LD_LIBRARY_PATH']),
      },
    ),
  });
}
