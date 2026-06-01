part of '../konyak_cli.dart';

const _macosPinnedLauncherManifestFileName = 'konyak-launcher.json';
const _macosPinnedLauncherExecutableName = 'konyak-launcher';

class _MacosPinnedProgramLauncherCommand {
  const _MacosPinnedProgramLauncherCommand({
    required this.executable,
    required this.arguments,
    required this.workingDirectory,
  });

  final String executable;
  final List<String> arguments;
  final String? workingDirectory;
}

void _synchronizeMacosPinnedProgramLaunchers({
  required KonyakHostPlatform hostPlatform,
  required Map<String, String> environment,
  required List<BottleRecord> bottles,
}) {
  if (hostPlatform != KonyakHostPlatform.macos) {
    return;
  }

  final launcherHome = _macosPinnedProgramLaunchersHome(environment);
  final launcherCommand = _macosPinnedProgramLauncherCommand(environment);
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
          iconPath: program.iconPath,
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

String? _macosPinnedProgramLaunchersHome(Map<String, String> environment) {
  final override = environment['KONYAK_MACOS_PINNED_LAUNCHERS_HOME'];
  if (override != null && override.trim().isNotEmpty) {
    return override.trim();
  }

  final home = environment['HOME'];
  if (home == null || home.trim().isEmpty) {
    return null;
  }

  return _joinPath(home.trim(), const ['Applications', 'Konyak']);
}

_MacosPinnedProgramLauncherCommand? _macosPinnedProgramLauncherCommand(
  Map<String, String> environment,
) {
  final developmentExecutable =
      environment['KONYAK_PINNED_PROGRAM_LAUNCHER_EXECUTABLE'];
  if (developmentExecutable != null &&
      developmentExecutable.trim().isNotEmpty) {
    final developmentArguments = _macosPinnedProgramLauncherArguments(
      environment['KONYAK_PINNED_PROGRAM_LAUNCHER_ARGUMENTS_JSON'],
    );
    if (developmentArguments == null) {
      return null;
    }

    final workingDirectory =
        environment['KONYAK_PINNED_PROGRAM_LAUNCHER_WORKING_DIRECTORY'];
    return _MacosPinnedProgramLauncherCommand(
      executable: developmentExecutable.trim(),
      arguments: developmentArguments,
      workingDirectory:
          workingDirectory == null || workingDirectory.trim().isEmpty
          ? null
          : workingDirectory.trim(),
    );
  }

  final override = environment['KONYAK_PINNED_PROGRAM_LAUNCHER_CLI'];
  if (override != null && override.trim().isNotEmpty) {
    return _MacosPinnedProgramLauncherCommand(
      executable: override.trim(),
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

List<String>? _macosPinnedProgramLauncherArguments(String? value) {
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

void _writeMacosPinnedProgramLauncher({
  required String bundlePath,
  required _MacosPinnedProgramLauncherCommand launcherCommand,
  required String displayName,
  required String? iconPath,
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

  Directory(macosPath).createSync(recursive: true);
  Directory(resourcesPath).createSync(recursive: true);
  final iconFileName = _writeMacosPinnedProgramLauncherIcon(
    resourcesPath: resourcesPath,
    iconPath: iconPath,
  );
  File(_joinPath(contentsPath, const ['Info.plist'])).writeAsStringSync(
    _macosPinnedProgramInfoPlist(
      manifest: manifest,
      displayName: displayName,
      iconFileName: iconFileName,
    ),
  );
  File(manifestPath).writeAsStringSync(jsonEncode(manifest.toJson()));
  File(
    executablePath,
  ).writeAsStringSync(_macosPinnedProgramLauncherScript(launcherCommand));
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
}

String _macosPinnedProgramInfoPlist({
  required _PinnedProgramLauncherManifest manifest,
  required String displayName,
  required String? iconFileName,
}) {
  final bundleIdentifier =
      '$konyakMacosBundleIdentifier.pinned.${manifest.launcherId}';
  final iconPlistEntry = iconFileName == null
      ? ''
      : '''
  <key>CFBundleIconFile</key>
  <string>${_xmlEscape(iconFileName)}</string>
''';

  return '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleDisplayName</key>
  <string>${_xmlEscape(displayName)}</string>
  <key>CFBundleExecutable</key>
  <string>$_macosPinnedLauncherExecutableName</string>
$iconPlistEntry
  <key>CFBundleIdentifier</key>
  <string>${_xmlEscape(bundleIdentifier)}</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>${_xmlEscape(displayName)}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$konyakAppVersion</string>
  <key>CFBundleVersion</key>
  <string>1</string>
</dict>
</plist>
''';
}

String _macosLauncherDisplayName(String name) {
  final normalized = name.trim();
  return normalized.isEmpty ? 'Konyak Program' : normalized;
}

String _uniqueMacosLauncherDisplayName(
  String name, {
  required Set<String> usedDisplayNames,
  required Set<String> usedBundleNames,
}) {
  final baseName = _macosLauncherDisplayName(name);
  var index = 1;

  while (true) {
    final displayName = index == 1 ? baseName : '$baseName ($index)';
    final displayKey = displayName.toLowerCase();
    final bundleName = _macosLauncherBundleName(displayName);
    final bundleKey = bundleName.toLowerCase();
    if (!usedDisplayNames.contains(displayKey) &&
        !usedBundleNames.contains(bundleKey)) {
      usedDisplayNames.add(displayKey);
      usedBundleNames.add(bundleKey);
      return displayName;
    }

    index += 1;
  }
}

String _macosLauncherBundleName(String displayName) {
  return '${_macosLauncherBundleBaseName(displayName)}.app';
}

String _macosLauncherBundleBaseName(String displayName) {
  final safeName = displayName
      .replaceAll(RegExp(r'[/\\:]'), '-')
      .replaceAll(RegExp(r'[\u0000-\u001f]'), '')
      .trim();
  return safeName.isEmpty ? 'Konyak Program' : safeName;
}

String _macosPinnedProgramLauncherScript(
  _MacosPinnedProgramLauncherCommand command,
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
manifest_dir=\$(CDPATH= cd -- "\$(dirname -- "\$0")/../Resources" && pwd -P)
manifest="\$manifest_dir/$_macosPinnedLauncherManifestFileName"
${changeDirectory}exec $launcherCommand
''';
}

void _deleteStaleMacosPinnedProgramLaunchers({
  required String launcherHome,
  required Set<String> desiredLauncherIds,
  required Map<String, String> desiredLauncherPaths,
}) {
  final launcherDirectory = Directory(launcherHome);
  if (!launcherDirectory.existsSync()) {
    return;
  }

  for (final entity in launcherDirectory.listSync(followLinks: false)) {
    if (entity is! Directory || !entity.path.endsWith('.app')) {
      continue;
    }

    final manifest = _readPinnedProgramLauncherManifest(
      _joinPath(entity.path, const [
        'Contents',
        'Resources',
        _macosPinnedLauncherManifestFileName,
      ]),
    );
    final desiredPath = manifest == null
        ? null
        : desiredLauncherPaths[manifest.launcherId];
    if (manifest == null ||
        (desiredLauncherIds.contains(manifest.launcherId) &&
            desiredPath == _normalizeFilesystemPath(entity.path))) {
      continue;
    }

    entity.deleteSync(recursive: true);
  }
}

Set<String> _unmanagedMacosLauncherBundleNames(String launcherHome) {
  final launcherDirectory = Directory(launcherHome);
  if (!launcherDirectory.existsSync()) {
    return <String>{};
  }

  final bundleNames = <String>{};
  for (final entity in launcherDirectory.listSync(followLinks: false)) {
    if (entity is! Directory || !entity.path.endsWith('.app')) {
      continue;
    }

    final manifest = _readPinnedProgramLauncherManifest(
      _joinPath(entity.path, const [
        'Contents',
        'Resources',
        _macosPinnedLauncherManifestFileName,
      ]),
    );
    if (manifest == null) {
      bundleNames.add(_baseName(entity.path).toLowerCase());
    }
  }

  return bundleNames;
}

const _macosPinnedLauncherIconFileName = 'KonyakPinnedProgram.icns';

String? _writeMacosPinnedProgramLauncherIcon({
  required String resourcesPath,
  required String? iconPath,
}) {
  final sourcePath = iconPath?.trim();
  if (sourcePath == null || sourcePath.isEmpty) {
    return null;
  }

  final source = File(sourcePath);
  if (!source.existsSync()) {
    return null;
  }

  if (sourcePath.toLowerCase().endsWith('.icns')) {
    source.copySync(
      _joinPath(resourcesPath, const [_macosPinnedLauncherIconFileName]),
    );
    return _macosPinnedLauncherIconFileName;
  }

  final convertedIcon = _convertMacosLauncherIconToIcns(
    sourcePath: sourcePath,
    resourcesPath: resourcesPath,
  );
  if (convertedIcon != null) {
    return convertedIcon;
  }

  final fallbackFileName = _macosPinnedLauncherFallbackIconFileName(sourcePath);
  source.copySync(_joinPath(resourcesPath, [fallbackFileName]));
  return fallbackFileName;
}

String? _convertMacosLauncherIconToIcns({
  required String sourcePath,
  required String resourcesPath,
}) {
  final workDirectory = Directory(
    _joinPath(resourcesPath, const ['KonyakPinnedProgramIconWork']),
  );
  final iconset = Directory(
    _joinPath(workDirectory.path, const ['KonyakPinnedProgram.iconset']),
  );
  final sourcePngPath = _joinPath(workDirectory.path, const ['source.png']);
  final icnsPath = _joinPath(resourcesPath, const [
    _macosPinnedLauncherIconFileName,
  ]);

  try {
    if (workDirectory.existsSync()) {
      workDirectory.deleteSync(recursive: true);
    }
    iconset.createSync(recursive: true);

    final convertResult = Process.runSync('sips', <String>[
      '-s',
      'format',
      'png',
      sourcePath,
      '--out',
      sourcePngPath,
    ], runInShell: false);
    if (convertResult.exitCode != 0 || !File(sourcePngPath).existsSync()) {
      return null;
    }

    for (final size in const <int>[16, 32, 128, 256, 512]) {
      final resized = _joinPath(iconset.path, ['icon_${size}x$size.png']);
      final resized2x = _joinPath(iconset.path, ['icon_${size}x$size@2x.png']);
      final resizeResult = Process.runSync('sips', <String>[
        '-z',
        '$size',
        '$size',
        sourcePngPath,
        '--out',
        resized,
      ], runInShell: false);
      final resize2xResult = Process.runSync('sips', <String>[
        '-z',
        '${size * 2}',
        '${size * 2}',
        sourcePngPath,
        '--out',
        resized2x,
      ], runInShell: false);
      if (resizeResult.exitCode != 0 || resize2xResult.exitCode != 0) {
        return null;
      }
    }

    final iconutilResult = Process.runSync('iconutil', <String>[
      '-c',
      'icns',
      iconset.path,
      '-o',
      icnsPath,
    ], runInShell: false);
    if (iconutilResult.exitCode != 0 || !File(icnsPath).existsSync()) {
      return null;
    }

    return _macosPinnedLauncherIconFileName;
  } on FileSystemException {
    return null;
  } on ProcessException {
    return null;
  } finally {
    if (workDirectory.existsSync()) {
      workDirectory.deleteSync(recursive: true);
    }
  }
}

String _macosPinnedLauncherFallbackIconFileName(String sourcePath) {
  final baseName = _baseName(sourcePath);
  final extensionStart = baseName.lastIndexOf('.');
  final extension = extensionStart == -1
      ? ''
      : baseName.substring(extensionStart).toLowerCase();
  if (extension.isEmpty || !RegExp(r'^\.[a-z0-9]+$').hasMatch(extension)) {
    return 'KonyakPinnedProgramIcon';
  }

  return 'KonyakPinnedProgram$extension';
}

_PinnedProgramLauncherManifest? _readPinnedProgramLauncherManifest(
  String manifestPath,
) {
  try {
    final decoded = jsonDecode(File(manifestPath).readAsStringSync());
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final schemaVersion = decoded['schemaVersion'];
    final createdBy = decoded['createdBy'];
    final launcherId = decoded['launcherId'];
    final bottleId = decoded['bottleId'];
    final programPath = decoded['programPath'];
    final programName = decoded['programName'];
    if (schemaVersion != cliSchemaVersion ||
        createdBy != konyakMacosBundleIdentifier ||
        launcherId is! String ||
        launcherId.trim().isEmpty ||
        bottleId is! String ||
        bottleId.trim().isEmpty ||
        programPath is! String ||
        programPath.trim().isEmpty ||
        programName is! String ||
        programName.trim().isEmpty) {
      return null;
    }

    return _PinnedProgramLauncherManifest(
      launcherId: launcherId,
      bottleId: bottleId,
      programPath: programPath,
      programName: programName,
    );
  } on FileSystemException {
    return null;
  } on FormatException {
    return null;
  }
}

String _xmlEscape(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}

String _posixShellSingleQuote(String value) {
  return "'${value.replaceAll("'", "'\\''")}'";
}
