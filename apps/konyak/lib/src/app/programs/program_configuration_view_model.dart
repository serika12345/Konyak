import '../../bottles/bottle_summary.dart';
import 'program_configuration_settings.dart';
import 'program_settings_controls.dart';

sealed class ProgramConfigurationViewModel {
  const ProgramConfigurationViewModel();
}

final class LoadingProgramConfigurationViewModel
    extends ProgramConfigurationViewModel {
  const LoadingProgramConfigurationViewModel();
}

final class ReadyProgramConfigurationViewModel
    extends ProgramConfigurationViewModel {
  const ReadyProgramConfigurationViewModel({
    required this.defaultLogPath,
    required this.canSave,
  });

  final String defaultLogPath;
  final bool canSave;
}

ProgramConfigurationViewModel programConfigurationViewModel({
  required BottleSummary bottle,
  required ProgramConfigurationSettingsState settingsState,
  required ProgramSettingsChangeAvailability programSettingsChangeAction,
}) {
  return switch (settingsState) {
    LoadingProgramConfigurationSettings() =>
      const LoadingProgramConfigurationViewModel(),
    ReadyProgramConfigurationSettings() => ReadyProgramConfigurationViewModel(
      defaultLogPath: programDefaultLogPath(bottle.path),
      canSave: canChangeProgramSettings(programSettingsChangeAction),
    ),
  };
}

ProgramSettingsChangeDispatch resolveProgramConfigurationSave({
  required BottleSummary bottle,
  required PinnedProgramSummary program,
  required ProgramSettingsSummary settings,
  required ProgramSettingsChangeAvailability action,
}) {
  return resolveProgramSettingsChange(
    bottle: bottle,
    program: program,
    settings: settings,
    action: action,
  );
}
