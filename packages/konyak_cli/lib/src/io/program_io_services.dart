import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../cli/cli_json_helpers.dart';
import '../domain/program/program_run_environment.dart';
import '../domain/program/program_run_models.dart';
import '../domain/program/program_runner.dart';
import '../domain/shared/domain_value_objects.dart';
import '../platform/platform_location_paths.dart';
import 'external_payload_helpers.dart';
import 'platform_host_paths.dart';

class DartIoProgramRunner implements ProgramRunner {
  const DartIoProgramRunner();

  @override
  ProgramRunResult run(ProgramRunRequest request) {
    return switch (request.completionPolicy) {
      ProgramRunCompletionPolicy.waitForExit => runAndWaitForExit(request),
      ProgramRunCompletionPolicy.launchOnly => runLaunchOnly(request),
    };
  }

  ProgramRunResult runAndWaitForExit(ProgramRunRequest request) {
    try {
      final result = Process.runSync(
        request.executable.value,
        request.arguments.value,
        environment: _programProcessEnvironment(request),
        includeParentEnvironment: false,
        workingDirectory: request.workingDirectory.match(
          () => null,
          (value) => value.value,
        ),
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

  ProgramRunResult runLaunchOnly(ProgramRunRequest request) {
    try {
      final result = Process.runSync(
        'bash',
        <String>[
          '-lc',
          r'nohup "$1" "${@:2}" >/dev/null 2>&1 &',
          '_',
          request.executable.value,
          ...request.arguments.value,
        ],
        environment: _programProcessEnvironment(request),
        includeParentEnvironment: false,
        workingDirectory: request.workingDirectory.match(
          () => null,
          (value) => value.value,
        ),
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
        executable: 'bash',
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

enum AsyncProgramOutputCompletionPolicy { streamsClosed, directProcessExit }

class DartIoAsyncProgramRunner implements AsyncProgramRunner {
  const DartIoAsyncProgramRunner({
    this.timeout,
    this.outputCompletionPolicy =
        AsyncProgramOutputCompletionPolicy.streamsClosed,
  });

  final Duration? timeout;
  final AsyncProgramOutputCompletionPolicy outputCompletionPolicy;

  static const directProcessOutputDrainTimeout = Duration(milliseconds: 250);

  @override
  Future<ProgramRunResult> run(ProgramRunRequest request) async {
    final Process process;
    try {
      process = await Process.start(
        request.executable.value,
        request.arguments.value,
        environment: _programProcessEnvironment(request),
        includeParentEnvironment: false,
        workingDirectory: request.workingDirectory.match(
          () => null,
          (value) => value.value,
        ),
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
    final stdoutDone = Completer<void>();
    final stderrDone = Completer<void>();
    final stdoutSubscription = process.stdout
        .transform(utf8.decoder)
        .listen(
          stdoutBuffer.write,
          onError: stdoutDone.completeError,
          onDone: stdoutDone.complete,
          cancelOnError: true,
        );
    final stderrSubscription = process.stderr
        .transform(utf8.decoder)
        .listen(
          stderrBuffer.write,
          onError: stderrDone.completeError,
          onDone: stderrDone.complete,
          cancelOnError: true,
        );
    final exitCodeFuture = process.exitCode;

    try {
      final processExitCode = await awaitAsyncProcessExit(
        exitCodeFuture: exitCodeFuture,
      );
      await finishProcessOutput(
        stdoutDone: stdoutDone.future,
        stderrDone: stderrDone.future,
        completionPolicy: outputCompletionPolicy,
      );

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
      await finishProcessOutput(
        stdoutDone: stdoutDone.future,
        stderrDone: stderrDone.future,
        completionPolicy: AsyncProgramOutputCompletionPolicy.directProcessExit,
      );
      final message = programRunnerTimeoutMessage(
        executable: request.executable.value,
        timeout: timeout,
      );
      await writeProgramRunStartupFailureLog(request, message);
      return ProgramRunFailed(message: message);
    } on FileSystemException catch (error) {
      return ProgramRunFailed(message: error.message);
    } finally {
      await stdoutSubscription.cancel();
      await stderrSubscription.cancel();
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

  Future<void> finishProcessOutput({
    required Future<void> stdoutDone,
    required Future<void> stderrDone,
    required AsyncProgramOutputCompletionPolicy completionPolicy,
  }) {
    return Future.wait(<Future<void>>[
      finishOutputStream(done: stdoutDone, completionPolicy: completionPolicy),
      finishOutputStream(done: stderrDone, completionPolicy: completionPolicy),
    ]).then((_) {});
  }

  Future<void> finishOutputStream({
    required Future<void> done,
    required AsyncProgramOutputCompletionPolicy completionPolicy,
  }) async {
    switch (completionPolicy) {
      case AsyncProgramOutputCompletionPolicy.streamsClosed:
        await done;
      case AsyncProgramOutputCompletionPolicy.directProcessExit:
        try {
          await done.timeout(directProcessOutputDrainTimeout);
        } on TimeoutException {
          // A long-lived descendant can retain the process pipe after the
          // requested installer has exited.
        }
    }
  }
}

Map<String, String> _programProcessEnvironment(ProgramRunRequest request) {
  final requestEnvironment = request.environment.toMap();
  return <String, String>{
    for (final entry in Platform.environment.entries)
      if (!isKonyakChildProcessRulesEnvironmentVariable(entry.key) &&
          !isWineWaitChildPipeIgnoreEnvironmentVariable(entry.key))
        entry.key: entry.value,
    for (final entry in requestEnvironment.entries)
      if (!isKonyakChildProcessRulesEnvironmentVariable(entry.key))
        entry.key: entry.value,
    ...request.environment[konyakChildProcessRulesEnvironmentVariable].match(
      () => const <String, String>{},
      (rules) => rules.isEmpty
          ? const <String, String>{}
          : <String, String>{konyakChildProcessRulesEnvironmentVariable: rules},
    ),
  };
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

    return snapshot.match(
      () async => (await readPsSnapshot(const <String>[
        '-axo',
        'command=',
      ])).match(() => '', (value) => value),
      (value) async => value,
    );
  }

  Future<Option<String>> readPsSnapshot(List<String> arguments) async {
    try {
      final result = await Process.run(
        'ps',
        arguments,
        runInShell: false,
      ).timeout(timeout);
      if (result.exitCode != 0) {
        return const Option.none();
      }

      return Option.of(processOutputToString(result.stdout));
    } on ProcessException {
      return const Option.none();
    } on TimeoutException {
      return const Option.none();
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
  PathOpenResult openPath(PathOpenTarget target) {
    return runPathOpenCommand(<String>[target.value]);
  }

  @override
  PathOpenResult revealPath(PathRevealTarget target) {
    return switch (currentHostPlatform()) {
      KonyakHostPlatform.macos => runPathOpenCommand(<String>[
        '-R',
        target.value,
      ]),
      KonyakHostPlatform.linux => runPathOpenCommand(<String>[
        programLocationPath(ProgramPath(target.value)),
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
    required ProgramExecutable executable,
    required ProgramRunArguments arguments,
  }) {
    try {
      final result = Process.runSync('bash', <String>[
        '-lc',
        r'nohup "$1" "${@:2}" >/dev/null 2>&1 &',
        '_',
        executable.value,
        ...arguments.value,
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
