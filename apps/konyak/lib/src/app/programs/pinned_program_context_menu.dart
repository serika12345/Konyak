import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../l10n/konyak_localizations.dart';
import '../app_constants.dart';
import '../app_platform.dart';
import '../bottles/bottle_action_availability.dart';
import '../home/sidebar.dart';

part 'pinned_program_context_menu.freezed.dart';

enum PinnedProgramContextMenuAction { run, config, unpin, rename, showInFinder }

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class PinnedProgramContextMenuDecision
    with _$PinnedProgramContextMenuDecision {
  const factory PinnedProgramContextMenuDecision.select(
    PinnedProgramContextMenuAction action,
  ) = SelectedPinnedProgramContextMenuAction;

  const factory PinnedProgramContextMenuDecision.cancelled() =
      CancelledPinnedProgramContextMenu;
}

List<PinnedProgramContextMenuAction>
pinnedProgramContextMenuActionsFromAvailability({
  required ProgramPathActionAvailability runProgramPathAction,
  required PinnedProgramActionAvailability configurePinnedProgramAction,
  required PinnedProgramActionAvailability unpinProgramAction,
  required PinnedProgramActionAvailability renamePinnedProgramAction,
  required PinnedProgramActionAvailability openPinnedProgramLocationAction,
}) {
  return [
    ...switch (runProgramPathAction) {
      AvailableProgramPathActionAvailability() => const [
        PinnedProgramContextMenuAction.run,
      ],
      UnavailableProgramPathActionAvailability() =>
        const <PinnedProgramContextMenuAction>[],
    },
    ...switch (configurePinnedProgramAction) {
      AvailablePinnedProgramActionAvailability() => const [
        PinnedProgramContextMenuAction.config,
      ],
      UnavailablePinnedProgramActionAvailability() =>
        const <PinnedProgramContextMenuAction>[],
    },
    ...switch (unpinProgramAction) {
      AvailablePinnedProgramActionAvailability() => const [
        PinnedProgramContextMenuAction.unpin,
      ],
      UnavailablePinnedProgramActionAvailability() =>
        const <PinnedProgramContextMenuAction>[],
    },
    ...switch (renamePinnedProgramAction) {
      AvailablePinnedProgramActionAvailability() => const [
        PinnedProgramContextMenuAction.rename,
      ],
      UnavailablePinnedProgramActionAvailability() =>
        const <PinnedProgramContextMenuAction>[],
    },
    ...switch (openPinnedProgramLocationAction) {
      AvailablePinnedProgramActionAvailability() => const [
        PinnedProgramContextMenuAction.showInFinder,
      ],
      UnavailablePinnedProgramActionAvailability() =>
        const <PinnedProgramContextMenuAction>[],
    },
  ];
}

List<PopupMenuEntry<PinnedProgramContextMenuAction>>
pinnedProgramContextMenuItems(
  KonyakThemeColors colors,
  KonyakPlatform platform,
  KonyakLocalizations localizations, {
  Iterable<PinnedProgramContextMenuAction> availableActions =
      PinnedProgramContextMenuAction.values,
}) {
  final actionSet = Set<PinnedProgramContextMenuAction>.unmodifiable(
    availableActions,
  );
  final hasRunAction = actionSet.contains(PinnedProgramContextMenuAction.run);
  final hasSettingsActions =
      actionSet.contains(PinnedProgramContextMenuAction.config) ||
      actionSet.contains(PinnedProgramContextMenuAction.unpin);
  final hasManagementActions =
      actionSet.contains(PinnedProgramContextMenuAction.rename) ||
      actionSet.contains(PinnedProgramContextMenuAction.showInFinder);

  return [
    if (hasRunAction)
      PopupMenuItem<PinnedProgramContextMenuAction>(
        value: PinnedProgramContextMenuAction.run,
        height: 36,
        child: BottleContextMenuItem(
          key: const ValueKey('pinned-program-context-run'),
          icon: Icons.play_arrow_outlined,
          label: localizations.runEllipsis,
        ),
      ),
    if (hasRunAction && (hasSettingsActions || hasManagementActions))
      const PopupMenuDivider(height: 8),
    if (hasSettingsActions)
      PopupMenuItem<PinnedProgramContextMenuAction>(
        enabled: false,
        height: 28,
        child: Text(
          localizations.settings,
          key: const ValueKey('pinned-program-context-settings-header'),
          style: TextStyle(
            color: colors.mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    if (actionSet.contains(PinnedProgramContextMenuAction.config))
      PopupMenuItem<PinnedProgramContextMenuAction>(
        value: PinnedProgramContextMenuAction.config,
        height: 36,
        child: BottleContextMenuItem(
          key: const ValueKey('pinned-program-context-config'),
          icon: Icons.settings_outlined,
          label: localizations.config,
        ),
      ),
    if (actionSet.contains(PinnedProgramContextMenuAction.unpin))
      PopupMenuItem<PinnedProgramContextMenuAction>(
        value: PinnedProgramContextMenuAction.unpin,
        height: 36,
        child: BottleContextMenuItem(
          key: const ValueKey('pinned-program-context-unpin'),
          icon: Icons.push_pin_outlined,
          label: localizations.unpin,
        ),
      ),
    if (hasSettingsActions && hasManagementActions)
      const PopupMenuDivider(height: 8),
    if (actionSet.contains(PinnedProgramContextMenuAction.rename))
      PopupMenuItem<PinnedProgramContextMenuAction>(
        value: PinnedProgramContextMenuAction.rename,
        height: 36,
        child: BottleContextMenuItem(
          key: const ValueKey('pinned-program-context-rename'),
          icon: Icons.edit_outlined,
          label: localizations.renameEllipsis,
        ),
      ),
    if (actionSet.contains(PinnedProgramContextMenuAction.showInFinder))
      PopupMenuItem<PinnedProgramContextMenuAction>(
        value: PinnedProgramContextMenuAction.showInFinder,
        height: 36,
        child: BottleContextMenuItem(
          key: const ValueKey('pinned-program-context-show-in-finder'),
          icon: Icons.folder_outlined,
          label: localizedShowInFileManagerLabel(localizations, platform),
        ),
      ),
  ];
}
