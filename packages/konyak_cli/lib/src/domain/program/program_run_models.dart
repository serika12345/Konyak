import 'package:fpdart/fpdart.dart';

import '../shared/domain_helpers.dart';
import '../shared/domain_value_objects.dart';
import 'program_run_environment.dart';

class ProgramRunRequest {
  ProgramRunRequest({
    required this.bottleId,
    required this.programPath,
    required this.runnerKind,
    required this.executable,
    required this.arguments,
    required this.environment,
    required this.logPath,
    this.createLogFile = true,
    this.workingDirectory = const Option.none(),
  });

  final BottleId bottleId;
  final ProgramPath programPath;
  final RunnerKind runnerKind;
  final ProgramExecutable executable;
  final ProgramRunArguments arguments;
  final ProgramRunEnvironment environment;
  final ProgramLogPath logPath;
  final bool createLogFile;
  final Option<ProgramWorkingDirectoryPath> workingDirectory;

  List<String> get argv {
    return List.unmodifiable(<String>[executable.value, ...arguments.value]);
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
    required String bottleId,
    required String status,
    required String runnerKind,
    required String executable,
    required List<String> argv,
    Option<String> processId = const Option.none(),
    this.processExitCode = const Option.none(),
    Option<String> message = const Option.none(),
  }) : bottleId = BottleId(bottleId),
       status = WineProcessStatus(status),
       runnerKind = RunnerKind(runnerKind),
       executable = ProgramExecutable(executable),
       argv = List.unmodifiable(argv),
       processId = processId.map(WineProcessId.new),
       message = _optionalNonBlankDomainString(message, 'message');

  final BottleId bottleId;
  final WineProcessStatus status;
  final RunnerKind runnerKind;
  final ProgramExecutable executable;
  final List<String> argv;
  final Option<WineProcessId> processId;
  final Option<int> processExitCode;
  final Option<String> message;
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
  return value.map((item) => requiredNonBlankDomainString(item, fieldName));
}

abstract interface class DetachedProcessStarter {
  DetachedProcessStartResult start({
    required String executable,
    required List<String> arguments,
  });
}
