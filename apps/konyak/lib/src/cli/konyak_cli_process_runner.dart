import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'konyak_cli_result_helpers.dart';

sealed class ProcessWorkingDirectory {
  const ProcessWorkingDirectory();
}

final class InheritedProcessWorkingDirectory extends ProcessWorkingDirectory {
  const InheritedProcessWorkingDirectory();
}

final class ConfiguredProcessWorkingDirectory extends ProcessWorkingDirectory {
  const ConfiguredProcessWorkingDirectory(this.path);

  final String path;
}

sealed class ProcessStartObserver {
  const ProcessStartObserver();
}

final class IgnoreProcessStart extends ProcessStartObserver {
  const IgnoreProcessStart();
}

final class NotifyProcessStart extends ProcessStartObserver {
  const NotifyProcessStart(this.onStarted);

  final void Function(int processId) onStarted;
}

sealed class ProcessStdoutObserver {
  const ProcessStdoutObserver();
}

final class IgnoreProcessStdout extends ProcessStdoutObserver {
  const IgnoreProcessStdout();
}

final class NotifyProcessStdoutLine extends ProcessStdoutObserver {
  const NotifyProcessStdoutLine(this.onLine);

  final void Function(String line) onLine;
}

sealed class ProcessRunObservation {
  const ProcessRunObservation();
}

final class UnobservedProcessRun extends ProcessRunObservation {
  const UnobservedProcessRun();
}

final class ObservedProcessRun extends ProcessRunObservation {
  const ObservedProcessRun({
    required this.startObserver,
    required this.stdoutObserver,
  });

  final ProcessStartObserver startObserver;
  final ProcessStdoutObserver stdoutObserver;
}

abstract interface class ProcessRunner {
  Future<ProcessRunResult> run(
    String executable,
    List<String> arguments, {
    ProcessWorkingDirectory workingDirectory =
        const InheritedProcessWorkingDirectory(),
    Map<String, String> environment = const <String, String>{},
    ProcessRunObservation observation = const UnobservedProcessRun(),
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
    ProcessWorkingDirectory workingDirectory =
        const InheritedProcessWorkingDirectory(),
    Map<String, String> environment = const <String, String>{},
    ProcessRunObservation observation = const UnobservedProcessRun(),
  }) async {
    final childEnvironment = <String, String>{
      ...konyakCliChildEnvironment(),
      ...environment,
    };

    switch (observation) {
      case ObservedProcessRun():
        return runStarted(
          executable,
          arguments,
          workingDirectory: workingDirectory,
          environment: childEnvironment,
          observation: observation,
        );
      case UnobservedProcessRun():
        break;
    }

    final ProcessResult result;
    try {
      result = await switch (workingDirectory) {
        InheritedProcessWorkingDirectory() => Process.run(
          executable,
          arguments,
          environment: childEnvironment,
          runInShell: false,
        ),
        ConfiguredProcessWorkingDirectory(:final path) => Process.run(
          executable,
          arguments,
          environment: childEnvironment,
          runInShell: false,
          workingDirectory: path,
        ),
      };
    } on ProcessException catch (error) {
      return ProcessRunResult(
        exitCode: 127,
        stdout: '',
        stderr: 'Failed to start $executable: ${error.message}',
      );
    }

    return ProcessRunResult(
      exitCode: result.exitCode,
      stdout: processOutputToString(result.stdout as Object),
      stderr: processOutputToString(result.stderr as Object),
    );
  }

  Future<ProcessRunResult> runStarted(
    String executable,
    List<String> arguments, {
    required ProcessWorkingDirectory workingDirectory,
    required Map<String, String> environment,
    required ObservedProcessRun observation,
  }) async {
    final Process process;
    try {
      process = await switch (workingDirectory) {
        InheritedProcessWorkingDirectory() => Process.start(
          executable,
          arguments,
          environment: environment,
          runInShell: false,
        ),
        ConfiguredProcessWorkingDirectory(:final path) => Process.start(
          executable,
          arguments,
          environment: environment,
          runInShell: false,
          workingDirectory: path,
        ),
      };
    } on ProcessException catch (error) {
      return ProcessRunResult(
        exitCode: 127,
        stdout: '',
        stderr: 'Failed to start $executable: ${error.message}',
      );
    }

    switch (observation.startObserver) {
      case IgnoreProcessStart():
        break;
      case NotifyProcessStart(:final onStarted):
        onStarted(process.pid);
    }

    final stderrBuffer = StringBuffer();
    final stderrFuture = process.stderr
        .transform(utf8.decoder)
        .forEach(stderrBuffer.write);
    return switch (observation.stdoutObserver) {
      IgnoreProcessStdout() => () async {
        final stdoutBuffer = StringBuffer();
        final stdoutFuture = process.stdout
            .transform(utf8.decoder)
            .forEach(stdoutBuffer.write);
        final exitCode = await process.exitCode;
        await stdoutFuture;
        await stderrFuture;

        return ProcessRunResult(
          exitCode: exitCode,
          stdout: stdoutBuffer.toString(),
          stderr: stderrBuffer.toString(),
        );
      }(),
      NotifyProcessStdoutLine(:final onLine) => () async {
        final stdoutLines = <String>[];
        final stdoutFuture = process.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .forEach((line) {
              stdoutLines.add(line);
              onLine(line);
            });

        final exitCode = await process.exitCode;
        await stdoutFuture;
        await stderrFuture;

        return ProcessRunResult(
          exitCode: exitCode,
          stdout: stdoutLines.join('\n'),
          stderr: stderrBuffer.toString(),
        );
      }(),
    };
  }
}

Map<String, String> konyakCliChildEnvironment() {
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

  final inheritedAppIconPath = Platform.environment['KONYAK_APP_ICON_PATH'];
  if (inheritedAppIconPath != null && inheritedAppIconPath.trim().isNotEmpty) {
    environment['KONYAK_APP_ICON_PATH'] = inheritedAppIconPath.trim();
  }

  final inheritedAppBundlePath = Platform.environment['KONYAK_APP_BUNDLE_PATH'];
  if (inheritedAppBundlePath != null &&
      inheritedAppBundlePath.trim().isNotEmpty) {
    environment['KONYAK_APP_BUNDLE_PATH'] = inheritedAppBundlePath.trim();
  }

  return environment;
}
