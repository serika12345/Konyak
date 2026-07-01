import 'dart:convert';

import 'package:args/args.dart' hide Option;
import 'package:fpdart/fpdart.dart';

import '../domain/program/program_settings_models.dart';
import '../domain/shared/domain_value_objects.dart';
import '../io/repository_storage_io.dart';
import 'cli_parsers.dart';
import 'cli_value_object_parsers.dart';

class ProgramRunCliRequest {
  const ProgramRunCliRequest({
    required this.bottleId,
    required this.programPath,
    this.settings = const Option.none(),
  });

  final BottleId bottleId;
  final String programPath;
  final Option<ProgramSettingsRecord> settings;
}

ProgramRunCliRequest? parseJsonProgramRunCliRequest(List<String> arguments) {
  return nullableParsedOption(parseJsonProgramRunCliRequestOption(arguments));
}

Option<ProgramRunCliRequest> parseJsonProgramRunCliRequestOption(
  List<String> arguments,
) {
  return Option.Do(($) {
    final results = $(
      _parseJsonProgramRunCommand(
        arguments,
        command: 'run-program',
        options: const <String>['program', 'settings-json'],
        restCount: 1,
      ),
    );
    final bottleId = $(requiredCliBottleIdOption(results));
    final programPath = $(requiredCliOptionOption(results, 'program'));
    final settings = $(_optionalProgramSettings(results));

    return ProgramRunCliRequest(
      bottleId: bottleId,
      programPath: programPath,
      settings: settings,
    );
  });
}

class GraphicsBackendHintsCliRequest {
  const GraphicsBackendHintsCliRequest({required this.programPath});

  final String programPath;
}

GraphicsBackendHintsCliRequest? parseJsonGraphicsBackendHintsCliRequest(
  List<String> arguments,
) {
  return nullableParsedOption(
    parseJsonGraphicsBackendHintsCliRequestOption(arguments),
  );
}

Option<GraphicsBackendHintsCliRequest>
parseJsonGraphicsBackendHintsCliRequestOption(List<String> arguments) {
  return Option.Do(($) {
    final results = $(
      _parseJsonProgramRunCommand(
        arguments,
        command: 'suggest-graphics-backend',
        options: const <String>['program'],
        restCount: 0,
      ),
    );
    final programPath = $(requiredCliOptionOption(results, 'program'));

    return GraphicsBackendHintsCliRequest(programPath: programPath);
  });
}

class WinetricksRunCliRequest {
  const WinetricksRunCliRequest({required this.bottleId, required this.verb});

  final BottleId bottleId;
  final String verb;
}

WinetricksRunCliRequest? parseJsonWinetricksRunCliRequest(
  List<String> arguments,
) {
  return nullableParsedOption(
    parseJsonWinetricksRunCliRequestOption(arguments),
  );
}

Option<WinetricksRunCliRequest> parseJsonWinetricksRunCliRequestOption(
  List<String> arguments,
) {
  return Option.Do(($) {
    final results = $(
      _parseJsonProgramRunCommand(
        arguments,
        command: 'run-winetricks',
        options: const <String>['verb'],
        restCount: 1,
      ),
    );
    final bottleId = $(requiredCliBottleIdOption(results));
    final verb = $(requiredCliOptionOption(results, 'verb'));

    return WinetricksRunCliRequest(bottleId: bottleId, verb: verb);
  });
}

class BottleCommandRunCliRequest {
  const BottleCommandRunCliRequest({
    required this.bottleId,
    required this.command,
  });

  final BottleId bottleId;
  final String command;
}

BottleCommandRunCliRequest? parseJsonBottleCommandRunCliRequest(
  List<String> arguments,
) {
  return nullableParsedOption(
    parseJsonBottleCommandRunCliRequestOption(arguments),
  );
}

Option<BottleCommandRunCliRequest> parseJsonBottleCommandRunCliRequestOption(
  List<String> arguments,
) {
  return Option.Do(($) {
    final results = $(
      _parseJsonProgramRunCommand(
        arguments,
        command: 'run-bottle-command',
        options: const <String>['command'],
        restCount: 1,
      ),
    );
    final bottleId = $(requiredCliBottleIdOption(results));
    final command = $(requiredCliOptionOption(results, 'command'));

    return BottleCommandRunCliRequest(bottleId: bottleId, command: command);
  });
}

Option<ArgResults> _parseJsonProgramRunCommand(
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

Option<Option<ProgramSettingsRecord>> _optionalProgramSettings(
  ArgResults results,
) {
  return optionalCliOptionOption(results, 'settings-json').match(
    () => Option.of(const Option<ProgramSettingsRecord>.none()),
    (settingsJson) =>
        _programSettingsRecordFromJsonString(settingsJson).map(Option.of),
  );
}

Option<ProgramSettingsRecord> _programSettingsRecordFromJsonString(String raw) {
  try {
    return programSettingsRecordFromJson(jsonDecode(raw));
  } on FormatException {
    return const Option.none();
  }
}
