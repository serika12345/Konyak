part of 'konyak_cli_client.dart';

BottleUpdateLoadResult _bottleUpdateResultFromCommand({
  required ProcessRunResult result,
  required String command,
}) {
  final parsed = parseBottleDetailPayload(result.stdout);

  return switch (parsed) {
    ParsedBottleDetail(:final bottle) when result.exitCode == 0 =>
      UpdatedBottle(bottle),
    BottleDetailNotFound(:final bottleId, :final message)
        when result.exitCode == 66 =>
      MissingBottleUpdate(bottleId: bottleId, message: message),
    ParsedBottleDetail() ||
    BottleDetailNotFound() ||
    BottleDetailParseFailure() => BottleUpdateLoadFailure(
      exitCode: result.exitCode,
      message: _operationFailureMessage(result, command),
      diagnostic: result.stderr,
    ),
  };
}

ProgramSettingsLoadResult _programSettingsResultFromCommand({
  required ProcessRunResult result,
  required String command,
}) {
  final parsed = _parseProgramSettingsPayload(result.stdout);

  return switch (parsed) {
    LoadedProgramSettings() when result.exitCode == 0 => parsed,
    MissingProgramSettingsBottle() when result.exitCode == 66 => parsed,
    LoadedProgramSettings() ||
    MissingProgramSettingsBottle() ||
    ProgramSettingsLoadFailure() => ProgramSettingsLoadFailure(
      exitCode: result.exitCode,
      message: _operationFailureMessage(result, command),
      diagnostic: result.stderr,
    ),
  };
}

AppSettingsLoadResult _appSettingsResultFromCommand({
  required ProcessRunResult result,
  required String command,
}) {
  final parsed = _parseAppSettingsPayload(result.stdout);

  return switch (parsed) {
    LoadedAppSettings() when result.exitCode == 0 => parsed,
    LoadedAppSettings() || AppSettingsLoadFailure() => AppSettingsLoadFailure(
      exitCode: result.exitCode,
      message: _operationFailureMessage(result, command),
      diagnostic: result.stderr,
    ),
  };
}

UpdateCheckLoadResult _updateCheckResultFromCommand({
  required ProcessRunResult result,
  required String command,
  required String payloadKey,
  required String idKey,
}) {
  final parsed = _parseUpdateCheckPayload(
    payload: result.stdout,
    payloadKey: payloadKey,
    idKey: idKey,
  );

  return switch (parsed) {
    LoadedUpdateCheck() when result.exitCode == 0 => parsed,
    LoadedUpdateCheck() || UpdateCheckLoadFailure() => UpdateCheckLoadFailure(
      exitCode: result.exitCode,
      message: _operationFailureMessage(result, command),
      diagnostic: result.stderr,
    ),
  };
}

UpdateInstallLoadResult _updateInstallResultFromCommand(
  ProcessRunResult result,
) {
  final parsed = _parseUpdateInstallPayload(result.stdout);

  return switch (parsed) {
    InstalledUpdate() when result.exitCode == 0 => parsed,
    InstalledUpdate() || UpdateInstallLoadFailure() => UpdateInstallLoadFailure(
      exitCode: result.exitCode,
      message: _operationFailureMessage(result, 'install-app-update'),
      diagnostic: result.stderr,
    ),
  };
}

WineProcessTerminationLoadResult _wineProcessTerminationResultFromCommand(
  ProcessRunResult result, {
  String command = 'terminate-wine-processes',
}) {
  if (result.exitCode == 0 &&
      _isSuccessfulWineProcessTerminationPayload(result.stdout)) {
    return const TerminatedWineProcesses();
  }

  return WineProcessTerminationLoadFailure(
    exitCode: result.exitCode,
    message: _operationFailureMessage(result, command),
    diagnostic: result.stderr,
  );
}

bool _isSuccessfulWineProcessTerminationPayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException {
    return false;
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return false;
  }

  final termination = decoded['wineProcessTermination'];
  if (termination is! Map<String, Object?>) {
    return false;
  }

  return termination['hasFailures'] == false &&
      (termination['bottles'] is List<Object?> ||
          termination['processes'] is List<Object?>);
}

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

  return 'delete-bottle failed with exit code ${result.exitCode}.';
}

String _operationFailureMessage(ProcessRunResult result, String command) {
  final message = _jsonErrorMessage(result.stdout);
  if (message != null) {
    return message;
  }

  return _commandFailureMessage(command, result);
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

RuntimeInstallParseResult _parseRuntimeInstallCommandPayload(String stdout) {
  final parsed = parseRuntimeInstallPayload(stdout);
  if (parsed is! RuntimeInstallParseFailure) {
    return parsed;
  }

  final lines = const LineSplitter()
      .convert(stdout)
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
  for (final line in lines.reversed) {
    final lineParsed = parseRuntimeInstallPayload(line);
    if (lineParsed is! RuntimeInstallParseFailure) {
      return lineParsed;
    }
  }

  return parsed;
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

String _processOutputToString(Object? output) {
  if (output == null) {
    return '';
  }

  if (output is String) {
    return output;
  }

  return output.toString();
}

String? _firstNonEmpty(String? first, String? second, [String? third]) {
  for (final value in <String?>[first, second, third]) {
    if (value != null && value.trim().isNotEmpty) {
      return value;
    }
  }

  return null;
}

String _joinPath(String root, Iterable<String> components) {
  var path = root;
  for (final component in components) {
    final normalized = component.replaceAll(RegExp(r'^/+|/+$'), '');
    path = path.endsWith('/') ? '$path$normalized' : '$path/$normalized';
  }

  return path;
}
