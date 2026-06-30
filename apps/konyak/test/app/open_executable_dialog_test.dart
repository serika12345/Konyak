import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/app/dialogs/open_executable_dialog.dart';
import 'package:konyak/src/bottles/bottle_summary.dart';

void main() {
  test('models dismissed open executable dialogs explicitly', () {
    const createDecision = OpenExecutableDecision.createBottle();

    expect(
      openExecutableDecisionFromNullable(null),
      const OpenExecutableDecision.cancelled(),
    );
    expect(openExecutableDecisionFromNullable(createDecision), createDecision);
  });

  test('models unavailable bottle choices explicitly', () {
    final selection = initialOpenExecutableBottleChoice(
      const <BottleSummary>[],
    );

    expect(switch (selection) {
      ChosenOpenExecutableBottle() => '',
      UnavailableOpenExecutableBottleChoice() => 'unavailable',
    }, 'unavailable');
  });

  test('selects the first available bottle explicitly', () {
    final bottle = BottleSummary(
      id: 'steam',
      name: 'Steam',
      path: '/bottles/steam',
      windowsVersion: 'win10',
    );
    final selection = initialOpenExecutableBottleChoice([bottle]);

    expect(switch (selection) {
      ChosenOpenExecutableBottle(:final bottle) => bottle.id,
      UnavailableOpenExecutableBottleChoice() => '',
    }, 'steam');
  });
}
