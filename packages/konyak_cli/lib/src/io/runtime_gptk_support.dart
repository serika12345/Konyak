part of '../../konyak_cli.dart';

Directory? _resolveGptkWineRoot(String sourcePath) {
  final sourceType = FileSystemEntity.typeSync(sourcePath);
  if (sourceType != FileSystemEntityType.directory) {
    return null;
  }

  if (!_baseName(sourcePath).endsWith('.app')) {
    return null;
  }

  final candidate = Directory(
    _joinPath(sourcePath, const ['Contents', 'Resources', 'wine']),
  );
  if (_isGptkWineRootCandidate(candidate)) {
    return candidate;
  }

  return null;
}

bool _isGptkWineRootCandidate(Directory directory) {
  if (!directory.existsSync()) {
    return false;
  }
  final wine64 = File(_joinPath(directory.path, const ['bin', 'wine64']));
  final wineserver = File(
    _joinPath(directory.path, const ['bin', 'wineserver']),
  );
  final lib = Directory(_joinPath(directory.path, const ['lib']));
  final lib64 = Directory(_joinPath(directory.path, const ['lib64']));
  return wine64.existsSync() &&
      wineserver.existsSync() &&
      (lib.existsSync() || lib64.existsSync());
}

String? _validateGptkD3DMetalSource(_GptkD3DMetalSource source) {
  final frameworkBinary = _d3dMetalFrameworkBinary(source.framework.path);
  if (frameworkBinary == null || !File(frameworkBinary).existsSync()) {
    return 'D3DMetal.framework does not contain a D3DMetal binary.';
  }
  if (!_looksLikeMachO(File(frameworkBinary))) {
    return 'D3DMetal.framework is not a Mach-O framework binary. Konyak '
        'rejects fixture text files and incomplete GPTK copies.';
  }
  if (!_looksLikeMachO(source.dylib)) {
    return 'libd3dshared.dylib is not a Mach-O binary. Konyak rejects fixture '
        'text files and incomplete GPTK copies.';
  }
  if (!_looksLikePE(source.d3d12Dll)) {
    return 'd3d12.dll is not a Windows PE binary. Select an official or '
        'compatible Game Porting Toolkit distribution.';
  }
  if (!_looksLikePE(source.dxgiDll)) {
    return 'dxgi.dll is not a Windows PE binary. Select an official or '
        'compatible Game Porting Toolkit distribution.';
  }
  return null;
}

_GptkD3DMetalSource? _resolveGptkD3DMetalSource(String sourcePath) {
  final sourceType = FileSystemEntity.typeSync(sourcePath);
  if (sourceType == FileSystemEntityType.notFound) {
    return null;
  }

  if (sourceType == FileSystemEntityType.directory &&
      _baseName(sourcePath) == 'D3DMetal.framework') {
    final framework = Directory(sourcePath);
    final siblingDylib = File(
      _joinPath(_dirname(sourcePath), const ['libd3dshared.dylib']),
    );
    final dllSource = _resolveGptkD3DMetalWindowsDlls(
      Directory(_dirname(sourcePath)),
    );
    if (siblingDylib.existsSync() && dllSource != null) {
      return _GptkD3DMetalSource(
        directory: Directory(_dirname(sourcePath)),
        framework: framework,
        dylib: siblingDylib,
        d3d12Dll: dllSource.d3d12Dll,
        dxgiDll: dllSource.dxgiDll,
      );
    }
    return null;
  }

  if (sourceType != FileSystemEntityType.directory) {
    return null;
  }

  final candidate = Directory(_joinPath(sourcePath, const ['lib', 'external']));
  final framework = Directory(
    _joinPath(candidate.path, const ['D3DMetal.framework']),
  );
  final dylib = File(_joinPath(candidate.path, const ['libd3dshared.dylib']));
  final dllSource = _resolveGptkD3DMetalWindowsDlls(candidate);
  if (framework.existsSync() && dylib.existsSync() && dllSource != null) {
    return _GptkD3DMetalSource(
      directory: candidate,
      framework: framework,
      dylib: dylib,
      d3d12Dll: dllSource.d3d12Dll,
      dxgiDll: dllSource.dxgiDll,
    );
  }

  return null;
}

class _GptkD3DMetalWindowsDllSource {
  const _GptkD3DMetalWindowsDllSource({
    required this.d3d12Dll,
    required this.dxgiDll,
  });

  final File d3d12Dll;
  final File dxgiDll;
}

_GptkD3DMetalWindowsDllSource? _resolveGptkD3DMetalWindowsDlls(
  Directory sourceDirectory,
) {
  final d3d12 = File(
    _joinPath(sourceDirectory.path, const [
      '..',
      'wine',
      'x86_64-windows',
      'd3d12.dll',
    ]),
  );
  final dxgi = File(_joinPath(_dirname(d3d12.path), const ['dxgi.dll']));
  if (d3d12.existsSync() && dxgi.existsSync()) {
    return _GptkD3DMetalWindowsDllSource(d3d12Dll: d3d12, dxgiDll: dxgi);
  }

  return null;
}

String? _d3dMetalFrameworkBinary(String frameworkPath) {
  for (final relativePath in const <List<String>>[
    <String>['D3DMetal'],
    <String>['Versions', 'A', 'D3DMetal'],
  ]) {
    final path = _joinPath(frameworkPath, relativePath);
    if (File(path).existsSync()) {
      return path;
    }
  }
  return null;
}

bool _looksLikeMachO(File file) {
  try {
    if (!file.existsSync() || file.lengthSync() < 4) {
      return false;
    }
    final bytes = file.openSync();
    try {
      final header = bytes.readSync(4);
      if (header.length < 4) {
        return false;
      }
      final magic =
          header[0] << 24 | header[1] << 16 | header[2] << 8 | header[3];
      return magic == 0xfeedface ||
          magic == 0xcefaedfe ||
          magic == 0xfeedfacf ||
          magic == 0xcffaedfe ||
          magic == 0xcafebabe ||
          magic == 0xbebafeca;
    } finally {
      bytes.closeSync();
    }
  } on FileSystemException {
    return false;
  }
}

bool _looksLikePE(File file) {
  try {
    if (!file.existsSync() || file.lengthSync() < 2) {
      return false;
    }
    final bytes = file.openSync();
    try {
      final header = bytes.readSync(2);
      return header.length == 2 && header[0] == 0x4d && header[1] == 0x5a;
    } finally {
      bytes.closeSync();
    }
  } on FileSystemException {
    return false;
  }
}
