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

sealed class RuntimeRecordParseResult {
  const RuntimeRecordParseResult();
}

final class ParsedRuntimeRecord extends RuntimeRecordParseResult {
  const ParsedRuntimeRecord(this.runtime);

  final RuntimeSummary runtime;
}

final class InvalidRuntimeRecord extends RuntimeRecordParseResult {
  const InvalidRuntimeRecord();
}

sealed class _RuntimeStackParseResult {
  const _RuntimeStackParseResult();
}

final class _ParsedRuntimeStack extends _RuntimeStackParseResult {
  const _ParsedRuntimeStack(this.stack);

  final RuntimeStackSummary stack;
}

final class _MissingRuntimeStack extends _RuntimeStackParseResult {
  const _MissingRuntimeStack();
}

final class _InvalidRuntimeStack extends _RuntimeStackParseResult {
  const _InvalidRuntimeStack();
}

sealed class _PayloadParseResult<T> {
  const _PayloadParseResult();
}

final class _ParsedPayload<T> extends _PayloadParseResult<T> {
  const _ParsedPayload(this.value);

  final T value;
}

final class _InvalidPayload<T> extends _PayloadParseResult<T> {
  const _InvalidPayload();
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

  return switch (_parseRuntimes(runtimeValues)) {
    _ParsedPayload(:final value) => ParsedRuntimeList(List.unmodifiable(value)),
    _InvalidPayload() => const RuntimeListParseFailure(
      'Runtime list payload contains an invalid runtime record.',
    ),
  };
}

_PayloadParseResult<List<RuntimeSummary>> _parseRuntimes(
  List<dynamic> runtimeValues,
) {
  final runtimes = <RuntimeSummary>[];
  for (final runtimeValue in runtimeValues) {
    switch (parseRuntimeRecord(runtimeValue)) {
      case ParsedRuntimeRecord(:final runtime):
        runtimes.add(runtime);
      case InvalidRuntimeRecord():
        return const _InvalidPayload<List<RuntimeSummary>>();
    }
  }

  return _ParsedPayload(List.unmodifiable(runtimes));
}

RuntimeRecordParseResult parseRuntimeRecord(Object? value) {
  if (value is! Map<String, dynamic>) {
    return const InvalidRuntimeRecord();
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
    return const InvalidRuntimeRecord();
  }

  if (!_isOptionalBool(isInstalled) ||
      !_isOptionalString(distributionKind) ||
      !_isOptionalString(applicationSupportPath) ||
      !_isOptionalString(libraryPath) ||
      !_isOptionalString(executablePath)) {
    return const InvalidRuntimeRecord();
  }

  return switch (_parseOptionalRuntimeStack(stack)) {
    _ParsedRuntimeStack(:final stack) => ParsedRuntimeRecord(
      RuntimeSummary(
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
        stack: stack,
      ),
    ),
    _MissingRuntimeStack() => ParsedRuntimeRecord(
      RuntimeSummary(
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
      ),
    ),
    _InvalidRuntimeStack() => const InvalidRuntimeRecord(),
  };
}

_RuntimeStackParseResult _parseOptionalRuntimeStack(Object? value) {
  if (value == null) {
    return const _MissingRuntimeStack();
  }

  if (value is! Map<String, dynamic>) {
    return const _InvalidRuntimeStack();
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
    return const _InvalidRuntimeStack();
  }

  final runtimeComponents = <RuntimeStackComponentSummary>[];
  for (final component in components) {
    switch (_parseRuntimeStackComponent(component)) {
      case _ParsedPayload(:final value):
        runtimeComponents.add(value);
      case _InvalidPayload():
        return const _InvalidRuntimeStack();
    }
  }

  return switch (_parseOptionalRuntimeStackBackends(backends)) {
    _ParsedPayload(value: final parsedBackends) => (() {
      final runtimeStack = RuntimeStackSummary(
        id: id,
        name: name,
        compatibilityTarget: compatibilityTarget,
        components: runtimeComponents,
        backends: parsedBackends,
      );
      if (isComplete != runtimeStack.isComplete) {
        return const _InvalidRuntimeStack();
      }

      return _ParsedRuntimeStack(runtimeStack);
    })(),
    _InvalidPayload() => const _InvalidRuntimeStack(),
  };
}

_PayloadParseResult<List<RuntimeStackBackendSummary>>
_parseOptionalRuntimeStackBackends(Object? value) {
  if (value == null) {
    return const _ParsedPayload(<RuntimeStackBackendSummary>[]);
  }

  if (value is! List<dynamic>) {
    return const _InvalidPayload<List<RuntimeStackBackendSummary>>();
  }

  final parsedBackends = <RuntimeStackBackendSummary>[];
  for (final backend in value) {
    switch (_parseRuntimeStackBackend(backend)) {
      case _ParsedPayload(:final value):
        parsedBackends.add(value);
      case _InvalidPayload():
        return const _InvalidPayload<List<RuntimeStackBackendSummary>>();
    }
  }

  return _ParsedPayload(List.unmodifiable(parsedBackends));
}

_PayloadParseResult<RuntimeStackBackendSummary> _parseRuntimeStackBackend(
  Object? value,
) {
  if (value is! Map<String, dynamic>) {
    return const _InvalidPayload<RuntimeStackBackendSummary>();
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
      isAvailable is! bool) {
    return const _InvalidPayload<RuntimeStackBackendSummary>();
  }

  return switch ((componentIds, missingComponentIds, missingPaths)) {
    (
      _ParsedPayload(value: final componentIds),
      _ParsedPayload(value: final missingComponentIds),
      _ParsedPayload(value: final missingPaths),
    ) =>
      (() {
        final runtimeStackBackend = RuntimeStackBackendSummary(
          id: id,
          name: name,
          role: role,
          componentIds: componentIds,
          missingComponentIds: missingComponentIds,
          missingPaths: missingPaths,
        );
        if (isAvailable != runtimeStackBackend.isAvailable) {
          return const _InvalidPayload<RuntimeStackBackendSummary>();
        }

        return _ParsedPayload(runtimeStackBackend);
      })(),
    _ => const _InvalidPayload<RuntimeStackBackendSummary>(),
  };
}

_PayloadParseResult<RuntimeStackComponentSummary> _parseRuntimeStackComponent(
  Object? value,
) {
  if (value is! Map<String, dynamic>) {
    return const _InvalidPayload<RuntimeStackComponentSummary>();
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
      !_isOptionalString(version)) {
    return const _InvalidPayload<RuntimeStackComponentSummary>();
  }

  return switch ((paths, missingPaths)) {
    (
      _ParsedPayload(value: final paths),
      _ParsedPayload(value: final missingPaths),
    ) =>
      (() {
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
          return const _InvalidPayload<RuntimeStackComponentSummary>();
        }

        return _ParsedPayload(runtimeStackComponent);
      })(),
    _ => const _InvalidPayload<RuntimeStackComponentSummary>(),
  };
}

_PayloadParseResult<List<String>> _parseStringList(Object? value) {
  if (value is! List<dynamic>) {
    return const _InvalidPayload<List<String>>();
  }

  final strings = value.whereType<String>().toList(growable: false);
  if (strings.length != value.length) {
    return const _InvalidPayload<List<String>>();
  }

  return _ParsedPayload(strings);
}

bool _isOptionalBool(Object? value) {
  return value == null || value is bool;
}

bool _isOptionalString(Object? value) {
  return value == null || value is String;
}
