import 'package:freezed_annotation/freezed_annotation.dart';

import '../shared/domain_value_objects.dart';
import 'program_runner.dart';

part 'program_graphics_backend_hints.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProgramGraphicsBackendHints with _$ProgramGraphicsBackendHints {
  const ProgramGraphicsBackendHints._();

  factory ProgramGraphicsBackendHints({
    required String programPath,
    required KonyakHostPlatform hostPlatform,
    required Iterable<ProgramGraphicsBackendSignal> signals,
    required Iterable<ProgramGraphicsBackendSuggestion> suggestions,
  }) {
    return ProgramGraphicsBackendHints._validated(
      programPath: ProgramPath(programPath),
      hostPlatform: hostPlatform,
      signals: List.unmodifiable(signals),
      suggestions: List.unmodifiable(suggestions),
    );
  }

  const factory ProgramGraphicsBackendHints._validated({
    required ProgramPath programPath,
    required KonyakHostPlatform hostPlatform,
    required List<ProgramGraphicsBackendSignal> signals,
    required List<ProgramGraphicsBackendSuggestion> suggestions,
  }) = _ProgramGraphicsBackendHints;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProgramGraphicsBackendSignal
    with _$ProgramGraphicsBackendSignal {
  const ProgramGraphicsBackendSignal._();

  factory ProgramGraphicsBackendSignal({
    required String kind,
    required String value,
  }) {
    return ProgramGraphicsBackendSignal._validated(
      kind: GraphicsBackendSignalKind(kind),
      value: GraphicsBackendSignalValue(value),
    );
  }

  const factory ProgramGraphicsBackendSignal._validated({
    required GraphicsBackendSignalKind kind,
    required GraphicsBackendSignalValue value,
  }) = _ProgramGraphicsBackendSignal;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProgramGraphicsBackendSuggestion
    with _$ProgramGraphicsBackendSuggestion {
  const ProgramGraphicsBackendSuggestion._();

  factory ProgramGraphicsBackendSuggestion({
    required String backend,
    required String confidence,
    required String reason,
  }) {
    return ProgramGraphicsBackendSuggestion._validated(
      backend: GraphicsBackendKind(backend),
      confidence: GraphicsBackendConfidence(confidence),
      reason: reason,
    );
  }

  const factory ProgramGraphicsBackendSuggestion._validated({
    required GraphicsBackendKind backend,
    required GraphicsBackendConfidence confidence,
    required String reason,
  }) = _ProgramGraphicsBackendSuggestion;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class ProgramGraphicsBackendHintsInspectionResult
    with _$ProgramGraphicsBackendHintsInspectionResult {
  const ProgramGraphicsBackendHintsInspectionResult._();

  const factory ProgramGraphicsBackendHintsInspectionResult.inspected(
    ProgramGraphicsBackendHints hints,
  ) = ProgramGraphicsBackendHintsInspected;

  factory ProgramGraphicsBackendHintsInspectionResult.missingProgram(
    String programPath,
  ) {
    return ProgramGraphicsBackendHintsInspectionResult._missingProgram(
      ProgramPath(programPath),
    );
  }

  const factory ProgramGraphicsBackendHintsInspectionResult._missingProgram(
    ProgramPath programPath,
  ) = ProgramGraphicsBackendHintsMissingProgram;

  factory ProgramGraphicsBackendHintsInspectionResult.failed({
    required String programPath,
    required String message,
  }) {
    return ProgramGraphicsBackendHintsInspectionResult._failed(
      programPath: ProgramPath(programPath),
      message: message,
    );
  }

  const factory ProgramGraphicsBackendHintsInspectionResult._failed({
    required ProgramPath programPath,
    required String message,
  }) = ProgramGraphicsBackendHintsInspectionFailed;
}

abstract interface class ProgramGraphicsBackendHintsInspector {
  ProgramGraphicsBackendHintsInspectionResult inspect({
    required ProgramPath programPath,
    required KonyakHostPlatform hostPlatform,
  });
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
