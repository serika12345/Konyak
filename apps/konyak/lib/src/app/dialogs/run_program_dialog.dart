import 'package:flutter/material.dart';

import '../../files/program_file_picker.dart';
import '../../l10n/konyak_localizations.dart';

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

  @override
  void dispose() {
    _programPathController.dispose();
    super.dispose();
  }

  void _submit() {
    final programPath = _programPathController.text.trim();
    if (programPath.isEmpty) {
      return;
    }

    Navigator.of(context).pop(programPath);
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
        width: 420,
        child: TextField(
          controller: _programPathController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: localizations.text('Program path'),
            suffixIcon: IconButton(
              tooltip: localizations.text('Choose program file'),
              onPressed: _chooseProgramFile,
              icon: const Icon(Icons.folder_open),
            ),
          ),
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localizations.text('Cancel')),
        ),
        FilledButton.icon(
          onPressed: canSubmit ? _submit : null,
          icon: const Icon(Icons.play_arrow),
          label: Text(localizations.text('Run')),
        ),
      ],
    );
  }
}
