part of '../../konyak_cli.dart';

const _requiredGptkD3DMetalWindowsFileNames = <String>[
  'atidxx64.dll',
  'd3d11.dll',
  'd3d12.dll',
  'dxgi.dll',
  'nvapi64.dll',
  'nvngx.dll',
];

const _requiredGptkD3DMetalUnixFileNames = <String>[
  'atidxx64.so',
  'd3d11.so',
  'd3d12.so',
  'dxgi.so',
  'nvapi64.so',
  'nvngx.so',
];

final class _GptkD3DMetalSourceResolution {
  _GptkD3DMetalSourceResolution({
    required this.source,
    required Iterable<String> mountRoots,
  }) : mountRoots = List.unmodifiable(mountRoots);

  final _GptkD3DMetalSource source;
  final List<String> mountRoots;

  void dispose() {
    for (var index = mountRoots.length - 1; index >= 0; index -= 1) {
      Process.runSync('hdiutil', <String>['detach', mountRoots[index]]);
    }
  }
}

_GptkD3DMetalSourceResolution? _resolveGptkD3DMetalSourcePath(
  String sourcePath,
) {
  final mountRoots = <String>[];
  try {
    final source = _resolveGptkD3DMetalSourceKeepingMounts(
      sourcePath,
      mountRoots,
    );
    if (source == null) {
      _disposeGptkMountRoots(mountRoots);
      return null;
    }
    return _GptkD3DMetalSourceResolution(
      source: source,
      mountRoots: mountRoots,
    );
  } on FileSystemException {
    _disposeGptkMountRoots(mountRoots);
    rethrow;
  } on ProcessException {
    _disposeGptkMountRoots(mountRoots);
    rethrow;
  }
}

_GptkD3DMetalSource? _resolveGptkD3DMetalSourceKeepingMounts(
  String sourcePath,
  List<String> mountRoots,
) {
  final sourceType = FileSystemEntity.typeSync(sourcePath, followLinks: false);
  if (sourceType == FileSystemEntityType.notFound) {
    return null;
  }

  if (sourceType == FileSystemEntityType.directory) {
    if (_baseName(sourcePath).endsWith('.app')) {
      for (final appSourceRoot in _gptkD3DMetalAppSourceRoots(sourcePath)) {
        final appSource = _resolveGptkD3DMetalSource(appSourceRoot.path);
        if (appSource != null) {
          return appSource;
        }
      }
    }

    final directSource = _resolveGptkD3DMetalSource(sourcePath);
    if (directSource != null) {
      return directSource;
    }

    final redist = _findDirectoryNamed(
      Directory(sourcePath),
      name: 'redist',
      maxDepth: 3,
    );
    if (redist != null) {
      return _resolveGptkD3DMetalSource(redist.path);
    }
    return null;
  }

  if (sourceType == FileSystemEntityType.file && sourcePath.endsWith('.dmg')) {
    final mountRoot = _mountGptkDmg(sourcePath);
    if (mountRoot == null) {
      return null;
    }
    mountRoots.add(mountRoot);

    final mountedSource = _resolveGptkD3DMetalSourceKeepingMounts(
      mountRoot,
      mountRoots,
    );
    if (mountedSource != null) {
      return mountedSource;
    }

    final nestedDmg = _findDmgFile(Directory(mountRoot), maxDepth: 2);
    if (nestedDmg != null) {
      return _resolveGptkD3DMetalSourceKeepingMounts(
        nestedDmg.path,
        mountRoots,
      );
    }
  }

  return null;
}

List<Directory> _gptkD3DMetalAppSourceRoots(String appBundlePath) {
  return <Directory>[
    Directory(
      _joinPath(appBundlePath, const ['Contents', 'Resources', 'wine']),
    ),
    Directory(
      _joinPath(appBundlePath, const [
        'Contents',
        'SharedSupport',
        'CrossOver',
        'lib64',
        'apple_gptk',
      ]),
    ),
  ];
}

String? _mountGptkDmg(String dmgPath) {
  final mountRoot = Directory.systemTemp.createTempSync('konyak-gptk-mount-');
  final result = Process.runSync('hdiutil', <String>[
    'attach',
    dmgPath,
    '-readonly',
    '-nobrowse',
    '-mountpoint',
    mountRoot.path,
  ]);
  if (result.exitCode != 0) {
    _deleteDirectoryIfPresent(mountRoot);
    return null;
  }
  return mountRoot.path;
}

void _disposeGptkMountRoots(List<String> mountRoots) {
  for (var index = mountRoots.length - 1; index >= 0; index -= 1) {
    Process.runSync('hdiutil', <String>['detach', mountRoots[index]]);
  }
}

