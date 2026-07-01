import 'dart:async';

import 'package:flutter/material.dart';

import '../app/dialogs/bottle_management_dialogs.dart';
import '../app/dialogs/create_bottle_dialog.dart';
import '../app/utils/bottle_lists.dart';
import '../bottles/bottle_summary.dart';
import '../cli/konyak_cli_bottle_commands.dart';
import '../cli/konyak_cli_bottle_result_types.dart';
import '../cli/konyak_cli_read_commands.dart';
import '../cli/konyak_cli_runtime_result_types.dart';
import '../files/file_path_pick_result.dart';
import '../l10n/konyak_localizations.dart';
import '../runtimes/runtime_summary.dart';
import 'blocking_progress_state.dart';
import 'bottle_operation_outcome.dart';
import 'bottle_update_success_feedback.dart';
import 'home_bottle_list_state.dart';
import 'home_loader.dart';
import 'home_loader_executables.dart';
import 'home_loader_runtimes.dart';
import 'runtime_settings_pending_controls_state.dart';

extension KonyakHomeLoaderBottles on KonyakHomeLoaderState {
  Future<void> loadBottles() async {
    updateState(() {
      homeBottleListState = startLoadingHomeBottleList(homeBottleListState);
    });

    final result = await widget.cliClient.listBottles();

    if (!mounted) {
      return;
    }

    updateState(() {
      switch (result) {
        case LoadedBottleList(:final bottles):
          homeBottleListState = loadHomeBottleList(bottles);
        case BottleListLoadFailure(:final message):
          homeBottleListState = failHomeBottleListLoad(
            state: homeBottleListState,
            message: message,
          );
      }
    });

    unawaited(drainPendingExecutableOpenPaths());
  }

  Future<void> createBottle() async {
    await createBottleFromDialog();
  }

  Future<BottleOperationOutcome> createBottleFromDialog() async {
    final decision = createBottleDecisionFromNullable(
      await showDialog<CreateBottleDecision>(
        context: context,
        builder: (context) => const CreateBottleDialog(),
      ),
    );

    return switch (decision) {
      final CreateBottleFromDialog input => createBottleFromInput(input),
      CancelledCreateBottleDialog() => const BottleOperationOutcome.cancelled(),
    };
  }

  Future<BottleOperationOutcome> createBottleFromInput(
    CreateBottleFromDialog input,
  ) async {
    updateState(() {
      createBottleProgress = BlockingProgressState.indeterminate(
        KonyakLocalizations.of(context).creatingBottleEllipsis,
      );
    });

    late final BottleCreateLoadResult result;
    try {
      result = await widget.cliClient.createBottle(
        name: input.name,
        windowsVersion: input.windowsVersion,
      );
    } finally {
      if (mounted) {
        updateState(() {
          createBottleProgress = const BlockingProgressState.hidden();
        });
      }
    }

    if (!mounted) {
      return const BottleOperationOutcome.unmounted();
    }

    switch (result) {
      case CreatedBottle(:final bottle):
        storeBottle(bottle);
        return BottleOperationOutcome.completed(bottle);
      case ExistingBottle(:final message) ||
          BottleCreateLoadFailure(:final message):
        showSnackBar(message);
        return const BottleOperationOutcome.failed();
    }
  }

  void storeBottle(
    BottleSummary bottle, {
    HomeBottleStoreMode mode = const HomeBottleStoreMode.upsert(),
  }) {
    updateState(() {
      homeBottleListState = storeHomeBottle(
        state: homeBottleListState,
        bottle: bottle,
        mode: mode,
      );
    });
  }

  void handleBottleUpdateResult(
    BottleUpdateLoadResult result, {
    HomeBottleStoreMode mode = const HomeBottleStoreMode.upsert(),
    BottleUpdateSuccessFeedback successFeedback =
        const BottleUpdateSuccessFeedback.silent(),
  }) {
    switch (result) {
      case UpdatedBottle(:final bottle):
        storeBottle(bottle, mode: mode);
        switch (bottleUpdateSuccessNotice(
          feedback: successFeedback,
          bottle: bottle,
        )) {
          case MessageBottleUpdateSuccessNotice(:final message):
            showSnackBar(message);
          case NoBottleUpdateSuccessNotice():
            return;
        }
      case MissingBottleUpdate(:final message) ||
          BottleUpdateLoadFailure(:final message):
        showSnackBar(message);
    }
  }

