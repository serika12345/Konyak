import '../domain/shared/domain_value_objects.dart';
import 'cli_parsers.dart';
import 'cli_value_object_parsers.dart';

class BottleLocationOpenCliRequest {
  const BottleLocationOpenCliRequest({
    required this.bottleId,
    required this.location,
  });

  final BottleId bottleId;
  final String location;
}

BottleLocationOpenCliRequest? parseJsonBottleLocationOpenCliRequest(
  List<String> arguments,
) {
  final results = parseJsonCliCommand(
    arguments,
    command: 'open-bottle-location',
    options: const <String>['location'],
  );
  if (results == null || !hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = requiredCliBottleId(results);
  final location = requiredCliOption(results, 'location');
  if (bottleId == null || location == null) {
    return null;
  }

  return BottleLocationOpenCliRequest(bottleId: bottleId, location: location);
}

class ProgramLocationOpenCliRequest {
  const ProgramLocationOpenCliRequest({
    required this.bottleId,
    required this.programPath,
  });

  final BottleId bottleId;
  final String programPath;
}

ProgramLocationOpenCliRequest? parseJsonProgramLocationOpenCliRequest(
  List<String> arguments,
) {
  final results = parseJsonCliCommand(
    arguments,
    command: 'open-program-location',
    options: const <String>['program'],
  );
  if (results == null || !hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = requiredCliBottleId(results);
  final programPath = requiredCliOption(results, 'program');
  if (bottleId == null || programPath == null) {
    return null;
  }

  return ProgramLocationOpenCliRequest(
    bottleId: bottleId,
    programPath: programPath,
  );
}
