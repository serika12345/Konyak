import 'package:freezed_annotation/freezed_annotation.dart';

import '../settings/app_settings_summary.dart';

part 'app_settings_state.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class AppSettingsState with _$AppSettingsState {
  const factory AppSettingsState.loaded(AppSettingsSummary settings) =
      LoadedAppSettingsState;

  const factory AppSettingsState.unavailable() = UnavailableAppSettingsState;
}

bool shouldAutomaticallyPinNewInstalledPrograms(AppSettingsState state) {
  return switch (state) {
    LoadedAppSettingsState(:final settings) =>
      settings.automaticallyPinNewInstalledPrograms,
    UnavailableAppSettingsState() => false,
  };
}

bool shouldTerminateWineProcessesOnClose(AppSettingsState state) {
  return switch (state) {
    LoadedAppSettingsState(:final settings) =>
      settings.terminateWineProcessesOnClose,
    UnavailableAppSettingsState() => false,
  };
}
