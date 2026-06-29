import 'dart:convert';

import '../domain/bottle/bottle_mutation_models.dart';
import '../domain/shared/domain_value_objects.dart';
import '../io/repository_storage_io.dart';
import 'cli_parsers.dart';
import 'cli_value_object_parsers.dart';

bool isJsonBottleListCommand(List<String> arguments) {
  return isJsonFlagOnlyCommand(arguments, 'list-bottles');
}

BottleId? parseJsonBottleInspectCommand(List<String> arguments) {
  final results = parseJsonCliCommand(arguments, command: 'inspect-bottle');
  if (results == null || !hasRestCount(results, 1)) {
    return null;
  }

  return requiredCliBottleId(results);
}

BottleId? parseJsonBottleProgramsListCommand(List<String> arguments) {
  final results = parseJsonCliCommand(
    arguments,
    command: 'list-bottle-programs',
  );
  if (results == null || !hasRestCount(results, 1)) {
    return null;
  }

  return requiredCliBottleId(results);
}

bool isJsonWinetricksVerbListCommand(List<String> arguments) {
  return isJsonFlagOnlyCommand(arguments, 'list-winetricks-verbs');
}

BottleCreateRequest? parseJsonBottleCreateRequest(List<String> arguments) {
  final results = parseJsonCliCommand(
    arguments,
    command: 'create-bottle',
    options: const <String>['name', 'windows-version'],
  );
  if (results == null || !hasRestCount(results, 0)) {
    return null;
  }

  final name = requiredCliOption(results, 'name');
  if (name == null) {
    return null;
  }

  final windowsVersion = optionalCliOption(results, 'windows-version');
  if (windowsVersion == null) {
    if (results.wasParsed('windows-version')) {
      return null;
    }
    return BottleCreateRequest(
      name: BottleName(name),
      windowsVersion: WindowsVersion('win10'),
    );
  }

  return BottleCreateRequest(
    name: BottleName(name),
    windowsVersion: WindowsVersion(windowsVersion),
  );
}

BottleArchiveExportRequest? parseJsonBottleArchiveExportRequest(
  List<String> arguments,
) {
  final results = parseJsonCliCommand(
    arguments,
    command: 'export-bottle-archive',
    options: const <String>['archive'],
  );
  if (results == null || !hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = requiredCliRest(results);
  final archivePath = requiredCliOption(results, 'archive');
  if (bottleId == null || archivePath == null) {
    return null;
  }

  return BottleArchiveExportRequest(
    bottleId: BottleId(bottleId),
    archivePath: BottleArchivePath(archivePath),
  );
}

BottleArchiveImportRequest? parseJsonBottleArchiveImportRequest(
  List<String> arguments,
) {
  final results = parseJsonCliCommand(
    arguments,
    command: 'import-bottle-archive',
    options: const <String>['archive'],
  );
  if (results == null || !hasRestCount(results, 0)) {
    return null;
  }

  final archivePath = requiredCliOption(results, 'archive');
  if (archivePath == null) {
    return null;
  }

  return BottleArchiveImportRequest(
    archivePath: BottleArchivePath(archivePath),
  );
}

BottleId? parseJsonBottleDeleteCommand(List<String> arguments) {
  final results = parseJsonCliCommand(arguments, command: 'delete-bottle');
  if (results == null || !hasRestCount(results, 1)) {
    return null;
  }

  return requiredCliBottleId(results);
}

BottleRenameRequest? parseJsonBottleRenameRequest(List<String> arguments) {
  final results = parseJsonCliCommand(
    arguments,
    command: 'rename-bottle',
    options: const <String>['name'],
  );
  if (results == null || !hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = requiredCliRest(results);
  final name = requiredCliOption(results, 'name');
  if (bottleId == null || name == null) {
    return null;
  }

  return BottleRenameRequest(
    bottleId: BottleId(bottleId),
    name: BottleName(name),
  );
}

BottleMoveRequest? parseJsonBottleMoveRequest(List<String> arguments) {
  final results = parseJsonCliCommand(
    arguments,
    command: 'move-bottle',
    options: const <String>['path'],
  );
  if (results == null || !hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = requiredCliRest(results);
  final path = requiredCliOption(results, 'path');
  if (bottleId == null || path == null) {
    return null;
  }

  return BottleMoveRequest(
    bottleId: BottleId(bottleId),
    path: BottlePath(path),
  );
}

WindowsVersionUpdateRequest? parseJsonWindowsVersionUpdateRequest(
  List<String> arguments,
) {
  final results = parseJsonCliCommand(
    arguments,
    command: 'set-windows-version',
    options: const <String>['windows-version'],
  );
  if (results == null || !hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = requiredCliRest(results);
  final windowsVersion = requiredCliOption(results, 'windows-version');
  if (bottleId == null || windowsVersion == null) {
    return null;
  }

  return WindowsVersionUpdateRequest(
    bottleId: BottleId(bottleId),
    windowsVersion: WindowsVersion(windowsVersion),
  );
}

RuntimeSettingsUpdateRequest? parseJsonRuntimeSettingsUpdateRequest(
  List<String> arguments,
) {
  final results = parseJsonCliCommand(
    arguments,
    command: 'set-runtime-settings',
    options: const <String>['settings-json'],
  );
  if (results == null || !hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = requiredCliRest(results);
  final settingsJson = requiredCliOption(results, 'settings-json');
  if (bottleId == null || settingsJson == null) {
    return null;
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(settingsJson);
  } on FormatException {
    return null;
  }

  return bottleRuntimeSettingsFromJson(decoded)
      .map(
        (runtimeSettings) => RuntimeSettingsUpdateRequest(
          bottleId: BottleId(bottleId),
          runtimeSettings: runtimeSettings,
        ),
      )
      .match(() => null, (value) => value);
}
