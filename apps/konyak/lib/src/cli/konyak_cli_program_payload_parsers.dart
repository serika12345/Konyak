import 'dart:convert';

import 'konyak_cli_program_result_types.dart';
import 'konyak_cli_wine_process_payload_parsers.dart';

sealed class _GraphicsBackendSignalParseResult {
  const _GraphicsBackendSignalParseResult();
}

final class _ParsedGraphicsBackendSignal
    extends _GraphicsBackendSignalParseResult {
  const _ParsedGraphicsBackendSignal(this.signal);

  final ProgramGraphicsBackendSignalSummary signal;
}

final class _InvalidGraphicsBackendSignal
    extends _GraphicsBackendSignalParseResult {
  const _InvalidGraphicsBackendSignal();
}

sealed class _GraphicsBackendSuggestionParseResult {
  const _GraphicsBackendSuggestionParseResult();
}

final class _ParsedGraphicsBackendSuggestion
    extends _GraphicsBackendSuggestionParseResult {
  const _ParsedGraphicsBackendSuggestion(this.suggestion);

  final ProgramGraphicsBackendSuggestionSummary suggestion;
}

final class _InvalidGraphicsBackendSuggestion
    extends _GraphicsBackendSuggestionParseResult {
  const _InvalidGraphicsBackendSuggestion();
}

BottleProgramListLoadResult parseBottleProgramListPayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (error) {
    return BottleProgramListLoadFailure(
      exitCode: 0,
      message: error.message,
      diagnostic: '',
    );
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return const BottleProgramListLoadFailure(
      exitCode: 0,
      message: 'Unsupported bottle program list payload.',
      diagnostic: '',
    );
  }

  final error = decoded['error'];
  if (error is Map<String, Object?>) {
    final message = error['message'];
    return BottleProgramListLoadFailure(
      exitCode: 0,
      message: message is String ? message : 'Bottle program list failed.',
      diagnostic: '',
    );
  }

  final bottlePrograms = decoded['bottlePrograms'];
  if (bottlePrograms is! Map<String, Object?>) {
    return const BottleProgramListLoadFailure(
      exitCode: 0,
      message: 'Missing bottlePrograms payload.',
      diagnostic: '',
    );
  }

  final bottleId = bottlePrograms['bottleId'];
  final programs = bottlePrograms['programs'];
  if (bottleId is! String || programs is! List<Object?>) {
    return const BottleProgramListLoadFailure(
      exitCode: 0,
      message: 'Invalid bottlePrograms payload.',
      diagnostic: '',
    );
  }

  final parsedPrograms = <BottleProgramSummary>[];
  for (final program in programs) {
    if (program is! Map<String, Object?>) {
      return const BottleProgramListLoadFailure(
        exitCode: 0,
        message: 'Invalid bottle program record.',
        diagnostic: '',
      );
    }

    final id = program['id'];
    final name = program['name'];
    final path = program['path'];
    final source = program['source'];
    if (id is! String ||
        name is! String ||
        path is! String ||
        source is! String) {
      return const BottleProgramListLoadFailure(
        exitCode: 0,
        message: 'Invalid bottle program record.',
        diagnostic: '',
      );
    }

    final metadata = parseProgramMetadata(program['metadata']);

    parsedPrograms.add(
      BottleProgramSummary(
        id: id,
        name: name,
        path: path,
        source: source,
        metadata: metadata,
      ),
    );
  }

  return LoadedBottlePrograms(
    bottleId: bottleId,
    programs: List.unmodifiable(parsedPrograms),
  );
}

GraphicsBackendHintsLoadResult parseGraphicsBackendHintsPayload(
  String payload,
) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (error) {
    return GraphicsBackendHintsLoadFailure(
      exitCode: 0,
      message: error.message,
      diagnostic: '',
    );
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return const GraphicsBackendHintsLoadFailure(
      exitCode: 0,
      message: 'Unsupported graphics backend hints payload.',
      diagnostic: '',
    );
  }

  final error = decoded['error'];
  if (error is Map<String, Object?>) {
    final message = error['message'];
    return GraphicsBackendHintsLoadFailure(
      exitCode: 0,
      message: message is String ? message : 'Graphics backend hint failed.',
      diagnostic: '',
    );
  }

  final hints = decoded['graphicsBackendHints'];
  if (hints is! Map<String, Object?>) {
    return const GraphicsBackendHintsLoadFailure(
      exitCode: 0,
      message: 'Missing graphicsBackendHints payload.',
      diagnostic: '',
    );
  }

  final programPath = hints['programPath'];
  final hostPlatform = hints['hostPlatform'];
  final signals = hints['signals'];
  final suggestions = hints['suggestions'];
  if (programPath is! String ||
      hostPlatform is! String ||
      signals is! List<Object?> ||
      suggestions is! List<Object?>) {
    return const GraphicsBackendHintsLoadFailure(
      exitCode: 0,
      message: 'Invalid graphicsBackendHints payload.',
      diagnostic: '',
    );
  }

  final parsedSignals = <ProgramGraphicsBackendSignalSummary>[];
  for (final signal in signals) {
    switch (_parseGraphicsBackendSignal(signal)) {
      case _ParsedGraphicsBackendSignal(:final signal):
        parsedSignals.add(signal);
      case _InvalidGraphicsBackendSignal():
        return const GraphicsBackendHintsLoadFailure(
          exitCode: 0,
          message: 'Invalid graphics backend signal.',
          diagnostic: '',
        );
    }
  }

  final parsedSuggestions = <ProgramGraphicsBackendSuggestionSummary>[];
  for (final suggestion in suggestions) {
    switch (_parseGraphicsBackendSuggestion(suggestion)) {
      case _ParsedGraphicsBackendSuggestion(:final suggestion):
        parsedSuggestions.add(suggestion);
      case _InvalidGraphicsBackendSuggestion():
        return const GraphicsBackendHintsLoadFailure(
          exitCode: 0,
          message: 'Invalid graphics backend suggestion.',
          diagnostic: '',
        );
    }
  }

  return LoadedGraphicsBackendHints(
    ProgramGraphicsBackendHintsSummary(
      programPath: programPath,
      hostPlatform: hostPlatform,
      signals: parsedSignals,
      suggestions: parsedSuggestions,
    ),
  );
}

_GraphicsBackendSignalParseResult _parseGraphicsBackendSignal(Object? signal) {
  if (signal is! Map<String, Object?>) {
    return const _InvalidGraphicsBackendSignal();
  }

  final kind = signal['kind'];
  final value = signal['value'];
  if (kind is! String || value is! String) {
    return const _InvalidGraphicsBackendSignal();
  }

  return _ParsedGraphicsBackendSignal(
    ProgramGraphicsBackendSignalSummary(kind: kind, value: value),
  );
}

_GraphicsBackendSuggestionParseResult _parseGraphicsBackendSuggestion(
  Object? suggestion,
) {
  if (suggestion is! Map<String, Object?>) {
    return const _InvalidGraphicsBackendSuggestion();
  }

  final backend = suggestion['backend'];
  final confidence = suggestion['confidence'];
  final reason = suggestion['reason'];
  if (backend is! String || confidence is! String || reason is! String) {
    return const _InvalidGraphicsBackendSuggestion();
  }

  return _ParsedGraphicsBackendSuggestion(
    ProgramGraphicsBackendSuggestionSummary(
      backend: backend,
      confidence: confidence,
      reason: reason,
    ),
  );
}