  Future<void> setRuntimeSettings({
    required BottleSummary bottle,
    required BottleRuntimeSettingsSummary runtimeSettings,
    required String controlKey,
  }) async {
    if (hasPendingRuntimeSettingsControl(
      state: runtimeSettingsPendingControlsState,
      bottleId: bottle.id,
    )) {
      return;
    }

    final previousBottle = switch (findBottleById(bottles, bottle.id)) {
      BottleSelectionFound(bottle: final foundBottle) => foundBottle,
      BottleSelectionMissing() => bottle,
    };
    updateState(() {
      runtimeSettingsPendingControlsState = startRuntimeSettingsControlUpdate(
        state: runtimeSettingsPendingControlsState,
        bottleId: bottle.id,
        controlKey: controlKey,
      );
      homeBottleListState = storeHomeBottle(
        state: homeBottleListState,
        bottle: previousBottle.withRuntimeSettings(runtimeSettings),
        mode: const HomeBottleStoreMode.upsert(),
      );
    });

    final BottleUpdateLoadResult result;
    result = await widget.cliClient.setRuntimeSettings(
      bottleId: bottle.id,
      runtimeSettings: runtimeSettings,
    );

    if (!mounted) {
      return;
    }

    final failureMessages = <String>[];
    updateState(() {
      runtimeSettingsPendingControlsState = finishRuntimeSettingsControlUpdate(
        state: runtimeSettingsPendingControlsState,
        bottleId: bottle.id,
      );
      switch (result) {
        case UpdatedBottle(:final bottle):
          homeBottleListState = storeHomeBottle(
            state: homeBottleListState,
            bottle: bottle,
            mode: const HomeBottleStoreMode.upsert(),
          );
        case MissingBottleUpdate(:final message) ||
            BottleUpdateLoadFailure(:final message):
          homeBottleListState = storeHomeBottle(
            state: homeBottleListState,
            bottle: previousBottle,
            mode: const HomeBottleStoreMode.upsert(),
          );
          failureMessages.add(message);
      }
    });

    for (final message in failureMessages) {
      showSnackBar(message);
    }
  }

  Future<void> loadBottleConfiguration(BottleSummary bottle) async {
    await reloadBottle(bottle);
    await loadRuntimeCapabilities();
  }

  Future<BottleOperationOutcome> reloadBottle(BottleSummary bottle) async {
    final result = await widget.cliClient.inspectBottle(bottle.id);

    if (!mounted) {
      return const BottleOperationOutcome.unmounted();
    }

    switch (result) {
      case LoadedBottleDetail(:final bottle):
        storeBottle(bottle);
        return BottleOperationOutcome.completed(bottle);
      case MissingBottleDetail(:final message) ||
          BottleDetailLoadFailure(:final message):
        showSnackBar(message);
        return const BottleOperationOutcome.failed();
    }
  }

  Future<void> loadRuntimeCapabilities() async {
    final result = await widget.cliClient.listKnownRuntimes();

    if (!mounted) {
      return;
    }

    switch (result) {
      case LoadedRuntimeList(:final runtimes):
        setKnownRuntimes(runtimes);
      case RuntimeListLoadFailure():
        setKnownRuntimes(const <RuntimeSummary>[]);
    }
  }

  Future<void> deleteBottle(BottleSummary bottle) async {
    final decision = deleteBottleDecisionFromNullable(
      await showDialog<DeleteBottleDecision>(
        context: context,
        builder: (context) => DeleteBottleDialog(bottleName: bottle.name),
      ),
    );

    switch (decision) {
      case DeleteBottleConfirmed():
        await deleteBottleAfterConfirmation(bottle);
      case CancelledDeleteBottleDialog():
        return;
    }
  }

  Future<void> deleteBottleAfterConfirmation(BottleSummary bottle) async {
    final result = await widget.cliClient.deleteBottle(bottle.id);

    if (!mounted) {
      return;
    }

    switch (result) {
      case DeletedBottle(:final bottle):
        updateState(() {
          homeBottleListState = removeHomeBottle(
            state: homeBottleListState,
            bottleId: bottle.id,
          );
        });
        showSnackBar(
          KonyakLocalizations.of(context).deletedBottle(bottle.name),
        );
      case MissingBottleDelete(:final message):
        showSnackBar(message);
      case BottleDeleteLoadFailure(:final message):
        showBottleDeleteFailureSnackBar(bottle: bottle, message: message);
    }
  }

