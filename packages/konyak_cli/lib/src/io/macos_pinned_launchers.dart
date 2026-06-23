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
  final String? workingDirectory;
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

  final launcherHome = _macosPinnedProgramLaunchersHome(hostEnvironment);
  final launcherCommand = _macosPinnedProgramLauncherCommand(hostEnvironment);
  if (launcherHome == null || launcherCommand == null) {
    return;
  }

  try {
    final desiredLauncherIds = <String>{};
    final desiredLauncherPaths = <String, String>{};
    final usedDisplayNames = <String>{};
    final usedBundleNames = _unmanagedMacosLauncherBundleNames(launcherHome);
    for (final bottle in bottles) {
      for (final program in bottle.pinnedPrograms) {
        final launcherId = _pinnedProgramLauncherId(
          bottleId: bottle.id,
          programPath: program.path,
        );
        final displayName = _uniqueMacosLauncherDisplayName(
          program.name,
          usedDisplayNames: usedDisplayNames,
          usedBundleNames: usedBundleNames,
        );
        final bundlePath = _joinPath(launcherHome, [
          _macosLauncherBundleName(displayName),
        ]);
        desiredLauncherIds.add(launcherId);
        desiredLauncherPaths[launcherId] = _normalizeFilesystemPath(bundlePath);
        _writeMacosPinnedProgramLauncher(
          bundlePath: bundlePath,
          launcherCommand: launcherCommand,
          displayName: displayName,
          iconPath: program.iconPath.toNullable(),
          manifest: _PinnedProgramLauncherManifest(
            launcherId: launcherId,
            bottleId: bottle.id,
            programPath: program.path,
            programName: program.name,
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
}

String? _macosPinnedProgramLaunchersHome(HostEnvironment environment) {
  final override = environment.nonEmptyValue(
    'KONYAK_MACOS_PINNED_LAUNCHERS_HOME',
  );
  if (override != null) {
    return override;
  }

  final home = environment.nonEmptyValue('HOME');
  if (home == null) {
    return null;
  }

  return _joinPath(home, const ['Applications', 'Konyak']);
}

_MacosPinnedProgramLauncherCommand? _macosPinnedProgramLauncherCommand(
  HostEnvironment environment,
) {
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

    final workingDirectory = environment.nonEmptyValue(
      'KONYAK_PINNED_PROGRAM_LAUNCHER_WORKING_DIRECTORY',
    );
    return _MacosPinnedProgramLauncherCommand(
      executable: developmentExecutable,
      arguments: developmentArguments,
      workingDirectory: workingDirectory,
    );
  }

  final override = environment.nonEmptyValue(
    'KONYAK_PINNED_PROGRAM_LAUNCHER_CLI',
  );
  if (override != null) {
    return _MacosPinnedProgramLauncherCommand(
      executable: override,
      arguments: const <String>[],
      workingDirectory: null,
    );
  }

  final bundlePath = _macosAppBundlePath(environment);
  if (bundlePath == null) {
    return null;
  }

  final cliExecutable = _joinPath(bundlePath, const [
    'Contents',
    'Resources',
    'konyak-cli',
  ]);
  if (!File(cliExecutable).existsSync()) {
    return null;
  }

  return _MacosPinnedProgramLauncherCommand(
    executable: cliExecutable,
    arguments: const <String>[],
    workingDirectory: null,
  );
}

List<String>? _pinnedProgramLauncherArguments(String? value) {
  if (value == null || value.trim().isEmpty) {
    return const <String>[];
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(value);
  } on FormatException {
    return null;
  }

  if (decoded is! List<Object?>) {
    return null;
  }

  final arguments = <String>[];
  for (final argument in decoded) {
    if (argument is! String) {
      return null;
    }
    arguments.add(argument);
  }

  return List.unmodifiable(arguments);
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
  required _PinnedProgramLauncherManifest manifest,
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
