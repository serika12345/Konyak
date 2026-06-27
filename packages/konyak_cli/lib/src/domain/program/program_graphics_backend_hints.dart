part of '../../../konyak_cli.dart';

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

ProgramGraphicsBackendHints _programGraphicsBackendHintsFromPortableExecutable({
  required String programPath,
  required KonyakHostPlatform hostPlatform,
  required Option<_PortableExecutableImage> image,
}) {
  final signals = image.match(
    () => const <ProgramGraphicsBackendSignal>[],
    _graphicsBackendSignals,
  );
  return ProgramGraphicsBackendHints(
    programPath: programPath,
    hostPlatform: hostPlatform,
    signals: signals,
    suggestions: _graphicsBackendSuggestions(
      hostPlatform: hostPlatform,
      signals: signals,
    ),
  );
}

List<ProgramGraphicsBackendSignal> _graphicsBackendSignals(
  _PortableExecutableImage image,
) {
  final signals = <ProgramGraphicsBackendSignal>[];
  final seen = <String>{};

  void addSignal(String kind, String value) {
    final normalizedValue = value.toLowerCase();
    final key = '$kind:$normalizedValue';
    if (!seen.add(key)) {
      return;
    }
    signals.add(
      ProgramGraphicsBackendSignal(kind: kind, value: normalizedValue),
    );
  }

  for (final dllName in image.importDllNames) {
    final normalized = dllName.toLowerCase();
    if (_graphicsImportDllNames.contains(normalized)) {
      addSignal('peImport', normalized);
    }
  }

  for (final signal in _graphicsStringSignals) {
    if (_containsAsciiCaseInsensitive(image.bytes, signal.value.value)) {
      addSignal('string', signal.value.value);
    }
  }

  return List.unmodifiable(signals);
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

bool _containsAsciiCaseInsensitive(Uint8List bytes, String value) {
  final needle = ascii.encode(value.toLowerCase());
  if (needle.isEmpty || bytes.length < needle.length) {
    return false;
  }

  for (var index = 0; index <= bytes.length - needle.length; index += 1) {
    var matches = true;
    for (var offset = 0; offset < needle.length; offset += 1) {
      final byte = bytes[index + offset];
      final normalizedByte = byte >= 0x41 && byte <= 0x5a ? byte + 0x20 : byte;
      if (normalizedByte != needle[offset]) {
        matches = false;
        break;
      }
    }
    if (matches) {
      return true;
    }
  }

  return false;
}

String _hostPlatformJsonValue(KonyakHostPlatform hostPlatform) {
  return switch (hostPlatform) {
    KonyakHostPlatform.macos => 'macos',
    KonyakHostPlatform.linux => 'linux',
  };
}

const _graphicsImportDllNames = <String>{
  'd3d9.dll',
  'd3d10.dll',
  'd3d10_1.dll',
  'd3d10core.dll',
  'd3d11.dll',
  'd3d12.dll',
  'dxgi.dll',
  'vulkan-1.dll',
  'opengl32.dll',
  'nvngx.dll',
};

final _graphicsStringSignals = <ProgramGraphicsBackendSignal>[
  ProgramGraphicsBackendSignal(kind: 'string', value: 'd3d12createdevice'),
  ProgramGraphicsBackendSignal(kind: 'string', value: 'd3d11createdevice'),
  ProgramGraphicsBackendSignal(kind: 'string', value: 'direct3dcreate9'),
  ProgramGraphicsBackendSignal(kind: 'string', value: 'vkcreateinstance'),
  ProgramGraphicsBackendSignal(kind: 'string', value: 'wglcreatecontext'),
  ProgramGraphicsBackendSignal(kind: 'string', value: 'nvngx'),
];

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
