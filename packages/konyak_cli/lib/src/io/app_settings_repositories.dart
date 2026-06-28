import 'dart:convert';
import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../domain/app/app_settings_models.dart';
import '../domain/program/program_runner.dart';
import '../domain/runtime/host_environment.dart';
import '../repository/composite_bottle_repository.dart';
import '../repository/file_bottle_repository.dart';
import '../repository/repository_interfaces.dart';
import '../shared/common_helpers.dart';
import '../shared/model_constants.dart';
import '../storage/storage_paths.dart';
import 'external_payload_helpers.dart';
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
        AppSettingsRecord(defaultBottlePath: fallbackDefaultBottlePath),
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
          'appSettings': settings.toJson(),
        }),
      );
      return settings;
    });
  }
}

Option<AppSettingsRecord> appSettingsRecordFromJson(
  Object? value, {
  required String fallbackDefaultBottlePath,
}) {
  final settings = objectMap(value);
  if (settings == null) {
    return const Option.none();
  }

  final terminateWineProcessesOnClose =
      settings['terminateWineProcessesOnClose'];
  final defaultBottlePath = settings['defaultBottlePath'];
  final appearanceMode = appAppearanceModeFromJson(settings['appearanceMode']);
  final languageMode = appLanguageModeFromJson(settings['languageMode']);
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

Option<AppAppearanceMode> appAppearanceModeFromJson(Object? value) {
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

Option<AppLanguageMode> appLanguageModeFromJson(Object? value) {
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
