import 'dart:io';

import '../platform/platform_terminal_commands.dart';
import '../shared/common_helpers.dart';
import 'gptk_wine_installation.dart';

void normalizeMacosWineRuntimeLayout(Directory runtimeRoot) {
  moveRuntimeLayoutChildrenToRoot(
    runtimeRoot: runtimeRoot,
    sourceRoot: Directory(joinPath(runtimeRoot.path, const ['Wine'])),
  );
  moveRuntimeLayoutChildrenToRoot(
    runtimeRoot: runtimeRoot,
    sourceRoot: Directory(
      joinPath(runtimeRoot.path, const ['Contents', 'Resources', 'wine']),
    ),
  );
  for (final entry in runtimeRoot.listSync()) {
    if (entry is! Directory || !basename(entry.path).endsWith('.app')) {
      continue;
    }
    moveRuntimeLayoutChildrenToRoot(
      runtimeRoot: runtimeRoot,
      sourceRoot: Directory(
        joinPath(entry.path, const ['Contents', 'Resources', 'wine']),
      ),
    );
    if (entry.existsSync()) {
      entry.deleteSync(recursive: true);
    }
  }
  normalizeMacosRuntimeComponents(runtimeRoot);
}

void normalizeMacosRuntimeComponents(Directory runtimeRoot) {
  final componentsRoot = Directory(
    joinPath(runtimeRoot.path, const ['Components']),
  );
  if (!componentsRoot.existsSync()) {
    return;
  }

  normalizeDxmtComponent(
    runtimeRoot: runtimeRoot,
    componentsRoot: componentsRoot,
  );
  normalizeDxvkComponent(
    runtimeRoot: runtimeRoot,
    componentsRoot: componentsRoot,
  );
  normalizeGptkD3DMetalComponent(
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
    moveRuntimeLayoutChildrenToRoot(
      runtimeRoot: runtimeRoot,
      sourceRoot: Directory(joinPath(componentsRoot.path, [componentId])),
    );
  }

  if (componentsRoot.existsSync() && componentsRoot.listSync().isEmpty) {
    componentsRoot.deleteSync(recursive: true);
  }
}

void normalizeDxmtComponent({
  required Directory runtimeRoot,
  required Directory componentsRoot,
}) {
  final sourceRoot = Directory(
    joinPath(componentsRoot.path, const ['DXMT', 'components', 'dxmt']),
  );
  if (!sourceRoot.existsSync()) {
    return;
  }

  final targetParent = Directory(joinPath(runtimeRoot.path, const ['lib']));
  final temporaryDxmtRoot = joinPath(runtimeRoot.path, const [
    '.konyak-dxmt-normalized',
  ]);
  moveFileSystemEntity(sourceRoot, temporaryDxmtRoot);
  final dxmtComponentRoot = Directory(
    joinPath(componentsRoot.path, const ['DXMT']),
  );
  if (dxmtComponentRoot.existsSync()) {
    dxmtComponentRoot.deleteSync(recursive: true);
  }
  targetParent.createSync(recursive: true);
  moveFileSystemEntity(
    Directory(temporaryDxmtRoot),
    joinPath(targetParent.path, const ['dxmt']),
  );
}

void normalizeDxvkComponent({
  required Directory runtimeRoot,
  required Directory componentsRoot,
}) {
  for (final sourceRoot in <Directory>[
    Directory(joinPath(componentsRoot.path, const ['DXVK-macOS', 'DXVK'])),
    Directory(joinPath(componentsRoot.path, const ['DXVK'])),
  ]) {
    if (!sourceRoot.existsSync()) {
      continue;
    }

    final targetRoot = Directory(
      joinPath(runtimeRoot.path, const ['lib', 'dxvk']),
    )..createSync(recursive: true);
    moveDirectoryIfExists(
      Directory(joinPath(targetRoot.path, const ['x64'])),
      Directory(joinPath(targetRoot.path, const ['x86_64-windows'])),
    );
    moveDirectoryIfExists(
      Directory(joinPath(targetRoot.path, const ['x32'])),
      Directory(joinPath(targetRoot.path, const ['i386-windows'])),
    );
    moveDirectoryIfExists(
      Directory(joinPath(sourceRoot.path, const ['x64'])),
      Directory(joinPath(targetRoot.path, const ['x86_64-windows'])),
    );
    moveDirectoryIfExists(
      Directory(joinPath(sourceRoot.path, const ['x32'])),
      Directory(joinPath(targetRoot.path, const ['i386-windows'])),
    );
    moveDirectoryIfExists(
      Directory(joinPath(sourceRoot.path, const ['x86_64-windows'])),
      Directory(joinPath(targetRoot.path, const ['x86_64-windows'])),
    );
    moveDirectoryIfExists(
      Directory(joinPath(sourceRoot.path, const ['i386-windows'])),
      Directory(joinPath(targetRoot.path, const ['i386-windows'])),
    );
    if (sourceRoot.existsSync()) {
      sourceRoot.deleteSync(recursive: true);
    }
  }
}

