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
import '../l10n/konyak_localizations.dart';
import '../runtimes/runtime_summary.dart';
import 'home_loader.dart';
import 'home_loader_executables.dart';
import 'home_loader_runtimes.dart';

extension KonyakHomeLoaderBottles on KonyakHomeLoaderState {
  Future<void> loadBottles() async {
    updateState(() {
      isLoading = true;
      errorMessage = null;
    });

    final result = await widget.cliClient.listBottles();

    if (!mounted) {
      return;
    }

    updateState(() {
      isLoading = false;

      switch (result) {
        case LoadedBottleList(:final bottles):
          this.bottles = bottles;
          errorMessage = null;
        case BottleListLoadFailure(:final message):
          errorMessage = message;
      }
    });

    unawaited(drainPendingExecutableOpenPaths());
  }

  Future<void> createBottle() async {
    await createBottleFromDialog();
  }

  Future<BottleSummary?> createBottleFromDialog() async {
    final input = await showDialog<CreateBottleInput>(
      context: context,
      builder: (context) => const CreateBottleDialog(),
    );

    if (input == null) {
      return null;
    }

    return createBottleFromInput(input);
  }

  Future<BottleSummary?> createBottleFromInput(CreateBottleInput input) async {
    updateState(() {
      isCreatingBottle = true;
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
          isCreatingBottle = false;
        });
      }
    }

    if (!mounted) {
      return null;
    }

    switch (result) {
      case CreatedBottle(:final bottle):
        storeBottle(bottle);
        return bottle;
      case ExistingBottle(:final message) ||
          BottleCreateLoadFailure(:final message):
        showSnackBar(message);
        return null;
    }
  }

  void storeBottle(BottleSummary bottle, {String? oldBottleId}) {
    updateState(() {
      bottles = oldBottleId == null
          ? upsertBottle(bottles, bottle)
          : replaceBottle(bottles, oldBottleId: oldBottleId, bottle: bottle);
      errorMessage = null;
    });
  }

  void handleBottleUpdateResult(
    BottleUpdateLoadResult result, {
    String? oldBottleId,
    String Function(BottleSummary bottle)? successMessage,
  }) {
    switch (result) {
      case UpdatedBottle(:final bottle):
        storeBottle(bottle, oldBottleId: oldBottleId);
        final message = successMessage?.call(bottle);
        if (message != null) {
          showSnackBar(message);
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
    if (pendingRuntimeSettingsControls.containsKey(bottle.id)) {
      return;
    }

    final previousBottle = switch (findBottleById(bottles, bottle.id)) {
      BottleSelectionFound(bottle: final foundBottle) => foundBottle,
      BottleSelectionMissing() => bottle,
    };
    updateState(() {
      pendingRuntimeSettingsControls[bottle.id] = controlKey;
      bottles = upsertBottle(
        bottles,
        previousBottle.withRuntimeSettings(runtimeSettings),
      );
      errorMessage = null;
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
      pendingRuntimeSettingsControls.remove(bottle.id);
      switch (result) {
        case UpdatedBottle(:final bottle):
          bottles = upsertBottle(bottles, bottle);
          errorMessage = null;
        case MissingBottleUpdate(:final message) ||
            BottleUpdateLoadFailure(:final message):
          bottles = upsertBottle(bottles, previousBottle);
          errorMessage = null;
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

  Future<BottleSummary?> reloadBottle(BottleSummary bottle) async {
    final result = await widget.cliClient.inspectBottle(bottle.id);

    if (!mounted) {
      return null;
    }

    switch (result) {
      case LoadedBottleDetail(:final bottle):
        storeBottle(bottle);
        return bottle;
      case MissingBottleDetail(:final message) ||
          BottleDetailLoadFailure(:final message):
        showSnackBar(message);
        return null;
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteBottleDialog(bottleName: bottle.name),
    );

    if (confirmed != true) {
      return;
    }

    await deleteBottleAfterConfirmation(bottle);
  }

  Future<void> deleteBottleAfterConfirmation(BottleSummary bottle) async {
    final result = await widget.cliClient.deleteBottle(bottle.id);

    if (!mounted) {
      return;
    }

    switch (result) {
      case DeletedBottle(:final bottle):
        updateState(() {
          bottles = removeBottle(bottles, bottle.id);
          errorMessage = null;
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
    final name = await showDialog<String>(
      context: context,
      builder: (context) => RenameBottleDialog(bottleName: bottle.name),
    );

    if (name == null) {
      return;
    }

    final result = await widget.cliClient.renameBottle(
      bottleId: bottle.id,
      name: name,
    );

    if (!mounted) {
      return;
    }

    handleBottleUpdateResult(
      result,
      oldBottleId: bottle.id,
      successMessage: (bottle) =>
          KonyakLocalizations.of(context).renamedBottle(bottle.name),
    );
  }

  Future<void> moveBottle(BottleSummary bottle) async {
    final path = await showDialog<String>(
      context: context,
      builder: (context) => MoveBottleDialog(
        bottleName: bottle.name,
        initialPath: bottle.path,
        directoryPicker: widget.directoryPicker,
      ),
    );

    if (path == null) {
      return;
    }

    final result = await widget.cliClient.moveBottle(
      bottleId: bottle.id,
      path: path,
    );

    if (!mounted) {
      return;
    }

    handleBottleUpdateResult(
      result,
      successMessage: (bottle) =>
          KonyakLocalizations.of(context).movedBottle(bottle.name),
    );
  }

  Future<void> exportBottleArchive(BottleSummary bottle) async {
    final archivePath = await widget.bottleArchivePicker.pickArchiveExportPath(
      suggestedName: '${bottle.id}.konyak-bottle.tar',
    );
    if (archivePath == null) {
      return;
    }

    updateState(() {
      archiveProgressMessage = KonyakLocalizations.of(
        context,
      ).exportingBottleArchiveEllipsis;
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
          archiveProgressMessage = null;
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
    final archivePath = await widget.bottleArchivePicker.pickArchiveToImport();
    if (archivePath == null) {
      return;
    }

    updateState(() {
      archiveProgressMessage = KonyakLocalizations.of(
        context,
      ).importingBottleArchiveEllipsis;
    });

    late final BottleArchiveImportLoadResult result;
    try {
      result = await widget.cliClient.importBottleArchive(
        archivePath: archivePath,
      );
    } finally {
      if (mounted) {
        updateState(() {
          archiveProgressMessage = null;
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
