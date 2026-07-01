import 'package:flutter/material.dart';

import '../../bottles/bottle_summary.dart';
import '../app_platform.dart';
import 'home_contracts.dart';
import 'home_navigation_state.dart';
import 'sidebar.dart';

class KonyakHomeSidebarPane extends StatelessWidget {
  const KonyakHomeSidebarPane({
    super.key,
    required this.platform,
    required this.bottles,
    required this.selectedBottle,
    required this.searchController,
    required this.isExpanded,
    required this.showExpandedContent,
    required this.isBottleSelectionLocked,
    required this.onSearchChanged,
    required this.onAnimationEnd,
    required this.onToggleSidebar,
    required this.bottleSelectionAction,
    required this.onBottleContextMenuAction,
  });

  final KonyakPlatform platform;
  final List<BottleSummary> bottles;
  final HomeNavigationBottleSelection selectedBottle;
  final TextEditingController searchController;
  final bool isExpanded;
  final bool showExpandedContent;
  final bool isBottleSelectionLocked;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAnimationEnd;
  final VoidCallback onToggleSidebar;
  final BottleSummaryActionAvailability bottleSelectionAction;
  final void Function(BottleSummary bottle, BottleContextMenuAction action)
  onBottleContextMenuAction;

  @override
  Widget build(BuildContext context) {
    return AnimatedSidebarSlot(
      isExpanded: isExpanded,
      showExpandedContent: showExpandedContent,
      onAnimationEnd: onAnimationEnd,
      expandedSidebar: KonyakSidebar(
        platform: platform,
        reserveLeadingWindowControlsSpace: platform.isMacOS,
        bottles: bottles,
        selectedBottle: selectedBottle,
        searchController: searchController,
        onSearchChanged: onSearchChanged,
        onToggleSidebar: onToggleSidebar,
        bottleSelectionAction: resolveHomeSidebarBottleSelectionAction(
          isBottleSelectionLocked: isBottleSelectionLocked,
          action: bottleSelectionAction,
        ),
        onBottleContextMenuAction: onBottleContextMenuAction,
      ),
      collapsedSidebar: CollapsedSidebarToggle(
        reserveLeadingWindowControlsSpace: platform.isMacOS,
        onToggleSidebar: onToggleSidebar,
      ),
    );
  }
}
