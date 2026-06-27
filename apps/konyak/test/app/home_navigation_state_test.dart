import 'package:flutter_test/flutter_test.dart';

import 'package:konyak/src/app/bottles/bottle_detail.dart';
import 'package:konyak/src/app/home/home_navigation_state.dart';
import 'package:konyak/src/bottles/bottle_summary.dart';

void main() {
  final steam = _bottle(
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
  final battle = _bottle(id: 'battle', name: 'Battle.net');

  test('selectBottle shows the overview and clears selected program', () {
    final state = const KonyakHomeNavigationState(
      selectedBottleId: 'steam',
      detailMode: BottleDetailMode.programConfiguration,
      selectedProgramPath: '/games/setup.exe',
    ).selectBottle(battle);

    expect(state.selectedBottleId, 'battle');
    expect(state.detailMode, BottleDetailMode.overview);
    expect(state.selectedProgramPath, isNull);
  });

  test('showBottleConfiguration keeps state when the bottle is locked', () {
    const current = KonyakHomeNavigationState(
      selectedBottleId: 'steam',
      detailMode: BottleDetailMode.overview,
    );

    final locked = current.showBottleConfiguration(
      steam,
      lockedBottleIds: const <String>['steam'],
    );
    final unlocked = current.showBottleConfiguration(
      battle,
      lockedBottleIds: const <String>['steam'],
    );

    expect(locked, same(current));
    expect(unlocked.selectedBottleId, 'battle');
    expect(unlocked.detailMode, BottleDetailMode.configuration);
    expect(unlocked.selectedProgramPath, isNull);
  });

  test(
    'showPinnedProgramConfiguration keeps state when the bottle is locked',
    () {
      final setup = steam.pinnedPrograms.first;
      const current = KonyakHomeNavigationState(
        selectedBottleId: 'battle',
        detailMode: BottleDetailMode.overview,
      );

      final locked = current.showPinnedProgramConfiguration(
        steam,
        setup,
        lockedBottleIds: const <String>['steam'],
      );
      final unlocked = current.showPinnedProgramConfiguration(
        steam,
        setup,
        lockedBottleIds: const <String>[],
      );

      expect(locked, same(current));
      expect(unlocked.selectedBottleId, 'steam');
      expect(unlocked.detailMode, BottleDetailMode.programConfiguration);
      expect(unlocked.selectedProgramPath, '/games/setup.exe');
    },
  );

  test('showBottleOverview keeps state while selected bottle is locked', () {
    const current = KonyakHomeNavigationState(
      selectedBottleId: 'steam',
      detailMode: BottleDetailMode.configuration,
    );

    final locked = current.showBottleOverview(
      bottles: <BottleSummary>[steam, battle],
      lockedBottleIds: const <String>['steam'],
    );
    final unlocked = current.showBottleOverview(
      bottles: <BottleSummary>[steam, battle],
      lockedBottleIds: const <String>[],
    );

    expect(locked, same(current));
    expect(unlocked.selectedBottleId, 'steam');
    expect(unlocked.detailMode, BottleDetailMode.overview);
    expect(unlocked.selectedProgramPath, isNull);
  });

  test(
    'reconcile selects the first available bottle when selection disappears',
    () {
      final state = const KonyakHomeNavigationState(
        selectedBottleId: 'missing',
        detailMode: BottleDetailMode.configuration,
      ).reconcile(<BottleSummary>[steam, battle]);

      expect(state.selectedBottleId, 'steam');
      expect(state.detailMode, BottleDetailMode.configuration);
      expect(state.selectedProgramPath, isNull);
    },
  );

  test(
    'reconcile clears program configuration when the program disappears',
    () {
      final state = const KonyakHomeNavigationState(
        selectedBottleId: 'steam',
        detailMode: BottleDetailMode.programConfiguration,
        selectedProgramPath: '/games/missing.exe',
      ).reconcile(<BottleSummary>[steam, battle]);

      expect(state.selectedBottleId, 'steam');
      expect(state.detailMode, BottleDetailMode.overview);
      expect(state.selectedProgramPath, isNull);
    },
  );
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
