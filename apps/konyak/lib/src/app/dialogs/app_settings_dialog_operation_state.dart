import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings_dialog_operation_state.freezed.dart';

enum AppSettingsDialogOperation {
  savingSettings,
  installingRuntime,
  importingGptkWine,
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class AppSettingsDialogOperationState
    with _$AppSettingsDialogOperationState {
  const AppSettingsDialogOperationState._();

  const factory AppSettingsDialogOperationState.idle() =
      IdleAppSettingsDialogOperations;

  factory AppSettingsDialogOperationState.running(
    Set<AppSettingsDialogOperation> operations,
  ) {
    return operations.isEmpty
        ? const AppSettingsDialogOperationState.idle()
        : AppSettingsDialogOperationState._running(
            Set.unmodifiable(operations),
          );
  }

  const factory AppSettingsDialogOperationState._running(
    Set<AppSettingsDialogOperation> operations,
  ) = RunningAppSettingsDialogOperations;
}

bool isAppSettingsDialogOperationRunning({
  required AppSettingsDialogOperationState state,
  required AppSettingsDialogOperation operation,
}) {
  return switch (state) {
    IdleAppSettingsDialogOperations() => false,
    RunningAppSettingsDialogOperations(:final operations) =>
      operations.contains(operation),
  };
}

AppSettingsDialogOperationState startAppSettingsDialogOperation({
  required AppSettingsDialogOperationState state,
  required AppSettingsDialogOperation operation,
}) {
  return switch (state) {
    IdleAppSettingsDialogOperations() =>
      AppSettingsDialogOperationState.running({operation}),
    RunningAppSettingsDialogOperations(:final operations) =>
      AppSettingsDialogOperationState.running({...operations, operation}),
  };
}

AppSettingsDialogOperationState finishAppSettingsDialogOperation({
  required AppSettingsDialogOperationState state,
  required AppSettingsDialogOperation operation,
}) {
  return switch (state) {
    IdleAppSettingsDialogOperations() => state,
    RunningAppSettingsDialogOperations(:final operations) =>
      AppSettingsDialogOperationState.running(
        operations.where((candidate) => candidate != operation).toSet(),
      ),
  };
}
