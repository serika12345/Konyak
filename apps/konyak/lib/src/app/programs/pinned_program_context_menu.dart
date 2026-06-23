import 'package:flutter/material.dart';

import '../app_constants.dart';
import '../app_platform.dart';
import '../home/sidebar.dart';

enum PinnedProgramContextMenuAction { run, config, unpin, rename, showInFinder }

List<PopupMenuEntry<PinnedProgramContextMenuAction>>
pinnedProgramContextMenuItems(
  KonyakThemeColors colors,
  KonyakPlatform platform,
) {
  return [
    const PopupMenuItem<PinnedProgramContextMenuAction>(
      value: PinnedProgramContextMenuAction.run,
      height: 36,
      child: BottleContextMenuItem(
        key: ValueKey('pinned-program-context-run'),
        icon: Icons.play_arrow_outlined,
        label: 'Run...',
      ),
    ),
    const PopupMenuDivider(height: 8),
    PopupMenuItem<PinnedProgramContextMenuAction>(
      enabled: false,
      height: 28,
      child: Text(
        'Settings',
        key: const ValueKey('pinned-program-context-settings-header'),
        style: TextStyle(
          color: colors.mutedText,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    const PopupMenuItem<PinnedProgramContextMenuAction>(
      value: PinnedProgramContextMenuAction.config,
      height: 36,
      child: BottleContextMenuItem(
        key: ValueKey('pinned-program-context-config'),
        icon: Icons.settings_outlined,
        label: 'Config',
      ),
    ),
    const PopupMenuItem<PinnedProgramContextMenuAction>(
      value: PinnedProgramContextMenuAction.unpin,
      height: 36,
      child: BottleContextMenuItem(
        key: ValueKey('pinned-program-context-unpin'),
        icon: Icons.push_pin_outlined,
        label: 'Unpin',
      ),
    ),
    const PopupMenuDivider(height: 8),
    const PopupMenuItem<PinnedProgramContextMenuAction>(
      value: PinnedProgramContextMenuAction.rename,
      height: 36,
      child: BottleContextMenuItem(
        key: ValueKey('pinned-program-context-rename'),
        icon: Icons.edit_outlined,
        label: 'Rename...',
      ),
    ),
    PopupMenuItem<PinnedProgramContextMenuAction>(
      value: PinnedProgramContextMenuAction.showInFinder,
      height: 36,
      child: BottleContextMenuItem(
        key: const ValueKey('pinned-program-context-show-in-finder'),
        icon: Icons.folder_outlined,
        label: platform.showInFileManagerLabel,
      ),
    ),
  ];
}
