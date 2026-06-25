import 'package:flutter/material.dart';

import '../../bottles/bottle_summary.dart';
import '../../l10n/konyak_localizations.dart';
import '../app_constants.dart';
import '../configuration_labels.dart';
import '../widgets/configuration_controls.dart';
import '../widgets/konyak_bottom_button.dart';
import 'program_configuration_settings.dart';
import 'program_environment_editor.dart';

class ProgramConfigurationView extends StatefulWidget {
  const ProgramConfigurationView({
    super.key,
    required this.bottle,
    required this.program,
    required this.settings,
    required this.isLoading,
    required this.onProgramSettingsChanged,
  });

  final BottleSummary bottle;
  final PinnedProgramSummary program;
  final ProgramSettingsSummary? settings;
  final bool isLoading;
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
  late TextEditingController _argumentsController;
  late List<ProgramEnvironmentControllers> _environmentControllers;

  @override
  void initState() {
    super.initState();
    _argumentsController = TextEditingController();
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
            title: localizations.text('Program'),
            children: [
              BottleConfigurationRow(
                label: localizations.text('Locale'),
                trailing: ConfigurationDropdown(
                  key: const ValueKey('program-config-locale'),
                  value: _locale,
                  labels: localizations.textMap(programLocaleLabels),
                  onChanged: (locale) {
                    setState(() {
                      _locale = locale;
                    });
                  },
                ),
              ),
              BottleConfigurationRow(
                label: localizations.text('Arguments'),
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
            title: localizations.text('Environment'),
            children: [
              ProgramEnvironmentEditor(
                controllers: _environmentControllers,
                onAdd: _addEnvironmentVariable,
                onRemove: _removeEnvironmentVariable,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: KonyakBottomButton(
              key: const ValueKey('program-config-save'),
              label: localizations.text('Save'),
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
    _argumentsController.text = settings.arguments;
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
      ),
    );
  }
}
