import 'package:flutter/material.dart';

import '../../bottles/bottle_summary.dart';
import '../../runtimes/runtime_summary.dart';
import '../app_constants.dart';
import '../app_platform.dart';
import '../bottles/bottle_detail.dart';
import '../bottles/runtime_settings_change.dart';
import '../utils/bottle_lists.dart';
import '../widgets/konyak_menu_bar.dart';
import 'sidebar.dart';

class KonyakHome extends StatefulWidget {
  const KonyakHome({
    super.key,
    required this.platform,
    this.runtime,
    this.bottles = const [],
    this.isLoading = false,
    this.errorMessage,
    this.onRefresh,
    this.onShowSettings,
    this.onShowAbout,
    this.onCreateBottle,
    this.onImportBottleArchive,
    this.onExportBottleArchive,
    this.onViewLatestLog,
    this.onRuntimeSettingsChanged,
    this.onLoadBottleConfiguration,
    this.onDeleteBottle,
    this.onRenameBottle,
    this.onMoveBottle,
    this.onRunProgram,
    this.onRunProgramPath,
    this.onPinProgram,
    this.programSettings = const <String, ProgramSettingsSummary>{},
    this.loadingProgramSettings = const <String>{},
    this.pendingRuntimeSettingsControls = const <String, String>{},
    this.onLoadPinnedProgramSettings,
    this.onProgramSettingsChanged,
    this.onUnpinProgram,
    this.onRenamePinnedProgram,
    this.onOpenPinnedProgramLocation,
    this.onRunBottleCommand,
    this.onShowWinetricks,
    this.onOpenBottleLocation,
    this.onShowBottlePrograms,
    this.onShowProcessManager,
    this.onTerminateBottleProcesses,
  });

  final KonyakPlatform platform;
  final RuntimeSummary? runtime;
  final List<BottleSummary> bottles;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRefresh;
  final VoidCallback? onShowSettings;
  final VoidCallback? onShowAbout;
  final VoidCallback? onCreateBottle;
  final VoidCallback? onImportBottleArchive;
  final ValueChanged<BottleSummary>? onExportBottleArchive;
  final VoidCallback? onViewLatestLog;
  final RuntimeSettingsChanged? onRuntimeSettingsChanged;
  final ValueChanged<BottleSummary>? onLoadBottleConfiguration;
  final ValueChanged<BottleSummary>? onDeleteBottle;
  final ValueChanged<BottleSummary>? onRenameBottle;
  final ValueChanged<BottleSummary>? onMoveBottle;
  final ValueChanged<BottleSummary>? onRunProgram;
  final void Function(BottleSummary bottle, String programPath)?
  onRunProgramPath;
  final ValueChanged<BottleSummary>? onPinProgram;
  final Map<String, ProgramSettingsSummary> programSettings;
  final Set<String> loadingProgramSettings;
  final Map<String, String> pendingRuntimeSettingsControls;
  final void Function(BottleSummary bottle, PinnedProgramSummary program)?
  onLoadPinnedProgramSettings;
  final void Function(
    BottleSummary bottle,
    PinnedProgramSummary program,
    ProgramSettingsSummary settings,
  )?
  onProgramSettingsChanged;
  final void Function(BottleSummary bottle, PinnedProgramSummary program)?
  onUnpinProgram;
  final void Function(BottleSummary bottle, PinnedProgramSummary program)?
  onRenamePinnedProgram;
  final void Function(BottleSummary bottle, PinnedProgramSummary program)?
  onOpenPinnedProgramLocation;
  final void Function(BottleSummary bottle, String command)? onRunBottleCommand;
  final ValueChanged<BottleSummary>? onShowWinetricks;
  final void Function(BottleSummary bottle, String location)?
  onOpenBottleLocation;
  final ValueChanged<BottleSummary>? onShowBottlePrograms;
  final VoidCallback? onShowProcessManager;
  final ValueChanged<BottleSummary>? onTerminateBottleProcesses;

  @override
  State<KonyakHome> createState() => _KonyakHomeState();
}

