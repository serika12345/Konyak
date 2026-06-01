import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_platform.dart';
import '../app/dialogs/app_settings_dialog.dart';
import '../app/dialogs/bottle_management_dialogs.dart';
import '../app/dialogs/bottle_programs_dialog.dart';
import '../app/dialogs/create_bottle_dialog.dart';
import '../app/dialogs/open_executable_dialog.dart';
import '../app/dialogs/pin_program_dialog.dart';
import '../app/dialogs/process_manager_dialog.dart';
import '../app/dialogs/run_program_dialog.dart';
import '../app/dialogs/winetricks_dialog.dart';
import '../app/home/home_screen.dart';
import '../app/runtime/runtime_platform.dart';
import '../app/startup/startup_update_checker.dart';
import '../app/utils/bottle_lists.dart';
import '../app/utils/program_labels.dart';
import '../app/utils/program_run_feedback.dart';
import '../app/widgets/blocking_progress_overlay.dart';
import '../bottles/bottle_summary.dart';
import '../cli/konyak_cli_client.dart';
import '../cli/runtime_install_contract.dart';
import '../files/bottle_archive_picker.dart';
import '../files/directory_picker.dart';
import '../files/gptk_wine_source_picker.dart';
import '../files/program_file_picker.dart';
import '../logs/log_reader.dart';
import '../runtimes/runtime_summary.dart';
import '../settings/app_settings_summary.dart';

part '../home_loader_parts/home_loader_platform_helpers.part.dart';
part '../home_loader_parts/home_loader_bottles.part.dart';
part '../home_loader_parts/home_loader_executables.part.dart';
part '../home_loader_parts/home_loader_programs.part.dart';
part '../home_loader_parts/home_loader_runtimes.part.dart';
part '../home_loader_parts/home_loader_settings.part.dart';

class KonyakHomeLoader extends StatefulWidget {
  const KonyakHomeLoader({
    super.key,
    required this.platform,
    required this.cliClient,
    required this.logReader,
    required this.programFilePicker,
    required this.directoryPicker,
    required this.gptkWineSourcePicker,
    required this.bottleArchivePicker,
    this.initialExecutablePaths = const <String>[],
    required this.enableBackgroundServices,
    required this.onAppSettingsLoaded,
    required this.onAppearanceModeChanged,
  });

  final KonyakPlatform platform;
  final KonyakCliClient cliClient;
  final LogReader logReader;
  final ProgramFilePicker programFilePicker;
  final DirectoryPicker directoryPicker;
  final GptkWineSourcePicker gptkWineSourcePicker;
  final BottleArchivePicker bottleArchivePicker;
  final List<String> initialExecutablePaths;
  final bool enableBackgroundServices;
  final ValueChanged<AppSettingsSummary> onAppSettingsLoaded;
  final ValueChanged<AppAppearanceMode> onAppearanceModeChanged;

  @override
  State<KonyakHomeLoader> createState() => _KonyakHomeLoaderState();
}

