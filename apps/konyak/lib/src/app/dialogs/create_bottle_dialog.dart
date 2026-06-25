import 'package:flutter/material.dart';

import '../../l10n/konyak_localizations.dart';
import '../configuration_labels.dart';

class CreateBottleInput {
  const CreateBottleInput({required this.name, required this.windowsVersion});

  final String name;
  final String windowsVersion;
}

class CreateBottleDialog extends StatefulWidget {
  const CreateBottleDialog({super.key});

  @override
  State<CreateBottleDialog> createState() => _CreateBottleDialogState();
}

class _CreateBottleDialogState extends State<CreateBottleDialog> {
  final TextEditingController _nameController = TextEditingController();
  String _windowsVersion = 'win10';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }

    Navigator.of(
      context,
    ).pop(CreateBottleInput(name: name, windowsVersion: _windowsVersion));
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _nameController.text.trim().isNotEmpty;
    final localizations = KonyakLocalizations.of(context);

    return AlertDialog(
      title: Text(localizations.text('Create bottle')),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: localizations.text('Name'),
              ),
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _windowsVersion,
              decoration: InputDecoration(
                labelText: localizations.text('Windows version'),
              ),
              items: windowsVersionMenuItems(_windowsVersion),
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _windowsVersion = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localizations.text('Cancel')),
        ),
        FilledButton.icon(
          onPressed: canSubmit ? _submit : null,
          icon: const Icon(Icons.add),
          label: Text(localizations.text('Create')),
        ),
      ],
    );
  }
}
