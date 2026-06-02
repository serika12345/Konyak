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

      final logFile = File(request.logPath);
      logFile.parent.createSync(recursive: true);
      logFile.writeAsStringSync(_programRunLog(request, result));

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
      final logFile = File(request.logPath);
      logFile.parent.createSync(recursive: true);
      logFile.writeAsStringSync(_programRunStartupFailureLog(request, message));

      return ProgramRunFailed(message: message);
    } on FileSystemException catch (error) {
      return ProgramRunFailed(message: error.message);
    }
  }
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
