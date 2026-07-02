import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../bottles/bottle_summary.dart';
import '../../l10n/konyak_localizations.dart';
import '../utils/bottle_lists.dart';

part 'open_executable_dialog.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class OpenExecutableDecision with _$OpenExecutableDecision {
  const factory OpenExecutableDecision.runInBottle(BottleSummary bottle) =
      RunExecutableInBottle;

  const factory OpenExecutableDecision.createBottle() =
      CreateBottleForExecutable;

  const factory OpenExecutableDecision.cancelled() =
      CancelledOpenExecutableDialog;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class OpenExecutableBottleChoice with _$OpenExecutableBottleChoice {
  const factory OpenExecutableBottleChoice.chosen(BottleSummary bottle) =
      ChosenOpenExecutableBottle;

  const factory OpenExecutableBottleChoice.unavailable() =
      UnavailableOpenExecutableBottleChoice;
}

OpenExecutableBottleChoice initialOpenExecutableBottleChoice(
  List<BottleSummary> bottles,
) {
  return switch (bottles) {
    [final bottle, ...] => OpenExecutableBottleChoice.chosen(bottle),
    _ => const OpenExecutableBottleChoice.unavailable(),
  };
}

OpenExecutableBottleChoice openExecutableBottleChoiceById({
  required List<BottleSummary> bottles,
  required String bottleId,
}) {
  return switch (findBottleById(bottles, bottleId)) {
    BottleSelectionFound(:final bottle) => OpenExecutableBottleChoice.chosen(
      bottle,
    ),
    BottleSelectionMissing() => const OpenExecutableBottleChoice.unavailable(),
  };
}

OpenExecutableBottleChoice reconcileOpenExecutableBottleChoice({
  required OpenExecutableBottleChoice choice,
  required List<BottleSummary> bottles,
}) {
  return switch (choice) {
    ChosenOpenExecutableBottle(:final bottle) =>
      switch (openExecutableBottleChoiceById(
        bottles: bottles,
        bottleId: bottle.id,
      )) {
        final ChosenOpenExecutableBottle updatedChoice => updatedChoice,
        UnavailableOpenExecutableBottleChoice() =>
          initialOpenExecutableBottleChoice(bottles),
      },
    UnavailableOpenExecutableBottleChoice() =>
      initialOpenExecutableBottleChoice(bottles),
  };
}

class OpenExecutableDialog extends StatefulWidget {
  const OpenExecutableDialog({
    super.key,
    required this.programPath,
    required this.bottles,
  });

  final String programPath;
  final List<BottleSummary> bottles;

  @override
  State<OpenExecutableDialog> createState() => _OpenExecutableDialogState();
}

class _OpenExecutableDialogState extends State<OpenExecutableDialog> {
  late OpenExecutableBottleChoice _bottleChoice;

  @override
  void initState() {
    super.initState();
    _bottleChoice = initialOpenExecutableBottleChoice(widget.bottles);
  }

  @override
  void didUpdateWidget(covariant OpenExecutableDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    _bottleChoice = reconcileOpenExecutableBottleChoice(
      choice: _bottleChoice,
      bottles: widget.bottles,
    );
  }

  void _run() {
    switch (_bottleChoice) {
      case ChosenOpenExecutableBottle(:final bottle):
        Navigator.of(context).pop(RunExecutableInBottle(bottle));
      case UnavailableOpenExecutableBottleChoice():
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final canRun = switch (_bottleChoice) {
      ChosenOpenExecutableBottle() => true,
      UnavailableOpenExecutableBottleChoice() => false,
    };
    final selectedBottleId = switch (_bottleChoice) {
      ChosenOpenExecutableBottle(:final bottle) => bottle.id,
      UnavailableOpenExecutableBottleChoice() => null,
    };
    final localizations = KonyakLocalizations.of(context);

    return AlertDialog(
      title: Text(localizations.openExecutable),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SelectableText(widget.programPath),
            const SizedBox(height: 16),
            if (widget.bottles.isEmpty)
              Text(localizations.emptyExecutableBottleMessage)
            else
              DropdownButtonFormField<String>(
                initialValue: selectedBottleId,
                decoration: InputDecoration(labelText: localizations.bottle),
                items: [
                  for (final bottle in widget.bottles)
                    DropdownMenuItem<String>(
                      value: bottle.id,
                      child: Text(bottle.name),
                    ),
                ],
                onChanged: (value) {
                  setState(() {
                    _bottleChoice = switch (value) {
                      final String bottleId => openExecutableBottleChoiceById(
                        bottles: widget.bottles,
                        bottleId: bottleId,
                      ),
                      _ => const OpenExecutableBottleChoice.unavailable(),
                    };
                  });
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(const OpenExecutableDecision.cancelled());
          },
          child: Text(localizations.cancel),
        ),
        TextButton.icon(
          onPressed: () {
            Navigator.of(context).pop(const CreateBottleForExecutable());
          },
          icon: const Icon(Icons.add),
          label: Text(localizations.createBottle),
        ),
        FilledButton.icon(
          onPressed: canRun ? _run : null,
          icon: const Icon(Icons.play_arrow),
          label: Text(localizations.run),
        ),
      ],
    );
  }
}
