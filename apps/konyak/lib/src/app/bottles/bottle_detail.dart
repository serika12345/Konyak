import 'package:flutter/material.dart';

import '../../l10n/konyak_localizations.dart';
import '../app_constants.dart';
import '../home/home_contracts.dart';
import '../programs/program_configuration_view.dart';
import '../widgets/konyak_top_bar.dart';
import 'bottle_configuration_view.dart';
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
                  onProgramSettingsChanged:
                      programActions.onProgramSettingsChanged,
                ),
              ConfigurationKonyakHomeDetailContent(:final bottle) =>
                BottleConfigurationView(
                  platform: state.platform,
                  runtimeCapabilitiesState: state.runtimeCapabilitiesState,
                  bottle: bottle,
                  runtimeSettingsControlState:
                      state.runtimeSettingsControlState,
                  onRuntimeSettingsChanged:
                      bottleActions.onRuntimeSettingsChanged,
                ),
              OverviewKonyakHomeDetailContent(:final bottle) => BottleOverview(
                platform: state.platform,
                bottle: bottle,
                loadState: state.bottleListLoadState,
                onRunProgram: programActions.onRunProgram,
                onRunProgramPath: programActions.onRunProgramPath,
                onPinProgram: programActions.onPinProgram,
                onConfigurePinnedProgram:
                    navigationActions.onConfigurePinnedProgram,
                onUnpinProgram: programActions.onUnpinProgram,
                onRenamePinnedProgram: programActions.onRenamePinnedProgram,
                onOpenPinnedProgramLocation:
                    programActions.onOpenPinnedProgramLocation,
                onShowBottleConfiguration:
                    navigationActions.onShowBottleConfiguration,
                onShowBottlePrograms: bottleActions.onShowPrograms,
              ),
              EmptyKonyakHomeDetailContent() => BottleOverview(
                platform: state.platform,
                bottle: null,
                loadState: state.bottleListLoadState,
                onRunProgram: programActions.onRunProgram,
                onRunProgramPath: programActions.onRunProgramPath,
                onPinProgram: programActions.onPinProgram,
                onConfigurePinnedProgram:
                    navigationActions.onConfigurePinnedProgram,
                onUnpinProgram: programActions.onUnpinProgram,
                onRenamePinnedProgram: programActions.onRenamePinnedProgram,
                onOpenPinnedProgramLocation:
                    programActions.onOpenPinnedProgramLocation,
                onShowBottleConfiguration:
                    navigationActions.onShowBottleConfiguration,
                onShowBottlePrograms: bottleActions.onShowPrograms,
              ),
            },
          ),
          switch (content) {
            ProgramKonyakHomeDetailContent(:final bottle, :final program) =>
              ProgramConfigurationBottomBar(
                platform: state.platform,
                bottle: bottle,
                program: program,
                onOpenPinnedProgramLocation:
                    programActions.onOpenPinnedProgramLocation,
                onRunProgramPath: programActions.onRunProgramPath,
              ),
            ConfigurationKonyakHomeDetailContent(:final bottle) =>
              BottleConfigurationBottomBar(
                bottle: bottle,
                onRunBottleCommand: winetricksActions.onRunBottleCommand,
                onOpenBottleLocation: bottleActions.onOpenLocation,
              ),
            OverviewKonyakHomeDetailContent(:final bottle) => KonyakBottomBar(
              bottle: bottle,
              onRunProgram: programActions.onRunProgram,
              onRunBottleCommand: winetricksActions.onRunBottleCommand,
              onShowWinetricks: winetricksActions.onShowWinetricks,
              onOpenBottleLocation: bottleActions.onOpenLocation,
            ),
            EmptyKonyakHomeDetailContent() => KonyakBottomBar(
              bottle: null,
              onRunProgram: programActions.onRunProgram,
              onRunBottleCommand: winetricksActions.onRunBottleCommand,
              onShowWinetricks: winetricksActions.onShowWinetricks,
              onOpenBottleLocation: bottleActions.onOpenLocation,
            ),
          },
        ],
      ),
    );
  }
}
