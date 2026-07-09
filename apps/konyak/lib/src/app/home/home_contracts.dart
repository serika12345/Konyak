import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../bottles/bottle_summary.dart';
import '../app_platform.dart';
import '../bottles/bottle_action_availability.dart';
import '../bottles/bottle_detail_mode.dart';
import '../bottles/runtime_capabilities_state.dart';
import '../bottles/runtime_settings_change.dart';
import '../bottles/runtime_settings_control_state.dart';
import '../programs/program_configuration_settings.dart';
import '../utils/bottle_lists.dart';
import 'bottle_list_load_state.dart';

export '../bottles/bottle_action_availability.dart';
export '../bottles/bottle_detail_mode.dart';
export '../bottles/runtime_capabilities_state.dart';
export '../bottles/runtime_settings_change.dart';
export '../bottles/runtime_settings_control_state.dart';
export '../programs/program_configuration_settings.dart';
export 'bottle_list_load_state.dart';

part 'home_contracts.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class KonyakHomeActionAvailability with _$KonyakHomeActionAvailability {
  const factory KonyakHomeActionAvailability.unavailable() =
      UnavailableKonyakHomeActionAvailability;

  const factory KonyakHomeActionAvailability.available(VoidCallback invoke) =
      AvailableKonyakHomeActionAvailability;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class KonyakHomeActionDispatch with _$KonyakHomeActionDispatch {
  const factory KonyakHomeActionDispatch.unavailable() =
      UnavailableKonyakHomeActionDispatch;

  const factory KonyakHomeActionDispatch.available(VoidCallback invoke) =
      AvailableKonyakHomeActionDispatch;
}

KonyakHomeActionAvailability homeActionAvailabilityFromNullable(
  VoidCallback? action,
) {
  return switch (action) {
    null => const KonyakHomeActionAvailability.unavailable(),
    final action => KonyakHomeActionAvailability.available(action),
  };
}

KonyakHomeActionDispatch resolveKonyakHomeAction(
  KonyakHomeActionAvailability action,
) {
  return switch (action) {
    AvailableKonyakHomeActionAvailability(:final invoke) =>
      KonyakHomeActionDispatch.available(invoke),
    UnavailableKonyakHomeActionAvailability() =>
      const KonyakHomeActionDispatch.unavailable(),
  };
}

VoidCallback? homeActionCallback(KonyakHomeActionAvailability action) {
  return switch (resolveKonyakHomeAction(action)) {
    AvailableKonyakHomeActionDispatch(:final invoke) => invoke,
    UnavailableKonyakHomeActionDispatch() => null,
  };
}

BottleSummaryActionAvailability resolveHomeSidebarBottleSelectionAction({
  required bool isBottleSelectionLocked,
  required BottleSummaryActionAvailability action,
}) {
  return switch ((isBottleSelectionLocked, action)) {
    (true, _) => const BottleSummaryActionAvailability.unavailable(),
    (false, _) => action,
  };
}

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
    this.refreshAction = const KonyakHomeActionAvailability.unavailable(),
    this.showSettingsAction = const KonyakHomeActionAvailability.unavailable(),
    this.showAboutAction = const KonyakHomeActionAvailability.unavailable(),
    this.checkKonyakUpdatesAction =
        const KonyakHomeActionAvailability.unavailable(),
    this.createBottleAction = const KonyakHomeActionAvailability.unavailable(),
    this.importBottleArchiveAction =
        const KonyakHomeActionAvailability.unavailable(),
    this.reinstallRuntimeAction =
        const KonyakHomeActionAvailability.unavailable(),
    this.viewLatestLogAction = const KonyakHomeActionAvailability.unavailable(),
    this.showProcessManagerAction =
        const KonyakHomeActionAvailability.unavailable(),
  });

  final KonyakHomeActionAvailability refreshAction;
  final KonyakHomeActionAvailability showSettingsAction;
  final KonyakHomeActionAvailability showAboutAction;
  final KonyakHomeActionAvailability checkKonyakUpdatesAction;
  final KonyakHomeActionAvailability createBottleAction;
  final KonyakHomeActionAvailability importBottleArchiveAction;
  final KonyakHomeActionAvailability reinstallRuntimeAction;
  final KonyakHomeActionAvailability viewLatestLogAction;
  final KonyakHomeActionAvailability showProcessManagerAction;
}

