part of '../../konyak_cli.dart';

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