  void showBottleDeleteFailureSnackBar({
    required BottleSummary bottle,
    required String message,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    showWarningSnackBar(
      message,
      action: SnackBarAction(
        label: KonyakLocalizations.of(context).retry,
        textColor: colorScheme.onErrorContainer,
        onPressed: () {
          final currentBottle = switch (findBottleById(bottles, bottle.id)) {
            BottleSelectionFound(bottle: final foundBottle) => foundBottle,
            BottleSelectionMissing() => bottle,
          };
          unawaited(deleteBottleAfterConfirmation(currentBottle));
        },
      ),
    );
  }

  Future<void> renameBottle(BottleSummary bottle) async {
    final decision = renameBottleDecisionFromNullable(
      await showDialog<RenameBottleDecision>(
        context: context,
        builder: (context) => RenameBottleDialog(bottleName: bottle.name),
      ),
    );

    switch (decision) {
      case RenameBottleToName(:final name):
        final result = await widget.cliClient.renameBottle(
          bottleId: bottle.id,
          name: name,
        );

        if (!mounted) {
          return;
        }

        handleBottleUpdateResult(
          result,
          mode: HomeBottleStoreMode.replace(bottle.id),
          successFeedback: BottleUpdateSuccessFeedback.message(
            (bottle) =>
                KonyakLocalizations.of(context).renamedBottle(bottle.name),
          ),
        );
      case CancelledRenameBottleDialog():
        return;
    }
  }

  Future<void> moveBottle(BottleSummary bottle) async {
    final decision = moveBottleDecisionFromNullable(
      await showDialog<MoveBottleDecision>(
        context: context,
        builder: (context) => MoveBottleDialog(
          bottleName: bottle.name,
          initialPath: bottle.path,
          directoryPicker: widget.directoryPicker,
        ),
      ),
    );

    switch (decision) {
      case MoveBottleToPath(:final path):
        final result = await widget.cliClient.moveBottle(
          bottleId: bottle.id,
          path: path,
        );

        if (!mounted) {
          return;
        }

        handleBottleUpdateResult(
          result,
          successFeedback: BottleUpdateSuccessFeedback.message(
            (bottle) =>
                KonyakLocalizations.of(context).movedBottle(bottle.name),
          ),
        );
      case CancelledMoveBottleDialog():
        return;
    }
  }

  Future<void> exportBottleArchive(BottleSummary bottle) async {
    final archiveSelection = await widget.bottleArchivePicker
        .pickArchiveExportPath(suggestedName: '${bottle.id}.konyak-bottle.tar');
    switch (archiveSelection) {
      case PickedFilePath(:final path):
        await exportBottleArchiveToPath(bottle: bottle, archivePath: path);
      case CancelledFilePathPick():
        return;
    }
  }

  Future<void> exportBottleArchiveToPath({
    required BottleSummary bottle,
    required String archivePath,
  }) async {
    updateState(() {
      archiveProgress = BlockingProgressState.indeterminate(
        KonyakLocalizations.of(context).exportingBottleArchiveEllipsis,
      );
    });

    late final BottleArchiveExportLoadResult result;
    try {
      result = await widget.cliClient.exportBottleArchive(
        bottleId: bottle.id,
        archivePath: archivePath,
      );
    } finally {
      if (mounted) {
        updateState(() {
          archiveProgress = const BlockingProgressState.hidden();
        });
      }
    }

    if (!mounted) {
      return;
    }

    switch (result) {
      case ExportedBottleArchive():
        showSnackBar(
          KonyakLocalizations.of(context).exportedBottle(bottle.name),
        );
      case BottleArchiveExportLoadFailure(:final message):
        showSnackBar(message);
    }
  }

  Future<void> importBottleArchive() async {
    final archiveSelection = await widget.bottleArchivePicker
        .pickArchiveToImport();
    switch (archiveSelection) {
      case PickedFilePath(:final path):
        await importBottleArchiveFromPath(path);
      case CancelledFilePathPick():
        return;
    }
  }

  Future<void> importBottleArchiveFromPath(String archivePath) async {
    updateState(() {
      archiveProgress = BlockingProgressState.indeterminate(
        KonyakLocalizations.of(context).importingBottleArchiveEllipsis,
      );
    });

    late final BottleArchiveImportLoadResult result;
    try {
      result = await widget.cliClient.importBottleArchive(
        archivePath: archivePath,
      );
    } finally {
      if (mounted) {
        updateState(() {
          archiveProgress = const BlockingProgressState.hidden();
        });
      }
    }

    if (!mounted) {
      return;
    }

    switch (result) {
      case ImportedBottleArchive(:final bottle):
        storeBottle(bottle);
        showSnackBar(
          KonyakLocalizations.of(context).importedBottle(bottle.name),
        );
      case BottleArchiveImportLoadFailure(:final message):
        showSnackBar(message);
    }
  }
}
