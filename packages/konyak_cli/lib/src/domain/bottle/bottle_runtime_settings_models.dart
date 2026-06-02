part of '../../../konyak_cli.dart';

class BottleRuntimeSettings {
  const BottleRuntimeSettings({
    this.enhancedSync = 'msync',
    this.metalHud = false,
    this.metalTrace = false,
    this.avxEnabled = false,
    this.dxrEnabled = false,
    this.dxvk = false,
    this.dxvkAsync = true,
    this.dxvkHud = 'off',
    this.vkd3dProton = false,
    this.buildVersion = 0,
    this.retinaMode = false,
    this.dpiScaling = 96,
  });

  final String enhancedSync;
  final bool metalHud;
  final bool metalTrace;
  final bool avxEnabled;
  final bool dxrEnabled;
  final bool dxvk;
  final bool dxvkAsync;
  final String dxvkHud;
  final bool vkd3dProton;
  final int buildVersion;
  final bool retinaMode;
  final int dpiScaling;

  BottleRuntimeSettings withEnhancedSync(String enhancedSync) {
    return BottleRuntimeSettings(
      enhancedSync: enhancedSync,
      metalHud: metalHud,
      metalTrace: metalTrace,
      avxEnabled: avxEnabled,
      dxrEnabled: dxrEnabled,
      dxvk: dxvk,
      dxvkAsync: dxvkAsync,
      dxvkHud: dxvkHud,
      vkd3dProton: vkd3dProton,
      buildVersion: buildVersion,
      retinaMode: retinaMode,
      dpiScaling: dpiScaling,
    );
  }

  BottleRuntimeSettings withMetalHud(bool metalHud) {
    return BottleRuntimeSettings(
      enhancedSync: enhancedSync,
      metalHud: metalHud,
      metalTrace: metalTrace,
      avxEnabled: avxEnabled,
      dxrEnabled: dxrEnabled,
      dxvk: dxvk,
      dxvkAsync: dxvkAsync,
      dxvkHud: dxvkHud,
      vkd3dProton: vkd3dProton,
      buildVersion: buildVersion,
      retinaMode: retinaMode,
      dpiScaling: dpiScaling,
    );
  }

  BottleRuntimeSettings withMetalTrace(bool metalTrace) {
    return BottleRuntimeSettings(
      enhancedSync: enhancedSync,
      metalHud: metalHud,
      metalTrace: metalTrace,
      avxEnabled: avxEnabled,
      dxrEnabled: dxrEnabled,
      dxvk: dxvk,
      dxvkAsync: dxvkAsync,
      dxvkHud: dxvkHud,
      vkd3dProton: vkd3dProton,
      buildVersion: buildVersion,
      retinaMode: retinaMode,
      dpiScaling: dpiScaling,
    );
  }

  BottleRuntimeSettings withAvxEnabled(bool avxEnabled) {
    return BottleRuntimeSettings(
      enhancedSync: enhancedSync,
      metalHud: metalHud,
      metalTrace: metalTrace,
      avxEnabled: avxEnabled,
      dxrEnabled: dxrEnabled,
      dxvk: dxvk,
      dxvkAsync: dxvkAsync,
      dxvkHud: dxvkHud,
      vkd3dProton: vkd3dProton,
      buildVersion: buildVersion,
      retinaMode: retinaMode,
      dpiScaling: dpiScaling,
    );
  }

  BottleRuntimeSettings withDxrEnabled(bool dxrEnabled) {
    return BottleRuntimeSettings(
      enhancedSync: enhancedSync,
      metalHud: metalHud,
      metalTrace: metalTrace,
      avxEnabled: avxEnabled,
      dxrEnabled: dxrEnabled,
      dxvk: dxvk,
      dxvkAsync: dxvkAsync,
      dxvkHud: dxvkHud,
      vkd3dProton: vkd3dProton,
      buildVersion: buildVersion,
      retinaMode: retinaMode,
      dpiScaling: dpiScaling,
    );
  }

  BottleRuntimeSettings withDxvk(bool dxvk) {
    return BottleRuntimeSettings(
      enhancedSync: enhancedSync,
      metalHud: metalHud,
      metalTrace: metalTrace,
      avxEnabled: avxEnabled,
      dxrEnabled: dxrEnabled,
      dxvk: dxvk,
      dxvkAsync: dxvkAsync,
      dxvkHud: dxvkHud,
      vkd3dProton: vkd3dProton,
      buildVersion: buildVersion,
      retinaMode: retinaMode,
      dpiScaling: dpiScaling,
    );
  }

  BottleRuntimeSettings withDxvkAsync(bool dxvkAsync) {
    return BottleRuntimeSettings(
      enhancedSync: enhancedSync,
      metalHud: metalHud,
      metalTrace: metalTrace,
      avxEnabled: avxEnabled,
      dxrEnabled: dxrEnabled,
      dxvk: dxvk,
      dxvkAsync: dxvkAsync,
      dxvkHud: dxvkHud,
      vkd3dProton: vkd3dProton,
      buildVersion: buildVersion,
      retinaMode: retinaMode,
      dpiScaling: dpiScaling,
    );
  }

