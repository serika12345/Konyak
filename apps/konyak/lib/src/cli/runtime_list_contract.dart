import 'dart:convert';

import '../runtimes/runtime_summary.dart';

const runtimeListSchemaVersion = 1;
const runtimeStackSchemaVersion = 1;

sealed class RuntimeListParseResult {
  const RuntimeListParseResult();
}

final class ParsedRuntimeList extends RuntimeListParseResult {
  const ParsedRuntimeList(this.runtimes);

  final List<RuntimeSummary> runtimes;
}

final class RuntimeListParseFailure extends RuntimeListParseResult {
  const RuntimeListParseFailure(this.message);

  final String message;
}

RuntimeListParseResult parseRuntimeListPayload(String payload) {
  final Object? decoded;

  try {
    decoded = jsonDecode(payload);
  } on FormatException {
    return const RuntimeListParseFailure(
      'Runtime list payload is not valid JSON.',
    );
  }

  if (decoded is! Map<String, dynamic>) {
    return const RuntimeListParseFailure(
      'Runtime list payload must be an object.',
    );
  }

  final Object? schemaVersion = decoded['schemaVersion'];
  if (schemaVersion != runtimeListSchemaVersion) {
    return const RuntimeListParseFailure(
      'Unsupported runtime list schema version.',
    );
  }

  final Object? runtimeValues = decoded['runtimes'];
  if (runtimeValues is! List<dynamic>) {
    return const RuntimeListParseFailure(
      'Runtime list payload must contain a runtimes array.',
    );
  }

  final runtimes = _parseRuntimes(runtimeValues);
  if (runtimes == null) {
    return const RuntimeListParseFailure(
      'Runtime list payload contains an invalid runtime record.',
    );
  }

  return ParsedRuntimeList(List.unmodifiable(runtimes));
}

List<RuntimeSummary>? _parseRuntimes(List<dynamic> runtimeValues) {
  final runtimes = runtimeValues
      .map(parseRuntimeRecord)
      .toList(growable: false);

  if (runtimes.any((runtime) => runtime == null)) {
    return null;
  }

  return runtimes.whereType<RuntimeSummary>().toList(growable: false);
}

RuntimeSummary? parseRuntimeRecord(Object? value) {
  if (value is! Map<String, dynamic>) {
    return null;
  }

  final Object? id = value['id'];
  final Object? name = value['name'];
  final Object? platform = value['platform'];
  final Object? architecture = value['architecture'];
  final Object? runnerKind = value['runnerKind'];
  final Object? isBundled = value['isBundled'];
  final Object? isUpdateable = value['isUpdateable'];
  final Object? distributionKind = value['distributionKind'];
  final Object? isInstalled = value['isInstalled'];
  final Object? applicationSupportPath = value['applicationSupportPath'];
  final Object? libraryPath = value['libraryPath'];
  final Object? executablePath = value['executablePath'];
  final Object? stack = value['stack'];

  if (id is! String ||
      name is! String ||
      platform is! String ||
      architecture is! String ||
      runnerKind is! String ||
      isBundled is! bool ||
      isUpdateable is! bool) {
    return null;
  }

  if (!_isOptionalBool(isInstalled) ||
      !_isOptionalString(distributionKind) ||
      !_isOptionalString(applicationSupportPath) ||
      !_isOptionalString(libraryPath) ||
      !_isOptionalString(executablePath)) {
    return null;
  }

  final runtimeStack = _parseOptionalRuntimeStack(stack);
  if (stack != null && runtimeStack == null) {
    return null;
  }

  return RuntimeSummary(
    id: id,
    name: name,
    platform: platform,
    architecture: architecture,
    runnerKind: runnerKind,
    isBundled: isBundled,
    isUpdateable: isUpdateable,
    distributionKind: distributionKind as String?,
    isInstalled: isInstalled as bool?,
    applicationSupportPath: applicationSupportPath as String?,
    libraryPath: libraryPath as String?,
    executablePath: executablePath as String?,
    stack: runtimeStack,
  );
}

