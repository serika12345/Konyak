import '../app/dialogs/dialog_decision.dart';
import '../app/dialogs/invalid_bottle_recovery_dialog.dart';
import '../bottles/invalid_bottle_record.dart';
import '../cli/konyak_cli_bottle_commands.dart';
import '../cli/konyak_cli_bottle_result_types.dart';
import '../l10n/konyak_localizations.dart';
import 'blocking_progress_state.dart';
import 'home_loader.dart';
import 'home_loader_bottles.dart';

extension KonyakHomeLoaderInvalidBottleRecovery on KonyakHomeLoaderState {
  Future<void> showInvalidBottleRecovery(
    InvalidBottleRecord invalidBottle,
  ) async {
    final decision = await showDialogDecision<InvalidBottleRecoveryDecision>(
      context: context,
      dismissedDecision: const CancelledInvalidBottleRecovery(),
      builder: (context) =>
          InvalidBottleRecoveryDialog(invalidBottle: invalidBottle),
    );

    switch (decision) {
      case DiscardInvalidBottleProfiles():
        await confirmDiscardInvalidBottleProfiles(invalidBottle);
      case CancelledInvalidBottleRecovery():
        return;
    }
  }

  Future<void> confirmDiscardInvalidBottleProfiles(
    InvalidBottleRecord invalidBottle,
  ) async {
    final decision =
        await showDialogDecision<DiscardInvalidBottleProfilesDecision>(
          context: context,
          dismissedDecision: const CancelledDiscardInvalidBottleProfiles(),
          builder: (context) => DiscardInvalidBottleProfilesConfirmationDialog(
            invalidBottle: invalidBottle,
          ),
        );

    switch (decision) {
      case ConfirmedDiscardInvalidBottleProfiles():
        await discardInvalidBottleProfiles(invalidBottle);
      case CancelledDiscardInvalidBottleProfiles():
        return;
    }
  }

  Future<void> discardInvalidBottleProfiles(
    InvalidBottleRecord invalidBottle,
  ) async {
    updateState(() {
      bottleMetadataRepairProgress = BlockingProgressState.indeterminate(
        KonyakLocalizations.of(context).repairingBottleMetadataEllipsis,
      );
    });

    late final BottleMetadataRepairLoadResult result;
    try {
      result = await widget.cliClient.discardInvalidBottleProfiles(
        invalidBottle.storageId,
      );
    } finally {
      if (mounted) {
        updateState(() {
          bottleMetadataRepairProgress = const BlockingProgressState.hidden();
        });
      }
    }

    if (!mounted) {
      return;
    }

    switch (result) {
      case RepairedBottleMetadata(:final repair):
        await loadBottles();
        if (mounted) {
          showSnackBar(
            KonyakLocalizations.of(
              context,
            ).repairedBottleMetadata(repair.backupPath),
          );
        }
      case BottleMetadataRepairLoadFailure(:final message):
        showWarningSnackBar(message);
    }
  }
}
