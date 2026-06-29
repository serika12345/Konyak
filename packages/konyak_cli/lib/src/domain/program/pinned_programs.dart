import 'package:fpdart/fpdart.dart';

import '../bottle/bottle_models.dart';
import '../shared/domain_helpers.dart';
import '../shared/domain_value_objects.dart';
import 'program_catalog_models.dart';
import 'program_mutation_models.dart';

bool hasPinnedProgram(BottleRecord bottle, String programPath) {
  final normalizedProgramPath = normalizeFilesystemPath(programPath);
  return bottle.pinnedPrograms.any(
    (program) => _isPinnedProgramPath(program, normalizedProgramPath),
  );
}

bool _isPinnedProgramPath(PinnedProgramRecord program, String normalizedPath) {
  return normalizeFilesystemPath(program.path.value) == normalizedPath;
}

BottleRecord bottleWithPinnedProgram(
  BottleRecord bottle,
  ProgramPinRequest request, {
  required ProgramMetadataExtractor programMetadataExtractor,
}) {
  final metadata = programMetadataExtractor.extract(
    bottle: bottle,
    programPath: request.programPath.value,
  );

  return bottle.withPinnedPrograms(<PinnedProgramRecord>[
    ...bottle.pinnedPrograms,
    PinnedProgramRecord(
      name: request.name.value,
      path: request.programPath.value,
      iconPath: metadata.match(
        () => const Option<String>.none(),
        (programMetadata) =>
            programMetadata.iconPath.map((value) => value.value),
      ),
    ),
  ]);
}

BottleRecord bottleWithPinnedProgramIcons(
  BottleRecord bottle, {
  required ProgramMetadataExtractor programMetadataExtractor,
}) {
  final updatedPinnedPrograms = bottle.pinnedPrograms
      .map((program) {
        if (program.iconPath.isSome()) {
          return (program: program, changed: false);
        }

        final metadata = programMetadataExtractor.extract(
          bottle: bottle,
          programPath: program.path.value,
        );
        final iconPath = metadata.match(
          () => const Option<ProgramIconPath>.none(),
          (programMetadata) => programMetadata.iconPath,
        );
        if (iconPath.isNone()) {
          return (program: program, changed: false);
        }

        return (program: program.withIconPath(iconPath), changed: true);
      })
      .toList(growable: false);
  final changed = updatedPinnedPrograms.any((program) => program.changed);

  if (!changed) {
    return bottle;
  }

  return bottle.withPinnedPrograms(
    updatedPinnedPrograms.map((program) => program.program),
  );
}

BottleRecord bottleWithoutMissingBottleLocalPinnedPrograms(
  BottleRecord bottle, {
  required bool Function(PinnedProgramRecord program) isPinnedProgramAvailable,
}) {
  final pinnedPrograms = bottle.pinnedPrograms
      .where(
        (program) =>
            !_isBottleLocalPinnedProgramPath(bottle, program.path.value) ||
            isPinnedProgramAvailable(program),
      )
      .toList(growable: false);

  if (pinnedPrograms.length == bottle.pinnedPrograms.length) {
    return bottle;
  }

  return bottle.withPinnedPrograms(pinnedPrograms);
}

bool isLivePinnedProgram(
  BottleRecord bottle,
  PinnedProgramRecord program, {
  required bool Function(PinnedProgramRecord program) isPinnedProgramAvailable,
}) {
  return !_isBottleLocalPinnedProgramPath(bottle, program.path.value) ||
      isPinnedProgramAvailable(program);
}

bool _isBottleLocalPinnedProgramPath(BottleRecord bottle, String programPath) {
  return isPathWithinRoot(
    path: normalizeFilesystemPath(programPath),
    root: normalizeFilesystemPath(bottle.path.value),
  );
}

BottleRecord bottleWithoutPinnedProgram(
  BottleRecord bottle,
  String programPath,
) {
  final normalizedProgramPath = normalizeFilesystemPath(programPath);
  return bottle.withPinnedPrograms(
    bottle.pinnedPrograms
        .where(
          (program) => !_isPinnedProgramPath(program, normalizedProgramPath),
        )
        .toList(growable: false),
  );
}

BottleRecord bottleWithRenamedPinnedProgram(
  BottleRecord bottle,
  ProgramRenameRequest request,
) {
  final normalizedProgramPath = normalizeFilesystemPath(
    request.programPath.value,
  );
  return bottle.withPinnedPrograms(
    bottle.pinnedPrograms
        .map(
          (program) => _isPinnedProgramPath(program, normalizedProgramPath)
              ? program.withName(request.name)
              : program,
        )
        .toList(growable: false),
  );
}
