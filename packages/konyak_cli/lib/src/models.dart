part of '../konyak_cli.dart';

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
