import 'package:flutter/material.dart';

import '../../bottles/bottle_summary.dart';
import '../app_constants.dart';

class SidebarBottleItem extends StatelessWidget {
  const SidebarBottleItem({
    super.key,
    required this.bottle,
    required this.isSelected,
    required this.onTap,
    required this.onContextMenuAction,
  });

  final BottleSummary bottle;
  final bool isSelected;
  final VoidCallback? onTap;
  final ValueChanged<BottleContextMenuAction> onContextMenuAction;

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapDown: (details) {
        onTap?.call();
        _showBottleContextMenu(context, details.globalPosition);
      },
      child: Material(
        key: ValueKey('sidebar-bottle-${bottle.id}'),
        color: isSelected ? colors.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
            child: Text(
              bottle.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? colors.accentText : colors.text,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showBottleContextMenu(
    BuildContext context,
    Offset globalPosition,
  ) async {
    final selectedAction = await showMenu<BottleContextMenuAction>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        globalPosition.dx,
        globalPosition.dy,
      ),
      color: KonyakThemeColors.of(context).menuBackground,
      popUpAnimationStyle: AnimationStyle.noAnimation,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: KonyakThemeColors.of(context).menuBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 220),
      items: _bottleContextMenuItems,
    );

    if (selectedAction == null) {
      return;
    }

    onContextMenuAction(selectedAction);
  }
}

enum BottleContextMenuAction {
  rename,
  remove,
  move,
  exportArchive,
  terminateProcesses,
  showInFinder,
}

const List<PopupMenuEntry<BottleContextMenuAction>> _bottleContextMenuItems = [
  PopupMenuItem<BottleContextMenuAction>(
    value: BottleContextMenuAction.rename,
    height: 34,
    child: BottleContextMenuItem(icon: Icons.edit_outlined, label: 'Rename...'),
  ),
  PopupMenuItem<BottleContextMenuAction>(
    value: BottleContextMenuAction.remove,
    height: 34,
    child: BottleContextMenuItem(
      icon: Icons.delete_outline,
      label: 'Remove...',
    ),
  ),
  PopupMenuDivider(height: 8),
  PopupMenuItem<BottleContextMenuAction>(
    value: BottleContextMenuAction.move,
    height: 34,
    child: BottleContextMenuItem(
      icon: Icons.drive_file_move_outline,
      label: 'Move...',
    ),
  ),
  PopupMenuItem<BottleContextMenuAction>(
    value: BottleContextMenuAction.exportArchive,
    height: 34,
    child: BottleContextMenuItem(
      icon: Icons.ios_share_outlined,
      label: 'Export as Archive...',
    ),
  ),
  PopupMenuDivider(height: 8),
  PopupMenuItem<BottleContextMenuAction>(
    value: BottleContextMenuAction.terminateProcesses,
    height: 34,
    child: BottleContextMenuItem(
      icon: Icons.stop_circle_outlined,
      label: 'Stop All Processes',
    ),
  ),
  PopupMenuDivider(height: 8),
  PopupMenuItem<BottleContextMenuAction>(
    value: BottleContextMenuAction.showInFinder,
    height: 34,
    child: BottleContextMenuItem(
      icon: Icons.folder_outlined,
      label: 'Show in Finder',
    ),
  ),
];

class BottleContextMenuItem extends StatelessWidget {
  const BottleContextMenuItem({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);

    return SizedBox(
      width: 176,
      child: Row(
        children: [
          Icon(icon, color: colors.text, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(color: colors.text, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

String bottleContextMenuActionLabel(BottleContextMenuAction action) {
  return switch (action) {
    BottleContextMenuAction.rename => 'Rename',
    BottleContextMenuAction.remove => 'Remove',
    BottleContextMenuAction.move => 'Move',
    BottleContextMenuAction.exportArchive => 'Export as Archive',
    BottleContextMenuAction.terminateProcesses => 'Stop All Processes',
    BottleContextMenuAction.showInFinder => 'Show in Finder',
  };
}
