import 'package:freezed_annotation/freezed_annotation.dart';

part 'runtime_settings_pending_controls_state.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class RuntimeSettingsPendingControlsState
    with _$RuntimeSettingsPendingControlsState {
  const RuntimeSettingsPendingControlsState._();

  const factory RuntimeSettingsPendingControlsState.empty() =
      EmptyRuntimeSettingsPendingControlsState;

  factory RuntimeSettingsPendingControlsState.pending(
    Map<String, String> controls,
  ) {
    return controls.isEmpty
        ? const RuntimeSettingsPendingControlsState.empty()
        : RuntimeSettingsPendingControlsState._pending(
            Map.unmodifiable(controls),
          );
  }

  const factory RuntimeSettingsPendingControlsState._pending(
    Map<String, String> controls,
  ) = PendingRuntimeSettingsPendingControlsState;
}

RuntimeSettingsPendingControlsState startRuntimeSettingsControlUpdate({
  required RuntimeSettingsPendingControlsState state,
  required String bottleId,
  required String controlKey,
}) {
  return hasPendingRuntimeSettingsControl(state: state, bottleId: bottleId)
      ? state
      : RuntimeSettingsPendingControlsState.pending({
          ...runtimeSettingsPendingControlsSnapshot(state),
          bottleId: controlKey,
        });
}

RuntimeSettingsPendingControlsState finishRuntimeSettingsControlUpdate({
  required RuntimeSettingsPendingControlsState state,
  required String bottleId,
}) {
  final controls = runtimeSettingsPendingControlsSnapshot(state);
  return controls.containsKey(bottleId)
      ? RuntimeSettingsPendingControlsState.pending(
          Map.fromEntries(
            controls.entries.where((entry) => entry.key != bottleId),
          ),
        )
      : state;
}

bool hasPendingRuntimeSettingsControl({
  required RuntimeSettingsPendingControlsState state,
  required String bottleId,
}) {
  return switch (state) {
    EmptyRuntimeSettingsPendingControlsState() => false,
    PendingRuntimeSettingsPendingControlsState(:final controls) =>
      controls.containsKey(bottleId),
  };
}

Map<String, String> runtimeSettingsPendingControlsSnapshot(
  RuntimeSettingsPendingControlsState state,
) {
  return switch (state) {
    EmptyRuntimeSettingsPendingControlsState() =>
      Map<String, String>.unmodifiable(const {}),
    PendingRuntimeSettingsPendingControlsState(:final controls) => controls,
  };
}
