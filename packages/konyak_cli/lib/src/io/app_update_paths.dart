part of '../../konyak_cli.dart';

String _appUpdateCacheDirectory(HostEnvironment environment) {
  return environment
      .nonEmptyValue('KONYAK_APP_UPDATE_CACHE_HOME')
      .match(
        () => switch (_currentHostPlatform()) {
          KonyakHostPlatform.linux =>
            environment
                .nonEmptyValue('XDG_CACHE_HOME')
                .match(
                  () => environment
                      .nonEmptyValue('HOME')
                      .match(
                        () => _joinPath(Directory.systemTemp.path, const [
                          'konyak',
                          'updates',
                        ]),
                        (home) => _joinPath(home, const [
                          '.cache',
                          'konyak',
                          'updates',
                        ]),
                      ),
                  (xdgCache) =>
                      _joinPath(xdgCache, const ['konyak', 'updates']),
                ),
          KonyakHostPlatform.macos =>
            environment
                .nonEmptyValue('HOME')
                .match(
                  () => _joinPath(Directory.systemTemp.path, const [
                    'konyak',
                    'updates',
                  ]),
                  (home) => _joinPath(home, const [
                    'Library',
                    'Caches',
                    'Konyak',
                    'Updates',
                  ]),
                ),
        },
        (override) => override,
      );
}

Option<String> _linuxAppImageTargetPath(HostEnvironment environment) {
  return environment
      .nonEmptyValue('KONYAK_APPIMAGE_PATH')
      .match(() => environment.nonEmptyValue('APPIMAGE'), Option.of);
}

Option<String> _macosAppBundlePath(HostEnvironment environment) {
  return environment
      .nonEmptyValue('KONYAK_APP_BUNDLE_PATH')
      .match(
        () => environment
            .nonEmptyValue('KONYAK_APP_EXECUTABLE')
            .flatMap(_macosAppBundlePathFromExecutable),
        Option.of,
      );
}

Option<String> _macosAppBundlePathFromExecutable(String executable) {
  final normalized = executable.replaceAll('\\', '/');
  const marker = '.app/Contents/MacOS/';
  final markerIndex = normalized.indexOf(marker);
  if (markerIndex < 0) {
    return const Option.none();
  }

  return Option.of(normalized.substring(0, markerIndex + '.app'.length));
}

Option<int> _konyakAppPid(HostEnvironment environment) {
  return environment.nonEmptyValue('KONYAK_APP_PID').flatMap((raw) {
    return switch (int.tryParse(raw)) {
      final int pid when pid > 0 => Option.of(pid),
      _ => const Option.none(),
    };
  });
}
