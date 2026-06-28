import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../cli/cli_json_helpers.dart';
import '../domain/program/program_run_models.dart';
import '../domain/program/program_runner.dart';
import '../platform/platform_location_paths.dart';
import 'external_payload_helpers.dart';
import 'platform_host_paths.dart';

class DartIoProgramRunner implements ProgramRunner {
  const DartIoProgramRunner();

  @override
  ProgramRunResult run(ProgramRunRequest request) {
    try {
      final result = Process.runSync(
        request.executable.value,
        request.arguments.value,
        environment: request.environment.toMap(),
        workingDirectory: request.workingDirectory.toNullable()?.value,
        runInShell: false,
      );

      if (request.createLogFile) {
        final logFile = File(request.logPath.value);
        logFile.parent.createSync(recursive: true);
        logFile.writeAsStringSync(programRunLog(request, result));
      }

      return ProgramRunCompleted(
        processExitCode: result.exitCode,
        stdout: processOutputToString(result.stdout),
        stderr: processOutputToString(result.stderr),
      );
    } on ProcessException catch (error) {
      final message = programRunnerFailureMessage(
        executable: request.executable.value,
        message: error.message,
      );
      if (request.createLogFile) {
        final logFile = File(request.logPath.value);
        logFile.parent.createSync(recursive: true);
        logFile.writeAsStringSync(
          programRunStartupFailureLog(request, message),
        );
      }

      return ProgramRunFailed(message: message);
    } on FileSystemException catch (error) {
      return ProgramRunFailed(message: error.message);
    }
  }
}

class DartIoAsyncProgramRunner implements AsyncProgramRunner {
  const DartIoAsyncProgramRunner({this.timeout});

  final Duration? timeout;

  @override
  Future<ProgramRunResult> run(ProgramRunRequest request) async {
    final Process process;
    try {
      process = await Process.start(
        request.executable.value,
        request.arguments.value,
        environment: request.environment.toMap(),
        workingDirectory: request.workingDirectory.toNullable()?.value,
        runInShell: false,
      );
    } on ProcessException catch (error) {
      final message = programRunnerFailureMessage(
        executable: request.executable.value,
        message: error.message,
      );
      await writeProgramRunStartupFailureLog(request, message);

      return ProgramRunFailed(message: message);
    }

    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();
    final stdoutFuture = process.stdout
        .transform(utf8.decoder)
        .forEach(stdoutBuffer.write);
    final stderrFuture = process.stderr
        .transform(utf8.decoder)
        .forEach(stderrBuffer.write);
    final exitCodeFuture = process.exitCode;

    try {
      final processExitCode = await awaitAsyncProcessExit(
        exitCodeFuture: exitCodeFuture,
      );
      await stdoutFuture;
      await stderrFuture;

      final result = ProcessResult(
        process.pid,
        processExitCode,
        stdoutBuffer.toString(),
        stderrBuffer.toString(),
      );
      if (request.createLogFile) {
        final logFile = File(request.logPath.value);
        await logFile.parent.create(recursive: true);
        await logFile.writeAsString(programRunLog(request, result));
      }
      return ProgramRunCompleted(
        processExitCode: processExitCode,
        stdout: stdoutBuffer.toString(),
        stderr: stderrBuffer.toString(),
      );
    } on TimeoutException {
      process.kill(ProcessSignal.sigterm);
      await finishTimedOutAsyncProcess(
        process: process,
        exitCodeFuture: exitCodeFuture,
      );
      await stdoutFuture;
      await stderrFuture;
      final message = programRunnerTimeoutMessage(
        executable: request.executable.value,
        timeout: timeout,
      );
      await writeProgramRunStartupFailureLog(request, message);
      return ProgramRunFailed(message: message);
    } on FileSystemException catch (error) {
      return ProgramRunFailed(message: error.message);
    }
  }

  Future<int> awaitAsyncProcessExit({required Future<int> exitCodeFuture}) {
    final timeout = this.timeout;
    if (timeout == null) {
      return exitCodeFuture;
    }

    return exitCodeFuture.timeout(timeout);
  }

  Future<void> finishTimedOutAsyncProcess({
    required Process process,
    required Future<int> exitCodeFuture,
  }) async {
    await exitCodeFuture.timeout(
      const Duration(milliseconds: 500),
      onTimeout: () {
        process.kill(ProcessSignal.sigkill);
        return -1;
      },
    );
  }
}

class DartIoHostProcessSnapshotReader implements HostProcessSnapshotReader {
  const DartIoHostProcessSnapshotReader();

  static const timeout = Duration(milliseconds: 750);

  @override
  Future<String> read() async {
    final snapshot = await readPsSnapshot(const <String>[
      'eww',
      '-axo',
      'command=',
    ]);
    if (snapshot != null) {
      return snapshot;
    }

    return await readPsSnapshot(const <String>['-axo', 'command=']) ?? '';
  }

  Future<String?> readPsSnapshot(List<String> arguments) async {
    try {
      final result = await Process.run(
        'ps',
        arguments,
        runInShell: false,
      ).timeout(timeout);
      if (result.exitCode != 0) {
        return null;
      }

      return processOutputToString(result.stdout);
    } on ProcessException {
      return null;
    } on TimeoutException {
      return null;
    }
  }
}

Future<void> writeProgramRunStartupFailureLog(
  ProgramRunRequest request,
  String message,
) async {
  if (!request.createLogFile) {
    return;
  }

  final logFile = File(request.logPath.value);
  await logFile.parent.create(recursive: true);
  await logFile.writeAsString(programRunStartupFailureLog(request, message));
}

String programRunnerTimeoutMessage({
  required String executable,
  required Duration? timeout,
}) {
  final seconds = timeout == null ? 'the configured' : '${timeout.inSeconds}';
  return 'Failed to complete $executable within $seconds seconds.';
}

class DartIoPathOpener implements PathOpener {
  const DartIoPathOpener();

  @override
  PathOpenResult openPath(String path) {
    return runPathOpenCommand(<String>[path]);
  }

  @override
  PathOpenResult revealPath(String path) {
    return switch (currentHostPlatform()) {
      KonyakHostPlatform.macos => runPathOpenCommand(<String>['-R', path]),
      KonyakHostPlatform.linux => runPathOpenCommand(<String>[
        programLocationPath(path),
      ]),
    };
  }

  PathOpenResult runPathOpenCommand(List<String> arguments) {
    try {
      final result = Process.runSync(
        pathOpenExecutable(),
        arguments,
        runInShell: false,
      );
      if (result.exitCode != 0) {
        return PathOpenFailed(processOutputToString(result.stderr));
      }

      return const PathOpenCompleted();
    } on ProcessException catch (error) {
      return PathOpenFailed(error.message);
    }
  }
}

class DartIoDetachedProcessStarter implements DetachedProcessStarter {
  const DartIoDetachedProcessStarter();

  @override
  DetachedProcessStartResult start({
    required String executable,
    required List<String> arguments,
  }) {
    try {
      final result = Process.runSync('bash', <String>[
        '-lc',
        r'nohup "$1" "${@:2}" >/dev/null 2>&1 &',
        '_',
        executable,
        ...arguments,
      ], runInShell: false);
      if (result.exitCode != 0) {
        return DetachedProcessStartFailed(processOutputToString(result.stderr));
      }

      return const DetachedProcessStartCompleted();
    } on ProcessException catch (error) {
      return DetachedProcessStartFailed(error.message);
    }
  }
}
