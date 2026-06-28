import '../domain/program/program_settings_models.dart';

Map<String, Object?> programSettingsRecordJson(ProgramSettingsRecord settings) {
  return <String, Object?>{
    'locale': settings.locale.value,
    'arguments': settings.arguments.value,
    'environment': settings.environment.toMap(),
    ...settings.logging.match(
      () => const <String, Object?>{},
      (logging) => <String, Object?>{
        'logging': programLoggingSettingsRecordJson(logging),
      },
    ),
  };
}

Map<String, Object?> programLoggingSettingsRecordJson(
  ProgramLoggingSettingsRecord logging,
) {
  return <String, Object?>{
    'createLogFile': logging.createLogFile,
    'additionalWineLoggingChannels':
        logging.additionalWineLoggingChannels.value,
    'logFilePath': logging.logFilePath.value,
  };
}
