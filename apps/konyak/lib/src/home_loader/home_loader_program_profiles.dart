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
      case CancelledProfileManagerDialog():
        return;
    }
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
    ProgramProfileInstallStage.dependency => switch (progress.dependency) {
      ProgramProfileInstallDependency(:final index, :final verb) =>
        localizations.installingVerb('${index + 1}. $verb'),
      NoProgramProfileInstallDependency() =>
        localizations.applyingProfileEllipsis(profileName),
    },
    ProgramProfileInstallStage.managedProgram =>
      localizations.applyingProfileEllipsis(profileName),
    ProgramProfileInstallStage.persistence =>
      localizations.applyingProfileEllipsis(profileName),
  };
}
