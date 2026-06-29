import 'dart:convert';

import '../runtimes/runtime_summary.dart';
import 'runtime_list_contract.dart';

const runtimeInstallSchemaVersion = 1;

sealed class RuntimeInstallParseResult {
  const RuntimeInstallParseResult();
}

final class ParsedRuntimeInstall extends RuntimeInstallParseResult {
  const ParsedRuntimeInstall(this.runtime);

  final RuntimeSummary runtime;
}

final class RuntimeInstallCommandFailure extends RuntimeInstallParseResult {
  const RuntimeInstallCommandFailure(this.message);

  final String message;
}

final class RuntimeInstallParseFailure extends RuntimeInstallParseResult {
  const RuntimeInstallParseFailure(this.message);

  final String message;
}

final class RuntimeInstallProgress {
  const RuntimeInstallProgress({
    required this.stage,
    required this.message,
    required this.fraction,
  });

  final String stage;
  final String message;
  final double fraction;
}

RuntimeInstallParseResult parseRuntimeInstallPayload(String payload) {
  final Object? decoded;

  try {
    decoded = jsonDecode(payload);
  } on FormatException {
    return const RuntimeInstallParseFailure(
      'Runtime install payload is not valid JSON.',
    );
  }

  if (decoded is! Map<String, dynamic>) {
    return const RuntimeInstallParseFailure(
      'Runtime install payload must be an object.',
    );
  }

  final Object? schemaVersion = decoded['schemaVersion'];
  if (schemaVersion != runtimeInstallSchemaVersion) {
    return const RuntimeInstallParseFailure(
      'Unsupported runtime install schema version.',
    );
  }

  switch (parseRuntimeRecord(decoded['runtime'])) {
    case ParsedRuntimeRecord(:final runtime):
      return ParsedRuntimeInstall(runtime);
    case InvalidRuntimeRecord():
      break;
  }

  final errorMessage = _parseErrorMessage(decoded['error']);
  if (errorMessage != null) {
    return RuntimeInstallCommandFailure(errorMessage);
  }

  return const RuntimeInstallParseFailure(
    'Runtime install payload must contain a runtime or error object.',
  );
}

RuntimeInstallProgress? parseRuntimeInstallProgressPayload(String payload) {
  final Object? decoded;

  try {
    decoded = jsonDecode(payload);
  } on FormatException {
    return null;
  }

  if (decoded is! Map<String, dynamic>) {
    return null;
  }

  final Object? schemaVersion = decoded['schemaVersion'];
  if (schemaVersion != runtimeInstallSchemaVersion) {
    return null;
  }

  final progress = decoded['runtimeInstallProgress'];
  if (progress is! Map<String, dynamic>) {
    return null;
  }

  final stage = progress['stage'];
  final message = progress['message'];
  final fraction = progress['fraction'];
  if (stage is! String ||
      stage.trim().isEmpty ||
      message is! String ||
      message.trim().isEmpty ||
      fraction is! num ||
      fraction < 0 ||
      fraction > 1) {
    return null;
  }

  return RuntimeInstallProgress(
    stage: stage,
    message: message,
    fraction: fraction.toDouble(),
  );
}

String? _parseErrorMessage(Object? value) {
  if (value is! Map<String, dynamic>) {
    return null;
  }

  final Object? message = value['message'];
  if (message is! String || message.isEmpty) {
    return null;
  }

  return message;
}
