import 'package:flutter/material.dart';

import '../../bottles/bottle_summary.dart';
import '../app_platform.dart';
import 'sidebar.dart';

class KonyakHomeSidebarPane extends StatelessWidget {
  const KonyakHomeSidebarPane({
    super.key,
    required this.platform,
    required this.bottles,
    required this.selectedBottleId,
    required this.searchController,
    required this.isExpanded,
    required this.showExpandedContent,
    required this.isBottleSelectionLocked,
    required this.onSearchChanged,
    required this.onAnimationEnd,
    required this.onToggleSidebar,
    required this.onBottleSelected,
    required this.onBottleContextMenuAction,
  });

  final KonyakPlatform platform;
  final List<BottleSummary> bottles;
  final String? selectedBottleId;
  final TextEditingController searchController;
  final bool isExpanded;
  final bool showExpandedContent;
  final bool isBottleSelectionLocked;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAnimationEnd;
  final VoidCallback onToggleSidebar;
  final ValueChanged<BottleSummary> onBottleSelected;
  final void Function(BottleSummary bottle, BottleContextMenuAction action)
  onBottleContextMenuAction;

  @override
  Widget build(BuildContext context) {
    return AnimatedSidebarSlot(
      isExpanded: isExpanded,
      showExpandedContent: showExpandedContent,
      onAnimationEnd: onAnimationEnd,
      expandedSidebar: KonyakSidebar(
        reserveLeadingWindowControlsSpace: platform.isMacOS,
        bottles: bottles,
        selectedBottleId: selectedBottleId,
        searchController: searchController,
        onSearchChanged: onSearchChanged,
        onToggleSidebar: onToggleSidebar,
        onBottleSelected: isBottleSelectionLocked ? null : onBottleSelected,
        onBottleContextMenuAction: onBottleContextMenuAction,
      ),
      collapsedSidebar: CollapsedSidebarToggle(
        reserveLeadingWindowControlsSpace: platform.isMacOS,
        onToggleSidebar: onToggleSidebar,
      ),
    );
  }
}
