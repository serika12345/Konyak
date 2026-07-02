import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/app/utils/bottle_lists.dart';
import 'package:konyak/src/bottles/bottle_summary.dart';
import 'package:konyak/src/home_loader/home_bottle_list_state.dart';
import 'package:konyak/src/home_loader/runtime_settings_pending_controls_state.dart';
import 'package:konyak/src/home_loader/runtime_settings_update_state.dart';

void main() {
  test(
    'starts runtime settings updates with an optimistic bottle snapshot',
    () {
      final steam = _bottle(id: 'steam', name: 'Steam');
      final battleNet = _bottle(id: 'battle-net', name: 'Battle.net');
      final started = startRuntimeSettingsUpdate(
        bottleListState: HomeBottleListState.loaded([steam, battleNet]),
        pendingControlsState: RuntimeSettingsPendingControlsState.pending({
          'battle-net': 'dxvk',
        }),
        bottle: steam,
        runtimeSettings: steam.runtimeSettings.withMetalHud(true),
        controlKey: 'metal-hud',
      );

      expect(
        runtimeSettingsPendingControlsSnapshot(started.pendingControlsState),
        {'battle-net': 'dxvk', 'steam': 'metal-hud'},
      );
      expect(_bottleIds(started.bottleListState), ['battle-net', 'steam']);
      expect(
        _bottleById(started.bottleListState, 'steam').runtimeSettings.metalHud,
        isTrue,
      );
    },
  );

  test(
    'finishes runtime settings updates by committing success or reverting',
    () {
      final previous = _bottle(id: 'steam', name: 'Steam');
      final started = startRuntimeSettingsUpdate(
        bottleListState: HomeBottleListState.loaded([previous]),
        pendingControlsState: const RuntimeSettingsPendingControlsState.empty(),
        bottle: previous,
        runtimeSettings: previous.runtimeSettings.withMetalHud(true),
        controlKey: 'metal-hud',
      );
      final persisted = previous.withRuntimeSettings(
        previous.runtimeSettings.withDxrEnabled(true),
      );

      final succeeded = finishSuccessfulRuntimeSettingsUpdate(
        bottleListState: started.bottleListState,
        pendingControlsState: started.pendingControlsState,
        bottle: persisted,
      );

      expect(
        runtimeSettingsPendingControlsSnapshot(succeeded.pendingControlsState),
        isEmpty,
      );
      expect(
        _bottleById(
          succeeded.bottleListState,
          'steam',
        ).runtimeSettings.dxrEnabled,
        isTrue,
      );
      expect(
        _bottleById(
          succeeded.bottleListState,
          'steam',
        ).runtimeSettings.metalHud,
        isFalse,
      );

      final failed = failRuntimeSettingsUpdate(
        bottleListState: started.bottleListState,
        pendingControlsState: started.pendingControlsState,
        previousBottle: previous,
      );

      expect(
        runtimeSettingsPendingControlsSnapshot(failed.pendingControlsState),
        isEmpty,
      );
      expect(
        _bottleById(failed.bottleListState, 'steam').runtimeSettings.metalHud,
        isFalse,
      );
    },
  );
}

List<String> _bottleIds(HomeBottleListState state) {
  return homeBottleListBottles(state).map((bottle) => bottle.id).toList();
}

BottleSummary _bottleById(HomeBottleListState state, String bottleId) {
  return switch (findBottleById(homeBottleListBottles(state), bottleId)) {
    BottleSelectionFound(:final bottle) => bottle,
    BottleSelectionMissing() => throw StateError(
      'missing test bottle $bottleId',
    ),
  };
}

BottleSummary _bottle({required String id, required String name}) {
  return BottleSummary(
    id: id,
    name: name,
    path: '/bottles/$id',
    windowsVersion: 'win10',
  );
}
