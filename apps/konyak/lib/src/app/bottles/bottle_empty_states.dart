import 'package:flutter/material.dart';

class BottleLoadFailureState extends StatelessWidget {
  const BottleLoadFailureState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 40),
          const SizedBox(height: 12),
          const Text('Could not load bottles', style: TextStyle(fontSize: 18)),
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
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 40),
          SizedBox(height: 12),
          Text('No bottles yet', style: TextStyle(fontSize: 18)),
          SizedBox(height: 6),
          Text('Create a bottle to start managing Windows programs.'),
        ],
      ),
    );
  }
}
