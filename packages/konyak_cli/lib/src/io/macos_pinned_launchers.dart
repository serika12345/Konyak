part of '../../konyak_cli.dart';

const _macosPinnedLauncherManifestFileName = 'konyak-launcher.json';
const _macosPinnedLauncherExecutableName = 'konyak-launcher';

class _MacosPinnedProgramLauncherCommand {
  _MacosPinnedProgramLauncherCommand({
    required this.executable,
    required List<String> arguments,
    required this.workingDirectory,
  }) : arguments = List.unmodifiable(arguments);

  final String executable;
  final List<String> arguments;
  final Option<String> workingDirectory;
}

void _synchronizeMacosPinnedProgramLaunchers({
  required KonyakHostPlatform hostPlatform,
  required Map<String, String> environment,
  required List<BottleRecord> bottles,
}) {
  final hostEnvironment = HostEnvironment(environment);
  if (hostPlatform != KonyakHostPlatform.macos) {
    return;
  }

  _macosPinnedProgramLaunchersHome(hostEnvironment).match<void>(() {}, (
    launcherHome,
  ) {
    _macosPinnedProgramLauncherCommand(hostEnvironment).match<void>(() {}, (
      launcherCommand,
    ) {
      try {
        final desiredLauncherIds = <String>{};
        final desiredLauncherPaths = <String, String>{};
        final usedDisplayNames = <String>{};
        final usedBundleNames = _unmanagedMacosLauncherBundleNames(
          launcherHome,
        );
        for (final bottle in bottles) {
          for (final program in bottle.pinnedPrograms) {
            final launcherId = _pinnedProgramLauncherId(
              bottleId: bottle.id.value,
              programPath: program.path.value,
            );
            final displayName = _uniqueMacosLauncherDisplayName(
              program.name.value,
              usedDisplayNames: usedDisplayNames,
              usedBundleNames: usedBundleNames,
            );
            final bundlePath = _joinPath(launcherHome, [
              _macosLauncherBundleName(displayName),
            ]);
            desiredLauncherIds.add(launcherId);
            desiredLauncherPaths[launcherId] = _normalizeFilesystemPath(
              bundlePath,
            );
            _writeMacosPinnedProgramLauncher(
              bundlePath: bundlePath,
              launcherCommand: launcherCommand,
              displayName: displayName,
              iconPath: program.iconPath
                  .map((value) => value.value)
                  .toNullable(),
              manifest: PinnedProgramLauncherManifest(
                launcherId: launcherId,
                bottleId: bottle.id.value,
                programPath: program.path.value,
                programName: program.name.value,
              ),
            );
          }
        }

        _deleteStaleMacosPinnedProgramLaunchers(
          launcherHome: launcherHome,
          desiredLauncherIds: desiredLauncherIds,
          desiredLauncherPaths: desiredLauncherPaths,
        );
      } on FileSystemException {
        return;
      } on ProcessException {
        return;
      }
    });
  });
}

Option<String> _macosPinnedProgramLaunchersHome(HostEnvironment environment) {
  return environment
      .nonEmptyValue('KONYAK_MACOS_PINNED_LAUNCHERS_HOME')
      .match(
        () => environment
            .nonEmptyValue('HOME')
            .map((home) => _joinPath(home, const ['Applications', 'Konyak'])),
        Option.of,
      );
}

Option<_MacosPinnedProgramLauncherCommand> _macosPinnedProgramLauncherCommand(
  HostEnvironment environment,
) {
  return environment
      .nonEmptyValue('KONYAK_PINNED_PROGRAM_LAUNCHER_EXECUTABLE')
      .match(
        () => environment
            .nonEmptyValue('KONYAK_PINNED_PROGRAM_LAUNCHER_CLI')
            .match(
              () => _macosAppBundlePath(environment).flatMap((bundlePath) {
                final cliExecutable = _joinPath(bundlePath, const [
                  'Contents',
                  'Resources',
                  'konyak-cli',
                ]);
                if (!File(cliExecutable).existsSync()) {
                  return const Option.none();
                }

                return Option.of(
                  _MacosPinnedProgramLauncherCommand(
                    executable: cliExecutable,
                    arguments: const <String>[],
                    workingDirectory: const Option.none(),
                  ),
                );
              }),
              (override) => Option.of(
                _MacosPinnedProgramLauncherCommand(
                  executable: override,
                  arguments: const <String>[],
                  workingDirectory: const Option.none(),
                ),
              ),
            ),
        (developmentExecutable) =>
            _pinnedProgramLauncherArguments(
              environment['KONYAK_PINNED_PROGRAM_LAUNCHER_ARGUMENTS_JSON'],
            ).map(
              (developmentArguments) => _MacosPinnedProgramLauncherCommand(
                executable: developmentExecutable,
                arguments: developmentArguments,
                workingDirectory: environment.nonEmptyValue(
                  'KONYAK_PINNED_PROGRAM_LAUNCHER_WORKING_DIRECTORY',
                ),
              ),
            ),
      );
}

Option<List<String>> _pinnedProgramLauncherArguments(Option<String> value) {
  return value.match(() => Option<List<String>>.of(const <String>[]), (raw) {
    if (raw.trim().isEmpty) {
      return Option<List<String>>.of(const <String>[]);
    }

    return _decodePinnedProgramLauncherArgumentsJson(raw).match(
      () => const Option.none(),
      (decoded) => switch (decoded) {
        final List<Object?> values => (() {
          final arguments = values.whereType<String>().toList(growable: false);
          if (arguments.length != values.length) {
            return const Option<List<String>>.none();
          }

          return Option<List<String>>.of(List<String>.unmodifiable(arguments));
        })(),
        _ => const Option.none(),
      },
    );
  });
}

Option<Object?> _decodePinnedProgramLauncherArgumentsJson(String raw) {
  try {
    return Option<Object?>.of(jsonDecode(raw));
  } on FormatException {
    return const Option.none();
  }
}

String _pinnedProgramLauncherId({
  required String bottleId,
  required String programPath,
}) {
  return sha256
      .convert(
        utf8.encode('$bottleId\u0000${_normalizeFilesystemPath(programPath)}'),
      )
      .toString()
      .substring(0, 16);
}

_MacosPinnedProgramLauncherBundlePlan _macosPinnedProgramLauncherBundlePlan({
  required String bundlePath,
  required _MacosPinnedProgramLauncherCommand launcherCommand,
  required String displayName,
  required String? iconFileName,
  required PinnedProgramLauncherManifest manifest,
}) {
  final contentsPath = _joinPath(bundlePath, const ['Contents']);
  final macosPath = _joinPath(contentsPath, const ['MacOS']);
  final resourcesPath = _joinPath(contentsPath, const ['Resources']);
  final executablePath = _joinPath(macosPath, const [
    _macosPinnedLauncherExecutableName,
  ]);
  final manifestPath = _joinPath(resourcesPath, const [
    _macosPinnedLauncherManifestFileName,
  ]);

  return _MacosPinnedProgramLauncherBundlePlan(
    infoPlistPath: _joinPath(contentsPath, const ['Info.plist']),
    manifestPath: manifestPath,
    executablePath: executablePath,
    infoPlist: _macosPinnedProgramInfoPlist(
      manifest: manifest,
      displayName: displayName,
      iconFileName: iconFileName,
    ),
    manifestJson: jsonEncode(manifest.toJson()),
    launcherScript: _macosPinnedProgramLauncherScript(launcherCommand),
  );
}
