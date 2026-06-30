import 'package:flutter/material.dart';

import '../../bottles/bottle_summary.dart';
import '../../l10n/konyak_localizations.dart';
import '../configuration_labels.dart';
import '../widgets/configuration_controls.dart';
import 'bottle_runtime_control_availability.dart';
import 'bottle_runtime_settings_controls.dart';
import 'runtime_settings_control_state.dart';

typedef RuntimeSettingsControlChanged =
    void Function(BottleRuntimeSettingsSummary runtimeSettings, String control);

class BottleWineSettingsSection extends StatelessWidget {
  const BottleWineSettingsSection({
    super.key,
    required this.settings,
    required this.availability,
    required this.runtimeSettingsControlState,
    required this.showMacosRuntimeSettings,
    required this.onChanged,
  });

  final BottleRuntimeSettingsSummary settings;
  final BottleRuntimeControlAvailability availability;
  final RuntimeSettingsControlState runtimeSettingsControlState;
  final bool showMacosRuntimeSettings;
  final RuntimeSettingsControlChanged onChanged;

  @override
  Widget build(BuildContext context) {
    final localizations = KonyakLocalizations.of(context);

    return BottleConfigurationSection(
      title: localizations.wine,
      children: [
        BottleConfigurationRow(
          label: localizations.windowsVersion,
          trailing: ConfigurationDropdown(
            key: const ValueKey('config-windows-version'),
            value: settings.buildVersion.toString(),
            labels: localizedBuildVersionLabels(localizations),
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
            label: localizations.highResolutionMode,
            value: settings.retinaMode,
            isLoading: isRuntimeSettingsControlUpdating(
              state: runtimeSettingsControlState,
              controlKey: runtimeSettingsControlHighResolutionMode,
            ),
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
          label: localizations.windowsDpi,
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
          label: localizations.enhancedSync,
          trailing: ConfigurationDropdown(
            key: const ValueKey('config-enhanced-sync'),
            value: settings.enhancedSync,
            labels: localizedEnhancedSyncLabels(localizations),
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
            label: localizations.advertiseAvxSupport,
            value: settings.avxEnabled,
            isLoading: isRuntimeSettingsControlUpdating(
              state: runtimeSettingsControlState,
              controlKey: runtimeSettingsControlAvxEnabled,
            ),
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
    required this.runtimeSettingsControlState,
    required this.showMacosRuntimeSettings,
    required this.showLinuxRuntimeSettings,
    required this.onChanged,
  });

  final BottleRuntimeSettingsSummary settings;
  final BottleRuntimeControlAvailability availability;
  final RuntimeSettingsControlState runtimeSettingsControlState;
  final bool showMacosRuntimeSettings;
  final bool showLinuxRuntimeSettings;
  final RuntimeSettingsControlChanged onChanged;

  @override
  Widget build(BuildContext context) {
    final localizations = KonyakLocalizations.of(context);
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
      title: localizations.graphics,
      children: [
        BottleConfigurationRow(
          label: localizations.graphicsBackend,
          trailing: ConfigurationDropdown(
            key: const ValueKey('config-graphics-backend'),
            value: graphicsBackend.name,
            labels: _graphicsBackendLabels(
              settings: settings,
              availability: availability,
              showMacosRuntimeSettings: showMacosRuntimeSettings,
              localizations: localizations,
            ),
            onChanged:
                !_canChangeGraphicsBackend(
                  availability: availability,
                  showMacosRuntimeSettings: showMacosRuntimeSettings,
                )
                ? null
                : (value) {
                    _withGraphicsBackendFromValue(
                      value,
                      (nextBackend) => onChanged(
                        settings.withGraphicsBackend(nextBackend),
                        runtimeSettingsControlGraphicsBackend,
                      ),
                    );
                  },
          ),
        ),
        if (showDxvkOptions)
          BottleConfigurationSwitchRow(
            loadingKey: const ValueKey('config-dxvk-async-switch-loading'),
            label: 'DXVK Async',
            value: settings.dxvkAsync,
            isLoading: isRuntimeSettingsControlUpdating(
              state: runtimeSettingsControlState,
              controlKey: runtimeSettingsControlDxvkAsync,
            ),
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
              labels: localizedDxvkHudLabels(localizations),
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
            isLoading: isRuntimeSettingsControlUpdating(
              state: runtimeSettingsControlState,
              controlKey: runtimeSettingsControlVkd3dProton,
            ),
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
            isLoading: isRuntimeSettingsControlUpdating(
              state: runtimeSettingsControlState,
              controlKey: runtimeSettingsControlMetalHud,
            ),
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
            isLoading: isRuntimeSettingsControlUpdating(
              state: runtimeSettingsControlState,
              controlKey: runtimeSettingsControlMetalTrace,
            ),
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
            isLoading: isRuntimeSettingsControlUpdating(
              state: runtimeSettingsControlState,
              controlKey: runtimeSettingsControlDlssMetalFx,
            ),
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
  required KonyakLocalizations localizations,
}) {
  final current = settings.graphicsBackend;
  return <String, String>{
    BottleGraphicsBackend.wineDefault.name: localizations.defaultLabel,
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

void _withGraphicsBackendFromValue(
  String value,
  void Function(BottleGraphicsBackend backend) onParsed,
) {
  switch (value) {
    case 'wineDefault':
      onParsed(BottleGraphicsBackend.wineDefault);
      return;
    case 'dxvk':
      onParsed(BottleGraphicsBackend.dxvk);
      return;
    case 'dxmt':
      onParsed(BottleGraphicsBackend.dxmt);
      return;
    case 'd3dMetal':
      onParsed(BottleGraphicsBackend.d3dMetal);
      return;
    default:
      return;
  }
}