RuntimeStackSummary? _parseOptionalRuntimeStack(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is! Map<String, dynamic>) {
    return null;
  }

  final Object? id = value['id'];
  final Object? schemaVersion = value['schemaVersion'];
  final Object? name = value['name'];
  final Object? compatibilityTarget = value['compatibilityTarget'];
  final Object? isComplete = value['isComplete'];
  final Object? components = value['components'];
  final Object? backends = value['backends'];

  if (schemaVersion != runtimeStackSchemaVersion ||
      id is! String ||
      name is! String ||
      compatibilityTarget is! String ||
      isComplete is! bool ||
      components is! List<dynamic>) {
    return null;
  }

  final parsedComponents = components
      .map(_parseRuntimeStackComponent)
      .toList(growable: false);
  if (parsedComponents.any((component) => component == null)) {
    return null;
  }
  final runtimeComponents = parsedComponents
      .whereType<RuntimeStackComponentSummary>()
      .toList(growable: false);

  final parsedBackends = _parseOptionalRuntimeStackBackends(backends);
  if (parsedBackends == null) {
    return null;
  }

  final runtimeStack = RuntimeStackSummary(
    id: id,
    name: name,
    compatibilityTarget: compatibilityTarget,
    components: runtimeComponents,
    backends: parsedBackends,
  );
  if (isComplete != runtimeStack.isComplete) {
    return null;
  }

  return runtimeStack;
}

List<RuntimeStackBackendSummary>? _parseOptionalRuntimeStackBackends(
  Object? value,
) {
  if (value == null) {
    return const <RuntimeStackBackendSummary>[];
  }

  if (value is! List<dynamic>) {
    return null;
  }

  final parsedBackends = value
      .map(_parseRuntimeStackBackend)
      .toList(growable: false);
  if (parsedBackends.any((backend) => backend == null)) {
    return null;
  }

  return parsedBackends.whereType<RuntimeStackBackendSummary>().toList(
    growable: false,
  );
}

RuntimeStackBackendSummary? _parseRuntimeStackBackend(Object? value) {
  if (value is! Map<String, dynamic>) {
    return null;
  }

  final Object? id = value['id'];
  final Object? name = value['name'];
  final Object? role = value['role'];
  final Object? isAvailable = value['isAvailable'];
  final componentIds = _parseStringList(value['componentIds']);
  final missingComponentIds = _parseStringList(value['missingComponentIds']);
  final missingPaths = _parseStringList(value['missingPaths']);

  if (id is! String ||
      name is! String ||
      role is! String ||
      isAvailable is! bool ||
      componentIds == null ||
      missingComponentIds == null ||
      missingPaths == null) {
    return null;
  }
  final runtimeStackBackend = RuntimeStackBackendSummary(
    id: id,
    name: name,
    role: role,
    componentIds: componentIds,
    missingComponentIds: missingComponentIds,
    missingPaths: missingPaths,
  );
  if (isAvailable != runtimeStackBackend.isAvailable) {
    return null;
  }

  return runtimeStackBackend;
}

RuntimeStackComponentSummary? _parseRuntimeStackComponent(Object? value) {
  if (value is! Map<String, dynamic>) {
    return null;
  }

  final Object? id = value['id'];
  final Object? name = value['name'];
  final Object? role = value['role'];
  final Object? isRequired = value['isRequired'];
  final Object? isInstalled = value['isInstalled'];
  final paths = _parseStringList(value['paths']);
  final missingPaths = _parseStringList(value['missingPaths']);
  final Object? version = value['version'];

  if (id is! String ||
      name is! String ||
      role is! String ||
      isRequired is! bool ||
      isInstalled is! bool ||
      paths == null ||
      missingPaths == null ||
      !_isOptionalString(version)) {
    return null;
  }
  final runtimeStackComponent = RuntimeStackComponentSummary(
    id: id,
    name: name,
    role: role,
    isRequired: isRequired,
    paths: paths,
    missingPaths: missingPaths,
    version: version as String?,
  );
  if (isInstalled != runtimeStackComponent.isInstalled) {
    return null;
  }

  return runtimeStackComponent;
}

List<String>? _parseStringList(Object? value) {
  if (value is! List<dynamic>) {
    return null;
  }

  final strings = value.whereType<String>().toList(growable: false);
  if (strings.length != value.length) {
    return null;
  }

  return strings;
}

bool _isOptionalBool(Object? value) {
  return value == null || value is bool;
}

bool _isOptionalString(Object? value) {
  return value == null || value is String;
}
