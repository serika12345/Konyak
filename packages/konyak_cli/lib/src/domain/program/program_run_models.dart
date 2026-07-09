import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../shared/domain_helpers.dart';
import '../shared/domain_value_objects.dart';
import 'program_run_environment.dart';

part 'program_run_models.freezed.dart';

enum ProgramRunCompletionPolicy {
  waitForExit('waitForExit'),
  launchOnly('launchOnly');

  const ProgramRunCompletionPolicy(this.value);

  final String value;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class ProgramRunRequest with _$ProgramRunRequest {
  const ProgramRunRequest._();

  factory ProgramRunRequest({
    required BottleId bottleId,
    required ProgramPath programPath,
    required RunnerKind runnerKind,
    required ProgramExecutable executable,
    required ProgramRunArguments arguments,
    required ProgramRunEnvironment environment,
    required ProgramLogPath logPath,
    bool createLogFile = true,
    Option<ProgramWorkingDirectoryPath> workingDirectory = const Option.none(),
    ProgramRunCompletionPolicy completionPolicy =
        ProgramRunCompletionPolicy.waitForExit,
  }) {
    return ProgramRunRequest._validated(
      bottleId: bottleId,
      programPath: programPath,
      runnerKind: runnerKind,
      executable: executable,
      arguments: arguments,
      environment: environment,
      logPath: logPath,
      createLogFile: createLogFile,
      workingDirectory: workingDirectory,
      completionPolicy: completionPolicy,
    );
  }

  const factory ProgramRunRequest._validated({
    required BottleId bottleId,
    required ProgramPath programPath,
    required RunnerKind runnerKind,
    required ProgramExecutable executable,
    required ProgramRunArguments arguments,
    required ProgramRunEnvironment environment,
    required ProgramLogPath logPath,
    required bool createLogFile,
    required Option<ProgramWorkingDirectoryPath> workingDirectory,
    required ProgramRunCompletionPolicy completionPolicy,
  }) = _ProgramRunRequest;

  List<String> get argv {
    return List.unmodifiable(<String>[executable.value, ...arguments.value]);
  }

  ProgramRunRequest withCompletionPolicy(
    ProgramRunCompletionPolicy completionPolicy,
  ) {
    return ProgramRunRequest(
      bottleId: bottleId,
      programPath: programPath,
      runnerKind: runnerKind,
      executable: executable,
      arguments: arguments,
      environment: environment,
      logPath: logPath,
      createLogFile: createLogFile,
      workingDirectory: workingDirectory,
      completionPolicy: completionPolicy,
    );
  }
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class WinedbgCommandPlan with _$WinedbgCommandPlan {
  const WinedbgCommandPlan._();

  const factory WinedbgCommandPlan({
    required WinedbgCommand command,
    required ProgramLogFileName logFileName,
    required ProgramRunArguments trailingArguments,
  }) = _WinedbgCommandPlan;
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
    required BottleId bottleId,
    required WineProcessStatus status,
    required RunnerKind runnerKind,
    required ProgramExecutable executable,
    required List<String> argv,
    Option<WineProcessId> processId = const Option.none(),
    Option<int> processExitCode = const Option.none(),
    Option<String> message = const Option.none(),
  }) {
    return WineProcessTerminationRecord._validated(
      bottleId: bottleId,
      status: status,
      runnerKind: runnerKind,
      executable: executable,
      argv: List<String>.unmodifiable(argv),
      processId: processId,
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
    required ProgramExecutable executable,
    required ProgramRunArguments arguments,
  });
}
