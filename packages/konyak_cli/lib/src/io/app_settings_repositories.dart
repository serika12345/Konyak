part of '../../konyak_cli.dart';

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

      final settings = AppSettingsRecord.fromJson(
        decoded['appSettings'],
        fallbackDefaultBottlePath: fallbackDefaultBottlePath,
      );
      if (settings == null) {
        throw const FormatException('Invalid app settings record.');
      }

      return settings;
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
