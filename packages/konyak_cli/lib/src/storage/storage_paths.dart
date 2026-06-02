part of '../../konyak_cli.dart';

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
  return bottle.withIdentity(
    id: id,
    name: name,
    path: _joinPath(directory, [id]),
  );
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

String _resolveDataHome(HostEnvironment environment) {
  final override = environment.nonEmptyValue('KONYAK_DATA_HOME');
  if (override != null) {
    return override;
  }

  final xdgDataHome = environment.nonEmptyValue('XDG_DATA_HOME');
  if (xdgDataHome != null) {
    return _joinPath(xdgDataHome, const ['konyak']);
  }

  final home = environment.nonEmptyValue('HOME');
  if (home != null) {
    return _joinPath(home, const ['.local', 'share', 'konyak']);
  }

  throw const BottleRepositoryException(
    'Unable to resolve Konyak data directory.',
  );
}

String _resolveBottleDataHome(
  HostEnvironment environment, {
  required KonyakHostPlatform hostPlatform,
}) {
  final override = environment.nonEmptyValue('KONYAK_DATA_HOME');
  if (override != null) {
    return override;
  }

  return switch (hostPlatform) {
    KonyakHostPlatform.macos => _konyakApplicationSupportFolder(environment),
    KonyakHostPlatform.linux => _resolveDataHome(environment),
  };
}

String _resolveConfigHome(
  HostEnvironment environment, {
  required KonyakHostPlatform hostPlatform,
}) {
  final override = environment.nonEmptyValue('KONYAK_CONFIG_HOME');
  if (override != null) {
    return override;
  }

  switch (hostPlatform) {
    case KonyakHostPlatform.macos:
      final home = environment.nonEmptyValue('HOME');
      if (home != null) {
        return _joinPath(home, const [
          'Library',
          'Application Support',
          'Konyak',
        ]);
      }
    case KonyakHostPlatform.linux:
      final xdgConfigHome = environment.nonEmptyValue('XDG_CONFIG_HOME');
      if (xdgConfigHome != null) {
        return _joinPath(xdgConfigHome, const ['konyak']);
      }

      final home = environment.nonEmptyValue('HOME');
      if (home != null) {
        return _joinPath(home, const ['.config', 'konyak']);
      }
  }

  throw const AppSettingsRepositoryException(
    'Unable to resolve Konyak config directory.',
  );
}

String _defaultBottlePath(
  HostEnvironment environment, {
  required KonyakHostPlatform hostPlatform,
}) {
  final override = environment.nonEmptyValue('KONYAK_DEFAULT_BOTTLE_PATH');
  if (override != null) {
    return override;
  }

  final dataHome = environment.nonEmptyValue('KONYAK_DATA_HOME');
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
