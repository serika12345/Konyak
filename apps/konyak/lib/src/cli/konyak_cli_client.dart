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

abstract interface class ProcessRunner {
  Future<ProcessRunResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String> environment = const <String, String>{},
    void Function(String line)? onStdoutLine,
  });
}

final class ProcessRunResult {
  const ProcessRunResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;
}

final class DartIoProcessRunner implements ProcessRunner {
  const DartIoProcessRunner();

  @override
  Future<ProcessRunResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String> environment = const <String, String>{},
    void Function(String line)? onStdoutLine,
  }) async {
    final childEnvironment = <String, String>{
      ..._konyakCliChildEnvironment(),
      ...environment,
    };

    if (onStdoutLine != null) {
      return _runStreaming(
        executable,
        arguments,
        workingDirectory: workingDirectory,
        environment: childEnvironment,
        onStdoutLine: onStdoutLine,
      );
    }

    final ProcessResult result;
    try {
      result = await Process.run(
        executable,
        arguments,
        environment: childEnvironment,
        runInShell: false,
        workingDirectory: workingDirectory,
      );
    } on ProcessException catch (error) {
      return ProcessRunResult(
        exitCode: 127,
        stdout: '',
        stderr: 'Failed to start $executable: ${error.message}',
      );
    }

    return ProcessRunResult(
      exitCode: result.exitCode,
      stdout: _processOutputToString(result.stdout),
      stderr: _processOutputToString(result.stderr),
    );
  }

  Future<ProcessRunResult> _runStreaming(
    String executable,
    List<String> arguments, {
    required String? workingDirectory,
    required Map<String, String> environment,
    required void Function(String line) onStdoutLine,
  }) async {
    final Process process;
    try {
      process = await Process.start(
        executable,
        arguments,
        environment: environment,
        runInShell: false,
        workingDirectory: workingDirectory,
      );
    } on ProcessException catch (error) {
      return ProcessRunResult(
        exitCode: 127,
        stdout: '',
        stderr: 'Failed to start $executable: ${error.message}',
      );
    }

    final stdoutLines = <String>[];
    final stderrBuffer = StringBuffer();
    final stdoutFuture = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .forEach((line) {
          stdoutLines.add(line);
          onStdoutLine(line);
        });
    final stderrFuture = process.stderr
        .transform(utf8.decoder)
        .forEach(stderrBuffer.write);

    final exitCode = await process.exitCode;
    await stdoutFuture;
    await stderrFuture;

    return ProcessRunResult(
      exitCode: exitCode,
      stdout: stdoutLines.join('\n'),
      stderr: stderrBuffer.toString(),
    );
  }
}

Map<String, String> _konyakCliChildEnvironment() {
  final environment = <String, String>{};
  final inheritedAppExecutable = Platform.environment['KONYAK_APP_EXECUTABLE'];
  if (inheritedAppExecutable != null &&
      inheritedAppExecutable.trim().isNotEmpty) {
    environment['KONYAK_APP_EXECUTABLE'] = inheritedAppExecutable.trim();
  } else if (Platform.resolvedExecutable.trim().isNotEmpty) {
    environment['KONYAK_APP_EXECUTABLE'] = Platform.resolvedExecutable;
  }

  final inheritedAppPid = Platform.environment['KONYAK_APP_PID'];
  if (inheritedAppPid != null && inheritedAppPid.trim().isNotEmpty) {
    environment['KONYAK_APP_PID'] = inheritedAppPid.trim();
  } else {
    environment['KONYAK_APP_PID'] = '$pid';
  }

  final inheritedAppBundlePath = Platform.environment['KONYAK_APP_BUNDLE_PATH'];
  if (inheritedAppBundlePath != null &&
      inheritedAppBundlePath.trim().isNotEmpty) {
    environment['KONYAK_APP_BUNDLE_PATH'] = inheritedAppBundlePath.trim();
  }

  return environment;
}

KonyakCliClient createDefaultKonyakCliClient({
  Map<String, String> environment = const <String, String>{},
  String dartExecutableDefine = const String.fromEnvironment(
    'KONYAK_DART_EXECUTABLE',
  ),
  String cliScriptDefine = const String.fromEnvironment('KONYAK_CLI_SCRIPT'),
  String cliExecutableDefine = const String.fromEnvironment(
    'KONYAK_CLI_EXECUTABLE',
  ),
  String appExecutableDefine = const String.fromEnvironment(
    'KONYAK_APP_EXECUTABLE',
  ),
  String runtimeProfileDefine = const String.fromEnvironment(
    'KONYAK_RUNTIME_PROFILE',
  ),
  String macosWineHomeDefine = const String.fromEnvironment(
    'KONYAK_MACOS_WINE_HOME',
  ),
  String macosWineStackManifestDefine = const String.fromEnvironment(
    'KONYAK_DEV_MACOS_WINE_STACK_MANIFEST',
  ),
  String macosDevRuntimePrepareScriptDefine = const String.fromEnvironment(
    'KONYAK_MACOS_DEV_RUNTIME_PREPARE_SCRIPT',
  ),
  String bundleResourcesDefine = const String.fromEnvironment(
    'KONYAK_BUNDLE_RESOURCES',
  ),
  String repoRootDefine = const String.fromEnvironment('KONYAK_REPO_ROOT'),
  String flutterRootDefine = const String.fromEnvironment('FLUTTER_ROOT'),
  ProcessRunner processRunner = const DartIoProcessRunner(),
}) {
  final activeEnvironment = environment.isEmpty
      ? Platform.environment
      : environment;
  final runtimeEnvironment = _runtimeEnvironmentOverrides(
    activeEnvironment,
    repoRootDefine: repoRootDefine,
    runtimeProfileDefine: runtimeProfileDefine,
    macosWineHomeDefine: macosWineHomeDefine,
    macosWineStackManifestDefine: macosWineStackManifestDefine,
    macosDevRuntimePrepareScriptDefine: macosDevRuntimePrepareScriptDefine,
  );

  final cliExecutable = _resolvePackagedCliExecutable(
    _firstNonEmpty(
      cliExecutableDefine,
      activeEnvironment['KONYAK_CLI_EXECUTABLE'],
    ),
    activeEnvironment,
    appExecutableDefine: appExecutableDefine,
    bundleResourcesDefine: bundleResourcesDefine,
  );
  if (cliExecutable != null) {
    return KonyakCliClient(
      executable: cliExecutable,
      environment: runtimeEnvironment,
      processRunner: processRunner,
    );
  }

  final cliScriptPath = _resolveCliScriptPath(
    activeEnvironment,
    cliScriptDefine: cliScriptDefine,
    repoRootDefine: repoRootDefine,
  );
  final cliScriptWorkingDirectory = _resolveCliScriptWorkingDirectory(
    cliScriptPath,
  );
  final cliScriptRunTarget = _resolveCliScriptRunTarget(cliScriptPath);

  return KonyakCliClient(
    executable: _resolveDartExecutable(
      activeEnvironment,
      dartExecutableDefine: dartExecutableDefine,
      flutterRootDefine: flutterRootDefine,
    ),
    environment: runtimeEnvironment,
    baseArguments:
        cliScriptWorkingDirectory == null || cliScriptRunTarget == null
        ? <String>[cliScriptPath]
        : <String>['run', cliScriptRunTarget],
    workingDirectory: cliScriptWorkingDirectory,
    processRunner: processRunner,
  );
}