void normalizeGptkD3DMetalComponent({
  required Directory runtimeRoot,
  required Directory componentsRoot,
}) {
  for (final sourceRoot in <Directory>[
    Directory(joinPath(componentsRoot.path, const ['GPTK-D3DMetal'])),
    Directory(joinPath(componentsRoot.path, const ['gptk-d3dmetal'])),
    Directory(joinPath(componentsRoot.path, const ['D3DMetal'])),
  ]) {
    if (!sourceRoot.existsSync()) {
      continue;
    }

    final targetRoot = Directory(
      joinPath(runtimeRoot.path, gptkD3DMetalComponentRelativePath),
    )..createSync(recursive: true);
    if (sameDirectory(sourceRoot, targetRoot)) {
      continue;
    }
    final sourceLibRoot = Directory(joinPath(sourceRoot.path, const ['lib']));
    if (sourceLibRoot.existsSync()) {
      moveRuntimeLayoutChildrenToRoot(
        runtimeRoot: targetRoot,
        sourceRoot: sourceRoot,
      );
      continue;
    }

    final targetLibRoot = Directory(joinPath(targetRoot.path, const ['lib']))
      ..createSync(recursive: true);
    moveRuntimeLayoutChildrenToRoot(
      runtimeRoot: targetLibRoot,
      sourceRoot: sourceRoot,
    );
  }
}

bool sameDirectory(Directory left, Directory right) {
  try {
    return left.resolveSymbolicLinksSync() == right.resolveSymbolicLinksSync();
  } on FileSystemException {
    return left.path == right.path;
  }
}

void moveDirectoryIfExists(Directory source, Directory destination) {
  if (!source.existsSync()) {
    return;
  }
  if (destination.existsSync()) {
    moveRuntimeLayoutChildrenToRoot(
      runtimeRoot: destination,
      sourceRoot: source,
    );
    return;
  }
  destination.parent.createSync(recursive: true);
  source.renameSync(destination.path);
}

void moveRuntimeLayoutChildrenToRoot({
  required Directory runtimeRoot,
  required Directory sourceRoot,
}) {
  if (!sourceRoot.existsSync()) {
    return;
  }

  for (final entry in sourceRoot.listSync()) {
    final targetPath = joinPath(runtimeRoot.path, [basename(entry.path)]);
    moveFileSystemEntity(entry, targetPath);
  }

  sourceRoot.deleteSync(recursive: true);
}

void moveFileSystemEntity(FileSystemEntity entry, String targetPath) {
  final sourceType = FileSystemEntity.typeSync(entry.path);
  final targetType = FileSystemEntity.typeSync(targetPath);
  if (sourceType == FileSystemEntityType.directory &&
      targetType == FileSystemEntityType.directory) {
    for (final child in Directory(entry.path).listSync()) {
      moveFileSystemEntity(child, joinPath(targetPath, [basename(child.path)]));
    }
    Directory(entry.path).deleteSync();
    return;
  }

  if (targetType != FileSystemEntityType.notFound) {
    deleteFileSystemEntity(targetPath, targetType);
  }
  entry.renameSync(targetPath);
}

void deleteFileSystemEntity(String path, FileSystemEntityType type) {
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
