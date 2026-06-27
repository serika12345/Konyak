part of '../../../konyak_cli.dart';

class ProgramSettingsRecord {
  const ProgramSettingsRecord({
    this.locale = '',
    this.arguments = '',
    this.environment = const ProgramEnvironmentOverrides.empty(),
    this.logging = const Option.none(),
  });

  final String locale;
  final String arguments;
  final ProgramEnvironmentOverrides environment;
  final Option<ProgramLoggingSettingsRecord> logging;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'locale': locale,
      'arguments': arguments,
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
  }) : additionalWineLoggingChannels = additionalWineLoggingChannels.trim(),
       logFilePath = logFilePath.trim();

  final bool createLogFile;
  final String additionalWineLoggingChannels;
  final String logFilePath;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'createLogFile': createLogFile,
      'additionalWineLoggingChannels': additionalWineLoggingChannels,
      'logFilePath': logFilePath,
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
