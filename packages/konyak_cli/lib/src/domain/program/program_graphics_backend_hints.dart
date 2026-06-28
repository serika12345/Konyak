import '../shared/domain_value_objects.dart';
import 'program_runner.dart';

final class ProgramGraphicsBackendHints {
  ProgramGraphicsBackendHints({
    required String programPath,
    required this.hostPlatform,
    required Iterable<ProgramGraphicsBackendSignal> signals,
    required Iterable<ProgramGraphicsBackendSuggestion> suggestions,
  }) : programPath = ProgramPath(programPath),
       signals = List.unmodifiable(signals),
       suggestions = List.unmodifiable(suggestions);

  final ProgramPath programPath;
  final KonyakHostPlatform hostPlatform;
  final List<ProgramGraphicsBackendSignal> signals;
  final List<ProgramGraphicsBackendSuggestion> suggestions;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'programPath': programPath.value,
      'hostPlatform': _hostPlatformJsonValue(hostPlatform),
      'signals': signals.map((signal) => signal.toJson()).toList(),
      'suggestions': suggestions
          .map((suggestion) => suggestion.toJson())
          .toList(),
    };
  }
}

final class ProgramGraphicsBackendSignal {
  ProgramGraphicsBackendSignal({required String kind, required String value})
    : kind = GraphicsBackendSignalKind(kind),
      value = GraphicsBackendSignalValue(value);

  final GraphicsBackendSignalKind kind;
  final GraphicsBackendSignalValue value;

  Map<String, Object?> toJson() {
    return <String, Object?>{'kind': kind.value, 'value': value.value};
  }
}

final class ProgramGraphicsBackendSuggestion {
  ProgramGraphicsBackendSuggestion({
    required String backend,
    required String confidence,
    required this.reason,
  }) : backend = GraphicsBackendKind(backend),
       confidence = GraphicsBackendConfidence(confidence);

  final GraphicsBackendKind backend;
  final GraphicsBackendConfidence confidence;
  final String reason;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'backend': backend.value,
      'confidence': confidence.value,
      'reason': reason,
    };
  }
}

sealed class ProgramGraphicsBackendHintsInspectionResult {
  const ProgramGraphicsBackendHintsInspectionResult();
}

abstract interface class ProgramGraphicsBackendHintsInspector {
  ProgramGraphicsBackendHintsInspectionResult inspect({
    required ProgramPath programPath,
    required KonyakHostPlatform hostPlatform,
  });
}

final class ProgramGraphicsBackendHintsInspected
    extends ProgramGraphicsBackendHintsInspectionResult {
  const ProgramGraphicsBackendHintsInspected(this.hints);

  final ProgramGraphicsBackendHints hints;
}

final class ProgramGraphicsBackendHintsMissingProgram
    extends ProgramGraphicsBackendHintsInspectionResult {
  ProgramGraphicsBackendHintsMissingProgram(String programPath)
    : programPath = ProgramPath(programPath);

  final ProgramPath programPath;
}

final class ProgramGraphicsBackendHintsInspectionFailed
    extends ProgramGraphicsBackendHintsInspectionResult {
  ProgramGraphicsBackendHintsInspectionFailed({
    required String programPath,
    required this.message,
  }) : programPath = ProgramPath(programPath);

  final ProgramPath programPath;
  final String message;
}

ProgramGraphicsBackendHints programGraphicsBackendHintsFromSignals({
  required String programPath,
  required KonyakHostPlatform hostPlatform,
  required Iterable<ProgramGraphicsBackendSignal> signals,
}) {
  final signalList = List<ProgramGraphicsBackendSignal>.unmodifiable(signals);
  return ProgramGraphicsBackendHints(
    programPath: programPath,
    hostPlatform: hostPlatform,
    signals: signalList,
    suggestions: _graphicsBackendSuggestions(
      hostPlatform: hostPlatform,
      signals: signalList,
    ),
  );
}

List<ProgramGraphicsBackendSuggestion> _graphicsBackendSuggestions({
  required KonyakHostPlatform hostPlatform,
  required List<ProgramGraphicsBackendSignal> signals,
}) {
  if (_hasAnyGraphicsSignal(signals, _d3d12Signals)) {
    return <ProgramGraphicsBackendSuggestion>[
      ProgramGraphicsBackendSuggestion(
        backend: switch (hostPlatform) {
          KonyakHostPlatform.macos => 'd3dMetal',
          KonyakHostPlatform.linux => 'vkd3dProton',
        },
        confidence: 'high',
        reason: 'D3D12 API usage was detected.',
      ),
    ];
  }

  if (_hasAnyGraphicsSignal(signals, _d3d11Signals)) {
    return switch (hostPlatform) {
      KonyakHostPlatform.macos => <ProgramGraphicsBackendSuggestion>[
        ProgramGraphicsBackendSuggestion(
          backend: 'dxmt',
          confidence: 'medium',
          reason: 'D3D10/D3D11 API usage was detected.',
        ),
        ProgramGraphicsBackendSuggestion(
          backend: 'dxvk',
          confidence: 'medium',
          reason: 'D3D10/D3D11 API usage was detected.',
        ),
      ],
      KonyakHostPlatform.linux => <ProgramGraphicsBackendSuggestion>[
        ProgramGraphicsBackendSuggestion(
          backend: 'dxvk',
          confidence: 'high',
          reason: 'D3D10/D3D11 API usage was detected.',
        ),
      ],
    };
  }

  if (_hasAnyGraphicsSignal(signals, _d3d9Signals)) {
    return <ProgramGraphicsBackendSuggestion>[
      ProgramGraphicsBackendSuggestion(
        backend: 'dxvk',
        confidence: 'high',
        reason: 'D3D9 API usage was detected.',
      ),
    ];
  }

  if (_hasAnyGraphicsSignal(signals, _nativeGraphicsSignals)) {
    return <ProgramGraphicsBackendSuggestion>[
      ProgramGraphicsBackendSuggestion(
        backend: 'wineDefault',
        confidence: 'medium',
        reason: 'Native OpenGL or Vulkan usage was detected.',
      ),
    ];
  }

  return const <ProgramGraphicsBackendSuggestion>[];
}

bool _hasAnyGraphicsSignal(
  List<ProgramGraphicsBackendSignal> signals,
  Set<String> expectedValues,
) {
  return signals.any((signal) => expectedValues.contains(signal.value.value));
}

String _hostPlatformJsonValue(KonyakHostPlatform hostPlatform) {
  return switch (hostPlatform) {
    KonyakHostPlatform.macos => 'macos',
    KonyakHostPlatform.linux => 'linux',
  };
}

const _d3d12Signals = <String>{'d3d12.dll', 'd3d12createdevice'};

const _d3d11Signals = <String>{
  'd3d10.dll',
  'd3d10_1.dll',
  'd3d10core.dll',
  'd3d11.dll',
  'd3d11createdevice',
};

const _d3d9Signals = <String>{'d3d9.dll', 'direct3dcreate9'};

const _nativeGraphicsSignals = <String>{
  'vulkan-1.dll',
  'opengl32.dll',
  'vkcreateinstance',
  'wglcreatecontext',
};
