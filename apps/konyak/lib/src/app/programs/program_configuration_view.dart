import 'package:flutter/material.dart';

import '../../bottles/bottle_summary.dart';
import '../../files/file_path_pick_result.dart';
import '../../files/log_file_picker.dart';
import '../../l10n/konyak_localizations.dart';
import '../app_constants.dart';
import '../widgets/konyak_bottom_button.dart';
import 'program_configuration_settings.dart';
import 'program_configuration_view_model.dart';
import 'program_settings_controls.dart';
import 'program_settings_form_controller.dart';

class ProgramConfigurationView extends StatefulWidget {
  const ProgramConfigurationView({
    super.key,
    required this.bottle,
    required this.program,
    required this.settingsState,
    required this.programSettingsChangeAction,
    this.logFilePicker = const FileSelectorLogFilePicker(),
  });

  final BottleSummary bottle;
  final PinnedProgramSummary program;
  final ProgramConfigurationSettingsState settingsState;
  final LogFilePicker logFilePicker;
  final ProgramSettingsChangeAvailability programSettingsChangeAction;

  @override
  State<ProgramConfigurationView> createState() =>
      _ProgramConfigurationViewState();
}

class _ProgramConfigurationViewState extends State<ProgramConfigurationView> {
  late final ProgramSettingsFormController _settingsController;

  @override
  void initState() {
    super.initState();
    _settingsController = ProgramSettingsFormController.fromSettings(
      programConfigurationSettingsForForm(widget.settingsState),
    );
  }

  @override
  void didUpdateWidget(covariant ProgramConfigurationView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.program.path != widget.program.path ||
        !sameProgramConfigurationSettingsState(
          oldWidget.settingsState,
          widget.settingsState,
        )) {
      _settingsController.replaceSettings(
        programConfigurationSettingsForForm(widget.settingsState),
      );
    }
  }

  @override
  void dispose() {
    _settingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);
    final localizations = KonyakLocalizations.of(context);
    final viewModel = programConfigurationViewModel(
      bottle: widget.bottle,
      settingsState: widget.settingsState,
      programSettingsChangeAction: widget.programSettingsChangeAction,
    );

    switch (viewModel) {
      case LoadingProgramConfigurationViewModel():
        return Center(child: CircularProgressIndicator(color: colors.accent));
      case final ReadyProgramConfigurationViewModel readyViewModel:
        return _settingsBody(
          localizations: localizations,
          viewModel: readyViewModel,
        );
    }
  }

  Widget _settingsBody({
    required KonyakLocalizations localizations,
    required ReadyProgramConfigurationViewModel viewModel,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProgramSettingsControls(
            keyPrefix: 'program-config',
            locale: _settingsController.locale,
            argumentsController: _settingsController.argumentsController,
            workingDirectoryKind: _settingsController.workingDirectoryKind,
            workingDirectoryController:
                _settingsController.workingDirectoryController,
            environmentControllers: _settingsController.environmentControllers,
            createLogFile: _settingsController.createLogFile,
            wineLoggingChannelsController:
                _settingsController.wineLoggingChannelsController,
            logFilePathController: _settingsController.logFilePathController,
            defaultLogPath: viewModel.defaultLogPath,
            onLocaleChanged: (locale) {
              setState(() {
                _settingsController.setLocale(locale);
              });
            },
            onWorkingDirectoryKindChanged: (kind) {
              setState(() {
                _settingsController.setWorkingDirectoryKind(kind);
              });
            },
            onWorkingDirectoryPathChanged: (_) {
              setState(() {});
            },
            onCreateLogFileChanged: (value) {
              setState(() {
                _settingsController.setCreateLogFile(value);
              });
            },
            onChooseLogFile: _chooseLogFile,
            onAddEnvironmentVariable: _addEnvironmentVariable,
            onRemoveEnvironmentVariable: _removeEnvironmentVariable,
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: KonyakBottomButton(
              key: const ValueKey('program-config-save'),
              label: localizations.save,
              onPressed:
                  viewModel.canSave &&
                      _settingsController.hasValidWorkingDirectory
                  ? _saveSettings
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  void _addEnvironmentVariable() {
    setState(_settingsController.addEnvironmentVariable);
  }

  void _removeEnvironmentVariable(int index) {
    setState(() {
      _settingsController.removeEnvironmentVariable(index);
    });
  }

  void _saveSettings() {
    final dispatch = resolveProgramConfigurationSave(
      bottle: widget.bottle,
      program: widget.program,
      settings: _settingsController.toSettings(),
      action: widget.programSettingsChangeAction,
    );

    switch (dispatch) {
      case AvailableProgramSettingsChangeDispatch(:final invoke):
        invoke();
      case UnavailableProgramSettingsChangeDispatch():
        return;
    }
  }

  Future<void> _chooseLogFile() async {
    final defaultLogPath = programDefaultLogPath(widget.bottle.path);
    final currentPath = _settingsController.effectiveLogPath(
      defaultLogPath: defaultLogPath,
    );
    final selection = await widget.logFilePicker.pickLogFilePath(
      initialDirectory: programPathInitialDirectory(currentPath),
      suggestedName: programPathSuggestedLogName(currentPath),
    );
    if (!mounted) {
      return;
    }

    switch (selection) {
      case PickedFilePath(:final path):
        setState(() {
          _settingsController.logFilePathController.text = path;
        });
      case CancelledFilePathPick():
        return;
    }
  }
}
