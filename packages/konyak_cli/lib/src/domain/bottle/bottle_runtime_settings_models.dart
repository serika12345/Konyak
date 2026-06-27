part of '../../../konyak_cli.dart';

class BottleRuntimeSettings {
  BottleRuntimeSettings({
    String enhancedSync = 'msync',
    this.metalHud = false,
    this.metalTrace = false,
    this.avxEnabled = false,
    this.dxrEnabled = false,
    this.dxvk = false,
    this.dxmt = false,
    this.dlssMetalFx = false,
    this.dxvkAsync = true,
    String dxvkHud = 'off',
    this.vkd3dProton = false,
    int buildVersion = 0,
    this.retinaMode = false,
    int dpiScaling = 96,
  }) : enhancedSync = EnhancedSyncMode(enhancedSync),
       dxvkHud = DxvkHudMode(dxvkHud),
       buildVersion = WindowsBuildVersion(buildVersion),
       dpiScaling = WindowsDpiScaling(dpiScaling);

  final EnhancedSyncMode enhancedSync;
  final bool metalHud;
  final bool metalTrace;
  final bool avxEnabled;
  final bool dxrEnabled;
  final bool dxvk;
  final bool dxmt;
  final bool dlssMetalFx;
  final bool dxvkAsync;
  final DxvkHudMode dxvkHud;
  final bool vkd3dProton;
  final WindowsBuildVersion buildVersion;
  final bool retinaMode;
  final WindowsDpiScaling dpiScaling;

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

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'enhancedSync': enhancedSync.value,
      'metalHud': metalHud,
      'metalTrace': metalTrace,
      'avxEnabled': avxEnabled,
      'dxrEnabled': dxrEnabled,
      'dxvk': dxvk,
      'dxmt': dxmt,
      'dlssMetalFx': dlssMetalFx,
      'dxvkAsync': dxvkAsync,
      'dxvkHud': dxvkHud.value,
      'vkd3dProton': vkd3dProton,
      'buildVersion': buildVersion.value,
      'retinaMode': retinaMode,
      'dpiScaling': dpiScaling.value,
    };
  }

  ProgramRunEnvironment macosEnvironment({
    bool enableD3DMetalDlssMetalFx = false,
  }) {
    var environment = const ProgramRunEnvironment.empty();

    if (dxrEnabled) {
      environment = environment.add(
        'WINEDLLOVERRIDES',
        'dxgi,d3d11,d3d12,nvapi64,nvngx=n,b',
      );
    } else if (dxmt) {
      environment = environment.add(
        'WINEDLLOVERRIDES',
        'dxgi,d3d10core,d3d11,winemetal=n,b',
      );
    } else if (dxvk) {
      environment = environment.add(
        'WINEDLLOVERRIDES',
        'dxgi,d3d9,d3d10,d3d10_1,d3d10core,d3d11=n,b',
      );
      final hud = switch (dxvkHud.value) {
        'full' => 'full',
        'partial' => 'devinfo,fps,frametimes',
        'fps' => 'fps',
        _ => null,
      };
      if (hud != null) {
        environment = environment.add('DXVK_HUD', hud);
      }
    }

    if (dxvk && dxvkAsync) {
      environment = environment.add('DXVK_ASYNC', '1');
    }

    environment = environment.merge(_wineSyncEnvironment());

    if (metalHud) {
      environment = environment.add('MTL_HUD_ENABLED', '1');
    }

    if (metalTrace) {
      environment = environment.add('METAL_CAPTURE_ENABLED', '1');
    }

    if (avxEnabled) {
      environment = environment.add('ROSETTA_ADVERTISE_AVX', '1');
    }

    if (dxrEnabled) {
      environment = environment.add('D3DM_SUPPORT_DXR', '1');
    }

    if (dlssMetalFx && dxmt && !dxrEnabled) {
      environment = environment.add(_dxmtEnableNvextEnvironmentKey, '1');
    }

    if (dlssMetalFx && dxrEnabled && enableD3DMetalDlssMetalFx) {
      environment = environment.add(_d3dMetalEnableMetalFxEnvironmentKey, '1');
    }

    return environment;
  }

  ProgramRunEnvironment linuxEnvironment() {
    var environment = const ProgramRunEnvironment.empty();

    if (dxvk) {
      final hud = switch (dxvkHud.value) {
        'full' => 'full',
        'partial' => 'devinfo,fps,frametimes',
        'fps' => 'fps',
        _ => null,
      };
      if (hud != null) {
        environment = environment.add('DXVK_HUD', hud);
      }
    }

    if (dxvk && dxvkAsync) {
      environment = environment.add('DXVK_ASYNC', '1');
    }

    environment = environment.merge(_wineSyncEnvironment());

    return environment;
  }

  ProgramRunEnvironment _wineSyncEnvironment() {
    return switch (enhancedSync.value) {
      'esync' => ProgramRunEnvironment(const {'WINEESYNC': '1'}),
      'msync' => ProgramRunEnvironment(const {'WINEMSYNC': '1'}),
      'none' => const ProgramRunEnvironment.empty(),
      _ => const ProgramRunEnvironment.empty(),
    };
  }

  @override
  bool operator ==(Object other) {
    return other is BottleRuntimeSettings &&
        other.enhancedSync == enhancedSync &&
        other.metalHud == metalHud &&
        other.metalTrace == metalTrace &&
        other.avxEnabled == avxEnabled &&
        other.dxrEnabled == dxrEnabled &&
        other.dxvk == dxvk &&
        other.dxmt == dxmt &&
        other.dlssMetalFx == dlssMetalFx &&
        other.dxvkAsync == dxvkAsync &&
        other.dxvkHud == dxvkHud &&
        other.vkd3dProton == vkd3dProton &&
        other.buildVersion == buildVersion &&
        other.retinaMode == retinaMode &&
        other.dpiScaling == dpiScaling;
  }

  @override
  int get hashCode {
    return Object.hash(
      enhancedSync,
      metalHud,
      metalTrace,
      avxEnabled,
      dxrEnabled,
      dxvk,
      dxmt,
      dlssMetalFx,
      dxvkAsync,
      dxvkHud,
      vkd3dProton,
      buildVersion,
      retinaMode,
      dpiScaling,
    );
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