const _bundleResourcesToken = '__KONYAK_BUNDLE_RESOURCES__';

String? _resolvePackagedCliExecutable(
  String? executable,
  Map<String, String> environment, {
  required String appExecutableDefine,
  required String bundleResourcesDefine,
}) {
  if (executable == null || !executable.contains(_bundleResourcesToken)) {
    return executable;
  }

  final bundleResources = _firstNonEmpty(
    bundleResourcesDefine,
    environment['KONYAK_BUNDLE_RESOURCES'],
    _bundleResourcesPathFromAppExecutable(
      _firstNonEmpty(
        appExecutableDefine,
        environment['KONYAK_APP_EXECUTABLE'],
        Platform.resolvedExecutable,
      ),
    ),
  );
  if (bundleResources == null) {
    return executable;
  }

  return executable.replaceAll(_bundleResourcesToken, bundleResources);
}

String? _bundleResourcesPathFromAppExecutable(String? executable) {
  if (executable == null || executable.trim().isEmpty) {
    return null;
  }

  final normalized = executable.replaceAll('\\', '/');
  final marker = '.app/Contents/MacOS/';
  final markerIndex = normalized.indexOf(marker);
  if (markerIndex < 0) {
    return null;
  }

  final bundleRootEnd = markerIndex + '.app/Contents/'.length;
  return '${normalized.substring(0, bundleRootEnd)}Resources';
}

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
  }) async {
    final result = await _runRuntimeInstall(
      command: 'install-macos-wine',
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

  Future<RuntimeInstallLoadResult> installLinuxWine({
    void Function(RuntimeInstallProgress progress)? onProgress,
  }) async {
    final result = await _runRuntimeInstall(
      command: 'install-linux-wine',
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

  Future<WineProcessTerminationLoadResult> terminateWineProcesses() async {
    final result = await _run(const ['terminate-wine-processes', '--json']);
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
  }) async {
    final result = await _run([
      'run-program',
      bottleId,
      '--program',
      programPath,
      '--json',
    ]);

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
        message: _programRunFailureMessage(result),
        diagnostic: result.stderr,
      ),
    };
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
  }) async {
    final result = await _run([
      'run-bottle-command',
      bottleId,
      '--command',
      command,
      '--json',
    ]);

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
        message: _commandFailureMessage('run-bottle-command', result),
        diagnostic: result.stderr,
      ),
    };
  }

  Future<ProgramRunLoadResult> runWinetricksVerb({
    required String bottleId,
    required String verb,
  }) async {
    final result = await _run([
      'run-winetricks',
      bottleId,
      '--verb',
      verb,
      '--json',
    ]);

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
        message: _operationFailureMessage(result, 'run-winetricks'),
        diagnostic: result.stderr,
      ),
    };
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

sealed class _BottleDeleteParseResult {
  const _BottleDeleteParseResult();
}

BottleArchiveExportLoadResult _parseBottleArchiveExportPayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (error) {
    return BottleArchiveExportLoadFailure(
      exitCode: 0,
      message: error.message,
      diagnostic: '',
    );
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return const BottleArchiveExportLoadFailure(
      exitCode: 0,
      message: 'Unsupported bottle archive export payload.',
      diagnostic: '',
    );
  }

  final archive = decoded['bottleArchive'];
  if (archive is! Map<String, Object?>) {
    return const BottleArchiveExportLoadFailure(
      exitCode: 0,
      message: 'Missing bottleArchive payload.',
      diagnostic: '',
    );
  }

  final bottleId = archive['bottleId'];
  final archivePath = archive['archivePath'];
  if (bottleId is! String || archivePath is! String) {
    return const BottleArchiveExportLoadFailure(
      exitCode: 0,
      message: 'Invalid bottleArchive payload.',
      diagnostic: '',
    );
  }

  return ExportedBottleArchive(bottleId: bottleId, archivePath: archivePath);
}

final class _ParsedBottleDelete extends _BottleDeleteParseResult {
  const _ParsedBottleDelete(this.bottle);

  final BottleSummary bottle;
}

final class _BottleDeleteNotFound extends _BottleDeleteParseResult {
  const _BottleDeleteNotFound({required this.bottleId, required this.message});

  final String bottleId;
  final String message;
}

final class _BottleDeleteParseFailure extends _BottleDeleteParseResult {
  const _BottleDeleteParseFailure(this.message);

  final String message;
}

_BottleDeleteParseResult _parseBottleDeletePayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException {
    return const _BottleDeleteParseFailure(
      'Bottle delete payload is not valid JSON.',
    );
  }

  if (decoded is! Map<String, dynamic>) {
    return const _BottleDeleteParseFailure(
      'Bottle delete payload must be an object.',
    );
  }

  if (decoded['schemaVersion'] != 1) {
    return const _BottleDeleteParseFailure(
      'Unsupported bottle delete schema version.',
    );
  }

  final notFound = _parseBottleDeleteNotFound(decoded['error']);
  if (notFound != null) {
    return notFound;
  }

  final bottle = parseBottleSummary(decoded['deletedBottle']);
  if (bottle == null) {
    return const _BottleDeleteParseFailure(
      'Bottle delete payload contains an invalid bottle record.',
    );
  }

  return _ParsedBottleDelete(bottle);
}

_BottleDeleteNotFound? _parseBottleDeleteNotFound(Object? value) {
  if (value is! Map<String, dynamic>) {
    return null;
  }

  final Object? code = value['code'];
  final Object? message = value['message'];
  final Object? bottleId = value['bottleId'];

  if (code != 'bottleNotFound' || message is! String || bottleId is! String) {
    return null;
  }

  return _BottleDeleteNotFound(bottleId: bottleId, message: message);
}

BottleLocationOpenResult _parseBottleLocationOpenPayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (error) {
    return BottleLocationOpenFailure(
      exitCode: 0,
      message: error.message,
      diagnostic: '',
    );
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return const BottleLocationOpenFailure(
      exitCode: 0,
      message: 'Unsupported bottle location open payload.',
      diagnostic: '',
    );
  }

  final error = decoded['error'];
  if (error is Map<String, Object?>) {
    final message = error['message'];
    return BottleLocationOpenFailure(
      exitCode: 0,
      message: message is String ? message : 'Bottle location open failed.',
      diagnostic: '',
    );
  }

  final openedLocation = decoded['openedLocation'];
  if (openedLocation is! Map<String, Object?>) {
    return const BottleLocationOpenFailure(
      exitCode: 0,
      message: 'Missing openedLocation payload.',
      diagnostic: '',
    );
  }

  final bottleId = openedLocation['bottleId'];
  final location = openedLocation['location'];
  final path = openedLocation['path'];
  if (bottleId is! String || location is! String || path is! String) {
    return const BottleLocationOpenFailure(
      exitCode: 0,
      message: 'Invalid openedLocation payload.',
      diagnostic: '',
    );
  }

  return OpenedBottleLocation(
    bottleId: bottleId,
    location: location,
    path: path,
  );
}

