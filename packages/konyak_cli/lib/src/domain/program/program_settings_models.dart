part of '../../../konyak_cli.dart';

class ProgramSettingsRecord {
  ProgramSettingsRecord({
    String locale = '',
    String arguments = '',
    this.environment = const ProgramEnvironmentOverrides.empty(),
    this.logging = const Option.none(),
  }) : locale = ProgramLocale(locale),
       arguments = ProgramArguments(arguments);

  final ProgramLocale locale;
  final ProgramArguments arguments;
  final ProgramEnvironmentOverrides environment;
  final Option<ProgramLoggingSettingsRecord> logging;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'locale': locale.value,
      'arguments': arguments.value,
      'environment': environment.toMap(),
      ...logging.match(
        () => const <String, Object?>{},
        (value) => <String, Object?>{'logging': value.toJson()},
      ),
    };
  }

  @override
  bool operator ==(Object other) {
    return other is ProgramSettingsRecord &&
        other.locale == locale &&
        other.arguments == arguments &&
        other.environment == environment &&
        other.logging == logging;
  }

  @override
  int get hashCode {
    return Object.hash(locale, arguments, environment, logging);
  }
}

class ProgramLoggingSettingsRecord {
  ProgramLoggingSettingsRecord({
    this.createLogFile = true,
    String additionalWineLoggingChannels = '',
    String logFilePath = '',
  }) : additionalWineLoggingChannels = WineDebugChannels(
         additionalWineLoggingChannels,
       ),
       logFilePath = ProgramLogPath(logFilePath);

  final bool createLogFile;
  final WineDebugChannels additionalWineLoggingChannels;
  final ProgramLogPath logFilePath;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'createLogFile': createLogFile,
      'additionalWineLoggingChannels': additionalWineLoggingChannels.value,
      'logFilePath': logFilePath.value,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is ProgramLoggingSettingsRecord &&
        other.createLogFile == createLogFile &&
        other.additionalWineLoggingChannels == additionalWineLoggingChannels &&
        other.logFilePath == logFilePath;
  }

  @override
  int get hashCode {
    return Object.hash(
      createLogFile,
      additionalWineLoggingChannels,
      logFilePath,
    );
  }
}
