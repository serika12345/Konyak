part of '../konyak_cli.dart';

bool _isJsonBottleListCommand(List<String> arguments) {
  return _isJsonFlagOnlyCommand(arguments, 'list-bottles');
}

String? _parseJsonBottleInspectCommand(List<String> arguments) {
  final results = _parseJsonCliCommand(arguments, command: 'inspect-bottle');
  if (results == null || !_hasRestCount(results, 1)) {
    return null;
  }

  return _requiredCliRest(results);
}

String? _parseJsonBottleProgramsListCommand(List<String> arguments) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'list-bottle-programs',
  );
  if (results == null || !_hasRestCount(results, 1)) {
    return null;
  }

  return _requiredCliRest(results);
}

bool _isJsonWinetricksVerbListCommand(List<String> arguments) {
  return _isJsonFlagOnlyCommand(arguments, 'list-winetricks-verbs');
}

BottleCreateRequest? _parseJsonBottleCreateRequest(List<String> arguments) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'create-bottle',
    options: const <String>['name', 'windows-version'],
  );
  if (results == null || !_hasRestCount(results, 0)) {
    return null;
  }

  final name = _requiredCliOption(results, 'name');
  if (name == null) {
    return null;
  }

  final windowsVersion = _optionalCliOption(results, 'windows-version');
  if (windowsVersion == null) {
    if (results.wasParsed('windows-version')) {
      return null;
    }
    return BottleCreateRequest(name: name, windowsVersion: 'win10');
  }

  return BottleCreateRequest(name: name, windowsVersion: windowsVersion);
}

BottleArchiveExportRequest? _parseJsonBottleArchiveExportRequest(
  List<String> arguments,
) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'export-bottle-archive',
    options: const <String>['archive'],
  );
  if (results == null || !_hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = _requiredCliRest(results);
  final archivePath = _requiredCliOption(results, 'archive');
  if (bottleId == null || archivePath == null) {
    return null;
  }

  return BottleArchiveExportRequest(
    bottleId: bottleId,
    archivePath: archivePath,
  );
}

BottleArchiveImportRequest? _parseJsonBottleArchiveImportRequest(
  List<String> arguments,
) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'import-bottle-archive',
    options: const <String>['archive'],
  );
  if (results == null || !_hasRestCount(results, 0)) {
    return null;
  }

  final archivePath = _requiredCliOption(results, 'archive');
  if (archivePath == null) {
    return null;
  }

  return BottleArchiveImportRequest(archivePath: archivePath);
}

String? _parseJsonBottleDeleteCommand(List<String> arguments) {
  final results = _parseJsonCliCommand(arguments, command: 'delete-bottle');
  if (results == null || !_hasRestCount(results, 1)) {
    return null;
  }

  return _requiredCliRest(results);
}

BottleRenameRequest? _parseJsonBottleRenameRequest(List<String> arguments) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'rename-bottle',
    options: const <String>['name'],
  );
  if (results == null || !_hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = _requiredCliRest(results);
  final name = _requiredCliOption(results, 'name');
  if (bottleId == null || name == null) {
    return null;
  }

  return BottleRenameRequest(bottleId: bottleId, name: name);
}

BottleMoveRequest? _parseJsonBottleMoveRequest(List<String> arguments) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'move-bottle',
    options: const <String>['path'],
  );
  if (results == null || !_hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = _requiredCliRest(results);
  final path = _requiredCliOption(results, 'path');
  if (bottleId == null || path == null) {
    return null;
  }

  return BottleMoveRequest(bottleId: bottleId, path: path);
}

WindowsVersionUpdateRequest? _parseJsonWindowsVersionUpdateRequest(
  List<String> arguments,
) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'set-windows-version',
    options: const <String>['windows-version'],
  );
  if (results == null || !_hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = _requiredCliRest(results);
  final windowsVersion = _requiredCliOption(results, 'windows-version');
  if (bottleId == null || windowsVersion == null) {
    return null;
  }

  return WindowsVersionUpdateRequest(
    bottleId: bottleId,
    windowsVersion: windowsVersion,
  );
}

RuntimeSettingsUpdateRequest? _parseJsonRuntimeSettingsUpdateRequest(
  List<String> arguments,
) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'set-runtime-settings',
    options: const <String>['settings-json'],
  );
  if (results == null || !_hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = _requiredCliRest(results);
  final settingsJson = _requiredCliOption(results, 'settings-json');
  if (bottleId == null || settingsJson == null) {
    return null;
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(settingsJson);
  } on FormatException {
    return null;
  }

  return _bottleRuntimeSettingsFromJson(decoded).match(
    () => null,
    (runtimeSettings) => RuntimeSettingsUpdateRequest(
      bottleId: bottleId,
      runtimeSettings: runtimeSettings,
    ),
  );
}