  BottleRuntimeSettings withDxvkHud(String dxvkHud) {
    return BottleRuntimeSettings(
      enhancedSync: enhancedSync,
      metalHud: metalHud,
      metalTrace: metalTrace,
      avxEnabled: avxEnabled,
      dxrEnabled: dxrEnabled,
      dxvk: dxvk,
      dxvkAsync: dxvkAsync,
      dxvkHud: dxvkHud,
      vkd3dProton: vkd3dProton,
      buildVersion: buildVersion,
      retinaMode: retinaMode,
      dpiScaling: dpiScaling,
    );
  }

  BottleRuntimeSettings withVkd3dProton(bool vkd3dProton) {
    return BottleRuntimeSettings(
      enhancedSync: enhancedSync,
      metalHud: metalHud,
      metalTrace: metalTrace,
      avxEnabled: avxEnabled,
      dxrEnabled: dxrEnabled,
      dxvk: dxvk,
      dxvkAsync: dxvkAsync,
      dxvkHud: dxvkHud,
      vkd3dProton: vkd3dProton,
      buildVersion: buildVersion,
      retinaMode: retinaMode,
      dpiScaling: dpiScaling,
    );
  }

  BottleRuntimeSettings withBuildVersion(int buildVersion) {
    return BottleRuntimeSettings(
      enhancedSync: enhancedSync,
      metalHud: metalHud,
      metalTrace: metalTrace,
      avxEnabled: avxEnabled,
      dxrEnabled: dxrEnabled,
      dxvk: dxvk,
      dxvkAsync: dxvkAsync,
      dxvkHud: dxvkHud,
      vkd3dProton: vkd3dProton,
      buildVersion: buildVersion,
      retinaMode: retinaMode,
      dpiScaling: dpiScaling,
    );
  }

  BottleRuntimeSettings withRetinaMode(bool retinaMode) {
    return BottleRuntimeSettings(
      enhancedSync: enhancedSync,
      metalHud: metalHud,
      metalTrace: metalTrace,
      avxEnabled: avxEnabled,
      dxrEnabled: dxrEnabled,
      dxvk: dxvk,
      dxvkAsync: dxvkAsync,
      dxvkHud: dxvkHud,
      vkd3dProton: vkd3dProton,
      buildVersion: buildVersion,
      retinaMode: retinaMode,
      dpiScaling: dpiScaling,
    );
  }

  BottleRuntimeSettings withDpiScaling(int dpiScaling) {
    return BottleRuntimeSettings(
      enhancedSync: enhancedSync,
      metalHud: metalHud,
      metalTrace: metalTrace,
      avxEnabled: avxEnabled,
      dxrEnabled: dxrEnabled,
      dxvk: dxvk,
      dxvkAsync: dxvkAsync,
      dxvkHud: dxvkHud,
      vkd3dProton: vkd3dProton,
      buildVersion: buildVersion,
      retinaMode: retinaMode,
      dpiScaling: dpiScaling,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'enhancedSync': enhancedSync,
      'metalHud': metalHud,
      'metalTrace': metalTrace,
      'avxEnabled': avxEnabled,
      'dxrEnabled': dxrEnabled,
      'dxvk': dxvk,
      'dxvkAsync': dxvkAsync,
      'dxvkHud': dxvkHud,
      'vkd3dProton': vkd3dProton,
      'buildVersion': buildVersion,
      'retinaMode': retinaMode,
      'dpiScaling': dpiScaling,
    };
  }

  Map<String, String> macosEnvironmentVariables() {
    final environment = <String, String>{};

    if (dxvk) {
      environment['WINEDLLOVERRIDES'] = 'dxgi,d3d9,d3d10core,d3d11=n,b';
      final hud = switch (dxvkHud) {
        'full' => 'full',
        'partial' => 'devinfo,fps,frametimes',
        'fps' => 'fps',
        _ => null,
      };
      if (hud != null) {
        environment['DXVK_HUD'] = hud;
      }
    }

    if (dxvk && dxvkAsync) {
      environment['DXVK_ASYNC'] = '1';
    }

    switch (enhancedSync) {
      case 'esync':
        environment['WINEESYNC'] = '1';
      case 'msync':
        environment['WINEMSYNC'] = '1';
        environment['WINEESYNC'] = '1';
      case 'none':
        break;
    }

    if (metalHud) {
      environment['MTL_HUD_ENABLED'] = '1';
    }

    if (metalTrace) {
      environment['METAL_CAPTURE_ENABLED'] = '1';
    }

    if (avxEnabled) {
      environment['ROSETTA_ADVERTISE_AVX'] = '1';
    }

    if (dxrEnabled) {
      environment['D3DM_SUPPORT_DXR'] = '1';
    }

    return Map.unmodifiable(environment);
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
      dxvkAsync,
      dxvkHud,
      vkd3dProton,
      buildVersion,
      retinaMode,
      dpiScaling,
    );
  }
}
