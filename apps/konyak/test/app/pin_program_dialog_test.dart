import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/app/dialogs/pin_program_dialog.dart';

void main() {
  test('models pin program dialog decisions explicitly', () {
    const decision = PinProgramDecision.pin(
      name: 'Setup',
      programPath: '/downloads/setup.exe',
    );

    expect(decision, isA<PinProgramFromDialog>());
    expect(
      const PinProgramDecision.cancelled(),
      isA<CancelledPinProgramDialog>(),
    );
  });
}
