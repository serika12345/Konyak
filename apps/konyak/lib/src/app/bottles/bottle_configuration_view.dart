import 'package:flutter/material.dart';

import '../../bottles/bottle_summary.dart';
import '../../runtimes/runtime_summary.dart';
import '../app_platform.dart';
import 'bottle_runtime_control_availability.dart';
import 'bottle_runtime_settings_sections.dart';
import 'runtime_settings_change.dart';

class BottleConfigurationView extends StatelessWidget {
  const BottleConfigurationView({
    super.key,
    required this.platform,
    required this.runtime,
    required this.isRuntimeCapabilitiesLoading,
    required this.bottle,
    required this.pendingRuntimeSettingsControlKey,
    required this.onRuntimeSettingsChanged,
  });

  final KonyakPlatform platform;
  final RuntimeSummary? runtime;
  final bool isRuntimeCapabilitiesLoading;
  final BottleSummary bottle;
  final String? pendingRuntimeSettingsControlKey;
  final RuntimeSettingsChanged? onRuntimeSettingsChanged;

  @override
  Widget build(BuildContext context) {
    final settings = bottle.runtimeSettings;
    final showMacosRuntimeSettings = platform.isMacOS;
    final showLinuxRuntimeSettings = platform.isLinux;
    final canChangeSettings = onRuntimeSettingsChanged != null;
    final hasPendingRuntimeSettings = pendingRuntimeSettingsControlKey != null;
    final availability = resolveBottleRuntimeControlAvailability(
      platform: platform,
      runtime: runtime,
      canChangeSettings: canChangeSettings,
      hasPendingRuntimeSettings: hasPendingRuntimeSettings,
    );

    if (isRuntimeCapabilitiesLoading) {
      return const Center(
        child: SizedBox.square(
          key: ValueKey('bottle-configuration-runtime-loading'),
          dimension: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BottleWineSettingsSection(
            settings: settings,
            availability: availability,
            pendingRuntimeSettingsControlKey: pendingRuntimeSettingsControlKey,
            showMacosRuntimeSettings: showMacosRuntimeSettings,
            onChanged: _updateRuntimeSettings,
          ),
          const SizedBox(height: 14),
          BottleGraphicsSettingsSection(
            settings: settings,
            availability: availability,
            pendingRuntimeSettingsControlKey: pendingRuntimeSettingsControlKey,
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
