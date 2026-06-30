import 'package:freezed_annotation/freezed_annotation.dart';

part 'runtime_settings_control_state.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class RuntimeSettingsControlState with _$RuntimeSettingsControlState {
  const factory RuntimeSettingsControlState.idle() = IdleRuntimeSettingsControl;

  const factory RuntimeSettingsControlState.updating(String controlKey) =
      UpdatingRuntimeSettingsControl;
}

bool hasPendingRuntimeSettings(RuntimeSettingsControlState state) {
  return switch (state) {
    IdleRuntimeSettingsControl() => false,
    UpdatingRuntimeSettingsControl() => true,
  };
}

bool isRuntimeSettingsControlUpdating({
  required RuntimeSettingsControlState state,
  required String controlKey,
}) {
  return switch (state) {
    UpdatingRuntimeSettingsControl(controlKey: final pendingControlKey) =>
      pendingControlKey == controlKey,
    IdleRuntimeSettingsControl() => false,
  };
}
