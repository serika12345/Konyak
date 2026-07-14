import 'dart:convert';

import 'bottle_detail_contract.dart';
import 'konyak_cli_bottle_result_types.dart';
import 'konyak_cli_failure_messages.dart';
import 'konyak_cli_process_runner.dart';
import 'konyak_cli_program_payload_parsers.dart';
import 'konyak_cli_program_result_types.dart';
import 'konyak_cli_settings_payload_parsers.dart';
import 'konyak_cli_settings_result_types.dart';
import 'konyak_cli_update_payload_parsers.dart';
import 'konyak_cli_update_result_types.dart';
import 'konyak_cli_wine_process_result_types.dart';
import 'program_profile_install_contract.dart';
import 'runtime_install_contract.dart';

BottleUpdateLoadResult bottleUpdateResultFromCommand({
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
      message: operationFailureMessage(result, command),
      diagnostic: result.stderr,
    ),
  };
}

ProgramSettingsLoadResult programSettingsResultFromCommand({
  required ProcessRunResult result,
  required String command,
}) {
  final parsed = parseProgramSettingsPayload(result.stdout);

  return switch (parsed) {
    LoadedProgramSettings() when result.exitCode == 0 => parsed,
    MissingProgramSettingsBottle() when result.exitCode == 66 => parsed,
    LoadedProgramSettings() ||
    MissingProgramSettingsBottle() ||
    ProgramSettingsLoadFailure() => ProgramSettingsLoadFailure(
      exitCode: result.exitCode,
      message: operationFailureMessage(result, command),
      diagnostic: result.stderr,
    ),
  };
}

AppSettingsLoadResult appSettingsResultFromCommand({
  required ProcessRunResult result,
  required String command,
}) {
  final parsed = parseAppSettingsPayload(result.stdout);

  return switch (parsed) {
    LoadedAppSettings() when result.exitCode == 0 => parsed,
    LoadedAppSettings() || AppSettingsLoadFailure() => AppSettingsLoadFailure(
      exitCode: result.exitCode,
      message: operationFailureMessage(result, command),
      diagnostic: result.stderr,
    ),
  };
}

UpdateCheckLoadResult updateCheckResultFromCommand({
  required ProcessRunResult result,
  required String command,
  required String payloadKey,
  required String idKey,
}) {
  final parsed = parseUpdateCheckPayload(
    payload: result.stdout,
    payloadKey: payloadKey,
    idKey: idKey,
  );

  return switch (parsed) {
    LoadedUpdateCheck() when result.exitCode == 0 => parsed,
    LoadedUpdateCheck() || UpdateCheckLoadFailure() => UpdateCheckLoadFailure(
      exitCode: result.exitCode,
      message: operationFailureMessage(result, command),
      diagnostic: result.stderr,
    ),
  };
}

UpdateInstallLoadResult updateInstallResultFromCommand(
  ProcessRunResult result,
) {
  final parsed = parseUpdateInstallPayload(result.stdout);

  return switch (parsed) {
    InstalledUpdate() when result.exitCode == 0 => parsed,
    InstalledUpdate() || UpdateInstallLoadFailure() => UpdateInstallLoadFailure(
      exitCode: result.exitCode,
      message: operationFailureMessage(result, 'install-app-update'),
      diagnostic: result.stderr,
    ),
  };
}

WineProcessTerminationLoadResult wineProcessTerminationResultFromCommand(
  ProcessRunResult result, {
  String command = 'terminate-wine-processes',
}) {
  if (result.exitCode == 0 &&
      isSuccessfulWineProcessTerminationPayload(result.stdout)) {
    return const TerminatedWineProcesses();
  }

  return WineProcessTerminationLoadFailure(
    exitCode: result.exitCode,
    message: operationFailureMessage(result, command),
    diagnostic: result.stderr,
  );
}

bool isSuccessfulWineProcessTerminationPayload(String payload) {
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

String operationFailureMessage(ProcessRunResult result, String command) {
  switch (jsonErrorMessage(result.stdout)) {
    case ParsedJsonErrorMessage(:final message):
      return message;
    case NoJsonErrorMessage():
      break;
  }

  return commandFailureMessage(command, result);
}

RuntimeInstallParseResult parseRuntimeInstallCommandPayload(String stdout) {
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

ProgramProfileInstallParseResult parseProgramProfileInstallCommandPayload(
  String stdout,
) {
  final parsed = parseProgramProfileInstallPayload(stdout);
  if (parsed is! ProgramProfileInstallParseFailure) {
    return parsed;
  }

  final lines = const LineSplitter()
      .convert(stdout)
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
  for (final line in lines.reversed) {
    final lineParsed = parseProgramProfileInstallPayload(line);
    if (lineParsed is! ProgramProfileInstallParseFailure) {
      return lineParsed;
    }
  }

  return parsed;
}

String processOutputToString(Object output) {
  if (output is String) {
    return output;
  }

  return output.toString();
}

String joinPath(String root, Iterable<String> components) {
  var path = root;
  for (final component in components) {
    final normalized = component.replaceAll(RegExp(r'^/+|/+$'), '');
    path = path.endsWith('/') ? '$path$normalized' : '$path/$normalized';
  }

  return path;
}
