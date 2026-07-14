import 'dart:io';

import '../shared/common_helpers.dart';
import 'directory_copy_support.dart';

enum FileBottleRepositoryRootStatus { missing, directory, invalid }

FileBottleRepositoryRootStatus fileBottleRepositoryRootStatus(
  String bottleDirectory,
) {
  final rootType = FileSystemEntity.typeSync(
    bottleDirectory,
    followLinks: false,
  );
  if (rootType == FileSystemEntityType.notFound) {
    return FileBottleRepositoryRootStatus.missing;
  }

  return Directory(bottleDirectory).existsSync()
      ? FileBottleRepositoryRootStatus.directory
      : FileBottleRepositoryRootStatus.invalid;
}

bool fileBottleRepositoryDirectoryExists(String bottleDirectory) {
  return Directory(bottleDirectory).existsSync();
}

List<Directory> fileBottleRepositoryBottleDirectories(String bottleDirectory) {
  return Directory(bottleDirectory)
      .listSync()
      .whereType<Directory>()
      .where((entry) {
        return File(fileBottleMetadataPath(entry.path)).existsSync();
      })
      .toList(growable: false);
}

bool fileBottleMetadataExists({
  required String bottleDirectory,
  required String id,
}) {
  return File(
    fileBottleMetadataPath(fileBottlePath(bottleDirectory, id)),
  ).existsSync();
}

bool fileBottlePathExists(String bottlePath) {
  return File(fileBottleMetadataPath(bottlePath)).existsSync();
}

bool fileBottleDirectoryExists(String bottlePath) {
  return Directory(bottlePath).existsSync();
}

void createFileBottleDirectories(String bottlePath) {
  Directory(bottlePath).createSync(recursive: true);
  Directory(
    joinPath(bottlePath, const ['drive_c']),
  ).createSync(recursive: true);
}

void deleteFileBottleDirectoryIfPresent(String bottlePath) {
  final directory = Directory(bottlePath);
  if (directory.existsSync()) {
    final metadataPath = normalizeFilesystemPath(
      fileBottleMetadataPath(bottlePath),
    );
    for (final entry in directory.listSync()) {
      if (normalizeFilesystemPath(entry.path) == metadataPath) {
        continue;
      }
      entry.deleteSync(recursive: true);
    }

    final metadata = File(fileBottleMetadataPath(bottlePath));
    if (metadata.existsSync()) {
      metadata.deleteSync();
    }
    directory.deleteSync();
  }
}

void moveFileBottleDirectoryIfChanged({
  required String from,
  required String to,
}) {
  if (normalizeFilesystemPath(from) == normalizeFilesystemPath(to)) {
    return;
  }

  moveDirectory(from: from, to: to);
}

String fileBottlePath(String bottleDirectory, String id) {
  return joinPath(bottleDirectory, [id]);
}

String fileBottleMetadataPath(String bottlePath) {
  return joinPath(bottlePath, const ['metadata.json']);
}
