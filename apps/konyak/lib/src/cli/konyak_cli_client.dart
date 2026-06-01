import 'dart:convert';
import 'dart:io';

import '../bottles/bottle_summary.dart';
import '../runs/program_run_summary.dart';
import '../runtimes/runtime_summary.dart';
import '../settings/app_settings_summary.dart';
import '../updates/update_check_summary.dart';
import 'bottle_create_contract.dart';
import 'bottle_detail_contract.dart';
import 'bottle_list_contract.dart';
import 'bottle_record_contract.dart';
import 'program_run_contract.dart';
import 'runtime_install_contract.dart';
import 'runtime_list_contract.dart';

part 'konyak_cli_process_runner.dart';
part 'konyak_cli_client_factory.dart';
part 'konyak_cli_payload_parsers.dart';
part 'konyak_cli_result_types.dart';
part 'konyak_cli_result_helpers.dart';

final class KonyakCliClient {
  const KonyakCliClient({
    required this.executable,
    this.baseArguments = const <String>[],
    this.environment = const <String, String>{},
    this.workingDirectory,
    required this.processRunner,
  });

  final String executable;
  final List<String> baseArguments;
  final Map<String, String> environment;
  final String? workingDirectory;
  final ProcessRunner processRunner;

  Future<BottleListLoadResult> listBottles() async {
    final result = await _run(const ['list-bottles', '--json']);

    if (result.exitCode != 0) {
      return BottleListLoadFailure(
        exitCode: result.exitCode,
        message: _commandFailureMessage('list-bottles', result),
        diagnostic: result.stderr,
      );
    }

    final parsed = parseBottleListPayload(result.stdout);

    return switch (parsed) {
      ParsedBottleList(:final bottles) => LoadedBottleList(bottles),
      BottleListParseFailure(:final message) => BottleListLoadFailure(
        exitCode: result.exitCode,
        message: message,
        diagnostic: result.stderr,
      ),
    };
  }

