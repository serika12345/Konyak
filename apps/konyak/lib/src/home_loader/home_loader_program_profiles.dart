import '../app/dialogs/dialog_decision.dart';
import '../app/dialogs/profile_manager_dialog.dart';
import '../bottles/bottle_summary.dart';
import '../cli/konyak_cli_program_commands.dart';
import '../cli/konyak_cli_program_result_types.dart';
import '../cli/program_profile_install_contract.dart';
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
        installProfileManifestPicker: widget.installProfileManifestPicker,
        initialDirectory: _bottleDriveCPath(bottle.path),
        inspectProfile: (profileId) =>
            widget.cliClient.inspectInstallProfile(profileId: profileId),
        executeAction: _executeProfileManagerAction,
      ),
    );

    if (!mounted) {
      return;
    }

    switch (decision) {
      case InstallProfileManagerDecision(:final profileId, :final profileName):
        await _installProgramProfile(
          bottle: bottle,
          profileId: profileId,
          profileName: profileName,
        );
      case ApplyProfileManagerDecision(
        :final profileId,
        :final profileName,
        :final programPath,
      ):
        await _applyProgramProfile(
          bottle: bottle,
          profileId: profileId,
          profileName: profileName,
          programPath: programPath,
        );
      case CancelledProfileManagerDialog():
        return;
    }
  }

  Future<ProfileManagerActionResult> _executeProfileManagerAction(
    ProfileManagerActionRequest request,
  ) {
    final localizations = KonyakLocalizations.of(context);
    return switch (request) {
      ImportProfileManagerActionRequest(:final sourcePath) =>
        _runInstallProfileMutation(
          progressMessage: localizations.importingProfileEllipsis,
          execute: () =>
              widget.cliClient.importInstallProfile(sourcePath: sourcePath),
        ),
      DuplicateProfileManagerActionRequest(:final manifestJson) =>
        _runInstallProfileMutation(
          progressMessage: localizations.importingProfileEllipsis,
          execute: () => widget.cliClient.importInstallProfileManifest(
            manifestJson: manifestJson,
          ),
        ),
      EditProfileManagerActionRequest(
        :final profileId,
        :final profileName,
        :final expectedDigest,
        :final manifestJson,
      ) =>
        _runInstallProfileMutation(
          progressMessage: localizations.updatingProfileEllipsis(profileName),
          execute: () => widget.cliClient.updateInstallProfileManifest(
            profileId: profileId,
            expectedDigest: expectedDigest,
            manifestJson: manifestJson,
          ),
        ),
      ExportProfileManagerActionRequest(
        :final profileId,
        :final profileName,
        :final destinationPath,
      ) =>
        _runInstallProfileMutation(
          progressMessage: localizations.exportingProfileEllipsis(profileName),
          execute: () => widget.cliClient.exportInstallProfile(
            profileId: profileId,
            destinationPath: destinationPath,
          ),
        ),
      DeleteProfileManagerActionRequest(
        :final profileId,
        :final profileName,
        :final expectedDigest,
      ) =>
        _runInstallProfileMutation(
          progressMessage: localizations.deletingProfileEllipsis(profileName),
          execute: () => widget.cliClient.deleteInstallProfile(
            profileId: profileId,
            expectedDigest: expectedDigest,
          ),
        ),
    };
  }

  Future<ProfileManagerActionResult> _runInstallProfileMutation({
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
      if (!mounted) {
        return const UnchangedProfileManagerCatalog();
      }
      return await _profileManagerActionResult(result);
    } finally {
      if (mounted) {
        updateState(() {
          profileManagerProgress = const BlockingProgressState.hidden();
        });
      }
    }
  }

  Future<ProfileManagerActionResult> _profileManagerActionResult(
    InstallProfileMutationLoadResult result,
  ) async {
    final localizations = KonyakLocalizations.of(context);
    switch (result) {
      case ValidatedInstallProfile(:final profile):
        showSnackBar(localizations.updatedProfile(profile.name));
        return _reloadProfileManagerCatalog(
          SelectProfileManagerCatalogProfile(profile.id),
        );
      case ImportedInstallProfile(:final profile):
        showSnackBar(localizations.importedProfile(profile.name));
        return _reloadProfileManagerCatalog(
          SelectProfileManagerCatalogProfile(profile.id),
        );
      case UpdatedInstallProfile(:final profile):
        showSnackBar(localizations.updatedProfile(profile.name));
        return _reloadProfileManagerCatalog(
          SelectProfileManagerCatalogProfile(profile.id),
        );
      case ExportedInstallProfile(:final profile):
        showSnackBar(localizations.exportedProfile(profile.name));
        return const UnchangedProfileManagerCatalog();
      case DeletedInstallProfile(:final profileId):
        showSnackBar(localizations.deletedProfile(profileId));
        return _reloadProfileManagerCatalog(
          const SelectFirstProfileManagerCatalogProfile(),
        );
      case InstallProfileMutationLoadFailure(:final message):
        showSnackBar(message);
        return const UnchangedProfileManagerCatalog();
    }
  }

  Future<ProfileManagerActionResult> _reloadProfileManagerCatalog(
    ProfileManagerCatalogSelection selection,
  ) async {
    final result = await widget.cliClient.listInstallProfiles();
    if (!mounted) {
      return const UnchangedProfileManagerCatalog();
    }
    return switch (result) {
      LoadedInstallProfiles(:final profiles) => ReloadedProfileManagerCatalog(
        profiles: profiles,
        selection: selection,
      ),
      InstallProfileListLoadFailure(:final message) => () {
        showSnackBar(message);
        return const UnchangedProfileManagerCatalog();
      }(),
    };
  }

  Future<void> _installProgramProfile({
    required BottleSummary bottle,
    required String profileId,
    required String profileName,
  }) async {
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
    required String profileId,
    required String profileName,
    required String programPath,
  }) async {
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
