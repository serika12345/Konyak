import 'dart:convert';
import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../domain/bottle/bottle_models.dart';
import '../domain/bottle/bottle_runtime_settings_models.dart';
import '../domain/program/program_profile_models.dart';
import '../domain/program/program_run_environment.dart';
import '../domain/program/program_run_models.dart';
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
  final workingDirectory = _programWorkingDirectorySettingFromJson(
    settings['workingDirectory'],
  );
  final environment = stringMap(settings['environment']);
  final logging = _programLoggingSettingsRecordFromJson(settings['logging']);
  if ((locale != null && locale is! String) ||
      (arguments != null && arguments is! String) ||
      environment == null) {
    return const Option.none();
  }

  return switch ((workingDirectory, logging)) {
    (_ProgramWorkingDirectorySettingInvalid(), _) => const Option.none(),
    (_, _ProgramLoggingSettingsInvalid()) => const Option.none(),
    (
      _ProgramWorkingDirectorySettingParsed(:final setting),
      _ProgramLoggingSettingsParsed(:final logging),
    ) =>
      Option.of(
        ProgramSettingsRecord(
          locale: ProgramLocale(locale is String ? locale : ''),
          arguments: ProgramArguments(arguments is String ? arguments : ''),
          workingDirectory: setting,
          environment: ProgramEnvironmentOverrides(environment),
          logging: logging,
        ),
      ),
  };
}

sealed class _ProgramWorkingDirectorySettingParseResult {
  const _ProgramWorkingDirectorySettingParseResult();
}

final class _ProgramWorkingDirectorySettingParsed
    extends _ProgramWorkingDirectorySettingParseResult {
  const _ProgramWorkingDirectorySettingParsed(this.setting);

  final ProgramWorkingDirectorySetting setting;
}

final class _ProgramWorkingDirectorySettingInvalid
    extends _ProgramWorkingDirectorySettingParseResult {
  const _ProgramWorkingDirectorySettingInvalid();
}

_ProgramWorkingDirectorySettingParseResult
_programWorkingDirectorySettingFromJson(Object? value) {
  if (value == null) {
    return const _ProgramWorkingDirectorySettingParsed(
      ProgramWorkingDirectorySetting.executableDirectory(),
    );
  }
  final setting = objectMap(value);
  if (setting == null) {
    return const _ProgramWorkingDirectorySettingInvalid();
  }
  final kind = setting['kind'];
  final path = setting['path'];
  if (kind == 'executableDirectory' && path == null) {
    return const _ProgramWorkingDirectorySettingParsed(
      ProgramWorkingDirectorySetting.executableDirectory(),
    );
  }
  if (kind != 'custom' || path is! String) {
    return const _ProgramWorkingDirectorySettingInvalid();
  }

  try {
    return _ProgramWorkingDirectorySettingParsed(
      ProgramWorkingDirectorySetting.custom(
        WindowsProgramWorkingDirectoryPath(path),
      ),
    );
  } on ArgumentError {
    return const _ProgramWorkingDirectorySettingInvalid();
  }
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
    const JsonEncoder.withIndent(
      '  ',
    ).convert(bottleMetadataDocumentJson(bottle)),
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
    final preInstallActions = item['preInstallActions'];
    final launchPolicyResult = _programProfileLaunchPolicyFromJson(
      item['launchPolicy'],
    );
    if (profileSchemaVersion is! int ||
        profileId is! String ||
        profileVersion is! int ||
        profileSourceKind is! String ||
        !ProfileSourceKind.values.any(
          (sourceKind) => sourceKind.value == profileSourceKind,
        ) ||
        profileSourceId is! String ||
        profileDigest is! String ||
        managedProgramPath is! String ||
        compatibilityProfileId is! String ||
        compatibilityProfileVersion is! int ||
        installerResource is! Map<String, dynamic> ||
        preInstallActions is! List<dynamic> ||
        launchPolicyResult is _InvalidProgramProfileLaunchPolicy) {
      return const Option.none();
    }
    final launchPolicy = switch (launchPolicyResult) {
      _AbsentProgramProfileLaunchPolicy() =>
        const Option<ProgramProfileLaunchPolicy>.none(),
      _ParsedProgramProfileLaunchPolicy(:final policy) => Option.of(policy),
      _InvalidProgramProfileLaunchPolicy() =>
        const Option<ProgramProfileLaunchPolicy>.none(),
    };

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
          profileSourceKind: ProfileSourceKind.values.singleWhere(
            (sourceKind) => sourceKind.value == profileSourceKind,
          ),
          profileSourceId: profileSourceId,
          profileDigest: profileDigest,
          managedProgramPath: managedProgramPath,
          installerResource: InstallerResourceRecord(
            kind: installerKind,
            url: installerUrl,
            sha256: installerSha256,
            fileName: installerFileName,
          ),
          preInstallActions: preInstallActions.map((action) {
            if (action is! Map<String, dynamic>) {
              throw const FormatException('Invalid pre-install action.');
            }
            final kind = action['kind'];
            if (kind == 'winetricks' && action['verb'] is String) {
              return PreInstallActionRecord.winetricks(
                verb: action['verb'] as String,
              );
            }
            if (kind == 'nativeDll' &&
                action['componentId'] is String &&
                action['machine'] is String &&
                action['destination'] is String &&
                action['targetFileName'] is String &&
                action['resource'] is Map<String, dynamic>) {
              final resource = action['resource'] as Map<String, dynamic>;
              if (resource['kind'] is String &&
                  resource['url'] is String &&
                  resource['sha256'] is String &&
                  resource['fileName'] is String) {
                return PreInstallActionRecord.nativeDll(
                  componentId: action['componentId'] as String,
                  machine: action['machine'] as String,
                  destination: action['destination'] as String,
                  targetFileName: action['targetFileName'] as String,
                  resource: NativeDllResourceRecord(
                    kind: resource['kind'] as String,
                    url: resource['url'] as String,
                    sha256: resource['sha256'] as String,
                    fileName: resource['fileName'] as String,
                  ),
                );
              }
            }
            throw const FormatException('Invalid pre-install action.');
          }),
          compatibilityProfileId: compatibilityProfileId,
          compatibilityProfileVersion: compatibilityProfileVersion,
          launchPolicy: launchPolicy,
        ),
      );
    } on ArgumentError catch (_) {
      return const Option.none();
    } on FormatException catch (_) {
      return const Option.none();
    }
  }

  return Option.of(List.unmodifiable(profiles));
}

