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
      final directory = Directory(source.path);
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
            source: source.id,
            metadata: metadata,
          ),
        );
      }
    }

    for (final pinnedProgram in bottle.pinnedPrograms) {
      final id = _uniqueProgramId(
        baseId: _bottleIdFromName(pinnedProgram.name),
        existing: programs,
      );
      final metadata = _metadataExtractor.extract(
        bottle: bottle,
        programPath: _metadataProgramPath(
          bottle: bottle,
          programPath: pinnedProgram.path,
        ),
      );
      programs.add(
        BottleProgramRecord(
          id: id,
          name: pinnedProgram.name,
          path: pinnedProgram.path,
          source: 'pinned',
          metadata: metadata,
        ),
      );
    }

    programs.sort((left, right) => left.name.compareTo(right.name));
    return List.unmodifiable(programs);
  }
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
    final request = programRunPlanner.planPrefixInitialization(bottle: bottle);
    final result = programRunner.run(request);

    return switch (result) {
      ProgramRunCompleted(:final processExitCode) when processExitCode == 0 =>
        const BottlePrefixInitialized(),
      ProgramRunCompleted(:final processExitCode) =>
        BottlePrefixInitializationFailed(
          'wineboot exited with code $processExitCode. See ${request.logPath}.',
        ),
      ProgramRunFailed(:final message) => BottlePrefixInitializationFailed(
        message,
      ),
    };
  }
}
