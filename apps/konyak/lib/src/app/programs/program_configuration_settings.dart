import '../../bottles/bottle_summary.dart';

class ProgramEnvironmentEntry {
  const ProgramEnvironmentEntry({required this.name, required this.value});

  final String name;
  final String value;
}

Map<String, String> programEnvironmentFromEntries(
  Iterable<ProgramEnvironmentEntry> entries,
) {
  final environment = <String, String>{};
  for (final entry in entries) {
    final name = entry.name.trim();
    if (name.isEmpty) {
      continue;
    }
    environment[name] = entry.value;
  }

  return Map.unmodifiable(environment);
}

bool sameProgramSettings(
  ProgramSettingsSummary? left,
  ProgramSettingsSummary? right,
) {
  if (left == null || right == null) {
    return left == right;
  }

  return left.locale == right.locale &&
      left.arguments == right.arguments &&
      left.environment == right.environment &&
      sameProgramLoggingSettings(left.logging, right.logging);
}

bool sameProgramLoggingSettings(
  ProgramLoggingSettingsSummary left,
  ProgramLoggingSettingsSummary right,
) {
  return left.createLogFile == right.createLogFile &&
      left.additionalWineLoggingChannels ==
          right.additionalWineLoggingChannels &&
      left.logFilePath == right.logFilePath;
}
