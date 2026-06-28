import 'package:fpdart/fpdart.dart';

import '../domain/bottle/bottle_models.dart';
import '../domain/bottle/bottle_mutation_models.dart';
import '../domain/program/pinned_programs.dart';
import '../domain/program/program_catalog_models.dart';
import '../domain/program/program_mutation_models.dart';
import '../domain/program/program_settings_models.dart';
import '../io/bottle_archives.dart';
import '../io/io_result.dart';
import '../shared/common_helpers.dart';
import '../storage/storage_paths.dart';
import 'file_bottle_repository_read_operations.dart';
import 'repository_interfaces.dart';

class StaticBottleCatalog implements BottleCatalog {
  StaticBottleCatalog(Iterable<BottleRecord> bottles)
    : bottles = List.unmodifiable(bottles);

  final List<BottleRecord> bottles;

  @override
  IoResult<List<BottleRecord>> listBottles() {
    return Right<String, List<BottleRecord>>(List.unmodifiable(bottles));
  }

  @override
  IoResult<Option<BottleRecord>> findBottle(String id) {
    for (final bottle in bottles) {
      if (bottle.id.value == id) {
        return Right<String, Option<BottleRecord>>(Option.of(bottle));
      }
    }

    return const Right<String, Option<BottleRecord>>(Option.none());
  }
}

class MemoryBottleRepository implements BottleRepository {
  MemoryBottleRepository({
    required this.dataHome,
    Iterable<BottleRecord> bottles = const <BottleRecord>[],
    Map<String, ProgramSettingsRecord> programSettings =
        const <String, ProgramSettingsRecord>{},
    required this.programMetadataExtractor,
  }) : bottlesById = <String, BottleRecord>{
         for (final bottle in bottles) bottle.id.value: bottle,
       },
       programSettingsByKey = Map<String, ProgramSettingsRecord>.of(
         programSettings,
       );

  final String dataHome;
  final Map<String, BottleRecord> bottlesById;
  final Map<String, ProgramSettingsRecord> programSettingsByKey;
  final ProgramMetadataExtractor programMetadataExtractor;

  @override
  IoResult<List<BottleRecord>> listBottles() {
    final bottles =
        bottlesById.values
            .toList(growable: false)
            .map((bottle) {
              final updated = bottleWithPinnedProgramIcons(
                bottleWithoutMissingBottleLocalPinnedProgramFiles(bottle),
                programMetadataExtractor: programMetadataExtractor,
              );
              if (updated != bottle) {
                bottlesById[bottle.id.value] = updated;
              }
              return updated;
            })
            .toList(growable: false)
          ..sort((left, right) => left.id.value.compareTo(right.id.value));

    return Right<String, List<BottleRecord>>(List.unmodifiable(bottles));
  }

  @override
  IoResult<Option<BottleRecord>> findBottle(String id) {
    return mapValue(bottlesById, id).match(
      () => const Right<String, Option<BottleRecord>>(Option.none()),
      (bottle) {
        final updated = bottleWithPinnedProgramIcons(
          bottleWithoutMissingBottleLocalPinnedProgramFiles(bottle),
          programMetadataExtractor: programMetadataExtractor,
        );
        if (updated != bottle) {
          bottlesById[id] = updated;
        }

        return Right<String, Option<BottleRecord>>(Option.of(updated));
      },
    );
  }

  @override
  BottleCreateResult createBottle(BottleCreateRequest request) {
    final bottle = bottleFromCreateRequest(request, dataHome);

    if (bottlesById.containsKey(bottle.id.value)) {
      return BottleCreateConflict(bottle.id.value);
    }

    bottlesById[bottle.id.value] = bottle;

    return BottleCreated(bottle);
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
    return readBottleArchive(
      archivePath: request.archivePath.value,
      bottleDirectory: joinPath(dataHome, const ['bottles']),
      hasBottle: (String bottleId) =>
          Right<String, bool>(bottlesById.containsKey(bottleId)),
      onImported: (BottleRecord bottle) {
        bottlesById[bottle.id.value] = bottle;
      },
    );
  }

  @override
  BottleDeleteResult deleteBottle(String id) {
    return removeMapValue(
      bottlesById,
      id,
    ).match(() => BottleDeleteMissing(id), BottleDeleted.new);
  }

  @override
  BottleRenameResult renameBottle(BottleRenameRequest request) {
    return mapValue(bottlesById, request.bottleId.value).match(
      () => BottleRenameMissing(request.bottleId.value),
      (bottle) {
        final renamed = renamedMemoryBottle(
          bottle: bottle,
          name: request.name.value,
          dataHome: dataHome,
        );
        final hasConflict = mapValue(bottlesById, renamed.id.value).match(
          () => false,
          (conflictingBottle) => conflictingBottle.id.value != bottle.id.value,
        );
        if (hasConflict) {
          return BottleRenameConflict(renamed.id.value);
        }

        bottlesById.remove(bottle.id.value);
        bottlesById[renamed.id.value] = renamed;

        return BottleRenamed(renamed);
      },
    );
  }

