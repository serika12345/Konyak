import 'package:flutter_test/flutter_test.dart';

import 'package:konyak/src/app/home/home_contracts.dart';
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
      selectedBottle: SelectedHomeNavigationBottle('steam'),
      detailMode: BottleDetailMode.programConfiguration,
      selectedProgram: SelectedHomeNavigationProgram('/games/setup.exe'),
    ).selectBottle(battle);

    expect(state.selectedBottle, const SelectedHomeNavigationBottle('battle'));
    expect(state.detailMode, BottleDetailMode.overview);
    expect(state.selectedProgram, const NoHomeNavigationProgram());
  });

  test('showBottleConfiguration keeps state when the bottle is locked', () {
    const current = KonyakHomeNavigationState(
      selectedBottle: SelectedHomeNavigationBottle('steam'),
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
    expect(
      unlocked.selectedBottle,
      const SelectedHomeNavigationBottle('battle'),
    );
    expect(unlocked.detailMode, BottleDetailMode.configuration);
    expect(unlocked.selectedProgram, const NoHomeNavigationProgram());
  });

  test(
    'showPinnedProgramConfiguration keeps state when the bottle is locked',
    () {
      final setup = steam.pinnedPrograms.first;
      const current = KonyakHomeNavigationState(
        selectedBottle: SelectedHomeNavigationBottle('battle'),
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
      expect(
        unlocked.selectedBottle,
        const SelectedHomeNavigationBottle('steam'),
      );
      expect(unlocked.detailMode, BottleDetailMode.programConfiguration);
      expect(
        unlocked.selectedProgram,
        const SelectedHomeNavigationProgram('/games/setup.exe'),
      );
    },
  );

  test('showBottleOverview keeps state while selected bottle is locked', () {
    const current = KonyakHomeNavigationState(
      selectedBottle: SelectedHomeNavigationBottle('steam'),
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
    expect(
      unlocked.selectedBottle,
      const SelectedHomeNavigationBottle('steam'),
    );
    expect(unlocked.detailMode, BottleDetailMode.overview);
    expect(unlocked.selectedProgram, const NoHomeNavigationProgram());
  });

  test(
    'reconcile selects the first available bottle when selection disappears',
    () {
      final state = const KonyakHomeNavigationState(
        selectedBottle: SelectedHomeNavigationBottle('missing'),
        detailMode: BottleDetailMode.configuration,
      ).reconcile(<BottleSummary>[steam, battle]);

      expect(state.selectedBottle, const SelectedHomeNavigationBottle('steam'));
      expect(state.detailMode, BottleDetailMode.configuration);
      expect(state.selectedProgram, const NoHomeNavigationProgram());
    },
  );

  test(
    'reconcile clears program configuration when the program disappears',
    () {
      final state = const KonyakHomeNavigationState(
        selectedBottle: SelectedHomeNavigationBottle('steam'),
        detailMode: BottleDetailMode.programConfiguration,
        selectedProgram: SelectedHomeNavigationProgram('/games/missing.exe'),
      ).reconcile(<BottleSummary>[steam, battle]);

      expect(state.selectedBottle, const SelectedHomeNavigationBottle('steam'));
      expect(state.detailMode, BottleDetailMode.overview);
      expect(state.selectedProgram, const NoHomeNavigationProgram());
    },
  );

  test('resolves selected bottle and program with explicit variants', () {
    const state = KonyakHomeNavigationState(
      selectedBottle: SelectedHomeNavigationBottle('steam'),
      detailMode: BottleDetailMode.programConfiguration,
      selectedProgram: SelectedHomeNavigationProgram('/games/setup.exe'),
    );

    final bottleResolution = state.selectedBottleIn(<BottleSummary>[
      steam,
      battle,
    ]);
    final programResolution = state.selectedProgramIn(steam);

    expect(switch (bottleResolution) {
      ResolvedHomeNavigationBottle(:final bottle) => bottle.id,
      MissingHomeNavigationBottle() || UnselectedHomeNavigationBottle() => '',
    }, 'steam');
    expect(switch (programResolution) {
      ResolvedHomeNavigationProgram(:final program) => program.path,
      MissingHomeNavigationProgram() || UnselectedHomeNavigationProgram() => '',
    }, '/games/setup.exe');
  });

  test('resolves detail selection with visible bottle fallback', () {
    const state = KonyakHomeNavigationState(
      selectedBottle: SelectedHomeNavigationBottle('missing'),
      detailMode: BottleDetailMode.programConfiguration,
      selectedProgram: SelectedHomeNavigationProgram('/games/setup.exe'),
    );

    expect(
      switch (state.detailSelectionIn(<BottleSummary>[steam, battle])) {
        SelectedKonyakHomeDetailProgram(:final bottle, :final program) => (
          bottle.id,
          program.path,
        ),
        SelectedKonyakHomeDetailBottle(:final bottle) => (bottle.id, ''),
        NoKonyakHomeDetailSelection() => ('', ''),
      },
      ('steam', '/games/setup.exe'),
    );
  });

  test('resolves missing selected programs as bottle detail selection', () {
    const state = KonyakHomeNavigationState(
      selectedBottle: SelectedHomeNavigationBottle('steam'),
      detailMode: BottleDetailMode.programConfiguration,
      selectedProgram: SelectedHomeNavigationProgram('/games/missing.exe'),
    );

    expect(switch (state.detailSelectionIn(<BottleSummary>[steam, battle])) {
      SelectedKonyakHomeDetailBottle(:final bottle) => bottle.id,
      SelectedKonyakHomeDetailProgram() || NoKonyakHomeDetailSelection() => '',
    }, 'steam');
  });

  test('resolves empty detail and sidebar selections explicitly', () {
    const state = KonyakHomeNavigationState();

    expect(
      state.detailSelectionIn(const <BottleSummary>[]),
      const KonyakHomeDetailSelection.none(),
    );
    expect(
      state.sidebarBottleSelectionIn(const <BottleSummary>[]),
      const NoHomeNavigationBottle(),
    );
  });

  test('resolves sidebar selection with visible bottle fallback', () {
    const state = KonyakHomeNavigationState(
      selectedBottle: SelectedHomeNavigationBottle('missing'),
    );

    expect(
      state.sidebarBottleSelectionIn(<BottleSummary>[steam, battle]),
      const SelectedHomeNavigationBottle('steam'),
    );
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
