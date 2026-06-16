part of '../../konyak_cli.dart';

extension _MacosWineLayoutNormalization on DartIoMacosWineInstaller {
  void _normalizeMacosWineRuntimeLayout(Directory runtimeRoot) {
    _moveRuntimeLayoutChildrenToRoot(
      runtimeRoot: runtimeRoot,
      sourceRoot: Directory(_joinPath(runtimeRoot.path, const ['Wine'])),
    );
    _moveRuntimeLayoutChildrenToRoot(
      runtimeRoot: runtimeRoot,
      sourceRoot: Directory(
        _joinPath(runtimeRoot.path, const ['Contents', 'Resources', 'wine']),
      ),
    );
    for (final entry in runtimeRoot.listSync()) {
      if (entry is! Directory || !_basename(entry.path).endsWith('.app')) {
        continue;
      }
      _moveRuntimeLayoutChildrenToRoot(
        runtimeRoot: runtimeRoot,
        sourceRoot: Directory(
          _joinPath(entry.path, const ['Contents', 'Resources', 'wine']),
        ),
      );
      if (entry.existsSync()) {
        entry.deleteSync(recursive: true);
      }
    }
    _normalizeMacosRuntimeComponents(runtimeRoot);
  }

  void _normalizeMacosRuntimeComponents(Directory runtimeRoot) {
    final componentsRoot = Directory(
      _joinPath(runtimeRoot.path, const ['Components']),
    );
    if (!componentsRoot.existsSync()) {
      return;
    }

    _normalizeDxmtComponent(
      runtimeRoot: runtimeRoot,
      componentsRoot: componentsRoot,
    );
    _normalizeDxvkComponent(
      runtimeRoot: runtimeRoot,
      componentsRoot: componentsRoot,
    );
    _normalizeGptkD3DMetalComponent(
      runtimeRoot: runtimeRoot,
      componentsRoot: componentsRoot,
    );

    for (final componentId in const <String>[
      'MoltenVK',
      'GStreamer',
      'FreeType',
      'wine-mono',
      'wine-gecko',
      'winetricks',
      'vkd3d',
    ]) {
      _moveRuntimeLayoutChildrenToRoot(
        runtimeRoot: runtimeRoot,
        sourceRoot: Directory(_joinPath(componentsRoot.path, [componentId])),
      );
    }

    if (componentsRoot.existsSync() && componentsRoot.listSync().isEmpty) {
      componentsRoot.deleteSync(recursive: true);
    }
  }

  void _normalizeDxmtComponent({
    required Directory runtimeRoot,
    required Directory componentsRoot,
  }) {
    final sourceRoot = Directory(
      _joinPath(componentsRoot.path, const ['DXMT', 'components', 'dxmt']),
    );
    if (!sourceRoot.existsSync()) {
      return;
    }

    final targetParent = Directory(_joinPath(runtimeRoot.path, const ['lib']));
    final temporaryDxmtRoot = _joinPath(runtimeRoot.path, const [
      '.konyak-dxmt-normalized',
    ]);
    _moveFileSystemEntity(sourceRoot, temporaryDxmtRoot);
    final dxmtComponentRoot = Directory(
      _joinPath(componentsRoot.path, const ['DXMT']),
    );
    if (dxmtComponentRoot.existsSync()) {
      dxmtComponentRoot.deleteSync(recursive: true);
    }
    targetParent.createSync(recursive: true);
    _moveFileSystemEntity(
      Directory(temporaryDxmtRoot),
      _joinPath(targetParent.path, const ['dxmt']),
    );
  }

  void _normalizeDxvkComponent({
    required Directory runtimeRoot,
    required Directory componentsRoot,
  }) {
    for (final sourceRoot in <Directory>[
      Directory(_joinPath(componentsRoot.path, const ['DXVK-macOS', 'DXVK'])),
      Directory(_joinPath(componentsRoot.path, const ['DXVK'])),
    ]) {
      if (!sourceRoot.existsSync()) {
        continue;
      }

      final targetRoot = Directory(
        _joinPath(runtimeRoot.path, const ['lib', 'dxvk']),
      )..createSync(recursive: true);
      _moveDirectoryIfExists(
        Directory(_joinPath(targetRoot.path, const ['x64'])),
        Directory(_joinPath(targetRoot.path, const ['x86_64-windows'])),
      );
      _moveDirectoryIfExists(
        Directory(_joinPath(targetRoot.path, const ['x32'])),
        Directory(_joinPath(targetRoot.path, const ['i386-windows'])),
      );
      _moveDirectoryIfExists(
        Directory(_joinPath(sourceRoot.path, const ['x64'])),
        Directory(_joinPath(targetRoot.path, const ['x86_64-windows'])),
      );
      _moveDirectoryIfExists(
        Directory(_joinPath(sourceRoot.path, const ['x32'])),
        Directory(_joinPath(targetRoot.path, const ['i386-windows'])),
      );
      _moveDirectoryIfExists(
        Directory(_joinPath(sourceRoot.path, const ['x86_64-windows'])),
        Directory(_joinPath(targetRoot.path, const ['x86_64-windows'])),
      );
      _moveDirectoryIfExists(
        Directory(_joinPath(sourceRoot.path, const ['i386-windows'])),
        Directory(_joinPath(targetRoot.path, const ['i386-windows'])),
      );
      if (sourceRoot.existsSync()) {
        sourceRoot.deleteSync(recursive: true);
      }
    }
  }

