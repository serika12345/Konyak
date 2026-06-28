import 'package:fpdart/fpdart.dart';

import '../shared/domain_value_objects.dart';
import 'program_run_environment.dart';

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
