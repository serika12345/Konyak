import 'package:freezed_annotation/freezed_annotation.dart';

part 'executable_open_queue_state.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class ExecutableOpenQueueState with _$ExecutableOpenQueueState {
  const ExecutableOpenQueueState._();

  const factory ExecutableOpenQueueState.empty() =
      EmptyExecutableOpenQueueState;

  factory ExecutableOpenQueueState.queued(List<String> programPaths) {
    return programPaths.isEmpty
        ? const ExecutableOpenQueueState.empty()
        : ExecutableOpenQueueState._queued(List.unmodifiable(programPaths));
  }

  const factory ExecutableOpenQueueState._queued(List<String> programPaths) =
      QueuedExecutableOpenQueueState;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class ExecutableOpenQueueDequeueResult
    with _$ExecutableOpenQueueDequeueResult {
  const factory ExecutableOpenQueueDequeueResult.empty({
    required ExecutableOpenQueueState state,
  }) = EmptyExecutableOpenQueue;

  const factory ExecutableOpenQueueDequeueResult.dequeued({
    required String programPath,
    required ExecutableOpenQueueState state,
  }) = DequeuedExecutableOpenPath;
}

ExecutableOpenQueueState enqueueExecutableOpenPaths({
  required ExecutableOpenQueueState state,
  required Iterable<String> paths,
}) {
  final addedPaths = List<String>.unmodifiable(paths);
  return addedPaths.isEmpty
      ? state
      : ExecutableOpenQueueState.queued([
          ..._queuedExecutableOpenPaths(state),
          ...addedPaths,
        ]);
}

ExecutableOpenQueueDequeueResult dequeueExecutableOpenPath(
  ExecutableOpenQueueState state,
) {
  return switch (state) {
    EmptyExecutableOpenQueueState() => ExecutableOpenQueueDequeueResult.empty(
      state: state,
    ),
    QueuedExecutableOpenQueueState(:final programPaths) =>
      ExecutableOpenQueueDequeueResult.dequeued(
        programPath: programPaths.first,
        state: ExecutableOpenQueueState.queued(programPaths.skip(1).toList()),
      ),
  };
}

bool hasPendingExecutableOpenPaths(ExecutableOpenQueueState state) {
  return switch (state) {
    EmptyExecutableOpenQueueState() => false,
    QueuedExecutableOpenQueueState() => true,
  };
}

List<String> _queuedExecutableOpenPaths(ExecutableOpenQueueState state) {
  return switch (state) {
    EmptyExecutableOpenQueueState() => List<String>.unmodifiable(const []),
    QueuedExecutableOpenQueueState(:final programPaths) => programPaths,
  };
}
