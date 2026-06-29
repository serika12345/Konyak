import 'package:freezed_annotation/freezed_annotation.dart';

import '../program/program_run_environment.dart';
import '../shared/domain_value_objects.dart';

part 'bottle_runtime_settings_models.freezed.dart';

@Freezed(map: FreezedMapOptions.none, when: FreezedWhenOptions.none)
abstract class BottleRuntimeSettings with _$BottleRuntimeSettings {
  const BottleRuntimeSettings._();

  factory BottleRuntimeSettings({
    String enhancedSync = 'msync',
    bool metalHud = false,
    bool metalTrace = false,
    bool avxEnabled = false,
    bool dxrEnabled = false,
    bool dxvk = false,
    bool dxmt = false,
    bool dlssMetalFx = false,
    bool dxvkAsync = true,
    String dxvkHud = 'off',
    bool vkd3dProton = false,
    int buildVersion = 0,
    bool retinaMode = false,
    int dpiScaling = 96,
  }) {
    return BottleRuntimeSettings._validated(
      enhancedSync: EnhancedSyncMode(enhancedSync),
      metalHud: metalHud,
      metalTrace: metalTrace,
      avxEnabled: avxEnabled,
      dxrEnabled: dxrEnabled,
      dxvk: dxvk,
      dxmt: dxmt,
      dlssMetalFx: dlssMetalFx,
      dxvkAsync: dxvkAsync,
      dxvkHud: DxvkHudMode(dxvkHud),
      vkd3dProton: vkd3dProton,
      buildVersion: WindowsBuildVersion(buildVersion),
      retinaMode: retinaMode,
      dpiScaling: WindowsDpiScaling(dpiScaling),
    );
  }

  const factory BottleRuntimeSettings._validated({
    required EnhancedSyncMode enhancedSync,
    required bool metalHud,
    required bool metalTrace,
    required bool avxEnabled,
    required bool dxrEnabled,
    required bool dxvk,
    required bool dxmt,
    required bool dlssMetalFx,
    required bool dxvkAsync,
    required DxvkHudMode dxvkHud,
    required bool vkd3dProton,
    required WindowsBuildVersion buildVersion,
    required bool retinaMode,
    required WindowsDpiScaling dpiScaling,
  }) = _BottleRuntimeSettings;

  BottleRuntimeSettings withEnhancedSync(String enhancedSync) {
    return BottleRuntimeSettings(
      enhancedSync: enhancedSync,
      metalHud: metalHud,
      metalTrace: metalTrace,
      avxEnabled: avxEnabled,
      dxrEnabled: dxrEnabled,
      dxvk: dxvk,
      dxmt: dxmt,
      dlssMetalFx: dlssMetalFx,
      dxvkAsync: dxvkAsync,
      dxvkHud: dxvkHud.value,
      vkd3dProton: vkd3dProton,
      buildVersion: buildVersion.value,
      retinaMode: retinaMode,
      dpiScaling: dpiScaling.value,
    );
  }

  BottleRuntimeSettings withMetalHud(bool metalHud) {
    return BottleRuntimeSettings(
      enhancedSync: enhancedSync.value,
      metalHud: metalHud,
      metalTrace: metalTrace,
      avxEnabled: avxEnabled,
      dxrEnabled: dxrEnabled,
      dxvk: dxvk,
      dxmt: dxmt,
      dlssMetalFx: dlssMetalFx,
      dxvkAsync: dxvkAsync,
      dxvkHud: dxvkHud.value,
      vkd3dProton: vkd3dProton,
      buildVersion: buildVersion.value,
      retinaMode: retinaMode,
      dpiScaling: dpiScaling.value,
    );
  }

  BottleRuntimeSettings withMetalTrace(bool metalTrace) {
    return BottleRuntimeSettings(
      enhancedSync: enhancedSync.value,
      metalHud: metalHud,
      metalTrace: metalTrace,
      avxEnabled: avxEnabled,
      dxrEnabled: dxrEnabled,
      dxvk: dxvk,
      dxmt: dxmt,
      dlssMetalFx: dlssMetalFx,
      dxvkAsync: dxvkAsync,
      dxvkHud: dxvkHud.value,
      vkd3dProton: vkd3dProton,
      buildVersion: buildVersion.value,
      retinaMode: retinaMode,
      dpiScaling: dpiScaling.value,
    );
  }