ProgramLocationOpenResult _parseProgramLocationOpenPayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (error) {
    return ProgramLocationOpenFailure(
      exitCode: 0,
      message: error.message,
      diagnostic: '',
    );
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return const ProgramLocationOpenFailure(
      exitCode: 0,
      message: 'Unsupported program location open payload.',
      diagnostic: '',
    );
  }

  final error = decoded['error'];
  if (error is Map<String, Object?>) {
    final message = error['message'];
    return ProgramLocationOpenFailure(
      exitCode: 0,
      message: message is String ? message : 'Program location open failed.',
      diagnostic: '',
    );
  }

  final openedLocation = decoded['openedProgramLocation'];
  if (openedLocation is! Map<String, Object?>) {
    return const ProgramLocationOpenFailure(
      exitCode: 0,
      message: 'Missing openedProgramLocation payload.',
      diagnostic: '',
    );
  }

  final bottleId = openedLocation['bottleId'];
  final programPath = openedLocation['programPath'];
  final path = openedLocation['path'];
  if (bottleId is! String || programPath is! String || path is! String) {
    return const ProgramLocationOpenFailure(
      exitCode: 0,
      message: 'Invalid openedProgramLocation payload.',
      diagnostic: '',
    );
  }

  return OpenedProgramLocation(
    bottleId: bottleId,
    programPath: programPath,
    path: path,
  );
}

ProgramSettingsLoadResult _parseProgramSettingsPayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (error) {
    return ProgramSettingsLoadFailure(
      exitCode: 0,
      message: error.message,
      diagnostic: '',
    );
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return const ProgramSettingsLoadFailure(
      exitCode: 0,
      message: 'Unsupported program settings payload.',
      diagnostic: '',
    );
  }

  final error = decoded['error'];
  if (error is Map<String, Object?>) {
    final code = error['code'];
    final bottleId = error['bottleId'];
    final message = error['message'];
    if (code == 'bottleNotFound' && bottleId is String && message is String) {
      return MissingProgramSettingsBottle(bottleId: bottleId, message: message);
    }

    return ProgramSettingsLoadFailure(
      exitCode: 0,
      message: message is String ? message : 'Program settings failed.',
      diagnostic: '',
    );
  }

  final programSettings = decoded['programSettings'];
  if (programSettings is! Map<String, Object?>) {
    return const ProgramSettingsLoadFailure(
      exitCode: 0,
      message: 'Missing programSettings payload.',
      diagnostic: '',
    );
  }

  final bottleId = programSettings['bottleId'];
  final programPath = programSettings['programPath'];
  final settings = _parseProgramSettingsSummary(programSettings['settings']);
  if (bottleId is! String || programPath is! String || settings == null) {
    return const ProgramSettingsLoadFailure(
      exitCode: 0,
      message: 'Invalid programSettings payload.',
      diagnostic: '',
    );
  }

  return LoadedProgramSettings(
    bottleId: bottleId,
    programPath: programPath,
    settings: settings,
  );
}

AppSettingsLoadResult _parseAppSettingsPayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (error) {
    return AppSettingsLoadFailure(
      exitCode: 0,
      message: error.message,
      diagnostic: '',
    );
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return const AppSettingsLoadFailure(
      exitCode: 0,
      message: 'Unsupported app settings payload.',
      diagnostic: '',
    );
  }

  final error = decoded['error'];
  if (error is Map<String, Object?>) {
    final message = error['message'];
    return AppSettingsLoadFailure(
      exitCode: 0,
      message: message is String ? message : 'App settings failed.',
      diagnostic: '',
    );
  }

  final settings = _parseAppSettingsSummary(decoded['appSettings']);
  if (settings == null) {
    return const AppSettingsLoadFailure(
      exitCode: 0,
      message: 'Invalid appSettings payload.',
      diagnostic: '',
    );
  }

  return LoadedAppSettings(settings);
}

UpdateCheckLoadResult _parseUpdateCheckPayload({
  required String payload,
  required String payloadKey,
  required String idKey,
}) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (error) {
    return UpdateCheckLoadFailure(
      exitCode: 0,
      message: error.message,
      diagnostic: '',
    );
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return const UpdateCheckLoadFailure(
      exitCode: 0,
      message: 'Unsupported update check payload.',
      diagnostic: '',
    );
  }

  final error = decoded['error'];
  if (error is Map<String, Object?>) {
    final message = error['message'];
    return UpdateCheckLoadFailure(
      exitCode: 0,
      message: message is String ? message : 'Update check failed.',
      diagnostic: '',
    );
  }

  final update = decoded[payloadKey];
  if (update is! Map<String, Object?>) {
    return const UpdateCheckLoadFailure(
      exitCode: 0,
      message: 'Missing update check payload.',
      diagnostic: '',
    );
  }

  final parsedUpdate = _parseUpdateCheckSummary(update, idKey: idKey);
  if (parsedUpdate == null) {
    return const UpdateCheckLoadFailure(
      exitCode: 0,
      message: 'Invalid update check payload.',
      diagnostic: '',
    );
  }

  return LoadedUpdateCheck(parsedUpdate);
}

UpdateInstallLoadResult _parseUpdateInstallPayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (error) {
    return UpdateInstallLoadFailure(
      exitCode: 0,
      message: error.message,
      diagnostic: '',
    );
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return const UpdateInstallLoadFailure(
      exitCode: 0,
      message: 'Unsupported update install payload.',
      diagnostic: '',
    );
  }

  final error = decoded['error'];
  if (error is Map<String, Object?>) {
    final message = error['message'];
    return UpdateInstallLoadFailure(
      exitCode: 0,
      message: message is String ? message : 'Update install failed.',
      diagnostic: '',
    );
  }

  final install = decoded['appUpdateInstall'];
  if (install is! Map<String, Object?>) {
    return const UpdateInstallLoadFailure(
      exitCode: 0,
      message: 'Missing update install payload.',
      diagnostic: '',
    );
  }

  final parsedInstall = _parseUpdateInstallSummary(install);
  if (parsedInstall == null) {
    return const UpdateInstallLoadFailure(
      exitCode: 0,
      message: 'Invalid update install payload.',
      diagnostic: '',
    );
  }

  return InstalledUpdate(parsedInstall);
}

UpdateCheckSummary? _parseUpdateCheckSummary(
  Map<String, Object?> value, {
  required String idKey,
}) {
  final id = value[idKey];
  final status = value['status'];
  final currentVersion = value['currentVersion'];
  final latestVersion = value['latestVersion'];
  final versionUrl = value['versionUrl'];
  final archiveUrl = value['archiveUrl'];

  if (id is! String || status is! String) {
    return null;
  }

  if (!_isOptionalString(currentVersion) ||
      !_isOptionalString(latestVersion) ||
      !_isOptionalString(versionUrl) ||
      !_isOptionalString(archiveUrl)) {
    return null;
  }

  return UpdateCheckSummary(
    id: id,
    status: status,
    currentVersion: currentVersion as String?,
    latestVersion: latestVersion as String?,
    versionUrl: versionUrl as String?,
    archiveUrl: archiveUrl as String?,
  );
}

