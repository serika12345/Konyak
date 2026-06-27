part of '../../konyak_cli.dart';

CliResult? _handleBottleReadCommand(
  List<String> arguments, {
  required _CliCommandContext context,
  required BottleCatalog activeBottleCatalog,
}) {
  if (_isJsonBottleListCommand(arguments)) {
    return activeBottleCatalog.listBottles().match<CliResult>(
      _bottleCatalogFailureJsonResult,
      (bottles) {
        _synchronizePinnedProgramLaunchers(
          hostPlatform: context.programRunPlanner.hostPlatform,
          environment: context.programRunPlanner.environment.toMap(),
          bottles: bottles,
        );
        return _jsonSuccess(<String, Object?>{
          'bottles': bottles
              .map((bottle) => bottle.toJson())
              .toList(growable: false),
        });
      },
    );
  }

  final inspectedBottleId = _parseJsonBottleInspectCommand(arguments);
  if (inspectedBottleId != null) {
    final bottleId = inspectedBottleId;
    return _foundBottleJsonResult(
      result: activeBottleCatalog.findBottle(bottleId),
      bottleId: bottleId,
      onFound: (bottle) {
        final inspectedBottle = _bottleWithRegistrySettings(
          bottle: bottle,
          programRunPlanner: context.programRunPlanner,
          programRunner: context.programRunner,
        );
        return _bottleJsonResult(inspectedBottle);
      },
    );
  }

  final bottleProgramsListId = _parseJsonBottleProgramsListCommand(arguments);
  if (bottleProgramsListId != null) {
    return _foundBottleJsonResult(
      result: activeBottleCatalog.findBottle(bottleProgramsListId),
      bottleId: bottleProgramsListId,
      onFound: (bottle) => _jsonSuccess(<String, Object?>{
        'bottlePrograms': <String, Object?>{
          'bottleId': bottle.id.value,
          'programs': context.bottleProgramRepository
              .listPrograms(bottle)
              .map((program) => program.toJson())
              .toList(growable: false),
        },
      }),
    );
  }

  return null;
}
