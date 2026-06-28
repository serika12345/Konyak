import 'package:flutter/material.dart';

import '../../bottles/bottle_summary.dart';
import '../../runtimes/runtime_summary.dart';
import '../app_platform.dart';
import '../bottles/bottle_detail_mode.dart';
import '../bottles/runtime_settings_change.dart';
import '../utils/bottle_lists.dart';

export '../bottles/bottle_detail_mode.dart';

typedef KonyakProgramPathAction =
    void Function(BottleSummary bottle, String programPath);
typedef KonyakPinnedProgramAction =
    void Function(BottleSummary bottle, PinnedProgramSummary program);
typedef KonyakProgramSettingsChanged =
    void Function(
      BottleSummary bottle,
      PinnedProgramSummary program,
      ProgramSettingsSummary settings,
    );
typedef KonyakBottleCommandAction =
    void Function(BottleSummary bottle, String command);
typedef KonyakBottleLocationAction =
    void Function(BottleSummary bottle, String location);

final class KonyakHomeViewState {
  KonyakHomeViewState({
    required this.platform,
    this.runtime,
    Iterable<BottleSummary> bottles = const <BottleSummary>[],
    this.isLoading = false,
    this.errorMessage,
    this.isRuntimeCapabilitiesLoading = false,
    Map<String, ProgramSettingsSummary> programSettings =
        const <String, ProgramSettingsSummary>{},
    Set<String> loadingProgramSettings = const <String>{},
    Map<String, String> pendingRuntimeSettingsControls =
        const <String, String>{},
  }) : bottles = List.unmodifiable(bottles),
       programSettings = Map.unmodifiable(programSettings),
       loadingProgramSettings = Set.unmodifiable(loadingProgramSettings),
       pendingRuntimeSettingsControls = Map.unmodifiable(
         pendingRuntimeSettingsControls,
       );

  final KonyakPlatform platform;
  final RuntimeSummary? runtime;
  final List<BottleSummary> bottles;
  final bool isLoading;
  final String? errorMessage;
  final bool isRuntimeCapabilitiesLoading;
  final Map<String, ProgramSettingsSummary> programSettings;
  final Set<String> loadingProgramSettings;
  final Map<String, String> pendingRuntimeSettingsControls;

  Iterable<String> get lockedBottleIds => pendingRuntimeSettingsControls.keys;

  bool hasPendingRuntimeSettingsFor(BottleSummary bottle) {
    return pendingRuntimeSettingsControls.containsKey(bottle.id);
  }

  KonyakHomeDetailState detailStateFor({
    required BottleSummary? bottle,
    required BottleDetailMode detailMode,
    required PinnedProgramSummary? selectedProgram,
    required bool isBottleNavigationLocked,
  }) {
    return KonyakHomeDetailState(
      platform: platform,
      runtime: runtime,
      bottle: bottle,
      isLoading: isLoading,
      errorMessage: errorMessage,
      detailMode: detailMode,
      selectedProgram: selectedProgram,
      programSettings: _programSettingsFor(bottle, selectedProgram),
      isProgramSettingsLoading: _isProgramSettingsLoadingFor(
        bottle,
        selectedProgram,
      ),
      isRuntimeCapabilitiesLoading: isRuntimeCapabilitiesLoading,
      pendingRuntimeSettingsControlKey: bottle == null
          ? null
          : pendingRuntimeSettingsControls[bottle.id],
      isBottleNavigationLocked: isBottleNavigationLocked,
    );
  }

  ProgramSettingsSummary? _programSettingsFor(
    BottleSummary? bottle,
    PinnedProgramSummary? program,
  ) {
    final selectedBottle = bottle;
    final selectedProgram = program;
    if (selectedBottle == null || selectedProgram == null) {
      return null;
    }

    return programSettings[programSettingsKey(
      bottleId: selectedBottle.id,
      programPath: selectedProgram.path,
    )];
  }

  bool _isProgramSettingsLoadingFor(
    BottleSummary? bottle,
    PinnedProgramSummary? program,
  ) {
    final selectedBottle = bottle;
    final selectedProgram = program;
    if (selectedBottle == null || selectedProgram == null) {
      return false;
    }

    return loadingProgramSettings.contains(
      programSettingsKey(
        bottleId: selectedBottle.id,
        programPath: selectedProgram.path,
      ),
    );
  }
}

