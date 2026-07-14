import 'package:flutter/material.dart';

import '../../bottles/bottle_summary.dart';
import '../../bottles/invalid_bottle_record.dart';
import '../../l10n/konyak_localizations.dart';
import '../app_constants.dart';
import '../app_platform.dart';
import 'home_contracts.dart';
import 'home_navigation_state.dart';
import 'sidebar_bottle_item.dart';
import 'sidebar_invalid_bottle_item.dart';
import 'sidebar_metrics.dart';

export 'sidebar_bottle_item.dart';
export 'sidebar_slot.dart';

class KonyakSidebar extends StatelessWidget {
  const KonyakSidebar({
    super.key,
    required this.platform,
    required this.reserveLeadingWindowControlsSpace,
    required this.bottles,
    this.invalidBottles = const <InvalidBottleRecord>[],
    required this.selectedBottle,
    required this.searchController,
    required this.onSearchChanged,
    required this.onToggleSidebar,
    required this.bottleSelectionAction,
    required this.onBottleContextMenuAction,
    this.recoveryAction = const UnavailableInvalidBottleRecoveryAction(),
  });

  final KonyakPlatform platform;
  final bool reserveLeadingWindowControlsSpace;
  final List<BottleSummary> bottles;
  final List<InvalidBottleRecord> invalidBottles;
  final HomeNavigationBottleSelection selectedBottle;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onToggleSidebar;
  final BottleSummaryActionAvailability bottleSelectionAction;
  final void Function(BottleSummary bottle, BottleContextMenuAction action)
  onBottleContextMenuAction;
  final InvalidBottleRecoveryActionAvailability recoveryAction;

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);
    final localizations = KonyakLocalizations.of(context);
    final topPadding = sidebarTopPadding(
      reserveLeadingWindowControlsSpace: reserveLeadingWindowControlsSpace,
    );

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
                    tooltip: localizations.toggleSidebar,
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
                        hintText: localizations.search,
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
                localizations.bottles,
                style: TextStyle(color: colors.mutedText, fontSize: 13),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  if (bottles.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        localizations.noBottles,
                        style: TextStyle(color: colors.mutedText, fontSize: 13),
                      ),
                    ),
                  ...bottles.indexed.expand((indexedBottle) {
                    final (index, bottle) = indexedBottle;
                    final isSelected = switch (selectedBottle) {
                      SelectedHomeNavigationBottle(:final bottleId) =>
                        bottle.id == bottleId,
                      NoHomeNavigationBottle() => false,
                    };
                    final resolvedSelectionAction = resolveBottleSummaryAction(
                      bottle: bottle,
                      action: bottleSelectionAction,
                    );

                    return <Widget>[
                      if (index > 0) const SizedBox(height: 6),
                      SidebarBottleItem(
                        platform: platform,
                        bottle: bottle,
                        isSelected: isSelected,
                        onTap: switch (resolvedSelectionAction) {
                          EnabledBottleTargetActionAvailability(
                            :final invoke,
                          ) =>
                            invoke,
                          DisabledBottleTargetActionAvailability() => null,
                        },
                        onContextMenuAction: (action) {
                          onBottleContextMenuAction(bottle, action);
                        },
                      ),
                    ];
                  }),
                  if (invalidBottles.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 18, bottom: 7),
                      child: Text(
                        localizations.bottlesNeedRepair,
                        style: TextStyle(color: colors.mutedText, fontSize: 13),
                      ),
                    ),
                    ...invalidBottles.indexed.expand((indexedBottle) {
                      final (index, invalidBottle) = indexedBottle;
                      final onTap = switch (recoveryAction) {
                        AvailableInvalidBottleRecoveryAction(:final invoke) =>
                          () => invoke(invalidBottle),
                        UnavailableInvalidBottleRecoveryAction() => null,
                      };

                      return <Widget>[
                        if (index > 0) const SizedBox(height: 6),
                        SidebarInvalidBottleItem(
                          invalidBottle: invalidBottle,
                          onTap: onTap,
                        ),
                      ];
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
