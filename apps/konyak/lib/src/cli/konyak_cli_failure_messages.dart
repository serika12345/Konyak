import 'dart:convert';

import 'bottle_create_contract.dart';
import 'bottle_detail_contract.dart';
import 'konyak_cli_bottle_payload_parsers.dart';
import 'konyak_cli_process_runner.dart';
import 'konyak_cli_result_helpers.dart';
import 'program_run_contract.dart';
import 'runtime_install_contract.dart';

sealed class JsonErrorMessageParseResult {
  const JsonErrorMessageParseResult();
}

final class ParsedJsonErrorMessage extends JsonErrorMessageParseResult {
  const ParsedJsonErrorMessage(this.message);

  final String message;
}

final class NoJsonErrorMessage extends JsonErrorMessageParseResult {
  const NoJsonErrorMessage();
}

String detailFailureMessage(ProcessRunResult result) {
  if (result.exitCode == 0) {
    final parsed = parseBottleDetailPayload(result.stdout);

    return switch (parsed) {
      BottleDetailParseFailure(:final message) => message,
      ParsedBottleDetail() || BottleDetailNotFound() =>
        'inspect-bottle returned an inconsistent detail payload.',
    };
  }

  return 'inspect-bottle failed with exit code ${result.exitCode}.';
}

String createFailureMessage(ProcessRunResult result) {
  if (result.exitCode == 0) {
    final parsed = parseBottleCreatePayload(result.stdout);

    return switch (parsed) {
      BottleCreateParseFailure(:final message) => message,
      ParsedBottleCreate() || BottleCreateConflict() =>
        'create-bottle returned an inconsistent payload.',
    };
  }

  return 'create-bottle failed with exit code ${result.exitCode}.';
}

String updateFailureMessage(ProcessRunResult result) {
  if (result.exitCode == 0) {
    final parsed = parseBottleDetailPayload(result.stdout);

    return switch (parsed) {
      BottleDetailParseFailure(:final message) => message,
      ParsedBottleDetail() || BottleDetailNotFound() =>
        'set-windows-version returned an inconsistent payload.',
    };
  }

  return 'set-windows-version failed with exit code ${result.exitCode}.';
}

String deleteFailureMessage(ProcessRunResult result) {
  if (result.exitCode == 0) {
    final parsed = parseBottleDeletePayload(result.stdout);

    return switch (parsed) {
      BottleDeleteParseFailure(:final message) => message,
      ParsedBottleDelete() || BottleDeleteNotFound() =>
        'delete-bottle returned an inconsistent payload.',
    };
  }

  return commandFailureMessage('delete-bottle', result);
}

String programRunFailureMessage(ProcessRunResult result) {
  if (result.exitCode == 0) {
    final parsed = parseProgramRunPayload(result.stdout);

    return switch (parsed) {
      ProgramRunParseFailure(:final message) => message,
      ParsedProgramRun() ||
      ProgramRunUnsupportedProgramType() ||
      ProgramRunBottleNotFound() ||
      ProgramRunExecutionFailure() =>
        'run-program returned an inconsistent payload.',
    };
  }

  return 'run-program failed with exit code ${result.exitCode}.';
}

String installRuntimeFailureMessage(ProcessRunResult result) {
  if (result.exitCode == 0) {
    final parsed = parseRuntimeInstallCommandPayload(result.stdout);

    return switch (parsed) {
      RuntimeInstallParseFailure(:final message) => message,
      ParsedRuntimeInstall() || RuntimeInstallCommandFailure() =>
        'install-macos-wine returned an inconsistent payload.',
    };
  }

  final parsed = parseRuntimeInstallCommandPayload(result.stdout);
  if (parsed case RuntimeInstallCommandFailure(:final message)) {
    return message;
  }

  return commandFailureMessage('install-macos-wine', result);
}

String commandFailureMessage(String command, ProcessRunResult result) {
  switch (jsonErrorMessage(result.stdout)) {
    case ParsedJsonErrorMessage(:final message):
      return message;
    case NoJsonErrorMessage():
      break;
  }

  final diagnostic = result.stderr.trim();
  if (diagnostic.isEmpty) {
    return '$command failed with exit code ${result.exitCode}.';
  }

  return '$command failed with exit code ${result.exitCode}: $diagnostic';
}

JsonErrorMessageParseResult jsonErrorMessage(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException {
    return const NoJsonErrorMessage();
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return const NoJsonErrorMessage();
  }

  final error = decoded['error'];
  if (error is! Map<String, Object?>) {
    return const NoJsonErrorMessage();
  }

  final message = error['message'];
  return message is String && message.isNotEmpty
      ? ParsedJsonErrorMessage(message)
      : const NoJsonErrorMessage();
}
