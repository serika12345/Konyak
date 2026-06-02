part of '../../../konyak_cli.dart';

class ProgramSettingsRecord {
  ProgramSettingsRecord({
    this.locale = '',
    this.arguments = '',
    Map<String, String> environment = const <String, String>{},
  }) : environment = environment.lock;

  final String locale;
  final String arguments;
  final IMap<String, String> environment;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'locale': locale,
      'arguments': arguments,
      'environment': environment.unlockView,
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
