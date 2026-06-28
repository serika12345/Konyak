part of '../../konyak_cli.dart';

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
              .map(_repairedBottleWithoutMissingBottleLocalPinnedProgramFiles)
              .map(
                (bottle) => bottleWithPinnedProgramIcons(
                  bottle,
                  programMetadataExtractor: _programMetadataExtractor,
                ),
              )
              .toList(growable: false)
            ..sort((left, right) => left.id.value.compareTo(right.id.value));

      return List.unmodifiable(bottles);
    });
  }

  IoResult<Option<BottleRecord>> findBottle(String id) {
    if (!_fileBottleMetadataExists(bottleDirectory: bottleDirectory, id: id)) {
      return const Right<String, Option<BottleRecord>>(Option.none());
    }

    return _ioResult(
      () => Option.of(
        bottleWithPinnedProgramIcons(
          _repairedBottleWithoutMissingBottleLocalPinnedProgramFiles(
            _readBottleMetadata(_fileBottlePath(bottleDirectory, id)),
          ),
          programMetadataExtractor: _programMetadataExtractor,
        ),
      ),
    );
  }
}

BottleRecord _repairedBottleWithoutMissingBottleLocalPinnedProgramFiles(
  BottleRecord bottle,
) {
  final updated = _bottleWithoutMissingBottleLocalPinnedProgramFiles(bottle);
  if (updated != bottle) {
    _writeBottleMetadata(updated);
  }
  return updated;
}

BottleRecord _bottleWithoutMissingBottleLocalPinnedProgramFiles(
  BottleRecord bottle,
) {
  return bottleWithoutMissingBottleLocalPinnedPrograms(
    bottle,
    isPinnedProgramAvailable: (program) =>
        _isPinnedProgramFileAvailable(bottle: bottle, program: program),
  );
}
