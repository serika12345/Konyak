import '../../bottles/bottle_summary.dart';
import '../app_platform.dart';
import '../home/home_contracts.dart';
import 'bottle_action_target.dart';
import 'bottle_overview_content.dart';

final class BottleDetailViewModel {
  const BottleDetailViewModel({
    required this.topBar,
    required this.body,
    required this.bottomBar,
  });

  final BottleDetailTopBarModel topBar;
  final BottleDetailBody body;
  final BottleDetailBottomBar bottomBar;
}

final class BottleDetailTopBarModel {
  const BottleDetailTopBarModel({
    required this.title,
    required this.backAction,
  });

  final BottleDetailTitle title;
  final KonyakHomeActionAvailability backAction;
}

sealed class BottleDetailTitle {
  const BottleDetailTitle();
}

final class KonyakBottleDetailTitle extends BottleDetailTitle {
  const KonyakBottleDetailTitle();
}

final class BottleNameBottleDetailTitle extends BottleDetailTitle {
  const BottleNameBottleDetailTitle(this.bottleName);

  final String bottleName;
}

final class BottleConfigurationBottleDetailTitle extends BottleDetailTitle {
  const BottleConfigurationBottleDetailTitle();
}

final class ProgramConfigurationBottleDetailTitle extends BottleDetailTitle {
  const ProgramConfigurationBottleDetailTitle(this.programName);

  final String programName;
}

sealed class BottleDetailBody {
  const BottleDetailBody();
}

final class ProgramConfigurationBottleDetailBody extends BottleDetailBody {
  const ProgramConfigurationBottleDetailBody({
    required this.bottle,
    required this.program,
    required this.settingsState,
    required this.programSettingsChangeAction,
  });

  final BottleSummary bottle;
  final PinnedProgramSummary program;
  final ProgramConfigurationSettingsState settingsState;
  final ProgramSettingsChangeAvailability programSettingsChangeAction;
}

final class BottleConfigurationBottleDetailBody extends BottleDetailBody {
  const BottleConfigurationBottleDetailBody({
    required this.platform,
    required this.runtimeCapabilitiesState,
    required this.bottle,
    required this.runtimeSettingsControlState,
    required this.runtimeSettingsChangeAction,
  });

  final KonyakPlatform platform;
  final RuntimeCapabilitiesState runtimeCapabilitiesState;
  final BottleSummary bottle;
  final RuntimeSettingsControlState runtimeSettingsControlState;
  final RuntimeSettingsChangeAvailability runtimeSettingsChangeAction;
}

final class OverviewBottleDetailBody extends BottleDetailBody {
  const OverviewBottleDetailBody({
    required this.platform,
    required this.content,
    required this.runProgramAction,
    required this.runProgramPathAction,
    required this.pinProgramAction,
    required this.configurePinnedProgramAction,
    required this.unpinProgramAction,
    required this.renamePinnedProgramAction,
    required this.openPinnedProgramLocationAction,
    required this.showBottleConfigurationAction,
    required this.showBottleProgramsAction,
  });

  final KonyakPlatform platform;
  final BottleOverviewContent content;
  final BottleSummaryActionAvailability runProgramAction;
  final ProgramPathActionAvailability runProgramPathAction;
  final BottleSummaryActionAvailability pinProgramAction;
  final PinnedProgramActionAvailability configurePinnedProgramAction;
  final PinnedProgramActionAvailability unpinProgramAction;
  final PinnedProgramActionAvailability renamePinnedProgramAction;
  final PinnedProgramActionAvailability openPinnedProgramLocationAction;
  final BottleSummaryActionAvailability showBottleConfigurationAction;
  final BottleSummaryActionAvailability showBottleProgramsAction;
}

sealed class BottleDetailBottomBar {
  const BottleDetailBottomBar();
}

final class ProgramConfigurationBottleDetailBottomBar
    extends BottleDetailBottomBar {
  const ProgramConfigurationBottleDetailBottomBar({
    required this.platform,
    required this.bottle,
    required this.program,
    required this.openPinnedProgramLocationAction,
    required this.runProgramPathAction,
  });

  final KonyakPlatform platform;
  final BottleSummary bottle;
  final PinnedProgramSummary program;
  final PinnedProgramActionAvailability openPinnedProgramLocationAction;
  final ProgramPathActionAvailability runProgramPathAction;
}

final class BottleConfigurationBottleDetailBottomBar
    extends BottleDetailBottomBar {
  const BottleConfigurationBottleDetailBottomBar({
    required this.bottle,
    required this.toolsAction,
  });

  final BottleSummary bottle;
  final BottleToolsActionAvailability toolsAction;
}

final class OverviewBottleDetailBottomBar extends BottleDetailBottomBar {
  const OverviewBottleDetailBottomBar({
    required this.target,
    required this.runProgramAction,
    required this.toolsAction,
    required this.showWinetricksAction,
  });

  final BottleActionTarget target;
  final BottleSummaryActionAvailability runProgramAction;
  final BottleToolsActionAvailability toolsAction;
  final BottleSummaryActionAvailability showWinetricksAction;
}

BottleDetailViewModel bottleDetailViewModel({
  required KonyakHomeDetailState state,
  required KonyakBottleActions bottleActions,
  required KonyakProgramActions programActions,
  required KonyakWinetricksActions winetricksActions,
  required KonyakHomeNavigationActions navigationActions,
}) {
  return BottleDetailViewModel(
    topBar: BottleDetailTopBarModel(
      title: _bottleDetailTitle(state.content),
      backAction: _bottleDetailBackAction(
        content: state.content,
        isBottleNavigationLocked: state.isBottleNavigationLocked,
        navigationActions: navigationActions,
      ),
    ),
    body: _bottleDetailBody(
      state: state,
      bottleActions: bottleActions,
      programActions: programActions,
      navigationActions: navigationActions,
    ),
    bottomBar: _bottleDetailBottomBar(
      state: state,
      bottleActions: bottleActions,
      programActions: programActions,
      winetricksActions: winetricksActions,
    ),
  );
}

