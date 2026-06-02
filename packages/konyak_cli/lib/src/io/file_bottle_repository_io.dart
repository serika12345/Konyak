part of '../../konyak_cli.dart';

bool _fileBottleRepositoryDirectoryExists(String bottleDirectory) {
  return Directory(bottleDirectory).existsSync();
}

List<Directory> _fileBottleRepositoryBottleDirectories(String bottleDirectory) {
  return Directory(bottleDirectory)
      .listSync()
      .whereType<Directory>()
      .where((entry) {
        return File(_fileBottleMetadataPath(entry.path)).existsSync();
      })
      .toList(growable: false);
}

bool _fileBottleMetadataExists({
  required String bottleDirectory,
  required String id,
}) {
  return File(
    _fileBottleMetadataPath(_fileBottlePath(bottleDirectory, id)),
  ).existsSync();
}

bool _fileBottlePathExists(String bottlePath) {
  return _fileBottleDirectoryExists(bottlePath) ||
      File(_fileBottleMetadataPath(bottlePath)).existsSync();
}

bool _fileBottleDirectoryExists(String bottlePath) {
  return Directory(bottlePath).existsSync();
}

void _createFileBottleDirectories(String bottlePath) {
  Directory(bottlePath).createSync(recursive: true);
  Directory(
    _joinPath(bottlePath, const ['drive_c']),
  ).createSync(recursive: true);
}

void _deleteFileBottleDirectoryIfPresent(String bottlePath) {
  final directory = Directory(bottlePath);
  if (directory.existsSync()) {
    directory.deleteSync(recursive: true);
  }
}

void _moveFileBottleDirectoryIfChanged({
  required String from,
  required String to,
}) {
  if (_normalizeFilesystemPath(from) == _normalizeFilesystemPath(to)) {
    return;
  }

  _moveDirectory(from: from, to: to);
}

String _fileBottlePath(String bottleDirectory, String id) {
  return _joinPath(bottleDirectory, [id]);
}

String _fileBottleMetadataPath(String bottlePath) {
  return _joinPath(bottlePath, const ['metadata.json']);
}
