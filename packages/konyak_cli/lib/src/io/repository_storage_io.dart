import 'dart:convert';
import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../domain/bottle/bottle_models.dart';
import '../domain/bottle/bottle_runtime_settings_models.dart';
import '../domain/program/program_run_environment.dart';
import '../domain/program/program_settings_models.dart';
import '../shared/common_helpers.dart';
import '../shared/model_constants.dart';
import 'external_payload_helpers.dart';

ProgramSettingsRecord readProgramSettingsJson(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    return ProgramSettingsRecord();
  }

  final decoded = jsonDecode(file.readAsStringSync());
  return programSettingsRecordFromJson(decoded).match(
    () => throw const FormatException(
      'Program settings contain an invalid record.',
    ),
    (value) => value,
  );
}

void writeProgramSettingsJson({
  required String path,
  required ProgramSettingsRecord settings,
}) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(settings.toJson()),
  );
}

Option<ProgramSettingsRecord> programSettingsRecordFromJson(Object? value) {
  final settings = objectMap(value);
  if (settings == null) {
    return const Option.none();
  }

  final locale = settings['locale'];
  final arguments = settings['arguments'];
  final environment = stringMap(settings['environment']);
  final logging = programLoggingSettingsRecordFromJson(settings['logging']);
  if ((locale != null && locale is! String) ||
      (arguments != null && arguments is! String) ||
      environment == null ||
      logging == null) {
    return const Option.none();
  }

  return Option.of(
    ProgramSettingsRecord(
      locale: locale is String ? locale : '',
      arguments: arguments is String ? arguments : '',
      environment: ProgramEnvironmentOverrides(environment),
      logging: logging,
    ),
  );
}

Option<ProgramLoggingSettingsRecord>? programLoggingSettingsRecordFromJson(
  Object? value,
) {
  if (value == null) {
    return const Option.none();
  }

  final settings = objectMap(value);
  if (settings == null) {
    return null;
  }

  final createLogFile = settings['createLogFile'];
  final additionalWineLoggingChannels =
      settings['additionalWineLoggingChannels'];
  final logFilePath = settings['logFilePath'];
  if ((createLogFile != null && createLogFile is! bool) ||
      (additionalWineLoggingChannels != null &&
          additionalWineLoggingChannels is! String) ||
      (logFilePath != null && logFilePath is! String)) {
    return null;
  }

  return Option.of(
    ProgramLoggingSettingsRecord(
      createLogFile: createLogFile is bool ? createLogFile : true,
      additionalWineLoggingChannels: additionalWineLoggingChannels is String
          ? additionalWineLoggingChannels
          : '',
      logFilePath: logFilePath is String ? logFilePath : '',
    ),
  );
}

Option<BottleRuntimeSettings> bottleRuntimeSettingsFromJson(Object? value) {
  if (value == null) {
    return Option.of(BottleRuntimeSettings());
  }

  final settings = objectMap(value);
  if (settings == null) {
    return const Option.none();
  }

  final enhancedSync = runtimeSettingsString(
    settings,
    'enhancedSync',
    allowedValues: const {'none', 'esync', 'msync'},
    defaultValue: 'msync',
  );
  final metalHud = runtimeSettingsBool(settings, 'metalHud');
  final metalTrace = runtimeSettingsBool(settings, 'metalTrace');
  final avxEnabled = runtimeSettingsBool(settings, 'avxEnabled');
  final dxrEnabled = runtimeSettingsBool(settings, 'dxrEnabled');
  final dxvk = runtimeSettingsBool(settings, 'dxvk');
  final dxmt = runtimeSettingsBool(settings, 'dxmt');
  final dlssMetalFx = runtimeSettingsBool(settings, 'dlssMetalFx');
  final dxvkAsync = runtimeSettingsBool(
    settings,
    'dxvkAsync',
    defaultValue: true,
  );
  final dxvkHud = runtimeSettingsString(
    settings,
    'dxvkHud',
    allowedValues: const {'full', 'partial', 'fps', 'off'},
    defaultValue: 'off',
  );
  final vkd3dProton = runtimeSettingsBool(settings, 'vkd3dProton');
  final buildVersion = runtimeSettingsInt(
    settings,
    'buildVersion',
    defaultValue: 0,
    minimum: 0,
    maximum: 999999,
  );
  final retinaMode = runtimeSettingsBool(settings, 'retinaMode');
  final dpiScaling = runtimeSettingsInt(
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

Option<String> runtimeSettingsString(
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

Option<bool> runtimeSettingsBool(
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

Option<int> runtimeSettingsInt(
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

BottleRecord readBottleMetadata(String bottlePath) {
  final metadata = File(joinPath(bottlePath, const ['metadata.json']));
  final decoded = jsonDecode(metadata.readAsStringSync());

  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Bottle metadata must be an object.');
  }

  if (decoded['schemaVersion'] != cliSchemaVersion) {
    throw const FormatException('Unsupported bottle metadata schema version.');
  }

  return bottleRecordFromJson(decoded['bottle']).match(
    () => throw const FormatException(
      'Bottle metadata contains an invalid record.',
    ),
    (value) => value,
  );
}

void writeBottleMetadata(BottleRecord bottle) {
  final metadata = File(joinPath(bottle.path.value, const ['metadata.json']));
  metadata.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(<String, Object?>{
      'schemaVersion': cliSchemaVersion,
      'bottle': bottle.toJson(),
    }),
  );
}

Option<BottleRecord> bottleRecordFromJson(Object? value) {
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

  final runtimeSettings = bottleRuntimeSettingsFromJson(
    value['runtimeSettings'],
  );
  final pinnedPrograms = pinnedProgramRecordsFromJson(value['pinnedPrograms']);
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

Option<List<PinnedProgramRecord>> pinnedProgramRecordsFromJson(Object? value) {
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
