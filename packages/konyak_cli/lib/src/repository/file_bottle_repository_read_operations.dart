import 'package:fpdart/fpdart.dart';

import '../domain/bottle/bottle_models.dart';
import '../domain/program/pinned_programs.dart';
import '../domain/program/program_catalog_models.dart';
import '../io/file_bottle_repository_io.dart';
import '../io/io_result.dart';
import '../io/pinned_program_availability_io.dart';
import '../io/repository_storage_io.dart';

class FileBottleRepositoryReadOperations {
  const FileBottleRepositoryReadOperations({
    required this.bottleDirectory,
    required this.programMetadataExtractor,
  });

  final String bottleDirectory;
  final ProgramMetadataExtractor programMetadataExtractor;

  IoResult<List<BottleRecord>> listBottles() {
    if (!fileBottleRepositoryDirectoryExists(bottleDirectory)) {
      return const Right<String, List<BottleRecord>>(<BottleRecord>[]);
    }

    return ioResult(() {
      final bottles =
          fileBottleRepositoryBottleDirectories(bottleDirectory)
              .map((entry) => readBottleMetadata(entry.path))
              .map(repairedBottleWithoutMissingBottleLocalPinnedProgramFiles)
              .map(
                (bottle) => bottleWithPinnedProgramIcons(
                  bottle,
                  programMetadataExtractor: programMetadataExtractor,
                ),
              )
              .toList(growable: false)
            ..sort((left, right) => left.id.value.compareTo(right.id.value));

      return List.unmodifiable(bottles);
    });
  }

  IoResult<Option<BottleRecord>> findBottle(String id) {
    if (!fileBottleMetadataExists(bottleDirectory: bottleDirectory, id: id)) {
      return const Right<String, Option<BottleRecord>>(Option.none());
    }

    return ioResult(
      () => Option.of(
        bottleWithPinnedProgramIcons(
          repairedBottleWithoutMissingBottleLocalPinnedProgramFiles(
            readBottleMetadata(fileBottlePath(bottleDirectory, id)),
          ),
          programMetadataExtractor: programMetadataExtractor,
        ),
      ),
    );
  }
}

BottleRecord repairedBottleWithoutMissingBottleLocalPinnedProgramFiles(
  BottleRecord bottle,
) {
  final updated = bottleWithoutMissingBottleLocalPinnedProgramFiles(bottle);
  if (updated != bottle) {
    writeBottleMetadata(updated);
  }
  return updated;
}

BottleRecord bottleWithoutMissingBottleLocalPinnedProgramFiles(
  BottleRecord bottle,
) {
  return bottleWithoutMissingBottleLocalPinnedPrograms(
    bottle,
    isPinnedProgramAvailable: (program) =>
        isPinnedProgramFileAvailable(bottle: bottle, program: program),
  );
}
