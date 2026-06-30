import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/app/utils/bottle_lists.dart';
import 'package:konyak/src/bottles/bottle_summary.dart';

void main() {
  test('selects a bottle by id without returning a nullable sentinel', () {
    final bottle = _bottle(id: 'steam', name: 'Steam');
    final selection = findBottleById([bottle], 'steam');

    expect(switch (selection) {
      BottleSelectionFound(:final bottle) => bottle.id,
      BottleSelectionMissing() => '',
    }, 'steam');
  });

  test('models a missing bottle selection explicitly', () {
    final selection = findBottleById(const <BottleSummary>[], 'missing');

    expect(switch (selection) {
      BottleSelectionFound() => '',
      BottleSelectionMissing(:final bottleId) => bottleId,
    }, 'missing');
  });

  test(
    'selects a pinned program path without returning a nullable sentinel',
    () {
      final bottle = _bottle(
        id: 'steam',
        name: 'Steam',
        pinnedPrograms: const <PinnedProgramSummary>[
          PinnedProgramSummary(
            name: 'Setup',
            path: '/games/setup.exe',
            removable: true,
          ),
        ],
      );
      final selection = findPinnedProgramByPath(bottle, '/games/setup.exe');

      expect(switch (selection) {
        PinnedProgramSelectionFound(:final program) => program.path,
        PinnedProgramSelectionMissing() => '',
      }, '/games/setup.exe');
    },
  );

  test('models a missing pinned program selection explicitly', () {
    final bottle = _bottle(id: 'steam', name: 'Steam');
    final selection = findPinnedProgramByPath(bottle, '/games/missing.exe');

    expect(switch (selection) {
      PinnedProgramSelectionFound() => '',
      PinnedProgramSelectionMissing(:final programPath) => programPath,
    }, '/games/missing.exe');
  });
}

BottleSummary _bottle({
  required String id,
  required String name,
  Iterable<PinnedProgramSummary> pinnedPrograms =
      const <PinnedProgramSummary>[],
}) {
  return BottleSummary(
    id: id,
    name: name,
    path: '/bottles/$id',
    windowsVersion: 'win10',
    pinnedPrograms: pinnedPrograms,
  );
}
