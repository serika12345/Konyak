import 'package:flutter/material.dart';

import '../../files/directory_picker.dart';

class DeleteBottleDialog extends StatelessWidget {
  const DeleteBottleDialog({super.key, required this.bottleName});

  final String bottleName;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Delete $bottleName?'),
      content: const Text('This removes the bottle folder and metadata.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Delete'),
        ),
      ],
    );
  }
}

class RenameBottleDialog extends StatefulWidget {
  const RenameBottleDialog({super.key, required this.bottleName});

  final String bottleName;

  @override
  State<RenameBottleDialog> createState() => _RenameBottleDialogState();
}

class _RenameBottleDialogState extends State<RenameBottleDialog> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.bottleName,
  );

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

    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _nameController.text.trim().isNotEmpty;

    return AlertDialog(
      title: Text('Rename ${widget.bottleName}'),
      content: SizedBox(
        width: 360,
        child: TextField(
          key: const ValueKey('rename-bottle-name-field'),
          controller: _nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: canSubmit ? _submit : null,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Rename'),
        ),
      ],
    );
  }
}

class RenamePinnedProgramDialog extends StatefulWidget {
  const RenamePinnedProgramDialog({super.key, required this.programName});

  final String programName;

  @override
  State<RenamePinnedProgramDialog> createState() =>
      _RenamePinnedProgramDialogState();
}

class _RenamePinnedProgramDialogState extends State<RenamePinnedProgramDialog> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.programName,
  );

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

    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _nameController.text.trim().isNotEmpty;

    return AlertDialog(
      title: Text('Rename ${widget.programName}'),
      content: SizedBox(
        width: 360,
        child: TextField(
          key: const ValueKey('rename-pinned-program-name-field'),
          controller: _nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: canSubmit ? _submit : null,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Rename'),
        ),
      ],
    );
  }
}

class MoveBottleDialog extends StatefulWidget {
  const MoveBottleDialog({
    super.key,
    required this.bottleName,
    required this.initialPath,
    required this.directoryPicker,
  });

  final String bottleName;
  final String initialPath;
  final DirectoryPicker directoryPicker;

  @override
  State<MoveBottleDialog> createState() => _MoveBottleDialogState();
}

class _MoveBottleDialogState extends State<MoveBottleDialog> {
  late final TextEditingController _pathController = TextEditingController(
    text: widget.initialPath,
  );

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _chooseDirectory() async {
    final path = await widget.directoryPicker.pickDirectoryPath();
    if (path == null || !mounted) {
      return;
    }

    setState(() {
      _pathController.text = path;
    });
  }

  void _submit() {
    final path = _pathController.text.trim();
    if (path.isEmpty) {
      return;
    }

    Navigator.of(context).pop(path);
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _pathController.text.trim().isNotEmpty;

    return AlertDialog(
      title: Text('Move ${widget.bottleName}'),
      content: SizedBox(
        width: 460,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('move-bottle-path-field'),
                controller: _pathController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Bottle path'),
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _chooseDirectory,
              child: const Text('Choose...'),
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
          icon: const Icon(Icons.drive_file_move_outline),
          label: const Text('Move'),
        ),
      ],
    );
  }
}
