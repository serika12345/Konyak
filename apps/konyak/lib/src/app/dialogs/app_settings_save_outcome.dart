import 'package:freezed_annotation/freezed_annotation.dart';

import '../../settings/app_settings_summary.dart';

part 'app_settings_save_outcome.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class AppSettingsSaveOutcome with _$AppSettingsSaveOutcome {
  const AppSettingsSaveOutcome._();

  const factory AppSettingsSaveOutcome.saved(AppSettingsSummary settings) =
      _SavedAppSettings;

  const factory AppSettingsSaveOutcome.failed() = _FailedAppSettingsSave;

  const factory AppSettingsSaveOutcome.unmounted() = _UnmountedAppSettingsSave;

  AppSettingsSummary settingsOr(AppSettingsSummary fallback) {
    return switch (this) {
      _SavedAppSettings(:final settings) => settings,
      _FailedAppSettingsSave() => fallback,
      _UnmountedAppSettingsSave() => fallback,
    };
  }
}
