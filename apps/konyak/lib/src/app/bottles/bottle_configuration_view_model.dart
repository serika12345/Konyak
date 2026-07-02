import '../../bottles/bottle_summary.dart';
import '../app_platform.dart';
import 'bottle_runtime_control_availability.dart';
import 'runtime_settings_change.dart';
import 'runtime_settings_control_state.dart';

sealed class BottleConfigurationViewModel {
  const BottleConfigurationViewModel();
}

final class LoadingBottleConfigurationViewModel
    extends BottleConfigurationViewModel {
  const LoadingBottleConfigurationViewModel();
}

final class RuntimeSettingsBottleConfigurationViewModel
    extends BottleConfigurationViewModel {
  const RuntimeSettingsBottleConfigurationViewModel({
    required this.bottle,
    required this.settings,
    required this.showMacosRuntimeSettings,
    required this.showLinuxRuntimeSettings,
    required this.availability,
    required this.runtimeSettingsControlState,
    required this.runtimeSettingsChangeAction,
  });

  final BottleSummary bottle;
  final BottleRuntimeSettingsSummary settings;
  final bool showMacosRuntimeSettings;
  final bool showLinuxRuntimeSettings;
  final BottleRuntimeControlAvailability availability;
  final RuntimeSettingsControlState runtimeSettingsControlState;
  final RuntimeSettingsChangeAvailability runtimeSettingsChangeAction;
}

BottleConfigurationViewModel bottleConfigurationViewModel({
  required KonyakPlatform platform,
  required RuntimeCapabilitiesState runtimeCapabilitiesState,
  required BottleSummary bottle,
  required RuntimeSettingsControlState runtimeSettingsControlState,
  required RuntimeSettingsChangeAvailability runtimeSettingsChangeAction,
}) {
  return switch (runtimeCapabilitiesState) {
    LoadingRuntimeCapabilities() => const LoadingBottleConfigurationViewModel(),
    AvailableRuntimeCapabilities() || UnavailableRuntimeCapabilities() =>
      RuntimeSettingsBottleConfigurationViewModel(
        bottle: bottle,
        settings: bottle.runtimeSettings,
        showMacosRuntimeSettings: platform.isMacOS,
        showLinuxRuntimeSettings: platform.isLinux,
        availability: resolveBottleRuntimeControlAvailability(
          platform: platform,
          runtimeCapabilitiesState: runtimeCapabilitiesState,
          canChangeSettings: canChangeRuntimeSettings(
            runtimeSettingsChangeAction,
          ),
          hasPendingRuntimeSettings: hasPendingRuntimeSettings(
            runtimeSettingsControlState,
          ),
        ),
        runtimeSettingsControlState: runtimeSettingsControlState,
        runtimeSettingsChangeAction: runtimeSettingsChangeAction,
      ),
  };
}

RuntimeSettingsChangeDispatch resolveBottleConfigurationRuntimeSettingsChange({
  required RuntimeSettingsBottleConfigurationViewModel viewModel,
  required BottleRuntimeSettingsSummary runtimeSettings,
  required String controlKey,
}) {
  return resolveRuntimeSettingsChange(
    bottle: viewModel.bottle,
    runtimeSettings: runtimeSettings,
    controlKey: controlKey,
    action: viewModel.runtimeSettingsChangeAction,
  );
}
