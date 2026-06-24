part of '../../konyak_cli.dart';

ProgramSettingsRecord _readProgramSettingsJson(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    return ProgramSettingsRecord();
  }

  final decoded = jsonDecode(file.readAsStringSync());
  return _programSettingsRecordFromJson(decoded).match(
    () => throw const FormatException(
      'Program settings contain an invalid record.',
    ),
    (value) => value,
  );
}

void _writeProgramSettingsJson({
  required String path,
  required ProgramSettingsRecord settings,
}) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(settings.toJson()),
  );
}

Option<ProgramSettingsRecord> _programSettingsRecordFromJson(Object? value) {
  final settings = _objectMap(value);
  if (settings == null) {
    return const Option.none();
  }

  final locale = settings['locale'];
  final arguments = settings['arguments'];
  final environment = _stringMap(settings['environment']);
  if ((locale != null && locale is! String) ||
      (arguments != null && arguments is! String) ||
      environment == null) {
    return const Option.none();
  }

  return Option.of(
    ProgramSettingsRecord(
      locale: locale is String ? locale : '',
      arguments: arguments is String ? arguments : '',
      environment: ProgramEnvironmentOverrides(environment),
    ),
  );
}

Option<BottleRuntimeSettings> _bottleRuntimeSettingsFromJson(Object? value) {
  if (value == null) {
    return Option.of(const BottleRuntimeSettings());
  }

  final settings = _objectMap(value);
  if (settings == null) {
    return const Option.none();
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
  final dxmt = _runtimeSettingsBool(settings, 'dxmt');
  final dlssMetalFx = _runtimeSettingsBool(settings, 'dlssMetalFx');
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
    step: Option.of(24),
  );

  final parsedEnhancedSync = enhancedSync.toNullable();
  final parsedMetalHud = metalHud.toNullable();
  final parsedMetalTrace = metalTrace.toNullable();
  final parsedAvxEnabled = avxEnabled.toNullable();
  final parsedDxrEnabled = dxrEnabled.toNullable();
  final parsedDxvk = dxvk.toNullable();
  final parsedDxmt = dxmt.toNullable();
  final parsedDlssMetalFx = dlssMetalFx.toNullable();
  final parsedDxvkAsync = dxvkAsync.toNullable();
  final parsedDxvkHud = dxvkHud.toNullable();
  final parsedVkd3dProton = vkd3dProton.toNullable();
  final parsedBuildVersion = buildVersion.toNullable();
  final parsedRetinaMode = retinaMode.toNullable();
  final parsedDpiScaling = dpiScaling.toNullable();
  if (parsedEnhancedSync == null ||
      parsedMetalHud == null ||
      parsedMetalTrace == null ||
      parsedAvxEnabled == null ||
      parsedDxrEnabled == null ||
      parsedDxvk == null ||
      parsedDxmt == null ||
      parsedDlssMetalFx == null ||
      parsedDxvkAsync == null ||
      parsedDxvkHud == null ||
      parsedVkd3dProton == null ||
      parsedBuildVersion == null ||
      parsedRetinaMode == null ||
      parsedDpiScaling == null) {
    return const Option.none();
  }

  return Option.of(
    BottleRuntimeSettings(
      enhancedSync: parsedEnhancedSync,
      metalHud: parsedMetalHud,
      metalTrace: parsedMetalTrace,
      avxEnabled: parsedAvxEnabled,
      dxrEnabled: parsedDxrEnabled,
      dxvk: parsedDxrEnabled || parsedDxmt ? false : parsedDxvk,
      dxmt: parsedDxrEnabled ? false : parsedDxmt,
      dlssMetalFx: parsedDlssMetalFx,
      dxvkAsync: parsedDxvkAsync,
      dxvkHud: parsedDxvkHud,
      vkd3dProton: parsedVkd3dProton,
      buildVersion: parsedBuildVersion,
      retinaMode: parsedRetinaMode,
      dpiScaling: parsedDpiScaling,
    ),
  );
}

Option<String> _runtimeSettingsString(
  Map<String, Object?> settings,
  String key, {
  required Set<String> allowedValues,
  required String defaultValue,
}) {
  if (!settings.containsKey(key)) {
    return Option.of(defaultValue);
  }

  final value = settings[key];
  if (value is! String || value.trim().isEmpty) {
    return const Option.none();
  }

  return allowedValues.contains(value) ? Option.of(value) : const Option.none();
}

