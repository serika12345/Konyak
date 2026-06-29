import 'dart:convert';

import '../domain/program/program_mutation_models.dart';
import '../domain/shared/domain_value_objects.dart';
import '../io/repository_storage_io.dart';
import 'cli_parsers.dart';

ProgramPinRequest? parseJsonProgramPinRequest(List<String> arguments) {
  final results = parseJsonCliCommand(
    arguments,
    command: 'pin-program',
    options: const <String>['name', 'program'],
  );
  if (results == null || !hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = requiredCliRest(results);
  final name = requiredCliOption(results, 'name');
  final programPath = requiredCliOption(results, 'program');
  if (bottleId == null || name == null || programPath == null) {
    return null;
  }

  return ProgramPinRequest(
    bottleId: BottleId(bottleId),
    name: ProgramName(name),
    programPath: ProgramPath(programPath),
  );
}

ProgramUnpinRequest? parseJsonProgramUnpinRequest(List<String> arguments) {
  final results = parseJsonCliCommand(
    arguments,
    command: 'unpin-program',
    options: const <String>['program'],
  );
  if (results == null || !hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = requiredCliRest(results);
  final programPath = requiredCliOption(results, 'program');
  if (bottleId == null || programPath == null) {
    return null;
  }

  return ProgramUnpinRequest(
    bottleId: BottleId(bottleId),
    programPath: ProgramPath(programPath),
  );
}

ProgramRenameRequest? parseJsonProgramRenameRequest(List<String> arguments) {
  final results = parseJsonCliCommand(
    arguments,
    command: 'rename-pinned-program',
    options: const <String>['program', 'name'],
  );
  if (results == null || !hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = requiredCliRest(results);
  final programPath = requiredCliOption(results, 'program');
  final name = requiredCliOption(results, 'name');
  if (bottleId == null || programPath == null || name == null) {
    return null;
  }

  return ProgramRenameRequest(
    bottleId: BottleId(bottleId),
    programPath: ProgramPath(programPath),
    name: ProgramName(name),
  );
}

ProgramSettingsRequest? parseJsonProgramSettingsRequest(
  List<String> arguments,
) {
  final results = parseJsonCliCommand(
    arguments,
    command: 'get-program-settings',
    options: const <String>['program'],
  );
  if (results == null || !hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = requiredCliRest(results);
  final programPath = requiredCliOption(results, 'program');
  if (bottleId == null || programPath == null) {
    return null;
  }

  return ProgramSettingsRequest(
    bottleId: BottleId(bottleId),
    programPath: ProgramPath(programPath),
  );
}

ProgramSettingsUpdateRequest? parseJsonProgramSettingsUpdateRequest(
  List<String> arguments,
) {
  final results = parseJsonCliCommand(
    arguments,
    command: 'set-program-settings',
    options: const <String>['program', 'settings-json'],
  );
  if (results == null || !hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = requiredCliRest(results);
  final programPath = requiredCliOption(results, 'program');
  final settingsJson = requiredCliOption(results, 'settings-json');
  if (bottleId == null || programPath == null || settingsJson == null) {
    return null;
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(settingsJson);
  } on FormatException {
    return null;
  }

  return programSettingsRecordFromJson(decoded)
      .map(
        (settings) => ProgramSettingsUpdateRequest(
          bottleId: BottleId(bottleId),
          programPath: ProgramPath(programPath),
          settings: settings,
        ),
      )
      .match(() => null, (value) => value);
}

class PinnedProgramLaunchCliRequest {
  const PinnedProgramLaunchCliRequest({required this.manifestPath});

  final String manifestPath;
}

PinnedProgramLaunchCliRequest? parseJsonPinnedProgramLaunchCliRequest(
  List<String> arguments,
) {
  final results = parseJsonCliCommand(
    arguments,
    command: 'launch-pinned-program',
    options: const <String>['manifest'],
  );
  if (results == null || !hasRestCount(results, 0)) {
    return null;
  }

  final manifestPath = requiredCliOption(results, 'manifest');
  if (manifestPath == null) {
    return null;
  }

  return PinnedProgramLaunchCliRequest(manifestPath: manifestPath);
}
