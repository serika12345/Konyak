import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/app/dialogs/confirmation_decision.dart';

void main() {
  test('models dismissed confirmation dialogs explicitly', () {
    const confirmed = ConfirmationDecision.confirmed();

    expect(
      confirmationDecisionFromNullable(null),
      const ConfirmationDecision.cancelled(),
    );
    expect(confirmationDecisionFromNullable(confirmed), confirmed);
  });
}
