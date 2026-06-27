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
    defaultBottlePath: Option.of(switch (appSettings) {
      final AppSettingsRecord settings => settings.defaultBottlePath.value,
      _ => _defaultBottlePath(hostEnvironment, hostPlatform: platform),
    }),
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
  Option<String> defaultBottlePath = const Option.none(),
}) {
  final defaultBottleDirectory = _joinPath(dataHome, const ['bottles']);
  final usesDefaultBottleDirectory = defaultBottlePath.match(
    () => true,
    (path) =>
        _normalizeFilesystemPath(path) ==
        _normalizeFilesystemPath(defaultBottleDirectory),
  );
  if (usesDefaultBottleDirectory) {
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
  final languageMode = _appLanguageModeFromJson(settings['languageMode']);
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

  return appearanceMode.match(
    () => const Option.none(),
    (parsedAppearanceMode) => languageMode.match(
      () => const Option.none(),
      (parsedLanguageMode) => Option.of(
        AppSettingsRecord(
          terminateWineProcessesOnClose: terminateWineProcessesOnClose is bool
              ? terminateWineProcessesOnClose
              : false,
          defaultBottlePath: defaultBottlePath is String
              ? defaultBottlePath
              : fallbackDefaultBottlePath,
          appearanceMode: parsedAppearanceMode,
          languageMode: parsedLanguageMode,
          automaticallyCheckForKonyakUpdates:
              automaticallyCheckForKonyakUpdates is bool
              ? automaticallyCheckForKonyakUpdates
              : false,
          automaticallyCheckForWineUpdates:
              automaticallyCheckForWineUpdates is bool
              ? automaticallyCheckForWineUpdates
              : true,
          automaticallyPinNewInstalledPrograms:
              automaticallyPinNewInstalledPrograms is bool
              ? automaticallyPinNewInstalledPrograms
              : true,
        ),
      ),
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

Option<AppLanguageMode> _appLanguageModeFromJson(Object? value) {
  if (value == null) {
    return Option.of(AppLanguageMode.system);
  }
  if (value is! String) {
    return const Option.none();
  }

  for (final mode in AppLanguageMode.values) {
    if (mode.jsonValue == value) {
      return Option.of(mode);
    }
  }

  return const Option.none();
}
