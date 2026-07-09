import 'package:flutter/material.dart';

import '../../l10n/konyak_localizations.dart';
import '../app_constants.dart';
import '../home/home_contracts.dart';
import '../programs/program_configuration_view.dart';
import '../widgets/konyak_top_bar.dart';
import 'bottle_configuration_view.dart';
import 'bottle_detail_view_model.dart';
import 'bottle_overview.dart';
import 'bottom_bars.dart';

export 'bottle_detail_mode.dart';

class KonyakBottleDetail extends StatelessWidget {
  const KonyakBottleDetail({
    super.key,
    required this.state,
    required this.menuActions,
    required this.bottleActions,
    required this.programActions,
    required this.winetricksActions,
    required this.navigationActions,
  });

  final KonyakHomeDetailState state;
  final KonyakHomeMenuActions menuActions;
  final KonyakBottleActions bottleActions;
  final KonyakProgramActions programActions;
  final KonyakWinetricksActions winetricksActions;
  final KonyakHomeNavigationActions navigationActions;

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);
    final localizations = KonyakLocalizations.of(context);
    final viewModel = bottleDetailViewModel(
      state: state,
      bottleActions: bottleActions,
      programActions: programActions,
      winetricksActions: winetricksActions,
      navigationActions: navigationActions,
    );

    return ColoredBox(
      color: colors.windowBackground,
      child: Column(
        children: [
          KonyakTopBar(
            title: _localizedBottleDetailTitle(
              localizations,
              viewModel.topBar.title,
            ),
            onBack: homeActionCallback(viewModel.topBar.backAction),
            onRefresh: homeActionCallback(menuActions.refreshAction),
            onShowProcessManager: homeActionCallback(
              menuActions.showProcessManagerAction,
            ),
            onShowSettings: homeActionCallback(menuActions.showSettingsAction),
            onCreateBottle: homeActionCallback(menuActions.createBottleAction),
            onViewLatestLog: homeActionCallback(
              menuActions.viewLatestLogAction,
            ),
          ),
          Expanded(child: _bottleDetailBody(viewModel.body)),
          _bottleDetailBottomBar(viewModel.bottomBar),
        ],
      ),
    );
  }
}

String _localizedBottleDetailTitle(
  KonyakLocalizations localizations,
  BottleDetailTitle title,
) {
  return switch (title) {
    ProgramConfigurationBottleDetailTitle(:final programName) =>
      localizations.programConfigurationTitle(programName),
    BottleConfigurationBottleDetailTitle() => localizations.bottleConfiguration,
    BottleNameBottleDetailTitle(:final bottleName) => bottleName,
    KonyakBottleDetailTitle() => 'Konyak',
  };
}

Widget _bottleDetailBody(BottleDetailBody body) {
  return switch (body) {
    ProgramConfigurationBottleDetailBody(
      :final bottle,
      :final program,
      :final settingsState,
      :final programSettingsChangeAction,
    ) =>
      ProgramConfigurationView(
        bottle: bottle,
        program: program,
        settingsState: settingsState,
        programSettingsChangeAction: programSettingsChangeAction,
      ),
    BottleConfigurationBottleDetailBody(
      :final platform,
      :final runtimeCapabilitiesState,
      :final bottle,
      :final runtimeSettingsControlState,
      :final runtimeSettingsChangeAction,
    ) =>
      BottleConfigurationView(
        platform: platform,
        runtimeCapabilitiesState: runtimeCapabilitiesState,
        bottle: bottle,
        runtimeSettingsControlState: runtimeSettingsControlState,
        runtimeSettingsChangeAction: runtimeSettingsChangeAction,
      ),
    OverviewBottleDetailBody(
      :final platform,
      :final content,
      :final runProgramAction,
      :final runProgramPathAction,
      :final pinProgramAction,
      :final configurePinnedProgramAction,
      :final unpinProgramAction,
      :final renamePinnedProgramAction,
      :final openPinnedProgramLocationAction,
      :final showBottleConfigurationAction,
      :final showBottleProgramsAction,
    ) =>
      BottleOverview(
        platform: platform,
        content: content,
        runProgramAction: runProgramAction,
        runProgramPathAction: runProgramPathAction,
        pinProgramAction: pinProgramAction,
        configurePinnedProgramAction: configurePinnedProgramAction,
        unpinProgramAction: unpinProgramAction,
        renamePinnedProgramAction: renamePinnedProgramAction,
        openPinnedProgramLocationAction: openPinnedProgramLocationAction,
        showBottleConfigurationAction: showBottleConfigurationAction,
        showBottleProgramsAction: showBottleProgramsAction,
      ),
  };
}

Widget _bottleDetailBottomBar(BottleDetailBottomBar bottomBar) {
  return switch (bottomBar) {
    ProgramConfigurationBottleDetailBottomBar(
      :final platform,
      :final bottle,
      :final program,
      :final openPinnedProgramLocationAction,
      :final runProgramPathAction,
    ) =>
      ProgramConfigurationBottomBar(
        platform: platform,
        bottle: bottle,
        program: program,
        openPinnedProgramLocationAction: openPinnedProgramLocationAction,
        runProgramPathAction: runProgramPathAction,
      ),
    BottleConfigurationBottleDetailBottomBar(
      :final bottle,
      :final toolsAction,
    ) =>
      BottleConfigurationBottomBar(bottle: bottle, toolsAction: toolsAction),
    OverviewBottleDetailBottomBar(
      :final target,
      :final runProgramAction,
      :final installSteamProfileAction,
      :final toolsAction,
      :final showWinetricksAction,
    ) =>
      KonyakBottomBar(
        target: target,
        runProgramAction: runProgramAction,
        installSteamProfileAction: installSteamProfileAction,
        toolsAction: toolsAction,
        showWinetricksAction: showWinetricksAction,
      ),
  };
}
