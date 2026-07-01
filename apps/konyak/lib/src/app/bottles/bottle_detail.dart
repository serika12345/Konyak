import 'package:flutter/material.dart';

import '../../l10n/konyak_localizations.dart';
import '../app_constants.dart';
import '../home/home_contracts.dart';
import '../programs/program_configuration_view.dart';
import '../widgets/konyak_top_bar.dart';
import 'bottle_action_availability.dart';
import 'bottle_action_target.dart';
import 'bottle_configuration_view.dart';
import 'bottle_overview.dart';
import 'bottle_overview_content.dart';
import 'bottom_bars.dart';
import 'runtime_settings_change.dart';

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
            onRefresh: menuActions.onRefresh,
            onShowProcessManager: menuActions.onShowProcessManager,
            onShowSettings: menuActions.onShowSettings,
            onCreateBottle: menuActions.onCreateBottle,
            onViewLatestLog: menuActions.onViewLatestLog,
          ),
          Expanded(
            child: switch (content) {
              ProgramKonyakHomeDetailContent(:final bottle, :final program) =>
                ProgramConfigurationView(
                  bottle: bottle,
                  program: program,
                  settingsState: state.programConfigurationSettingsState,
                  programSettingsChangeAction:
                      programSettingsChangeAvailabilityFromNullable(
                        programActions.onProgramSettingsChanged,
                      ),
                ),
              ConfigurationKonyakHomeDetailContent(:final bottle) =>
                BottleConfigurationView(
                  platform: state.platform,
                  runtimeCapabilitiesState: state.runtimeCapabilitiesState,
                  bottle: bottle,
                  runtimeSettingsControlState:
                      state.runtimeSettingsControlState,
                  runtimeSettingsChangeAction:
                      runtimeSettingsChangeAvailabilityFromNullable(
                        bottleActions.onRuntimeSettingsChanged,
                      ),
                ),
              OverviewKonyakHomeDetailContent(:final bottle) => BottleOverview(
                platform: state.platform,
                content: BottleOverviewContent.bottle(bottle),
                runProgramAction: bottleSummaryActionAvailabilityFromNullable(
                  programActions.onRunProgram,
                ),
                runProgramPathAction: programPathActionAvailabilityFromNullable(
                  programActions.onRunProgramPath,
                ),
                pinProgramAction: bottleSummaryActionAvailabilityFromNullable(
                  programActions.onPinProgram,
                ),
                configurePinnedProgramAction:
                    PinnedProgramActionAvailability.available(
                      navigationActions.onConfigurePinnedProgram,
                    ),
                unpinProgramAction: pinnedProgramActionAvailabilityFromNullable(
                  programActions.onUnpinProgram,
                ),
                renamePinnedProgramAction:
                    pinnedProgramActionAvailabilityFromNullable(
                      programActions.onRenamePinnedProgram,
                    ),
                openPinnedProgramLocationAction:
                    pinnedProgramActionAvailabilityFromNullable(
                      programActions.onOpenPinnedProgramLocation,
                    ),
                showBottleConfigurationAction:
                    bottleSummaryActionAvailabilityFromNullable(
                      navigationActions.onShowBottleConfiguration,
                    ),
                showBottleProgramsAction:
                    bottleSummaryActionAvailabilityFromNullable(
                      bottleActions.onShowPrograms,
                    ),
              ),
              EmptyKonyakHomeDetailContent() => BottleOverview(
                platform: state.platform,
                content: BottleOverviewContent.empty(state.bottleListLoadState),
                runProgramAction: bottleSummaryActionAvailabilityFromNullable(
                  programActions.onRunProgram,
                ),
                runProgramPathAction: programPathActionAvailabilityFromNullable(
                  programActions.onRunProgramPath,
                ),
                pinProgramAction: bottleSummaryActionAvailabilityFromNullable(
                  programActions.onPinProgram,
                ),
                configurePinnedProgramAction:
                    PinnedProgramActionAvailability.available(
                      navigationActions.onConfigurePinnedProgram,
                    ),
                unpinProgramAction: pinnedProgramActionAvailabilityFromNullable(
                  programActions.onUnpinProgram,
                ),
                renamePinnedProgramAction:
                    pinnedProgramActionAvailabilityFromNullable(
                      programActions.onRenamePinnedProgram,
                    ),
                openPinnedProgramLocationAction:
                    pinnedProgramActionAvailabilityFromNullable(
                      programActions.onOpenPinnedProgramLocation,
                    ),
                showBottleConfigurationAction:
                    bottleSummaryActionAvailabilityFromNullable(
                      navigationActions.onShowBottleConfiguration,
                    ),
                showBottleProgramsAction:
                    bottleSummaryActionAvailabilityFromNullable(
                      bottleActions.onShowPrograms,
                    ),
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
                    pinnedProgramActionAvailabilityFromNullable(
                      programActions.onOpenPinnedProgramLocation,
                    ),
                runProgramPathAction: programPathActionAvailabilityFromNullable(
                  programActions.onRunProgramPath,
                ),
              ),
            ConfigurationKonyakHomeDetailContent(:final bottle) =>
              BottleConfigurationBottomBar(
                bottle: bottle,
                toolsAction: bottleToolsActionAvailabilityFromNullable(
                  onRunCommand: winetricksActions.onRunBottleCommand,
                  onOpenLocation: bottleActions.onOpenLocation,
                ),
              ),
            OverviewKonyakHomeDetailContent(:final bottle) => KonyakBottomBar(
              target: BottleActionTarget.bottle(bottle),
              runProgramAction: bottleSummaryActionAvailabilityFromNullable(
                programActions.onRunProgram,
              ),
              toolsAction: bottleToolsActionAvailabilityFromNullable(
                onRunCommand: winetricksActions.onRunBottleCommand,
                onOpenLocation: bottleActions.onOpenLocation,
              ),
              showWinetricksAction: bottleSummaryActionAvailabilityFromNullable(
                winetricksActions.onShowWinetricks,
              ),
            ),
            EmptyKonyakHomeDetailContent() => KonyakBottomBar(
              target: const BottleActionTarget.none(),
              runProgramAction: bottleSummaryActionAvailabilityFromNullable(
                programActions.onRunProgram,
              ),
              toolsAction: bottleToolsActionAvailabilityFromNullable(
                onRunCommand: winetricksActions.onRunBottleCommand,
                onOpenLocation: bottleActions.onOpenLocation,
              ),
              showWinetricksAction: bottleSummaryActionAvailabilityFromNullable(
                winetricksActions.onShowWinetricks,
              ),
            ),
          },
        ],
      ),
    );
  }
}
