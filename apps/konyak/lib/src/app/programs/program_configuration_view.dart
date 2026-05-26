import 'package:flutter/material.dart';

import '../../bottles/bottle_summary.dart';
import '../app_constants.dart';
import '../configuration_labels.dart';
import '../widgets/configuration_controls.dart';
import '../widgets/konyak_bottom_button.dart';

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
  late List<_EnvironmentControllers> _environmentControllers;

  @override
  void initState() {
    super.initState();
    _argumentsController = TextEditingController();
    _environmentControllers = <_EnvironmentControllers>[];
    _replaceSettings(widget.settings ?? const ProgramSettingsSummary());
  }

  @override
  void didUpdateWidget(covariant ProgramConfigurationView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.program.path != widget.program.path ||
        !_sameProgramSettings(oldWidget.settings, widget.settings)) {
      _replaceSettings(widget.settings ?? const ProgramSettingsSummary());
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

    if (widget.isLoading && widget.settings == null) {
      return Center(child: CircularProgressIndicator(color: colors.accent));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BottleConfigurationSection(
            title: 'Program',
            children: [
              BottleConfigurationRow(
                label: 'Locale',
                trailing: ConfigurationDropdown(
                  key: const ValueKey('program-config-locale'),
                  value: _locale,
                  labels: programLocaleLabels,
                  onChanged: (locale) {
                    setState(() {
                      _locale = locale;
                    });
                  },
                ),
              ),
              BottleConfigurationRow(
                label: 'Arguments',
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
            title: 'Environment',
            children: [
              for (final (index, controllers)
                  in _environmentControllers.indexed)
                _ProgramEnvironmentRow(
                  index: index,
                  controllers: controllers,
                  onRemove: () {
                    setState(() {
                      _environmentControllers.removeAt(index).dispose();
                    });
                  },
                ),
              _AddEnvironmentRow(
                onPressed: () {
                  setState(() {
                    _environmentControllers.add(_EnvironmentControllers());
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: KonyakBottomButton(
              key: const ValueKey('program-config-save'),
              label: 'Save',
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
          (entry) =>
              _EnvironmentControllers(name: entry.key, value: entry.value),
        )
        .toList(growable: true);
  }

  void _saveSettings() {
    widget.onProgramSettingsChanged?.call(
      widget.bottle,
      widget.program,
      ProgramSettingsSummary(
        locale: _locale,
        arguments: _argumentsController.text,
        environment: _environmentFromControllers(_environmentControllers),
      ),
    );
  }
}

class _EnvironmentControllers {
  _EnvironmentControllers({String name = '', String value = ''})
    : nameController = TextEditingController(text: name),
      valueController = TextEditingController(text: value);

  final TextEditingController nameController;
  final TextEditingController valueController;

  void dispose() {
    nameController.dispose();
    valueController.dispose();
  }
}

class _ProgramEnvironmentRow extends StatelessWidget {
  const _ProgramEnvironmentRow({
    required this.index,
    required this.controllers,
    required this.onRemove,
  });

  final int index;
  final _EnvironmentControllers controllers;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: Row(
        children: [
          const SizedBox(width: 14),
          Expanded(
            child: ConfigurationTextField(
              key: ValueKey('program-config-env-key-$index'),
              controller: controllers.nameController,
              hintText: 'NAME',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ConfigurationTextField(
              key: ValueKey('program-config-env-value-$index'),
              controller: controllers.valueController,
              hintText: 'Value',
            ),
          ),
          IconButton(
            tooltip: 'Remove environment variable',
            onPressed: onRemove,
            color: KonyakThemeColors.of(context).mutedText,
            iconSize: 18,
            constraints: const BoxConstraints.tightFor(width: 34, height: 34),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _AddEnvironmentRow extends StatelessWidget {
  const _AddEnvironmentRow({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          key: const ValueKey('program-config-add-environment'),
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: KonyakThemeColors.of(context).text,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: const Icon(Icons.add, size: 17),
          label: const Text(
            'Add',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}

class ConfigurationTextField extends StatelessWidget {
  const ConfigurationTextField({
    super.key,
    required this.controller,
    required this.hintText,
  });

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);

    return SizedBox(
      width: 260,
      height: 30,
      child: TextField(
        controller: controller,
        style: TextStyle(color: colors.text, fontSize: 13),
        decoration: InputDecoration(
          hintText: hintText,
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
    );
  }
}

Map<String, String> _environmentFromControllers(
  List<_EnvironmentControllers> controllers,
) {
  final environment = <String, String>{};
  for (final controller in controllers) {
    final name = controller.nameController.text.trim();
    if (name.isEmpty) {
      continue;
    }
    environment[name] = controller.valueController.text;
  }

  return Map.unmodifiable(environment);
}

bool _sameProgramSettings(
  ProgramSettingsSummary? left,
  ProgramSettingsSummary? right,
) {
  if (left == null || right == null) {
    return left == right;
  }

  return left.locale == right.locale &&
      left.arguments == right.arguments &&
      _stringMapEquals(left.environment, right.environment);
}

bool _stringMapEquals(Map<String, String> left, Map<String, String> right) {
  if (left.length != right.length) {
    return false;
  }

  for (final entry in left.entries) {
    if (right[entry.key] != entry.value) {
      return false;
    }
  }

  return true;
}
