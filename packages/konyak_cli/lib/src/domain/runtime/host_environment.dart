part of '../../../konyak_cli.dart';

final class HostEnvironment {
  HostEnvironment(Map<String, String> variables)
    : _variables = variables
          .map(
            (name, value) =>
                MapEntry(_requiredEnvironmentVariableName(name), value),
          )
          .lock;

  const HostEnvironment.empty() : _variables = const IMapConst({});

  final IMap<String, String> _variables;

  String? operator [](String name) {
    return _variables[name];
  }

  String? nonEmptyValue(String name) {
    final value = _variables[_requiredEnvironmentVariableName(name)];
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    return value;
  }

  Map<String, String> toMap() {
    return _variables.unlockView;
  }

  @override
  bool operator ==(Object other) {
    return other is HostEnvironment && other._variables == _variables;
  }

  @override
  int get hashCode => _variables.hashCode;
}
