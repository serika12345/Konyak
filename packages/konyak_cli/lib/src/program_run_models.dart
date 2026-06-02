part of '../konyak_cli.dart';

class ProgramRunRequest {
  ProgramRunRequest({
    required this.bottleId,
    required this.programPath,
    required this.runnerKind,
    required this.executable,
    required List<String> arguments,
    required Map<String, String> environment,
    required this.logPath,
    this.workingDirectory,
  }) : arguments = List.unmodifiable(arguments),
       environment = Map.unmodifiable(environment);

  final String bottleId;
  final String programPath;
  final String runnerKind;
  final String executable;
  final List<String> arguments;
  final Map<String, String> environment;
  final String logPath;
  final String? workingDirectory;

  List<String> get argv {
    return List.unmodifiable(<String>[executable, ...arguments]);
  }
}

sealed class ProgramRunResult {
  const ProgramRunResult();
}

class ProgramRunCompleted extends ProgramRunResult {
  const ProgramRunCompleted({
    required this.processExitCode,
    this.stdout = '',
    this.stderr = '',
  });

  final int processExitCode;
  final String stdout;
  final String stderr;
}

class ProgramRunFailed extends ProgramRunResult {
  const ProgramRunFailed({required this.message});

  final String message;
}

class WineProcessTerminationRecord {
  WineProcessTerminationRecord({
    required this.bottleId,
    required this.status,
    required this.runnerKind,
    required this.executable,
    required List<String> argv,
    this.processId,
    this.processExitCode,
    this.message,
  }) : argv = List.unmodifiable(argv);

  final String bottleId;
  final String status;
  final String runnerKind;
  final String executable;
  final List<String> argv;
  final String? processId;
  final int? processExitCode;
  final String? message;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'bottleId': bottleId,
      if (processId != null) 'processId': processId,
      'status': status,
      'runnerKind': runnerKind,
      'executable': executable,
      'argv': argv,
      if (processExitCode != null) 'processExitCode': processExitCode,
      if (message != null) 'message': message,
    };
  }
}

sealed class PathOpenResult {
  const PathOpenResult();
}

class PathOpenCompleted extends PathOpenResult {
  const PathOpenCompleted();
}

class PathOpenFailed extends PathOpenResult {
  const PathOpenFailed(this.message);

  final String message;
}

sealed class DetachedProcessStartResult {
  const DetachedProcessStartResult();
}

class DetachedProcessStartCompleted extends DetachedProcessStartResult {
  const DetachedProcessStartCompleted();
}

class DetachedProcessStartFailed extends DetachedProcessStartResult {
  const DetachedProcessStartFailed(this.message);

  final String message;
}

abstract interface class DetachedProcessStarter {
  DetachedProcessStartResult start({
    required String executable,
    required List<String> arguments,
  });
}
