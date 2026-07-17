import 'dart:async';

import 'package:flutter/material.dart';

import '../../cli/install_profile_manifest_editor.dart';
import '../../cli/konyak_cli_program_result_types.dart';
import '../../files/file_path_pick_result.dart';
import '../../files/file_picker_arguments.dart';
import '../../files/program_file_picker.dart';
import '../../l10n/konyak_localizations.dart';
import 'confirmation_decision.dart';
import 'dialog_decision.dart';

typedef InstallProfileInspector =
    Future<InstallProfileInspectLoadResult> Function(String profileId);

sealed class ProfileManagerDecision {
  const ProfileManagerDecision();
}

final class InstallProfileManagerDecision extends ProfileManagerDecision {
  const InstallProfileManagerDecision({required this.profileId});

  final String profileId;
}

final class ApplyProfileManagerDecision extends ProfileManagerDecision {
  const ApplyProfileManagerDecision({
    required this.profileId,
    required this.programPath,
  });

  final String profileId;
  final String programPath;
}

final class ImportProfileManagerDecision extends ProfileManagerDecision {
  const ImportProfileManagerDecision();
}

final class EditProfileManagerDecision extends ProfileManagerDecision {
  const EditProfileManagerDecision({
    required this.profileId,
    required this.expectedDigest,
    required this.manifestJson,
  });

  final String profileId;
  final String expectedDigest;
  final String manifestJson;
}

final class DuplicateProfileManagerDecision extends ProfileManagerDecision {
  const DuplicateProfileManagerDecision({required this.manifestJson});

  final String manifestJson;
}

final class ExportProfileManagerDecision extends ProfileManagerDecision {
  const ExportProfileManagerDecision({
    required this.profileId,
    required this.suggestedName,
  });

  final String profileId;
  final String suggestedName;
}

final class DeleteProfileManagerDecision extends ProfileManagerDecision {
  const DeleteProfileManagerDecision({
    required this.profileId,
    required this.profileName,
    required this.expectedDigest,
  });

  final String profileId;
  final String profileName;
  final String expectedDigest;
}

final class CancelledProfileManagerDialog extends ProfileManagerDecision {
  const CancelledProfileManagerDialog();
}

sealed class InstallProfileDetailsState {
  const InstallProfileDetailsState();
}

final class NoInstallProfileDetails extends InstallProfileDetailsState {
  const NoInstallProfileDetails();
}

final class LoadingInstallProfileDetails extends InstallProfileDetailsState {
  const LoadingInstallProfileDetails();
}

final class LoadedInstallProfileDetails extends InstallProfileDetailsState {
  const LoadedInstallProfileDetails(this.profile);

  final InstallProfileDetails profile;
}

final class FailedInstallProfileDetails extends InstallProfileDetailsState {
  const FailedInstallProfileDetails(this.message);

  final String message;
}

class ProfileManagerDialog extends StatefulWidget {
  const ProfileManagerDialog({
    super.key,
    required this.bottleName,
    required this.profiles,
    required this.programFilePicker,
    required this.initialDirectory,
    required this.inspectProfile,
  });

  final String bottleName;
  final List<InstallProfileListItem> profiles;
  final ProgramFilePicker programFilePicker;
  final String initialDirectory;
  final InstallProfileInspector inspectProfile;

  @override
  State<ProfileManagerDialog> createState() => _ProfileManagerDialogState();
}

class _ProfileManagerDialogState extends State<ProfileManagerDialog> {
  final TextEditingController _programPathController = TextEditingController();
  InstallProfileListItem? _selectedProfile;
  InstallProfileDetailsState _detailsState = const NoInstallProfileDetails();
  int _detailsRequestId = 0;

  @override
  void initState() {
    super.initState();
    if (widget.profiles.isNotEmpty) {
      unawaited(_selectProfile(widget.profiles.first));
    }
  }

