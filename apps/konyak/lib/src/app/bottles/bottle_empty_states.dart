import 'package:flutter/material.dart';

import '../../l10n/konyak_localizations.dart';

class BottleLoadFailureState extends StatelessWidget {
  const BottleLoadFailureState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final localizations = KonyakLocalizations.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 40),
          const SizedBox(height: 12),
          Text(
            localizations.text('Could not load bottles'),
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(message),
        ],
      ),
    );
  }
}

class EmptyBottleState extends StatelessWidget {
  const EmptyBottleState({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = KonyakLocalizations.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 40),
          const SizedBox(height: 12),
          Text(
            localizations.text('No bottles yet'),
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            localizations.text(
              'Create a bottle to start managing Windows programs.',
            ),
          ),
        ],
      ),
    );
  }
}
