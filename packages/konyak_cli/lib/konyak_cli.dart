import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:args/args.dart';
import 'package:crypto/crypto.dart';

part 'src/cli_commands.dart';
part 'src/cli_handlers.dart';
part 'src/cli_parsers.dart';
part 'src/cli_results.dart';
part 'src/models.dart';
part 'src/program_discovery.dart';
part 'src/platform_io.dart';
part 'src/program_metadata.dart';
part 'src/program_settings.dart';
part 'src/program_runner.dart';
part 'src/repositories.dart';
part 'src/runtime_installation.dart';
part 'src/runtime_support.dart';
part 'src/wine_run_requests.dart';
part 'src/runtime_validation.dart';
part 'src/updates.dart';
part 'src/runtimes.dart';

ProgramSettingsRecord _readProgramSettingsJson(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    return const ProgramSettingsRecord();
  }

  final decoded = jsonDecode(file.readAsStringSync());
  final settings = ProgramSettingsRecord.fromJson(decoded);
  if (settings == null) {
    throw const FormatException('Program settings contain an invalid record.');
  }

  return settings;
}

void _writeProgramSettingsJson({
  required String path,
  required ProgramSettingsRecord settings,
}) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(settings.toJson()),
  );
}

String _programSettingsJsonPath({
  required BottleRecord bottle,
  required String programPath,
}) {
  return _joinPath(bottle.path, [
    'program-settings',
    _programSettingsFileName(programPath, extension: 'json'),
  ]);
}

String _programSettingsFileName(
  String programPath, {
  required String extension,
}) {
  final normalized = programPath.trim().replaceAll(RegExp(r'[\\/]+$'), '');
  final lastSlash = normalized.lastIndexOf('/');
  final lastBackslash = normalized.lastIndexOf(r'\');
  final separator = max(lastSlash, lastBackslash);
  final rawName = separator == -1
      ? normalized
      : normalized.substring(separator + 1);
  final safeName = rawName.replaceAll(RegExp(r'[/\\:]'), '_').trim();
  if (safeName.isEmpty) {
    throw const BottleRepositoryException(
      'Program path cannot form a settings file name.',
    );
  }

  return '$safeName.$extension';
}

String _programSettingsKey({
  required String bottleId,
  required String programPath,
}) {
  return '$bottleId:${_normalizeFilesystemPath(programPath)}';
}

String _appSettingsJsonPath(String configHome) {
  return _joinPath(configHome, const ['settings.json']);
}

BottleRecord _readBottleMetadata(String bottlePath) {
  final metadata = File(_joinPath(bottlePath, const ['metadata.json']));
  final decoded = jsonDecode(metadata.readAsStringSync());

  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Bottle metadata must be an object.');
  }

  if (decoded['schemaVersion'] != cliSchemaVersion) {
    throw const FormatException('Unsupported bottle metadata schema version.');
  }

  final bottle = BottleRecord.fromJson(decoded['bottle']);
  if (bottle == null) {
    throw const FormatException('Bottle metadata contains an invalid record.');
  }

  return bottle;
}

void _writeBottleMetadata(BottleRecord bottle) {
  final metadata = File(_joinPath(bottle.path, const ['metadata.json']));
  metadata.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(<String, Object?>{
      'schemaVersion': cliSchemaVersion,
      'bottle': bottle.toJson(),
    }),
  );
}

BottleRecord _bottleFromCreateRequest(
  BottleCreateRequest request,
  String dataHome, {
  String? bottleDirectory,
}) {
  final id = _bottleIdFromName(request.name);
  if (id.isEmpty) {
    throw const BottleRepositoryException('Bottle name cannot form an id.');
  }

  final directory = bottleDirectory ?? _joinPath(dataHome, const ['bottles']);
  return BottleRecord(
    id: id,
    name: request.name,
    path: _joinPath(directory, [id]),
    windowsVersion: request.windowsVersion,
  );
}

BottleRecord _renamedMemoryBottle({
  required BottleRecord bottle,
  required String name,
  required String dataHome,
}) {
  return _renamedFileBottle(bottle: bottle, name: name, dataHome: dataHome);
}

BottleRecord _renamedFileBottle({
  required BottleRecord bottle,
  required String name,
  required String dataHome,
  String? bottleDirectory,
}) {
  final id = _bottleIdFromName(name);
  if (id.isEmpty) {
    throw const BottleRepositoryException('Bottle name cannot form an id.');
  }

  final directory = bottleDirectory ?? _joinPath(dataHome, const ['bottles']);
  return bottle.copyWith(id: id, name: name, path: _joinPath(directory, [id]));
}

final _bottleIdLetterOrNumber = RegExp(r'[\p{L}\p{N}]', unicode: true);

String _bottleIdFromName(String name) {
  final buffer = StringBuffer();
  var lastWasSeparator = false;

  for (final rune in name.trim().toLowerCase().runes) {
    final character = String.fromCharCode(rune);
    if (_bottleIdLetterOrNumber.hasMatch(character)) {
      buffer.write(character);
      lastWasSeparator = false;
    } else if (buffer.isNotEmpty && !lastWasSeparator) {
      buffer.write('-');
      lastWasSeparator = true;
    }
  }

  final id = buffer.toString();
  return id.endsWith('-') ? id.substring(0, id.length - 1) : id;
}

String _resolveDataHome(Map<String, String> environment) {
  final override = environment['KONYAK_DATA_HOME'];
  if (override != null && override.trim().isNotEmpty) {
    return override;
  }

  final xdgDataHome = environment['XDG_DATA_HOME'];
  if (xdgDataHome != null && xdgDataHome.trim().isNotEmpty) {
    return _joinPath(xdgDataHome, const ['konyak']);
  }

  final home = environment['HOME'];
  if (home != null && home.trim().isNotEmpty) {
    return _joinPath(home, const ['.local', 'share', 'konyak']);
  }

  throw const BottleRepositoryException(
    'Unable to resolve Konyak data directory.',
  );
}