  @override
  void dispose() {
    _programPathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = KonyakLocalizations.of(context);
    final selectedProfile = _selectedProfile;
    final loadedProfile = switch (_detailsState) {
      LoadedInstallProfileDetails(:final profile) => profile,
      _ => null,
    };
    final canInstall =
        selectedProfile != null && _detailsState is LoadedInstallProfileDetails;
    final canApply =
        selectedProfile != null &&
        _programPathController.text.trim().isNotEmpty &&
        _detailsState is LoadedInstallProfileDetails;

    return AlertDialog(
      title: Text(localizations.profileManagerIn(widget.bottleName)),
      content: SizedBox(
        width: 860,
        height: 560,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const ValueKey('profile-manager-import'),
                  onPressed: _importProfile,
                  icon: const Icon(Icons.file_open),
                  label: Text(localizations.importProfileEllipsis),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('profile-manager-edit-or-duplicate'),
                  onPressed:
                      loadedProfile != null &&
                          loadedProfile.manifestJson.isNotEmpty
                      ? _editOrDuplicateSelectedProfile
                      : null,
                  icon: Icon(
                    loadedProfile?.profileSourceKind == 'user'
                        ? Icons.edit
                        : Icons.copy,
                  ),
                  label: Text(
                    loadedProfile?.profileSourceKind == 'user'
                        ? localizations.editProfile
                        : localizations.duplicateProfile,
                  ),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('profile-manager-export'),
                  onPressed: loadedProfile == null ? null : _exportProfile,
                  icon: const Icon(Icons.save_alt),
                  label: Text(localizations.exportProfileEllipsis),
                ),
                TextButton.icon(
                  key: const ValueKey('profile-manager-delete'),
                  onPressed: loadedProfile?.profileSourceKind == 'user'
                      ? _confirmDeleteProfile
                      : null,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(localizations.delete),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: widget.profiles.isEmpty
                  ? Center(child: Text(localizations.noInstallProfilesFound))
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 250,
                          child: ListView.builder(
                            itemCount: widget.profiles.length,
                            itemBuilder: (context, index) {
                              final profile = widget.profiles[index];
                              return ListTile(
                                key: ValueKey(
                                  'profile-manager-profile-${profile.id}',
                                ),
                                title: Text(profile.name),
                                subtitle: Text(
                                  '${profile.id} v${profile.profileVersion} '
                                  '· ${profile.profileSourceKind}',
                                ),
                                selected: selectedProfile?.id == profile.id,
                                dense: true,
                                onTap: () {
                                  unawaited(_selectProfile(profile));
                                },
                              );
                            },
                          ),
                        ),
                        const VerticalDivider(width: 24),
                        Expanded(
                          child: _ProfileManagerDetails(
                            selectedProfile: selectedProfile,
                            profile: loadedProfile,
                            state: _detailsState,
                            programPathController: _programPathController,
                            onProgramPathChanged: () => setState(() {}),
                            onChooseProgram: _chooseProgramFile,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(const CancelledProfileManagerDialog());
          },
          child: Text(localizations.cancel),
        ),
        OutlinedButton.icon(
          onPressed: canApply ? _applySelectedProfile : null,
          icon: const Icon(Icons.check),
          label: Text(localizations.applyProfileToExistingProgram),
        ),
        FilledButton.icon(
          key: const ValueKey('profile-manager-install-automatically'),
          onPressed: canInstall ? _installSelectedProfile : null,
          icon: const Icon(Icons.download),
          label: Text(localizations.installProfileAutomatically),
        ),
      ],
    );
  }

  void _importProfile() {
    Navigator.of(context).pop(const ImportProfileManagerDecision());
  }

  Future<void> _editOrDuplicateSelectedProfile() async {
    final profile = switch (_detailsState) {
      LoadedInstallProfileDetails(:final profile) => profile,
      _ => null,
    };
    if (profile == null || profile.manifestJson.isEmpty) {
      return;
    }

    final isUserProfile = profile.profileSourceKind == 'user';
    late final String initialManifestJson;
    switch (isUserProfile
        ? DuplicatedInstallProfileManifest(profile.manifestJson)
        : duplicateInstallProfileManifest(profile)) {
      case DuplicatedInstallProfileManifest(:final manifestJson):
        initialManifestJson = manifestJson;
      case InvalidInstallProfileManifestForDuplication(:final message):
        setState(() {
          _detailsState = FailedInstallProfileDetails(message);
        });
        return;
    }
    final localizations = KonyakLocalizations.of(context);
    final decision = await showDialogDecision<ProfileManifestEditorDecision>(
      context: context,
      dismissedDecision: const CancelledProfileManifestEditor(),
      builder: (context) => _ProfileManifestEditorDialog(
        title: isUserProfile
            ? localizations.editProfileManifest(profile.name)
            : localizations.duplicateProfileManifest(profile.name),
        initialManifestJson: initialManifestJson,
      ),
    );
    if (!mounted) {
      return;
    }

    switch (decision) {
      case SavedProfileManifest(:final manifestJson):
        Navigator.of(context).pop(
          isUserProfile
              ? EditProfileManagerDecision(
                  profileId: profile.id,
                  expectedDigest: profile.profileDigest,
                  manifestJson: manifestJson,
                )
              : DuplicateProfileManagerDecision(manifestJson: manifestJson),
        );
      case CancelledProfileManifestEditor():
        return;
    }
  }

  void _exportProfile() {
    final profile = switch (_detailsState) {
      LoadedInstallProfileDetails(:final profile) => profile,
      _ => null,
    };
    if (profile == null) {
      return;
    }

    Navigator.of(context).pop(
      ExportProfileManagerDecision(
        profileId: profile.id,
        suggestedName: '${profile.id}.json',
      ),
    );
  }

  Future<void> _confirmDeleteProfile() async {
    final profile = switch (_detailsState) {
      LoadedInstallProfileDetails(:final profile) => profile,
      _ => null,
    };
    if (profile == null || profile.profileSourceKind != 'user') {
      return;
    }

    final localizations = KonyakLocalizations.of(context);
    final decision = await showDialogDecision<ConfirmationDecision>(
      context: context,
      dismissedDecision: const ConfirmationDecision.cancelled(),
      builder: (context) => AlertDialog(
        title: Text(localizations.deleteProfile(profile.name)),
        content: Text(localizations.deleteProfileMessage(profile.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(
              context,
            ).pop(const ConfirmationDecision.cancelled()),
            child: Text(localizations.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(
              context,
            ).pop(const ConfirmationDecision.confirmed()),
            child: Text(localizations.delete),
          ),
        ],
      ),
    );
    if (!mounted) {
      return;
    }

    switch (decision) {
      case ConfirmedDialogDecision():
        Navigator.of(context).pop(
          DeleteProfileManagerDecision(
            profileId: profile.id,
            profileName: profile.name,
            expectedDigest: profile.profileDigest,
          ),
        );
      case CancelledDialogDecision():
        return;
    }
  }

  Future<void> _selectProfile(InstallProfileListItem profile) async {
    final requestId = ++_detailsRequestId;
    setState(() {
      _selectedProfile = profile;
      _detailsState = const LoadingInstallProfileDetails();
    });

    final result = await widget.inspectProfile(profile.id);
    if (!mounted || requestId != _detailsRequestId) {
      return;
    }

    setState(() {
      _detailsState = switch (result) {
        InspectedInstallProfile(:final profile) => LoadedInstallProfileDetails(
          profile,
        ),
        InstallProfileInspectLoadFailure(:final message) =>
          FailedInstallProfileDetails(message),
      };
    });
  }

  Future<void> _chooseProgramFile() async {
    final selection = await widget.programFilePicker.pickProgramPath(
      initialDirectory: filePickerInitialDirectoryFromPath(
        widget.initialDirectory,
      ),
    );
    if (!mounted) {
      return;
    }

    switch (selection) {
      case PickedFilePath(:final path):
        setState(() {
          _programPathController.text = path;
        });
      case CancelledFilePathPick():
        return;
    }
  }

  void _applySelectedProfile() {
    final profile = _selectedProfile;
    final programPath = _programPathController.text.trim();
    if (profile == null || programPath.isEmpty) {
      return;
    }

    Navigator.of(context).pop(
      ApplyProfileManagerDecision(
        profileId: profile.id,
        programPath: programPath,
      ),
    );
  }

  void _installSelectedProfile() {
    final profile = _selectedProfile;
    if (profile == null || _detailsState is! LoadedInstallProfileDetails) {
      return;
    }

    Navigator.of(
      context,
    ).pop(InstallProfileManagerDecision(profileId: profile.id));
  }
}

