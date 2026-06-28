import '../domain/program/program_graphics_backend_hints.dart';
import '../domain/program/program_runner.dart';

Map<String, Object?> programGraphicsBackendHintsJson(
  ProgramGraphicsBackendHints hints,
) {
  return <String, Object?>{
    'programPath': hints.programPath.value,
    'hostPlatform': _hostPlatformJsonValue(hints.hostPlatform),
    'signals': hints.signals
        .map(programGraphicsBackendSignalJson)
        .toList(growable: false),
    'suggestions': hints.suggestions
        .map(programGraphicsBackendSuggestionJson)
        .toList(growable: false),
  };
}

Map<String, Object?> programGraphicsBackendSignalJson(
  ProgramGraphicsBackendSignal signal,
) {
  return <String, Object?>{
    'kind': signal.kind.value,
    'value': signal.value.value,
  };
}

Map<String, Object?> programGraphicsBackendSuggestionJson(
  ProgramGraphicsBackendSuggestion suggestion,
) {
  return <String, Object?>{
    'backend': suggestion.backend.value,
    'confidence': suggestion.confidence.value,
    'reason': suggestion.reason,
  };
}

String _hostPlatformJsonValue(KonyakHostPlatform hostPlatform) {
  return switch (hostPlatform) {
    KonyakHostPlatform.macos => 'macos',
    KonyakHostPlatform.linux => 'linux',
  };
}
