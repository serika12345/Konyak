import 'package:flutter/material.dart';

import '../../bottles/bottle_summary.dart';
import '../app_platform.dart';
import 'bottle_configuration_view_model.dart';
import 'bottle_runtime_control_availability.dart';
import 'bottle_runtime_settings_sections.dart';
import 'runtime_settings_change.dart';
import 'runtime_settings_control_state.dart';

class BottleConfigurationView extends StatelessWidget {
  const BottleConfigurationView({
    super.key,
    required this.platform,
    required this.runtimeCapabilitiesState,
    required this.bottle,
    required this.runtimeSettingsControlState,
    required this.runtimeSettingsChangeAction,
  });

  final KonyakPlatform platform;
  final RuntimeCapabilitiesState runtimeCapabilitiesState;
  final BottleSummary bottle;
  final RuntimeSettingsControlState runtimeSettingsControlState;
  final RuntimeSettingsChangeAvailability runtimeSettingsChangeAction;

  @override
  Widget build(BuildContext context) {
    final viewModel = bottleConfigurationViewModel(
      platform: platform,
      runtimeCapabilitiesState: runtimeCapabilitiesState,
      bottle: bottle,
      runtimeSettingsControlState: runtimeSettingsControlState,
      runtimeSettingsChangeAction: runtimeSettingsChangeAction,
    );
    return switch (viewModel) {
      LoadingBottleConfigurationViewModel() => const Center(
        child: SizedBox.square(
          key: ValueKey('bottle-configuration-runtime-loading'),
          dimension: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
      final RuntimeSettingsBottleConfigurationViewModel viewModel =>
        _settingsBody(viewModel),
    };
  }

  Widget _settingsBody(RuntimeSettingsBottleConfigurationViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BottleWineSettingsSection(
            settings: viewModel.settings,
            availability: viewModel.availability,
            runtimeSettingsControlState: viewModel.runtimeSettingsControlState,
            showMacosRuntimeSettings: viewModel.showMacosRuntimeSettings,
            onChanged: (runtimeSettings, controlKey) {
              _updateRuntimeSettings(viewModel, runtimeSettings, controlKey);
            },
          ),
          const SizedBox(height: 14),
          BottleGraphicsSettingsSection(
            settings: viewModel.settings,
            availability: viewModel.availability,
            runtimeSettingsControlState: viewModel.runtimeSettingsControlState,
            showMacosRuntimeSettings: viewModel.showMacosRuntimeSettings,
            showLinuxRuntimeSettings: viewModel.showLinuxRuntimeSettings,
            onChanged: (runtimeSettings, controlKey) {
              _updateRuntimeSettings(viewModel, runtimeSettings, controlKey);
            },
          ),
        ],
      ),
    );
  }

  void _updateRuntimeSettings(
    RuntimeSettingsBottleConfigurationViewModel viewModel,
    BottleRuntimeSettingsSummary runtimeSettings,
    String controlKey,
  ) {
    final dispatch = resolveBottleConfigurationRuntimeSettingsChange(
      viewModel: viewModel,
      runtimeSettings: runtimeSettings,
      controlKey: controlKey,
    );

    switch (dispatch) {
      case AvailableRuntimeSettingsChangeDispatch(:final invoke):
        invoke();
      case UnavailableRuntimeSettingsChangeDispatch():
        return;
    }
  }
}
