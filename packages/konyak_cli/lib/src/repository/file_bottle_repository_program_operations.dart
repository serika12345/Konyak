import 'package:fpdart/fpdart.dart';

import '../domain/bottle/bottle_models.dart';
import '../domain/program/pinned_programs.dart';
import '../domain/program/program_catalog_models.dart';
import '../domain/program/program_mutation_models.dart';
import '../domain/program/program_profiles.dart';
import '../domain/shared/domain_value_objects.dart';
import '../io/io_result.dart';
import '../io/repository_storage_io.dart';
import '../storage/storage_paths.dart';

class FileBottleRepositoryProgramOperations {
  const FileBottleRepositoryProgramOperations({
    required this.programMetadataExtractor,
    required this.findBottle,
  });

  final ProgramMetadataExtractor programMetadataExtractor;
  final IoResult<Option<BottleRecord>> Function(BottleId id) findBottle;

  ProgramPinResult pinProgram(ProgramPinRequest request) {
    return findBottle(request.bottleId).fold<ProgramPinResult>(
      ProgramPinResult.failed,
      (bottle) => bottle.match(
        () => ProgramPinResult.missing(request.bottleId),
        (bottle) {
          if (hasPinnedProgram(bottle, request.programPath)) {
            return ProgramPinResult.conflict(request.programPath);
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
            ProgramPinResult.failed,
            (_) => ProgramPinResult.pinned(updated),
          );
        },
      ),
    );
  }

  ProgramUpdateResult unpinProgram(ProgramUnpinRequest request) {
    return findBottle(request.bottleId).fold<ProgramUpdateResult>(
      ProgramUpdateResult.failed,
      (bottle) => bottle.match(
        () => ProgramUpdateResult.missingBottle(request.bottleId),
        (bottle) {
          if (!hasPinnedProgram(bottle, request.programPath)) {
            return ProgramUpdateResult.missingProgram(request.programPath);
          }

          final updated = bottleWithoutPinnedProgram(
            bottle,
            request.programPath,
          );

          final writeResult = ioResult(() {
            writeBottleMetadata(updated);
          });
          return writeResult.fold<ProgramUpdateResult>(
            ProgramUpdateResult.failed,
            (_) => ProgramUpdateResult.updated(updated),
          );
        },
      ),
    );
  }

  ProgramUpdateResult renamePinnedProgram(ProgramRenameRequest request) {
    return findBottle(request.bottleId).fold<ProgramUpdateResult>(
      ProgramUpdateResult.failed,
      (bottle) => bottle.match(
        () => ProgramUpdateResult.missingBottle(request.bottleId),
        (bottle) {
          if (!hasPinnedProgram(bottle, request.programPath)) {
            return ProgramUpdateResult.missingProgram(request.programPath);
          }

          final updated = bottleWithRenamedPinnedProgram(bottle, request);

          final writeResult = ioResult(() {
            writeBottleMetadata(updated);
          });
          return writeResult.fold<ProgramUpdateResult>(
            ProgramUpdateResult.failed,
            (_) => ProgramUpdateResult.updated(updated),
          );
        },
      ),
    );
  }

  ProgramSettingsReadResult readProgramSettings(
    ProgramSettingsRequest request,
  ) {
    return findBottle(request.bottleId).fold<ProgramSettingsReadResult>(
      ProgramSettingsReadResult.failed,
      (bottle) => bottle.match(
        () => ProgramSettingsReadResult.missingBottle(request.bottleId),
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
    return findBottle(request.bottleId).fold<ProgramSettingsUpdateResult>(
      ProgramSettingsUpdateResult.failed,
      (bottle) => bottle.match(
        () => ProgramSettingsUpdateResult.missingBottle(request.bottleId),
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

  ProgramProfileUpdateResult applyProgramProfile(
    ProgramProfileApplyRequest request,
  ) {
    return findBottle(request.bottleId).fold<ProgramProfileUpdateResult>(
      ProgramProfileUpdateResult.failed,
      (bottle) => bottle.match(
        () => ProgramProfileUpdateResult.missingBottle(request.bottleId),
        (bottle) {
          final updated = bottleWithAppliedProgramProfile(
            bottle: bottle,
            installProfile: request.installProfile,
            programPath: request.programPath,
            programMetadataExtractor: programMetadataExtractor,
          );
          final writeResult = ioResult(() {
            writeBottleMetadata(updated);
          });
          return writeResult.fold<ProgramProfileUpdateResult>(
            ProgramProfileUpdateResult.failed,
            (_) => findProgramProfile(updated, request.installProfile.id).match(
              () => const ProgramProfileUpdateResult.failed(
                'Program profile metadata was not written.',
              ),
              (profile) => ProgramProfileUpdateResult.updated(
                bottleId: request.bottleId,
                profile: profile,
              ),
            ),
          );
        },
      ),
    );
  }

  ProgramProfileUpdateResult repairProgramProfile(
    ProgramProfileRepairRequest request,
  ) {
    return findBottle(request.bottleId).fold<ProgramProfileUpdateResult>(
      ProgramProfileUpdateResult.failed,
      (bottle) => bottle.match(
        () => ProgramProfileUpdateResult.missingBottle(request.bottleId),
        (bottle) => findProgramProfile(bottle, request.installProfile.id).match(
          () => ProgramProfileUpdateResult.profileNotApplied(
            request.installProfile.id,
          ),
          (_) {
            final updated = bottleWithRepairedProgramProfile(
              bottle: bottle,
              installProfile: request.installProfile,
              programMetadataExtractor: programMetadataExtractor,
            );
            final writeResult = ioResult(() {
              writeBottleMetadata(updated);
            });
            return writeResult.fold<ProgramProfileUpdateResult>(
              ProgramProfileUpdateResult.failed,
              (_) =>
                  findProgramProfile(updated, request.installProfile.id).match(
                    () => const ProgramProfileUpdateResult.failed(
                      'Program profile metadata was not written.',
                    ),
                    (profile) => ProgramProfileUpdateResult.updated(
                      bottleId: request.bottleId,
                      profile: profile,
                    ),
                  ),
            );
          },
        ),
      ),
    );
  }
}
