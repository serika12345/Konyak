import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../files/directory_picker.dart';
import '../../files/file_path_pick_result.dart';
import '../../l10n/konyak_localizations.dart';

part 'bottle_management_dialogs.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class DeleteBottleDecision with _$DeleteBottleDecision {
  const factory DeleteBottleDecision.delete() = DeleteBottleConfirmed;

  const factory DeleteBottleDecision.cancelled() = CancelledDeleteBottleDialog;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class RenameBottleDecision with _$RenameBottleDecision {
  const factory RenameBottleDecision.rename(String name) = RenameBottleToName;

  const factory RenameBottleDecision.cancelled() = CancelledRenameBottleDialog;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class RenamePinnedProgramDecision with _$RenamePinnedProgramDecision {
  const factory RenamePinnedProgramDecision.rename(String name) =
      RenamePinnedProgramToName;

  const factory RenamePinnedProgramDecision.cancelled() =
      CancelledRenamePinnedProgramDialog;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class MoveBottleDecision with _$MoveBottleDecision {
  const factory MoveBottleDecision.move(String path) = MoveBottleToPath;

  const factory MoveBottleDecision.cancelled() = CancelledMoveBottleDialog;
}

class DeleteBottleDialog extends StatelessWidget {
  const DeleteBottleDialog({super.key, required this.bottleName});

  final String bottleName;

  @override
  Widget build(BuildContext context) {
    final localizations = KonyakLocalizations.of(context);

    return AlertDialog(
      title: Text(localizations.deleteBottleTitle(bottleName)),
      content: Text(localizations.thisRemovesTheBottleFolderAndMetadata),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(const DeleteBottleDecision.cancelled());
          },
          child: Text(localizations.cancel),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop(const DeleteBottleDecision.delete());
          },
          icon: const Icon(Icons.delete_outline),
          label: Text(localizations.delete),
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

    Navigator.of(context).pop(RenameBottleDecision.rename(name));
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _nameController.text.trim().isNotEmpty;
    final localizations = KonyakLocalizations.of(context);

    return AlertDialog(
      title: Text(localizations.renameBottleTitle(widget.bottleName)),
      content: SizedBox(
        width: 360,
        child: TextField(
          key: const ValueKey('rename-bottle-name-field'),
          controller: _nameController,
          autofocus: true,
          decoration: InputDecoration(labelText: localizations.name),
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(const RenameBottleDecision.cancelled());
          },
          child: Text(localizations.cancel),
        ),
        FilledButton.icon(
          onPressed: canSubmit ? _submit : null,
          icon: const Icon(Icons.edit_outlined),
          label: Text(localizations.rename),
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

    Navigator.of(context).pop(RenamePinnedProgramDecision.rename(name));
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _nameController.text.trim().isNotEmpty;
    final localizations = KonyakLocalizations.of(context);

    return AlertDialog(
      title: Text(localizations.renameProgramTitle(widget.programName)),
      content: SizedBox(
        width: 360,
        child: TextField(
          key: const ValueKey('rename-pinned-program-name-field'),
          controller: _nameController,
          autofocus: true,
          decoration: InputDecoration(labelText: localizations.name),
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(
              context,
            ).pop(const RenamePinnedProgramDecision.cancelled());
          },
          child: Text(localizations.cancel),
        ),
        FilledButton.icon(
          onPressed: canSubmit ? _submit : null,
          icon: const Icon(Icons.edit_outlined),
          label: Text(localizations.rename),
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
    final selection = await widget.directoryPicker.pickDirectoryPath();
    if (!mounted) {
      return;
    }

    switch (selection) {
      case PickedFilePath(:final path):
        setState(() {
          _pathController.text = path;
        });
      case CancelledFilePathPick():
        return;
    }
  }

  void _submit() {
    final path = _pathController.text.trim();
    if (path.isEmpty) {
      return;
    }

    Navigator.of(context).pop(MoveBottleDecision.move(path));
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _pathController.text.trim().isNotEmpty;
    final localizations = KonyakLocalizations.of(context);

    return AlertDialog(
      title: Text(localizations.moveBottleTitle(widget.bottleName)),
      content: SizedBox(
        width: 460,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('move-bottle-path-field'),
                controller: _pathController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: localizations.bottlePath,
                ),
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _chooseDirectory,
              child: Text(localizations.chooseEllipsis),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(const MoveBottleDecision.cancelled());
          },
          child: Text(localizations.cancel),
        ),
        FilledButton.icon(
          onPressed: canSubmit ? _submit : null,
          icon: const Icon(Icons.drive_file_move_outline),
          label: Text(localizations.move),
        ),
      ],
    );
  }
}
