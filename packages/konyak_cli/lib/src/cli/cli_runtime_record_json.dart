import 'package:fpdart/fpdart.dart';

import '../domain/runtime/runtime_models.dart';
import '../domain/shared/domain_value_objects.dart';
import '../shared/model_constants.dart';

Map<String, Object?> runtimeRecordJson(RuntimeRecord runtime) {
  return <String, Object?>{
    'id': runtime.id.value,
    'name': runtime.name.value,
    'platform': runtime.platform.value,
    'architecture': runtime.architecture.value,
    'runnerKind': runtime.runnerKind.value,
    'isBundled': runtime.isBundled,
    'isUpdateable': runtime.isUpdateable,
    ..._runtimeJsonStringField('distributionKind', runtime.distributionKind),
    ...runtime.isInstalled.match(
      () => const <String, Object?>{},
      (value) => <String, Object?>{'isInstalled': value},
    ),
    ..._runtimeJsonStringField(
      'applicationSupportPath',
      runtime.applicationSupportPath,
    ),
    ..._runtimeJsonStringField('libraryPath', runtime.libraryPath),
    ..._runtimeJsonStringField('executablePath', runtime.executablePath),
    ...runtime.stack.match(
      () => const <String, Object?>{},
      (stack) => <String, Object?>{'stack': runtimeStackJson(stack)},
    ),
  };
}

Map<String, Object?> runtimeStackJson(RuntimeStack stack) {
  return <String, Object?>{
    'schemaVersion': runtimeStackSchemaVersion,
    'id': stack.id.value,
    'name': stack.name.value,
    'compatibilityTarget': stack.compatibilityTarget.value,
    'isComplete': stack.isComplete,
    'components': stack.components
        .map(runtimeStackComponentJson)
        .toList(growable: false),
    if (stack.backends.isNotEmpty)
      'backends': stack.backends
          .map(runtimeStackBackendJson)
          .toList(growable: false),
  };
}

Map<String, Object?> runtimeStackBackendJson(RuntimeStackBackend backend) {
  return <String, Object?>{
    'id': backend.id.value,
    'name': backend.name.value,
    'role': backend.role.value,
    'isAvailable': backend.isAvailable,
    'componentIds': backend.componentIds
        .map((value) => value.value)
        .toList(growable: false),
    'missingComponentIds': backend.missingComponentIds
        .map((value) => value.value)
        .toList(growable: false),
    'missingPaths': backend.missingPaths
        .map((value) => value.value)
        .toList(growable: false),
  };
}

Map<String, Object?> runtimeStackComponentJson(
  RuntimeStackComponent component,
) {
  return <String, Object?>{
    'id': component.id.value,
    'name': component.name.value,
    'role': component.role.value,
    'isRequired': component.isRequired,
    'isInstalled': component.isInstalled,
    'paths': component.paths
        .map((value) => value.value)
        .toList(growable: false),
    'missingPaths': component.missingPaths
        .map((value) => value.value)
        .toList(growable: false),
    ..._runtimeJsonStringField('version', component.version),
  };
}

Map<String, Object?> _runtimeJsonStringField(
  String key,
  Option<StringDomainValueObject> value,
) {
  return value.match(
    () => const <String, Object?>{},
    (item) => <String, Object?>{key: item.value},
  );
}
