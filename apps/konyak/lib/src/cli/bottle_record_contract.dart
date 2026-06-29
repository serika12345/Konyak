import '../bottles/bottle_summary.dart';

sealed class BottleSummaryParseResult {
  const BottleSummaryParseResult();
}

final class ParsedBottleSummary extends BottleSummaryParseResult {
  const ParsedBottleSummary(this.bottle);

  final BottleSummary bottle;
}

final class InvalidBottleSummary extends BottleSummaryParseResult {
  const InvalidBottleSummary();
}

sealed class _PayloadParseResult<T> {
  const _PayloadParseResult();
}

final class _ParsedPayload<T> extends _PayloadParseResult<T> {
  const _ParsedPayload(this.value);

  final T value;
}

final class _InvalidPayload<T> extends _PayloadParseResult<T> {
  const _InvalidPayload();
}

BottleSummaryParseResult parseBottleSummary(Object? value) {
  if (value is! Map<String, dynamic>) {
    return const InvalidBottleSummary();
  }

  final Object? id = value['id'];
  final Object? name = value['name'];
  final Object? path = value['path'];
  final Object? windowsVersion = value['windowsVersion'];

  if (id is! String ||
      name is! String ||
      path is! String ||
      windowsVersion is! String) {
    return const InvalidBottleSummary();
  }

  return switch ((
    _parseRuntimeSettings(value['runtimeSettings']),
    _parsePinnedPrograms(value['pinnedPrograms']),
  )) {
    (
      _ParsedPayload(value: final runtimeSettings),
      _ParsedPayload(value: final pinnedPrograms),
    ) =>
      ParsedBottleSummary(
        BottleSummary(
          id: id,
          name: name,
          path: path,
          windowsVersion: windowsVersion,
          runtimeSettings: runtimeSettings,
          pinnedPrograms: pinnedPrograms,
        ),
      ),
    _ => const InvalidBottleSummary(),
  };
}

_PayloadParseResult<BottleRuntimeSettingsSummary> _parseRuntimeSettings(
  Object? value,
) {
  if (value == null) {
    return const _ParsedPayload(BottleRuntimeSettingsSummary());
  }

  if (value is! Map<String, dynamic>) {
    return const _InvalidPayload<BottleRuntimeSettingsSummary>();
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
  final dxmt = _runtimeSettingsBool(value, 'dxmt');
  final dlssMetalFx = _runtimeSettingsBool(value, 'dlssMetalFx');
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

  return switch ((
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
  )) {
    (
      _ParsedPayload(value: final enhancedSync),
      _ParsedPayload(value: final metalHud),
      _ParsedPayload(value: final metalTrace),
      _ParsedPayload(value: final avxEnabled),
      _ParsedPayload(value: final dxrEnabled),
      _ParsedPayload(value: final dxvk),
      _ParsedPayload(value: final dxmt),
      _ParsedPayload(value: final dlssMetalFx),
      _ParsedPayload(value: final dxvkAsync),
      _ParsedPayload(value: final dxvkHud),
      _ParsedPayload(value: final vkd3dProton),
      _ParsedPayload(value: final buildVersion),
      _ParsedPayload(value: final retinaMode),
      _ParsedPayload(value: final dpiScaling),
    ) =>
      _ParsedPayload(
        BottleRuntimeSettingsSummary(
          enhancedSync: enhancedSync,
          metalHud: metalHud,
          metalTrace: metalTrace,
          avxEnabled: avxEnabled,
          dxrEnabled: dxrEnabled,
          dxvk: dxrEnabled || dxmt ? false : dxvk,
          dxmt: dxrEnabled ? false : dxmt,
          dlssMetalFx: dlssMetalFx,
          dxvkAsync: dxvkAsync,
          dxvkHud: dxvkHud,
          vkd3dProton: vkd3dProton,
          buildVersion: buildVersion,
          retinaMode: retinaMode,
          dpiScaling: dpiScaling,
        ),
      ),
    _ => const _InvalidPayload<BottleRuntimeSettingsSummary>(),
  };
}

_PayloadParseResult<String> _runtimeSettingsString(
  Map<String, dynamic> settings,
  String key, {
  required Set<String> allowedValues,
  required String defaultValue,
}) {
  if (!settings.containsKey(key)) {
    return _ParsedPayload(defaultValue);
  }

  final value = settings[key];
  if (value is! String || value.trim().isEmpty) {
    return const _InvalidPayload<String>();
  }

  return allowedValues.contains(value)
      ? _ParsedPayload(value)
      : const _InvalidPayload<String>();
}

_PayloadParseResult<bool> _runtimeSettingsBool(
  Map<String, dynamic> settings,
  String key, {
  bool defaultValue = false,
}) {
  if (!settings.containsKey(key)) {
    return _ParsedPayload(defaultValue);
  }

  final value = settings[key];
  return value is bool ? _ParsedPayload(value) : const _InvalidPayload<bool>();
}

_PayloadParseResult<int> _runtimeSettingsInt(
  Map<String, dynamic> settings,
  String key, {
  required int defaultValue,
  required int minimum,
  required int maximum,
  int step = 1,
}) {
  if (!settings.containsKey(key)) {
    return _ParsedPayload(defaultValue);
  }

  final value = settings[key];
  if (value is! int || value < minimum || value > maximum) {
    return const _InvalidPayload<int>();
  }

  if ((value - minimum) % step != 0) {
    return const _InvalidPayload<int>();
  }

  return _ParsedPayload(value);
}

_PayloadParseResult<List<PinnedProgramSummary>> _parsePinnedPrograms(
  Object? value,
) {
  if (value == null) {
    return const _ParsedPayload(<PinnedProgramSummary>[]);
  }
  if (value is! List<dynamic>) {
    return const _InvalidPayload<List<PinnedProgramSummary>>();
  }

  final programs = <PinnedProgramSummary>[];
  for (final item in value) {
    if (item is! Map<String, dynamic>) {
      return const _InvalidPayload<List<PinnedProgramSummary>>();
    }

    final Object? name = item['name'];
    final Object? path = item['path'];
    final Object? removable = item['removable'];
    final Object? iconPath = item['iconPath'];
    if (name is! String || path is! String || removable is! bool) {
      return const _InvalidPayload<List<PinnedProgramSummary>>();
    }
    if (iconPath != null && iconPath is! String) {
      return const _InvalidPayload<List<PinnedProgramSummary>>();
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

  return _ParsedPayload(List.unmodifiable(programs));
}