sealed class ProfileManifestEditorDecision {
  const ProfileManifestEditorDecision();
}

final class SavedProfileManifest extends ProfileManifestEditorDecision {
  const SavedProfileManifest(this.manifestJson);

  final String manifestJson;
}

final class CancelledProfileManifestEditor
    extends ProfileManifestEditorDecision {
  const CancelledProfileManifestEditor();
}

class _ProfileManifestEditorDialog extends StatefulWidget {
  const _ProfileManifestEditorDialog({
    required this.title,
    required this.initialManifestJson,
  });

  final String title;
  final String initialManifestJson;

  @override
  State<_ProfileManifestEditorDialog> createState() =>
      _ProfileManifestEditorDialogState();
}

class _ProfileManifestEditorDialogState
    extends State<_ProfileManifestEditorDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialManifestJson);
  }

  @override
  void dispose() {
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
          ),
          onChanged: (_) => setState(() {}),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(const CancelledProfileManifestEditor()),
          child: Text(localizations.cancel),
        ),
        FilledButton(
          onPressed: _controller.text.trim().isEmpty
              ? null
              : () => Navigator.of(
                  context,
                ).pop(SavedProfileManifest(_controller.text)),
          child: Text(localizations.save),
        ),
      ],
    );
  }
}

class _ProfileManagerDetails extends StatelessWidget {
  const _ProfileManagerDetails({
    required this.selectedProfile,
    required this.profile,
    required this.state,
    required this.programPathController,
    required this.onProgramPathChanged,
    required this.onChooseProgram,
  });

