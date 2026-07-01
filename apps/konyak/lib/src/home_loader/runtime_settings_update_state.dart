import 'package:freezed_annotation/freezed_annotation.dart';

import '../bottles/bottle_summary.dart';
import 'home_bottle_list_state.dart';
import 'runtime_settings_pending_controls_state.dart';

part 'runtime_settings_update_state.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class RuntimeSettingsUpdateState with _$RuntimeSettingsUpdateState {
  const factory RuntimeSettingsUpdateState({
    required HomeBottleListState bottleListState,
    required RuntimeSettingsPendingControlsState pendingControlsState,
  }) = ResolvedRuntimeSettingsUpdateState;
}

RuntimeSettingsUpdateState startRuntimeSettingsUpdate({
  required HomeBottleListState bottleListState,
  required RuntimeSettingsPendingControlsState pendingControlsState,
  required BottleSummary bottle,
  required BottleRuntimeSettingsSummary runtimeSettings,
  required String controlKey,
}) {
  return RuntimeSettingsUpdateState(
    bottleListState: storeHomeBottle(
      state: bottleListState,
      bottle: bottle.withRuntimeSettings(runtimeSettings),
      mode: const HomeBottleStoreMode.upsert(),
    ),
    pendingControlsState: startRuntimeSettingsControlUpdate(
      state: pendingControlsState,
      bottleId: bottle.id,
      controlKey: controlKey,
    ),
  );
}

RuntimeSettingsUpdateState finishSuccessfulRuntimeSettingsUpdate({
  required HomeBottleListState bottleListState,
  required RuntimeSettingsPendingControlsState pendingControlsState,
  required BottleSummary bottle,
}) {
  return _finishRuntimeSettingsUpdate(
    bottleListState: bottleListState,
    pendingControlsState: pendingControlsState,
    bottle: bottle,
  );
}

RuntimeSettingsUpdateState failRuntimeSettingsUpdate({
  required HomeBottleListState bottleListState,
  required RuntimeSettingsPendingControlsState pendingControlsState,
  required BottleSummary previousBottle,
}) {
  return _finishRuntimeSettingsUpdate(
    bottleListState: bottleListState,
    pendingControlsState: pendingControlsState,
    bottle: previousBottle,
  );
}

RuntimeSettingsUpdateState _finishRuntimeSettingsUpdate({
  required HomeBottleListState bottleListState,
  required RuntimeSettingsPendingControlsState pendingControlsState,
  required BottleSummary bottle,
}) {
  return RuntimeSettingsUpdateState(
    bottleListState: storeHomeBottle(
      state: bottleListState,
      bottle: bottle,
      mode: const HomeBottleStoreMode.upsert(),
    ),
    pendingControlsState: finishRuntimeSettingsControlUpdate(
      state: pendingControlsState,
      bottleId: bottle.id,
    ),
  );
}
