import 'package:flutter/material.dart';

import '../../bottles/bottle_summary.dart';
import '../app_constants.dart';
import '../utils/bottle_lists.dart';
import 'home_contracts.dart';
import 'home_detail_pane.dart';
import 'home_menu_bar.dart';
import 'home_navigation_state.dart';
import 'home_sidebar_pane.dart';
import 'sidebar.dart';

class KonyakHome extends StatefulWidget {
  const KonyakHome({
    super.key,
    required this.state,
    this.menuActions = const KonyakHomeMenuActions(),
    this.bottleActions = const KonyakBottleActions(),
    this.programActions = const KonyakProgramActions(),
    this.winetricksActions = const KonyakWinetricksActions(),
  });

  final KonyakHomeViewState state;
  final KonyakHomeMenuActions menuActions;
  final KonyakBottleActions bottleActions;
  final KonyakProgramActions programActions;
  final KonyakWinetricksActions winetricksActions;

  @override
  State<KonyakHome> createState() => _KonyakHomeState();
}

class _KonyakHomeState extends State<KonyakHome> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSidebarVisible = true;
  bool _showExpandedSidebarContent = true;
  KonyakHomeNavigationState _navigationState =
      const KonyakHomeNavigationState();

  @override
  void didUpdateWidget(covariant KonyakHome oldWidget) {
    super.didUpdateWidget(oldWidget);

    final nextNavigationState = _navigationState.reconcile(
      widget.state.bottles,
    );
    if (nextNavigationState != _navigationState) {
      _navigationState = nextNavigationState;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = KonyakThemeColors.of(context);
    final state = widget.state;
    final filteredBottles = filterBottles(
      bottles: state.bottles,
      searchQuery: _searchController.text,
    );
    final selectedBottle =
        _navigationState.selectedBottleIn(filteredBottles) ??
        (filteredBottles.isEmpty ? null : filteredBottles.first);
    final selectedProgram = _navigationState.selectedProgramIn(selectedBottle);
    final selectedBottleHasPendingRuntimeSettings =
        selectedBottle != null &&
        state.hasPendingRuntimeSettingsFor(selectedBottle);

    return Scaffold(
      body: Column(
        children: [
          if (state.platform.isLinux)
            KonyakHomeMenuBar(
              onShowAbout: widget.menuActions.onShowAbout,
              onShowSettings: widget.menuActions.onShowSettings,
              onCheckKonyakUpdates: widget.menuActions.onCheckKonyakUpdates,
              onImportBottleArchive: widget.menuActions.onImportBottleArchive,
              onReinstallRuntime: widget.menuActions.onReinstallRuntime,
            ),
          Expanded(
            child: Row(
              children: [
                KonyakHomeSidebarPane(
                  platform: state.platform,
                  bottles: filteredBottles,
                  selectedBottleId: selectedBottle?.id,
                  searchController: _searchController,
                  isExpanded: _isSidebarVisible,
                  showExpandedContent: _showExpandedSidebarContent,
                  isBottleSelectionLocked:
                      selectedBottleHasPendingRuntimeSettings,
                  onSearchChanged: (_) => setState(() {}),
                  onAnimationEnd: _handleSidebarAnimationEnd,
                  onToggleSidebar: _toggleSidebar,
                  onBottleSelected: _selectBottle,
                  onBottleContextMenuAction: _handleBottleContextMenuAction,
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: colors.strongBorder,
                ),
                Expanded(
                  child: KonyakHomeDetailPane(
                    state: state.detailStateFor(
                      bottle: selectedBottle,
                      detailMode: _navigationState.detailMode,
                      selectedProgram: selectedProgram,
                      isBottleNavigationLocked:
                          selectedBottleHasPendingRuntimeSettings,
                    ),
                    menuActions: widget.menuActions,
                    bottleActions: widget.bottleActions,
                    programActions: widget.programActions,
                    winetricksActions: widget.winetricksActions,
                    navigationActions: KonyakHomeNavigationActions(
                      onBackToBottle: _showBottleOverview,
                      onShowBottleConfiguration: _showBottleConfiguration,
                      onConfigurePinnedProgram: _showPinnedProgramConfiguration,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleSidebar() {
    setState(() {
      if (_isSidebarVisible) {
        _isSidebarVisible = false;
      } else {
        _showExpandedSidebarContent = true;
        _isSidebarVisible = true;
      }
    });
  }

  void _handleSidebarAnimationEnd() {
    if (_isSidebarVisible || !_showExpandedSidebarContent) {
      return;
    }

    setState(() {
      _showExpandedSidebarContent = false;
    });
  }

  void _showBottleConfiguration(BottleSummary bottle) {
    final nextNavigationState = _navigationState.showBottleConfiguration(
      bottle,
      lockedBottleIds: widget.state.lockedBottleIds,
    );
    if (identical(nextNavigationState, _navigationState)) {
      return;
    }
    setState(() {
      _navigationState = nextNavigationState;
    });
    widget.bottleActions.onLoadConfiguration?.call(bottle);
  }

  void _showPinnedProgramConfiguration(
    BottleSummary bottle,
    PinnedProgramSummary program,
  ) {
    final nextNavigationState = _navigationState.showPinnedProgramConfiguration(
      bottle,
      program,
      lockedBottleIds: widget.state.lockedBottleIds,
    );
    if (identical(nextNavigationState, _navigationState)) {
      return;
    }
    setState(() {
      _navigationState = nextNavigationState;
    });
    widget.programActions.onLoadPinnedProgramSettings?.call(bottle, program);
  }

  void _showBottleOverview() {
    final nextNavigationState = _navigationState.showBottleOverview(
      bottles: widget.state.bottles,
      lockedBottleIds: widget.state.lockedBottleIds,
    );
    if (identical(nextNavigationState, _navigationState)) {
      return;
    }
    setState(() {
      _navigationState = nextNavigationState;
    });
  }

  void _selectBottle(BottleSummary bottle) {
    setState(() {
      _navigationState = _navigationState.selectBottle(bottle);
    });
  }

  void _handleBottleContextMenuAction(
    BottleSummary bottle,
    BottleContextMenuAction action,
  ) {
    switch (action) {
      case BottleContextMenuAction.remove:
        widget.bottleActions.onDelete?.call(bottle);
      case BottleContextMenuAction.rename:
        widget.bottleActions.onRename?.call(bottle);
      case BottleContextMenuAction.move:
        widget.bottleActions.onMove?.call(bottle);
      case BottleContextMenuAction.showInFinder:
        widget.bottleActions.onOpenLocation?.call(bottle, 'root');
      case BottleContextMenuAction.exportArchive:
        widget.bottleActions.onExportArchive?.call(bottle);
      case BottleContextMenuAction.terminateProcesses:
        widget.bottleActions.onTerminateProcesses?.call(bottle);
    }
  }
}
