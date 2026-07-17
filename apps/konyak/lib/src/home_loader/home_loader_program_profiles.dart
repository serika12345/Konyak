import '../app/dialogs/dialog_decision.dart';
import '../app/dialogs/profile_manager_dialog.dart';
import '../bottles/bottle_summary.dart';
import '../cli/konyak_cli_program_commands.dart';
import '../cli/konyak_cli_program_result_types.dart';
import '../cli/program_profile_install_contract.dart';
import '../files/file_path_pick_result.dart';
import '../l10n/konyak_localizations.dart';
import 'blocking_progress_state.dart';
import 'home_loader.dart';
import 'home_loader_bottles.dart';

extension KonyakHomeLoaderProgramProfiles on KonyakHomeLoaderState {
  Future<void> showProfileManager(BottleSummary bottle) async {
    updateState(() {
      profileManagerProgress = BlockingProgressState.indeterminate(
        KonyakLocalizations.of(context).loadingInstallProfilesEllipsis,
      );
    });

    late final InstallProfileListLoadResult listResult;
    try {
      listResult = await widget.cliClient.listInstallProfiles();
    } finally {
      if (mounted) {
        updateState(() {
          profileManagerProgress = const BlockingProgressState.hidden();
        });
      }
    }

    if (!mounted) {
      return;
    }

    switch (listResult) {
      case LoadedInstallProfiles(:final profiles):
        await _showProfileManagerDialog(bottle: bottle, profiles: profiles);
      case InstallProfileListLoadFailure(:final message):
        showSnackBar(message);
    }
  }

  Future<void> _showProfileManagerDialog({
    required BottleSummary bottle,
    required List<InstallProfileListItem> profiles,
  }) async {
    final decision = await showDialogDecision<ProfileManagerDecision>(
      context: context,
      dismissedDecision: const CancelledProfileManagerDialog(),
      builder: (context) => ProfileManagerDialog(
        bottleName: bottle.name,
        profiles: profiles,
        programFilePicker: widget.programFilePicker,
        initialDirectory: _bottleDriveCPath(bottle.path),
        inspectProfile: (profileId) =>
            widget.cliClient.inspectInstallProfile(profileId: profileId),
      ),
    );

    if (!mounted) {
      return;
    }

    switch (decision) {
      case InstallProfileManagerDecision(:final profileId):
        await _installProgramProfile(
          bottle: bottle,
          profiles: profiles,
          profileId: profileId,
        );
      case ApplyProfileManagerDecision(:final profileId, :final programPath):
        await _applyProgramProfile(
          bottle: bottle,
          profiles: profiles,
          profileId: profileId,
          programPath: programPath,
        );
      case ImportProfileManagerDecision():
        await _importInstallProfile(bottle);
      case DuplicateProfileManagerDecision(:final manifestJson):
        await _runInstallProfileMutation(
          bottle: bottle,
          progressMessage: KonyakLocalizations.of(
            context,
          ).importingProfileEllipsis,
          execute: () => widget.cliClient.importInstallProfileManifest(
            manifestJson: manifestJson,
          ),
        );
      case EditProfileManagerDecision(
        :final profileId,
        :final expectedDigest,
        :final manifestJson,
      ):
        await _runInstallProfileMutation(
          bottle: bottle,
          progressMessage: KonyakLocalizations.of(context)
              .updatingProfileEllipsis(
                _profileNameById(profiles: profiles, profileId: profileId),
              ),
          execute: () => widget.cliClient.updateInstallProfileManifest(
            profileId: profileId,
            expectedDigest: expectedDigest,
            manifestJson: manifestJson,
          ),
        );
      case ExportProfileManagerDecision(:final profileId, :final suggestedName):
        await _exportInstallProfile(
          bottle: bottle,
          profiles: profiles,
          profileId: profileId,
          suggestedName: suggestedName,
        );
      case DeleteProfileManagerDecision(
        :final profileId,
        :final profileName,
        :final expectedDigest,
      ):
        await _runInstallProfileMutation(
          bottle: bottle,
          progressMessage: KonyakLocalizations.of(
            context,
          ).deletingProfileEllipsis(profileName),
          execute: () => widget.cliClient.deleteInstallProfile(
            profileId: profileId,
            expectedDigest: expectedDigest,
          ),
        );
      case CancelledProfileManagerDialog():
        return;
    }
  }

  Future<void> _importInstallProfile(BottleSummary bottle) async {
    final selection = await widget.installProfileManifestPicker
        .pickProfileToImport();
    if (!mounted) {
      return;
    }

    switch (selection) {
      case PickedFilePath(:final path):
        await _runInstallProfileMutation(
          bottle: bottle,
          progressMessage: KonyakLocalizations.of(
            context,
          ).importingProfileEllipsis,
          execute: () =>
              widget.cliClient.importInstallProfile(sourcePath: path),
        );
      case CancelledFilePathPick():
        await showProfileManager(bottle);
    }
  }

  Future<void> _exportInstallProfile({
    required BottleSummary bottle,
    required List<InstallProfileListItem> profiles,
    required String profileId,
    required String suggestedName,
  }) async {
    final selection = await widget.installProfileManifestPicker
        .pickProfileExportPath(suggestedName: suggestedName);
    if (!mounted) {
      return;
    }

    switch (selection) {
      case PickedFilePath(:final path):
        await _runInstallProfileMutation(
          bottle: bottle,
          progressMessage: KonyakLocalizations.of(context)
              .exportingProfileEllipsis(
                _profileNameById(profiles: profiles, profileId: profileId),
              ),
          execute: () => widget.cliClient.exportInstallProfile(
            profileId: profileId,
            destinationPath: path,
          ),
        );
      case CancelledFilePathPick():
        await showProfileManager(bottle);
    }
  }