  @override
  BottleMoveResult moveBottle(BottleMoveRequest request) {
    return mapValue(bottlesById, request.bottleId.value).match(
      () => BottleMoveMissing(request.bottleId.value),
      (bottle) {
        if (hasBottleAtPath(
          bottlesById.values,
          request.path.value,
          exceptId: bottle.id.value,
        )) {
          return BottleMoveConflict(request.path.value);
        }

        final moved = bottle.withPath(request.path.value);
        bottlesById[bottle.id.value] = moved;

        return BottleMoved(moved);
      },
    );
  }

  @override
  BottleUpdateResult setWindowsVersion(WindowsVersionUpdateRequest request) {
    return mapValue(bottlesById, request.bottleId.value).match(
      () => BottleUpdateMissing(request.bottleId.value),
      (bottle) {
        final updated = bottle.withWindowsVersion(request.windowsVersion.value);
        bottlesById[request.bottleId.value] = updated;

        return BottleUpdated(updated);
      },
    );
  }

  @override
  BottleUpdateResult setRuntimeSettings(RuntimeSettingsUpdateRequest request) {
    return mapValue(bottlesById, request.bottleId.value).match(
      () => BottleUpdateMissing(request.bottleId.value),
      (bottle) {
        final updated = bottle.withRuntimeSettings(request.runtimeSettings);
        bottlesById[request.bottleId.value] = updated;

        return BottleUpdated(updated);
      },
    );
  }

  @override
  ProgramPinResult pinProgram(ProgramPinRequest request) {
    return mapValue(bottlesById, request.bottleId.value).match(
      () => ProgramPinMissing(request.bottleId.value),
      (bottle) {
        if (hasPinnedProgram(bottle, request.programPath.value)) {
          return ProgramPinConflict(request.programPath.value);
        }

        final updated = bottleWithPinnedProgram(
          bottle,
          request,
          programMetadataExtractor: programMetadataExtractor,
        );
        bottlesById[request.bottleId.value] = updated;

        return ProgramPinned(updated);
      },
    );
  }

  @override
  ProgramUpdateResult unpinProgram(ProgramUnpinRequest request) {
    return mapValue(bottlesById, request.bottleId.value).match(
      () => ProgramUpdateMissingBottle(request.bottleId.value),
      (bottle) {
        if (!hasPinnedProgram(bottle, request.programPath.value)) {
          return ProgramUpdateMissingProgram(request.programPath.value);
        }

        final updated = bottleWithoutPinnedProgram(
          bottle,
          request.programPath.value,
        );
        bottlesById[request.bottleId.value] = updated;

        return ProgramUpdated(updated);
      },
    );
  }

  @override
  ProgramUpdateResult renamePinnedProgram(ProgramRenameRequest request) {
    return mapValue(bottlesById, request.bottleId.value).match(
      () => ProgramUpdateMissingBottle(request.bottleId.value),
      (bottle) {
        if (!hasPinnedProgram(bottle, request.programPath.value)) {
          return ProgramUpdateMissingProgram(request.programPath.value);
        }

        final updated = bottleWithRenamedPinnedProgram(bottle, request);
        bottlesById[request.bottleId.value] = updated;

        return ProgramUpdated(updated);
      },
    );
  }

  @override
  ProgramSettingsReadResult readProgramSettings(
    ProgramSettingsRequest request,
  ) {
    return mapValue(bottlesById, request.bottleId.value).match(
      () => ProgramSettingsReadMissingBottle(request.bottleId.value),
      (bottle) => ProgramSettingsRead(
        mapValue(
          programSettingsByKey,
          programSettingsKey(
            bottleId: bottle.id.value,
            programPath: request.programPath.value,
          ),
        ).match(ProgramSettingsRecord.new, (settings) => settings),
      ),
    );
  }

  @override
  ProgramSettingsUpdateResult setProgramSettings(
    ProgramSettingsUpdateRequest request,
  ) {
    return mapValue(bottlesById, request.bottleId.value).match(
      () => ProgramSettingsUpdateMissingBottle(request.bottleId.value),
      (bottle) {
        programSettingsByKey[programSettingsKey(
              bottleId: bottle.id.value,
              programPath: request.programPath.value,
            )] =
            request.settings;

        return ProgramSettingsUpdated(request.settings);
      },
    );
  }
}

Option<V> mapValue<K, V>(Map<K, V> map, K key) {
  if (!map.containsKey(key)) {
    return const Option.none();
  }

  return Option.of(map[key] as V);
}

Option<V> removeMapValue<K, V>(Map<K, V> map, K key) {
  if (!map.containsKey(key)) {
    return const Option.none();
  }

  return Option.of(map.remove(key) as V);
}