UpdateInstallSummary? _parseUpdateInstallSummary(Map<String, Object?> value) {
  final id = value['appId'];
  final status = value['status'];
  final currentVersion = value['currentVersion'];
  final installedVersion = value['installedVersion'];
  final archiveUrl = value['archiveUrl'];
  final installPath = value['installPath'];

  if (id is! String || status is! String) {
    return null;
  }

  if (!_isOptionalString(currentVersion) ||
      !_isOptionalString(installedVersion) ||
      !_isOptionalString(archiveUrl) ||
      !_isOptionalString(installPath)) {
    return null;
  }

  return UpdateInstallSummary(
    id: id,
    status: status,
    currentVersion: currentVersion as String?,
    installedVersion: installedVersion as String?,
    archiveUrl: archiveUrl as String?,
    installPath: installPath as String?,
  );
}

AppSettingsSummary? _parseAppSettingsSummary(Object? value) {
  if (value is! Map<String, Object?>) {
    return null;
  }

  final terminateWineProcessesOnClose = value['terminateWineProcessesOnClose'];
  final defaultBottlePath = value['defaultBottlePath'];
  final appearanceMode = appAppearanceModeFromJson(value['appearanceMode']);
  final automaticallyCheckForKonyakUpdates =
      value['automaticallyCheckForKonyakUpdates'];
  final automaticallyCheckForWineUpdates =
      value['automaticallyCheckForWineUpdates'];

  if (terminateWineProcessesOnClose is! bool ||
      defaultBottlePath is! String ||
      defaultBottlePath.trim().isEmpty ||
      appearanceMode == null ||
      automaticallyCheckForKonyakUpdates is! bool ||
      automaticallyCheckForWineUpdates is! bool) {
    return null;
  }

  return AppSettingsSummary(
    terminateWineProcessesOnClose: terminateWineProcessesOnClose,
    defaultBottlePath: defaultBottlePath,
    appearanceMode: appearanceMode,
    automaticallyCheckForKonyakUpdates: automaticallyCheckForKonyakUpdates,
    automaticallyCheckForWineUpdates: automaticallyCheckForWineUpdates,
  );
}

ProgramSettingsSummary? _parseProgramSettingsSummary(Object? value) {
  if (value is! Map<String, Object?>) {
    return null;
  }

  final locale = value['locale'];
  final arguments = value['arguments'];
  final environment = _parseStringMap(value['environment']);
  if (locale is! String || arguments is! String || environment == null) {
    return null;
  }

  return ProgramSettingsSummary(
    locale: locale,
    arguments: arguments,
    environment: environment,
  );
}

Map<String, String>? _parseStringMap(Object? value) {
  if (value is! Map<String, Object?>) {
    return null;
  }

  final environment = <String, String>{};
  for (final entry in value.entries) {
    if (entry.value is! String) {
      return null;
    }
    environment[entry.key] = entry.value as String;
  }

  return Map.unmodifiable(environment);
}

bool _isOptionalString(Object? value) {
  return value == null || value is String;
}

BottleProgramListLoadResult _parseBottleProgramListPayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (error) {
    return BottleProgramListLoadFailure(
      exitCode: 0,
      message: error.message,
      diagnostic: '',
    );
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return const BottleProgramListLoadFailure(
      exitCode: 0,
      message: 'Unsupported bottle program list payload.',
      diagnostic: '',
    );
  }

  final error = decoded['error'];
  if (error is Map<String, Object?>) {
    final message = error['message'];
    return BottleProgramListLoadFailure(
      exitCode: 0,
      message: message is String ? message : 'Bottle program list failed.',
      diagnostic: '',
    );
  }

  final bottlePrograms = decoded['bottlePrograms'];
  if (bottlePrograms is! Map<String, Object?>) {
    return const BottleProgramListLoadFailure(
      exitCode: 0,
      message: 'Missing bottlePrograms payload.',
      diagnostic: '',
    );
  }

  final bottleId = bottlePrograms['bottleId'];
  final programs = bottlePrograms['programs'];
  if (bottleId is! String || programs is! List<Object?>) {
    return const BottleProgramListLoadFailure(
      exitCode: 0,
      message: 'Invalid bottlePrograms payload.',
      diagnostic: '',
    );
  }

  final parsedPrograms = <BottleProgramSummary>[];
  for (final program in programs) {
    if (program is! Map<String, Object?>) {
      return const BottleProgramListLoadFailure(
        exitCode: 0,
        message: 'Invalid bottle program record.',
        diagnostic: '',
      );
    }

    final id = program['id'];
    final name = program['name'];
    final path = program['path'];
    final source = program['source'];
    if (id is! String ||
        name is! String ||
        path is! String ||
        source is! String) {
      return const BottleProgramListLoadFailure(
        exitCode: 0,
        message: 'Invalid bottle program record.',
        diagnostic: '',
      );
    }

    final metadata = _parseProgramMetadata(program['metadata']);

    parsedPrograms.add(
      BottleProgramSummary(
        id: id,
        name: name,
        path: path,
        source: source,
        metadata: metadata,
      ),
    );
  }

  return LoadedBottlePrograms(
    bottleId: bottleId,
    programs: List.unmodifiable(parsedPrograms),
  );
}

WineProcessListLoadResult _parseWineProcessListPayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (error) {
    return WineProcessListLoadFailure(
      exitCode: 0,
      message: error.message,
      diagnostic: '',
    );
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return const WineProcessListLoadFailure(
      exitCode: 0,
      message: 'Unsupported Wine process list payload.',
      diagnostic: '',
    );
  }

  final error = decoded['error'];
  if (error is Map<String, Object?>) {
    final message = error['message'];
    return WineProcessListLoadFailure(
      exitCode: 0,
      message: message is String ? message : 'Wine process list failed.',
      diagnostic: '',
    );
  }

  final wineProcesses = decoded['wineProcesses'];
  if (wineProcesses is! Map<String, Object?>) {
    return const WineProcessListLoadFailure(
      exitCode: 0,
      message: 'Missing wineProcesses payload.',
      diagnostic: '',
    );
  }

  final processes = wineProcesses['processes'];
  if (processes is! List<Object?>) {
    return const WineProcessListLoadFailure(
      exitCode: 0,
      message: 'Invalid wineProcesses payload.',
      diagnostic: '',
    );
  }

  final parsedProcesses = <WineProcessSummary>[];
  for (final process in processes) {
    if (process is! Map<String, Object?>) {
      return const WineProcessListLoadFailure(
        exitCode: 0,
        message: 'Invalid Wine process record.',
        diagnostic: '',
      );
    }

    final bottleId = process['bottleId'];
    final processId = process['processId'];
    final executable = process['executable'];
    final hostPath = process['hostPath'];
    if (bottleId is! String ||
        processId is! String ||
        executable is! String ||
        (hostPath != null && hostPath is! String)) {
      return const WineProcessListLoadFailure(
        exitCode: 0,
        message: 'Invalid Wine process record.',
        diagnostic: '',
      );
    }

    parsedProcesses.add(
      WineProcessSummary(
        bottleId: bottleId,
        processId: processId,
        executable: executable,
        hostPath: hostPath is String ? hostPath : null,
        metadata: _parseProgramMetadata(process['metadata']),
      ),
    );
  }

  return LoadedWineProcesses(processes: parsedProcesses);
}

