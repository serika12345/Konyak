part of '../konyak_cli.dart';

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

  AppSettingsRecord copyWith({
    bool? terminateWineProcessesOnClose,
    String? defaultBottlePath,
    AppAppearanceMode? appearanceMode,
    bool? automaticallyCheckForKonyakUpdates,
    bool? automaticallyCheckForWineUpdates,
  }) {
    return AppSettingsRecord(
      terminateWineProcessesOnClose:
          terminateWineProcessesOnClose ?? this.terminateWineProcessesOnClose,
      defaultBottlePath: defaultBottlePath ?? this.defaultBottlePath,
      appearanceMode: appearanceMode ?? this.appearanceMode,
      automaticallyCheckForKonyakUpdates:
          automaticallyCheckForKonyakUpdates ??
          this.automaticallyCheckForKonyakUpdates,
      automaticallyCheckForWineUpdates:
          automaticallyCheckForWineUpdates ??
          this.automaticallyCheckForWineUpdates,
    );
  }

  static AppSettingsRecord? fromJson(
    Object? value, {
    required String fallbackDefaultBottlePath,
  }) {
    final settings = _objectMap(value);
    if (settings == null) {
      return null;
    }

    final terminateWineProcessesOnClose =
        settings['terminateWineProcessesOnClose'];
    final defaultBottlePath = settings['defaultBottlePath'];
    final appearanceMode = _appAppearanceModeFromJson(
      settings['appearanceMode'],
    );
    final automaticallyCheckForKonyakUpdates =
        settings['automaticallyCheckForKonyakUpdates'];
    final automaticallyCheckForWineUpdates =
        settings['automaticallyCheckForWineUpdates'];

    if (terminateWineProcessesOnClose != null &&
        terminateWineProcessesOnClose is! bool) {
      return null;
    }
    if (defaultBottlePath != null &&
        (defaultBottlePath is! String || defaultBottlePath.trim().isEmpty)) {
      return null;
    }
    if (appearanceMode == null) {
      return null;
    }
    if (automaticallyCheckForKonyakUpdates != null &&
        automaticallyCheckForKonyakUpdates is! bool) {
      return null;
    }
    if (automaticallyCheckForWineUpdates != null &&
        automaticallyCheckForWineUpdates is! bool) {
      return null;
    }

    return AppSettingsRecord(
      terminateWineProcessesOnClose: terminateWineProcessesOnClose is bool
          ? terminateWineProcessesOnClose
          : true,
      defaultBottlePath: defaultBottlePath is String
          ? defaultBottlePath
          : fallbackDefaultBottlePath,
      appearanceMode: appearanceMode,
      automaticallyCheckForKonyakUpdates:
          automaticallyCheckForKonyakUpdates is bool
          ? automaticallyCheckForKonyakUpdates
          : false,
      automaticallyCheckForWineUpdates: automaticallyCheckForWineUpdates is bool
          ? automaticallyCheckForWineUpdates
          : true,
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

AppAppearanceMode? _appAppearanceModeFromJson(Object? value) {
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
