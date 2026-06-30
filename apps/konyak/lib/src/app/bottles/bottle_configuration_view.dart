import 'package:flutter/material.dart';

import '../../bottles/bottle_summary.dart';
import '../app_platform.dart';
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
    required this.onRuntimeSettingsChanged,
  });

  final KonyakPlatform platform;
  final RuntimeCapabilitiesState runtimeCapabilitiesState;
  final BottleSummary bottle;
  final RuntimeSettingsControlState runtimeSettingsControlState;
  final RuntimeSettingsChanged? onRuntimeSettingsChanged;

  @override
  Widget build(BuildContext context) {
    final settings = bottle.runtimeSettings;
    final showMacosRuntimeSettings = platform.isMacOS;
    final showLinuxRuntimeSettings = platform.isLinux;
    final canChangeSettings = onRuntimeSettingsChanged != null;
    final hasPendingRuntimeSettingsUpdate = hasPendingRuntimeSettings(
      runtimeSettingsControlState,
    );
    return switch (runtimeCapabilitiesState) {
      LoadingRuntimeCapabilities() => const Center(
        child: SizedBox.square(
          key: ValueKey('bottle-configuration-runtime-loading'),
          dimension: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
      AvailableRuntimeCapabilities() ||
      UnavailableRuntimeCapabilities() => _settingsBody(
        settings: settings,
        showMacosRuntimeSettings: showMacosRuntimeSettings,
        showLinuxRuntimeSettings: showLinuxRuntimeSettings,
        canChangeSettings: canChangeSettings,
        hasPendingRuntimeSettings: hasPendingRuntimeSettingsUpdate,
      ),
    };
  }

  Widget _settingsBody({
    required BottleRuntimeSettingsSummary settings,
    required bool showMacosRuntimeSettings,
    required bool showLinuxRuntimeSettings,
    required bool canChangeSettings,
    required bool hasPendingRuntimeSettings,
  }) {
    final availability = resolveBottleRuntimeControlAvailability(
      platform: platform,
      runtimeCapabilitiesState: runtimeCapabilitiesState,
      canChangeSettings: canChangeSettings,
      hasPendingRuntimeSettings: hasPendingRuntimeSettings,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BottleWineSettingsSection(
            settings: settings,
            availability: availability,
            runtimeSettingsControlState: runtimeSettingsControlState,
            showMacosRuntimeSettings: showMacosRuntimeSettings,
            onChanged: _updateRuntimeSettings,
          ),
          const SizedBox(height: 14),
          BottleGraphicsSettingsSection(
            settings: settings,
            availability: availability,
            runtimeSettingsControlState: runtimeSettingsControlState,
            showMacosRuntimeSettings: showMacosRuntimeSettings,
            showLinuxRuntimeSettings: showLinuxRuntimeSettings,
            onChanged: _updateRuntimeSettings,
          ),
        ],
      ),
    );
  }

  void _updateRuntimeSettings(
    BottleRuntimeSettingsSummary runtimeSettings,
    String controlKey,
  ) {
    onRuntimeSettingsChanged?.call(bottle, runtimeSettings, controlKey);
  }
}
