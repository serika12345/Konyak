part of 'konyak_cli_client.dart';

extension KonyakCliRuntimeCommands on KonyakCliClient {
  Future<RuntimeInstallLoadResult> installMacosWine({
    void Function(RuntimeInstallProgress progress)? onProgress,
  }) {
    return _runtimeInstallResultFromCommand(
      command: 'install-macos-wine',
      onProgress: onProgress,
    );
  }

  Future<RuntimeInstallLoadResult> installLinuxWine({
    void Function(RuntimeInstallProgress progress)? onProgress,
  }) {
    return _runtimeInstallResultFromCommand(
      command: 'install-linux-wine',
      onProgress: onProgress,
    );
  }

  Future<ProcessRunResult> installGptkWine({required String sourcePath}) {
    return _run(['install-gptk-wine', '--from', sourcePath, '--json']);
  }

  Future<ProcessRunResult> openUrl(String url) {
    return _run(['open-url', url, '--json']);
  }

  Future<UpdateCheckLoadResult> checkKonyakUpdate() async {
    final result = await _run(const ['check-app-update', '--json']);
    return _updateCheckResultFromCommand(
      result: result,
      command: 'check-app-update',
      payloadKey: 'appUpdate',
      idKey: 'appId',
    );
  }

  Future<UpdateCheckLoadResult> checkRuntimeUpdate(String runtimeId) async {
    final result = await _run(['check-runtime-update', runtimeId, '--json']);
    return _updateCheckResultFromCommand(
      result: result,
      command: 'check-runtime-update',
      payloadKey: 'runtimeUpdate',
      idKey: 'runtimeId',
    );
  }

  Future<WineProcessTerminationLoadResult> terminateWineProcesses({
    String? bottleId,
  }) async {
    final result = await _run([
      'terminate-wine-processes',
      if (bottleId != null) ...['--bottle', bottleId],
      '--json',
    ]);
    return _wineProcessTerminationResultFromCommand(result);
  }

  Future<WineProcessTerminationLoadResult> terminateWineProcess({
    required String bottleId,
    required String processId,
  }) async {
    final result = await _run([
      'terminate-wine-process',
      '--bottle',
      bottleId,
      '--process',
      processId,
      '--json',
    ]);
    return _wineProcessTerminationResultFromCommand(
      result,
      command: 'terminate-wine-process',
    );
  }

  Future<UpdateInstallLoadResult> installKonyakUpdate() async {
    final result = await _run(const ['install-app-update', '--json']);
    return _updateInstallResultFromCommand(result);
  }

  Future<RuntimeInstallLoadResult> installRuntimeUpdate(
    String runtimeId,
  ) async {
    final result = await _run(['install-runtime-update', runtimeId, '--json']);
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
        message: _installRuntimeFailureMessage(result),
        diagnostic: result.stderr,
      ),
    };
  }
}
