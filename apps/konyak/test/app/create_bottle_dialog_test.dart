import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/app/dialogs/create_bottle_dialog.dart';

void main() {
  test('models dismissed create bottle dialogs explicitly', () {
    const createDecision = CreateBottleDecision.create(
      name: 'Steam',
      windowsVersion: 'win10',
    );

    expect(
      createBottleDecisionFromNullable(null),
      const CreateBottleDecision.cancelled(),
    );
    expect(createBottleDecisionFromNullable(createDecision), createDecision);
  });
}