String _resolveBottleDataHome(
  Map<String, String> environment, {
  required KonyakHostPlatform hostPlatform,
}) {
  final override = environment['KONYAK_DATA_HOME'];
  if (override != null && override.trim().isNotEmpty) {
    return override;
  }

  return switch (hostPlatform) {
    KonyakHostPlatform.macos => _konyakApplicationSupportFolder(environment),
    KonyakHostPlatform.linux => _resolveDataHome(environment),
  };
}

void _recordExternalProgramRun({
  required BottleRecord bottle,
  required ProgramRunRequest request,
}) {
  final normalizedProgramPath = request.programPath.trim();
  if (normalizedProgramPath.isEmpty ||
      !normalizedProgramPath.startsWith('/') ||
      _isPathWithinRoot(path: normalizedProgramPath, root: bottle.path)) {
    return;
  }

  _recordExternalProgramLaunch(
    bottle: bottle,
    programPath: normalizedProgramPath,
  );
}

void _synchronizeLinuxDesktopLauncherForProgramRun({
  required KonyakHostPlatform hostPlatform,
  required Map<String, String> environment,
  required BottleRecord bottle,
  required ProgramRunRequest request,
  ProgramMetadataExtractor programMetadataExtractor =
      const DartIoProgramMetadataExtractor(),
}) {
  if (hostPlatform != KonyakHostPlatform.linux ||
      request.runnerKind != 'wine') {
    return;
  }

  final normalizedProgramPath = request.programPath.trim();
  if (normalizedProgramPath.isEmpty ||
      !normalizedProgramPath.startsWith('/') ||
      _isPathWithinRoot(path: normalizedProgramPath, root: bottle.path)) {
    return;
  }

  try {
    _recordExternalProgramLaunch(
      bottle: bottle,
      programPath: normalizedProgramPath,
    );
    final launcherPath = _linuxExternalProgramLauncherPath(
      environment: environment,
      bottleId: bottle.id,
      programPath: normalizedProgramPath,
    );
    final metadata = programMetadataExtractor.extract(
      bottle: bottle,
      programPath: _metadataProgramPath(
        bottle: bottle,
        programPath: normalizedProgramPath,
      ),
    );
    final launcherName = metadata?.productName?.trim().isNotEmpty == true
        ? metadata!.productName!.trim()
        : metadata?.fileDescription?.trim().isNotEmpty == true
        ? metadata!.fileDescription!.trim()
        : _baseName(normalizedProgramPath);
    final launcherDirectory = File(launcherPath).parent
      ..createSync(recursive: true);
    final launcherContents = _linuxExternalProgramDesktopEntry(
      bottle: bottle,
      request: request,
      launcherName: launcherName,
      iconPath: metadata?.iconPath,
    );
    File(_joinPath(launcherDirectory.path, [_baseName(launcherPath)]))
      ..createSync(recursive: true)
      ..writeAsStringSync(launcherContents);
  } on FileSystemException {
    return;
  } on BottleRepositoryException {
    return;
  } on StateError {
    return;
  }
}

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

void _recordExternalProgramLaunch({
  required BottleRecord bottle,
  required String programPath,
}) {
  try {
    final launchIndexFile = File(
      _joinPath(bottle.path, const ['cache', 'external-program-launches.json']),
    );
    final entry = <String, Object?>{
      'programPath': programPath,
      'executableName': _normalizedExecutableName(programPath),
    };

    final existingEntries = <Map<String, Object?>>[];
    if (launchIndexFile.existsSync()) {
      final decoded =
          jsonDecode(launchIndexFile.readAsStringSync())
              as Map<String, Object?>;
      if (decoded['schemaVersion'] == 1) {
        final launches = decoded['launches'];
        if (launches is List<Object?>) {
          for (final launch in launches) {
            if (launch is Map<String, Object?>) {
              final existingProgramPath = launch['programPath'];
              final existingExecutableName = launch['executableName'];
              if (existingProgramPath is! String ||
                  existingExecutableName is! String) {
                continue;
              }

              if (_normalizeFilesystemPath(existingProgramPath) ==
                      _normalizeFilesystemPath(programPath) &&
                  _normalizedExecutableName(existingExecutableName) ==
                      entry['executableName']) {
                continue;
              }

              existingEntries.add(<String, Object?>{
                'programPath': existingProgramPath,
                'executableName': existingExecutableName,
              });
            }
          }
        }
      }
    }

    final launches = <Map<String, Object?>>[...existingEntries.take(31), entry];
    launchIndexFile.parent.createSync(recursive: true);
    launchIndexFile.writeAsStringSync(
      jsonEncode({'schemaVersion': 1, 'launches': launches}),
    );
  } on FileSystemException {
    return;
  } on FormatException {
    return;
  } on TypeError {
    return;
  }
}

String _linuxExternalProgramLauncherPath({
  required Map<String, String> environment,
  required String bottleId,
  required String programPath,
}) {
  final digest = sha1.convert(utf8.encode('$bottleId:$programPath')).toString();
  return _joinPath(_linuxApplicationsHome(environment), <String>[
    'konyak',
    'konyak-$bottleId-${digest.substring(0, 12)}.desktop',
  ]);
}

