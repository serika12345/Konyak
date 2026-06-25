import 'package:flutter/material.dart';

import '../../files/program_file_picker.dart';
import '../../l10n/konyak_localizations.dart';
import '../utils/program_labels.dart';

class PinProgramInput {
  const PinProgramInput({required this.name, required this.programPath});

  final String name;
  final String programPath;
}

class PinProgramDialog extends StatefulWidget {
  const PinProgramDialog({
    super.key,
    required this.bottleName,
    required this.programFilePicker,
  });

  final String bottleName;
  final ProgramFilePicker programFilePicker;

  @override
  State<PinProgramDialog> createState() => _PinProgramDialogState();
}

class _PinProgramDialogState extends State<PinProgramDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _programPathController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _programPathController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final programPath = _programPathController.text.trim();
    if (name.isEmpty || programPath.isEmpty) {
      return;
    }

    Navigator.of(
      context,
    ).pop(PinProgramInput(name: name, programPath: programPath));
  }

  Future<void> _chooseProgramFile() async {
    final selectedPath = await widget.programFilePicker.pickProgramPath();
    if (!mounted || selectedPath == null || selectedPath.trim().isEmpty) {
      return;
    }

    setState(() {
      _programPathController.text = selectedPath;
      if (_nameController.text.trim().isEmpty) {
        _nameController.text = defaultProgramName(selectedPath);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit =
        _nameController.text.trim().isNotEmpty &&
        _programPathController.text.trim().isNotEmpty;
    final localizations = KonyakLocalizations.of(context);

    return AlertDialog(
      title: Text(localizations.pinProgramIn(widget.bottleName)),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const ValueKey('pin-program-name-field'),
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(labelText: localizations.name),
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('pin-program-path-field'),
              controller: _programPathController,
              decoration: InputDecoration(
                labelText: localizations.programPath,
                suffixIcon: IconButton(
                  tooltip: localizations.chooseProgramFile,
                  onPressed: _chooseProgramFile,
                  icon: const Icon(Icons.folder_open),
                ),
              ),
              textInputAction: TextInputAction.done,
              onChanged: (_) {
                if (_nameController.text.trim().isEmpty) {
                  _nameController.text = defaultProgramName(
                    _programPathController.text,
                  );
                }
                setState(() {});
              },
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localizations.cancel),
        ),
        FilledButton.icon(
          onPressed: canSubmit ? _submit : null,
          icon: const Icon(Icons.push_pin_outlined),
          label: Text(localizations.pin),
        ),
      ],
    );
  }
}
