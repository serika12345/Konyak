import 'package:flutter/material.dart';

import '../../bottles/bottle_summary.dart';
import '../../runtimes/runtime_summary.dart';
import '../app_platform.dart';
import '../configuration_labels.dart';
import '../widgets/configuration_controls.dart';

class BottleConfigurationView extends StatelessWidget {
  const BottleConfigurationView({
    super.key,
    required this.platform,
    required this.runtime,
    required this.bottle,
    required this.onRuntimeSettingsChanged,
  });

  final KonyakPlatform platform;
  final RuntimeSummary? runtime;
  final BottleSummary bottle;
  final void Function(
    BottleSummary bottle,
    BottleRuntimeSettingsSummary runtimeSettings,
  )?
  onRuntimeSettingsChanged;

  @override
  Widget build(BuildContext context) {
    final settings = bottle.runtimeSettings;
    final showMacosRuntimeSettings = platform.isMacOS;
    final canChangeSettings = onRuntimeSettingsChanged != null;
    final canUseWineRuntime =
        canChangeSettings && runtime?.isInstalled == true && _isStackComplete();
    final canUseDxvk =
        canChangeSettings &&
        (platform.isMacOS
            ? _isRuntimeComponentAvailable('dxvk-macos')
            : _isRuntimeComponentAvailable('dxvk'));
    final canUseMetal =
        canChangeSettings && _isRuntimeComponentAvailable('moltenvk');
    final canUseDxr =
        canChangeSettings && _isRuntimeComponentAvailable('gptk-d3dmetal');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BottleConfigurationSection(
            title: 'Wine',
            children: [
              BottleConfigurationRow(
                label: 'Windows Version',
                trailing: ConfigurationDropdown(
                  key: const ValueKey('config-windows-version'),
                  value: settings.buildVersion.toString(),
                  labels: buildVersionLabels,
                  width: 210,
                  onChanged: !canUseWineRuntime
                      ? null
                      : (value) {
                          _updateRuntimeSettings(
                            settings.copyWith(buildVersion: int.parse(value)),
                          );
                        },
                ),
              ),
              if (showMacosRuntimeSettings)
                BottleConfigurationSwitchRow(
                  switchKey: const ValueKey('config-retina-mode-switch'),
                  label: 'Retina Mode',
                  value: settings.retinaMode,
                  onChanged: !canUseWineRuntime
                      ? null
                      : (value) {
                          _updateRuntimeSettings(
                            settings.copyWith(retinaMode: value),
                          );
                        },
                ),
              BottleConfigurationRow(
                label: 'Enhanced Sync',
                trailing: ConfigurationDropdown(
                  key: const ValueKey('config-enhanced-sync'),
                  value: settings.enhancedSync,
                  labels: enhancedSyncLabels,
                  onChanged: !canUseWineRuntime
                      ? null
                      : (value) {
                          _updateRuntimeSettings(
                            settings.copyWith(enhancedSync: value),
                          );
                        },
                ),
              ),
              BottleConfigurationRow(
                label: 'DPI Scaling',
                trailing: ConfigurationDropdown(
                  key: const ValueKey('config-dpi-scaling'),
                  value: settings.dpiScaling.toString(),
                  labels: dpiScalingLabels,
                  width: 110,
                  onChanged: !canUseWineRuntime
                      ? null
                      : (value) {
                          _updateRuntimeSettings(
                            settings.copyWith(dpiScaling: int.parse(value)),
                          );
                        },
                ),
              ),
              if (showMacosRuntimeSettings)
                BottleConfigurationSwitchRow(
                  label: 'Advertise AVX Support',
                  value: settings.avxEnabled,
                  onChanged: !canUseWineRuntime
                      ? null
                      : (value) {
                          _updateRuntimeSettings(
                            settings.copyWith(avxEnabled: value),
                          );
                        },
                ),
            ],
          ),
          const SizedBox(height: 14),
          BottleConfigurationSection(
            title: 'DXVK',
            children: [
              BottleConfigurationSwitchRow(
                switchKey: const ValueKey('config-dxvk-switch'),
                label: 'DXVK',
                value: settings.dxvk,
                onChanged: !canUseDxvk
                    ? null
                    : (value) {
                        _updateRuntimeSettings(settings.copyWith(dxvk: value));
                      },
              ),
              BottleConfigurationSwitchRow(
                label: 'DXVK Async',
                value: settings.dxvkAsync,
                onChanged: settings.dxvk && canUseDxvk
                    ? (value) {
                        _updateRuntimeSettings(
                          settings.copyWith(dxvkAsync: value),
                        );
                      }
                    : null,
              ),
              BottleConfigurationRow(
                label: 'DXVK HUD',
                trailing: ConfigurationDropdown(
                  value: settings.dxvkHud,
                  labels: dxvkHudLabels,
                  onChanged: settings.dxvk && canUseDxvk
                      ? (value) {
                          _updateRuntimeSettings(
                            settings.copyWith(dxvkHud: value),
                          );
                        }
                      : null,
                ),
              ),
            ],
          ),
          if (platform.isLinux) ...[
            const SizedBox(height: 14),
            const BottleConfigurationSection(
              title: 'Vulkan',
              children: [
                BottleConfigurationRow(
                  label: 'D3D12',
                  trailing: Text('vkd3d-proton'),
                ),
              ],
            ),
          ],
          if (showMacosRuntimeSettings) ...[
            const SizedBox(height: 14),
            BottleConfigurationSection(
              title: 'Metal',
              children: [
                BottleConfigurationSwitchRow(
                  label: 'Metal HUD',
                  value: settings.metalHud,
                  onChanged: !canUseMetal
                      ? null
                      : (value) {
                          _updateRuntimeSettings(
                            settings.copyWith(metalHud: value),
                          );
                        },
                ),
                BottleConfigurationSwitchRow(
                  label: 'Metal Trace',
                  value: settings.metalTrace,
                  onChanged: !canUseMetal
                      ? null
                      : (value) {
                          _updateRuntimeSettings(
                            settings.copyWith(metalTrace: value),
                          );
                        },
                ),
                BottleConfigurationSwitchRow(
                  label: 'DXR',
                  value: settings.dxrEnabled,
                  onChanged: !canUseDxr
                      ? null
                      : (value) {
                          _updateRuntimeSettings(
                            settings.copyWith(dxrEnabled: value),
                          );
                        },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _updateRuntimeSettings(BottleRuntimeSettingsSummary runtimeSettings) {
    onRuntimeSettingsChanged?.call(bottle, runtimeSettings);
  }

  bool _isStackComplete() {
    return runtime?.stack?.isComplete == true;
  }

  bool _isRuntimeComponentAvailable(String componentId) {
    if (runtime?.isInstalled != true) {
      return false;
    }

    final stack = runtime?.stack;
    if (stack == null) {
      return false;
    }

    for (final component in stack.components) {
      if (component.id == componentId) {
        return component.missingPaths.isEmpty;
      }
    }

    return false;
  }
}
