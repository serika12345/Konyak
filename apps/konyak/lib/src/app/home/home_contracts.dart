import 'package:flutter/material.dart';

import '../../bottles/bottle_summary.dart';
import '../app_platform.dart';
import '../bottles/bottle_detail_mode.dart';
import '../bottles/runtime_capabilities_state.dart';
import '../bottles/runtime_settings_change.dart';
import '../bottles/runtime_settings_control_state.dart';
import '../programs/program_configuration_settings.dart';
import '../utils/bottle_lists.dart';
import 'bottle_list_load_state.dart';

export '../bottles/bottle_detail_mode.dart';
export '../bottles/runtime_capabilities_state.dart';
export '../bottles/runtime_settings_control_state.dart';
export '../programs/program_configuration_settings.dart';
export 'bottle_list_load_state.dart';

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
    this.runtimeCapabilitiesState =
        const RuntimeCapabilitiesState.unavailable(),
    Iterable<BottleSummary> bottles = const <BottleSummary>[],
    this.bottleListLoadState = const BottleListLoadState.loaded(),
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
  final RuntimeCapabilitiesState runtimeCapabilitiesState;
  final List<BottleSummary> bottles;
  final BottleListLoadState bottleListLoadState;
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
      runtimeCapabilitiesState: runtimeCapabilitiesState,
      bottle: bottle,
      bottleListLoadState: bottleListLoadState,
      detailMode: detailMode,
      selectedProgram: selectedProgram,
      programConfigurationSettingsState:
          programConfigurationSettingsStateFromNullable(
            settings: _programSettingsFor(bottle, selectedProgram),
            isLoading: _isProgramSettingsLoadingFor(bottle, selectedProgram),
          ),
      runtimeSettingsControlState: _runtimeSettingsControlStateFor(bottle),
      isBottleNavigationLocked: isBottleNavigationLocked,
    );
  }

  RuntimeSettingsControlState _runtimeSettingsControlStateFor(
    BottleSummary? bottle,
  ) {
    final controlKey = switch (bottle) {
      BottleSummary(:final id) => pendingRuntimeSettingsControls[id],
      _ => null,
    };

    return switch (controlKey) {
      final String controlKey => RuntimeSettingsControlState.updating(
        controlKey,
      ),
      _ => const RuntimeSettingsControlState.idle(),
    };
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
    required this.runtimeCapabilitiesState,
    required this.bottle,
    required this.bottleListLoadState,
    required this.detailMode,
    required this.selectedProgram,
    required this.programConfigurationSettingsState,
    required this.runtimeSettingsControlState,
    required this.isBottleNavigationLocked,
  });

  final KonyakPlatform platform;
  final RuntimeCapabilitiesState runtimeCapabilitiesState;
  final BottleSummary? bottle;
  final BottleListLoadState bottleListLoadState;
  final BottleDetailMode detailMode;
  final PinnedProgramSummary? selectedProgram;
  final ProgramConfigurationSettingsState programConfigurationSettingsState;
  final RuntimeSettingsControlState runtimeSettingsControlState;
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
