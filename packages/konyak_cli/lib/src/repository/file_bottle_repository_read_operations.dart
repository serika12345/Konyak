import 'package:fpdart/fpdart.dart';

import '../domain/bottle/bottle_metadata_recovery_models.dart';
import '../domain/bottle/bottle_models.dart';
import '../domain/program/pinned_programs.dart';
import '../domain/program/program_catalog_models.dart';
import '../domain/shared/domain_value_objects.dart';
import '../io/bottle_metadata_recovery_io.dart';
import '../io/file_bottle_repository_io.dart';
import '../io/io_result.dart';
import '../io/pinned_program_availability_io.dart';
import '../io/repository_storage_io.dart';
import '../shared/common_helpers.dart';

class FileBottleRepositoryReadOperations {
  const FileBottleRepositoryReadOperations({
    required this.bottleDirectory,
    required this.programMetadataExtractor,
  });

  final String bottleDirectory;
  final ProgramMetadataExtractor programMetadataExtractor;

  IoResult<List<BottleRecord>> listBottles() {
    return listBottleCatalog().map(
      (snapshot) => List<BottleRecord>.unmodifiable(snapshot.bottles),
    );
  }

  IoResult<BottleCatalogSnapshot> listBottleCatalog() {
    return ioResult(() {
      switch (fileBottleRepositoryRootStatus(bottleDirectory)) {
        case FileBottleRepositoryRootStatus.missing:
          return BottleCatalogSnapshot();
        case FileBottleRepositoryRootStatus.invalid:
          throw const FormatException(
            'Bottle repository root is not a directory.',
          );
        case FileBottleRepositoryRootStatus.directory:
          break;
      }

      final inspections = fileBottleRepositoryBottleDirectories(bottleDirectory)
          .map((entry) {
            return inspectBottleMetadata(
              bottlePath: entry.path,
              storageId: BottleStorageId(baseName(entry.path)),
            );
          })
          .toList(growable: false);
      final bottles =
          inspections
              .whereType<ValidBottleMetadata>()
              .map((inspection) => inspection.bottle)
              .map(repairedBottleWithoutMissingBottleLocalPinnedProgramFiles)
              .map(
                (bottle) => bottleWithPinnedProgramIcons(
                  bottle,
                  programMetadataExtractor: programMetadataExtractor,
                ),
              )
              .toList(growable: false)
            ..sort((left, right) => left.id.value.compareTo(right.id.value));

      final invalidBottles =
          inspections
              .whereType<InvalidBottleMetadata>()
              .map((inspection) => inspection.summary)
              .toList(growable: false)
            ..sort(
              (left, right) =>
                  left.storageId.value.compareTo(right.storageId.value),
            );

      return BottleCatalogSnapshot(
        bottles: bottles,
        invalidBottles: invalidBottles,
      );
    });
  }

  IoResult<Option<BottleRecord>> findBottle(BottleId id) {
    if (!fileBottleMetadataExists(
      bottleDirectory: bottleDirectory,
      id: id.value,
    )) {
      return const Right<String, Option<BottleRecord>>(Option.none());
    }

    return ioResult(
      () => Option.of(
        bottleWithPinnedProgramIcons(
          repairedBottleWithoutMissingBottleLocalPinnedProgramFiles(
            readBottleMetadata(fileBottlePath(bottleDirectory, id.value)),
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
