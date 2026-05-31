import 'package:flutter/material.dart';

import '../../bottles/bottle_summary.dart';
import '../../runtimes/runtime_summary.dart';
import '../app_platform.dart';
import '../configuration_labels.dart';
import '../widgets/configuration_controls.dart';
import 'runtime_settings_change.dart';

const runtimeSettingsControlRetinaMode = 'retinaMode';
const runtimeSettingsControlBuildVersion = 'buildVersion';
const runtimeSettingsControlEnhancedSync = 'enhancedSync';
const runtimeSettingsControlDpiScaling = 'dpiScaling';
const runtimeSettingsControlAvxEnabled = 'avxEnabled';
const runtimeSettingsControlDxvk = 'dxvk';
const runtimeSettingsControlDxvkAsync = 'dxvkAsync';
const runtimeSettingsControlDxvkHud = 'dxvkHud';
const runtimeSettingsControlMetalHud = 'metalHud';
const runtimeSettingsControlMetalTrace = 'metalTrace';
const runtimeSettingsControlDxrEnabled = 'dxrEnabled';

class BottleConfigurationView extends StatelessWidget {
  const BottleConfigurationView({
    super.key,
    required this.platform,
    required this.runtime,
    required this.bottle,
    required this.pendingRuntimeSettingsControlKey,
    required this.onRuntimeSettingsChanged,
  });

  final KonyakPlatform platform;
  final RuntimeSummary? runtime;
  final BottleSummary bottle;
  final String? pendingRuntimeSettingsControlKey;
  final RuntimeSettingsChanged? onRuntimeSettingsChanged;

  @override
  Widget build(BuildContext context) {
    final settings = bottle.runtimeSettings;
    final showMacosRuntimeSettings = platform.isMacOS;
    final canChangeSettings = onRuntimeSettingsChanged != null;
    final hasPendingRuntimeSettings = pendingRuntimeSettingsControlKey != null;
    final canUseWineRuntime =
        canChangeSettings &&
        !hasPendingRuntimeSettings &&
        runtime?.isInstalled == true &&
        _isStackComplete();
    final canUseDxvk =
        canChangeSettings &&
        !hasPendingRuntimeSettings &&
        (platform.isMacOS
            ? _isRuntimeComponentAvailable('dxvk-macos')
            : _isRuntimeComponentAvailable('dxvk'));
    final canUseMetal =
        canChangeSettings &&
        !hasPendingRuntimeSettings &&
        _isRuntimeComponentAvailable('moltenvk');
    final canUseDxr =
        canChangeSettings &&
        !hasPendingRuntimeSettings &&
        _isRuntimeComponentAvailable('gptk-d3dmetal');

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
                            runtimeSettingsControlBuildVersion,
                          );
                        },
                ),
              ),
              if (showMacosRuntimeSettings)
                BottleConfigurationSwitchRow(
                  switchKey: const ValueKey('config-retina-mode-switch'),
                  loadingKey: const ValueKey(
                    'config-retina-mode-switch-loading',
                  ),
                  label: 'Retina Mode',
                  value: settings.retinaMode,
                  isLoading:
                      pendingRuntimeSettingsControlKey ==
                      runtimeSettingsControlRetinaMode,
                  onChanged: !canUseWineRuntime
                      ? null
                      : (value) {
                          _updateRuntimeSettings(
                            settings.copyWith(retinaMode: value),
                            runtimeSettingsControlRetinaMode,
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
                            runtimeSettingsControlEnhancedSync,
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
                            runtimeSettingsControlDpiScaling,
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
                  onChanged: !canUseWineRuntime
                      ? null
                      : (value) {
                          _updateRuntimeSettings(
                            settings.copyWith(avxEnabled: value),
                            runtimeSettingsControlAvxEnabled,
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
                loadingKey: const ValueKey('config-dxvk-switch-loading'),
                label: 'DXVK',
                value: settings.dxvk,
                isLoading:
                    pendingRuntimeSettingsControlKey ==
                    runtimeSettingsControlDxvk,
                onChanged: !canUseDxvk
                    ? null
                    : (value) {
                        _updateRuntimeSettings(
                          settings.copyWith(dxvk: value),
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
                onChanged: settings.dxvk && canUseDxvk
                    ? (value) {
                        _updateRuntimeSettings(
                          settings.copyWith(dxvkAsync: value),
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
                  onChanged: settings.dxvk && canUseDxvk
                      ? (value) {
                          _updateRuntimeSettings(
                            settings.copyWith(dxvkHud: value),
                            runtimeSettingsControlDxvkHud,
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
                  loadingKey: const ValueKey('config-metal-hud-switch-loading'),
                  label: 'Metal HUD',
                  value: settings.metalHud,
                  isLoading:
                      pendingRuntimeSettingsControlKey ==
                      runtimeSettingsControlMetalHud,
                  onChanged: !canUseMetal
                      ? null
                      : (value) {
                          _updateRuntimeSettings(
                            settings.copyWith(metalHud: value),
                            runtimeSettingsControlMetalHud,
                          );
                        },
                ),
                BottleConfigurationSwitchRow(
                  loadingKey: const ValueKey(
                    'config-metal-trace-switch-loading',
                  ),
                  label: 'Metal Trace',
                  value: settings.metalTrace,
                  isLoading:
                      pendingRuntimeSettingsControlKey ==
                      runtimeSettingsControlMetalTrace,
                  onChanged: !canUseMetal
                      ? null
                      : (value) {
                          _updateRuntimeSettings(
                            settings.copyWith(metalTrace: value),
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
                  onChanged: !canUseDxr
                      ? null
                      : (value) {
                          _updateRuntimeSettings(
                            settings.copyWith(dxrEnabled: value),
                            runtimeSettingsControlDxrEnabled,
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

  void _updateRuntimeSettings(
    BottleRuntimeSettingsSummary runtimeSettings,
    String controlKey,
  ) {
    onRuntimeSettingsChanged?.call(bottle, runtimeSettings, controlKey);
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
