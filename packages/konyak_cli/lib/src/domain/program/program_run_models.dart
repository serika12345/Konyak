import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../shared/domain_helpers.dart';
import '../shared/domain_value_objects.dart';
import 'program_run_environment.dart';

part 'program_run_models.freezed.dart';

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

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class ProgramRunResult with _$ProgramRunResult {
  const ProgramRunResult._();

  const factory ProgramRunResult.completed({
    required int processExitCode,
    @Default('') String stdout,
    @Default('') String stderr,
  }) = ProgramRunCompleted;

  const factory ProgramRunResult.failed({required String message}) =
      ProgramRunFailed;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class WineProcessTerminationRecord
    with _$WineProcessTerminationRecord {
  const WineProcessTerminationRecord._();

  factory WineProcessTerminationRecord({
    required String bottleId,
    required String status,
    required String runnerKind,
    required String executable,
    required List<String> argv,
    Option<String> processId = const Option.none(),
    Option<int> processExitCode = const Option.none(),
    Option<String> message = const Option.none(),
  }) {
    return WineProcessTerminationRecord._validated(
      bottleId: BottleId(bottleId),
      status: WineProcessStatus(status),
      runnerKind: RunnerKind(runnerKind),
      executable: ProgramExecutable(executable),
      argv: List<String>.unmodifiable(argv),
      processId: processId.map(WineProcessId.new),
      processExitCode: processExitCode,
      message: _optionalNonBlankDomainString(message, 'message'),
    );
  }

  const factory WineProcessTerminationRecord._validated({
    required BottleId bottleId,
    required WineProcessStatus status,
    required RunnerKind runnerKind,
    required ProgramExecutable executable,
    required List<String> argv,
    required Option<WineProcessId> processId,
    required Option<int> processExitCode,
    required Option<String> message,
  }) = _WineProcessTerminationRecord;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class PathOpenResult with _$PathOpenResult {
  const PathOpenResult._();

  const factory PathOpenResult.completed() = PathOpenCompleted;

  const factory PathOpenResult.failed(String message) = PathOpenFailed;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class DetachedProcessStartResult with _$DetachedProcessStartResult {
  const DetachedProcessStartResult._();

  const factory DetachedProcessStartResult.completed() =
      DetachedProcessStartCompleted;

  const factory DetachedProcessStartResult.failed(String message) =
      DetachedProcessStartFailed;
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
