part of '../konyak_cli.dart';

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

  BottleRuntimeSettings copyWith({
    String? enhancedSync,
    bool? metalHud,
    bool? metalTrace,
    bool? avxEnabled,
    bool? dxrEnabled,
    bool? dxvk,
    bool? dxvkAsync,
    String? dxvkHud,
    bool? vkd3dProton,
    int? buildVersion,
    bool? retinaMode,
    int? dpiScaling,
  }) {
    return BottleRuntimeSettings(
      enhancedSync: enhancedSync ?? this.enhancedSync,
      metalHud: metalHud ?? this.metalHud,
      metalTrace: metalTrace ?? this.metalTrace,
      avxEnabled: avxEnabled ?? this.avxEnabled,
      dxrEnabled: dxrEnabled ?? this.dxrEnabled,
      dxvk: dxvk ?? this.dxvk,
      dxvkAsync: dxvkAsync ?? this.dxvkAsync,
      dxvkHud: dxvkHud ?? this.dxvkHud,
      vkd3dProton: vkd3dProton ?? this.vkd3dProton,
      buildVersion: buildVersion ?? this.buildVersion,
      retinaMode: retinaMode ?? this.retinaMode,
      dpiScaling: dpiScaling ?? this.dpiScaling,
    );
  }

  static BottleRuntimeSettings? fromJson(Object? value) {
    if (value == null) {
      return const BottleRuntimeSettings();
    }

    final settings = _objectMap(value);
    if (settings == null) {
      return null;
    }

    final enhancedSync = _runtimeSettingsString(
      settings,
      'enhancedSync',
      allowedValues: const {'none', 'esync', 'msync'},
      defaultValue: 'msync',
    );
    final metalHud = _runtimeSettingsBool(settings, 'metalHud');
    final metalTrace = _runtimeSettingsBool(settings, 'metalTrace');
    final avxEnabled = _runtimeSettingsBool(settings, 'avxEnabled');
    final dxrEnabled = _runtimeSettingsBool(settings, 'dxrEnabled');
    final dxvk = _runtimeSettingsBool(settings, 'dxvk');
    final dxvkAsync = _runtimeSettingsBool(
      settings,
      'dxvkAsync',
      defaultValue: true,
    );
    final dxvkHud = _runtimeSettingsString(
      settings,
      'dxvkHud',
      allowedValues: const {'full', 'partial', 'fps', 'off'},
      defaultValue: 'off',
    );
    final vkd3dProton = _runtimeSettingsBool(settings, 'vkd3dProton');
    final buildVersion = _runtimeSettingsInt(
      settings,
      'buildVersion',
      defaultValue: 0,
      minimum: 0,
      maximum: 999999,
    );
    final retinaMode = _runtimeSettingsBool(settings, 'retinaMode');
    final dpiScaling = _runtimeSettingsInt(
      settings,
      'dpiScaling',
      defaultValue: 96,
      minimum: 96,
      maximum: 480,
      step: 24,
    );

    if (enhancedSync == null ||
        metalHud == null ||
        metalTrace == null ||
        avxEnabled == null ||
        dxrEnabled == null ||
        dxvk == null ||
        dxvkAsync == null ||
        dxvkHud == null ||
        vkd3dProton == null ||
        buildVersion == null ||
        retinaMode == null ||
        dpiScaling == null) {
      return null;
    }

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

String? _runtimeSettingsString(
  Map<String, Object?> settings,
  String key, {
  required Set<String> allowedValues,
  required String defaultValue,
}) {
  if (!settings.containsKey(key)) {
    return defaultValue;
  }

  final value = settings[key];
  if (value is! String || value.trim().isEmpty) {
    return null;
  }

  return allowedValues.contains(value) ? value : null;
}

bool? _runtimeSettingsBool(
  Map<String, Object?> settings,
  String key, {
  bool defaultValue = false,
}) {
  if (!settings.containsKey(key)) {
    return defaultValue;
  }

  final value = settings[key];
  return value is bool ? value : null;
}

int? _runtimeSettingsInt(
  Map<String, Object?> settings,
  String key, {
  required int defaultValue,
  required int minimum,
  required int maximum,
  int? step,
}) {
  if (!settings.containsKey(key)) {
    return defaultValue;
  }

  final value = settings[key];
  if (value is! int || value < minimum || value > maximum) {
    return null;
  }

  final requiredStep = step;
  if (requiredStep != null && (value - minimum) % requiredStep != 0) {
    return null;
  }

  return value;
}