  final InstallProfileListItem? selectedProfile;
  final InstallProfileDetails? profile;
  final InstallProfileDetailsState state;
  final TextEditingController programPathController;
  final VoidCallback onProgramPathChanged;
  final VoidCallback onChooseProgram;

  @override
  Widget build(BuildContext context) {
    final localizations = KonyakLocalizations.of(context);
    final selectedProfile = this.selectedProfile;
    if (selectedProfile == null) {
      return Center(child: Text(localizations.noInstallProfilesFound));
    }

    final profile = this.profile;
    if (profile == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            selectedProfile.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (state is LoadingInstallProfileDetails)
            Row(
              children: [
                const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(localizations.loadingProfileDetailsEllipsis),
              ],
            ),
          if (state case FailedInstallProfileDetails(:final message))
            Text(
              message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      );
    }

    return SingleChildScrollView(
      key: const ValueKey('profile-manager-details-scroll'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(profile.name, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(profile.summary),
          const SizedBox(height: 12),
          _ProfileDetailRow(
            label: localizations.installProfileSource,
            value:
                '${profile.profileSourceKind} / ${profile.profileSourceId}\n'
                'SHA-256: ${profile.profileDigest}',
          ),
          _ProfileDetailRow(
            label: localizations.installProfileInstallerUrl,
            value:
                '${profile.installerResource.url}\n'
                'SHA-256: ${profile.installerResource.sha256}',
          ),
          _ProfileDetailRow(
            label: localizations.installProfilePlatforms,
            value: profile.platforms.join(', '),
          ),
          _ProfileDetailRow(
            label: localizations.installProfileWindowsVersion,
            value: profile.windowsVersion,
          ),
          _ProfileDetailRow(
            label: localizations.installProfileManagedProgramPath,
            value: profile.managedProgramPath,
          ),
          _ProfileDetailRow(
            label: localizations.installProfileDependencies,
            value: profile.preInstallActions.isEmpty
                ? localizations.installProfileNoDependencies
                : _preInstallActionOrderLabel(profile.preInstallActions),
            tooltip: _preInstallActionResourceAuditLabel(
              profile.preInstallActions,
            ),
          ),
          _ProfileDetailRow(
            label: localizations.installProfileRunCompletionPolicy,
            value: profile.runCompletionPolicy,
          ),
          _ProfileDetailRow(
            label: localizations.installProfileCompatibilityRules,
            value: _compatibilityRulesLabel(profile, localizations),
          ),
          const SizedBox(height: 18),
          TextField(
            key: const ValueKey('profile-manager-program-path-field'),
            controller: programPathController,
            decoration: InputDecoration(
              labelText: localizations.programPath,
              suffixIcon: IconButton(
                tooltip: localizations.chooseProgramFile,
                onPressed: onChooseProgram,
                icon: const Icon(Icons.folder_open),
              ),
            ),
            textInputAction: TextInputAction.done,
            onChanged: (_) => onProgramPathChanged(),
          ),
        ],
      ),
    );
  }
}

class _ProfileDetailRow extends StatelessWidget {
  const _ProfileDetailRow({
    required this.label,
    required this.value,
    this.tooltip,
  });

  final String label;
  final String value;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: labelStyle),
          const SizedBox(height: 2),
          switch (tooltip) {
            final String message when message.isNotEmpty => Tooltip(
              message: message,
              child: Text(value),
            ),
            _ => Text(value),
          },
        ],
      ),
    );
  }
}

String _compatibilityRulesLabel(
  InstallProfileDetails profile,
  KonyakLocalizations localizations,
) {
  final compatibilityProfile = profile.compatibilityProfile;
  final actions = compatibilityProfile.childProcessRules
      .map((rule) => rule.executableSuffix)
      .toList(growable: false);
  if (actions.isEmpty) {
    return localizations.installProfileNoCompatibilityRules;
  }

  return actions.join(', ');
}

String _preInstallActionOrderLabel(List<PreInstallActionSummary> actions) {
  return List<String>.generate(
    actions.length,
    (index) => switch (actions[index]) {
      WinetricksPreInstallActionSummary(:final verb) =>
        '${index + 1}. winetricks $verb',
      NativeDllPreInstallActionSummary(
        :final machine,
        :final destination,
        :final targetFileName,
      ) =>
        '${index + 1}. nativeDll $machine → $destination/$targetFileName',
    },
    growable: false,
  ).join('\n');
}

String _preInstallActionResourceAuditLabel(
  List<PreInstallActionSummary> actions,
) {
  return actions
      .whereType<NativeDllPreInstallActionSummary>()
      .map(
        (action) =>
            '${action.componentId}\n${action.resource.url}\n'
            'SHA-256: ${action.resource.sha256}',
      )
      .join('\n\n');
}
