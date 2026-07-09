import '../bottles/bottle_summary.dart';
import '../cli/konyak_cli_program_commands.dart';
import '../cli/konyak_cli_program_result_types.dart';
import '../files/file_path_pick_result.dart';
import '../l10n/konyak_localizations.dart';
import 'blocking_progress_state.dart';
import 'home_loader.dart';
import 'home_loader_bottles.dart';

const steamProgramProfileId = 'steam';

extension KonyakHomeLoaderProgramProfiles on KonyakHomeLoaderState {
  Future<void> installSteamProfile(BottleSummary bottle) async {
    final pickResult = await widget.programFilePicker.pickProgramPath();

    final String installerPath;
    switch (pickResult) {
      case PickedFilePath(:final path):
        installerPath = path;
      case CancelledFilePathPick():
        return;
    }

    updateState(() {
      installProfileProgress = BlockingProgressState.indeterminate(
        KonyakLocalizations.of(context).installingSteamEllipsis,
      );
    });

    late final InstallProgramProfileLoadResult result;
    try {
      result = await widget.cliClient.installProfile(
        profileId: steamProgramProfileId,
        bottleId: bottle.id,
        installerPath: installerPath,
      );
    } finally {
      if (mounted) {
        updateState(() {
          installProfileProgress = const BlockingProgressState.hidden();
        });
      }
    }

    if (!mounted) {
      return;
    }

    switch (result) {
      case InstalledProgramProfile():
        showSnackBar(KonyakLocalizations.of(context).installedSteam);
        await reloadBottle(bottle);
      case InstallProgramProfileLoadFailure(:final message):
        showSnackBar(message);
    }
  }
}
