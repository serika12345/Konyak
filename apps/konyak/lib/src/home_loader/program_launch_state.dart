import 'package:freezed_annotation/freezed_annotation.dart';

part 'program_launch_state.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class ProgramLaunchState with _$ProgramLaunchState {
  const ProgramLaunchState._();

  const factory ProgramLaunchState.idle({@Default(0) int nextLaunchId}) =
      IdleProgramLaunchState;

  factory ProgramLaunchState.active({
    required int nextLaunchId,
    required Set<int> launchIds,
  }) {
    return launchIds.isEmpty
        ? ProgramLaunchState.idle(nextLaunchId: nextLaunchId)
        : ProgramLaunchState._active(
            nextLaunchId: nextLaunchId,
            launchIds: Set.unmodifiable(launchIds),
          );
  }

  const factory ProgramLaunchState._active({
    required int nextLaunchId,
    required Set<int> launchIds,
  }) = ActiveProgramLaunchState;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class ProgramLaunchStartResult with _$ProgramLaunchStartResult {
  const factory ProgramLaunchStartResult({
    required ProgramLaunchState state,
    required int launchId,
  }) = StartedProgramLaunch;
}

ProgramLaunchStartResult startProgramLaunch({
  required ProgramLaunchState state,
}) {
  final nextLaunchId = _nextProgramLaunchId(state);
  return ProgramLaunchStartResult(
    launchId: nextLaunchId,
    state: ProgramLaunchState.active(
      nextLaunchId: nextLaunchId + 1,
      launchIds: {..._activeProgramLaunchIds(state), nextLaunchId},
    ),
  );
}

ProgramLaunchState finishProgramLaunch({
  required ProgramLaunchState state,
  required int launchId,
}) {
  return switch (state) {
    IdleProgramLaunchState() => state,
    ActiveProgramLaunchState(:final nextLaunchId, :final launchIds) =>
      ProgramLaunchState.active(
        nextLaunchId: nextLaunchId,
        launchIds: launchIds
            .where((candidate) => candidate != launchId)
            .toSet(),
      ),
  };
}

bool isProgramLaunchActive({
  required ProgramLaunchState state,
  required int launchId,
}) {
  return _activeProgramLaunchIds(state).contains(launchId);
}

bool hasActiveProgramLaunches(ProgramLaunchState state) {
  return switch (state) {
    IdleProgramLaunchState() => false,
    ActiveProgramLaunchState() => true,
  };
}

int _nextProgramLaunchId(ProgramLaunchState state) {
  return switch (state) {
    IdleProgramLaunchState(:final nextLaunchId) => nextLaunchId,
    ActiveProgramLaunchState(:final nextLaunchId) => nextLaunchId,
  };
}

Set<int> _activeProgramLaunchIds(ProgramLaunchState state) {
  return switch (state) {
    IdleProgramLaunchState() => Set<int>.unmodifiable(const []),
    ActiveProgramLaunchState(:final launchIds) => launchIds,
  };
}
