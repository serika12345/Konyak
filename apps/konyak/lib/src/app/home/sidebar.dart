import 'package:flutter/material.dart';

import '../../bottles/bottle_summary.dart';
import '../app_constants.dart';

const _defaultSidebarTopPadding = 12.0;
const _sidebarTopPaddingWithWindowControls = 52.0;

class AnimatedSidebarSlot extends StatelessWidget {
  const AnimatedSidebarSlot({
    super.key,
    required this.isExpanded,
    required this.showExpandedContent,
    required this.onAnimationEnd,
    required this.expandedSidebar,
    required this.collapsedSidebar,
  });

  final bool isExpanded;
  final bool showExpandedContent;
  final VoidCallback onAnimationEnd;
  final Widget expandedSidebar;
  final Widget collapsedSidebar;

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);

    return AnimatedContainer(
      key: const ValueKey('sidebar-slot'),
      duration: sidebarAnimationDuration,
      curve: sidebarAnimationCurve,
      width: isExpanded ? sidebarExpandedWidth : sidebarCollapsedWidth,
      decoration: BoxDecoration(color: colors.sidebarBackground),
      clipBehavior: Clip.hardEdge,
      onEnd: onAnimationEnd,
      child: showExpandedContent
          ? OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: sidebarExpandedWidth,
              maxWidth: sidebarExpandedWidth,
              child: expandedSidebar,
            )
          : collapsedSidebar,
    );
  }
}

class KonyakSidebar extends StatelessWidget {
  const KonyakSidebar({
    super.key,
    required this.reserveLeadingWindowControlsSpace,
    required this.bottles,
    required this.selectedBottleId,
    required this.searchController,
    required this.onSearchChanged,
    required this.onToggleSidebar,
    required this.onBottleSelected,
    required this.onBottleContextMenuAction,
  });

  final bool reserveLeadingWindowControlsSpace;
  final List<BottleSummary> bottles;
  final String? selectedBottleId;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onToggleSidebar;
  final ValueChanged<BottleSummary> onBottleSelected;
  final void Function(BottleSummary bottle, BottleContextMenuAction action)
  onBottleContextMenuAction;

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);
    final topPadding = reserveLeadingWindowControlsSpace
        ? _sidebarTopPaddingWithWindowControls
        : _defaultSidebarTopPadding;

    return Container(
      width: sidebarExpandedWidth,
      color: colors.sidebarBackground,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(10, topPadding, 10, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Toggle sidebar',
                    onPressed: onToggleSidebar,
                    color: colors.sidebarIcon,
                    iconSize: 20,
                    constraints: const BoxConstraints.tightFor(
                      width: 34,
                      height: 34,
                    ),
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.view_sidebar_outlined),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onChanged: onSearchChanged,
                      style: TextStyle(color: colors.text, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search',
                        hintStyle: TextStyle(
                          color: colors.mutedText,
                          fontSize: 13,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: colors.text,
                          size: 18,
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        isDense: true,
                        filled: true,
                        fillColor: colors.sidebarSearchBackground,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 7,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: colors.sidebarSearchBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: colors.mutedText),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 16, 10, 7),
              child: Text(
                'Bottles',
                style: TextStyle(color: colors.mutedText, fontSize: 13),
              ),
            ),
            Expanded(
              child: bottles.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        'No Bottles',
                        style: TextStyle(color: colors.mutedText, fontSize: 13),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount: bottles.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final bottle = bottles[index];
                        final isSelected = bottle.id == selectedBottleId;

                        return SidebarBottleItem(
                          bottle: bottle,
                          isSelected: isSelected,
                          onTap: () => onBottleSelected(bottle),
                          onContextMenuAction: (action) {
                            onBottleContextMenuAction(bottle, action);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class CollapsedSidebarToggle extends StatelessWidget {
  const CollapsedSidebarToggle({
    super.key,
    required this.reserveLeadingWindowControlsSpace,
    required this.onToggleSidebar,
  });

  final bool reserveLeadingWindowControlsSpace;
  final VoidCallback onToggleSidebar;

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);
    final topPadding = reserveLeadingWindowControlsSpace
        ? _sidebarTopPaddingWithWindowControls
        : _defaultSidebarTopPadding;

    return Container(
      width: sidebarCollapsedWidth,
      color: colors.sidebarBackground,
      child: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.only(top: topPadding),
            child: IconButton(
              tooltip: 'Toggle sidebar',
              onPressed: onToggleSidebar,
              color: colors.sidebarIcon,
              iconSize: 20,
              constraints: const BoxConstraints.tightFor(width: 34, height: 34),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.view_sidebar_outlined),
            ),
          ),
        ),
      ),
    );
  }
}

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
  final VoidCallback onTap;
  final ValueChanged<BottleContextMenuAction> onContextMenuAction;

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapDown: (details) {
        onTap();
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
    BottleContextMenuAction.showInFinder => 'Show in Finder',
  };
}
