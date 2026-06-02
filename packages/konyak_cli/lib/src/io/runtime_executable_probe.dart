part of '../../konyak_cli.dart';

class DartIoRuntimeExecutableProbe implements RuntimeExecutableProbe {
  const DartIoRuntimeExecutableProbe();

  @override
  RuntimeExecutableProbeResult run({
    required String executable,
    required List<String> arguments,
    required ProgramRunEnvironment environment,
    required String workingDirectory,
  }) {
    try {
      final result = Process.runSync(
        executable,
        arguments,
        environment: environment.toMap(),
        workingDirectory: workingDirectory,
        runInShell: false,
      );

      return RuntimeExecutableProbeResult(
        exitCode: result.exitCode,
        stdout: _processOutputToString(result.stdout),
        stderr: _processOutputToString(result.stderr),
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
