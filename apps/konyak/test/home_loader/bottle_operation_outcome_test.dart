import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/bottles/bottle_summary.dart';
import 'package:konyak/src/home_loader/bottle_operation_outcome.dart';

void main() {
  test('models completed bottle operations without a nullable result', () {
    final bottle = _bottle(id: 'created-bottle');
    final outcome = BottleOperationOutcome.completed(bottle);

    switch (outcome) {
      case CompletedBottleOperation(:final bottle):
        expect(bottle.id, 'created-bottle');
      case CancelledBottleOperation():
      case FailedBottleOperation():
      case UnmountedBottleOperation():
        fail('Expected a completed bottle operation.');
    }
  });
}

BottleSummary _bottle({required String id}) {
  return BottleSummary(
    id: id,
    name: id,
    path: '/bottles/$id',
    windowsVersion: 'win11',
    pinnedPrograms: const <PinnedProgramSummary>[],
    runtimeSettings: const BottleRuntimeSettingsSummary(),
  );
}
