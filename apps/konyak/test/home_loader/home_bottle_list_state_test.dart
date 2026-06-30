import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/app/home/bottle_list_load_state.dart';
import 'package:konyak/src/bottles/bottle_summary.dart';
import 'package:konyak/src/home_loader/home_bottle_list_state.dart';

void main() {
  test('models an initial loading bottle list explicitly', () {
    final state = HomeBottleListState.loading();

    expect(homeBottleListBottles(state), isEmpty);
    expect(homeBottleListLoadState(state), const BottleListLoadState.loading());
  });

  test('snapshots loaded bottles immutably', () {
    final sourceBottles = <BottleSummary>[_bottle(id: 'steam', name: 'Steam')];
    final state = HomeBottleListState.loaded(sourceBottles);

    sourceBottles.clear();

    expect(_bottleIds(state), ['steam']);
    expect(homeBottleListBottles(state).clear, throwsUnsupportedError);
    expect(homeBottleListLoadState(state), const BottleListLoadState.loaded());
  });

  test('preserves bottles while loading and after load failure', () {
    final loaded = HomeBottleListState.loaded([
      _bottle(id: 'steam', name: 'Steam'),
    ]);

    final loading = startLoadingHomeBottleList(loaded);

    expect(_bottleIds(loading), ['steam']);
    expect(
      homeBottleListLoadState(loading),
      const BottleListLoadState.loading(),
    );

    final failed = failHomeBottleListLoad(
      state: loading,
      message: 'list-bottles failed',
    );

    expect(_bottleIds(failed), ['steam']);
    expect(
      homeBottleListLoadState(failed),
      const BottleListLoadState.failed('list-bottles failed'),
    );
  });

  test('stores, replaces, and removes bottles through immutable updates', () {
    final steam = _bottle(id: 'steam', name: 'Steam');
    final battleNet = _bottle(id: 'battle-net', name: 'Battle.net');
    final heroic = _bottle(id: 'heroic', name: 'Heroic');
    final loaded = HomeBottleListState.loaded([steam]);

    final stored = storeHomeBottle(state: loaded, bottle: battleNet);

    expect(_bottleIds(stored), ['battle-net', 'steam']);

    final replaced = storeHomeBottle(
      state: stored,
      oldBottleId: 'battle-net',
      bottle: heroic,
    );

    expect(_bottleIds(replaced), ['heroic', 'steam']);

    final removed = removeHomeBottle(state: replaced, bottleId: 'steam');

    expect(_bottleIds(removed), ['heroic']);
    expect(
      homeBottleListLoadState(removed),
      const BottleListLoadState.loaded(),
    );
    switch (removed) {
      case LoadedHomeBottleListState():
        break;
      case LoadingHomeBottleListState() || FailedHomeBottleListState():
        fail('stored bottle updates must leave the list loaded');
    }
  });
}

List<String> _bottleIds(HomeBottleListState state) {
  return homeBottleListBottles(state).map((bottle) => bottle.id).toList();
}

BottleSummary _bottle({required String id, required String name}) {
  return BottleSummary(
    id: id,
    name: name,
    path: '/bottles/$id',
    windowsVersion: 'win10',
  );
}
