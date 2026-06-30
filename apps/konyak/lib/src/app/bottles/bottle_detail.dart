import 'package:flutter/material.dart';

import '../../l10n/konyak_localizations.dart';
import '../app_constants.dart';
import '../home/home_contracts.dart';
import '../programs/program_configuration_settings.dart';
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
    final activeBottle = state.bottle;
    final activeProgram = activeBottle == null ? null : state.selectedProgram;

    final isConfiguration =
        state.detailMode == BottleDetailMode.configuration &&
        activeBottle != null;
    final isProgramConfiguration =
        state.detailMode == BottleDetailMode.programConfiguration &&
        activeBottle != null &&
        activeProgram != null;

    return ColoredBox(
      color: colors.windowBackground,
      child: Column(
        children: [
          KonyakTopBar(
            title: isProgramConfiguration
                ? localizations.programConfigurationTitle(activeProgram.name)
                : isConfiguration
                ? localizations.bottleConfiguration
                : activeBottle?.name ?? 'Konyak',
            onBack: isConfiguration || isProgramConfiguration
                ? state.isBottleNavigationLocked
                      ? null
                      : navigationActions.onBackToBottle
                : null,
            onRefresh: menuActions.onRefresh,
            onShowProcessManager: menuActions.onShowProcessManager,
            onShowSettings: menuActions.onShowSettings,
            onCreateBottle: menuActions.onCreateBottle,
            onViewLatestLog: menuActions.onViewLatestLog,
          ),
          Expanded(
            child: isProgramConfiguration
                ? ProgramConfigurationView(
                    bottle: activeBottle,
                    program: activeProgram,
                    settingsState:
                        programConfigurationSettingsStateFromNullable(
                          settings: state.programSettings,
                          isLoading: state.isProgramSettingsLoading,
                        ),
                    onProgramSettingsChanged:
                        programActions.onProgramSettingsChanged,
                  )
                : isConfiguration
                ? BottleConfigurationView(
                    platform: state.platform,
                    runtime: state.runtime,
                    isRuntimeCapabilitiesLoading:
                        state.isRuntimeCapabilitiesLoading,
                    bottle: activeBottle,
                    pendingRuntimeSettingsControlKey:
                        state.pendingRuntimeSettingsControlKey,
                    onRuntimeSettingsChanged:
                        bottleActions.onRuntimeSettingsChanged,
                  )
                : BottleOverview(
                    platform: state.platform,
                    bottle: activeBottle,
                    isLoading: state.isLoading,
                    errorMessage: state.errorMessage,
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
          ),
          if (isProgramConfiguration)
            ProgramConfigurationBottomBar(
              platform: state.platform,
              bottle: activeBottle,
              program: activeProgram,
              onOpenPinnedProgramLocation:
                  programActions.onOpenPinnedProgramLocation,
              onRunProgramPath: programActions.onRunProgramPath,
            )
          else if (isConfiguration)
            BottleConfigurationBottomBar(
              bottle: activeBottle,
              onRunBottleCommand: winetricksActions.onRunBottleCommand,
              onOpenBottleLocation: bottleActions.onOpenLocation,
            )
          else
            KonyakBottomBar(
              bottle: activeBottle,
              onRunProgram: programActions.onRunProgram,
              onRunBottleCommand: winetricksActions.onRunBottleCommand,
              onShowWinetricks: winetricksActions.onShowWinetricks,
              onOpenBottleLocation: bottleActions.onOpenLocation,
            ),
        ],
      ),
    );
  }
}