Option<bool> _runtimeSettingsBool(
  Map<String, Object?> settings,
  String key, {
  bool defaultValue = false,
}) {
  if (!settings.containsKey(key)) {
    return Option.of(defaultValue);
  }

  final value = settings[key];
  return value is bool ? Option.of(value) : const Option.none();
}

Option<int> _runtimeSettingsInt(
  Map<String, Object?> settings,
  String key, {
  required int defaultValue,
  required int minimum,
  required int maximum,
  Option<int> step = const Option.none(),
}) {
  if (!settings.containsKey(key)) {
    return Option.of(defaultValue);
  }

  final value = settings[key];
  if (value is! int || value < minimum || value > maximum) {
    return const Option.none();
  }

  if (step.match(
    () => false,
    (requiredStep) => (value - minimum) % requiredStep != 0,
  )) {
    return const Option.none();
  }

  return Option.of(value);
}

BottleRecord _readBottleMetadata(String bottlePath) {
  final metadata = File(_joinPath(bottlePath, const ['metadata.json']));
  final decoded = jsonDecode(metadata.readAsStringSync());

  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Bottle metadata must be an object.');
  }

  if (decoded['schemaVersion'] != cliSchemaVersion) {
    throw const FormatException('Unsupported bottle metadata schema version.');
  }

  return _bottleRecordFromJson(decoded['bottle']).match(
    () => throw const FormatException(
      'Bottle metadata contains an invalid record.',
    ),
    (value) => value,
  );
}

void _writeBottleMetadata(BottleRecord bottle) {
  final metadata = File(_joinPath(bottle.path, const ['metadata.json']));
  metadata.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(<String, Object?>{
      'schemaVersion': cliSchemaVersion,
      'bottle': bottle.toJson(),
    }),
  );
}

Option<BottleRecord> _bottleRecordFromJson(Object? value) {
  if (value is! Map<String, dynamic>) {
    return const Option.none();
  }

  final Object? id = value['id'];
  final Object? name = value['name'];
  final Object? path = value['path'];
  final Object? windowsVersion = value['windowsVersion'];

  if (id is! String ||
      name is! String ||
      path is! String ||
      windowsVersion is! String) {
    return const Option.none();
  }

  final runtimeSettings = _bottleRuntimeSettingsFromJson(
    value['runtimeSettings'],
  );
  final pinnedPrograms = _pinnedProgramRecordsFromJson(value['pinnedPrograms']);
  final parsedRuntimeSettings = runtimeSettings.toNullable();
  final parsedPinnedPrograms = pinnedPrograms.toNullable();
  if (parsedRuntimeSettings == null || parsedPinnedPrograms == null) {
    return const Option.none();
  }

  try {
    return Option.of(
      BottleRecord(
        id: id,
        name: name,
        path: path,
        windowsVersion: windowsVersion,
        runtimeSettings: parsedRuntimeSettings,
        pinnedPrograms: parsedPinnedPrograms,
      ),
    );
  } on ArgumentError {
    return const Option.none();
  }
}

Option<List<PinnedProgramRecord>> _pinnedProgramRecordsFromJson(Object? value) {
  if (value == null) {
    return Option.of(const <PinnedProgramRecord>[]);
  }
  if (value is! List<dynamic>) {
    return const Option.none();
  }

  final programs = <PinnedProgramRecord>[];
  for (final item in value) {
    if (item is! Map<String, dynamic>) {
      return const Option.none();
    }

    final name = item['name'];
    final path = item['path'];
    final removable = item['removable'];
    final iconPath = item['iconPath'];
    if (name is! String || path is! String) {
      return const Option.none();
    }
    if (iconPath != null && iconPath is! String) {
      return const Option.none();
    }

    try {
      programs.add(
        PinnedProgramRecord(
          name: name,
          path: path,
          removable: removable is bool && removable,
          iconPath: iconPath is String
              ? Option.of(iconPath)
              : const Option.none(),
        ),
      );
    } on ArgumentError {
      return const Option.none();
    }
  }

  return Option.of(List.unmodifiable(programs));
}
