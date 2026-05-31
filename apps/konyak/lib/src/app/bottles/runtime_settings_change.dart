import '../../bottles/bottle_summary.dart';

typedef RuntimeSettingsChanged =
    void Function(
      BottleSummary bottle,
      BottleRuntimeSettingsSummary runtimeSettings,
      String controlKey,
    );