final class KonyakBottleActions {
  const KonyakBottleActions({
    this.loadConfigurationAction =
        const BottleSummaryActionAvailability.unavailable(),
    this.deleteAction = const BottleSummaryActionAvailability.unavailable(),
    this.renameAction = const BottleSummaryActionAvailability.unavailable(),
    this.moveAction = const BottleSummaryActionAvailability.unavailable(),
    this.exportArchiveAction =
        const BottleSummaryActionAvailability.unavailable(),
    this.runtimeSettingsChangeAction =
        const RuntimeSettingsChangeAvailability.unavailable(),
    this.openLocationAction =
        const BottleLocationActionAvailability.unavailable(),
    this.showProgramsAction =
        const BottleSummaryActionAvailability.unavailable(),
    this.terminateProcessesAction =
        const BottleSummaryActionAvailability.unavailable(),
  });

  final BottleSummaryActionAvailability loadConfigurationAction;
  final BottleSummaryActionAvailability deleteAction;
  final BottleSummaryActionAvailability renameAction;
  final BottleSummaryActionAvailability moveAction;
  final BottleSummaryActionAvailability exportArchiveAction;
  final RuntimeSettingsChangeAvailability runtimeSettingsChangeAction;
  final BottleLocationActionAvailability openLocationAction;
  final BottleSummaryActionAvailability showProgramsAction;
  final BottleSummaryActionAvailability terminateProcessesAction;
}

final class KonyakProgramActions {
  const KonyakProgramActions({
    this.runProgramAction = const BottleSummaryActionAvailability.unavailable(),
    this.installSteamProfileAction =
        const BottleSummaryActionAvailability.unavailable(),
    this.runProgramPathAction =
        const ProgramPathActionAvailability.unavailable(),
    this.pinProgramAction = const BottleSummaryActionAvailability.unavailable(),
    this.loadPinnedProgramSettingsAction =
        const PinnedProgramActionAvailability.unavailable(),
    this.programSettingsChangeAction =
        const ProgramSettingsChangeAvailability.unavailable(),
    this.unpinProgramAction =
        const PinnedProgramActionAvailability.unavailable(),
    this.renamePinnedProgramAction =
        const PinnedProgramActionAvailability.unavailable(),
    this.openPinnedProgramLocationAction =
        const PinnedProgramActionAvailability.unavailable(),
  });

  final BottleSummaryActionAvailability runProgramAction;
  final BottleSummaryActionAvailability installSteamProfileAction;
  final ProgramPathActionAvailability runProgramPathAction;
  final BottleSummaryActionAvailability pinProgramAction;
  final PinnedProgramActionAvailability loadPinnedProgramSettingsAction;
  final ProgramSettingsChangeAvailability programSettingsChangeAction;
  final PinnedProgramActionAvailability unpinProgramAction;
  final PinnedProgramActionAvailability renamePinnedProgramAction;
  final PinnedProgramActionAvailability openPinnedProgramLocationAction;
}

final class KonyakWinetricksActions {
  const KonyakWinetricksActions({
    this.runBottleCommandAction =
        const BottleCommandActionAvailability.unavailable(),
    this.showWinetricksAction =
        const BottleSummaryActionAvailability.unavailable(),
  });

  final BottleCommandActionAvailability runBottleCommandAction;
  final BottleSummaryActionAvailability showWinetricksAction;
}

final class KonyakHomeNavigationActions {
  const KonyakHomeNavigationActions({
    required this.onBackToBottle,
    required this.onShowBottleConfiguration,
    required this.onConfigurePinnedProgram,
  });

  final VoidCallback onBackToBottle;
  final ValueChanged<BottleSummary> onShowBottleConfiguration;
  final PinnedProgramAction onConfigurePinnedProgram;
}
