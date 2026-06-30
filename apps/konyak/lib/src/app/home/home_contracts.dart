import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

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

part 'home_contracts.freezed.dart';

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

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class KonyakHomeDetailSelection with _$KonyakHomeDetailSelection {
  const factory KonyakHomeDetailSelection.none() = NoKonyakHomeDetailSelection;

  const factory KonyakHomeDetailSelection.bottle(BottleSummary bottle) =
      SelectedKonyakHomeDetailBottle;

  const factory KonyakHomeDetailSelection.program({
    required BottleSummary bottle,
    required PinnedProgramSummary program,
  }) = SelectedKonyakHomeDetailProgram;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class KonyakHomeDetailContent with _$KonyakHomeDetailContent {
  const factory KonyakHomeDetailContent.empty() = EmptyKonyakHomeDetailContent;

  const factory KonyakHomeDetailContent.overview(BottleSummary bottle) =
      OverviewKonyakHomeDetailContent;

  const factory KonyakHomeDetailContent.configuration(BottleSummary bottle) =
      ConfigurationKonyakHomeDetailContent;

  const factory KonyakHomeDetailContent.program({
    required BottleSummary bottle,
    required PinnedProgramSummary program,
  }) = ProgramKonyakHomeDetailContent;
}

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
    required KonyakHomeDetailSelection selection,
    required BottleDetailMode detailMode,
    required bool isBottleNavigationLocked,
  }) {
    return KonyakHomeDetailState(
      platform: platform,
      runtimeCapabilitiesState: runtimeCapabilitiesState,
      content: _detailContentFor(selection: selection, detailMode: detailMode),
      bottleListLoadState: bottleListLoadState,
      programConfigurationSettingsState: _programConfigurationSettingsStateFor(
        selection,
      ),
      runtimeSettingsControlState: _runtimeSettingsControlStateFor(selection),
      isBottleNavigationLocked: isBottleNavigationLocked,
    );
  }

  RuntimeSettingsControlState _runtimeSettingsControlStateFor(
    KonyakHomeDetailSelection selection,
  ) {
    return switch (selection) {
      NoKonyakHomeDetailSelection() => const RuntimeSettingsControlState.idle(),
      SelectedKonyakHomeDetailBottle(:final bottle) ||
      SelectedKonyakHomeDetailProgram(
        :final bottle,
      ) => _runtimeSettingsControlStateForBottle(bottle),
    };
  }

  RuntimeSettingsControlState _runtimeSettingsControlStateForBottle(
    BottleSummary bottle,
  ) {
    return switch (pendingRuntimeSettingsControls.entries
        .where((entry) => entry.key == bottle.id)
        .map((entry) => entry.value)
        .toList(growable: false)) {
      [final controlKey] => RuntimeSettingsControlState.updating(controlKey),
      _ => const RuntimeSettingsControlState.idle(),
    };
  }

  ProgramConfigurationSettingsState _programConfigurationSettingsStateFor(
    KonyakHomeDetailSelection selection,
  ) {
    return switch (selection) {
      SelectedKonyakHomeDetailProgram(:final bottle, :final program) => () {
        final settingsKey = programSettingsKey(
          bottleId: bottle.id,
          programPath: program.path,
        );

        return programConfigurationSettingsStateFromNullable(
          settings: programSettings[settingsKey],
          isLoading: loadingProgramSettings.contains(settingsKey),
        );
      }(),
      NoKonyakHomeDetailSelection() || SelectedKonyakHomeDetailBottle() =>
        ProgramConfigurationSettingsState.ready(ProgramSettingsSummary()),
    };
  }

  KonyakHomeDetailContent _detailContentFor({
    required KonyakHomeDetailSelection selection,
    required BottleDetailMode detailMode,
  }) {
    return switch ((selection, detailMode)) {
      (
        SelectedKonyakHomeDetailProgram(:final bottle, :final program),
        BottleDetailMode.programConfiguration,
      ) =>
        KonyakHomeDetailContent.program(bottle: bottle, program: program),
      (
        SelectedKonyakHomeDetailBottle(:final bottle),
        BottleDetailMode.configuration,
      ) =>
        KonyakHomeDetailContent.configuration(bottle),
      (
        SelectedKonyakHomeDetailProgram(:final bottle),
        BottleDetailMode.configuration,
      ) =>
        KonyakHomeDetailContent.configuration(bottle),
      (SelectedKonyakHomeDetailBottle(:final bottle), _) =>
        KonyakHomeDetailContent.overview(bottle),
      (SelectedKonyakHomeDetailProgram(:final bottle), _) =>
        KonyakHomeDetailContent.overview(bottle),
      (NoKonyakHomeDetailSelection(), _) =>
        const KonyakHomeDetailContent.empty(),
    };
  }
}

final class KonyakHomeDetailState {
  const KonyakHomeDetailState({
    required this.platform,
    required this.runtimeCapabilitiesState,
    required this.content,
    required this.bottleListLoadState,
    required this.programConfigurationSettingsState,
    required this.runtimeSettingsControlState,
    required this.isBottleNavigationLocked,
  });

  final KonyakPlatform platform;
  final RuntimeCapabilitiesState runtimeCapabilitiesState;
  final KonyakHomeDetailContent content;
  final BottleListLoadState bottleListLoadState;
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
