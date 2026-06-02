part of '../konyak_cli.dart';

bool _hasPinnedProgram(BottleRecord bottle, String programPath) {
  final normalizedProgramPath = _normalizeFilesystemPath(programPath);
  return bottle.pinnedPrograms.any(
    (program) => _isPinnedProgramPath(program, normalizedProgramPath),
  );
}

bool _isPinnedProgramPath(PinnedProgramRecord program, String normalizedPath) {
  return _normalizeFilesystemPath(program.path) == normalizedPath;
}

BottleRecord _bottleWithPinnedProgram(
  BottleRecord bottle,
  ProgramPinRequest request, {
  required ProgramMetadataExtractor programMetadataExtractor,
}) {
  final metadata = programMetadataExtractor.extract(
    bottle: bottle,
    programPath: _metadataProgramPath(
      bottle: bottle,
      programPath: request.programPath,
    ),
  );

  return bottle.withPinnedPrograms(<PinnedProgramRecord>[
    ...bottle.pinnedPrograms,
    PinnedProgramRecord(
      name: request.name,
      path: request.programPath,
      iconPath: metadata.match(
        () => const Option<String>.none(),
        (programMetadata) => programMetadata.iconPath,
      ),
    ),
  ]);
}

BottleRecord _bottleWithPinnedProgramIcons(
  BottleRecord bottle, {
  required ProgramMetadataExtractor programMetadataExtractor,
}) {
  var changed = false;
  final pinnedPrograms = bottle.pinnedPrograms
      .map((program) {
        if (program.iconPath.isSome()) {
          return program;
        }

        final metadata = programMetadataExtractor.extract(
          bottle: bottle,
          programPath: _metadataProgramPath(
            bottle: bottle,
            programPath: program.path,
          ),
        );
        final iconPath = metadata.match(
          () => const Option<String>.none(),
          (programMetadata) => programMetadata.iconPath,
        );
        if (iconPath.isNone()) {
          return program;
        }

        changed = true;
        return program.withIconPath(iconPath);
      })
      .toList(growable: false);

  if (!changed) {
    return bottle;
  }

  return bottle.withPinnedPrograms(pinnedPrograms);
}

BottleRecord _bottleWithoutPinnedProgram(
  BottleRecord bottle,
  String programPath,
) {
  final normalizedProgramPath = _normalizeFilesystemPath(programPath);
  return bottle.withPinnedPrograms(
    bottle.pinnedPrograms
        .where(
          (program) => !_isPinnedProgramPath(program, normalizedProgramPath),
        )
        .toList(growable: false),
  );
}

BottleRecord _bottleWithRenamedPinnedProgram(
  BottleRecord bottle,
  ProgramRenameRequest request,
) {
  final normalizedProgramPath = _normalizeFilesystemPath(request.programPath);
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