String _linuxExternalProgramDesktopEntry({
  required BottleRecord bottle,
  required ProgramRunRequest request,
  required String launcherName,
  required String? iconPath,
}) {
  final lines = <String>[
    '[Desktop Entry]',
    'Type=Application',
    'Name=$launcherName',
    'Exec=${_linuxDesktopEntryExec(request: request, bottle: bottle)}',
    'NoDisplay=true',
    'StartupNotify=true',
    'StartupWMClass=${_normalizedExecutableName(request.programPath)}',
    'Path=${_parentDirectory(request.programPath) ?? bottle.path}',
  ];

  if (iconPath != null && iconPath.trim().isNotEmpty) {
    lines.add('Icon=$iconPath');
  }

  return '${lines.join('\n')}\n';
}

String _linuxDesktopEntryExec({
  required ProgramRunRequest request,
  required BottleRecord bottle,
}) {
  final arguments = request.arguments.map(_desktopEntryQuote).join(' ');
  final buffer = StringBuffer(
    'env "WINEPREFIX=${bottle.path}" ${request.executable}',
  );
  if (arguments.isNotEmpty) {
    buffer.write(' ');
    buffer.write(arguments);
  }

  return buffer.toString();
}

String _desktopEntryQuote(String value) {
  final escaped = value.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
  return '"$escaped"';
}

String _linuxApplicationsHome(Map<String, String> environment) {
  final xdgDataHome = environment['XDG_DATA_HOME'];
  if (xdgDataHome != null && xdgDataHome.trim().isNotEmpty) {
    return _joinPath(xdgDataHome, const <String>['applications']);
  }

  final home = environment['HOME'];
  if (home != null && home.trim().isNotEmpty) {
    return _joinPath(home, const <String>['.local', 'share', 'applications']);
  }

  throw const BottleRepositoryException(
    'Unable to resolve Linux applications directory.',
  );
}

const _linuxKonyakDesktopEntryId = 'app.konyak.Konyak.desktop';
const _linuxExecutableMimeTypes = <String>[
  'application/x-ms-dos-executable',
  'application/x-msdownload',
  'application/vnd.microsoft.portable-executable',
  'application/x-msi',
  'application/x-ms-installer',
  'application/x-ms-shortcut',
  'application/x-msdos-program',
  'text/x-msdos-batch',
];

sealed class _LinuxFileAssociationInstallResult {
  const _LinuxFileAssociationInstallResult();
}

final class _LinuxFileAssociationsInstalled
    extends _LinuxFileAssociationInstallResult {
  const _LinuxFileAssociationsInstalled({
    required this.desktopEntryPath,
    required this.mimeAppsPath,
  });

  final String desktopEntryPath;
  final String mimeAppsPath;
}

final class _LinuxFileAssociationInstallFailed
    extends _LinuxFileAssociationInstallResult {
  const _LinuxFileAssociationInstallFailed(this.message);

  final String message;
}

_LinuxFileAssociationInstallResult _installLinuxFileAssociations({
  required KonyakHostPlatform hostPlatform,
  required Map<String, String> environment,
}) {
  if (hostPlatform != KonyakHostPlatform.linux &&
      environment['KONYAK_FORCE_LINUX_FILE_ASSOCIATIONS'] != '1') {
    return const _LinuxFileAssociationInstallFailed(
      'Linux file associations are supported on Linux only.',
    );
  }

  final appExecutable = _linuxFileAssociationAppExecutable(environment);
  if (appExecutable == null) {
    return const _LinuxFileAssociationInstallFailed(
      'Unable to resolve the Konyak application executable.',
    );
  }

  try {
    final desktopEntryPath = _joinPath(_linuxApplicationsHome(environment), [
      _linuxKonyakDesktopEntryId,
    ]);
    final mimeAppsPath = _linuxMimeAppsPath(environment);

    final desktopEntry = File(desktopEntryPath);
    desktopEntry.parent.createSync(recursive: true);
    desktopEntry.writeAsStringSync(
      _linuxKonyakDesktopEntry(appExecutable: appExecutable),
    );

    final mimeApps = File(mimeAppsPath);
    mimeApps.parent.createSync(recursive: true);
    mimeApps.writeAsStringSync(
      _linuxMimeAppsWithKonyakDefaults(
        existing: mimeApps.existsSync() ? mimeApps.readAsStringSync() : '',
      ),
    );

    return _LinuxFileAssociationsInstalled(
      desktopEntryPath: desktopEntryPath,
      mimeAppsPath: mimeAppsPath,
    );
  } on FileSystemException catch (error) {
    return _LinuxFileAssociationInstallFailed(error.message);
  } on BottleRepositoryException catch (error) {
    return _LinuxFileAssociationInstallFailed(error.message);
  }
}

String? _linuxFileAssociationAppExecutable(Map<String, String> environment) {
  for (final key in const <String>[
    'KONYAK_APPIMAGE_PATH',
    'KONYAK_APP_EXECUTABLE',
  ]) {
    final value = environment[key];
    if (value != null && value.trim().isNotEmpty) {
      return value.trim();
    }
  }

  return null;
}

String _linuxKonyakDesktopEntry({required String appExecutable}) {
  final mimeTypes = '${_linuxExecutableMimeTypes.join(';')};';
  return <String>[
    '[Desktop Entry]',
    'Version=1.0',
    'Type=Application',
    'Name=Konyak',
    'Comment=Run Windows executables with Konyak.',
    'Exec=${_desktopEntryQuote(appExecutable)} %f',
    'Icon=app.konyak.Konyak',
    'StartupWMClass=app.konyak.Konyak',
    'Terminal=false',
    'Categories=Utility;',
    'MimeType=$mimeTypes',
    'StartupNotify=true',
    '',
  ].join('\n');
}