Directory? _findDirectoryNamed(
  Directory root, {
  required String name,
  required int maxDepth,
}) {
  if (maxDepth < 0 || !root.existsSync()) {
    return null;
  }
  for (final entry in root.listSync(followLinks: false)) {
    if (entry is Directory && _baseName(entry.path) == name) {
      return entry;
    }
  }
  for (final entry in root.listSync(followLinks: false)) {
    if (entry is! Directory) {
      continue;
    }
    final found = _findDirectoryNamed(
      entry,
      name: name,
      maxDepth: maxDepth - 1,
    );
    if (found != null) {
      return found;
    }
  }
  return null;
}

File? _findDmgFile(Directory root, {required int maxDepth}) {
  if (maxDepth < 0 || !root.existsSync()) {
    return null;
  }
  for (final entry in root.listSync(followLinks: false)) {
    if (entry is File && entry.path.endsWith('.dmg')) {
      return entry;
    }
  }
  for (final entry in root.listSync(followLinks: false)) {
    if (entry is! Directory) {
      continue;
    }
    final found = _findDmgFile(entry, maxDepth: maxDepth - 1);
    if (found != null) {
      return found;
    }
  }
  return null;
}

Either<String, Unit> _validateGptkD3DMetalSource(_GptkD3DMetalSource source) {
  final frameworkBinary = _d3dMetalFrameworkBinary(source.framework.path);
  if (frameworkBinary == null || !File(frameworkBinary).existsSync()) {
    return const Left<String, Unit>(
      'D3DMetal.framework does not contain a D3DMetal binary.',
    );
  }
  if (!_looksLikeMachO(File(frameworkBinary))) {
    return const Left<String, Unit>(
      'D3DMetal.framework is not a Mach-O framework binary. Konyak '
      'rejects fixture text files and incomplete GPTK copies.',
    );
  }
  if (!_looksLikeMachO(source.dylib)) {
    return const Left<String, Unit>(
      'libd3dshared.dylib is not a Mach-O binary. Konyak rejects fixture '
      'text files and incomplete GPTK copies.',
    );
  }
  if (!_looksLikePE(source.d3d12Dll)) {
    return const Left<String, Unit>(
      'd3d12.dll is not a Windows PE binary. Select an official or '
      'compatible Game Porting Toolkit distribution.',
    );
  }
  if (!_looksLikePE(source.d3d11Dll)) {
    return const Left<String, Unit>(
      'd3d11.dll is not a Windows PE binary. Select an official or '
      'compatible Game Porting Toolkit distribution.',
    );
  }
  if (!_looksLikePE(source.dxgiDll)) {
    return const Left<String, Unit>(
      'dxgi.dll is not a Windows PE binary. Select an official or '
      'compatible Game Porting Toolkit distribution.',
    );
  }
  for (final dllName in _requiredGptkD3DMetalWindowsFileNames) {
    final path = _gptkD3DMetalWindowsPayloadPath(
      source.windowsDllRoot,
      dllName,
    );
    if (path == null) {
      return Left<String, Unit>('GPTK/D3DMetal payload is missing $dllName.');
    }
    if (!_looksLikePE(File(path))) {
      return Left<String, Unit>(
        '$dllName is not a Windows PE binary. Select an official or '
        'compatible Game Porting Toolkit distribution.',
      );
    }
  }
  for (final libraryName in _requiredGptkD3DMetalUnixFileNames) {
    final path = _gptkD3DMetalUnixPayloadPath(
      source.unixLibraryRoot,
      libraryName,
    );
    if (path == null) {
      return Left<String, Unit>(
        'GPTK/D3DMetal payload is missing $libraryName.',
      );
    }
    final type = FileSystemEntity.typeSync(path, followLinks: false);
    if (type == FileSystemEntityType.link) {
      if (Link(path).targetSync() != '../../external/libd3dshared.dylib') {
        return Left<String, Unit>(
          '$libraryName must be a symlink to '
          '../../external/libd3dshared.dylib.',
        );
      }
    } else if (type == FileSystemEntityType.file) {
      if (!_looksLikeMachO(File(path))) {
        return Left<String, Unit>(
          '$libraryName is not a Mach-O binary. Select an official or '
          'compatible Game Porting Toolkit distribution.',
        );
      }
    } else {
      return Left<String, Unit>(
        'GPTK/D3DMetal payload path is unsupported: $libraryName.',
      );
    }
  }
  for (final libraryName in const <String>['d3d11.so', 'd3d12.so', 'dxgi.so']) {
    final path = _gptkD3DMetalUnixPayloadPath(
      source.unixLibraryRoot,
      libraryName,
    );
    if (path == null ||
        FileSystemEntity.typeSync(path, followLinks: false) !=
            FileSystemEntityType.link ||
        Link(path).targetSync() != '../../external/libd3dshared.dylib') {
      return Left<String, Unit>(
        '$libraryName must be a symlink to '
        '../../external/libd3dshared.dylib.',
      );
    }
  }
  return const Right<String, Unit>(unit);
}

