import 'package:flutter/material.dart';

import '../../bottles/invalid_bottle_record.dart';
import '../../l10n/konyak_localizations.dart';

sealed class InvalidBottleRecoveryDecision {
  const InvalidBottleRecoveryDecision();
}

final class DiscardInvalidBottleProfiles extends InvalidBottleRecoveryDecision {
  const DiscardInvalidBottleProfiles();
}

final class CancelledInvalidBottleRecovery
    extends InvalidBottleRecoveryDecision {
  const CancelledInvalidBottleRecovery();
}

sealed class DiscardInvalidBottleProfilesDecision {
  const DiscardInvalidBottleProfilesDecision();
}

final class ConfirmedDiscardInvalidBottleProfiles
    extends DiscardInvalidBottleProfilesDecision {
  const ConfirmedDiscardInvalidBottleProfiles();
}

final class CancelledDiscardInvalidBottleProfiles
    extends DiscardInvalidBottleProfilesDecision {
  const CancelledDiscardInvalidBottleProfiles();
}

class InvalidBottleRecoveryDialog extends StatelessWidget {
  const InvalidBottleRecoveryDialog({super.key, required this.invalidBottle});

  final InvalidBottleRecord invalidBottle;

  @override
  Widget build(BuildContext context) {
    final localizations = KonyakLocalizations.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_outlined,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 10),
          Text(localizations.bottleNeedsRepair),
        ],
      ),
      content: SizedBox(
        width: 560,
        child: SelectionArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RecoveryField(
                label: localizations.storageIdentifier,
                value: invalidBottle.storageId,
              ),
              const SizedBox(height: 14),
              _RecoveryField(
                label: localizations.bottlePath,
                value: invalidBottle.path,
              ),
              const SizedBox(height: 14),
              Text(invalidBottle.message),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(const CancelledInvalidBottleRecovery());
          },
          child: Text(localizations.close),
        ),
        if (invalidBottle.canDiscardInvalidProfiles)
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop(const DiscardInvalidBottleProfiles());
            },
            icon: const Icon(Icons.restore_from_trash_outlined),
            label: Text(
              localizations.discardIncompatibleProfileSettingsEllipsis,
            ),
          ),
      ],
    );
  }
}

class DiscardInvalidBottleProfilesConfirmationDialog extends StatelessWidget {
  const DiscardInvalidBottleProfilesConfirmationDialog({
    super.key,
    required this.invalidBottle,
  });

  final InvalidBottleRecord invalidBottle;

  @override
  Widget build(BuildContext context) {
    final localizations = KonyakLocalizations.of(context);

    return AlertDialog(
      title: Text(localizations.discardIncompatibleProfileSettingsTitle),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(localizations.discardIncompatibleProfileSettingsMessage),
            const SizedBox(height: 16),
            _RecoveryField(
              label: localizations.storageIdentifier,
              value: invalidBottle.storageId,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(
              context,
            ).pop(const CancelledDiscardInvalidBottleProfiles());
          },
          child: Text(localizations.cancel),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(
              context,
            ).pop(const ConfirmedDiscardInvalidBottleProfiles());
          },
          icon: const Icon(Icons.delete_outline),
          label: Text(localizations.discardProfileSettings),
        ),
      ],
    );
  }
}

class _RecoveryField extends StatelessWidget {
  const _RecoveryField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.labelMedium),
        const SizedBox(height: 3),
        Text(value),
      ],
    );
  }
}
