import 'package:flutter/material.dart';

import '../../l10n/konyak_localizations.dart';
import '../app_constants.dart';
import '../home/home_contracts.dart';
import '../programs/program_configuration_view.dart';
import '../widgets/konyak_top_bar.dart';
import 'bottle_action_target.dart';
import 'bottle_configuration_view.dart';
import 'bottle_overview.dart';
import 'bottle_overview_content.dart';
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
    final content = state.content;

    return ColoredBox(
      color: colors.windowBackground,
      child: Column(
        children: [
          KonyakTopBar(
            title: switch (content) {
              ProgramKonyakHomeDetailContent(:final program) =>
                localizations.programConfigurationTitle(program.name),
              ConfigurationKonyakHomeDetailContent() =>
                localizations.bottleConfiguration,
              OverviewKonyakHomeDetailContent(:final bottle) => bottle.name,
              EmptyKonyakHomeDetailContent() => 'Konyak',
            },
            onBack: switch (content) {
              ConfigurationKonyakHomeDetailContent() ||
              ProgramKonyakHomeDetailContent() =>
                state.isBottleNavigationLocked
                    ? null
                    : navigationActions.onBackToBottle,
              OverviewKonyakHomeDetailContent() ||
              EmptyKonyakHomeDetailContent() => null,
            },
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
          Expanded(
            child: switch (content) {
              ProgramKonyakHomeDetailContent(:final bottle, :final program) =>
                ProgramConfigurationView(
                  bottle: bottle,
                  program: program,
                  settingsState: state.programConfigurationSettingsState,
                  programSettingsChangeAction:
                      programActions.programSettingsChangeAction,
                ),
              ConfigurationKonyakHomeDetailContent(:final bottle) =>
                BottleConfigurationView(
                  platform: state.platform,
                  runtimeCapabilitiesState: state.runtimeCapabilitiesState,
                  bottle: bottle,
                  runtimeSettingsControlState:
                      state.runtimeSettingsControlState,
                  runtimeSettingsChangeAction:
                      bottleActions.runtimeSettingsChangeAction,
                ),
              OverviewKonyakHomeDetailContent(:final bottle) => BottleOverview(
                platform: state.platform,
                content: BottleOverviewContent.bottle(bottle),
                runProgramAction: programActions.runProgramAction,
                runProgramPathAction: programActions.runProgramPathAction,
                pinProgramAction: programActions.pinProgramAction,
                configurePinnedProgramAction:
                    PinnedProgramActionAvailability.available(
                      navigationActions.onConfigurePinnedProgram,
                    ),
                unpinProgramAction: programActions.unpinProgramAction,
                renamePinnedProgramAction:
                    programActions.renamePinnedProgramAction,
                openPinnedProgramLocationAction:
                    programActions.openPinnedProgramLocationAction,
                showBottleConfigurationAction:
                    BottleSummaryActionAvailability.available(
                      navigationActions.onShowBottleConfiguration,
                    ),
                showBottleProgramsAction: bottleActions.showProgramsAction,
              ),
              EmptyKonyakHomeDetailContent() => BottleOverview(
                platform: state.platform,
                content: BottleOverviewContent.empty(state.bottleListLoadState),
                runProgramAction: programActions.runProgramAction,
                runProgramPathAction: programActions.runProgramPathAction,
                pinProgramAction: programActions.pinProgramAction,
                configurePinnedProgramAction:
                    PinnedProgramActionAvailability.available(
                      navigationActions.onConfigurePinnedProgram,
                    ),
                unpinProgramAction: programActions.unpinProgramAction,
                renamePinnedProgramAction:
                    programActions.renamePinnedProgramAction,
                openPinnedProgramLocationAction:
                    programActions.openPinnedProgramLocationAction,
                showBottleConfigurationAction:
                    BottleSummaryActionAvailability.available(
                      navigationActions.onShowBottleConfiguration,
                    ),
                showBottleProgramsAction: bottleActions.showProgramsAction,
              ),
            },
          ),
          switch (content) {
            ProgramKonyakHomeDetailContent(:final bottle, :final program) =>
              ProgramConfigurationBottomBar(
                platform: state.platform,
                bottle: bottle,
                program: program,
                openPinnedProgramLocationAction:
                    programActions.openPinnedProgramLocationAction,
                runProgramPathAction: programActions.runProgramPathAction,
              ),
            ConfigurationKonyakHomeDetailContent(:final bottle) =>
              BottleConfigurationBottomBar(
                bottle: bottle,
                toolsAction: bottleToolsActionAvailabilityFromActions(
                  commandAction: winetricksActions.runBottleCommandAction,
                  locationAction: bottleActions.openLocationAction,
                ),
              ),
            OverviewKonyakHomeDetailContent(:final bottle) => KonyakBottomBar(
              target: BottleActionTarget.bottle(bottle),
              runProgramAction: programActions.runProgramAction,
              toolsAction: bottleToolsActionAvailabilityFromActions(
                commandAction: winetricksActions.runBottleCommandAction,
                locationAction: bottleActions.openLocationAction,
              ),
              showWinetricksAction: winetricksActions.showWinetricksAction,
            ),
            EmptyKonyakHomeDetailContent() => KonyakBottomBar(
              target: const BottleActionTarget.none(),
              runProgramAction: programActions.runProgramAction,
              toolsAction: bottleToolsActionAvailabilityFromActions(
                commandAction: winetricksActions.runBottleCommandAction,
                locationAction: bottleActions.openLocationAction,
              ),
              showWinetricksAction: winetricksActions.showWinetricksAction,
            ),
          },
        ],
      ),
    );
  }
}
