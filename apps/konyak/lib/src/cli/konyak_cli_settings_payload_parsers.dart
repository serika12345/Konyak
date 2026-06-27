part of 'konyak_cli_client.dart';

ProgramSettingsLoadResult _parseProgramSettingsPayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (error) {
    return ProgramSettingsLoadFailure(
      exitCode: 0,
      message: error.message,
      diagnostic: '',
    );
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return const ProgramSettingsLoadFailure(
      exitCode: 0,
      message: 'Unsupported program settings payload.',
      diagnostic: '',
    );
  }

  final error = decoded['error'];
  if (error is Map<String, Object?>) {
    final code = error['code'];
    final bottleId = error['bottleId'];
    final message = error['message'];
    if (code == 'bottleNotFound' && bottleId is String && message is String) {
      return MissingProgramSettingsBottle(bottleId: bottleId, message: message);
    }

    return ProgramSettingsLoadFailure(
      exitCode: 0,
      message: message is String ? message : 'Program settings failed.',
      diagnostic: '',
    );
  }

  final programSettings = decoded['programSettings'];
  if (programSettings is! Map<String, Object?>) {
    return const ProgramSettingsLoadFailure(
      exitCode: 0,
      message: 'Missing programSettings payload.',
      diagnostic: '',
    );
  }

  final bottleId = programSettings['bottleId'];
  final programPath = programSettings['programPath'];
  final settings = _parseProgramSettingsSummary(programSettings['settings']);
  if (bottleId is! String || programPath is! String || settings == null) {
    return const ProgramSettingsLoadFailure(
      exitCode: 0,
      message: 'Invalid programSettings payload.',
      diagnostic: '',
    );
  }

  return LoadedProgramSettings(
    bottleId: bottleId,
    programPath: programPath,
    settings: settings,
  );
}

AppSettingsLoadResult _parseAppSettingsPayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (error) {
    return AppSettingsLoadFailure(
      exitCode: 0,
      message: error.message,
      diagnostic: '',
    );
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return const AppSettingsLoadFailure(
      exitCode: 0,
      message: 'Unsupported app settings payload.',
      diagnostic: '',
    );
  }

  final error = decoded['error'];
  if (error is Map<String, Object?>) {
    final message = error['message'];
    return AppSettingsLoadFailure(
      exitCode: 0,
      message: message is String ? message : 'App settings failed.',
      diagnostic: '',
    );
  }

  final settings = _parseAppSettingsSummary(decoded['appSettings']);
  if (settings == null) {
    return const AppSettingsLoadFailure(
      exitCode: 0,
      message: 'Invalid appSettings payload.',
      diagnostic: '',
    );
  }

  return LoadedAppSettings(settings);
}

AppSettingsSummary? _parseAppSettingsSummary(Object? value) {
  if (value is! Map<String, Object?>) {
    return null;
  }

  final terminateWineProcessesOnClose = value['terminateWineProcessesOnClose'];
  final defaultBottlePath = value['defaultBottlePath'];
  final appearanceMode = appAppearanceModeFromJson(value['appearanceMode']);
  final languageMode = appLanguageModeFromJson(value['languageMode']);
  final automaticallyCheckForKonyakUpdates =
      value['automaticallyCheckForKonyakUpdates'];
  final automaticallyCheckForWineUpdates =
      value['automaticallyCheckForWineUpdates'];
  final automaticallyPinNewInstalledPrograms =
      value['automaticallyPinNewInstalledPrograms'];

  if (terminateWineProcessesOnClose is! bool ||
      defaultBottlePath is! String ||
      defaultBottlePath.trim().isEmpty ||
      appearanceMode == null ||
      languageMode == null ||
      automaticallyCheckForKonyakUpdates is! bool ||
      automaticallyCheckForWineUpdates is! bool ||
      (automaticallyPinNewInstalledPrograms != null &&
          automaticallyPinNewInstalledPrograms is! bool)) {
    return null;
  }

  return AppSettingsSummary(
    terminateWineProcessesOnClose: terminateWineProcessesOnClose,
    defaultBottlePath: defaultBottlePath,
    appearanceMode: appearanceMode,
    languageMode: languageMode,
    automaticallyCheckForKonyakUpdates: automaticallyCheckForKonyakUpdates,
    automaticallyCheckForWineUpdates: automaticallyCheckForWineUpdates,
    automaticallyPinNewInstalledPrograms:
        automaticallyPinNewInstalledPrograms is bool
        ? automaticallyPinNewInstalledPrograms
        : true,
  );
}

ProgramSettingsSummary? _parseProgramSettingsSummary(Object? value) {
  if (value is! Map<String, Object?>) {
    return null;
  }

  final locale = value['locale'];
  final arguments = value['arguments'];
  final environment = _parseStringMap(value['environment']);
  final logging = _parseProgramLoggingSettingsSummary(value['logging']);
  if (locale is! String ||
      arguments is! String ||
      environment == null ||
      logging == null) {
    return null;
  }

  return ProgramSettingsSummary(
    locale: locale,
    arguments: arguments,
    environment: environment,
    logging: logging,
  );
}

ProgramLoggingSettingsSummary? _parseProgramLoggingSettingsSummary(
  Object? value,
) {
  if (value == null) {
    return const ProgramLoggingSettingsSummary();
  }
  if (value is! Map<String, Object?>) {
    return null;
  }

  final createLogFile = value['createLogFile'];
  final additionalWineLoggingChannels = value['additionalWineLoggingChannels'];
  final logFilePath = value['logFilePath'];
  if ((createLogFile != null && createLogFile is! bool) ||
      (additionalWineLoggingChannels != null &&
          additionalWineLoggingChannels is! String) ||
      (logFilePath != null && logFilePath is! String)) {
    return null;
  }

  return ProgramLoggingSettingsSummary(
    createLogFile: createLogFile is bool ? createLogFile : true,
    additionalWineLoggingChannels: additionalWineLoggingChannels is String
        ? additionalWineLoggingChannels
        : '',
    logFilePath: logFilePath is String ? logFilePath : '',
  );
}

Map<String, String>? _parseStringMap(Object? value) {
  if (value is! Map<String, Object?>) {
    return null;
  }

  final environment = <String, String>{};
  for (final entry in value.entries) {
    if (entry.value is! String) {
      return null;
    }
    environment[entry.key] = entry.value as String;
  }

  return Map.unmodifiable(environment);
}

bool _isOptionalString(Object? value) {
  return value == null || value is String;
}
