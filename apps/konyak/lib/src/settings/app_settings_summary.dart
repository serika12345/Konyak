import 'dart:ui';

enum AppAppearanceMode {
  dark('dark'),
  light('light'),
  system('system');

  const AppAppearanceMode(this.jsonValue);

  final String jsonValue;
}

enum AppLanguageMode {
  system('system'),
  english('en'),
  japanese('ja');

  const AppLanguageMode(this.jsonValue);

  final String jsonValue;
}

class AppSettingsSummary {
  const AppSettingsSummary({
    this.terminateWineProcessesOnClose = true,
    required this.defaultBottlePath,
    this.appearanceMode = AppAppearanceMode.dark,
    this.languageMode = AppLanguageMode.system,
    this.automaticallyCheckForKonyakUpdates = false,
    this.automaticallyCheckForWineUpdates = true,
    this.automaticallyPinNewInstalledPrograms = true,
  });

  final bool terminateWineProcessesOnClose;
  final String defaultBottlePath;
  final AppAppearanceMode appearanceMode;
  final AppLanguageMode languageMode;
  final bool automaticallyCheckForKonyakUpdates;
  final bool automaticallyCheckForWineUpdates;
  final bool automaticallyPinNewInstalledPrograms;

  AppSettingsSummary withTerminateWineProcessesOnClose(
    bool terminateWineProcessesOnClose,
  ) {
    return AppSettingsSummary(
      terminateWineProcessesOnClose: terminateWineProcessesOnClose,
      defaultBottlePath: defaultBottlePath,
      appearanceMode: appearanceMode,
      languageMode: languageMode,
      automaticallyCheckForKonyakUpdates: automaticallyCheckForKonyakUpdates,
      automaticallyCheckForWineUpdates: automaticallyCheckForWineUpdates,
      automaticallyPinNewInstalledPrograms:
          automaticallyPinNewInstalledPrograms,
    );
  }

  AppSettingsSummary withDefaultBottlePath(String defaultBottlePath) {
    return AppSettingsSummary(
      terminateWineProcessesOnClose: terminateWineProcessesOnClose,
      defaultBottlePath: defaultBottlePath,
      appearanceMode: appearanceMode,
      languageMode: languageMode,
      automaticallyCheckForKonyakUpdates: automaticallyCheckForKonyakUpdates,
      automaticallyCheckForWineUpdates: automaticallyCheckForWineUpdates,
      automaticallyPinNewInstalledPrograms:
          automaticallyPinNewInstalledPrograms,
    );
  }

  AppSettingsSummary withAppearanceMode(AppAppearanceMode appearanceMode) {
    return AppSettingsSummary(
      terminateWineProcessesOnClose: terminateWineProcessesOnClose,
      defaultBottlePath: defaultBottlePath,
      appearanceMode: appearanceMode,
      languageMode: languageMode,
      automaticallyCheckForKonyakUpdates: automaticallyCheckForKonyakUpdates,
      automaticallyCheckForWineUpdates: automaticallyCheckForWineUpdates,
      automaticallyPinNewInstalledPrograms:
          automaticallyPinNewInstalledPrograms,
    );
  }

  AppSettingsSummary withLanguageMode(AppLanguageMode languageMode) {
    return AppSettingsSummary(
      terminateWineProcessesOnClose: terminateWineProcessesOnClose,
      defaultBottlePath: defaultBottlePath,
      appearanceMode: appearanceMode,
      languageMode: languageMode,
      automaticallyCheckForKonyakUpdates: automaticallyCheckForKonyakUpdates,
      automaticallyCheckForWineUpdates: automaticallyCheckForWineUpdates,
      automaticallyPinNewInstalledPrograms:
          automaticallyPinNewInstalledPrograms,
    );
  }

  AppSettingsSummary withAutomaticallyCheckForKonyakUpdates(
    bool automaticallyCheckForKonyakUpdates,
  ) {
    return AppSettingsSummary(
      terminateWineProcessesOnClose: terminateWineProcessesOnClose,
      defaultBottlePath: defaultBottlePath,
      appearanceMode: appearanceMode,
      languageMode: languageMode,
      automaticallyCheckForKonyakUpdates: automaticallyCheckForKonyakUpdates,
      automaticallyCheckForWineUpdates: automaticallyCheckForWineUpdates,
      automaticallyPinNewInstalledPrograms:
          automaticallyPinNewInstalledPrograms,
    );
  }

  AppSettingsSummary withAutomaticallyCheckForWineUpdates(
    bool automaticallyCheckForWineUpdates,
  ) {
    return AppSettingsSummary(
      terminateWineProcessesOnClose: terminateWineProcessesOnClose,
      defaultBottlePath: defaultBottlePath,
      appearanceMode: appearanceMode,
      languageMode: languageMode,
      automaticallyCheckForKonyakUpdates: automaticallyCheckForKonyakUpdates,
      automaticallyCheckForWineUpdates: automaticallyCheckForWineUpdates,
      automaticallyPinNewInstalledPrograms:
          automaticallyPinNewInstalledPrograms,
    );
  }

  AppSettingsSummary withAutomaticallyPinNewInstalledPrograms(
    bool automaticallyPinNewInstalledPrograms,
  ) {
    return AppSettingsSummary(
      terminateWineProcessesOnClose: terminateWineProcessesOnClose,
      defaultBottlePath: defaultBottlePath,
      appearanceMode: appearanceMode,
      languageMode: languageMode,
      automaticallyCheckForKonyakUpdates: automaticallyCheckForKonyakUpdates,
      automaticallyCheckForWineUpdates: automaticallyCheckForWineUpdates,
      automaticallyPinNewInstalledPrograms:
          automaticallyPinNewInstalledPrograms,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'terminateWineProcessesOnClose': terminateWineProcessesOnClose,
      'defaultBottlePath': defaultBottlePath,
      'appearanceMode': appearanceMode.jsonValue,
      'languageMode': languageMode.jsonValue,
      'automaticallyCheckForKonyakUpdates': automaticallyCheckForKonyakUpdates,
      'automaticallyCheckForWineUpdates': automaticallyCheckForWineUpdates,
      'automaticallyPinNewInstalledPrograms':
          automaticallyPinNewInstalledPrograms,
    };
  }
}

AppAppearanceMode? appAppearanceModeFromJson(Object? value) {
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

AppLanguageMode? appLanguageModeFromJson(Object? value) {
  if (value == null) {
    return AppLanguageMode.system;
  }
  if (value is! String) {
    return null;
  }

  for (final mode in AppLanguageMode.values) {
    if (mode.jsonValue == value) {
      return mode;
    }
  }

  return null;
}

Locale? localeForAppLanguageMode(AppLanguageMode mode) {
  return switch (mode) {
    AppLanguageMode.system => null,
    AppLanguageMode.english => const Locale('en'),
    AppLanguageMode.japanese => const Locale('ja'),
  };
}
