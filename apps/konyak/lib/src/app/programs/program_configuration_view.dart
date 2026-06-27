import 'package:flutter/material.dart';

import '../../bottles/bottle_summary.dart';
import '../../files/log_file_picker.dart';
import '../../l10n/konyak_localizations.dart';
import '../app_constants.dart';
import '../widgets/konyak_bottom_button.dart';
import 'program_configuration_settings.dart';
import 'program_settings_controls.dart';
import 'program_settings_form_controller.dart';

class ProgramConfigurationView extends StatefulWidget {
  const ProgramConfigurationView({
    super.key,
    required this.bottle,
    required this.program,
    required this.settings,
    required this.isLoading,
    required this.onProgramSettingsChanged,
    this.logFilePicker = const FileSelectorLogFilePicker(),
  });

  final BottleSummary bottle;
  final PinnedProgramSummary program;
  final ProgramSettingsSummary? settings;
  final bool isLoading;
  final LogFilePicker logFilePicker;
  final void Function(
    BottleSummary bottle,
    PinnedProgramSummary program,
    ProgramSettingsSummary settings,
  )?
  onProgramSettingsChanged;

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
      widget.settings ?? ProgramSettingsSummary(),
    );
  }

  @override
  void didUpdateWidget(covariant ProgramConfigurationView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.program.path != widget.program.path ||
        !sameProgramSettings(oldWidget.settings, widget.settings)) {
      _settingsController.replaceSettings(
        widget.settings ?? ProgramSettingsSummary(),
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

    if (widget.isLoading && widget.settings == null) {
      return Center(child: CircularProgressIndicator(color: colors.accent));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProgramSettingsControls(
            keyPrefix: 'program-config',
            locale: _settingsController.locale,
            argumentsController: _settingsController.argumentsController,
            environmentControllers: _settingsController.environmentControllers,
            createLogFile: _settingsController.createLogFile,
            wineLoggingChannelsController:
                _settingsController.wineLoggingChannelsController,
            logFilePathController: _settingsController.logFilePathController,
            defaultLogPath: _defaultLogPath,
            onLocaleChanged: (locale) {
              setState(() {
                _settingsController.setLocale(locale);
              });
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
              onPressed: widget.onProgramSettingsChanged == null
                  ? null
                  : _saveSettings,
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
    widget.onProgramSettingsChanged?.call(
      widget.bottle,
      widget.program,
      _settingsController.toSettings(),
    );
  }

  Future<void> _chooseLogFile() async {
    final currentPath = _settingsController.effectiveLogPath(
      defaultLogPath: _defaultLogPath,
    );
    final selectedPath = await widget.logFilePicker.pickLogFilePath(
      initialDirectory: programPathDirectory(currentPath),
      suggestedName: programPathFileName(currentPath) ?? 'latest.log',
    );
    if (!mounted || selectedPath == null || selectedPath.trim().isEmpty) {
      return;
    }

    setState(() {
      _settingsController.logFilePathController.text = selectedPath;
    });
  }

  String get _defaultLogPath => programDefaultLogPath(widget.bottle.path);
}
