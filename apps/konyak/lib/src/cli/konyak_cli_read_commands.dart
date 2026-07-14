import 'dart:async';

import 'bottle_detail_contract.dart';
import 'bottle_list_contract.dart';
import 'konyak_cli_bottle_result_types.dart';
import 'konyak_cli_client.dart' show KonyakCliClient;
import 'konyak_cli_failure_messages.dart';
import 'konyak_cli_process_runner.dart';
import 'konyak_cli_program_payload_parsers.dart';
import 'konyak_cli_program_result_types.dart';
import 'konyak_cli_runtime_result_types.dart';
import 'konyak_cli_wine_process_payload_parsers.dart';
import 'konyak_cli_wine_process_result_types.dart';
import 'konyak_cli_winetricks_payload_parsers.dart';
import 'konyak_cli_winetricks_result_types.dart';
import 'runtime_list_contract.dart';

extension KonyakCliReadCommands on KonyakCliClient {
  Future<BottleListLoadResult> listBottles() async {
    final result = await run(const ['list-bottles', '--json']);

    if (result.exitCode != 0) {
      return BottleListLoadFailure(
        exitCode: result.exitCode,
        message: commandFailureMessage('list-bottles', result),
        diagnostic: result.stderr,
      );
    }

    final parsed = parseBottleListPayload(result.stdout);

    return switch (parsed) {
      ParsedBottleList(:final bottles, :final invalidBottles) =>
        LoadedBottleList(bottles: bottles, invalidBottles: invalidBottles),
      BottleListParseFailure(:final message) => BottleListLoadFailure(
        exitCode: result.exitCode,
        message: message,
        diagnostic: result.stderr,
      ),
    };
  }

  Future<BottleDetailLoadResult> inspectBottle(String bottleId) async {
    final result = await run(['inspect-bottle', bottleId, '--json']);

    final parsed = parseBottleDetailPayload(result.stdout);

    return switch (parsed) {
      ParsedBottleDetail(:final bottle) when result.exitCode == 0 =>
        LoadedBottleDetail(bottle),
      BottleDetailNotFound(:final bottleId, :final message)
          when result.exitCode == 66 =>
        MissingBottleDetail(bottleId: bottleId, message: message),
      ParsedBottleDetail() ||
      BottleDetailNotFound() ||
      BottleDetailParseFailure() => BottleDetailLoadFailure(
        exitCode: result.exitCode,
        message: detailFailureMessage(result),
        diagnostic: result.stderr,
      ),
    };
  }

  Future<RuntimeListLoadResult> listKnownRuntimes() async {
    final result = await run(const ['list-runtimes', '--json']);

    if (result.exitCode != 0) {
      return RuntimeListLoadFailure(
        exitCode: result.exitCode,
        message: 'list-runtimes failed with exit code ${result.exitCode}.',
        diagnostic: result.stderr,
      );
    }

    final parsed = parseRuntimeListPayload(result.stdout);

    return switch (parsed) {
      ParsedRuntimeList(:final runtimes) => LoadedRuntimeList(runtimes),
      RuntimeListParseFailure(:final message) => RuntimeListLoadFailure(
        exitCode: result.exitCode,
        message: message,
        diagnostic: result.stderr,
      ),
    };
  }

  Future<ProcessRunResult> installLinuxFileAssociations() {
    return run(const ['install-linux-file-associations', '--json']);
  }

  Future<BottleProgramListLoadResult> listBottlePrograms(
    String bottleId,
  ) async {
    final result = await run(['list-bottle-programs', bottleId, '--json']);
    final parsed = parseBottleProgramListPayload(result.stdout);

    return switch (parsed) {
      LoadedBottlePrograms() when result.exitCode == 0 => parsed,
      BottleProgramListLoadFailure(:final message) =>
        BottleProgramListLoadFailure(
          exitCode: result.exitCode,
          message: message,
          diagnostic: result.stderr,
        ),
      LoadedBottlePrograms() => BottleProgramListLoadFailure(
        exitCode: result.exitCode,
        message: commandFailureMessage('list-bottle-programs', result),
        diagnostic: result.stderr,
      ),
    };
  }

  Future<WineProcessListLoadResult> listWineProcesses() async {
    final result = await run(const ['list-wine-processes', '--json']);
    final parsed = parseWineProcessListPayload(result.stdout);

    return switch (parsed) {
      LoadedWineProcesses() when result.exitCode == 0 => parsed,
      WineProcessListLoadFailure(:final message) => WineProcessListLoadFailure(
        exitCode: result.exitCode,
        message: message,
        diagnostic: result.stderr,
      ),
      LoadedWineProcesses() => WineProcessListLoadFailure(
        exitCode: result.exitCode,
        message: commandFailureMessage('list-wine-processes', result),
        diagnostic: result.stderr,
      ),
    };
  }

  Future<WinetricksVerbListLoadResult> listWinetricksVerbs() async {
    final result = await run(const ['list-winetricks-verbs', '--json']);
    final parsed = parseWinetricksVerbListPayload(result.stdout);

    return switch (parsed) {
      LoadedWinetricksVerbs() when result.exitCode == 0 => parsed,
      WinetricksVerbListLoadFailure(:final message) =>
        WinetricksVerbListLoadFailure(
          exitCode: result.exitCode,
          message: message,
          diagnostic: result.stderr,
        ),
      LoadedWinetricksVerbs() => WinetricksVerbListLoadFailure(
        exitCode: result.exitCode,
        message: commandFailureMessage('list-winetricks-verbs', result),
        diagnostic: result.stderr,
      ),
    };
  }
}
