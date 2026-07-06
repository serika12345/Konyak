import 'dart:async';

import '../runtimes/gptk_import_version.dart';
import 'konyak_cli_client.dart'
    show
        IgnoreRuntimeInstallProgress,
        KonyakCliClient,
        RuntimeInstallProgressObservation;
import 'konyak_cli_failure_messages.dart';
import 'konyak_cli_process_runner.dart';
import 'konyak_cli_result_helpers.dart';
import 'konyak_cli_runtime_result_types.dart';
import 'konyak_cli_update_result_types.dart';
import 'konyak_cli_wine_process_result_types.dart';
import 'runtime_install_contract.dart';

sealed class WineProcessTerminationScope {
  const WineProcessTerminationScope();
}

final class AllWineProcesses extends WineProcessTerminationScope {
  const AllWineProcesses();
}

final class BottleWineProcesses extends WineProcessTerminationScope {
  const BottleWineProcesses(this.bottleId);

  final String bottleId;
}

extension KonyakCliRuntimeCommands on KonyakCliClient {
  Future<RuntimeInstallLoadResult> installMacosWine({
    bool reinstall = false,
    RuntimeInstallProgressObservation progressObservation =
        const IgnoreRuntimeInstallProgress(),
  }) {
    return runtimeInstallResultFromCommand(
      command: 'install-macos-wine',
      arguments: reinstall ? const <String>['--reinstall'] : const <String>[],
      progressObservation: progressObservation,
    );
  }

  Future<RuntimeInstallLoadResult> installLinuxWine({
    bool reinstall = false,
    RuntimeInstallProgressObservation progressObservation =
        const IgnoreRuntimeInstallProgress(),
  }) {
    return runtimeInstallResultFromCommand(
      command: 'install-linux-wine',
      arguments: reinstall ? const <String>['--reinstall'] : const <String>[],
      progressObservation: progressObservation,
    );
  }

  Future<ProcessRunResult> installGptkWine({
    required String sourcePath,
    GptkImportVersion version = GptkImportVersion.auto,
  }) {
    return run([
      'install-gptk-wine',
      '--from',
      sourcePath,
      ...version.cliArguments,
      '--json',
    ]);
  }

  Future<ProcessRunResult> openUrl(String url) {
    return run(['open-url', url, '--json']);
  }

  Future<UpdateCheckLoadResult> checkKonyakUpdate() async {
    final result = await run(const ['check-app-update', '--json']);
    return updateCheckResultFromCommand(
      result: result,
      command: 'check-app-update',
      payloadKey: 'appUpdate',
      idKey: 'appId',
    );
  }

  Future<UpdateCheckLoadResult> checkRuntimeUpdate(String runtimeId) async {
    final result = await run(['check-runtime-update', runtimeId, '--json']);
    return updateCheckResultFromCommand(
      result: result,
      command: 'check-runtime-update',
      payloadKey: 'runtimeUpdate',
      idKey: 'runtimeId',
    );
  }

  Future<WineProcessTerminationLoadResult> terminateWineProcesses({
    WineProcessTerminationScope scope = const AllWineProcesses(),
  }) async {
    final result = await run([
      'terminate-wine-processes',
      ...switch (scope) {
        AllWineProcesses() => const <String>[],
        BottleWineProcesses(:final bottleId) => ['--bottle', bottleId],
      },
      '--json',
    ]);
    return wineProcessTerminationResultFromCommand(result);
  }

  Future<WineProcessTerminationLoadResult> terminateWineProcess({
    required String bottleId,
    required String processId,
  }) async {
    final result = await run([
      'terminate-wine-process',
      '--bottle',
      bottleId,
      '--process',
      processId,
      '--json',
    ]);
    return wineProcessTerminationResultFromCommand(
      result,
      command: 'terminate-wine-process',
    );
  }

  Future<UpdateInstallLoadResult> installKonyakUpdate() async {
    final result = await run(const ['install-app-update', '--json']);
    return updateInstallResultFromCommand(result);
  }

  Future<RuntimeInstallLoadResult> installRuntimeUpdate(
    String runtimeId,
  ) async {
    final result = await run(['install-runtime-update', runtimeId, '--json']);
    final parsed = parseRuntimeInstallPayload(result.stdout);

    return switch (parsed) {
      ParsedRuntimeInstall(:final runtime) when result.exitCode == 0 =>
        InstalledRuntime(runtime),
      RuntimeInstallCommandFailure(:final message) => RuntimeInstallLoadFailure(
        exitCode: result.exitCode,
        message: message,
        diagnostic: result.stderr,
      ),
      ParsedRuntimeInstall() ||
      RuntimeInstallParseFailure() => RuntimeInstallLoadFailure(
        exitCode: result.exitCode,
        message: installRuntimeFailureMessage(result),
        diagnostic: result.stderr,
      ),
    };
  }
}