final class KonyakHomeDetailState {
  const KonyakHomeDetailState({
    required this.platform,
    required this.runtime,
    required this.bottle,
    required this.isLoading,
    required this.errorMessage,
    required this.detailMode,
    required this.selectedProgram,
    required this.programSettings,
    required this.isProgramSettingsLoading,
    required this.isRuntimeCapabilitiesLoading,
    required this.pendingRuntimeSettingsControlKey,
    required this.isBottleNavigationLocked,
  });

  final KonyakPlatform platform;
  final RuntimeSummary? runtime;
  final BottleSummary? bottle;
  final bool isLoading;
  final String? errorMessage;
  final BottleDetailMode detailMode;
  final PinnedProgramSummary? selectedProgram;
  final ProgramSettingsSummary? programSettings;
  final bool isProgramSettingsLoading;
  final bool isRuntimeCapabilitiesLoading;
  final String? pendingRuntimeSettingsControlKey;
  final bool isBottleNavigationLocked;
}

final class KonyakHomeMenuActions {
  const KonyakHomeMenuActions({
    this.onRefresh,
    this.onShowSettings,
    this.onShowAbout,
    this.onCheckKonyakUpdates,
    this.onCreateBottle,
    this.onImportBottleArchive,
    this.onReinstallRuntime,
    this.onViewLatestLog,
    this.onShowProcessManager,
  });

  final VoidCallback? onRefresh;
  final VoidCallback? onShowSettings;
  final VoidCallback? onShowAbout;
  final VoidCallback? onCheckKonyakUpdates;
  final VoidCallback? onCreateBottle;
  final VoidCallback? onImportBottleArchive;
  final VoidCallback? onReinstallRuntime;
  final VoidCallback? onViewLatestLog;
  final VoidCallback? onShowProcessManager;
}

final class KonyakBottleActions {
  const KonyakBottleActions({
    this.onLoadConfiguration,
    this.onDelete,
    this.onRename,
    this.onMove,
    this.onExportArchive,
    this.onRuntimeSettingsChanged,
    this.onOpenLocation,
    this.onShowPrograms,
    this.onTerminateProcesses,
  });

  final ValueChanged<BottleSummary>? onLoadConfiguration;
  final ValueChanged<BottleSummary>? onDelete;
  final ValueChanged<BottleSummary>? onRename;
  final ValueChanged<BottleSummary>? onMove;
  final ValueChanged<BottleSummary>? onExportArchive;
  final RuntimeSettingsChanged? onRuntimeSettingsChanged;
  final KonyakBottleLocationAction? onOpenLocation;
  final ValueChanged<BottleSummary>? onShowPrograms;
  final ValueChanged<BottleSummary>? onTerminateProcesses;
}

final class KonyakProgramActions {
  const KonyakProgramActions({
    this.onRunProgram,
    this.onRunProgramPath,
    this.onPinProgram,
    this.onLoadPinnedProgramSettings,
    this.onProgramSettingsChanged,
    this.onUnpinProgram,
    this.onRenamePinnedProgram,
    this.onOpenPinnedProgramLocation,
  });

  final ValueChanged<BottleSummary>? onRunProgram;
  final KonyakProgramPathAction? onRunProgramPath;
  final ValueChanged<BottleSummary>? onPinProgram;
  final KonyakPinnedProgramAction? onLoadPinnedProgramSettings;
  final KonyakProgramSettingsChanged? onProgramSettingsChanged;
  final KonyakPinnedProgramAction? onUnpinProgram;
  final KonyakPinnedProgramAction? onRenamePinnedProgram;
  final KonyakPinnedProgramAction? onOpenPinnedProgramLocation;
}

final class KonyakWinetricksActions {
  const KonyakWinetricksActions({
    this.onRunBottleCommand,
    this.onShowWinetricks,
  });

  final KonyakBottleCommandAction? onRunBottleCommand;
  final ValueChanged<BottleSummary>? onShowWinetricks;
}

final class KonyakHomeNavigationActions {
  const KonyakHomeNavigationActions({
    required this.onBackToBottle,
    required this.onShowBottleConfiguration,
    required this.onConfigurePinnedProgram,
  });

  final VoidCallback onBackToBottle;
  final ValueChanged<BottleSummary> onShowBottleConfiguration;
  final KonyakPinnedProgramAction onConfigurePinnedProgram;
}
