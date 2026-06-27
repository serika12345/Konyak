part of '../../../konyak_cli.dart';

final class ProgramEnvironmentOverrides {
  ProgramEnvironmentOverrides(Map<String, String> variables)
    : _variables = variables
          .map(
            (name, value) => MapEntry(
              ProgramEnvironmentVariableName(name),
              ProgramEnvironmentVariableValue(value),
            ),
          )
          .lock;

  const ProgramEnvironmentOverrides.empty() : _variables = const IMapConst({});

  final IMap<ProgramEnvironmentVariableName, ProgramEnvironmentVariableValue>
  _variables;

  Map<String, String> toMap() {
    return _variables
        .map((name, value) => MapEntry(name.value, value.value))
        .unlockView;
  }

  ProgramEnvironmentOverrides add(String name, String value) {
    return ProgramEnvironmentOverrides._withVariables(
      _variables.add(
        ProgramEnvironmentVariableName(name),
        ProgramEnvironmentVariableValue(value),
      ),
    );
  }

  ProgramEnvironmentOverrides._withVariables(this._variables);

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
            (name, value) => MapEntry(
              ProgramEnvironmentVariableName(name),
              ProgramEnvironmentVariableValue(value),
            ),
          )
          .lock;

  const ProgramRunEnvironment.empty() : _variables = const IMapConst({});

  final IMap<ProgramEnvironmentVariableName, ProgramEnvironmentVariableValue>
  _variables;

  Option<String> operator [](String name) {
    final key = ProgramEnvironmentVariableName(name);
    if (!_variables.containsKey(key)) {
      return const Option.none();
    }

    return Option.of(
      (_variables[key] as ProgramEnvironmentVariableValue).value,
    );
  }

  Map<String, String> toMap() {
    return _variables
        .map((name, value) => MapEntry(name.value, value.value))
        .unlockView;
  }

  ProgramRunEnvironment merge(ProgramRunEnvironment other) {
    return ProgramRunEnvironment._withVariables(
      _variables.addAll(other._variables),
    );
  }

  ProgramRunEnvironment add(String name, String value) {
    return ProgramRunEnvironment._withVariables(
      _variables.add(
        ProgramEnvironmentVariableName(name),
        ProgramEnvironmentVariableValue(value),
      ),
    );
  }

  ProgramRunEnvironment._withVariables(this._variables);

  @override
  bool operator ==(Object other) {
    return other is ProgramRunEnvironment && other._variables == _variables;
  }

  @override
  int get hashCode => _variables.hashCode;
}