  Future<void> _runInstallProfileMutation({
    required BottleSummary bottle,
    required String progressMessage,
    required Future<InstallProfileMutationLoadResult> Function() execute,
  }) async {
    updateState(() {
      profileManagerProgress = BlockingProgressState.indeterminate(
        progressMessage,
      );
    });

    late final InstallProfileMutationLoadResult result;
    try {
      result = await execute();
    } finally {
      if (mounted) {
        updateState(() {
          profileManagerProgress = const BlockingProgressState.hidden();
        });
      }
    }

    if (!mounted) {
      return;
    }

    final localizations = KonyakLocalizations.of(context);
    switch (result) {
      case ValidatedInstallProfile(:final profile):
        showSnackBar(localizations.updatedProfile(profile.name));
      case ImportedInstallProfile(:final profile):
        showSnackBar(localizations.importedProfile(profile.name));
      case UpdatedInstallProfile(:final profile):
        showSnackBar(localizations.updatedProfile(profile.name));
      case ExportedInstallProfile(:final profile):
        showSnackBar(localizations.exportedProfile(profile.name));
      case DeletedInstallProfile(:final profileId):
        showSnackBar(localizations.deletedProfile(profileId));
      case InstallProfileMutationLoadFailure(:final message):
        showSnackBar(message);
    }
    await showProfileManager(bottle);
  }

  Future<void> _installProgramProfile({
    required BottleSummary bottle,
    required List<InstallProfileListItem> profiles,
    required String profileId,
  }) async {
    final profileName = _profileNameById(
      profiles: profiles,
      profileId: profileId,
    );
    final localizations = KonyakLocalizations.of(context);

    updateState(() {
      profileManagerProgress = BlockingProgressState.indeterminate(
        localizations.applyingProfileEllipsis(profileName),
      );
    });

    late final ProgramProfileInstallLoadResult result;
    try {
      result = await widget.cliClient.installProgramProfile(
        profileId: profileId,
        bottleId: bottle.id,
        progressObservation: NotifyProgramProfileInstallProgress((progress) {
          if (!mounted) {
            return;
          }
          updateState(() {
            profileManagerProgress = BlockingProgressState.indeterminate(
              _programProfileInstallProgressMessage(
                localizations: localizations,
                profileName: profileName,
                progress: progress,
              ),
            );
          });
        }),
      );
    } finally {
      if (mounted) {
        updateState(() {
          profileManagerProgress = const BlockingProgressState.hidden();
        });
      }
    }

    if (!mounted) {
      return;
    }

    switch (result) {
      case InstalledProgramProfile():
        showSnackBar(localizations.installedRuntime(profileName));
        await reloadBottle(bottle);
      case ProgramProfileInstallLoadFailure(:final message):
        showSnackBar(message);
    }
  }

  Future<void> _applyProgramProfile({
    required BottleSummary bottle,
    required List<InstallProfileListItem> profiles,
    required String profileId,
    required String programPath,
  }) async {
    final profileName = _profileNameById(
      profiles: profiles,
      profileId: profileId,
    );

    updateState(() {
      profileManagerProgress = BlockingProgressState.indeterminate(
        KonyakLocalizations.of(context).applyingProfileEllipsis(profileName),
      );
    });

    late final ProgramProfileApplyLoadResult result;
    try {
      result = await widget.cliClient.applyProgramProfile(
        profileId: profileId,
        bottleId: bottle.id,
        programPath: programPath,
      );
    } finally {
      if (mounted) {
        updateState(() {
          profileManagerProgress = const BlockingProgressState.hidden();
        });
      }
    }

    if (!mounted) {
      return;
    }

    switch (result) {
      case AppliedProgramProfile():
        showSnackBar(
          KonyakLocalizations.of(context).appliedProfile(profileName),
        );
        await reloadBottle(bottle);
      case ProgramProfileApplyLoadFailure(:final message):
        showSnackBar(message);
    }
  }
}

String _profileNameById({
  required List<InstallProfileListItem> profiles,
  required String profileId,
}) {
  for (final profile in profiles) {
    if (profile.id == profileId) {
      return profile.name;
    }
  }

  return profileId;
}

String _bottleDriveCPath(String bottlePath) {
  if (bottlePath.endsWith('/')) {
    return '${bottlePath}drive_c';
  }

  return '$bottlePath/drive_c';
}

String _programProfileInstallProgressMessage({
  required KonyakLocalizations localizations,
  required String profileName,
  required ProgramProfileInstallProgress progress,
}) {
  return switch (progress.stage) {
    ProgramProfileInstallStage.preflight =>
      localizations.loadingProfileDetailsEllipsis,
    ProgramProfileInstallStage.download => localizations.downloadProgress(
      profileName,
    ),
    ProgramProfileInstallStage.verification =>
      localizations.applyingProfileEllipsis(profileName),
    ProgramProfileInstallStage.installer =>
      localizations.applyingProfileEllipsis(profileName),
    ProgramProfileInstallStage.resourceCleanup =>
      localizations.applyingProfileEllipsis(profileName),
    ProgramProfileInstallStage.preInstallAction => switch (progress.action) {
      ProgramProfileInstallAction(:final index, :final id) =>
        localizations.installingVerb('${index + 1}. $id'),
      NoProgramProfileInstallAction() => localizations.applyingProfileEllipsis(
        profileName,
      ),
    },
    ProgramProfileInstallStage.managedProgram =>
      localizations.applyingProfileEllipsis(profileName),
    ProgramProfileInstallStage.persistence =>
      localizations.applyingProfileEllipsis(profileName),
  };
}
