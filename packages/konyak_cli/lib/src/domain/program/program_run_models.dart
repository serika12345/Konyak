part of '../../../konyak_cli.dart';

class ProgramRunRequest {
  ProgramRunRequest({
    required this.bottleId,
    required this.programPath,
    required this.runnerKind,
    required this.executable,
    required List<String> arguments,
    required Map<String, String> environment,
    required this.logPath,
    Option<String> workingDirectory = const Option.none(),
  }) : arguments = List.unmodifiable(arguments),
       environment = Map.unmodifiable(environment),
       workingDirectory = _optionalNonBlankDomainString(
         workingDirectory,
         'workingDirectory',
       );

  final String bottleId;
  final String programPath;
  final String runnerKind;
  final String executable;
  final List<String> arguments;
  final Map<String, String> environment;
  final String logPath;
  final Option<String> workingDirectory;

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
    Option<String> processId = const Option.none(),
    this.processExitCode = const Option.none(),
    Option<String> message = const Option.none(),
  }) : argv = List.unmodifiable(argv),
       processId = _optionalNonBlankDomainString(processId, 'processId'),
       message = _optionalNonBlankDomainString(message, 'message');

  final String bottleId;
  final String status;
  final String runnerKind;
  final String executable;
  final List<String> argv;
  final Option<String> processId;
  final Option<int> processExitCode;
  final Option<String> message;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'bottleId': bottleId,
      ...processId.match(
        () => const <String, Object?>{},
        (value) => <String, Object?>{'processId': value},
      ),
      'status': status,
      'runnerKind': runnerKind,
      'executable': executable,
      'argv': argv,
      ...processExitCode.match(
        () => const <String, Object?>{},
        (value) => <String, Object?>{'processExitCode': value},
      ),
      ...message.match(
        () => const <String, Object?>{},
        (value) => <String, Object?>{'message': value},
      ),
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

Option<String> _optionalNonBlankDomainString(
  Option<String> value,
  String fieldName,
) {
  return value.map((item) => _requiredNonBlankDomainString(item, fieldName));
}

abstract interface class DetachedProcessStarter {
  DetachedProcessStartResult start({
    required String executable,
    required List<String> arguments,
  });
}
