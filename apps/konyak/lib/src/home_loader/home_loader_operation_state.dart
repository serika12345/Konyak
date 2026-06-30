import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_loader_operation_state.freezed.dart';

enum HomeLoaderOperation {
  showingSettings,
  checkingKonyakUpdate,
  handlingExecutableOpen,
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class HomeLoaderOperationState with _$HomeLoaderOperationState {
  const HomeLoaderOperationState._();

  const factory HomeLoaderOperationState.idle() = IdleHomeLoaderOperations;

  factory HomeLoaderOperationState.running(
    Set<HomeLoaderOperation> operations,
  ) {
    return operations.isEmpty
        ? const HomeLoaderOperationState.idle()
        : HomeLoaderOperationState._running(Set.unmodifiable(operations));
  }

  const factory HomeLoaderOperationState._running(
    Set<HomeLoaderOperation> operations,
  ) = RunningHomeLoaderOperations;
}

bool isHomeLoaderOperationRunning({
  required HomeLoaderOperationState state,
  required HomeLoaderOperation operation,
}) {
  return switch (state) {
    IdleHomeLoaderOperations() => false,
    RunningHomeLoaderOperations(:final operations) => operations.contains(
      operation,
    ),
  };
}

HomeLoaderOperationState startHomeLoaderOperation({
  required HomeLoaderOperationState state,
  required HomeLoaderOperation operation,
}) {
  return switch (state) {
    IdleHomeLoaderOperations() => HomeLoaderOperationState.running({operation}),
    RunningHomeLoaderOperations(:final operations) =>
      HomeLoaderOperationState.running({...operations, operation}),
  };
}

HomeLoaderOperationState finishHomeLoaderOperation({
  required HomeLoaderOperationState state,
  required HomeLoaderOperation operation,
}) {
  return switch (state) {
    IdleHomeLoaderOperations() => state,
    RunningHomeLoaderOperations(:final operations) =>
      HomeLoaderOperationState.running(
        operations.where((candidate) => candidate != operation).toSet(),
      ),
  };
}
