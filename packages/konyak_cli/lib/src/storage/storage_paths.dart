part of '../../konyak_cli.dart';

String _programSettingsJsonPath({
  required BottleRecord bottle,
  required String programPath,
}) {
  return _joinPath(bottle.path.value, [
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
  Option<String> bottleDirectory = const Option.none(),
}) {
  final id = _bottleIdFromName(request.name.value);
  if (id.isEmpty) {
    throw const BottleRepositoryException('Bottle name cannot form an id.');
  }

  final directory = bottleDirectory.match(
    () => _joinPath(dataHome, const ['bottles']),
    (value) => value,
  );
  return BottleRecord(
    id: id,
    name: request.name.value,
    path: _joinPath(directory, [id]),
    windowsVersion: request.windowsVersion.value,
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
  Option<String> bottleDirectory = const Option.none(),
}) {
  final id = _bottleIdFromName(name);
  if (id.isEmpty) {
    throw const BottleRepositoryException('Bottle name cannot form an id.');
  }

  final directory = bottleDirectory.match(
    () => _joinPath(dataHome, const ['bottles']),
    (value) => value,
  );
  return bottle.withIdentity(
    id: id,
    name: name,
    path: _joinPath(directory, [id]),
  );
}

final _bottleIdLetterOrNumber = RegExp(r'[\p{L}\p{N}]', unicode: true);

String _bottleIdFromName(String name) {
  final state = name.trim().toLowerCase().runes.fold(
    (id: '', lastWasSeparator: false),
    (state, rune) {
      final character = String.fromCharCode(rune);
      if (_bottleIdLetterOrNumber.hasMatch(character)) {
        return (id: '${state.id}$character', lastWasSeparator: false);
      }

      if (state.id.isNotEmpty && !state.lastWasSeparator) {
        return (id: '${state.id}-', lastWasSeparator: true);
      }

      return state;
    },
  );
  final id = state.id;
  return id.endsWith('-') ? id.substring(0, id.length - 1) : id;
}

String _resolveDataHome(HostEnvironment environment) {
  return environment
      .nonEmptyValue('KONYAK_DATA_HOME')
      .match(
        () => environment
            .nonEmptyValue('XDG_DATA_HOME')
            .match(
              () => environment
                  .nonEmptyValue('HOME')
                  .match(
                    () => throw const BottleRepositoryException(
                      'Unable to resolve Konyak data directory.',
                    ),
                    (home) =>
                        _joinPath(home, const ['.local', 'share', 'konyak']),
                  ),
              (xdgDataHome) => _joinPath(xdgDataHome, const ['konyak']),
            ),
        (override) => override,
      );
}

String _resolveBottleDataHome(
  HostEnvironment environment, {
  required KonyakHostPlatform hostPlatform,
}) {
  return environment
      .nonEmptyValue('KONYAK_DATA_HOME')
      .match(
        () => switch (hostPlatform) {
          KonyakHostPlatform.macos => konyakApplicationSupportFolder(
            environment,
          ),
          KonyakHostPlatform.linux => _resolveDataHome(environment),
        },
        (override) => override,
      );
}

String _resolveConfigHome(
  HostEnvironment environment, {
  required KonyakHostPlatform hostPlatform,
}) {
  return environment
      .nonEmptyValue('KONYAK_CONFIG_HOME')
      .match(
        () => switch (hostPlatform) {
          KonyakHostPlatform.macos =>
            environment
                .nonEmptyValue('HOME')
                .match(
                  () => throw const AppSettingsRepositoryException(
                    'Unable to resolve Konyak config directory.',
                  ),
                  (home) => _joinPath(home, const [
                    'Library',
                    'Application Support',
                    'Konyak',
                  ]),
                ),
          KonyakHostPlatform.linux =>
            environment
                .nonEmptyValue('XDG_CONFIG_HOME')
                .match(
                  () => environment
                      .nonEmptyValue('HOME')
                      .match(
                        () => throw const AppSettingsRepositoryException(
                          'Unable to resolve Konyak config directory.',
                        ),
                        (home) => _joinPath(home, const ['.config', 'konyak']),
                      ),
                  (xdgConfigHome) => _joinPath(xdgConfigHome, const ['konyak']),
                ),
        },
        (override) => override,
      );
}

String _defaultBottlePath(
  HostEnvironment environment, {
  required KonyakHostPlatform hostPlatform,
}) {
  return environment
      .nonEmptyValue('KONYAK_DEFAULT_BOTTLE_PATH')
      .match(
        () => environment
            .nonEmptyValue('KONYAK_DATA_HOME')
            .match(
              () => switch (hostPlatform) {
                KonyakHostPlatform.macos => _joinPath(
                  _resolveBottleDataHome(
                    environment,
                    hostPlatform: hostPlatform,
                  ),
                  const ['Bottles'],
                ),
                KonyakHostPlatform.linux => _joinPath(
                  _resolveDataHome(environment),
                  const ['bottles'],
                ),
              },
              (dataHome) => _joinPath(dataHome, const ['bottles']),
            ),
        (override) => override,
      );
}

bool _hasBottleAtPath(
  Iterable<BottleRecord> bottles,
  String path, {
  required String exceptId,
}) {
  final normalizedPath = _normalizeFilesystemPath(path);
  return bottles.any(
    (bottle) =>
        bottle.id.value != exceptId &&
        _normalizeFilesystemPath(bottle.path.value) == normalizedPath,
  );
}