ProgramMetadataSummary? _parseProgramMetadata(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is! Map<String, Object?>) {
    return null;
  }

  final architecture = value['architecture'];
  final fileDescription = value['fileDescription'];
  final productName = value['productName'];
  final companyName = value['companyName'];
  final fileVersion = value['fileVersion'];
  final productVersion = value['productVersion'];
  final iconPath = value['iconPath'];

  return ProgramMetadataSummary(
    architecture: architecture is String ? architecture : null,
    fileDescription: fileDescription is String ? fileDescription : null,
    productName: productName is String ? productName : null,
    companyName: companyName is String ? companyName : null,
    fileVersion: fileVersion is String ? fileVersion : null,
    productVersion: productVersion is String ? productVersion : null,
    iconPath: iconPath is String ? iconPath : null,
  );
}

WinetricksVerbListLoadResult _parseWinetricksVerbListPayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (error) {
    return WinetricksVerbListLoadFailure(
      exitCode: 0,
      message: error.message,
      diagnostic: '',
    );
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return const WinetricksVerbListLoadFailure(
      exitCode: 0,
      message: 'Unsupported winetricks verb list payload.',
      diagnostic: '',
    );
  }

  final error = decoded['error'];
  if (error is Map<String, Object?>) {
    final message = error['message'];
    return WinetricksVerbListLoadFailure(
      exitCode: 0,
      message: message is String ? message : 'Winetricks verb list failed.',
      diagnostic: '',
    );
  }

  final winetricks = decoded['winetricks'];
  if (winetricks is! Map<String, Object?>) {
    return const WinetricksVerbListLoadFailure(
      exitCode: 0,
      message: 'Missing winetricks payload.',
      diagnostic: '',
    );
  }

  final categories = winetricks['categories'];
  if (categories is! List<Object?>) {
    return const WinetricksVerbListLoadFailure(
      exitCode: 0,
      message: 'Invalid winetricks categories payload.',
      diagnostic: '',
    );
  }

  final parsedCategories = <WinetricksCategorySummary>[];
  for (final category in categories) {
    final parsedCategory = _parseWinetricksCategorySummary(category);
    if (parsedCategory == null) {
      return const WinetricksVerbListLoadFailure(
        exitCode: 0,
        message: 'Invalid winetricks category record.',
        diagnostic: '',
      );
    }

    parsedCategories.add(parsedCategory);
  }

  return LoadedWinetricksVerbs(categories: parsedCategories);
}

WinetricksCategorySummary? _parseWinetricksCategorySummary(Object? value) {
  if (value is! Map<String, Object?>) {
    return null;
  }

  final id = value['id'];
  final name = value['name'];
  final verbs = value['verbs'];
  if (id is! String || name is! String || verbs is! List<Object?>) {
    return null;
  }

  final parsedVerbs = <WinetricksVerbSummary>[];
  for (final verb in verbs) {
    final parsedVerb = _parseWinetricksVerbSummary(verb);
    if (parsedVerb == null) {
      return null;
    }

    parsedVerbs.add(parsedVerb);
  }

  return WinetricksCategorySummary(id: id, name: name, verbs: parsedVerbs);
}

WinetricksVerbSummary? _parseWinetricksVerbSummary(Object? value) {
  if (value is! Map<String, Object?>) {
    return null;
  }

  final id = value['id'];
  final name = value['name'];
  final description = value['description'];
  if (id is! String || name is! String || description is! String) {
    return null;
  }

  return WinetricksVerbSummary(id: id, name: name, description: description);
}

String _resolveDartExecutable(
  Map<String, String> environment, {
  required String dartExecutableDefine,
  required String flutterRootDefine,
}) {
  final override = _firstNonEmpty(
    dartExecutableDefine,
    environment['KONYAK_DART_EXECUTABLE'],
  );
  if (override != null && override.trim().isNotEmpty) {
    return override;
  }

  final flutterRoot = _firstNonEmpty(
    flutterRootDefine,
    environment['FLUTTER_ROOT'],
  );
  if (flutterRoot != null && flutterRoot.trim().isNotEmpty) {
    return _joinPath(flutterRoot, const ['bin', 'dart']);
  }

  return 'dart';
}

String _resolveCliScriptPath(
  Map<String, String> environment, {
  required String cliScriptDefine,
  required String repoRootDefine,
}) {
  final override = _firstNonEmpty(
    cliScriptDefine,
    environment['KONYAK_CLI_SCRIPT'],
  );
  if (override != null && override.trim().isNotEmpty) {
    return override;
  }

  final repoRoot = _firstNonEmpty(
    repoRootDefine,
    environment['KONYAK_REPO_ROOT'],
  );
  if (repoRoot != null && repoRoot.trim().isNotEmpty) {
    return _joinPath(repoRoot, const [
      'packages',
      'konyak_cli',
      'bin',
      'konyak.dart',
    ]);
  }

  return '../../packages/konyak_cli/bin/konyak.dart';
}

Map<String, String> _runtimeEnvironmentOverrides(
  Map<String, String> environment, {
  required String repoRootDefine,
  required String runtimeProfileDefine,
  required String macosWineHomeDefine,
  required String macosWineStackManifestDefine,
  required String macosDevRuntimePrepareScriptDefine,
}) {
  final runtimeProfile = _firstNonEmpty(
    runtimeProfileDefine,
    environment['KONYAK_RUNTIME_PROFILE'],
  );
  final repoRoot = _firstNonEmpty(
    repoRootDefine,
    environment['KONYAK_REPO_ROOT'],
  );
  final isDevelopment = runtimeProfile == 'development';
  final macosWineHome = _firstNonEmpty(
    macosWineHomeDefine,
    environment['KONYAK_MACOS_WINE_HOME'],
    isDevelopment && repoRoot != null
        ? _joinPath(repoRoot, const [
            '.dart_tool',
            'konyak',
            'dev-runtime',
            'macos-wine',
          ])
        : null,
  );
  final macosStackManifest = _firstNonEmpty(
    macosWineStackManifestDefine,
    environment['KONYAK_DEV_MACOS_WINE_STACK_MANIFEST'],
    isDevelopment && repoRoot != null
        ? _joinPath(repoRoot, const [
            '.dart_tool',
            'konyak',
            'dev-runtime-source',
            'macos-wine-stack',
            'konyak-macos-wine-runtime-stack-source.json',
          ])
        : null,
  );
  final macosPrepareScript = _firstNonEmpty(
    macosDevRuntimePrepareScriptDefine,
    environment['KONYAK_MACOS_DEV_RUNTIME_PREPARE_SCRIPT'],
    isDevelopment && repoRoot != null
        ? _joinPath(repoRoot, const [
            'scripts',
            'prepare_macos_dev_runtime_stack.zsh',
          ])
        : null,
  );

  final overrides = <String, String>{};
  void addIfPresent(String key, String? value) {
    if (value != null && value.trim().isNotEmpty) {
      overrides[key] = value.trim();
    }
  }

  addIfPresent('KONYAK_RUNTIME_PROFILE', runtimeProfile);
  addIfPresent('KONYAK_MACOS_WINE_HOME', macosWineHome);
  addIfPresent('KONYAK_DEV_MACOS_WINE_STACK_MANIFEST', macosStackManifest);
  addIfPresent('KONYAK_MACOS_DEV_RUNTIME_PREPARE_SCRIPT', macosPrepareScript);

  return Map.unmodifiable(overrides);
}

