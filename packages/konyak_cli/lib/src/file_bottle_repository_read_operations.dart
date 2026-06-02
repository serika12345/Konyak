part of '../konyak_cli.dart';

mixin _FileBottleRepositoryReadOperations {
  String get bottleDirectory;

  ProgramMetadataExtractor get _programMetadataExtractor;
  List<BottleRecord> listBottles() {
    if (!_fileBottleRepositoryDirectoryExists(bottleDirectory)) {
      return const <BottleRecord>[];
    }

    try {
      final bottles =
          _fileBottleRepositoryBottleDirectories(bottleDirectory)
              .map((entry) => _readBottleMetadata(entry.path))
              .map(
                (bottle) => _bottleWithPinnedProgramIcons(
                  bottle,
                  programMetadataExtractor: _programMetadataExtractor,
                ),
              )
              .toList(growable: false)
            ..sort((left, right) => left.id.compareTo(right.id));

      return List.unmodifiable(bottles);
    } on FileSystemException catch (error) {
      throw BottleRepositoryException(error.message);
    } on FormatException catch (error) {
      throw BottleRepositoryException(error.message);
    }
  }

  BottleRecord? findBottle(String id) {
    if (!_fileBottleMetadataExists(bottleDirectory: bottleDirectory, id: id)) {
      return null;
    }

    try {
      return _bottleWithPinnedProgramIcons(
        _readBottleMetadata(_fileBottlePath(bottleDirectory, id)),
        programMetadataExtractor: _programMetadataExtractor,
      );
    } on FileSystemException catch (error) {
      throw BottleRepositoryException(error.message);
    } on FormatException catch (error) {
      throw BottleRepositoryException(error.message);
    }
  }
}
