import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/app/bottles/bottle_action_availability.dart';
import 'package:konyak/src/app/bottles/bottle_action_target.dart';
import 'package:konyak/src/app/bottles/bottle_overview_content.dart';
import 'package:konyak/src/app/bottles/bottle_tool_action.dart';
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

  test('models unavailable bottle summary actions explicitly', () {
    final action = bottleSummaryActionAvailabilityFromNullable(null);

    expect(action, isA<UnavailableBottleSummaryActionAvailability>());
  });

  test('resolves selected bottom-bar actions to an enabled callback', () {
    final bottle = _bottle(id: 'steam', name: 'Steam');
    final invokedBottleIds = <String>[];
    final action = resolveBottleTargetAction(
      target: BottleActionTarget.bottle(bottle),
      action: BottleSummaryActionAvailability.available(
        (bottle) => invokedBottleIds.add(bottle.id),
      ),
    );

    switch (action) {
      case EnabledBottleTargetActionAvailability(:final invoke):
        invoke();
      case DisabledBottleTargetActionAvailability():
        fail('Expected a selected bottle and available action to be enabled.');
    }

    expect(invokedBottleIds, <String>['steam']);
  });

  test('disables bottom-bar actions when no bottle is selected', () {
    final action = resolveBottleTargetAction(
      target: const BottleActionTarget.none(),
      action: BottleSummaryActionAvailability.available(
        (_) => fail('Unavailable target must not run the action.'),
      ),
    );

    expect(action, isA<DisabledBottleTargetActionAvailability>());
  });

  test('disables bottom-bar actions when the action is unavailable', () {
    final bottle = _bottle(id: 'steam', name: 'Steam');
    final action = resolveBottleTargetAction(
      target: BottleActionTarget.bottle(bottle),
      action: const BottleSummaryActionAvailability.unavailable(),
    );

    expect(action, isA<DisabledBottleTargetActionAvailability>());
  });

  test('resolves bottle summary actions without a nullable callback', () {
    final bottle = _bottle(id: 'steam', name: 'Steam');
    final invokedBottleIds = <String>[];
    final action = resolveBottleSummaryAction(
      bottle: bottle,
      action: BottleSummaryActionAvailability.available(
        (bottle) => invokedBottleIds.add(bottle.id),
      ),
    );

    switch (action) {
      case EnabledBottleTargetActionAvailability(:final invoke):
        invoke();
      case DisabledBottleTargetActionAvailability():
        fail('Expected bottle summary action to be enabled.');
    }

    expect(invokedBottleIds, <String>['steam']);
  });

  test('chooses the first available bottle summary action', () {
    final fallback = BottleSummaryActionAvailability.available((_) {});

    expect(
      firstAvailableBottleSummaryAction(
        preferred: const BottleSummaryActionAvailability.unavailable(),
        fallback: fallback,
      ),
      fallback,
    );

    final preferred = BottleSummaryActionAvailability.available((_) {});
    expect(
      firstAvailableBottleSummaryAction(
        preferred: preferred,
        fallback: fallback,
      ),
      preferred,
    );
  });

  test('models unavailable bottle tools actions explicitly', () {
    final actions = bottleToolsActionAvailabilityFromNullable(
      onRunCommand: null,
      onOpenLocation: null,
    );

    expect(actions, isA<UnavailableBottleToolsActionAvailability>());
    expect(availableBottleToolActionKinds(actions), isEmpty);
  });

  test('resolves selected bottle tools targets with available tool kinds', () {
    final bottle = _bottle(id: 'steam', name: 'Steam');
    final targetAction = resolveBottleToolsTargetAction(
      target: BottleActionTarget.bottle(bottle),
      actions: BottleToolsActionAvailability.command((_, _) {}),
    );

    switch (targetAction) {
      case EnabledBottleToolsTargetActionAvailability(
        :final bottle,
        :final actions,
      ):
        expect(bottle.id, 'steam');
        expect(availableBottleToolActionKinds(actions), [
          BottleToolActionKind.command,
        ]);
      case DisabledBottleToolsTargetActionAvailability():
        fail('Expected selected bottle tools to be enabled.');
    }
  });

  test('disables bottle tools targets without a selected bottle', () {
    final targetAction = resolveBottleToolsTargetAction(
      target: const BottleActionTarget.none(),
      actions: BottleToolsActionAvailability.command((_, _) {}),
    );

    expect(targetAction, isA<DisabledBottleToolsTargetActionAvailability>());
  });

  test('dispatches bottle tools actions explicitly by kind', () {
    final bottle = _bottle(id: 'steam', name: 'Steam');
    final commandIds = <String>[];
    final locationIds = <String>[];
    final actions = BottleToolsActionAvailability.commandAndLocation(
      onRunCommand: (_, command) => commandIds.add(command),
      onOpenLocation: (_, location) => locationIds.add(location),
    );

    final commandDispatch = resolveBottleToolActionDispatch(
      bottle: bottle,
      actions: actions,
      action: const BottleToolAction.command('cmd'),
    );
    final locationDispatch = resolveBottleToolActionDispatch(
      bottle: bottle,
      actions: actions,
      action: const BottleToolAction.location('c-drive'),
    );

    switch (commandDispatch) {
      case AvailableBottleToolActionDispatch(:final invoke):
        invoke();
      case UnavailableBottleToolActionDispatch():
        fail('Expected command tool dispatch to be available.');
    }
    switch (locationDispatch) {
      case AvailableBottleToolActionDispatch(:final invoke):
        invoke();
      case UnavailableBottleToolActionDispatch():
        fail('Expected location tool dispatch to be available.');
    }

    expect(commandIds, <String>['cmd']);
    expect(locationIds, <String>['c-drive']);
  });

  test(
    'builds bottle tools availability from explicit command and location actions',
    () {
      final actions = bottleToolsActionAvailabilityFromActions(
        commandAction: BottleCommandActionAvailability.available((_, _) {}),
        locationAction: BottleLocationActionAvailability.available((_, _) {}),
      );

      expect(actions, isA<CommandAndLocationBottleToolsActionAvailability>());
      expect(
        availableBottleToolActionKinds(actions),
        BottleToolActionKind.values,
      );
    },
  );

  test('resolves bottle location actions without nullable callbacks', () {
    final bottle = _bottle(id: 'steam', name: 'Steam');
    final openedLocations = <String>[];
    final dispatch = resolveBottleLocationAction(
      bottle: bottle,
      location: 'root',
      action: BottleLocationActionAvailability.available(
        (_, location) => openedLocations.add(location),
      ),
    );

    switch (dispatch) {
      case AvailableBottleLocationActionDispatch(:final invoke):
        invoke();
      case UnavailableBottleLocationActionDispatch():
        fail('Expected location dispatch to be available.');
    }

    expect(openedLocations, <String>['root']);
    expect(
      resolveBottleLocationAction(
        bottle: bottle,
        location: 'root',
        action: const BottleLocationActionAvailability.unavailable(),
      ),
      isA<UnavailableBottleLocationActionDispatch>(),
    );
  });

  test('rejects unavailable bottle tool kinds before dispatch', () {
    final bottle = _bottle(id: 'steam', name: 'Steam');
    final dispatch = resolveBottleToolActionDispatch(
      bottle: bottle,
      actions: BottleToolsActionAvailability.command((_, _) {
        fail('Unavailable location dispatch must not run command actions.');
      }),
      action: const BottleToolAction.location('c-drive'),
    );

    expect(dispatch, isA<UnavailableBottleToolActionDispatch>());
  });

  test('models unavailable pinned program actions explicitly', () {
    final action = pinnedProgramActionAvailabilityFromNullable(null);

    expect(action, isA<UnavailablePinnedProgramActionAvailability>());
  });

  test('resolves pinned program actions to an enabled callback', () {
    final bottle = _bottle(id: 'steam', name: 'Steam');
    final program = _program(name: 'Steam', path: 'C:/Steam/steam.exe');
    final invokedTargets = <(String, String)>[];
    final action = resolvePinnedProgramAction(
      bottle: bottle,
      program: program,
      action: PinnedProgramActionAvailability.available(
        (bottle, program) => invokedTargets.add((bottle.id, program.path)),
      ),
    );

    switch (action) {
      case EnabledBottleTargetActionAvailability(:final invoke):
        invoke();
      case DisabledBottleTargetActionAvailability():
        fail('Expected pinned program action to be enabled.');
    }

    expect(invokedTargets, <(String, String)>[('steam', 'C:/Steam/steam.exe')]);
  });

  test('disables unavailable pinned program actions', () {
    final bottle = _bottle(id: 'steam', name: 'Steam');
    final program = _program(name: 'Steam', path: 'C:/Steam/steam.exe');
    final action = resolvePinnedProgramAction(
      bottle: bottle,
      program: program,
      action: const PinnedProgramActionAvailability.unavailable(),
    );

    expect(action, isA<DisabledBottleTargetActionAvailability>());
  });

  test('models unavailable program path actions explicitly', () {
    final action = programPathActionAvailabilityFromNullable(null);

    expect(action, isA<UnavailableProgramPathActionAvailability>());
  });

  test('resolves program path actions to an enabled callback', () {
    final bottle = _bottle(id: 'steam', name: 'Steam');
    final program = _program(name: 'Steam', path: 'C:/Steam/steam.exe');
    final invokedTargets = <(String, String)>[];
    final action = resolveProgramPathAction(
      bottle: bottle,
      program: program,
      action: ProgramPathActionAvailability.available(
        (bottle, programPath) => invokedTargets.add((bottle.id, programPath)),
      ),
    );

    switch (action) {
      case EnabledBottleTargetActionAvailability(:final invoke):
        invoke();
      case DisabledBottleTargetActionAvailability():
        fail('Expected program path action to be enabled.');
    }

    expect(invokedTargets, <(String, String)>[('steam', 'C:/Steam/steam.exe')]);
  });

  test('disables unavailable program path actions', () {
    final bottle = _bottle(id: 'steam', name: 'Steam');
    final program = _program(name: 'Steam', path: 'C:/Steam/steam.exe');
    final action = resolveProgramPathAction(
      bottle: bottle,
      program: program,
      action: const ProgramPathActionAvailability.unavailable(),
    );

    expect(action, isA<DisabledBottleTargetActionAvailability>());
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

PinnedProgramSummary _program({required String name, required String path}) {
  return PinnedProgramSummary(name: name, path: path, removable: true);
}
