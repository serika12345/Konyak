import '../settings/app_settings_summary.dart';

sealed class AppSettingsLoadResult {
  const AppSettingsLoadResult();
}

final class LoadedAppSettings extends AppSettingsLoadResult {
  const LoadedAppSettings(this.settings);

  final AppSettingsSummary settings;
}

final class AppSettingsLoadFailure extends AppSettingsLoadResult {
  const AppSettingsLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}
