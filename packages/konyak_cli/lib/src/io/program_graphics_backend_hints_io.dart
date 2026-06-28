part of '../../konyak_cli.dart';

class DartIoProgramGraphicsBackendHintsInspector {
  const DartIoProgramGraphicsBackendHintsInspector();

  ProgramGraphicsBackendHintsInspectionResult inspect({
    required String programPath,
    required KonyakHostPlatform hostPlatform,
  }) {
    try {
      final file = File(programPath);
      if (!file.existsSync()) {
        return ProgramGraphicsBackendHintsMissingProgram(programPath);
      }

      return ProgramGraphicsBackendHintsInspected(
        programGraphicsBackendHintsFromSignals(
          programPath: programPath,
          hostPlatform: hostPlatform,
          signals: _PortableExecutableImage.parse(file.readAsBytesSync()).match(
            () => const <ProgramGraphicsBackendSignal>[],
            _graphicsBackendSignalsFromPortableExecutable,
          ),
        ),
      );
    } on FileSystemException catch (error) {
      return ProgramGraphicsBackendHintsInspectionFailed(
        programPath: programPath,
        message: error.message,
      );
    } on FormatException catch (error) {
      return ProgramGraphicsBackendHintsInspectionFailed(
        programPath: programPath,
        message: error.message,
      );
    } on RangeError {
      return ProgramGraphicsBackendHintsInspectionFailed(
        programPath: programPath,
        message: 'Program file could not be inspected.',
      );
    }
  }
}

List<ProgramGraphicsBackendSignal>
_graphicsBackendSignalsFromPortableExecutable(_PortableExecutableImage image) {
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

  for (final value in _graphicsStringSignalValues) {
    if (_containsAsciiCaseInsensitive(image.bytes, value)) {
      addSignal('string', value);
    }
  }

  return List.unmodifiable(signals);
}

bool _containsAsciiCaseInsensitive(Uint8List bytes, String value) {
  final needle = ascii.encode(value.toLowerCase());
  if (needle.isEmpty || bytes.length < needle.length) {
    return false;
  }

  return Iterable<int>.generate(bytes.length - needle.length + 1).any(
    (index) => Iterable<int>.generate(needle.length).every((offset) {
      final byte = bytes[index + offset];
      final normalizedByte = byte >= 0x41 && byte <= 0x5a ? byte + 0x20 : byte;
      return normalizedByte == needle[offset];
    }),
  );
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

const _graphicsStringSignalValues = <String>{
  'd3d12createdevice',
  'd3d11createdevice',
  'direct3dcreate9',
  'vkcreateinstance',
  'wglcreatecontext',
  'nvngx',
};
