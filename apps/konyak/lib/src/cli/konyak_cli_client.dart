import 'dart:async';
import 'dart:convert';

import 'konyak_cli_failure_messages.dart';
import 'konyak_cli_process_runner.dart';
import 'konyak_cli_program_result_types.dart';
import 'konyak_cli_result_helpers.dart';
import 'konyak_cli_runtime_result_types.dart';
import 'program_run_contract.dart';
import 'runtime_install_contract.dart';

export 'konyak_cli_bottle_commands.dart';
export 'konyak_cli_bottle_payload_parsers.dart';
export 'konyak_cli_bottle_result_types.dart';
export 'konyak_cli_client_factory.dart';
export 'konyak_cli_failure_messages.dart';
export 'konyak_cli_launch_config.dart';
export 'konyak_cli_process_runner.dart';
export 'konyak_cli_program_commands.dart';
export 'konyak_cli_program_payload_parsers.dart';
export 'konyak_cli_program_result_types.dart';
export 'konyak_cli_read_commands.dart';
export 'konyak_cli_result_helpers.dart';
export 'konyak_cli_runtime_commands.dart';
export 'konyak_cli_runtime_result_types.dart';
export 'konyak_cli_settings_commands.dart';
export 'konyak_cli_settings_payload_parsers.dart';
export 'konyak_cli_settings_result_types.dart';
export 'konyak_cli_update_payload_parsers.dart';
export 'konyak_cli_update_result_types.dart';
export 'konyak_cli_wine_process_payload_parsers.dart';
export 'konyak_cli_wine_process_result_types.dart';
export 'konyak_cli_winetricks_payload_parsers.dart';
export 'konyak_cli_winetricks_result_types.dart';

final class KonyakCliClient {
  KonyakCliClient({
    required this.executable,
    List<String> baseArguments = const <String>[],
    Map<String, String> environment = const <String, String>{},
    this.workingDirectory,
    required this.processRunner,
  }) : baseArguments = List.unmodifiable(baseArguments),
       environment = Map.unmodifiable(environment);

  final String executable;
  final List<String> baseArguments;
  final Map<String, String> environment;
  final String? workingDirectory;
  final ProcessRunner processRunner;

  Future<RuntimeInstallLoadResult> runtimeInstallResultFromCommand({
    required String command,
    List<String> arguments = const <String>[],
    required void Function(RuntimeInstallProgress progress)? onProgress,
  }) async {
    final result = await runRuntimeInstall(
      command: command,
      arguments: arguments,
      onProgress: onProgress,
    );
    final parsed = parseRuntimeInstallCommandPayload(result.stdout);

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
        message: installRuntimeFailureMessage(result),
        diagnostic: result.stderr,
      ),
    };
  }

  Future<ProgramRunLoadResult> programRunResultFromCommand({
    required List<String> arguments,
    required String Function(ProcessRunResult result) failureMessage,
    void Function(int processId)? onStarted,
  }) async {
    final result = await run(arguments, onStarted: onStarted);
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
        :final logFileCreated,
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
          logFileCreated: logFileCreated,
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

  Future<ProcessRunResult> run(
    List<String> arguments, {
    void Function(int processId)? onStarted,
  }) {
    return processRunner.run(
      executable,
      <String>[...baseArguments, ...arguments],
      workingDirectory: workingDirectory,
      environment: <String, String>{...environment, ...launcherEnvironment()},
      onStarted: onStarted,
    );
  }

  Future<ProcessRunResult> runRuntimeInstall({
    required String command,
    List<String> arguments = const <String>[],
    required void Function(RuntimeInstallProgress progress)? onProgress,
  }) {
    if (onProgress == null) {
      return run(<String>[command, ...arguments, '--json']);
    }

    return processRunner.run(
      executable,
      <String>[
        ...baseArguments,
        command,
        ...arguments,
        '--progress-json',
        '--json',
      ],
      workingDirectory: workingDirectory,
      environment: <String, String>{...environment, ...launcherEnvironment()},
      onStdoutLine: (line) {
        switch (parseRuntimeInstallProgressPayload(line)) {
          case ParsedRuntimeInstallProgress(:final progress):
            onProgress(progress);
          case InvalidRuntimeInstallProgress():
            break;
        }
      },
    );
  }

  Map<String, String> launcherEnvironment() {
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
