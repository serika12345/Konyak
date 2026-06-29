import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:fpdart/fpdart.dart';

import '../shared/domain_value_objects.dart';

/// Intentionally hand-written instead of Freezed: host environment variables
/// enter as raw maps, then stay hidden behind validated immutable storage.
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

  Option<String> operator [](String name) {
    return _value(name).map((value) => value.value);
  }

  Option<String> nonEmptyValue(String name) {
    return this[name].flatMap(
      (value) => value.trim().isEmpty ? const Option.none() : Option.of(value),
    );
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

  Option<ProgramEnvironmentVariableValue> _value(String name) {
    final key = ProgramEnvironmentVariableName(name);
    if (!_variables.containsKey(key)) {
      return const Option.none();
    }

    return Option.of(_variables[key] as ProgramEnvironmentVariableValue);
  }
}
