import '../repository/repository_interfaces.dart';
import 'cli_app_process_parsers.dart';
import 'cli_app_process_results.dart';
import 'cli_commands.dart';
import 'cli_result_model.dart';

CliResult? handleWineProcessCommand(
  List<String> arguments, {
  required CliCommandContext context,
  required BottleCatalog activeBottleCatalog,
}) {
  if (isJsonWineProcessListCommand(arguments)) {
    return listWineProcessesJsonResult(
      bottleCatalog: activeBottleCatalog,
      programRunPlanner: context.programRunPlanner,
      programRunner: context.programRunner,
      programMetadataExtractor: context.programMetadataExtractor,
    );
  }

  final wineProcessTerminationRequest = parseJsonWineProcessTerminationRequest(
    arguments,
  );
  if (wineProcessTerminationRequest != null) {
    return terminateWineProcessJsonResult(
      bottleCatalog: activeBottleCatalog,
      programRunPlanner: context.programRunPlanner,
      programRunner: context.programRunner,
      bottleId: wineProcessTerminationRequest.bottleId.value,
      processId: wineProcessTerminationRequest.processId.value,
    );
  }

  final wineProcessGroupTerminationRequest =
      parseJsonWineProcessGroupTerminationRequest(arguments);
  if (wineProcessGroupTerminationRequest != null) {
    return terminateWineProcessesJsonResult(
      bottleCatalog: activeBottleCatalog,
      programRunPlanner: context.programRunPlanner,
      programRunner: context.programRunner,
      bottleId: wineProcessGroupTerminationRequest.bottleId.map(
        (value) => value.value,
      ),
    );
  }

  return null;
}
