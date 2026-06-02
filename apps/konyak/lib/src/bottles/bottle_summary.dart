class BottleSummary {
  BottleSummary({
    required this.id,
    required this.name,
    required this.path,
    required this.windowsVersion,
    this.runtimeSettings = const BottleRuntimeSettingsSummary(),
    List<PinnedProgramSummary> pinnedPrograms = const <PinnedProgramSummary>[],
  }) : pinnedPrograms = List.unmodifiable(pinnedPrograms);

  final String id;
  final String name;
  final String path;
  final String windowsVersion;
  final BottleRuntimeSettingsSummary runtimeSettings;
  final List<PinnedProgramSummary> pinnedPrograms;
}

class BottleRuntimeSettingsSummary {
  const BottleRuntimeSettingsSummary({
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

  BottleRuntimeSettingsSummary withEnhancedSync(String enhancedSync) {
    return BottleRuntimeSettingsSummary(
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

  BottleRuntimeSettingsSummary withMetalHud(bool metalHud) {
    return BottleRuntimeSettingsSummary(
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

  BottleRuntimeSettingsSummary withMetalTrace(bool metalTrace) {
    return BottleRuntimeSettingsSummary(
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

  BottleRuntimeSettingsSummary withAvxEnabled(bool avxEnabled) {
    return BottleRuntimeSettingsSummary(
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

  BottleRuntimeSettingsSummary withDxrEnabled(bool dxrEnabled) {
    return BottleRuntimeSettingsSummary(
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

  BottleRuntimeSettingsSummary withDxvk(bool dxvk) {
    return BottleRuntimeSettingsSummary(
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

  BottleRuntimeSettingsSummary withDxvkAsync(bool dxvkAsync) {
    return BottleRuntimeSettingsSummary(
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

  BottleRuntimeSettingsSummary withDxvkHud(String dxvkHud) {
    return BottleRuntimeSettingsSummary(
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

  BottleRuntimeSettingsSummary withVkd3dProton(bool vkd3dProton) {
    return BottleRuntimeSettingsSummary(
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

  BottleRuntimeSettingsSummary withBuildVersion(int buildVersion) {
    return BottleRuntimeSettingsSummary(
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

  BottleRuntimeSettingsSummary withRetinaMode(bool retinaMode) {
    return BottleRuntimeSettingsSummary(
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

  BottleRuntimeSettingsSummary withDpiScaling(int dpiScaling) {
    return BottleRuntimeSettingsSummary(
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
}

class PinnedProgramSummary {
  const PinnedProgramSummary({
    required this.name,
    required this.path,
    required this.removable,
    this.iconPath,
  });

  final String name;
  final String path;
  final bool removable;
  final String? iconPath;
}

class ProgramSettingsSummary {
  ProgramSettingsSummary({
    this.locale = '',
    this.arguments = '',
    Map<String, String> environment = const <String, String>{},
  }) : environment = Map.unmodifiable(environment);

  final String locale;
  final String arguments;
  final Map<String, String> environment;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'locale': locale,
      'arguments': arguments,
      'environment': environment,
    };
  }
}
