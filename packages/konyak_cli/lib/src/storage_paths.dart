part of '../konyak_cli.dart';

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
