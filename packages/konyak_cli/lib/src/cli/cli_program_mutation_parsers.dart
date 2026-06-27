part of '../../konyak_cli.dart';

ProgramPinRequest? _parseJsonProgramPinRequest(List<String> arguments) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'pin-program',
    options: const <String>['name', 'program'],
  );
  if (results == null || !_hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = _requiredCliRest(results);
  final name = _requiredCliOption(results, 'name');
  final programPath = _requiredCliOption(results, 'program');
  if (bottleId == null || name == null || programPath == null) {
    return null;
  }

  return ProgramPinRequest(
    bottleId: bottleId,
    name: name,
    programPath: programPath,
  );
}

ProgramUnpinRequest? _parseJsonProgramUnpinRequest(List<String> arguments) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'unpin-program',
    options: const <String>['program'],
  );
  if (results == null || !_hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = _requiredCliRest(results);
  final programPath = _requiredCliOption(results, 'program');
  if (bottleId == null || programPath == null) {
    return null;
  }

  return ProgramUnpinRequest(bottleId: bottleId, programPath: programPath);
}

ProgramRenameRequest? _parseJsonProgramRenameRequest(List<String> arguments) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'rename-pinned-program',
    options: const <String>['program', 'name'],
  );
  if (results == null || !_hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = _requiredCliRest(results);
  final programPath = _requiredCliOption(results, 'program');
  final name = _requiredCliOption(results, 'name');
  if (bottleId == null || programPath == null || name == null) {
    return null;
  }

  return ProgramRenameRequest(
    bottleId: bottleId,
    programPath: programPath,
    name: name,
  );
}

ProgramSettingsRequest? _parseJsonProgramSettingsRequest(
  List<String> arguments,
) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'get-program-settings',
    options: const <String>['program'],
  );
  if (results == null || !_hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = _requiredCliRest(results);
  final programPath = _requiredCliOption(results, 'program');
  if (bottleId == null || programPath == null) {
    return null;
  }

  return ProgramSettingsRequest(bottleId: bottleId, programPath: programPath);
}

ProgramSettingsUpdateRequest? _parseJsonProgramSettingsUpdateRequest(
  List<String> arguments,
) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'set-program-settings',
    options: const <String>['program', 'settings-json'],
  );
  if (results == null || !_hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = _requiredCliRest(results);
  final programPath = _requiredCliOption(results, 'program');
  final settingsJson = _requiredCliOption(results, 'settings-json');
  if (bottleId == null || programPath == null || settingsJson == null) {
    return null;
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(settingsJson);
  } on FormatException {
    return null;
  }

  return _programSettingsRecordFromJson(decoded)
      .map(
        (settings) => ProgramSettingsUpdateRequest(
          bottleId: bottleId,
          programPath: programPath,
          settings: settings,
        ),
      )
      .toNullable();
}

class _PinnedProgramLaunchCliRequest {
  const _PinnedProgramLaunchCliRequest({required this.manifestPath});

  final String manifestPath;
}

_PinnedProgramLaunchCliRequest? _parseJsonPinnedProgramLaunchCliRequest(
  List<String> arguments,
) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'launch-pinned-program',
    options: const <String>['manifest'],
  );
  if (results == null || !_hasRestCount(results, 0)) {
    return null;
  }

  final manifestPath = _requiredCliOption(results, 'manifest');
  if (manifestPath == null) {
    return null;
  }

  return _PinnedProgramLaunchCliRequest(manifestPath: manifestPath);
}