  void _normalizeGptkD3DMetalComponent({
    required Directory runtimeRoot,
    required Directory componentsRoot,
  }) {
    for (final sourceRoot in <Directory>[
      Directory(_joinPath(componentsRoot.path, const ['GPTK-D3DMetal'])),
      Directory(_joinPath(componentsRoot.path, const ['gptk-d3dmetal'])),
      Directory(_joinPath(componentsRoot.path, const ['D3DMetal'])),
    ]) {
      if (!sourceRoot.existsSync()) {
        continue;
      }

      final targetRoot = Directory(
        _joinPath(runtimeRoot.path, _gptkD3DMetalComponentRelativePath),
      )..createSync(recursive: true);
      if (_sameDirectory(sourceRoot, targetRoot)) {
        continue;
      }
      final sourceLibRoot = Directory(
        _joinPath(sourceRoot.path, const ['lib']),
      );
      if (sourceLibRoot.existsSync()) {
        _moveRuntimeLayoutChildrenToRoot(
          runtimeRoot: targetRoot,
          sourceRoot: sourceRoot,
        );
        continue;
      }

      final targetLibRoot = Directory(_joinPath(targetRoot.path, const ['lib']))
        ..createSync(recursive: true);
      _moveRuntimeLayoutChildrenToRoot(
        runtimeRoot: targetLibRoot,
        sourceRoot: sourceRoot,
      );
    }
  }

  bool _sameDirectory(Directory left, Directory right) {
    try {
      return left.resolveSymbolicLinksSync() ==
          right.resolveSymbolicLinksSync();
    } on FileSystemException {
      return left.path == right.path;
    }
  }

  void _moveDirectoryIfExists(Directory source, Directory destination) {
    if (!source.existsSync()) {
      return;
    }
    if (destination.existsSync()) {
      _moveRuntimeLayoutChildrenToRoot(
        runtimeRoot: destination,
        sourceRoot: source,
      );
      return;
    }
    destination.parent.createSync(recursive: true);
    source.renameSync(destination.path);
  }

  void _moveRuntimeLayoutChildrenToRoot({
    required Directory runtimeRoot,
    required Directory sourceRoot,
  }) {
    if (!sourceRoot.existsSync()) {
      return;
    }

    for (final entry in sourceRoot.listSync()) {
      final targetPath = _joinPath(runtimeRoot.path, [_basename(entry.path)]);
      _moveFileSystemEntity(entry, targetPath);
    }

    sourceRoot.deleteSync(recursive: true);
  }

  void _moveFileSystemEntity(FileSystemEntity entry, String targetPath) {
    final sourceType = FileSystemEntity.typeSync(entry.path);
    final targetType = FileSystemEntity.typeSync(targetPath);
    if (sourceType == FileSystemEntityType.directory &&
        targetType == FileSystemEntityType.directory) {
      for (final child in Directory(entry.path).listSync()) {
        _moveFileSystemEntity(
          child,
          _joinPath(targetPath, [_basename(child.path)]),
        );
      }
      Directory(entry.path).deleteSync();
      return;
    }

    if (targetType != FileSystemEntityType.notFound) {
      _deleteFileSystemEntity(targetPath, targetType);
    }
    entry.renameSync(targetPath);
  }

  void _deleteFileSystemEntity(String path, FileSystemEntityType type) {
    switch (type) {
      case FileSystemEntityType.directory:
        Directory(path).deleteSync(recursive: true);
      case FileSystemEntityType.file:
      case FileSystemEntityType.link:
      case FileSystemEntityType.pipe:
      case FileSystemEntityType.unixDomainSock:
        File(path).deleteSync();
      case FileSystemEntityType.notFound:
        break;
    }
  }
}
