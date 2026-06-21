import 'package:flutter/material.dart';

import '../../bottles/bottle_summary.dart';
import '../configuration_labels.dart';
import '../widgets/configuration_controls.dart';
import 'bottle_runtime_control_availability.dart';
import 'bottle_runtime_settings_controls.dart';

typedef RuntimeSettingsControlChanged =
    void Function(BottleRuntimeSettingsSummary runtimeSettings, String control);

class BottleWineSettingsSection extends StatelessWidget {
  const BottleWineSettingsSection({
    super.key,
    required this.settings,
    required this.availability,
    required this.pendingRuntimeSettingsControlKey,
    required this.showMacosRuntimeSettings,
    required this.onChanged,
  });

  final BottleRuntimeSettingsSummary settings;
  final BottleRuntimeControlAvailability availability;
  final String? pendingRuntimeSettingsControlKey;
  final bool showMacosRuntimeSettings;
  final RuntimeSettingsControlChanged onChanged;

  @override
  Widget build(BuildContext context) {
    return BottleConfigurationSection(
      title: 'Wine',
      children: [
        BottleConfigurationRow(
          label: 'Windows Version',
          trailing: ConfigurationDropdown(
            key: const ValueKey('config-windows-version'),
            value: settings.buildVersion.toString(),
            labels: buildVersionLabels,
            width: 210,
            onChanged: !availability.canUseWineRuntime
                ? null
                : (value) {
                    onChanged(
                      settings.withBuildVersion(int.parse(value)),
                      runtimeSettingsControlBuildVersion,
                    );
                  },
          ),
        ),
        if (showMacosRuntimeSettings)
          BottleConfigurationSwitchRow(
            switchKey: const ValueKey('config-retina-mode-switch'),
            loadingKey: const ValueKey('config-retina-mode-switch-loading'),
            label: 'High Resolution Mode',
            value: settings.retinaMode,
            isLoading:
                pendingRuntimeSettingsControlKey ==
                runtimeSettingsControlHighResolutionMode,
            onChanged: !availability.canUseWineRuntime
                ? null
                : (value) {
                    onChanged(
                      settings.withHighResolutionMode(value),
                      runtimeSettingsControlHighResolutionMode,
                    );
                  },
          ),
        BottleConfigurationRow(
          label: 'Windows DPI',
          trailing: ConfigurationDropdown(
            key: const ValueKey('config-dpi-scaling'),
            value: settings.dpiScaling.toString(),
            labels: dpiScalingLabels,
            width: 110,
            onChanged: !availability.canUseWineRuntime
                ? null
                : (value) {
                    onChanged(
                      settings.withDpiScaling(int.parse(value)),
                      runtimeSettingsControlWindowsDpi,
                    );
                  },
          ),
        ),
        BottleConfigurationRow(
          label: 'Enhanced Sync',
          trailing: ConfigurationDropdown(
            key: const ValueKey('config-enhanced-sync'),
            value: settings.enhancedSync,
            labels: enhancedSyncLabels,
            onChanged: !availability.canUseWineRuntime
                ? null
                : (value) {
                    onChanged(
                      settings.withEnhancedSync(value),
                      runtimeSettingsControlEnhancedSync,
                    );
                  },
          ),
        ),
        if (showMacosRuntimeSettings)
          BottleConfigurationSwitchRow(
            loadingKey: const ValueKey('config-avx-switch-loading'),
            label: 'Advertise AVX Support',
            value: settings.avxEnabled,
            isLoading:
                pendingRuntimeSettingsControlKey ==
                runtimeSettingsControlAvxEnabled,
            onChanged: !availability.canUseWineRuntime
                ? null
                : (value) {
                    onChanged(
                      settings.withAvxEnabled(value),
                      runtimeSettingsControlAvxEnabled,
                    );
                  },
          ),
      ],
    );
  }
}

class BottleDxvkSettingsSection extends StatelessWidget {
  const BottleDxvkSettingsSection({
    super.key,
    required this.settings,
    required this.availability,
    required this.pendingRuntimeSettingsControlKey,
    required this.onChanged,
  });

  final BottleRuntimeSettingsSummary settings;
  final BottleRuntimeControlAvailability availability;
  final String? pendingRuntimeSettingsControlKey;
  final RuntimeSettingsControlChanged onChanged;

