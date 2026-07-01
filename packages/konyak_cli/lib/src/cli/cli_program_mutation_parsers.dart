import 'dart:convert';

import 'package:args/args.dart' hide Option;
import 'package:fpdart/fpdart.dart';

import '../domain/program/program_mutation_models.dart';
import '../domain/program/program_settings_models.dart';
import '../domain/shared/domain_value_objects.dart';
import '../io/repository_storage_io.dart';
import 'cli_parsers.dart';

ProgramPinRequest? parseJsonProgramPinRequest(List<String> arguments) {
  return _nullableParsedRequest(parseJsonProgramPinRequestOption(arguments));
}

Option<ProgramPinRequest> parseJsonProgramPinRequestOption(
  List<String> arguments,
) {
  return Option.Do(($) {
    final results = $(
      _parseJsonProgramMutationCommand(
        arguments,
        command: 'pin-program',
        options: const <String>['name', 'program'],
        restCount: 1,
      ),
    );
    final target = $(_programMutationTargetFromResults(results));
    final name = $(_requiredProgramName(results, 'name'));

    return ProgramPinRequest(
      bottleId: target.bottleId,
      name: name,
      programPath: target.programPath,
    );
  });
}

ProgramUnpinRequest? parseJsonProgramUnpinRequest(List<String> arguments) {
  return _nullableParsedRequest(parseJsonProgramUnpinRequestOption(arguments));
}

Option<ProgramUnpinRequest> parseJsonProgramUnpinRequestOption(
  List<String> arguments,
) {
  return Option.Do(($) {
    final results = $(
      _parseJsonProgramMutationCommand(
        arguments,
        command: 'unpin-program',
        options: const <String>['program'],
        restCount: 1,
      ),
    );
    final target = $(_programMutationTargetFromResults(results));

    return ProgramUnpinRequest(
      bottleId: target.bottleId,
      programPath: target.programPath,
    );
  });
}

ProgramRenameRequest? parseJsonProgramRenameRequest(List<String> arguments) {
  return _nullableParsedRequest(parseJsonProgramRenameRequestOption(arguments));
}

Option<ProgramRenameRequest> parseJsonProgramRenameRequestOption(
  List<String> arguments,
) {
  return Option.Do(($) {
    final results = $(
      _parseJsonProgramMutationCommand(
        arguments,
        command: 'rename-pinned-program',
        options: const <String>['program', 'name'],
        restCount: 1,
      ),
    );
    final target = $(_programMutationTargetFromResults(results));
    final name = $(_requiredProgramName(results, 'name'));

    return ProgramRenameRequest(
      bottleId: target.bottleId,
      programPath: target.programPath,
      name: name,
    );
  });
}

ProgramSettingsRequest? parseJsonProgramSettingsRequest(
  List<String> arguments,
) {
  return _nullableParsedRequest(
    parseJsonProgramSettingsRequestOption(arguments),
  );
}

Option<ProgramSettingsRequest> parseJsonProgramSettingsRequestOption(
  List<String> arguments,
) {
  return Option.Do(($) {
    final results = $(
      _parseJsonProgramMutationCommand(
        arguments,
        command: 'get-program-settings',
        options: const <String>['program'],
        restCount: 1,
      ),
    );
    final target = $(_programMutationTargetFromResults(results));

    return ProgramSettingsRequest(
      bottleId: target.bottleId,
      programPath: target.programPath,
    );
  });
}

ProgramSettingsUpdateRequest? parseJsonProgramSettingsUpdateRequest(
  List<String> arguments,
) {
  return _nullableParsedRequest(
    parseJsonProgramSettingsUpdateRequestOption(arguments),
  );
}

Option<ProgramSettingsUpdateRequest>
parseJsonProgramSettingsUpdateRequestOption(List<String> arguments) {
  return Option.Do(($) {
    final results = $(
      _parseJsonProgramMutationCommand(
        arguments,
        command: 'set-program-settings',
        options: const <String>['program', 'settings-json'],
        restCount: 1,
      ),
    );
    final target = $(_programMutationTargetFromResults(results));
    final settingsJson = $(_requiredCliOption(results, 'settings-json'));
    final settings = $(_programSettingsRecordFromJsonString(settingsJson));

    return ProgramSettingsUpdateRequest(
      bottleId: target.bottleId,
      programPath: target.programPath,
      settings: settings,
    );
  });
}

class PinnedProgramLaunchCliRequest {
  const PinnedProgramLaunchCliRequest({required this.manifestPath});

  final String manifestPath;
}

PinnedProgramLaunchCliRequest? parseJsonPinnedProgramLaunchCliRequest(
  List<String> arguments,
) {
  return _nullableParsedRequest(
    parseJsonPinnedProgramLaunchCliRequestOption(arguments),
  );
}

Option<PinnedProgramLaunchCliRequest>
parseJsonPinnedProgramLaunchCliRequestOption(List<String> arguments) {
  return Option.Do(($) {
    final results = $(
      _parseJsonProgramMutationCommand(
        arguments,
        command: 'launch-pinned-program',
        options: const <String>['manifest'],
        restCount: 0,
      ),
    );
    final manifestPath = $(_requiredCliOption(results, 'manifest'));

    return PinnedProgramLaunchCliRequest(manifestPath: manifestPath);
  });
}

Option<ArgResults> _parseJsonProgramMutationCommand(
  List<String> arguments, {
  required String command,
  required Iterable<String> options,
  required int restCount,
}) {
  return Option.Do(($) {
    final results = $(
      Option.fromNullable(
        parseJsonCliCommand(arguments, command: command, options: options),
      ),
    );

    if (!hasRestCount(results, restCount)) {
      return $(const Option<ArgResults>.none());
    }

    return results;
  });
}

Option<({BottleId bottleId, ProgramPath programPath})>
_programMutationTargetFromResults(ArgResults results) {
  return Option.Do(($) {
    final bottleId = $(_requiredBottleId(results));
    final programPath = $(_requiredProgramPath(results, 'program'));

    return (bottleId: bottleId, programPath: programPath);
  });
}

Option<BottleId> _requiredBottleId(ArgResults results) {
  return Option.fromNullable(requiredCliRest(results)).map(BottleId.new);
}

Option<ProgramPath> _requiredProgramPath(ArgResults results, String name) {
  return _requiredCliOption(results, name).map(ProgramPath.new);
}

Option<ProgramName> _requiredProgramName(ArgResults results, String name) {
  return _requiredCliOption(results, name).map(ProgramName.new);
}

Option<String> _requiredCliOption(ArgResults results, String name) {
  return Option.fromNullable(requiredCliOption(results, name));
}

Option<ProgramSettingsRecord> _programSettingsRecordFromJsonString(String raw) {
  try {
    return programSettingsRecordFromJson(jsonDecode(raw));
  } on FormatException {
    return const Option.none();
  }
}

T? _nullableParsedRequest<T>(Option<T> request) {
  return request.match(() => null, (value) => value);
}
