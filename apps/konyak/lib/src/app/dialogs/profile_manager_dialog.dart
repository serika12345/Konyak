import 'dart:async';

import 'package:flutter/material.dart';

import '../../cli/konyak_cli_program_result_types.dart';
import '../../files/file_path_pick_result.dart';
import '../../files/file_picker_arguments.dart';
import '../../files/program_file_picker.dart';
import '../../l10n/konyak_localizations.dart';

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
    final canInstall =
        selectedProfile != null && _detailsState is LoadedInstallProfileDetails;
    final canApply =
        selectedProfile != null &&
        _programPathController.text.trim().isNotEmpty &&
        _detailsState is LoadedInstallProfileDetails;

    return AlertDialog(
      title: Text(localizations.profileManagerIn(widget.bottleName)),
      content: SizedBox(
        width: 800,
        height: 520,
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
                            '${profile.id} v${profile.profileVersion}',
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
                      profile: switch (_detailsState) {
                        LoadedInstallProfileDetails(:final profile) => profile,
                        _ => null,
                      },
                      state: _detailsState,
                      programPathController: _programPathController,
                      onProgramPathChanged: () => setState(() {}),
                      onChooseProgram: _chooseProgramFile,
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
            value: profile.dependencyWinetricksVerbs.isEmpty
                ? localizations.installProfileNoDependencies
                : _dependencyOrderLabel(profile.dependencyWinetricksVerbs),
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
  const _ProfileDetailRow({required this.label, required this.value});

  final String label;
  final String value;

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
          Text(value),
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

String _dependencyOrderLabel(List<String> verbs) {
  return List<String>.generate(
    verbs.length,
    (index) => '${index + 1}. ${verbs[index]}',
    growable: false,
  ).join('\n');
}
