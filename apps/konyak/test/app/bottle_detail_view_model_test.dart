import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/app/app_platform.dart';
import 'package:konyak/src/app/bottles/bottle_action_target.dart';
import 'package:konyak/src/app/bottles/bottle_detail_view_model.dart';
import 'package:konyak/src/app/bottles/bottle_overview_content.dart';
import 'package:konyak/src/app/bottles/bottle_tool_action.dart';
import 'package:konyak/src/app/home/home_contracts.dart';
import 'package:konyak/src/bottles/bottle_summary.dart';

void main() {
  test('builds program configuration detail models outside the widget', () {
    final bottle = _bottle(id: 'steam', name: 'Steam');
    final program = _program(name: 'Game', path: '/games/game.exe');
    var backInvoked = false;
    final settingsChangeAction = ProgramSettingsChangeAvailability.available(
      (_, _, _) {},
    );
    final runProgramPathAction = ProgramPathActionAvailability.available(
      (_, _) {},
    );
    final openProgramLocationAction = PinnedProgramActionAvailability.available(
      (_, _) {},
    );
    final viewModel = bottleDetailViewModel(
      state: _detailState(
        content: KonyakHomeDetailContent.program(
          bottle: bottle,
          program: program,
        ),
        programConfigurationSettingsState:
            const ProgramConfigurationSettingsState.loading(),
      ),
      bottleActions: const KonyakBottleActions(),
      programActions: KonyakProgramActions(
        programSettingsChangeAction: settingsChangeAction,
        runProgramPathAction: runProgramPathAction,
        openPinnedProgramLocationAction: openProgramLocationAction,
      ),
      winetricksActions: const KonyakWinetricksActions(),
      navigationActions: KonyakHomeNavigationActions(
        onBackToBottle: () => backInvoked = true,
        onShowBottleConfiguration: (_) {},
        onConfigurePinnedProgram: (_, _) {},
      ),
    );

    expect(switch (viewModel.topBar.title) {
      ProgramConfigurationBottleDetailTitle(:final programName) => programName,
      _ => '',
    }, 'Game');
    switch (viewModel.topBar.backAction) {
      case AvailableKonyakHomeActionAvailability(:final invoke):
        invoke();
      case UnavailableKonyakHomeActionAvailability():
        fail('Program configuration must expose back navigation.');
    }
    expect(backInvoked, isTrue);

    switch (viewModel.body) {
      case ProgramConfigurationBottleDetailBody(
        :final bottle,
        :final program,
        :final settingsState,
        :final programSettingsChangeAction,
      ):
        expect(bottle.id, 'steam');
        expect(program.path, '/games/game.exe');
        expect(settingsState, isA<LoadingProgramConfigurationSettings>());
        expect(programSettingsChangeAction, settingsChangeAction);
      case _:
        fail('Expected program configuration body model.');
    }
    switch (viewModel.bottomBar) {
      case ProgramConfigurationBottleDetailBottomBar(
        :final bottle,
        :final program,
        runProgramPathAction: final resolvedRunProgramPathAction,
        openPinnedProgramLocationAction: final resolvedOpenProgramLocationAction,
      ):
        expect(bottle.id, 'steam');
        expect(program.path, '/games/game.exe');
        expect(resolvedRunProgramPathAction, runProgramPathAction);
        expect(resolvedOpenProgramLocationAction, openProgramLocationAction);
      case _:
        fail('Expected program configuration bottom bar model.');
    }
  });

  test('builds locked bottle configuration models with tools availability', () {
    final bottle = _bottle(id: 'steam', name: 'Steam');
    final runtimeSettingsChangeAction =
        RuntimeSettingsChangeAvailability.available((_, _, _) {});
    final commandAction = BottleCommandActionAvailability.available((_, _) {});
    final locationAction = BottleLocationActionAvailability.available(
      (_, _) {},
    );
    final viewModel = bottleDetailViewModel(
      state: _detailState(
        content: KonyakHomeDetailContent.configuration(bottle),
        programConfigurationSettingsState:
            ProgramConfigurationSettingsState.ready(ProgramSettingsSummary()),
        runtimeSettingsControlState: const RuntimeSettingsControlState.updating(
          'metal-hud',
        ),
        isBottleNavigationLocked: true,
      ),
      bottleActions: KonyakBottleActions(
        runtimeSettingsChangeAction: runtimeSettingsChangeAction,
        openLocationAction: locationAction,
      ),
      programActions: const KonyakProgramActions(),
      winetricksActions: KonyakWinetricksActions(
        runBottleCommandAction: commandAction,
      ),
      navigationActions: KonyakHomeNavigationActions(
        onBackToBottle: () => fail('Locked configuration must not navigate.'),
        onShowBottleConfiguration: (_) {},
        onConfigurePinnedProgram: (_, _) {},
      ),
    );

    expect(viewModel.topBar.title, isA<BottleConfigurationBottleDetailTitle>());
    expect(
      viewModel.topBar.backAction,
      isA<UnavailableKonyakHomeActionAvailability>(),
    );

    switch (viewModel.body) {
      case BottleConfigurationBottleDetailBody(
        :final bottle,
        :final runtimeSettingsControlState,
        runtimeSettingsChangeAction: final resolvedRuntimeSettingsChangeAction,
      ):
        expect(bottle.id, 'steam');
        expect(
          runtimeSettingsControlState,
          const RuntimeSettingsControlState.updating('metal-hud'),
        );
        expect(
          resolvedRuntimeSettingsChangeAction,
          runtimeSettingsChangeAction,
        );
      case _:
        fail('Expected bottle configuration body model.');
    }
    switch (viewModel.bottomBar) {
      case BottleConfigurationBottleDetailBottomBar(:final toolsAction):
        expect(
          availableBottleToolActionKinds(toolsAction),
          BottleToolActionKind.values,
        );
      case _:
        fail('Expected bottle configuration bottom bar model.');
    }
  });

  test(
    'builds empty overview models with explicit empty content and target',
    () {
      final viewModel = bottleDetailViewModel(
        state: _detailState(
          content: const KonyakHomeDetailContent.empty(),
          programConfigurationSettingsState:
              ProgramConfigurationSettingsState.ready(ProgramSettingsSummary()),
          bottleListLoadState: const BottleListLoadState.failed(
            'list-bottles failed',
          ),
        ),
        bottleActions: const KonyakBottleActions(),
        programActions: const KonyakProgramActions(),
        winetricksActions: const KonyakWinetricksActions(),
        navigationActions: KonyakHomeNavigationActions(
          onBackToBottle: () {},
          onShowBottleConfiguration: (_) {},
          onConfigurePinnedProgram: (_, _) {},
        ),
      );

      expect(viewModel.topBar.title, isA<KonyakBottleDetailTitle>());
      expect(
        viewModel.topBar.backAction,
        isA<UnavailableKonyakHomeActionAvailability>(),
      );
      switch (viewModel.body) {
        case OverviewBottleDetailBody(:final content):
          expect(switch (content) {
            EmptyBottleOverviewContent(:final loadState) => loadState,
            SelectedBottleOverviewContent() =>
              const BottleListLoadState.loaded(),
          }, const BottleListLoadState.failed('list-bottles failed'));
        case _:
          fail('Expected overview body model.');
      }
      switch (viewModel.bottomBar) {
        case OverviewBottleDetailBottomBar(:final target):
          expect(target, const BottleActionTarget.none());
        case _:
          fail('Expected overview bottom bar model.');
      }
    },
  );
}

KonyakHomeDetailState _detailState({
  required KonyakHomeDetailContent content,
  required ProgramConfigurationSettingsState programConfigurationSettingsState,
  RuntimeSettingsControlState runtimeSettingsControlState =
      const RuntimeSettingsControlState.idle(),
  BottleListLoadState bottleListLoadState = const BottleListLoadState.loaded(),
  bool isBottleNavigationLocked = false,
}) {
  return KonyakHomeDetailState(
    platform: KonyakPlatform.macos,
    runtimeCapabilitiesState: const RuntimeCapabilitiesState.unavailable(),
    content: content,
    bottleListLoadState: bottleListLoadState,
    programConfigurationSettingsState: programConfigurationSettingsState,
    runtimeSettingsControlState: runtimeSettingsControlState,
    isBottleNavigationLocked: isBottleNavigationLocked,
  );
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
