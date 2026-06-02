import 'package:flutter/material.dart';

import '../../bottles/bottle_summary.dart';
import '../../runtimes/runtime_summary.dart';
import '../app_platform.dart';
import '../bottles/bottle_detail.dart';
import '../bottles/runtime_settings_change.dart';
import '../utils/bottle_lists.dart';

class KonyakHomeDetailPane extends StatelessWidget {
  const KonyakHomeDetailPane({
    super.key,
    required this.platform,
    required this.runtime,
    required this.bottle,
    required this.isLoading,
    required this.errorMessage,
    required this.detailMode,
    required this.selectedProgram,
    required this.programSettings,
    required this.loadingProgramSettings,
    required this.isRuntimeCapabilitiesLoading,
    required this.pendingRuntimeSettingsControlKey,
    required this.isBottleNavigationLocked,
    required this.onRefresh,
    required this.onShowSettings,
    required this.onCreateBottle,
    required this.onViewLatestLog,
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
  final BottleDetailMode detailMode;
  final PinnedProgramSummary? selectedProgram;
  final Map<String, ProgramSettingsSummary> programSettings;
  final Set<String> loadingProgramSettings;
  final bool isRuntimeCapabilitiesLoading;
  final String? pendingRuntimeSettingsControlKey;
  final bool isBottleNavigationLocked;
  final VoidCallback? onRefresh;
  final VoidCallback? onShowSettings;
  final VoidCallback? onCreateBottle;
  final VoidCallback? onViewLatestLog;
  final VoidCallback onBackToBottle;
  final ValueChanged<BottleSummary> onShowBottleConfiguration;
  final RuntimeSettingsChanged? onRuntimeSettingsChanged;
  final ValueChanged<BottleSummary>? onDeleteBottle;
  final ValueChanged<BottleSummary>? onRunProgram;
  final void Function(BottleSummary bottle, String programPath)?
  onRunProgramPath;
  final ValueChanged<BottleSummary>? onPinProgram;
  final void Function(BottleSummary bottle, PinnedProgramSummary program)
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
    return KonyakBottleDetail(
      platform: platform,
      runtime: runtime,
      bottle: bottle,
      isLoading: isLoading,
      errorMessage: errorMessage,
      onRefresh: onRefresh,
      onShowSettings: onShowSettings,
      onCreateBottle: onCreateBottle,
      onViewLatestLog: onViewLatestLog,
      detailMode: detailMode,
      selectedProgram: selectedProgram,
      programSettings: _selectedProgramSettings,
      isProgramSettingsLoading: _isSelectedProgramSettingsLoading,
      isRuntimeCapabilitiesLoading: isRuntimeCapabilitiesLoading,
      pendingRuntimeSettingsControlKey: pendingRuntimeSettingsControlKey,
      onBackToBottle: isBottleNavigationLocked ? null : onBackToBottle,
      onShowBottleConfiguration: onShowBottleConfiguration,
      onRuntimeSettingsChanged: onRuntimeSettingsChanged,
      onDeleteBottle: onDeleteBottle,
      onRunProgram: onRunProgram,
      onRunProgramPath: onRunProgramPath,
      onPinProgram: onPinProgram,
      onConfigurePinnedProgram: onConfigurePinnedProgram,
      onProgramSettingsChanged: onProgramSettingsChanged,
      onUnpinProgram: onUnpinProgram,
      onRenamePinnedProgram: onRenamePinnedProgram,
      onOpenPinnedProgramLocation: onOpenPinnedProgramLocation,
      onRunBottleCommand: onRunBottleCommand,
      onShowWinetricks: onShowWinetricks,
      onOpenBottleLocation: onOpenBottleLocation,
      onShowBottlePrograms: onShowBottlePrograms,
      onShowProcessManager: onShowProcessManager,
    );
  }

  ProgramSettingsSummary? get _selectedProgramSettings {
    final selectedBottle = bottle;
    final program = selectedProgram;
    if (selectedBottle == null || program == null) {
      return null;
    }

    return programSettings[programSettingsKey(
      bottleId: selectedBottle.id,
      programPath: program.path,
    )];
  }

  bool get _isSelectedProgramSettingsLoading {
    final selectedBottle = bottle;
    final program = selectedProgram;
    if (selectedBottle == null || program == null) {
      return false;
    }

    return loadingProgramSettings.contains(
      programSettingsKey(
        bottleId: selectedBottle.id,
        programPath: program.path,
      ),
    );
  }
}
