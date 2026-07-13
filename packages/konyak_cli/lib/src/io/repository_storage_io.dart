import 'dart:convert';
import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../domain/bottle/bottle_models.dart';
import '../domain/bottle/bottle_runtime_settings_models.dart';
import '../domain/program/program_profile_models.dart';
import '../domain/program/program_run_environment.dart';
import '../domain/program/program_settings_models.dart';
import '../domain/shared/domain_value_objects.dart';
import '../shared/common_helpers.dart';
import '../shared/model_constants.dart';
import 'bottle_metadata_json.dart';
import 'external_payload_helpers.dart';
import 'program_settings_json.dart';

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
    const JsonEncoder.withIndent(
      '  ',
    ).convert(programSettingsRecordJson(settings)),
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
  final logging = _programLoggingSettingsRecordFromJson(settings['logging']);
  if ((locale != null && locale is! String) ||
      (arguments != null && arguments is! String) ||
      environment == null) {
    return const Option.none();
  }

  return switch (logging) {
    _ProgramLoggingSettingsInvalid() => const Option.none(),
    _ProgramLoggingSettingsParsed(:final logging) => Option.of(
      ProgramSettingsRecord(
        locale: ProgramLocale(locale is String ? locale : ''),
        arguments: ProgramArguments(arguments is String ? arguments : ''),
        environment: ProgramEnvironmentOverrides(environment),
        logging: logging,
      ),
    ),
  };
}

sealed class _ProgramLoggingSettingsParseResult {
  const _ProgramLoggingSettingsParseResult();
}

final class _ProgramLoggingSettingsParsed
    extends _ProgramLoggingSettingsParseResult {
  const _ProgramLoggingSettingsParsed(this.logging);

  final Option<ProgramLoggingSettingsRecord> logging;
}

final class _ProgramLoggingSettingsInvalid
    extends _ProgramLoggingSettingsParseResult {
  const _ProgramLoggingSettingsInvalid();
}

