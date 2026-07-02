import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../l10n/konyak_localizations.dart';
import '../configuration_labels.dart';

part 'create_bottle_dialog.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class CreateBottleDecision with _$CreateBottleDecision {
  const factory CreateBottleDecision.create({
    required String name,
    required String windowsVersion,
  }) = CreateBottleFromDialog;

  const factory CreateBottleDecision.cancelled() = CancelledCreateBottleDialog;
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

    Navigator.of(context).pop(
      CreateBottleDecision.create(name: name, windowsVersion: _windowsVersion),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _nameController.text.trim().isNotEmpty;
    final localizations = KonyakLocalizations.of(context);

    return AlertDialog(
      title: Text(localizations.createBottleAction),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(labelText: localizations.name),
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _windowsVersion,
              decoration: InputDecoration(
                labelText: localizations.windowsVersionFieldLabel,
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
          onPressed: () {
            Navigator.of(context).pop(const CreateBottleDecision.cancelled());
          },
          child: Text(localizations.cancel),
        ),
        FilledButton.icon(
          onPressed: canSubmit ? _submit : null,
          icon: const Icon(Icons.add),
          label: Text(localizations.create),
        ),
      ],
    );
  }
}