  BottleRuntimeSettings withAvxEnabled(bool avxEnabled) {
    return BottleRuntimeSettings(
      enhancedSync: enhancedSync.value,
      metalHud: metalHud,
      metalTrace: metalTrace,
      avxEnabled: avxEnabled,
      dxrEnabled: dxrEnabled,
      dxvk: dxvk,
      dxmt: dxmt,
      dlssMetalFx: dlssMetalFx,
      dxvkAsync: dxvkAsync,
      dxvkHud: dxvkHud.value,
      vkd3dProton: vkd3dProton,
      buildVersion: buildVersion.value,
      retinaMode: retinaMode,
      dpiScaling: dpiScaling.value,
    );
  }

  BottleRuntimeSettings withDxrEnabled(bool dxrEnabled) {
    return BottleRuntimeSettings(
      enhancedSync: enhancedSync.value,
      metalHud: metalHud,
      metalTrace: metalTrace,
      avxEnabled: avxEnabled,
      dxrEnabled: dxrEnabled,
      dxvk: dxrEnabled ? false : dxvk,
      dxmt: dxrEnabled ? false : dxmt,
      dlssMetalFx: dlssMetalFx,
      dxvkAsync: dxvkAsync,
      dxvkHud: dxvkHud.value,
      vkd3dProton: vkd3dProton,
      buildVersion: buildVersion.value,
      retinaMode: retinaMode,
      dpiScaling: dpiScaling.value,
    );
  }

  BottleRuntimeSettings withDxvk(bool dxvk) {
    return BottleRuntimeSettings(
      enhancedSync: enhancedSync.value,
      metalHud: metalHud,
      metalTrace: metalTrace,
      avxEnabled: avxEnabled,
      dxrEnabled: dxvk ? false : dxrEnabled,
      dxvk: dxvk,
      dxmt: dxvk ? false : dxmt,
      dlssMetalFx: dlssMetalFx,
      dxvkAsync: dxvkAsync,
      dxvkHud: dxvkHud.value,
      vkd3dProton: vkd3dProton,
      buildVersion: buildVersion.value,
      retinaMode: retinaMode,
      dpiScaling: dpiScaling.value,
    );
  }

  BottleRuntimeSettings withDxmt(bool dxmt) {
    return BottleRuntimeSettings(
      enhancedSync: enhancedSync.value,
      metalHud: metalHud,
      metalTrace: metalTrace,
      avxEnabled: avxEnabled,
      dxrEnabled: dxmt ? false : dxrEnabled,
      dxvk: dxmt ? false : dxvk,
      dxmt: dxmt,
      dlssMetalFx: dlssMetalFx,
      dxvkAsync: dxvkAsync,
      dxvkHud: dxvkHud.value,
      vkd3dProton: vkd3dProton,
      buildVersion: buildVersion.value,
      retinaMode: retinaMode,
      dpiScaling: dpiScaling.value,
    );
  }

  BottleRuntimeSettings withDlssMetalFx(bool dlssMetalFx) {
    return BottleRuntimeSettings(
      enhancedSync: enhancedSync.value,
      metalHud: metalHud,
      metalTrace: metalTrace,
      avxEnabled: avxEnabled,
      dxrEnabled: dxrEnabled,
      dxvk: dxvk,
      dxmt: dxmt,
      dlssMetalFx: dlssMetalFx,
      dxvkAsync: dxvkAsync,
      dxvkHud: dxvkHud.value,
      vkd3dProton: vkd3dProton,
      buildVersion: buildVersion.value,
      retinaMode: retinaMode,
      dpiScaling: dpiScaling.value,
    );
  }

  BottleRuntimeSettings withDxvkAsync(bool dxvkAsync) {
    return BottleRuntimeSettings(
      enhancedSync: enhancedSync.value,
      metalHud: metalHud,
      metalTrace: metalTrace,
      avxEnabled: avxEnabled,
      dxrEnabled: dxrEnabled,
      dxvk: dxvk,
      dxmt: dxmt,
      dlssMetalFx: dlssMetalFx,
      dxvkAsync: dxvkAsync,
      dxvkHud: dxvkHud.value,
      vkd3dProton: vkd3dProton,
      buildVersion: buildVersion.value,
      retinaMode: retinaMode,
      dpiScaling: dpiScaling.value,
    );
  }

