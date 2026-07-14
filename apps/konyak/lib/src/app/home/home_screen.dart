import 'package:flutter/material.dart';

import '../../bottles/bottle_summary.dart';
import '../app_constants.dart';
import '../bottles/bottle_detail.dart';
import '../utils/bottle_lists.dart';
import 'home_contracts.dart';
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
    this.recoveryActions = const KonyakBottleRecoveryActions(),
  });

  final KonyakHomeViewState state;
  final KonyakHomeMenuActions menuActions;
  final KonyakBottleActions bottleActions;
  final KonyakProgramActions programActions;
  final KonyakWinetricksActions winetricksActions;
  final KonyakBottleRecoveryActions recoveryActions;

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
    final detailSelection = _navigationState.detailSelectionIn(filteredBottles);
    final sidebarBottleSelection = _navigationState.sidebarBottleSelectionIn(
      filteredBottles,
    );
    final selectedBottleHasPendingRuntimeSettings = switch (detailSelection) {
      SelectedKonyakHomeDetailBottle(:final bottle) ||
      SelectedKonyakHomeDetailProgram(
        :final bottle,
      ) => state.hasPendingRuntimeSettingsFor(bottle),
      NoKonyakHomeDetailSelection() => false,
    };

    return Scaffold(
      body: Column(
        children: [
          if (state.platform.isLinux)
            KonyakHomeMenuBar(
              showAboutAction: widget.menuActions.showAboutAction,
              showSettingsAction: widget.menuActions.showSettingsAction,
              checkKonyakUpdatesAction:
                  widget.menuActions.checkKonyakUpdatesAction,
              importBottleArchiveAction:
                  widget.menuActions.importBottleArchiveAction,
              reinstallRuntimeAction: widget.menuActions.reinstallRuntimeAction,
            ),
          Expanded(
            child: Row(
              children: [
                KonyakHomeSidebarPane(
                  platform: state.platform,
                  bottles: filteredBottles,
                  invalidBottles: state.invalidBottles,
                  selectedBottle: sidebarBottleSelection,
                  searchController: _searchController,
                  isExpanded: _isSidebarVisible,
                  showExpandedContent: _showExpandedSidebarContent,
                  isBottleSelectionLocked:
                      selectedBottleHasPendingRuntimeSettings,
                  onSearchChanged: (_) => setState(() {}),
                  onAnimationEnd: _handleSidebarAnimationEnd,
                  onToggleSidebar: _toggleSidebar,
                  bottleSelectionAction:
                      BottleSummaryActionAvailability.available(_selectBottle),
                  onBottleContextMenuAction: _handleBottleContextMenuAction,
                  recoveryAction: widget.recoveryActions.showRecoveryAction,
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: colors.strongBorder,
                ),
                Expanded(
                  child: KonyakBottleDetail(
                    state: state.detailStateFor(
                      selection: detailSelection,
                      detailMode: _navigationState.detailMode,
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
    _invokeBottleTargetAction(
      resolveBottleSummaryAction(
        bottle: bottle,
        action: widget.bottleActions.loadConfigurationAction,
      ),
    );
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
    _invokeBottleTargetAction(
      resolvePinnedProgramAction(
        bottle: bottle,
        program: program,
        action: widget.programActions.loadPinnedProgramSettingsAction,
      ),
    );
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
        _invokeBottleTargetAction(
          resolveBottleSummaryAction(
            bottle: bottle,
            action: widget.bottleActions.deleteAction,
          ),
        );
      case BottleContextMenuAction.rename:
        _invokeBottleTargetAction(
          resolveBottleSummaryAction(
            bottle: bottle,
            action: widget.bottleActions.renameAction,
          ),
        );
      case BottleContextMenuAction.move:
        _invokeBottleTargetAction(
          resolveBottleSummaryAction(
            bottle: bottle,
            action: widget.bottleActions.moveAction,
          ),
        );
      case BottleContextMenuAction.showInFinder:
        _invokeBottleLocationAction(
          resolveBottleLocationAction(
            bottle: bottle,
            location: 'root',
            action: widget.bottleActions.openLocationAction,
          ),
        );
      case BottleContextMenuAction.exportArchive:
        _invokeBottleTargetAction(
          resolveBottleSummaryAction(
            bottle: bottle,
            action: widget.bottleActions.exportArchiveAction,
          ),
        );
      case BottleContextMenuAction.terminateProcesses:
        _invokeBottleTargetAction(
          resolveBottleSummaryAction(
            bottle: bottle,
            action: widget.bottleActions.terminateProcessesAction,
          ),
        );
    }
  }

  void _invokeBottleTargetAction(BottleTargetActionAvailability action) {
    switch (action) {
      case EnabledBottleTargetActionAvailability(:final invoke):
        invoke();
      case DisabledBottleTargetActionAvailability():
    }
  }

  void _invokeBottleLocationAction(BottleLocationActionDispatch action) {
    switch (action) {
      case AvailableBottleLocationActionDispatch(:final invoke):
        invoke();
      case UnavailableBottleLocationActionDispatch():
    }
  }
}
