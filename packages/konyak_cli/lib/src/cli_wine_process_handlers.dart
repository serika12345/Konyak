part of '../konyak_cli.dart';

CliResult? _handleWineProcessCommand(
  List<String> arguments, {
  required _CliCommandContext context,
  required BottleCatalog activeBottleCatalog,
}) {
  if (_isJsonWineProcessListCommand(arguments)) {
    return _listWineProcessesJsonResult(
      bottleCatalog: activeBottleCatalog,
      programRunPlanner: context.programRunPlanner,
      programRunner: context.programRunner,
      programMetadataExtractor: context.programMetadataExtractor,
    );
  }

  final wineProcessTerminationRequest = _parseJsonWineProcessTerminationRequest(
    arguments,
  );
  if (wineProcessTerminationRequest != null) {
    return _terminateWineProcessJsonResult(
      bottleCatalog: activeBottleCatalog,
      programRunPlanner: context.programRunPlanner,
      programRunner: context.programRunner,
      bottleId: wineProcessTerminationRequest.bottleId,
      processId: wineProcessTerminationRequest.processId,
    );
  }

  final wineProcessGroupTerminationRequest =
      _parseJsonWineProcessGroupTerminationRequest(arguments);
  if (wineProcessGroupTerminationRequest != null) {
    return _terminateWineProcessesJsonResult(
      bottleCatalog: activeBottleCatalog,
      programRunPlanner: context.programRunPlanner,
      programRunner: context.programRunner,
      bottleId: wineProcessGroupTerminationRequest.bottleId,
    );
  }

  return null;
}