  Future<BottleDetailLoadResult> inspectBottle(String bottleId) async {
    final result = await _run(['inspect-bottle', bottleId, '--json']);

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
        message: _detailFailureMessage(result),
        diagnostic: result.stderr,
      ),
    };
  }

  Future<RuntimeListLoadResult> listKnownRuntimes() async {
    final result = await _run(const ['list-runtimes', '--json']);

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
    return _run(const ['install-linux-file-associations', '--json']);
  }

  Future<BottleProgramListLoadResult> listBottlePrograms(
    String bottleId,
  ) async {
    final result = await _run(['list-bottle-programs', bottleId, '--json']);
    final parsed = _parseBottleProgramListPayload(result.stdout);

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
        message: _commandFailureMessage('list-bottle-programs', result),
        diagnostic: result.stderr,
      ),
    };
  }

  Future<WineProcessListLoadResult> listWineProcesses() async {
    final result = await _run(const ['list-wine-processes', '--json']);
    final parsed = _parseWineProcessListPayload(result.stdout);

    return switch (parsed) {
      LoadedWineProcesses() when result.exitCode == 0 => parsed,
      WineProcessListLoadFailure(:final message) => WineProcessListLoadFailure(
        exitCode: result.exitCode,
        message: message,
        diagnostic: result.stderr,
      ),
      LoadedWineProcesses() => WineProcessListLoadFailure(
        exitCode: result.exitCode,
        message: _commandFailureMessage('list-wine-processes', result),
        diagnostic: result.stderr,
      ),
    };
  }

  Future<WinetricksVerbListLoadResult> listWinetricksVerbs() async {
    final result = await _run(const ['list-winetricks-verbs', '--json']);
    final parsed = _parseWinetricksVerbListPayload(result.stdout);

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
        message: _commandFailureMessage('list-winetricks-verbs', result),
        diagnostic: result.stderr,
      ),
    };
  }

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

  Future<AppSettingsLoadResult> getAppSettings() async {
    final result = await _run(const ['get-app-settings', '--json']);
    return _appSettingsResultFromCommand(
      result: result,
      command: 'get-app-settings',
    );
  }

  Future<AppSettingsLoadResult> setAppSettings({
    required AppSettingsSummary settings,
  }) async {
    final result = await _run([
      'set-app-settings',
      '--settings-json',
      jsonEncode(settings.toJson()),
      '--json',
    ]);
    return _appSettingsResultFromCommand(
      result: result,
      command: 'set-app-settings',
    );
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

  Future<BottleCreateLoadResult> createBottle({
    required String name,
    required String windowsVersion,
  }) async {
    final result = await _run([
      'create-bottle',
      '--name',
      name,
      '--windows-version',
      windowsVersion,
      '--json',
    ]);

    final parsed = parseBottleCreatePayload(result.stdout);

    return switch (parsed) {
      ParsedBottleCreate(:final bottle) when result.exitCode == 0 =>
        CreatedBottle(bottle),
      BottleCreateConflict(:final bottleId, :final message)
          when result.exitCode == 73 =>
        ExistingBottle(bottleId: bottleId, message: message),
      ParsedBottleCreate() ||
      BottleCreateConflict() ||
      BottleCreateParseFailure() => BottleCreateLoadFailure(
        exitCode: result.exitCode,
        message: _createFailureMessage(result),
        diagnostic: result.stderr,
      ),
    };
  }

  Future<BottleArchiveExportLoadResult> exportBottleArchive({
    required String bottleId,
    required String archivePath,
  }) async {
    final result = await _run([
      'export-bottle-archive',
      bottleId,
      '--archive',
      archivePath,
      '--json',
    ]);

    final parsed = _parseBottleArchiveExportPayload(result.stdout);
    return switch (parsed) {
      ExportedBottleArchive() when result.exitCode == 0 => parsed,
      ExportedBottleArchive() ||
      BottleArchiveExportLoadFailure() => BottleArchiveExportLoadFailure(
        exitCode: result.exitCode,
        message: _operationFailureMessage(result, 'export-bottle-archive'),
        diagnostic: result.stderr,
      ),
    };
  }

  Future<BottleArchiveImportLoadResult> importBottleArchive({
    required String archivePath,
  }) async {
    final result = await _run([
      'import-bottle-archive',
      '--archive',
      archivePath,
      '--json',
    ]);

    final parsed = parseBottleDetailPayload(result.stdout);
    return switch (parsed) {
      ParsedBottleDetail(:final bottle) when result.exitCode == 0 =>
        ImportedBottleArchive(bottle),
      ParsedBottleDetail() ||
      BottleDetailNotFound() ||
      BottleDetailParseFailure() => BottleArchiveImportLoadFailure(
        exitCode: result.exitCode,
        message: _operationFailureMessage(result, 'import-bottle-archive'),
        diagnostic: result.stderr,
      ),
    };
  }

  Future<BottleUpdateLoadResult> setWindowsVersion({
    required String bottleId,
    required String windowsVersion,
  }) async {
    final result = await _run([
      'set-windows-version',
      bottleId,
      '--windows-version',
      windowsVersion,
      '--json',
    ]);

    final parsed = parseBottleDetailPayload(result.stdout);

    return switch (parsed) {
      ParsedBottleDetail(:final bottle) when result.exitCode == 0 =>
        UpdatedBottle(bottle),
      BottleDetailNotFound(:final bottleId, :final message)
          when result.exitCode == 66 =>
        MissingBottleUpdate(bottleId: bottleId, message: message),
      ParsedBottleDetail() ||
      BottleDetailNotFound() ||
      BottleDetailParseFailure() => BottleUpdateLoadFailure(
        exitCode: result.exitCode,
        message: _updateFailureMessage(result),
        diagnostic: result.stderr,
      ),
    };
  }

  Future<BottleUpdateLoadResult> setRuntimeSettings({
    required String bottleId,
    required BottleRuntimeSettingsSummary runtimeSettings,
  }) async {
    final result = await _run([
      'set-runtime-settings',
      bottleId,
      '--settings-json',
      jsonEncode(runtimeSettings.toJson()),
      '--json',
    ]);

    return _bottleUpdateResultFromCommand(
      result: result,
      command: 'set-runtime-settings',
    );
  }

  Future<BottleDeleteLoadResult> deleteBottle(String bottleId) async {
    final result = await _run(['delete-bottle', bottleId, '--json']);
    final parsed = _parseBottleDeletePayload(result.stdout);

    return switch (parsed) {
      _ParsedBottleDelete(:final bottle) when result.exitCode == 0 =>
        DeletedBottle(bottle),
      _BottleDeleteNotFound(:final bottleId, :final message)
          when result.exitCode == 66 =>
        MissingBottleDelete(bottleId: bottleId, message: message),
      _ParsedBottleDelete() ||
      _BottleDeleteNotFound() ||
      _BottleDeleteParseFailure() => BottleDeleteLoadFailure(
        exitCode: result.exitCode,
        message: _deleteFailureMessage(result),
        diagnostic: result.stderr,
      ),
    };
  }

  Future<BottleUpdateLoadResult> renameBottle({
    required String bottleId,
    required String name,
  }) async {
    final result = await _run([
      'rename-bottle',
      bottleId,
      '--name',
      name,
      '--json',
    ]);

    return _bottleUpdateResultFromCommand(
      result: result,
      command: 'rename-bottle',
    );
  }

  Future<BottleUpdateLoadResult> moveBottle({
    required String bottleId,
    required String path,
  }) async {
    final result = await _run([
      'move-bottle',
      bottleId,
      '--path',
      path,
      '--json',
    ]);

    return _bottleUpdateResultFromCommand(
      result: result,
      command: 'move-bottle',
    );
  }

  Future<ProgramRunLoadResult> runProgram({
    required String bottleId,
    required String programPath,
  }) {
    return _programRunResultFromCommand(
      arguments: ['run-program', bottleId, '--program', programPath, '--json'],
      failureMessage: _programRunFailureMessage,
    );
  }

  Future<BottleUpdateLoadResult> pinProgram({
    required String bottleId,
    required String name,
    required String programPath,
  }) async {
    final result = await _run([
      'pin-program',
      bottleId,
      '--name',
      name,
      '--program',
      programPath,
      '--json',
    ]);

    return _bottleUpdateResultFromCommand(
      result: result,
      command: 'pin-program',
    );
  }

  Future<BottleUpdateLoadResult> unpinProgram({
    required String bottleId,
    required String programPath,
  }) async {
    final result = await _run([
      'unpin-program',
      bottleId,
      '--program',
      programPath,
      '--json',
    ]);

    return _bottleUpdateResultFromCommand(
      result: result,
      command: 'unpin-program',
    );
  }

  Future<BottleUpdateLoadResult> renamePinnedProgram({
    required String bottleId,
    required String programPath,
    required String name,
  }) async {
    final result = await _run([
      'rename-pinned-program',
      bottleId,
      '--program',
      programPath,
      '--name',
      name,
      '--json',
    ]);

    return _bottleUpdateResultFromCommand(
      result: result,
      command: 'rename-pinned-program',
    );
  }

  Future<ProgramSettingsLoadResult> getProgramSettings({
    required String bottleId,
    required String programPath,
  }) async {
    final result = await _run([
      'get-program-settings',
      bottleId,
      '--program',
      programPath,
      '--json',
    ]);

    return _programSettingsResultFromCommand(
      result: result,
      command: 'get-program-settings',
    );
  }

  Future<ProgramSettingsLoadResult> setProgramSettings({
    required String bottleId,
    required String programPath,
    required ProgramSettingsSummary settings,
  }) async {
    final result = await _run([
      'set-program-settings',
      bottleId,
      '--program',
      programPath,
      '--settings-json',
      jsonEncode(settings.toJson()),
      '--json',
    ]);

    return _programSettingsResultFromCommand(
      result: result,
      command: 'set-program-settings',
    );
  }

  Future<ProgramRunLoadResult> runBottleCommand({
    required String bottleId,
    required String command,
  }) {
    return _programRunResultFromCommand(
      arguments: [
        'run-bottle-command',
        bottleId,
        '--command',
        command,
        '--json',
      ],
      failureMessage: (result) =>
          _commandFailureMessage('run-bottle-command', result),
    );
  }

  Future<ProgramRunLoadResult> runWinetricksVerb({
    required String bottleId,
    required String verb,
  }) {
    return _programRunResultFromCommand(
      arguments: ['run-winetricks', bottleId, '--verb', verb, '--json'],
      failureMessage: (result) =>
          _operationFailureMessage(result, 'run-winetricks'),
    );
  }

  Future<BottleLocationOpenResult> openBottleLocation({
    required String bottleId,
    required String location,
  }) async {
    final result = await _run([
      'open-bottle-location',
      bottleId,
      '--location',
      location,
      '--json',
    ]);

    final parsed = _parseBottleLocationOpenPayload(result.stdout);

    return switch (parsed) {
      OpenedBottleLocation() when result.exitCode == 0 => parsed,
      BottleLocationOpenFailure(:final message) => BottleLocationOpenFailure(
        exitCode: result.exitCode,
        message: message,
        diagnostic: result.stderr,
      ),
      OpenedBottleLocation() => BottleLocationOpenFailure(
        exitCode: result.exitCode,
        message: _commandFailureMessage('open-bottle-location', result),
        diagnostic: result.stderr,
      ),
    };
  }

  Future<ProgramLocationOpenResult> openProgramLocation({
    required String bottleId,
    required String programPath,
  }) async {
    final result = await _run([
      'open-program-location',
      bottleId,
      '--program',
      programPath,
      '--json',
    ]);

    final parsed = _parseProgramLocationOpenPayload(result.stdout);

    return switch (parsed) {
      OpenedProgramLocation() when result.exitCode == 0 => parsed,
      ProgramLocationOpenFailure(:final message) => ProgramLocationOpenFailure(
        exitCode: result.exitCode,
        message: message,
        diagnostic: result.stderr,
      ),
      OpenedProgramLocation() => ProgramLocationOpenFailure(
        exitCode: result.exitCode,
        message: _commandFailureMessage('open-program-location', result),
        diagnostic: result.stderr,
      ),
    };
  }

  Future<RuntimeInstallLoadResult> _runtimeInstallResultFromCommand({
    required String command,
    required void Function(RuntimeInstallProgress progress)? onProgress,
  }) async {
    final result = await _runRuntimeInstall(
      command: command,
      onProgress: onProgress,
    );
    final parsed = _parseRuntimeInstallCommandPayload(result.stdout);

    return switch (parsed) {
      ParsedRuntimeInstall(:final runtime) when result.exitCode == 0 =>
        InstalledRuntime(runtime),
      RuntimeInstallCommandFailure(:final message) when result.exitCode == 75 =>
        RuntimeInstallLoadFailure(
          exitCode: result.exitCode,
          message: message,
          diagnostic: result.stderr,
        ),
      ParsedRuntimeInstall() ||
      RuntimeInstallCommandFailure() ||
      RuntimeInstallParseFailure() => RuntimeInstallLoadFailure(
        exitCode: result.exitCode,
        message: _installRuntimeFailureMessage(result),
        diagnostic: result.stderr,
      ),
    };
  }

  Future<ProgramRunLoadResult> _programRunResultFromCommand({
    required List<String> arguments,
    required String Function(ProcessRunResult result) failureMessage,
  }) async {
    final result = await _run(arguments);
    final parsed = parseProgramRunPayload(result.stdout);

    return switch (parsed) {
      ParsedProgramRun(:final run) when result.exitCode == 0 =>
        CompletedProgramRun(run),
      ProgramRunUnsupportedProgramType(:final programPath, :final message)
          when result.exitCode == 65 =>
        UnsupportedProgramRun(programPath: programPath, message: message),
      ProgramRunBottleNotFound(:final bottleId, :final message)
          when result.exitCode == 66 =>
        MissingProgramRunBottle(bottleId: bottleId, message: message),
      ProgramRunExecutionFailure(
        :final bottleId,
        :final programPath,
        :final message,
        :final runnerKind,
        :final executable,
        :final workingDirectory,
        :final argv,
        :final logPath,
      )
          when result.exitCode == 75 =>
        FailedProgramRun(
          bottleId: bottleId,
          programPath: programPath,
          message: message,
          runnerKind: runnerKind,
          executable: executable,
          workingDirectory: workingDirectory,
          argv: argv,
          logPath: logPath,
        ),
      ParsedProgramRun() ||
      ProgramRunUnsupportedProgramType() ||
      ProgramRunBottleNotFound() ||
      ProgramRunExecutionFailure() ||
      ProgramRunParseFailure() => ProgramRunLoadFailure(
        exitCode: result.exitCode,
        message: failureMessage(result),
        diagnostic: result.stderr,
      ),
    };
  }

  Future<ProcessRunResult> _run(List<String> arguments) {
    return processRunner.run(
      executable,
      <String>[...baseArguments, ...arguments],
      workingDirectory: workingDirectory,
      environment: <String, String>{...environment, ..._launcherEnvironment()},
    );
  }

  Future<ProcessRunResult> _runRuntimeInstall({
    required String command,
    required void Function(RuntimeInstallProgress progress)? onProgress,
  }) {
    if (onProgress == null) {
      return _run(<String>[command, '--json']);
    }

    return processRunner.run(
      executable,
      <String>[...baseArguments, command, '--progress-json', '--json'],
      workingDirectory: workingDirectory,
      environment: <String, String>{...environment, ..._launcherEnvironment()},
      onStdoutLine: (line) {
        final progress = parseRuntimeInstallProgressPayload(line);
        if (progress != null) {
          onProgress(progress);
        }
      },
    );
  }

  Map<String, String> _launcherEnvironment() {
    final environment = <String, String>{
      'KONYAK_PINNED_PROGRAM_LAUNCHER_EXECUTABLE': executable,
      'KONYAK_PINNED_PROGRAM_LAUNCHER_ARGUMENTS_JSON': jsonEncode(
        baseArguments,
      ),
    };
    final launcherWorkingDirectory = workingDirectory;
    if (launcherWorkingDirectory != null) {
      environment['KONYAK_PINNED_PROGRAM_LAUNCHER_WORKING_DIRECTORY'] =
          launcherWorkingDirectory;
    }
    return environment;
  }
}
