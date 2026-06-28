part of '../../konyak_cli.dart';

class DartIoBottleProgramRepository implements BottleProgramRepository {
  const DartIoBottleProgramRepository({
    ProgramMetadataExtractor metadataExtractor =
        const DartIoProgramMetadataExtractor(),
  }) : _metadataExtractor = metadataExtractor;

  final ProgramMetadataExtractor _metadataExtractor;

  @override
  List<BottleProgramRecord> listPrograms(BottleRecord bottle) {
    final programs = <BottleProgramRecord>[];
    for (final source in _bottleStartMenuSources(bottle)) {
      final directory = Directory(source.path.value);
      if (!directory.existsSync()) {
        continue;
      }

      for (final entity in directory.listSync(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File || !_isShortcutPath(entity.path)) {
          continue;
        }

        final name = _shortcutProgramName(entity.path);
        final id = _uniqueProgramId(
          baseId: _bottleIdFromName(name),
          existing: programs,
        );
        final metadata = _metadataExtractor.extract(
          bottle: bottle,
          programPath: _metadataProgramPath(
            bottle: bottle,
            programPath: entity.path,
          ),
        );
        programs.add(
          BottleProgramRecord(
            id: id,
            name: name,
            path: entity.path,
            source: source.id.value,
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
            _isPinnedProgramFileAvailable(bottle: bottle, program: program),
      )) {
        continue;
      }

      if (_hasDiscoveredProgramPath(programs, pinnedProgram.path.value)) {
        continue;
      }

      final id = _uniqueProgramId(
        baseId: _bottleIdFromName(pinnedProgram.name.value),
        existing: programs,
      );
      final metadata = _metadataExtractor.extract(
        bottle: bottle,
        programPath: _metadataProgramPath(
          bottle: bottle,
          programPath: pinnedProgram.path.value,
        ),
      );
      programs.add(
        BottleProgramRecord(
          id: id,
          name: pinnedProgram.name.value,
          path: pinnedProgram.path.value,
          source: 'pinned',
          metadata: metadata,
        ),
      );
    }

    programs.sort((left, right) => left.name.value.compareTo(right.name.value));
    return List.unmodifiable(programs);
  }
}

bool _hasDiscoveredProgramPath(
  List<BottleProgramRecord> programs,
  String programPath,
) {
  final normalizedProgramPath = _normalizeFilesystemPath(programPath);
  return programs.any(
    (program) =>
        _normalizeFilesystemPath(program.path.value) == normalizedProgramPath,
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
