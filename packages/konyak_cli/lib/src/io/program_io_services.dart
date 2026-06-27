part of '../../konyak_cli.dart';

class DartIoProgramRunner implements ProgramRunner {
  const DartIoProgramRunner();

  @override
  ProgramRunResult run(ProgramRunRequest request) {
    try {
      final result = Process.runSync(
        request.executable,
        request.arguments,
        environment: request.environment.toMap(),
        workingDirectory: request.workingDirectory.toNullable(),
        runInShell: false,
      );

      if (request.createLogFile) {
        final logFile = File(request.logPath);
        logFile.parent.createSync(recursive: true);
        logFile.writeAsStringSync(_programRunLog(request, result));
      }

      return ProgramRunCompleted(
        processExitCode: result.exitCode,
        stdout: _processOutputToString(result.stdout),
        stderr: _processOutputToString(result.stderr),
      );
    } on ProcessException catch (error) {
      final message = _programRunnerFailureMessage(
        executable: request.executable,
        message: error.message,
      );
      if (request.createLogFile) {
        final logFile = File(request.logPath);
        logFile.parent.createSync(recursive: true);
        logFile.writeAsStringSync(
          _programRunStartupFailureLog(request, message),
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
        request.executable,
        request.arguments,
        environment: request.environment.toMap(),
        workingDirectory: request.workingDirectory.toNullable(),
        runInShell: false,
      );
    } on ProcessException catch (error) {
      final message = _programRunnerFailureMessage(
        executable: request.executable,
        message: error.message,
      );
      await _writeProgramRunStartupFailureLog(request, message);

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
      final processExitCode = await _awaitAsyncProcessExit(
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
        final logFile = File(request.logPath);
        await logFile.parent.create(recursive: true);
        await logFile.writeAsString(_programRunLog(request, result));
      }
      return ProgramRunCompleted(
        processExitCode: processExitCode,
        stdout: stdoutBuffer.toString(),
        stderr: stderrBuffer.toString(),
      );
    } on TimeoutException {
      process.kill(ProcessSignal.sigterm);
      await _finishTimedOutAsyncProcess(
        process: process,
        exitCodeFuture: exitCodeFuture,
      );
      await stdoutFuture;
      await stderrFuture;
      final message = _programRunnerTimeoutMessage(
        executable: request.executable,
        timeout: timeout,
      );
      await _writeProgramRunStartupFailureLog(request, message);
      return ProgramRunFailed(message: message);
    } on FileSystemException catch (error) {
      return ProgramRunFailed(message: error.message);
    }
  }

  Future<int> _awaitAsyncProcessExit({required Future<int> exitCodeFuture}) {
    final timeout = this.timeout;
    if (timeout == null) {
      return exitCodeFuture;
    }

    return exitCodeFuture.timeout(timeout);
  }

  Future<void> _finishTimedOutAsyncProcess({
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

  static const _timeout = Duration(milliseconds: 750);

  @override
  Future<String> read() async {
    final snapshot = await _readPsSnapshot(const <String>[
      'eww',
      '-axo',
      'command=',
    ]);
    if (snapshot != null) {
      return snapshot;
    }

    return await _readPsSnapshot(const <String>['-axo', 'command=']) ?? '';
  }

  Future<String?> _readPsSnapshot(List<String> arguments) async {
    try {
      final result = await Process.run(
        'ps',
        arguments,
        runInShell: false,
      ).timeout(_timeout);
      if (result.exitCode != 0) {
        return null;
      }

      return _processOutputToString(result.stdout);
    } on ProcessException {
      return null;
    } on TimeoutException {
      return null;
    }
  }
}

Future<void> _writeProgramRunStartupFailureLog(
  ProgramRunRequest request,
  String message,
) async {
  if (!request.createLogFile) {
    return;
  }

  final logFile = File(request.logPath);
  await logFile.parent.create(recursive: true);
  await logFile.writeAsString(_programRunStartupFailureLog(request, message));
}

String _programRunnerTimeoutMessage({
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
    return _runPathOpenCommand(<String>[path]);
  }

  @override
  PathOpenResult revealPath(String path) {
    return switch (_currentHostPlatform()) {
      KonyakHostPlatform.macos => _runPathOpenCommand(<String>['-R', path]),
      KonyakHostPlatform.linux => _runPathOpenCommand(<String>[
        _programLocationPath(path),
      ]),
    };
  }

  PathOpenResult _runPathOpenCommand(List<String> arguments) {
    try {
      final result = Process.runSync(
        _pathOpenExecutable(),
        arguments,
        runInShell: false,
      );
      if (result.exitCode != 0) {
        return PathOpenFailed(_processOutputToString(result.stderr));
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
        return DetachedProcessStartFailed(
          _processOutputToString(result.stderr),
        );
      }

      return const DetachedProcessStartCompleted();
    } on ProcessException catch (error) {
      return DetachedProcessStartFailed(error.message);
    }
  }
}
