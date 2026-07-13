import 'dart:io';

import '../domain/program/program_runner.dart';
import '../domain/runtime/host_environment.dart';
import '../shared/common_helpers.dart';
import 'platform_host_paths.dart';

String profileInstallerCacheDirectory(HostEnvironment environment) {
  return environment
      .nonEmptyValue('KONYAK_PROFILE_INSTALLER_CACHE_HOME')
      .match(
        () => switch (currentHostPlatform()) {
          KonyakHostPlatform.linux =>
            environment
                .nonEmptyValue('XDG_CACHE_HOME')
                .match(
                  () => environment
                      .nonEmptyValue('HOME')
                      .match(
                        () => joinPath(
                          Directory.systemTemp.path,
                          const <String>['konyak', 'profile-installers'],
                        ),
                        (home) => joinPath(home, const <String>[
                          '.cache',
                          'konyak',
                          'profile-installers',
                        ]),
                      ),
                  (cache) => joinPath(cache, const <String>[
                    'konyak',
                    'profile-installers',
                  ]),
                ),
          KonyakHostPlatform.macos =>
            environment
                .nonEmptyValue('HOME')
                .match(
                  () => joinPath(Directory.systemTemp.path, const <String>[
                    'konyak',
                    'profile-installers',
                  ]),
                  (home) => joinPath(home, const <String>[
                    'Library',
                    'Caches',
                    'Konyak',
                    'ProfileInstallers',
                  ]),
                ),
        },
        (override) => override,
      );
}
