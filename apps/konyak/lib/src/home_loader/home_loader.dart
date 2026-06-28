import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app_platform.dart';
import '../app/home/home_screen.dart';
import '../app/programs/program_window_probe.dart';
import '../app/runtime/runtime_platform.dart';
import '../app/widgets/blocking_progress_overlay.dart';
import '../app/widgets/konyak_snack_bar.dart';
import '../bottles/bottle_summary.dart';
import '../cli/konyak_cli_client.dart';
import '../files/bottle_archive_picker.dart';
import '../files/directory_picker.dart';
import '../files/gptk_wine_source_picker.dart';
import '../files/program_file_picker.dart';
import '../l10n/konyak_localizations.dart';
import '../logs/log_reader.dart';
import '../settings/app_settings_summary.dart';
import 'home_loader_bottles.dart';
import 'home_loader_executables.dart';
import 'home_loader_pinned_programs.dart';
import 'home_loader_platform_helpers.dart';
import 'home_loader_programs.dart';
import 'home_loader_runtimes.dart';
import 'home_loader_settings.dart';
import 'home_loader_wine_processes.dart';
import 'home_loader_winetricks.dart';
import 'known_runtimes_state.dart';

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
    required this.programWindowProbe,
    this.initialExecutablePaths = const <String>[],
    this.executableOpenAutoRunBottleId,
    required this.enableBackgroundServices,
    required this.onAppSettingsLoaded,
    required this.onAppearanceModeChanged,
    required this.onLanguageModeChanged,
  });

  final KonyakPlatform platform;
  final KonyakCliClient cliClient;
  final LogReader logReader;
  final ProgramFilePicker programFilePicker;
  final DirectoryPicker directoryPicker;
  final GptkWineSourcePicker gptkWineSourcePicker;
  final BottleArchivePicker bottleArchivePicker;
  final ProgramWindowProbe programWindowProbe;
  final List<String> initialExecutablePaths;
  final String? executableOpenAutoRunBottleId;
  final bool enableBackgroundServices;
  final ValueChanged<AppSettingsSummary> onAppSettingsLoaded;
  final ValueChanged<AppAppearanceMode> onAppearanceModeChanged;
  final ValueChanged<AppLanguageMode> onLanguageModeChanged;

  @override
  State<KonyakHomeLoader> createState() => KonyakHomeLoaderState();
}

