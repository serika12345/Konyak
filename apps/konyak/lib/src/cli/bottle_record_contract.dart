import '../bottles/bottle_summary.dart';

BottleSummary? parseBottleSummary(Object? value) {
  if (value is! Map<String, dynamic>) {
    return null;
  }

  final Object? id = value['id'];
  final Object? name = value['name'];
  final Object? path = value['path'];
  final Object? windowsVersion = value['windowsVersion'];

  if (id is! String ||
      name is! String ||
      path is! String ||
      windowsVersion is! String) {
    return null;
  }

  final runtimeSettings = _parseRuntimeSettings(value['runtimeSettings']);
  if (runtimeSettings == null) {
    return null;
  }

  return BottleSummary(
    id: id,
    name: name,
    path: path,
    windowsVersion: windowsVersion,
    runtimeSettings: runtimeSettings,
    pinnedPrograms: _parsePinnedPrograms(value['pinnedPrograms']),
  );
}

BottleRuntimeSettingsSummary? _parseRuntimeSettings(Object? value) {
  if (value == null) {
    return const BottleRuntimeSettingsSummary();
  }

  if (value is! Map<String, dynamic>) {
    return null;
  }

  final enhancedSync = _runtimeSettingsString(
    value,
    'enhancedSync',
    allowedValues: const {'none', 'esync', 'msync'},
    defaultValue: 'msync',
  );
  final metalHud = _runtimeSettingsBool(value, 'metalHud');
  final metalTrace = _runtimeSettingsBool(value, 'metalTrace');
  final avxEnabled = _runtimeSettingsBool(value, 'avxEnabled');
  final dxrEnabled = _runtimeSettingsBool(value, 'dxrEnabled');
  final dxvk = _runtimeSettingsBool(value, 'dxvk');
  final dxvkAsync = _runtimeSettingsBool(
    value,
    'dxvkAsync',
    defaultValue: true,
  );
  final dxvkHud = _runtimeSettingsString(
    value,
    'dxvkHud',
    allowedValues: const {'full', 'partial', 'fps', 'off'},
    defaultValue: 'off',
  );
  final vkd3dProton = _runtimeSettingsBool(value, 'vkd3dProton');
  final buildVersion = _runtimeSettingsInt(
    value,
    'buildVersion',
    defaultValue: 0,
    minimum: 0,
    maximum: 999999,
  );
  final retinaMode = _runtimeSettingsBool(value, 'retinaMode');
  final dpiScaling = _runtimeSettingsInt(
    value,
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

String? _runtimeSettingsString(
  Map<String, dynamic> settings,
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
  Map<String, dynamic> settings,
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
  Map<String, dynamic> settings,
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

List<PinnedProgramSummary> _parsePinnedPrograms(Object? value) {
  if (value is! List<dynamic>) {
    return const <PinnedProgramSummary>[];
  }

  final programs = <PinnedProgramSummary>[];
  for (final item in value) {
    if (item is! Map<String, dynamic>) {
      return const <PinnedProgramSummary>[];
    }

    final Object? name = item['name'];
    final Object? path = item['path'];
    final Object? removable = item['removable'];
    final Object? iconPath = item['iconPath'];
    if (name is! String || path is! String || removable is! bool) {
      return const <PinnedProgramSummary>[];
    }
    if (iconPath != null && iconPath is! String) {
      return const <PinnedProgramSummary>[];
    }

    programs.add(
      PinnedProgramSummary(
        name: name,
        path: path,
        removable: removable,
        iconPath: iconPath is String ? iconPath : null,
      ),
    );
  }

  return List.unmodifiable(programs);
}
