part of 'konyak_cli_client.dart';

String _detailFailureMessage(ProcessRunResult result) {
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

String _createFailureMessage(ProcessRunResult result) {
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

String _updateFailureMessage(ProcessRunResult result) {
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

String _deleteFailureMessage(ProcessRunResult result) {
  if (result.exitCode == 0) {
    final parsed = _parseBottleDeletePayload(result.stdout);

    return switch (parsed) {
      _BottleDeleteParseFailure(:final message) => message,
      _ParsedBottleDelete() || _BottleDeleteNotFound() =>
        'delete-bottle returned an inconsistent payload.',
    };
  }

  return _commandFailureMessage('delete-bottle', result);
}

String _programRunFailureMessage(ProcessRunResult result) {
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

String _installRuntimeFailureMessage(ProcessRunResult result) {
  if (result.exitCode == 0) {
    final parsed = _parseRuntimeInstallCommandPayload(result.stdout);

    return switch (parsed) {
      RuntimeInstallParseFailure(:final message) => message,
      ParsedRuntimeInstall() || RuntimeInstallCommandFailure() =>
        'install-macos-wine returned an inconsistent payload.',
    };
  }

  final parsed = _parseRuntimeInstallCommandPayload(result.stdout);
  if (parsed case RuntimeInstallCommandFailure(:final message)) {
    return message;
  }

  return _commandFailureMessage('install-macos-wine', result);
}

String _commandFailureMessage(String command, ProcessRunResult result) {
  final message = _jsonErrorMessage(result.stdout);
  if (message != null) {
    return message;
  }

  final diagnostic = result.stderr.trim();
  if (diagnostic.isEmpty) {
    return '$command failed with exit code ${result.exitCode}.';
  }

  return '$command failed with exit code ${result.exitCode}: $diagnostic';
}

String? _jsonErrorMessage(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException {
    return null;
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return null;
  }

  final error = decoded['error'];
  if (error is! Map<String, Object?>) {
    return null;
  }

  final message = error['message'];
  return message is String ? message : null;
}
