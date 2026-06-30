import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/app/bottles/bottle_action_target.dart';
import 'package:konyak/src/app/bottles/bottle_overview_content.dart';
import 'package:konyak/src/app/home/bottle_list_load_state.dart';
import 'package:konyak/src/bottles/bottle_summary.dart';

void main() {
  test('models overview empty content without a nullable bottle sentinel', () {
    const content = BottleOverviewContent.empty(
      BottleListLoadState.failed('list-bottles failed'),
    );

    expect(switch (content) {
      EmptyBottleOverviewContent(:final loadState) => loadState,
      SelectedBottleOverviewContent() => const BottleListLoadState.loaded(),
    }, const BottleListLoadState.failed('list-bottles failed'));
  });

  test(
    'models selected overview content without a nullable bottle sentinel',
    () {
      final bottle = _bottle(id: 'steam', name: 'Steam');

      expect(switch (BottleOverviewContent.bottle(bottle)) {
        SelectedBottleOverviewContent(:final bottle) => bottle.id,
        EmptyBottleOverviewContent() => '',
      }, 'steam');
    },
  );

  test('models absent bottom-bar targets explicitly', () {
    expect(const BottleActionTarget.none(), isA<NoBottleActionTarget>());
  });

  test('models selected bottom-bar targets explicitly', () {
    final bottle = _bottle(id: 'steam', name: 'Steam');

    expect(switch (BottleActionTarget.bottle(bottle)) {
      SelectedBottleActionTarget(:final bottle) => bottle.id,
      NoBottleActionTarget() => '',
    }, 'steam');
  });
}

BottleSummary _bottle({required String id, required String name}) {
  return BottleSummary(
    id: id,
    name: name,
    path: '/bottles/$id',
    windowsVersion: 'win10',
  );
}