String _linuxMimeAppsPath(Map<String, String> environment) {
  final xdgConfigHome = environment['XDG_CONFIG_HOME'];
  if (xdgConfigHome != null && xdgConfigHome.trim().isNotEmpty) {
    return _joinPath(xdgConfigHome, const ['mimeapps.list']);
  }

  final home = environment['HOME'];
  if (home != null && home.trim().isNotEmpty) {
    return _joinPath(home, const ['.config', 'mimeapps.list']);
  }

  throw const BottleRepositoryException(
    'Unable to resolve Linux MIME applications file.',
  );
}

String _linuxMimeAppsWithKonyakDefaults({required String existing}) {
  final lines = existing.split('\n');
  final output = <String>[];
  var inDefaultApplications = false;
  var wroteDefaultApplications = false;
  final pendingMimeTypes = <String>{..._linuxExecutableMimeTypes};

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      if (inDefaultApplications) {
        _appendLinuxMimeDefaults(output, pendingMimeTypes);
      }
      inDefaultApplications = trimmed == '[Default Applications]';
      wroteDefaultApplications |= inDefaultApplications;
      output.add(line);
      continue;
    }

    if (inDefaultApplications) {
      final separator = line.indexOf('=');
      if (separator > 0) {
        final mimeType = line.substring(0, separator).trim();
        if (pendingMimeTypes.remove(mimeType)) {
          output.add('$mimeType=$_linuxKonyakDesktopEntryId');
          continue;
        }
      }
    }

    if (line.isNotEmpty || output.isNotEmpty) {
      output.add(line);
    }
  }

  if (inDefaultApplications) {
    _appendLinuxMimeDefaults(output, pendingMimeTypes);
  } else {
    if (output.isNotEmpty && output.last.isNotEmpty) {
      output.add('');
    }
    output.add('[Default Applications]');
    _appendLinuxMimeDefaults(output, pendingMimeTypes);
  }

  if (!wroteDefaultApplications && output.first == '') {
    output.removeAt(0);
  }

  return '${output.join('\n').replaceAll(RegExp(r'\n+$'), '')}\n';
}

void _appendLinuxMimeDefaults(
  List<String> output,
  Set<String> pendingMimeTypes,
) {
  for (final mimeType in _linuxExecutableMimeTypes) {
    if (pendingMimeTypes.remove(mimeType)) {
      output.add('$mimeType=$_linuxKonyakDesktopEntryId');
    }
  }
}

bool _isPathWithinRoot({required String path, required String root}) {
  final normalizedPath = path.replaceAll('\\', '/');
  final normalizedRoot = root
      .replaceAll('\\', '/')
      .replaceAll(RegExp(r'/+$'), '');
  return normalizedPath == normalizedRoot ||
      normalizedPath.startsWith('$normalizedRoot/');
}

String? _parentDirectory(String path) {
  final normalized = path.replaceAll('\\', '/').replaceAll(RegExp(r'/+$'), '');
  final index = normalized.lastIndexOf('/');
  if (index <= 0) {
    return index == 0 ? '/' : null;
  }

  return normalized.substring(0, index);
}

String _resolveConfigHome(
  Map<String, String> environment, {
  required KonyakHostPlatform hostPlatform,
}) {
  final override = environment['KONYAK_CONFIG_HOME'];
  if (override != null && override.trim().isNotEmpty) {
    return override;
  }

  switch (hostPlatform) {
    case KonyakHostPlatform.macos:
      final home = environment['HOME'];
      if (home != null && home.trim().isNotEmpty) {
        return _joinPath(home, const [
          'Library',
          'Application Support',
          'Konyak',
        ]);
      }
    case KonyakHostPlatform.linux:
      final xdgConfigHome = environment['XDG_CONFIG_HOME'];
      if (xdgConfigHome != null && xdgConfigHome.trim().isNotEmpty) {
        return _joinPath(xdgConfigHome, const ['konyak']);
      }

      final home = environment['HOME'];
      if (home != null && home.trim().isNotEmpty) {
        return _joinPath(home, const ['.config', 'konyak']);
      }
  }

  throw const AppSettingsRepositoryException(
    'Unable to resolve Konyak config directory.',
  );
}

String _defaultBottlePath(
  Map<String, String> environment, {
  required KonyakHostPlatform hostPlatform,
}) {
  final override = environment['KONYAK_DEFAULT_BOTTLE_PATH'];
  if (override != null && override.trim().isNotEmpty) {
    return override;
  }

  final dataHome = _nonEmptyEnvironmentValue(environment, 'KONYAK_DATA_HOME');
  if (dataHome != null) {
    return _joinPath(dataHome, const ['bottles']);
  }

  return switch (hostPlatform) {
    KonyakHostPlatform.macos => _joinPath(
      _resolveBottleDataHome(environment, hostPlatform: hostPlatform),
      const ['Bottles'],
    ),
    KonyakHostPlatform.linux => _joinPath(_resolveDataHome(environment), const [
      'bottles',
    ]),
  };
}

bool _hasBottleAtPath(
  Iterable<BottleRecord> bottles,
  String path, {
  required String exceptId,
}) {
  final normalizedPath = _normalizeFilesystemPath(path);
  return bottles.any(
    (bottle) =>
        bottle.id != exceptId &&
        _normalizeFilesystemPath(bottle.path) == normalizedPath,
  );
}

bool _hasPinnedProgram(BottleRecord bottle, String programPath) {
  final normalizedProgramPath = _normalizeFilesystemPath(programPath);
  return bottle.pinnedPrograms.any(
    (program) => _isPinnedProgramPath(program, normalizedProgramPath),
  );
}

bool _isPinnedProgramPath(PinnedProgramRecord program, String normalizedPath) {
  return _normalizeFilesystemPath(program.path) == normalizedPath;
}

