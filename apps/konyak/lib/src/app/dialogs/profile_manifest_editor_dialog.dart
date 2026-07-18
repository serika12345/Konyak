import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/konyak_localizations.dart';
import 'profile_manager_action_contract.dart';

sealed class ProfileManifestEditorDecision {
  const ProfileManifestEditorDecision();
}

final class SavedProfileManifest extends ProfileManifestEditorDecision {
  const SavedProfileManifest(this.result);

  final ProfileManagerActionResult result;
}

final class CancelledProfileManifestEditor
    extends ProfileManifestEditorDecision {
  const CancelledProfileManifestEditor();
}

class ProfileManifestEditorDialog extends StatefulWidget {
  const ProfileManifestEditorDialog({
    super.key,
    required this.title,
    required this.initialManifestJson,
    required this.validateManifest,
    required this.saveManifest,
  });

  final String title;
  final String initialManifestJson;
  final Future<ProfileManagerManifestValidationResult> Function(
    String manifestJson,
  )
  validateManifest;
  final Future<ProfileManagerActionResult> Function(String manifestJson)
  saveManifest;

  @override
  State<ProfileManifestEditorDialog> createState() =>
      _ProfileManifestEditorDialogState();
}

class _ProfileManifestEditorDialogState
    extends State<ProfileManifestEditorDialog> {
  static const _validationDebounce = Duration(milliseconds: 300);

  late final TextEditingController _controller;
  Timer? _validationTimer;
  _ProfileManifestEditorValidationState _validationState =
      const _ValidProfileManifestEditor();
  int _validationRequestId = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialManifestJson);
  }

  @override
  void dispose() {
    _validationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = KonyakLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 720,
        height: 520,
        child: TextField(
          key: const ValueKey('profile-manifest-editor-field'),
          controller: _controller,
          expands: true,
          maxLines: null,
          minLines: null,
          keyboardType: TextInputType.multiline,
          textAlignVertical: TextAlignVertical.top,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: localizations.profileManifestJson,
            alignLabelWithHint: true,
            errorText: switch (_validationState) {
              _InvalidProfileManifestEditor(:final message) ||
              _FailedProfileManifestSave(:final message) => message,
              _ValidProfileManifestEditor() ||
              _PendingProfileManifestValidation() => null,
            },
            errorMaxLines: 6,
          ),
          readOnly: _saving,
          onChanged: _manifestChanged,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving
              ? null
              : () => Navigator.of(
                  context,
                ).pop(const CancelledProfileManifestEditor()),
          child: Text(localizations.cancel),
        ),
        FilledButton(
          onPressed: _canSave ? _saveManifest : null,
          child: Text(localizations.save),
        ),
      ],
    );
  }

  bool get _canSave =>
      !_saving &&
      (_validationState is _ValidProfileManifestEditor ||
          _validationState is _FailedProfileManifestSave);

  void _manifestChanged(String manifestJson) {
    final requestId = ++_validationRequestId;
    _validationTimer?.cancel();
    setState(() {
      _validationState = const _PendingProfileManifestValidation();
    });
    _validationTimer = Timer(
      _validationDebounce,
      () => unawaited(_validateManifest(manifestJson, requestId)),
    );
  }

  Future<void> _validateManifest(String manifestJson, int requestId) async {
    final result = await widget.validateManifest(manifestJson);
    if (!mounted || requestId != _validationRequestId) {
      return;
    }
    setState(() {
      _validationState = switch (result) {
        ValidProfileManagerManifest() => const _ValidProfileManifestEditor(),
        InvalidProfileManagerManifest(:final message) =>
          _InvalidProfileManifestEditor(message),
      };
    });
  }

  Future<void> _saveManifest() async {
    if (!_canSave) {
      return;
    }
    setState(() {
      _saving = true;
    });
    final result = await widget.saveManifest(_controller.text);
    if (!mounted) {
      return;
    }
    switch (result.disposition) {
      case CompletedProfileManagerAction():
        Navigator.of(context).pop(SavedProfileManifest(result));
      case RejectedProfileManagerAction():
        setState(() {
          _saving = false;
          _validationState = _FailedProfileManifestSave(
            _profileManagerActionFeedbackMessage(result.feedback),
          );
        });
    }
  }
}

sealed class _ProfileManifestEditorValidationState {
  const _ProfileManifestEditorValidationState();
}

final class _ValidProfileManifestEditor
    extends _ProfileManifestEditorValidationState {
  const _ValidProfileManifestEditor();
}

final class _PendingProfileManifestValidation
    extends _ProfileManifestEditorValidationState {
  const _PendingProfileManifestValidation();
}

final class _InvalidProfileManifestEditor
    extends _ProfileManifestEditorValidationState {
  const _InvalidProfileManifestEditor(this.message);

  final String message;
}

final class _FailedProfileManifestSave
    extends _ProfileManifestEditorValidationState {
  const _FailedProfileManifestSave(this.message);

  final String message;
}

String _profileManagerActionFeedbackMessage(
  ProfileManagerActionFeedback feedback,
) {
  return switch (feedback) {
    ShowProfileManagerActionFeedback(:final message) => message,
    NoProfileManagerActionFeedback() => 'The profile could not be saved.',
  };
}
