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

class BottleGraphicsSettingsSection extends StatelessWidget {
  const BottleGraphicsSettingsSection({
    super.key,
    required this.settings,
    required this.availability,
    required this.pendingRuntimeSettingsControlKey,
    required this.showMacosRuntimeSettings,
    required this.showLinuxRuntimeSettings,
    required this.onChanged,
  });

  final BottleRuntimeSettingsSummary settings;
  final BottleRuntimeControlAvailability availability;
  final String? pendingRuntimeSettingsControlKey;
  final bool showMacosRuntimeSettings;
  final bool showLinuxRuntimeSettings;
  final RuntimeSettingsControlChanged onChanged;

  @override
  Widget build(BuildContext context) {
    final graphicsBackend = settings.graphicsBackend;
    final showDxvkOptions = graphicsBackend == BottleGraphicsBackend.dxvk;
    final showMetalOptions =
        showMacosRuntimeSettings &&
        (graphicsBackend == BottleGraphicsBackend.dxmt ||
            graphicsBackend == BottleGraphicsBackend.d3dMetal);
    final canUseDlssMetalFx = switch (graphicsBackend) {
      BottleGraphicsBackend.dxmt => availability.canUseDxmtDlssMetalFx,
      BottleGraphicsBackend.d3dMetal => availability.canUseD3DMetalDlssMetalFx,
      BottleGraphicsBackend.wineDefault || BottleGraphicsBackend.dxvk => false,
    };

    return BottleConfigurationSection(
      title: 'Graphics',
      children: [
        BottleConfigurationRow(
          label: 'Graphics Backend',
          trailing: ConfigurationDropdown(
            key: const ValueKey('config-graphics-backend'),
            value: graphicsBackend.name,
            labels: _graphicsBackendLabels(
              settings: settings,
              availability: availability,
              showMacosRuntimeSettings: showMacosRuntimeSettings,
            ),
            onChanged:
                !_canChangeGraphicsBackend(
                  availability: availability,
                  showMacosRuntimeSettings: showMacosRuntimeSettings,
                )
                ? null
                : (value) {
                    final nextBackend = _graphicsBackendFromValue(value);
                    if (nextBackend == null) {
                      return;
                    }
                    onChanged(
                      settings.withGraphicsBackend(nextBackend),
                      runtimeSettingsControlGraphicsBackend,
                    );
                  },
          ),
        ),
        if (showDxvkOptions)
          BottleConfigurationSwitchRow(
            loadingKey: const ValueKey('config-dxvk-async-switch-loading'),
            label: 'DXVK Async',
            value: settings.dxvkAsync,
            isLoading:
                pendingRuntimeSettingsControlKey ==
                runtimeSettingsControlDxvkAsync,
            onChanged: availability.canUseDxvk
                ? (value) {
                    onChanged(
                      settings.withDxvkAsync(value),
                      runtimeSettingsControlDxvkAsync,
                    );
                  }
                : null,
          ),
        if (showDxvkOptions)
          BottleConfigurationRow(
            label: 'DXVK HUD',
            trailing: ConfigurationDropdown(
              value: settings.dxvkHud,
              labels: dxvkHudLabels,
              onChanged: availability.canUseDxvk
                  ? (value) {
                      onChanged(
                        settings.withDxvkHud(value),
                        runtimeSettingsControlDxvkHud,
                      );
                    }
                  : null,
            ),
          ),
        if (showLinuxRuntimeSettings)
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
        if (showMetalOptions)
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
        if (showMetalOptions)
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
        if (showMetalOptions)
          BottleConfigurationSwitchRow(
            switchKey: const ValueKey('config-dlss-metalfx-switch'),
            loadingKey: const ValueKey('config-dlss-metalfx-switch-loading'),
            label: 'DLSS / MetalFX',
            value: settings.dlssMetalFx,
            isLoading:
                pendingRuntimeSettingsControlKey ==
                runtimeSettingsControlDlssMetalFx,
            onChanged: !canUseDlssMetalFx
                ? null
                : (value) {
                    onChanged(
                      settings.withDlssMetalFx(value),
                      runtimeSettingsControlDlssMetalFx,
                    );
                  },
          ),
      ],
    );
  }
}

Map<String, String> _graphicsBackendLabels({
  required BottleRuntimeSettingsSummary settings,
  required BottleRuntimeControlAvailability availability,
  required bool showMacosRuntimeSettings,
}) {
  final current = settings.graphicsBackend;
  return <String, String>{
    BottleGraphicsBackend.wineDefault.name: 'Default',
    if (availability.canUseDxvk || current == BottleGraphicsBackend.dxvk)
      BottleGraphicsBackend.dxvk.name: showMacosRuntimeSettings
          ? 'DXVK-macOS'
          : 'DXVK',
    if (showMacosRuntimeSettings &&
        (availability.canUseDxmt || current == BottleGraphicsBackend.dxmt))
      BottleGraphicsBackend.dxmt.name: 'DXMT',
    if (showMacosRuntimeSettings &&
        (availability.canUseDxr || current == BottleGraphicsBackend.d3dMetal))
      BottleGraphicsBackend.d3dMetal.name: 'GPTK/D3DMetal',
  };
}

bool _canChangeGraphicsBackend({
  required BottleRuntimeControlAvailability availability,
  required bool showMacosRuntimeSettings,
}) {
  return availability.canUseDxvk ||
      (showMacosRuntimeSettings &&
          (availability.canUseDxmt || availability.canUseDxr));
}

BottleGraphicsBackend? _graphicsBackendFromValue(String value) {
  return switch (value) {
    'wineDefault' => BottleGraphicsBackend.wineDefault,
    'dxvk' => BottleGraphicsBackend.dxvk,
    'dxmt' => BottleGraphicsBackend.dxmt,
    'd3dMetal' => BottleGraphicsBackend.d3dMetal,
    _ => null,
  };
}
