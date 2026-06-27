import 'package:flutter/material.dart';

import '../../bottles/bottle_summary.dart';
import '../../files/program_file_picker.dart';
import '../../l10n/konyak_localizations.dart';
import '../programs/program_configuration_settings.dart';
import '../programs/program_environment_editor.dart';

class RunProgramDialogResult {
  RunProgramDialogResult({required this.programPath, this.settings});

  final String programPath;
  final ProgramSettingsSummary? settings;
}

class RunProgramDialog extends StatefulWidget {
  const RunProgramDialog({
    super.key,
    required this.bottleName,
    required this.programFilePicker,
    required this.initialDirectory,
  });

  final String bottleName;
  final ProgramFilePicker programFilePicker;
  final String initialDirectory;

  @override
  State<RunProgramDialog> createState() => _RunProgramDialogState();
}

class _RunProgramDialogState extends State<RunProgramDialog> {
  final TextEditingController _programPathController = TextEditingController();
  final TextEditingController _argumentsController = TextEditingController();
  final List<ProgramEnvironmentControllers> _environmentControllers =
      <ProgramEnvironmentControllers>[];
  bool _optionsExpanded = false;

  @override
  void dispose() {
    _programPathController.dispose();
    _argumentsController.dispose();
    for (final controllers in _environmentControllers) {
      controllers.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final programPath = _programPathController.text.trim();
    if (programPath.isEmpty) {
      return;
    }

    Navigator.of(context).pop(
      RunProgramDialogResult(
        programPath: programPath,
        settings: _oneTimeSettings(),
      ),
    );
  }

  Future<void> _chooseProgramFile() async {
    final selectedPath = await widget.programFilePicker.pickProgramPath(
      initialDirectory: widget.initialDirectory,
    );
    if (!mounted || selectedPath == null || selectedPath.trim().isEmpty) {
      return;
    }

    setState(() {
      _programPathController.text = selectedPath;
    });
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _programPathController.text.trim().isNotEmpty;
    final localizations = KonyakLocalizations.of(context);

    return AlertDialog(
      title: Text(localizations.runProgramIn(widget.bottleName)),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _programPathController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: localizations.programPath,
                  suffixIcon: IconButton(
                    tooltip: localizations.chooseProgramFile,
                    onPressed: _chooseProgramFile,
                    icon: const Icon(Icons.folder_open),
                  ),
                ),
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const ValueKey('run-program-options-toggle'),
                  onPressed: () {
                    setState(() {
                      _optionsExpanded = !_optionsExpanded;
                    });
                  },
                  icon: Icon(
                    _optionsExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                  label: Text(localizations.options),
                ),
              ),
              if (_optionsExpanded)
                _RunProgramOptions(
                  argumentsController: _argumentsController,
                  environmentControllers: _environmentControllers,
                  onAddEnvironmentVariable: _addEnvironmentVariable,
                  onRemoveEnvironmentVariable: _removeEnvironmentVariable,
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localizations.cancel),
        ),
        FilledButton.icon(
          onPressed: canSubmit ? _submit : null,
          icon: const Icon(Icons.play_arrow),
          label: Text(localizations.run),
        ),
      ],
    );
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

  ProgramSettingsSummary? _oneTimeSettings() {
    final arguments = _argumentsController.text;
    final environment = programEnvironmentFromEntries(
      _environmentControllers.map((controller) => controller.toEntry()),
    );
    if (arguments.trim().isEmpty && environment.isEmpty) {
      return null;
    }

    return ProgramSettingsSummary(
      arguments: arguments,
      environment: environment,
    );
  }
}

class _RunProgramOptions extends StatelessWidget {
  const _RunProgramOptions({
    required this.argumentsController,
    required this.environmentControllers,
    required this.onAddEnvironmentVariable,
    required this.onRemoveEnvironmentVariable,
  });

  final TextEditingController argumentsController;
  final List<ProgramEnvironmentControllers> environmentControllers;
  final VoidCallback onAddEnvironmentVariable;
  final ValueChanged<int> onRemoveEnvironmentVariable;

  @override
  Widget build(BuildContext context) {
    final localizations = KonyakLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const ValueKey('run-program-arguments-field'),
          controller: argumentsController,
          decoration: InputDecoration(
            labelText: localizations.arguments,
            hintText: '-windowed',
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 4),
          child: Text(localizations.environment, style: textTheme.labelLarge),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(6),
          ),
          child: ProgramEnvironmentEditor(
            keyPrefix: 'run-program',
            controllers: environmentControllers,
            onAdd: onAddEnvironmentVariable,
            onRemove: onRemoveEnvironmentVariable,
          ),
        ),
      ],
    );
  }
}
