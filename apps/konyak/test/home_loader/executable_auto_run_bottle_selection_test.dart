import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/bottles/bottle_summary.dart';
import 'package:konyak/src/home_loader/executable_auto_run_bottle_selection.dart';

void main() {
  test('selects an executable auto-run bottle without a nullable result', () {
    final bottle = _bottle(id: 'steam');

    final selected = selectExecutableAutoRunBottle(
      bottles: [bottle],
      bottleId: ' steam ',
    );
    final missing = selectExecutableAutoRunBottle(
      bottles: <BottleSummary>[],
      bottleId: 'steam',
    );
    final disabled = selectExecutableAutoRunBottle(
      bottles: <BottleSummary>[],
      bottleId: '  ',
    );

    switch (selected) {
      case FoundExecutableAutoRunBottle(:final bottle):
        expect(bottle.id, 'steam');
      case MissingExecutableAutoRunBottle():
      case DisabledExecutableAutoRunBottle():
        fail('Expected the configured bottle to be selected.');
    }
    expect(missing, const ExecutableAutoRunBottleSelection.missing('steam'));
    expect(disabled, const ExecutableAutoRunBottleSelection.disabled());
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
