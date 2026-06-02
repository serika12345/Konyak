part of '../../../konyak_cli.dart';

final class ProgramEnvironmentOverrides {
  ProgramEnvironmentOverrides(Map<String, String> variables)
    : _variables = variables
          .map(
            (name, value) =>
                MapEntry(_requiredEnvironmentVariableName(name), value),
          )
          .lock;

  const ProgramEnvironmentOverrides.empty() : _variables = const IMapConst({});

  final IMap<String, String> _variables;

  Map<String, String> toMap() {
    return _variables.unlockView;
  }

  ProgramEnvironmentOverrides add(String name, String value) {
    return ProgramEnvironmentOverrides(
      _variables.add(_requiredEnvironmentVariableName(name), value).unlockView,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProgramEnvironmentOverrides &&
        other._variables == _variables;
  }

  @override
  int get hashCode => _variables.hashCode;
}

final class ProgramRunEnvironment {
  ProgramRunEnvironment(Map<String, String> variables)
    : _variables = variables
          .map(
            (name, value) =>
                MapEntry(_requiredEnvironmentVariableName(name), value),
          )
          .lock;

  const ProgramRunEnvironment.empty() : _variables = const IMapConst({});

  final IMap<String, String> _variables;

  String? operator [](String name) {
    return _variables[name];
  }

  Map<String, String> toMap() {
    return _variables.unlockView;
  }

  @override
  bool operator ==(Object other) {
    return other is ProgramRunEnvironment && other._variables == _variables;
  }

  @override
  int get hashCode => _variables.hashCode;
}

String _requiredEnvironmentVariableName(String value) {
  final name = _requiredNonBlankDomainString(
    value,
    'environment variable name',
  );
  if (name.contains('=')) {
    throw ArgumentError.value(value, 'environment variable name');
  }

  return name;
}
