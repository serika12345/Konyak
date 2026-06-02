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
      _stringMapEquals(left.environment, right.environment);
}

bool _stringMapEquals(Map<String, String> left, Map<String, String> right) {
  if (left.length != right.length) {
    return false;
  }

  for (final entry in left.entries) {
    if (right[entry.key] != entry.value) {
      return false;
    }
  }

  return true;
}
