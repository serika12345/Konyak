import 'package:flutter/material.dart';

import '../../l10n/konyak_localizations.dart';
import '../app_constants.dart';
import '../widgets/configuration_controls.dart';
import 'program_configuration_settings.dart';

class ProgramEnvironmentControllers {
  ProgramEnvironmentControllers({String name = '', String value = ''})
    : nameController = TextEditingController(text: name),
      valueController = TextEditingController(text: value);

  final TextEditingController nameController;
  final TextEditingController valueController;

  ProgramEnvironmentEntry toEntry() {
    return ProgramEnvironmentEntry(
      name: nameController.text,
      value: valueController.text,
    );
  }

  void dispose() {
    nameController.dispose();
    valueController.dispose();
  }
}

class ProgramEnvironmentEditor extends StatelessWidget {
  const ProgramEnvironmentEditor({
    super.key,
    required this.controllers,
    required this.onAdd,
    required this.onRemove,
    this.keyPrefix = 'program-config',
  });

  final List<ProgramEnvironmentControllers> controllers;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final (index, controller) in controllers.indexed)
          ProgramEnvironmentRow(
            index: index,
            keyPrefix: keyPrefix,
            controllers: controller,
            onRemove: () {
              onRemove(index);
            },
          ),
        AddEnvironmentRow(keyPrefix: keyPrefix, onPressed: onAdd),
      ],
    );
  }
}

class ProgramEnvironmentRow extends StatelessWidget {
  const ProgramEnvironmentRow({
    super.key,
    required this.index,
    required this.keyPrefix,
    required this.controllers,
    required this.onRemove,
  });

  final int index;
  final String keyPrefix;
  final ProgramEnvironmentControllers controllers;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final localizations = KonyakLocalizations.of(context);

    return SizedBox(
      height: 46,
      child: Row(
        children: [
          const SizedBox(width: 14),
          Expanded(
            child: ConfigurationTextField(
              key: ValueKey('$keyPrefix-env-key-$index'),
              controller: controllers.nameController,
              hintText: localizations.environmentNameHint,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ConfigurationTextField(
              key: ValueKey('$keyPrefix-env-value-$index'),
              controller: controllers.valueController,
              hintText: localizations.environmentValueHint,
            ),
          ),
          IconButton(
            tooltip: localizations.removeEnvironmentVariable,
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

class AddEnvironmentRow extends StatelessWidget {
  const AddEnvironmentRow({
    super.key,
    required this.keyPrefix,
    required this.onPressed,
  });

  final String keyPrefix;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final localizations = KonyakLocalizations.of(context);

    return SizedBox(
      height: 42,
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          key: ValueKey('$keyPrefix-add-environment'),
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: KonyakThemeColors.of(context).text,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: const Icon(Icons.add, size: 17),
          label: Text(
            localizations.add,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}
