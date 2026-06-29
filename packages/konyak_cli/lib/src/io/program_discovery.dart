import 'dart:io';

import '../domain/bottle/bottle_models.dart';
import '../domain/program/pinned_programs.dart';
import '../domain/program/program_catalog_models.dart';
import '../domain/program/program_run_models.dart';
import '../domain/program/program_runner.dart';
import '../domain/shared/domain_value_objects.dart';
import '../repository/repository_interfaces.dart';
import '../shared/common_helpers.dart';
import '../storage/storage_paths.dart';
import 'pe_program_metadata.dart';
import 'pinned_program_availability_io.dart';
import 'program_shortcut_metadata.dart';
import 'program_shortcut_metadata_io.dart';

class DartIoBottleProgramRepository implements BottleProgramRepository {
  const DartIoBottleProgramRepository({required this.metadataExtractor});

  final ProgramMetadataExtractor metadataExtractor;

  @override
  List<BottleProgramRecord> listPrograms(BottleRecord bottle) {
    final programs = <BottleProgramRecord>[];
    for (final source in bottleStartMenuSources(bottle)) {
      final directory = Directory(source.path.value);
      if (!directory.existsSync()) {
        continue;
      }

      for (final entity in directory.listSync(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File || !isShortcutPath(entity.path)) {
          continue;
        }

        final name = shortcutProgramName(entity.path);
        final id = uniqueProgramId(
          baseId: bottleIdFromName(name),
          existing: programs,
        );
        final metadata = metadataExtractor.extract(
          bottle: bottle,
          programPath: metadataProgramPath(
            bottle: bottle,
            programPath: ProgramPath(entity.path),
          ),
        );
        programs.add(
          BottleProgramRecord(
            id: ProgramId(id),
            name: ProgramName(name),
            path: ProgramPath(entity.path),
            source: source.id,
            metadata: metadata,
          ),
        );
      }
    }

    for (final pinnedProgram in bottle.pinnedPrograms) {
      if (!isLivePinnedProgram(
        bottle,
        pinnedProgram,
        isPinnedProgramAvailable: (program) =>
            isPinnedProgramFileAvailable(bottle: bottle, program: program),
      )) {
        continue;
      }

      if (hasDiscoveredProgramPath(programs, pinnedProgram.path.value)) {
        continue;
      }

      final id = uniqueProgramId(
        baseId: bottleIdFromName(pinnedProgram.name.value),
        existing: programs,
      );
      final metadata = metadataExtractor.extract(
        bottle: bottle,
        programPath: metadataProgramPath(
          bottle: bottle,
          programPath: pinnedProgram.path,
        ),
      );
      programs.add(
        BottleProgramRecord(
          id: ProgramId(id),
          name: pinnedProgram.name,
          path: pinnedProgram.path,
          source: ProgramSource('pinned'),
          metadata: metadata,
        ),
      );
    }

    programs.sort((left, right) => left.name.value.compareTo(right.name.value));
    return List.unmodifiable(programs);
  }
}

bool hasDiscoveredProgramPath(
  List<BottleProgramRecord> programs,
  String programPath,
) {
  final normalizedProgramPath = normalizeFilesystemPath(programPath);
  return programs.any(
    (program) =>
        normalizeFilesystemPath(program.path.value) == normalizedProgramPath,
  );
}

class DartIoBottlePrefixInitializer implements BottlePrefixInitializer {
  const DartIoBottlePrefixInitializer({
    required this.programRunPlanner,
    required this.programRunner,
  });

  final ProgramRunPlanner programRunPlanner;
  final ProgramRunner programRunner;

  @override
  BottlePrefixInitializationResult initialize(BottleRecord bottle) {
    for (final request in programRunPlanner.planPrefixBootstrap(
      bottle: bottle,
    )) {
      final result = programRunner.run(request);

      switch (result) {
        case ProgramRunCompleted(:final processExitCode)
            when processExitCode == 0:
          continue;
        case ProgramRunCompleted(:final processExitCode):
          return BottlePrefixInitializationFailed(
            '${request.programPath.value} exited with code $processExitCode. '
            'See ${request.logPath.value}.',
          );
        case ProgramRunFailed(:final message):
          return BottlePrefixInitializationFailed(message);
      }
    }

    return const BottlePrefixInitialized();
  }
}
