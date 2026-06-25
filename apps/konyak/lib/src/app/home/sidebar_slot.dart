import 'package:flutter/material.dart';

import '../../l10n/konyak_localizations.dart';
import '../app_constants.dart';
import 'sidebar_metrics.dart';

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
    final topPadding = sidebarTopPadding(
      reserveLeadingWindowControlsSpace: reserveLeadingWindowControlsSpace,
    );

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
              tooltip: KonyakLocalizations.of(context).text('Toggle sidebar'),
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
