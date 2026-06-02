part of '../../konyak_cli.dart';

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
