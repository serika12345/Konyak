import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/app/dialogs/confirmation_decision.dart';
import 'package:konyak/src/app/dialogs/dialog_decision.dart';

void main() {
  testWidgets(
    'returns an explicit dismissed decision when a dialog is closed',
    (tester) async {
      final decisions = <ConfirmationDecision>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  decisions.add(
                    await showDialogDecision<ConfirmationDecision>(
                      context: context,
                      dismissedDecision: const ConfirmationDecision.cancelled(),
                      builder: (context) {
                        return const AlertDialog(
                          content: Text('Decision dialog'),
                        );
                      },
                    ),
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.text('Decision dialog'))).pop();
      await tester.pumpAndSettle();

      expect(decisions, const [ConfirmationDecision.cancelled()]);
    },
  );

  testWidgets('returns the selected explicit dialog decision', (tester) async {
    final decisions = <ConfirmationDecision>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                decisions.add(
                  await showDialogDecision<ConfirmationDecision>(
                    context: context,
                    dismissedDecision: const ConfirmationDecision.cancelled(),
                    builder: (context) {
                      return AlertDialog(
                        content: TextButton(
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).pop(const ConfirmationDecision.confirmed());
                          },
                          child: const Text('Confirm'),
                        ),
                      );
                    },
                  ),
                );
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(decisions, const [ConfirmationDecision.confirmed()]);
  });
}