_GptkD3DMetalSource? _resolveGptkD3DMetalSource(String sourcePath) {
  final sourceType = FileSystemEntity.typeSync(sourcePath);
  if (sourceType == FileSystemEntityType.notFound) {
    return null;
  }

  if (sourceType == FileSystemEntityType.directory &&
      _baseName(sourcePath) == 'D3DMetal.framework') {
    return _gptkD3DMetalSourceFromExternalRoot(Directory(_dirname(sourcePath)));
  }

  if (sourceType != FileSystemEntityType.directory) {
    return null;
  }

  final directSource = _gptkD3DMetalSourceFromExternalRoot(
    Directory(sourcePath),
  );
  if (directSource != null) {
    return directSource;
  }

  final directExternalCandidate = Directory(
    _joinPath(sourcePath, const ['external']),
  );
  final directExternalSource = _gptkD3DMetalSourceFromExternalRoot(
    directExternalCandidate,
  );
  if (directExternalSource != null) {
    return directExternalSource;
  }

  final candidate = Directory(_joinPath(sourcePath, const ['lib', 'external']));
  return _gptkD3DMetalSourceFromExternalRoot(candidate);
}

_GptkD3DMetalSource? _gptkD3DMetalSourceFromExternalRoot(
  Directory externalRoot,
) {
  final framework = Directory(
    _joinPath(externalRoot.path, const ['D3DMetal.framework']),
  );
  final dylib = File(
    _joinPath(externalRoot.path, const ['libd3dshared.dylib']),
  );
  final libRoot = Directory(_dirname(externalRoot.path));
  final payloadRoot = _baseName(libRoot.path) == 'lib'
      ? Directory(_dirname(libRoot.path))
      : libRoot;
  final windowsDllRoot = Directory(
    _joinPath(libRoot.path, const ['wine', 'x86_64-windows']),
  );
  final unixLibraryRoot = Directory(
    _joinPath(libRoot.path, const ['wine', 'x86_64-unix']),
  );
  final dllSource = _resolveGptkD3DMetalWindowsDlls(windowsDllRoot);
  if (framework.existsSync() &&
      dylib.existsSync() &&
      unixLibraryRoot.existsSync() &&
      dllSource != null) {
    return _GptkD3DMetalSource(
      payloadRoot: payloadRoot,
      externalRoot: externalRoot,
      windowsDllRoot: windowsDllRoot,
      unixLibraryRoot: unixLibraryRoot,
      framework: framework,
      dylib: dylib,
      d3d11Dll: dllSource.d3d11Dll,
      d3d12Dll: dllSource.d3d12Dll,
      dxgiDll: dllSource.dxgiDll,
    );
  }

  return null;
}

class _GptkD3DMetalWindowsDllSource {
  const _GptkD3DMetalWindowsDllSource({
    required this.d3d11Dll,
    required this.d3d12Dll,
    required this.dxgiDll,
  });

  final File d3d11Dll;
  final File d3d12Dll;
  final File dxgiDll;
}

_GptkD3DMetalWindowsDllSource? _resolveGptkD3DMetalWindowsDlls(
  Directory windowsDllRoot,
) {
  final d3d12 = File(_joinPath(windowsDllRoot.path, const ['d3d12.dll']));
  final d3d11 = File(_joinPath(_dirname(d3d12.path), const ['d3d11.dll']));
  final dxgi = File(_joinPath(_dirname(d3d12.path), const ['dxgi.dll']));
  if (d3d11.existsSync() && d3d12.existsSync() && dxgi.existsSync()) {
    return _GptkD3DMetalWindowsDllSource(
      d3d11Dll: d3d11,
      d3d12Dll: d3d12,
      dxgiDll: dxgi,
    );
  }

  return null;
}

String? _gptkD3DMetalWindowsPayloadPath(
  Directory windowsDllRoot,
  String destinationName,
) {
  return _firstExistingFile(
    windowsDllRoot,
    _gptkD3DMetalSourceNames(destinationName),
  );
}

String? _gptkD3DMetalUnixPayloadPath(
  Directory unixLibraryRoot,
  String destinationName,
) {
  return _firstExistingFileSystemEntity(
    unixLibraryRoot,
    _gptkD3DMetalSourceNames(destinationName),
  );
}

List<String> _gptkD3DMetalSourceNames(String destinationName) {
  return switch (destinationName) {
    'nvngx.dll' => const <String>['nvngx.dll', 'nvngx-on-metalfx.dll'],
    'nvngx.so' => const <String>['nvngx.so', 'nvngx-on-metalfx.so'],
    _ => <String>[destinationName],
  };
}

String? _firstExistingFile(Directory root, Iterable<String> names) {
  for (final name in names) {
    final path = _joinPath(root.path, [name]);
    if (File(path).existsSync()) {
      return path;
    }
  }
  return null;
}

String? _firstExistingFileSystemEntity(Directory root, Iterable<String> names) {
  for (final name in names) {
    final path = _joinPath(root.path, [name]);
    if (FileSystemEntity.typeSync(path, followLinks: false) !=
        FileSystemEntityType.notFound) {
      return path;
    }
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
