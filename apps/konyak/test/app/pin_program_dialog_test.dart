import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/app/dialogs/pin_program_dialog.dart';

void main() {
  test('models dismissed pin program dialogs explicitly', () {
    const pinDecision = PinProgramDecision.pin(
      name: 'Setup',
      programPath: '/downloads/setup.exe',
    );

    expect(
      pinProgramDecisionFromNullable(null),
      const PinProgramDecision.cancelled(),
    );
    expect(pinProgramDecisionFromNullable(pinDecision), pinDecision);
  });
}
