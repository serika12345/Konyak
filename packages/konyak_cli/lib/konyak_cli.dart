import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

const cliSchemaVersion = 1;
const runtimeStackSchemaVersion = 1;
const konyakAppId = 'konyak';
const konyakAppVersion = '1.0.0';
const konyakMacosBundleIdentifier = 'app.konyak.Konyak';
const konyakAppVersionUrl =
    'https://api.github.com/repos/serika12345/Konyak/releases/latest';
const runtimeStackManifestFileName = '.konyak-runtime-stack.json';
const linuxWineRuntimeId = 'konyak-linux-wine';
const macosWineRuntimeId = 'konyak-macos-wine';
const macosWineArchiveUrl =
    'https://github.com/Gcenx/macOS_Wine_builds/releases/download/11.9/wine-devel-11.9-osx64.tar.xz';
const macosWineArchiveFileName = 'macos-wine.tar.xz';
const macosWineVersionUrl =
    'https://api.github.com/repos/Gcenx/macOS_Wine_builds/releases/latest';
const winetricksScriptUrl =
    'https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks';
const _rosettaRuntimePath = '/Library/Apple/usr/libexec/oah/libRosettaRuntime';
const _rosettaInstallCommand = <String>[
  '/usr/sbin/softwareupdate',
  '--install-rosetta',
  '--agree-to-license',
];

enum AppAppearanceMode {
  dark('dark'),
  light('light'),
  system('system');

  const AppAppearanceMode(this.jsonValue);

  final String jsonValue;
}

class AppSettingsRecord {
  const AppSettingsRecord({
    this.terminateWineProcessesOnClose = true,
    required this.defaultBottlePath,
    this.appearanceMode = AppAppearanceMode.dark,
    this.automaticallyCheckForKonyakUpdates = false,
    this.automaticallyCheckForWineUpdates = true,
  });

  final bool terminateWineProcessesOnClose;
  final String defaultBottlePath;
  final AppAppearanceMode appearanceMode;
  final bool automaticallyCheckForKonyakUpdates;
  final bool automaticallyCheckForWineUpdates;

  AppSettingsRecord copyWith({
    bool? terminateWineProcessesOnClose,
    String? defaultBottlePath,
    AppAppearanceMode? appearanceMode,
    bool? automaticallyCheckForKonyakUpdates,
    bool? automaticallyCheckForWineUpdates,
  }) {
    return AppSettingsRecord(
      terminateWineProcessesOnClose:
          terminateWineProcessesOnClose ?? this.terminateWineProcessesOnClose,
      defaultBottlePath: defaultBottlePath ?? this.defaultBottlePath,
      appearanceMode: appearanceMode ?? this.appearanceMode,
      automaticallyCheckForKonyakUpdates:
          automaticallyCheckForKonyakUpdates ??
          this.automaticallyCheckForKonyakUpdates,
      automaticallyCheckForWineUpdates:
          automaticallyCheckForWineUpdates ??
          this.automaticallyCheckForWineUpdates,
    );
  }

  static AppSettingsRecord? fromJson(
    Object? value, {
    required String fallbackDefaultBottlePath,
  }) {
    final settings = _objectMap(value);
    if (settings == null) {
      return null;
    }

    final terminateWineProcessesOnClose =
        settings['terminateWineProcessesOnClose'];
    final defaultBottlePath = settings['defaultBottlePath'];
    final appearanceMode = _appAppearanceModeFromJson(
      settings['appearanceMode'],
    );
    final automaticallyCheckForKonyakUpdates =
        settings['automaticallyCheckForKonyakUpdates'];
    final automaticallyCheckForWineUpdates =
        settings['automaticallyCheckForWineUpdates'];

    if (terminateWineProcessesOnClose != null &&
        terminateWineProcessesOnClose is! bool) {
      return null;
    }
    if (defaultBottlePath != null &&
        (defaultBottlePath is! String || defaultBottlePath.trim().isEmpty)) {
      return null;
    }
    if (appearanceMode == null) {
      return null;
    }
    if (automaticallyCheckForKonyakUpdates != null &&
        automaticallyCheckForKonyakUpdates is! bool) {
      return null;
    }
    if (automaticallyCheckForWineUpdates != null &&
        automaticallyCheckForWineUpdates is! bool) {
      return null;
    }

    return AppSettingsRecord(
      terminateWineProcessesOnClose: terminateWineProcessesOnClose is bool
          ? terminateWineProcessesOnClose
          : true,
      defaultBottlePath: defaultBottlePath is String
          ? defaultBottlePath
          : fallbackDefaultBottlePath,
      appearanceMode: appearanceMode,
      automaticallyCheckForKonyakUpdates:
          automaticallyCheckForKonyakUpdates is bool
          ? automaticallyCheckForKonyakUpdates
          : false,
      automaticallyCheckForWineUpdates: automaticallyCheckForWineUpdates is bool
          ? automaticallyCheckForWineUpdates
          : true,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'terminateWineProcessesOnClose': terminateWineProcessesOnClose,
      'defaultBottlePath': defaultBottlePath,
      'appearanceMode': appearanceMode.jsonValue,
      'automaticallyCheckForKonyakUpdates': automaticallyCheckForKonyakUpdates,
      'automaticallyCheckForWineUpdates': automaticallyCheckForWineUpdates,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is AppSettingsRecord &&
        other.terminateWineProcessesOnClose == terminateWineProcessesOnClose &&
        other.defaultBottlePath == defaultBottlePath &&
        other.appearanceMode == appearanceMode &&
        other.automaticallyCheckForKonyakUpdates ==
            automaticallyCheckForKonyakUpdates &&
        other.automaticallyCheckForWineUpdates ==
            automaticallyCheckForWineUpdates;
  }

  @override
  int get hashCode => Object.hash(
    terminateWineProcessesOnClose,
    defaultBottlePath,
    appearanceMode,
    automaticallyCheckForKonyakUpdates,
    automaticallyCheckForWineUpdates,
  );
}

AppAppearanceMode? _appAppearanceModeFromJson(Object? value) {
  if (value == null) {
    return AppAppearanceMode.dark;
  }
  if (value is! String) {
    return null;
  }

  for (final mode in AppAppearanceMode.values) {
    if (mode.jsonValue == value) {
      return mode;
    }
  }

  return null;
}

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

class CliResult {
  const CliResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;
}

class BottleRecord {
  const BottleRecord({
    required this.id,
    required this.name,
    required this.path,
    required this.windowsVersion,
    this.runtimeSettings = const BottleRuntimeSettings(),
    this.pinnedPrograms = const <PinnedProgramRecord>[],
  });

  final String id;
  final String name;
  final String path;
  final String windowsVersion;
  final BottleRuntimeSettings runtimeSettings;
  final List<PinnedProgramRecord> pinnedPrograms;

  BottleRecord copyWith({
    String? id,
    String? name,
    String? path,
    String? windowsVersion,
    BottleRuntimeSettings? runtimeSettings,
    List<PinnedProgramRecord>? pinnedPrograms,
  }) {
    return BottleRecord(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      windowsVersion: windowsVersion ?? this.windowsVersion,
      runtimeSettings: runtimeSettings ?? this.runtimeSettings,
      pinnedPrograms: pinnedPrograms ?? this.pinnedPrograms,
    );
  }

  static BottleRecord? fromJson(Object? value) {
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

    final runtimeSettings = BottleRuntimeSettings.fromJson(
      value['runtimeSettings'],
    );
    if (runtimeSettings == null) {
      return null;
    }

    return BottleRecord(
      id: id,
      name: name,
      path: path,
      windowsVersion: windowsVersion,
      runtimeSettings: runtimeSettings,
      pinnedPrograms: _parsePinnedPrograms(value['pinnedPrograms']),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'path': path,
      'windowsVersion': windowsVersion,
      if (runtimeSettings != const BottleRuntimeSettings())
        'runtimeSettings': runtimeSettings.toJson(),
      if (pinnedPrograms.isNotEmpty)
        'pinnedPrograms': pinnedPrograms
            .map((program) => program.toJson())
            .toList(growable: false),
    };
  }

  @override
  bool operator ==(Object other) {
    return other is BottleRecord &&
        other.id == id &&
        other.name == name &&
        other.path == path &&
        other.windowsVersion == windowsVersion &&
        other.runtimeSettings == runtimeSettings &&
        _listEquals(other.pinnedPrograms, pinnedPrograms);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      path,
      windowsVersion,
      runtimeSettings,
      Object.hashAll(pinnedPrograms),
    );
  }
}

class PinnedProgramRecord {
  const PinnedProgramRecord({
    required this.name,
    required this.path,
    this.removable = false,
    this.iconPath,
  });

  final String name;
  final String path;
  final bool removable;
  final String? iconPath;

  PinnedProgramRecord copyWith({
    String? name,
    String? path,
    bool? removable,
    String? iconPath,
  }) {
    return PinnedProgramRecord(
      name: name ?? this.name,
      path: path ?? this.path,
      removable: removable ?? this.removable,
      iconPath: iconPath ?? this.iconPath,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'name': name,
      'path': path,
      'removable': removable,
      if (iconPath != null) 'iconPath': iconPath,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is PinnedProgramRecord &&
        other.name == name &&
        other.path == path &&
        other.removable == removable &&
        other.iconPath == iconPath;
  }

  @override
  int get hashCode => Object.hash(name, path, removable, iconPath);
}

class ProgramSettingsRecord {
  const ProgramSettingsRecord({
    this.locale = '',
    this.arguments = '',
    this.environment = const <String, String>{},
  });

  final String locale;
  final String arguments;
  final Map<String, String> environment;

  static ProgramSettingsRecord? fromJson(Object? value) {
    final settings = _objectMap(value);
    if (settings == null) {
      return null;
    }

    final locale = settings['locale'];
    final arguments = settings['arguments'];
    final environment = _stringMap(settings['environment']);
    if ((locale != null && locale is! String) ||
        (arguments != null && arguments is! String) ||
        environment == null) {
      return null;
    }

    return ProgramSettingsRecord(
      locale: locale is String ? locale : '',
      arguments: arguments is String ? arguments : '',
      environment: environment,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'locale': locale,
      'arguments': arguments,
      'environment': environment,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is ProgramSettingsRecord &&
        other.locale == locale &&
        other.arguments == arguments &&
        _mapEquals(other.environment, environment);
  }

  @override
  int get hashCode {
    final environmentKeys = environment.keys.toList(growable: false)..sort();
    return Object.hash(
      locale,
      arguments,
      Object.hashAll(
        environmentKeys.map((key) => Object.hash(key, environment[key])),
      ),
    );
  }
}

List<PinnedProgramRecord> _parsePinnedPrograms(Object? value) {
  if (value is! List<dynamic>) {
    return const <PinnedProgramRecord>[];
  }

  final programs = <PinnedProgramRecord>[];
  for (final item in value) {
    if (item is! Map<String, dynamic>) {
      return const <PinnedProgramRecord>[];
    }

    final name = item['name'];
    final path = item['path'];
    final removable = item['removable'];
    final iconPath = item['iconPath'];
    if (name is! String || path is! String) {
      return const <PinnedProgramRecord>[];
    }
    if (iconPath != null && iconPath is! String) {
      return const <PinnedProgramRecord>[];
    }

    programs.add(
      PinnedProgramRecord(
        name: name,
        path: path,
        removable: removable is bool && removable,
        iconPath: iconPath is String ? iconPath : null,
      ),
    );
  }

  return List.unmodifiable(programs);
}

abstract interface class BottleCatalog {
  List<BottleRecord> listBottles();

  BottleRecord? findBottle(String id);
}

abstract interface class AppSettingsRepository {
  AppSettingsRecord read();

  AppSettingsRecord write(AppSettingsRecord settings);
}

abstract interface class BottleRepository implements BottleCatalog {
  BottleCreateResult createBottle(BottleCreateRequest request);

  BottleArchiveExportResult exportBottleArchive(
    BottleArchiveExportRequest request,
  );

  BottleArchiveImportResult importBottleArchive(
    BottleArchiveImportRequest request,
  );

  BottleDeleteResult deleteBottle(String id);

  BottleRenameResult renameBottle(BottleRenameRequest request);

  BottleMoveResult moveBottle(BottleMoveRequest request);

  BottleUpdateResult setWindowsVersion(WindowsVersionUpdateRequest request);

  BottleUpdateResult setRuntimeSettings(RuntimeSettingsUpdateRequest request);

  ProgramPinResult pinProgram(ProgramPinRequest request);

  ProgramUpdateResult unpinProgram(ProgramUnpinRequest request);

  ProgramUpdateResult renamePinnedProgram(ProgramRenameRequest request);

  ProgramSettingsReadResult readProgramSettings(ProgramSettingsRequest request);

  ProgramSettingsUpdateResult setProgramSettings(
    ProgramSettingsUpdateRequest request,
  );
}

abstract interface class BottleProgramRepository {
  List<BottleProgramRecord> listPrograms(BottleRecord bottle);
}

abstract interface class BottlePrefixInitializer {
  BottlePrefixInitializationResult initialize(BottleRecord bottle);
}

sealed class BottlePrefixInitializationResult {
  const BottlePrefixInitializationResult();
}

class BottlePrefixInitialized extends BottlePrefixInitializationResult {
  const BottlePrefixInitialized();
}

class BottlePrefixInitializationFailed
    extends BottlePrefixInitializationResult {
  const BottlePrefixInitializationFailed(this.message);

  final String message;
}

abstract interface class WinetricksVerbRepository {
  WinetricksVerbListResult listVerbs();
}

abstract interface class WinetricksVerbLister {
  WinetricksVerbListResult listVerbs({required String executable});
}

abstract interface class WinetricksScriptInstaller {
  WinetricksScriptInstallResult installIfMissing({required String executable});
}

class BottleProgramRecord {
  const BottleProgramRecord({
    required this.id,
    required this.name,
    required this.path,
    required this.source,
    this.metadata,
  });

  final String id;
  final String name;
  final String path;
  final String source;
  final ProgramMetadataRecord? metadata;

  Map<String, Object?> toJson() {
    final programMetadata = metadata;

    return <String, Object?>{
      'id': id,
      'name': name,
      'path': path,
      'source': source,
      if (programMetadata != null) 'metadata': programMetadata.toJson(),
    };
  }
}

class ProgramMetadataRecord {
  const ProgramMetadataRecord({
    this.architecture,
    this.fileDescription,
    this.productName,
    this.companyName,
    this.fileVersion,
    this.productVersion,
    this.iconPath,
  });

  final String? architecture;
  final String? fileDescription;
  final String? productName;
  final String? companyName;
  final String? fileVersion;
  final String? productVersion;
  final String? iconPath;

  bool get isEmpty {
    return architecture == null &&
        fileDescription == null &&
        productName == null &&
        companyName == null &&
        fileVersion == null &&
        productVersion == null &&
        iconPath == null;
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (architecture != null) 'architecture': architecture,
      if (fileDescription != null) 'fileDescription': fileDescription,
      if (productName != null) 'productName': productName,
      if (companyName != null) 'companyName': companyName,
      if (fileVersion != null) 'fileVersion': fileVersion,
      if (productVersion != null) 'productVersion': productVersion,
      if (iconPath != null) 'iconPath': iconPath,
    };
  }
}

class WineProcessRecord {
  const WineProcessRecord({
    required this.bottleId,
    required this.processId,
    required this.executable,
    this.hostPath,
    this.metadata,
  });

  final String bottleId;
  final String processId;
  final String executable;
  final String? hostPath;
  final ProgramMetadataRecord? metadata;

  Map<String, Object?> toJson() {
    final processMetadata = metadata;

    return <String, Object?>{
      'bottleId': bottleId,
      'processId': processId,
      'executable': executable,
      if (hostPath != null) 'hostPath': hostPath,
      if (processMetadata != null) 'metadata': processMetadata.toJson(),
    };
  }
}

abstract interface class ProgramMetadataExtractor {
  ProgramMetadataRecord? extract({
    required BottleRecord bottle,
    required String programPath,
  });
}

class WinetricksVerbRecord {
  const WinetricksVerbRecord({
    required this.id,
    required this.name,
    required this.description,
  });

  final String id;
  final String name;
  final String description;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'description': description,
    };
  }
}

class WinetricksCategoryRecord {
  WinetricksCategoryRecord({
    required this.id,
    required this.name,
    required List<WinetricksVerbRecord> verbs,
  }) : verbs = List.unmodifiable(verbs);

  final String id;
  final String name;
  final List<WinetricksVerbRecord> verbs;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'verbs': verbs.map((verb) => verb.toJson()).toList(growable: false),
    };
  }
}

sealed class WinetricksVerbListResult {
  const WinetricksVerbListResult();
}

class WinetricksVerbListCompleted extends WinetricksVerbListResult {
  WinetricksVerbListCompleted({
    required List<WinetricksCategoryRecord> categories,
  }) : categories = List.unmodifiable(categories);

  final List<WinetricksCategoryRecord> categories;
}

class WinetricksVerbListFailed extends WinetricksVerbListResult {
  const WinetricksVerbListFailed(this.message);

  final String message;
}

sealed class WinetricksScriptInstallResult {
  const WinetricksScriptInstallResult();
}

class WinetricksScriptInstallCompleted extends WinetricksScriptInstallResult {
  const WinetricksScriptInstallCompleted();
}

class WinetricksScriptInstallFailed extends WinetricksScriptInstallResult {
  const WinetricksScriptInstallFailed(this.message);

  final String message;
}

class DartIoWinetricksVerbRepository implements WinetricksVerbRepository {
  const DartIoWinetricksVerbRepository({
    required this.runtimeRoot,
    this.hostPlatform = KonyakHostPlatform.macos,
    this.lister = const DartIoWinetricksVerbLister(),
    this.scriptInstaller = const DartIoWinetricksScriptInstaller(),
  });

  factory DartIoWinetricksVerbRepository.current({
    Map<String, String>? environment,
    KonyakHostPlatform? hostPlatform,
    WinetricksVerbLister lister = const DartIoWinetricksVerbLister(),
    WinetricksScriptInstaller scriptInstaller =
        const DartIoWinetricksScriptInstaller(),
  }) {
    final resolvedEnvironment = environment ?? Platform.environment;
    final resolvedHostPlatform = hostPlatform ?? _currentHostPlatform();
    return DartIoWinetricksVerbRepository(
      runtimeRoot: switch (resolvedHostPlatform) {
        KonyakHostPlatform.macos => _macosWineRuntimeRoot(resolvedEnvironment),
        KonyakHostPlatform.linux => _linuxWineRuntimeRoot(resolvedEnvironment),
      },
      hostPlatform: resolvedHostPlatform,
      lister: lister,
      scriptInstaller: scriptInstaller,
    );
  }

  final String runtimeRoot;
  final KonyakHostPlatform hostPlatform;
  final WinetricksVerbLister lister;
  final WinetricksScriptInstaller scriptInstaller;

  @override
  WinetricksVerbListResult listVerbs() {
    if (hostPlatform == KonyakHostPlatform.linux) {
      final managedExecutable = _joinPath(runtimeRoot, const ['winetricks']);
      return lister.listVerbs(
        executable: File(managedExecutable).existsSync()
            ? managedExecutable
            : 'winetricks',
      );
    }

    final verbsFile = File(_joinPath(runtimeRoot, const ['verbs.txt']));
    if (verbsFile.existsSync()) {
      try {
        return WinetricksVerbListCompleted(
          categories: parseWinetricksVerbs(verbsFile.readAsStringSync()),
        );
      } on FileSystemException catch (error) {
        return WinetricksVerbListFailed(error.message);
      }
    }

    final executable = _joinPath(runtimeRoot, const ['winetricks']);
    final installResult = scriptInstaller.installIfMissing(
      executable: executable,
    );
    switch (installResult) {
      case WinetricksScriptInstallCompleted():
        return lister.listVerbs(executable: executable);
      case WinetricksScriptInstallFailed(:final message):
        return WinetricksVerbListFailed(message);
    }
  }
}

class DartIoWinetricksScriptInstaller implements WinetricksScriptInstaller {
  const DartIoWinetricksScriptInstaller();

  @override
  WinetricksScriptInstallResult installIfMissing({required String executable}) {
    final target = File(executable);
    if (target.existsSync()) {
      return const WinetricksScriptInstallCompleted();
    }

    final temporaryPath = '$executable.download';
    final temporaryFile = File(temporaryPath);

    try {
      target.parent.createSync(recursive: true);
      final downloadResult = Process.runSync('curl', <String>[
        '--fail',
        '--location',
        '--silent',
        '--show-error',
        '--output',
        temporaryPath,
        winetricksScriptUrl,
      ], runInShell: false);

      if (downloadResult.exitCode != 0) {
        _deleteFileIfPresent(temporaryFile);
        return WinetricksScriptInstallFailed(
          _commandFailureMessage('download Winetricks', downloadResult),
        );
      }

      temporaryFile.renameSync(executable);

      final chmodResult = Process.runSync('chmod', <String>[
        '755',
        executable,
      ], runInShell: false);
      if (chmodResult.exitCode != 0) {
        return WinetricksScriptInstallFailed(
          _commandFailureMessage('mark Winetricks executable', chmodResult),
        );
      }

      return const WinetricksScriptInstallCompleted();
    } on ProcessException catch (error) {
      _deleteFileIfPresent(temporaryFile);
      return WinetricksScriptInstallFailed(
        _programRunnerFailureMessage(
          executable: error.executable,
          message: error.message,
        ),
      );
    } on FileSystemException catch (error) {
      _deleteFileIfPresent(temporaryFile);
      return WinetricksScriptInstallFailed(error.message);
    }
  }
}

void _deleteFileIfPresent(File file) {
  try {
    if (file.existsSync()) {
      file.deleteSync();
    }
  } on FileSystemException {
    // Best-effort cleanup only; the original failure is more useful.
  }
}

class DartIoWinetricksVerbLister implements WinetricksVerbLister {
  const DartIoWinetricksVerbLister();

  @override
  WinetricksVerbListResult listVerbs({required String executable}) {
    try {
      final result = Process.runSync(
        executable,
        const <String>['list-all'],
        environment: const <String, String>{'LANG': 'C'},
        runInShell: false,
      );

      if (result.exitCode != 0) {
        return WinetricksVerbListFailed(
          _commandFailureMessage('winetricks list-all', result),
        );
      }

      return WinetricksVerbListCompleted(
        categories: parseWinetricksVerbs(_processOutputToString(result.stdout)),
      );
    } on ProcessException catch (error) {
      return WinetricksVerbListFailed(
        _programRunnerFailureMessage(
          executable: error.executable,
          message: error.message,
        ),
      );
    }
  }
}

class DartIoBottleProgramRepository implements BottleProgramRepository {
  const DartIoBottleProgramRepository({
    ProgramMetadataExtractor metadataExtractor =
        const DartIoProgramMetadataExtractor(),
  }) : _metadataExtractor = metadataExtractor;

  final ProgramMetadataExtractor _metadataExtractor;

  @override
  List<BottleProgramRecord> listPrograms(BottleRecord bottle) {
    final programs = <BottleProgramRecord>[];
    for (final source in _bottleStartMenuSources(bottle)) {
      final directory = Directory(source.path);
      if (!directory.existsSync()) {
        continue;
      }

      for (final entity in directory.listSync(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File || !_isShortcutPath(entity.path)) {
          continue;
        }

        final name = _shortcutProgramName(entity.path);
        final id = _uniqueProgramId(
          baseId: _bottleIdFromName(name),
          existing: programs,
        );
        final metadata = _metadataExtractor.extract(
          bottle: bottle,
          programPath: _metadataProgramPath(
            bottle: bottle,
            programPath: entity.path,
          ),
        );
        programs.add(
          BottleProgramRecord(
            id: id,
            name: name,
            path: entity.path,
            source: source.id,
            metadata: metadata,
          ),
        );
      }
    }

    for (final pinnedProgram in bottle.pinnedPrograms) {
      final id = _uniqueProgramId(
        baseId: _bottleIdFromName(pinnedProgram.name),
        existing: programs,
      );
      final metadata = _metadataExtractor.extract(
        bottle: bottle,
        programPath: _metadataProgramPath(
          bottle: bottle,
          programPath: pinnedProgram.path,
        ),
      );
      programs.add(
        BottleProgramRecord(
          id: id,
          name: pinnedProgram.name,
          path: pinnedProgram.path,
          source: 'pinned',
          metadata: metadata,
        ),
      );
    }

    programs.sort((left, right) => left.name.compareTo(right.name));
    return List.unmodifiable(programs);
  }
}

class DartIoProgramMetadataExtractor implements ProgramMetadataExtractor {
  const DartIoProgramMetadataExtractor();

  @override
  ProgramMetadataRecord? extract({
    required BottleRecord bottle,
    required String programPath,
  }) {
    try {
      final file = File(programPath);
      if (!file.existsSync()) {
        return null;
      }

      final image = _PortableExecutableImage.parse(file.readAsBytesSync());
      if (image == null) {
        return null;
      }

      final versionStrings = _peVersionStrings(image);
      final iconPath = _extractPeIcon(
        image: image,
        bottle: bottle,
        programPath: programPath,
        fileStat: file.statSync(),
      );
      final metadata = ProgramMetadataRecord(
        architecture: image.architecture,
        fileDescription: versionStrings['FileDescription'],
        productName: versionStrings['ProductName'],
        companyName: versionStrings['CompanyName'],
        fileVersion: versionStrings['FileVersion'],
        productVersion: versionStrings['ProductVersion'],
        iconPath: iconPath,
      );

      return metadata.isEmpty ? null : metadata;
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    } on RangeError {
      return null;
    }
  }
}

class DartIoBottlePrefixInitializer implements BottlePrefixInitializer {
  const DartIoBottlePrefixInitializer({
    required this.programRunPlanner,
    required this.programRunner,
  });

  final ProgramRunPlanner programRunPlanner;
  final ProgramRunner programRunner;

  @override
  BottlePrefixInitializationResult initialize(BottleRecord bottle) {
    final request = programRunPlanner.planPrefixInitialization(bottle: bottle);
    final result = programRunner.run(request);

    return switch (result) {
      ProgramRunCompleted(:final processExitCode) when processExitCode == 0 =>
        const BottlePrefixInitialized(),
      ProgramRunCompleted(:final processExitCode) =>
        BottlePrefixInitializationFailed(
          'wineboot exited with code $processExitCode. See ${request.logPath}.',
        ),
      ProgramRunFailed(:final message) => BottlePrefixInitializationFailed(
        message,
      ),
    };
  }
}

class BottleCreateRequest {
  const BottleCreateRequest({required this.name, required this.windowsVersion});

  final String name;
  final String windowsVersion;
}

class BottleArchiveExportRequest {
  const BottleArchiveExportRequest({
    required this.bottleId,
    required this.archivePath,
  });

  final String bottleId;
  final String archivePath;
}

class BottleArchiveImportRequest {
  const BottleArchiveImportRequest({required this.archivePath});

  final String archivePath;
}

class BottleArchiveRecord {
  const BottleArchiveRecord({
    required this.bottleId,
    required this.archivePath,
  });

  final String bottleId;
  final String archivePath;

  Map<String, Object?> toJson() {
    return <String, Object?>{'bottleId': bottleId, 'archivePath': archivePath};
  }
}

sealed class BottleCreateResult {
  const BottleCreateResult();
}

class BottleCreated extends BottleCreateResult {
  const BottleCreated(this.bottle);

  final BottleRecord bottle;
}

class BottleCreateConflict extends BottleCreateResult {
  const BottleCreateConflict(this.bottleId);

  final String bottleId;
}

sealed class BottleArchiveExportResult {
  const BottleArchiveExportResult();
}

class BottleArchiveExported extends BottleArchiveExportResult {
  const BottleArchiveExported(this.archive);

  final BottleArchiveRecord archive;
}

class BottleArchiveExportMissing extends BottleArchiveExportResult {
  const BottleArchiveExportMissing(this.bottleId);

  final String bottleId;
}

class BottleArchiveExportFailed extends BottleArchiveExportResult {
  const BottleArchiveExportFailed(this.message);

  final String message;
}

sealed class BottleArchiveImportResult {
  const BottleArchiveImportResult();
}

class BottleArchiveImported extends BottleArchiveImportResult {
  const BottleArchiveImported(this.bottle);

  final BottleRecord bottle;
}

class BottleArchiveImportConflict extends BottleArchiveImportResult {
  const BottleArchiveImportConflict(this.bottleId);

  final String bottleId;
}

class BottleArchiveImportFailed extends BottleArchiveImportResult {
  const BottleArchiveImportFailed(this.message);

  final String message;
}

sealed class BottleDeleteResult {
  const BottleDeleteResult();
}

class BottleDeleted extends BottleDeleteResult {
  const BottleDeleted(this.bottle);

  final BottleRecord bottle;
}

class BottleDeleteMissing extends BottleDeleteResult {
  const BottleDeleteMissing(this.bottleId);

  final String bottleId;
}

class BottleRenameRequest {
  const BottleRenameRequest({required this.bottleId, required this.name});

  final String bottleId;
  final String name;
}

sealed class BottleRenameResult {
  const BottleRenameResult();
}

class BottleRenamed extends BottleRenameResult {
  const BottleRenamed(this.bottle);

  final BottleRecord bottle;
}

class BottleRenameMissing extends BottleRenameResult {
  const BottleRenameMissing(this.bottleId);

  final String bottleId;
}

class BottleRenameConflict extends BottleRenameResult {
  const BottleRenameConflict(this.bottleId);

  final String bottleId;
}

class BottleMoveRequest {
  const BottleMoveRequest({required this.bottleId, required this.path});

  final String bottleId;
  final String path;
}

sealed class BottleMoveResult {
  const BottleMoveResult();
}

class BottleMoved extends BottleMoveResult {
  const BottleMoved(this.bottle);

  final BottleRecord bottle;
}

class BottleMoveMissing extends BottleMoveResult {
  const BottleMoveMissing(this.bottleId);

  final String bottleId;
}

class BottleMoveConflict extends BottleMoveResult {
  const BottleMoveConflict(this.path);

  final String path;
}

class WindowsVersionUpdateRequest {
  const WindowsVersionUpdateRequest({
    required this.bottleId,
    required this.windowsVersion,
  });

  final String bottleId;
  final String windowsVersion;
}

class RuntimeSettingsUpdateRequest {
  const RuntimeSettingsUpdateRequest({
    required this.bottleId,
    required this.runtimeSettings,
  });

  final String bottleId;
  final BottleRuntimeSettings runtimeSettings;
}

sealed class BottleUpdateResult {
  const BottleUpdateResult();
}

class BottleUpdated extends BottleUpdateResult {
  const BottleUpdated(this.bottle);

  final BottleRecord bottle;
}

class BottleUpdateMissing extends BottleUpdateResult {
  const BottleUpdateMissing(this.bottleId);

  final String bottleId;
}

class ProgramPinRequest {
  const ProgramPinRequest({
    required this.bottleId,
    required this.name,
    required this.programPath,
  });

  final String bottleId;
  final String name;
  final String programPath;
}

sealed class ProgramPinResult {
  const ProgramPinResult();
}

class ProgramPinned extends ProgramPinResult {
  const ProgramPinned(this.bottle);

  final BottleRecord bottle;
}

class ProgramPinMissing extends ProgramPinResult {
  const ProgramPinMissing(this.bottleId);

  final String bottleId;
}

class ProgramPinConflict extends ProgramPinResult {
  const ProgramPinConflict(this.programPath);

  final String programPath;
}

class ProgramUnpinRequest {
  const ProgramUnpinRequest({
    required this.bottleId,
    required this.programPath,
  });

  final String bottleId;
  final String programPath;
}

class ProgramRenameRequest {
  const ProgramRenameRequest({
    required this.bottleId,
    required this.programPath,
    required this.name,
  });

  final String bottleId;
  final String programPath;
  final String name;
}

class _PinnedProgramLauncherManifest {
  const _PinnedProgramLauncherManifest({
    required this.launcherId,
    required this.bottleId,
    required this.programPath,
    required this.programName,
  });

  final String launcherId;
  final String bottleId;
  final String programPath;
  final String programName;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': cliSchemaVersion,
      'createdBy': konyakMacosBundleIdentifier,
      'launcherId': launcherId,
      'bottleId': bottleId,
      'programPath': programPath,
      'programName': programName,
    };
  }
}

class WineProcessTerminationRequest {
  const WineProcessTerminationRequest({
    required this.bottleId,
    required this.processId,
  });

  final String bottleId;
  final String processId;
}

class WineProcessGroupTerminationRequest {
  const WineProcessGroupTerminationRequest({this.bottleId});

  final String? bottleId;
}

sealed class ProgramUpdateResult {
  const ProgramUpdateResult();
}

class ProgramUpdated extends ProgramUpdateResult {
  const ProgramUpdated(this.bottle);

  final BottleRecord bottle;
}

class ProgramUpdateMissingBottle extends ProgramUpdateResult {
  const ProgramUpdateMissingBottle(this.bottleId);

  final String bottleId;
}

class ProgramUpdateMissingProgram extends ProgramUpdateResult {
  const ProgramUpdateMissingProgram(this.programPath);

  final String programPath;
}

class ProgramSettingsRequest {
  const ProgramSettingsRequest({
    required this.bottleId,
    required this.programPath,
  });

  final String bottleId;
  final String programPath;
}

class ProgramSettingsUpdateRequest {
  const ProgramSettingsUpdateRequest({
    required this.bottleId,
    required this.programPath,
    required this.settings,
  });

  final String bottleId;
  final String programPath;
  final ProgramSettingsRecord settings;
}

sealed class ProgramSettingsReadResult {
  const ProgramSettingsReadResult();
}

class ProgramSettingsRead extends ProgramSettingsReadResult {
  const ProgramSettingsRead(this.settings);

  final ProgramSettingsRecord settings;
}

class ProgramSettingsReadMissingBottle extends ProgramSettingsReadResult {
  const ProgramSettingsReadMissingBottle(this.bottleId);

  final String bottleId;
}

sealed class ProgramSettingsUpdateResult {
  const ProgramSettingsUpdateResult();
}

class ProgramSettingsUpdated extends ProgramSettingsUpdateResult {
  const ProgramSettingsUpdated(this.settings);

  final ProgramSettingsRecord settings;
}

class ProgramSettingsUpdateMissingBottle extends ProgramSettingsUpdateResult {
  const ProgramSettingsUpdateMissingBottle(this.bottleId);

  final String bottleId;
}

class BottleRepositoryException implements Exception {
  const BottleRepositoryException(this.message);

  final String message;
}

class AppSettingsRepositoryException implements Exception {
  const AppSettingsRepositoryException(this.message);

  final String message;
}

BottleRepository defaultBottleRepositoryFromEnvironment(
  Map<String, String> environment, {
  KonyakHostPlatform? hostPlatform,
  AppSettingsRecord? appSettings,
}) {
  final platform = hostPlatform ?? _currentHostPlatform();
  return _defaultFileBottleRepository(
    dataHome: _resolveBottleDataHome(environment, hostPlatform: platform),
    defaultBottlePath:
        appSettings?.defaultBottlePath ??
        _defaultBottlePath(environment, hostPlatform: platform),
  );
}

AppSettingsRepository defaultAppSettingsRepositoryFromEnvironment(
  Map<String, String> environment, {
  KonyakHostPlatform? hostPlatform,
}) {
  final platform = hostPlatform ?? _currentHostPlatform();
  return FileAppSettingsRepository.fromEnvironment(
    environment,
    hostPlatform: platform,
  );
}

BottleRepository _defaultFileBottleRepository({
  required String dataHome,
  String? defaultBottlePath,
}) {
  final defaultBottleDirectory = _joinPath(dataHome, const ['bottles']);
  if (defaultBottlePath == null ||
      _normalizeFilesystemPath(defaultBottlePath) ==
          _normalizeFilesystemPath(defaultBottleDirectory)) {
    return FileBottleRepository(
      dataHome: dataHome,
      bottleDirectory: defaultBottlePath,
    );
  }

  return CompositeBottleRepository(
    catalogs: <BottleCatalog>[FileBottleRepository(dataHome: dataHome)],
    writableRepository: FileBottleRepository(
      dataHome: dataHome,
      bottleDirectory: defaultBottlePath,
    ),
  );
}

class MemoryAppSettingsRepository implements AppSettingsRepository {
  MemoryAppSettingsRepository(this._settings);

  AppSettingsRecord _settings;

  @override
  AppSettingsRecord read() {
    return _settings;
  }

  @override
  AppSettingsRecord write(AppSettingsRecord settings) {
    _settings = settings;
    return _settings;
  }
}

class FileAppSettingsRepository implements AppSettingsRepository {
  const FileAppSettingsRepository({
    required this.configHome,
    required this.fallbackDefaultBottlePath,
  });

  factory FileAppSettingsRepository.fromEnvironment(
    Map<String, String> environment, {
    KonyakHostPlatform? hostPlatform,
  }) {
    final platform = hostPlatform ?? _currentHostPlatform();
    return FileAppSettingsRepository(
      configHome: _resolveConfigHome(environment, hostPlatform: platform),
      fallbackDefaultBottlePath: _defaultBottlePath(
        environment,
        hostPlatform: platform,
      ),
    );
  }

  final String configHome;
  final String fallbackDefaultBottlePath;

  @override
  AppSettingsRecord read() {
    final file = File(_appSettingsJsonPath(configHome));
    if (!file.existsSync()) {
      return AppSettingsRecord(defaultBottlePath: fallbackDefaultBottlePath);
    }

    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, Object?> ||
          decoded['schemaVersion'] != cliSchemaVersion) {
        throw const FormatException('Unsupported app settings schema.');
      }

      final settings = AppSettingsRecord.fromJson(
        decoded['appSettings'],
        fallbackDefaultBottlePath: fallbackDefaultBottlePath,
      );
      if (settings == null) {
        throw const FormatException('Invalid app settings record.');
      }

      return settings;
    } on FileSystemException catch (error) {
      throw AppSettingsRepositoryException(error.message);
    } on FormatException catch (error) {
      throw AppSettingsRepositoryException(error.message);
    }
  }

  @override
  AppSettingsRecord write(AppSettingsRecord settings) {
    try {
      final file = File(_appSettingsJsonPath(configHome));
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(<String, Object?>{
          'schemaVersion': cliSchemaVersion,
          'appSettings': settings.toJson(),
        }),
      );
      return settings;
    } on FileSystemException catch (error) {
      throw AppSettingsRepositoryException(error.message);
    }
  }
}

class StaticBottleCatalog implements BottleCatalog {
  const StaticBottleCatalog(this._bottles);

  final List<BottleRecord> _bottles;

  @override
  List<BottleRecord> listBottles() {
    return List.unmodifiable(_bottles);
  }

  @override
  BottleRecord? findBottle(String id) {
    for (final bottle in _bottles) {
      if (bottle.id == id) {
        return bottle;
      }
    }

    return null;
  }
}

class MemoryBottleRepository implements BottleRepository {
  MemoryBottleRepository({
    required this.dataHome,
    Iterable<BottleRecord> bottles = const <BottleRecord>[],
    Map<String, ProgramSettingsRecord> programSettings =
        const <String, ProgramSettingsRecord>{},
    ProgramMetadataExtractor programMetadataExtractor =
        const DartIoProgramMetadataExtractor(),
  }) : _bottles = <String, BottleRecord>{
         for (final bottle in bottles) bottle.id: bottle,
       },
       _programSettings = Map<String, ProgramSettingsRecord>.of(
         programSettings,
       ),
       _programMetadataExtractor = programMetadataExtractor;

  final String dataHome;
  final Map<String, BottleRecord> _bottles;
  final Map<String, ProgramSettingsRecord> _programSettings;
  final ProgramMetadataExtractor _programMetadataExtractor;

  @override
  List<BottleRecord> listBottles() {
    final bottles =
        _bottles.values
            .toList(growable: false)
            .map((bottle) {
              final updated = _bottleWithPinnedProgramIcons(
                bottle,
                programMetadataExtractor: _programMetadataExtractor,
              );
              if (updated != bottle) {
                _bottles[bottle.id] = updated;
              }
              return updated;
            })
            .toList(growable: false)
          ..sort((left, right) => left.id.compareTo(right.id));

    return List.unmodifiable(bottles);
  }

  @override
  BottleRecord? findBottle(String id) {
    final bottle = _bottles[id];
    if (bottle == null) {
      return null;
    }

    final updated = _bottleWithPinnedProgramIcons(
      bottle,
      programMetadataExtractor: _programMetadataExtractor,
    );
    if (updated != bottle) {
      _bottles[id] = updated;
    }

    return updated;
  }

  @override
  BottleCreateResult createBottle(BottleCreateRequest request) {
    final bottle = _bottleFromCreateRequest(request, dataHome);

    if (_bottles.containsKey(bottle.id)) {
      return BottleCreateConflict(bottle.id);
    }

    _bottles[bottle.id] = bottle;

    return BottleCreated(bottle);
  }

  @override
  BottleArchiveExportResult exportBottleArchive(
    BottleArchiveExportRequest request,
  ) {
    final bottle = findBottle(request.bottleId);
    if (bottle == null) {
      return BottleArchiveExportMissing(request.bottleId);
    }

    return _exportBottleArchive(
      bottle: bottle,
      archivePath: request.archivePath,
    );
  }

  @override
  BottleArchiveImportResult importBottleArchive(
    BottleArchiveImportRequest request,
  ) {
    return _importBottleArchive(
      archivePath: request.archivePath,
      bottleDirectory: _joinPath(dataHome, const ['bottles']),
      hasBottle: _bottles.containsKey,
      onImported: (bottle) {
        _bottles[bottle.id] = bottle;
      },
    );
  }

  @override
  BottleDeleteResult deleteBottle(String id) {
    final bottle = _bottles.remove(id);
    if (bottle == null) {
      return BottleDeleteMissing(id);
    }

    return BottleDeleted(bottle);
  }

  @override
  BottleRenameResult renameBottle(BottleRenameRequest request) {
    final bottle = _bottles[request.bottleId];
    if (bottle == null) {
      return BottleRenameMissing(request.bottleId);
    }

    final renamed = _renamedMemoryBottle(
      bottle: bottle,
      name: request.name,
      dataHome: dataHome,
    );
    final conflictingBottle = _bottles[renamed.id];
    if (conflictingBottle != null && conflictingBottle.id != bottle.id) {
      return BottleRenameConflict(renamed.id);
    }

    _bottles.remove(bottle.id);
    _bottles[renamed.id] = renamed;

    return BottleRenamed(renamed);
  }

  @override
  BottleMoveResult moveBottle(BottleMoveRequest request) {
    final bottle = _bottles[request.bottleId];
    if (bottle == null) {
      return BottleMoveMissing(request.bottleId);
    }

    if (_hasBottleAtPath(_bottles.values, request.path, exceptId: bottle.id)) {
      return BottleMoveConflict(request.path);
    }

    final moved = bottle.copyWith(path: request.path);
    _bottles[bottle.id] = moved;

    return BottleMoved(moved);
  }

  @override
  BottleUpdateResult setWindowsVersion(WindowsVersionUpdateRequest request) {
    final bottle = _bottles[request.bottleId];
    if (bottle == null) {
      return BottleUpdateMissing(request.bottleId);
    }

    final updated = bottle.copyWith(windowsVersion: request.windowsVersion);
    _bottles[request.bottleId] = updated;

    return BottleUpdated(updated);
  }

  @override
  BottleUpdateResult setRuntimeSettings(RuntimeSettingsUpdateRequest request) {
    final bottle = _bottles[request.bottleId];
    if (bottle == null) {
      return BottleUpdateMissing(request.bottleId);
    }

    final updated = bottle.copyWith(runtimeSettings: request.runtimeSettings);
    _bottles[request.bottleId] = updated;

    return BottleUpdated(updated);
  }

  @override
  ProgramPinResult pinProgram(ProgramPinRequest request) {
    final bottle = _bottles[request.bottleId];
    if (bottle == null) {
      return ProgramPinMissing(request.bottleId);
    }

    if (_hasPinnedProgram(bottle, request.programPath)) {
      return ProgramPinConflict(request.programPath);
    }

    final updated = _bottleWithPinnedProgram(
      bottle,
      request,
      programMetadataExtractor: _programMetadataExtractor,
    );
    _bottles[request.bottleId] = updated;

    return ProgramPinned(updated);
  }

  @override
  ProgramUpdateResult unpinProgram(ProgramUnpinRequest request) {
    final bottle = _bottles[request.bottleId];
    if (bottle == null) {
      return ProgramUpdateMissingBottle(request.bottleId);
    }

    if (!_hasPinnedProgram(bottle, request.programPath)) {
      return ProgramUpdateMissingProgram(request.programPath);
    }

    final updated = _bottleWithoutPinnedProgram(bottle, request.programPath);
    _bottles[request.bottleId] = updated;

    return ProgramUpdated(updated);
  }

  @override
  ProgramUpdateResult renamePinnedProgram(ProgramRenameRequest request) {
    final bottle = _bottles[request.bottleId];
    if (bottle == null) {
      return ProgramUpdateMissingBottle(request.bottleId);
    }

    if (!_hasPinnedProgram(bottle, request.programPath)) {
      return ProgramUpdateMissingProgram(request.programPath);
    }

    final updated = _bottleWithRenamedPinnedProgram(bottle, request);
    _bottles[request.bottleId] = updated;

    return ProgramUpdated(updated);
  }

  @override
  ProgramSettingsReadResult readProgramSettings(
    ProgramSettingsRequest request,
  ) {
    final bottle = _bottles[request.bottleId];
    if (bottle == null) {
      return ProgramSettingsReadMissingBottle(request.bottleId);
    }

    return ProgramSettingsRead(
      _programSettings[_programSettingsKey(
            bottleId: request.bottleId,
            programPath: request.programPath,
          )] ??
          const ProgramSettingsRecord(),
    );
  }

  @override
  ProgramSettingsUpdateResult setProgramSettings(
    ProgramSettingsUpdateRequest request,
  ) {
    final bottle = _bottles[request.bottleId];
    if (bottle == null) {
      return ProgramSettingsUpdateMissingBottle(request.bottleId);
    }

    _programSettings[_programSettingsKey(
          bottleId: request.bottleId,
          programPath: request.programPath,
        )] =
        request.settings;

    return ProgramSettingsUpdated(request.settings);
  }
}

class CompositeBottleRepository implements BottleRepository {
  CompositeBottleRepository({
    required Iterable<BottleCatalog> catalogs,
    required this.writableRepository,
  }) : _catalogs = List.unmodifiable(catalogs);

  final List<BottleCatalog> _catalogs;
  final BottleRepository writableRepository;

  @override
  List<BottleRecord> listBottles() {
    final records = <String, BottleRecord>{};
    for (final bottle in writableRepository.listBottles()) {
      records[bottle.id] = bottle;
    }

    for (final catalog in _catalogs) {
      for (final bottle in catalog.listBottles()) {
        records.putIfAbsent(bottle.id, () => bottle);
      }
    }

    final bottles = records.values.toList(growable: false)
      ..sort((left, right) => left.id.compareTo(right.id));

    return List.unmodifiable(bottles);
  }

  @override
  BottleRecord? findBottle(String id) {
    final localBottle = writableRepository.findBottle(id);
    if (localBottle != null) {
      return localBottle;
    }

    for (final catalog in _catalogs) {
      final bottle = catalog.findBottle(id);
      if (bottle != null) {
        return bottle;
      }
    }

    return null;
  }

  @override
  BottleCreateResult createBottle(BottleCreateRequest request) {
    return writableRepository.createBottle(request);
  }

  @override
  BottleArchiveExportResult exportBottleArchive(
    BottleArchiveExportRequest request,
  ) {
    final bottle = findBottle(request.bottleId);
    if (bottle == null) {
      return BottleArchiveExportMissing(request.bottleId);
    }

    return _exportBottleArchive(
      bottle: bottle,
      archivePath: request.archivePath,
    );
  }

  @override
  BottleArchiveImportResult importBottleArchive(
    BottleArchiveImportRequest request,
  ) {
    return writableRepository.importBottleArchive(request);
  }

  @override
  BottleDeleteResult deleteBottle(String id) {
    final writableDelete = writableRepository.deleteBottle(id);
    if (writableDelete is BottleDeleted) {
      return writableDelete;
    }

    for (final catalog in _catalogs) {
      if (catalog is! BottleRepository) {
        continue;
      }

      final catalogDelete = catalog.deleteBottle(id);
      if (catalogDelete is BottleDeleted) {
        return catalogDelete;
      }
    }

    return BottleDeleteMissing(id);
  }

  @override
  BottleRenameResult renameBottle(BottleRenameRequest request) {
    final writableRename = writableRepository.renameBottle(request);
    if (writableRename is BottleRenamed ||
        writableRename is BottleRenameConflict) {
      return writableRename;
    }

    for (final catalog in _catalogs) {
      if (catalog is! BottleRepository) {
        continue;
      }

      final catalogRename = catalog.renameBottle(request);
      if (catalogRename is BottleRenamed ||
          catalogRename is BottleRenameConflict) {
        return catalogRename;
      }
    }

    return BottleRenameMissing(request.bottleId);
  }

  @override
  BottleMoveResult moveBottle(BottleMoveRequest request) {
    final writableMove = writableRepository.moveBottle(request);
    if (writableMove is BottleMoved || writableMove is BottleMoveConflict) {
      return writableMove;
    }

    for (final catalog in _catalogs) {
      if (catalog is! BottleRepository) {
        continue;
      }

      final catalogMove = catalog.moveBottle(request);
      if (catalogMove is BottleMoved || catalogMove is BottleMoveConflict) {
        return catalogMove;
      }
    }

    return BottleMoveMissing(request.bottleId);
  }

  @override
  BottleUpdateResult setWindowsVersion(WindowsVersionUpdateRequest request) {
    return writableRepository.setWindowsVersion(request);
  }

  @override
  BottleUpdateResult setRuntimeSettings(RuntimeSettingsUpdateRequest request) {
    final writableUpdate = writableRepository.setRuntimeSettings(request);
    if (writableUpdate is BottleUpdated) {
      return writableUpdate;
    }

    for (final catalog in _catalogs) {
      if (catalog is! BottleRepository) {
        continue;
      }

      final catalogUpdate = catalog.setRuntimeSettings(request);
      if (catalogUpdate is BottleUpdated) {
        return catalogUpdate;
      }
    }

    return BottleUpdateMissing(request.bottleId);
  }

  @override
  ProgramPinResult pinProgram(ProgramPinRequest request) {
    final writablePin = writableRepository.pinProgram(request);
    if (writablePin is ProgramPinned || writablePin is ProgramPinConflict) {
      return writablePin;
    }

    for (final catalog in _catalogs) {
      if (catalog is! BottleRepository) {
        continue;
      }

      final catalogPin = catalog.pinProgram(request);
      if (catalogPin is ProgramPinned || catalogPin is ProgramPinConflict) {
        return catalogPin;
      }
    }

    return ProgramPinMissing(request.bottleId);
  }

  @override
  ProgramUpdateResult unpinProgram(ProgramUnpinRequest request) {
    final writableUpdate = writableRepository.unpinProgram(request);
    if (writableUpdate is ProgramUpdated ||
        writableUpdate is ProgramUpdateMissingProgram) {
      return writableUpdate;
    }

    for (final catalog in _catalogs) {
      if (catalog is! BottleRepository) {
        continue;
      }

      final catalogUpdate = catalog.unpinProgram(request);
      if (catalogUpdate is ProgramUpdated ||
          catalogUpdate is ProgramUpdateMissingProgram) {
        return catalogUpdate;
      }
    }

    return ProgramUpdateMissingBottle(request.bottleId);
  }

  @override
  ProgramUpdateResult renamePinnedProgram(ProgramRenameRequest request) {
    final writableUpdate = writableRepository.renamePinnedProgram(request);
    if (writableUpdate is ProgramUpdated ||
        writableUpdate is ProgramUpdateMissingProgram) {
      return writableUpdate;
    }

    for (final catalog in _catalogs) {
      if (catalog is! BottleRepository) {
        continue;
      }

      final catalogUpdate = catalog.renamePinnedProgram(request);
      if (catalogUpdate is ProgramUpdated ||
          catalogUpdate is ProgramUpdateMissingProgram) {
        return catalogUpdate;
      }
    }

    return ProgramUpdateMissingBottle(request.bottleId);
  }

  @override
  ProgramSettingsReadResult readProgramSettings(
    ProgramSettingsRequest request,
  ) {
    final writableRead = writableRepository.readProgramSettings(request);
    if (writableRead is ProgramSettingsRead) {
      return writableRead;
    }

    for (final catalog in _catalogs) {
      if (catalog is! BottleRepository) {
        continue;
      }

      final catalogRead = catalog.readProgramSettings(request);
      if (catalogRead is ProgramSettingsRead) {
        return catalogRead;
      }
    }

    return ProgramSettingsReadMissingBottle(request.bottleId);
  }

  @override
  ProgramSettingsUpdateResult setProgramSettings(
    ProgramSettingsUpdateRequest request,
  ) {
    final writableUpdate = writableRepository.setProgramSettings(request);
    if (writableUpdate is ProgramSettingsUpdated) {
      return writableUpdate;
    }

    for (final catalog in _catalogs) {
      if (catalog is! BottleRepository) {
        continue;
      }

      final catalogUpdate = catalog.setProgramSettings(request);
      if (catalogUpdate is ProgramSettingsUpdated) {
        return catalogUpdate;
      }
    }

    return ProgramSettingsUpdateMissingBottle(request.bottleId);
  }
}

class FileBottleRepository implements BottleRepository {
  FileBottleRepository({
    required this.dataHome,
    String? bottleDirectory,
    ProgramMetadataExtractor programMetadataExtractor =
        const DartIoProgramMetadataExtractor(),
  }) : bottleDirectory =
           bottleDirectory ?? _joinPath(dataHome, const ['bottles']),
       _programMetadataExtractor = programMetadataExtractor;

  factory FileBottleRepository.fromEnvironment(
    Map<String, String> environment, {
    String? bottleDirectory,
  }) {
    return FileBottleRepository(
      dataHome: _resolveDataHome(environment),
      bottleDirectory: bottleDirectory,
    );
  }

  final String dataHome;
  final String bottleDirectory;
  final ProgramMetadataExtractor _programMetadataExtractor;

  @override
  List<BottleRecord> listBottles() {
    final directory = Directory(bottleDirectory);
    if (!directory.existsSync()) {
      return const <BottleRecord>[];
    }

    try {
      final bottles =
          directory
              .listSync()
              .whereType<Directory>()
              .where((entry) {
                return File(
                  _joinPath(entry.path, const ['metadata.json']),
                ).existsSync();
              })
              .map((entry) => _readBottleMetadata(entry.path))
              .map(
                (bottle) => _bottleWithPinnedProgramIcons(
                  bottle,
                  programMetadataExtractor: _programMetadataExtractor,
                ),
              )
              .toList(growable: false)
            ..sort((left, right) => left.id.compareTo(right.id));

      return List.unmodifiable(bottles);
    } on FileSystemException catch (error) {
      throw BottleRepositoryException(error.message);
    } on FormatException catch (error) {
      throw BottleRepositoryException(error.message);
    }
  }

  @override
  BottleRecord? findBottle(String id) {
    final directory = Directory(bottleDirectory);
    final metadata = File(_joinPath(directory.path, [id, 'metadata.json']));

    if (!metadata.existsSync()) {
      return null;
    }

    try {
      return _bottleWithPinnedProgramIcons(
        _readBottleMetadata(_joinPath(directory.path, [id])),
        programMetadataExtractor: _programMetadataExtractor,
      );
    } on FileSystemException catch (error) {
      throw BottleRepositoryException(error.message);
    } on FormatException catch (error) {
      throw BottleRepositoryException(error.message);
    }
  }

  @override
  BottleCreateResult createBottle(BottleCreateRequest request) {
    final bottle = _bottleFromCreateRequest(
      request,
      dataHome,
      bottleDirectory: bottleDirectory,
    );
    final bottlePathDirectory = Directory(bottle.path);
    final metadata = File(_joinPath(bottle.path, const ['metadata.json']));

    if (bottlePathDirectory.existsSync() || metadata.existsSync()) {
      return BottleCreateConflict(bottle.id);
    }

    try {
      bottlePathDirectory.createSync(recursive: true);
      Directory(
        _joinPath(bottle.path, const ['drive_c']),
      ).createSync(recursive: true);
      _writeBottleMetadata(bottle);
    } on FileSystemException catch (error) {
      throw BottleRepositoryException(error.message);
    }

    return BottleCreated(bottle);
  }

  @override
  BottleArchiveExportResult exportBottleArchive(
    BottleArchiveExportRequest request,
  ) {
    final bottle = findBottle(request.bottleId);
    if (bottle == null) {
      return BottleArchiveExportMissing(request.bottleId);
    }

    return _exportBottleArchive(
      bottle: bottle,
      archivePath: request.archivePath,
    );
  }

  @override
  BottleArchiveImportResult importBottleArchive(
    BottleArchiveImportRequest request,
  ) {
    return _importBottleArchive(
      archivePath: request.archivePath,
      bottleDirectory: bottleDirectory,
      hasBottle: (bottleId) => findBottle(bottleId) != null,
    );
  }

  @override
  BottleDeleteResult deleteBottle(String id) {
    final bottle = findBottle(id);
    if (bottle == null) {
      return BottleDeleteMissing(id);
    }

    try {
      final bottleDirectory = Directory(bottle.path);
      if (bottleDirectory.existsSync()) {
        bottleDirectory.deleteSync(recursive: true);
      }
    } on FileSystemException catch (error) {
      throw BottleRepositoryException(error.message);
    }

    return BottleDeleted(bottle);
  }

  @override
  BottleRenameResult renameBottle(BottleRenameRequest request) {
    final bottle = findBottle(request.bottleId);
    if (bottle == null) {
      return BottleRenameMissing(request.bottleId);
    }

    final renamed = _renamedFileBottle(
      bottle: bottle,
      name: request.name,
      dataHome: dataHome,
      bottleDirectory: bottleDirectory,
    );
    if (renamed.id != bottle.id && Directory(renamed.path).existsSync()) {
      return BottleRenameConflict(renamed.id);
    }

    try {
      if (renamed.path != bottle.path) {
        _moveDirectory(from: bottle.path, to: renamed.path);
      }
      _writeBottleMetadata(renamed);
    } on FileSystemException catch (error) {
      throw BottleRepositoryException(error.message);
    }

    return BottleRenamed(renamed);
  }

  @override
  BottleMoveResult moveBottle(BottleMoveRequest request) {
    final bottle = findBottle(request.bottleId);
    if (bottle == null) {
      return BottleMoveMissing(request.bottleId);
    }

    final destinationPath = request.path;
    if (_normalizeFilesystemPath(destinationPath) !=
            _normalizeFilesystemPath(bottle.path) &&
        Directory(destinationPath).existsSync()) {
      return BottleMoveConflict(destinationPath);
    }

    final moved = bottle.copyWith(path: destinationPath);

    try {
      if (_normalizeFilesystemPath(destinationPath) !=
          _normalizeFilesystemPath(bottle.path)) {
        _moveDirectory(from: bottle.path, to: destinationPath);
      }
      _writeBottleMetadata(moved);
    } on FileSystemException catch (error) {
      throw BottleRepositoryException(error.message);
    }

    return BottleMoved(moved);
  }

  @override
  BottleUpdateResult setWindowsVersion(WindowsVersionUpdateRequest request) {
    final bottle = findBottle(request.bottleId);
    if (bottle == null) {
      return BottleUpdateMissing(request.bottleId);
    }

    final updated = bottle.copyWith(windowsVersion: request.windowsVersion);

    try {
      _writeBottleMetadata(updated);
    } on FileSystemException catch (error) {
      throw BottleRepositoryException(error.message);
    }

    return BottleUpdated(updated);
  }

  @override
  BottleUpdateResult setRuntimeSettings(RuntimeSettingsUpdateRequest request) {
    final bottle = findBottle(request.bottleId);
    if (bottle == null) {
      return BottleUpdateMissing(request.bottleId);
    }

    final updated = bottle.copyWith(runtimeSettings: request.runtimeSettings);

    try {
      _writeBottleMetadata(updated);
    } on FileSystemException catch (error) {
      throw BottleRepositoryException(error.message);
    }

    return BottleUpdated(updated);
  }

  @override
  ProgramPinResult pinProgram(ProgramPinRequest request) {
    final bottle = findBottle(request.bottleId);
    if (bottle == null) {
      return ProgramPinMissing(request.bottleId);
    }

    if (_hasPinnedProgram(bottle, request.programPath)) {
      return ProgramPinConflict(request.programPath);
    }

    final updated = _bottleWithPinnedProgram(
      bottle,
      request,
      programMetadataExtractor: _programMetadataExtractor,
    );

    try {
      _writeBottleMetadata(updated);
    } on FileSystemException catch (error) {
      throw BottleRepositoryException(error.message);
    }

    return ProgramPinned(updated);
  }

  @override
  ProgramUpdateResult unpinProgram(ProgramUnpinRequest request) {
    final bottle = findBottle(request.bottleId);
    if (bottle == null) {
      return ProgramUpdateMissingBottle(request.bottleId);
    }

    if (!_hasPinnedProgram(bottle, request.programPath)) {
      return ProgramUpdateMissingProgram(request.programPath);
    }

    final updated = _bottleWithoutPinnedProgram(bottle, request.programPath);

    try {
      _writeBottleMetadata(updated);
    } on FileSystemException catch (error) {
      throw BottleRepositoryException(error.message);
    }

    return ProgramUpdated(updated);
  }

  @override
  ProgramUpdateResult renamePinnedProgram(ProgramRenameRequest request) {
    final bottle = findBottle(request.bottleId);
    if (bottle == null) {
      return ProgramUpdateMissingBottle(request.bottleId);
    }

    if (!_hasPinnedProgram(bottle, request.programPath)) {
      return ProgramUpdateMissingProgram(request.programPath);
    }

    final updated = _bottleWithRenamedPinnedProgram(bottle, request);

    try {
      _writeBottleMetadata(updated);
    } on FileSystemException catch (error) {
      throw BottleRepositoryException(error.message);
    }

    return ProgramUpdated(updated);
  }

  @override
  ProgramSettingsReadResult readProgramSettings(
    ProgramSettingsRequest request,
  ) {
    final bottle = findBottle(request.bottleId);
    if (bottle == null) {
      return ProgramSettingsReadMissingBottle(request.bottleId);
    }

    try {
      return ProgramSettingsRead(
        _readProgramSettingsJson(
          _programSettingsJsonPath(
            bottle: bottle,
            programPath: request.programPath,
          ),
        ),
      );
    } on FileSystemException catch (error) {
      throw BottleRepositoryException(error.message);
    } on FormatException catch (error) {
      throw BottleRepositoryException(error.message);
    }
  }

  @override
  ProgramSettingsUpdateResult setProgramSettings(
    ProgramSettingsUpdateRequest request,
  ) {
    final bottle = findBottle(request.bottleId);
    if (bottle == null) {
      return ProgramSettingsUpdateMissingBottle(request.bottleId);
    }

    try {
      _writeProgramSettingsJson(
        path: _programSettingsJsonPath(
          bottle: bottle,
          programPath: request.programPath,
        ),
        settings: request.settings,
      );
    } on FileSystemException catch (error) {
      throw BottleRepositoryException(error.message);
    }

    return ProgramSettingsUpdated(request.settings);
  }
}

class RuntimeDefinition {
  const RuntimeDefinition({
    required this.id,
    required this.name,
    required this.platform,
    required this.architecture,
    required this.runnerKind,
    required this.isBundled,
    required this.isUpdateable,
    this.distributionKind,
    this.archiveUrl,
    this.versionUrl,
  });

  final String id;
  final String name;
  final String platform;
  final String architecture;
  final String runnerKind;
  final bool isBundled;
  final bool isUpdateable;
  final String? distributionKind;
  final String? archiveUrl;
  final String? versionUrl;
}

class InstalledRuntimeState {
  const InstalledRuntimeState({
    this.isInstalled,
    this.applicationSupportPath,
    this.libraryPath,
    this.executablePath,
  });

  const InstalledRuntimeState.unknown()
    : isInstalled = null,
      applicationSupportPath = null,
      libraryPath = null,
      executablePath = null;

  final bool? isInstalled;
  final String? applicationSupportPath;
  final String? libraryPath;
  final String? executablePath;
}

class RuntimeCapabilities {
  const RuntimeCapabilities({this.stack});

  const RuntimeCapabilities.empty() : stack = null;

  final RuntimeStack? stack;
}

class RuntimeRecord {
  const RuntimeRecord({
    required this.id,
    required this.name,
    required this.platform,
    required this.architecture,
    required this.runnerKind,
    required this.isBundled,
    required this.isUpdateable,
    this.distributionKind,
    this.isInstalled,
    this.applicationSupportPath,
    this.libraryPath,
    this.executablePath,
    this.archiveUrl,
    this.versionUrl,
    this.stack,
  });

  RuntimeRecord.fromParts({
    required RuntimeDefinition definition,
    InstalledRuntimeState installedState =
        const InstalledRuntimeState.unknown(),
    RuntimeCapabilities capabilities = const RuntimeCapabilities.empty(),
  }) : id = definition.id,
       name = definition.name,
       platform = definition.platform,
       architecture = definition.architecture,
       runnerKind = definition.runnerKind,
       isBundled = definition.isBundled,
       isUpdateable = definition.isUpdateable,
       distributionKind = definition.distributionKind,
       isInstalled = installedState.isInstalled,
       applicationSupportPath = installedState.applicationSupportPath,
       libraryPath = installedState.libraryPath,
       executablePath = installedState.executablePath,
       archiveUrl = definition.archiveUrl,
       versionUrl = definition.versionUrl,
       stack = capabilities.stack;

  final String id;
  final String name;
  final String platform;
  final String architecture;
  final String runnerKind;
  final bool isBundled;
  final bool isUpdateable;
  final String? distributionKind;
  final bool? isInstalled;
  final String? applicationSupportPath;
  final String? libraryPath;
  final String? executablePath;
  final String? archiveUrl;
  final String? versionUrl;
  final RuntimeStack? stack;

  Map<String, Object?> toJson() {
    final runtimeStack = stack;

    return <String, Object?>{
      'id': id,
      'name': name,
      'platform': platform,
      'architecture': architecture,
      'runnerKind': runnerKind,
      'isBundled': isBundled,
      'isUpdateable': isUpdateable,
      if (distributionKind != null) 'distributionKind': distributionKind,
      if (isInstalled != null) 'isInstalled': isInstalled,
      if (applicationSupportPath != null)
        'applicationSupportPath': applicationSupportPath,
      if (libraryPath != null) 'libraryPath': libraryPath,
      if (executablePath != null) 'executablePath': executablePath,
      if (runtimeStack != null) 'stack': runtimeStack.toJson(),
    };
  }
}

class RuntimeStack {
  RuntimeStack({
    required this.id,
    required this.name,
    required this.compatibilityTarget,
    required Iterable<RuntimeStackComponent> components,
  }) : components = List.unmodifiable(components);

  final String id;
  final String name;
  final String compatibilityTarget;
  final List<RuntimeStackComponent> components;

  bool get isComplete {
    return components
        .where((component) => component.isRequired)
        .every((component) => component.isInstalled);
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': runtimeStackSchemaVersion,
      'id': id,
      'name': name,
      'compatibilityTarget': compatibilityTarget,
      'isComplete': isComplete,
      'components': components
          .map((component) => component.toJson())
          .toList(growable: false),
    };
  }
}

class RuntimeStackComponent {
  RuntimeStackComponent({
    required this.id,
    required this.name,
    required this.role,
    required this.isRequired,
    required Iterable<String> paths,
    required Iterable<String> missingPaths,
    this.version,
  }) : paths = List.unmodifiable(paths),
       missingPaths = List.unmodifiable(missingPaths);

  final String id;
  final String name;
  final String role;
  final bool isRequired;
  final List<String> paths;
  final List<String> missingPaths;
  final String? version;

  bool get isInstalled {
    return missingPaths.isEmpty;
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'role': role,
      'isRequired': isRequired,
      'isInstalled': isInstalled,
      'paths': paths,
      'missingPaths': missingPaths,
      if (version != null) 'version': version,
    };
  }
}

class RuntimeSourceManifest {
  RuntimeSourceManifest({
    required this.runtimeId,
    required this.stackId,
    required Iterable<RuntimeSourceComponent> components,
  }) : components = List.unmodifiable(components);

  final String runtimeId;
  final String stackId;
  final List<RuntimeSourceComponent> components;

  RuntimeSourceComponent? componentById(String id) {
    for (final component in components) {
      if (component.id == id) {
        return component;
      }
    }

    return null;
  }
}

class RuntimeSourceComponent {
  const RuntimeSourceComponent({
    required this.id,
    required this.version,
    required this.archiveUrl,
    required this.sha256,
  });

  final String id;
  final String version;
  final String archiveUrl;
  final String sha256;
}

class _RuntimeStackSourceArchiveBundle {
  const _RuntimeStackSourceArchiveBundle({
    required this.wineArchivePath,
    required this.componentArchivePaths,
    required this.componentVersions,
  });

  final String wineArchivePath;
  final List<String> componentArchivePaths;
  final Map<String, String> componentVersions;
}

sealed class _RuntimeStackSourceArchiveBundleResult {
  const _RuntimeStackSourceArchiveBundleResult();
}

class _RuntimeStackSourceArchiveBundleResolved
    extends _RuntimeStackSourceArchiveBundleResult {
  const _RuntimeStackSourceArchiveBundleResolved(this.bundle);

  final _RuntimeStackSourceArchiveBundle bundle;
}

class _RuntimeStackSourceArchiveBundleFailed
    extends _RuntimeStackSourceArchiveBundleResult {
  const _RuntimeStackSourceArchiveBundleFailed(this.message);

  final String message;
}

abstract interface class RuntimeCatalog {
  List<RuntimeRecord> listRuntimes();
}

class StaticRuntimeCatalog implements RuntimeCatalog {
  const StaticRuntimeCatalog(this._runtimes);

  final List<RuntimeRecord> _runtimes;

  @override
  List<RuntimeRecord> listRuntimes() {
    return List.unmodifiable(_runtimes);
  }
}

abstract interface class FileStatusProbe {
  bool exists(String path);
}

abstract interface class RuntimeStackVersionProbe {
  String? versionFor({
    required String runtimeRoot,
    required String componentId,
  });
}

class DartIoFileStatusProbe implements FileStatusProbe {
  const DartIoFileStatusProbe();

  @override
  bool exists(String path) {
    return FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound;
  }
}

class DartIoRuntimeStackVersionProbe implements RuntimeStackVersionProbe {
  const DartIoRuntimeStackVersionProbe();

  @override
  String? versionFor({
    required String runtimeRoot,
    required String componentId,
  }) {
    final manifest = File(
      _joinPath(runtimeRoot, const [runtimeStackManifestFileName]),
    );
    if (!manifest.existsSync()) {
      return null;
    }

    try {
      final decoded = jsonDecode(manifest.readAsStringSync());
      return _runtimeStackComponentVersion(decoded, componentId);
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    }
  }
}

class MacosWineRuntimeCatalog implements RuntimeCatalog {
  MacosWineRuntimeCatalog({
    required this.hostPlatform,
    required Map<String, String> environment,
    FileStatusProbe fileStatusProbe = const DartIoFileStatusProbe(),
    RuntimeStackVersionProbe runtimeStackVersionProbe =
        const DartIoRuntimeStackVersionProbe(),
  }) : environment = Map.unmodifiable(environment),
       _fileStatusProbe = fileStatusProbe,
       _runtimeStackVersionProbe = runtimeStackVersionProbe;

  factory MacosWineRuntimeCatalog.current() {
    return MacosWineRuntimeCatalog(
      hostPlatform: _currentHostPlatform(),
      environment: Platform.environment,
    );
  }

  final KonyakHostPlatform hostPlatform;
  final Map<String, String> environment;
  final FileStatusProbe _fileStatusProbe;
  final RuntimeStackVersionProbe _runtimeStackVersionProbe;

  @override
  List<RuntimeRecord> listRuntimes() {
    return switch (hostPlatform) {
      KonyakHostPlatform.macos => <RuntimeRecord>[
        _macosWineRuntimeRecord(
          environment: environment,
          fileStatusProbe: _fileStatusProbe,
          runtimeStackVersionProbe: _runtimeStackVersionProbe,
        ),
      ],
      KonyakHostPlatform.linux => const <RuntimeRecord>[],
    };
  }
}

class KonyakRuntimeCatalog implements RuntimeCatalog {
  KonyakRuntimeCatalog({
    required this.hostPlatform,
    required Map<String, String> environment,
    FileStatusProbe fileStatusProbe = const DartIoFileStatusProbe(),
    RuntimeStackVersionProbe runtimeStackVersionProbe =
        const DartIoRuntimeStackVersionProbe(),
  }) : environment = Map.unmodifiable(environment),
       _fileStatusProbe = fileStatusProbe,
       _runtimeStackVersionProbe = runtimeStackVersionProbe;

  factory KonyakRuntimeCatalog.current() {
    return KonyakRuntimeCatalog(
      hostPlatform: _currentHostPlatform(),
      environment: Platform.environment,
    );
  }

  final KonyakHostPlatform hostPlatform;
  final Map<String, String> environment;
  final FileStatusProbe _fileStatusProbe;
  final RuntimeStackVersionProbe _runtimeStackVersionProbe;

  @override
  List<RuntimeRecord> listRuntimes() {
    return switch (hostPlatform) {
      KonyakHostPlatform.macos => <RuntimeRecord>[
        _macosWineRuntimeRecord(
          environment: environment,
          fileStatusProbe: _fileStatusProbe,
          runtimeStackVersionProbe: _runtimeStackVersionProbe,
        ),
      ],
      KonyakHostPlatform.linux => <RuntimeRecord>[
        _linuxWineRuntimeRecord(
          environment: environment,
          fileStatusProbe: _fileStatusProbe,
          runtimeStackVersionProbe: _runtimeStackVersionProbe,
        ),
      ],
    };
  }
}

abstract interface class ProgramRunner {
  ProgramRunResult run(ProgramRunRequest request);
}

abstract interface class PathOpener {
  PathOpenResult openPath(String path);

  PathOpenResult revealPath(String path);
}

enum KonyakHostPlatform { linux, macos }

class ProgramRunPlanner {
  ProgramRunPlanner({
    required this.hostPlatform,
    Map<String, String> environment = const <String, String>{},
  }) : environment = Map.unmodifiable(environment);

  factory ProgramRunPlanner.current() {
    return ProgramRunPlanner(
      hostPlatform: _currentHostPlatform(),
      environment: Platform.environment,
    );
  }

  final KonyakHostPlatform hostPlatform;
  final Map<String, String> environment;

  ProgramRunRequest? plan({
    required BottleRecord bottle,
    required String programPath,
    ProgramSettingsRecord programSettings = const ProgramSettingsRecord(),
  }) {
    final supportedProgramPath = _isSupportedProgramPath(programPath);
    if (!supportedProgramPath) {
      return null;
    }

    return switch (hostPlatform) {
      KonyakHostPlatform.linux => _linuxWineRequest(
        bottle: bottle,
        programPath: programPath,
        environment: environment,
        programSettings: programSettings,
      ),
      KonyakHostPlatform.macos => _macosWineRequest(
        bottle: bottle,
        programPath: programPath,
        environment: environment,
        programSettings: programSettings,
      ),
    };
  }

  ProgramRunRequest? planBottleCommand({
    required BottleRecord bottle,
    required String command,
  }) {
    final supportedCommand = _supportedBottleCommand(command);
    if (supportedCommand == null) {
      return null;
    }

    if (supportedCommand == 'terminal') {
      return switch (hostPlatform) {
        KonyakHostPlatform.linux => _linuxTerminalCommandRequest(
          bottle: bottle,
          environment: environment,
        ),
        KonyakHostPlatform.macos => _macosTerminalCommandRequest(
          bottle: bottle,
          environment: environment,
        ),
      };
    }

    if (supportedCommand == 'winetricks') {
      return switch (hostPlatform) {
        KonyakHostPlatform.linux => _linuxWinetricksCommandRequest(
          bottle: bottle,
          environment: environment,
        ),
        KonyakHostPlatform.macos => _macosWinetricksCommandRequest(
          bottle: bottle,
          environment: environment,
          verb: null,
        ),
      };
    }

    return switch (hostPlatform) {
      KonyakHostPlatform.linux => _linuxWineCommandRequest(
        bottle: bottle,
        command: supportedCommand,
        environment: environment,
      ),
      KonyakHostPlatform.macos => _macosWineCommandRequest(
        bottle: bottle,
        command: supportedCommand,
        environment: environment,
      ),
    };
  }

  ProgramRunRequest planPrefixInitialization({required BottleRecord bottle}) {
    return switch (hostPlatform) {
      KonyakHostPlatform.linux => _linuxWinebootRequest(
        bottle: bottle,
        environment: environment,
      ),
      KonyakHostPlatform.macos => _macosWinebootRequest(
        bottle: bottle,
        environment: environment,
      ),
    };
  }

  ProgramRunRequest planWineProcessTermination({required BottleRecord bottle}) {
    return switch (hostPlatform) {
      KonyakHostPlatform.linux => _linuxWineserverKillRequest(
        bottle: bottle,
        environment: environment,
      ),
      KonyakHostPlatform.macos => _macosWineserverKillRequest(
        bottle: bottle,
        environment: environment,
      ),
    };
  }

  ProgramRunRequest planWineProcessList({required BottleRecord bottle}) {
    return switch (hostPlatform) {
      KonyakHostPlatform.linux => _linuxWinedbgRequest(
        bottle: bottle,
        environment: environment,
        command: 'info proc',
        logName: 'wine-processes.log',
      ),
      KonyakHostPlatform.macos => _macosWinedbgRequest(
        bottle: bottle,
        environment: environment,
        command: 'info proc',
        logName: 'wine-processes.log',
      ),
    };
  }

  ProgramRunRequest planWineProcessKill({
    required BottleRecord bottle,
    required String processId,
  }) {
    final attachProcessId = _winedbgAttachProcessId(processId);
    return switch (hostPlatform) {
      KonyakHostPlatform.linux => _linuxWinedbgRequest(
        bottle: bottle,
        environment: environment,
        command: 'kill',
        logName: 'wine-process-kill.log',
        trailingArguments: <String>[attachProcessId],
      ),
      KonyakHostPlatform.macos => _macosWinedbgRequest(
        bottle: bottle,
        environment: environment,
        command: 'kill',
        logName: 'wine-process-kill.log',
        trailingArguments: <String>[attachProcessId],
      ),
    };
  }

  ProgramRunRequest? planWinetricksVerb({
    required BottleRecord bottle,
    required String verb,
  }) {
    if (!_isSupportedWinetricksVerb(verb)) {
      return null;
    }

    return switch (hostPlatform) {
      KonyakHostPlatform.linux => _linuxWinetricksCommandRequest(
        bottle: bottle,
        environment: environment,
        verb: verb,
      ),
      KonyakHostPlatform.macos => _macosWinetricksCommandRequest(
        bottle: bottle,
        environment: environment,
        verb: verb,
      ),
    };
  }

  List<ProgramRunRequest> planWindowsVersionRegistryUpdates({
    required BottleRecord bottle,
    required String windowsVersion,
  }) {
    final updates = _windowsVersionRegistryUpdates(windowsVersion);

    return List.unmodifiable(
      updates.map((update) {
        return switch (hostPlatform) {
          KonyakHostPlatform.linux => _linuxRegistryUpdateRequest(
            bottle: bottle,
            update: update,
            environment: environment,
          ),
          KonyakHostPlatform.macos => _macosRegistryUpdateRequest(
            bottle: bottle,
            update: update,
            environment: environment,
          ),
        };
      }),
    );
  }

  List<ProgramRunRequest> planRuntimeSettingsRegistryUpdates({
    required BottleRecord bottle,
    required BottleRuntimeSettings currentRuntimeSettings,
    required BottleRuntimeSettings runtimeSettings,
  }) {
    final updates = _runtimeSettingsRegistryUpdates(
      currentRuntimeSettings: currentRuntimeSettings,
      runtimeSettings: runtimeSettings,
      includeMacDriverSettings: hostPlatform == KonyakHostPlatform.macos,
    );

    return List.unmodifiable(
      updates.map((update) {
        return switch (hostPlatform) {
          KonyakHostPlatform.linux => _linuxRegistryUpdateRequest(
            bottle: bottle,
            update: update,
            environment: environment,
          ),
          KonyakHostPlatform.macos => _macosRegistryUpdateRequest(
            bottle: bottle,
            update: update,
            environment: environment,
          ),
        };
      }),
    );
  }

  List<ProgramRunRequest> planBottleSettingsRegistryQueries({
    required BottleRecord bottle,
  }) {
    final queries = _bottleSettingsRegistryQueries(
      includeMacDriverSettings: hostPlatform == KonyakHostPlatform.macos,
    );

    return List.unmodifiable(
      queries.map((query) {
        return switch (hostPlatform) {
          KonyakHostPlatform.linux => _linuxRegistryQueryRequest(
            bottle: bottle,
            query: query,
            environment: environment,
          ),
          KonyakHostPlatform.macos => _macosRegistryQueryRequest(
            bottle: bottle,
            query: query,
            environment: environment,
          ),
        };
      }),
    );
  }
}

class ProgramRunRequest {
  ProgramRunRequest({
    required this.bottleId,
    required this.programPath,
    required this.runnerKind,
    required this.executable,
    required List<String> arguments,
    required Map<String, String> environment,
    required this.logPath,
    this.workingDirectory,
  }) : arguments = List.unmodifiable(arguments),
       environment = Map.unmodifiable(environment);

  final String bottleId;
  final String programPath;
  final String runnerKind;
  final String executable;
  final List<String> arguments;
  final Map<String, String> environment;
  final String logPath;
  final String? workingDirectory;

  List<String> get argv {
    return List.unmodifiable(<String>[executable, ...arguments]);
  }
}

sealed class ProgramRunResult {
  const ProgramRunResult();
}

class ProgramRunCompleted extends ProgramRunResult {
  const ProgramRunCompleted({
    required this.processExitCode,
    this.stdout = '',
    this.stderr = '',
  });

  final int processExitCode;
  final String stdout;
  final String stderr;
}

class ProgramRunFailed extends ProgramRunResult {
  const ProgramRunFailed({required this.message});

  final String message;
}

class WineProcessTerminationRecord {
  const WineProcessTerminationRecord({
    required this.bottleId,
    required this.status,
    required this.runnerKind,
    required this.executable,
    required this.argv,
    this.processId,
    this.processExitCode,
    this.message,
  });

  final String bottleId;
  final String status;
  final String runnerKind;
  final String executable;
  final List<String> argv;
  final String? processId;
  final int? processExitCode;
  final String? message;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'bottleId': bottleId,
      if (processId != null) 'processId': processId,
      'status': status,
      'runnerKind': runnerKind,
      'executable': executable,
      'argv': argv,
      if (processExitCode != null) 'processExitCode': processExitCode,
      if (message != null) 'message': message,
    };
  }
}

sealed class PathOpenResult {
  const PathOpenResult();
}

class PathOpenCompleted extends PathOpenResult {
  const PathOpenCompleted();
}

class PathOpenFailed extends PathOpenResult {
  const PathOpenFailed(this.message);

  final String message;
}

sealed class DetachedProcessStartResult {
  const DetachedProcessStartResult();
}

class DetachedProcessStartCompleted extends DetachedProcessStartResult {
  const DetachedProcessStartCompleted();
}

class DetachedProcessStartFailed extends DetachedProcessStartResult {
  const DetachedProcessStartFailed(this.message);

  final String message;
}

abstract interface class DetachedProcessStarter {
  DetachedProcessStartResult start({
    required String executable,
    required List<String> arguments,
  });
}

class DartIoProgramRunner implements ProgramRunner {
  const DartIoProgramRunner();

  @override
  ProgramRunResult run(ProgramRunRequest request) {
    try {
      final result = Process.runSync(
        request.executable,
        request.arguments,
        environment: request.environment,
        workingDirectory: request.workingDirectory,
        runInShell: false,
      );

      final logFile = File(request.logPath);
      logFile.parent.createSync(recursive: true);
      logFile.writeAsStringSync(_programRunLog(request, result));

      return ProgramRunCompleted(
        processExitCode: result.exitCode,
        stdout: _processOutputToString(result.stdout),
        stderr: _processOutputToString(result.stderr),
      );
    } on ProcessException catch (error) {
      final message = _programRunnerFailureMessage(
        executable: request.executable,
        message: error.message,
      );
      final logFile = File(request.logPath);
      logFile.parent.createSync(recursive: true);
      logFile.writeAsStringSync(_programRunStartupFailureLog(request, message));

      return ProgramRunFailed(message: message);
    } on FileSystemException catch (error) {
      return ProgramRunFailed(message: error.message);
    }
  }
}

class DartIoPathOpener implements PathOpener {
  const DartIoPathOpener();

  @override
  PathOpenResult openPath(String path) {
    return _runPathOpenCommand(<String>[path]);
  }

  @override
  PathOpenResult revealPath(String path) {
    return switch (_currentHostPlatform()) {
      KonyakHostPlatform.macos => _runPathOpenCommand(<String>['-R', path]),
      KonyakHostPlatform.linux => _runPathOpenCommand(<String>[
        _programLocationPath(path),
      ]),
    };
  }

  PathOpenResult _runPathOpenCommand(List<String> arguments) {
    try {
      final result = Process.runSync(
        _pathOpenExecutable(),
        arguments,
        runInShell: false,
      );
      if (result.exitCode != 0) {
        return PathOpenFailed(_processOutputToString(result.stderr));
      }

      return const PathOpenCompleted();
    } on ProcessException catch (error) {
      return PathOpenFailed(error.message);
    }
  }
}

class DartIoDetachedProcessStarter implements DetachedProcessStarter {
  const DartIoDetachedProcessStarter();

  @override
  DetachedProcessStartResult start({
    required String executable,
    required List<String> arguments,
  }) {
    try {
      final result = Process.runSync('bash', <String>[
        '-lc',
        r'nohup "$1" "${@:2}" >/dev/null 2>&1 &',
        '_',
        executable,
        ...arguments,
      ], runInShell: false);
      if (result.exitCode != 0) {
        return DetachedProcessStartFailed(
          _processOutputToString(result.stderr),
        );
      }

      return const DetachedProcessStartCompleted();
    } on ProcessException catch (error) {
      return DetachedProcessStartFailed(error.message);
    }
  }
}

enum RuntimeInstallOperation {
  fullInstall,
  repair,
  componentInstall,
  updateInstall,
}

sealed class RuntimeInstallRequestOperation {
  const RuntimeInstallRequestOperation();

  RuntimeInstallOperation get operation;

  bool get force;

  String? get archivePath => null;

  String? get archiveUrl => null;

  String? get archiveSha256 => null;

  List<String> get componentArchivePaths => const <String>[];

  String? get sourceManifest => null;

  String? get sourceManifestSignature => null;
}

final class RuntimeFullInstallOperation extends RuntimeInstallRequestOperation {
  const RuntimeFullInstallOperation({
    this.archivePath,
    this.archiveUrl,
    this.archiveSha256,
    this.sourceManifest,
    this.sourceManifestSignature,
    this.force = false,
  });

  @override
  RuntimeInstallOperation get operation => RuntimeInstallOperation.fullInstall;

  @override
  final String? archivePath;

  @override
  final String? archiveUrl;

  @override
  final String? archiveSha256;

  @override
  final String? sourceManifest;

  @override
  final String? sourceManifestSignature;

  @override
  final bool force;
}

final class RuntimeRepairOperation extends RuntimeInstallRequestOperation {
  const RuntimeRepairOperation({
    this.archivePath,
    this.archiveUrl,
    this.archiveSha256,
    this.sourceManifest,
    this.sourceManifestSignature,
    this.force = true,
  });

  @override
  RuntimeInstallOperation get operation => RuntimeInstallOperation.repair;

  @override
  final String? archivePath;

  @override
  final String? archiveUrl;

  @override
  final String? archiveSha256;

  @override
  final String? sourceManifest;

  @override
  final String? sourceManifestSignature;

  @override
  final bool force;
}

final class RuntimeComponentInstallOperation
    extends RuntimeInstallRequestOperation {
  RuntimeComponentInstallOperation({
    this.archivePath,
    this.archiveUrl,
    this.archiveSha256,
    Iterable<String> componentArchivePaths = const <String>[],
    this.force = false,
  }) : componentArchivePaths = List.unmodifiable(componentArchivePaths);

  @override
  RuntimeInstallOperation get operation =>
      RuntimeInstallOperation.componentInstall;

  @override
  final String? archivePath;

  @override
  final String? archiveUrl;

  @override
  final String? archiveSha256;

  @override
  final List<String> componentArchivePaths;

  @override
  final bool force;
}

final class RuntimeUpdateInstallOperation
    extends RuntimeInstallRequestOperation {
  const RuntimeUpdateInstallOperation({
    this.archiveUrl,
    this.archiveSha256,
    this.sourceManifest,
    this.sourceManifestSignature,
    this.force = true,
  });

  @override
  RuntimeInstallOperation get operation =>
      RuntimeInstallOperation.updateInstall;

  @override
  final String? archiveUrl;

  @override
  final String? archiveSha256;

  @override
  final String? sourceManifest;

  @override
  final String? sourceManifestSignature;

  @override
  final bool force;
}

class MacosWineInstallRequest {
  MacosWineInstallRequest.fullInstall({
    String? archivePath,
    String? archiveUrl,
    String? archiveSha256,
    String? sourceManifest,
    String? sourceManifestSignature,
    bool force = false,
    this.emitProgress = false,
  }) : requestOperation = RuntimeFullInstallOperation(
         archivePath: archivePath,
         archiveUrl: archiveUrl,
         archiveSha256: archiveSha256,
         sourceManifest: sourceManifest,
         sourceManifestSignature: sourceManifestSignature,
         force: force,
       );

  MacosWineInstallRequest.repair({
    String? archivePath,
    String? archiveUrl,
    String? archiveSha256,
    String? sourceManifest,
    String? sourceManifestSignature,
    bool force = true,
    this.emitProgress = false,
  }) : requestOperation = RuntimeRepairOperation(
         archivePath: archivePath,
         archiveUrl: archiveUrl,
         archiveSha256: archiveSha256,
         sourceManifest: sourceManifest,
         sourceManifestSignature: sourceManifestSignature,
         force: force,
       );

  MacosWineInstallRequest.componentInstall({
    String? archivePath,
    String? archiveUrl,
    String? archiveSha256,
    Iterable<String> componentArchivePaths = const <String>[],
    bool force = false,
    this.emitProgress = false,
  }) : requestOperation = RuntimeComponentInstallOperation(
         archivePath: archivePath,
         archiveUrl: archiveUrl,
         archiveSha256: archiveSha256,
         componentArchivePaths: componentArchivePaths,
         force: force,
       );

  MacosWineInstallRequest.updateInstall({
    String? archiveUrl,
    String? archiveSha256,
    String? sourceManifest,
    String? sourceManifestSignature,
    bool force = true,
    this.emitProgress = false,
  }) : requestOperation = RuntimeUpdateInstallOperation(
         archiveUrl: archiveUrl,
         archiveSha256: archiveSha256,
         sourceManifest: sourceManifest,
         sourceManifestSignature: sourceManifestSignature,
         force: force,
       );

  final RuntimeInstallRequestOperation requestOperation;
  final bool emitProgress;

  RuntimeInstallOperation get operation => requestOperation.operation;

  String? get archivePath => requestOperation.archivePath;

  String? get archiveUrl => requestOperation.archiveUrl;

  String? get archiveSha256 => requestOperation.archiveSha256;

  List<String> get componentArchivePaths =>
      requestOperation.componentArchivePaths;

  String? get sourceManifest => requestOperation.sourceManifest;

  String? get sourceManifestSignature =>
      requestOperation.sourceManifestSignature;

  bool get force => requestOperation.force;
}

class LinuxWineInstallRequest {
  LinuxWineInstallRequest.fullInstall({
    String? archivePath,
    String? archiveUrl,
    String? archiveSha256,
    String? sourceManifest,
    String? sourceManifestSignature,
    bool force = false,
    this.emitProgress = false,
  }) : requestOperation = RuntimeFullInstallOperation(
         archivePath: archivePath,
         archiveUrl: archiveUrl,
         archiveSha256: archiveSha256,
         sourceManifest: sourceManifest,
         sourceManifestSignature: sourceManifestSignature,
         force: force,
       );

  LinuxWineInstallRequest.repair({
    String? archivePath,
    String? archiveUrl,
    String? archiveSha256,
    String? sourceManifest,
    String? sourceManifestSignature,
    bool force = true,
    this.emitProgress = false,
  }) : requestOperation = RuntimeRepairOperation(
         archivePath: archivePath,
         archiveUrl: archiveUrl,
         archiveSha256: archiveSha256,
         sourceManifest: sourceManifest,
         sourceManifestSignature: sourceManifestSignature,
         force: force,
       );

  LinuxWineInstallRequest.componentInstall({
    String? archivePath,
    String? archiveUrl,
    String? archiveSha256,
    Iterable<String> componentArchivePaths = const <String>[],
    bool force = false,
    this.emitProgress = false,
  }) : requestOperation = RuntimeComponentInstallOperation(
         archivePath: archivePath,
         archiveUrl: archiveUrl,
         archiveSha256: archiveSha256,
         componentArchivePaths: componentArchivePaths,
         force: force,
       );

  LinuxWineInstallRequest.updateInstall({
    String? archiveUrl,
    String? archiveSha256,
    String? sourceManifest,
    String? sourceManifestSignature,
    bool force = true,
    this.emitProgress = false,
  }) : requestOperation = RuntimeUpdateInstallOperation(
         archiveUrl: archiveUrl,
         archiveSha256: archiveSha256,
         sourceManifest: sourceManifest,
         sourceManifestSignature: sourceManifestSignature,
         force: force,
       );

  final RuntimeInstallRequestOperation requestOperation;
  final bool emitProgress;

  RuntimeInstallOperation get operation => requestOperation.operation;

  String? get archivePath => requestOperation.archivePath;

  String? get archiveUrl => requestOperation.archiveUrl;

  String? get archiveSha256 => requestOperation.archiveSha256;

  List<String> get componentArchivePaths =>
      requestOperation.componentArchivePaths;

  String? get sourceManifest => requestOperation.sourceManifest;

  String? get sourceManifestSignature =>
      requestOperation.sourceManifestSignature;

  bool get force => requestOperation.force;
}

class RuntimePackageInstallRequest {
  const RuntimePackageInstallRequest({
    required this.runtimeLabel,
    required this.archivePath,
    required this.archiveSha256,
    required this.componentArchivePaths,
    required this.componentVersions,
    required this.runtimeRoot,
    required this.requiredExecutableRelativePath,
    required this.expectedExecutablePath,
    this.preserveExistingRuntimeFiles = false,
    this.normalizeStagingRoot,
    this.afterManifestWrite,
    this.progressSink,
  });

  final String runtimeLabel;
  final String archivePath;
  final String? archiveSha256;
  final List<String> componentArchivePaths;
  final Map<String, String> componentVersions;
  final Directory runtimeRoot;
  final List<String> requiredExecutableRelativePath;
  final String expectedExecutablePath;
  final bool preserveExistingRuntimeFiles;
  final void Function(Directory runtimeRoot)? normalizeStagingRoot;
  final void Function(Directory runtimeRoot)? afterManifestWrite;
  final RuntimeInstallProgressSink? progressSink;
}

sealed class RuntimePackageInstallResult {
  const RuntimePackageInstallResult();
}

class RuntimePackageInstallCompleted extends RuntimePackageInstallResult {
  const RuntimePackageInstallCompleted();
}

class RuntimePackageInstallFailed extends RuntimePackageInstallResult {
  const RuntimePackageInstallFailed(this.message);

  final String message;
}

abstract interface class RuntimePackageInstaller {
  RuntimePackageInstallResult install(RuntimePackageInstallRequest request);
}

class DartIoRuntimePackageInstaller implements RuntimePackageInstaller {
  const DartIoRuntimePackageInstaller();

  @override
  RuntimePackageInstallResult install(RuntimePackageInstallRequest request) {
    final failure = _installRuntimeArchives(
      runtimeLabel: request.runtimeLabel,
      archivePath: request.archivePath,
      archiveSha256: request.archiveSha256,
      componentArchivePaths: request.componentArchivePaths,
      componentVersions: request.componentVersions,
      runtimeRoot: request.runtimeRoot,
      requiredExecutableRelativePath: request.requiredExecutableRelativePath,
      expectedExecutablePath: request.expectedExecutablePath,
      preserveExistingRuntimeFiles: request.preserveExistingRuntimeFiles,
      normalizeStagingRoot: request.normalizeStagingRoot,
      afterManifestWrite: request.afterManifestWrite,
      progressSink: request.progressSink,
    );

    return failure == null
        ? const RuntimePackageInstallCompleted()
        : RuntimePackageInstallFailed(failure);
  }
}

class RuntimeInstallProgress {
  const RuntimeInstallProgress({
    required this.stage,
    required this.message,
    required this.fraction,
  });

  final String stage;
  final String message;
  final double fraction;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'stage': stage,
      'message': message,
      'fraction': fraction,
    };
  }
}

abstract interface class RuntimeInstallProgressSink {
  void emit(RuntimeInstallProgress progress);
}

final class JsonRuntimeInstallProgressSink
    implements RuntimeInstallProgressSink {
  const JsonRuntimeInstallProgressSink(this.output);

  final StringSink output;

  @override
  void emit(RuntimeInstallProgress progress) {
    output.writeln(
      jsonEncode(<String, Object?>{
        'schemaVersion': cliSchemaVersion,
        'runtimeInstallProgress': progress.toJson(),
      }),
    );
  }
}

sealed class MacosWineInstallResult {
  const MacosWineInstallResult();
}

class MacosWineInstallCompleted extends MacosWineInstallResult {
  const MacosWineInstallCompleted({required this.runtime});

  final RuntimeRecord runtime;
}

class MacosWineInstallFailed extends MacosWineInstallResult {
  const MacosWineInstallFailed(this.message);

  final String message;
}

abstract interface class MacosWineInstaller {
  MacosWineInstallResult install(
    MacosWineInstallRequest request, {
    RuntimeInstallProgressSink? progressSink,
  });
}

class GptkWineInstallRequest {
  const GptkWineInstallRequest({required this.sourcePath});

  final String sourcePath;
}

class GptkWineInstallRecord {
  const GptkWineInstallRecord({
    required this.componentId,
    required this.sourceDirectory,
    required this.runtimeRoot,
    required this.installedExecutablePath,
  });

  final String componentId;
  final String sourceDirectory;
  final String runtimeRoot;
  final String installedExecutablePath;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'componentId': componentId,
      'sourceDirectory': sourceDirectory,
      'runtimeRoot': runtimeRoot,
      'installedExecutablePath': installedExecutablePath,
    };
  }
}

sealed class GptkWineInstallResult {
  const GptkWineInstallResult();
}

class GptkWineInstallCompleted extends GptkWineInstallResult {
  const GptkWineInstallCompleted(this.record);

  final GptkWineInstallRecord record;
}

class GptkWineInstallFailed extends GptkWineInstallResult {
  const GptkWineInstallFailed(this.message);

  final String message;
}

abstract interface class GptkWineInstaller {
  GptkWineInstallResult install(GptkWineInstallRequest request);
}

sealed class LinuxWineInstallResult {
  const LinuxWineInstallResult();
}

class LinuxWineInstallCompleted extends LinuxWineInstallResult {
  const LinuxWineInstallCompleted({required this.runtime});

  final RuntimeRecord runtime;
}

class LinuxWineInstallFailed extends LinuxWineInstallResult {
  const LinuxWineInstallFailed(this.message);

  final String message;
}

abstract interface class LinuxWineInstaller {
  LinuxWineInstallResult install(
    LinuxWineInstallRequest request, {
    RuntimeInstallProgressSink? progressSink,
  });
}

class DartIoGptkWineInstaller implements GptkWineInstaller {
  const DartIoGptkWineInstaller({required this.environment});

  factory DartIoGptkWineInstaller.current() {
    return DartIoGptkWineInstaller(environment: Platform.environment);
  }

  static const componentId = 'wine';
  static const componentVersion = 'user-provided-gptk-wine';

  final Map<String, String> environment;

  @override
  GptkWineInstallResult install(GptkWineInstallRequest request) {
    final sourcePath = request.sourcePath.trim();
    if (sourcePath.isEmpty) {
      return const GptkWineInstallFailed('GPTK Wine source path is empty.');
    }

    final sourceRoot = _resolveGptkWineRoot(sourcePath);
    if (sourceRoot == null) {
      return const GptkWineInstallFailed(
        'Select a Game Porting Toolkit.app bundle that contains '
        'Contents/Resources/wine.',
      );
    }

    final validationFailure = _validateGptkWineRoot(sourceRoot);
    if (validationFailure != null) {
      return GptkWineInstallFailed(validationFailure);
    }

    final runtimeRoot = Directory(_macosWineRuntimeRoot(environment));
    final backupRoot = Directory('${runtimeRoot.path}.backup');
    final lockFile = File(_runtimeInstallLockPath(runtimeRoot));
    var lockCreated = false;
    var backupCreated = false;

    try {
      try {
        lockFile.createSync(exclusive: true);
        lockCreated = true;
      } on FileSystemException {
        return const GptkWineInstallFailed(
          'Konyak macOS Wine installation is already running.',
        );
      }

      final bundledD3DMetal = _resolveGptkD3DMetalSource(sourceRoot.path);
      if (bundledD3DMetal == null) {
        return const GptkWineInstallFailed(
          'Selected GPTK app does not contain D3DMetal.framework, '
          'libd3dshared.dylib, d3d12.dll, and dxgi.dll.',
        );
      }
      final d3dMetalValidationFailure = _validateGptkD3DMetalSource(
        bundledD3DMetal,
      );
      if (d3dMetalValidationFailure != null) {
        return GptkWineInstallFailed(d3dMetalValidationFailure);
      }

      runtimeRoot.parent.createSync(recursive: true);
      if (backupRoot.existsSync()) {
        backupRoot.deleteSync(recursive: true);
      }
      if (runtimeRoot.existsSync()) {
        runtimeRoot.renameSync(backupRoot.path);
        backupCreated = true;
        _copyDirectoryContentsReplacing(
          source: backupRoot,
          destination: runtimeRoot,
        );
      }
      _copyDirectoryContentsReplacing(
        source: sourceRoot,
        destination: runtimeRoot,
        skipRelativePaths: const <List<String>>[
          <String>['share', 'wine', 'mono'],
        ],
      );
      _upsertRuntimeStackComponentVersion(
        runtimeRoot: runtimeRoot,
        componentId: _gptkD3DMetalComponentId,
        version: 'user-provided',
      );
      _upsertRuntimeStackComponentVersion(
        runtimeRoot: runtimeRoot,
        componentId: componentId,
        version: componentVersion,
      );
    } on FileSystemException catch (error) {
      if (backupCreated) {
        if (runtimeRoot.existsSync()) {
          runtimeRoot.deleteSync(recursive: true);
        }
        if (backupRoot.existsSync()) {
          backupRoot.renameSync(runtimeRoot.path);
        }
      }
      return GptkWineInstallFailed(error.message);
    } finally {
      if (backupRoot.existsSync()) {
        backupRoot.deleteSync(recursive: true);
      }
      if (lockCreated && lockFile.existsSync()) {
        lockFile.deleteSync();
      }
    }

    return GptkWineInstallCompleted(
      GptkWineInstallRecord(
        componentId: componentId,
        sourceDirectory: sourceRoot.path,
        runtimeRoot: runtimeRoot.path,
        installedExecutablePath: _macosWineExecutable(environment),
      ),
    );
  }
}

class _GptkD3DMetalSource {
  const _GptkD3DMetalSource({
    required this.directory,
    required this.framework,
    required this.dylib,
    required this.d3d12Dll,
    required this.dxgiDll,
  });

  final Directory directory;
  final Directory framework;
  final File dylib;
  final File d3d12Dll;
  final File dxgiDll;
}

const _gptkD3DMetalComponentId = 'gptk-d3dmetal';

class DartIoMacosWineInstaller implements MacosWineInstaller {
  DartIoMacosWineInstaller({
    required this.hostPlatform,
    required Map<String, String> environment,
    FileStatusProbe fileStatusProbe = const DartIoFileStatusProbe(),
    RuntimeStackVersionProbe runtimeStackVersionProbe =
        const DartIoRuntimeStackVersionProbe(),
    RuntimePackageInstaller runtimePackageInstaller =
        const DartIoRuntimePackageInstaller(),
  }) : environment = Map.unmodifiable(environment),
       _fileStatusProbe = fileStatusProbe,
       _runtimeStackVersionProbe = runtimeStackVersionProbe,
       _runtimePackageInstaller = runtimePackageInstaller;

  factory DartIoMacosWineInstaller.current() {
    return DartIoMacosWineInstaller(
      hostPlatform: _currentHostPlatform(),
      environment: Platform.environment,
    );
  }

  final KonyakHostPlatform hostPlatform;
  final Map<String, String> environment;
  final FileStatusProbe _fileStatusProbe;
  final RuntimeStackVersionProbe _runtimeStackVersionProbe;
  final RuntimePackageInstaller _runtimePackageInstaller;

  @override
  MacosWineInstallResult install(
    MacosWineInstallRequest request, {
    RuntimeInstallProgressSink? progressSink,
  }) {
    final progress = request.emitProgress ? progressSink : null;
    _emitRuntimeInstallProgress(
      progress,
      stage: 'preparing',
      message: 'Preparing Konyak macOS Wine install...',
      fraction: 0,
    );

    if (hostPlatform != KonyakHostPlatform.macos) {
      return const MacosWineInstallFailed(
        'macOS Wine installation is supported on macOS only.',
      );
    }

    final currentRuntime = _macosWineRuntimeRecord(
      environment: environment,
      fileStatusProbe: _fileStatusProbe,
      runtimeStackVersionProbe: _runtimeStackVersionProbe,
    );
    final componentArchivePaths = List<String>.unmodifiable(
      request.componentArchivePaths,
    );
    final sourceManifest =
        request.sourceManifest ??
        _runtimeSourceManifestForPlatform(
          platformSpec: _macosKonyakRuntimePlatformSpec,
          environment: environment,
        );
    final sourceManifestSignature =
        request.sourceManifestSignature ??
        _runtimeSourceManifestSignatureForPlatform(
          platformSpec: _macosKonyakRuntimePlatformSpec,
          environment: environment,
        );
    final hasExplicitInstallSource =
        request.archivePath != null ||
        request.archiveUrl != null ||
        componentArchivePaths.isNotEmpty ||
        request.sourceManifest != null;
    final shouldPreserveExistingRuntimeFiles =
        !request.force &&
        currentRuntime.isInstalled == true &&
        currentRuntime.stack?.isComplete != true &&
        !hasExplicitInstallSource;
    if (!request.force &&
        request.archivePath == null &&
        request.archiveUrl == null &&
        componentArchivePaths.isEmpty &&
        request.sourceManifest == null &&
        currentRuntime.isInstalled == true &&
        currentRuntime.stack?.isComplete == true) {
      _emitRuntimeInstallProgress(
        progress,
        stage: 'complete',
        message: 'Konyak macOS Wine is already installed.',
        fraction: 1,
      );
      return MacosWineInstallCompleted(runtime: currentRuntime);
    }
    if (!request.force &&
        currentRuntime.isInstalled == true &&
        currentRuntime.stack?.isComplete != true &&
        !hasExplicitInstallSource &&
        sourceManifest == null) {
      return const MacosWineInstallFailed(
        'Konyak macOS Wine is installed, but the runtime stack is incomplete. '
        'Configure KONYAK_DEV_MACOS_WINE_STACK_MANIFEST or '
        'KONYAK_MACOS_WINE_STACK_MANIFEST, or pass --source-manifest or '
        '--component-archive to repair it.',
      );
    }

    if (sourceManifest != null) {
      return _installMacosWineStackFromSourceManifest(
        sourceManifest,
        sourceManifestSignature: sourceManifestSignature,
        preserveExistingRuntimeFiles: shouldPreserveExistingRuntimeFiles,
        progressSink: progress,
      );
    }

    final archive = request.archivePath;
    if (archive != null) {
      return _installMacosWineArchive(
        archivePath: archive,
        archiveSha256: request.archiveSha256,
        componentArchivePaths: componentArchivePaths,
        preserveExistingRuntimeFiles: shouldPreserveExistingRuntimeFiles,
        progressSink: progress,
      );
    }

    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-macos-wine-',
    );
    final archiveUrl =
        request.archiveUrl ??
        _runtimeDefaultArchiveUrl(
          platformSpec: _macosKonyakRuntimePlatformSpec,
          environment: environment,
        )!;
    final archiveFileName =
        _fileNameFromUrl(archiveUrl) ??
        _macosKonyakRuntimePlatformSpec.defaultArchiveFileName;
    final downloadedArchivePath = _joinPath(tempDirectory.path, [
      archiveFileName,
    ]);

    try {
      final downloadFailure = _downloadRuntimeStackSourceArchive(
        source: archiveUrl,
        targetPath: downloadedArchivePath,
        progressSink: progress,
        stage: 'downloading',
        message: 'Downloading Konyak macOS Wine...',
        startFraction: 0.05,
        endFraction: 0.65,
      );
      if (downloadFailure != null) {
        return MacosWineInstallFailed(downloadFailure);
      }

      return _installMacosWineArchive(
        archivePath: downloadedArchivePath,
        archiveSha256: request.archiveSha256,
        componentArchivePaths: componentArchivePaths,
        preserveExistingRuntimeFiles: shouldPreserveExistingRuntimeFiles,
        progressSink: progress,
      );
    } on FileSystemException catch (error) {
      return MacosWineInstallFailed(error.message);
    } on ProcessException catch (error) {
      return MacosWineInstallFailed(error.message);
    } finally {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    }
  }

  Future<MacosWineInstallResult> installStreaming(
    MacosWineInstallRequest request, {
    RuntimeInstallProgressSink? progressSink,
  }) async {
    final progress = request.emitProgress ? progressSink : null;
    _emitRuntimeInstallProgress(
      progress,
      stage: 'preparing',
      message: 'Preparing Konyak macOS Wine install...',
      fraction: 0,
    );

    if (hostPlatform != KonyakHostPlatform.macos) {
      return const MacosWineInstallFailed(
        'macOS Wine installation is supported on macOS only.',
      );
    }

    final currentRuntime = _macosWineRuntimeRecord(
      environment: environment,
      fileStatusProbe: _fileStatusProbe,
      runtimeStackVersionProbe: _runtimeStackVersionProbe,
    );
    final componentArchivePaths = List<String>.unmodifiable(
      request.componentArchivePaths,
    );
    final sourceManifest =
        request.sourceManifest ??
        _runtimeSourceManifestForPlatform(
          platformSpec: _macosKonyakRuntimePlatformSpec,
          environment: environment,
        );
    final sourceManifestSignature =
        request.sourceManifestSignature ??
        _runtimeSourceManifestSignatureForPlatform(
          platformSpec: _macosKonyakRuntimePlatformSpec,
          environment: environment,
        );
    final hasExplicitInstallSource =
        request.archivePath != null ||
        request.archiveUrl != null ||
        componentArchivePaths.isNotEmpty ||
        request.sourceManifest != null;
    final shouldPreserveExistingRuntimeFiles =
        !request.force &&
        currentRuntime.isInstalled == true &&
        currentRuntime.stack?.isComplete != true &&
        !hasExplicitInstallSource;
    if (!request.force &&
        request.archivePath == null &&
        request.archiveUrl == null &&
        componentArchivePaths.isEmpty &&
        request.sourceManifest == null &&
        currentRuntime.isInstalled == true &&
        currentRuntime.stack?.isComplete == true) {
      _emitRuntimeInstallProgress(
        progress,
        stage: 'complete',
        message: 'Konyak macOS Wine is already installed.',
        fraction: 1,
      );
      return MacosWineInstallCompleted(runtime: currentRuntime);
    }
    if (!request.force &&
        currentRuntime.isInstalled == true &&
        currentRuntime.stack?.isComplete != true &&
        !hasExplicitInstallSource &&
        sourceManifest == null) {
      return const MacosWineInstallFailed(
        'Konyak macOS Wine is installed, but the runtime stack is incomplete. '
        'Configure KONYAK_DEV_MACOS_WINE_STACK_MANIFEST or '
        'KONYAK_MACOS_WINE_STACK_MANIFEST, or pass --source-manifest or '
        '--component-archive to repair it.',
      );
    }

    if (sourceManifest != null) {
      return _installMacosWineStackFromSourceManifestStreaming(
        sourceManifest,
        sourceManifestSignature: sourceManifestSignature,
        preserveExistingRuntimeFiles: shouldPreserveExistingRuntimeFiles,
        progressSink: progress,
      );
    }

    final archive = request.archivePath;
    if (archive != null) {
      return _installMacosWineArchive(
        archivePath: archive,
        archiveSha256: request.archiveSha256,
        componentArchivePaths: componentArchivePaths,
        preserveExistingRuntimeFiles: shouldPreserveExistingRuntimeFiles,
        progressSink: progress,
      );
    }

    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-macos-wine-',
    );
    final archiveUrl =
        request.archiveUrl ??
        _runtimeDefaultArchiveUrl(
          platformSpec: _macosKonyakRuntimePlatformSpec,
          environment: environment,
        )!;
    final archiveFileName =
        _fileNameFromUrl(archiveUrl) ??
        _macosKonyakRuntimePlatformSpec.defaultArchiveFileName;
    final downloadedArchivePath = _joinPath(tempDirectory.path, [
      archiveFileName,
    ]);

    try {
      final downloadFailure = await _downloadRuntimeStackSourceArchiveStreaming(
        source: archiveUrl,
        targetPath: downloadedArchivePath,
        progressSink: progress,
        stage: 'downloading',
        message: 'Downloading Konyak macOS Wine...',
        startFraction: 0.05,
        endFraction: 0.65,
      );
      if (downloadFailure != null) {
        return MacosWineInstallFailed(downloadFailure);
      }

      return _installMacosWineArchive(
        archivePath: downloadedArchivePath,
        archiveSha256: request.archiveSha256,
        componentArchivePaths: componentArchivePaths,
        preserveExistingRuntimeFiles: shouldPreserveExistingRuntimeFiles,
        progressSink: progress,
      );
    } on FileSystemException catch (error) {
      return MacosWineInstallFailed(error.message);
    } on ProcessException catch (error) {
      return MacosWineInstallFailed(error.message);
    } finally {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    }
  }

  MacosWineInstallResult _installMacosWineArchive({
    required String archivePath,
    required String? archiveSha256,
    List<String> componentArchivePaths = const <String>[],
    Map<String, String> componentVersions = const <String, String>{},
    bool preserveExistingRuntimeFiles = false,
    RuntimeInstallProgressSink? progressSink,
  }) {
    final installResult = _runtimePackageInstaller.install(
      RuntimePackageInstallRequest(
        runtimeLabel: 'macOS Wine',
        archivePath: archivePath,
        archiveSha256: archiveSha256,
        componentArchivePaths: componentArchivePaths,
        componentVersions: componentVersions,
        runtimeRoot: Directory(_macosWineRuntimeRoot(environment)),
        requiredExecutableRelativePath:
            _macosKonyakRuntimePlatformSpec.requiredExecutableRelativePath,
        expectedExecutablePath: _macosWineExecutable(environment),
        preserveExistingRuntimeFiles: preserveExistingRuntimeFiles,
        normalizeStagingRoot:
            _macosKonyakRuntimePlatformSpec.layoutNormalization ==
                _RuntimeLayoutNormalization.macosWineBundle
            ? _normalizeMacosWineRuntimeLayout
            : null,
        afterManifestWrite:
            _macosKonyakRuntimePlatformSpec.layoutNormalization ==
                _RuntimeLayoutNormalization.macosWineBundle
            ? _ensureMacosWine64Alias
            : null,
        progressSink: progressSink,
      ),
    );
    switch (installResult) {
      case RuntimePackageInstallFailed(:final message):
        return MacosWineInstallFailed(message);
      case RuntimePackageInstallCompleted():
        break;
    }

    final runtime = _macosWineRuntimeRecord(
      environment: environment,
      fileStatusProbe: const DartIoFileStatusProbe(),
      runtimeStackVersionProbe: _runtimeStackVersionProbe,
    );

    if (runtime.isInstalled != true) {
      return MacosWineInstallFailed(
        'macOS Wine archive did not install `${runtime.executablePath}`.',
      );
    }

    _emitRuntimeInstallProgress(
      progressSink,
      stage: 'complete',
      message: 'Installed Konyak macOS Wine.',
      fraction: 1,
    );

    return MacosWineInstallCompleted(runtime: runtime);
  }

  MacosWineInstallResult _installMacosWineStackFromSourceManifest(
    String sourceManifest, {
    required String? sourceManifestSignature,
    required bool preserveExistingRuntimeFiles,
    required RuntimeInstallProgressSink? progressSink,
  }) {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-macos-wine-stack-',
    );
    try {
      _emitRuntimeInstallProgress(
        progressSink,
        stage: 'readingManifest',
        message: 'Reading Konyak macOS Wine manifest...',
        fraction: 0.02,
      );
      final manifestPayload = _readRuntimeStackSourceText(
        sourceManifest,
        signatureSource: sourceManifestSignature,
      );
      final manifest = _runtimeStackSourceManifestFromPayload(manifestPayload);
      if (manifest == null) {
        return const MacosWineInstallFailed(
          'Runtime stack source manifest is invalid.',
        );
      }
      final bundleResult = _resolveRuntimeStackSourceArchiveBundle(
        manifest: manifest,
        platformSpec: _macosKonyakRuntimePlatformSpec,
        tempDirectory: tempDirectory,
        progressSink: progressSink,
      );
      return switch (bundleResult) {
        _RuntimeStackSourceArchiveBundleFailed(:final message) =>
          MacosWineInstallFailed(message),
        _RuntimeStackSourceArchiveBundleResolved(:final bundle) =>
          _installMacosWineArchive(
            archivePath: bundle.wineArchivePath,
            archiveSha256: null,
            componentArchivePaths: bundle.componentArchivePaths,
            componentVersions: bundle.componentVersions,
            preserveExistingRuntimeFiles: preserveExistingRuntimeFiles,
            progressSink: progressSink,
          ),
      };
    } on FileSystemException catch (error) {
      return MacosWineInstallFailed(error.message);
    } on ProcessException catch (error) {
      return MacosWineInstallFailed(error.message);
    } finally {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    }
  }

  Future<MacosWineInstallResult>
  _installMacosWineStackFromSourceManifestStreaming(
    String sourceManifest, {
    required String? sourceManifestSignature,
    required bool preserveExistingRuntimeFiles,
    required RuntimeInstallProgressSink? progressSink,
  }) async {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-macos-wine-stack-',
    );
    try {
      _emitRuntimeInstallProgress(
        progressSink,
        stage: 'readingManifest',
        message: 'Reading Konyak macOS Wine manifest...',
        fraction: 0.02,
      );
      final manifestPayload = _readRuntimeStackSourceText(
        sourceManifest,
        signatureSource: sourceManifestSignature,
      );
      final manifest = _runtimeStackSourceManifestFromPayload(manifestPayload);
      if (manifest == null) {
        return const MacosWineInstallFailed(
          'Runtime stack source manifest is invalid.',
        );
      }
      final bundleResult =
          await _resolveRuntimeStackSourceArchiveBundleStreaming(
            manifest: manifest,
            platformSpec: _macosKonyakRuntimePlatformSpec,
            tempDirectory: tempDirectory,
            progressSink: progressSink,
          );
      return switch (bundleResult) {
        _RuntimeStackSourceArchiveBundleFailed(:final message) =>
          MacosWineInstallFailed(message),
        _RuntimeStackSourceArchiveBundleResolved(:final bundle) =>
          _installMacosWineArchive(
            archivePath: bundle.wineArchivePath,
            archiveSha256: null,
            componentArchivePaths: bundle.componentArchivePaths,
            componentVersions: bundle.componentVersions,
            preserveExistingRuntimeFiles: preserveExistingRuntimeFiles,
            progressSink: progressSink,
          ),
      };
    } on FileSystemException catch (error) {
      return MacosWineInstallFailed(error.message);
    } on ProcessException catch (error) {
      return MacosWineInstallFailed(error.message);
    } finally {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    }
  }

  String _readRuntimeStackSourceText(
    String source, {
    required String? signatureSource,
  }) {
    return _readAndVerifyRuntimeStackSourceText(
      source: source,
      signatureSource: signatureSource,
      publicKeyPath:
          _nonEmptyEnvironmentValue(
            environment,
            'KONYAK_RUNTIME_STACK_PUBLIC_KEY_PATH',
          ) ??
          _nonEmptyEnvironmentValue(
            environment,
            'KONYAK_MACOS_WINE_STACK_PUBLIC_KEY_PATH',
          ),
      publicKeyText:
          _nonEmptyEnvironmentValue(
            environment,
            'KONYAK_RUNTIME_STACK_PUBLIC_KEY',
          ) ??
          _nonEmptyEnvironmentValue(
            environment,
            'KONYAK_MACOS_WINE_STACK_PUBLIC_KEY',
          ),
    );
  }

  void _normalizeMacosWineRuntimeLayout(Directory runtimeRoot) {
    _moveRuntimeLayoutChildrenToRoot(
      runtimeRoot: runtimeRoot,
      sourceRoot: Directory(_joinPath(runtimeRoot.path, const ['Wine'])),
    );
    _moveRuntimeLayoutChildrenToRoot(
      runtimeRoot: runtimeRoot,
      sourceRoot: Directory(
        _joinPath(runtimeRoot.path, const ['Contents', 'Resources', 'wine']),
      ),
    );
    for (final entry in runtimeRoot.listSync()) {
      if (entry is! Directory || !_basename(entry.path).endsWith('.app')) {
        continue;
      }
      _moveRuntimeLayoutChildrenToRoot(
        runtimeRoot: runtimeRoot,
        sourceRoot: Directory(
          _joinPath(entry.path, const ['Contents', 'Resources', 'wine']),
        ),
      );
      if (entry.existsSync()) {
        entry.deleteSync(recursive: true);
      }
    }
    _normalizeMacosRuntimeComponents(runtimeRoot);
  }

  void _normalizeMacosRuntimeComponents(Directory runtimeRoot) {
    final componentsRoot = Directory(
      _joinPath(runtimeRoot.path, const ['Components']),
    );
    if (!componentsRoot.existsSync()) {
      return;
    }

    for (final componentId in const <String>[
      'DXVK-macOS',
      'DXVK',
      'MoltenVK',
      'GStreamer',
      'wine-mono',
      'winetricks',
      'GPTK-D3DMetal',
      'gptk-d3dmetal',
      'D3DMetal',
    ]) {
      _moveRuntimeLayoutChildrenToRoot(
        runtimeRoot: runtimeRoot,
        sourceRoot: Directory(_joinPath(componentsRoot.path, [componentId])),
      );
    }

    if (componentsRoot.existsSync() && componentsRoot.listSync().isEmpty) {
      componentsRoot.deleteSync(recursive: true);
    }
  }

  void _moveRuntimeLayoutChildrenToRoot({
    required Directory runtimeRoot,
    required Directory sourceRoot,
  }) {
    if (!sourceRoot.existsSync()) {
      return;
    }

    for (final entry in sourceRoot.listSync()) {
      final targetPath = _joinPath(runtimeRoot.path, [_basename(entry.path)]);
      _moveFileSystemEntity(entry, targetPath);
    }

    sourceRoot.deleteSync(recursive: true);
  }

  void _moveFileSystemEntity(FileSystemEntity entry, String targetPath) {
    final sourceType = FileSystemEntity.typeSync(entry.path);
    final targetType = FileSystemEntity.typeSync(targetPath);
    if (sourceType == FileSystemEntityType.directory &&
        targetType == FileSystemEntityType.directory) {
      for (final child in Directory(entry.path).listSync()) {
        _moveFileSystemEntity(
          child,
          _joinPath(targetPath, [_basename(child.path)]),
        );
      }
      Directory(entry.path).deleteSync();
      return;
    }

    if (targetType != FileSystemEntityType.notFound) {
      _deleteFileSystemEntity(targetPath, targetType);
    }
    entry.renameSync(targetPath);
  }

  void _ensureMacosWine64Alias(Directory runtimeRoot) {
    final binPath = _joinPath(runtimeRoot.path, const ['bin']);
    final winePath = _joinPath(binPath, const ['wine']);
    final wine64Path = _joinPath(binPath, const ['wine64']);

    if (FileSystemEntity.typeSync(wine64Path) !=
        FileSystemEntityType.notFound) {
      return;
    }
    if (FileSystemEntity.typeSync(winePath) == FileSystemEntityType.notFound) {
      return;
    }

    Link(wine64Path).createSync('wine');
  }

  void _deleteFileSystemEntity(String path, FileSystemEntityType type) {
    switch (type) {
      case FileSystemEntityType.directory:
        Directory(path).deleteSync(recursive: true);
      case FileSystemEntityType.file:
      case FileSystemEntityType.link:
      case FileSystemEntityType.pipe:
      case FileSystemEntityType.unixDomainSock:
        File(path).deleteSync();
      case FileSystemEntityType.notFound:
        break;
    }
  }
}

class DartIoLinuxWineInstaller implements LinuxWineInstaller {
  DartIoLinuxWineInstaller({
    required this.hostPlatform,
    required Map<String, String> environment,
    FileStatusProbe fileStatusProbe = const DartIoFileStatusProbe(),
    RuntimeStackVersionProbe runtimeStackVersionProbe =
        const DartIoRuntimeStackVersionProbe(),
    RuntimePackageInstaller runtimePackageInstaller =
        const DartIoRuntimePackageInstaller(),
  }) : environment = Map.unmodifiable(environment),
       _fileStatusProbe = fileStatusProbe,
       _runtimeStackVersionProbe = runtimeStackVersionProbe,
       _runtimePackageInstaller = runtimePackageInstaller;

  factory DartIoLinuxWineInstaller.current() {
    return DartIoLinuxWineInstaller(
      hostPlatform: _currentHostPlatform(),
      environment: Platform.environment,
    );
  }

  final KonyakHostPlatform hostPlatform;
  final Map<String, String> environment;
  final FileStatusProbe _fileStatusProbe;
  final RuntimeStackVersionProbe _runtimeStackVersionProbe;
  final RuntimePackageInstaller _runtimePackageInstaller;

  @override
  LinuxWineInstallResult install(
    LinuxWineInstallRequest request, {
    RuntimeInstallProgressSink? progressSink,
  }) {
    final progress = request.emitProgress ? progressSink : null;
    _emitRuntimeInstallProgress(
      progress,
      stage: 'preparing',
      message: 'Preparing Konyak Linux Wine install...',
      fraction: 0,
    );

    if (hostPlatform != KonyakHostPlatform.linux) {
      return const LinuxWineInstallFailed(
        'Linux Wine installation is supported on Linux only.',
      );
    }

    final currentRuntime = _linuxWineRuntimeRecord(
      environment: environment,
      fileStatusProbe: _fileStatusProbe,
      runtimeStackVersionProbe: _runtimeStackVersionProbe,
    );
    final componentArchivePaths = List<String>.unmodifiable(
      request.componentArchivePaths,
    );
    final sourceManifest =
        request.sourceManifest ??
        _runtimeSourceManifestForPlatform(
          platformSpec: _linuxWineRuntimePlatformSpec,
          environment: environment,
        );
    final sourceManifestSignature =
        request.sourceManifestSignature ??
        _runtimeSourceManifestSignatureForPlatform(
          platformSpec: _linuxWineRuntimePlatformSpec,
          environment: environment,
        );
    if (!request.force &&
        request.archivePath == null &&
        request.archiveUrl == null &&
        componentArchivePaths.isEmpty &&
        request.sourceManifest == null &&
        currentRuntime.isInstalled == true &&
        currentRuntime.stack?.isComplete == true) {
      _emitRuntimeInstallProgress(
        progress,
        stage: 'complete',
        message: 'Konyak Linux Wine is already installed.',
        fraction: 1,
      );
      return LinuxWineInstallCompleted(runtime: currentRuntime);
    }

    if (sourceManifest != null) {
      return _installLinuxWineStackFromSourceManifest(
        sourceManifest,
        sourceManifestSignature: sourceManifestSignature,
        progressSink: progress,
      );
    }

    final archivePath = request.archivePath;
    if (archivePath != null) {
      return _installLinuxWineArchive(
        archivePath: archivePath,
        archiveSha256: request.archiveSha256,
        componentArchivePaths: componentArchivePaths,
        progressSink: progress,
      );
    }

    final archiveUrl =
        request.archiveUrl ??
        _runtimeDefaultArchiveUrl(
          platformSpec: _linuxWineRuntimePlatformSpec,
          environment: environment,
        );
    if (archiveUrl == null) {
      return const LinuxWineInstallFailed(
        'Linux Wine archive is not configured.',
      );
    }

    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-linux-wine-',
    );
    final archiveFileName =
        _fileNameFromUrl(archiveUrl) ??
        _linuxWineRuntimePlatformSpec.defaultArchiveFileName;
    final downloadedArchivePath = _joinPath(tempDirectory.path, [
      archiveFileName,
    ]);

    try {
      final downloadFailure = _downloadRuntimeStackSourceArchive(
        source: archiveUrl,
        targetPath: downloadedArchivePath,
        progressSink: progress,
        stage: 'downloading',
        message: 'Downloading Konyak Linux Wine...',
        startFraction: 0.05,
        endFraction: 0.65,
      );
      if (downloadFailure != null) {
        return LinuxWineInstallFailed(downloadFailure);
      }

      return _installLinuxWineArchive(
        archivePath: downloadedArchivePath,
        archiveSha256: request.archiveSha256,
        componentArchivePaths: componentArchivePaths,
        progressSink: progress,
      );
    } on FileSystemException catch (error) {
      return LinuxWineInstallFailed(error.message);
    } on ProcessException catch (error) {
      return LinuxWineInstallFailed(error.message);
    } finally {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    }
  }

  Future<LinuxWineInstallResult> installStreaming(
    LinuxWineInstallRequest request, {
    RuntimeInstallProgressSink? progressSink,
  }) async {
    final progress = request.emitProgress ? progressSink : null;
    _emitRuntimeInstallProgress(
      progress,
      stage: 'preparing',
      message: 'Preparing Konyak Linux Wine install...',
      fraction: 0,
    );

    if (hostPlatform != KonyakHostPlatform.linux) {
      return const LinuxWineInstallFailed(
        'Linux Wine installation is supported on Linux only.',
      );
    }

    final currentRuntime = _linuxWineRuntimeRecord(
      environment: environment,
      fileStatusProbe: _fileStatusProbe,
      runtimeStackVersionProbe: _runtimeStackVersionProbe,
    );
    final componentArchivePaths = List<String>.unmodifiable(
      request.componentArchivePaths,
    );
    final sourceManifest =
        request.sourceManifest ??
        _runtimeSourceManifestForPlatform(
          platformSpec: _linuxWineRuntimePlatformSpec,
          environment: environment,
        );
    final sourceManifestSignature =
        request.sourceManifestSignature ??
        _runtimeSourceManifestSignatureForPlatform(
          platformSpec: _linuxWineRuntimePlatformSpec,
          environment: environment,
        );
    if (!request.force &&
        request.archivePath == null &&
        request.archiveUrl == null &&
        componentArchivePaths.isEmpty &&
        request.sourceManifest == null &&
        currentRuntime.isInstalled == true &&
        currentRuntime.stack?.isComplete == true) {
      _emitRuntimeInstallProgress(
        progress,
        stage: 'complete',
        message: 'Konyak Linux Wine is already installed.',
        fraction: 1,
      );
      return LinuxWineInstallCompleted(runtime: currentRuntime);
    }

    if (sourceManifest != null) {
      return _installLinuxWineStackFromSourceManifestStreaming(
        sourceManifest,
        sourceManifestSignature: sourceManifestSignature,
        progressSink: progress,
      );
    }

    final archivePath = request.archivePath;
    if (archivePath != null) {
      return _installLinuxWineArchive(
        archivePath: archivePath,
        archiveSha256: request.archiveSha256,
        componentArchivePaths: componentArchivePaths,
        progressSink: progress,
      );
    }

    final archiveUrl =
        request.archiveUrl ??
        _runtimeDefaultArchiveUrl(
          platformSpec: _linuxWineRuntimePlatformSpec,
          environment: environment,
        );
    if (archiveUrl == null) {
      return const LinuxWineInstallFailed(
        'Linux Wine archive is not configured.',
      );
    }

    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-linux-wine-',
    );
    final archiveFileName =
        _fileNameFromUrl(archiveUrl) ??
        _linuxWineRuntimePlatformSpec.defaultArchiveFileName;
    final downloadedArchivePath = _joinPath(tempDirectory.path, [
      archiveFileName,
    ]);

    try {
      final downloadFailure = await _downloadRuntimeStackSourceArchiveStreaming(
        source: archiveUrl,
        targetPath: downloadedArchivePath,
        progressSink: progress,
        stage: 'downloading',
        message: 'Downloading Konyak Linux Wine...',
        startFraction: 0.05,
        endFraction: 0.65,
      );
      if (downloadFailure != null) {
        return LinuxWineInstallFailed(downloadFailure);
      }

      return _installLinuxWineArchive(
        archivePath: downloadedArchivePath,
        archiveSha256: request.archiveSha256,
        componentArchivePaths: componentArchivePaths,
        progressSink: progress,
      );
    } on FileSystemException catch (error) {
      return LinuxWineInstallFailed(error.message);
    } on ProcessException catch (error) {
      return LinuxWineInstallFailed(error.message);
    } finally {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    }
  }

  LinuxWineInstallResult _installLinuxWineArchive({
    required String archivePath,
    required String? archiveSha256,
    List<String> componentArchivePaths = const <String>[],
    Map<String, String> componentVersions = const <String, String>{},
    RuntimeInstallProgressSink? progressSink,
  }) {
    final installResult = _runtimePackageInstaller.install(
      RuntimePackageInstallRequest(
        runtimeLabel: 'Linux Wine',
        archivePath: archivePath,
        archiveSha256: archiveSha256,
        componentArchivePaths: componentArchivePaths,
        componentVersions: componentVersions,
        runtimeRoot: Directory(_linuxWineRuntimeRoot(environment)),
        requiredExecutableRelativePath:
            _linuxWineRuntimePlatformSpec.requiredExecutableRelativePath,
        expectedExecutablePath: _linuxWineExecutable(environment),
        progressSink: progressSink,
      ),
    );
    switch (installResult) {
      case RuntimePackageInstallFailed(:final message):
        return LinuxWineInstallFailed(message);
      case RuntimePackageInstallCompleted():
        break;
    }

    final runtime = _linuxWineRuntimeRecord(
      environment: environment,
      fileStatusProbe: const DartIoFileStatusProbe(),
      runtimeStackVersionProbe: _runtimeStackVersionProbe,
    );
    if (runtime.isInstalled != true) {
      return LinuxWineInstallFailed(
        'Linux Wine archive did not install `${runtime.executablePath}`.',
      );
    }

    _emitRuntimeInstallProgress(
      progressSink,
      stage: 'complete',
      message: 'Installed Konyak Linux Wine.',
      fraction: 1,
    );

    return LinuxWineInstallCompleted(runtime: runtime);
  }

  LinuxWineInstallResult _installLinuxWineStackFromSourceManifest(
    String sourceManifest, {
    required String? sourceManifestSignature,
    required RuntimeInstallProgressSink? progressSink,
  }) {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-linux-wine-stack-',
    );
    try {
      _emitRuntimeInstallProgress(
        progressSink,
        stage: 'readingManifest',
        message: 'Reading Konyak Linux Wine manifest...',
        fraction: 0.02,
      );
      final manifestPayload = _readRuntimeStackSourceText(
        sourceManifest,
        signatureSource: sourceManifestSignature,
      );
      final manifest = _runtimeStackSourceManifestFromPayload(manifestPayload);
      if (manifest == null) {
        return const LinuxWineInstallFailed(
          'Runtime stack source manifest is invalid.',
        );
      }
      final bundleResult = _resolveRuntimeStackSourceArchiveBundle(
        manifest: manifest,
        platformSpec: _linuxWineRuntimePlatformSpec,
        tempDirectory: tempDirectory,
        progressSink: progressSink,
      );
      return switch (bundleResult) {
        _RuntimeStackSourceArchiveBundleFailed(:final message) =>
          LinuxWineInstallFailed(message),
        _RuntimeStackSourceArchiveBundleResolved(:final bundle) =>
          _installLinuxWineArchive(
            archivePath: bundle.wineArchivePath,
            archiveSha256: null,
            componentArchivePaths: bundle.componentArchivePaths,
            componentVersions: bundle.componentVersions,
            progressSink: progressSink,
          ),
      };
    } on FileSystemException catch (error) {
      return LinuxWineInstallFailed(error.message);
    } on ProcessException catch (error) {
      return LinuxWineInstallFailed(error.message);
    } finally {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    }
  }

  Future<LinuxWineInstallResult>
  _installLinuxWineStackFromSourceManifestStreaming(
    String sourceManifest, {
    required String? sourceManifestSignature,
    required RuntimeInstallProgressSink? progressSink,
  }) async {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'konyak-linux-wine-stack-',
    );
    try {
      _emitRuntimeInstallProgress(
        progressSink,
        stage: 'readingManifest',
        message: 'Reading Konyak Linux Wine manifest...',
        fraction: 0.02,
      );
      final manifestPayload = _readRuntimeStackSourceText(
        sourceManifest,
        signatureSource: sourceManifestSignature,
      );
      final manifest = _runtimeStackSourceManifestFromPayload(manifestPayload);
      if (manifest == null) {
        return const LinuxWineInstallFailed(
          'Runtime stack source manifest is invalid.',
        );
      }
      final bundleResult =
          await _resolveRuntimeStackSourceArchiveBundleStreaming(
            manifest: manifest,
            platformSpec: _linuxWineRuntimePlatformSpec,
            tempDirectory: tempDirectory,
            progressSink: progressSink,
          );
      return switch (bundleResult) {
        _RuntimeStackSourceArchiveBundleFailed(:final message) =>
          LinuxWineInstallFailed(message),
        _RuntimeStackSourceArchiveBundleResolved(:final bundle) =>
          _installLinuxWineArchive(
            archivePath: bundle.wineArchivePath,
            archiveSha256: null,
            componentArchivePaths: bundle.componentArchivePaths,
            componentVersions: bundle.componentVersions,
            progressSink: progressSink,
          ),
      };
    } on FileSystemException catch (error) {
      return LinuxWineInstallFailed(error.message);
    } on ProcessException catch (error) {
      return LinuxWineInstallFailed(error.message);
    } finally {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    }
  }

  String _readRuntimeStackSourceText(
    String source, {
    required String? signatureSource,
  }) {
    return _readAndVerifyRuntimeStackSourceText(
      source: source,
      signatureSource: signatureSource,
      publicKeyPath:
          _nonEmptyEnvironmentValue(
            environment,
            'KONYAK_RUNTIME_STACK_PUBLIC_KEY_PATH',
          ) ??
          _nonEmptyEnvironmentValue(
            environment,
            'KONYAK_LINUX_WINE_STACK_PUBLIC_KEY_PATH',
          ),
      publicKeyText:
          _nonEmptyEnvironmentValue(
            environment,
            'KONYAK_RUNTIME_STACK_PUBLIC_KEY',
          ) ??
          _nonEmptyEnvironmentValue(
            environment,
            'KONYAK_LINUX_WINE_STACK_PUBLIC_KEY',
          ),
    );
  }
}

class RuntimeUpdateRecord {
  const RuntimeUpdateRecord({
    required this.runtimeId,
    required this.status,
    this.currentVersion,
    this.latestVersion,
    this.versionUrl,
    this.archiveUrl,
    this.sourceManifestUrl,
    this.sourceManifestSignatureUrl,
  });

  final String runtimeId;
  final String status;
  final String? currentVersion;
  final String? latestVersion;
  final String? versionUrl;
  final String? archiveUrl;
  final String? sourceManifestUrl;
  final String? sourceManifestSignatureUrl;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'runtimeId': runtimeId,
      'status': status,
      if (currentVersion != null) 'currentVersion': currentVersion,
      if (latestVersion != null) 'latestVersion': latestVersion,
      if (versionUrl != null) 'versionUrl': versionUrl,
      if (archiveUrl != null) 'archiveUrl': archiveUrl,
      if (sourceManifestUrl != null) 'sourceManifestUrl': sourceManifestUrl,
      if (sourceManifestSignatureUrl != null)
        'sourceManifestSignatureUrl': sourceManifestSignatureUrl,
    };
  }
}

sealed class RuntimeUpdateCheckResult {
  const RuntimeUpdateCheckResult();
}

class RuntimeUpdateCheckCompleted extends RuntimeUpdateCheckResult {
  const RuntimeUpdateCheckCompleted(this.update);

  final RuntimeUpdateRecord update;
}

class RuntimeUpdateCheckFailed extends RuntimeUpdateCheckResult {
  const RuntimeUpdateCheckFailed(this.message);

  final String message;
}

class RuntimeUpdateRuntimeNotFound extends RuntimeUpdateCheckResult {
  const RuntimeUpdateRuntimeNotFound(this.runtimeId);

  final String runtimeId;
}

abstract interface class RuntimeUpdateChecker {
  RuntimeUpdateCheckResult check(String runtimeId);
}

class AppUpdateRecord {
  const AppUpdateRecord({
    required this.appId,
    required this.status,
    this.currentVersion,
    this.latestVersion,
    this.versionUrl,
    this.archiveUrl,
    this.archiveSha256,
  });

  final String appId;
  final String status;
  final String? currentVersion;
  final String? latestVersion;
  final String? versionUrl;
  final String? archiveUrl;
  final String? archiveSha256;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'appId': appId,
      'status': status,
      if (currentVersion != null) 'currentVersion': currentVersion,
      if (latestVersion != null) 'latestVersion': latestVersion,
      if (versionUrl != null) 'versionUrl': versionUrl,
      if (archiveUrl != null) 'archiveUrl': archiveUrl,
      if (archiveSha256 != null) 'archiveSha256': archiveSha256,
    };
  }
}

sealed class AppUpdateCheckResult {
  const AppUpdateCheckResult();
}

class AppUpdateCheckCompleted extends AppUpdateCheckResult {
  const AppUpdateCheckCompleted(this.update);

  final AppUpdateRecord update;
}

class AppUpdateCheckFailed extends AppUpdateCheckResult {
  const AppUpdateCheckFailed(this.message);

  final String message;
}

abstract interface class AppUpdateChecker {
  AppUpdateCheckResult check();
}

class AppUpdateInstallRecord {
  const AppUpdateInstallRecord({
    required this.appId,
    required this.status,
    this.currentVersion,
    this.installedVersion,
    this.archiveUrl,
    this.archiveSha256,
    this.installPath,
  });

  final String appId;
  final String status;
  final String? currentVersion;
  final String? installedVersion;
  final String? archiveUrl;
  final String? archiveSha256;
  final String? installPath;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'appId': appId,
      'status': status,
      if (currentVersion != null) 'currentVersion': currentVersion,
      if (installedVersion != null) 'installedVersion': installedVersion,
      if (archiveUrl != null) 'archiveUrl': archiveUrl,
      if (archiveSha256 != null) 'archiveSha256': archiveSha256,
      if (installPath != null) 'installPath': installPath,
    };
  }
}

sealed class AppUpdateInstallResult {
  const AppUpdateInstallResult();
}

class AppUpdateInstallCompleted extends AppUpdateInstallResult {
  const AppUpdateInstallCompleted(this.install);

  final AppUpdateInstallRecord install;
}

class AppUpdateInstallFailed extends AppUpdateInstallResult {
  const AppUpdateInstallFailed(this.message);

  final String message;
}

abstract interface class AppUpdateInstaller {
  AppUpdateInstallResult install(AppUpdateRecord update);
}

class RuntimeReleaseMetadata {
  const RuntimeReleaseMetadata({
    required this.version,
    this.archiveUrl,
    this.archiveSha256,
    this.sourceManifestUrl,
    this.sourceManifestSignatureUrl,
  });

  final String version;
  final String? archiveUrl;
  final String? archiveSha256;
  final String? sourceManifestUrl;
  final String? sourceManifestSignatureUrl;
}

sealed class RuntimeReleaseMetadataFetchResult {
  const RuntimeReleaseMetadataFetchResult();
}

class RuntimeReleaseMetadataFetched extends RuntimeReleaseMetadataFetchResult {
  const RuntimeReleaseMetadataFetched(this.metadata);

  final RuntimeReleaseMetadata metadata;
}

class RuntimeReleaseMetadataFetchFailed
    extends RuntimeReleaseMetadataFetchResult {
  const RuntimeReleaseMetadataFetchFailed(this.message);

  final String message;
}

abstract interface class RuntimeReleaseMetadataFetcher {
  RuntimeReleaseMetadataFetchResult fetch(String versionUrl);
}

class StaticRuntimeReleaseMetadataFetcher
    implements RuntimeReleaseMetadataFetcher {
  const StaticRuntimeReleaseMetadataFetcher(this.metadata);

  final RuntimeReleaseMetadata metadata;

  @override
  RuntimeReleaseMetadataFetchResult fetch(String versionUrl) {
    return RuntimeReleaseMetadataFetched(metadata);
  }
}

class DartIoRuntimeReleaseMetadataFetcher
    implements RuntimeReleaseMetadataFetcher {
  const DartIoRuntimeReleaseMetadataFetcher();

  @override
  RuntimeReleaseMetadataFetchResult fetch(String versionUrl) {
    try {
      final result = Process.runSync('curl', [
        '--fail',
        '--location',
        '--silent',
        versionUrl,
      ], runInShell: false);
      if (result.exitCode != 0) {
        return RuntimeReleaseMetadataFetchFailed(
          _commandFailureMessage('check runtime update', result),
        );
      }

      final decoded = jsonDecode(_processOutputToString(result.stdout));
      final version = _runtimeReleaseVersion(decoded);
      if (version == null) {
        return const RuntimeReleaseMetadataFetchFailed(
          'Runtime release metadata does not contain a version.',
        );
      }

      final archiveUrl = _runtimeReleaseArchiveUrl(decoded);
      return RuntimeReleaseMetadataFetched(
        RuntimeReleaseMetadata(
          version: version,
          archiveUrl: archiveUrl,
          archiveSha256: _runtimeReleaseArchiveSha256(decoded, archiveUrl),
          sourceManifestUrl: _runtimeReleaseSourceManifestUrl(decoded),
          sourceManifestSignatureUrl: _runtimeReleaseSourceManifestSignatureUrl(
            decoded,
          ),
        ),
      );
    } on FormatException {
      return const RuntimeReleaseMetadataFetchFailed(
        'Runtime release metadata is not valid JSON.',
      );
    } on ProcessException catch (error) {
      return RuntimeReleaseMetadataFetchFailed(error.message);
    }
  }
}

class DartIoRuntimeUpdateChecker implements RuntimeUpdateChecker {
  const DartIoRuntimeUpdateChecker({
    required this.runtimeCatalog,
    this.releaseMetadataFetcher = const DartIoRuntimeReleaseMetadataFetcher(),
  });

  final RuntimeCatalog runtimeCatalog;
  final RuntimeReleaseMetadataFetcher releaseMetadataFetcher;

  @override
  RuntimeUpdateCheckResult check(String runtimeId) {
    final runtime = _runtimeById(runtimeCatalog.listRuntimes(), runtimeId);
    if (runtime == null) {
      return RuntimeUpdateRuntimeNotFound(runtimeId);
    }

    final versionUrl = runtime.versionUrl;
    if (versionUrl == null || versionUrl.trim().isEmpty) {
      return RuntimeUpdateCheckCompleted(
        RuntimeUpdateRecord(
          runtimeId: runtime.id,
          status: 'unknown',
          currentVersion: _runtimeWineVersion(runtime),
          archiveUrl: runtime.archiveUrl,
        ),
      );
    }

    final metadata = releaseMetadataFetcher.fetch(versionUrl);
    return switch (metadata) {
      RuntimeReleaseMetadataFetched(:final metadata) =>
        RuntimeUpdateCheckCompleted(
          RuntimeUpdateRecord(
            runtimeId: runtime.id,
            status: _updateStatus(
              currentVersion: _runtimeWineVersion(runtime),
              latestVersion: metadata.version,
            ),
            currentVersion: _runtimeWineVersion(runtime),
            latestVersion: metadata.version,
            versionUrl: versionUrl,
            archiveUrl: metadata.archiveUrl ?? runtime.archiveUrl,
            sourceManifestUrl: metadata.sourceManifestUrl,
            sourceManifestSignatureUrl: metadata.sourceManifestSignatureUrl,
          ),
        ),
      RuntimeReleaseMetadataFetchFailed(:final message) =>
        RuntimeUpdateCheckFailed(message),
    };
  }
}

class DartIoAppUpdateChecker implements AppUpdateChecker {
  const DartIoAppUpdateChecker({
    required this.appId,
    required this.currentVersion,
    required this.versionUrl,
    this.archiveUrl,
    this.archiveSha256,
    this.releaseMetadataFetcher = const DartIoRuntimeReleaseMetadataFetcher(),
  });

  factory DartIoAppUpdateChecker.fromEnvironment(
    Map<String, String> environment,
  ) {
    return DartIoAppUpdateChecker(
      appId:
          _nonEmptyEnvironmentValue(environment, 'KONYAK_APP_ID') ??
          konyakAppId,
      currentVersion:
          _nonEmptyEnvironmentValue(environment, 'KONYAK_APP_VERSION') ??
          konyakAppVersion,
      versionUrl:
          _nonEmptyEnvironmentValue(environment, 'KONYAK_APP_VERSION_URL') ??
          konyakAppVersionUrl,
      archiveUrl: _nonEmptyEnvironmentValue(
        environment,
        'KONYAK_APP_ARCHIVE_URL',
      ),
      archiveSha256: _nonEmptyEnvironmentValue(
        environment,
        'KONYAK_APP_ARCHIVE_SHA256',
      ),
    );
  }

  final String appId;
  final String currentVersion;
  final String versionUrl;
  final String? archiveUrl;
  final String? archiveSha256;
  final RuntimeReleaseMetadataFetcher releaseMetadataFetcher;

  @override
  AppUpdateCheckResult check() {
    if (versionUrl.trim().isEmpty) {
      return AppUpdateCheckCompleted(
        AppUpdateRecord(
          appId: appId,
          status: 'unknown',
          currentVersion: currentVersion,
          archiveUrl: archiveUrl,
          archiveSha256: archiveSha256,
        ),
      );
    }

    final metadata = releaseMetadataFetcher.fetch(versionUrl);
    return switch (metadata) {
      RuntimeReleaseMetadataFetched(:final metadata) => AppUpdateCheckCompleted(
        AppUpdateRecord(
          appId: appId,
          status: _updateStatus(
            currentVersion: currentVersion,
            latestVersion: metadata.version,
          ),
          currentVersion: currentVersion,
          latestVersion: metadata.version,
          versionUrl: versionUrl,
          archiveUrl: metadata.archiveUrl ?? archiveUrl,
          archiveSha256: metadata.archiveSha256 ?? archiveSha256,
        ),
      ),
      RuntimeReleaseMetadataFetchFailed(:final message) => AppUpdateCheckFailed(
        message,
      ),
    };
  }
}

class DartIoAppUpdateInstaller implements AppUpdateInstaller {
  DartIoAppUpdateInstaller({
    required Map<String, String> environment,
    KonyakHostPlatform? hostPlatform,
    PathOpener pathOpener = const DartIoPathOpener(),
    DetachedProcessStarter detachedProcessStarter =
        const DartIoDetachedProcessStarter(),
  }) : environment = Map.unmodifiable(environment),
       hostPlatform = hostPlatform ?? _currentHostPlatform(),
       _pathOpener = pathOpener,
       _detachedProcessStarter = detachedProcessStarter;

  factory DartIoAppUpdateInstaller.fromEnvironment(
    Map<String, String> environment,
  ) {
    return DartIoAppUpdateInstaller(environment: environment);
  }

  final Map<String, String> environment;
  final KonyakHostPlatform hostPlatform;
  final PathOpener _pathOpener;
  final DetachedProcessStarter _detachedProcessStarter;

  @override
  AppUpdateInstallResult install(AppUpdateRecord update) {
    final archiveUrl = update.archiveUrl;
    if (archiveUrl == null || archiveUrl.trim().isEmpty) {
      return const AppUpdateInstallFailed(
        'Konyak update metadata does not contain an archive URL.',
      );
    }
    final expectedSha256 = update.archiveSha256;
    if (expectedSha256 == null || !_isSha256Hex(expectedSha256)) {
      return const AppUpdateInstallFailed(
        'Konyak update metadata does not contain a valid archive checksum.',
      );
    }

    final fileName = _fileNameFromUrl(archiveUrl) ?? 'Konyak-update';
    final updatesDirectory = Directory(_appUpdateCacheDirectory(environment));
    final archivePath = _joinPath(updatesDirectory.path, [fileName]);

    try {
      updatesDirectory.createSync(recursive: true);
      final download = Process.runSync('curl', [
        '--fail',
        '--location',
        '--output',
        archivePath,
        archiveUrl,
      ], runInShell: false);
      if (download.exitCode != 0) {
        return AppUpdateInstallFailed(
          _commandFailureMessage('download Konyak update', download),
        );
      }

      final archive = File(archivePath);
      final actualSha256 = _sha256HexDigest(archive);
      if (actualSha256.toLowerCase() != expectedSha256.toLowerCase()) {
        if (archive.existsSync()) {
          archive.deleteSync();
        }
        return AppUpdateInstallFailed(
          'Konyak update archive checksum mismatch: expected '
          '$expectedSha256, got $actualSha256.',
        );
      }

      if (hostPlatform == KonyakHostPlatform.macos) {
        final macosResult = _installMacosAppBundleUpdate(
          update: update,
          archivePath: archivePath,
          actualSha256: actualSha256,
          updatesDirectory: updatesDirectory,
        );
        if (macosResult != null) {
          return macosResult;
        }
      }

      if (hostPlatform == KonyakHostPlatform.linux) {
        final linuxResult = _installLinuxAppImageUpdate(
          update: update,
          archivePath: archivePath,
          actualSha256: actualSha256,
          updatesDirectory: updatesDirectory,
        );
        if (linuxResult != null) {
          return linuxResult;
        }
      }

      final openResult = _pathOpener.openPath(archivePath);
      return switch (openResult) {
        PathOpenCompleted() => AppUpdateInstallCompleted(
          AppUpdateInstallRecord(
            appId: update.appId,
            status: 'installed',
            currentVersion: update.currentVersion,
            installedVersion: update.latestVersion,
            archiveUrl: archiveUrl,
            archiveSha256: actualSha256,
            installPath: archivePath,
          ),
        ),
        PathOpenFailed(:final message) => AppUpdateInstallFailed(message),
      };
    } on FileSystemException catch (error) {
      return AppUpdateInstallFailed(error.message);
    } on ProcessException catch (error) {
      return AppUpdateInstallFailed(error.message);
    }
  }

  AppUpdateInstallResult? _installMacosAppBundleUpdate({
    required AppUpdateRecord update,
    required String archivePath,
    required String actualSha256,
    required Directory updatesDirectory,
  }) {
    final targetBundlePath = _macosAppBundlePath(environment);
    final appPid = _konyakAppPid(environment);
    if (targetBundlePath == null || appPid == null) {
      return null;
    }

    final targetBundle = Directory(targetBundlePath);
    if (!targetBundle.existsSync()) {
      return AppUpdateInstallFailed(
        'Current Konyak app bundle does not exist: $targetBundlePath',
      );
    }

    final stagedArchivePath = _joinPath(updatesDirectory.path, [
      'Konyak-update-${DateTime.now().microsecondsSinceEpoch}.zip',
    ]);
    final stagedArchive = File(stagedArchivePath);
    stagedArchive.parent.createSync(recursive: true);
    File(archivePath).copySync(stagedArchivePath);
    stagedArchive.setLastModifiedSync(DateTime.now());

    final handoffScriptPath = _joinPath(updatesDirectory.path, [
      'install-macos-app-update-${DateTime.now().microsecondsSinceEpoch}.sh',
    ]);
    final handoffScript = File(handoffScriptPath);
    handoffScript.writeAsStringSync(_macosAppBundleUpdateHandoffScript());
    handoffScript.setLastModifiedSync(DateTime.now());
    Process.runSync('chmod', ['755', handoffScriptPath], runInShell: false);

    final startResult = _detachedProcessStarter.start(
      executable: 'bash',
      arguments: [
        handoffScriptPath,
        stagedArchivePath,
        targetBundlePath,
        '$appPid',
      ],
    );
    return switch (startResult) {
      DetachedProcessStartCompleted() => AppUpdateInstallCompleted(
        AppUpdateInstallRecord(
          appId: update.appId,
          status: 'installed',
          currentVersion: update.currentVersion,
          installedVersion: update.latestVersion,
          archiveUrl: update.archiveUrl,
          archiveSha256: actualSha256,
          installPath: targetBundlePath,
        ),
      ),
      DetachedProcessStartFailed(:final message) => AppUpdateInstallFailed(
        message,
      ),
    };
  }

  AppUpdateInstallResult? _installLinuxAppImageUpdate({
    required AppUpdateRecord update,
    required String archivePath,
    required String actualSha256,
    required Directory updatesDirectory,
  }) {
    final targetPath = _linuxAppImageTargetPath(environment);
    final appPid = _konyakAppPid(environment);
    if (targetPath == null || appPid == null) {
      return null;
    }

    final stagedArchivePath = _joinPath(updatesDirectory.path, [
      'Konyak-update-${DateTime.now().microsecondsSinceEpoch}.AppImage',
    ]);
    final stagedArchive = File(stagedArchivePath);
    stagedArchive.parent.createSync(recursive: true);
    File(archivePath).copySync(stagedArchivePath);
    stagedArchive.setLastModifiedSync(DateTime.now());

    final handoffScriptPath = _joinPath(updatesDirectory.path, [
      'install-appimage-update-${DateTime.now().microsecondsSinceEpoch}.sh',
    ]);
    final handoffScript = File(handoffScriptPath);
    handoffScript.writeAsStringSync(_linuxAppImageUpdateHandoffScript());
    handoffScript.setLastModifiedSync(DateTime.now());
    Process.runSync('chmod', ['755', handoffScriptPath], runInShell: false);

    final startResult = _detachedProcessStarter.start(
      executable: 'bash',
      arguments: [handoffScriptPath, stagedArchivePath, targetPath, '$appPid'],
    );
    return switch (startResult) {
      DetachedProcessStartCompleted() => AppUpdateInstallCompleted(
        AppUpdateInstallRecord(
          appId: update.appId,
          status: 'installed',
          currentVersion: update.currentVersion,
          installedVersion: update.latestVersion,
          archiveUrl: update.archiveUrl,
          archiveSha256: actualSha256,
          installPath: targetPath,
        ),
      ),
      DetachedProcessStartFailed(:final message) => AppUpdateInstallFailed(
        message,
      ),
    };
  }
}

class _RuntimeStackComponentDefinition {
  const _RuntimeStackComponentDefinition({
    required this.id,
    required this.name,
    required this.role,
    required this.isRequired,
    required this.relativePaths,
  });

  final String id;
  final String name;
  final String role;
  final bool isRequired;
  final List<List<String>> relativePaths;
}

class _RuntimePlatformSpec {
  const _RuntimePlatformSpec({
    required this.runtimeId,
    required this.runtimeName,
    required this.platform,
    required this.architecture,
    required this.runnerKind,
    required this.stackId,
    required this.stackName,
    required this.requiredExecutableRelativePath,
    required this.defaultArchiveFileName,
    required this.developmentSourceManifestEnvironmentKey,
    required this.releaseSourceManifestEnvironmentKey,
    required this.developmentSourceSignatureEnvironmentKey,
    required this.releaseSourceSignatureEnvironmentKey,
    required this.componentDefinitions,
    this.defaultArchiveUrl,
    this.archiveUrlEnvironmentKey,
    this.layoutNormalization = _RuntimeLayoutNormalization.none,
  });

  final String runtimeId;
  final String runtimeName;
  final String platform;
  final String architecture;
  final String runnerKind;
  final String stackId;
  final String stackName;
  final List<String> requiredExecutableRelativePath;
  final String defaultArchiveFileName;
  final String developmentSourceManifestEnvironmentKey;
  final String releaseSourceManifestEnvironmentKey;
  final String developmentSourceSignatureEnvironmentKey;
  final String releaseSourceSignatureEnvironmentKey;
  final List<_RuntimeStackComponentDefinition> componentDefinitions;
  final String? defaultArchiveUrl;
  final String? archiveUrlEnvironmentKey;
  final _RuntimeLayoutNormalization layoutNormalization;
}

enum _RuntimeLayoutNormalization { none, macosWineBundle }

class RuntimeValidationRecord {
  RuntimeValidationRecord({
    required this.runtimeId,
    required this.isValid,
    required Iterable<RuntimeValidationCheck> checks,
  }) : checks = List.unmodifiable(checks);

  final String runtimeId;
  final bool isValid;
  final List<RuntimeValidationCheck> checks;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'runtimeId': runtimeId,
      'isValid': isValid,
      'checks': checks.map((check) => check.toJson()).toList(growable: false),
    };
  }
}

class RuntimeValidationCheck {
  const RuntimeValidationCheck({
    required this.id,
    required this.name,
    required this.isRequired,
    required this.isPassed,
    required this.message,
  });

  final String id;
  final String name;
  final bool isRequired;
  final bool isPassed;
  final String message;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'isRequired': isRequired,
      'isPassed': isPassed,
      'message': message,
    };
  }
}

sealed class RuntimeValidationResult {
  const RuntimeValidationResult();
}

class RuntimeValidationCompleted extends RuntimeValidationResult {
  const RuntimeValidationCompleted(this.validation);

  final RuntimeValidationRecord validation;
}

class RuntimeValidationFailed extends RuntimeValidationResult {
  const RuntimeValidationFailed(this.message);

  final String message;
}

class RuntimeValidationRuntimeNotFound extends RuntimeValidationResult {
  const RuntimeValidationRuntimeNotFound(this.runtimeId);

  final String runtimeId;
}

abstract interface class RuntimeValidator {
  RuntimeValidationResult validate(String runtimeId);
}

class RuntimeExecutableProbeResult {
  const RuntimeExecutableProbeResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;
}

abstract interface class RuntimeExecutableProbe {
  RuntimeExecutableProbeResult run({
    required String executable,
    required List<String> arguments,
    required Map<String, String> environment,
    required String workingDirectory,
  });
}

class DartIoRuntimeExecutableProbe implements RuntimeExecutableProbe {
  const DartIoRuntimeExecutableProbe();

  @override
  RuntimeExecutableProbeResult run({
    required String executable,
    required List<String> arguments,
    required Map<String, String> environment,
    required String workingDirectory,
  }) {
    try {
      final result = Process.runSync(
        executable,
        arguments,
        environment: environment,
        workingDirectory: workingDirectory,
        runInShell: false,
      );

      return RuntimeExecutableProbeResult(
        exitCode: result.exitCode,
        stdout: _processOutputToString(result.stdout),
        stderr: _processOutputToString(result.stderr),
      );
    } on ProcessException catch (error) {
      return RuntimeExecutableProbeResult(
        exitCode: 127,
        stdout: '',
        stderr: error.message,
      );
    }
  }
}

class DartIoMacosWineRuntimeValidator implements RuntimeValidator {
  const DartIoMacosWineRuntimeValidator({
    required this.runtimeCatalog,
    this.fileStatusProbe = const DartIoFileStatusProbe(),
    this.executableProbe = const DartIoRuntimeExecutableProbe(),
  });

  final RuntimeCatalog runtimeCatalog;
  final FileStatusProbe fileStatusProbe;
  final RuntimeExecutableProbe executableProbe;

  @override
  RuntimeValidationResult validate(String runtimeId) {
    final runtime = _runtimeById(runtimeCatalog.listRuntimes(), runtimeId);
    if (runtime == null) {
      return RuntimeValidationRuntimeNotFound(runtimeId);
    }

    final runtimeRoot = runtime.libraryPath;
    final executablePath = runtime.executablePath;
    if (runtimeRoot == null || executablePath == null) {
      return RuntimeValidationCompleted(
        RuntimeValidationRecord(
          runtimeId: runtime.id,
          isValid: false,
          checks: const [
            RuntimeValidationCheck(
              id: 'runtime-layout',
              name: 'Runtime layout',
              isRequired: true,
              isPassed: false,
              message: 'Runtime record is missing layout paths.',
            ),
          ],
        ),
      );
    }

    final checks = <RuntimeValidationCheck>[
      _runtimePathCheck(
        id: 'runtime-root',
        name: 'Runtime root',
        path: runtimeRoot,
        fileStatusProbe: fileStatusProbe,
      ),
      _runtimePathCheck(
        id: 'wine-executable',
        name: 'Wine executable',
        path: executablePath,
        fileStatusProbe: fileStatusProbe,
      ),
      _runtimeAnyPathCheck(
        id: 'loader-dylibs',
        name: 'Wine loader libraries',
        paths: _macosWineLoaderLibraryPaths(runtimeRoot),
        fileStatusProbe: fileStatusProbe,
      ),
    ];

    if (!checks.every((check) => !check.isRequired || check.isPassed)) {
      return RuntimeValidationCompleted(
        RuntimeValidationRecord(
          runtimeId: runtime.id,
          isValid: false,
          checks: checks,
        ),
      );
    }

    final loaderResult = executableProbe.run(
      executable: executablePath,
      arguments: const ['--version'],
      environment: <String, String>{
        'DYLD_LIBRARY_PATH': _joinPath(runtimeRoot, const ['lib']),
      },
      workingDirectory: _dirname(executablePath),
    );
    final loaderCheck = RuntimeValidationCheck(
      id: 'wine-loader',
      name: 'Wine loader',
      isRequired: true,
      isPassed: loaderResult.exitCode == 0,
      message: loaderResult.exitCode == 0
          ? 'wine64 --version completed.'
          : _runtimeLoaderFailureMessage(loaderResult),
    );
    final completedChecks = <RuntimeValidationCheck>[...checks, loaderCheck];

    return RuntimeValidationCompleted(
      RuntimeValidationRecord(
        runtimeId: runtime.id,
        isValid: completedChecks.every(
          (check) => !check.isRequired || check.isPassed,
        ),
        checks: completedChecks,
      ),
    );
  }
}

class MacosSetupStatus {
  const MacosSetupStatus({
    required this.isSupported,
    required this.rosetta,
    required this.runtime,
  });

  final bool isSupported;
  final RosettaSetupStatus rosetta;
  final RuntimeSetupStatus runtime;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'isSupported': isSupported,
      'rosetta': rosetta.toJson(),
      'runtime': runtime.toJson(),
    };
  }
}

class RosettaSetupStatus {
  const RosettaSetupStatus({
    required this.isRequired,
    required this.isInstalled,
    required this.installCommand,
  });

  final bool isRequired;
  final bool isInstalled;
  final List<String> installCommand;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'isRequired': isRequired,
      'isInstalled': isInstalled,
      'installCommand': installCommand,
    };
  }
}

class RuntimeSetupStatus {
  const RuntimeSetupStatus({
    required this.runtimeId,
    required this.isInstalled,
  });

  final String runtimeId;
  final bool isInstalled;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'runtimeId': runtimeId,
      'isInstalled': isInstalled,
    };
  }
}

sealed class MacosSetupCheckResult {
  const MacosSetupCheckResult();
}

class MacosSetupCheckCompleted extends MacosSetupCheckResult {
  const MacosSetupCheckCompleted(this.status);

  final MacosSetupStatus status;
}

class MacosSetupCheckFailed extends MacosSetupCheckResult {
  const MacosSetupCheckFailed(this.message);

  final String message;
}

abstract interface class MacosSetupChecker {
  MacosSetupCheckResult check();
}

class DartIoMacosSetupChecker implements MacosSetupChecker {
  const DartIoMacosSetupChecker({
    required this.hostPlatform,
    required this.runtimeCatalog,
    this.fileStatusProbe = const DartIoFileStatusProbe(),
  });

  factory DartIoMacosSetupChecker.current(RuntimeCatalog runtimeCatalog) {
    return DartIoMacosSetupChecker(
      hostPlatform: _currentHostPlatform(),
      runtimeCatalog: runtimeCatalog,
    );
  }

  final KonyakHostPlatform hostPlatform;
  final RuntimeCatalog runtimeCatalog;
  final FileStatusProbe fileStatusProbe;

  @override
  MacosSetupCheckResult check() {
    final runtime = _runtimeById(
      runtimeCatalog.listRuntimes(),
      macosWineRuntimeId,
    );

    return MacosSetupCheckCompleted(
      MacosSetupStatus(
        isSupported: hostPlatform == KonyakHostPlatform.macos,
        rosetta: RosettaSetupStatus(
          isRequired: hostPlatform == KonyakHostPlatform.macos,
          isInstalled: fileStatusProbe.exists(_rosettaRuntimePath),
          installCommand: _rosettaInstallCommand,
        ),
        runtime: RuntimeSetupStatus(
          runtimeId: macosWineRuntimeId,
          isInstalled: runtime?.isInstalled == true,
        ),
      ),
    );
  }
}

CliResult runCli(
  List<String> arguments, {
  BottleCatalog bottleCatalog = const StaticBottleCatalog(<BottleRecord>[]),
  BottleRepository? bottleRepository,
  BottleProgramRepository bottleProgramRepository =
      const DartIoBottleProgramRepository(),
  ProgramMetadataExtractor programMetadataExtractor =
      const DartIoProgramMetadataExtractor(),
  WinetricksVerbRepository? winetricksVerbRepository,
  WinetricksScriptInstaller winetricksScriptInstaller =
      const DartIoWinetricksScriptInstaller(),
  RuntimeCatalog runtimeCatalog = const StaticRuntimeCatalog(<RuntimeRecord>[]),
  ProgramRunPlanner? programRunPlanner,
  ProgramRunner? programRunner,
  BottlePrefixInitializer? bottlePrefixInitializer,
  PathOpener? pathOpener,
  MacosWineInstaller? macosWineInstaller,
  LinuxWineInstaller? linuxWineInstaller,
  GptkWineInstaller? gptkWineInstaller,
  RuntimeUpdateChecker? runtimeUpdateChecker,
  AppUpdateChecker? appUpdateChecker,
  AppUpdateInstaller? appUpdateInstaller,
  RuntimeValidator? runtimeValidator,
  MacosSetupChecker? macosSetupChecker,
  AppSettingsRepository? appSettingsRepository,
  RuntimeInstallProgressSink? runtimeInstallProgressSink,
}) {
  try {
    return _runCli(
      arguments,
      bottleCatalog: bottleCatalog,
      bottleRepository: bottleRepository,
      bottleProgramRepository: bottleProgramRepository,
      programMetadataExtractor: programMetadataExtractor,
      winetricksVerbRepository:
          winetricksVerbRepository ?? DartIoWinetricksVerbRepository.current(),
      winetricksScriptInstaller: winetricksScriptInstaller,
      runtimeCatalog: runtimeCatalog,
      programRunPlanner: programRunPlanner ?? ProgramRunPlanner.current(),
      programRunner: programRunner,
      bottlePrefixInitializer: bottlePrefixInitializer,
      pathOpener: pathOpener,
      macosWineInstaller: macosWineInstaller,
      linuxWineInstaller: linuxWineInstaller,
      gptkWineInstaller: gptkWineInstaller,
      runtimeUpdateChecker: runtimeUpdateChecker,
      appUpdateChecker: appUpdateChecker,
      appUpdateInstaller: appUpdateInstaller,
      runtimeValidator: runtimeValidator,
      macosSetupChecker: macosSetupChecker,
      appSettingsRepository: appSettingsRepository,
      runtimeInstallProgressSink: runtimeInstallProgressSink,
    );
  } on BottleRepositoryException catch (error) {
    return _jsonError(
      exitCode: 74,
      code: 'bottleRepositoryError',
      message: error.message,
    );
  } on AppSettingsRepositoryException catch (error) {
    return _jsonError(
      exitCode: 74,
      code: 'appSettingsRepositoryError',
      message: error.message,
    );
  }
}

Future<CliResult> runCliStreaming(
  List<String> arguments, {
  BottleCatalog bottleCatalog = const StaticBottleCatalog(<BottleRecord>[]),
  BottleRepository? bottleRepository,
  BottleProgramRepository bottleProgramRepository =
      const DartIoBottleProgramRepository(),
  ProgramMetadataExtractor programMetadataExtractor =
      const DartIoProgramMetadataExtractor(),
  WinetricksVerbRepository? winetricksVerbRepository,
  WinetricksScriptInstaller winetricksScriptInstaller =
      const DartIoWinetricksScriptInstaller(),
  RuntimeCatalog runtimeCatalog = const StaticRuntimeCatalog(<RuntimeRecord>[]),
  ProgramRunPlanner? programRunPlanner,
  ProgramRunner? programRunner,
  BottlePrefixInitializer? bottlePrefixInitializer,
  PathOpener? pathOpener,
  MacosWineInstaller? macosWineInstaller,
  LinuxWineInstaller? linuxWineInstaller,
  GptkWineInstaller? gptkWineInstaller,
  RuntimeUpdateChecker? runtimeUpdateChecker,
  AppUpdateChecker? appUpdateChecker,
  AppUpdateInstaller? appUpdateInstaller,
  RuntimeValidator? runtimeValidator,
  MacosSetupChecker? macosSetupChecker,
  AppSettingsRepository? appSettingsRepository,
  RuntimeInstallProgressSink? runtimeInstallProgressSink,
}) async {
  final macosWineInstallRequest = _parseJsonMacosWineInstallRequest(arguments);
  if (macosWineInstallRequest?.emitProgress == true &&
      macosWineInstaller is DartIoMacosWineInstaller) {
    final installResult = await macosWineInstaller.installStreaming(
      macosWineInstallRequest!,
      progressSink: runtimeInstallProgressSink,
    );
    return _macosWineInstallCliResult(installResult);
  }

  final linuxWineInstallRequest = _parseJsonLinuxWineInstallRequest(arguments);
  if (linuxWineInstallRequest?.emitProgress == true &&
      linuxWineInstaller is DartIoLinuxWineInstaller) {
    final installResult = await linuxWineInstaller.installStreaming(
      linuxWineInstallRequest!,
      progressSink: runtimeInstallProgressSink,
    );
    return _linuxWineInstallCliResult(installResult);
  }

  return runCli(
    arguments,
    bottleCatalog: bottleCatalog,
    bottleRepository: bottleRepository,
    bottleProgramRepository: bottleProgramRepository,
    programMetadataExtractor: programMetadataExtractor,
    winetricksVerbRepository: winetricksVerbRepository,
    winetricksScriptInstaller: winetricksScriptInstaller,
    runtimeCatalog: runtimeCatalog,
    programRunPlanner: programRunPlanner,
    programRunner: programRunner,
    bottlePrefixInitializer: bottlePrefixInitializer,
    pathOpener: pathOpener,
    macosWineInstaller: macosWineInstaller,
    linuxWineInstaller: linuxWineInstaller,
    gptkWineInstaller: gptkWineInstaller,
    runtimeUpdateChecker: runtimeUpdateChecker,
    appUpdateChecker: appUpdateChecker,
    appUpdateInstaller: appUpdateInstaller,
    runtimeValidator: runtimeValidator,
    macosSetupChecker: macosSetupChecker,
    appSettingsRepository: appSettingsRepository,
    runtimeInstallProgressSink: runtimeInstallProgressSink,
  );
}

CliResult _programUpdateJsonResult(ProgramUpdateResult result) {
  return switch (result) {
    ProgramUpdated(:final bottle) => CliResult(
      exitCode: 0,
      stdout: jsonEncode(<String, Object?>{
        'schemaVersion': cliSchemaVersion,
        'bottle': bottle.toJson(),
      }),
      stderr: '',
    ),
    ProgramUpdateMissingBottle(:final bottleId) => _bottleNotFoundError(
      bottleId,
    ),
    ProgramUpdateMissingProgram(:final programPath) => _jsonError(
      exitCode: 66,
      code: 'programNotPinned',
      message: 'Program is not pinned.',
      extra: <String, Object?>{'programPath': programPath},
    ),
  };
}

CliResult _runPinnedProgramLauncherCli({
  required _PinnedProgramLaunchCliRequest request,
  required BottleRepository? bottleRepository,
  required ProgramRunPlanner programRunPlanner,
  required ProgramRunner? programRunner,
}) {
  final launcherManifest = _readPinnedProgramLauncherManifest(
    request.manifestPath,
  );
  if (launcherManifest == null) {
    return _jsonError(
      exitCode: 65,
      code: 'invalidPinnedProgramLauncher',
      message: 'Pinned program launcher manifest is invalid.',
      extra: <String, Object?>{'manifestPath': request.manifestPath},
    );
  }

  if (bottleRepository == null) {
    return _jsonError(
      exitCode: 74,
      code: 'bottleRepositoryUnavailable',
      message: 'Bottle repository is not configured.',
    );
  }

  if (programRunner == null) {
    return _jsonError(
      exitCode: 74,
      code: 'programRunnerUnavailable',
      message: 'Program runner is not configured.',
    );
  }

  final bottle = bottleRepository.findBottle(launcherManifest.bottleId);
  if (bottle == null) {
    return _bottleNotFoundError(launcherManifest.bottleId);
  }

  final expectedLauncherId = _pinnedProgramLauncherId(
    bottleId: launcherManifest.bottleId,
    programPath: launcherManifest.programPath,
  );
  if (launcherManifest.launcherId != expectedLauncherId ||
      !_hasPinnedProgram(bottle, launcherManifest.programPath)) {
    return _jsonError(
      exitCode: 66,
      code: 'programNotPinned',
      message: 'Program is not pinned.',
      extra: <String, Object?>{'programPath': launcherManifest.programPath},
    );
  }

  final settingsResult = bottleRepository.readProgramSettings(
    ProgramSettingsRequest(
      bottleId: bottle.id,
      programPath: launcherManifest.programPath,
    ),
  );
  final programSettings = switch (settingsResult) {
    ProgramSettingsRead(:final settings) => settings,
    ProgramSettingsReadMissingBottle() => const ProgramSettingsRecord(),
  };
  final programRunRequest = programRunPlanner.plan(
    bottle: bottle,
    programPath: launcherManifest.programPath,
    programSettings: programSettings,
  );
  if (programRunRequest == null) {
    return _jsonError(
      exitCode: 65,
      code: 'unsupportedProgramType',
      message: 'Program type is not supported.',
      extra: <String, Object?>{'programPath': launcherManifest.programPath},
    );
  }

  final runResult = programRunner.run(programRunRequest);

  return switch (runResult) {
    ProgramRunCompleted(:final processExitCode) => _programRunJsonResult(
      request: programRunRequest,
      processExitCode: processExitCode,
    ),
    ProgramRunFailed(:final message) => _programRunFailedJsonResult(
      request: programRunRequest,
      message: message,
    ),
  };
}

CliResult _bottleArchiveExportJsonResult(BottleArchiveExportResult result) {
  return switch (result) {
    BottleArchiveExported(:final archive) => CliResult(
      exitCode: 0,
      stdout: jsonEncode(<String, Object?>{
        'schemaVersion': cliSchemaVersion,
        'bottleArchive': archive.toJson(),
      }),
      stderr: '',
    ),
    BottleArchiveExportMissing(:final bottleId) => _bottleNotFoundError(
      bottleId,
    ),
    BottleArchiveExportFailed(:final message) => _jsonError(
      exitCode: 75,
      code: 'bottleArchiveExportFailed',
      message: message,
    ),
  };
}

CliResult _bottleArchiveImportJsonResult(BottleArchiveImportResult result) {
  return switch (result) {
    BottleArchiveImported(:final bottle) => CliResult(
      exitCode: 0,
      stdout: jsonEncode(<String, Object?>{
        'schemaVersion': cliSchemaVersion,
        'bottle': bottle.toJson(),
      }),
      stderr: '',
    ),
    BottleArchiveImportConflict(:final bottleId) => _jsonError(
      exitCode: 73,
      code: 'bottleAlreadyExists',
      message: 'Bottle already exists.',
      extra: <String, Object?>{'bottleId': bottleId},
    ),
    BottleArchiveImportFailed(:final message) => _jsonError(
      exitCode: 65,
      code: 'invalidBottleArchive',
      message: message,
    ),
  };
}

CliResult _appSettingsJsonResult(AppSettingsRecord settings) {
  return CliResult(
    exitCode: 0,
    stdout: jsonEncode(<String, Object?>{
      'schemaVersion': cliSchemaVersion,
      'appSettings': settings.toJson(),
    }),
    stderr: '',
  );
}

CliResult _appUpdateJsonResult(AppUpdateRecord update) {
  return CliResult(
    exitCode: 0,
    stdout: jsonEncode(<String, Object?>{
      'schemaVersion': cliSchemaVersion,
      'appUpdate': update.toJson(),
    }),
    stderr: '',
  );
}

CliResult _appUpdateInstallJsonResult(AppUpdateInstallRecord install) {
  return CliResult(
    exitCode: 0,
    stdout: jsonEncode(<String, Object?>{
      'schemaVersion': cliSchemaVersion,
      'appUpdateInstall': install.toJson(),
    }),
    stderr: '',
  );
}

CliResult _wineProcessTerminationJsonResult(
  List<WineProcessTerminationRecord> records, {
  String recordsKey = 'bottles',
}) {
  final hasFailures = records.any((record) => record.status != 'terminated');
  return CliResult(
    exitCode: hasFailures ? 75 : 0,
    stdout: jsonEncode(<String, Object?>{
      'schemaVersion': cliSchemaVersion,
      'wineProcessTermination': <String, Object?>{
        'hasFailures': hasFailures,
        recordsKey: records
            .map((record) => record.toJson())
            .toList(growable: false),
      },
    }),
    stderr: '',
  );
}

CliResult _wineProcessListJsonResult(List<WineProcessRecord> records) {
  return CliResult(
    exitCode: 0,
    stdout: jsonEncode(<String, Object?>{
      'schemaVersion': cliSchemaVersion,
      'wineProcesses': <String, Object?>{
        'processes': records
            .map((record) => record.toJson())
            .toList(growable: false),
      },
    }),
    stderr: '',
  );
}

CliResult _programSettingsReadJsonResult({
  required ProgramSettingsRequest request,
  required ProgramSettingsReadResult result,
}) {
  return switch (result) {
    ProgramSettingsRead(:final settings) => _programSettingsJsonResult(
      bottleId: request.bottleId,
      programPath: request.programPath,
      settings: settings,
    ),
    ProgramSettingsReadMissingBottle(:final bottleId) => _bottleNotFoundError(
      bottleId,
    ),
  };
}

CliResult _programSettingsUpdateJsonResult({
  required ProgramSettingsUpdateRequest request,
  required ProgramSettingsUpdateResult result,
}) {
  return switch (result) {
    ProgramSettingsUpdated(:final settings) => _programSettingsJsonResult(
      bottleId: request.bottleId,
      programPath: request.programPath,
      settings: settings,
    ),
    ProgramSettingsUpdateMissingBottle(:final bottleId) => _bottleNotFoundError(
      bottleId,
    ),
  };
}

CliResult _programSettingsJsonResult({
  required String bottleId,
  required String programPath,
  required ProgramSettingsRecord settings,
}) {
  return CliResult(
    exitCode: 0,
    stdout: jsonEncode(<String, Object?>{
      'schemaVersion': cliSchemaVersion,
      'programSettings': <String, Object?>{
        'bottleId': bottleId,
        'programPath': programPath,
        'settings': settings.toJson(),
      },
    }),
    stderr: '',
  );
}

CliResult? _applyRuntimeSettingsRegistryUpdates({
  required BottleRecord bottle,
  required BottleRuntimeSettings runtimeSettings,
  required ProgramRunPlanner programRunPlanner,
  required ProgramRunner? programRunner,
}) {
  return _applyRegistryUpdateRequests(
    requests: programRunPlanner.planRuntimeSettingsRegistryUpdates(
      bottle: bottle,
      currentRuntimeSettings: bottle.runtimeSettings,
      runtimeSettings: runtimeSettings,
    ),
    programRunner: programRunner,
  );
}

CliResult? _syncRuntimeSettingsDllOverrides({
  required BottleRecord bottle,
  required BottleRuntimeSettings runtimeSettings,
  required ProgramRunPlanner programRunPlanner,
}) {
  if (programRunPlanner.hostPlatform != KonyakHostPlatform.macos ||
      !runtimeSettings.dxvk) {
    return null;
  }

  try {
    _syncMacosDxvkDllOverrides(
      bottle: bottle,
      environment: programRunPlanner.environment,
    );
    return null;
  } on FileSystemException catch (error) {
    return _jsonError(
      exitCode: 74,
      code: 'runtimeSettingsDllSyncFailed',
      message: 'Failed to synchronize runtime DLL overrides.',
      extra: <String, Object?>{
        'details': <String, Object?>{
          if (error.path != null) 'path': error.path,
          'osError': error.osError?.message ?? error.message,
        },
      },
    );
  }
}

CliResult? _applyWindowsVersionRegistryUpdates({
  required BottleRecord bottle,
  required String windowsVersion,
  required ProgramRunPlanner programRunPlanner,
  required ProgramRunner? programRunner,
}) {
  return _applyRegistryUpdateRequests(
    requests: programRunPlanner.planWindowsVersionRegistryUpdates(
      bottle: bottle,
      windowsVersion: windowsVersion,
    ),
    programRunner: programRunner,
  );
}

CliResult? _applyRegistryUpdateRequests({
  required Iterable<ProgramRunRequest> requests,
  required ProgramRunner? programRunner,
}) {
  final runner = programRunner;
  if (runner == null) {
    return null;
  }

  for (final request in requests) {
    final result = runner.run(request);
    switch (result) {
      case ProgramRunCompleted(:final processExitCode)
          when processExitCode == 0:
        continue;
      case ProgramRunCompleted(:final processExitCode):
        return _jsonError(
          exitCode: 75,
          code: 'registryUpdateFailed',
          message:
              'Registry update `${request.arguments.join(' ')}` exited with '
              'code $processExitCode.',
          extra: <String, Object?>{'processExitCode': processExitCode},
        );
      case ProgramRunFailed(:final message):
        return _jsonError(
          exitCode: 75,
          code: 'registryUpdateFailed',
          message: message,
        );
    }
  }

  return null;
}

BottleRecord _bottleWithRegistrySettings({
  required BottleRecord bottle,
  required ProgramRunPlanner programRunPlanner,
  required ProgramRunner? programRunner,
}) {
  final runner = programRunner;
  if (runner == null) {
    return bottle;
  }

  var currentBottle = bottle;
  for (final request in programRunPlanner.planBottleSettingsRegistryQueries(
    bottle: bottle,
  )) {
    final result = runner.run(request);
    switch (result) {
      case ProgramRunCompleted(:final processExitCode, :final stdout)
          when processExitCode == 0:
        currentBottle = _bottleWithRegistryValue(
          bottle: currentBottle,
          arguments: request.arguments,
          stdout: stdout,
        );
      case ProgramRunCompleted():
        continue;
      case ProgramRunFailed():
        continue;
    }
  }

  return currentBottle;
}

CliResult _terminateWineProcessesJsonResult({
  required BottleCatalog bottleCatalog,
  required ProgramRunPlanner programRunPlanner,
  required ProgramRunner? programRunner,
  String? bottleId,
}) {
  final runner = programRunner;
  if (runner == null) {
    return _jsonError(
      exitCode: 74,
      code: 'programRunnerUnavailable',
      message: 'Program runner is not configured.',
    );
  }

  final records = <WineProcessTerminationRecord>[];
  final bottles = bottleCatalog.listBottles();
  final targetBottles = bottleId == null
      ? bottles
      : <BottleRecord>[?_findBottle(bottles, bottleId)];
  if (bottleId != null && targetBottles.isEmpty) {
    return _bottleNotFoundError(bottleId);
  }

  for (final bottle in targetBottles) {
    final request = programRunPlanner.planWineProcessTermination(
      bottle: bottle,
    );
    final result = runner.run(request);
    switch (result) {
      case ProgramRunCompleted(:final processExitCode):
        records.add(
          WineProcessTerminationRecord(
            bottleId: bottle.id,
            status: _isSuccessfulWineServerTerminationExit(processExitCode)
                ? 'terminated'
                : 'failed',
            runnerKind: request.runnerKind,
            executable: request.executable,
            argv: request.argv,
            processExitCode: processExitCode,
          ),
        );
      case ProgramRunFailed(:final message):
        records.add(
          WineProcessTerminationRecord(
            bottleId: bottle.id,
            status: 'failed',
            runnerKind: request.runnerKind,
            executable: request.executable,
            argv: request.argv,
            message: message,
          ),
        );
    }
  }

  return _wineProcessTerminationJsonResult(records);
}

bool _isSuccessfulWineServerTerminationExit(int processExitCode) {
  return processExitCode == 0 || processExitCode == 1;
}

CliResult _listWineProcessesJsonResult({
  required BottleCatalog bottleCatalog,
  required ProgramRunPlanner programRunPlanner,
  required ProgramRunner? programRunner,
  required ProgramMetadataExtractor programMetadataExtractor,
}) {
  final runner = programRunner;
  if (runner == null) {
    return _jsonError(
      exitCode: 74,
      code: 'programRunnerUnavailable',
      message: 'Program runner is not configured.',
    );
  }

  final records = <WineProcessRecord>[];
  for (final bottle in bottleCatalog.listBottles()) {
    final request = programRunPlanner.planWineProcessList(bottle: bottle);
    final result = runner.run(request);
    switch (result) {
      case ProgramRunCompleted(:final processExitCode, :final stdout)
          when processExitCode == 0:
        records.addAll(
          _parseWinedbgProcessList(stdout)
              .where((process) {
                return !_isWineInfrastructureProcess(process);
              })
              .map((process) {
                final hostPath = _wineProcessHostPath(
                  bottle: bottle,
                  executable: process.executable,
                );
                final metadata = hostPath == null
                    ? null
                    : programMetadataExtractor.extract(
                        bottle: bottle,
                        programPath: hostPath,
                      );
                return WineProcessRecord(
                  bottleId: bottle.id,
                  processId: process.processId,
                  executable: process.executable,
                  hostPath: hostPath,
                  metadata: metadata,
                );
              }),
        );
      case ProgramRunCompleted(:final processExitCode, :final stderr):
        return _jsonError(
          exitCode: 75,
          code: 'wineProcessListFailed',
          message:
              'Wine process list for `${bottle.id}` exited with code '
              '$processExitCode.',
          extra: <String, Object?>{'diagnostic': stderr},
        );
      case ProgramRunFailed(:final message):
        return _jsonError(
          exitCode: 75,
          code: 'wineProcessListFailed',
          message: message,
        );
    }
  }

  return _wineProcessListJsonResult(records);
}

CliResult _terminateWineProcessJsonResult({
  required BottleCatalog bottleCatalog,
  required ProgramRunPlanner programRunPlanner,
  required ProgramRunner? programRunner,
  required String bottleId,
  required String processId,
}) {
  final runner = programRunner;
  if (runner == null) {
    return _jsonError(
      exitCode: 74,
      code: 'programRunnerUnavailable',
      message: 'Program runner is not configured.',
    );
  }

  final bottle = _findBottle(bottleCatalog.listBottles(), bottleId);
  if (bottle == null) {
    return _bottleNotFoundError(bottleId);
  }

  final request = programRunPlanner.planWineProcessKill(
    bottle: bottle,
    processId: processId,
  );
  final result = runner.run(request);
  final record = switch (result) {
    ProgramRunCompleted(:final processExitCode) => WineProcessTerminationRecord(
      bottleId: bottle.id,
      processId: processId,
      status: processExitCode == 0 ? 'terminated' : 'failed',
      runnerKind: request.runnerKind,
      executable: request.executable,
      argv: request.argv,
      processExitCode: processExitCode,
    ),
    ProgramRunFailed(:final message) => WineProcessTerminationRecord(
      bottleId: bottle.id,
      processId: processId,
      status: 'failed',
      runnerKind: request.runnerKind,
      executable: request.executable,
      argv: request.argv,
      message: message,
    ),
  };

  return _wineProcessTerminationJsonResult(<WineProcessTerminationRecord>[
    record,
  ], recordsKey: 'processes');
}

CliResult _installAppUpdateJsonResult({
  required AppUpdateChecker? appUpdateChecker,
  required AppUpdateInstaller? appUpdateInstaller,
}) {
  final checker = appUpdateChecker;
  if (checker == null) {
    return _jsonError(
      exitCode: 74,
      code: 'appUpdateCheckerUnavailable',
      message: 'App update checker is not configured.',
    );
  }

  final installer = appUpdateInstaller;
  if (installer == null) {
    return _jsonError(
      exitCode: 74,
      code: 'appUpdateInstallerUnavailable',
      message: 'App update installer is not configured.',
    );
  }

  final updateResult = checker.check();
  return switch (updateResult) {
    AppUpdateCheckCompleted(:final update) when update.status != 'available' =>
      _appUpdateInstallJsonResult(
        AppUpdateInstallRecord(
          appId: update.appId,
          status: update.status,
          currentVersion: update.currentVersion,
          installedVersion: update.currentVersion,
          archiveUrl: update.archiveUrl,
        ),
      ),
    AppUpdateCheckCompleted(:final update) => switch (installer.install(
      update,
    )) {
      AppUpdateInstallCompleted(:final install) => _appUpdateInstallJsonResult(
        install,
      ),
      AppUpdateInstallFailed(:final message) => _jsonError(
        exitCode: 75,
        code: 'appUpdateInstallFailed',
        message: message,
      ),
    },
    AppUpdateCheckFailed(:final message) => _jsonError(
      exitCode: 75,
      code: 'appUpdateCheckFailed',
      message: message,
    ),
  };
}

CliResult _installRuntimeUpdateJsonResult({
  required String runtimeId,
  required RuntimeUpdateChecker? runtimeUpdateChecker,
  required MacosWineInstaller? macosWineInstaller,
  required LinuxWineInstaller? linuxWineInstaller,
}) {
  final checker = runtimeUpdateChecker;
  if (checker == null) {
    return _jsonError(
      exitCode: 74,
      code: 'runtimeUpdateCheckerUnavailable',
      message: 'Runtime update checker is not configured.',
    );
  }

  final updateResult = checker.check(runtimeId);
  return switch (updateResult) {
    RuntimeUpdateCheckCompleted(:final update)
        when update.status != 'available' =>
      _jsonError(
        exitCode: 65,
        code: 'runtimeUpdateNotAvailable',
        message: 'Runtime update is not available.',
        extra: <String, Object?>{'runtimeId': runtimeId},
      ),
    RuntimeUpdateCheckCompleted(:final update) => switch (runtimeId) {
      macosWineRuntimeId => switch (macosWineInstaller) {
        null => _jsonError(
          exitCode: 74,
          code: 'macosWineInstallerUnavailable',
          message: 'macOS Wine installer is not configured.',
        ),
        final installer => switch (installer.install(
          _macosWineInstallRequestForRuntimeUpdate(update),
        )) {
          MacosWineInstallCompleted(:final runtime) => CliResult(
            exitCode: 0,
            stdout: jsonEncode(<String, Object?>{
              'schemaVersion': cliSchemaVersion,
              'runtime': runtime.toJson(),
            }),
            stderr: '',
          ),
          MacosWineInstallFailed(:final message) => _jsonError(
            exitCode: 75,
            code: 'macosWineInstallFailed',
            message: message,
          ),
        },
      },
      linuxWineRuntimeId => switch (linuxWineInstaller) {
        null => _jsonError(
          exitCode: 74,
          code: 'linuxWineInstallerUnavailable',
          message: 'Linux Wine installer is not configured.',
        ),
        final installer => switch (installer.install(
          _linuxWineInstallRequestForRuntimeUpdate(update),
        )) {
          LinuxWineInstallCompleted(:final runtime) => CliResult(
            exitCode: 0,
            stdout: jsonEncode(<String, Object?>{
              'schemaVersion': cliSchemaVersion,
              'runtime': runtime.toJson(),
            }),
            stderr: '',
          ),
          LinuxWineInstallFailed(:final message) => _jsonError(
            exitCode: 75,
            code: 'linuxWineInstallFailed',
            message: message,
          ),
        },
      },
      _ => _jsonError(
        exitCode: 65,
        code: 'unsupportedRuntimeUpdateInstall',
        message: 'Runtime update installation is not supported.',
        extra: <String, Object?>{'runtimeId': runtimeId},
      ),
    },
    RuntimeUpdateRuntimeNotFound(:final runtimeId) => _jsonError(
      exitCode: 66,
      code: 'runtimeNotFound',
      message: 'Runtime not found.',
      extra: <String, Object?>{'runtimeId': runtimeId},
    ),
    RuntimeUpdateCheckFailed(:final message) => _jsonError(
      exitCode: 75,
      code: 'runtimeUpdateCheckFailed',
      message: message,
    ),
  };
}

CliResult _macosWineInstallCliResult(MacosWineInstallResult installResult) {
  return switch (installResult) {
    MacosWineInstallCompleted(:final runtime) => CliResult(
      exitCode: 0,
      stdout: jsonEncode(<String, Object?>{
        'schemaVersion': cliSchemaVersion,
        'runtime': runtime.toJson(),
      }),
      stderr: '',
    ),
    MacosWineInstallFailed(:final message) => _jsonError(
      exitCode: 75,
      code: 'macosWineInstallFailed',
      message: message,
    ),
  };
}

CliResult _linuxWineInstallCliResult(LinuxWineInstallResult installResult) {
  return switch (installResult) {
    LinuxWineInstallCompleted(:final runtime) => CliResult(
      exitCode: 0,
      stdout: jsonEncode(<String, Object?>{
        'schemaVersion': cliSchemaVersion,
        'runtime': runtime.toJson(),
      }),
      stderr: '',
    ),
    LinuxWineInstallFailed(:final message) => _jsonError(
      exitCode: 75,
      code: 'linuxWineInstallFailed',
      message: message,
    ),
  };
}

MacosWineInstallRequest _macosWineInstallRequestForRuntimeUpdate(
  RuntimeUpdateRecord update,
) {
  final archiveUrl = update.archiveUrl;
  final sourceManifestUrl = update.sourceManifestUrl;
  if (sourceManifestUrl != null && sourceManifestUrl.trim().isNotEmpty) {
    return MacosWineInstallRequest.updateInstall(
      sourceManifest: sourceManifestUrl,
      sourceManifestSignature: update.sourceManifestSignatureUrl,
    );
  }
  if (archiveUrl != null && _isRuntimeStackSourceManifestSource(archiveUrl)) {
    return MacosWineInstallRequest.updateInstall(sourceManifest: archiveUrl);
  }

  return MacosWineInstallRequest.updateInstall(archiveUrl: archiveUrl);
}

LinuxWineInstallRequest _linuxWineInstallRequestForRuntimeUpdate(
  RuntimeUpdateRecord update,
) {
  final archiveUrl = update.archiveUrl;
  final sourceManifestUrl = update.sourceManifestUrl;
  if (sourceManifestUrl != null && sourceManifestUrl.trim().isNotEmpty) {
    return LinuxWineInstallRequest.updateInstall(
      sourceManifest: sourceManifestUrl,
      sourceManifestSignature: update.sourceManifestSignatureUrl,
    );
  }
  if (archiveUrl != null && _isRuntimeStackSourceManifestSource(archiveUrl)) {
    return LinuxWineInstallRequest.updateInstall(sourceManifest: archiveUrl);
  }

  return LinuxWineInstallRequest.updateInstall(archiveUrl: archiveUrl);
}

bool _isRuntimeStackSourceManifestSource(String source) {
  final normalized = source.trim().toLowerCase();
  return normalized.endsWith('.json') || normalized.contains('manifest');
}

CliResult _runCli(
  List<String> arguments, {
  required BottleCatalog bottleCatalog,
  required BottleRepository? bottleRepository,
  required BottleProgramRepository bottleProgramRepository,
  required ProgramMetadataExtractor programMetadataExtractor,
  required WinetricksVerbRepository winetricksVerbRepository,
  required WinetricksScriptInstaller winetricksScriptInstaller,
  required RuntimeCatalog runtimeCatalog,
  required ProgramRunPlanner programRunPlanner,
  required ProgramRunner? programRunner,
  required BottlePrefixInitializer? bottlePrefixInitializer,
  required PathOpener? pathOpener,
  required MacosWineInstaller? macosWineInstaller,
  required LinuxWineInstaller? linuxWineInstaller,
  required GptkWineInstaller? gptkWineInstaller,
  required RuntimeUpdateChecker? runtimeUpdateChecker,
  required AppUpdateChecker? appUpdateChecker,
  required AppUpdateInstaller? appUpdateInstaller,
  required RuntimeValidator? runtimeValidator,
  required MacosSetupChecker? macosSetupChecker,
  required AppSettingsRepository? appSettingsRepository,
  required RuntimeInstallProgressSink? runtimeInstallProgressSink,
}) {
  final activeBottleCatalog = bottleRepository ?? bottleCatalog;

  if (_isJsonAppUpdateCheckCommand(arguments)) {
    final checker = appUpdateChecker;
    if (checker == null) {
      return _jsonError(
        exitCode: 74,
        code: 'appUpdateCheckerUnavailable',
        message: 'App update checker is not configured.',
      );
    }

    final updateResult = checker.check();
    return switch (updateResult) {
      AppUpdateCheckCompleted(:final update) => _appUpdateJsonResult(update),
      AppUpdateCheckFailed(:final message) => _jsonError(
        exitCode: 75,
        code: 'appUpdateCheckFailed',
        message: message,
      ),
    };
  }

  if (_isJsonAppSettingsGetCommand(arguments)) {
    final repository = appSettingsRepository;
    if (repository == null) {
      return _jsonError(
        exitCode: 74,
        code: 'appSettingsRepositoryUnavailable',
        message: 'App settings repository is not configured.',
      );
    }

    return _appSettingsJsonResult(repository.read());
  }

  final appSettingsUpdate = _parseJsonAppSettingsUpdateRequest(arguments);
  if (appSettingsUpdate != null) {
    final repository = appSettingsRepository;
    if (repository == null) {
      return _jsonError(
        exitCode: 74,
        code: 'appSettingsRepositoryUnavailable',
        message: 'App settings repository is not configured.',
      );
    }

    return _appSettingsJsonResult(repository.write(appSettingsUpdate));
  }

  if (_isJsonLinuxFileAssociationInstallCommand(arguments)) {
    final result = _installLinuxFileAssociations(
      hostPlatform: programRunPlanner.hostPlatform,
      environment: programRunPlanner.environment,
    );
    return switch (result) {
      _LinuxFileAssociationsInstalled(
        :final desktopEntryPath,
        :final mimeAppsPath,
      ) =>
        CliResult(
          exitCode: 0,
          stdout: jsonEncode(<String, Object?>{
            'schemaVersion': cliSchemaVersion,
            'linuxFileAssociations': <String, Object?>{
              'desktopEntryPath': desktopEntryPath,
              'mimeAppsPath': mimeAppsPath,
              'mimeTypes': _linuxExecutableMimeTypes,
            },
          }),
          stderr: '',
        ),
      _LinuxFileAssociationInstallFailed(:final message) => _jsonError(
        exitCode: 75,
        code: 'linuxFileAssociationInstallFailed',
        message: message,
      ),
    };
  }

  if (_isJsonWineProcessListCommand(arguments)) {
    return _listWineProcessesJsonResult(
      bottleCatalog: activeBottleCatalog,
      programRunPlanner: programRunPlanner,
      programRunner: programRunner,
      programMetadataExtractor: programMetadataExtractor,
    );
  }

  final wineProcessTerminationRequest = _parseJsonWineProcessTerminationRequest(
    arguments,
  );
  if (wineProcessTerminationRequest != null) {
    return _terminateWineProcessJsonResult(
      bottleCatalog: activeBottleCatalog,
      programRunPlanner: programRunPlanner,
      programRunner: programRunner,
      bottleId: wineProcessTerminationRequest.bottleId,
      processId: wineProcessTerminationRequest.processId,
    );
  }

  final wineProcessGroupTerminationRequest =
      _parseJsonWineProcessGroupTerminationRequest(arguments);
  if (wineProcessGroupTerminationRequest != null) {
    return _terminateWineProcessesJsonResult(
      bottleCatalog: activeBottleCatalog,
      programRunPlanner: programRunPlanner,
      programRunner: programRunner,
      bottleId: wineProcessGroupTerminationRequest.bottleId,
    );
  }

  if (_isJsonAppUpdateInstallCommand(arguments)) {
    return _installAppUpdateJsonResult(
      appUpdateChecker: appUpdateChecker,
      appUpdateInstaller: appUpdateInstaller,
    );
  }

  if (_isJsonBottleListCommand(arguments)) {
    final bottles = activeBottleCatalog.listBottles();
    _synchronizeMacosPinnedProgramLaunchers(
      hostPlatform: programRunPlanner.hostPlatform,
      environment: programRunPlanner.environment,
      bottles: bottles,
    );
    return CliResult(
      exitCode: 0,
      stdout: jsonEncode(<String, Object?>{
        'schemaVersion': cliSchemaVersion,
        'bottles': bottles
            .map((bottle) => bottle.toJson())
            .toList(growable: false),
      }),
      stderr: '',
    );
  }

  if (_isJsonBottleInspectCommand(arguments)) {
    final bottleId = arguments[1];
    final bottle = activeBottleCatalog.findBottle(bottleId);

    if (bottle == null) {
      return CliResult(
        exitCode: 66,
        stdout: jsonEncode(<String, Object?>{
          'schemaVersion': cliSchemaVersion,
          'error': <String, Object?>{
            'code': 'bottleNotFound',
            'message': 'Bottle not found.',
            'bottleId': bottleId,
          },
        }),
        stderr: '',
      );
    }

    final inspectedBottle = _bottleWithRegistrySettings(
      bottle: bottle,
      programRunPlanner: programRunPlanner,
      programRunner: programRunner,
    );

    return CliResult(
      exitCode: 0,
      stdout: jsonEncode(<String, Object?>{
        'schemaVersion': cliSchemaVersion,
        'bottle': inspectedBottle.toJson(),
      }),
      stderr: '',
    );
  }

  final bottleProgramsListId = _parseJsonBottleProgramsListCommand(arguments);
  if (bottleProgramsListId != null) {
    final bottle = activeBottleCatalog.findBottle(bottleProgramsListId);

    if (bottle == null) {
      return _bottleNotFoundError(bottleProgramsListId);
    }

    return CliResult(
      exitCode: 0,
      stdout: jsonEncode(<String, Object?>{
        'schemaVersion': cliSchemaVersion,
        'bottlePrograms': <String, Object?>{
          'bottleId': bottle.id,
          'programs': bottleProgramRepository
              .listPrograms(bottle)
              .map((program) => program.toJson())
              .toList(growable: false),
        },
      }),
      stderr: '',
    );
  }

  if (_isJsonWinetricksVerbListCommand(arguments)) {
    final listResult = winetricksVerbRepository.listVerbs();
    return switch (listResult) {
      WinetricksVerbListCompleted(:final categories) => CliResult(
        exitCode: 0,
        stdout: jsonEncode(<String, Object?>{
          'schemaVersion': cliSchemaVersion,
          'winetricks': <String, Object?>{
            'categories': categories
                .map((category) => category.toJson())
                .toList(growable: false),
          },
        }),
        stderr: '',
      ),
      WinetricksVerbListFailed(:final message) => _jsonError(
        exitCode: 75,
        code: 'winetricksVerbsUnavailable',
        message: message,
      ),
    };
  }

  final createBottleRequest = _parseJsonBottleCreateRequest(arguments);
  if (createBottleRequest != null) {
    if (bottleRepository == null) {
      return _jsonError(
        exitCode: 74,
        code: 'bottleRepositoryUnavailable',
        message: 'Bottle repository is not configured.',
      );
    }

    final createResult = bottleRepository.createBottle(createBottleRequest);

    return switch (createResult) {
      BottleCreated(:final bottle) => _createdBottleJsonResult(
        bottle: bottle,
        bottlePrefixInitializer: bottlePrefixInitializer,
      ),
      BottleCreateConflict(:final bottleId) => _jsonError(
        exitCode: 73,
        code: 'bottleAlreadyExists',
        message: 'Bottle already exists.',
        extra: <String, Object?>{'bottleId': bottleId},
      ),
    };
  }

  final bottleArchiveExportRequest = _parseJsonBottleArchiveExportRequest(
    arguments,
  );
  if (bottleArchiveExportRequest != null) {
    if (bottleRepository == null) {
      return _jsonError(
        exitCode: 74,
        code: 'bottleRepositoryUnavailable',
        message: 'Bottle repository is not configured.',
      );
    }

    return _bottleArchiveExportJsonResult(
      bottleRepository.exportBottleArchive(bottleArchiveExportRequest),
    );
  }

  final bottleArchiveImportRequest = _parseJsonBottleArchiveImportRequest(
    arguments,
  );
  if (bottleArchiveImportRequest != null) {
    if (bottleRepository == null) {
      return _jsonError(
        exitCode: 74,
        code: 'bottleRepositoryUnavailable',
        message: 'Bottle repository is not configured.',
      );
    }

    return _bottleArchiveImportJsonResult(
      bottleRepository.importBottleArchive(bottleArchiveImportRequest),
    );
  }

  final deleteBottleId = _parseJsonBottleDeleteCommand(arguments);
  if (deleteBottleId != null) {
    if (bottleRepository == null) {
      return _jsonError(
        exitCode: 74,
        code: 'bottleRepositoryUnavailable',
        message: 'Bottle repository is not configured.',
      );
    }

    final deleteResult = bottleRepository.deleteBottle(deleteBottleId);

    return switch (deleteResult) {
      BottleDeleted(:final bottle) => CliResult(
        exitCode: 0,
        stdout: jsonEncode(<String, Object?>{
          'schemaVersion': cliSchemaVersion,
          'deletedBottle': bottle.toJson(),
        }),
        stderr: '',
      ),
      BottleDeleteMissing(:final bottleId) => _bottleNotFoundError(bottleId),
    };
  }

  final renameBottleRequest = _parseJsonBottleRenameRequest(arguments);
  if (renameBottleRequest != null) {
    if (bottleRepository == null) {
      return _jsonError(
        exitCode: 74,
        code: 'bottleRepositoryUnavailable',
        message: 'Bottle repository is not configured.',
      );
    }

    final renameResult = bottleRepository.renameBottle(renameBottleRequest);

    return switch (renameResult) {
      BottleRenamed(:final bottle) => CliResult(
        exitCode: 0,
        stdout: jsonEncode(<String, Object?>{
          'schemaVersion': cliSchemaVersion,
          'bottle': bottle.toJson(),
        }),
        stderr: '',
      ),
      BottleRenameMissing(:final bottleId) => _bottleNotFoundError(bottleId),
      BottleRenameConflict(:final bottleId) => _jsonError(
        exitCode: 73,
        code: 'bottleAlreadyExists',
        message: 'Bottle already exists.',
        extra: <String, Object?>{'bottleId': bottleId},
      ),
    };
  }

  final moveBottleRequest = _parseJsonBottleMoveRequest(arguments);
  if (moveBottleRequest != null) {
    if (bottleRepository == null) {
      return _jsonError(
        exitCode: 74,
        code: 'bottleRepositoryUnavailable',
        message: 'Bottle repository is not configured.',
      );
    }

    final moveResult = bottleRepository.moveBottle(moveBottleRequest);

    return switch (moveResult) {
      BottleMoved(:final bottle) => CliResult(
        exitCode: 0,
        stdout: jsonEncode(<String, Object?>{
          'schemaVersion': cliSchemaVersion,
          'bottle': bottle.toJson(),
        }),
        stderr: '',
      ),
      BottleMoveMissing(:final bottleId) => _bottleNotFoundError(bottleId),
      BottleMoveConflict(:final path) => _jsonError(
        exitCode: 73,
        code: 'bottleMoveDestinationExists',
        message: 'Bottle move destination exists.',
        extra: <String, Object?>{'path': path},
      ),
    };
  }

  final windowsVersionUpdateRequest = _parseJsonWindowsVersionUpdateRequest(
    arguments,
  );
  if (windowsVersionUpdateRequest != null) {
    if (bottleRepository == null) {
      return _jsonError(
        exitCode: 74,
        code: 'bottleRepositoryUnavailable',
        message: 'Bottle repository is not configured.',
      );
    }

    final bottle = bottleRepository.findBottle(
      windowsVersionUpdateRequest.bottleId,
    );
    if (bottle == null) {
      return _bottleNotFoundError(windowsVersionUpdateRequest.bottleId);
    }

    final registryUpdateFailure = _applyWindowsVersionRegistryUpdates(
      bottle: bottle,
      windowsVersion: windowsVersionUpdateRequest.windowsVersion,
      programRunPlanner: programRunPlanner,
      programRunner: programRunner,
    );
    if (registryUpdateFailure != null) {
      return registryUpdateFailure;
    }

    final updateResult = bottleRepository.setWindowsVersion(
      windowsVersionUpdateRequest,
    );

    return switch (updateResult) {
      BottleUpdated(:final bottle) => CliResult(
        exitCode: 0,
        stdout: jsonEncode(<String, Object?>{
          'schemaVersion': cliSchemaVersion,
          'bottle': bottle.toJson(),
        }),
        stderr: '',
      ),
      BottleUpdateMissing(:final bottleId) => _bottleNotFoundError(bottleId),
    };
  }

  final runtimeSettingsUpdateRequest = _parseJsonRuntimeSettingsUpdateRequest(
    arguments,
  );
  if (runtimeSettingsUpdateRequest != null) {
    if (bottleRepository == null) {
      return _jsonError(
        exitCode: 74,
        code: 'bottleRepositoryUnavailable',
        message: 'Bottle repository is not configured.',
      );
    }

    final bottle = bottleRepository.findBottle(
      runtimeSettingsUpdateRequest.bottleId,
    );
    if (bottle == null) {
      return _bottleNotFoundError(runtimeSettingsUpdateRequest.bottleId);
    }

    final registryUpdateFailure = _applyRuntimeSettingsRegistryUpdates(
      bottle: bottle,
      runtimeSettings: runtimeSettingsUpdateRequest.runtimeSettings,
      programRunPlanner: programRunPlanner,
      programRunner: programRunner,
    );
    if (registryUpdateFailure != null) {
      return registryUpdateFailure;
    }

    final dllSyncFailure = _syncRuntimeSettingsDllOverrides(
      bottle: bottle,
      runtimeSettings: runtimeSettingsUpdateRequest.runtimeSettings,
      programRunPlanner: programRunPlanner,
    );
    if (dllSyncFailure != null) {
      return dllSyncFailure;
    }

    final updateResult = bottleRepository.setRuntimeSettings(
      runtimeSettingsUpdateRequest,
    );

    return switch (updateResult) {
      BottleUpdated(:final bottle) => CliResult(
        exitCode: 0,
        stdout: jsonEncode(<String, Object?>{
          'schemaVersion': cliSchemaVersion,
          'bottle': bottle.toJson(),
        }),
        stderr: '',
      ),
      BottleUpdateMissing(:final bottleId) => _bottleNotFoundError(bottleId),
    };
  }

  final programPinRequest = _parseJsonProgramPinRequest(arguments);
  if (programPinRequest != null) {
    if (!_isSupportedProgramPath(programPinRequest.programPath)) {
      return _jsonError(
        exitCode: 65,
        code: 'unsupportedProgramType',
        message: 'Program type is not supported.',
        extra: <String, Object?>{'programPath': programPinRequest.programPath},
      );
    }

    if (bottleRepository == null) {
      return _jsonError(
        exitCode: 74,
        code: 'bottleRepositoryUnavailable',
        message: 'Bottle repository is not configured.',
      );
    }

    final pinResult = bottleRepository.pinProgram(programPinRequest);
    if (pinResult is ProgramPinned) {
      _synchronizeMacosPinnedProgramLaunchers(
        hostPlatform: programRunPlanner.hostPlatform,
        environment: programRunPlanner.environment,
        bottles: bottleRepository.listBottles(),
      );
    }

    return switch (pinResult) {
      ProgramPinned(:final bottle) => CliResult(
        exitCode: 0,
        stdout: jsonEncode(<String, Object?>{
          'schemaVersion': cliSchemaVersion,
          'bottle': bottle.toJson(),
        }),
        stderr: '',
      ),
      ProgramPinMissing(:final bottleId) => _bottleNotFoundError(bottleId),
      ProgramPinConflict(:final programPath) => _jsonError(
        exitCode: 73,
        code: 'programAlreadyPinned',
        message: 'Program is already pinned.',
        extra: <String, Object?>{'programPath': programPath},
      ),
    };
  }

  final programUnpinRequest = _parseJsonProgramUnpinRequest(arguments);
  if (programUnpinRequest != null) {
    if (bottleRepository == null) {
      return _jsonError(
        exitCode: 74,
        code: 'bottleRepositoryUnavailable',
        message: 'Bottle repository is not configured.',
      );
    }

    final updateResult = bottleRepository.unpinProgram(programUnpinRequest);
    if (updateResult is ProgramUpdated) {
      _synchronizeMacosPinnedProgramLaunchers(
        hostPlatform: programRunPlanner.hostPlatform,
        environment: programRunPlanner.environment,
        bottles: bottleRepository.listBottles(),
      );
    }

    return _programUpdateJsonResult(updateResult);
  }

  final programRenameRequest = _parseJsonProgramRenameRequest(arguments);
  if (programRenameRequest != null) {
    if (bottleRepository == null) {
      return _jsonError(
        exitCode: 74,
        code: 'bottleRepositoryUnavailable',
        message: 'Bottle repository is not configured.',
      );
    }

    final updateResult = bottleRepository.renamePinnedProgram(
      programRenameRequest,
    );
    if (updateResult is ProgramUpdated) {
      _synchronizeMacosPinnedProgramLaunchers(
        hostPlatform: programRunPlanner.hostPlatform,
        environment: programRunPlanner.environment,
        bottles: bottleRepository.listBottles(),
      );
    }

    return _programUpdateJsonResult(updateResult);
  }

  final programSettingsRequest = _parseJsonProgramSettingsRequest(arguments);
  if (programSettingsRequest != null) {
    if (bottleRepository == null) {
      return _jsonError(
        exitCode: 74,
        code: 'bottleRepositoryUnavailable',
        message: 'Bottle repository is not configured.',
      );
    }

    final readResult = bottleRepository.readProgramSettings(
      programSettingsRequest,
    );

    return _programSettingsReadJsonResult(
      request: programSettingsRequest,
      result: readResult,
    );
  }

  final programSettingsUpdateRequest = _parseJsonProgramSettingsUpdateRequest(
    arguments,
  );
  if (programSettingsUpdateRequest != null) {
    if (bottleRepository == null) {
      return _jsonError(
        exitCode: 74,
        code: 'bottleRepositoryUnavailable',
        message: 'Bottle repository is not configured.',
      );
    }

    final updateResult = bottleRepository.setProgramSettings(
      programSettingsUpdateRequest,
    );

    return _programSettingsUpdateJsonResult(
      request: programSettingsUpdateRequest,
      result: updateResult,
    );
  }

  final pinnedProgramLaunchCliRequest = _parseJsonPinnedProgramLaunchCliRequest(
    arguments,
  );
  if (pinnedProgramLaunchCliRequest != null) {
    return _runPinnedProgramLauncherCli(
      request: pinnedProgramLaunchCliRequest,
      bottleRepository: bottleRepository,
      programRunPlanner: programRunPlanner,
      programRunner: programRunner,
    );
  }

  final programRunCliRequest = _parseJsonProgramRunCliRequest(arguments);
  if (programRunCliRequest != null) {
    if (bottleRepository == null) {
      return _jsonError(
        exitCode: 74,
        code: 'bottleRepositoryUnavailable',
        message: 'Bottle repository is not configured.',
      );
    }

    if (programRunner == null) {
      return _jsonError(
        exitCode: 74,
        code: 'programRunnerUnavailable',
        message: 'Program runner is not configured.',
      );
    }

    final bottle = bottleRepository.findBottle(programRunCliRequest.bottleId);
    if (bottle == null) {
      return _bottleNotFoundError(programRunCliRequest.bottleId);
    }

    final settingsResult = bottleRepository.readProgramSettings(
      ProgramSettingsRequest(
        bottleId: bottle.id,
        programPath: programRunCliRequest.programPath,
      ),
    );
    final programSettings = switch (settingsResult) {
      ProgramSettingsRead(:final settings) => settings,
      ProgramSettingsReadMissingBottle() => const ProgramSettingsRecord(),
    };

    final programRunRequest = programRunPlanner.plan(
      bottle: bottle,
      programPath: programRunCliRequest.programPath,
      programSettings: programSettings,
    );
    if (programRunRequest == null) {
      return _jsonError(
        exitCode: 65,
        code: 'unsupportedProgramType',
        message: 'Program type is not supported.',
        extra: <String, Object?>{
          'programPath': programRunCliRequest.programPath,
        },
      );
    }

    _recordExternalProgramRun(bottle: bottle, request: programRunRequest);
    _synchronizeLinuxDesktopLauncherForProgramRun(
      hostPlatform: programRunPlanner.hostPlatform,
      environment: programRunPlanner.environment,
      bottle: bottle,
      request: programRunRequest,
    );

    final runResult = programRunner.run(programRunRequest);

    return switch (runResult) {
      ProgramRunCompleted(:final processExitCode) => _programRunJsonResult(
        request: programRunRequest,
        processExitCode: processExitCode,
      ),
      ProgramRunFailed(:final message) => _programRunFailedJsonResult(
        request: programRunRequest,
        message: message,
      ),
    };
  }

  final winetricksRunCliRequest = _parseJsonWinetricksRunCliRequest(arguments);
  if (winetricksRunCliRequest != null) {
    if (bottleRepository == null) {
      return _jsonError(
        exitCode: 74,
        code: 'bottleRepositoryUnavailable',
        message: 'Bottle repository is not configured.',
      );
    }

    if (programRunner == null) {
      return _jsonError(
        exitCode: 74,
        code: 'programRunnerUnavailable',
        message: 'Program runner is not configured.',
      );
    }

    final bottle = bottleRepository.findBottle(
      winetricksRunCliRequest.bottleId,
    );
    if (bottle == null) {
      return _bottleNotFoundError(winetricksRunCliRequest.bottleId);
    }

    final programRunRequest = programRunPlanner.planWinetricksVerb(
      bottle: bottle,
      verb: winetricksRunCliRequest.verb,
    );
    if (programRunRequest == null) {
      return _jsonError(
        exitCode: 65,
        code: 'unsupportedWinetricksVerb',
        message: 'Winetricks verb is not supported.',
        extra: <String, Object?>{'verb': winetricksRunCliRequest.verb},
      );
    }

    final winetricksReady = _ensureWinetricksScriptForRun(
      request: programRunRequest,
      scriptInstaller: winetricksScriptInstaller,
    );
    if (winetricksReady != null) {
      return winetricksReady;
    }

    final runResult = programRunner.run(programRunRequest);

    return switch (runResult) {
      ProgramRunCompleted(:final processExitCode) => _programRunJsonResult(
        request: programRunRequest,
        processExitCode: processExitCode,
      ),
      ProgramRunFailed(:final message) => _programRunFailedJsonResult(
        request: programRunRequest,
        message: message,
      ),
    };
  }

  final bottleCommandRunCliRequest = _parseJsonBottleCommandRunCliRequest(
    arguments,
  );
  if (bottleCommandRunCliRequest != null) {
    if (bottleRepository == null) {
      return _jsonError(
        exitCode: 74,
        code: 'bottleRepositoryUnavailable',
        message: 'Bottle repository is not configured.',
      );
    }

    if (programRunner == null) {
      return _jsonError(
        exitCode: 74,
        code: 'programRunnerUnavailable',
        message: 'Program runner is not configured.',
      );
    }

    final bottle = bottleRepository.findBottle(
      bottleCommandRunCliRequest.bottleId,
    );
    if (bottle == null) {
      return _bottleNotFoundError(bottleCommandRunCliRequest.bottleId);
    }

    final programRunRequest = programRunPlanner.planBottleCommand(
      bottle: bottle,
      command: bottleCommandRunCliRequest.command,
    );
    if (programRunRequest == null) {
      return _jsonError(
        exitCode: 65,
        code: 'unsupportedBottleCommand',
        message: 'Bottle command is not supported.',
        extra: <String, Object?>{'command': bottleCommandRunCliRequest.command},
      );
    }

    final winetricksReady = _ensureWinetricksScriptForRun(
      request: programRunRequest,
      scriptInstaller: winetricksScriptInstaller,
    );
    if (winetricksReady != null) {
      return winetricksReady;
    }

    final runResult = programRunner.run(programRunRequest);

    return switch (runResult) {
      ProgramRunCompleted(:final processExitCode) => _programRunJsonResult(
        request: programRunRequest,
        processExitCode: processExitCode,
      ),
      ProgramRunFailed(:final message) => _programRunFailedJsonResult(
        request: programRunRequest,
        message: message,
      ),
    };
  }

  final bottleLocationOpenCliRequest = _parseJsonBottleLocationOpenCliRequest(
    arguments,
  );
  if (bottleLocationOpenCliRequest != null) {
    if (bottleRepository == null) {
      return _jsonError(
        exitCode: 74,
        code: 'bottleRepositoryUnavailable',
        message: 'Bottle repository is not configured.',
      );
    }

    if (pathOpener == null) {
      return _jsonError(
        exitCode: 74,
        code: 'pathOpenerUnavailable',
        message: 'Path opener is not configured.',
      );
    }

    final bottle = bottleRepository.findBottle(
      bottleLocationOpenCliRequest.bottleId,
    );
    if (bottle == null) {
      return _bottleNotFoundError(bottleLocationOpenCliRequest.bottleId);
    }

    final path = _bottleLocationPath(
      bottle: bottle,
      location: bottleLocationOpenCliRequest.location,
    );
    if (path == null) {
      return _jsonError(
        exitCode: 65,
        code: 'unsupportedBottleLocation',
        message: 'Bottle location is not supported.',
        extra: <String, Object?>{
          'location': bottleLocationOpenCliRequest.location,
        },
      );
    }

    final openResult = pathOpener.openPath(path);

    return switch (openResult) {
      PathOpenCompleted() => CliResult(
        exitCode: 0,
        stdout: jsonEncode(<String, Object?>{
          'schemaVersion': cliSchemaVersion,
          'openedLocation': <String, Object?>{
            'bottleId': bottle.id,
            'location': bottleLocationOpenCliRequest.location,
            'path': path,
          },
        }),
        stderr: '',
      ),
      PathOpenFailed(:final message) => _jsonError(
        exitCode: 75,
        code: 'bottleLocationOpenFailed',
        message: message,
        extra: <String, Object?>{
          'bottleId': bottle.id,
          'location': bottleLocationOpenCliRequest.location,
          'path': path,
        },
      ),
    };
  }

  final programLocationOpenCliRequest = _parseJsonProgramLocationOpenCliRequest(
    arguments,
  );
  if (programLocationOpenCliRequest != null) {
    if (bottleRepository == null) {
      return _jsonError(
        exitCode: 74,
        code: 'bottleRepositoryUnavailable',
        message: 'Bottle repository is not configured.',
      );
    }

    if (pathOpener == null) {
      return _jsonError(
        exitCode: 74,
        code: 'pathOpenerUnavailable',
        message: 'Path opener is not configured.',
      );
    }

    final bottle = bottleRepository.findBottle(
      programLocationOpenCliRequest.bottleId,
    );
    if (bottle == null) {
      return _bottleNotFoundError(programLocationOpenCliRequest.bottleId);
    }

    if (!_hasPinnedProgram(bottle, programLocationOpenCliRequest.programPath)) {
      return _jsonError(
        exitCode: 66,
        code: 'programNotPinned',
        message: 'Program is not pinned.',
        extra: <String, Object?>{
          'programPath': programLocationOpenCliRequest.programPath,
        },
      );
    }

    final path = programLocationOpenCliRequest.programPath;
    final openResult = pathOpener.revealPath(path);

    return switch (openResult) {
      PathOpenCompleted() => CliResult(
        exitCode: 0,
        stdout: jsonEncode(<String, Object?>{
          'schemaVersion': cliSchemaVersion,
          'openedProgramLocation': <String, Object?>{
            'bottleId': bottle.id,
            'programPath': programLocationOpenCliRequest.programPath,
            'path': path,
          },
        }),
        stderr: '',
      ),
      PathOpenFailed(:final message) => _jsonError(
        exitCode: 75,
        code: 'programLocationOpenFailed',
        message: message,
        extra: <String, Object?>{
          'bottleId': bottle.id,
          'programPath': programLocationOpenCliRequest.programPath,
          'path': path,
        },
      ),
    };
  }

  if (_isJsonRuntimeListCommand(arguments)) {
    return CliResult(
      exitCode: 0,
      stdout: jsonEncode(<String, Object?>{
        'schemaVersion': cliSchemaVersion,
        'runtimes': runtimeCatalog
            .listRuntimes()
            .map((runtime) => runtime.toJson())
            .toList(growable: false),
      }),
      stderr: '',
    );
  }

  if (_isJsonMacosSetupCheckCommand(arguments)) {
    if (macosSetupChecker == null) {
      return _jsonError(
        exitCode: 74,
        code: 'macosSetupCheckerUnavailable',
        message: 'macOS setup checker is not configured.',
      );
    }

    final setupResult = macosSetupChecker.check();
    return switch (setupResult) {
      MacosSetupCheckCompleted(:final status) => CliResult(
        exitCode: 0,
        stdout: jsonEncode(<String, Object?>{
          'schemaVersion': cliSchemaVersion,
          'macosSetup': status.toJson(),
        }),
        stderr: '',
      ),
      MacosSetupCheckFailed(:final message) => _jsonError(
        exitCode: 75,
        code: 'macosSetupCheckFailed',
        message: message,
      ),
    };
  }

  final gptkWineInstallRequest = _parseJsonGptkWineInstallRequest(arguments);
  if (gptkWineInstallRequest != null) {
    final installer = gptkWineInstaller;
    if (installer == null) {
      return _jsonError(
        exitCode: 74,
        code: 'gptkWineInstallerUnavailable',
        message: 'GPTK-compatible Wine installer is not configured.',
      );
    }

    return switch (installer.install(gptkWineInstallRequest)) {
      GptkWineInstallCompleted(:final record) => CliResult(
        exitCode: 0,
        stdout: jsonEncode(<String, Object?>{
          'schemaVersion': cliSchemaVersion,
          'gptkWineInstall': record.toJson(),
        }),
        stderr: '',
      ),
      GptkWineInstallFailed(:final message) => _jsonError(
        exitCode: 75,
        code: 'gptkWineInstallFailed',
        message: message,
      ),
    };
  }

  final openUrl = _parseJsonOpenUrlCommand(arguments);
  if (openUrl != null) {
    if (pathOpener == null) {
      return _jsonError(
        exitCode: 74,
        code: 'pathOpenerUnavailable',
        message: 'Path opener is not configured.',
      );
    }
    final openResult = pathOpener.openPath(openUrl);
    return switch (openResult) {
      PathOpenCompleted() => CliResult(
        exitCode: 0,
        stdout: jsonEncode(<String, Object?>{
          'schemaVersion': cliSchemaVersion,
          'openedUrl': <String, Object?>{'url': openUrl},
        }),
        stderr: '',
      ),
      PathOpenFailed(:final message) => _jsonError(
        exitCode: 75,
        code: 'urlOpenFailed',
        message: message,
        extra: <String, Object?>{'url': openUrl},
      ),
    };
  }

  final runtimeUpdateId = _parseJsonRuntimeIdCommand(
    arguments,
    'check-runtime-update',
  );
  if (runtimeUpdateId != null) {
    if (runtimeUpdateChecker == null) {
      return _jsonError(
        exitCode: 74,
        code: 'runtimeUpdateCheckerUnavailable',
        message: 'Runtime update checker is not configured.',
      );
    }

    final updateResult = runtimeUpdateChecker.check(runtimeUpdateId);
    return switch (updateResult) {
      RuntimeUpdateCheckCompleted(:final update) => CliResult(
        exitCode: 0,
        stdout: jsonEncode(<String, Object?>{
          'schemaVersion': cliSchemaVersion,
          'runtimeUpdate': update.toJson(),
        }),
        stderr: '',
      ),
      RuntimeUpdateRuntimeNotFound(:final runtimeId) => _jsonError(
        exitCode: 66,
        code: 'runtimeNotFound',
        message: 'Runtime not found.',
        extra: <String, Object?>{'runtimeId': runtimeId},
      ),
      RuntimeUpdateCheckFailed(:final message) => _jsonError(
        exitCode: 75,
        code: 'runtimeUpdateCheckFailed',
        message: message,
      ),
    };
  }

  final runtimeUpdateInstallId = _parseJsonRuntimeIdCommand(
    arguments,
    'install-runtime-update',
  );
  if (runtimeUpdateInstallId != null) {
    return _installRuntimeUpdateJsonResult(
      runtimeId: runtimeUpdateInstallId,
      runtimeUpdateChecker: runtimeUpdateChecker,
      macosWineInstaller: macosWineInstaller,
      linuxWineInstaller: linuxWineInstaller,
    );
  }

  final runtimeValidationId = _parseJsonRuntimeIdCommand(
    arguments,
    'validate-runtime',
  );
  if (runtimeValidationId != null) {
    if (runtimeValidator == null) {
      return _jsonError(
        exitCode: 74,
        code: 'runtimeValidatorUnavailable',
        message: 'Runtime validator is not configured.',
      );
    }

    final validationResult = runtimeValidator.validate(runtimeValidationId);
    return switch (validationResult) {
      RuntimeValidationCompleted(:final validation) => CliResult(
        exitCode: validation.isValid ? 0 : 75,
        stdout: jsonEncode(<String, Object?>{
          'schemaVersion': cliSchemaVersion,
          'runtimeValidation': validation.toJson(),
        }),
        stderr: '',
      ),
      RuntimeValidationRuntimeNotFound(:final runtimeId) => _jsonError(
        exitCode: 66,
        code: 'runtimeNotFound',
        message: 'Runtime not found.',
        extra: <String, Object?>{'runtimeId': runtimeId},
      ),
      RuntimeValidationFailed(:final message) => _jsonError(
        exitCode: 75,
        code: 'runtimeValidationFailed',
        message: message,
      ),
    };
  }

  final macosWineInstallRequest = _parseJsonMacosWineInstallRequest(arguments);
  if (macosWineInstallRequest != null) {
    if (macosWineInstaller == null) {
      return _jsonError(
        exitCode: 74,
        code: 'macosWineInstallerUnavailable',
        message: 'macOS Wine installer is not configured.',
      );
    }

    final installResult = macosWineInstaller.install(
      macosWineInstallRequest,
      progressSink: macosWineInstallRequest.emitProgress
          ? runtimeInstallProgressSink
          : null,
    );

    return switch (installResult) {
      MacosWineInstallCompleted(:final runtime) => CliResult(
        exitCode: 0,
        stdout: jsonEncode(<String, Object?>{
          'schemaVersion': cliSchemaVersion,
          'runtime': runtime.toJson(),
        }),
        stderr: '',
      ),
      MacosWineInstallFailed(:final message) => _jsonError(
        exitCode: 75,
        code: 'macosWineInstallFailed',
        message: message,
      ),
    };
  }

  final linuxWineInstallRequest = _parseJsonLinuxWineInstallRequest(arguments);
  if (linuxWineInstallRequest != null) {
    final installer = linuxWineInstaller;
    if (installer == null) {
      return _jsonError(
        exitCode: 74,
        code: 'linuxWineInstallerUnavailable',
        message: 'Linux Wine installer is not configured.',
      );
    }

    return switch (installer.install(
      linuxWineInstallRequest,
      progressSink: linuxWineInstallRequest.emitProgress
          ? runtimeInstallProgressSink
          : null,
    )) {
      LinuxWineInstallCompleted(:final runtime) => CliResult(
        exitCode: 0,
        stdout: jsonEncode(<String, Object?>{
          'schemaVersion': cliSchemaVersion,
          'runtime': runtime.toJson(),
        }),
        stderr: '',
      ),
      LinuxWineInstallFailed(:final message) => _jsonError(
        exitCode: 75,
        code: 'linuxWineInstallFailed',
        message: message,
      ),
    };
  }

  return const CliResult(
    exitCode: 64,
    stdout: '',
    stderr: '''
Usage:
  konyak check-app-update --json
  konyak install-app-update --json
  konyak get-app-settings --json
  konyak set-app-settings --settings-json <json> --json
  konyak install-linux-file-associations --json
  konyak list-wine-processes --json
  konyak terminate-wine-process --bottle <id> --process <pid> --json
  konyak terminate-wine-processes [--bottle <id>] --json
  konyak list-bottles --json
  konyak inspect-bottle <id> --json
  konyak list-bottle-programs <id> --json
  konyak list-winetricks-verbs --json
  konyak create-bottle --name <name> [--windows-version <version>] --json
  konyak export-bottle-archive <id> --archive <path> --json
  konyak import-bottle-archive --archive <path> --json
  konyak delete-bottle <id> --json
  konyak rename-bottle <id> --name <name> --json
  konyak move-bottle <id> --path <path> --json
  konyak set-windows-version <id> --windows-version <version> --json
  konyak set-runtime-settings <id> --settings-json <json> --json
  konyak pin-program <id> --name <name> --program <path> --json
  konyak unpin-program <id> --program <path> --json
  konyak rename-pinned-program <id> --program <path> --name <name> --json
  konyak get-program-settings <id> --program <path> --json
  konyak set-program-settings <id> --program <path> --settings-json <json> --json
  konyak launch-pinned-program --manifest <path> --json
  konyak run-program <id> --program <path> --json
  konyak run-winetricks <id> --verb <verb> --json
  konyak run-bottle-command <id> --command <winecfg|regedit|control|terminal|winetricks> --json
  konyak open-bottle-location <id> --location <root|c-drive> --json
  konyak open-program-location <id> --program <path> --json
  konyak list-runtimes --json
  konyak check-macos-setup --json
  konyak install-gptk-wine --from <path> --json
  konyak open-url <https-url> --json
  konyak check-runtime-update <id> --json
  konyak install-runtime-update <id> --json
  konyak validate-runtime <id> --json
  konyak install-linux-wine [--archive <path> | --archive-url <url>] [--archive-sha256 <sha256>] [--component-archive <path> ...] [--source-manifest <path-or-url>] --json
  konyak install-macos-wine [--source-manifest <path-or-url> | --archive <path> [--archive-sha256 <sha256>] [--component-archive <path> ...] | --archive-url <url> [--component-archive <path> ...]] --json
''',
  );
}

bool _isJsonBottleListCommand(List<String> arguments) {
  return arguments.length == 2 &&
      arguments.first == 'list-bottles' &&
      arguments.last == '--json';
}

bool _isJsonAppUpdateCheckCommand(List<String> arguments) {
  return arguments.length == 2 &&
      arguments.first == 'check-app-update' &&
      arguments.last == '--json';
}

bool _isJsonAppUpdateInstallCommand(List<String> arguments) {
  return arguments.length == 2 &&
      arguments.first == 'install-app-update' &&
      arguments.last == '--json';
}

bool _isJsonAppSettingsGetCommand(List<String> arguments) {
  return arguments.length == 2 &&
      arguments.first == 'get-app-settings' &&
      arguments.last == '--json';
}

bool _isJsonLinuxFileAssociationInstallCommand(List<String> arguments) {
  return arguments.length == 2 &&
      arguments.first == 'install-linux-file-associations' &&
      arguments.last == '--json';
}

AppSettingsRecord? _parseJsonAppSettingsUpdateRequest(List<String> arguments) {
  if (arguments.length != 4 ||
      arguments.first != 'set-app-settings' ||
      arguments[1] != '--settings-json' ||
      arguments.last != '--json') {
    return null;
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(arguments[2]);
  } on FormatException {
    return null;
  }

  final settings = AppSettingsRecord.fromJson(
    decoded,
    fallbackDefaultBottlePath: '',
  );
  if (settings == null || settings.defaultBottlePath.trim().isEmpty) {
    return null;
  }

  return settings;
}

bool _isJsonWineProcessListCommand(List<String> arguments) {
  return arguments.length == 2 &&
      arguments.first == 'list-wine-processes' &&
      arguments.last == '--json';
}

WineProcessTerminationRequest? _parseJsonWineProcessTerminationRequest(
  List<String> arguments,
) {
  if (arguments.length != 6 ||
      arguments.first != 'terminate-wine-process' ||
      arguments[1] != '--bottle' ||
      arguments[3] != '--process' ||
      arguments.last != '--json') {
    return null;
  }

  final bottleId = arguments[2].trim();
  final processId = arguments[4].trim();
  if (bottleId.isEmpty || processId.isEmpty) {
    return null;
  }

  return WineProcessTerminationRequest(
    bottleId: bottleId,
    processId: processId,
  );
}

WineProcessGroupTerminationRequest?
_parseJsonWineProcessGroupTerminationRequest(List<String> arguments) {
  if (arguments.length == 2 &&
      arguments.first == 'terminate-wine-processes' &&
      arguments.last == '--json') {
    return const WineProcessGroupTerminationRequest();
  }

  if (arguments.length != 4 ||
      arguments.first != 'terminate-wine-processes' ||
      arguments[1] != '--bottle' ||
      arguments.last != '--json') {
    return null;
  }

  final bottleId = arguments[2].trim();
  if (bottleId.isEmpty) {
    return null;
  }

  return WineProcessGroupTerminationRequest(bottleId: bottleId);
}

bool _isJsonBottleInspectCommand(List<String> arguments) {
  return arguments.length == 3 &&
      arguments.first == 'inspect-bottle' &&
      arguments[1].isNotEmpty &&
      arguments.last == '--json';
}

String? _parseJsonBottleProgramsListCommand(List<String> arguments) {
  if (arguments.length != 3 ||
      arguments.first != 'list-bottle-programs' ||
      arguments.last != '--json') {
    return null;
  }

  final bottleId = arguments[1].trim();
  return bottleId.isEmpty ? null : bottleId;
}

bool _isJsonWinetricksVerbListCommand(List<String> arguments) {
  return arguments.length == 2 &&
      arguments.first == 'list-winetricks-verbs' &&
      arguments.last == '--json';
}

BottleCreateRequest? _parseJsonBottleCreateRequest(List<String> arguments) {
  if (arguments.length != 4 && arguments.length != 6) {
    return null;
  }

  if (arguments.first != 'create-bottle' ||
      arguments[1] != '--name' ||
      arguments.last != '--json') {
    return null;
  }

  final name = arguments[2].trim();
  if (name.isEmpty) {
    return null;
  }

  if (arguments.length == 4) {
    return BottleCreateRequest(name: name, windowsVersion: 'win10');
  }

  if (arguments[3] != '--windows-version') {
    return null;
  }

  final windowsVersion = arguments[4].trim();
  if (windowsVersion.isEmpty) {
    return null;
  }

  return BottleCreateRequest(name: name, windowsVersion: windowsVersion);
}

BottleArchiveExportRequest? _parseJsonBottleArchiveExportRequest(
  List<String> arguments,
) {
  if (arguments.length != 5 ||
      arguments.first != 'export-bottle-archive' ||
      arguments[2] != '--archive' ||
      arguments.last != '--json') {
    return null;
  }

  final bottleId = arguments[1].trim();
  final archivePath = arguments[3].trim();
  if (bottleId.isEmpty || archivePath.isEmpty) {
    return null;
  }

  return BottleArchiveExportRequest(
    bottleId: bottleId,
    archivePath: archivePath,
  );
}

BottleArchiveImportRequest? _parseJsonBottleArchiveImportRequest(
  List<String> arguments,
) {
  if (arguments.length != 4 ||
      arguments.first != 'import-bottle-archive' ||
      arguments[1] != '--archive' ||
      arguments.last != '--json') {
    return null;
  }

  final archivePath = arguments[2].trim();
  if (archivePath.isEmpty) {
    return null;
  }

  return BottleArchiveImportRequest(archivePath: archivePath);
}

String? _parseJsonBottleDeleteCommand(List<String> arguments) {
  if (arguments.length != 3 ||
      arguments.first != 'delete-bottle' ||
      arguments.last != '--json') {
    return null;
  }

  final bottleId = arguments[1].trim();
  return bottleId.isEmpty ? null : bottleId;
}

BottleRenameRequest? _parseJsonBottleRenameRequest(List<String> arguments) {
  if (arguments.length != 5 ||
      arguments.first != 'rename-bottle' ||
      arguments[2] != '--name' ||
      arguments.last != '--json') {
    return null;
  }

  final bottleId = arguments[1].trim();
  final name = arguments[3].trim();
  if (bottleId.isEmpty || name.isEmpty) {
    return null;
  }

  return BottleRenameRequest(bottleId: bottleId, name: name);
}

BottleMoveRequest? _parseJsonBottleMoveRequest(List<String> arguments) {
  if (arguments.length != 5 ||
      arguments.first != 'move-bottle' ||
      arguments[2] != '--path' ||
      arguments.last != '--json') {
    return null;
  }

  final bottleId = arguments[1].trim();
  final path = arguments[3].trim();
  if (bottleId.isEmpty || path.isEmpty) {
    return null;
  }

  return BottleMoveRequest(bottleId: bottleId, path: path);
}

WindowsVersionUpdateRequest? _parseJsonWindowsVersionUpdateRequest(
  List<String> arguments,
) {
  if (arguments.length != 5 ||
      arguments.first != 'set-windows-version' ||
      arguments[2] != '--windows-version' ||
      arguments.last != '--json') {
    return null;
  }

  final bottleId = arguments[1].trim();
  final windowsVersion = arguments[3].trim();

  if (bottleId.isEmpty || windowsVersion.isEmpty) {
    return null;
  }

  return WindowsVersionUpdateRequest(
    bottleId: bottleId,
    windowsVersion: windowsVersion,
  );
}

RuntimeSettingsUpdateRequest? _parseJsonRuntimeSettingsUpdateRequest(
  List<String> arguments,
) {
  if (arguments.length != 5 ||
      arguments.first != 'set-runtime-settings' ||
      arguments[2] != '--settings-json' ||
      arguments.last != '--json') {
    return null;
  }

  final bottleId = arguments[1].trim();
  if (bottleId.isEmpty) {
    return null;
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(arguments[3]);
  } on FormatException {
    return null;
  }

  if (decoded == null) {
    return null;
  }

  final runtimeSettings = BottleRuntimeSettings.fromJson(decoded);
  if (runtimeSettings == null) {
    return null;
  }

  return RuntimeSettingsUpdateRequest(
    bottleId: bottleId,
    runtimeSettings: runtimeSettings,
  );
}

ProgramPinRequest? _parseJsonProgramPinRequest(List<String> arguments) {
  if (arguments.length != 7 ||
      arguments.first != 'pin-program' ||
      arguments[2] != '--name' ||
      arguments[4] != '--program' ||
      arguments.last != '--json') {
    return null;
  }

  final bottleId = arguments[1].trim();
  final name = arguments[3].trim();
  final programPath = arguments[5].trim();
  if (bottleId.isEmpty || name.isEmpty || programPath.isEmpty) {
    return null;
  }

  return ProgramPinRequest(
    bottleId: bottleId,
    name: name,
    programPath: programPath,
  );
}

ProgramUnpinRequest? _parseJsonProgramUnpinRequest(List<String> arguments) {
  if (arguments.length != 5 ||
      arguments.first != 'unpin-program' ||
      arguments[2] != '--program' ||
      arguments.last != '--json') {
    return null;
  }

  final bottleId = arguments[1].trim();
  final programPath = arguments[3].trim();
  if (bottleId.isEmpty || programPath.isEmpty) {
    return null;
  }

  return ProgramUnpinRequest(bottleId: bottleId, programPath: programPath);
}

ProgramRenameRequest? _parseJsonProgramRenameRequest(List<String> arguments) {
  if (arguments.length != 7 ||
      arguments.first != 'rename-pinned-program' ||
      arguments[2] != '--program' ||
      arguments[4] != '--name' ||
      arguments.last != '--json') {
    return null;
  }

  final bottleId = arguments[1].trim();
  final programPath = arguments[3].trim();
  final name = arguments[5].trim();
  if (bottleId.isEmpty || programPath.isEmpty || name.isEmpty) {
    return null;
  }

  return ProgramRenameRequest(
    bottleId: bottleId,
    programPath: programPath,
    name: name,
  );
}

ProgramSettingsRequest? _parseJsonProgramSettingsRequest(
  List<String> arguments,
) {
  if (arguments.length != 5 ||
      arguments.first != 'get-program-settings' ||
      arguments[2] != '--program' ||
      arguments.last != '--json') {
    return null;
  }

  final bottleId = arguments[1].trim();
  final programPath = arguments[3].trim();
  if (bottleId.isEmpty || programPath.isEmpty) {
    return null;
  }

  return ProgramSettingsRequest(bottleId: bottleId, programPath: programPath);
}

ProgramSettingsUpdateRequest? _parseJsonProgramSettingsUpdateRequest(
  List<String> arguments,
) {
  if (arguments.length != 7 ||
      arguments.first != 'set-program-settings' ||
      arguments[2] != '--program' ||
      arguments[4] != '--settings-json' ||
      arguments.last != '--json') {
    return null;
  }

  final bottleId = arguments[1].trim();
  final programPath = arguments[3].trim();
  if (bottleId.isEmpty || programPath.isEmpty) {
    return null;
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(arguments[5]);
  } on FormatException {
    return null;
  }

  final settings = ProgramSettingsRecord.fromJson(decoded);
  if (settings == null) {
    return null;
  }

  return ProgramSettingsUpdateRequest(
    bottleId: bottleId,
    programPath: programPath,
    settings: settings,
  );
}

bool _isJsonRuntimeListCommand(List<String> arguments) {
  return arguments.length == 2 &&
      arguments.first == 'list-runtimes' &&
      arguments.last == '--json';
}

bool _isJsonMacosSetupCheckCommand(List<String> arguments) {
  return arguments.length == 2 &&
      arguments.first == 'check-macos-setup' &&
      arguments.last == '--json';
}

GptkWineInstallRequest? _parseJsonGptkWineInstallRequest(
  List<String> arguments,
) {
  if (arguments.length != 4 ||
      arguments.first != 'install-gptk-wine' ||
      arguments[1] != '--from' ||
      arguments.last != '--json') {
    return null;
  }

  final sourcePath = arguments[2].trim();
  if (sourcePath.isEmpty) {
    return null;
  }

  return GptkWineInstallRequest(sourcePath: sourcePath);
}

String? _parseJsonOpenUrlCommand(List<String> arguments) {
  if (arguments.length != 3 ||
      arguments.first != 'open-url' ||
      arguments.last != '--json') {
    return null;
  }

  final url = arguments[1].trim();
  if (url.startsWith('https://') || url.startsWith('http://')) {
    return url;
  }

  return null;
}

String? _parseJsonRuntimeIdCommand(List<String> arguments, String command) {
  if (arguments.length != 3 ||
      arguments.first != command ||
      arguments.last != '--json') {
    return null;
  }

  final runtimeId = arguments[1].trim();
  if (runtimeId.isEmpty) {
    return null;
  }

  return runtimeId;
}

MacosWineInstallRequest? _parseJsonMacosWineInstallRequest(
  List<String> arguments,
) {
  if (arguments.length == 2 &&
      arguments.first == 'install-macos-wine' &&
      arguments.last == '--json') {
    return MacosWineInstallRequest.fullInstall();
  }

  if (arguments.first != 'install-macos-wine' || arguments.last != '--json') {
    return null;
  }

  String? archivePath;
  String? archiveUrl;
  String? archiveSha256;
  final componentArchivePaths = <String>[];
  String? sourceManifest;
  var emitProgress = false;

  var index = 1;
  while (index < arguments.length - 1) {
    final option = arguments[index];
    if (option == '--progress-json') {
      emitProgress = true;
      index += 1;
      continue;
    }

    if (index + 1 >= arguments.length - 1) {
      return null;
    }

    final value = arguments[index + 1].trim();
    if (value.isEmpty) {
      return null;
    }

    switch (option) {
      case '--archive':
        archivePath = value;
      case '--archive-url':
        archiveUrl = value;
      case '--archive-sha256':
        if (!_isSha256Hex(value)) {
          return null;
        }
        archiveSha256 = value;
      case '--component-archive':
        componentArchivePaths.add(value);
      case '--source-manifest':
        sourceManifest = value;
      default:
        return null;
    }
    index += 2;
  }

  if (archivePath != null && archiveUrl != null) {
    return null;
  }

  if (sourceManifest != null &&
      (archivePath != null ||
          archiveUrl != null ||
          archiveSha256 != null ||
          componentArchivePaths.isNotEmpty)) {
    return null;
  }

  if (componentArchivePaths.isNotEmpty) {
    return MacosWineInstallRequest.componentInstall(
      archivePath: archivePath,
      archiveUrl: archiveUrl,
      archiveSha256: archiveSha256,
      componentArchivePaths: componentArchivePaths,
      emitProgress: emitProgress,
    );
  }

  return MacosWineInstallRequest.fullInstall(
    archivePath: archivePath,
    archiveUrl: archiveUrl,
    archiveSha256: archiveSha256,
    sourceManifest: sourceManifest,
    emitProgress: emitProgress,
  );
}

LinuxWineInstallRequest? _parseJsonLinuxWineInstallRequest(
  List<String> arguments,
) {
  if (arguments.length == 2 &&
      arguments.first == 'install-linux-wine' &&
      arguments.last == '--json') {
    return LinuxWineInstallRequest.fullInstall();
  }

  if (arguments.first != 'install-linux-wine' || arguments.last != '--json') {
    return null;
  }

  String? archivePath;
  String? archiveUrl;
  String? archiveSha256;
  final componentArchivePaths = <String>[];
  String? sourceManifest;
  var emitProgress = false;

  var index = 1;
  while (index < arguments.length - 1) {
    final option = arguments[index];
    if (option == '--progress-json') {
      emitProgress = true;
      index += 1;
      continue;
    }

    if (index + 1 >= arguments.length - 1) {
      return null;
    }

    final value = arguments[index + 1].trim();
    if (value.isEmpty) {
      return null;
    }

    switch (option) {
      case '--archive':
        archivePath = value;
      case '--archive-url':
        archiveUrl = value;
      case '--archive-sha256':
        if (!_isSha256Hex(value)) {
          return null;
        }
        archiveSha256 = value;
      case '--component-archive':
        componentArchivePaths.add(value);
      case '--source-manifest':
        sourceManifest = value;
      default:
        return null;
    }
    index += 2;
  }

  if (archivePath != null && archiveUrl != null) {
    return null;
  }

  if (sourceManifest != null &&
      (archivePath != null ||
          archiveUrl != null ||
          archiveSha256 != null ||
          componentArchivePaths.isNotEmpty)) {
    return null;
  }

  if (componentArchivePaths.isNotEmpty) {
    return LinuxWineInstallRequest.componentInstall(
      archivePath: archivePath,
      archiveUrl: archiveUrl,
      archiveSha256: archiveSha256,
      componentArchivePaths: componentArchivePaths,
      emitProgress: emitProgress,
    );
  }

  return LinuxWineInstallRequest.fullInstall(
    archivePath: archivePath,
    archiveUrl: archiveUrl,
    archiveSha256: archiveSha256,
    sourceManifest: sourceManifest,
    emitProgress: emitProgress,
  );
}

class _ProgramRunCliRequest {
  const _ProgramRunCliRequest({
    required this.bottleId,
    required this.programPath,
  });

  final String bottleId;
  final String programPath;
}

_ProgramRunCliRequest? _parseJsonProgramRunCliRequest(List<String> arguments) {
  if (arguments.length != 5 ||
      arguments.first != 'run-program' ||
      arguments[2] != '--program' ||
      arguments.last != '--json') {
    return null;
  }

  final bottleId = arguments[1].trim();
  final programPath = arguments[3].trim();

  if (bottleId.isEmpty || programPath.isEmpty) {
    return null;
  }

  return _ProgramRunCliRequest(bottleId: bottleId, programPath: programPath);
}

class _PinnedProgramLaunchCliRequest {
  const _PinnedProgramLaunchCliRequest({required this.manifestPath});

  final String manifestPath;
}

_PinnedProgramLaunchCliRequest? _parseJsonPinnedProgramLaunchCliRequest(
  List<String> arguments,
) {
  if (arguments.length != 4 ||
      arguments.first != 'launch-pinned-program' ||
      arguments[1] != '--manifest' ||
      arguments.last != '--json') {
    return null;
  }

  final manifestPath = arguments[2].trim();
  if (manifestPath.isEmpty) {
    return null;
  }

  return _PinnedProgramLaunchCliRequest(manifestPath: manifestPath);
}

class _WinetricksRunCliRequest {
  const _WinetricksRunCliRequest({required this.bottleId, required this.verb});

  final String bottleId;
  final String verb;
}

_WinetricksRunCliRequest? _parseJsonWinetricksRunCliRequest(
  List<String> arguments,
) {
  if (arguments.length != 5 ||
      arguments.first != 'run-winetricks' ||
      arguments[2] != '--verb' ||
      arguments.last != '--json') {
    return null;
  }

  final bottleId = arguments[1].trim();
  final verb = arguments[3].trim();

  if (bottleId.isEmpty || verb.isEmpty) {
    return null;
  }

  return _WinetricksRunCliRequest(bottleId: bottleId, verb: verb);
}

class _BottleCommandRunCliRequest {
  const _BottleCommandRunCliRequest({
    required this.bottleId,
    required this.command,
  });

  final String bottleId;
  final String command;
}

_BottleCommandRunCliRequest? _parseJsonBottleCommandRunCliRequest(
  List<String> arguments,
) {
  if (arguments.length != 5 ||
      arguments.first != 'run-bottle-command' ||
      arguments[2] != '--command' ||
      arguments.last != '--json') {
    return null;
  }

  final bottleId = arguments[1].trim();
  final command = arguments[3].trim();

  if (bottleId.isEmpty || command.isEmpty) {
    return null;
  }

  return _BottleCommandRunCliRequest(bottleId: bottleId, command: command);
}

class _BottleLocationOpenCliRequest {
  const _BottleLocationOpenCliRequest({
    required this.bottleId,
    required this.location,
  });

  final String bottleId;
  final String location;
}

_BottleLocationOpenCliRequest? _parseJsonBottleLocationOpenCliRequest(
  List<String> arguments,
) {
  if (arguments.length != 5 ||
      arguments.first != 'open-bottle-location' ||
      arguments[2] != '--location' ||
      arguments.last != '--json') {
    return null;
  }

  final bottleId = arguments[1].trim();
  final location = arguments[3].trim();

  if (bottleId.isEmpty || location.isEmpty) {
    return null;
  }

  return _BottleLocationOpenCliRequest(bottleId: bottleId, location: location);
}

class _ProgramLocationOpenCliRequest {
  const _ProgramLocationOpenCliRequest({
    required this.bottleId,
    required this.programPath,
  });

  final String bottleId;
  final String programPath;
}

_ProgramLocationOpenCliRequest? _parseJsonProgramLocationOpenCliRequest(
  List<String> arguments,
) {
  if (arguments.length != 5 ||
      arguments.first != 'open-program-location' ||
      arguments[2] != '--program' ||
      arguments.last != '--json') {
    return null;
  }

  final bottleId = arguments[1].trim();
  final programPath = arguments[3].trim();

  if (bottleId.isEmpty || programPath.isEmpty) {
    return null;
  }

  return _ProgramLocationOpenCliRequest(
    bottleId: bottleId,
    programPath: programPath,
  );
}

ProgramRunRequest _linuxWineRequest({
  required BottleRecord bottle,
  required String programPath,
  required Map<String, String> environment,
  required ProgramSettingsRecord programSettings,
}) {
  final arguments = <String>[
    ..._wineArgumentsForProgramPath(programPath),
    ..._programSettingsArguments(programSettings),
  ];

  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: programPath,
    runnerKind: 'wine',
    executable: _linuxWineExecutable(environment),
    arguments: arguments,
    environment: <String, String>{
      ..._linuxRuntimeEnvironment(environment),
      ..._programSettingsEnvironment(programSettings),
      ..._linuxWineEnvironmentWithRuntime(
        bottle: bottle,
        environment: environment,
      ),
    },
    logPath: _joinPath(bottle.path, const ['logs', 'latest.log']),
  );
}

ProgramRunRequest _linuxWineCommandRequest({
  required BottleRecord bottle,
  required String command,
  required Map<String, String> environment,
}) {
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: command,
    runnerKind: 'wine',
    executable: _linuxWineExecutable(environment),
    arguments: <String>[command],
    environment: <String, String>{
      ..._linuxRuntimeEnvironment(environment),
      ..._linuxWineEnvironmentWithRuntime(
        bottle: bottle,
        environment: environment,
      ),
    },
    logPath: _joinPath(bottle.path, const ['logs', 'latest.log']),
  );
}

ProgramRunRequest _linuxRegistryUpdateRequest({
  required BottleRecord bottle,
  required _RegistryValueUpdate update,
  required Map<String, String> environment,
}) {
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: 'reg',
    runnerKind: 'wineRegistry',
    executable: _linuxWineExecutable(environment),
    arguments: _registryUpdateArguments(update),
    environment: <String, String>{
      ..._linuxRuntimeEnvironment(environment),
      ..._linuxWineEnvironmentWithRuntime(
        bottle: bottle,
        environment: environment,
      ),
    },
    logPath: _joinPath(bottle.path, const ['logs', 'latest.log']),
  );
}

ProgramRunRequest _linuxRegistryQueryRequest({
  required BottleRecord bottle,
  required _RegistryValueQuery query,
  required Map<String, String> environment,
}) {
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: 'reg',
    runnerKind: 'wineRegistryQuery',
    executable: _linuxWineExecutable(environment),
    arguments: _registryQueryArguments(query),
    environment: <String, String>{
      ..._linuxRuntimeEnvironment(environment),
      ..._linuxWineEnvironmentWithRuntime(
        bottle: bottle,
        environment: environment,
      ),
    },
    logPath: _joinPath(bottle.path, const ['logs', 'registry.log']),
  );
}

ProgramRunRequest _linuxWinebootRequest({
  required BottleRecord bottle,
  required Map<String, String> environment,
}) {
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: 'wineboot',
    runnerKind: 'wineboot',
    executable: _linuxWinebootExecutable(environment),
    arguments: const <String>['--init'],
    environment: <String, String>{
      ..._linuxRuntimeEnvironment(environment),
      ..._linuxWineEnvironmentWithRuntime(
        bottle: bottle,
        environment: environment,
      ),
    },
    logPath: _joinPath(bottle.path, const ['logs', 'prefix-init.log']),
  );
}

ProgramRunRequest _linuxWineserverKillRequest({
  required BottleRecord bottle,
  required Map<String, String> environment,
}) {
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: 'wineserver',
    runnerKind: 'wineserver',
    executable: _linuxWineserverExecutable(environment),
    arguments: const <String>['-k'],
    environment: <String, String>{
      ..._linuxRuntimeEnvironment(environment),
      ..._linuxWinePrefixEnvironment(bottle),
    },
    logPath: _joinPath(bottle.path, const ['logs', 'wineserver-kill.log']),
  );
}

ProgramRunRequest _linuxWinedbgRequest({
  required BottleRecord bottle,
  required Map<String, String> environment,
  required String command,
  required String logName,
  List<String> trailingArguments = const <String>[],
}) {
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: 'winedbg',
    runnerKind: 'winedbg',
    executable: _linuxWinedbgExecutable(environment),
    arguments: <String>['--command', command, ...trailingArguments],
    environment: <String, String>{
      ..._linuxRuntimeEnvironment(environment),
      ..._linuxWinePrefixEnvironment(bottle),
    },
    logPath: _joinPath(bottle.path, <String>['logs', logName]),
  );
}

ProgramRunRequest _macosWineRequest({
  required BottleRecord bottle,
  required String programPath,
  required Map<String, String> environment,
  required ProgramSettingsRecord programSettings,
}) {
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: programPath,
    runnerKind: 'macosWine',
    executable: _macosWineExecutable(environment),
    arguments: <String>[
      'start',
      '/unix',
      programPath,
      ..._programSettingsArguments(programSettings),
    ],
    environment: <String, String>{
      ..._macosWineEnvironment(bottle: bottle, environment: environment),
      ..._programSettingsEnvironment(programSettings),
      'WINEPREFIX': bottle.path,
    },
    logPath: _joinPath(bottle.path, const ['logs', 'latest.log']),
    workingDirectory: _macosWineBinFolder(environment),
  );
}

ProgramRunRequest _macosWinebootRequest({
  required BottleRecord bottle,
  required Map<String, String> environment,
}) {
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: 'wineboot',
    runnerKind: 'macosWine',
    executable: _macosWineExecutable(environment),
    arguments: const <String>['wineboot', '--init'],
    environment: _macosWineEnvironment(
      bottle: bottle,
      environment: environment,
    ),
    logPath: _joinPath(bottle.path, const ['logs', 'prefix-init.log']),
    workingDirectory: _macosWineBinFolder(environment),
  );
}

ProgramRunRequest _macosWineserverKillRequest({
  required BottleRecord bottle,
  required Map<String, String> environment,
}) {
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: 'wineserver',
    runnerKind: 'macosWineserver',
    executable: _macosWineserverExecutable(environment),
    arguments: const <String>['-k'],
    environment: _macosWineEnvironment(
      bottle: bottle,
      environment: environment,
    ),
    logPath: _joinPath(bottle.path, const ['logs', 'wineserver-kill.log']),
    workingDirectory: _macosWineBinFolder(environment),
  );
}

ProgramRunRequest _macosWinedbgRequest({
  required BottleRecord bottle,
  required Map<String, String> environment,
  required String command,
  required String logName,
  List<String> trailingArguments = const <String>[],
}) {
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: 'winedbg',
    runnerKind: 'macosWinedbg',
    executable: _macosWineExecutable(environment),
    arguments: <String>['winedbg', '--command', command, ...trailingArguments],
    environment: _macosWineEnvironment(
      bottle: bottle,
      environment: environment,
    ),
    logPath: _joinPath(bottle.path, <String>['logs', logName]),
    workingDirectory: _macosWineBinFolder(environment),
  );
}

Map<String, String> _macosWineEnvironment({
  required BottleRecord bottle,
  required Map<String, String> environment,
}) {
  final wineEnvironment = <String, String>{
    'WINEPREFIX': bottle.path,
    'WINEDEBUG': 'fixme-all',
    'GST_DEBUG': '1',
    'DYLD_LIBRARY_PATH': _prependPath(
      _joinPath(_macosWineRuntimeRoot(environment), const ['lib']),
      environment['DYLD_LIBRARY_PATH'],
    ),
    ...bottle.runtimeSettings.macosEnvironmentVariables(),
  };
  if (bottle.runtimeSettings.dxvk) {
    final runtimeRoot = _macosWineRuntimeRoot(environment);
    wineEnvironment['WINEDLLPATH'] = [
      _joinPath(runtimeRoot, const ['DXVK', 'x64']),
      _joinPath(runtimeRoot, const ['DXVK', 'x32']),
    ].join(':');
  }

  return Map.unmodifiable(wineEnvironment);
}

const _dxvkOverrideDllNames = <String>[
  'dxgi.dll',
  'd3d9.dll',
  'd3d10core.dll',
  'd3d11.dll',
];

void _syncMacosDxvkDllOverrides({
  required BottleRecord bottle,
  required Map<String, String> environment,
}) {
  final runtimeRoot = _macosWineRuntimeRoot(environment);
  for (final arch in const <(String, String)>[
    ('x64', 'system32'),
    ('x32', 'syswow64'),
  ]) {
    final (runtimeArch, windowsDirectory) = arch;
    final destinationDirectory = Directory(
      _joinPath(bottle.path, <String>['drive_c', 'windows', windowsDirectory]),
    )..createSync(recursive: true);

    for (final dllName in _dxvkOverrideDllNames) {
      final sourcePath = _joinPath(runtimeRoot, <String>[
        'DXVK',
        runtimeArch,
        dllName,
      ]);
      final sourceFile = File(sourcePath);
      if (!sourceFile.existsSync()) {
        throw FileSystemException(
          'DXVK override DLL was not found.',
          sourcePath,
        );
      }
      sourceFile.copySync(_joinPath(destinationDirectory.path, [dllName]));
    }
  }
}

Map<String, String> _linuxWineEnvironment(BottleRecord bottle) {
  return <String, String>{
    ..._linuxWinePrefixEnvironment(bottle),
    ...bottle.runtimeSettings.macosEnvironmentVariables(),
  };
}

Map<String, String> _linuxWinePrefixEnvironment(BottleRecord bottle) {
  return <String, String>{'WINEPREFIX': bottle.path};
}

Map<String, String> _linuxWineEnvironmentWithRuntime({
  required BottleRecord bottle,
  required Map<String, String> environment,
}) {
  final wineEnvironment = <String, String>{..._linuxWineEnvironment(bottle)};
  if (bottle.runtimeSettings.dxvk) {
    final runtimeRoot = _linuxWineRuntimeRoot(environment);
    wineEnvironment['WINEDLLPATH'] = [
      _joinPath(runtimeRoot, const ['dxvk', 'x64']),
      _joinPath(runtimeRoot, const ['dxvk', 'x86']),
    ].join(':');
  }

  return Map.unmodifiable(wineEnvironment);
}

ProgramRunRequest _macosWineCommandRequest({
  required BottleRecord bottle,
  required String command,
  required Map<String, String> environment,
}) {
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: command,
    runnerKind: 'macosWine',
    executable: _macosWineExecutable(environment),
    arguments: <String>[command],
    environment: _macosWineEnvironment(
      bottle: bottle,
      environment: environment,
    ),
    logPath: _joinPath(bottle.path, const ['logs', 'latest.log']),
    workingDirectory: _macosWineBinFolder(environment),
  );
}

ProgramRunRequest _macosRegistryUpdateRequest({
  required BottleRecord bottle,
  required _RegistryValueUpdate update,
  required Map<String, String> environment,
}) {
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: 'reg',
    runnerKind: 'macosWineRegistry',
    executable: _macosWineExecutable(environment),
    arguments: _registryUpdateArguments(update),
    environment: _macosWineEnvironment(
      bottle: bottle,
      environment: environment,
    ),
    logPath: _joinPath(bottle.path, const ['logs', 'latest.log']),
    workingDirectory: _macosWineBinFolder(environment),
  );
}

ProgramRunRequest _macosRegistryQueryRequest({
  required BottleRecord bottle,
  required _RegistryValueQuery query,
  required Map<String, String> environment,
}) {
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: 'reg',
    runnerKind: 'macosWineRegistryQuery',
    executable: _macosWineExecutable(environment),
    arguments: _registryQueryArguments(query),
    environment: _macosWineEnvironment(
      bottle: bottle,
      environment: environment,
    ),
    logPath: _joinPath(bottle.path, const ['logs', 'registry.log']),
    workingDirectory: _macosWineBinFolder(environment),
  );
}

ProgramRunRequest _linuxTerminalCommandRequest({
  required BottleRecord bottle,
  required Map<String, String> environment,
}) {
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: 'terminal',
    runnerKind: 'terminal',
    executable: 'sh',
    arguments: <String>[
      '-lc',
      _linuxTerminalLauncherCommand(environment),
      _linuxWineTerminalShellCommandWithEnvironment(
        bottle: bottle,
        environment: environment,
      ),
    ],
    environment: const <String, String>{},
    logPath: _joinPath(bottle.path, const ['logs', 'latest.log']),
    workingDirectory: bottle.path,
  );
}

ProgramRunRequest _macosTerminalCommandRequest({
  required BottleRecord bottle,
  required Map<String, String> environment,
}) {
  final shellCommand = _macosWineTerminalShellCommand(
    bottle: bottle,
    environment: environment,
  );

  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: 'terminal',
    runnerKind: 'macosTerminal',
    executable: '/usr/bin/osascript',
    arguments: <String>['-e', _macosTerminalAppleScript(shellCommand)],
    environment: const <String, String>{},
    logPath: _joinPath(bottle.path, const ['logs', 'latest.log']),
  );
}

ProgramRunRequest _linuxWinetricksCommandRequest({
  required BottleRecord bottle,
  required Map<String, String> environment,
  String? verb,
}) {
  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: verb ?? 'winetricks',
    runnerKind: 'winetricks',
    executable: _linuxWinetricksExecutable(environment),
    arguments: verb == null ? const <String>[] : <String>[verb],
    environment: <String, String>{
      ..._linuxRuntimeEnvironment(environment),
      ..._linuxWineEnvironmentWithRuntime(
        bottle: bottle,
        environment: environment,
      ),
    },
    logPath: _joinPath(bottle.path, const ['logs', 'latest.log']),
  );
}

ProgramRunRequest _macosWinetricksCommandRequest({
  required BottleRecord bottle,
  required Map<String, String> environment,
  required String? verb,
}) {
  final runtimeRoot = _macosWineRuntimeRoot(environment);
  final runtimeBin = _macosWineBinFolder(environment);

  return ProgramRunRequest(
    bottleId: bottle.id,
    programPath: verb ?? 'winetricks',
    runnerKind: 'macosWinetricks',
    executable: _macosWinetricksExecutable(environment),
    arguments: verb == null ? const <String>[] : <String>[verb],
    environment: <String, String>{
      ..._macosWineEnvironment(bottle: bottle, environment: environment),
      'WINE': 'wine64',
      'PATH': _prependPath(runtimeBin, environment['PATH']),
    },
    logPath: _joinPath(bottle.path, const ['logs', 'latest.log']),
    workingDirectory: runtimeRoot,
  );
}

const _linuxWineRuntimeComponentDefinitions =
    <_RuntimeStackComponentDefinition>[
      _RuntimeStackComponentDefinition(
        id: 'wine',
        name: 'Wine',
        role: 'windows-runner',
        isRequired: true,
        relativePaths: <List<String>>[
          <String>['bin', 'wine'],
          <String>['bin', 'winedbg'],
          <String>['bin', 'wineserver'],
        ],
      ),
      _RuntimeStackComponentDefinition(
        id: 'winetricks',
        name: 'winetricks',
        role: 'verb-installer',
        isRequired: true,
        relativePaths: <List<String>>[
          <String>['winetricks'],
        ],
      ),
      _RuntimeStackComponentDefinition(
        id: 'wine-mono',
        name: 'wine-mono',
        role: 'dotnet-runtime',
        isRequired: true,
        relativePaths: <List<String>>[
          <String>['share', 'wine', 'mono'],
        ],
      ),
      _RuntimeStackComponentDefinition(
        id: 'dxvk',
        name: 'DXVK',
        role: 'd3d9-d3d11-vulkan-translation',
        isRequired: true,
        relativePaths: <List<String>>[
          <String>['dxvk', 'x64', 'dxgi.dll'],
          <String>['dxvk', 'x64', 'd3d9.dll'],
          <String>['dxvk', 'x64', 'd3d10core.dll'],
          <String>['dxvk', 'x64', 'd3d11.dll'],
          <String>['dxvk', 'x86', 'dxgi.dll'],
          <String>['dxvk', 'x86', 'd3d9.dll'],
          <String>['dxvk', 'x86', 'd3d10core.dll'],
          <String>['dxvk', 'x86', 'd3d11.dll'],
        ],
      ),
      _RuntimeStackComponentDefinition(
        id: 'vkd3d-proton',
        name: 'vkd3d-proton',
        role: 'd3d12-vulkan-translation',
        isRequired: true,
        relativePaths: <List<String>>[
          <String>['vkd3d-proton', 'x64', 'd3d12.dll'],
          <String>['vkd3d-proton', 'x86', 'd3d12.dll'],
        ],
      ),
    ];

const _macosKonyakRuntimeComponentDefinitions =
    <_RuntimeStackComponentDefinition>[
      _RuntimeStackComponentDefinition(
        id: 'wine',
        name: 'Wine',
        role: 'windows-runner',
        isRequired: true,
        relativePaths: <List<String>>[
          <String>['bin', 'wine64'],
          <String>['bin', 'wineserver'],
        ],
      ),
      _RuntimeStackComponentDefinition(
        id: 'wine32on64',
        name: 'Wine32-on-64 support',
        role: '32-bit-windows-support',
        isRequired: true,
        relativePaths: <List<String>>[
          <String>['bin', 'wine'],
        ],
      ),
      _RuntimeStackComponentDefinition(
        id: 'dxvk-macos',
        name: 'DXVK-macOS',
        role: 'd3d9-d3d11-translation',
        isRequired: true,
        relativePaths: <List<String>>[
          <String>['DXVK', 'x64', 'dxgi.dll'],
          <String>['DXVK', 'x64', 'd3d9.dll'],
          <String>['DXVK', 'x64', 'd3d10core.dll'],
          <String>['DXVK', 'x64', 'd3d11.dll'],
          <String>['DXVK', 'x32', 'dxgi.dll'],
          <String>['DXVK', 'x32', 'd3d9.dll'],
          <String>['DXVK', 'x32', 'd3d10core.dll'],
          <String>['DXVK', 'x32', 'd3d11.dll'],
        ],
      ),
      _RuntimeStackComponentDefinition(
        id: 'moltenvk',
        name: 'MoltenVK',
        role: 'vulkan-metal-translation',
        isRequired: true,
        relativePaths: <List<String>>[
          <String>['lib', 'libMoltenVK.dylib'],
        ],
      ),
      _RuntimeStackComponentDefinition(
        id: 'gstreamer',
        name: 'GStreamer runtime',
        role: 'media-runtime',
        isRequired: true,
        relativePaths: <List<String>>[
          <String>['lib', 'libgstreamer-1.0.0.dylib'],
        ],
      ),
      _RuntimeStackComponentDefinition(
        id: 'wine-mono',
        name: 'wine-mono',
        role: 'dotnet-runtime',
        isRequired: true,
        relativePaths: <List<String>>[
          <String>['share', 'wine', 'mono'],
        ],
      ),
      _RuntimeStackComponentDefinition(
        id: 'winetricks',
        name: 'winetricks',
        role: 'verb-installer',
        isRequired: true,
        relativePaths: <List<String>>[
          <String>['winetricks'],
        ],
      ),
      _RuntimeStackComponentDefinition(
        id: 'gptk-d3dmetal',
        name: 'GPTK/D3DMetal',
        role: 'd3d12-metal-translation',
        isRequired: false,
        relativePaths: <List<String>>[
          <String>['lib', 'external', 'D3DMetal.framework'],
          <String>['lib', 'external', 'libd3dshared.dylib'],
          <String>['lib', 'wine', 'x86_64-windows', 'd3d12.dll'],
          <String>['lib', 'wine', 'x86_64-windows', 'dxgi.dll'],
        ],
      ),
    ];

const _linuxWineRuntimePlatformSpec = _RuntimePlatformSpec(
  runtimeId: linuxWineRuntimeId,
  runtimeName: 'Konyak Linux Wine',
  platform: 'linux',
  architecture: 'x86_64',
  runnerKind: 'wine',
  stackId: 'linux-wine-runtime-stack',
  stackName: 'Linux Wine/Proton runtime stack',
  requiredExecutableRelativePath: <String>['bin', 'wine'],
  defaultArchiveFileName: 'linux-wine.tar.xz',
  archiveUrlEnvironmentKey: 'KONYAK_LINUX_WINE_ARCHIVE_URL',
  developmentSourceManifestEnvironmentKey:
      'KONYAK_DEV_LINUX_WINE_STACK_MANIFEST',
  releaseSourceManifestEnvironmentKey: 'KONYAK_LINUX_WINE_STACK_MANIFEST',
  developmentSourceSignatureEnvironmentKey:
      'KONYAK_DEV_LINUX_WINE_STACK_SIGNATURE_URL',
  releaseSourceSignatureEnvironmentKey: 'KONYAK_LINUX_WINE_STACK_SIGNATURE_URL',
  componentDefinitions: _linuxWineRuntimeComponentDefinitions,
);

const _macosKonyakRuntimePlatformSpec = _RuntimePlatformSpec(
  runtimeId: macosWineRuntimeId,
  runtimeName: 'Konyak macOS Wine',
  platform: 'macos',
  architecture: 'x86_64',
  runnerKind: 'macosWine',
  stackId: 'macos-konyak-runtime-stack',
  stackName: 'Konyak macOS runtime stack',
  requiredExecutableRelativePath: <String>['bin', 'wine64'],
  defaultArchiveUrl: macosWineArchiveUrl,
  defaultArchiveFileName: macosWineArchiveFileName,
  developmentSourceManifestEnvironmentKey:
      'KONYAK_DEV_MACOS_WINE_STACK_MANIFEST',
  releaseSourceManifestEnvironmentKey: 'KONYAK_MACOS_WINE_STACK_MANIFEST',
  developmentSourceSignatureEnvironmentKey:
      'KONYAK_DEV_MACOS_WINE_STACK_SIGNATURE_URL',
  releaseSourceSignatureEnvironmentKey: 'KONYAK_MACOS_WINE_STACK_SIGNATURE_URL',
  layoutNormalization: _RuntimeLayoutNormalization.macosWineBundle,
  componentDefinitions: _macosKonyakRuntimeComponentDefinitions,
);

String? _runtimeSourceManifestForPlatform({
  required _RuntimePlatformSpec platformSpec,
  required Map<String, String> environment,
}) {
  return _runtimeProfileEnvironmentValue(
    environment,
    developmentKey: platformSpec.developmentSourceManifestEnvironmentKey,
    releaseKey: platformSpec.releaseSourceManifestEnvironmentKey,
  );
}

String? _runtimeSourceManifestSignatureForPlatform({
  required _RuntimePlatformSpec platformSpec,
  required Map<String, String> environment,
}) {
  return _runtimeProfileEnvironmentValue(
    environment,
    developmentKey: platformSpec.developmentSourceSignatureEnvironmentKey,
    releaseKey: platformSpec.releaseSourceSignatureEnvironmentKey,
  );
}

String? _runtimeDefaultArchiveUrl({
  required _RuntimePlatformSpec platformSpec,
  required Map<String, String> environment,
}) {
  final archiveUrlEnvironmentKey = platformSpec.archiveUrlEnvironmentKey;
  if (archiveUrlEnvironmentKey != null) {
    return _nonEmptyEnvironmentValue(environment, archiveUrlEnvironmentKey);
  }

  return platformSpec.defaultArchiveUrl;
}

RuntimeRecord _macosWineRuntimeRecord({
  required Map<String, String> environment,
  required FileStatusProbe fileStatusProbe,
  required RuntimeStackVersionProbe runtimeStackVersionProbe,
}) {
  const platformSpec = _macosKonyakRuntimePlatformSpec;
  final applicationSupportPath = _konyakApplicationSupportFolder(environment);
  final libraryPath = _macosWineRuntimeRoot(environment);
  final executablePath = _macosWineExecutable(environment);
  final isInstalled = fileStatusProbe.exists(executablePath);

  return RuntimeRecord.fromParts(
    definition: RuntimeDefinition(
      id: platformSpec.runtimeId,
      name: platformSpec.runtimeName,
      platform: platformSpec.platform,
      architecture: platformSpec.architecture,
      runnerKind: platformSpec.runnerKind,
      isBundled: false,
      isUpdateable: true,
      distributionKind: _runtimeDistributionKind(environment, 'bootstrap'),
      archiveUrl: platformSpec.defaultArchiveUrl,
      versionUrl: macosWineVersionUrl,
    ),
    installedState: InstalledRuntimeState(
      isInstalled: isInstalled,
      applicationSupportPath: applicationSupportPath,
      libraryPath: libraryPath,
      executablePath: executablePath,
    ),
    capabilities: RuntimeCapabilities(
      stack: _runtimeStackForPlatform(
        platformSpec: platformSpec,
        runtimeRoot: libraryPath,
        fileStatusProbe: fileStatusProbe,
        runtimeStackVersionProbe: runtimeStackVersionProbe,
      ),
    ),
  );
}

RuntimeRecord _linuxWineRuntimeRecord({
  required Map<String, String> environment,
  required FileStatusProbe fileStatusProbe,
  required RuntimeStackVersionProbe runtimeStackVersionProbe,
}) {
  const platformSpec = _linuxWineRuntimePlatformSpec;
  final runtimeRoot = _linuxWineRuntimeRoot(environment);
  final executablePath = _joinPath(runtimeRoot, const ['bin', 'wine']);
  final archiveUrl = _runtimeDefaultArchiveUrl(
    platformSpec: platformSpec,
    environment: environment,
  );
  final versionUrl = _nonEmptyEnvironmentValue(
    environment,
    'KONYAK_LINUX_WINE_VERSION_URL',
  );
  return RuntimeRecord.fromParts(
    definition: RuntimeDefinition(
      id: platformSpec.runtimeId,
      name: platformSpec.runtimeName,
      platform: platformSpec.platform,
      architecture: platformSpec.architecture,
      runnerKind: platformSpec.runnerKind,
      isBundled: false,
      isUpdateable: archiveUrl != null || versionUrl != null,
      distributionKind: _runtimeDistributionKind(environment, 'managed'),
      archiveUrl: archiveUrl,
      versionUrl: versionUrl,
    ),
    installedState: InstalledRuntimeState(
      isInstalled: fileStatusProbe.exists(executablePath),
      libraryPath: runtimeRoot,
      executablePath: executablePath,
    ),
    capabilities: RuntimeCapabilities(
      stack: _runtimeStackForPlatform(
        platformSpec: platformSpec,
        runtimeRoot: runtimeRoot,
        fileStatusProbe: fileStatusProbe,
        runtimeStackVersionProbe: runtimeStackVersionProbe,
      ),
    ),
  );
}

RuntimeStack _runtimeStackForPlatform({
  required _RuntimePlatformSpec platformSpec,
  required String runtimeRoot,
  required FileStatusProbe fileStatusProbe,
  required RuntimeStackVersionProbe runtimeStackVersionProbe,
}) {
  return RuntimeStack(
    id: platformSpec.stackId,
    name: platformSpec.stackName,
    compatibilityTarget: platformSpec.stackId,
    components: platformSpec.componentDefinitions
        .map(
          (definition) => _runtimeStackComponent(
            runtimeRoot: runtimeRoot,
            fileStatusProbe: fileStatusProbe,
            runtimeStackVersionProbe: runtimeStackVersionProbe,
            definition: definition,
          ),
        )
        .toList(growable: false),
  );
}

RuntimeStackComponent _runtimeStackComponent({
  required String runtimeRoot,
  required FileStatusProbe fileStatusProbe,
  required RuntimeStackVersionProbe runtimeStackVersionProbe,
  required _RuntimeStackComponentDefinition definition,
}) {
  final paths = definition.relativePaths
      .map((pathSegments) => _joinPath(runtimeRoot, pathSegments))
      .toList(growable: false);
  final missingPaths = paths
      .where((path) => !fileStatusProbe.exists(path))
      .toList();
  if (definition.id == 'gptk-d3dmetal') {
    final frameworkBinary = _d3dMetalFrameworkBinary(paths.first);
    if (frameworkBinary == null || !_looksLikeMachO(File(frameworkBinary))) {
      if (!missingPaths.contains(paths.first)) {
        missingPaths.add(paths.first);
      }
    }
    if (!_looksLikeMachO(File(paths[1]))) {
      if (!missingPaths.contains(paths[1])) {
        missingPaths.add(paths[1]);
      }
    }
  }

  return RuntimeStackComponent(
    id: definition.id,
    name: definition.name,
    role: definition.role,
    isRequired: definition.isRequired,
    paths: paths,
    missingPaths: missingPaths,
    version: missingPaths.isEmpty
        ? runtimeStackVersionProbe.versionFor(
            runtimeRoot: runtimeRoot,
            componentId: definition.id,
          )
        : null,
  );
}

RuntimeSourceManifest? _runtimeStackSourceManifestFromPayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException {
    return null;
  }

  if (decoded is! Map<String, dynamic> ||
      decoded['schemaVersion'] != runtimeStackSchemaVersion) {
    return null;
  }

  final runtimeId = decoded['runtimeId'];
  final stackId = decoded['stackId'];
  final components = decoded['components'];
  if (runtimeId is! String ||
      runtimeId.trim().isEmpty ||
      stackId is! String ||
      stackId.trim().isEmpty ||
      components is! List<dynamic>) {
    return null;
  }

  final parsedComponents = <RuntimeSourceComponent>[];
  for (final component in components) {
    final parsedComponent = _runtimeStackSourceComponent(component);
    if (parsedComponent == null) {
      return null;
    }
    parsedComponents.add(parsedComponent);
  }

  if (parsedComponents.isEmpty) {
    return null;
  }

  return RuntimeSourceManifest(
    runtimeId: runtimeId,
    stackId: stackId,
    components: parsedComponents,
  );
}

RuntimeSourceComponent? _runtimeStackSourceComponent(Object? value) {
  if (value is! Map<String, dynamic>) {
    return null;
  }

  final id = value['id'];
  final version = value['version'];
  final archiveUrl = value['archiveUrl'];
  final sha256 = value['sha256'];

  if (id is! String ||
      id.trim().isEmpty ||
      version is! String ||
      version.trim().isEmpty ||
      archiveUrl is! String ||
      archiveUrl.trim().isEmpty ||
      sha256 is! String ||
      !_isSha256Hex(sha256)) {
    return null;
  }

  return RuntimeSourceComponent(
    id: id,
    version: version,
    archiveUrl: archiveUrl,
    sha256: sha256,
  );
}

_RuntimeStackSourceArchiveBundleResult _resolveRuntimeStackSourceArchiveBundle({
  required RuntimeSourceManifest manifest,
  required _RuntimePlatformSpec platformSpec,
  required Directory tempDirectory,
  required RuntimeInstallProgressSink? progressSink,
}) {
  if (manifest.runtimeId != platformSpec.runtimeId ||
      manifest.stackId != platformSpec.stackId) {
    return const _RuntimeStackSourceArchiveBundleFailed(
      'Runtime stack source manifest targets an unsupported runtime.',
    );
  }

  final wineComponent = manifest.componentById('wine');
  if (wineComponent == null) {
    return const _RuntimeStackSourceArchiveBundleFailed(
      'Runtime stack source manifest does not contain a Wine component.',
    );
  }

  final archivePaths = <String, String>{};
  final componentCount = manifest.components.length;
  for (final component in manifest.components) {
    final fileName =
        _fileNameFromUrl(component.archiveUrl) ?? '${component.id}.tar.xz';
    final archivePath = _joinPath(tempDirectory.path, [
      '${archivePaths.length}-$fileName',
    ]);
    final componentIndex = archivePaths.length;
    final startFraction = 0.05 + (componentIndex / componentCount) * 0.55;
    final endFraction = 0.05 + ((componentIndex + 1) / componentCount) * 0.55;
    final downloadFailure = _downloadRuntimeStackSourceArchive(
      source: component.archiveUrl,
      targetPath: archivePath,
      progressSink: progressSink,
      stage: 'downloading',
      message: 'Downloading ${component.id}...',
      startFraction: startFraction,
      endFraction: endFraction,
    );
    if (downloadFailure != null) {
      return _RuntimeStackSourceArchiveBundleFailed(downloadFailure);
    }

    _emitRuntimeInstallProgress(
      progressSink,
      stage: 'verifying',
      message: 'Verifying ${component.id}...',
      fraction: endFraction,
    );
    final actualSha256 = _sha256HexDigest(File(archivePath));
    if (actualSha256.toLowerCase() != component.sha256.toLowerCase()) {
      return _RuntimeStackSourceArchiveBundleFailed(
        'Runtime stack component `${component.id}` checksum mismatch: '
        'expected ${component.sha256}, got $actualSha256.',
      );
    }

    archivePaths[component.id] = archivePath;
  }

  final wineArchivePath = archivePaths[wineComponent.id];
  if (wineArchivePath == null) {
    return const _RuntimeStackSourceArchiveBundleFailed(
      'Runtime stack source manifest did not resolve a Wine archive.',
    );
  }

  return _RuntimeStackSourceArchiveBundleResolved(
    _RuntimeStackSourceArchiveBundle(
      wineArchivePath: wineArchivePath,
      componentArchivePaths: <String>[
        for (final component in manifest.components)
          if (component.id != wineComponent.id) archivePaths[component.id]!,
      ],
      componentVersions: <String, String>{
        for (final component in manifest.components)
          component.id: component.version,
      },
    ),
  );
}

Future<_RuntimeStackSourceArchiveBundleResult>
_resolveRuntimeStackSourceArchiveBundleStreaming({
  required RuntimeSourceManifest manifest,
  required _RuntimePlatformSpec platformSpec,
  required Directory tempDirectory,
  required RuntimeInstallProgressSink? progressSink,
}) async {
  if (manifest.runtimeId != platformSpec.runtimeId ||
      manifest.stackId != platformSpec.stackId) {
    return const _RuntimeStackSourceArchiveBundleFailed(
      'Runtime stack source manifest targets an unsupported runtime.',
    );
  }

  final wineComponent = manifest.componentById('wine');
  if (wineComponent == null) {
    return const _RuntimeStackSourceArchiveBundleFailed(
      'Runtime stack source manifest does not contain a Wine component.',
    );
  }

  final archivePaths = <String, String>{};
  final componentCount = manifest.components.length;
  for (final component in manifest.components) {
    final fileName =
        _fileNameFromUrl(component.archiveUrl) ?? '${component.id}.tar.xz';
    final archivePath = _joinPath(tempDirectory.path, [
      '${archivePaths.length}-$fileName',
    ]);
    final componentIndex = archivePaths.length;
    final startFraction = 0.05 + (componentIndex / componentCount) * 0.55;
    final endFraction = 0.05 + ((componentIndex + 1) / componentCount) * 0.55;
    final downloadFailure = await _downloadRuntimeStackSourceArchiveStreaming(
      source: component.archiveUrl,
      targetPath: archivePath,
      progressSink: progressSink,
      stage: 'downloading',
      message: 'Downloading ${component.id}...',
      startFraction: startFraction,
      endFraction: endFraction,
    );
    if (downloadFailure != null) {
      return _RuntimeStackSourceArchiveBundleFailed(downloadFailure);
    }

    _emitRuntimeInstallProgress(
      progressSink,
      stage: 'verifying',
      message: 'Verifying ${component.id}...',
      fraction: endFraction,
    );
    final actualSha256 = _sha256HexDigest(File(archivePath));
    if (actualSha256.toLowerCase() != component.sha256.toLowerCase()) {
      return _RuntimeStackSourceArchiveBundleFailed(
        'Runtime stack component `${component.id}` checksum mismatch: '
        'expected ${component.sha256}, got $actualSha256.',
      );
    }

    archivePaths[component.id] = archivePath;
  }

  final wineArchivePath = archivePaths[wineComponent.id];
  if (wineArchivePath == null) {
    return const _RuntimeStackSourceArchiveBundleFailed(
      'Runtime stack source manifest did not resolve a Wine archive.',
    );
  }

  return _RuntimeStackSourceArchiveBundleResolved(
    _RuntimeStackSourceArchiveBundle(
      wineArchivePath: wineArchivePath,
      componentArchivePaths: <String>[
        for (final component in manifest.components)
          if (component.id != wineComponent.id) archivePaths[component.id]!,
      ],
      componentVersions: <String, String>{
        for (final component in manifest.components)
          component.id: component.version,
      },
    ),
  );
}

String? _downloadRuntimeStackSourceArchive({
  required String source,
  required String targetPath,
  required RuntimeInstallProgressSink? progressSink,
  required String stage,
  required String message,
  required double startFraction,
  required double endFraction,
}) {
  final localPath = _localSourcePath(source);
  if (localPath != null) {
    _emitRuntimeInstallProgress(
      progressSink,
      stage: stage,
      message: message,
      fraction: startFraction,
    );
    File(targetPath).parent.createSync(recursive: true);
    File(localPath).copySync(targetPath);
    _emitRuntimeInstallProgress(
      progressSink,
      stage: stage,
      message: message,
      fraction: endFraction,
    );
    return null;
  }

  _emitRuntimeInstallProgress(
    progressSink,
    stage: stage,
    message: message,
    fraction: startFraction,
  );
  final result = Process.runSync('curl', [
    '--fail',
    '--location',
    '--output',
    targetPath,
    source,
  ], runInShell: false);
  if (result.exitCode != 0) {
    return _commandFailureMessage('download runtime stack component', result);
  }
  _emitRuntimeInstallProgress(
    progressSink,
    stage: stage,
    message: message,
    fraction: endFraction,
  );
  return null;
}

Future<String?> _downloadRuntimeStackSourceArchiveStreaming({
  required String source,
  required String targetPath,
  required RuntimeInstallProgressSink? progressSink,
  required String stage,
  required String message,
  required double startFraction,
  required double endFraction,
}) {
  final localPath = _localSourcePath(source);
  if (localPath != null) {
    return _copyRuntimeStackSourceArchiveStreaming(
      sourcePath: localPath,
      targetPath: targetPath,
      progressSink: progressSink,
      stage: stage,
      message: message,
      startFraction: startFraction,
      endFraction: endFraction,
    );
  }

  return _downloadRuntimeStackSourceUriStreaming(
    source: source,
    targetPath: targetPath,
    progressSink: progressSink,
    stage: stage,
    message: message,
    startFraction: startFraction,
    endFraction: endFraction,
  );
}

Future<String?> _copyRuntimeStackSourceArchiveStreaming({
  required String sourcePath,
  required String targetPath,
  required RuntimeInstallProgressSink? progressSink,
  required String stage,
  required String message,
  required double startFraction,
  required double endFraction,
}) async {
  try {
    final source = File(sourcePath);
    final totalBytes = await source.length();
    var copiedBytes = 0;
    File(targetPath).parent.createSync(recursive: true);
    final sink = File(targetPath).openWrite();

    _emitRuntimeInstallProgress(
      progressSink,
      stage: stage,
      message: message,
      fraction: startFraction,
    );
    try {
      await for (final chunk in source.openRead()) {
        copiedBytes += chunk.length;
        sink.add(chunk);
        _emitRuntimeInstallByteProgress(
          progressSink,
          stage: stage,
          message: message,
          copiedBytes: copiedBytes,
          totalBytes: totalBytes,
          startFraction: startFraction,
          endFraction: endFraction,
        );
      }
    } finally {
      await sink.close();
    }

    _emitRuntimeInstallProgress(
      progressSink,
      stage: stage,
      message: message,
      fraction: endFraction,
    );
    return null;
  } on FileSystemException catch (error) {
    return error.message;
  }
}

Future<String?> _downloadRuntimeStackSourceUriStreaming({
  required String source,
  required String targetPath,
  required RuntimeInstallProgressSink? progressSink,
  required String stage,
  required String message,
  required double startFraction,
  required double endFraction,
}) async {
  final uri = Uri.tryParse(source);
  if (uri == null || !uri.hasScheme) {
    return 'Runtime stack component URL is invalid: $source';
  }

  final client = HttpClient();
  try {
    _emitRuntimeInstallProgress(
      progressSink,
      stage: stage,
      message: message,
      fraction: startFraction,
    );

    final request = await client.getUrl(uri);
    request.headers.set(
      HttpHeaders.userAgentHeader,
      'Konyak/$konyakAppVersion',
    );
    final response = await request.close();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return 'download runtime stack component failed with HTTP status '
          '${response.statusCode}.';
    }

    final totalBytes = response.contentLength;
    var receivedBytes = 0;
    File(targetPath).parent.createSync(recursive: true);
    final sink = File(targetPath).openWrite();
    try {
      await for (final chunk in response) {
        receivedBytes += chunk.length;
        sink.add(chunk);
        _emitRuntimeInstallByteProgress(
          progressSink,
          stage: stage,
          message: message,
          copiedBytes: receivedBytes,
          totalBytes: totalBytes,
          startFraction: startFraction,
          endFraction: endFraction,
        );
      }
    } finally {
      await sink.close();
    }

    _emitRuntimeInstallProgress(
      progressSink,
      stage: stage,
      message: message,
      fraction: endFraction,
    );
    return null;
  } on HttpException catch (error) {
    return error.message;
  } on IOException catch (error) {
    return error.toString();
  } finally {
    client.close(force: true);
  }
}

void _emitRuntimeInstallByteProgress(
  RuntimeInstallProgressSink? progressSink, {
  required String stage,
  required String message,
  required int copiedBytes,
  required int totalBytes,
  required double startFraction,
  required double endFraction,
}) {
  if (totalBytes <= 0) {
    return;
  }

  final byteFraction = copiedBytes / totalBytes;
  _emitRuntimeInstallProgress(
    progressSink,
    stage: stage,
    message: message,
    fraction: startFraction + (endFraction - startFraction) * byteFraction,
  );
}

void _emitRuntimeInstallProgress(
  RuntimeInstallProgressSink? progressSink, {
  required String stage,
  required String message,
  required double fraction,
}) {
  final normalizedFraction = fraction.clamp(0, 1).toDouble();
  progressSink?.emit(
    RuntimeInstallProgress(
      stage: stage,
      message: message,
      fraction: normalizedFraction,
    ),
  );
}

String? _runtimeStackComponentVersion(Object? decoded, String componentId) {
  final components = _runtimeStackComponentVersions(decoded);
  return components[componentId];
}

Map<String, String> _runtimeStackComponentVersions(Object? decoded) {
  if (decoded is! Map<String, dynamic>) {
    return const <String, String>{};
  }
  if (decoded['schemaVersion'] != runtimeStackSchemaVersion) {
    return const <String, String>{};
  }

  final components = decoded['components'];
  if (components is! Map<String, dynamic>) {
    return const <String, String>{};
  }

  final versions = <String, String>{};
  for (final entry in components.entries) {
    final version = entry.value;
    if (version is String && version.isNotEmpty) {
      versions[entry.key] = version;
    }
  }

  return Map.unmodifiable(versions);
}

String? _installRuntimeArchives({
  required String runtimeLabel,
  required String archivePath,
  required String? archiveSha256,
  required List<String> componentArchivePaths,
  required Map<String, String> componentVersions,
  required Directory runtimeRoot,
  required List<String> requiredExecutableRelativePath,
  required String expectedExecutablePath,
  required bool preserveExistingRuntimeFiles,
  void Function(Directory runtimeRoot)? normalizeStagingRoot,
  void Function(Directory runtimeRoot)? afterManifestWrite,
  RuntimeInstallProgressSink? progressSink,
}) {
  final expectedSha256 = archiveSha256;
  if (expectedSha256 != null) {
    _emitRuntimeInstallProgress(
      progressSink,
      stage: 'verifying',
      message: 'Verifying $runtimeLabel archive...',
      fraction: 0.62,
    );
    try {
      final archive = File(archivePath);
      if (!archive.existsSync()) {
        return '$runtimeLabel archive `$archivePath` was not found.';
      }
      final actualSha256 = _sha256HexDigest(archive);
      if (actualSha256.toLowerCase() != expectedSha256.toLowerCase()) {
        return '$runtimeLabel archive checksum mismatch: expected '
            '$expectedSha256, got $actualSha256.';
      }
    } on FileSystemException catch (error) {
      return error.message;
    }
  }

  final stagingRoot = Directory(
    _runtimeSiblingPathForInstall(runtimeRoot, 'install'),
  );
  final backupRoot = Directory(
    _runtimeSiblingPathForInstall(runtimeRoot, 'previous'),
  );
  final lockFile = File(_runtimeInstallLockPath(runtimeRoot));
  final resolvedComponentVersions = <String, String>{...componentVersions};
  final archivePaths = <String>[archivePath, ...componentArchivePaths];
  var lockCreated = false;

  try {
    runtimeRoot.parent.createSync(recursive: true);
    try {
      lockFile.createSync(exclusive: true);
      lockCreated = true;
    } on FileSystemException {
      return '$runtimeLabel installation is already running.';
    }
    if (stagingRoot.existsSync()) {
      stagingRoot.deleteSync(recursive: true);
    }
    stagingRoot.createSync(recursive: true);

    for (var index = 0; index < archivePaths.length; index += 1) {
      final currentArchivePath = archivePaths[index];
      final archive = File(currentArchivePath);
      if (!archive.existsSync()) {
        return '$runtimeLabel archive `$currentArchivePath` was not found.';
      }

      final startFraction = 0.65 + (index / archivePaths.length) * 0.25;
      final endFraction = 0.65 + ((index + 1) / archivePaths.length) * 0.25;
      _emitRuntimeInstallProgress(
        progressSink,
        stage: 'extracting',
        message: 'Extracting ${_basename(currentArchivePath)}...',
        fraction: startFraction,
      );
      final extraction = Process.runSync('tar', [
        '-xf',
        currentArchivePath,
        '-C',
        stagingRoot.path,
        '--strip-components',
        '1',
      ], runInShell: false);
      if (extraction.exitCode != 0) {
        return _commandFailureMessage('extract $runtimeLabel', extraction);
      }

      _mergeRuntimeStackManifest(
        runtimeRoot: stagingRoot,
        componentVersions: resolvedComponentVersions,
      );
      _emitRuntimeInstallProgress(
        progressSink,
        stage: 'extracting',
        message: 'Extracted ${_basename(currentArchivePath)}.',
        fraction: endFraction,
      );
    }

    _emitRuntimeInstallProgress(
      progressSink,
      stage: 'finalizing',
      message: 'Finalizing $runtimeLabel install...',
      fraction: 0.92,
    );
    normalizeStagingRoot?.call(stagingRoot);
    if (preserveExistingRuntimeFiles && runtimeRoot.existsSync()) {
      _copyDirectoryContentsReplacing(
        source: runtimeRoot,
        destination: stagingRoot,
      );
      _mergeRuntimeStackManifest(
        runtimeRoot: runtimeRoot,
        componentVersions: resolvedComponentVersions,
      );
    }
    _writeRuntimeStackManifest(
      runtimeRoot: stagingRoot,
      componentVersions: resolvedComponentVersions,
    );
    afterManifestWrite?.call(stagingRoot);

    final stagedExecutable = File(
      _joinPath(stagingRoot.path, requiredExecutableRelativePath),
    );
    if (!stagedExecutable.existsSync()) {
      return '$runtimeLabel archive did not install `$expectedExecutablePath`.';
    }

    _replaceRuntimeRootInPlace(
      runtimeRoot: runtimeRoot,
      stagingRoot: stagingRoot,
      backupRoot: backupRoot,
    );
    _emitRuntimeInstallProgress(
      progressSink,
      stage: 'finalizing',
      message: 'Installed $runtimeLabel files.',
      fraction: 0.98,
    );
  } on ProcessException catch (error) {
    return error.message;
  } on FileSystemException catch (error) {
    return error.message;
  } finally {
    if (stagingRoot.existsSync()) {
      stagingRoot.deleteSync(recursive: true);
    }
    if (backupRoot.existsSync()) {
      backupRoot.deleteSync(recursive: true);
    }
    if (lockCreated && lockFile.existsSync()) {
      lockFile.deleteSync();
    }
  }

  return null;
}

String _runtimeInstallLockPath(Directory runtimeRoot) {
  return '${runtimeRoot.path}.install.lock';
}

void _mergeRuntimeStackManifest({
  required Directory runtimeRoot,
  required Map<String, String> componentVersions,
}) {
  final manifest = File(
    _joinPath(runtimeRoot.path, const [runtimeStackManifestFileName]),
  );
  if (!manifest.existsSync()) {
    return;
  }

  try {
    componentVersions.addAll(
      _runtimeStackComponentVersions(jsonDecode(manifest.readAsStringSync())),
    );
  } on FileSystemException {
    return;
  } on FormatException {
    return;
  }
}

void _writeRuntimeStackManifest({
  required Directory runtimeRoot,
  required Map<String, String> componentVersions,
}) {
  if (componentVersions.isEmpty) {
    return;
  }

  final manifest = File(
    _joinPath(runtimeRoot.path, const [runtimeStackManifestFileName]),
  );
  manifest.writeAsStringSync(
    jsonEncode(<String, Object?>{
      'schemaVersion': runtimeStackSchemaVersion,
      'components': componentVersions,
    }),
  );
}

void _upsertRuntimeStackComponentVersion({
  required Directory runtimeRoot,
  required String componentId,
  required String version,
}) {
  final componentVersions = <String, String>{};
  _mergeRuntimeStackManifest(
    runtimeRoot: runtimeRoot,
    componentVersions: componentVersions,
  );
  componentVersions[componentId] = version;
  _writeRuntimeStackManifest(
    runtimeRoot: runtimeRoot,
    componentVersions: componentVersions,
  );
}

Directory? _resolveGptkWineRoot(String sourcePath) {
  final sourceType = FileSystemEntity.typeSync(sourcePath);
  if (sourceType != FileSystemEntityType.directory) {
    return null;
  }

  if (!_baseName(sourcePath).endsWith('.app')) {
    return null;
  }

  final candidate = Directory(
    _joinPath(sourcePath, const ['Contents', 'Resources', 'wine']),
  );
  if (_isGptkWineRootCandidate(candidate)) {
    return candidate;
  }

  return null;
}

bool _isGptkWineRootCandidate(Directory directory) {
  if (!directory.existsSync()) {
    return false;
  }
  final wine64 = File(_joinPath(directory.path, const ['bin', 'wine64']));
  final wineserver = File(
    _joinPath(directory.path, const ['bin', 'wineserver']),
  );
  final lib = Directory(_joinPath(directory.path, const ['lib']));
  final lib64 = Directory(_joinPath(directory.path, const ['lib64']));
  return wine64.existsSync() &&
      wineserver.existsSync() &&
      (lib.existsSync() || lib64.existsSync());
}

String? _validateGptkWineRoot(Directory sourceRoot) {
  final wine64 = File(_joinPath(sourceRoot.path, const ['bin', 'wine64']));
  final wineserver = File(
    _joinPath(sourceRoot.path, const ['bin', 'wineserver']),
  );
  if (!wine64.existsSync()) {
    return 'GPTK-compatible Wine source is missing bin/wine64.';
  }
  if (!wineserver.existsSync()) {
    return 'GPTK-compatible Wine source is missing bin/wineserver.';
  }
  if (!_looksLikeMachO(wine64)) {
    return 'bin/wine64 is not a Mach-O binary. Konyak rejects fixture text '
        'files and incomplete Wine copies.';
  }
  if (!_looksLikeMachO(wineserver)) {
    return 'bin/wineserver is not a Mach-O binary. Konyak rejects fixture text '
        'files and incomplete Wine copies.';
  }

  final lib = Directory(_joinPath(sourceRoot.path, const ['lib']));
  final lib64 = Directory(_joinPath(sourceRoot.path, const ['lib64']));
  if (!lib.existsSync() && !lib64.existsSync()) {
    return 'GPTK-compatible Wine source is missing lib or lib64.';
  }

  return null;
}

String? _validateGptkD3DMetalSource(_GptkD3DMetalSource source) {
  final frameworkBinary = _d3dMetalFrameworkBinary(source.framework.path);
  if (frameworkBinary == null || !File(frameworkBinary).existsSync()) {
    return 'D3DMetal.framework does not contain a D3DMetal binary.';
  }
  if (!_looksLikeMachO(File(frameworkBinary))) {
    return 'D3DMetal.framework is not a Mach-O framework binary. Konyak '
        'rejects fixture text files and incomplete GPTK copies.';
  }
  if (!_looksLikeMachO(source.dylib)) {
    return 'libd3dshared.dylib is not a Mach-O binary. Konyak rejects fixture '
        'text files and incomplete GPTK copies.';
  }
  if (!_looksLikePE(source.d3d12Dll)) {
    return 'd3d12.dll is not a Windows PE binary. Select an official or '
        'compatible Game Porting Toolkit distribution.';
  }
  if (!_looksLikePE(source.dxgiDll)) {
    return 'dxgi.dll is not a Windows PE binary. Select an official or '
        'compatible Game Porting Toolkit distribution.';
  }
  return null;
}

_GptkD3DMetalSource? _resolveGptkD3DMetalSource(String sourcePath) {
  final sourceType = FileSystemEntity.typeSync(sourcePath);
  if (sourceType == FileSystemEntityType.notFound) {
    return null;
  }

  if (sourceType == FileSystemEntityType.directory &&
      _baseName(sourcePath) == 'D3DMetal.framework') {
    final framework = Directory(sourcePath);
    final siblingDylib = File(
      _joinPath(_dirname(sourcePath), const ['libd3dshared.dylib']),
    );
    final dllSource = _resolveGptkD3DMetalWindowsDlls(
      Directory(_dirname(sourcePath)),
    );
    if (siblingDylib.existsSync() && dllSource != null) {
      return _GptkD3DMetalSource(
        directory: Directory(_dirname(sourcePath)),
        framework: framework,
        dylib: siblingDylib,
        d3d12Dll: dllSource.d3d12Dll,
        dxgiDll: dllSource.dxgiDll,
      );
    }
    return null;
  }

  if (sourceType != FileSystemEntityType.directory) {
    return null;
  }

  final candidate = Directory(_joinPath(sourcePath, const ['lib', 'external']));
  final framework = Directory(
    _joinPath(candidate.path, const ['D3DMetal.framework']),
  );
  final dylib = File(_joinPath(candidate.path, const ['libd3dshared.dylib']));
  final dllSource = _resolveGptkD3DMetalWindowsDlls(candidate);
  if (framework.existsSync() && dylib.existsSync() && dllSource != null) {
    return _GptkD3DMetalSource(
      directory: candidate,
      framework: framework,
      dylib: dylib,
      d3d12Dll: dllSource.d3d12Dll,
      dxgiDll: dllSource.dxgiDll,
    );
  }

  return null;
}

class _GptkD3DMetalWindowsDllSource {
  const _GptkD3DMetalWindowsDllSource({
    required this.d3d12Dll,
    required this.dxgiDll,
  });

  final File d3d12Dll;
  final File dxgiDll;
}

_GptkD3DMetalWindowsDllSource? _resolveGptkD3DMetalWindowsDlls(
  Directory sourceDirectory,
) {
  final d3d12 = File(
    _joinPath(sourceDirectory.path, const [
      '..',
      'wine',
      'x86_64-windows',
      'd3d12.dll',
    ]),
  );
  final dxgi = File(_joinPath(_dirname(d3d12.path), const ['dxgi.dll']));
  if (d3d12.existsSync() && dxgi.existsSync()) {
    return _GptkD3DMetalWindowsDllSource(d3d12Dll: d3d12, dxgiDll: dxgi);
  }

  return null;
}

String? _d3dMetalFrameworkBinary(String frameworkPath) {
  for (final relativePath in const <List<String>>[
    <String>['D3DMetal'],
    <String>['Versions', 'A', 'D3DMetal'],
  ]) {
    final path = _joinPath(frameworkPath, relativePath);
    if (File(path).existsSync()) {
      return path;
    }
  }
  return null;
}

bool _looksLikeMachO(File file) {
  try {
    if (!file.existsSync() || file.lengthSync() < 4) {
      return false;
    }
    final bytes = file.openSync();
    try {
      final header = bytes.readSync(4);
      if (header.length < 4) {
        return false;
      }
      final magic =
          header[0] << 24 | header[1] << 16 | header[2] << 8 | header[3];
      return magic == 0xfeedface ||
          magic == 0xcefaedfe ||
          magic == 0xfeedfacf ||
          magic == 0xcffaedfe ||
          magic == 0xcafebabe ||
          magic == 0xbebafeca;
    } finally {
      bytes.closeSync();
    }
  } on FileSystemException {
    return false;
  }
}

bool _looksLikePE(File file) {
  try {
    if (!file.existsSync() || file.lengthSync() < 2) {
      return false;
    }
    final bytes = file.openSync();
    try {
      final header = bytes.readSync(2);
      return header.length == 2 && header[0] == 0x4d && header[1] == 0x5a;
    } finally {
      bytes.closeSync();
    }
  } on FileSystemException {
    return false;
  }
}

RuntimeRecord? _runtimeById(List<RuntimeRecord> runtimes, String runtimeId) {
  for (final runtime in runtimes) {
    if (runtime.id == runtimeId) {
      return runtime;
    }
  }

  return null;
}

String? _runtimeWineVersion(RuntimeRecord runtime) {
  final stack = runtime.stack;
  if (stack == null) {
    return null;
  }

  for (final component in stack.components) {
    if (component.id == 'wine') {
      return component.version;
    }
  }

  return null;
}

String _updateStatus({
  required String? currentVersion,
  required String latestVersion,
}) {
  if (currentVersion == null || currentVersion.trim().isEmpty) {
    return 'unknown';
  }

  if (_normalizeRuntimeVersion(currentVersion) ==
      _normalizeRuntimeVersion(latestVersion)) {
    return 'current';
  }

  return 'available';
}

String _normalizeRuntimeVersion(String version) {
  return version
      .trim()
      .toLowerCase()
      .replaceFirst(RegExp(r'^wine-devel-'), '')
      .replaceFirst(RegExp(r'^v'), '');
}

String? _runtimeReleaseVersion(Object? decoded) {
  if (decoded is! Map<String, dynamic>) {
    return null;
  }

  final tagName = decoded['tag_name'];
  if (tagName is String && tagName.trim().isNotEmpty) {
    return tagName;
  }

  final name = decoded['name'];
  if (name is String && name.trim().isNotEmpty) {
    return name;
  }

  return null;
}

String? _runtimeReleaseArchiveUrl(Object? decoded) {
  if (decoded is! Map<String, dynamic>) {
    return null;
  }

  final assets = decoded['assets'];
  if (assets is! List<dynamic>) {
    return null;
  }

  final urls = <String>[];
  for (final asset in assets) {
    if (asset is! Map<String, dynamic>) {
      continue;
    }

    final url = asset['browser_download_url'];
    if (url is String &&
        url.trim().isNotEmpty &&
        !_isReleaseMetadataAssetUrl(url)) {
      urls.add(url);
    }
  }

  if (urls.isEmpty) {
    return null;
  }

  for (final extension in const <String>[
    '.tar.xz',
    '.tar.gz',
    '.zip',
    '.dmg',
    '.appimage',
  ]) {
    for (final url in urls) {
      if (url.toLowerCase().contains(extension)) {
        return url;
      }
    }
  }

  return urls.first;
}

String? _runtimeReleaseSourceManifestUrl(Object? decoded) {
  if (decoded is! Map<String, dynamic>) {
    return null;
  }

  final releaseAssetUrl = _runtimeReleaseMetadataAssetUrl(decoded);
  if (releaseAssetUrl == null) {
    return null;
  }

  final releaseMetadata = _runtimeReleaseEmbeddedMetadata(releaseAssetUrl);
  if (releaseMetadata == null) {
    return null;
  }

  final fileName = _runtimeReleaseSourceManifestFileName(releaseMetadata);
  if (fileName == null) {
    return null;
  }

  final assetUrl = _runtimeReleaseAssetUrlByFileName(decoded, fileName);
  if (assetUrl != null) {
    return assetUrl;
  }

  return _resolveReleaseMetadataAssetUrl(releaseAssetUrl, fileName);
}

String? _runtimeReleaseSourceManifestSignatureUrl(Object? decoded) {
  if (decoded is! Map<String, dynamic>) {
    return null;
  }

  final releaseAssetUrl = _runtimeReleaseMetadataAssetUrl(decoded);
  if (releaseAssetUrl == null) {
    return null;
  }

  final releaseMetadata = _runtimeReleaseEmbeddedMetadata(releaseAssetUrl);
  if (releaseMetadata == null) {
    return null;
  }

  final fileName = _runtimeReleaseSourceManifestSignatureFileName(
    releaseMetadata,
  );
  if (fileName == null) {
    return null;
  }

  final assetUrl = _runtimeReleaseAssetUrlByFileName(decoded, fileName);
  if (assetUrl != null) {
    return assetUrl;
  }

  return _resolveReleaseMetadataAssetUrl(releaseAssetUrl, fileName);
}

String? _runtimeReleaseMetadataAssetUrl(Object? decoded) {
  if (decoded is! Map<String, dynamic>) {
    return null;
  }

  final assets = decoded['assets'];
  if (assets is! List<dynamic>) {
    return null;
  }

  for (final asset in assets) {
    if (asset is! Map<String, dynamic>) {
      continue;
    }

    final url = asset['browser_download_url'];
    if (url is String &&
        url.trim().isNotEmpty &&
        url.trim().toLowerCase().endsWith('.release.json')) {
      return url;
    }
  }

  return null;
}

Map<String, dynamic>? _runtimeReleaseEmbeddedMetadata(String assetUrl) {
  try {
    final result = Process.runSync('curl', [
      '--fail',
      '--location',
      '--silent',
      assetUrl,
    ], runInShell: false);
    if (result.exitCode != 0) {
      return null;
    }

    final decoded = jsonDecode(_processOutputToString(result.stdout));
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
  } on FormatException {
    return null;
  } on ProcessException {
    return null;
  }

  return null;
}

String? _runtimeReleaseSourceManifestFileName(Object? decoded) {
  if (decoded is! Map<String, dynamic>) {
    return null;
  }

  final runtimeStack = decoded['runtimeStack'];
  if (runtimeStack is! Map<String, dynamic>) {
    return null;
  }

  final fileName = runtimeStack['sourceManifestFileName'];
  if (fileName is String && fileName.trim().isNotEmpty) {
    return fileName;
  }

  return null;
}

String? _runtimeReleaseSourceManifestSignatureFileName(Object? decoded) {
  if (decoded is! Map<String, dynamic>) {
    return null;
  }

  final runtimeStack = decoded['runtimeStack'];
  if (runtimeStack is! Map<String, dynamic>) {
    return null;
  }

  final fileName = runtimeStack['signatureFileName'];
  if (fileName is String && fileName.trim().isNotEmpty) {
    return fileName;
  }

  return null;
}

String? _runtimeReleaseAssetUrlByFileName(Object? decoded, String fileName) {
  if (decoded is! Map<String, dynamic>) {
    return null;
  }

  final assets = decoded['assets'];
  if (assets is! List<dynamic>) {
    return null;
  }

  for (final asset in assets) {
    if (asset is! Map<String, dynamic>) {
      continue;
    }

    final url = asset['browser_download_url'];
    if (url is String &&
        url.trim().isNotEmpty &&
        _fileNameFromUrl(url) == fileName) {
      return url;
    }
  }

  return null;
}

String? _resolveReleaseMetadataAssetUrl(String metadataUrl, String fileName) {
  final metadataUri = Uri.tryParse(metadataUrl);
  if (metadataUri == null) {
    return null;
  }

  final segments = List<String>.from(metadataUri.pathSegments);
  if (segments.isEmpty) {
    return null;
  }

  segments[segments.length - 1] = fileName;
  return metadataUri.replace(pathSegments: segments).toString();
}

bool _isReleaseMetadataAssetUrl(String url) {
  final normalized = url.trim().toLowerCase();
  return normalized.endsWith('.sha256') ||
      normalized.endsWith('.sha256sum') ||
      normalized.endsWith('.sha256sums') ||
      normalized.endsWith('/sha256sums') ||
      normalized.endsWith('/sha256sum') ||
      normalized.endsWith('.release.json');
}

String? _runtimeReleaseArchiveSha256(Object? decoded, String? archiveUrl) {
  if (decoded is! Map<String, dynamic>) {
    return null;
  }

  for (final key in const <String>['archiveSha256', 'archive_sha256']) {
    final value = decoded[key];
    if (value is String && _isSha256Hex(value)) {
      return value;
    }
  }

  final body = decoded['body'];
  if (body is! String || body.trim().isEmpty) {
    return null;
  }

  final archiveFileName = archiveUrl == null
      ? null
      : _fileNameFromUrl(archiveUrl);
  final digestPattern = RegExp(r'\b[0-9a-fA-F]{64}\b');
  for (final line in const LineSplitter().convert(body)) {
    if (archiveFileName != null && !line.contains(archiveFileName)) {
      continue;
    }

    final digest = digestPattern.firstMatch(line)?.group(0);
    if (digest != null && _isSha256Hex(digest)) {
      return digest;
    }
  }

  if (archiveFileName == null) {
    return digestPattern.firstMatch(body)?.group(0);
  }

  return null;
}

RuntimeValidationCheck _runtimePathCheck({
  required String id,
  required String name,
  required String path,
  required FileStatusProbe fileStatusProbe,
}) {
  final exists = fileStatusProbe.exists(path);
  return RuntimeValidationCheck(
    id: id,
    name: name,
    isRequired: true,
    isPassed: exists,
    message: exists ? 'Found $path.' : 'Missing $path.',
  );
}

RuntimeValidationCheck _runtimeAnyPathCheck({
  required String id,
  required String name,
  required List<String> paths,
  required FileStatusProbe fileStatusProbe,
}) {
  final existingPath = paths
      .where((path) => fileStatusProbe.exists(path))
      .cast<String?>()
      .firstWhere((path) => path != null, orElse: () => null);

  return RuntimeValidationCheck(
    id: id,
    name: name,
    isRequired: true,
    isPassed: existingPath != null,
    message: existingPath != null
        ? 'Found $existingPath.'
        : 'Missing one of: ${paths.join(', ')}.',
  );
}

List<String> _macosWineLoaderLibraryPaths(String runtimeRoot) {
  return <String>[
    _joinPath(runtimeRoot, const ['lib']),
    _joinPath(runtimeRoot, const ['lib64']),
  ];
}

String _runtimeLoaderFailureMessage(RuntimeExecutableProbeResult result) {
  final stderr = result.stderr.trim();
  if (stderr.isNotEmpty) {
    return stderr;
  }

  final stdout = result.stdout.trim();
  if (stdout.isNotEmpty) {
    return stdout;
  }

  return 'wine64 --version exited with code ${result.exitCode}.';
}

bool _isSha256Hex(String value) {
  return RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(value);
}

String _sha256HexDigest(File file) {
  final outputSink = _DigestSink();
  final inputSink = sha256.startChunkedConversion(outputSink);
  final inputFile = file.openSync();

  try {
    final buffer = Uint8List(64 * 1024);
    while (true) {
      final length = inputFile.readIntoSync(buffer);
      if (length == 0) {
        break;
      }
      inputSink.add(Uint8List.sublistView(buffer, 0, length));
    }
    inputSink.close();
  } finally {
    inputFile.closeSync();
  }

  final digest = outputSink.digest;
  if (digest == null) {
    throw const FormatException('SHA-256 digest was not produced.');
  }

  return digest.toString();
}

List<String> _wineArgumentsForProgramPath(String programPath) {
  final lowerCasePath = programPath.toLowerCase();

  if (lowerCasePath.endsWith('.exe')) {
    return <String>[programPath];
  }

  if (lowerCasePath.endsWith('.msi')) {
    return <String>['msiexec', '/i', programPath];
  }

  if (lowerCasePath.endsWith('.bat') || lowerCasePath.endsWith('.cmd')) {
    return <String>['cmd', '/c', programPath];
  }

  if (lowerCasePath.endsWith('.lnk')) {
    return <String>['start', '/unix', programPath];
  }

  throw StateError('Unsupported program path: $programPath');
}

List<String> _programSettingsArguments(ProgramSettingsRecord settings) {
  final arguments = settings.arguments.trim();
  if (arguments.isEmpty) {
    return const <String>[];
  }

  return arguments.split(RegExp(r'\s+'));
}

Map<String, String> _programSettingsEnvironment(
  ProgramSettingsRecord settings,
) {
  final environment = <String, String>{...settings.environment};
  if (settings.locale.trim().isNotEmpty) {
    environment['LC_ALL'] = settings.locale;
  }

  return environment;
}

bool _isSupportedProgramPath(String programPath) {
  final lowerCasePath = programPath.toLowerCase();

  return lowerCasePath.endsWith('.exe') ||
      lowerCasePath.endsWith('.msi') ||
      lowerCasePath.endsWith('.bat') ||
      lowerCasePath.endsWith('.cmd') ||
      lowerCasePath.endsWith('.lnk');
}

List<_RegistryValueUpdate> _windowsVersionRegistryUpdates(
  String windowsVersion,
) {
  return <_RegistryValueUpdate>[
    _RegistryValueUpdate(
      key: r'HKCU\Software\Wine',
      name: 'Version',
      type: 'REG_SZ',
      data: windowsVersion,
    ),
  ];
}

List<_RegistryValueUpdate> _runtimeSettingsRegistryUpdates({
  required BottleRuntimeSettings currentRuntimeSettings,
  required BottleRuntimeSettings runtimeSettings,
  required bool includeMacDriverSettings,
}) {
  final updates = <_RegistryValueUpdate>[];

  if (runtimeSettings.buildVersion != currentRuntimeSettings.buildVersion) {
    final windowsVersion = _windowsVersionForBuildVersion(
      runtimeSettings.buildVersion,
    );
    if (windowsVersion != null) {
      updates.addAll(_windowsVersionRegistryUpdates(windowsVersion));
    }

    updates
      ..add(
        _RegistryValueUpdate(
          key: r'HKLM\Software\Microsoft\Windows NT\CurrentVersion',
          name: 'CurrentBuild',
          type: 'REG_SZ',
          data: runtimeSettings.buildVersion.toString(),
        ),
      )
      ..add(
        _RegistryValueUpdate(
          key: r'HKLM\Software\Microsoft\Windows NT\CurrentVersion',
          name: 'CurrentBuildNumber',
          type: 'REG_SZ',
          data: runtimeSettings.buildVersion.toString(),
        ),
      );
  }

  if (includeMacDriverSettings &&
      runtimeSettings.retinaMode != currentRuntimeSettings.retinaMode) {
    updates.add(
      _RegistryValueUpdate(
        key: r'HKCU\Software\Wine\Mac Driver',
        name: 'RetinaMode',
        type: 'REG_SZ',
        data: runtimeSettings.retinaMode ? 'y' : 'n',
      ),
    );
  }

  if (runtimeSettings.dpiScaling != currentRuntimeSettings.dpiScaling) {
    updates.add(
      _RegistryValueUpdate(
        key: r'HKCU\Control Panel\Desktop',
        name: 'LogPixels',
        type: 'REG_DWORD',
        data: runtimeSettings.dpiScaling.toString(),
      ),
    );
  }

  return List.unmodifiable(updates);
}

String? _windowsVersionForBuildVersion(int buildVersion) {
  if (buildVersion >= 22000) {
    return 'win11';
  }
  if (buildVersion >= 10000) {
    return 'win10';
  }
  if (buildVersion >= 9600) {
    return 'win81';
  }
  if (buildVersion >= 9200) {
    return 'win8';
  }
  if (buildVersion >= 7600) {
    return 'win7';
  }
  if (buildVersion >= 3790) {
    return 'winxp64';
  }

  return null;
}

List<_RegistryValueQuery> _bottleSettingsRegistryQueries({
  required bool includeMacDriverSettings,
}) {
  return <_RegistryValueQuery>[
    const _RegistryValueQuery(key: r'HKCU\Software\Wine', name: 'Version'),
    const _RegistryValueQuery(
      key: r'HKLM\Software\Microsoft\Windows NT\CurrentVersion',
      name: 'CurrentBuild',
    ),
    if (includeMacDriverSettings)
      const _RegistryValueQuery(
        key: r'HKCU\Software\Wine\Mac Driver',
        name: 'RetinaMode',
      ),
    const _RegistryValueQuery(
      key: r'HKCU\Control Panel\Desktop',
      name: 'LogPixels',
    ),
  ];
}

BottleRecord _bottleWithRegistryValue({
  required BottleRecord bottle,
  required List<String> arguments,
  required String stdout,
}) {
  final name = _registryValueNameFromArguments(arguments);
  if (name == null) {
    return bottle;
  }

  final data = _registryQueryValue(stdout, name);
  if (data == null) {
    return bottle;
  }

  if (name == 'Version') {
    return _bottleWithWindowsVersion(bottle, data);
  }

  return bottle.copyWith(
    runtimeSettings: _runtimeSettingsWithRegistryValue(
      runtimeSettings: bottle.runtimeSettings,
      arguments: arguments,
      stdout: stdout,
    ),
  );
}

List<String> _registryUpdateArguments(_RegistryValueUpdate update) {
  return <String>[
    'reg',
    'add',
    update.key,
    '-v',
    update.name,
    '-t',
    update.type,
    '-d',
    update.data,
    '-f',
  ];
}

List<String> _registryQueryArguments(_RegistryValueQuery query) {
  return <String>['reg', 'query', query.key, '/v', query.name];
}

BottleRuntimeSettings _runtimeSettingsWithRegistryValue({
  required BottleRuntimeSettings runtimeSettings,
  required List<String> arguments,
  required String stdout,
}) {
  final name = _registryValueNameFromArguments(arguments);
  if (name == null) {
    return runtimeSettings;
  }

  final data = _registryQueryValue(stdout, name);
  if (data == null) {
    return runtimeSettings;
  }

  return switch (name) {
    'CurrentBuild' => _runtimeSettingsWithBuildVersion(runtimeSettings, data),
    'RetinaMode' => _runtimeSettingsWithRetinaMode(runtimeSettings, data),
    'LogPixels' => _runtimeSettingsWithDpiScaling(runtimeSettings, data),
    _ => runtimeSettings,
  };
}

BottleRecord _bottleWithWindowsVersion(BottleRecord bottle, String data) {
  final windowsVersion = _registryWindowsVersion(data);
  if (windowsVersion == null) {
    return bottle;
  }

  return bottle.copyWith(windowsVersion: windowsVersion);
}

String? _registryWindowsVersion(String data) {
  return switch (data.trim().toLowerCase()) {
    'winxp' => 'winxp64',
    'winxp64' ||
    'win7' ||
    'win8' ||
    'win81' ||
    'win10' ||
    'win11' => data.trim().toLowerCase(),
    _ => null,
  };
}

BottleRuntimeSettings _runtimeSettingsWithBuildVersion(
  BottleRuntimeSettings runtimeSettings,
  String data,
) {
  final buildVersion = int.tryParse(data.trim());
  if (buildVersion == null || buildVersion < 0 || buildVersion > 999999) {
    return runtimeSettings;
  }

  return runtimeSettings.copyWith(buildVersion: buildVersion);
}

BottleRuntimeSettings _runtimeSettingsWithRetinaMode(
  BottleRuntimeSettings runtimeSettings,
  String data,
) {
  return switch (data.trim().toLowerCase()) {
    'y' => runtimeSettings.copyWith(retinaMode: true),
    'n' => runtimeSettings.copyWith(retinaMode: false),
    _ => runtimeSettings,
  };
}

BottleRuntimeSettings _runtimeSettingsWithDpiScaling(
  BottleRuntimeSettings runtimeSettings,
  String data,
) {
  final dpiScaling = _registryDwordValue(data);
  if (dpiScaling == null ||
      dpiScaling < 96 ||
      dpiScaling > 480 ||
      (dpiScaling - 96) % 24 != 0) {
    return runtimeSettings;
  }

  return runtimeSettings.copyWith(dpiScaling: dpiScaling);
}

String? _registryValueNameFromArguments(List<String> arguments) {
  final valueIndex = arguments.indexOf('/v');
  if (valueIndex == -1 || valueIndex + 1 >= arguments.length) {
    return null;
  }

  return arguments[valueIndex + 1];
}

String? _registryQueryValue(String output, String name) {
  for (final line in const LineSplitter().convert(output)) {
    final columns = line.trim().split(RegExp(r'\s+'));
    if (columns.length >= 3 && columns.first == name) {
      return columns.sublist(2).join(' ');
    }
  }

  return null;
}

int? _registryDwordValue(String data) {
  final parts = data.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) {
    return null;
  }

  final token = parts.first;
  if (token.startsWith('0x') || token.startsWith('0X')) {
    return int.tryParse(token.substring(2), radix: 16);
  }

  return int.tryParse(token);
}

final class _RegistryValueUpdate {
  const _RegistryValueUpdate({
    required this.key,
    required this.name,
    required this.type,
    required this.data,
  });

  final String key;
  final String name;
  final String type;
  final String data;
}

final class _RegistryValueQuery {
  const _RegistryValueQuery({required this.key, required this.name});

  final String key;
  final String name;
}

String? _supportedBottleCommand(String command) {
  final normalized = command.trim().toLowerCase();
  return switch (normalized) {
    'winecfg' ||
    'regedit' ||
    'control' ||
    'terminal' ||
    'winetricks' => normalized,
    _ => null,
  };
}

List<WinetricksCategoryRecord> parseWinetricksVerbs(String content) {
  final categories = <WinetricksCategoryRecord>[];
  var currentCategoryId = '';
  var currentCategoryName = '';
  var currentVerbs = <WinetricksVerbRecord>[];

  void flushCurrentCategory() {
    if (currentCategoryId.isEmpty) {
      return;
    }

    categories.add(
      WinetricksCategoryRecord(
        id: currentCategoryId,
        name: currentCategoryName,
        verbs: currentVerbs,
      ),
    );
    currentCategoryId = '';
    currentCategoryName = '';
    currentVerbs = <WinetricksVerbRecord>[];
  }

  for (final line in content.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      continue;
    }

    final categoryId = _winetricksCategoryId(trimmed);
    if (categoryId != null) {
      flushCurrentCategory();
      final categoryName = _winetricksCategoryName(categoryId);
      if (categoryName != null) {
        currentCategoryId = categoryId;
        currentCategoryName = categoryName;
      }
      continue;
    }

    if (currentCategoryId.isEmpty) {
      continue;
    }

    final verb = _parseWinetricksVerbLine(trimmed);
    if (verb != null) {
      currentVerbs.add(verb);
    }
  }

  flushCurrentCategory();

  return List.unmodifiable(
    categories.where((category) => category.verbs.isNotEmpty),
  );
}

String? _winetricksCategoryId(String line) {
  if (!line.startsWith('=====') || !line.endsWith('=====')) {
    return null;
  }

  final id = line.replaceAll('=', '').trim().toLowerCase();
  return id.isEmpty ? null : id;
}

String? _winetricksCategoryName(String id) {
  return switch (id) {
    'apps' => 'Apps',
    'benchmarks' => 'Benchmarks',
    'dlls' => 'DLLs',
    'fonts' => 'Fonts',
    'games' => 'Games',
    'settings' => 'Settings',
    _ => null,
  };
}

WinetricksVerbRecord? _parseWinetricksVerbLine(String line) {
  final match = RegExp(r'^(\S+)\s*(.*)$').firstMatch(line);
  if (match == null) {
    return null;
  }

  final name = match.group(1)?.trim() ?? '';
  if (!_isSupportedWinetricksVerb(name)) {
    return null;
  }

  return WinetricksVerbRecord(
    id: name,
    name: name,
    description: match.group(2)?.trim() ?? '',
  );
}

bool _isSupportedWinetricksVerb(String verb) {
  return RegExp(r'^[A-Za-z0-9_.+-]+$').hasMatch(verb);
}

List<_BottleProgramSource> _bottleStartMenuSources(BottleRecord bottle) {
  return <_BottleProgramSource>[
    _BottleProgramSource(
      id: 'globalStartMenu',
      path: _joinPath(bottle.path, const [
        'drive_c',
        'ProgramData',
        'Microsoft',
        'Windows',
        'Start Menu',
      ]),
    ),
    _BottleProgramSource(
      id: 'userStartMenu',
      path: _joinPath(bottle.path, const [
        'drive_c',
        'users',
        'crossover',
        'AppData',
        'Roaming',
        'Microsoft',
        'Windows',
        'Start Menu',
      ]),
    ),
  ];
}

class _BottleProgramSource {
  const _BottleProgramSource({required this.id, required this.path});

  final String id;
  final String path;
}

bool _isShortcutPath(String path) {
  return path.toLowerCase().endsWith('.lnk') &&
      !_baseName(path).startsWith('.');
}

String _shortcutProgramName(String path) {
  final baseName = _baseName(path);
  final extensionStart = baseName.toLowerCase().lastIndexOf('.lnk');
  if (extensionStart <= 0) {
    return baseName;
  }

  return baseName.substring(0, extensionStart);
}

String? _shortcutTargetProgramPath({
  required BottleRecord bottle,
  required String shortcutPath,
}) {
  try {
    final bytes = File(shortcutPath).readAsBytesSync();
    final windowsPath = _shellLinkLocalBasePath(bytes);
    if (windowsPath == null) {
      return null;
    }

    return _wineWindowsPathToHostPath(bottle: bottle, windowsPath: windowsPath);
  } on FileSystemException {
    return null;
  } on RangeError {
    return null;
  }
}

String _metadataProgramPath({
  required BottleRecord bottle,
  required String programPath,
}) {
  if (!_isShortcutPath(programPath)) {
    return programPath;
  }

  return _shortcutTargetProgramPath(
        bottle: bottle,
        shortcutPath: programPath,
      ) ??
      programPath;
}

String? _shellLinkLocalBasePath(Uint8List bytes) {
  const shellLinkHeaderSize = 0x4c;
  final headerSize = _readUint32(bytes, 0);
  final linkFlags = _readUint32(bytes, 0x14);
  if (headerSize != shellLinkHeaderSize || linkFlags == null) {
    return null;
  }

  var offset = shellLinkHeaderSize;
  if (linkFlags & 0x00000001 != 0) {
    final idListSize = _readUint16(bytes, offset);
    if (idListSize == null) {
      return null;
    }
    offset += 2 + idListSize;
  }

  if (linkFlags & 0x00000002 == 0) {
    return null;
  }

  final linkInfoSize = _readUint32(bytes, offset);
  final linkInfoHeaderSize = _readUint32(bytes, offset + 4);
  final localBasePathOffset = _readUint32(bytes, offset + 16);
  if (linkInfoSize == null ||
      linkInfoHeaderSize == null ||
      localBasePathOffset == null ||
      linkInfoSize <= 0 ||
      offset + linkInfoSize > bytes.length) {
    return null;
  }

  if (linkInfoHeaderSize >= 0x24) {
    final localBasePathUnicodeOffset = _readUint32(bytes, offset + 28);
    if (localBasePathUnicodeOffset != null && localBasePathUnicodeOffset > 0) {
      return _nullTerminatedUtf16LeString(
        bytes,
        offset + localBasePathUnicodeOffset,
        offset + linkInfoSize,
      );
    }
  }

  return _nullTerminatedAsciiString(
    bytes,
    offset + localBasePathOffset,
    offset + linkInfoSize,
  );
}

String? _wineWindowsPathToHostPath({
  required BottleRecord bottle,
  required String windowsPath,
}) {
  final normalized = windowsPath.trim().replaceAll('\\', '/');
  final driveMatch = RegExp(r'^([A-Za-z]):/?(.*)$').firstMatch(normalized);
  if (driveMatch == null) {
    return normalized.startsWith('/') ? normalized : null;
  }

  final drive = driveMatch.group(1)?.toLowerCase();
  final path = driveMatch.group(2) ?? '';
  final parts = path
      .split('/')
      .where((part) => part.isNotEmpty)
      .toList(growable: false);

  return switch (drive) {
    'c' => _joinPath(bottle.path, <String>['drive_c', ...parts]),
    'z' => '/${parts.join('/')}',
    _ => null,
  };
}

String? _wineProcessHostPath({
  required BottleRecord bottle,
  required String executable,
}) {
  final hostPath = _wineWindowsPathToHostPath(
    bottle: bottle,
    windowsPath: executable,
  );
  if (hostPath != null) {
    return hostPath;
  }

  final normalized = executable.trim();
  if (normalized.startsWith('/') && !normalized.startsWith('/_')) {
    return normalized;
  }

  final pinnedProgramPath = _pinnedProgramPathForExecutable(
    bottle: bottle,
    executable: executable,
  );
  if (pinnedProgramPath != null) {
    return pinnedProgramPath;
  }

  final recordedExternalProgramPath = _recordedExternalProgramPathForExecutable(
    bottle: bottle,
    executable: executable,
  );
  if (recordedExternalProgramPath != null) {
    return recordedExternalProgramPath;
  }

  return _latestRunProgramPathForExecutable(
    bottle: bottle,
    executable: executable,
  );
}

String? _pinnedProgramPathForExecutable({
  required BottleRecord bottle,
  required String executable,
}) {
  for (final program in bottle.pinnedPrograms) {
    final metadataPath = _metadataProgramPath(
      bottle: bottle,
      programPath: program.path,
    );
    if (_executableNamesMatch(metadataPath, executable)) {
      return metadataPath;
    }
  }

  return null;
}

String? _latestRunProgramPathForExecutable({
  required BottleRecord bottle,
  required String executable,
}) {
  final logFile = File(_joinPath(bottle.path, const ['logs', 'latest.log']));
  if (!logFile.existsSync()) {
    return null;
  }

  try {
    for (final line in const LineSplitter().convert(
      logFile.readAsStringSync(),
    )) {
      final argumentsJson = line.startsWith('Arguments: ')
          ? line.substring('Arguments: '.length)
          : null;
      if (argumentsJson == null) {
        continue;
      }

      final decoded = jsonDecode(argumentsJson);
      if (decoded is! List<Object?>) {
        continue;
      }

      for (final argument in decoded.whereType<String>()) {
        final hostPath = _runArgumentHostPath(
          bottle: bottle,
          argument: argument,
        );
        if (hostPath == null || !_executableNamesMatch(hostPath, executable)) {
          continue;
        }

        return _metadataProgramPath(bottle: bottle, programPath: hostPath);
      }
    }
  } on FileSystemException {
    return null;
  } on FormatException {
    return null;
  }

  return null;
}

String? _recordedExternalProgramPathForExecutable({
  required BottleRecord bottle,
  required String executable,
}) {
  final launchIndexFile = File(
    _joinPath(bottle.path, const ['cache', 'external-program-launches.json']),
  );
  if (!launchIndexFile.existsSync()) {
    return null;
  }

  try {
    final decoded =
        jsonDecode(launchIndexFile.readAsStringSync()) as Map<String, Object?>;
    if (decoded['schemaVersion'] != 1) {
      return null;
    }

    final launches = decoded['launches'];
    if (launches is! List<Object?>) {
      return null;
    }

    for (final launch in launches.reversed) {
      if (launch is! Map<String, Object?>) {
        continue;
      }

      final programPath = launch['programPath'];
      final executableName = launch['executableName'];
      if (programPath is! String || executableName is! String) {
        continue;
      }

      if (_normalizedExecutableName(executableName) !=
          _normalizedExecutableName(executable)) {
        continue;
      }

      return _metadataProgramPath(bottle: bottle, programPath: programPath);
    }
  } on FileSystemException {
    return null;
  } on FormatException {
    return null;
  }

  return null;
}

String? _runArgumentHostPath({
  required BottleRecord bottle,
  required String argument,
}) {
  final hostPath = _wineWindowsPathToHostPath(
    bottle: bottle,
    windowsPath: argument,
  );
  if (hostPath != null) {
    return hostPath;
  }

  final normalized = argument.trim();
  return normalized.startsWith('/') ? normalized : null;
}

bool _executableNamesMatch(String candidatePath, String executable) {
  final candidateName = _normalizedExecutableName(candidatePath);
  final executableName = _normalizedExecutableName(executable);
  return candidateName.isNotEmpty && candidateName == executableName;
}

bool _isWineInfrastructureProcess(_WinedbgProcess process) {
  return _wineInfrastructureExecutableNames.contains(
    _normalizedExecutableName(process.executable),
  );
}

const _wineInfrastructureExecutableNames = <String>{
  'conhost.exe',
  'explorer.exe',
  'plugplay.exe',
  'rpcss.exe',
  'services.exe',
  'start.exe',
  'svchost.exe',
  'winedbg.exe',
  'winedevice.exe',
  'wineboot.exe',
  'winemenubuilder.exe',
};

String _winedbgAttachProcessId(String processId) {
  final normalized = processId.trim();
  if (normalized.startsWith(RegExp('0x', caseSensitive: false))) {
    return normalized;
  }
  if (RegExp(r'^[0-9a-fA-F]+$').hasMatch(normalized)) {
    return '0x$normalized';
  }

  return normalized;
}

String _normalizedExecutableName(String executable) {
  final quotedMatches = RegExp(
    r'''['"]([^'"]+\.exe)['"]''',
    caseSensitive: false,
  ).allMatches(executable).toList(growable: false);
  if (quotedMatches.isNotEmpty) {
    final quotedPath = quotedMatches.last.group(1)!.replaceAll('\\', '/');
    return _baseName(quotedPath).trim().toLowerCase();
  }

  final slashNormalized = executable.trim().replaceAll('\\', '/');
  final baseName = _baseName(slashNormalized).trim();
  return baseName.toLowerCase();
}

List<_WinedbgProcess> _parseWinedbgProcessList(String stdout) {
  final processes = <_WinedbgProcess>[];
  for (final rawLine in const LineSplitter().convert(stdout)) {
    final line = rawLine.trim();
    if (line.isEmpty ||
        line.startsWith('Wine-dbg>') ||
        line.toLowerCase().startsWith('pid ')) {
      continue;
    }

    final match = RegExp(
      r'^(?:[=*>\s]+)?(0x[0-9a-fA-F]+|[0-9a-fA-F]{2,})\s+\S+\s+(.+)$',
    ).firstMatch(line);
    if (match == null) {
      continue;
    }

    final processId = match.group(1);
    final executable = _unquoteWinedbgExecutable(match.group(2) ?? '');
    if (processId == null || executable.isEmpty) {
      continue;
    }

    processes.add(
      _WinedbgProcess(processId: processId, executable: executable),
    );
  }

  return List.unmodifiable(processes);
}

String _unquoteWinedbgExecutable(String value) {
  var normalized = value.trim();
  normalized = normalized.replaceFirst(RegExp(r'''^(?:\\_|/_)\s+'''), '');
  if (normalized.length >= 2) {
    final first = normalized.codeUnitAt(0);
    final last = normalized.codeUnitAt(normalized.length - 1);
    if ((first == 0x27 && last == 0x27) || (first == 0x22 && last == 0x22)) {
      normalized = normalized.substring(1, normalized.length - 1);
    }
  }

  return normalized;
}

class _WinedbgProcess {
  const _WinedbgProcess({required this.processId, required this.executable});

  final String processId;
  final String executable;
}

BottleRecord? _findBottle(Iterable<BottleRecord> bottles, String bottleId) {
  for (final bottle in bottles) {
    if (bottle.id == bottleId) {
      return bottle;
    }
  }

  return null;
}

String _uniqueProgramId({
  required String baseId,
  required List<BottleProgramRecord> existing,
}) {
  final fallbackBaseId = baseId.isEmpty ? 'program' : baseId;
  if (existing.every((program) => program.id != fallbackBaseId)) {
    return fallbackBaseId;
  }

  var suffix = 2;
  while (existing.any((program) => program.id == '$fallbackBaseId-$suffix')) {
    suffix += 1;
  }

  return '$fallbackBaseId-$suffix';
}

String? _extractPeIcon({
  required _PortableExecutableImage image,
  required BottleRecord bottle,
  required String programPath,
  required FileStat fileStat,
}) {
  final icoBytes = _peIconBytes(image);
  if (icoBytes == null) {
    return null;
  }

  final cacheKey = sha256
      .convert(
        utf8.encode(
          '$programPath|${fileStat.size}|'
          '${fileStat.modified.millisecondsSinceEpoch}',
        ),
      )
      .toString()
      .substring(0, 24);
  final iconPath = _joinPath(bottle.path, ['cache', 'icons', '$cacheKey.ico']);

  try {
    final iconFile = File(iconPath);
    iconFile.parent.createSync(recursive: true);
    iconFile.writeAsBytesSync(icoBytes);

    return iconPath;
  } on FileSystemException {
    return null;
  }
}

Uint8List? _peIconBytes(_PortableExecutableImage image) {
  final groupResources = _peResourceLeaves(image, 14);
  if (groupResources.isEmpty) {
    return null;
  }

  final iconResources = <int, Uint8List>{};
  for (final resource in _peResourceLeaves(image, 3)) {
    if (resource.ids.isEmpty) {
      continue;
    }
    iconResources.putIfAbsent(resource.ids.first, () => resource.data);
  }

  for (final group in groupResources) {
    final icon = _icoFromGroupIconResource(
      group.data,
      iconResources: iconResources,
    );
    if (icon != null) {
      return icon;
    }
  }

  return null;
}

Uint8List? _icoFromGroupIconResource(
  Uint8List groupData, {
  required Map<int, Uint8List> iconResources,
}) {
  final count = _readUint16(groupData, 4);
  if (count == null || count <= 0 || groupData.length < 6 + count * 14) {
    return null;
  }

  final entries = <_IcoImageEntry>[];
  for (var index = 0; index < count; index += 1) {
    final offset = 6 + index * 14;
    final bytesInResource = _readUint32(groupData, offset + 8);
    final iconId = _readUint16(groupData, offset + 12);
    if (bytesInResource == null || iconId == null) {
      return null;
    }
    final iconData = iconResources[iconId];
    if (iconData == null) {
      continue;
    }

    entries.add(
      _IcoImageEntry(
        width: groupData[offset],
        height: groupData[offset + 1],
        colorCount: groupData[offset + 2],
        planes: _readUint16(groupData, offset + 4) ?? 0,
        bitCount: _readUint16(groupData, offset + 6) ?? 0,
        data: iconData,
      ),
    );
  }

  if (entries.isEmpty) {
    return null;
  }

  final header = Uint8List(6 + entries.length * 16);
  _writeUint16(header, 2, 1);
  _writeUint16(header, 4, entries.length);

  var imageOffset = header.length;
  for (var index = 0; index < entries.length; index += 1) {
    final entry = entries[index];
    final offset = 6 + index * 16;
    header[offset] = entry.width;
    header[offset + 1] = entry.height;
    header[offset + 2] = entry.colorCount;
    _writeUint16(header, offset + 4, entry.planes);
    _writeUint16(header, offset + 6, entry.bitCount);
    _writeUint32(header, offset + 8, entry.data.length);
    _writeUint32(header, offset + 12, imageOffset);
    imageOffset += entry.data.length;
  }

  final output = BytesBuilder(copy: false)..add(header);
  for (final entry in entries) {
    output.add(entry.data);
  }

  return output.takeBytes();
}

Map<String, String> _peVersionStrings(_PortableExecutableImage image) {
  final resources = _peResourceLeaves(image, 16);
  final values = <String, String>{};
  for (final resource in resources) {
    final strings = _utf16LeTokens(resource.data);
    for (final key in const <String>[
      'FileDescription',
      'ProductName',
      'CompanyName',
      'FileVersion',
      'ProductVersion',
    ]) {
      values.putIfAbsent(key, () => _valueAfterToken(strings, key) ?? '');
      if (values[key] == '') {
        values.remove(key);
      }
    }
  }

  return Map.unmodifiable(values);
}

String? _valueAfterToken(List<String> values, String key) {
  final knownKeys = const <String>{
    'FileDescription',
    'ProductName',
    'CompanyName',
    'FileVersion',
    'ProductVersion',
  };
  for (var index = 0; index < values.length; index += 1) {
    if (values[index] != key) {
      continue;
    }
    for (
      var valueIndex = index + 1;
      valueIndex < values.length;
      valueIndex += 1
    ) {
      final value = values[valueIndex];
      if (knownKeys.contains(value)) {
        break;
      }
      if (value.isNotEmpty) {
        return value;
      }
    }
  }

  return null;
}

List<String> _utf16LeTokens(Uint8List bytes) {
  final codeUnits = <int>[];
  for (var offset = 0; offset + 1 < bytes.length; offset += 2) {
    codeUnits.add(_readUint16(bytes, offset) ?? 0);
  }

  return String.fromCharCodes(codeUnits)
      .split('\u0000')
      .map((value) => value.replaceAll(RegExp(r'[\x00-\x1f]'), '').trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
}

String? _nullTerminatedAsciiString(
  Uint8List bytes,
  int offset,
  int maximumOffset,
) {
  if (offset < 0 || offset >= bytes.length || offset >= maximumOffset) {
    return null;
  }

  final endOffset = _nullByteOffset(bytes, offset, maximumOffset);
  if (endOffset == null) {
    return null;
  }

  return ascii.decode(
    Uint8List.sublistView(bytes, offset, endOffset),
    allowInvalid: true,
  );
}

String? _nullTerminatedUtf16LeString(
  Uint8List bytes,
  int offset,
  int maximumOffset,
) {
  if (offset < 0 || offset + 1 >= bytes.length || offset >= maximumOffset) {
    return null;
  }

  final codeUnits = <int>[];
  for (var cursor = offset; cursor + 1 < maximumOffset; cursor += 2) {
    final codeUnit = _readUint16(bytes, cursor);
    if (codeUnit == null || codeUnit == 0) {
      break;
    }
    codeUnits.add(codeUnit);
  }

  return codeUnits.isEmpty ? null : String.fromCharCodes(codeUnits);
}

int? _nullByteOffset(Uint8List bytes, int offset, int maximumOffset) {
  final boundedMaximum = min(maximumOffset, bytes.length);
  for (var cursor = offset; cursor < boundedMaximum; cursor += 1) {
    if (bytes[cursor] == 0) {
      return cursor;
    }
  }

  return null;
}

List<_PeResourceLeaf> _peResourceLeaves(
  _PortableExecutableImage image,
  int typeId,
) {
  final resourceRootOffset = image.resourceRootOffset;
  if (resourceRootOffset == null) {
    return const <_PeResourceLeaf>[];
  }

  final rootEntries = _peResourceDirectoryEntries(
    image.bytes,
    resourceRootOffset,
  );
  for (final entry in rootEntries) {
    if (entry.id != typeId || !entry.isDirectory) {
      continue;
    }

    return _peResourceLeavesFromDirectory(
      image: image,
      directoryOffset: resourceRootOffset + entry.targetOffset,
      ids: const <int>[],
    );
  }

  return const <_PeResourceLeaf>[];
}

List<_PeResourceLeaf> _peResourceLeavesFromDirectory({
  required _PortableExecutableImage image,
  required int directoryOffset,
  required List<int> ids,
}) {
  final resourceRootOffset = image.resourceRootOffset;
  if (resourceRootOffset == null) {
    return const <_PeResourceLeaf>[];
  }

  final leaves = <_PeResourceLeaf>[];
  for (final entry in _peResourceDirectoryEntries(
    image.bytes,
    directoryOffset,
  )) {
    final nextIds = entry.id == null ? ids : <int>[...ids, entry.id!];
    if (entry.isDirectory) {
      leaves.addAll(
        _peResourceLeavesFromDirectory(
          image: image,
          directoryOffset: resourceRootOffset + entry.targetOffset,
          ids: nextIds,
        ),
      );
      continue;
    }

    final dataEntryOffset = resourceRootOffset + entry.targetOffset;
    final dataRva = _readUint32(image.bytes, dataEntryOffset);
    final size = _readUint32(image.bytes, dataEntryOffset + 4);
    if (dataRva == null || size == null) {
      continue;
    }
    final dataOffset = image.rawOffsetForRva(dataRva);
    if (dataOffset == null || dataOffset + size > image.bytes.length) {
      continue;
    }

    leaves.add(
      _PeResourceLeaf(
        ids: nextIds,
        data: Uint8List.sublistView(image.bytes, dataOffset, dataOffset + size),
      ),
    );
  }

  return List.unmodifiable(leaves);
}

List<_PeResourceDirectoryEntry> _peResourceDirectoryEntries(
  Uint8List bytes,
  int directoryOffset,
) {
  final namedEntryCount = _readUint16(bytes, directoryOffset + 12);
  final idEntryCount = _readUint16(bytes, directoryOffset + 14);
  if (namedEntryCount == null || idEntryCount == null) {
    return const <_PeResourceDirectoryEntry>[];
  }

  final entries = <_PeResourceDirectoryEntry>[];
  final entryCount = namedEntryCount + idEntryCount;
  final maximumEntryCount = (bytes.length - (directoryOffset + 16)) ~/ 8;
  if (entryCount < 0 || entryCount > maximumEntryCount) {
    return const <_PeResourceDirectoryEntry>[];
  }
  for (var index = 0; index < entryCount; index += 1) {
    final offset = directoryOffset + 16 + index * 8;
    final nameOrId = _readUint32(bytes, offset);
    final offsetToData = _readUint32(bytes, offset + 4);
    if (nameOrId == null || offsetToData == null) {
      continue;
    }

    entries.add(
      _PeResourceDirectoryEntry(
        id: nameOrId & 0x80000000 == 0 ? nameOrId & 0xffff : null,
        isDirectory: offsetToData & 0x80000000 != 0,
        targetOffset: offsetToData & 0x7fffffff,
      ),
    );
  }

  return List.unmodifiable(entries);
}

final class _PortableExecutableImage {
  const _PortableExecutableImage({
    required this.bytes,
    required this.machine,
    required this.sections,
    required this.resourceRva,
    required this.resourceRootOffset,
  });

  final Uint8List bytes;
  final int machine;
  final List<_PeSection> sections;
  final int? resourceRva;
  final int? resourceRootOffset;

  String? get architecture {
    return switch (machine) {
      0x014c => 'x86',
      0x8664 => 'x86_64',
      0xaa64 => 'arm64',
      0x01c4 => 'arm',
      _ => null,
    };
  }

  int? rawOffsetForRva(int rva) {
    for (final section in sections) {
      final sectionSize = max(section.virtualSize, section.rawSize);
      if (rva >= section.virtualAddress &&
          rva < section.virtualAddress + sectionSize) {
        return section.rawOffset + (rva - section.virtualAddress);
      }
    }

    return null;
  }

  static _PortableExecutableImage? parse(Uint8List bytes) {
    if (bytes.length < 0x40 || bytes[0] != 0x4d || bytes[1] != 0x5a) {
      return null;
    }

    final peOffset = _readUint32(bytes, 0x3c);
    if (peOffset == null ||
        peOffset + 24 > bytes.length ||
        bytes[peOffset] != 0x50 ||
        bytes[peOffset + 1] != 0x45 ||
        bytes[peOffset + 2] != 0x00 ||
        bytes[peOffset + 3] != 0x00) {
      return null;
    }

    final machine = _readUint16(bytes, peOffset + 4);
    final sectionCount = _readUint16(bytes, peOffset + 6);
    final optionalHeaderSize = _readUint16(bytes, peOffset + 20);
    if (machine == null ||
        sectionCount == null ||
        optionalHeaderSize == null ||
        optionalHeaderSize < 2) {
      return null;
    }

    final optionalHeaderOffset = peOffset + 24;
    final magic = _readUint16(bytes, optionalHeaderOffset);
    final dataDirectoryOffset = switch (magic) {
      0x010b => optionalHeaderOffset + 96,
      0x020b => optionalHeaderOffset + 112,
      _ => null,
    };
    if (dataDirectoryOffset == null) {
      return null;
    }

    final resourceDirectoryOffset = dataDirectoryOffset + 8 * 2;
    final resourceRva = _readUint32(bytes, resourceDirectoryOffset);
    final sectionHeaderOffset = optionalHeaderOffset + optionalHeaderSize;
    final sections = <_PeSection>[];
    for (var index = 0; index < sectionCount; index += 1) {
      final offset = sectionHeaderOffset + index * 40;
      if (offset + 40 > bytes.length) {
        return null;
      }

      final virtualSize = _readUint32(bytes, offset + 8);
      final virtualAddress = _readUint32(bytes, offset + 12);
      final rawSize = _readUint32(bytes, offset + 16);
      final rawOffset = _readUint32(bytes, offset + 20);
      if (virtualSize == null ||
          virtualAddress == null ||
          rawSize == null ||
          rawOffset == null) {
        return null;
      }
      sections.add(
        _PeSection(
          virtualSize: virtualSize,
          virtualAddress: virtualAddress,
          rawSize: rawSize,
          rawOffset: rawOffset,
        ),
      );
    }

    final image = _PortableExecutableImage(
      bytes: bytes,
      machine: machine,
      sections: List.unmodifiable(sections),
      resourceRva: resourceRva,
      resourceRootOffset: null,
    );

    return _PortableExecutableImage(
      bytes: bytes,
      machine: machine,
      sections: List.unmodifiable(sections),
      resourceRva: resourceRva,
      resourceRootOffset: resourceRva == null
          ? null
          : image.rawOffsetForRva(resourceRva),
    );
  }
}

final class _PeSection {
  const _PeSection({
    required this.virtualSize,
    required this.virtualAddress,
    required this.rawSize,
    required this.rawOffset,
  });

  final int virtualSize;
  final int virtualAddress;
  final int rawSize;
  final int rawOffset;
}

final class _PeResourceDirectoryEntry {
  const _PeResourceDirectoryEntry({
    required this.id,
    required this.isDirectory,
    required this.targetOffset,
  });

  final int? id;
  final bool isDirectory;
  final int targetOffset;
}

final class _PeResourceLeaf {
  const _PeResourceLeaf({required this.ids, required this.data});

  final List<int> ids;
  final Uint8List data;
}

final class _IcoImageEntry {
  const _IcoImageEntry({
    required this.width,
    required this.height,
    required this.colorCount,
    required this.planes,
    required this.bitCount,
    required this.data,
  });

  final int width;
  final int height;
  final int colorCount;
  final int planes;
  final int bitCount;
  final Uint8List data;
}

String? _bottleLocationPath({
  required BottleRecord bottle,
  required String location,
}) {
  final normalized = location.trim().toLowerCase();
  return switch (normalized) {
    'root' => bottle.path,
    'c-drive' => _joinPath(bottle.path, const ['drive_c']),
    _ => null,
  };
}

String _programLocationPath(String programPath) {
  final normalized = _normalizeFilesystemPath(programPath);
  final separator = normalized.lastIndexOf('/');
  if (separator <= 0) {
    return normalized;
  }

  return normalized.substring(0, separator);
}

KonyakHostPlatform _currentHostPlatform() {
  return switch (Platform.operatingSystem) {
    'macos' => KonyakHostPlatform.macos,
    _ => KonyakHostPlatform.linux,
  };
}

String _pathOpenExecutable() {
  return switch (_currentHostPlatform()) {
    KonyakHostPlatform.macos =>
      File('/usr/bin/open').existsSync() ? '/usr/bin/open' : 'open',
    KonyakHostPlatform.linux => 'xdg-open',
  };
}

String _konyakApplicationSupportFolder(Map<String, String> environment) {
  final override = environment['KONYAK_APPLICATION_SUPPORT'];
  if (override != null && override.trim().isNotEmpty) {
    return override;
  }

  final home = environment['HOME'];
  if (home != null && home.trim().isNotEmpty) {
    return _joinPath(home, const ['Library', 'Application Support', 'Konyak']);
  }

  return 'Konyak';
}

String _macosWineRuntimeRoot(Map<String, String> environment) {
  final override = environment['KONYAK_MACOS_WINE_HOME'];
  if (override != null && override.trim().isNotEmpty) {
    return override;
  }

  return _joinPath(_konyakApplicationSupportFolder(environment), const [
    'Runtimes',
    'macos-wine',
  ]);
}

String _linuxWineRuntimeRoot(Map<String, String> environment) {
  final override = environment['KONYAK_LINUX_WINE_HOME'];
  if (override != null && override.trim().isNotEmpty) {
    return override;
  }

  return _joinPath(_resolveDataHome(environment), const [
    'Runtimes',
    'linux-wine',
  ]);
}

String _macosWineBinFolder(Map<String, String> environment) {
  return _joinPath(_macosWineRuntimeRoot(environment), const ['bin']);
}

String? _linuxManagedRuntimeBinFolder(Map<String, String> environment) {
  final override = environment['KONYAK_LINUX_WINE_HOME'];
  if (override == null || override.trim().isEmpty) {
    return null;
  }

  return _joinPath(override, const ['bin']);
}

String _macosWineExecutable(Map<String, String> environment) {
  return _joinPath(_macosWineBinFolder(environment), const ['wine64']);
}

String _linuxWineExecutable(Map<String, String> environment) {
  final runtimeBin = _linuxManagedRuntimeBinFolder(environment);
  if (runtimeBin != null) {
    return _joinPath(runtimeBin, const ['wine']);
  }

  return 'wine';
}

String _linuxWinebootExecutable(Map<String, String> environment) {
  final runtimeBin = _linuxManagedRuntimeBinFolder(environment);
  if (runtimeBin != null) {
    return _joinPath(runtimeBin, const ['wineboot']);
  }

  return 'wineboot';
}

String _linuxWineserverExecutable(Map<String, String> environment) {
  final runtimeBin = _linuxManagedRuntimeBinFolder(environment);
  if (runtimeBin != null) {
    return _joinPath(runtimeBin, const ['wineserver']);
  }

  return 'wineserver';
}

String _linuxWinedbgExecutable(Map<String, String> environment) {
  final runtimeBin = _linuxManagedRuntimeBinFolder(environment);
  if (runtimeBin != null) {
    return _joinPath(runtimeBin, const ['winedbg']);
  }

  return 'winedbg';
}

String _macosWineserverExecutable(Map<String, String> environment) {
  return _joinPath(_macosWineBinFolder(environment), const ['wineserver']);
}

String _macosWinetricksExecutable(Map<String, String> environment) {
  return _joinPath(_macosWineRuntimeRoot(environment), const ['winetricks']);
}

String _linuxWinetricksExecutable(Map<String, String> environment) {
  final override = environment['KONYAK_LINUX_WINE_HOME'];
  if (override != null && override.trim().isNotEmpty) {
    return _joinPath(override, const ['winetricks']);
  }

  return 'winetricks';
}

Map<String, String> _linuxRuntimeEnvironment(Map<String, String> environment) {
  final runtimeBin = _linuxManagedRuntimeBinFolder(environment);
  final wineLibraryPath = environment['KONYAK_LINUX_WINE_LIBRARY_PATH'];
  final hasWineLibraryPath =
      wineLibraryPath != null && wineLibraryPath.trim().isNotEmpty;
  if (runtimeBin == null && !hasWineLibraryPath) {
    return const <String, String>{};
  }

  final runtimeEnvironment = <String, String>{};
  if (runtimeBin != null) {
    runtimeEnvironment['PATH'] = _prependPath(runtimeBin, environment['PATH']);
  }
  if (hasWineLibraryPath) {
    runtimeEnvironment['LD_LIBRARY_PATH'] = _prependPath(
      wineLibraryPath.trim(),
      environment['LD_LIBRARY_PATH'],
    );
  }

  return Map.unmodifiable(runtimeEnvironment);
}

String _appUpdateCacheDirectory(Map<String, String> environment) {
  final override = environment['KONYAK_APP_UPDATE_CACHE_HOME'];
  if (override != null && override.trim().isNotEmpty) {
    return override;
  }

  final xdgCache = environment['XDG_CACHE_HOME'];
  if (_currentHostPlatform() == KonyakHostPlatform.linux &&
      xdgCache != null &&
      xdgCache.trim().isNotEmpty) {
    return _joinPath(xdgCache, const ['konyak', 'updates']);
  }

  final home = environment['HOME'];
  if (home != null && home.trim().isNotEmpty) {
    return switch (_currentHostPlatform()) {
      KonyakHostPlatform.macos => _joinPath(home, const [
        'Library',
        'Caches',
        'Konyak',
        'Updates',
      ]),
      KonyakHostPlatform.linux => _joinPath(home, const [
        '.cache',
        'konyak',
        'updates',
      ]),
    };
  }

  return _joinPath(Directory.systemTemp.path, const ['konyak', 'updates']);
}

String? _linuxAppImageTargetPath(Map<String, String> environment) {
  final override = environment['KONYAK_APPIMAGE_PATH'];
  if (override != null && override.trim().isNotEmpty) {
    return override.trim();
  }

  final appImage = environment['APPIMAGE'];
  if (appImage != null && appImage.trim().isNotEmpty) {
    return appImage.trim();
  }

  return null;
}

String? _macosAppBundlePath(Map<String, String> environment) {
  final override = environment['KONYAK_APP_BUNDLE_PATH'];
  if (override != null && override.trim().isNotEmpty) {
    return override.trim();
  }

  final executable = environment['KONYAK_APP_EXECUTABLE'];
  if (executable == null || executable.trim().isEmpty) {
    return null;
  }

  return _macosAppBundlePathFromExecutable(executable.trim());
}

String? _macosAppBundlePathFromExecutable(String executable) {
  final normalized = executable.replaceAll('\\', '/');
  const marker = '.app/Contents/MacOS/';
  final markerIndex = normalized.indexOf(marker);
  if (markerIndex < 0) {
    return null;
  }

  return normalized.substring(0, markerIndex + '.app'.length);
}

int? _konyakAppPid(Map<String, String> environment) {
  final raw = environment['KONYAK_APP_PID'];
  if (raw == null || raw.trim().isEmpty) {
    return null;
  }

  final pid = int.tryParse(raw.trim());
  if (pid == null || pid <= 0) {
    return null;
  }

  return pid;
}

String? _fileNameFromUrl(String url) {
  final parsed = Uri.tryParse(url);
  final segments = parsed?.pathSegments;
  final candidate = segments == null || segments.isEmpty
      ? null
      : segments.last.trim();
  if (candidate == null || candidate.isEmpty) {
    return null;
  }

  return candidate.replaceAll(RegExp(r'[^A-Za-z0-9._+-]'), '_');
}

String _runtimeSiblingPathForInstall(Directory runtimeRoot, String suffix) {
  return '${runtimeRoot.path}.$suffix-${DateTime.now().microsecondsSinceEpoch}';
}

void _replaceRuntimeRootInPlace({
  required Directory runtimeRoot,
  required Directory stagingRoot,
  required Directory backupRoot,
}) {
  var backupCreated = false;
  if (runtimeRoot.existsSync()) {
    if (backupRoot.existsSync()) {
      backupRoot.deleteSync(recursive: true);
    }
    runtimeRoot.renameSync(backupRoot.path);
    backupCreated = true;
  }

  try {
    stagingRoot.renameSync(runtimeRoot.path);
    if (backupCreated && backupRoot.existsSync()) {
      backupRoot.deleteSync(recursive: true);
    }
  } on FileSystemException {
    if (FileSystemEntity.typeSync(runtimeRoot.path) !=
        FileSystemEntityType.notFound) {
      runtimeRoot.deleteSync(recursive: true);
    }
    if (backupCreated && backupRoot.existsSync()) {
      backupRoot.renameSync(runtimeRoot.path);
    }
    rethrow;
  }
}

String? _localSourcePath(String source) {
  final uri = Uri.tryParse(source);
  if (uri != null && uri.scheme == 'file') {
    return uri.toFilePath();
  }

  if (uri == null || uri.scheme.isEmpty) {
    return source;
  }

  return null;
}

String _readAndVerifyRuntimeStackSourceText({
  required String source,
  required String? signatureSource,
  required String? publicKeyPath,
  required String? publicKeyText,
}) {
  final payload = _readTextSource(
    source,
    action: 'download runtime stack source manifest',
  );
  final normalizedPublicKeyPath = publicKeyPath?.trim();
  final normalizedPublicKeyText = publicKeyText?.trim();
  final hasPublicKeyPath =
      normalizedPublicKeyPath != null && normalizedPublicKeyPath.isNotEmpty;
  final hasPublicKeyText =
      normalizedPublicKeyText != null && normalizedPublicKeyText.isNotEmpty;
  final normalizedSignatureSource = signatureSource?.trim();

  if (!hasPublicKeyPath && !hasPublicKeyText) {
    if (normalizedSignatureSource != null &&
        normalizedSignatureSource.isNotEmpty) {
      throw const FileSystemException(
        'Runtime stack source signature was provided without a public key.',
      );
    }
    return payload;
  }

  final effectiveSignatureSource =
      normalizedSignatureSource == null || normalizedSignatureSource.isEmpty
      ? '$source.sig'
      : normalizedSignatureSource;
  final tempDirectory = Directory.systemTemp.createTempSync(
    'konyak-runtime-stack-verify-',
  );
  try {
    final payloadPath = _joinPath(tempDirectory.path, const ['manifest.json']);
    File(payloadPath).writeAsStringSync(payload);

    final signaturePath = _joinPath(tempDirectory.path, const ['manifest.sig']);
    _writeSourceBytes(
      source: effectiveSignatureSource,
      targetPath: signaturePath,
      action: 'download runtime stack source signature',
    );

    final resolvedPublicKeyPath = hasPublicKeyPath
        ? normalizedPublicKeyPath
        : _joinPath(tempDirectory.path, const ['runtime-stack-public-key.pem']);
    if (!hasPublicKeyPath) {
      File(
        resolvedPublicKeyPath,
      ).writeAsStringSync('$normalizedPublicKeyText\n');
    }

    final result = Process.runSync('openssl', [
      'dgst',
      '-sha256',
      '-verify',
      resolvedPublicKeyPath,
      '-signature',
      signaturePath,
      payloadPath,
    ], runInShell: false);
    if (result.exitCode != 0) {
      throw ProcessException(
        'openssl',
        const <String>[],
        'Runtime stack source manifest signature verification failed: '
            '${_commandFailureMessage("verify runtime stack source manifest signature", result)}',
        result.exitCode,
      );
    }

    return payload;
  } finally {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  }
}

String _readTextSource(String source, {required String action}) {
  final localPath = _localSourcePath(source);
  if (localPath != null) {
    return File(localPath).readAsStringSync();
  }

  final result = Process.runSync('curl', [
    '--fail',
    '--location',
    '--silent',
    source,
  ], runInShell: false);
  if (result.exitCode != 0) {
    throw ProcessException(
      'curl',
      const <String>[],
      _commandFailureMessage(action, result),
      result.exitCode,
    );
  }

  return _processOutputToString(result.stdout);
}

void _writeSourceBytes({
  required String source,
  required String targetPath,
  required String action,
}) {
  final localPath = _localSourcePath(source);
  if (localPath != null) {
    File(targetPath).parent.createSync(recursive: true);
    File(localPath).copySync(targetPath);
    return;
  }

  final result = Process.runSync('curl', [
    '--fail',
    '--location',
    '--silent',
    '--output',
    targetPath,
    source,
  ], runInShell: false);
  if (result.exitCode != 0) {
    throw ProcessException(
      'curl',
      const <String>[],
      _commandFailureMessage(action, result),
      result.exitCode,
    );
  }
}

String _macosAppBundleUpdateHandoffScript() {
  return r'''
#!/usr/bin/env bash
set -euo pipefail

source_archive="$1"
target_bundle="$2"
app_pid="$3"
target_parent="$(dirname "$target_bundle")"
bundle_name="$(basename "$target_bundle")"
work_dir="$(mktemp -d "${TMPDIR:-/tmp}/konyak-macos-update.XXXXXX")"
extract_dir="$work_dir/extract"
helper_script="$work_dir/install-macos-app-update-helper.sh"
backup_path="$target_bundle.konyak-backup"

cleanup() {
  rm -rf "$work_dir"
}
trap cleanup EXIT

if [[ ! -d "$target_bundle" ]]; then
  exit 66
fi

mkdir -p "$extract_dir"
ditto -x -k "$source_archive" "$extract_dir"

updated_bundle=""
if [[ -d "$extract_dir/$bundle_name" ]]; then
  updated_bundle="$extract_dir/$bundle_name"
else
  for candidate in "$extract_dir"/*.app "$extract_dir"/*/*.app; do
    if [[ -d "$candidate" ]]; then
      updated_bundle="$candidate"
      break
    fi
  done
fi
if [[ -z "$updated_bundle" ]]; then
  exit 66
fi
if [[ ! -d "$updated_bundle/Contents/MacOS" ]]; then
  exit 66
fi

cat >"$helper_script" <<'HELPER'
#!/usr/bin/env bash
set -euo pipefail

updated_bundle="$1"
target_bundle="$2"
backup_path="$3"
source_archive="$4"
app_pid="$5"
staging_path="$target_bundle.konyak-update"

kill -TERM "$app_pid" 2>/dev/null || true

for ((attempt = 0; attempt < 60; attempt += 1)); do
  if ! kill -0 "$app_pid" 2>/dev/null; then
    break
  fi
  sleep 1
done

if kill -0 "$app_pid" 2>/dev/null; then
  exit 75
fi

rm -rf "$staging_path" "$backup_path"
ditto "$updated_bundle" "$staging_path"

if [[ -e "$target_bundle" ]]; then
  mv "$target_bundle" "$backup_path"
fi

if mv "$staging_path" "$target_bundle"; then
  rm -rf "$backup_path" "$source_archive"
else
  rm -rf "$staging_path"
  if [[ -e "$backup_path" ]]; then
    mv "$backup_path" "$target_bundle"
  fi
  exit 75
fi

xattr -dr com.apple.quarantine "$target_bundle" 2>/dev/null || true
HELPER
chmod 755 "$helper_script"

if [[ -w "$target_parent" ]]; then
  "$helper_script" "$updated_bundle" "$target_bundle" "$backup_path" "$source_archive" "$app_pid"
else
  osascript - "$helper_script" "$updated_bundle" "$target_bundle" "$backup_path" "$source_archive" "$app_pid" <<'APPLESCRIPT'
on run argv
  set helperScript to item 1 of argv
  set updatedBundle to item 2 of argv
  set targetBundle to item 3 of argv
  set backupPath to item 4 of argv
  set sourceArchive to item 5 of argv
  set appPid to item 6 of argv
  set command to "/bin/bash " & quoted form of helperScript & " " & quoted form of updatedBundle & " " & quoted form of targetBundle & " " & quoted form of backupPath & " " & quoted form of sourceArchive & " " & quoted form of appPid
  do shell script command with administrator privileges
end run
APPLESCRIPT
fi

nohup open "$target_bundle" >/dev/null 2>&1 &
''';
}

String _linuxAppImageUpdateHandoffScript() {
  return r'''
#!/usr/bin/env bash
set -euo pipefail

source_archive="$1"
target_appimage="$2"
app_pid="$3"
staging_path="$target_appimage.konyak-update"
backup_path="$target_appimage.konyak-backup"

kill -TERM "$app_pid" 2>/dev/null || true

for _ in $(seq 1 60); do
  if ! kill -0 "$app_pid" 2>/dev/null; then
    break
  fi
  sleep 1
done

if kill -0 "$app_pid" 2>/dev/null; then
  exit 75
fi

rm -f "$staging_path" "$backup_path"
cp "$source_archive" "$staging_path"
chmod 755 "$staging_path"

if [[ -e "$target_appimage" ]]; then
  mv "$target_appimage" "$backup_path"
fi

if mv "$staging_path" "$target_appimage"; then
  rm -f "$backup_path" "$source_archive"
else
  rm -f "$staging_path"
  if [[ -e "$backup_path" ]]; then
    mv "$backup_path" "$target_appimage"
  fi
  exit 75
fi

nohup "$target_appimage" >/dev/null 2>&1 &
''';
}

String? _linuxTerminalOverride(Map<String, String> environment) {
  final terminal = environment['TERMINAL'];
  if (terminal != null && terminal.trim().isNotEmpty) {
    return terminal.trim();
  }

  return null;
}

String _linuxTerminalLauncherCommand(Map<String, String> environment) {
  final override = _linuxTerminalOverride(environment);
  final candidates = <String>[
    if (override != null) 'exec ${_shellQuote(override)} -e bash -lc "\$0" sh',
    'if command -v x-terminal-emulator >/dev/null 2>&1; then exec x-terminal-emulator -e bash -lc "\$0" sh; fi',
    'if command -v kgx >/dev/null 2>&1; then exec kgx -- bash -lc "\$0"; fi',
    'if command -v gnome-terminal >/dev/null 2>&1; then exec gnome-terminal -- bash -lc "\$0"; fi',
    'if command -v ptyxis >/dev/null 2>&1; then exec ptyxis --standalone -- bash -lc "\$0"; fi',
    'if command -v konsole >/dev/null 2>&1; then exec konsole -e bash -lc "\$0"; fi',
    'if command -v xfce4-terminal >/dev/null 2>&1; then exec xfce4-terminal -x bash -lc "\$0"; fi',
    'if command -v mate-terminal >/dev/null 2>&1; then exec mate-terminal -- bash -lc "\$0"; fi',
    'if command -v tilix >/dev/null 2>&1; then exec tilix -- bash -lc "\$0"; fi',
    'if command -v kitty >/dev/null 2>&1; then exec kitty bash -lc "\$0"; fi',
    'if command -v alacritty >/dev/null 2>&1; then exec alacritty -e bash -lc "\$0"; fi',
    'if command -v wezterm >/dev/null 2>&1; then exec wezterm start -- bash -lc "\$0"; fi',
    'echo "No supported terminal emulator found." >&2',
    'exit 127',
  ];

  return candidates.join('\n');
}

String _linuxWineTerminalShellCommandWithEnvironment({
  required BottleRecord bottle,
  required Map<String, String> environment,
}) {
  final executable = _linuxWineExecutable(environment);
  final runtimeBin = _linuxManagedRuntimeBinFolder(environment);
  final wineLibraryPath = environment['KONYAK_LINUX_WINE_LIBRARY_PATH'];
  final shellSetup = <String>[
    'cd ${_shellQuote(bottle.path)}',
    'export WINEPREFIX=${_shellQuote(bottle.path)}',
    'export WINE=${_shellQuote(executable)}',
    if (runtimeBin != null) 'export PATH=${_shellQuote(runtimeBin)}:\$PATH',
    if (wineLibraryPath != null && wineLibraryPath.trim().isNotEmpty)
      'export LD_LIBRARY_PATH=${_shellQuote(wineLibraryPath.trim())}:\${LD_LIBRARY_PATH:-}',
    'alias wine=${_shellQuote(executable)}',
    'alias wine64=${_shellQuote(executable)}',
    'alias winecfg=${_shellQuote('$executable winecfg')}',
    'alias msiexec=${_shellQuote('$executable msiexec')}',
  ];

  return <String>[
    "exec bash --noprofile --rcfile <(cat <<'KONYAK_BASHRC'",
    ...shellSetup,
    'KONYAK_BASHRC',
    ') -i',
  ].join('\n');
}

String _macosWineTerminalShellCommand({
  required BottleRecord bottle,
  required Map<String, String> environment,
}) {
  final runtimeBin = _macosWineBinFolder(environment);
  final commands = <String>[
    'cd ${_shellQuote(bottle.path)}',
    'export PATH=${_shellQuote(runtimeBin)}:\$PATH',
    'export WINE=${_shellQuote('wine64')}',
    'alias wine=${_shellQuote('wine64')}',
    'alias winecfg=${_shellQuote('wine64 winecfg')}',
    'alias msiexec=${_shellQuote('wine64 msiexec')}',
    'alias regedit=${_shellQuote('wine64 regedit')}',
    'alias regsvr32=${_shellQuote('wine64 regsvr32')}',
    'alias wineboot=${_shellQuote('wine64 wineboot')}',
    'alias wineconsole=${_shellQuote('wine64 wineconsole')}',
    'alias winedbg=${_shellQuote('wine64 winedbg')}',
    'alias winefile=${_shellQuote('wine64 winefile')}',
    'alias winepath=${_shellQuote('wine64 winepath')}',
  ];

  _macosWineEnvironment(bottle: bottle, environment: environment).forEach((
    key,
    value,
  ) {
    commands.add('export $key=${_shellQuote(value)}');
  });

  return commands.join('; ');
}

String _macosTerminalAppleScript(String shellCommand) {
  final escapedCommand = _appleScriptString(shellCommand);
  return '''
tell application "Terminal"
activate
do script "$escapedCommand"
end tell
''';
}

String _appleScriptString(String value) {
  return value
      .replaceAll(r'\', r'\\')
      .replaceAll('"', r'\"')
      .replaceAll('\n', r'\n');
}

String _shellQuote(String value) {
  return "'${value.replaceAll("'", "'\"'\"'")}'";
}

String _prependPath(String path, String? existingPath) {
  if (existingPath == null || existingPath.trim().isEmpty) {
    return path;
  }

  return '$path:$existingPath';
}

String _basename(String path) {
  return path.split('/').last;
}

String _dirname(String path) {
  final index = path.lastIndexOf('/');
  if (index <= 0) {
    return '.';
  }

  return path.substring(0, index);
}

final class _DigestSink implements Sink<Digest> {
  Digest? digest;

  @override
  void add(Digest data) {
    digest = data;
  }

  @override
  void close() {}
}

ProgramSettingsRecord _readProgramSettingsJson(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    return const ProgramSettingsRecord();
  }

  final decoded = jsonDecode(file.readAsStringSync());
  final settings = ProgramSettingsRecord.fromJson(decoded);
  if (settings == null) {
    throw const FormatException('Program settings contain an invalid record.');
  }

  return settings;
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

String _programSettingsJsonPath({
  required BottleRecord bottle,
  required String programPath,
}) {
  return _joinPath(bottle.path, [
    'program-settings',
    _programSettingsFileName(programPath, extension: 'json'),
  ]);
}

String _programSettingsFileName(
  String programPath, {
  required String extension,
}) {
  final normalized = programPath.trim().replaceAll(RegExp(r'[\\/]+$'), '');
  final lastSlash = normalized.lastIndexOf('/');
  final lastBackslash = normalized.lastIndexOf(r'\');
  final separator = max(lastSlash, lastBackslash);
  final rawName = separator == -1
      ? normalized
      : normalized.substring(separator + 1);
  final safeName = rawName.replaceAll(RegExp(r'[/\\:]'), '_').trim();
  if (safeName.isEmpty) {
    throw const BottleRepositoryException(
      'Program path cannot form a settings file name.',
    );
  }

  return '$safeName.$extension';
}

String _programSettingsKey({
  required String bottleId,
  required String programPath,
}) {
  return '$bottleId:${_normalizeFilesystemPath(programPath)}';
}

String _appSettingsJsonPath(String configHome) {
  return _joinPath(configHome, const ['settings.json']);
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

  final bottle = BottleRecord.fromJson(decoded['bottle']);
  if (bottle == null) {
    throw const FormatException('Bottle metadata contains an invalid record.');
  }

  return bottle;
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

BottleRecord _bottleFromCreateRequest(
  BottleCreateRequest request,
  String dataHome, {
  String? bottleDirectory,
}) {
  final id = _bottleIdFromName(request.name);
  if (id.isEmpty) {
    throw const BottleRepositoryException('Bottle name cannot form an id.');
  }

  final directory = bottleDirectory ?? _joinPath(dataHome, const ['bottles']);
  return BottleRecord(
    id: id,
    name: request.name,
    path: _joinPath(directory, [id]),
    windowsVersion: request.windowsVersion,
  );
}

BottleRecord _renamedMemoryBottle({
  required BottleRecord bottle,
  required String name,
  required String dataHome,
}) {
  return _renamedFileBottle(bottle: bottle, name: name, dataHome: dataHome);
}

BottleRecord _renamedFileBottle({
  required BottleRecord bottle,
  required String name,
  required String dataHome,
  String? bottleDirectory,
}) {
  final id = _bottleIdFromName(name);
  if (id.isEmpty) {
    throw const BottleRepositoryException('Bottle name cannot form an id.');
  }

  final directory = bottleDirectory ?? _joinPath(dataHome, const ['bottles']);
  return bottle.copyWith(id: id, name: name, path: _joinPath(directory, [id]));
}

final _bottleIdLetterOrNumber = RegExp(r'[\p{L}\p{N}]', unicode: true);

String _bottleIdFromName(String name) {
  final buffer = StringBuffer();
  var lastWasSeparator = false;

  for (final rune in name.trim().toLowerCase().runes) {
    final character = String.fromCharCode(rune);
    if (_bottleIdLetterOrNumber.hasMatch(character)) {
      buffer.write(character);
      lastWasSeparator = false;
    } else if (buffer.isNotEmpty && !lastWasSeparator) {
      buffer.write('-');
      lastWasSeparator = true;
    }
  }

  final id = buffer.toString();
  return id.endsWith('-') ? id.substring(0, id.length - 1) : id;
}

String _resolveDataHome(Map<String, String> environment) {
  final override = environment['KONYAK_DATA_HOME'];
  if (override != null && override.trim().isNotEmpty) {
    return override;
  }

  final xdgDataHome = environment['XDG_DATA_HOME'];
  if (xdgDataHome != null && xdgDataHome.trim().isNotEmpty) {
    return _joinPath(xdgDataHome, const ['konyak']);
  }

  final home = environment['HOME'];
  if (home != null && home.trim().isNotEmpty) {
    return _joinPath(home, const ['.local', 'share', 'konyak']);
  }

  throw const BottleRepositoryException(
    'Unable to resolve Konyak data directory.',
  );
}

String _resolveBottleDataHome(
  Map<String, String> environment, {
  required KonyakHostPlatform hostPlatform,
}) {
  final override = environment['KONYAK_DATA_HOME'];
  if (override != null && override.trim().isNotEmpty) {
    return override;
  }

  return switch (hostPlatform) {
    KonyakHostPlatform.macos => _konyakApplicationSupportFolder(environment),
    KonyakHostPlatform.linux => _resolveDataHome(environment),
  };
}

void _recordExternalProgramRun({
  required BottleRecord bottle,
  required ProgramRunRequest request,
}) {
  final normalizedProgramPath = request.programPath.trim();
  if (normalizedProgramPath.isEmpty ||
      !normalizedProgramPath.startsWith('/') ||
      _isPathWithinRoot(path: normalizedProgramPath, root: bottle.path)) {
    return;
  }

  _recordExternalProgramLaunch(
    bottle: bottle,
    programPath: normalizedProgramPath,
  );
}

void _synchronizeLinuxDesktopLauncherForProgramRun({
  required KonyakHostPlatform hostPlatform,
  required Map<String, String> environment,
  required BottleRecord bottle,
  required ProgramRunRequest request,
  ProgramMetadataExtractor programMetadataExtractor =
      const DartIoProgramMetadataExtractor(),
}) {
  if (hostPlatform != KonyakHostPlatform.linux ||
      request.runnerKind != 'wine') {
    return;
  }

  final normalizedProgramPath = request.programPath.trim();
  if (normalizedProgramPath.isEmpty ||
      !normalizedProgramPath.startsWith('/') ||
      _isPathWithinRoot(path: normalizedProgramPath, root: bottle.path)) {
    return;
  }

  try {
    _recordExternalProgramLaunch(
      bottle: bottle,
      programPath: normalizedProgramPath,
    );
    final launcherPath = _linuxExternalProgramLauncherPath(
      environment: environment,
      bottleId: bottle.id,
      programPath: normalizedProgramPath,
    );
    final metadata = programMetadataExtractor.extract(
      bottle: bottle,
      programPath: _metadataProgramPath(
        bottle: bottle,
        programPath: normalizedProgramPath,
      ),
    );
    final launcherName = metadata?.productName?.trim().isNotEmpty == true
        ? metadata!.productName!.trim()
        : metadata?.fileDescription?.trim().isNotEmpty == true
        ? metadata!.fileDescription!.trim()
        : _baseName(normalizedProgramPath);
    final launcherDirectory = File(launcherPath).parent
      ..createSync(recursive: true);
    final launcherContents = _linuxExternalProgramDesktopEntry(
      bottle: bottle,
      request: request,
      launcherName: launcherName,
      iconPath: metadata?.iconPath,
    );
    File(_joinPath(launcherDirectory.path, [_baseName(launcherPath)]))
      ..createSync(recursive: true)
      ..writeAsStringSync(launcherContents);
  } on FileSystemException {
    return;
  } on BottleRepositoryException {
    return;
  } on StateError {
    return;
  }
}

const _macosPinnedLauncherManifestFileName = 'konyak-launcher.json';
const _macosPinnedLauncherExecutableName = 'konyak-launcher';

class _MacosPinnedProgramLauncherCommand {
  const _MacosPinnedProgramLauncherCommand({
    required this.executable,
    required this.arguments,
    required this.workingDirectory,
  });

  final String executable;
  final List<String> arguments;
  final String? workingDirectory;
}

void _synchronizeMacosPinnedProgramLaunchers({
  required KonyakHostPlatform hostPlatform,
  required Map<String, String> environment,
  required List<BottleRecord> bottles,
}) {
  if (hostPlatform != KonyakHostPlatform.macos) {
    return;
  }

  final launcherHome = _macosPinnedProgramLaunchersHome(environment);
  final launcherCommand = _macosPinnedProgramLauncherCommand(environment);
  if (launcherHome == null || launcherCommand == null) {
    return;
  }

  try {
    final desiredLauncherIds = <String>{};
    final desiredLauncherPaths = <String, String>{};
    final usedDisplayNames = <String>{};
    final usedBundleNames = _unmanagedMacosLauncherBundleNames(launcherHome);
    for (final bottle in bottles) {
      for (final program in bottle.pinnedPrograms) {
        final launcherId = _pinnedProgramLauncherId(
          bottleId: bottle.id,
          programPath: program.path,
        );
        final displayName = _uniqueMacosLauncherDisplayName(
          program.name,
          usedDisplayNames: usedDisplayNames,
          usedBundleNames: usedBundleNames,
        );
        final bundlePath = _joinPath(launcherHome, [
          _macosLauncherBundleName(displayName),
        ]);
        desiredLauncherIds.add(launcherId);
        desiredLauncherPaths[launcherId] = _normalizeFilesystemPath(bundlePath);
        _writeMacosPinnedProgramLauncher(
          bundlePath: bundlePath,
          launcherCommand: launcherCommand,
          displayName: displayName,
          iconPath: program.iconPath,
          manifest: _PinnedProgramLauncherManifest(
            launcherId: launcherId,
            bottleId: bottle.id,
            programPath: program.path,
            programName: program.name,
          ),
        );
      }
    }

    _deleteStaleMacosPinnedProgramLaunchers(
      launcherHome: launcherHome,
      desiredLauncherIds: desiredLauncherIds,
      desiredLauncherPaths: desiredLauncherPaths,
    );
  } on FileSystemException {
    return;
  } on ProcessException {
    return;
  }
}

String? _macosPinnedProgramLaunchersHome(Map<String, String> environment) {
  final override = environment['KONYAK_MACOS_PINNED_LAUNCHERS_HOME'];
  if (override != null && override.trim().isNotEmpty) {
    return override.trim();
  }

  final home = environment['HOME'];
  if (home == null || home.trim().isEmpty) {
    return null;
  }

  return _joinPath(home.trim(), const ['Applications', 'Konyak']);
}

_MacosPinnedProgramLauncherCommand? _macosPinnedProgramLauncherCommand(
  Map<String, String> environment,
) {
  final developmentExecutable =
      environment['KONYAK_PINNED_PROGRAM_LAUNCHER_EXECUTABLE'];
  if (developmentExecutable != null &&
      developmentExecutable.trim().isNotEmpty) {
    final developmentArguments = _macosPinnedProgramLauncherArguments(
      environment['KONYAK_PINNED_PROGRAM_LAUNCHER_ARGUMENTS_JSON'],
    );
    if (developmentArguments == null) {
      return null;
    }

    final workingDirectory =
        environment['KONYAK_PINNED_PROGRAM_LAUNCHER_WORKING_DIRECTORY'];
    return _MacosPinnedProgramLauncherCommand(
      executable: developmentExecutable.trim(),
      arguments: developmentArguments,
      workingDirectory:
          workingDirectory == null || workingDirectory.trim().isEmpty
          ? null
          : workingDirectory.trim(),
    );
  }

  final override = environment['KONYAK_PINNED_PROGRAM_LAUNCHER_CLI'];
  if (override != null && override.trim().isNotEmpty) {
    return _MacosPinnedProgramLauncherCommand(
      executable: override.trim(),
      arguments: const <String>[],
      workingDirectory: null,
    );
  }

  final bundlePath = _macosAppBundlePath(environment);
  if (bundlePath == null) {
    return null;
  }

  final cliExecutable = _joinPath(bundlePath, const [
    'Contents',
    'Resources',
    'konyak-cli',
  ]);
  if (!File(cliExecutable).existsSync()) {
    return null;
  }

  return _MacosPinnedProgramLauncherCommand(
    executable: cliExecutable,
    arguments: const <String>[],
    workingDirectory: null,
  );
}

List<String>? _macosPinnedProgramLauncherArguments(String? value) {
  if (value == null || value.trim().isEmpty) {
    return const <String>[];
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(value);
  } on FormatException {
    return null;
  }

  if (decoded is! List<Object?>) {
    return null;
  }

  final arguments = <String>[];
  for (final argument in decoded) {
    if (argument is! String) {
      return null;
    }
    arguments.add(argument);
  }

  return List.unmodifiable(arguments);
}

String _pinnedProgramLauncherId({
  required String bottleId,
  required String programPath,
}) {
  return sha256
      .convert(
        utf8.encode('$bottleId\u0000${_normalizeFilesystemPath(programPath)}'),
      )
      .toString()
      .substring(0, 16);
}

void _writeMacosPinnedProgramLauncher({
  required String bundlePath,
  required _MacosPinnedProgramLauncherCommand launcherCommand,
  required String displayName,
  required String? iconPath,
  required _PinnedProgramLauncherManifest manifest,
}) {
  final contentsPath = _joinPath(bundlePath, const ['Contents']);
  final macosPath = _joinPath(contentsPath, const ['MacOS']);
  final resourcesPath = _joinPath(contentsPath, const ['Resources']);
  final executablePath = _joinPath(macosPath, const [
    _macosPinnedLauncherExecutableName,
  ]);
  final manifestPath = _joinPath(resourcesPath, const [
    _macosPinnedLauncherManifestFileName,
  ]);

  Directory(macosPath).createSync(recursive: true);
  Directory(resourcesPath).createSync(recursive: true);
  final iconFileName = _writeMacosPinnedProgramLauncherIcon(
    resourcesPath: resourcesPath,
    iconPath: iconPath,
  );
  File(_joinPath(contentsPath, const ['Info.plist'])).writeAsStringSync(
    _macosPinnedProgramInfoPlist(
      manifest: manifest,
      displayName: displayName,
      iconFileName: iconFileName,
    ),
  );
  File(manifestPath).writeAsStringSync(jsonEncode(manifest.toJson()));
  File(
    executablePath,
  ).writeAsStringSync(_macosPinnedProgramLauncherScript(launcherCommand));
  final executableChmodResult = Process.runSync('chmod', <String>[
    '755',
    executablePath,
  ], runInShell: false);
  if (executableChmodResult.exitCode != 0) {
    throw FileSystemException(
      'Unable to mark launcher executable.',
      executablePath,
    );
  }
}

String _macosPinnedProgramInfoPlist({
  required _PinnedProgramLauncherManifest manifest,
  required String displayName,
  required String? iconFileName,
}) {
  final bundleIdentifier =
      '$konyakMacosBundleIdentifier.pinned.${manifest.launcherId}';
  final iconPlistEntry = iconFileName == null
      ? ''
      : '''
  <key>CFBundleIconFile</key>
  <string>${_xmlEscape(iconFileName)}</string>
''';

  return '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleDisplayName</key>
  <string>${_xmlEscape(displayName)}</string>
  <key>CFBundleExecutable</key>
  <string>$_macosPinnedLauncherExecutableName</string>
$iconPlistEntry
  <key>CFBundleIdentifier</key>
  <string>${_xmlEscape(bundleIdentifier)}</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>${_xmlEscape(displayName)}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$konyakAppVersion</string>
  <key>CFBundleVersion</key>
  <string>1</string>
</dict>
</plist>
''';
}

String _macosLauncherDisplayName(String name) {
  final normalized = name.trim();
  return normalized.isEmpty ? 'Konyak Program' : normalized;
}

String _uniqueMacosLauncherDisplayName(
  String name, {
  required Set<String> usedDisplayNames,
  required Set<String> usedBundleNames,
}) {
  final baseName = _macosLauncherDisplayName(name);
  var index = 1;

  while (true) {
    final displayName = index == 1 ? baseName : '$baseName ($index)';
    final displayKey = displayName.toLowerCase();
    final bundleName = _macosLauncherBundleName(displayName);
    final bundleKey = bundleName.toLowerCase();
    if (!usedDisplayNames.contains(displayKey) &&
        !usedBundleNames.contains(bundleKey)) {
      usedDisplayNames.add(displayKey);
      usedBundleNames.add(bundleKey);
      return displayName;
    }

    index += 1;
  }
}

String _macosLauncherBundleName(String displayName) {
  return '${_macosLauncherBundleBaseName(displayName)}.app';
}

String _macosLauncherBundleBaseName(String displayName) {
  final safeName = displayName
      .replaceAll(RegExp(r'[/\\:]'), '-')
      .replaceAll(RegExp(r'[\u0000-\u001f]'), '')
      .trim();
  return safeName.isEmpty ? 'Konyak Program' : safeName;
}

String _macosPinnedProgramLauncherScript(
  _MacosPinnedProgramLauncherCommand command,
) {
  final workingDirectory = command.workingDirectory;
  final changeDirectory = workingDirectory == null
      ? ''
      : 'cd ${_posixShellSingleQuote(workingDirectory)}\n';
  final launcherCommand = <String>[
    _posixShellSingleQuote(command.executable),
    ...command.arguments.map(_posixShellSingleQuote),
    'launch-pinned-program',
    '--manifest',
    r'"$manifest"',
    '--json',
  ].join(' ');

  return '''
#!/bin/sh
set -eu
manifest_dir=\$(CDPATH= cd -- "\$(dirname -- "\$0")/../Resources" && pwd -P)
manifest="\$manifest_dir/$_macosPinnedLauncherManifestFileName"
${changeDirectory}exec $launcherCommand
''';
}

void _deleteStaleMacosPinnedProgramLaunchers({
  required String launcherHome,
  required Set<String> desiredLauncherIds,
  required Map<String, String> desiredLauncherPaths,
}) {
  final launcherDirectory = Directory(launcherHome);
  if (!launcherDirectory.existsSync()) {
    return;
  }

  for (final entity in launcherDirectory.listSync(followLinks: false)) {
    if (entity is! Directory || !entity.path.endsWith('.app')) {
      continue;
    }

    final manifest = _readPinnedProgramLauncherManifest(
      _joinPath(entity.path, const [
        'Contents',
        'Resources',
        _macosPinnedLauncherManifestFileName,
      ]),
    );
    final desiredPath = manifest == null
        ? null
        : desiredLauncherPaths[manifest.launcherId];
    if (manifest == null ||
        (desiredLauncherIds.contains(manifest.launcherId) &&
            desiredPath == _normalizeFilesystemPath(entity.path))) {
      continue;
    }

    entity.deleteSync(recursive: true);
  }
}

Set<String> _unmanagedMacosLauncherBundleNames(String launcherHome) {
  final launcherDirectory = Directory(launcherHome);
  if (!launcherDirectory.existsSync()) {
    return <String>{};
  }

  final bundleNames = <String>{};
  for (final entity in launcherDirectory.listSync(followLinks: false)) {
    if (entity is! Directory || !entity.path.endsWith('.app')) {
      continue;
    }

    final manifest = _readPinnedProgramLauncherManifest(
      _joinPath(entity.path, const [
        'Contents',
        'Resources',
        _macosPinnedLauncherManifestFileName,
      ]),
    );
    if (manifest == null) {
      bundleNames.add(_baseName(entity.path).toLowerCase());
    }
  }

  return bundleNames;
}

const _macosPinnedLauncherIconFileName = 'KonyakPinnedProgram.icns';

String? _writeMacosPinnedProgramLauncherIcon({
  required String resourcesPath,
  required String? iconPath,
}) {
  final sourcePath = iconPath?.trim();
  if (sourcePath == null || sourcePath.isEmpty) {
    return null;
  }

  final source = File(sourcePath);
  if (!source.existsSync()) {
    return null;
  }

  if (sourcePath.toLowerCase().endsWith('.icns')) {
    source.copySync(
      _joinPath(resourcesPath, const [_macosPinnedLauncherIconFileName]),
    );
    return _macosPinnedLauncherIconFileName;
  }

  final convertedIcon = _convertMacosLauncherIconToIcns(
    sourcePath: sourcePath,
    resourcesPath: resourcesPath,
  );
  if (convertedIcon != null) {
    return convertedIcon;
  }

  final fallbackFileName = _macosPinnedLauncherFallbackIconFileName(sourcePath);
  source.copySync(_joinPath(resourcesPath, [fallbackFileName]));
  return fallbackFileName;
}

String? _convertMacosLauncherIconToIcns({
  required String sourcePath,
  required String resourcesPath,
}) {
  final workDirectory = Directory(
    _joinPath(resourcesPath, const ['KonyakPinnedProgramIconWork']),
  );
  final iconset = Directory(
    _joinPath(workDirectory.path, const ['KonyakPinnedProgram.iconset']),
  );
  final sourcePngPath = _joinPath(workDirectory.path, const ['source.png']);
  final icnsPath = _joinPath(resourcesPath, const [
    _macosPinnedLauncherIconFileName,
  ]);

  try {
    if (workDirectory.existsSync()) {
      workDirectory.deleteSync(recursive: true);
    }
    iconset.createSync(recursive: true);

    final convertResult = Process.runSync('sips', <String>[
      '-s',
      'format',
      'png',
      sourcePath,
      '--out',
      sourcePngPath,
    ], runInShell: false);
    if (convertResult.exitCode != 0 || !File(sourcePngPath).existsSync()) {
      return null;
    }

    for (final size in const <int>[16, 32, 128, 256, 512]) {
      final resized = _joinPath(iconset.path, ['icon_${size}x$size.png']);
      final resized2x = _joinPath(iconset.path, ['icon_${size}x$size@2x.png']);
      final resizeResult = Process.runSync('sips', <String>[
        '-z',
        '$size',
        '$size',
        sourcePngPath,
        '--out',
        resized,
      ], runInShell: false);
      final resize2xResult = Process.runSync('sips', <String>[
        '-z',
        '${size * 2}',
        '${size * 2}',
        sourcePngPath,
        '--out',
        resized2x,
      ], runInShell: false);
      if (resizeResult.exitCode != 0 || resize2xResult.exitCode != 0) {
        return null;
      }
    }

    final iconutilResult = Process.runSync('iconutil', <String>[
      '-c',
      'icns',
      iconset.path,
      '-o',
      icnsPath,
    ], runInShell: false);
    if (iconutilResult.exitCode != 0 || !File(icnsPath).existsSync()) {
      return null;
    }

    return _macosPinnedLauncherIconFileName;
  } on FileSystemException {
    return null;
  } on ProcessException {
    return null;
  } finally {
    if (workDirectory.existsSync()) {
      workDirectory.deleteSync(recursive: true);
    }
  }
}

String _macosPinnedLauncherFallbackIconFileName(String sourcePath) {
  final baseName = _baseName(sourcePath);
  final extensionStart = baseName.lastIndexOf('.');
  final extension = extensionStart == -1
      ? ''
      : baseName.substring(extensionStart).toLowerCase();
  if (extension.isEmpty || !RegExp(r'^\.[a-z0-9]+$').hasMatch(extension)) {
    return 'KonyakPinnedProgramIcon';
  }

  return 'KonyakPinnedProgram$extension';
}

_PinnedProgramLauncherManifest? _readPinnedProgramLauncherManifest(
  String manifestPath,
) {
  try {
    final decoded = jsonDecode(File(manifestPath).readAsStringSync());
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final schemaVersion = decoded['schemaVersion'];
    final createdBy = decoded['createdBy'];
    final launcherId = decoded['launcherId'];
    final bottleId = decoded['bottleId'];
    final programPath = decoded['programPath'];
    final programName = decoded['programName'];
    if (schemaVersion != cliSchemaVersion ||
        createdBy != konyakMacosBundleIdentifier ||
        launcherId is! String ||
        launcherId.trim().isEmpty ||
        bottleId is! String ||
        bottleId.trim().isEmpty ||
        programPath is! String ||
        programPath.trim().isEmpty ||
        programName is! String ||
        programName.trim().isEmpty) {
      return null;
    }

    return _PinnedProgramLauncherManifest(
      launcherId: launcherId,
      bottleId: bottleId,
      programPath: programPath,
      programName: programName,
    );
  } on FileSystemException {
    return null;
  } on FormatException {
    return null;
  }
}

String _xmlEscape(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}

String _posixShellSingleQuote(String value) {
  return "'${value.replaceAll("'", "'\\''")}'";
}

void _recordExternalProgramLaunch({
  required BottleRecord bottle,
  required String programPath,
}) {
  try {
    final launchIndexFile = File(
      _joinPath(bottle.path, const ['cache', 'external-program-launches.json']),
    );
    final entry = <String, Object?>{
      'programPath': programPath,
      'executableName': _normalizedExecutableName(programPath),
    };

    final existingEntries = <Map<String, Object?>>[];
    if (launchIndexFile.existsSync()) {
      final decoded =
          jsonDecode(launchIndexFile.readAsStringSync())
              as Map<String, Object?>;
      if (decoded['schemaVersion'] == 1) {
        final launches = decoded['launches'];
        if (launches is List<Object?>) {
          for (final launch in launches) {
            if (launch is Map<String, Object?>) {
              final existingProgramPath = launch['programPath'];
              final existingExecutableName = launch['executableName'];
              if (existingProgramPath is! String ||
                  existingExecutableName is! String) {
                continue;
              }

              if (_normalizeFilesystemPath(existingProgramPath) ==
                      _normalizeFilesystemPath(programPath) &&
                  _normalizedExecutableName(existingExecutableName) ==
                      entry['executableName']) {
                continue;
              }

              existingEntries.add(<String, Object?>{
                'programPath': existingProgramPath,
                'executableName': existingExecutableName,
              });
            }
          }
        }
      }
    }

    final launches = <Map<String, Object?>>[...existingEntries.take(31), entry];
    launchIndexFile.parent.createSync(recursive: true);
    launchIndexFile.writeAsStringSync(
      jsonEncode({'schemaVersion': 1, 'launches': launches}),
    );
  } on FileSystemException {
    return;
  } on FormatException {
    return;
  } on TypeError {
    return;
  }
}

String _linuxExternalProgramLauncherPath({
  required Map<String, String> environment,
  required String bottleId,
  required String programPath,
}) {
  final digest = sha1.convert(utf8.encode('$bottleId:$programPath')).toString();
  return _joinPath(_linuxApplicationsHome(environment), <String>[
    'konyak',
    'konyak-$bottleId-${digest.substring(0, 12)}.desktop',
  ]);
}

String _linuxExternalProgramDesktopEntry({
  required BottleRecord bottle,
  required ProgramRunRequest request,
  required String launcherName,
  required String? iconPath,
}) {
  final lines = <String>[
    '[Desktop Entry]',
    'Type=Application',
    'Name=$launcherName',
    'Exec=${_linuxDesktopEntryExec(request: request, bottle: bottle)}',
    'NoDisplay=true',
    'StartupNotify=true',
    'StartupWMClass=${_normalizedExecutableName(request.programPath)}',
    'Path=${_parentDirectory(request.programPath) ?? bottle.path}',
  ];

  if (iconPath != null && iconPath.trim().isNotEmpty) {
    lines.add('Icon=$iconPath');
  }

  return '${lines.join('\n')}\n';
}

String _linuxDesktopEntryExec({
  required ProgramRunRequest request,
  required BottleRecord bottle,
}) {
  final arguments = request.arguments.map(_desktopEntryQuote).join(' ');
  final buffer = StringBuffer(
    'env "WINEPREFIX=${bottle.path}" ${request.executable}',
  );
  if (arguments.isNotEmpty) {
    buffer.write(' ');
    buffer.write(arguments);
  }

  return buffer.toString();
}

String _desktopEntryQuote(String value) {
  final escaped = value.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
  return '"$escaped"';
}

String _linuxApplicationsHome(Map<String, String> environment) {
  final xdgDataHome = environment['XDG_DATA_HOME'];
  if (xdgDataHome != null && xdgDataHome.trim().isNotEmpty) {
    return _joinPath(xdgDataHome, const <String>['applications']);
  }

  final home = environment['HOME'];
  if (home != null && home.trim().isNotEmpty) {
    return _joinPath(home, const <String>['.local', 'share', 'applications']);
  }

  throw const BottleRepositoryException(
    'Unable to resolve Linux applications directory.',
  );
}

const _linuxKonyakDesktopEntryId = 'app.konyak.Konyak.desktop';
const _linuxExecutableMimeTypes = <String>[
  'application/x-ms-dos-executable',
  'application/x-msdownload',
  'application/vnd.microsoft.portable-executable',
  'application/x-msi',
  'application/x-ms-installer',
  'application/x-ms-shortcut',
  'application/x-msdos-program',
  'text/x-msdos-batch',
];

sealed class _LinuxFileAssociationInstallResult {
  const _LinuxFileAssociationInstallResult();
}

final class _LinuxFileAssociationsInstalled
    extends _LinuxFileAssociationInstallResult {
  const _LinuxFileAssociationsInstalled({
    required this.desktopEntryPath,
    required this.mimeAppsPath,
  });

  final String desktopEntryPath;
  final String mimeAppsPath;
}

final class _LinuxFileAssociationInstallFailed
    extends _LinuxFileAssociationInstallResult {
  const _LinuxFileAssociationInstallFailed(this.message);

  final String message;
}

_LinuxFileAssociationInstallResult _installLinuxFileAssociations({
  required KonyakHostPlatform hostPlatform,
  required Map<String, String> environment,
}) {
  if (hostPlatform != KonyakHostPlatform.linux &&
      environment['KONYAK_FORCE_LINUX_FILE_ASSOCIATIONS'] != '1') {
    return const _LinuxFileAssociationInstallFailed(
      'Linux file associations are supported on Linux only.',
    );
  }

  final appExecutable = _linuxFileAssociationAppExecutable(environment);
  if (appExecutable == null) {
    return const _LinuxFileAssociationInstallFailed(
      'Unable to resolve the Konyak application executable.',
    );
  }

  try {
    final desktopEntryPath = _joinPath(_linuxApplicationsHome(environment), [
      _linuxKonyakDesktopEntryId,
    ]);
    final mimeAppsPath = _linuxMimeAppsPath(environment);

    final desktopEntry = File(desktopEntryPath);
    desktopEntry.parent.createSync(recursive: true);
    desktopEntry.writeAsStringSync(
      _linuxKonyakDesktopEntry(appExecutable: appExecutable),
    );

    final mimeApps = File(mimeAppsPath);
    mimeApps.parent.createSync(recursive: true);
    mimeApps.writeAsStringSync(
      _linuxMimeAppsWithKonyakDefaults(
        existing: mimeApps.existsSync() ? mimeApps.readAsStringSync() : '',
      ),
    );

    return _LinuxFileAssociationsInstalled(
      desktopEntryPath: desktopEntryPath,
      mimeAppsPath: mimeAppsPath,
    );
  } on FileSystemException catch (error) {
    return _LinuxFileAssociationInstallFailed(error.message);
  } on BottleRepositoryException catch (error) {
    return _LinuxFileAssociationInstallFailed(error.message);
  }
}

String? _linuxFileAssociationAppExecutable(Map<String, String> environment) {
  for (final key in const <String>[
    'KONYAK_APPIMAGE_PATH',
    'KONYAK_APP_EXECUTABLE',
  ]) {
    final value = environment[key];
    if (value != null && value.trim().isNotEmpty) {
      return value.trim();
    }
  }

  return null;
}

String _linuxKonyakDesktopEntry({required String appExecutable}) {
  final mimeTypes = '${_linuxExecutableMimeTypes.join(';')};';
  return <String>[
    '[Desktop Entry]',
    'Version=1.0',
    'Type=Application',
    'Name=Konyak',
    'Comment=Run Windows executables with Konyak.',
    'Exec=${_desktopEntryQuote(appExecutable)} %f',
    'Icon=app.konyak.Konyak',
    'StartupWMClass=app.konyak.Konyak',
    'Terminal=false',
    'Categories=Utility;',
    'MimeType=$mimeTypes',
    'StartupNotify=true',
    '',
  ].join('\n');
}

String _linuxMimeAppsPath(Map<String, String> environment) {
  final xdgConfigHome = environment['XDG_CONFIG_HOME'];
  if (xdgConfigHome != null && xdgConfigHome.trim().isNotEmpty) {
    return _joinPath(xdgConfigHome, const ['mimeapps.list']);
  }

  final home = environment['HOME'];
  if (home != null && home.trim().isNotEmpty) {
    return _joinPath(home, const ['.config', 'mimeapps.list']);
  }

  throw const BottleRepositoryException(
    'Unable to resolve Linux MIME applications file.',
  );
}

String _linuxMimeAppsWithKonyakDefaults({required String existing}) {
  final lines = existing.split('\n');
  final output = <String>[];
  var inDefaultApplications = false;
  var wroteDefaultApplications = false;
  final pendingMimeTypes = <String>{..._linuxExecutableMimeTypes};

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      if (inDefaultApplications) {
        _appendLinuxMimeDefaults(output, pendingMimeTypes);
      }
      inDefaultApplications = trimmed == '[Default Applications]';
      wroteDefaultApplications |= inDefaultApplications;
      output.add(line);
      continue;
    }

    if (inDefaultApplications) {
      final separator = line.indexOf('=');
      if (separator > 0) {
        final mimeType = line.substring(0, separator).trim();
        if (pendingMimeTypes.remove(mimeType)) {
          output.add('$mimeType=$_linuxKonyakDesktopEntryId');
          continue;
        }
      }
    }

    if (line.isNotEmpty || output.isNotEmpty) {
      output.add(line);
    }
  }

  if (inDefaultApplications) {
    _appendLinuxMimeDefaults(output, pendingMimeTypes);
  } else {
    if (output.isNotEmpty && output.last.isNotEmpty) {
      output.add('');
    }
    output.add('[Default Applications]');
    _appendLinuxMimeDefaults(output, pendingMimeTypes);
  }

  if (!wroteDefaultApplications && output.first == '') {
    output.removeAt(0);
  }

  return '${output.join('\n').replaceAll(RegExp(r'\n+$'), '')}\n';
}

void _appendLinuxMimeDefaults(
  List<String> output,
  Set<String> pendingMimeTypes,
) {
  for (final mimeType in _linuxExecutableMimeTypes) {
    if (pendingMimeTypes.remove(mimeType)) {
      output.add('$mimeType=$_linuxKonyakDesktopEntryId');
    }
  }
}

bool _isPathWithinRoot({required String path, required String root}) {
  final normalizedPath = path.replaceAll('\\', '/');
  final normalizedRoot = root
      .replaceAll('\\', '/')
      .replaceAll(RegExp(r'/+$'), '');
  return normalizedPath == normalizedRoot ||
      normalizedPath.startsWith('$normalizedRoot/');
}

String? _parentDirectory(String path) {
  final normalized = path.replaceAll('\\', '/').replaceAll(RegExp(r'/+$'), '');
  final index = normalized.lastIndexOf('/');
  if (index <= 0) {
    return index == 0 ? '/' : null;
  }

  return normalized.substring(0, index);
}

String _resolveConfigHome(
  Map<String, String> environment, {
  required KonyakHostPlatform hostPlatform,
}) {
  final override = environment['KONYAK_CONFIG_HOME'];
  if (override != null && override.trim().isNotEmpty) {
    return override;
  }

  switch (hostPlatform) {
    case KonyakHostPlatform.macos:
      final home = environment['HOME'];
      if (home != null && home.trim().isNotEmpty) {
        return _joinPath(home, const [
          'Library',
          'Application Support',
          'Konyak',
        ]);
      }
    case KonyakHostPlatform.linux:
      final xdgConfigHome = environment['XDG_CONFIG_HOME'];
      if (xdgConfigHome != null && xdgConfigHome.trim().isNotEmpty) {
        return _joinPath(xdgConfigHome, const ['konyak']);
      }

      final home = environment['HOME'];
      if (home != null && home.trim().isNotEmpty) {
        return _joinPath(home, const ['.config', 'konyak']);
      }
  }

  throw const AppSettingsRepositoryException(
    'Unable to resolve Konyak config directory.',
  );
}

String _defaultBottlePath(
  Map<String, String> environment, {
  required KonyakHostPlatform hostPlatform,
}) {
  final override = environment['KONYAK_DEFAULT_BOTTLE_PATH'];
  if (override != null && override.trim().isNotEmpty) {
    return override;
  }

  final dataHome = _nonEmptyEnvironmentValue(environment, 'KONYAK_DATA_HOME');
  if (dataHome != null) {
    return _joinPath(dataHome, const ['bottles']);
  }

  return switch (hostPlatform) {
    KonyakHostPlatform.macos => _joinPath(
      _resolveBottleDataHome(environment, hostPlatform: hostPlatform),
      const ['Bottles'],
    ),
    KonyakHostPlatform.linux => _joinPath(_resolveDataHome(environment), const [
      'bottles',
    ]),
  };
}

bool _hasBottleAtPath(
  Iterable<BottleRecord> bottles,
  String path, {
  required String exceptId,
}) {
  final normalizedPath = _normalizeFilesystemPath(path);
  return bottles.any(
    (bottle) =>
        bottle.id != exceptId &&
        _normalizeFilesystemPath(bottle.path) == normalizedPath,
  );
}

bool _hasPinnedProgram(BottleRecord bottle, String programPath) {
  final normalizedProgramPath = _normalizeFilesystemPath(programPath);
  return bottle.pinnedPrograms.any(
    (program) => _isPinnedProgramPath(program, normalizedProgramPath),
  );
}

bool _isPinnedProgramPath(PinnedProgramRecord program, String normalizedPath) {
  return _normalizeFilesystemPath(program.path) == normalizedPath;
}

BottleRecord _bottleWithPinnedProgram(
  BottleRecord bottle,
  ProgramPinRequest request, {
  required ProgramMetadataExtractor programMetadataExtractor,
}) {
  final metadata = programMetadataExtractor.extract(
    bottle: bottle,
    programPath: _metadataProgramPath(
      bottle: bottle,
      programPath: request.programPath,
    ),
  );

  return bottle.copyWith(
    pinnedPrograms: <PinnedProgramRecord>[
      ...bottle.pinnedPrograms,
      PinnedProgramRecord(
        name: request.name,
        path: request.programPath,
        iconPath: metadata?.iconPath,
      ),
    ],
  );
}

BottleRecord _bottleWithPinnedProgramIcons(
  BottleRecord bottle, {
  required ProgramMetadataExtractor programMetadataExtractor,
}) {
  var changed = false;
  final pinnedPrograms = bottle.pinnedPrograms
      .map((program) {
        final existingIconPath = program.iconPath;
        if (existingIconPath != null && existingIconPath.trim().isNotEmpty) {
          return program;
        }

        final metadata = programMetadataExtractor.extract(
          bottle: bottle,
          programPath: _metadataProgramPath(
            bottle: bottle,
            programPath: program.path,
          ),
        );
        final iconPath = metadata?.iconPath;
        if (iconPath == null || iconPath.trim().isEmpty) {
          return program;
        }

        changed = true;
        return program.copyWith(iconPath: iconPath);
      })
      .toList(growable: false);

  if (!changed) {
    return bottle;
  }

  return bottle.copyWith(pinnedPrograms: pinnedPrograms);
}

BottleRecord _bottleWithoutPinnedProgram(
  BottleRecord bottle,
  String programPath,
) {
  final normalizedProgramPath = _normalizeFilesystemPath(programPath);
  return bottle.copyWith(
    pinnedPrograms: bottle.pinnedPrograms
        .where(
          (program) => !_isPinnedProgramPath(program, normalizedProgramPath),
        )
        .toList(growable: false),
  );
}

BottleRecord _bottleWithRenamedPinnedProgram(
  BottleRecord bottle,
  ProgramRenameRequest request,
) {
  final normalizedProgramPath = _normalizeFilesystemPath(request.programPath);
  return bottle.copyWith(
    pinnedPrograms: bottle.pinnedPrograms
        .map(
          (program) => _isPinnedProgramPath(program, normalizedProgramPath)
              ? program.copyWith(name: request.name)
              : program,
        )
        .toList(growable: false),
  );
}

String _normalizeFilesystemPath(String path) {
  return path.trim().replaceAll(RegExp(r'/+$'), '');
}

void _moveDirectory({required String from, required String to}) {
  final source = Directory(from);
  if (!source.existsSync()) {
    throw FileSystemException('Bottle directory was not found.', from);
  }

  final destination = Directory(to);
  destination.parent.createSync(recursive: true);

  try {
    source.renameSync(destination.path);
  } on FileSystemException {
    _copyDirectory(source: source, destination: destination);
    source.deleteSync(recursive: true);
  }
}

BottleArchiveExportResult _exportBottleArchive({
  required BottleRecord bottle,
  required String archivePath,
}) {
  final normalizedBottlePath = _normalizeFilesystemPath(bottle.path);
  final bottleDirectory = Directory(normalizedBottlePath);
  if (!bottleDirectory.existsSync()) {
    return BottleArchiveExportFailed('Bottle directory was not found.');
  }

  try {
    final normalizedArchivePath = _normalizeFilesystemPath(archivePath);
    if (normalizedArchivePath == normalizedBottlePath ||
        normalizedArchivePath.startsWith('$normalizedBottlePath/')) {
      return BottleArchiveExportFailed(
        'Bottle archive path must be outside the bottle directory.',
      );
    }

    final archive = File(archivePath);
    archive.parent.createSync(recursive: true);
    final result = Process.runSync('tar', [
      '-cf',
      archive.path,
      '-C',
      _dirname(normalizedBottlePath),
      _basename(normalizedBottlePath),
    ], runInShell: false);
    if (result.exitCode != 0) {
      return BottleArchiveExportFailed(
        _commandFailureMessage('export bottle archive', result),
      );
    }
  } on FileSystemException catch (error) {
    return BottleArchiveExportFailed(error.message);
  } on ProcessException catch (error) {
    return BottleArchiveExportFailed(error.message);
  }

  return BottleArchiveExported(
    BottleArchiveRecord(bottleId: bottle.id, archivePath: archivePath),
  );
}

BottleArchiveImportResult _importBottleArchive({
  required String archivePath,
  required String bottleDirectory,
  required bool Function(String bottleId) hasBottle,
  void Function(BottleRecord bottle)? onImported,
}) {
  final archive = File(archivePath);
  if (!archive.existsSync()) {
    return BottleArchiveImportFailed('Bottle archive was not found.');
  }

  final listing = _validatedBottleArchiveListing(archivePath);
  switch (listing) {
    case _InvalidBottleArchiveListing(:final message):
      return BottleArchiveImportFailed(message);
    case _ValidBottleArchiveListing():
      break;
  }

  final tempDirectory = Directory.systemTemp.createTempSync(
    'konyak-bottle-import-',
  );
  try {
    final extraction = Process.runSync('tar', [
      '-xf',
      archivePath,
      '-C',
      tempDirectory.path,
    ], runInShell: false);
    if (extraction.exitCode != 0) {
      return BottleArchiveImportFailed(
        _commandFailureMessage('import bottle archive', extraction),
      );
    }

    final extractedBottlePath = _joinPath(tempDirectory.path, [
      listing.topLevelDirectory,
    ]);
    final extractedBottleDirectory = Directory(extractedBottlePath);
    if (!extractedBottleDirectory.existsSync()) {
      return const BottleArchiveImportFailed(
        'Bottle archive does not contain a bottle directory.',
      );
    }

    final imported = _readBottleMetadata(extractedBottlePath);
    if (!_isValidBottleArchiveId(imported.id)) {
      return const BottleArchiveImportFailed(
        'Bottle archive metadata contains an invalid bottle id.',
      );
    }
    if (hasBottle(imported.id)) {
      return BottleArchiveImportConflict(imported.id);
    }

    final destinationPath = _joinPath(bottleDirectory, [imported.id]);
    if (Directory(destinationPath).existsSync()) {
      return BottleArchiveImportConflict(imported.id);
    }

    final relocated = imported.copyWith(path: destinationPath);
    _moveDirectory(from: extractedBottlePath, to: destinationPath);
    _writeBottleMetadata(relocated);
    onImported?.call(relocated);

    return BottleArchiveImported(relocated);
  } on FileSystemException catch (error) {
    return BottleArchiveImportFailed(error.message);
  } on FormatException catch (error) {
    return BottleArchiveImportFailed(error.message);
  } on ProcessException catch (error) {
    return BottleArchiveImportFailed(error.message);
  } finally {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  }
}

sealed class _BottleArchiveListing {
  const _BottleArchiveListing();
}

final class _ValidBottleArchiveListing extends _BottleArchiveListing {
  const _ValidBottleArchiveListing({required this.topLevelDirectory});

  final String topLevelDirectory;
}

final class _InvalidBottleArchiveListing extends _BottleArchiveListing {
  const _InvalidBottleArchiveListing(this.message);

  final String message;
}

_BottleArchiveListing _validatedBottleArchiveListing(String archivePath) {
  final result = Process.runSync('tar', [
    '-tf',
    archivePath,
  ], runInShell: false);
  if (result.exitCode != 0) {
    return _InvalidBottleArchiveListing(
      _commandFailureMessage('inspect bottle archive', result),
    );
  }

  final entries = _processOutputToString(result.stdout)
      .split('\n')
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toList(growable: false);
  if (entries.isEmpty) {
    return const _InvalidBottleArchiveListing('Bottle archive is empty.');
  }

  final topLevelDirectories = <String>{};
  var hasMetadata = false;
  for (final entry in entries) {
    if (!_isSafeArchiveEntryPath(entry)) {
      return const _InvalidBottleArchiveListing(
        'Bottle archive contains an unsafe path.',
      );
    }

    final segments = entry
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);
    topLevelDirectories.add(segments.first);
    if (segments.length == 2 && segments.last == 'metadata.json') {
      hasMetadata = true;
    }
  }

  if (topLevelDirectories.length != 1) {
    return const _InvalidBottleArchiveListing(
      'Bottle archive must contain exactly one bottle directory.',
    );
  }
  if (!hasMetadata) {
    return const _InvalidBottleArchiveListing(
      'Bottle archive does not contain bottle metadata.',
    );
  }

  return _ValidBottleArchiveListing(
    topLevelDirectory: topLevelDirectories.single,
  );
}

bool _isSafeArchiveEntryPath(String path) {
  if (path.startsWith('/') ||
      path.startsWith(r'\') ||
      path.contains('\u0000')) {
    return false;
  }
  if (path.contains(r'\')) {
    return false;
  }

  final segments = path.split('/').where((segment) => segment.isNotEmpty);
  var hasSegment = false;
  for (final segment in segments) {
    hasSegment = true;
    if (segment == '.' || segment == '..') {
      return false;
    }
  }

  return hasSegment;
}

bool _isValidBottleArchiveId(String id) {
  return id.isNotEmpty &&
      !id.contains('/') &&
      !id.contains(r'\') &&
      id != '.' &&
      id != '..';
}

void _copyDirectory({
  required Directory source,
  required Directory destination,
}) {
  if (destination.existsSync()) {
    throw FileSystemException(
      'Destination directory already exists.',
      destination.path,
    );
  }

  destination.createSync(recursive: true);
  for (final entity in source.listSync(followLinks: false)) {
    final targetPath = _joinPath(destination.path, [_baseName(entity.path)]);
    if (entity is Directory) {
      _copyDirectory(source: entity, destination: Directory(targetPath));
    } else if (entity is File) {
      entity.copySync(targetPath);
    } else if (entity is Link) {
      Link(targetPath).createSync(entity.targetSync());
    }
  }
}

void _copyDirectoryContentsReplacing({
  required Directory source,
  required Directory destination,
  List<List<String>> skipRelativePaths = const <List<String>>[],
}) {
  destination.createSync(recursive: true);
  _copyDirectoryEntriesReplacing(
    source: source,
    destination: destination,
    relativePath: const <String>[],
    skipRelativePaths: skipRelativePaths,
  );
}

void _copyDirectoryEntriesReplacing({
  required Directory source,
  required Directory destination,
  required List<String> relativePath,
  required List<List<String>> skipRelativePaths,
}) {
  for (final entity in source.listSync(followLinks: false)) {
    final name = _baseName(entity.path);
    final entityRelativePath = <String>[...relativePath, name];
    if (_isSkippedRelativePath(entityRelativePath, skipRelativePaths)) {
      continue;
    }
    final targetPath = _joinPath(destination.path, [name]);
    if (entity is Directory) {
      final targetType = FileSystemEntity.typeSync(targetPath);
      if (targetType != FileSystemEntityType.notFound &&
          targetType != FileSystemEntityType.directory) {
        _deleteFileSystemEntitySync(targetPath, targetType);
      }
      final targetDirectory = Directory(targetPath)
        ..createSync(recursive: true);
      _copyDirectoryEntriesReplacing(
        source: entity,
        destination: targetDirectory,
        relativePath: entityRelativePath,
        skipRelativePaths: skipRelativePaths,
      );
    } else if (entity is File) {
      final targetType = FileSystemEntity.typeSync(targetPath);
      if (targetType == FileSystemEntityType.directory) {
        Directory(targetPath).deleteSync(recursive: true);
      }
      entity.copySync(targetPath);
    } else if (entity is Link) {
      final targetType = FileSystemEntity.typeSync(targetPath);
      if (targetType != FileSystemEntityType.notFound) {
        _deleteFileSystemEntitySync(targetPath, targetType);
      }
      Link(targetPath).createSync(entity.targetSync());
    }
  }
}

void _deleteFileSystemEntitySync(String path, FileSystemEntityType type) {
  if (type == FileSystemEntityType.directory) {
    Directory(path).deleteSync(recursive: true);
  } else if (type == FileSystemEntityType.link) {
    Link(path).deleteSync();
  } else {
    File(path).deleteSync();
  }
}

bool _isSkippedRelativePath(
  List<String> relativePath,
  List<List<String>> skipRelativePaths,
) {
  for (final skipped in skipRelativePaths) {
    if (relativePath.length < skipped.length) {
      continue;
    }
    var matches = true;
    for (var index = 0; index < skipped.length; index += 1) {
      if (relativePath[index] != skipped[index]) {
        matches = false;
        break;
      }
    }
    if (matches) {
      return true;
    }
  }
  return false;
}

String? _nonEmptyEnvironmentValue(Map<String, String> environment, String key) {
  final value = environment[key];
  if (value == null || value.trim().isEmpty) {
    return null;
  }

  return value;
}

String? _runtimeProfileEnvironmentValue(
  Map<String, String> environment, {
  required String developmentKey,
  required String releaseKey,
}) {
  if (_isDevelopmentRuntimeProfile(environment)) {
    return _nonEmptyEnvironmentValue(environment, developmentKey);
  }

  return _nonEmptyEnvironmentValue(environment, releaseKey);
}

String _runtimeDistributionKind(
  Map<String, String> environment,
  String defaultKind,
) {
  if (_isDevelopmentRuntimeProfile(environment)) {
    return 'development';
  }

  return defaultKind;
}

bool _isDevelopmentRuntimeProfile(Map<String, String> environment) {
  return _nonEmptyEnvironmentValue(environment, 'KONYAK_RUNTIME_PROFILE') ==
      'development';
}

Map<String, Object?>? _objectMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value.cast<String, Object?>();
  }

  if (value is Map<String, Object?>) {
    return value;
  }

  return null;
}

String _baseName(String path) {
  final normalized = path.replaceAll(RegExp(r'/+$'), '');
  final index = normalized.lastIndexOf('/');
  if (index == -1) {
    return normalized;
  }

  return normalized.substring(index + 1);
}

CliResult _jsonError({
  required int exitCode,
  required String code,
  required String message,
  Map<String, Object?> extra = const <String, Object?>{},
}) {
  return CliResult(
    exitCode: exitCode,
    stdout: jsonEncode(<String, Object?>{
      'schemaVersion': cliSchemaVersion,
      'error': <String, Object?>{'code': code, 'message': message, ...extra},
    }),
    stderr: '',
  );
}

CliResult _bottleNotFoundError(String bottleId) {
  return _jsonError(
    exitCode: 66,
    code: 'bottleNotFound',
    message: 'Bottle not found.',
    extra: <String, Object?>{'bottleId': bottleId},
  );
}

CliResult _createdBottleJsonResult({
  required BottleRecord bottle,
  required BottlePrefixInitializer? bottlePrefixInitializer,
}) {
  final initializer = bottlePrefixInitializer;
  if (initializer != null) {
    final initializationResult = initializer.initialize(bottle);
    switch (initializationResult) {
      case BottlePrefixInitialized():
        break;
      case BottlePrefixInitializationFailed(:final message):
        return _jsonError(
          exitCode: 75,
          code: 'bottlePrefixInitializationFailed',
          message: message,
          extra: <String, Object?>{
            'bottleId': bottle.id,
            'bottlePath': bottle.path,
          },
        );
    }
  }

  return CliResult(
    exitCode: 0,
    stdout: jsonEncode(<String, Object?>{
      'schemaVersion': cliSchemaVersion,
      'bottle': bottle.toJson(),
    }),
    stderr: '',
  );
}

CliResult _programRunJsonResult({
  required ProgramRunRequest request,
  required int processExitCode,
}) {
  return CliResult(
    exitCode: 0,
    stdout: jsonEncode(<String, Object?>{
      'schemaVersion': cliSchemaVersion,
      'run': <String, Object?>{
        'bottleId': request.bottleId,
        'programPath': request.programPath,
        'runnerKind': request.runnerKind,
        'executable': request.executable,
        'workingDirectory': request.workingDirectory,
        'argv': request.argv,
        'logPath': request.logPath,
        'processExitCode': processExitCode,
      },
    }),
    stderr: '',
  );
}

CliResult _programRunFailedJsonResult({
  required ProgramRunRequest request,
  required String message,
}) {
  return _jsonError(
    exitCode: 75,
    code: 'programRunFailed',
    message: message,
    extra: <String, Object?>{
      'bottleId': request.bottleId,
      'programPath': request.programPath,
      'runnerKind': request.runnerKind,
      'executable': request.executable,
      'workingDirectory': request.workingDirectory,
      'argv': request.argv,
      'logPath': request.logPath,
    },
  );
}

CliResult? _ensureWinetricksScriptForRun({
  required ProgramRunRequest request,
  required WinetricksScriptInstaller scriptInstaller,
}) {
  if (request.runnerKind != 'macosWinetricks') {
    return null;
  }

  final installResult = scriptInstaller.installIfMissing(
    executable: request.executable,
  );
  return switch (installResult) {
    WinetricksScriptInstallCompleted() => null,
    WinetricksScriptInstallFailed(:final message) => _jsonError(
      exitCode: 75,
      code: 'winetricksUnavailable',
      message: message,
    ),
  };
}

String _programRunLog(ProgramRunRequest request, ProcessResult result) {
  final stdout = _processOutputToString(result.stdout);
  final stderr = _processOutputToString(result.stderr);

  return _programRunLogContent(
    request: request,
    processExitCode: result.exitCode,
    stdout: stdout,
    stderr: stderr,
  );
}

String _programRunStartupFailureLog(
  ProgramRunRequest request,
  String startupError,
) {
  return _programRunLogContent(
    request: request,
    startupError: startupError,
    stdout: '',
    stderr: '',
  );
}

String _programRunLogContent({
  required ProgramRunRequest request,
  required String stdout,
  required String stderr,
  int? processExitCode,
  String? startupError,
}) {
  final environmentLines =
      request.environment.entries
          .map((entry) => MapEntry(entry.key, '${entry.key}=${entry.value}'))
          .toList(growable: false)
        ..sort((left, right) => left.key.compareTo(right.key));

  return <String>[
    'Konyak Wine Run Log',
    '',
    '[Process]',
    'Runner Kind: ${request.runnerKind}',
    'Executable: ${request.executable}',
    'Working Directory: ${request.workingDirectory ?? ''}',
    'Arguments: ${jsonEncode(request.arguments)}',
    'argv: ${jsonEncode(request.argv)}',
    if (processExitCode != null) 'Process Exit Code: $processExitCode',
    if (processExitCode != null) 'exitCode: $processExitCode',
    if (startupError != null) 'Startup Error: $startupError',
    '',
    '[Environment]',
    ...environmentLines.map((entry) => entry.value),
    '',
    '[stdout]',
    stdout,
    '',
    '[stderr]',
    stderr,
    '',
  ].join('\n');
}

String _programRunnerFailureMessage({
  required String executable,
  required String message,
}) {
  if (message == 'No such file or directory') {
    return 'Runner executable `$executable` was not found.';
  }

  return message;
}

String _commandFailureMessage(String action, ProcessResult result) {
  final stderr = _processOutputToString(result.stderr).trim();
  final stdout = _processOutputToString(result.stdout).trim();
  final details = stderr.isNotEmpty ? stderr : stdout;

  if (details.isEmpty) {
    return 'Failed to $action with exit code ${result.exitCode}.';
  }

  return 'Failed to $action with exit code ${result.exitCode}: $details';
}

String _processOutputToString(Object? output) {
  if (output == null) {
    return '';
  }

  if (output is String) {
    return output;
  }

  if (output is List<int>) {
    return utf8.decode(output, allowMalformed: true);
  }

  return output.toString();
}

int? _readUint16(Uint8List bytes, int offset) {
  if (offset < 0 || offset + 2 > bytes.length) {
    return null;
  }

  return bytes[offset] | bytes[offset + 1] << 8;
}

int? _readUint32(Uint8List bytes, int offset) {
  if (offset < 0 || offset + 4 > bytes.length) {
    return null;
  }

  return bytes[offset] |
      bytes[offset + 1] << 8 |
      bytes[offset + 2] << 16 |
      bytes[offset + 3] << 24;
}

void _writeUint16(Uint8List bytes, int offset, int value) {
  bytes[offset] = value & 0xff;
  bytes[offset + 1] = value >> 8 & 0xff;
}

void _writeUint32(Uint8List bytes, int offset, int value) {
  bytes[offset] = value & 0xff;
  bytes[offset + 1] = value >> 8 & 0xff;
  bytes[offset + 2] = value >> 16 & 0xff;
  bytes[offset + 3] = value >> 24 & 0xff;
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (identical(left, right)) {
    return true;
  }

  if (left.length != right.length) {
    return false;
  }

  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) {
      return false;
    }
  }

  return true;
}

bool _mapEquals<K, V>(Map<K, V> left, Map<K, V> right) {
  if (identical(left, right)) {
    return true;
  }

  if (left.length != right.length) {
    return false;
  }

  for (final entry in left.entries) {
    if (!right.containsKey(entry.key) || right[entry.key] != entry.value) {
      return false;
    }
  }

  return true;
}

Map<String, String>? _stringMap(Object? value) {
  if (value == null) {
    return const <String, String>{};
  }

  final map = _objectMap(value);
  if (map == null) {
    return null;
  }

  final result = <String, String>{};
  for (final entry in map.entries) {
    if (entry.key.trim().isEmpty ||
        entry.key.contains('=') ||
        entry.value is! String) {
      return null;
    }
    result[entry.key] = entry.value as String;
  }

  return Map.unmodifiable(result);
}

String _joinPath(String root, Iterable<String> components) {
  var path = root;
  for (final component in components) {
    final normalized = component.replaceAll(RegExp(r'^/+|/+$'), '');
    path = path.endsWith('/') ? '$path$normalized' : '$path/$normalized';
  }

  return path;
}
