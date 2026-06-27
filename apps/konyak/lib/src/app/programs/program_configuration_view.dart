import 'package:flutter/material.dart';

import '../../bottles/bottle_summary.dart';
import '../../files/log_file_picker.dart';
import '../../l10n/konyak_localizations.dart';
import '../app_constants.dart';
import '../configuration_labels.dart';
import '../widgets/konyak_bottom_button.dart';
import 'program_configuration_settings.dart';
import 'program_environment_editor.dart';
import 'program_settings_controls.dart';

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
  late String _locale;
  late bool _createLogFile;
  late TextEditingController _argumentsController;
  late TextEditingController _wineLoggingChannelsController;
  late TextEditingController _logFilePathController;
  late List<ProgramEnvironmentControllers> _environmentControllers;

  @override
  void initState() {
    super.initState();
    _argumentsController = TextEditingController();
    _wineLoggingChannelsController = TextEditingController();
    _logFilePathController = TextEditingController();
    _environmentControllers = <ProgramEnvironmentControllers>[];
    _replaceSettings(widget.settings ?? ProgramSettingsSummary());
  }

  @override
  void didUpdateWidget(covariant ProgramConfigurationView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.program.path != widget.program.path ||
        !sameProgramSettings(oldWidget.settings, widget.settings)) {
      _replaceSettings(widget.settings ?? ProgramSettingsSummary());
    }
  }

  @override
  void dispose() {
    _argumentsController.dispose();
    _wineLoggingChannelsController.dispose();
    _logFilePathController.dispose();
    for (final controllers in _environmentControllers) {
      controllers.dispose();
    }
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
            locale: _locale,
            argumentsController: _argumentsController,
            environmentControllers: _environmentControllers,
            createLogFile: _createLogFile,
            wineLoggingChannelsController: _wineLoggingChannelsController,
            logFilePathController: _logFilePathController,
            defaultLogPath: _defaultLogPath,
            onLocaleChanged: (locale) {
              setState(() {
                _locale = locale;
              });
            },
            onCreateLogFileChanged: (value) {
              setState(() {
                _createLogFile = value;
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

  void _replaceSettings(ProgramSettingsSummary settings) {
    _locale = programLocaleLabels.containsKey(settings.locale)
        ? settings.locale
        : '';
    _createLogFile = settings.logging.createLogFile;
    _argumentsController.text = settings.arguments;
    _wineLoggingChannelsController.text =
        settings.logging.additionalWineLoggingChannels;
    _logFilePathController.text = settings.logging.logFilePath;
    for (final controllers in _environmentControllers) {
      controllers.dispose();
    }
    _environmentControllers = settings.environment.entries
        .map(
          (entry) => ProgramEnvironmentControllers(
            name: entry.key,
            value: entry.value,
          ),
        )
        .toList(growable: true);
  }

  void _addEnvironmentVariable() {
    setState(() {
      _environmentControllers.add(ProgramEnvironmentControllers());
    });
  }

  void _removeEnvironmentVariable(int index) {
    setState(() {
      _environmentControllers.removeAt(index).dispose();
    });
  }

  void _saveSettings() {
    widget.onProgramSettingsChanged?.call(
      widget.bottle,
      widget.program,
      ProgramSettingsSummary(
        locale: _locale,
        arguments: _argumentsController.text,
        environment: programEnvironmentFromEntries(
          _environmentControllers.map((controller) => controller.toEntry()),
        ),
        logging: ProgramLoggingSettingsSummary(
          createLogFile: _createLogFile,
          additionalWineLoggingChannels: _wineLoggingChannelsController.text,
          logFilePath: _logFilePathController.text,
        ),
      ),
    );
  }

  Future<void> _chooseLogFile() async {
    final currentPath = _effectiveLogPath();
    final selectedPath = await widget.logFilePicker.pickLogFilePath(
      initialDirectory: programPathDirectory(currentPath),
      suggestedName: programPathFileName(currentPath) ?? 'latest.log',
    );
    if (!mounted || selectedPath == null || selectedPath.trim().isEmpty) {
      return;
    }

    setState(() {
      _logFilePathController.text = selectedPath;
    });
  }

  String get _defaultLogPath => programDefaultLogPath(widget.bottle.path);

  String _effectiveLogPath() {
    return effectiveProgramLogPath(
      selectedLogPath: _logFilePathController.text,
      defaultLogPath: _defaultLogPath,
    );
  }
}
