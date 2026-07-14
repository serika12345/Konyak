import '../domain/bottle/bottle_metadata_recovery_models.dart';
import '../io/bottle_metadata_json.dart';
import '../io/linux_pinned_launchers.dart';
import '../repository/repository_interfaces.dart';
import 'cli_bottle_parsers.dart';
import 'cli_bottle_results.dart';
import 'cli_commands.dart';
import 'cli_json_helpers.dart';
import 'cli_program_catalog_json.dart';
import 'cli_result_model.dart';

CliResult? handleBottleReadCommand(
  List<String> arguments, {
  required CliCommandContext context,
  required BottleCatalog activeBottleCatalog,
}) {
  if (isJsonBottleListCommand(arguments)) {
    final snapshotResult = switch (activeBottleCatalog) {
      final RecoverableBottleCatalog recoverable =>
        recoverable.listBottleCatalog(),
      _ => activeBottleCatalog.listBottles().map(
        (bottles) => BottleCatalogSnapshot(bottles: bottles),
      ),
    };
    return snapshotResult.match<CliResult>(bottleCatalogFailureJsonResult, (
      snapshot,
    ) {
      synchronizePinnedProgramLaunchers(
        hostPlatform: context.programRunPlanner.hostPlatform,
        environment: context.programRunPlanner.environment.toMap(),
        bottles: snapshot.bottles.toList(),
      );
      return jsonSuccess(<String, Object?>{
        'bottles': snapshot.bottles
            .map(bottleRecordJson)
            .toList(growable: false),
        'invalidBottles': snapshot.invalidBottles
            .map(invalidBottleSummaryJson)
            .toList(growable: false),
      });
    });
  }

  final inspectedBottleId = parseJsonBottleInspectCommand(arguments);
  if (inspectedBottleId != null) {
    final bottleId = inspectedBottleId;
    return foundBottleJsonResult(
      result: activeBottleCatalog.findBottle(bottleId),
      bottleId: bottleId,
      onFound: (bottle) {
        final inspectedBottle = bottleWithRegistrySettings(
          bottle: bottle,
          programRunPlanner: context.programRunPlanner,
          programRunner: context.programRunner,
        );
        return bottleJsonResult(inspectedBottle);
      },
    );
  }

  final bottleProgramsListId = parseJsonBottleProgramsListCommand(arguments);
  if (bottleProgramsListId != null) {
    return foundBottleJsonResult(
      result: activeBottleCatalog.findBottle(bottleProgramsListId),
      bottleId: bottleProgramsListId,
      onFound: (bottle) => jsonSuccess(<String, Object?>{
        'bottlePrograms': <String, Object?>{
          'bottleId': bottle.id.value,
          'programs': context.bottleProgramRepository
              .listPrograms(bottle)
              .map(bottleProgramRecordJson)
              .toList(growable: false),
        },
      }),
    );
  }

  return null;
}