BottleDetailTitle _bottleDetailTitle(KonyakHomeDetailContent content) {
  return switch (content) {
    ProgramKonyakHomeDetailContent(:final program) =>
      ProgramConfigurationBottleDetailTitle(program.name),
    ConfigurationKonyakHomeDetailContent() =>
      const BottleConfigurationBottleDetailTitle(),
    OverviewKonyakHomeDetailContent(:final bottle) =>
      BottleNameBottleDetailTitle(bottle.name),
    EmptyKonyakHomeDetailContent() => const KonyakBottleDetailTitle(),
  };
}

KonyakHomeActionAvailability _bottleDetailBackAction({
  required KonyakHomeDetailContent content,
  required bool isBottleNavigationLocked,
  required KonyakHomeNavigationActions navigationActions,
}) {
  return switch ((content, isBottleNavigationLocked)) {
    (
      ConfigurationKonyakHomeDetailContent() ||
          ProgramKonyakHomeDetailContent(),
      false,
    ) =>
      KonyakHomeActionAvailability.available(navigationActions.onBackToBottle),
    _ => const KonyakHomeActionAvailability.unavailable(),
  };
}

BottleDetailBody _bottleDetailBody({
  required KonyakHomeDetailState state,
  required KonyakBottleActions bottleActions,
  required KonyakProgramActions programActions,
  required KonyakHomeNavigationActions navigationActions,
}) {
  return switch (state.content) {
    ProgramKonyakHomeDetailContent(:final bottle, :final program) =>
      ProgramConfigurationBottleDetailBody(
        bottle: bottle,
        program: program,
        settingsState: state.programConfigurationSettingsState,
        programSettingsChangeAction: programActions.programSettingsChangeAction,
      ),
    ConfigurationKonyakHomeDetailContent(:final bottle) =>
      BottleConfigurationBottleDetailBody(
        platform: state.platform,
        runtimeCapabilitiesState: state.runtimeCapabilitiesState,
        bottle: bottle,
        runtimeSettingsControlState: state.runtimeSettingsControlState,
        runtimeSettingsChangeAction: bottleActions.runtimeSettingsChangeAction,
      ),
    OverviewKonyakHomeDetailContent(:final bottle) => _overviewBody(
      state: state,
      content: BottleOverviewContent.bottle(bottle),
      bottleActions: bottleActions,
      programActions: programActions,
      navigationActions: navigationActions,
    ),
    EmptyKonyakHomeDetailContent() => _overviewBody(
      state: state,
      content: BottleOverviewContent.empty(state.bottleListLoadState),
      bottleActions: bottleActions,
      programActions: programActions,
      navigationActions: navigationActions,
    ),
  };
}

OverviewBottleDetailBody _overviewBody({
  required KonyakHomeDetailState state,
  required BottleOverviewContent content,
  required KonyakBottleActions bottleActions,
  required KonyakProgramActions programActions,
  required KonyakHomeNavigationActions navigationActions,
}) {
  return OverviewBottleDetailBody(
    platform: state.platform,
    content: content,
    runProgramAction: programActions.runProgramAction,
    runProgramPathAction: programActions.runProgramPathAction,
    pinProgramAction: programActions.pinProgramAction,
    configurePinnedProgramAction: PinnedProgramActionAvailability.available(
      navigationActions.onConfigurePinnedProgram,
    ),
    unpinProgramAction: programActions.unpinProgramAction,
    renamePinnedProgramAction: programActions.renamePinnedProgramAction,
    openPinnedProgramLocationAction:
        programActions.openPinnedProgramLocationAction,
    showBottleConfigurationAction: BottleSummaryActionAvailability.available(
      navigationActions.onShowBottleConfiguration,
    ),
    showBottleProgramsAction: bottleActions.showProgramsAction,
  );
}

BottleDetailBottomBar _bottleDetailBottomBar({
  required KonyakHomeDetailState state,
  required KonyakBottleActions bottleActions,
  required KonyakProgramActions programActions,
  required KonyakWinetricksActions winetricksActions,
}) {
  final toolsAction = bottleToolsActionAvailabilityFromActions(
    commandAction: winetricksActions.runBottleCommandAction,
    locationAction: bottleActions.openLocationAction,
  );
  return switch (state.content) {
    ProgramKonyakHomeDetailContent(:final bottle, :final program) =>
      ProgramConfigurationBottleDetailBottomBar(
        platform: state.platform,
        bottle: bottle,
        program: program,
        openPinnedProgramLocationAction:
            programActions.openPinnedProgramLocationAction,
        runProgramPathAction: programActions.runProgramPathAction,
      ),
    ConfigurationKonyakHomeDetailContent(:final bottle) =>
      BottleConfigurationBottleDetailBottomBar(
        bottle: bottle,
        toolsAction: toolsAction,
      ),
    OverviewKonyakHomeDetailContent(:final bottle) =>
      OverviewBottleDetailBottomBar(
        target: BottleActionTarget.bottle(bottle),
        runProgramAction: programActions.runProgramAction,
        toolsAction: toolsAction,
        showWinetricksAction: winetricksActions.showWinetricksAction,
      ),
    EmptyKonyakHomeDetailContent() => OverviewBottleDetailBottomBar(
      target: const BottleActionTarget.none(),
      runProgramAction: programActions.runProgramAction,
      toolsAction: toolsAction,
      showWinetricksAction: winetricksActions.showWinetricksAction,
    ),
  };
}
