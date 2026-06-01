part of '../konyak_cli.dart';

class ProgramSettingsRecord {
  const ProgramSettingsRecord({
    this.locale = '',
    this.arguments = '',
    this.environment = const <String, String>{},
  });

  final String locale;
  final String arguments;
  final Map<String, String> environment;

  static ProgramSettingsRecord? fromJson(Object? value) {
    final settings = _objectMap(value);
    if (settings == null) {
      return null;
    }

    final locale = settings['locale'];
    final arguments = settings['arguments'];
    final environment = _stringMap(settings['environment']);
    if ((locale != null && locale is! String) ||
        (arguments != null && arguments is! String) ||
        environment == null) {
      return null;
    }

    return ProgramSettingsRecord(
      locale: locale is String ? locale : '',
      arguments: arguments is String ? arguments : '',
      environment: environment,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'locale': locale,
      'arguments': arguments,
      'environment': environment,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is ProgramSettingsRecord &&
        other.locale == locale &&
        other.arguments == arguments &&
        _mapEquals(other.environment, environment);
  }

  @override
  int get hashCode {
    final environmentKeys = environment.keys.toList(growable: false)..sort();
    return Object.hash(
      locale,
      arguments,
      Object.hashAll(
        environmentKeys.map((key) => Object.hash(key, environment[key])),
      ),
    );
  }
}

List<PinnedProgramRecord> _parsePinnedPrograms(Object? value) {
  if (value is! List<dynamic>) {
    return const <PinnedProgramRecord>[];
  }

  final programs = <PinnedProgramRecord>[];
  for (final item in value) {
    if (item is! Map<String, dynamic>) {
      return const <PinnedProgramRecord>[];
    }

    final name = item['name'];
    final path = item['path'];
    final removable = item['removable'];
    final iconPath = item['iconPath'];
    if (name is! String || path is! String) {
      return const <PinnedProgramRecord>[];
    }
    if (iconPath != null && iconPath is! String) {
      return const <PinnedProgramRecord>[];
    }

    programs.add(
      PinnedProgramRecord(
        name: name,
        path: path,
        removable: removable is bool && removable,
        iconPath: iconPath is String ? iconPath : null,
      ),
    );
  }

  return List.unmodifiable(programs);
}
