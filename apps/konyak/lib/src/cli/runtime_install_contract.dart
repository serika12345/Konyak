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

sealed class RuntimeInstallProgressParseResult {
  const RuntimeInstallProgressParseResult();
}

final class ParsedRuntimeInstallProgress
    extends RuntimeInstallProgressParseResult {
  const ParsedRuntimeInstallProgress(this.progress);

  final RuntimeInstallProgress progress;
}

final class InvalidRuntimeInstallProgress
    extends RuntimeInstallProgressParseResult {
  const InvalidRuntimeInstallProgress();
}

sealed class _RuntimeInstallErrorMessageParseResult {
  const _RuntimeInstallErrorMessageParseResult();
}

final class _ParsedRuntimeInstallErrorMessage
    extends _RuntimeInstallErrorMessageParseResult {
  const _ParsedRuntimeInstallErrorMessage(this.message);

  final String message;
}

final class _InvalidRuntimeInstallErrorMessage
    extends _RuntimeInstallErrorMessageParseResult {
  const _InvalidRuntimeInstallErrorMessage();
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

  switch (_parseErrorMessage(decoded['error'])) {
    case _ParsedRuntimeInstallErrorMessage(:final message):
      return RuntimeInstallCommandFailure(message);
    case _InvalidRuntimeInstallErrorMessage():
      break;
  }

  return const RuntimeInstallParseFailure(
    'Runtime install payload must contain a runtime or error object.',
  );
}

RuntimeInstallProgressParseResult parseRuntimeInstallProgressPayload(
  String payload,
) {
  final Object? decoded;

  try {
    decoded = jsonDecode(payload);
  } on FormatException {
    return const InvalidRuntimeInstallProgress();
  }

  if (decoded is! Map<String, dynamic>) {
    return const InvalidRuntimeInstallProgress();
  }

  final Object? schemaVersion = decoded['schemaVersion'];
  if (schemaVersion != runtimeInstallSchemaVersion) {
    return const InvalidRuntimeInstallProgress();
  }

  final progress = decoded['runtimeInstallProgress'];
  if (progress is! Map<String, dynamic>) {
    return const InvalidRuntimeInstallProgress();
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
    return const InvalidRuntimeInstallProgress();
  }

  return ParsedRuntimeInstallProgress(
    RuntimeInstallProgress(
      stage: stage,
      message: message,
      fraction: fraction.toDouble(),
    ),
  );
}

_RuntimeInstallErrorMessageParseResult _parseErrorMessage(Object? value) {
  if (value is! Map<String, dynamic>) {
    return const _InvalidRuntimeInstallErrorMessage();
  }

  final Object? message = value['message'];
  if (message is! String || message.isEmpty) {
    return const _InvalidRuntimeInstallErrorMessage();
  }

  return _ParsedRuntimeInstallErrorMessage(message);
}
