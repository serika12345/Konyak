part of '../../konyak_cli.dart';

const _linuxPinnedLauncherManifestFileName = 'konyak-launcher.json';
const _linuxPinnedLauncherExecutableName = 'launch';
const _linuxPinnedLauncherDesktopEntryPrefix = 'app.konyak.Konyak.pinned.';

class _LinuxPinnedProgramLauncherCommand {
  _LinuxPinnedProgramLauncherCommand({
    required this.executable,
    required List<String> arguments,
    required this.workingDirectory,
  }) : arguments = List.unmodifiable(arguments);

  final String executable;
  final List<String> arguments;
  final Option<String> workingDirectory;
}

void _synchronizePinnedProgramLaunchers({
  required KonyakHostPlatform hostPlatform,
  required Map<String, String> environment,
  required List<BottleRecord> bottles,
}) {
  _synchronizeMacosPinnedProgramLaunchers(
    hostPlatform: hostPlatform,
    environment: environment,
    bottles: bottles,
  );
  _synchronizeLinuxPinnedProgramLaunchers(
    hostPlatform: hostPlatform,
    environment: environment,
    bottles: bottles,
  );
}

void _synchronizeLinuxPinnedProgramLaunchers({
  required KonyakHostPlatform hostPlatform,
  required Map<String, String> environment,
  required List<BottleRecord> bottles,
}) {
  final hostEnvironment = HostEnvironment(environment);
  if (hostPlatform != KonyakHostPlatform.linux) {
    return;
  }

  _linuxPinnedProgramLauncherCommand(hostEnvironment).match<void>(() {}, (
    launcherCommand,
  ) {
    try {
      final desiredLaunchers = <_PinnedProgramLauncherWrite>[
        for (final bottle in bottles)
          for (final program in bottle.pinnedPrograms)
            _PinnedProgramLauncherWrite(
              displayName: _linuxPinnedProgramDisplayName(program.name.value),
              iconPath: program.iconPath.map((value) => value.value),
              manifest: PinnedProgramLauncherManifest(
                launcherId: _pinnedProgramLauncherId(
                  bottleId: bottle.id.value,
                  programPath: program.path.value,
                ),
                bottleId: bottle.id.value,
                programPath: program.path.value,
                programName: program.name.value,
              ),
            ),
      ];
      final desiredLauncherIds = <String>{
        for (final launcher in desiredLaunchers)
          launcher.manifest.launcherId.value,
      };
      final wroteAny = desiredLaunchers.fold(
        false,
        (changed, launcher) =>
            _writeLinuxPinnedProgramLauncher(
              environment: hostEnvironment,
              launcherCommand: launcherCommand,
              displayName: launcher.displayName,
              iconPath: launcher.iconPath.toNullable(),
              manifest: launcher.manifest,
            ) ||
            changed,
      );
      final removedAny = _deleteStaleLinuxPinnedProgramLaunchers(
        environment: hostEnvironment,
        desiredLauncherIds: desiredLauncherIds,
      );
      final changed = wroteAny || removedAny;
      if (!changed) {
        return;
      }
      _refreshLinuxDesktopIntegrationCaches(
        applicationsPath: _linuxApplicationsHome(hostEnvironment),
        iconThemePath: null,
      );
    } on FileSystemException {
      return;
    } on ProcessException {
      return;
    } on BottleRepositoryException {
      return;
    }
  });
}

final class _PinnedProgramLauncherWrite {
  const _PinnedProgramLauncherWrite({
    required this.displayName,
    required this.iconPath,
    required this.manifest,
  });

  final String displayName;
  final Option<String> iconPath;
  final PinnedProgramLauncherManifest manifest;
}

