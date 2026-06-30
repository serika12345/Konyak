import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../l10n/konyak_localizations.dart';
import '../app_constants.dart';
import '../app_platform.dart';
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

PinnedProgramContextMenuDecision pinnedProgramContextMenuDecisionFromNullable(
  PinnedProgramContextMenuAction? action,
) {
  return switch (action) {
    final PinnedProgramContextMenuAction action =>
      PinnedProgramContextMenuDecision.select(action),
    null => const PinnedProgramContextMenuDecision.cancelled(),
  };
}

List<PopupMenuEntry<PinnedProgramContextMenuAction>>
pinnedProgramContextMenuItems(
  KonyakThemeColors colors,
  KonyakPlatform platform,
  KonyakLocalizations localizations,
) {
  return [
    PopupMenuItem<PinnedProgramContextMenuAction>(
      value: PinnedProgramContextMenuAction.run,
      height: 36,
      child: BottleContextMenuItem(
        key: const ValueKey('pinned-program-context-run'),
        icon: Icons.play_arrow_outlined,
        label: localizations.runEllipsis,
      ),
    ),
    const PopupMenuDivider(height: 8),
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
    PopupMenuItem<PinnedProgramContextMenuAction>(
      value: PinnedProgramContextMenuAction.config,
      height: 36,
      child: BottleContextMenuItem(
        key: const ValueKey('pinned-program-context-config'),
        icon: Icons.settings_outlined,
        label: localizations.config,
      ),
    ),
    PopupMenuItem<PinnedProgramContextMenuAction>(
      value: PinnedProgramContextMenuAction.unpin,
      height: 36,
      child: BottleContextMenuItem(
        key: const ValueKey('pinned-program-context-unpin'),
        icon: Icons.push_pin_outlined,
        label: localizations.unpin,
      ),
    ),
    const PopupMenuDivider(height: 8),
    PopupMenuItem<PinnedProgramContextMenuAction>(
      value: PinnedProgramContextMenuAction.rename,
      height: 36,
      child: BottleContextMenuItem(
        key: const ValueKey('pinned-program-context-rename'),
        icon: Icons.edit_outlined,
        label: localizations.renameEllipsis,
      ),
    ),
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
