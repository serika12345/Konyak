import 'dart:io';

import '../domain/program/program_run_environment.dart';
import '../domain/runtime/runtime_validation_models.dart';
import '../domain/shared/domain_value_objects.dart';
import 'external_payload_helpers.dart';

class DartIoRuntimeExecutableProbe implements RuntimeExecutableProbe {
  const DartIoRuntimeExecutableProbe();

  @override
  RuntimeExecutableProbeResult run({
    required ProgramExecutable executable,
    required ProgramRunArguments arguments,
    required ProgramRunEnvironment environment,
    required ProgramWorkingDirectoryPath workingDirectory,
  }) {
    try {
      final result = Process.runSync(
        executable.value,
        arguments.value,
        environment: environment.toMap(),
        workingDirectory: workingDirectory.value,
        runInShell: false,
      );

      return RuntimeExecutableProbeResult(
        exitCode: result.exitCode,
        stdout: processOutputToString(result.stdout),
        stderr: processOutputToString(result.stderr),
      );
    } on ProcessException catch (error) {
      return RuntimeExecutableProbeResult(
        exitCode: 127,
        stdout: '',
        stderr: error.message,
      );
    }
  }
}
