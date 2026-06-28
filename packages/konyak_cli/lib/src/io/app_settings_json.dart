import 'package:fpdart/fpdart.dart';

import '../domain/app/app_settings_models.dart';
import 'external_payload_helpers.dart';

Map<String, Object?> appSettingsRecordJson(AppSettingsRecord settings) {
  return <String, Object?>{
    'terminateWineProcessesOnClose': settings.terminateWineProcessesOnClose,
    'defaultBottlePath': settings.defaultBottlePath.value,
    'appearanceMode': appAppearanceModeJsonValue(settings.appearanceMode),
    'languageMode': appLanguageModeJsonValue(settings.languageMode),
    'automaticallyCheckForKonyakUpdates':
        settings.automaticallyCheckForKonyakUpdates,
    'automaticallyCheckForWineUpdates':
        settings.automaticallyCheckForWineUpdates,
    'automaticallyPinNewInstalledPrograms':
        settings.automaticallyPinNewInstalledPrograms,
  };
}

String appAppearanceModeJsonValue(AppAppearanceMode mode) {
  return switch (mode) {
    AppAppearanceMode.dark => 'dark',
    AppAppearanceMode.light => 'light',
    AppAppearanceMode.system => 'system',
  };
}

String appLanguageModeJsonValue(AppLanguageMode mode) {
  return switch (mode) {
    AppLanguageMode.system => 'system',
    AppLanguageMode.english => 'en',
    AppLanguageMode.japanese => 'ja',
  };
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
  return switch (value) {
    null => Option.of(AppAppearanceMode.dark),
    'dark' => Option.of(AppAppearanceMode.dark),
    'light' => Option.of(AppAppearanceMode.light),
    'system' => Option.of(AppAppearanceMode.system),
    _ => const Option.none(),
  };
}

Option<AppLanguageMode> appLanguageModeFromJson(Object? value) {
  return switch (value) {
    null => Option.of(AppLanguageMode.system),
    'system' => Option.of(AppLanguageMode.system),
    'en' => Option.of(AppLanguageMode.english),
    'ja' => Option.of(AppLanguageMode.japanese),
    _ => const Option.none(),
  };
}