String? _resolveCliScriptWorkingDirectory(String cliScriptPath) {
  final pathSegments = _splitPathSegments(cliScriptPath);
  if (pathSegments.length < 2 ||
      pathSegments[pathSegments.length - 2] != 'bin') {
    return null;
  }

  return _joinPath(
    _pathPrefixForSegmentCount(cliScriptPath, pathSegments.length - 2),
    const <String>[],
  );
}

String? _resolveCliScriptRunTarget(String cliScriptPath) {
  final pathSegments = _splitPathSegments(cliScriptPath);
  if (pathSegments.length < 2 ||
      pathSegments[pathSegments.length - 2] != 'bin') {
    return null;
  }

  return pathSegments.skip(pathSegments.length - 2).join('/');
}

List<String> _splitPathSegments(String path) {
  final normalized = path.replaceAll('\\', '/');
  return normalized.split('/').where((segment) => segment.isNotEmpty).toList();
}

String _pathPrefixForSegmentCount(String path, int segmentCount) {
  final normalized = path.replaceAll('\\', '/');
  final isAbsolute = normalized.startsWith('/');
  final segments = _splitPathSegments(path);
  final prefixSegments = segments.take(segmentCount).toList();
  if (prefixSegments.isEmpty) {
    return isAbsolute ? '/' : '.';
  }

  final prefix = prefixSegments.join('/');
  return isAbsolute ? '/$prefix' : prefix;
}

sealed class BottleListLoadResult {
  const BottleListLoadResult();
}

final class LoadedBottleList extends BottleListLoadResult {
  const LoadedBottleList(this.bottles);

  final List<BottleSummary> bottles;
}

final class BottleListLoadFailure extends BottleListLoadResult {
  const BottleListLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class BottleDetailLoadResult {
  const BottleDetailLoadResult();
}

final class LoadedBottleDetail extends BottleDetailLoadResult {
  const LoadedBottleDetail(this.bottle);

  final BottleSummary bottle;
}

final class MissingBottleDetail extends BottleDetailLoadResult {
  const MissingBottleDetail({required this.bottleId, required this.message});

  final String bottleId;
  final String message;
}

final class BottleDetailLoadFailure extends BottleDetailLoadResult {
  const BottleDetailLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class RuntimeListLoadResult {
  const RuntimeListLoadResult();
}

final class LoadedRuntimeList extends RuntimeListLoadResult {
  const LoadedRuntimeList(this.runtimes);

  final List<RuntimeSummary> runtimes;
}

final class RuntimeListLoadFailure extends RuntimeListLoadResult {
  const RuntimeListLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class RuntimeInstallLoadResult {
  const RuntimeInstallLoadResult();
}

final class InstalledRuntime extends RuntimeInstallLoadResult {
  const InstalledRuntime(this.runtime);

  final RuntimeSummary runtime;
}

final class RuntimeInstallLoadFailure extends RuntimeInstallLoadResult {
  const RuntimeInstallLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class AppSettingsLoadResult {
  const AppSettingsLoadResult();
}

final class LoadedAppSettings extends AppSettingsLoadResult {
  const LoadedAppSettings(this.settings);

  final AppSettingsSummary settings;
}

final class AppSettingsLoadFailure extends AppSettingsLoadResult {
  const AppSettingsLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class UpdateCheckLoadResult {
  const UpdateCheckLoadResult();
}

final class LoadedUpdateCheck extends UpdateCheckLoadResult {
  const LoadedUpdateCheck(this.update);

  final UpdateCheckSummary update;
}

final class UpdateCheckLoadFailure extends UpdateCheckLoadResult {
  const UpdateCheckLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class UpdateInstallLoadResult {
  const UpdateInstallLoadResult();
}

final class InstalledUpdate extends UpdateInstallLoadResult {
  const InstalledUpdate(this.update);

