import 'dart:async';

import '../app/dialogs/bottle_management_dialogs.dart';
import '../app/dialogs/dialog_decision.dart';
import '../app/dialogs/pin_program_dialog.dart';
import '../app/utils/bottle_lists.dart';
import '../bottles/bottle_summary.dart';
import '../cli/konyak_cli_program_commands.dart';
import '../cli/konyak_cli_program_result_types.dart';
import '../l10n/konyak_localizations.dart';
import 'bottle_update_success_feedback.dart';
import 'home_loader.dart';
import 'home_loader_bottles.dart';
import 'pinned_program_settings_cache_state.dart';

extension KonyakHomeLoaderPinnedPrograms on KonyakHomeLoaderState {
  Future<void> pinProgram(BottleSummary bottle) async {
    final decision = await showDialogDecision<PinProgramDecision>(
      context: context,
      dismissedDecision: const PinProgramDecision.cancelled(),
      builder: (context) => PinProgramDialog(
        bottleName: bottle.name,
        programFilePicker: widget.programFilePicker,
      ),
    );

    switch (decision) {
      case PinProgramFromDialog(:final name, :final programPath):
        await pinProgramPath(
          bottle: bottle,
          name: name,
          programPath: programPath,
        );
      case CancelledPinProgramDialog():
        return;
    }
  }

  Future<void> pinProgramPath({
    required BottleSummary bottle,
    required String name,
    required String programPath,
  }) async {
    final result = await widget.cliClient.pinProgram(
      bottleId: bottle.id,
      name: name,
      programPath: programPath,
    );

    if (!mounted) {
      return;
    }

    handleBottleUpdateResult(
      result,
      successFeedback: BottleUpdateSuccessFeedback.message(
        (_) => KonyakLocalizations.of(context).pinnedProgram(name),
      ),
    );
  }

  Future<void> unpinProgram({
    required BottleSummary bottle,
    required PinnedProgramSummary program,
  }) async {
    final result = await widget.cliClient.unpinProgram(
      bottleId: bottle.id,
      programPath: program.path,
    );

    if (!mounted) {
      return;
    }

    handleBottleUpdateResult(
      result,
      successFeedback: BottleUpdateSuccessFeedback.message(
        (_) => KonyakLocalizations.of(context).unpinnedProgram(program.name),
      ),
    );
  }

  Future<void> renamePinnedProgram({
    required BottleSummary bottle,
    required PinnedProgramSummary program,
  }) async {
    final decision = await showDialogDecision<RenamePinnedProgramDecision>(
      context: context,
      dismissedDecision: const RenamePinnedProgramDecision.cancelled(),
      builder: (context) =>
          RenamePinnedProgramDialog(programName: program.name),
    );

    switch (decision) {
      case RenamePinnedProgramToName(:final name):
        final result = await widget.cliClient.renamePinnedProgram(
          bottleId: bottle.id,
          programPath: program.path,
          name: name,
        );

        if (!mounted) {
          return;
        }

        handleBottleUpdateResult(
          result,
          successFeedback: BottleUpdateSuccessFeedback.message(
            (_) => KonyakLocalizations.of(context).renamedProgram(name),
          ),
        );
      case CancelledRenamePinnedProgramDialog():
        return;
    }
  }

  Future<void> openPinnedProgramLocation({
    required BottleSummary bottle,
    required PinnedProgramSummary program,
  }) async {
    final result = await widget.cliClient.openProgramLocation(
      bottleId: bottle.id,
      programPath: program.path,
    );

    if (!mounted) {
      return;
    }

    final message = switch (result) {
      OpenedProgramLocation() => KonyakLocalizations.of(
        context,
      ).openedProgramLocation(program.name),
      ProgramLocationOpenFailure(:final message) => message,
    };

    showSnackBar(message);
  }

  Future<void> loadPinnedProgramSettings({
    required BottleSummary bottle,
    required PinnedProgramSummary program,
  }) async {
    final key = programSettingsKey(
      bottleId: bottle.id,
      programPath: program.path,
    );
    updateState(() {
      pinnedProgramSettingsCacheState = startLoadingPinnedProgramSettings(
        state: pinnedProgramSettingsCacheState,
        key: key,
      );
    });

    final result = await widget.cliClient.getProgramSettings(
      bottleId: bottle.id,
      programPath: program.path,
    );

    if (!mounted) {
      return;
    }

    updateState(() {
      switch (result) {
        case LoadedProgramSettings(:final settings):
          pinnedProgramSettingsCacheState = storeLoadedPinnedProgramSettings(
            state: pinnedProgramSettingsCacheState,
            key: key,
            settings: settings,
          );
        case MissingProgramSettingsBottle() || ProgramSettingsLoadFailure():
          pinnedProgramSettingsCacheState = removePinnedProgramSettings(
            state: pinnedProgramSettingsCacheState,
            key: key,
          );
      }
    });

    switch (result) {
      case LoadedProgramSettings():
        break;
      case MissingProgramSettingsBottle(:final message) ||
          ProgramSettingsLoadFailure(:final message):
        showSnackBar(message);
    }
  }

  Future<void> setPinnedProgramSettings({
    required BottleSummary bottle,
    required PinnedProgramSummary program,
    required ProgramSettingsSummary settings,
  }) async {
    final result = await widget.cliClient.setProgramSettings(
      bottleId: bottle.id,
      programPath: program.path,
      settings: settings,
    );

    if (!mounted) {
      return;
    }

    switch (result) {
      case LoadedProgramSettings(:final settings):
        updateState(() {
          pinnedProgramSettingsCacheState = savePinnedProgramSettings(
            state: pinnedProgramSettingsCacheState,
            key: programSettingsKey(
              bottleId: bottle.id,
              programPath: program.path,
            ),
            settings: settings,
          );
        });
        showSnackBar(
          KonyakLocalizations.of(
            context,
          ).savedProgramConfiguration(program.name),
        );
      case MissingProgramSettingsBottle(:final message) ||
          ProgramSettingsLoadFailure(:final message):
        showSnackBar(message);
    }
  }
}