BottleRecord _bottleWithPinnedProgram(
  BottleRecord bottle,
  ProgramPinRequest request, {
  required ProgramMetadataExtractor programMetadataExtractor,
}) {
  final metadata = programMetadataExtractor.extract(
    bottle: bottle,
    programPath: _metadataProgramPath(
      bottle: bottle,
      programPath: request.programPath,
    ),
  );

  return bottle.copyWith(
    pinnedPrograms: <PinnedProgramRecord>[
      ...bottle.pinnedPrograms,
      PinnedProgramRecord(
        name: request.name,
        path: request.programPath,
        iconPath: metadata?.iconPath,
      ),
    ],
  );
}

BottleRecord _bottleWithPinnedProgramIcons(
  BottleRecord bottle, {
  required ProgramMetadataExtractor programMetadataExtractor,
}) {
  var changed = false;
  final pinnedPrograms = bottle.pinnedPrograms
      .map((program) {
        final existingIconPath = program.iconPath;
        if (existingIconPath != null && existingIconPath.trim().isNotEmpty) {
          return program;
        }

        final metadata = programMetadataExtractor.extract(
          bottle: bottle,
          programPath: _metadataProgramPath(
            bottle: bottle,
            programPath: program.path,
          ),
        );
        final iconPath = metadata?.iconPath;
        if (iconPath == null || iconPath.trim().isEmpty) {
          return program;
        }

        changed = true;
        return program.copyWith(iconPath: iconPath);
      })
      .toList(growable: false);

  if (!changed) {
    return bottle;
  }

  return bottle.copyWith(pinnedPrograms: pinnedPrograms);
}

BottleRecord _bottleWithoutPinnedProgram(
  BottleRecord bottle,
  String programPath,
) {
  final normalizedProgramPath = _normalizeFilesystemPath(programPath);
  return bottle.copyWith(
    pinnedPrograms: bottle.pinnedPrograms
        .where(
          (program) => !_isPinnedProgramPath(program, normalizedProgramPath),
        )
        .toList(growable: false),
  );
}

BottleRecord _bottleWithRenamedPinnedProgram(
  BottleRecord bottle,
  ProgramRenameRequest request,
) {
  final normalizedProgramPath = _normalizeFilesystemPath(request.programPath);
  return bottle.copyWith(
    pinnedPrograms: bottle.pinnedPrograms
        .map(
          (program) => _isPinnedProgramPath(program, normalizedProgramPath)
              ? program.copyWith(name: request.name)
              : program,
        )
        .toList(growable: false),
  );
}

String _normalizeFilesystemPath(String path) {
  return path.trim().replaceAll(RegExp(r'/+$'), '');
}

void _moveDirectory({required String from, required String to}) {
  final source = Directory(from);
  if (!source.existsSync()) {
    throw FileSystemException('Bottle directory was not found.', from);
  }

  final destination = Directory(to);
  destination.parent.createSync(recursive: true);

  try {
    source.renameSync(destination.path);
  } on FileSystemException {
    _copyDirectory(source: source, destination: destination);
    source.deleteSync(recursive: true);
  }
}

BottleArchiveExportResult _exportBottleArchive({
  required BottleRecord bottle,
  required String archivePath,
}) {
  final normalizedBottlePath = _normalizeFilesystemPath(bottle.path);
  final bottleDirectory = Directory(normalizedBottlePath);
  if (!bottleDirectory.existsSync()) {
    return BottleArchiveExportFailed('Bottle directory was not found.');
  }

  try {
    final normalizedArchivePath = _normalizeFilesystemPath(archivePath);
    if (normalizedArchivePath == normalizedBottlePath ||
        normalizedArchivePath.startsWith('$normalizedBottlePath/')) {
      return BottleArchiveExportFailed(
        'Bottle archive path must be outside the bottle directory.',
      );
    }

    final archive = File(archivePath);
    archive.parent.createSync(recursive: true);
    final result = Process.runSync('tar', [
      '-cf',
      archive.path,
      '-C',
      _dirname(normalizedBottlePath),
      _basename(normalizedBottlePath),
    ], runInShell: false);
    if (result.exitCode != 0) {
      return BottleArchiveExportFailed(
        _commandFailureMessage('export bottle archive', result),
      );
    }
  } on FileSystemException catch (error) {
    return BottleArchiveExportFailed(error.message);
  } on ProcessException catch (error) {
    return BottleArchiveExportFailed(error.message);
  }

  return BottleArchiveExported(
    BottleArchiveRecord(bottleId: bottle.id, archivePath: archivePath),
  );
}

