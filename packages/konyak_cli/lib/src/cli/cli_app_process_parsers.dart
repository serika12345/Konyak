import 'dart:convert';

import 'package:fpdart/fpdart.dart';

import '../domain/app/app_settings_models.dart';
import '../domain/program/program_mutation_models.dart';
import '../domain/shared/domain_value_objects.dart';
import '../io/app_settings_json.dart';
import 'cli_parsers.dart';

bool isJsonAppUpdateCheckCommand(List<String> arguments) {
  return isJsonFlagOnlyCommand(arguments, 'check-app-update');
}

bool isJsonAppUpdateInstallCommand(List<String> arguments) {
  return isJsonFlagOnlyCommand(arguments, 'install-app-update');
}

bool isJsonAppSettingsGetCommand(List<String> arguments) {
  return isJsonFlagOnlyCommand(arguments, 'get-app-settings');
}

bool isJsonLinuxFileAssociationInstallCommand(List<String> arguments) {
  return isJsonFlagOnlyCommand(arguments, 'install-linux-file-associations');
}

AppSettingsRecord? parseJsonAppSettingsUpdateRequest(List<String> arguments) {
  final results = parseJsonCliCommand(
    arguments,
    command: 'set-app-settings',
    options: const <String>['settings-json'],
  );
  if (results == null || !hasRestCount(results, 0)) {
    return null;
  }
  final settingsJson = requiredCliOption(results, 'settings-json');
  if (settingsJson == null) {
    return null;
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(settingsJson);
  } on FormatException {
    return null;
  }

  final settings = appSettingsRecordFromJson(
    decoded,
    fallbackDefaultBottlePath: '',
  );
  return settings
      .flatMap(
        (value) => value.defaultBottlePath.value.trim().isEmpty
            ? const Option<AppSettingsRecord>.none()
            : Option.of(value),
      )
      .toNullable();
}

bool isJsonWineProcessListCommand(List<String> arguments) {
  return isJsonFlagOnlyCommand(arguments, 'list-wine-processes');
}

WineProcessTerminationRequest? parseJsonWineProcessTerminationRequest(
  List<String> arguments,
) {
  final results = parseJsonCliCommand(
    arguments,
    command: 'terminate-wine-process',
    options: const <String>['bottle', 'process'],
  );
  if (results == null || !hasRestCount(results, 0)) {
    return null;
  }

  final bottleId = requiredCliOption(results, 'bottle');
  final processId = requiredCliOption(results, 'process');
  if (bottleId == null || processId == null) {
    return null;
  }

  return WineProcessTerminationRequest(
    bottleId: BottleId(bottleId),
    processId: WineProcessId(processId),
  );
}

WineProcessGroupTerminationRequest? parseJsonWineProcessGroupTerminationRequest(
  List<String> arguments,
) {
  final results = parseJsonCliCommand(
    arguments,
    command: 'terminate-wine-processes',
    options: const <String>['bottle'],
  );
  if (results == null || !hasRestCount(results, 0)) {
    return null;
  }

  final bottleId = optionalCliOption(results, 'bottle');
  if (bottleId == null) {
    return results.wasParsed('bottle')
        ? null
        : WineProcessGroupTerminationRequest();
  }

  return WineProcessGroupTerminationRequest(
    bottleId: Option.of(BottleId(bottleId)),
  );
}