class _KonyakHomeLoaderState extends State<KonyakHomeLoader>
    with WidgetsBindingObserver {
  List<BottleSummary> _bottles = const <BottleSummary>[];
  bool _isLoading = true;
  bool _isCreatingBottle = false;
  bool _isLoadingWinetricks = false;
  String? _winetricksInstallProgressMessage;
  String? _archiveProgressMessage;
  String? _runtimeInstallProgressMessage;
  double? _runtimeInstallProgressFraction;
  bool _isShowingSettings = false;
  bool _hasTerminatedWineProcesses = false;
  AppSettingsSummary? _appSettings;
  String? _errorMessage;
  String? _latestRunLogPath;
  List<RuntimeSummary> _knownRuntimes = const <RuntimeSummary>[];
  bool _hasLoadedKnownRuntimes = false;
  final List<String> _pendingExecutableOpenPaths = <String>[];
  bool _isHandlingExecutableOpen = false;
  final Map<String, ProgramSettingsSummary> _programSettings =
      <String, ProgramSettingsSummary>{};
  final Set<String> _loadingProgramSettings = <String>{};
  final Map<String, String> _pendingRuntimeSettingsControls =
      <String, String>{};

  @override
  void initState() {
    super.initState();
    if (widget.enableBackgroundServices) {
      WidgetsBinding.instance.addObserver(this);
    }
    _pendingExecutableOpenPaths.addAll(
      _validExecutableOpenPaths(widget.initialExecutablePaths),
    );
    _macosMenuChannel.setMethodCallHandler(_handleMacosMenuMethodCall);
    unawaited(_loadPendingExecutableOpenPathsFromPlatform());
    _loadBottles();
    if (widget.enableBackgroundServices) {
      unawaited(_initializeBackgroundServices());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      _terminateWineProcessesOnClose();
    }
  }

  @override
  void dispose() {
    _terminateWineProcessesOnClose();
    _macosMenuChannel.setMethodCallHandler(null);
    if (widget.enableBackgroundServices) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  void _updateState(VoidCallback callback) => setState(callback);

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        KonyakHome(
          platform: widget.platform,
          runtime: runtimeForPlatform(widget.platform, _knownRuntimes),
          bottles: _bottles,
          isLoading: _isLoading,
          errorMessage: _errorMessage,
          onRefresh: _loadBottles,
          onShowSettings: _showSettings,
          onShowAbout: _showAbout,
          onCreateBottle: _createBottle,
          onImportBottleArchive: _importBottleArchive,
          onExportBottleArchive: _exportBottleArchive,
          onViewLatestLog: _latestRunLogPath == null ? null : _showLatestLog,
          pendingRuntimeSettingsControls: _pendingRuntimeSettingsControls,
          onRuntimeSettingsChanged: (bottle, runtimeSettings, controlKey) {
            _setRuntimeSettings(
              bottle: bottle,
              runtimeSettings: runtimeSettings,
              controlKey: controlKey,
            );
          },
          onLoadBottleConfiguration: _loadBottleConfiguration,
          onDeleteBottle: _deleteBottle,
          onRenameBottle: _renameBottle,
          onMoveBottle: _moveBottle,
          onRunProgram: _runProgram,
          onRunProgramPath: (bottle, programPath) {
            _runProgramPath(bottle: bottle, programPath: programPath);
          },
          onPinProgram: _pinProgram,
          programSettings: _programSettings,
          loadingProgramSettings: _loadingProgramSettings,
          isRuntimeCapabilitiesLoading: !_hasLoadedKnownRuntimes,
          onLoadPinnedProgramSettings: (bottle, program) {
            _loadPinnedProgramSettings(bottle: bottle, program: program);
          },
          onProgramSettingsChanged: (bottle, program, settings) {
            _setPinnedProgramSettings(
              bottle: bottle,
              program: program,
              settings: settings,
            );
          },
          onUnpinProgram: (bottle, program) {
            _unpinProgram(bottle: bottle, program: program);
          },
          onRenamePinnedProgram: (bottle, program) {
            _renamePinnedProgram(bottle: bottle, program: program);
          },
          onOpenPinnedProgramLocation: (bottle, program) {
            _openPinnedProgramLocation(bottle: bottle, program: program);
          },
          onRunBottleCommand: (bottle, command) {
            _runBottleCommand(bottle: bottle, command: command);
          },
          onShowWinetricks: _showWinetricks,
          onOpenBottleLocation: (bottle, location) {
            _openBottleLocation(bottle: bottle, location: location);
          },
          onShowBottlePrograms: _showBottlePrograms,
          onShowProcessManager: _showProcessManager,
          onTerminateBottleProcesses: _terminateBottleProcesses,
        ),
        if (_isCreatingBottle)
          const BlockingProgressOverlay(
            key: ValueKey('create-bottle-progress'),
            message: 'Creating bottle...',
          ),
        if (_isLoadingWinetricks)
          const BlockingProgressOverlay(
            key: ValueKey('winetricks-progress'),
            message: 'Loading winetricks packages...',
          ),
        if (_winetricksInstallProgressMessage case final message?)
          BlockingProgressOverlay(
            key: const ValueKey('winetricks-progress'),
            message: message,
          ),
        if (_archiveProgressMessage case final message?)
          BlockingProgressOverlay(
            key: const ValueKey('bottle-archive-progress'),
            message: message,
          ),
        if (_runtimeInstallProgressMessage case final message?)
          BlockingProgressOverlay(
            key: const ValueKey('runtime-install-progress'),
            message: message,
            progress: _runtimeInstallProgressFraction,
          ),
      ],
    );
  }
}
