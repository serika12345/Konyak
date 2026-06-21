import 'package:flutter/material.dart';

import '../../bottles/bottle_summary.dart';
import '../../runtimes/runtime_summary.dart';
import '../app_constants.dart';
import '../app_platform.dart';
import '../programs/program_configuration_view.dart';
import '../widgets/konyak_top_bar.dart';
import 'bottle_configuration_view.dart';
import 'bottle_overview.dart';
import 'bottom_bars.dart';
import 'runtime_settings_change.dart';

enum BottleDetailMode { overview, configuration, programConfiguration }

class KonyakBottleDetail extends StatelessWidget {
  const KonyakBottleDetail({
    super.key,
    required this.platform,
    required this.runtime,
    required this.bottle,
    required this.isLoading,
    required this.errorMessage,
    required this.onRefresh,
    required this.onShowSettings,
    required this.onCreateBottle,
    required this.onViewLatestLog,
    required this.detailMode,
    required this.selectedProgram,
    required this.programSettings,
    required this.isProgramSettingsLoading,
    required this.isRuntimeCapabilitiesLoading,
    required this.pendingRuntimeSettingsControlKey,
    required this.onBackToBottle,
    required this.onShowBottleConfiguration,
    required this.onRuntimeSettingsChanged,
    required this.onDeleteBottle,
    required this.onRunProgram,
    required this.onRunProgramPath,
    required this.onPinProgram,
    required this.onConfigurePinnedProgram,
    required this.onProgramSettingsChanged,
    required this.onUnpinProgram,
    required this.onRenamePinnedProgram,
    required this.onOpenPinnedProgramLocation,
    required this.onRunBottleCommand,
    required this.onShowWinetricks,
    required this.onOpenBottleLocation,
    required this.onShowBottlePrograms,
    required this.onShowProcessManager,
  });

  final KonyakPlatform platform;
  final RuntimeSummary? runtime;
  final BottleSummary? bottle;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRefresh;
  final VoidCallback? onShowSettings;
  final VoidCallback? onCreateBottle;
  final VoidCallback? onViewLatestLog;
  final BottleDetailMode detailMode;
  final PinnedProgramSummary? selectedProgram;
  final ProgramSettingsSummary? programSettings;
  final bool isProgramSettingsLoading;
  final bool isRuntimeCapabilitiesLoading;
  final String? pendingRuntimeSettingsControlKey;
  final VoidCallback? onBackToBottle;
  final ValueChanged<BottleSummary>? onShowBottleConfiguration;
  final RuntimeSettingsChanged? onRuntimeSettingsChanged;
  final ValueChanged<BottleSummary>? onDeleteBottle;
  final ValueChanged<BottleSummary>? onRunProgram;
  final void Function(BottleSummary bottle, String programPath)?
  onRunProgramPath;
  final ValueChanged<BottleSummary>? onPinProgram;
  final void Function(BottleSummary bottle, PinnedProgramSummary program)?
  onConfigurePinnedProgram;
  final void Function(
    BottleSummary bottle,
    PinnedProgramSummary program,
    ProgramSettingsSummary settings,
  )?
  onProgramSettingsChanged;
  final void Function(BottleSummary bottle, PinnedProgramSummary program)?
  onUnpinProgram;
  final void Function(BottleSummary bottle, PinnedProgramSummary program)?
  onRenamePinnedProgram;
  final void Function(BottleSummary bottle, PinnedProgramSummary program)?
  onOpenPinnedProgramLocation;
  final void Function(BottleSummary bottle, String command)? onRunBottleCommand;
  final ValueChanged<BottleSummary>? onShowWinetricks;
  final void Function(BottleSummary bottle, String location)?
  onOpenBottleLocation;
  final ValueChanged<BottleSummary>? onShowBottlePrograms;
  final VoidCallback? onShowProcessManager;

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);
    final activeBottle = bottle;
    final activeProgram = activeBottle == null ? null : selectedProgram;

    final isConfiguration =
        detailMode == BottleDetailMode.configuration && activeBottle != null;
    final isProgramConfiguration =
        detailMode == BottleDetailMode.programConfiguration &&
        activeBottle != null &&
        activeProgram != null;

    return ColoredBox(
      color: colors.windowBackground,
      child: Column(
        children: [
          KonyakTopBar(
            title: isProgramConfiguration
                ? '${activeProgram.name} Configuration'
                : isConfiguration
                ? 'Bottle Configuration'
                : activeBottle?.name ?? 'Konyak',
            onBack: isConfiguration || isProgramConfiguration
                ? onBackToBottle
                : null,
            onRefresh: onRefresh,
            onShowProcessManager: onShowProcessManager,
            onShowSettings: onShowSettings,
            onCreateBottle: onCreateBottle,
            onViewLatestLog: onViewLatestLog,
          ),
          Expanded(
            child: isProgramConfiguration
                ? ProgramConfigurationView(
                    bottle: activeBottle,
                    program: activeProgram,
                    settings: programSettings,
                    isLoading: isProgramSettingsLoading,
                    onProgramSettingsChanged: onProgramSettingsChanged,
                  )
                : isConfiguration
                ? BottleConfigurationView(
                    platform: platform,
                    runtime: runtime,
                    isRuntimeCapabilitiesLoading: isRuntimeCapabilitiesLoading,
                    bottle: activeBottle,
                    pendingRuntimeSettingsControlKey:
                        pendingRuntimeSettingsControlKey,
                    onRuntimeSettingsChanged: onRuntimeSettingsChanged,
                  )
                : BottleOverview(
                    bottle: activeBottle,
                    isLoading: isLoading,
                    errorMessage: errorMessage,
                    onRunProgram: onRunProgram,
                    onRunProgramPath: onRunProgramPath,
                    onPinProgram: onPinProgram,
                    onConfigurePinnedProgram: onConfigurePinnedProgram,
                    onUnpinProgram: onUnpinProgram,
                    onRenamePinnedProgram: onRenamePinnedProgram,
                    onOpenPinnedProgramLocation: onOpenPinnedProgramLocation,
                    onShowBottleConfiguration: onShowBottleConfiguration,
                    onShowBottlePrograms: onShowBottlePrograms,
                  ),
          ),
          if (isProgramConfiguration)
            ProgramConfigurationBottomBar(
              bottle: activeBottle,
              program: activeProgram,
              onOpenPinnedProgramLocation: onOpenPinnedProgramLocation,
              onRunProgramPath: onRunProgramPath,
            )
          else if (isConfiguration)
            BottleConfigurationBottomBar(
              bottle: activeBottle,
              onRunBottleCommand: onRunBottleCommand,
              onOpenBottleLocation: onOpenBottleLocation,
            )
          else
            KonyakBottomBar(
              bottle: activeBottle,
              onRunProgram: onRunProgram,
              onRunBottleCommand: onRunBottleCommand,
              onShowWinetricks: onShowWinetricks,
              onOpenBottleLocation: onOpenBottleLocation,
            ),
        ],
      ),
    );
  }
}