  BottleRuntimeSettings withDxvkHud(String dxvkHud) {
    return BottleRuntimeSettings(
      enhancedSync: enhancedSync.value,
      metalHud: metalHud,
      metalTrace: metalTrace,
      avxEnabled: avxEnabled,
      dxrEnabled: dxrEnabled,
      dxvk: dxvk,
      dxmt: dxmt,
      dlssMetalFx: dlssMetalFx,
      dxvkAsync: dxvkAsync,
      dxvkHud: dxvkHud,
      vkd3dProton: vkd3dProton,
      buildVersion: buildVersion.value,
      retinaMode: retinaMode,
      dpiScaling: dpiScaling.value,
    );
  }

  BottleRuntimeSettings withVkd3dProton(bool vkd3dProton) {
    return BottleRuntimeSettings(
      enhancedSync: enhancedSync.value,
      metalHud: metalHud,
      metalTrace: metalTrace,
      avxEnabled: avxEnabled,
      dxrEnabled: dxrEnabled,
      dxvk: dxvk,
      dxmt: dxmt,
      dlssMetalFx: dlssMetalFx,
      dxvkAsync: dxvkAsync,
      dxvkHud: dxvkHud.value,
      vkd3dProton: vkd3dProton,
      buildVersion: buildVersion.value,
      retinaMode: retinaMode,
      dpiScaling: dpiScaling.value,
    );
  }

  BottleRuntimeSettings withBuildVersion(int buildVersion) {
    return BottleRuntimeSettings(
      enhancedSync: enhancedSync.value,
      metalHud: metalHud,
      metalTrace: metalTrace,
      avxEnabled: avxEnabled,
      dxrEnabled: dxrEnabled,
      dxvk: dxvk,
      dxmt: dxmt,
      dlssMetalFx: dlssMetalFx,
      dxvkAsync: dxvkAsync,
      dxvkHud: dxvkHud.value,
      vkd3dProton: vkd3dProton,
      buildVersion: buildVersion,
      retinaMode: retinaMode,
      dpiScaling: dpiScaling.value,
    );
  }

  BottleRuntimeSettings withRetinaMode(bool retinaMode) {
    return BottleRuntimeSettings(
      enhancedSync: enhancedSync.value,
      metalHud: metalHud,
      metalTrace: metalTrace,
      avxEnabled: avxEnabled,
      dxrEnabled: dxrEnabled,
      dxvk: dxvk,
      dxmt: dxmt,
      dlssMetalFx: dlssMetalFx,
      dxvkAsync: dxvkAsync,
      dxvkHud: dxvkHud.value,
      vkd3dProton: vkd3dProton,
      buildVersion: buildVersion.value,
      retinaMode: retinaMode,
      dpiScaling: dpiScaling.value,
    );
  }

  BottleRuntimeSettings withHighResolutionModeWindowsDpiAdjustment(
    BottleRuntimeSettings currentRuntimeSettings,
  ) {
    if (retinaMode == currentRuntimeSettings.retinaMode) {
      return this;
    }

    return withDpiScaling(
      _windowsDpiForHighResolutionModeChange(
        currentWindowsDpi: currentRuntimeSettings.dpiScaling.value,
        highResolutionMode: retinaMode,
      ),
    );
  }

  BottleRuntimeSettings withDpiScaling(int dpiScaling) {
    return BottleRuntimeSettings(
      enhancedSync: enhancedSync.value,
      metalHud: metalHud,
      metalTrace: metalTrace,
      avxEnabled: avxEnabled,
      dxrEnabled: dxrEnabled,
      dxvk: dxvk,
      dxmt: dxmt,
      dlssMetalFx: dlssMetalFx,
      dxvkAsync: dxvkAsync,
      dxvkHud: dxvkHud.value,
      vkd3dProton: vkd3dProton,
      buildVersion: buildVersion.value,
      retinaMode: retinaMode,
      dpiScaling: dpiScaling,
    );
  }

