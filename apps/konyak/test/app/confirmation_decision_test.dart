import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/app/dialogs/confirmation_decision.dart';

void main() {
  test('models confirmation dialog decisions explicitly', () {
    expect(
      const ConfirmationDecision.confirmed(),
      isA<ConfirmedDialogDecision>(),
    );
    expect(
      const ConfirmationDecision.cancelled(),
      isA<CancelledDialogDecision>(),
    );
  });
}
