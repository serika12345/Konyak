import 'package:fpdart/fpdart.dart';

import '../domain/bottle/bottle_models.dart';
import '../domain/program/pinned_programs.dart';
import '../domain/program/program_catalog_models.dart';
import '../domain/program/program_mutation_models.dart';
import '../io/io_result.dart';
import '../io/repository_storage_io.dart';
import '../storage/storage_paths.dart';

class FileBottleRepositoryProgramOperations {
  const FileBottleRepositoryProgramOperations({
    required this.programMetadataExtractor,
    required this.findBottle,
  });

  final ProgramMetadataExtractor programMetadataExtractor;
  final IoResult<Option<BottleRecord>> Function(String id) findBottle;

  ProgramPinResult pinProgram(ProgramPinRequest request) {
    return findBottle(request.bottleId.value).fold<ProgramPinResult>(
      ProgramPinFailed.new,
      (bottle) => bottle.match(
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

          final writeResult = ioResult(() {
            writeBottleMetadata(updated);
          });
          return writeResult.fold<ProgramPinResult>(
            ProgramPinFailed.new,
            (_) => ProgramPinned(updated),
          );
        },
      ),
    );
  }

  ProgramUpdateResult unpinProgram(ProgramUnpinRequest request) {
    return findBottle(request.bottleId.value).fold<ProgramUpdateResult>(
      ProgramUpdateFailed.new,
      (bottle) => bottle.match(
        () => ProgramUpdateMissingBottle(request.bottleId.value),
        (bottle) {
          if (!hasPinnedProgram(bottle, request.programPath.value)) {
            return ProgramUpdateMissingProgram(request.programPath.value);
          }

          final updated = bottleWithoutPinnedProgram(
            bottle,
            request.programPath.value,
          );

          final writeResult = ioResult(() {
            writeBottleMetadata(updated);
          });
          return writeResult.fold<ProgramUpdateResult>(
            ProgramUpdateFailed.new,
            (_) => ProgramUpdated(updated),
          );
        },
      ),
    );
  }

  ProgramUpdateResult renamePinnedProgram(ProgramRenameRequest request) {
    return findBottle(request.bottleId.value).fold<ProgramUpdateResult>(
      ProgramUpdateFailed.new,
      (bottle) => bottle.match(
        () => ProgramUpdateMissingBottle(request.bottleId.value),
        (bottle) {
          if (!hasPinnedProgram(bottle, request.programPath.value)) {
            return ProgramUpdateMissingProgram(request.programPath.value);
          }

          final updated = bottleWithRenamedPinnedProgram(bottle, request);

          final writeResult = ioResult(() {
            writeBottleMetadata(updated);
          });
          return writeResult.fold<ProgramUpdateResult>(
            ProgramUpdateFailed.new,
            (_) => ProgramUpdated(updated),
          );
        },
      ),
    );
  }

  ProgramSettingsReadResult readProgramSettings(
    ProgramSettingsRequest request,
  ) {
    return findBottle(request.bottleId.value).fold<ProgramSettingsReadResult>(
      ProgramSettingsReadResult.failed,
      (bottle) => bottle.match(
        () => ProgramSettingsReadResult.missingBottle(request.bottleId.value),
        (bottle) {
          final readResult = ioResult(
            () => readProgramSettingsJson(
              programSettingsJsonPath(
                bottle: bottle,
                programPath: request.programPath.value,
              ),
            ),
          );
          return readResult.fold<ProgramSettingsReadResult>(
            ProgramSettingsReadResult.failed,
            ProgramSettingsReadResult.read,
          );
        },
      ),
    );
  }

  ProgramSettingsUpdateResult setProgramSettings(
    ProgramSettingsUpdateRequest request,
  ) {
    return findBottle(request.bottleId.value).fold<ProgramSettingsUpdateResult>(
      ProgramSettingsUpdateResult.failed,
      (bottle) => bottle.match(
        () => ProgramSettingsUpdateResult.missingBottle(request.bottleId.value),
        (bottle) {
          final writeResult = ioResult(() {
            writeProgramSettingsJson(
              path: programSettingsJsonPath(
                bottle: bottle,
                programPath: request.programPath.value,
              ),
              settings: request.settings,
            );
          });
          return writeResult.fold<ProgramSettingsUpdateResult>(
            ProgramSettingsUpdateResult.failed,
            (_) => ProgramSettingsUpdateResult.updated(request.settings),
          );
        },
      ),
    );
  }
}
