part of '../konyak_cli.dart';

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

  final settings = ProgramSettingsRecord.fromJson(decoded);
  if (settings == null) {
    return null;
  }

  return ProgramSettingsUpdateRequest(
    bottleId: bottleId,
    programPath: programPath,
    settings: settings,
  );
}

class _ProgramRunCliRequest {
  const _ProgramRunCliRequest({
    required this.bottleId,
    required this.programPath,
  });

  final String bottleId;
  final String programPath;
}

_ProgramRunCliRequest? _parseJsonProgramRunCliRequest(List<String> arguments) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'run-program',
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

  return _ProgramRunCliRequest(bottleId: bottleId, programPath: programPath);
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

class _WinetricksRunCliRequest {
  const _WinetricksRunCliRequest({required this.bottleId, required this.verb});

  final String bottleId;
  final String verb;
}

_WinetricksRunCliRequest? _parseJsonWinetricksRunCliRequest(
  List<String> arguments,
) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'run-winetricks',
    options: const <String>['verb'],
  );
  if (results == null || !_hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = _requiredCliRest(results);
  final verb = _requiredCliOption(results, 'verb');
  if (bottleId == null || verb == null) {
    return null;
  }

  return _WinetricksRunCliRequest(bottleId: bottleId, verb: verb);
}

class _BottleCommandRunCliRequest {
  const _BottleCommandRunCliRequest({
    required this.bottleId,
    required this.command,
  });

  final String bottleId;
  final String command;
}

_BottleCommandRunCliRequest? _parseJsonBottleCommandRunCliRequest(
  List<String> arguments,
) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'run-bottle-command',
    options: const <String>['command'],
  );
  if (results == null || !_hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = _requiredCliRest(results);
  final command = _requiredCliOption(results, 'command');
  if (bottleId == null || command == null) {
    return null;
  }

  return _BottleCommandRunCliRequest(bottleId: bottleId, command: command);
}

class _BottleLocationOpenCliRequest {
  const _BottleLocationOpenCliRequest({
    required this.bottleId,
    required this.location,
  });

  final String bottleId;
  final String location;
}

_BottleLocationOpenCliRequest? _parseJsonBottleLocationOpenCliRequest(
  List<String> arguments,
) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'open-bottle-location',
    options: const <String>['location'],
  );
  if (results == null || !_hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = _requiredCliRest(results);
  final location = _requiredCliOption(results, 'location');
  if (bottleId == null || location == null) {
    return null;
  }

  return _BottleLocationOpenCliRequest(bottleId: bottleId, location: location);
}

class _ProgramLocationOpenCliRequest {
  const _ProgramLocationOpenCliRequest({
    required this.bottleId,
    required this.programPath,
  });

  final String bottleId;
  final String programPath;
}

_ProgramLocationOpenCliRequest? _parseJsonProgramLocationOpenCliRequest(
  List<String> arguments,
) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'open-program-location',
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

  return _ProgramLocationOpenCliRequest(
    bottleId: bottleId,
    programPath: programPath,
  );
}
