import 'dart:convert';

import '../runs/program_run_summary.dart';

const programRunSchemaVersion = 1;

sealed class ProgramRunParseResult {
  const ProgramRunParseResult();
}

final class ParsedProgramRun extends ProgramRunParseResult {
  const ParsedProgramRun(this.run);

  final ProgramRunSummary run;
}

final class ProgramRunBottleNotFound extends ProgramRunParseResult {
  const ProgramRunBottleNotFound({
    required this.bottleId,
    required this.message,
  });

  final String bottleId;
  final String message;
}

final class ProgramRunUnsupportedProgramType extends ProgramRunParseResult {
  const ProgramRunUnsupportedProgramType({
    required this.programPath,
    required this.message,
  });

  final String programPath;
  final String message;
}

final class ProgramRunExecutionFailure extends ProgramRunParseResult {
  ProgramRunExecutionFailure({
    required this.bottleId,
    required this.programPath,
    required this.message,
    required this.runnerKind,
    required this.executable,
    required List<String> argv,
    required this.logPath,
    this.logFileCreated = true,
    this.workingDirectory,
  }) : argv = List.unmodifiable(argv);

  final String bottleId;
  final String programPath;
  final String message;
  final String runnerKind;
  final String executable;
  final String? workingDirectory;
  final List<String> argv;
  final String logPath;
  final bool logFileCreated;
}

final class ProgramRunParseFailure extends ProgramRunParseResult {
  const ProgramRunParseFailure(this.message);

  final String message;
}

ProgramRunParseResult parseProgramRunPayload(String payload) {
  final Object? decoded;

  try {
    decoded = jsonDecode(payload);
  } on FormatException {
    return const ProgramRunParseFailure(
      'Program run payload is not valid JSON.',
    );
  }

  if (decoded is! Map<String, dynamic>) {
    return const ProgramRunParseFailure(
      'Program run payload must be an object.',
    );
  }

  final Object? schemaVersion = decoded['schemaVersion'];
  if (schemaVersion != programRunSchemaVersion) {
    return const ProgramRunParseFailure(
      'Unsupported program run schema version.',
    );
  }

  switch (_parseProgramRunError(decoded['error'])) {
    case _ParsedProgramRunError(:final result):
      return result;
    case _NoProgramRunError():
      break;
  }

  final run = _parseProgramRunSummary(decoded['run']);
  if (run == null) {
    return const ProgramRunParseFailure(
      'Program run payload contains an invalid run record.',
    );
  }

  return ParsedProgramRun(run);
}

sealed class _ProgramRunErrorParseResult {
  const _ProgramRunErrorParseResult();
}

final class _ParsedProgramRunError extends _ProgramRunErrorParseResult {
  const _ParsedProgramRunError(this.result);

  final ProgramRunParseResult result;
}

final class _NoProgramRunError extends _ProgramRunErrorParseResult {
  const _NoProgramRunError();
}

_ProgramRunErrorParseResult _parseProgramRunError(Object? value) {
  final parsedErrors = <ProgramRunParseResult>[
    ?_parseBottleNotFound(value),
    ?_parseUnsupportedProgramType(value),
    ?_parseExecutionFailure(value),
  ];

  return parsedErrors.isEmpty
      ? const _NoProgramRunError()
      : _ParsedProgramRunError(parsedErrors.first);
}

ProgramRunBottleNotFound? _parseBottleNotFound(Object? value) {
  if (value is! Map<String, dynamic>) {
    return null;
  }

  final Object? code = value['code'];
  final Object? message = value['message'];
  final Object? bottleId = value['bottleId'];

  if (code != 'bottleNotFound' || message is! String || bottleId is! String) {
    return null;
  }

  return ProgramRunBottleNotFound(bottleId: bottleId, message: message);
}

ProgramRunUnsupportedProgramType? _parseUnsupportedProgramType(Object? value) {
  if (value is! Map<String, dynamic>) {
    return null;
  }

  final Object? code = value['code'];
  final Object? message = value['message'];
  final Object? programPath = value['programPath'];

  if (code != 'unsupportedProgramType' ||
      message is! String ||
      programPath is! String) {
    return null;
  }

  return ProgramRunUnsupportedProgramType(
    programPath: programPath,
    message: message,
  );
}

ProgramRunExecutionFailure? _parseExecutionFailure(Object? value) {
  if (value is! Map<String, dynamic>) {
    return null;
  }

  final Object? code = value['code'];
  final Object? message = value['message'];
  final Object? bottleId = value['bottleId'];
  final Object? programPath = value['programPath'];
  final Object? runnerKind = value['runnerKind'];
  final Object? executable = value['executable'];
  final Object? workingDirectory = value['workingDirectory'];
  final argv = _parseStringList(value['argv']);
  final Object? logPath = value['logPath'];
  final Object? logFileCreated = value['logFileCreated'];

  if (code != 'programRunFailed' ||
      message is! String ||
      bottleId is! String ||
      programPath is! String ||
      runnerKind is! String ||
      executable is! String ||
      !_isOptionalString(workingDirectory) ||
      argv == null ||
      logPath is! String ||
      !_isOptionalBool(logFileCreated)) {
    return null;
  }

  return ProgramRunExecutionFailure(
    bottleId: bottleId,
    programPath: programPath,
    message: message,
    runnerKind: runnerKind,
    executable: executable,
    workingDirectory: workingDirectory as String?,
    argv: argv,
    logPath: logPath,
    logFileCreated: logFileCreated is bool ? logFileCreated : true,
  );
}

ProgramRunSummary? _parseProgramRunSummary(Object? value) {
  if (value is! Map<String, dynamic>) {
    return null;
  }

  final Object? bottleId = value['bottleId'];
  final Object? programPath = value['programPath'];
  final Object? runnerKind = value['runnerKind'];
  final Object? executable = value['executable'];
  final Object? workingDirectory = value['workingDirectory'];
  final argv = _parseStringList(value['argv']);
  final Object? logPath = value['logPath'];
  final Object? logFileCreated = value['logFileCreated'];
  final Object? processExitCode = value['processExitCode'];

  if (bottleId is! String ||
      programPath is! String ||
      runnerKind is! String ||
      executable is! String ||
      !_isOptionalString(workingDirectory) ||
      argv == null ||
      logPath is! String ||
      !_isOptionalBool(logFileCreated) ||
      processExitCode is! int) {
    return null;
  }

  return ProgramRunSummary(
    bottleId: bottleId,
    programPath: programPath,
    runnerKind: runnerKind,
    executable: executable,
    workingDirectory: workingDirectory as String?,
    argv: argv,
    logPath: logPath,
    logFileCreated: logFileCreated is bool ? logFileCreated : true,
    processExitCode: processExitCode,
  );
}

List<String>? _parseStringList(Object? value) {
  if (value is! List<dynamic>) {
    return null;
  }

  final strings = value.whereType<String>().toList(growable: false);
  if (strings.length != value.length) {
    return null;
  }

  return List.unmodifiable(strings);
}

bool _isOptionalString(Object? value) {
  return value == null || value is String;
}

bool _isOptionalBool(Object? value) {
  return value == null || value is bool;
}
