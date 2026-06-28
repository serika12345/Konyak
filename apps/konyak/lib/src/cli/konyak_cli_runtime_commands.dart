import 'dart:async';

import 'konyak_cli_client.dart' show KonyakCliClient;
import 'konyak_cli_failure_messages.dart';
import 'konyak_cli_process_runner.dart';
import 'konyak_cli_result_helpers.dart';
import 'konyak_cli_runtime_result_types.dart';
import 'konyak_cli_update_result_types.dart';
import 'konyak_cli_wine_process_result_types.dart';
import 'runtime_install_contract.dart';

extension KonyakCliRuntimeCommands on KonyakCliClient {
  Future<RuntimeInstallLoadResult> installMacosWine({
    bool reinstall = false,
    void Function(RuntimeInstallProgress progress)? onProgress,
  }) {
    return runtimeInstallResultFromCommand(
      command: 'install-macos-wine',
      arguments: reinstall ? const <String>['--reinstall'] : const <String>[],
      onProgress: onProgress,
    );
  }

  Future<RuntimeInstallLoadResult> installLinuxWine({
    bool reinstall = false,
    void Function(RuntimeInstallProgress progress)? onProgress,
  }) {
    return runtimeInstallResultFromCommand(
      command: 'install-linux-wine',
      arguments: reinstall ? const <String>['--reinstall'] : const <String>[],
      onProgress: onProgress,
    );
  }

  Future<ProcessRunResult> installGptkWine({required String sourcePath}) {
    return run(['install-gptk-wine', '--from', sourcePath, '--json']);
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
    String? bottleId,
  }) async {
    final result = await run([
      'terminate-wine-processes',
      if (bottleId != null) ...['--bottle', bottleId],
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