class KonyakHomeLoaderState extends State<KonyakHomeLoader>
    with WidgetsBindingObserver {
  List<BottleSummary> bottles = const <BottleSummary>[];
  bool isLoading = true;
  bool isCreatingBottle = false;
  final Set<int> activeProgramLaunchIds = <int>{};
  int nextProgramLaunchId = 0;
  bool isLoadingWinetricks = false;
  String? winetricksInstallProgressMessage;
  String? archiveProgressMessage;
  String? runtimeInstallProgressMessage;
  double? runtimeInstallProgressFraction;
  String? konyakUpdateCheckProgressMessage;
  bool isShowingSettings = false;
  bool isCheckingKonyakUpdate = false;
  bool hasTerminatedWineProcesses = false;
  AppSettingsSummary? appSettings;
  String? errorMessage;
  String? latestRunLogPath;
  KnownRuntimesState knownRuntimes = const KnownRuntimesPending();
  final List<String> pendingExecutableOpenPaths = <String>[];
  bool isHandlingExecutableOpen = false;
  final Map<String, ProgramSettingsSummary> programSettings =
      <String, ProgramSettingsSummary>{};
  final Set<String> loadingProgramSettings = <String>{};
  final Map<String, String> pendingRuntimeSettingsControls = <String, String>{};

  @override
  void initState() {
    super.initState();
    if (widget.enableBackgroundServices) {
      WidgetsBinding.instance.addObserver(this);
    }
    pendingExecutableOpenPaths.addAll(
      validExecutableOpenPaths(widget.initialExecutablePaths),
    );
    macosMenuChannel.setMethodCallHandler(handleMacosMenuMethodCall);
    unawaited(loadPendingExecutableOpenPathsFromPlatform());
    loadBottles();
    if (widget.enableBackgroundServices) {
      unawaited(initializeBackgroundServices());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      unawaited(terminateWineProcessesOnClose());
    }
  }

  @override
  void dispose() {
    unawaited(terminateWineProcessesOnClose());
    macosMenuChannel.setMethodCallHandler(null);
    if (widget.enableBackgroundServices) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  void updateState(VoidCallback callback) => setState(callback);

  void showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(konyakSnackBar(context: context, message: message));
  }

  void showWarningSnackBar(String message, {SnackBarAction? action}) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      konyakSnackBar(
        context: context,
        message: message,
        backgroundColor: colorScheme.errorContainer,
        textColor: colorScheme.onErrorContainer,
        leading: Icon(
          Icons.warning_amber_outlined,
          color: colorScheme.onErrorContainer,
        ),
        action: action,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (widget.platform.isMacOS) const MacosNativeMenuLocalizer(),
        KonyakHome(
          platform: widget.platform,
          runtime: runtimeForPlatform(widget.platform, knownRuntimes.runtimes),
          bottles: bottles,
          isLoading: isLoading,
          errorMessage: errorMessage,
          onRefresh: loadBottles,
          onShowSettings: showSettings,
          onShowAbout: showAbout,
          onCheckKonyakUpdates: isCheckingKonyakUpdate
              ? null
              : checkKonyakUpdateFromMenu,
          onCreateBottle: createBottle,
          onImportBottleArchive: importBottleArchive,
          onReinstallRuntime: reinstallManagedRuntimeFromMenu,
          onExportBottleArchive: exportBottleArchive,
          onViewLatestLog: latestRunLogPath == null ? null : showLatestLog,
          pendingRuntimeSettingsControls: pendingRuntimeSettingsControls,
          onRuntimeSettingsChanged: (bottle, runtimeSettings, controlKey) {
            setRuntimeSettings(
              bottle: bottle,
              runtimeSettings: runtimeSettings,
              controlKey: controlKey,
            );
          },
          onLoadBottleConfiguration: loadBottleConfiguration,
          onDeleteBottle: deleteBottle,
          onRenameBottle: renameBottle,
          onMoveBottle: moveBottle,
          onRunProgram: runProgram,
          onRunProgramPath: (bottle, programPath) {
            runProgramPath(bottle: bottle, programPath: programPath);
          },
          onPinProgram: pinProgram,
          programSettings: programSettings,
          loadingProgramSettings: loadingProgramSettings,
          isRuntimeCapabilitiesLoading: !knownRuntimes.isLoaded,
          onLoadPinnedProgramSettings: (bottle, program) {
            loadPinnedProgramSettings(bottle: bottle, program: program);
          },
          onProgramSettingsChanged: (bottle, program, settings) {
            setPinnedProgramSettings(
              bottle: bottle,
              program: program,
              settings: settings,
            );
          },
          onUnpinProgram: (bottle, program) {
            unpinProgram(bottle: bottle, program: program);
          },
          onRenamePinnedProgram: (bottle, program) {
            renamePinnedProgram(bottle: bottle, program: program);
          },
          onOpenPinnedProgramLocation: (bottle, program) {
            openPinnedProgramLocation(bottle: bottle, program: program);
          },
          onRunBottleCommand: (bottle, command) {
            runBottleCommand(bottle: bottle, command: command);
          },
          onShowWinetricks: showWinetricks,
          onOpenBottleLocation: (bottle, location) {
            openBottleLocation(bottle: bottle, location: location);
          },
          onShowBottlePrograms: showBottlePrograms,
          onShowProcessManager: showProcessManager,
          onTerminateBottleProcesses: terminateBottleProcesses,
        ),
        if (isCreatingBottle)
          BlockingProgressOverlay(
            key: const ValueKey('create-bottle-progress'),
            message: KonyakLocalizations.of(context).creatingBottleEllipsis,
          ),
        if (activeProgramLaunchIds.isNotEmpty)
          BlockingProgressOverlay(
            key: const ValueKey('program-launch-progress'),
            message: KonyakLocalizations.of(context).launchingProgramEllipsis,
          ),
        if (isLoadingWinetricks)
          BlockingProgressOverlay(
            key: const ValueKey('winetricks-progress'),
            message: KonyakLocalizations.of(
              context,
            ).loadingWinetricksPackagesEllipsis,
          ),
        if (winetricksInstallProgressMessage case final message?)
          BlockingProgressOverlay(
            key: const ValueKey('winetricks-progress'),
            message: message,
          ),
        if (archiveProgressMessage case final message?)
          BlockingProgressOverlay(
            key: const ValueKey('bottle-archive-progress'),
            message: message,
          ),
        if (runtimeInstallProgressMessage case final message?)
          BlockingProgressOverlay(
            key: const ValueKey('runtime-install-progress'),
            message: message,
            progress: runtimeInstallProgressFraction,
          ),
        if (konyakUpdateCheckProgressMessage case final message?)
          BlockingProgressOverlay(
            key: const ValueKey('konyak-update-check-progress'),
            message: message,
          ),
      ],
    );
  }
}
