import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:fpdart/fpdart.dart';

import '../shared/domain_value_objects.dart';

const konyakChildProcessRulesEnvironmentVariable = 'KONYAK_CHILD_PROCESS_RULES';

bool isKonyakChildProcessRulesEnvironmentVariable(String name) {
  return name.toUpperCase() == konyakChildProcessRulesEnvironmentVariable;
}

/// Intentionally hand-written instead of Freezed: the public boundary accepts
/// raw environment maps, but the validated immutable map storage stays private.
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

  ProgramRunEnvironment toRunEnvironmentWhere(
    bool Function(ProgramEnvironmentVariableName name) includeName,
  ) {
    return ProgramRunEnvironment(
      Map<String, String>.fromEntries(
        _variables.entries
            .where((entry) => includeName(entry.key))
            .map((entry) => MapEntry(entry.key.value, entry.value.value)),
      ),
    );
  }

  ProgramEnvironmentOverrides add(
    ProgramEnvironmentVariableName name,
    ProgramEnvironmentVariableValue value,
  ) {
    return ProgramEnvironmentOverrides._withVariables(
      _variables.add(name, value),
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

/// Intentionally hand-written instead of Freezed: generated fields would expose
/// the internal immutable map and make storage details part of the domain API.
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

  ProgramRunEnvironment add(
    ProgramEnvironmentVariableName name,
    ProgramEnvironmentVariableValue value,
  ) {
    return ProgramRunEnvironment._withVariables(_variables.add(name, value));
  }

  ProgramRunEnvironment._withVariables(this._variables);

  @override
  bool operator ==(Object other) {
    return other is ProgramRunEnvironment && other._variables == _variables;
  }

  @override
  int get hashCode => _variables.hashCode;
}
