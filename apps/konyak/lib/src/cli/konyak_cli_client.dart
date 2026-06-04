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
part 'konyak_cli_launch_config.dart';
part 'konyak_cli_client_factory.dart';
part 'konyak_cli_bottle_payload_parsers.dart';
part 'konyak_cli_program_payload_parsers.dart';
part 'konyak_cli_settings_payload_parsers.dart';
part 'konyak_cli_update_payload_parsers.dart';
part 'konyak_cli_wine_process_payload_parsers.dart';
part 'konyak_cli_winetricks_payload_parsers.dart';
part 'konyak_cli_bottle_result_types.dart';
part 'konyak_cli_program_result_types.dart';
part 'konyak_cli_runtime_result_types.dart';
part 'konyak_cli_settings_result_types.dart';
part 'konyak_cli_update_result_types.dart';
part 'konyak_cli_wine_process_result_types.dart';
part 'konyak_cli_winetricks_result_types.dart';
part 'konyak_cli_failure_messages.dart';
part 'konyak_cli_result_helpers.dart';
part 'konyak_cli_read_commands.dart';
part 'konyak_cli_runtime_commands.dart';
part 'konyak_cli_settings_commands.dart';
part 'konyak_cli_bottle_commands.dart';
part 'konyak_cli_program_commands.dart';

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

  Future<RuntimeInstallLoadResult> _runtimeInstallResultFromCommand({
    required String command,
    List<String> arguments = const <String>[],
    required void Function(RuntimeInstallProgress progress)? onProgress,
  }) async {
    final result = await _runRuntimeInstall(
      command: command,
      arguments: arguments,
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
    List<String> arguments = const <String>[],
    required void Function(RuntimeInstallProgress progress)? onProgress,
  }) {
    if (onProgress == null) {
      return _run(<String>[command, ...arguments, '--json']);
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