_ProgramLoggingSettingsParseResult _programLoggingSettingsRecordFromJson(
  Object? value,
) {
  if (value == null) {
    return const _ProgramLoggingSettingsParsed(Option.none());
  }

  final settings = objectMap(value);
  if (settings == null) {
    return const _ProgramLoggingSettingsInvalid();
  }

  final createLogFile = settings['createLogFile'];
  final additionalWineLoggingChannels =
      settings['additionalWineLoggingChannels'];
  final logFilePath = settings['logFilePath'];
  if ((createLogFile != null && createLogFile is! bool) ||
      (additionalWineLoggingChannels != null &&
          additionalWineLoggingChannels is! String) ||
      (logFilePath != null && logFilePath is! String)) {
    return const _ProgramLoggingSettingsInvalid();
  }

  return _ProgramLoggingSettingsParsed(
    Option.of(
      ProgramLoggingSettingsRecord(
        createLogFile: createLogFile is bool ? createLogFile : true,
        additionalWineLoggingChannels: WineDebugChannels(
          additionalWineLoggingChannels is String
              ? additionalWineLoggingChannels
              : '',
        ),
        logFilePath: ProgramLogPath(logFilePath is String ? logFilePath : ''),
      ),
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

  return Option.Do(($) {
    final parsedEnhancedSync = $(enhancedSync);
    final parsedMetalHud = $(metalHud);
    final parsedMetalTrace = $(metalTrace);
    final parsedAvxEnabled = $(avxEnabled);
    final parsedDxrEnabled = $(dxrEnabled);
    final parsedDxvk = $(dxvk);
    final parsedDxmt = $(dxmt);
    final parsedDlssMetalFx = $(dlssMetalFx);
    final parsedDxvkAsync = $(dxvkAsync);
    final parsedDxvkHud = $(dxvkHud);
    final parsedVkd3dProton = $(vkd3dProton);
    final parsedBuildVersion = $(buildVersion);
    final parsedRetinaMode = $(retinaMode);
    final parsedDpiScaling = $(dpiScaling);

    return BottleRuntimeSettings(
      enhancedSync: EnhancedSyncMode(parsedEnhancedSync),
      metalHud: parsedMetalHud,
      metalTrace: parsedMetalTrace,
      avxEnabled: parsedAvxEnabled,
      dxrEnabled: parsedDxrEnabled,
      dxvk: parsedDxrEnabled || parsedDxmt ? false : parsedDxvk,
      dxmt: parsedDxrEnabled ? false : parsedDxmt,
      dlssMetalFx: parsedDlssMetalFx,
      dxvkAsync: parsedDxvkAsync,
      dxvkHud: DxvkHudMode(parsedDxvkHud),
      vkd3dProton: parsedVkd3dProton,
      buildVersion: WindowsBuildVersion(parsedBuildVersion),
      retinaMode: parsedRetinaMode,
      dpiScaling: WindowsDpiScaling(parsedDpiScaling),
    );
  });
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
      'bottle': bottleRecordJson(bottle),
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
  final programProfiles = programProfileRecordsFromJson(value['profiles']);

  try {
    return Option.Do(($) {
      return BottleRecord(
        id: id,
        name: name,
        path: path,
        windowsVersion: windowsVersion,
        runtimeSettings: Option.of($(runtimeSettings)),
        pinnedPrograms: $(pinnedPrograms),
        programProfiles: $(programProfiles),
      );
    });
  } on ArgumentError {
    return const Option<BottleRecord>.none();
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

Option<List<ProgramProfileRecord>> programProfileRecordsFromJson(
  Object? value,
) {
  if (value == null) {
    return Option.of(const <ProgramProfileRecord>[]);
  }
  if (value is! List<dynamic>) {
    return const Option.none();
  }

  final profiles = <ProgramProfileRecord>[];
  for (final item in value) {
    if (item is! Map<String, dynamic>) {
      return const Option.none();
    }

    final profileSchemaVersion = item['profileSchemaVersion'];
    final profileId = item['profileId'];
    final profileVersion = item['profileVersion'];
    final profileSourceKind = item['profileSourceKind'];
    final profileSourceId = item['profileSourceId'];
    final profileDigest = item['profileDigest'];
    final managedProgramPath = item['managedProgramPath'];
    final compatibilityProfileId = item['compatibilityProfileId'];
    final compatibilityProfileVersion = item['compatibilityProfileVersion'];
    final installerResource = item['installerResource'];
    if (profileSchemaVersion is! int ||
        profileId is! String ||
        profileVersion is! int ||
        profileSourceKind != ProfileSourceKind.builtin.value ||
        profileSourceId is! String ||
        profileDigest is! String ||
        managedProgramPath is! String ||
        compatibilityProfileId is! String ||
        compatibilityProfileVersion is! int ||
        installerResource is! Map<String, dynamic>) {
      return const Option.none();
    }

    final installerKind = installerResource['kind'];
    final installerUrl = installerResource['url'];
    final installerSha256 = installerResource['sha256'];
    final installerFileName = installerResource['fileName'];
    if (installerKind is! String ||
        installerUrl is! String ||
        installerSha256 is! String ||
        installerFileName is! String) {
      return const Option.none();
    }

    try {
      profiles.add(
        ProgramProfileRecord(
          profileSchemaVersion: profileSchemaVersion,
          profileId: profileId,
          profileVersion: profileVersion,
          profileSourceKind: ProfileSourceKind.builtin,
          profileSourceId: profileSourceId,
          profileDigest: profileDigest,
          managedProgramPath: managedProgramPath,
          installerResource: InstallerResourceRecord(
            kind: installerKind,
            url: installerUrl,
            sha256: installerSha256,
            fileName: installerFileName,
          ),
          compatibilityProfileId: compatibilityProfileId,
          compatibilityProfileVersion: compatibilityProfileVersion,
        ),
      );
    } on ArgumentError {
      return const Option.none();
    }
  }

  return Option.of(List.unmodifiable(profiles));
}
