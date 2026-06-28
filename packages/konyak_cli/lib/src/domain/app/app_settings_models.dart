import '../shared/domain_value_objects.dart';

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

class AppSettingsRecord {
  AppSettingsRecord({
    this.terminateWineProcessesOnClose = false,
    required String defaultBottlePath,
    this.appearanceMode = AppAppearanceMode.dark,
    this.languageMode = AppLanguageMode.system,
    this.automaticallyCheckForKonyakUpdates = false,
    this.automaticallyCheckForWineUpdates = true,
    this.automaticallyPinNewInstalledPrograms = true,
  }) : defaultBottlePath = DefaultBottlePath(defaultBottlePath);

  final bool terminateWineProcessesOnClose;
  final DefaultBottlePath defaultBottlePath;
  final AppAppearanceMode appearanceMode;
  final AppLanguageMode languageMode;
  final bool automaticallyCheckForKonyakUpdates;
  final bool automaticallyCheckForWineUpdates;
  final bool automaticallyPinNewInstalledPrograms;

  AppSettingsRecord withTerminateWineProcessesOnClose(
    bool terminateWineProcessesOnClose,
  ) {
    return AppSettingsRecord(
      terminateWineProcessesOnClose: terminateWineProcessesOnClose,
      defaultBottlePath: defaultBottlePath.value,
      appearanceMode: appearanceMode,
      languageMode: languageMode,
      automaticallyCheckForKonyakUpdates: automaticallyCheckForKonyakUpdates,
      automaticallyCheckForWineUpdates: automaticallyCheckForWineUpdates,
      automaticallyPinNewInstalledPrograms:
          automaticallyPinNewInstalledPrograms,
    );
  }

  AppSettingsRecord withDefaultBottlePath(String defaultBottlePath) {
    return AppSettingsRecord(
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

  AppSettingsRecord withAppearanceMode(AppAppearanceMode appearanceMode) {
    return AppSettingsRecord(
      terminateWineProcessesOnClose: terminateWineProcessesOnClose,
      defaultBottlePath: defaultBottlePath.value,
      appearanceMode: appearanceMode,
      languageMode: languageMode,
      automaticallyCheckForKonyakUpdates: automaticallyCheckForKonyakUpdates,
      automaticallyCheckForWineUpdates: automaticallyCheckForWineUpdates,
      automaticallyPinNewInstalledPrograms:
          automaticallyPinNewInstalledPrograms,
    );
  }

  AppSettingsRecord withLanguageMode(AppLanguageMode languageMode) {
    return AppSettingsRecord(
      terminateWineProcessesOnClose: terminateWineProcessesOnClose,
      defaultBottlePath: defaultBottlePath.value,
      appearanceMode: appearanceMode,
      languageMode: languageMode,
      automaticallyCheckForKonyakUpdates: automaticallyCheckForKonyakUpdates,
      automaticallyCheckForWineUpdates: automaticallyCheckForWineUpdates,
      automaticallyPinNewInstalledPrograms:
          automaticallyPinNewInstalledPrograms,
    );
  }

  AppSettingsRecord withAutomaticallyCheckForKonyakUpdates(
    bool automaticallyCheckForKonyakUpdates,
  ) {
    return AppSettingsRecord(
      terminateWineProcessesOnClose: terminateWineProcessesOnClose,
      defaultBottlePath: defaultBottlePath.value,
      appearanceMode: appearanceMode,
      languageMode: languageMode,
      automaticallyCheckForKonyakUpdates: automaticallyCheckForKonyakUpdates,
      automaticallyCheckForWineUpdates: automaticallyCheckForWineUpdates,
      automaticallyPinNewInstalledPrograms:
          automaticallyPinNewInstalledPrograms,
    );
  }

  AppSettingsRecord withAutomaticallyCheckForWineUpdates(
    bool automaticallyCheckForWineUpdates,
  ) {
    return AppSettingsRecord(
      terminateWineProcessesOnClose: terminateWineProcessesOnClose,
      defaultBottlePath: defaultBottlePath.value,
      appearanceMode: appearanceMode,
      languageMode: languageMode,
      automaticallyCheckForKonyakUpdates: automaticallyCheckForKonyakUpdates,
      automaticallyCheckForWineUpdates: automaticallyCheckForWineUpdates,
      automaticallyPinNewInstalledPrograms:
          automaticallyPinNewInstalledPrograms,
    );
  }

  AppSettingsRecord withAutomaticallyPinNewInstalledPrograms(
    bool automaticallyPinNewInstalledPrograms,
  ) {
    return AppSettingsRecord(
      terminateWineProcessesOnClose: terminateWineProcessesOnClose,
      defaultBottlePath: defaultBottlePath.value,
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
      'defaultBottlePath': defaultBottlePath.value,
      'appearanceMode': appearanceMode.jsonValue,
      'languageMode': languageMode.jsonValue,
      'automaticallyCheckForKonyakUpdates': automaticallyCheckForKonyakUpdates,
      'automaticallyCheckForWineUpdates': automaticallyCheckForWineUpdates,
      'automaticallyPinNewInstalledPrograms':
          automaticallyPinNewInstalledPrograms,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is AppSettingsRecord &&
        other.terminateWineProcessesOnClose == terminateWineProcessesOnClose &&
        other.defaultBottlePath == defaultBottlePath &&
        other.appearanceMode == appearanceMode &&
        other.languageMode == languageMode &&
        other.automaticallyCheckForKonyakUpdates ==
            automaticallyCheckForKonyakUpdates &&
        other.automaticallyCheckForWineUpdates ==
            automaticallyCheckForWineUpdates &&
        other.automaticallyPinNewInstalledPrograms ==
            automaticallyPinNewInstalledPrograms;
  }

  @override
  int get hashCode => Object.hash(
    terminateWineProcessesOnClose,
    defaultBottlePath,
    appearanceMode,
    languageMode,
    automaticallyCheckForKonyakUpdates,
    automaticallyCheckForWineUpdates,
    automaticallyPinNewInstalledPrograms,
  );
}