Option<_LinuxPinnedProgramLauncherCommand> _linuxPinnedProgramLauncherCommand(
  HostEnvironment environment,
) {
  return environment
      .nonEmptyValue('KONYAK_APPIMAGE_PATH')
      .match(
        () => environment
            .nonEmptyValue('KONYAK_PINNED_PROGRAM_LAUNCHER_EXECUTABLE')
            .match(
              () => environment
                  .nonEmptyValue('KONYAK_PINNED_PROGRAM_LAUNCHER_CLI')
                  .match(
                    () => environment
                        .nonEmptyValue('KONYAK_BUNDLE_RESOURCES')
                        .match(() => const Option.none(), (bundleResources) {
                          final cliExecutable = _joinPath(
                            bundleResources,
                            const ['konyak-cli'],
                          );
                          if (!File(cliExecutable).existsSync()) {
                            return const Option.none();
                          }

                          return Option.of(
                            _LinuxPinnedProgramLauncherCommand(
                              executable: cliExecutable,
                              arguments: const <String>[],
                              workingDirectory: const Option.none(),
                            ),
                          );
                        }),
                    (override) => Option.of(
                      _LinuxPinnedProgramLauncherCommand(
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
                    (developmentArguments) =>
                        _LinuxPinnedProgramLauncherCommand(
                          executable: developmentExecutable,
                          arguments: developmentArguments,
                          workingDirectory: environment.nonEmptyValue(
                            'KONYAK_PINNED_PROGRAM_LAUNCHER_WORKING_DIRECTORY',
                          ),
                        ),
                  ),
            ),
        (appImage) => Option.of(
          _LinuxPinnedProgramLauncherCommand(
            executable: appImage,
            arguments: const <String>['--konyak-cli'],
            workingDirectory: const Option.none(),
          ),
        ),
      );
}

bool _writeLinuxPinnedProgramLauncher({
  required HostEnvironment environment,
  required _LinuxPinnedProgramLauncherCommand launcherCommand,
  required String displayName,
  required String? iconPath,
  required PinnedProgramLauncherManifest manifest,
}) {
  final launcherDirectoryPath = _linuxPinnedProgramLauncherDirectoryPath(
    environment: environment,
    launcherId: manifest.launcherId.value,
  );
  final executablePath = _joinPath(launcherDirectoryPath, const [
    _linuxPinnedLauncherExecutableName,
  ]);
  final manifestPath = _joinPath(launcherDirectoryPath, const [
    _linuxPinnedLauncherManifestFileName,
  ]);
  final desktopEntryPath = _linuxPinnedProgramDesktopEntryPath(
    environment: environment,
    launcherId: manifest.launcherId.value,
  );

  Directory(launcherDirectoryPath).createSync(recursive: true);
  final manifestChanged = _writeTextFileIfChanged(
    manifestPath,
    jsonEncode(manifest.toJson()),
  );
  final executableChanged = _writeTextFileIfChanged(
    executablePath,
    _linuxPinnedProgramLauncherScript(launcherCommand),
  );
  final executableChmodResult = Process.runSync('chmod', <String>[
    '755',
    executablePath,
  ], runInShell: false);
  if (executableChmodResult.exitCode != 0) {
    throw FileSystemException(
      'Unable to mark launcher executable.',
      executablePath,
    );
  }

  final desktopEntryChanged = _writeTextFileIfChanged(
    desktopEntryPath,
    _linuxPinnedProgramDesktopEntry(
      displayName: displayName,
      executablePath: executablePath,
      iconPath: iconPath,
      programPath: manifest.programPath.value,
    ),
  );

  return manifestChanged || executableChanged || desktopEntryChanged;
}

bool _deleteStaleLinuxPinnedProgramLaunchers({
  required HostEnvironment environment,
  required Set<String> desiredLauncherIds,
}) {
  final desktopEntriesDeleted = _deleteStaleLinuxPinnedProgramDesktopEntries(
    environment: environment,
    desiredLauncherIds: desiredLauncherIds,
  );
  final launcherDirectoriesDeleted =
      _deleteStaleLinuxPinnedProgramLauncherDirectories(
        environment: environment,
        desiredLauncherIds: desiredLauncherIds,
      );

  return desktopEntriesDeleted || launcherDirectoriesDeleted;
}

bool _deleteStaleLinuxPinnedProgramDesktopEntries({
  required HostEnvironment environment,
  required Set<String> desiredLauncherIds,
}) {
  final applicationsDirectory = Directory(_linuxApplicationsHome(environment));
  if (!applicationsDirectory.existsSync()) {
    return false;
  }

  return applicationsDirectory
      .listSync(followLinks: false)
      .whereType<File>()
      .where((entity) => _isLinuxPinnedProgramDesktopEntryPath(entity.path))
      .where((entity) {
        final launcherId = _linuxPinnedProgramLauncherIdFromDesktopEntryPath(
          entity.path,
        );
        return launcherId != null && !desiredLauncherIds.contains(launcherId);
      })
      .map((entity) {
        entity.deleteSync();
        return true;
      })
      .fold(false, (deletedAny, deleted) => deletedAny || deleted);
}

bool _deleteStaleLinuxPinnedProgramLauncherDirectories({
  required HostEnvironment environment,
  required Set<String> desiredLauncherIds,
}) {
  final launcherRoot = Directory(_linuxPinnedProgramLauncherRoot(environment));
  if (!launcherRoot.existsSync()) {
    return false;
  }

  return launcherRoot
      .listSync(followLinks: false)
      .whereType<Directory>()
      .where((entity) => !desiredLauncherIds.contains(_baseName(entity.path)))
      .where((entity) {
        final manifest = _readPinnedProgramLauncherManifest(
          _joinPath(entity.path, const [_linuxPinnedLauncherManifestFileName]),
        );
        return manifest.match(() => false, (_) => true);
      })
      .map((entity) {
        entity.deleteSync(recursive: true);
        return true;
      })
      .fold(false, (deletedAny, deleted) => deletedAny || deleted);
}

String _linuxPinnedProgramLauncherRoot(HostEnvironment environment) {
  return _joinPath(_linuxDataHome(environment), const [
    'konyak',
    'launchers',
    'linux-pinned',
  ]);
}

String _linuxPinnedProgramLauncherDirectoryPath({
  required HostEnvironment environment,
  required String launcherId,
}) {
  return _joinPath(_linuxPinnedProgramLauncherRoot(environment), [launcherId]);
}

String _linuxPinnedProgramDesktopEntryPath({
  required HostEnvironment environment,
  required String launcherId,
}) {
  return _joinPath(_linuxApplicationsHome(environment), [
    '$_linuxPinnedLauncherDesktopEntryPrefix$launcherId.desktop',
  ]);
}

bool _isLinuxPinnedProgramDesktopEntryPath(String path) {
  final fileName = _baseName(path);
  return fileName.startsWith(_linuxPinnedLauncherDesktopEntryPrefix) &&
      fileName.endsWith('.desktop');
}

String? _linuxPinnedProgramLauncherIdFromDesktopEntryPath(String path) {
  final fileName = _baseName(path);
  if (!fileName.startsWith(_linuxPinnedLauncherDesktopEntryPrefix) ||
      !fileName.endsWith('.desktop')) {
    return null;
  }

  return fileName.substring(
    _linuxPinnedLauncherDesktopEntryPrefix.length,
    fileName.length - '.desktop'.length,
  );
}

String _linuxPinnedProgramDisplayName(String name) {
  final normalized = name.trim();
  return normalized.isEmpty ? 'Konyak Program' : normalized;
}

String _linuxPinnedProgramDesktopEntry({
  required String displayName,
  required String executablePath,
  required String? iconPath,
  required String programPath,
}) {
  final iconValue = iconPath == null || iconPath.trim().isEmpty
      ? 'app.konyak.Konyak'
      : _linuxDesktopEntryText(iconPath);
  return <String>[
    '[Desktop Entry]',
    'Version=1.0',
    'Type=Application',
    'Name=${_linuxDesktopEntryText(displayName)}',
    'Exec=${_desktopEntryQuote(executablePath)}',
    'Icon=$iconValue',
    'StartupWMClass=${_linuxDesktopEntryText(_normalizedExecutableName(programPath))}',
    'Terminal=false',
    'Categories=Utility;',
    'StartupNotify=true',
    '',
  ].join('\n');
}

String _linuxPinnedProgramLauncherScript(
  _LinuxPinnedProgramLauncherCommand command,
) {
  final changeDirectory = command.workingDirectory.match(
    () => '',
    (workingDirectory) => 'cd ${_posixShellSingleQuote(workingDirectory)}\n',
  );
  final launcherCommand = <String>[
    _posixShellSingleQuote(command.executable),
    ...command.arguments.map(_posixShellSingleQuote),
    'launch-pinned-program',
    '--manifest',
    r'"$manifest"',
    '--json',
  ].join(' ');

  return '''
#!/bin/sh
set -eu
manifest_dir=\$(CDPATH= cd -- "\$(dirname -- "\$0")" && pwd -P)
manifest="\$manifest_dir/$_linuxPinnedLauncherManifestFileName"
${changeDirectory}exec $launcherCommand
''';
}

String _linuxDesktopEntryText(String value) {
  return value.replaceAll(RegExp(r'[\u0000-\u001f\u007f]'), ' ').trim();
}

bool _writeTextFileIfChanged(String path, String contents) {
  final file = File(path);
  if (file.existsSync() && file.readAsStringSync() == contents) {
    return false;
  }

  file.parent.createSync(recursive: true);
  file.writeAsStringSync(contents);
  return true;
}
