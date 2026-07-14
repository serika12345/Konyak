import 'package:fpdart/fpdart.dart';

import '../domain/bottle/bottle_metadata_recovery_models.dart';
import '../domain/bottle/bottle_models.dart';
import '../domain/bottle/bottle_mutation_models.dart';
import '../domain/program/program_mutation_models.dart';
import '../domain/shared/domain_value_objects.dart';
import '../io/bottle_archives.dart';
import '../io/io_result.dart';
import 'repository_interfaces.dart';

class CompositeBottleRepository
    implements
        BottleRepository,
        RecoverableBottleCatalog,
        BottleMetadataRepairRepository {
  CompositeBottleRepository({
    required Iterable<BottleCatalog> catalogs,
    required this.writableRepository,
  }) : catalogs = List.unmodifiable(catalogs);

  final List<BottleCatalog> catalogs;
  final BottleRepository writableRepository;

  @override
  IoResult<List<BottleRecord>> listBottles() {
    return listBottleCatalog().map(
      (snapshot) => List<BottleRecord>.unmodifiable(snapshot.bottles),
    );
  }

  @override
  IoResult<BottleCatalogSnapshot> listBottleCatalog() {
    final records = <String, BottleRecord>{};
    final claimedStorageIds = <String>{};
    final invalidBottles = <InvalidBottleSummary>[];
    return _listBottleCatalog(writableRepository).match<
      IoResult<BottleCatalogSnapshot>
    >(Left<String, BottleCatalogSnapshot>.new, (writableSnapshot) {
      for (final bottle in writableSnapshot.bottles) {
        records[bottle.id.value] = bottle;
        claimedStorageIds.add(bottle.id.value);
      }
      for (final invalidBottle in writableSnapshot.invalidBottles) {
        if (claimedStorageIds.add(invalidBottle.storageId.value)) {
          invalidBottles.add(invalidBottle);
        }
      }

      for (final catalog in catalogs) {
        switch (_listBottleCatalog(catalog)) {
          case Left<String, BottleCatalogSnapshot>(:final value):
            return Left<String, BottleCatalogSnapshot>(value);
          case Right<String, BottleCatalogSnapshot>(:final value):
            for (final bottle in value.bottles) {
              if (claimedStorageIds.add(bottle.id.value)) {
                records[bottle.id.value] = bottle;
              }
            }
            for (final invalidBottle in value.invalidBottles) {
              if (claimedStorageIds.add(invalidBottle.storageId.value)) {
                invalidBottles.add(invalidBottle);
              }
            }
        }
      }

      final bottles = records.values.toList(growable: false)
        ..sort((left, right) => left.id.value.compareTo(right.id.value));
      invalidBottles.sort(
        (left, right) => left.storageId.value.compareTo(right.storageId.value),
      );

      return Right<String, BottleCatalogSnapshot>(
        BottleCatalogSnapshot(bottles: bottles, invalidBottles: invalidBottles),
      );
    });
  }

  @override
  BottleMetadataRepairResult repairBottleMetadata(
    BottleMetadataRepairRequest request,
  ) {
    final repositories = switch (writableRepository) {
      final BottleMetadataRepairRepository repository =>
        <BottleMetadataRepairRepository>[
          repository,
          ...catalogs.whereType<BottleMetadataRepairRepository>(),
        ],
      _ => catalogs.whereType<BottleMetadataRepairRepository>().toList(
        growable: false,
      ),
    };
    return _repairBottleMetadataAcrossRepositories(
      repositories: repositories,
      request: request,
      index: 0,
    );
  }

  @override
  IoResult<Option<BottleRecord>> findBottle(BottleId id) {
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
    return findBottle(request.bottleId).fold(
      BottleArchiveExportFailed.new,
      (bottle) => bottle.match(
        () => BottleArchiveExportMissing(request.bottleId),
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
  BottleDeleteResult deleteBottle(BottleId id) {
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

    return ProgramSettingsReadResult.missingBottle(request.bottleId);
  }

  @override
  ProgramSettingsUpdateResult setProgramSettings(
    ProgramSettingsUpdateRequest request,
  ) {
    return writableRepository.setProgramSettings(request);
  }

  @override
  ProgramProfileUpdateResult applyProgramProfile(
    ProgramProfileApplyRequest request,
  ) {
    return writableRepository.applyProgramProfile(request);
  }

  @override
  ProgramProfileUpdateResult repairProgramProfile(
    ProgramProfileRepairRequest request,
  ) {
    return writableRepository.repairProgramProfile(request);
  }
}

IoResult<BottleCatalogSnapshot> _listBottleCatalog(BottleCatalog catalog) {
  return switch (catalog) {
    final RecoverableBottleCatalog recoverable =>
      recoverable.listBottleCatalog(),
    _ => catalog.listBottles().map(
      (bottles) => BottleCatalogSnapshot(bottles: bottles),
    ),
  };
}

BottleMetadataRepairResult _repairBottleMetadataAcrossRepositories({
  required List<BottleMetadataRepairRepository> repositories,
  required BottleMetadataRepairRequest request,
  required int index,
}) {
  if (index >= repositories.length) {
    return BottleMetadataRepairMissing(request.storageId);
  }

  final current = repositories[index].repairBottleMetadata(request);
  return switch (current) {
    BottleMetadataRepaired() || BottleMetadataRepairFailed() => current,
    BottleMetadataRepairMissing() => _repairBottleMetadataAcrossRepositories(
      repositories: repositories,
      request: request,
      index: index + 1,
    ),
    BottleMetadataRepairNotRepairable() => current,
  };
}
