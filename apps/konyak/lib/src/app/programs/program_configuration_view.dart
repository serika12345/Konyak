import 'package:flutter/material.dart';

import '../../bottles/bottle_summary.dart';
import '../../files/log_file_picker.dart';
import '../../l10n/konyak_localizations.dart';
import '../app_constants.dart';
import '../configuration_labels.dart';
import '../widgets/configuration_controls.dart';
import '../widgets/konyak_bottom_button.dart';
import 'program_configuration_settings.dart';
import 'program_environment_editor.dart';
import 'wine_logging_channel_menu.dart';

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
          BottleConfigurationSection(
            title: localizations.program,
            children: [
              BottleConfigurationRow(
                label: localizations.locale,
                trailing: ConfigurationDropdown(
                  key: const ValueKey('program-config-locale'),
                  value: _locale,
                  labels: localizedProgramLocaleLabels(localizations),
                  onChanged: (locale) {
                    setState(() {
                      _locale = locale;
                    });
                  },
                ),
              ),
              BottleConfigurationRow(
                label: localizations.arguments,
                trailing: ConfigurationTextField(
                  key: const ValueKey('program-config-arguments-field'),
                  controller: _argumentsController,
                  hintText: '-windowed',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          BottleConfigurationSection(
            title: localizations.environment,
            children: [
              ProgramEnvironmentEditor(
                controllers: _environmentControllers,
                onAdd: _addEnvironmentVariable,
                onRemove: _removeEnvironmentVariable,
              ),
            ],
          ),
          const SizedBox(height: 14),
          BottleConfigurationSection(
            title: localizations.logging,
            children: [
              BottleConfigurationSwitchRow(
                switchKey: const ValueKey('program-config-create-log-file'),
                label: localizations.createLogFile,
                value: _createLogFile,
                onChanged: (value) {
                  setState(() {
                    _createLogFile = value;
                  });
                },
              ),
              BottleConfigurationRow(
                label: localizations.additionalWineLoggingChannels,
                trailing: ConfigurationTextField(
                  key: const ValueKey(
                    'program-config-wine-logging-channels-field',
                  ),
                  controller: _wineLoggingChannelsController,
                  hintText: '+seh,+relay',
                  suffixIcon: WineLoggingChannelMenu(
                    key: const ValueKey(
                      'program-config-wine-logging-channel-menu',
                    ),
                    onSelected: (channels) {
                      appendWineLoggingChannels(
                        _wineLoggingChannelsController,
                        channels,
                      );
                    },
                  ),
                ),
              ),
              BottleConfigurationRow(
                label: localizations.logFile,
                trailing: _ProgramLogFilePathControl(
                  controller: _logFilePathController,
                  defaultLogPath: _defaultLogPath,
                  onChooseLogFile: _chooseLogFile,
                ),
              ),
            ],
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
      initialDirectory: _pathDirectory(currentPath),
      suggestedName: _pathFileName(currentPath) ?? 'latest.log',
    );
    if (!mounted || selectedPath == null || selectedPath.trim().isEmpty) {
      return;
    }

    setState(() {
      _logFilePathController.text = selectedPath;
    });
  }

  String get _defaultLogPath => _programDefaultLogPath(widget.bottle.path);

  String _effectiveLogPath() {
    final selectedPath = _logFilePathController.text.trim();
    if (selectedPath.isNotEmpty) {
      return selectedPath;
    }

    return _defaultLogPath;
  }
}

class _ProgramLogFilePathControl extends StatelessWidget {
  const _ProgramLogFilePathControl({
    required this.controller,
    required this.defaultLogPath,
    required this.onChooseLogFile,
  });

  final TextEditingController controller;
  final String defaultLogPath;
  final VoidCallback onChooseLogFile;

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);
    final localizations = KonyakLocalizations.of(context);

    return SizedBox(
      width: 330,
      height: 30,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: const ValueKey('program-config-log-file-path-field'),
              controller: controller,
              style: TextStyle(color: colors.text, fontSize: 13),
              decoration: InputDecoration(
                hintText: defaultLogPath,
                hintStyle: TextStyle(color: colors.mutedText, fontSize: 13),
                isDense: true,
                filled: true,
                fillColor: colors.inputBackground,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: colors.mutedText),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            key: const ValueKey('program-config-change-log-file'),
            onPressed: onChooseLogFile,
            child: Text(localizations.change),
          ),
        ],
      ),
    );
  }
}

String _programDefaultLogPath(String bottlePath) {
  if (bottlePath.endsWith('/')) {
    return '${bottlePath}logs/latest.log';
  }

  return '$bottlePath/logs/latest.log';
}

String? _pathDirectory(String path) {
  final normalized = path.trim();
  if (normalized.isEmpty) {
    return null;
  }

  final separator = normalized.lastIndexOf('/');
  if (separator <= 0) {
    return null;
  }

  return normalized.substring(0, separator);
}

String? _pathFileName(String path) {
  final normalized = path.trim();
  if (normalized.isEmpty) {
    return null;
  }

  final separator = normalized.lastIndexOf('/');
  return separator == -1 ? normalized : normalized.substring(separator + 1);
}
