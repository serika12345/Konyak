part of '../konyak_cli.dart';

class ProgramSettingsRecord {
  ProgramSettingsRecord({
    this.locale = '',
    this.arguments = '',
    Map<String, String> environment = const <String, String>{},
  }) : environment = Map.unmodifiable(environment);

  final String locale;
  final String arguments;
  final Map<String, String> environment;

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
