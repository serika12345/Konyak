import 'package:args/args.dart' hide Option;
import 'package:fpdart/fpdart.dart';

import '../domain/shared/domain_value_objects.dart';
import 'cli_parsers.dart';
import 'cli_value_object_parsers.dart';

class BottleLocationOpenCliRequest {
  const BottleLocationOpenCliRequest({
    required this.bottleId,
    required this.location,
  });

  final BottleId bottleId;
  final BottleLocation location;
}

Option<BottleLocationOpenCliRequest>
parseJsonBottleLocationOpenCliRequestOption(List<String> arguments) {
  return Option.Do(($) {
    final results = $(
      _parseJsonLocationCommand(
        arguments,
        command: 'open-bottle-location',
        options: const <String>['location'],
        restCount: 1,
      ),
    );
    final bottleId = $(requiredCliBottleIdOption(results));
    final locationValue = $(requiredCliOptionOption(results, 'location'));

    return BottleLocationOpenCliRequest(
      bottleId: bottleId,
      location: BottleLocation(locationValue),
    );
  });
}

class ProgramLocationOpenCliRequest {
  const ProgramLocationOpenCliRequest({
    required this.bottleId,
    required this.programPath,
  });

  final BottleId bottleId;
  final ProgramPath programPath;
}

Option<ProgramLocationOpenCliRequest>
parseJsonProgramLocationOpenCliRequestOption(List<String> arguments) {
  return Option.Do(($) {
    final results = $(
      _parseJsonLocationCommand(
        arguments,
        command: 'open-program-location',
        options: const <String>['program'],
        restCount: 1,
      ),
    );
    final bottleId = $(requiredCliBottleIdOption(results));
    final programPathValue = $(requiredCliOptionOption(results, 'program'));

    return ProgramLocationOpenCliRequest(
      bottleId: bottleId,
      programPath: ProgramPath(programPathValue),
    );
  });
}

Option<ArgResults> _parseJsonLocationCommand(
  List<String> arguments, {
  required String command,
  required Iterable<String> options,
  required int restCount,
}) {
  return Option.Do(($) {
    final results = $(
      parseJsonCliCommandOption(arguments, command: command, options: options),
    );

    if (!hasRestCount(results, restCount)) {
      return $(const Option<ArgResults>.none());
    }

    return results;
  });
}
