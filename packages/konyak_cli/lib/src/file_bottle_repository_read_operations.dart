part of '../konyak_cli.dart';

class _FileBottleRepositoryReadOperations {
  const _FileBottleRepositoryReadOperations({
    required this.bottleDirectory,
    required ProgramMetadataExtractor programMetadataExtractor,
  }) : _programMetadataExtractor = programMetadataExtractor;

  final String bottleDirectory;
  final ProgramMetadataExtractor _programMetadataExtractor;

  IoResult<List<BottleRecord>> listBottles() {
    if (!_fileBottleRepositoryDirectoryExists(bottleDirectory)) {
      return const Right<String, List<BottleRecord>>(<BottleRecord>[]);
    }

    return _ioResult(() {
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
    });
  }

  IoResult<BottleRecord?> findBottle(String id) {
    if (!_fileBottleMetadataExists(bottleDirectory: bottleDirectory, id: id)) {
      return const Right<String, BottleRecord?>(null);
    }

    return _ioResult(
      () => _bottleWithPinnedProgramIcons(
        _readBottleMetadata(_fileBottlePath(bottleDirectory, id)),
        programMetadataExtractor: _programMetadataExtractor,
      ),
    );
  }
}
