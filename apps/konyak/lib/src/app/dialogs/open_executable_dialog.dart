import 'package:flutter/material.dart';

import '../../bottles/bottle_summary.dart';
import '../../l10n/konyak_localizations.dart';

sealed class OpenExecutableDecision {
  const OpenExecutableDecision();
}

final class RunExecutableInBottle extends OpenExecutableDecision {
  const RunExecutableInBottle(this.bottle);

  final BottleSummary bottle;
}

final class CreateBottleForExecutable extends OpenExecutableDecision {
  const CreateBottleForExecutable();
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
  String? _selectedBottleId;

  @override
  void initState() {
    super.initState();
    _selectedBottleId = widget.bottles.isEmpty ? null : widget.bottles.first.id;
  }

  @override
  void didUpdateWidget(covariant OpenExecutableDialog oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_selectedBottle == null) {
      _selectedBottleId = widget.bottles.isEmpty
          ? null
          : widget.bottles.first.id;
    }
  }

  BottleSummary? get _selectedBottle {
    for (final bottle in widget.bottles) {
      if (bottle.id == _selectedBottleId) {
        return bottle;
      }
    }

    return null;
  }

  void _run() {
    final bottle = _selectedBottle;
    if (bottle == null) {
      return;
    }

    Navigator.of(context).pop(RunExecutableInBottle(bottle));
  }

  @override
  Widget build(BuildContext context) {
    final selectedBottle = _selectedBottle;
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
                initialValue: _selectedBottleId,
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
                    _selectedBottleId = value;
                  });
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
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
          onPressed: selectedBottle == null ? null : _run,
          icon: const Icon(Icons.play_arrow),
          label: Text(localizations.run),
        ),
      ],
    );
  }
}
