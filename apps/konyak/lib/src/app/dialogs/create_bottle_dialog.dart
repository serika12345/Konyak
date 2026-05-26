import 'package:flutter/material.dart';

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

    return AlertDialog(
      title: const Text('Create bottle'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name'),
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _windowsVersion,
              decoration: const InputDecoration(labelText: 'Windows version'),
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
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: canSubmit ? _submit : null,
          icon: const Icon(Icons.add),
          label: const Text('Create'),
        ),
      ],
    );
  }
}