class _KonyakHomeState extends State<KonyakHome> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedBottleId;
  bool _isSidebarVisible = true;
  bool _showExpandedSidebarContent = true;
  BottleDetailMode _detailMode = BottleDetailMode.overview;
  String? _selectedProgramPath;

  @override
  void didUpdateWidget(covariant KonyakHome oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (findSelectedBottle(widget.bottles, _selectedBottleId) == null) {
      _selectedBottleId = widget.bottles.isEmpty
          ? null
          : widget.bottles.first.id;
      if (_selectedBottleId == null) {
        _detailMode = BottleDetailMode.overview;
        _selectedProgramPath = null;
      }
    }

    final selectedBottle = findSelectedBottle(
      widget.bottles,
      _selectedBottleId,
    );
    if (_detailMode == BottleDetailMode.programConfiguration &&
        findSelectedProgram(selectedBottle, _selectedProgramPath) == null) {
      _detailMode = BottleDetailMode.overview;
      _selectedProgramPath = null;
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
    final filteredBottles = filterBottles(
      bottles: widget.bottles,
      searchQuery: _searchController.text,
    );
    final selectedBottle =
        findSelectedBottle(filteredBottles, _selectedBottleId) ??
        (filteredBottles.isEmpty ? null : filteredBottles.first);
    final selectedProgram = findSelectedProgram(
      selectedBottle,
      _selectedProgramPath,
    );
    final selectedBottleHasPendingRuntimeSettings =
        selectedBottle != null &&
        widget.pendingRuntimeSettingsControls.containsKey(selectedBottle.id);

    return Scaffold(
      body: Column(
        children: [
          if (widget.platform.isLinux)
            KonyakMenuBar(
              menus: [
                KonyakMenuDefinition(
                  label: 'Konyak',
                  items: [
                    KonyakMenuItemDefinition(
                      label: 'About Konyak',
                      icon: Icons.info_outline,
                      onPressed: widget.onShowAbout,
                    ),
                    KonyakMenuItemDefinition(
                      label: 'Settings…',
                      icon: Icons.settings_outlined,
                      onPressed: widget.onShowSettings,
                    ),
                  ],
                ),
                KonyakMenuDefinition(
                  label: 'File',
                  items: [
                    KonyakMenuItemDefinition(
                      label: 'Import Bottle',
                      icon: Icons.file_upload_outlined,
                      onPressed: widget.onImportBottleArchive,
                    ),
                  ],
                ),
              ],
            ),
          Expanded(
            child: Row(
              children: [
                AnimatedSidebarSlot(
                  isExpanded: _isSidebarVisible,
                  showExpandedContent: _showExpandedSidebarContent,
                  onAnimationEnd: _handleSidebarAnimationEnd,
                  expandedSidebar: KonyakSidebar(
                    reserveLeadingWindowControlsSpace: widget.platform.isMacOS,
                    bottles: filteredBottles,
                    selectedBottleId: selectedBottle?.id,
                    searchController: _searchController,
                    onSearchChanged: (_) => setState(() {}),
                    onToggleSidebar: _toggleSidebar,
                    onBottleSelected: selectedBottleHasPendingRuntimeSettings
                        ? null
                        : (bottle) {
                            setState(() {
                              _selectedBottleId = bottle.id;
                              _detailMode = BottleDetailMode.overview;
                              _selectedProgramPath = null;
                            });
                          },
                    onBottleContextMenuAction: _handleBottleContextMenuAction,
                  ),
                  collapsedSidebar: CollapsedSidebarToggle(
                    reserveLeadingWindowControlsSpace: widget.platform.isMacOS,
                    onToggleSidebar: _toggleSidebar,
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: colors.strongBorder,
                ),
                Expanded(
                  child: KonyakBottleDetail(
                    platform: widget.platform,
                    runtime: widget.runtime,
                    bottle: selectedBottle,
                    isLoading: widget.isLoading,
                    errorMessage: widget.errorMessage,
                    onRefresh: widget.onRefresh,
                    onShowSettings: widget.onShowSettings,
                    onCreateBottle: widget.onCreateBottle,
                    onViewLatestLog: widget.onViewLatestLog,
                    detailMode: _detailMode,
                    selectedProgram: selectedProgram,
                    programSettings:
                        selectedProgram == null || selectedBottle == null
                        ? null
                        : widget.programSettings[programSettingsKey(
                            bottleId: selectedBottle.id,
                            programPath: selectedProgram.path,
                          )],
                    isProgramSettingsLoading:
                        selectedProgram != null &&
                        selectedBottle != null &&
                        widget.loadingProgramSettings.contains(
                          programSettingsKey(
                            bottleId: selectedBottle.id,
                            programPath: selectedProgram.path,
                          ),
                        ),
                    pendingRuntimeSettingsControlKey: selectedBottle == null
                        ? null
                        : widget.pendingRuntimeSettingsControls[selectedBottle
                              .id],
                    onBackToBottle: selectedBottleHasPendingRuntimeSettings
                        ? null
                        : _showBottleOverview,
                    onShowBottleConfiguration: _showBottleConfiguration,
                    onRuntimeSettingsChanged: widget.onRuntimeSettingsChanged,
                    onDeleteBottle: widget.onDeleteBottle,
                    onRunProgram: widget.onRunProgram,
                    onRunProgramPath: widget.onRunProgramPath,
                    onPinProgram: widget.onPinProgram,
                    onConfigurePinnedProgram: _showPinnedProgramConfiguration,
                    onProgramSettingsChanged: widget.onProgramSettingsChanged,
                    onUnpinProgram: widget.onUnpinProgram,
                    onRenamePinnedProgram: widget.onRenamePinnedProgram,
                    onOpenPinnedProgramLocation:
                        widget.onOpenPinnedProgramLocation,
                    onRunBottleCommand: widget.onRunBottleCommand,
                    onShowWinetricks: widget.onShowWinetricks,
                    onOpenBottleLocation: widget.onOpenBottleLocation,
                    onShowBottlePrograms: widget.onShowBottlePrograms,
                    onShowProcessManager: widget.onShowProcessManager,
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
    if (widget.pendingRuntimeSettingsControls.containsKey(bottle.id)) {
      return;
    }
    setState(() {
      _selectedBottleId = bottle.id;
      _detailMode = BottleDetailMode.configuration;
      _selectedProgramPath = null;
    });
    widget.onLoadBottleConfiguration?.call(bottle);
  }

  void _showPinnedProgramConfiguration(
    BottleSummary bottle,
    PinnedProgramSummary program,
  ) {
    if (widget.pendingRuntimeSettingsControls.containsKey(bottle.id)) {
      return;
    }
    setState(() {
      _selectedBottleId = bottle.id;
      _selectedProgramPath = program.path;
      _detailMode = BottleDetailMode.programConfiguration;
    });
    widget.onLoadPinnedProgramSettings?.call(bottle, program);
  }

  void _showBottleOverview() {
    final selectedBottle = findSelectedBottle(
      widget.bottles,
      _selectedBottleId,
    );
    if (selectedBottle != null &&
        widget.pendingRuntimeSettingsControls.containsKey(selectedBottle.id)) {
      return;
    }
    setState(() {
      _detailMode = BottleDetailMode.overview;
      _selectedProgramPath = null;
    });
  }

  void _handleBottleContextMenuAction(
    BottleSummary bottle,
    BottleContextMenuAction action,
  ) {
    setState(() {
      _selectedBottleId = bottle.id;
    });

    switch (action) {
      case BottleContextMenuAction.remove:
        widget.onDeleteBottle?.call(bottle);
      case BottleContextMenuAction.rename:
        widget.onRenameBottle?.call(bottle);
      case BottleContextMenuAction.move:
        widget.onMoveBottle?.call(bottle);
      case BottleContextMenuAction.showInFinder:
        widget.onOpenBottleLocation?.call(bottle, 'root');
      case BottleContextMenuAction.exportArchive:
        widget.onExportBottleArchive?.call(bottle);
      case BottleContextMenuAction.terminateProcesses:
        widget.onTerminateBottleProcesses?.call(bottle);
    }
  }
}
