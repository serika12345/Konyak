import '../domain/runtime/runtime_validation_models.dart';

Map<String, Object?> runtimeValidationRecordJson(
  RuntimeValidationRecord validation,
) {
  return <String, Object?>{
    'runtimeId': validation.runtimeId.value,
    'isValid': validation.isValid,
    'checks': validation.checks
        .map(runtimeValidationCheckJson)
        .toList(growable: false),
  };
}

Map<String, Object?> runtimeValidationCheckJson(RuntimeValidationCheck check) {
  return <String, Object?>{
    'id': check.id,
    'name': check.name,
    'isRequired': check.isRequired,
    'isPassed': check.isPassed,
    'message': check.message,
  };
}
