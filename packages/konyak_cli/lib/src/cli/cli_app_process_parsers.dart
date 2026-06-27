part of '../../konyak_cli.dart';

bool _isJsonAppUpdateCheckCommand(List<String> arguments) {
  return _isJsonFlagOnlyCommand(arguments, 'check-app-update');
}

bool _isJsonAppUpdateInstallCommand(List<String> arguments) {
  return _isJsonFlagOnlyCommand(arguments, 'install-app-update');
}

bool _isJsonAppSettingsGetCommand(List<String> arguments) {
  return _isJsonFlagOnlyCommand(arguments, 'get-app-settings');
}

bool _isJsonLinuxFileAssociationInstallCommand(List<String> arguments) {
  return _isJsonFlagOnlyCommand(arguments, 'install-linux-file-associations');
}

AppSettingsRecord? _parseJsonAppSettingsUpdateRequest(List<String> arguments) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'set-app-settings',
    options: const <String>['settings-json'],
  );
  if (results == null || !_hasRestCount(results, 0)) {
    return null;
  }
  final settingsJson = _requiredCliOption(results, 'settings-json');
  if (settingsJson == null) {
    return null;
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(settingsJson);
  } on FormatException {
    return null;
  }

  final settings = _appSettingsRecordFromJson(
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

bool _isJsonWineProcessListCommand(List<String> arguments) {
  return _isJsonFlagOnlyCommand(arguments, 'list-wine-processes');
}

WineProcessTerminationRequest? _parseJsonWineProcessTerminationRequest(
  List<String> arguments,
) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'terminate-wine-process',
    options: const <String>['bottle', 'process'],
  );
  if (results == null || !_hasRestCount(results, 0)) {
    return null;
  }

  final bottleId = _requiredCliOption(results, 'bottle');
  final processId = _requiredCliOption(results, 'process');
  if (bottleId == null || processId == null) {
    return null;
  }

  return WineProcessTerminationRequest(
    bottleId: bottleId,
    processId: processId,
  );
}

WineProcessGroupTerminationRequest?
_parseJsonWineProcessGroupTerminationRequest(List<String> arguments) {
  final results = _parseJsonCliCommand(
    arguments,
    command: 'terminate-wine-processes',
    options: const <String>['bottle'],
  );
  if (results == null || !_hasRestCount(results, 0)) {
    return null;
  }

  final bottleId = _optionalCliOption(results, 'bottle');
  if (bottleId == null) {
    return results.wasParsed('bottle')
        ? null
        : WineProcessGroupTerminationRequest();
  }

  return WineProcessGroupTerminationRequest(bottleId: Option.of(bottleId));
}