BottleArchiveImportResult _importBottleArchive({
  required String archivePath,
  required String bottleDirectory,
  required bool Function(String bottleId) hasBottle,
  void Function(BottleRecord bottle)? onImported,
}) {
  final archive = File(archivePath);
  if (!archive.existsSync()) {
    return BottleArchiveImportFailed('Bottle archive was not found.');
  }

  final listing = _validatedBottleArchiveListing(archivePath);
  switch (listing) {
    case _InvalidBottleArchiveListing(:final message):
      return BottleArchiveImportFailed(message);
    case _ValidBottleArchiveListing():
      break;
  }

  final tempDirectory = Directory.systemTemp.createTempSync(
    'konyak-bottle-import-',
  );
  try {
    final extraction = Process.runSync('tar', [
      '-xf',
      archivePath,
      '-C',
      tempDirectory.path,
    ], runInShell: false);
    if (extraction.exitCode != 0) {
      return BottleArchiveImportFailed(
        _commandFailureMessage('import bottle archive', extraction),
      );
    }

    final extractedBottlePath = _joinPath(tempDirectory.path, [
      listing.topLevelDirectory,
    ]);
    final extractedBottleDirectory = Directory(extractedBottlePath);
    if (!extractedBottleDirectory.existsSync()) {
      return const BottleArchiveImportFailed(
        'Bottle archive does not contain a bottle directory.',
      );
    }

    final imported = _readBottleMetadata(extractedBottlePath);
    if (!_isValidBottleArchiveId(imported.id)) {
      return const BottleArchiveImportFailed(
        'Bottle archive metadata contains an invalid bottle id.',
      );
    }
    if (hasBottle(imported.id)) {
      return BottleArchiveImportConflict(imported.id);
    }

    final destinationPath = _joinPath(bottleDirectory, [imported.id]);
    if (Directory(destinationPath).existsSync()) {
      return BottleArchiveImportConflict(imported.id);
    }

    final relocated = imported.copyWith(path: destinationPath);
    _moveDirectory(from: extractedBottlePath, to: destinationPath);
    _writeBottleMetadata(relocated);
    onImported?.call(relocated);

    return BottleArchiveImported(relocated);
  } on FileSystemException catch (error) {
    return BottleArchiveImportFailed(error.message);
  } on FormatException catch (error) {
    return BottleArchiveImportFailed(error.message);
  } on ProcessException catch (error) {
    return BottleArchiveImportFailed(error.message);
  } finally {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  }
}

sealed class _BottleArchiveListing {
  const _BottleArchiveListing();
}

final class _ValidBottleArchiveListing extends _BottleArchiveListing {
  const _ValidBottleArchiveListing({required this.topLevelDirectory});

  final String topLevelDirectory;
}

final class _InvalidBottleArchiveListing extends _BottleArchiveListing {
  const _InvalidBottleArchiveListing(this.message);

  final String message;
}

_BottleArchiveListing _validatedBottleArchiveListing(String archivePath) {
  final result = Process.runSync('tar', [
    '-tf',
    archivePath,
  ], runInShell: false);
  if (result.exitCode != 0) {
    return _InvalidBottleArchiveListing(
      _commandFailureMessage('inspect bottle archive', result),
    );
  }

  final entries = _processOutputToString(result.stdout)
      .split('\n')
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toList(growable: false);
  if (entries.isEmpty) {
    return const _InvalidBottleArchiveListing('Bottle archive is empty.');
  }

  final topLevelDirectories = <String>{};
  var hasMetadata = false;
  for (final entry in entries) {
    if (!_isSafeArchiveEntryPath(entry)) {
      return const _InvalidBottleArchiveListing(
        'Bottle archive contains an unsafe path.',
      );
    }

    final segments = entry
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);
    topLevelDirectories.add(segments.first);
    if (segments.length == 2 && segments.last == 'metadata.json') {
      hasMetadata = true;
    }
  }

  if (topLevelDirectories.length != 1) {
    return const _InvalidBottleArchiveListing(
      'Bottle archive must contain exactly one bottle directory.',
    );
  }
  if (!hasMetadata) {
    return const _InvalidBottleArchiveListing(
      'Bottle archive does not contain bottle metadata.',
    );
  }

  return _ValidBottleArchiveListing(
    topLevelDirectory: topLevelDirectories.single,
  );
}