sealed class _ProgramProfileLaunchPolicyParseResult {
  const _ProgramProfileLaunchPolicyParseResult();
}

final class _AbsentProgramProfileLaunchPolicy
    extends _ProgramProfileLaunchPolicyParseResult {
  const _AbsentProgramProfileLaunchPolicy();
}

final class _ParsedProgramProfileLaunchPolicy
    extends _ProgramProfileLaunchPolicyParseResult {
  const _ParsedProgramProfileLaunchPolicy(this.policy);

  final ProgramProfileLaunchPolicy policy;
}

final class _InvalidProgramProfileLaunchPolicy
    extends _ProgramProfileLaunchPolicyParseResult {
  const _InvalidProgramProfileLaunchPolicy();
}

_ProgramProfileLaunchPolicyParseResult _programProfileLaunchPolicyFromJson(
  Object? value,
) {
  if (value == null) {
    return const _AbsentProgramProfileLaunchPolicy();
  }
  if (value is! Map<String, dynamic>) {
    return const _InvalidProgramProfileLaunchPolicy();
  }
  final runCompletionPolicy = value['runCompletionPolicy'];
  final compatibilityProfile = value['compatibilityProfile'];
  if (runCompletionPolicy is! String ||
      compatibilityProfile is! Map<String, dynamic>) {
    return const _InvalidProgramProfileLaunchPolicy();
  }
  final compatibilityProfileId = compatibilityProfile['id'];
  final compatibilityProfileVersion = compatibilityProfile['profileVersion'];
  final childProcessRules = compatibilityProfile['childProcessRules'];
  if (compatibilityProfileId is! String ||
      compatibilityProfileVersion is! int ||
      childProcessRules is! List<dynamic>) {
    return const _InvalidProgramProfileLaunchPolicy();
  }

  try {
    return _ParsedProgramProfileLaunchPolicy(
      ProgramProfileLaunchPolicy(
        runCompletionPolicy: ProgramRunCompletionPolicy.values.singleWhere(
          (policy) => policy.value == runCompletionPolicy,
        ),
        compatibilityProfile: CompatibilityProfileRecord(
          id: compatibilityProfileId,
          profileVersion: compatibilityProfileVersion,
          childProcessRules: childProcessRules.map((rule) {
            if (rule is! Map<String, dynamic> ||
                rule['executableSuffix'] is! String ||
                rule['appendArgumentsIfMissing'] is! List<dynamic> ||
                !(rule['appendArgumentsIfMissing'] as List<dynamic>).every(
                  (argument) => argument is String,
                )) {
              throw const FormatException(
                'Invalid child-process compatibility rule.',
              );
            }
            return ChildProcessCompatibilityRule(
              executableSuffix: rule['executableSuffix'] as String,
              appendArgumentsIfMissing:
                  (rule['appendArgumentsIfMissing'] as List<dynamic>)
                      .cast<String>(),
            );
          }),
        ),
      ),
    );
  } on ArgumentError catch (_) {
    return const _InvalidProgramProfileLaunchPolicy();
  } on FormatException catch (_) {
    return const _InvalidProgramProfileLaunchPolicy();
  } on StateError catch (_) {
    return const _InvalidProgramProfileLaunchPolicy();
  }
}