  final UpdateInstallSummary update;
}

final class UpdateInstallLoadFailure extends UpdateInstallLoadResult {
  const UpdateInstallLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class WineProcessTerminationLoadResult {
  const WineProcessTerminationLoadResult();
}

final class TerminatedWineProcesses extends WineProcessTerminationLoadResult {
  const TerminatedWineProcesses();
}

final class WineProcessTerminationLoadFailure
    extends WineProcessTerminationLoadResult {
  const WineProcessTerminationLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class BottleCreateLoadResult {
  const BottleCreateLoadResult();
}

final class CreatedBottle extends BottleCreateLoadResult {
  const CreatedBottle(this.bottle);

  final BottleSummary bottle;
}

final class ExistingBottle extends BottleCreateLoadResult {
  const ExistingBottle({required this.bottleId, required this.message});

  final String bottleId;
  final String message;
}

final class BottleCreateLoadFailure extends BottleCreateLoadResult {
  const BottleCreateLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class BottleArchiveExportLoadResult {
  const BottleArchiveExportLoadResult();
}

final class ExportedBottleArchive extends BottleArchiveExportLoadResult {
  const ExportedBottleArchive({
    required this.bottleId,
    required this.archivePath,
  });

  final String bottleId;
  final String archivePath;
}

final class BottleArchiveExportLoadFailure
    extends BottleArchiveExportLoadResult {
  const BottleArchiveExportLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class BottleArchiveImportLoadResult {
  const BottleArchiveImportLoadResult();
}

final class ImportedBottleArchive extends BottleArchiveImportLoadResult {
  const ImportedBottleArchive(this.bottle);

  final BottleSummary bottle;
}

final class BottleArchiveImportLoadFailure
    extends BottleArchiveImportLoadResult {
  const BottleArchiveImportLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class BottleUpdateLoadResult {
  const BottleUpdateLoadResult();
}

final class UpdatedBottle extends BottleUpdateLoadResult {
  const UpdatedBottle(this.bottle);

  final BottleSummary bottle;
}

final class MissingBottleUpdate extends BottleUpdateLoadResult {
  const MissingBottleUpdate({required this.bottleId, required this.message});

  final String bottleId;
  final String message;
}

final class BottleUpdateLoadFailure extends BottleUpdateLoadResult {
  const BottleUpdateLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class BottleDeleteLoadResult {
  const BottleDeleteLoadResult();
}

final class DeletedBottle extends BottleDeleteLoadResult {
  const DeletedBottle(this.bottle);

  final BottleSummary bottle;
}

final class MissingBottleDelete extends BottleDeleteLoadResult {
  const MissingBottleDelete({required this.bottleId, required this.message});

  final String bottleId;
  final String message;
}

final class BottleDeleteLoadFailure extends BottleDeleteLoadResult {
  const BottleDeleteLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class ProgramRunLoadResult {
  const ProgramRunLoadResult();
}

final class CompletedProgramRun extends ProgramRunLoadResult {
  const CompletedProgramRun(this.run);

  final ProgramRunSummary run;
}

final class UnsupportedProgramRun extends ProgramRunLoadResult {
  const UnsupportedProgramRun({
    required this.programPath,
    required this.message,
  });

  final String programPath;
  final String message;
}

final class MissingProgramRunBottle extends ProgramRunLoadResult {
  const MissingProgramRunBottle({
    required this.bottleId,
    required this.message,
  });

  final String bottleId;
  final String message;
}

final class FailedProgramRun extends ProgramRunLoadResult {
  FailedProgramRun({
    required this.bottleId,
    required this.programPath,
    required this.message,
    required this.runnerKind,
    required this.executable,
    required List<String> argv,
    required this.logPath,
    this.workingDirectory,
  }) : argv = List.unmodifiable(argv);

  final String bottleId;
  final String programPath;
  final String message;
  final String runnerKind;
  final String executable;
  final String? workingDirectory;
  final List<String> argv;
  final String logPath;
}

final class ProgramRunLoadFailure extends ProgramRunLoadResult {
  const ProgramRunLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class BottleLocationOpenResult {
  const BottleLocationOpenResult();
}

final class OpenedBottleLocation extends BottleLocationOpenResult {
  const OpenedBottleLocation({
    required this.bottleId,
    required this.location,
    required this.path,
  });

  final String bottleId;
  final String location;
  final String path;
}

final class BottleLocationOpenFailure extends BottleLocationOpenResult {
  const BottleLocationOpenFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class ProgramLocationOpenResult {
  const ProgramLocationOpenResult();
}

final class OpenedProgramLocation extends ProgramLocationOpenResult {
  const OpenedProgramLocation({
    required this.bottleId,
    required this.programPath,
    required this.path,
  });

  final String bottleId;
  final String programPath;
  final String path;
}

final class ProgramLocationOpenFailure extends ProgramLocationOpenResult {
  const ProgramLocationOpenFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

sealed class ProgramSettingsLoadResult {
  const ProgramSettingsLoadResult();
}

final class LoadedProgramSettings extends ProgramSettingsLoadResult {
  const LoadedProgramSettings({
    required this.bottleId,
    required this.programPath,
    required this.settings,
  });

  final String bottleId;
  final String programPath;
  final ProgramSettingsSummary settings;
}

final class MissingProgramSettingsBottle extends ProgramSettingsLoadResult {
  const MissingProgramSettingsBottle({
    required this.bottleId,
    required this.message,
  });

  final String bottleId;
  final String message;
}

final class ProgramSettingsLoadFailure extends ProgramSettingsLoadResult {
  const ProgramSettingsLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

final class BottleProgramSummary {
  const BottleProgramSummary({
    required this.id,
    required this.name,
    required this.path,
    required this.source,
    this.metadata,
  });

  final String id;
  final String name;
  final String path;
  final String source;
  final ProgramMetadataSummary? metadata;
}

final class ProgramMetadataSummary {
  const ProgramMetadataSummary({
    this.architecture,
    this.fileDescription,
    this.productName,
    this.companyName,
    this.fileVersion,
    this.productVersion,
    this.iconPath,
  });

  final String? architecture;
  final String? fileDescription;
  final String? productName;
  final String? companyName;
  final String? fileVersion;
  final String? productVersion;
  final String? iconPath;

  String get displayName {
    return fileDescription ?? productName ?? '';
  }
}

sealed class WineProcessListLoadResult {
  const WineProcessListLoadResult();
}

final class LoadedWineProcesses extends WineProcessListLoadResult {
  LoadedWineProcesses({required List<WineProcessSummary> processes})
    : processes = List.unmodifiable(processes);

  final List<WineProcessSummary> processes;
}

final class WineProcessListLoadFailure extends WineProcessListLoadResult {
  const WineProcessListLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

final class WineProcessSummary {
  const WineProcessSummary({
    required this.bottleId,
    required this.processId,
    required this.executable,
    this.hostPath,
    this.metadata,
  });

  final String bottleId;
  final String processId;
  final String executable;
  final String? hostPath;
  final ProgramMetadataSummary? metadata;
}

sealed class BottleProgramListLoadResult {
  const BottleProgramListLoadResult();
}

final class LoadedBottlePrograms extends BottleProgramListLoadResult {
  LoadedBottlePrograms({
    required this.bottleId,
    required List<BottleProgramSummary> programs,
  }) : programs = List.unmodifiable(programs);

  final String bottleId;
  final List<BottleProgramSummary> programs;
}

final class BottleProgramListLoadFailure extends BottleProgramListLoadResult {
  const BottleProgramListLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

final class WinetricksVerbSummary {
  const WinetricksVerbSummary({
    required this.id,
    required this.name,
    required this.description,
  });

  final String id;
  final String name;
  final String description;
}

final class WinetricksCategorySummary {
  WinetricksCategorySummary({
    required this.id,
    required this.name,
    required List<WinetricksVerbSummary> verbs,
  }) : verbs = List.unmodifiable(verbs);

  final String id;
  final String name;
  final List<WinetricksVerbSummary> verbs;
}

sealed class WinetricksVerbListLoadResult {
  const WinetricksVerbListLoadResult();
}

final class LoadedWinetricksVerbs extends WinetricksVerbListLoadResult {
  LoadedWinetricksVerbs({required List<WinetricksCategorySummary> categories})
    : categories = List.unmodifiable(categories);

  final List<WinetricksCategorySummary> categories;
}

final class WinetricksVerbListLoadFailure extends WinetricksVerbListLoadResult {
  const WinetricksVerbListLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}

BottleUpdateLoadResult _bottleUpdateResultFromCommand({
  required ProcessRunResult result,
  required String command,
}) {
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
      message: _operationFailureMessage(result, command),
      diagnostic: result.stderr,
    ),
  };
}

ProgramSettingsLoadResult _programSettingsResultFromCommand({
  required ProcessRunResult result,
  required String command,
}) {
  final parsed = _parseProgramSettingsPayload(result.stdout);

  return switch (parsed) {
    LoadedProgramSettings() when result.exitCode == 0 => parsed,
    MissingProgramSettingsBottle() when result.exitCode == 66 => parsed,
    LoadedProgramSettings() ||
    MissingProgramSettingsBottle() ||
    ProgramSettingsLoadFailure() => ProgramSettingsLoadFailure(
      exitCode: result.exitCode,
      message: _operationFailureMessage(result, command),
      diagnostic: result.stderr,
    ),
  };
}

AppSettingsLoadResult _appSettingsResultFromCommand({
  required ProcessRunResult result,
  required String command,
}) {
  final parsed = _parseAppSettingsPayload(result.stdout);

  return switch (parsed) {
    LoadedAppSettings() when result.exitCode == 0 => parsed,
    LoadedAppSettings() || AppSettingsLoadFailure() => AppSettingsLoadFailure(
      exitCode: result.exitCode,
      message: _operationFailureMessage(result, command),
      diagnostic: result.stderr,
    ),
  };
}

UpdateCheckLoadResult _updateCheckResultFromCommand({
  required ProcessRunResult result,
  required String command,
  required String payloadKey,
  required String idKey,
}) {
  final parsed = _parseUpdateCheckPayload(
    payload: result.stdout,
    payloadKey: payloadKey,
    idKey: idKey,
  );

  return switch (parsed) {
    LoadedUpdateCheck() when result.exitCode == 0 => parsed,
    LoadedUpdateCheck() || UpdateCheckLoadFailure() => UpdateCheckLoadFailure(
      exitCode: result.exitCode,
      message: _operationFailureMessage(result, command),
      diagnostic: result.stderr,
    ),
  };
}

UpdateInstallLoadResult _updateInstallResultFromCommand(
  ProcessRunResult result,
) {
  final parsed = _parseUpdateInstallPayload(result.stdout);

  return switch (parsed) {
    InstalledUpdate() when result.exitCode == 0 => parsed,
    InstalledUpdate() || UpdateInstallLoadFailure() => UpdateInstallLoadFailure(
      exitCode: result.exitCode,
      message: _operationFailureMessage(result, 'install-app-update'),
      diagnostic: result.stderr,
    ),
  };
}

WineProcessTerminationLoadResult _wineProcessTerminationResultFromCommand(
  ProcessRunResult result, {
  String command = 'terminate-wine-processes',
}) {
  if (result.exitCode == 0 &&
      _isSuccessfulWineProcessTerminationPayload(result.stdout)) {
    return const TerminatedWineProcesses();
  }

  return WineProcessTerminationLoadFailure(
    exitCode: result.exitCode,
    message: _operationFailureMessage(result, command),
    diagnostic: result.stderr,
  );
}

bool _isSuccessfulWineProcessTerminationPayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException {
    return false;
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return false;
  }

  final termination = decoded['wineProcessTermination'];
  if (termination is! Map<String, Object?>) {
    return false;
  }

  return termination['hasFailures'] == false &&
      (termination['bottles'] is List<Object?> ||
          termination['processes'] is List<Object?>);
}

String _detailFailureMessage(ProcessRunResult result) {
  if (result.exitCode == 0) {
    final parsed = parseBottleDetailPayload(result.stdout);

    return switch (parsed) {
      BottleDetailParseFailure(:final message) => message,
      ParsedBottleDetail() || BottleDetailNotFound() =>
        'inspect-bottle returned an inconsistent detail payload.',
    };
  }

  return 'inspect-bottle failed with exit code ${result.exitCode}.';
}

String _createFailureMessage(ProcessRunResult result) {
  if (result.exitCode == 0) {
    final parsed = parseBottleCreatePayload(result.stdout);

    return switch (parsed) {
      BottleCreateParseFailure(:final message) => message,
      ParsedBottleCreate() || BottleCreateConflict() =>
        'create-bottle returned an inconsistent payload.',
    };
  }

  return 'create-bottle failed with exit code ${result.exitCode}.';
}

String _updateFailureMessage(ProcessRunResult result) {
  if (result.exitCode == 0) {
    final parsed = parseBottleDetailPayload(result.stdout);

    return switch (parsed) {
      BottleDetailParseFailure(:final message) => message,
      ParsedBottleDetail() || BottleDetailNotFound() =>
        'set-windows-version returned an inconsistent payload.',
    };
  }

  return 'set-windows-version failed with exit code ${result.exitCode}.';
}

String _deleteFailureMessage(ProcessRunResult result) {
  if (result.exitCode == 0) {
    final parsed = _parseBottleDeletePayload(result.stdout);

    return switch (parsed) {
      _BottleDeleteParseFailure(:final message) => message,
      _ParsedBottleDelete() || _BottleDeleteNotFound() =>
        'delete-bottle returned an inconsistent payload.',
    };
  }

  return 'delete-bottle failed with exit code ${result.exitCode}.';
}

String _operationFailureMessage(ProcessRunResult result, String command) {
  final message = _jsonErrorMessage(result.stdout);
  if (message != null) {
    return message;
  }

  return _commandFailureMessage(command, result);
}

String? _jsonErrorMessage(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException {
    return null;
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return null;
  }

  final error = decoded['error'];
  if (error is! Map<String, Object?>) {
    return null;
  }

  final message = error['message'];
  return message is String ? message : null;
}

String _programRunFailureMessage(ProcessRunResult result) {
  if (result.exitCode == 0) {
    final parsed = parseProgramRunPayload(result.stdout);

    return switch (parsed) {
      ProgramRunParseFailure(:final message) => message,
      ParsedProgramRun() ||
      ProgramRunUnsupportedProgramType() ||
      ProgramRunBottleNotFound() ||
      ProgramRunExecutionFailure() =>
        'run-program returned an inconsistent payload.',
    };
  }

  return 'run-program failed with exit code ${result.exitCode}.';
}

String _installRuntimeFailureMessage(ProcessRunResult result) {
  if (result.exitCode == 0) {
    final parsed = _parseRuntimeInstallCommandPayload(result.stdout);

    return switch (parsed) {
      RuntimeInstallParseFailure(:final message) => message,
      ParsedRuntimeInstall() || RuntimeInstallCommandFailure() =>
        'install-macos-wine returned an inconsistent payload.',
    };
  }

  final parsed = _parseRuntimeInstallCommandPayload(result.stdout);
  if (parsed case RuntimeInstallCommandFailure(:final message)) {
    return message;
  }

  return _commandFailureMessage('install-macos-wine', result);
}

RuntimeInstallParseResult _parseRuntimeInstallCommandPayload(String stdout) {
  final parsed = parseRuntimeInstallPayload(stdout);
  if (parsed is! RuntimeInstallParseFailure) {
    return parsed;
  }

  final lines = const LineSplitter()
      .convert(stdout)
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
  for (final line in lines.reversed) {
    final lineParsed = parseRuntimeInstallPayload(line);
    if (lineParsed is! RuntimeInstallParseFailure) {
      return lineParsed;
    }
  }

  return parsed;
}

String _commandFailureMessage(String command, ProcessRunResult result) {
  final message = _jsonErrorMessage(result.stdout);
  if (message != null) {
    return message;
  }

  final diagnostic = result.stderr.trim();
  if (diagnostic.isEmpty) {
    return '$command failed with exit code ${result.exitCode}.';
  }

  return '$command failed with exit code ${result.exitCode}: $diagnostic';
}

String _processOutputToString(Object? output) {
  if (output == null) {
    return '';
  }

  if (output is String) {
    return output;
  }

  return output.toString();
}

String? _firstNonEmpty(String? first, String? second, [String? third]) {
  for (final value in <String?>[first, second, third]) {
    if (value != null && value.trim().isNotEmpty) {
      return value;
    }
  }

  return null;
}

String _joinPath(String root, Iterable<String> components) {
  var path = root;
  for (final component in components) {
    final normalized = component.replaceAll(RegExp(r'^/+|/+$'), '');
    path = path.endsWith('/') ? '$path$normalized' : '$path/$normalized';
  }

  return path;
}
