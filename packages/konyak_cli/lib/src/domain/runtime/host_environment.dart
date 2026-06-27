part of '../../../konyak_cli.dart';

final class HostEnvironment {
  HostEnvironment(Map<String, String> variables)
    : _variables = variables
          .map(
            (name, value) => MapEntry(
              ProgramEnvironmentVariableName(name),
              ProgramEnvironmentVariableValue(value),
            ),
          )
          .lock;

  const HostEnvironment.empty() : _variables = const IMapConst({});

  final IMap<ProgramEnvironmentVariableName, ProgramEnvironmentVariableValue>
  _variables;

  String? operator [](String name) {
    return _variables[ProgramEnvironmentVariableName(name)]?.value;
  }

  String? nonEmptyValue(String name) {
    final value = _variables[ProgramEnvironmentVariableName(name)]?.value;
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    return value;
  }

  Map<String, String> toMap() {
    return _variables
        .map((name, value) => MapEntry(name.value, value.value))
        .unlockView;
  }

  @override
  bool operator ==(Object other) {
    return other is HostEnvironment && other._variables == _variables;
  }

  @override
  int get hashCode => _variables.hashCode;
}
