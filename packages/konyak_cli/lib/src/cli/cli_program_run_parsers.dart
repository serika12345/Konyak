import 'dart:convert';

import 'package:fpdart/fpdart.dart';

import '../domain/program/program_settings_models.dart';
import '../io/repository_storage_io.dart';
import 'cli_parsers.dart';

class ProgramRunCliRequest {
  const ProgramRunCliRequest({
    required this.bottleId,
    required this.programPath,
    this.settings = const Option.none(),
  });

  final String bottleId;
  final String programPath;
  final Option<ProgramSettingsRecord> settings;
}

ProgramRunCliRequest? parseJsonProgramRunCliRequest(List<String> arguments) {
  final results = parseJsonCliCommand(
    arguments,
    command: 'run-program',
    options: const <String>['program', 'settings-json'],
  );
  if (results == null || !hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = requiredCliRest(results);
  final programPath = requiredCliOption(results, 'program');
  if (bottleId == null || programPath == null) {
    return null;
  }

  final settingsJson = optionalCliOption(results, 'settings-json');
  Option<ProgramSettingsRecord> settings = const Option.none();
  if (settingsJson != null) {
    final Object? decoded;
    try {
      decoded = jsonDecode(settingsJson);
    } on FormatException {
      return null;
    }

    settings = programSettingsRecordFromJson(decoded);
    if (settings.isNone()) {
      return null;
    }
  }

  return ProgramRunCliRequest(
    bottleId: bottleId,
    programPath: programPath,
    settings: settings,
  );
}

class GraphicsBackendHintsCliRequest {
  const GraphicsBackendHintsCliRequest({required this.programPath});

  final String programPath;
}

GraphicsBackendHintsCliRequest? parseJsonGraphicsBackendHintsCliRequest(
  List<String> arguments,
) {
  final results = parseJsonCliCommand(
    arguments,
    command: 'suggest-graphics-backend',
    options: const <String>['program'],
  );
  if (results == null || hasEmptyParsedCliOption(results, 'program')) {
    return null;
  }
  if (!hasRestCount(results, 0)) {
    return null;
  }

  final programPath = requiredCliOption(results, 'program');
  if (programPath == null) {
    return null;
  }

  return GraphicsBackendHintsCliRequest(programPath: programPath);
}

class WinetricksRunCliRequest {
  const WinetricksRunCliRequest({required this.bottleId, required this.verb});

  final String bottleId;
  final String verb;
}

WinetricksRunCliRequest? parseJsonWinetricksRunCliRequest(
  List<String> arguments,
) {
  final results = parseJsonCliCommand(
    arguments,
    command: 'run-winetricks',
    options: const <String>['verb'],
  );
  if (results == null || !hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = requiredCliRest(results);
  final verb = requiredCliOption(results, 'verb');
  if (bottleId == null || verb == null) {
    return null;
  }

  return WinetricksRunCliRequest(bottleId: bottleId, verb: verb);
}

class BottleCommandRunCliRequest {
  const BottleCommandRunCliRequest({
    required this.bottleId,
    required this.command,
  });

  final String bottleId;
  final String command;
}

BottleCommandRunCliRequest? parseJsonBottleCommandRunCliRequest(
  List<String> arguments,
) {
  final results = parseJsonCliCommand(
    arguments,
    command: 'run-bottle-command',
    options: const <String>['command'],
  );
  if (results == null || !hasRestCount(results, 1)) {
    return null;
  }

  final bottleId = requiredCliRest(results);
  final command = requiredCliOption(results, 'command');
  if (bottleId == null || command == null) {
    return null;
  }

  return BottleCommandRunCliRequest(bottleId: bottleId, command: command);
}
