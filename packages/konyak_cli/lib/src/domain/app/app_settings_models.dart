part of '../../../konyak_cli.dart';

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

  AppSettingsRecord withTerminateWineProcessesOnClose(
    bool terminateWineProcessesOnClose,
  ) {
    return AppSettingsRecord(
      terminateWineProcessesOnClose: terminateWineProcessesOnClose,
      defaultBottlePath: defaultBottlePath,
      appearanceMode: appearanceMode,
      automaticallyCheckForKonyakUpdates: automaticallyCheckForKonyakUpdates,
      automaticallyCheckForWineUpdates: automaticallyCheckForWineUpdates,
    );
  }

  AppSettingsRecord withDefaultBottlePath(String defaultBottlePath) {
    return AppSettingsRecord(
      terminateWineProcessesOnClose: terminateWineProcessesOnClose,
      defaultBottlePath: defaultBottlePath,
      appearanceMode: appearanceMode,
      automaticallyCheckForKonyakUpdates: automaticallyCheckForKonyakUpdates,
      automaticallyCheckForWineUpdates: automaticallyCheckForWineUpdates,
    );
  }

  AppSettingsRecord withAppearanceMode(AppAppearanceMode appearanceMode) {
    return AppSettingsRecord(
      terminateWineProcessesOnClose: terminateWineProcessesOnClose,
      defaultBottlePath: defaultBottlePath,
      appearanceMode: appearanceMode,
      automaticallyCheckForKonyakUpdates: automaticallyCheckForKonyakUpdates,
      automaticallyCheckForWineUpdates: automaticallyCheckForWineUpdates,
    );
  }

  AppSettingsRecord withAutomaticallyCheckForKonyakUpdates(
    bool automaticallyCheckForKonyakUpdates,
  ) {
    return AppSettingsRecord(
      terminateWineProcessesOnClose: terminateWineProcessesOnClose,
      defaultBottlePath: defaultBottlePath,
      appearanceMode: appearanceMode,
      automaticallyCheckForKonyakUpdates: automaticallyCheckForKonyakUpdates,
      automaticallyCheckForWineUpdates: automaticallyCheckForWineUpdates,
    );
  }

  AppSettingsRecord withAutomaticallyCheckForWineUpdates(
    bool automaticallyCheckForWineUpdates,
  ) {
    return AppSettingsRecord(
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
