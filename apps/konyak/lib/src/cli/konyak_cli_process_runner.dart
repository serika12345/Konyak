part of 'konyak_cli_client.dart';

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

  final inheritedAppImagePath = Platform.environment['KONYAK_APPIMAGE_PATH'];
  if (inheritedAppImagePath != null &&
      inheritedAppImagePath.trim().isNotEmpty) {
    environment['KONYAK_APPIMAGE_PATH'] = inheritedAppImagePath.trim();
  }

  final inheritedAppBundlePath = Platform.environment['KONYAK_APP_BUNDLE_PATH'];
  if (inheritedAppBundlePath != null &&
      inheritedAppBundlePath.trim().isNotEmpty) {
    environment['KONYAK_APP_BUNDLE_PATH'] = inheritedAppBundlePath.trim();
  }

  return environment;
}
