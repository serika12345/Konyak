part of '../konyak_cli.dart';

CliResult? _handleBottleReadCommand(
  List<String> arguments, {
  required _CliCommandContext context,
  required BottleCatalog activeBottleCatalog,
}) {
  if (_isJsonBottleListCommand(arguments)) {
    final bottlesResult = activeBottleCatalog.listBottles();
    final failure = bottlesResult.fold<CliResult?>(
      _bottleCatalogFailureJsonResult,
      (_) => null,
    );
    if (failure != null) {
      return failure;
    }
    final bottles = bottlesResult.getOrElse((_) => const <BottleRecord>[]);
    _synchronizeMacosPinnedProgramLaunchers(
      hostPlatform: context.programRunPlanner.hostPlatform,
      environment: context.programRunPlanner.environment,
      bottles: bottles,
    );
    return _jsonSuccess(<String, Object?>{
      'bottles': bottles
          .map((bottle) => bottle.toJson())
          .toList(growable: false),
    });
  }

  final inspectedBottleId = _parseJsonBottleInspectCommand(arguments);
  if (inspectedBottleId != null) {
    final bottleId = inspectedBottleId;
    final bottleResult = activeBottleCatalog.findBottle(bottleId);
    final failure = bottleResult.fold<CliResult?>(
      _bottleCatalogFailureJsonResult,
      (_) => null,
    );
    if (failure != null) {
      return failure;
    }
    final bottle = bottleResult.getOrElse((_) => null);
    if (bottle == null) {
      return _bottleNotFoundError(bottleId);
    }

    final inspectedBottle = _bottleWithRegistrySettings(
      bottle: bottle,
      programRunPlanner: context.programRunPlanner,
      programRunner: context.programRunner,
    );
    return _bottleJsonResult(inspectedBottle);
  }

  final bottleProgramsListId = _parseJsonBottleProgramsListCommand(arguments);
  if (bottleProgramsListId != null) {
    final bottleResult = activeBottleCatalog.findBottle(bottleProgramsListId);
    final failure = bottleResult.fold<CliResult?>(
      _bottleCatalogFailureJsonResult,
      (_) => null,
    );
    if (failure != null) {
      return failure;
    }
    final bottle = bottleResult.getOrElse((_) => null);
    if (bottle == null) {
      return _bottleNotFoundError(bottleProgramsListId);
    }

    return _jsonSuccess(<String, Object?>{
      'bottlePrograms': <String, Object?>{
        'bottleId': bottle.id,
        'programs': context.bottleProgramRepository
            .listPrograms(bottle)
            .map((program) => program.toJson())
            .toList(growable: false),
      },
    });
  }

  return null;
}
