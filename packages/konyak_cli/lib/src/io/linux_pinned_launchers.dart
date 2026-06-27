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
  final String? workingDirectory;
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

  final launcherCommand = _linuxPinnedProgramLauncherCommand(hostEnvironment);
  if (launcherCommand == null) {
    return;
  }

  try {
    final desiredLauncherIds = <String>{};
    var changed = false;
    for (final bottle in bottles) {
      for (final program in bottle.pinnedPrograms) {
        final launcherId = _pinnedProgramLauncherId(
          bottleId: bottle.id.value,
          programPath: program.path.value,
        );
        desiredLauncherIds.add(launcherId);
        changed =
            _writeLinuxPinnedProgramLauncher(
              environment: hostEnvironment,
              launcherCommand: launcherCommand,
              displayName: _linuxPinnedProgramDisplayName(program.name.value),
              iconPath: program.iconPath
                  .map((value) => value.value)
                  .toNullable(),
              manifest: _PinnedProgramLauncherManifest(
                launcherId: launcherId,
                bottleId: bottle.id.value,
                programPath: program.path.value,
                programName: program.name.value,
              ),
            ) ||
            changed;
      }
    }

    changed =
        _deleteStaleLinuxPinnedProgramLaunchers(
          environment: hostEnvironment,
          desiredLauncherIds: desiredLauncherIds,
        ) ||
        changed;
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
}

_LinuxPinnedProgramLauncherCommand? _linuxPinnedProgramLauncherCommand(
  HostEnvironment environment,
) {
  final appImage = environment.nonEmptyValue('KONYAK_APPIMAGE_PATH');
  if (appImage != null) {
    return _LinuxPinnedProgramLauncherCommand(
      executable: appImage,
      arguments: const <String>['--konyak-cli'],
      workingDirectory: null,
    );
  }

  final developmentExecutable = environment.nonEmptyValue(
    'KONYAK_PINNED_PROGRAM_LAUNCHER_EXECUTABLE',
  );
  if (developmentExecutable != null) {
    final developmentArguments = _pinnedProgramLauncherArguments(
      environment['KONYAK_PINNED_PROGRAM_LAUNCHER_ARGUMENTS_JSON'],
    );
    if (developmentArguments == null) {
      return null;
    }

    return _LinuxPinnedProgramLauncherCommand(
      executable: developmentExecutable,
      arguments: developmentArguments,
      workingDirectory: environment.nonEmptyValue(
        'KONYAK_PINNED_PROGRAM_LAUNCHER_WORKING_DIRECTORY',
      ),
    );
  }

  final override = environment.nonEmptyValue(
    'KONYAK_PINNED_PROGRAM_LAUNCHER_CLI',
  );
  if (override != null) {
    return _LinuxPinnedProgramLauncherCommand(
      executable: override,
      arguments: const <String>[],
      workingDirectory: null,
    );
  }

  final bundleResources = environment.nonEmptyValue('KONYAK_BUNDLE_RESOURCES');
  if (bundleResources == null) {
    return null;
  }

  final cliExecutable = _joinPath(bundleResources, const ['konyak-cli']);
  if (!File(cliExecutable).existsSync()) {
    return null;
  }

  return _LinuxPinnedProgramLauncherCommand(
    executable: cliExecutable,
    arguments: const <String>[],
    workingDirectory: null,
  );
}

bool _writeLinuxPinnedProgramLauncher({
  required HostEnvironment environment,
  required _LinuxPinnedProgramLauncherCommand launcherCommand,
  required String displayName,
  required String? iconPath,
  required _PinnedProgramLauncherManifest manifest,
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
  var changed = _writeTextFileIfChanged(
    manifestPath,
    jsonEncode(manifest.toJson()),
  );
  changed =
      _writeTextFileIfChanged(
        executablePath,
        _linuxPinnedProgramLauncherScript(launcherCommand),
      ) ||
      changed;
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

  return _writeTextFileIfChanged(
        desktopEntryPath,
        _linuxPinnedProgramDesktopEntry(
          displayName: displayName,
          executablePath: executablePath,
          iconPath: iconPath,
          programPath: manifest.programPath.value,
        ),
      ) ||
      changed;
}

bool _deleteStaleLinuxPinnedProgramLaunchers({
  required HostEnvironment environment,
  required Set<String> desiredLauncherIds,
}) {
  var changed = false;
  final applicationsDirectory = Directory(_linuxApplicationsHome(environment));
  if (applicationsDirectory.existsSync()) {
    for (final entity in applicationsDirectory.listSync(followLinks: false)) {
      if (entity is! File ||
          !_isLinuxPinnedProgramDesktopEntryPath(entity.path)) {
        continue;
      }

      final launcherId = _linuxPinnedProgramLauncherIdFromDesktopEntryPath(
        entity.path,
      );
      if (launcherId == null || desiredLauncherIds.contains(launcherId)) {
        continue;
      }
      entity.deleteSync();
      changed = true;
    }
  }

  final launcherRoot = Directory(_linuxPinnedProgramLauncherRoot(environment));
  if (!launcherRoot.existsSync()) {
    return changed;
  }

  for (final entity in launcherRoot.listSync(followLinks: false)) {
    if (entity is! Directory) {
      continue;
    }

    final launcherId = _baseName(entity.path);
    if (desiredLauncherIds.contains(launcherId)) {
      continue;
    }

    final manifest = _readPinnedProgramLauncherManifest(
      _joinPath(entity.path, const [_linuxPinnedLauncherManifestFileName]),
    );
    if (manifest.isNone()) {
      continue;
    }
    entity.deleteSync(recursive: true);
    changed = true;
  }

  return changed;
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
  final workingDirectory = command.workingDirectory;
  final changeDirectory = workingDirectory == null
      ? ''
      : 'cd ${_posixShellSingleQuote(workingDirectory)}\n';
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