  @override
  Widget build(BuildContext context) {
    return BottleConfigurationSection(
      title: 'DXVK',
      children: [
        BottleConfigurationSwitchRow(
          switchKey: const ValueKey('config-dxvk-switch'),
          loadingKey: const ValueKey('config-dxvk-switch-loading'),
          label: 'DXVK',
          value: settings.dxvk,
          isLoading:
              pendingRuntimeSettingsControlKey == runtimeSettingsControlDxvk,
          onChanged: !availability.canUseDxvk
              ? null
              : (value) {
                  onChanged(
                    settings.withDxvk(value),
                    runtimeSettingsControlDxvk,
                  );
                },
        ),
        BottleConfigurationSwitchRow(
          loadingKey: const ValueKey('config-dxvk-async-switch-loading'),
          label: 'DXVK Async',
          value: settings.dxvkAsync,
          isLoading:
              pendingRuntimeSettingsControlKey ==
              runtimeSettingsControlDxvkAsync,
          onChanged: settings.dxvk && availability.canUseDxvk
              ? (value) {
                  onChanged(
                    settings.withDxvkAsync(value),
                    runtimeSettingsControlDxvkAsync,
                  );
                }
              : null,
        ),
        BottleConfigurationRow(
          label: 'DXVK HUD',
          trailing: ConfigurationDropdown(
            value: settings.dxvkHud,
            labels: dxvkHudLabels,
            onChanged: settings.dxvk && availability.canUseDxvk
                ? (value) {
                    onChanged(
                      settings.withDxvkHud(value),
                      runtimeSettingsControlDxvkHud,
                    );
                  }
                : null,
          ),
        ),
      ],
    );
  }
}

class BottleVulkanSettingsSection extends StatelessWidget {
  const BottleVulkanSettingsSection({
    super.key,
    required this.settings,
    required this.availability,
    required this.pendingRuntimeSettingsControlKey,
    required this.onChanged,
  });

  final BottleRuntimeSettingsSummary settings;
  final BottleRuntimeControlAvailability availability;
  final String? pendingRuntimeSettingsControlKey;
  final RuntimeSettingsControlChanged onChanged;

  @override
  Widget build(BuildContext context) {
    return BottleConfigurationSection(
      title: 'Vulkan',
      children: [
        BottleConfigurationSwitchRow(
          switchKey: const ValueKey('config-vkd3d-proton-switch'),
          loadingKey: const ValueKey('config-vkd3d-proton-switch-loading'),
          label: 'vkd3d-proton',
          value: settings.vkd3dProton,
          isLoading:
              pendingRuntimeSettingsControlKey ==
              runtimeSettingsControlVkd3dProton,
          onChanged: !availability.canUseVkd3dProton
              ? null
              : (value) {
                  onChanged(
                    settings.withVkd3dProton(value),
                    runtimeSettingsControlVkd3dProton,
                  );
                },
        ),
      ],
    );
  }
}

class BottleMetalSettingsSection extends StatelessWidget {
  const BottleMetalSettingsSection({
    super.key,
    required this.settings,
    required this.availability,
    required this.pendingRuntimeSettingsControlKey,
    required this.onChanged,
  });

  final BottleRuntimeSettingsSummary settings;
  final BottleRuntimeControlAvailability availability;
  final String? pendingRuntimeSettingsControlKey;
  final RuntimeSettingsControlChanged onChanged;

  @override
  Widget build(BuildContext context) {
    return BottleConfigurationSection(
      title: 'Metal',
      children: [
        BottleConfigurationSwitchRow(
          switchKey: const ValueKey('config-dxmt-switch'),
          loadingKey: const ValueKey('config-dxmt-switch-loading'),
          label: 'DXMT',
          value: settings.dxmt,
          isLoading:
              pendingRuntimeSettingsControlKey == runtimeSettingsControlDxmt,
          onChanged: !availability.canUseDxmt
              ? null
              : (value) {
                  onChanged(
                    settings.withDxmt(value),
                    runtimeSettingsControlDxmt,
                  );
                },
        ),
        BottleConfigurationSwitchRow(
          loadingKey: const ValueKey('config-metal-hud-switch-loading'),
          label: 'Metal HUD',
          value: settings.metalHud,
          isLoading:
              pendingRuntimeSettingsControlKey ==
              runtimeSettingsControlMetalHud,
          onChanged: !availability.canUseMetal
              ? null
              : (value) {
                  onChanged(
                    settings.withMetalHud(value),
                    runtimeSettingsControlMetalHud,
                  );
                },
        ),
        BottleConfigurationSwitchRow(
          loadingKey: const ValueKey('config-metal-trace-switch-loading'),
          label: 'Metal Trace',
          value: settings.metalTrace,
          isLoading:
              pendingRuntimeSettingsControlKey ==
              runtimeSettingsControlMetalTrace,
          onChanged: !availability.canUseMetal
              ? null
              : (value) {
                  onChanged(
                    settings.withMetalTrace(value),
                    runtimeSettingsControlMetalTrace,
                  );
                },
        ),
        BottleConfigurationSwitchRow(
          loadingKey: const ValueKey('config-dxr-switch-loading'),
          label: 'DXR',
          value: settings.dxrEnabled,
          isLoading:
              pendingRuntimeSettingsControlKey ==
              runtimeSettingsControlDxrEnabled,
          onChanged: !availability.canUseDxr
              ? null
              : (value) {
                  onChanged(
                    settings.withDxrEnabled(value),
                    runtimeSettingsControlDxrEnabled,
                  );
                },
        ),
      ],
    );
  }
}
