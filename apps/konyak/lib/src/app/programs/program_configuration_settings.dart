import 'package:freezed_annotation/freezed_annotation.dart';

import '../../bottles/bottle_summary.dart';

part 'program_configuration_settings.freezed.dart';

typedef ProgramSettingsChanged =
    void Function(
      BottleSummary bottle,
      PinnedProgramSummary program,
      ProgramSettingsSummary settings,
    );
typedef ProgramSettingsChangeDispatchCallback = void Function();

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

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class ProgramSettingsChangeAvailability
    with _$ProgramSettingsChangeAvailability {
  const factory ProgramSettingsChangeAvailability.unavailable() =
      UnavailableProgramSettingsChangeAvailability;

  const factory ProgramSettingsChangeAvailability.available(
    ProgramSettingsChanged invoke,
  ) = AvailableProgramSettingsChangeAvailability;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class ProgramSettingsChangeDispatch
    with _$ProgramSettingsChangeDispatch {
  const factory ProgramSettingsChangeDispatch.unavailable() =
      UnavailableProgramSettingsChangeDispatch;

  const factory ProgramSettingsChangeDispatch.available(
    ProgramSettingsChangeDispatchCallback invoke,
  ) = AvailableProgramSettingsChangeDispatch;
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

ProgramSettingsChangeAvailability programSettingsChangeAvailabilityFromNullable(
  ProgramSettingsChanged? action,
) {
  return switch (action) {
    null => const ProgramSettingsChangeAvailability.unavailable(),
    final action => ProgramSettingsChangeAvailability.available(action),
  };
}

bool canChangeProgramSettings(ProgramSettingsChangeAvailability action) {
  return switch (action) {
    AvailableProgramSettingsChangeAvailability() => true,
    UnavailableProgramSettingsChangeAvailability() => false,
  };
}

ProgramSettingsChangeDispatch resolveProgramSettingsChange({
  required BottleSummary bottle,
  required PinnedProgramSummary program,
  required ProgramSettingsSummary settings,
  required ProgramSettingsChangeAvailability action,
}) {
  return switch (action) {
    AvailableProgramSettingsChangeAvailability(:final invoke) =>
      ProgramSettingsChangeDispatch.available(
        () => invoke(bottle, program, settings),
      ),
    UnavailableProgramSettingsChangeAvailability() =>
      const ProgramSettingsChangeDispatch.unavailable(),
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
      left.workingDirectory.kind == right.workingDirectory.kind &&
      left.workingDirectory.path == right.workingDirectory.path &&
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
