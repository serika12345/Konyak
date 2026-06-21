part of '../../konyak_cli.dart';

BottleRepository defaultBottleRepositoryFromEnvironment(
  Map<String, String> environment, {
  KonyakHostPlatform? hostPlatform,
  AppSettingsRecord? appSettings,
}) {
  final platform = hostPlatform ?? _currentHostPlatform();
  final hostEnvironment = HostEnvironment(environment);
  return _defaultFileBottleRepository(
    dataHome: _resolveBottleDataHome(hostEnvironment, hostPlatform: platform),
    defaultBottlePath:
        appSettings?.defaultBottlePath ??
        _defaultBottlePath(hostEnvironment, hostPlatform: platform),
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
  IoResult<AppSettingsRecord> read() {
    return Right<String, AppSettingsRecord>(_settings);
  }

  @override
  IoResult<AppSettingsRecord> write(AppSettingsRecord settings) {
    _settings = settings;
    return Right<String, AppSettingsRecord>(_settings);
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
    final hostEnvironment = HostEnvironment(environment);
    return FileAppSettingsRepository(
      configHome: _resolveConfigHome(hostEnvironment, hostPlatform: platform),
      fallbackDefaultBottlePath: _defaultBottlePath(
        hostEnvironment,
        hostPlatform: platform,
      ),
    );
  }

  final String configHome;
  final String fallbackDefaultBottlePath;

  @override
  IoResult<AppSettingsRecord> read() {
    final file = File(_appSettingsJsonPath(configHome));
    if (!file.existsSync()) {
      return Right<String, AppSettingsRecord>(
        AppSettingsRecord(defaultBottlePath: fallbackDefaultBottlePath),
      );
    }

    return _ioResult(() {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, Object?> ||
          decoded['schemaVersion'] != cliSchemaVersion) {
        throw const FormatException('Unsupported app settings schema.');
      }

      final settings = _appSettingsRecordFromJson(
        decoded['appSettings'],
        fallbackDefaultBottlePath: fallbackDefaultBottlePath,
      );
      return settings.match(
        () => throw const FormatException('Invalid app settings record.'),
        (value) => value,
      );
    });
  }

  @override
  IoResult<AppSettingsRecord> write(AppSettingsRecord settings) {
    return _ioResult(() {
      final file = File(_appSettingsJsonPath(configHome));
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(<String, Object?>{
          'schemaVersion': cliSchemaVersion,
          'appSettings': settings.toJson(),
        }),
      );
      return settings;
    });
  }
}

Option<AppSettingsRecord> _appSettingsRecordFromJson(
  Object? value, {
  required String fallbackDefaultBottlePath,
}) {
  final settings = _objectMap(value);
  if (settings == null) {
    return const Option.none();
  }

  final terminateWineProcessesOnClose =
      settings['terminateWineProcessesOnClose'];
  final defaultBottlePath = settings['defaultBottlePath'];
  final appearanceMode = _appAppearanceModeFromJson(settings['appearanceMode']);
  final automaticallyCheckForKonyakUpdates =
      settings['automaticallyCheckForKonyakUpdates'];
  final automaticallyCheckForWineUpdates =
      settings['automaticallyCheckForWineUpdates'];
  final automaticallyPinNewInstalledPrograms =
      settings['automaticallyPinNewInstalledPrograms'];

  if (terminateWineProcessesOnClose != null &&
      terminateWineProcessesOnClose is! bool) {
    return const Option.none();
  }
  if (defaultBottlePath != null &&
      (defaultBottlePath is! String || defaultBottlePath.trim().isEmpty)) {
    return const Option.none();
  }
  final parsedAppearanceMode = appearanceMode.match<AppAppearanceMode?>(
    () => null,
    (value) => value,
  );
  if (parsedAppearanceMode == null) {
    return const Option.none();
  }
  if (automaticallyCheckForKonyakUpdates != null &&
      automaticallyCheckForKonyakUpdates is! bool) {
    return const Option.none();
  }
  if (automaticallyCheckForWineUpdates != null &&
      automaticallyCheckForWineUpdates is! bool) {
    return const Option.none();
  }
  if (automaticallyPinNewInstalledPrograms != null &&
      automaticallyPinNewInstalledPrograms is! bool) {
    return const Option.none();
  }

  return Option.of(
    AppSettingsRecord(
      terminateWineProcessesOnClose: terminateWineProcessesOnClose is bool
          ? terminateWineProcessesOnClose
          : true,
      defaultBottlePath: defaultBottlePath is String
          ? defaultBottlePath
          : fallbackDefaultBottlePath,
      appearanceMode: parsedAppearanceMode,
      automaticallyCheckForKonyakUpdates:
          automaticallyCheckForKonyakUpdates is bool
          ? automaticallyCheckForKonyakUpdates
          : false,
      automaticallyCheckForWineUpdates: automaticallyCheckForWineUpdates is bool
          ? automaticallyCheckForWineUpdates
          : true,
      automaticallyPinNewInstalledPrograms:
          automaticallyPinNewInstalledPrograms is bool
          ? automaticallyPinNewInstalledPrograms
          : true,
    ),
  );
}

Option<AppAppearanceMode> _appAppearanceModeFromJson(Object? value) {
  if (value == null) {
    return Option.of(AppAppearanceMode.dark);
  }
  if (value is! String) {
    return const Option.none();
  }

  for (final mode in AppAppearanceMode.values) {
    if (mode.jsonValue == value) {
      return Option.of(mode);
    }
  }

  return const Option.none();
}
