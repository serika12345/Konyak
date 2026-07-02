import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/app/dialogs/create_bottle_dialog.dart';

void main() {
  test('models create bottle dialog decisions explicitly', () {
    const decision = CreateBottleDecision.create(
      name: 'Steam',
      windowsVersion: 'win10',
    );

    expect(decision, isA<CreateBottleFromDialog>());
    expect(
      const CreateBottleDecision.cancelled(),
      isA<CancelledCreateBottleDialog>(),
    );
  });
}
