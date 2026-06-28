import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../domain/program/program_runner.dart';
import '../domain/runtime/host_environment.dart';
import '../shared/common_helpers.dart';
import 'platform_host_paths.dart';

String appUpdateCacheDirectory(HostEnvironment environment) {
  return environment
      .nonEmptyValue('KONYAK_APP_UPDATE_CACHE_HOME')
      .match(
        () => switch (currentHostPlatform()) {
          KonyakHostPlatform.linux =>
            environment
                .nonEmptyValue('XDG_CACHE_HOME')
                .match(
                  () => environment
                      .nonEmptyValue('HOME')
                      .match(
                        () => joinPath(Directory.systemTemp.path, const [
                          'konyak',
                          'updates',
                        ]),
                        (home) => joinPath(home, const [
                          '.cache',
                          'konyak',
                          'updates',
                        ]),
                      ),
                  (xdgCache) => joinPath(xdgCache, const ['konyak', 'updates']),
                ),
          KonyakHostPlatform.macos =>
            environment
                .nonEmptyValue('HOME')
                .match(
                  () => joinPath(Directory.systemTemp.path, const [
                    'konyak',
                    'updates',
                  ]),
                  (home) => joinPath(home, const [
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

Option<String> linuxAppImageTargetPath(HostEnvironment environment) {
  return environment
      .nonEmptyValue('KONYAK_APPIMAGE_PATH')
      .match(() => environment.nonEmptyValue('APPIMAGE'), Option.of);
}

Option<String> macosAppBundlePath(HostEnvironment environment) {
  return environment
      .nonEmptyValue('KONYAK_APP_BUNDLE_PATH')
      .match(
        () => environment
            .nonEmptyValue('KONYAK_APP_EXECUTABLE')
            .flatMap(macosAppBundlePathFromExecutable),
        Option.of,
      );
}

Option<String> macosAppBundlePathFromExecutable(String executable) {
  final normalized = executable.replaceAll('\\', '/');
  const marker = '.app/Contents/MacOS/';
  final markerIndex = normalized.indexOf(marker);
  if (markerIndex < 0) {
    return const Option.none();
  }

  return Option.of(normalized.substring(0, markerIndex + '.app'.length));
}

Option<int> konyakAppPid(HostEnvironment environment) {
  return environment.nonEmptyValue('KONYAK_APP_PID').flatMap((raw) {
    return switch (int.tryParse(raw)) {
      final int pid when pid > 0 => Option.of(pid),
      _ => const Option.none(),
    };
  });
}
