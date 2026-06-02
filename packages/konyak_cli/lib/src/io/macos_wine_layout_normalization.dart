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

    for (final componentId in const <String>[
      'DXVK-macOS',
      'DXVK',
      'MoltenVK',
      'GStreamer',
      'wine-mono',
      'winetricks',
      'GPTK-D3DMetal',
      'gptk-d3dmetal',
      'D3DMetal',
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

  void _ensureMacosWine64Alias(Directory runtimeRoot) {
    final binPath = _joinPath(runtimeRoot.path, const ['bin']);
    final winePath = _joinPath(binPath, const ['wine']);
    final wine64Path = _joinPath(binPath, const ['wine64']);

    if (FileSystemEntity.typeSync(wine64Path) !=
        FileSystemEntityType.notFound) {
      return;
    }
    if (FileSystemEntity.typeSync(winePath) == FileSystemEntityType.notFound) {
      return;
    }

    Link(wine64Path).createSync('wine');
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