  ProgramRunEnvironment macosEnvironment({
    bool enableD3DMetalDlssMetalFx = false,
  }) {
    final entries = <(String, String)>[
      if (dxrEnabled)
        ('WINEDLLOVERRIDES', 'dxgi,d3d11,d3d12,nvapi64,nvngx=n,b')
      else if (dxmt)
        ('WINEDLLOVERRIDES', 'dxgi,d3d10core,d3d11,winemetal=n,b')
      else if (dxvk)
        ('WINEDLLOVERRIDES', 'dxgi,d3d9,d3d10,d3d10_1,d3d10core,d3d11=n,b'),
      if (dxvk) ..._dxvkHudEnvironmentEntries(),
      if (dxvk && dxvkAsync) ('DXVK_ASYNC', '1'),
      if (metalHud) ('MTL_HUD_ENABLED', '1'),
      if (metalTrace) ('METAL_CAPTURE_ENABLED', '1'),
      if (avxEnabled) ('ROSETTA_ADVERTISE_AVX', '1'),
      if (dxrEnabled) ('D3DM_SUPPORT_DXR', '1'),
      if (dlssMetalFx && dxmt && !dxrEnabled)
        (_dxmtEnableNvextEnvironmentKey, '1'),
      if (dlssMetalFx && dxrEnabled && enableD3DMetalDlssMetalFx)
        (_d3dMetalEnableMetalFxEnvironmentKey, '1'),
    ];

    return entries
        .fold(
          const ProgramRunEnvironment.empty(),
          (environment, entry) => environment.add(entry.$1, entry.$2),
        )
        .merge(_wineSyncEnvironment());
  }

  ProgramRunEnvironment linuxEnvironment() {
    final entries = <(String, String)>[
      if (dxvk) ..._dxvkHudEnvironmentEntries(),
      if (dxvk && dxvkAsync) ('DXVK_ASYNC', '1'),
    ];

    return entries
        .fold(
          const ProgramRunEnvironment.empty(),
          (environment, entry) => environment.add(entry.$1, entry.$2),
        )
        .merge(_wineSyncEnvironment());
  }

  List<(String, String)> _dxvkHudEnvironmentEntries() {
    return switch (dxvkHud.value) {
      'full' => const [('DXVK_HUD', 'full')],
      'partial' => const [('DXVK_HUD', 'devinfo,fps,frametimes')],
      'fps' => const [('DXVK_HUD', 'fps')],
      _ => const [],
    };
  }

  ProgramRunEnvironment _wineSyncEnvironment() {
    return switch (enhancedSync.value) {
      'esync' => ProgramRunEnvironment(const {'WINEESYNC': '1'}),
      'msync' => ProgramRunEnvironment(const {'WINEMSYNC': '1'}),
      'none' => const ProgramRunEnvironment.empty(),
      _ => const ProgramRunEnvironment.empty(),
    };
  }
}

// DXMT NVEXT is implemented in dxgi.cpp and documented in DXMT's
// Vendor Extensions wiki:
// https://github.com/3Shain/dxmt/blob/main/src/dxgi/dxgi.cpp
// https://github.com/3Shain/dxmt/wiki/Vendor-Extensions
const _dxmtEnableNvextEnvironmentKey = 'DXMT_ENABLE_NVEXT';

// CrossOver/GPTK D3DMetal DLSS powered by MetalFX references use this signal:
// https://support.codeweavers.com/en_US/advanced-settings-in-crossover-mac-26
const _d3dMetalEnableMetalFxEnvironmentKey = 'D3DM_ENABLE_METALFX';

const _minimumWindowsDpi = 96;
const _maximumWindowsDpi = 480;
const _windowsDpiStep = 24;

int _windowsDpiForHighResolutionModeChange({
  required int currentWindowsDpi,
  required bool highResolutionMode,
}) {
  if (highResolutionMode) {
    final doubled = currentWindowsDpi * 2;
    return doubled > _maximumWindowsDpi ? _maximumWindowsDpi : doubled;
  }

  final halved = currentWindowsDpi ~/ 2;
  final minimumApplied = halved < _minimumWindowsDpi
      ? _minimumWindowsDpi
      : halved;
  final steppedOffset =
      ((minimumApplied - _minimumWindowsDpi) ~/ _windowsDpiStep) *
      _windowsDpiStep;
  return _minimumWindowsDpi + steppedOffset;
}
