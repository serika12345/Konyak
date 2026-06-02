part of '../../../konyak_cli.dart';

class ProgramSettingsRecord {
  const ProgramSettingsRecord({
    this.locale = '',
    this.arguments = '',
    this.environment = const ProgramEnvironmentOverrides.empty(),
  });

  final String locale;
  final String arguments;
  final ProgramEnvironmentOverrides environment;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'locale': locale,
      'arguments': arguments,
      'environment': environment.toMap(),
    };
  }

  @override
  bool operator ==(Object other) {
    return other is ProgramSettingsRecord &&
        other.locale == locale &&
        other.arguments == arguments &&
        other.environment == environment;
  }

  @override
  int get hashCode {
    return Object.hash(locale, arguments, environment);
  }
}
