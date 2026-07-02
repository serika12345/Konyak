import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/app/app_platform.dart';
import 'package:konyak/src/app/bottles/bottle_configuration_view_model.dart';
import 'package:konyak/src/app/bottles/bottle_runtime_control_availability.dart';
import 'package:konyak/src/app/bottles/runtime_settings_change.dart';
import 'package:konyak/src/app/bottles/runtime_settings_control_state.dart';
import 'package:konyak/src/bottles/bottle_summary.dart';

void main() {
  test('models runtime settings loading explicitly', () {
    final viewModel = bottleConfigurationViewModel(
      platform: KonyakPlatform.macos,
      runtimeCapabilitiesState: const RuntimeCapabilitiesState.loading(),
      bottle: _bottle(id: 'steam', name: 'Steam'),
      runtimeSettingsControlState: const RuntimeSettingsControlState.idle(),
      runtimeSettingsChangeAction:
          const RuntimeSettingsChangeAvailability.unavailable(),
    );

    expect(viewModel, isA<LoadingBottleConfigurationViewModel>());
  });

  test('builds runtime settings controls from platform and action state', () {
    final bottle = _bottle(id: 'steam', name: 'Steam');
    final action = RuntimeSettingsChangeAvailability.available((_, _, _) {});
    final viewModel = bottleConfigurationViewModel(
      platform: KonyakPlatform.linux,
      runtimeCapabilitiesState: const RuntimeCapabilitiesState.unavailable(),
      bottle: bottle,
      runtimeSettingsControlState: const RuntimeSettingsControlState.idle(),
      runtimeSettingsChangeAction: action,
    );

    switch (viewModel) {
      case RuntimeSettingsBottleConfigurationViewModel(
        :final bottle,
        :final showMacosRuntimeSettings,
        :final showLinuxRuntimeSettings,
        :final availability,
        :final runtimeSettingsChangeAction,
      ):
        expect(bottle.id, 'steam');
        expect(showMacosRuntimeSettings, isFalse);
        expect(showLinuxRuntimeSettings, isTrue);
        expect(availability, const BottleRuntimeControlAvailability.disabled());
        expect(runtimeSettingsChangeAction, action);
      case LoadingBottleConfigurationViewModel():
        fail('Unavailable capabilities should still build disabled controls.');
    }
  });

  test('resolves runtime settings dispatch from the current view model', () {
    final bottle = _bottle(id: 'steam', name: 'Steam');
    final changedControlKeys = <String>[];
    final viewModel = bottleConfigurationViewModel(
      platform: KonyakPlatform.macos,
      runtimeCapabilitiesState: const RuntimeCapabilitiesState.unavailable(),
      bottle: bottle,
      runtimeSettingsControlState: const RuntimeSettingsControlState.idle(),
      runtimeSettingsChangeAction: RuntimeSettingsChangeAvailability.available(
        (_, _, controlKey) => changedControlKeys.add(controlKey),
      ),
    );

    final dispatch = switch (viewModel) {
      final RuntimeSettingsBottleConfigurationViewModel viewModel =>
        resolveBottleConfigurationRuntimeSettingsChange(
          viewModel: viewModel,
          runtimeSettings: const BottleRuntimeSettingsSummary(metalHud: true),
          controlKey: 'metal-hud',
        ),
      LoadingBottleConfigurationViewModel() =>
        const RuntimeSettingsChangeDispatch.unavailable(),
    };

    switch (dispatch) {
      case AvailableRuntimeSettingsChangeDispatch(:final invoke):
        invoke();
      case UnavailableRuntimeSettingsChangeDispatch():
        fail('Expected available runtime settings dispatch.');
    }

    expect(changedControlKeys, ['metal-hud']);
  });
}

BottleSummary _bottle({required String id, required String name}) {
  return BottleSummary(
    id: id,
    name: name,
    path: '/bottles/$id',
    windowsVersion: 'win10',
  );
}
