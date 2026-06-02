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

  BottleSummary copyWith({
    String? id,
    String? name,
    String? path,
    String? windowsVersion,
    BottleRuntimeSettingsSummary? runtimeSettings,
    List<PinnedProgramSummary>? pinnedPrograms,
  }) {
    return BottleSummary(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      windowsVersion: windowsVersion ?? this.windowsVersion,
      runtimeSettings: runtimeSettings ?? this.runtimeSettings,
      pinnedPrograms: pinnedPrograms ?? this.pinnedPrograms,
    );
  }
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

  BottleRuntimeSettingsSummary copyWith({
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
    return BottleRuntimeSettingsSummary(
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

  ProgramSettingsSummary copyWith({
    String? locale,
    String? arguments,
    Map<String, String>? environment,
  }) {
    return ProgramSettingsSummary(
      locale: locale ?? this.locale,
      arguments: arguments ?? this.arguments,
      environment: environment ?? this.environment,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'locale': locale,
      'arguments': arguments,
      'environment': environment,
    };
  }
}