bool _isSafeArchiveEntryPath(String path) {
  if (path.startsWith('/') ||
      path.startsWith(r'\') ||
      path.contains('\u0000')) {
    return false;
  }
  if (path.contains(r'\')) {
    return false;
  }

  final segments = path.split('/').where((segment) => segment.isNotEmpty);
  var hasSegment = false;
  for (final segment in segments) {
    hasSegment = true;
    if (segment == '.' || segment == '..') {
      return false;
    }
  }

  return hasSegment;
}

bool _isValidBottleArchiveId(String id) {
  return id.isNotEmpty &&
      !id.contains('/') &&
      !id.contains(r'\') &&
      id != '.' &&
      id != '..';
}

void _copyDirectory({
  required Directory source,
  required Directory destination,
}) {
  if (destination.existsSync()) {
    throw FileSystemException(
      'Destination directory already exists.',
      destination.path,
    );
  }

  destination.createSync(recursive: true);
  for (final entity in source.listSync(followLinks: false)) {
    final targetPath = _joinPath(destination.path, [_baseName(entity.path)]);
    if (entity is Directory) {
      _copyDirectory(source: entity, destination: Directory(targetPath));
    } else if (entity is File) {
      entity.copySync(targetPath);
    } else if (entity is Link) {
      Link(targetPath).createSync(entity.targetSync());
    }
  }
}

void _copyDirectoryContentsReplacing({
  required Directory source,
  required Directory destination,
  List<List<String>> skipRelativePaths = const <List<String>>[],
}) {
  destination.createSync(recursive: true);
  _copyDirectoryEntriesReplacing(
    source: source,
    destination: destination,
    relativePath: const <String>[],
    skipRelativePaths: skipRelativePaths,
  );
}

void _copyDirectoryEntriesReplacing({
  required Directory source,
  required Directory destination,
  required List<String> relativePath,
  required List<List<String>> skipRelativePaths,
}) {
  for (final entity in source.listSync(followLinks: false)) {
    final name = _baseName(entity.path);
    final entityRelativePath = <String>[...relativePath, name];
    if (_isSkippedRelativePath(entityRelativePath, skipRelativePaths)) {
      continue;
    }
    final targetPath = _joinPath(destination.path, [name]);
    if (entity is Directory) {
      final targetType = FileSystemEntity.typeSync(targetPath);
      if (targetType != FileSystemEntityType.notFound &&
          targetType != FileSystemEntityType.directory) {
        _deleteFileSystemEntitySync(targetPath, targetType);
      }
      final targetDirectory = Directory(targetPath)
        ..createSync(recursive: true);
      _copyDirectoryEntriesReplacing(
        source: entity,
        destination: targetDirectory,
        relativePath: entityRelativePath,
        skipRelativePaths: skipRelativePaths,
      );
    } else if (entity is File) {
      final targetType = FileSystemEntity.typeSync(targetPath);
      if (targetType == FileSystemEntityType.directory) {
        Directory(targetPath).deleteSync(recursive: true);
      }
      entity.copySync(targetPath);
    } else if (entity is Link) {
      final targetType = FileSystemEntity.typeSync(targetPath);
      if (targetType != FileSystemEntityType.notFound) {
        _deleteFileSystemEntitySync(targetPath, targetType);
      }
      Link(targetPath).createSync(entity.targetSync());
    }
  }
}

void _deleteFileSystemEntitySync(String path, FileSystemEntityType type) {
  if (type == FileSystemEntityType.directory) {
    Directory(path).deleteSync(recursive: true);
  } else if (type == FileSystemEntityType.link) {
    Link(path).deleteSync();
  } else {
    File(path).deleteSync();
  }
}

bool _isSkippedRelativePath(
  List<String> relativePath,
  List<List<String>> skipRelativePaths,
) {
  for (final skipped in skipRelativePaths) {
    if (relativePath.length < skipped.length) {
      continue;
    }
    var matches = true;
    for (var index = 0; index < skipped.length; index += 1) {
      if (relativePath[index] != skipped[index]) {
        matches = false;
        break;
      }
    }
    if (matches) {
      return true;
    }
  }
  return false;
}

String? _nonEmptyEnvironmentValue(Map<String, String> environment, String key) {
  final value = environment[key];
  if (value == null || value.trim().isEmpty) {
    return null;
  }

  return value;
}

String? _runtimeProfileEnvironmentValue(
  Map<String, String> environment, {
  required String developmentKey,
  required String releaseKey,
}) {
  if (_isDevelopmentRuntimeProfile(environment)) {
    return _nonEmptyEnvironmentValue(environment, developmentKey);
  }

  return _nonEmptyEnvironmentValue(environment, releaseKey);
}

String _runtimeDistributionKind(
  Map<String, String> environment,
  String defaultKind,
) {
  if (_isDevelopmentRuntimeProfile(environment)) {
    return 'development';
  }

  return defaultKind;
}

bool _isDevelopmentRuntimeProfile(Map<String, String> environment) {
  return _nonEmptyEnvironmentValue(environment, 'KONYAK_RUNTIME_PROFILE') ==
      'development';
}

Map<String, Object?>? _objectMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value.cast<String, Object?>();
  }

  if (value is Map<String, Object?>) {
    return value;
  }

  return null;
}

String _baseName(String path) {
  final normalized = path.replaceAll(RegExp(r'/+$'), '');
  final index = normalized.lastIndexOf('/');
  if (index == -1) {
    return normalized;
  }

  return normalized.substring(index + 1);
}

CliResult _jsonSuccess(Map<String, Object?> payload, {int exitCode = 0}) {
  return CliResult(
    exitCode: exitCode,
    stdout: jsonEncode(<String, Object?>{
      'schemaVersion': cliSchemaVersion,
      ...payload,
    }),
    stderr: '',
  );
}

CliResult _unavailableJsonError({
  required String code,
  required String subject,
}) {
  return _jsonError(
    exitCode: 74,
    code: code,
    message: '$subject is not configured.',
  );
}

CliResult _jsonError({
  required int exitCode,
  required String code,
  required String message,
  Map<String, Object?> extra = const <String, Object?>{},
}) {
  return CliResult(
    exitCode: exitCode,
    stdout: jsonEncode(<String, Object?>{
      'schemaVersion': cliSchemaVersion,
      'error': <String, Object?>{'code': code, 'message': message, ...extra},
    }),
    stderr: '',
  );
}

CliResult _bottleNotFoundError(String bottleId) {
  return _jsonError(
    exitCode: 66,
    code: 'bottleNotFound',
    message: 'Bottle not found.',
    extra: <String, Object?>{'bottleId': bottleId},
  );
}

CliResult _createdBottleJsonResult({
  required BottleRecord bottle,
  required BottlePrefixInitializer? bottlePrefixInitializer,
}) {
  final initializer = bottlePrefixInitializer;
  if (initializer != null) {
    final initializationResult = initializer.initialize(bottle);
    switch (initializationResult) {
      case BottlePrefixInitialized():
        break;
      case BottlePrefixInitializationFailed(:final message):
        return _jsonError(
          exitCode: 75,
          code: 'bottlePrefixInitializationFailed',
          message: message,
          extra: <String, Object?>{
            'bottleId': bottle.id,
            'bottlePath': bottle.path,
          },
        );
    }
  }

  return _bottleJsonResult(bottle);
}

CliResult _programRunJsonResult({
  required ProgramRunRequest request,
  required int processExitCode,
}) {
  return _jsonSuccess(<String, Object?>{
    'run': <String, Object?>{
      'bottleId': request.bottleId,
      'programPath': request.programPath,
      'runnerKind': request.runnerKind,
      'executable': request.executable,
      'workingDirectory': request.workingDirectory,
      'argv': request.argv,
      'logPath': request.logPath,
      'processExitCode': processExitCode,
    },
  });
}

CliResult _programRunFailedJsonResult({
  required ProgramRunRequest request,
  required String message,
}) {
  return _jsonError(
    exitCode: 75,
    code: 'programRunFailed',
    message: message,
    extra: <String, Object?>{
      'bottleId': request.bottleId,
      'programPath': request.programPath,
      'runnerKind': request.runnerKind,
      'executable': request.executable,
      'workingDirectory': request.workingDirectory,
      'argv': request.argv,
      'logPath': request.logPath,
    },
  );
}

CliResult? _ensureWinetricksScriptForRun({
  required ProgramRunRequest request,
  required WinetricksScriptInstaller scriptInstaller,
}) {
  if (request.runnerKind != 'macosWinetricks') {
    return null;
  }

  final installResult = scriptInstaller.installIfMissing(
    executable: request.executable,
  );
  return switch (installResult) {
    WinetricksScriptInstallCompleted() => null,
    WinetricksScriptInstallFailed(:final message) => _jsonError(
      exitCode: 75,
      code: 'winetricksUnavailable',
      message: message,
    ),
  };
}

String _programRunLog(ProgramRunRequest request, ProcessResult result) {
  final stdout = _processOutputToString(result.stdout);
  final stderr = _processOutputToString(result.stderr);

  return _programRunLogContent(
    request: request,
    processExitCode: result.exitCode,
    stdout: stdout,
    stderr: stderr,
  );
}

String _programRunStartupFailureLog(
  ProgramRunRequest request,
  String startupError,
) {
  return _programRunLogContent(
    request: request,
    startupError: startupError,
    stdout: '',
    stderr: '',
  );
}

String _programRunLogContent({
  required ProgramRunRequest request,
  required String stdout,
  required String stderr,
  int? processExitCode,
  String? startupError,
}) {
  final environmentLines =
      request.environment.entries
          .map((entry) => MapEntry(entry.key, '${entry.key}=${entry.value}'))
          .toList(growable: false)
        ..sort((left, right) => left.key.compareTo(right.key));

  return <String>[
    'Konyak Wine Run Log',
    '',
    '[Process]',
    'Runner Kind: ${request.runnerKind}',
    'Executable: ${request.executable}',
    'Working Directory: ${request.workingDirectory ?? ''}',
    'Arguments: ${jsonEncode(request.arguments)}',
    'argv: ${jsonEncode(request.argv)}',
    if (processExitCode != null) 'Process Exit Code: $processExitCode',
    if (processExitCode != null) 'exitCode: $processExitCode',
    if (startupError != null) 'Startup Error: $startupError',
    '',
    '[Environment]',
    ...environmentLines.map((entry) => entry.value),
    '',
    '[stdout]',
    stdout,
    '',
    '[stderr]',
    stderr,
    '',
  ].join('\n');
}

String _programRunnerFailureMessage({
  required String executable,
  required String message,
}) {
  if (message == 'No such file or directory') {
    return 'Runner executable `$executable` was not found.';
  }

  return message;
}

String _commandFailureMessage(String action, ProcessResult result) {
  final stderr = _processOutputToString(result.stderr).trim();
  final stdout = _processOutputToString(result.stdout).trim();
  final details = stderr.isNotEmpty ? stderr : stdout;

  if (details.isEmpty) {
    return 'Failed to $action with exit code ${result.exitCode}.';
  }

  return 'Failed to $action with exit code ${result.exitCode}: $details';
}

String _processOutputToString(Object? output) {
  if (output == null) {
    return '';
  }

  if (output is String) {
    return output;
  }

  if (output is List<int>) {
    return utf8.decode(output, allowMalformed: true);
  }

  return output.toString();
}

int? _readUint16(Uint8List bytes, int offset) {
  if (offset < 0 || offset + 2 > bytes.length) {
    return null;
  }

  return bytes[offset] | bytes[offset + 1] << 8;
}

int? _readUint32(Uint8List bytes, int offset) {
  if (offset < 0 || offset + 4 > bytes.length) {
    return null;
  }

  return bytes[offset] |
      bytes[offset + 1] << 8 |
      bytes[offset + 2] << 16 |
      bytes[offset + 3] << 24;
}

void _writeUint16(Uint8List bytes, int offset, int value) {
  bytes[offset] = value & 0xff;
  bytes[offset + 1] = value >> 8 & 0xff;
}

void _writeUint32(Uint8List bytes, int offset, int value) {
  bytes[offset] = value & 0xff;
  bytes[offset + 1] = value >> 8 & 0xff;
  bytes[offset + 2] = value >> 16 & 0xff;
  bytes[offset + 3] = value >> 24 & 0xff;
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (identical(left, right)) {
    return true;
  }

  if (left.length != right.length) {
    return false;
  }

  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) {
      return false;
    }
  }

  return true;
}

bool _mapEquals<K, V>(Map<K, V> left, Map<K, V> right) {
  if (identical(left, right)) {
    return true;
  }

  if (left.length != right.length) {
    return false;
  }

  for (final entry in left.entries) {
    if (!right.containsKey(entry.key) || right[entry.key] != entry.value) {
      return false;
    }
  }

  return true;
}

Map<String, String>? _stringMap(Object? value) {
  if (value == null) {
    return const <String, String>{};
  }

  final map = _objectMap(value);
  if (map == null) {
    return null;
  }

  final result = <String, String>{};
  for (final entry in map.entries) {
    if (entry.key.trim().isEmpty ||
        entry.key.contains('=') ||
        entry.value is! String) {
      return null;
    }
    result[entry.key] = entry.value as String;
  }

  return Map.unmodifiable(result);
}

String _joinPath(String root, Iterable<String> components) {
  var path = root;
  for (final component in components) {
    final normalized = component.replaceAll(RegExp(r'^/+|/+$'), '');
    path = path.endsWith('/') ? '$path$normalized' : '$path/$normalized';
  }

  return path;
}
