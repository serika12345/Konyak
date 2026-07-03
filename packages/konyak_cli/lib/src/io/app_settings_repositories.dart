import 'dart:convert';
import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../domain/app/app_settings_models.dart';
import '../domain/program/program_runner.dart';
import '../domain/runtime/host_environment.dart';
import '../domain/shared/domain_value_objects.dart';
import '../repository/composite_bottle_repository.dart';
import '../repository/file_bottle_repository.dart';
import '../repository/repository_interfaces.dart';
import '../shared/common_helpers.dart';
import '../shared/model_constants.dart';
import '../storage/storage_paths.dart';
import 'app_settings_json.dart';
import 'io_result.dart';
import 'platform_host_paths.dart';
import 'program_metadata_io.dart';

BottleRepository defaultBottleRepositoryFromEnvironment(
  Map<String, String> environment, {
  KonyakHostPlatform? hostPlatform,
  AppSettingsRecord? appSettings,
}) {
  final platform = hostPlatform ?? currentHostPlatform();
  final hostEnvironment = HostEnvironment(environment);
  return defaultFileBottleRepository(
    dataHome: resolveBottleDataHome(hostEnvironment, hostPlatform: platform),
    defaultBottlePath: Option.of(switch (appSettings) {
      final AppSettingsRecord settings => settings.defaultBottlePath.value,
      _ => defaultBottlePath(hostEnvironment, hostPlatform: platform),
    }),
  );
}

AppSettingsRepository defaultAppSettingsRepositoryFromEnvironment(
  Map<String, String> environment, {
  KonyakHostPlatform? hostPlatform,
}) {
  final platform = hostPlatform ?? currentHostPlatform();
  return FileAppSettingsRepository.fromEnvironment(
    environment,
    hostPlatform: platform,
  );
}

BottleRepository defaultFileBottleRepository({
  required String dataHome,
  Option<String> defaultBottlePath = const Option.none(),
}) {
  final defaultBottleDirectory = joinPath(dataHome, const ['bottles']);
  final usesDefaultBottleDirectory = defaultBottlePath.match(
    () => true,
    (path) =>
        normalizeFilesystemPath(path) ==
        normalizeFilesystemPath(defaultBottleDirectory),
  );
  if (usesDefaultBottleDirectory) {
    return FileBottleRepository(
      dataHome: dataHome,
      bottleDirectory: defaultBottlePath,
      programMetadataExtractor: const DartIoProgramMetadataExtractor(),
    );
  }

  return CompositeBottleRepository(
    catalogs: <BottleCatalog>[
      FileBottleRepository(
        dataHome: dataHome,
        programMetadataExtractor: const DartIoProgramMetadataExtractor(),
      ),
    ],
    writableRepository: FileBottleRepository(
      dataHome: dataHome,
      bottleDirectory: defaultBottlePath,
      programMetadataExtractor: const DartIoProgramMetadataExtractor(),
    ),
  );
}

class MemoryAppSettingsRepository implements AppSettingsRepository {
  MemoryAppSettingsRepository(this.settings);

  AppSettingsRecord settings;

  @override
  IoResult<AppSettingsRecord> read() {
    return Right<String, AppSettingsRecord>(settings);
  }

  @override
  IoResult<AppSettingsRecord> write(AppSettingsRecord settings) {
    this.settings = settings;
    return Right<String, AppSettingsRecord>(settings);
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
    final platform = hostPlatform ?? currentHostPlatform();
    final hostEnvironment = HostEnvironment(environment);
    return FileAppSettingsRepository(
      configHome: resolveConfigHome(hostEnvironment, hostPlatform: platform),
      fallbackDefaultBottlePath: defaultBottlePath(
        hostEnvironment,
        hostPlatform: platform,
      ),
    );
  }

  final String configHome;
  final String fallbackDefaultBottlePath;

  @override
  IoResult<AppSettingsRecord> read() {
    final file = File(appSettingsJsonPath(configHome));
    if (!file.existsSync()) {
      return Right<String, AppSettingsRecord>(
        AppSettingsRecord(
          defaultBottlePath: DefaultBottlePath(fallbackDefaultBottlePath),
        ),
      );
    }

    return ioResult(() {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, Object?> ||
          decoded['schemaVersion'] != cliSchemaVersion) {
        throw const FormatException('Unsupported app settings schema.');
      }

      final settings = appSettingsRecordFromJson(
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
    return ioResult(() {
      final file = File(appSettingsJsonPath(configHome));
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(<String, Object?>{
          'schemaVersion': cliSchemaVersion,
          'appSettings': appSettingsRecordJson(settings),
        }),
      );
      return settings;
    });
  }
}
