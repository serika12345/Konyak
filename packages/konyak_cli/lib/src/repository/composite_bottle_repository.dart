import 'package:fpdart/fpdart.dart';

import '../domain/bottle/bottle_models.dart';
import '../domain/bottle/bottle_mutation_models.dart';
import '../domain/program/program_mutation_models.dart';
import '../io/bottle_archives.dart';
import '../io/io_result.dart';
import 'repository_interfaces.dart';

class CompositeBottleRepository implements BottleRepository {
  CompositeBottleRepository({
    required Iterable<BottleCatalog> catalogs,
    required this.writableRepository,
  }) : catalogs = List.unmodifiable(catalogs);

  final List<BottleCatalog> catalogs;
  final BottleRepository writableRepository;

  @override
  IoResult<List<BottleRecord>> listBottles() {
    final records = <String, BottleRecord>{};
    return writableRepository.listBottles().match<IoResult<List<BottleRecord>>>(
      Left<String, List<BottleRecord>>.new,
      (writableBottles) {
        for (final bottle in writableBottles) {
          records[bottle.id.value] = bottle;
        }

        for (final catalog in catalogs) {
          switch (catalog.listBottles()) {
            case Left<String, List<BottleRecord>>(:final value):
              return Left<String, List<BottleRecord>>(value);
            case Right<String, List<BottleRecord>>(:final value):
              for (final bottle in value) {
                records.putIfAbsent(bottle.id.value, () => bottle);
              }
          }
        }

        final bottles = records.values.toList(growable: false)
          ..sort((left, right) => left.id.value.compareTo(right.id.value));

        return Right<String, List<BottleRecord>>(List.unmodifiable(bottles));
      },
    );
  }

  @override
  IoResult<Option<BottleRecord>> findBottle(String id) {
    return writableRepository
        .findBottle(id)
        .match<IoResult<Option<BottleRecord>>>(
          Left<String, Option<BottleRecord>>.new,
          (localRecord) {
            if (localRecord.isSome()) {
              return Right<String, Option<BottleRecord>>(localRecord);
            }

            for (final catalog in catalogs) {
              switch (catalog.findBottle(id)) {
                case Left<String, Option<BottleRecord>>(:final value):
                  return Left<String, Option<BottleRecord>>(value);
                case Right<String, Option<BottleRecord>>(:final value):
                  if (value.isSome()) {
                    return Right<String, Option<BottleRecord>>(value);
                  }
              }
            }

            return const Right<String, Option<BottleRecord>>(Option.none());
          },
        );
  }

  @override
  BottleCreateResult createBottle(BottleCreateRequest request) {
    return writableRepository.createBottle(request);
  }

  @override
  BottleArchiveExportResult exportBottleArchive(
    BottleArchiveExportRequest request,
  ) {
    return findBottle(request.bottleId.value).fold(
      BottleArchiveExportFailed.new,
      (bottle) => bottle.match(
        () => BottleArchiveExportMissing(request.bottleId.value),
        (bottle) => writeBottleArchive(
          bottle: bottle,
          archivePath: request.archivePath.value,
        ),
      ),
    );
  }

  @override
  BottleArchiveImportResult importBottleArchive(
    BottleArchiveImportRequest request,
  ) {
    return writableRepository.importBottleArchive(request);
  }

  @override
  BottleDeleteResult deleteBottle(String id) {
    return writableRepository.deleteBottle(id);
  }

  @override
  BottleRenameResult renameBottle(BottleRenameRequest request) {
    return writableRepository.renameBottle(request);
  }

  @override
  BottleMoveResult moveBottle(BottleMoveRequest request) {
    return writableRepository.moveBottle(request);
  }

  @override
  BottleUpdateResult setWindowsVersion(WindowsVersionUpdateRequest request) {
    return writableRepository.setWindowsVersion(request);
  }

  @override
  BottleUpdateResult setRuntimeSettings(RuntimeSettingsUpdateRequest request) {
    return writableRepository.setRuntimeSettings(request);
  }

  @override
  ProgramPinResult pinProgram(ProgramPinRequest request) {
    return writableRepository.pinProgram(request);
  }

  @override
  ProgramUpdateResult unpinProgram(ProgramUnpinRequest request) {
    return writableRepository.unpinProgram(request);
  }

  @override
  ProgramUpdateResult renamePinnedProgram(ProgramRenameRequest request) {
    return writableRepository.renamePinnedProgram(request);
  }

  @override
  ProgramSettingsReadResult readProgramSettings(
    ProgramSettingsRequest request,
  ) {
    final writableRead = writableRepository.readProgramSettings(request);
    if (writableRead is ProgramSettingsRead) {
      return writableRead;
    }

    for (final catalog in catalogs) {
      if (catalog is! BottleRepository) {
        continue;
      }

      final catalogRead = catalog.readProgramSettings(request);
      if (catalogRead is ProgramSettingsRead) {
        return catalogRead;
      }
    }

    return ProgramSettingsReadMissingBottle(request.bottleId.value);
  }

  @override
  ProgramSettingsUpdateResult setProgramSettings(
    ProgramSettingsUpdateRequest request,
  ) {
    return writableRepository.setProgramSettings(request);
  }
}
