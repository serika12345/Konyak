import 'dart:io';

import '../shared/common_helpers.dart';

void moveDirectory({required String from, required String to}) {
  final source = Directory(from);
  if (!source.existsSync()) {
    throw FileSystemException('Bottle directory was not found.', from);
  }

  final destination = Directory(to);
  destination.parent.createSync(recursive: true);

  try {
    source.renameSync(destination.path);
  } on FileSystemException {
    copyDirectory(source: source, destination: destination);
    source.deleteSync(recursive: true);
  }
}

void copyDirectory({
  required Directory source,
  required Directory destination,
}) {
  if (destination.existsSync()) {
    throw FileSystemException(
      'Destination directory already exists.',
      destination.path,
    );
  }

  destination.createSync(recursive: true);
  for (final entity in source.listSync(followLinks: false)) {
    final targetPath = joinPath(destination.path, [baseName(entity.path)]);
    if (entity is Directory) {
      copyDirectory(source: entity, destination: Directory(targetPath));
    } else if (entity is File) {
      entity.copySync(targetPath);
    } else if (entity is Link) {
      Link(targetPath).createSync(entity.targetSync());
    }
  }
}

void copyDirectoryContentsReplacing({
  required Directory source,
  required Directory destination,
  List<List<String>> skipRelativePaths = const <List<String>>[],
}) {
  destination.createSync(recursive: true);
  copyDirectoryEntriesReplacing(
    source: source,
    destination: destination,
    relativePath: const <String>[],
    skipRelativePaths: skipRelativePaths,
  );
}

void copyDirectoryEntriesReplacing({
  required Directory source,
  required Directory destination,
  required List<String> relativePath,
  required List<List<String>> skipRelativePaths,
}) {
  for (final entity in source.listSync(followLinks: false)) {
    final name = baseName(entity.path);
    final entityRelativePath = <String>[...relativePath, name];
    if (isSkippedRelativePath(entityRelativePath, skipRelativePaths)) {
      continue;
    }
    final targetPath = joinPath(destination.path, [name]);
    if (entity is Directory) {
      final targetType = FileSystemEntity.typeSync(targetPath);
      if (targetType != FileSystemEntityType.notFound &&
          targetType != FileSystemEntityType.directory) {
        deleteFileSystemEntitySync(targetPath, targetType);
      }
      final targetDirectory = Directory(targetPath)
        ..createSync(recursive: true);
      copyDirectoryEntriesReplacing(
        source: entity,
        destination: targetDirectory,
        relativePath: entityRelativePath,
        skipRelativePaths: skipRelativePaths,
      );
    } else if (entity is File) {
      final targetType = FileSystemEntity.typeSync(targetPath);
      if (targetType == FileSystemEntityType.directory) {
        Directory(targetPath).deleteSync(recursive: true);
      }
      entity.copySync(targetPath);
    } else if (entity is Link) {
      final targetType = FileSystemEntity.typeSync(targetPath);
      if (targetType != FileSystemEntityType.notFound) {
        deleteFileSystemEntitySync(targetPath, targetType);
      }
      Link(targetPath).createSync(entity.targetSync());
    }
  }
}

void deleteFileSystemEntitySync(String path, FileSystemEntityType type) {
  if (type == FileSystemEntityType.directory) {
    Directory(path).deleteSync(recursive: true);
  } else if (type == FileSystemEntityType.link) {
    Link(path).deleteSync();
  } else {
    File(path).deleteSync();
  }
}

void deleteDirectoryIfPresent(Directory directory) {
  if (directory.existsSync()) {
    directory.deleteSync(recursive: true);
  }
}

bool isSkippedRelativePath(
  List<String> relativePath,
  List<List<String>> skipRelativePaths,
) {
  for (final skipped in skipRelativePaths) {
    if (relativePath.length < skipped.length) {
      continue;
    }
    var matches = true;
    for (var index = 0; index < skipped.length; index += 1) {
      if (relativePath[index] != skipped[index]) {
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
