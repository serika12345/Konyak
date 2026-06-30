import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/home_loader/runtime_settings_pending_controls_state.dart';

void main() {
  test('models no pending runtime settings controls explicitly', () {
    const state = RuntimeSettingsPendingControlsState.empty();

    expect(
      hasPendingRuntimeSettingsControl(state: state, bottleId: 'steam'),
      isFalse,
    );
    expect(runtimeSettingsPendingControlsSnapshot(state), isEmpty);
  });

  test('starts and finishes pending runtime settings controls immutably', () {
    final started = startRuntimeSettingsControlUpdate(
      state: const RuntimeSettingsPendingControlsState.empty(),
      bottleId: 'steam',
      controlKey: 'dxvk',
    );

    expect(
      hasPendingRuntimeSettingsControl(state: started, bottleId: 'steam'),
      isTrue,
    );
    expect(runtimeSettingsPendingControlsSnapshot(started), {'steam': 'dxvk'});

    final duplicateStart = startRuntimeSettingsControlUpdate(
      state: started,
      bottleId: 'steam',
      controlKey: 'metal-hud',
    );

    expect(runtimeSettingsPendingControlsSnapshot(duplicateStart), {
      'steam': 'dxvk',
    });

    final secondBottleStarted = startRuntimeSettingsControlUpdate(
      state: duplicateStart,
      bottleId: 'battle-net',
      controlKey: 'esync',
    );

    expect(runtimeSettingsPendingControlsSnapshot(secondBottleStarted), {
      'steam': 'dxvk',
      'battle-net': 'esync',
    });

    final steamFinished = finishRuntimeSettingsControlUpdate(
      state: secondBottleStarted,
      bottleId: 'steam',
    );

    expect(
      hasPendingRuntimeSettingsControl(state: steamFinished, bottleId: 'steam'),
      isFalse,
    );
    expect(runtimeSettingsPendingControlsSnapshot(steamFinished), {
      'battle-net': 'esync',
    });

    final missingBottleFinished = finishRuntimeSettingsControlUpdate(
      state: steamFinished,
      bottleId: 'missing',
    );

    expect(runtimeSettingsPendingControlsSnapshot(missingBottleFinished), {
      'battle-net': 'esync',
    });

    final allFinished = finishRuntimeSettingsControlUpdate(
      state: missingBottleFinished,
      bottleId: 'battle-net',
    );

    expect(runtimeSettingsPendingControlsSnapshot(allFinished), isEmpty);
    switch (allFinished) {
      case EmptyRuntimeSettingsPendingControlsState():
        break;
      case PendingRuntimeSettingsPendingControlsState():
        fail('finishing the final pending control must return empty state');
    }
  });

  test('takes an immutable snapshot of source controls', () {
    final sourceControls = <String, String>{'steam': 'dxvk'};
    final state = RuntimeSettingsPendingControlsState.pending(sourceControls);

    sourceControls['steam'] = 'metal-hud';
    sourceControls['battle-net'] = 'esync';

    expect(runtimeSettingsPendingControlsSnapshot(state), {'steam': 'dxvk'});
    expect(
      runtimeSettingsPendingControlsSnapshot(state).clear,
      throwsUnsupportedError,
    );
  });
}
