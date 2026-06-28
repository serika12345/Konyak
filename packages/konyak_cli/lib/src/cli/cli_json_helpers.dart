import 'dart:convert';
import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../domain/bottle/bottle_models.dart';
import '../domain/program/program_run_models.dart';
import '../io/external_payload_helpers.dart';
import '../repository/repository_interfaces.dart';
import '../shared/model_constants.dart';
import 'cli_bottle_results.dart';
import 'cli_result_model.dart';

CliResult jsonSuccess(Map<String, Object?> payload, {int exitCode = 0}) {
  return CliResult(
    exitCode: exitCode,
    stdout: jsonEncode(<String, Object?>{
      'schemaVersion': cliSchemaVersion,
      ...payload,
    }),
    stderr: '',
  );
}

CliResult unavailableJsonError({
  required String code,
  required String subject,
}) {
  return jsonError(
    exitCode: 74,
    code: code,
    message: '$subject is not configured.',
  );
}

CliResult jsonError({
  required int exitCode,
  required String code,
  required String message,
  Map<String, Object?> extra = const <String, Object?>{},
}) {
  return CliResult(
    exitCode: exitCode,
    stdout: jsonEncode(<String, Object?>{
      'schemaVersion': cliSchemaVersion,
      'error': <String, Object?>{'code': code, 'message': message, ...extra},
    }),
    stderr: '',
  );
}

CliResult bottleNotFoundError(String bottleId) {
  return jsonError(
    exitCode: 66,
    code: 'bottleNotFound',
    message: 'Bottle not found.',
    extra: <String, Object?>{'bottleId': bottleId},
  );
}

CliResult createdBottleJsonResult({
  required BottleRecord bottle,
  required BottlePrefixInitializer? bottlePrefixInitializer,
}) {
  final initializer = bottlePrefixInitializer;
  if (initializer != null) {
    final initializationResult = initializer.initialize(bottle);
    switch (initializationResult) {
      case BottlePrefixInitialized():
        break;
      case BottlePrefixInitializationFailed(:final message):
        return jsonError(
          exitCode: 75,
          code: 'bottlePrefixInitializationFailed',
          message: message,
          extra: <String, Object?>{
            'bottleId': bottle.id.value,
            'bottlePath': bottle.path.value,
          },
        );
    }
  }

  return bottleJsonResult(bottle);
}

CliResult programRunJsonResult({
  required ProgramRunRequest request,
  required int processExitCode,
}) {
  return jsonSuccess(<String, Object?>{
    'run': <String, Object?>{
      'bottleId': request.bottleId.value,
      'programPath': request.programPath.value,
      'runnerKind': request.runnerKind.value,
      'executable': request.executable.value,
      'workingDirectory': request.workingDirectory.toNullable()?.value,
      'argv': request.argv,
      'logPath': request.logPath.value,
      'logFileCreated': request.createLogFile,
      'processExitCode': processExitCode,
    },
  });
}

CliResult programRunFailedJsonResult({
  required ProgramRunRequest request,
  required String message,
}) {
  return jsonError(
    exitCode: 75,
    code: 'programRunFailed',
    message: message,
    extra: <String, Object?>{
      'bottleId': request.bottleId.value,
      'programPath': request.programPath.value,
      'runnerKind': request.runnerKind.value,
      'executable': request.executable.value,
      'workingDirectory': request.workingDirectory.toNullable()?.value,
      'argv': request.argv,
      'logPath': request.logPath.value,
      'logFileCreated': request.createLogFile,
    },
  );
}

String programRunLog(ProgramRunRequest request, ProcessResult result) {
  final stdout = processOutputToString(result.stdout);
  final stderr = processOutputToString(result.stderr);

  return programRunLogContent(
    request: request,
    processExitCode: result.exitCode,
    stdout: stdout,
    stderr: stderr,
  );
}

String programRunStartupFailureLog(
  ProgramRunRequest request,
  String startupError,
) {
  return programRunLogContent(
    request: request,
    startupError: startupError,
    stdout: '',
    stderr: '',
  );
}

String programRunLogContent({
  required ProgramRunRequest request,
  required String stdout,
  required String stderr,
  int? processExitCode,
  String? startupError,
}) {
  final environmentLines =
      request.environment
          .toMap()
          .entries
          .map((entry) => MapEntry(entry.key, '${entry.key}=${entry.value}'))
          .toList(growable: false)
        ..sort((left, right) => left.key.compareTo(right.key));

  return <String>[
    'Konyak Wine Run Log',
    '',
    '[Process]',
    'Runner Kind: ${request.runnerKind.value}',
    'Executable: ${request.executable.value}',
    'Working Directory: ${request.workingDirectory.map((value) => value.value).getOrElse(() => '')}',
    'Arguments: ${jsonEncode(request.arguments.value)}',
    'argv: ${jsonEncode(request.argv)}',
    if (processExitCode != null) 'Process Exit Code: $processExitCode',
    if (processExitCode != null) 'exitCode: $processExitCode',
    if (startupError != null) 'Startup Error: $startupError',
    '',
    '[Environment]',
    ...environmentLines.map((entry) => entry.value),
    '',
    '[stdout]',
    stdout,
    '',
    '[stderr]',
    stderr,
    '',
  ].join('\n');
}

String programRunnerFailureMessage({
  required String executable,
  required String message,
}) {
  if (message == 'No such file or directory') {
    return 'Runner executable `$executable` was not found.';
  }

  return message;
}
