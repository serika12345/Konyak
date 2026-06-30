import 'package:freezed_annotation/freezed_annotation.dart';

import '../../bottles/bottle_summary.dart';

part 'program_configuration_settings.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class ProgramConfigurationSettingsState
    with _$ProgramConfigurationSettingsState {
  const factory ProgramConfigurationSettingsState.loading() =
      LoadingProgramConfigurationSettings;

  const factory ProgramConfigurationSettingsState.ready(
    ProgramSettingsSummary settings,
  ) = ReadyProgramConfigurationSettings;
}

class ProgramEnvironmentEntry {
  const ProgramEnvironmentEntry({required this.name, required this.value});

  final String name;
  final String value;
}

Map<String, String> programEnvironmentFromEntries(
  Iterable<ProgramEnvironmentEntry> entries,
) {
  final environment = <String, String>{};
  for (final entry in entries) {
    final name = entry.name.trim();
    if (name.isEmpty) {
      continue;
    }
    environment[name] = entry.value;
  }

  return Map.unmodifiable(environment);
}

ProgramConfigurationSettingsState
programConfigurationSettingsStateFromNullable({
  required ProgramSettingsSummary? settings,
  required bool isLoading,
}) {
  return switch ((settings, isLoading)) {
    (final ProgramSettingsSummary settings, _) =>
      ProgramConfigurationSettingsState.ready(settings),
    (null, true) => const ProgramConfigurationSettingsState.loading(),
    (null, false) => ProgramConfigurationSettingsState.ready(
      ProgramSettingsSummary(),
    ),
  };
}

ProgramSettingsSummary programConfigurationSettingsForForm(
  ProgramConfigurationSettingsState state,
) {
  return switch (state) {
    ReadyProgramConfigurationSettings(:final settings) => settings,
    LoadingProgramConfigurationSettings() => ProgramSettingsSummary(),
  };
}

bool sameProgramConfigurationSettingsState(
  ProgramConfigurationSettingsState left,
  ProgramConfigurationSettingsState right,
) {
  return switch ((left, right)) {
    (
      ReadyProgramConfigurationSettings(settings: final leftSettings),
      ReadyProgramConfigurationSettings(settings: final rightSettings),
    ) =>
      sameProgramSettings(leftSettings, rightSettings),
    (
      LoadingProgramConfigurationSettings(),
      LoadingProgramConfigurationSettings(),
    ) =>
      true,
    _ => false,
  };
}

bool sameProgramSettings(
  ProgramSettingsSummary left,
  ProgramSettingsSummary right,
) {
  return left.locale == right.locale &&
      left.arguments == right.arguments &&
      left.environment == right.environment &&
      sameProgramLoggingSettings(left.logging, right.logging);
}

bool sameProgramLoggingSettings(
  ProgramLoggingSettingsSummary left,
  ProgramLoggingSettingsSummary right,
) {
  return left.createLogFile == right.createLogFile &&
      left.additionalWineLoggingChannels ==
          right.additionalWineLoggingChannels &&
      left.logFilePath == right.logFilePath;
}
