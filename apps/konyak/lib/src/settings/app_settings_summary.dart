enum AppAppearanceMode {
  dark('dark'),
  light('light'),
  system('system');

  const AppAppearanceMode(this.jsonValue);

  final String jsonValue;
}

class AppSettingsSummary {
  const AppSettingsSummary({
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

  AppSettingsSummary withTerminateWineProcessesOnClose(
    bool terminateWineProcessesOnClose,
  ) {
    return AppSettingsSummary(
      terminateWineProcessesOnClose: terminateWineProcessesOnClose,
      defaultBottlePath: defaultBottlePath,
      appearanceMode: appearanceMode,
      automaticallyCheckForKonyakUpdates: automaticallyCheckForKonyakUpdates,
      automaticallyCheckForWineUpdates: automaticallyCheckForWineUpdates,
    );
  }

  AppSettingsSummary withDefaultBottlePath(String defaultBottlePath) {
    return AppSettingsSummary(
      terminateWineProcessesOnClose: terminateWineProcessesOnClose,
      defaultBottlePath: defaultBottlePath,
      appearanceMode: appearanceMode,
      automaticallyCheckForKonyakUpdates: automaticallyCheckForKonyakUpdates,
      automaticallyCheckForWineUpdates: automaticallyCheckForWineUpdates,
    );
  }

  AppSettingsSummary withAppearanceMode(AppAppearanceMode appearanceMode) {
    return AppSettingsSummary(
      terminateWineProcessesOnClose: terminateWineProcessesOnClose,
      defaultBottlePath: defaultBottlePath,
      appearanceMode: appearanceMode,
      automaticallyCheckForKonyakUpdates: automaticallyCheckForKonyakUpdates,
      automaticallyCheckForWineUpdates: automaticallyCheckForWineUpdates,
    );
  }

  AppSettingsSummary withAutomaticallyCheckForKonyakUpdates(
    bool automaticallyCheckForKonyakUpdates,
  ) {
    return AppSettingsSummary(
      terminateWineProcessesOnClose: terminateWineProcessesOnClose,
      defaultBottlePath: defaultBottlePath,
      appearanceMode: appearanceMode,
      automaticallyCheckForKonyakUpdates: automaticallyCheckForKonyakUpdates,
      automaticallyCheckForWineUpdates: automaticallyCheckForWineUpdates,
    );
  }

  AppSettingsSummary withAutomaticallyCheckForWineUpdates(
    bool automaticallyCheckForWineUpdates,
  ) {
    return AppSettingsSummary(
      terminateWineProcessesOnClose: terminateWineProcessesOnClose,
      defaultBottlePath: defaultBottlePath,
      appearanceMode: appearanceMode,
      automaticallyCheckForKonyakUpdates: automaticallyCheckForKonyakUpdates,
      automaticallyCheckForWineUpdates: automaticallyCheckForWineUpdates,
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
