import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app_platform.dart';
import '../app/home/home_contracts.dart';
import '../app/home/home_screen.dart';
import '../app/programs/program_window_probe.dart';
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
import 'app_settings_state.dart';
import 'blocking_progress_state.dart';
import 'executable_open_queue_state.dart';
import 'home_bottle_list_state.dart';
import 'home_loader_bottles.dart';
import 'home_loader_executables.dart';
import 'home_loader_operation_state.dart';
import 'home_loader_pinned_programs.dart';
import 'home_loader_platform_helpers.dart';
import 'home_loader_programs.dart';
import 'home_loader_runtimes.dart';
import 'home_loader_settings.dart';
import 'home_loader_wine_processes.dart';
import 'home_loader_winetricks.dart';
import 'known_runtimes_state.dart';
import 'latest_run_log_state.dart';
import 'pinned_program_settings_cache_state.dart';
import 'program_launch_state.dart';
import 'runtime_settings_pending_controls_state.dart';
import 'wine_process_close_cleanup_state.dart';

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
  HomeBottleListState homeBottleListState = HomeBottleListState.loading();
  List<BottleSummary> get bottles => homeBottleListBottles(homeBottleListState);
  BottleListLoadState get bottleListLoadState =>
      homeBottleListLoadState(homeBottleListState);
  BlockingProgressState createBottleProgress =
      const BlockingProgressState.hidden();
  ProgramLaunchState programLaunchState = const ProgramLaunchState.idle();
  BlockingProgressState winetricksLoadProgress =
      const BlockingProgressState.hidden();
  BlockingProgressState winetricksInstallProgress =
      const BlockingProgressState.hidden();
  BlockingProgressState archiveProgress = const BlockingProgressState.hidden();
  BlockingProgressState runtimeInstallProgress =
      const BlockingProgressState.hidden();
  BlockingProgressState konyakUpdateCheckProgress =
      const BlockingProgressState.hidden();
  HomeLoaderOperationState operationState =
      const HomeLoaderOperationState.idle();
  WineProcessCloseCleanupState wineProcessCloseCleanupState =
      const WineProcessCloseCleanupState.notRequested();
  AppSettingsState appSettings = const AppSettingsState.unavailable();
  LatestRunLogState latestRunLog = const LatestRunLogState.unavailable();
  KnownRuntimesState knownRuntimes = const KnownRuntimesState.pending();
  ExecutableOpenQueueState executableOpenQueueState =
      const ExecutableOpenQueueState.empty();
  PinnedProgramSettingsCacheState pinnedProgramSettingsCacheState =
      const PinnedProgramSettingsCacheState.empty();
  RuntimeSettingsPendingControlsState runtimeSettingsPendingControlsState =
      const RuntimeSettingsPendingControlsState.empty();

  @override
  void initState() {
    super.initState();
    if (widget.enableBackgroundServices) {
      WidgetsBinding.instance.addObserver(this);
    }
    executableOpenQueueState = enqueueExecutableOpenPaths(
      state: executableOpenQueueState,
      paths: validExecutableOpenPaths(widget.initialExecutablePaths),
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
          state: KonyakHomeViewState(
            platform: widget.platform,
            runtimeCapabilitiesState: runtimeCapabilitiesStateForPlatform(
              platform: widget.platform,
              isLoading: !knownRuntimes.isLoaded,
              runtimes: knownRuntimes.runtimes,
            ),
            bottles: bottles,
            bottleListLoadState: bottleListLoadState,
            programSettings: pinnedProgramSettingsSnapshot(
              pinnedProgramSettingsCacheState,
            ),
            loadingProgramSettings: loadingPinnedProgramSettingsKeysSnapshot(
              pinnedProgramSettingsCacheState,
            ),
            pendingRuntimeSettingsControls:
                runtimeSettingsPendingControlsSnapshot(
                  runtimeSettingsPendingControlsState,
                ),
          ),
          menuActions: KonyakHomeMenuActions(
            refreshAction: KonyakHomeActionAvailability.available(loadBottles),
            showSettingsAction: KonyakHomeActionAvailability.available(
              showSettings,
            ),
            showAboutAction: KonyakHomeActionAvailability.available(showAbout),
            checkKonyakUpdatesAction:
                isHomeLoaderOperationRunning(
                  state: operationState,
                  operation: HomeLoaderOperation.checkingKonyakUpdate,
                )
                ? const KonyakHomeActionAvailability.unavailable()
                : KonyakHomeActionAvailability.available(
                    checkKonyakUpdateFromMenu,
                  ),
            createBottleAction: KonyakHomeActionAvailability.available(
              createBottle,
            ),
            importBottleArchiveAction: KonyakHomeActionAvailability.available(
              importBottleArchive,
            ),
            reinstallRuntimeAction: KonyakHomeActionAvailability.available(
              reinstallManagedRuntimeFromMenu,
            ),
            viewLatestLogAction: switch (latestRunLog) {
              AvailableLatestRunLog() => KonyakHomeActionAvailability.available(
                showLatestLog,
              ),
              UnavailableLatestRunLog() =>
                const KonyakHomeActionAvailability.unavailable(),
            },
            showProcessManagerAction: KonyakHomeActionAvailability.available(
              showProcessManager,
            ),
          ),
          bottleActions: KonyakBottleActions(
            loadConfigurationAction: BottleSummaryActionAvailability.available(
              loadBottleConfiguration,
            ),
            deleteAction: BottleSummaryActionAvailability.available(
              deleteBottle,
            ),
            renameAction: BottleSummaryActionAvailability.available(
              renameBottle,
            ),
            moveAction: BottleSummaryActionAvailability.available(moveBottle),
            exportArchiveAction: BottleSummaryActionAvailability.available(
              exportBottleArchive,
            ),
            runtimeSettingsChangeAction:
                RuntimeSettingsChangeAvailability.available((
                  bottle,
                  runtimeSettings,
                  controlKey,
                ) {
                  setRuntimeSettings(
                    bottle: bottle,
                    runtimeSettings: runtimeSettings,
                    controlKey: controlKey,
                  );
                }),
            openLocationAction: BottleLocationActionAvailability.available((
              bottle,
              location,
            ) {
              openBottleLocation(bottle: bottle, location: location);
            }),
            showProgramsAction: BottleSummaryActionAvailability.available(
              showBottlePrograms,
            ),
            terminateProcessesAction: BottleSummaryActionAvailability.available(
              terminateBottleProcesses,
            ),
          ),
          programActions: KonyakProgramActions(
            runProgramAction: BottleSummaryActionAvailability.available(
              runProgram,
            ),
            runProgramPathAction: ProgramPathActionAvailability.available((
              bottle,
              programPath,
            ) {
              runProgramPath(bottle: bottle, programPath: programPath);
            }),
            pinProgramAction: BottleSummaryActionAvailability.available(
              pinProgram,
            ),
            loadPinnedProgramSettingsAction:
                PinnedProgramActionAvailability.available((bottle, program) {
                  loadPinnedProgramSettings(bottle: bottle, program: program);
                }),
            programSettingsChangeAction:
                ProgramSettingsChangeAvailability.available((
                  bottle,
                  program,
                  settings,
                ) {
                  setPinnedProgramSettings(
                    bottle: bottle,
                    program: program,
                    settings: settings,
                  );
                }),
            unpinProgramAction: PinnedProgramActionAvailability.available((
              bottle,
              program,
            ) {
              unpinProgram(bottle: bottle, program: program);
            }),
            renamePinnedProgramAction:
                PinnedProgramActionAvailability.available((bottle, program) {
                  renamePinnedProgram(bottle: bottle, program: program);
                }),
            openPinnedProgramLocationAction:
                PinnedProgramActionAvailability.available((bottle, program) {
                  openPinnedProgramLocation(bottle: bottle, program: program);
                }),
          ),
          winetricksActions: KonyakWinetricksActions(
            runBottleCommandAction: BottleCommandActionAvailability.available((
              bottle,
              command,
            ) {
              runBottleCommand(bottle: bottle, command: command);
            }),
            showWinetricksAction: BottleSummaryActionAvailability.available(
              showWinetricks,
            ),
          ),
        ),
        ...blockingProgressOverlays(
          key: const ValueKey('create-bottle-progress'),
          state: createBottleProgress,
        ),
        if (hasActiveProgramLaunches(programLaunchState))
          BlockingProgressOverlay(
            key: const ValueKey('program-launch-progress'),
            message: KonyakLocalizations.of(context).launchingProgramEllipsis,
          ),
        ...blockingProgressOverlays(
          key: const ValueKey('winetricks-progress'),
          state: winetricksLoadProgress,
        ),
        ...blockingProgressOverlays(
          key: const ValueKey('winetricks-progress'),
          state: winetricksInstallProgress,
        ),
        ...blockingProgressOverlays(
          key: const ValueKey('bottle-archive-progress'),
          state: archiveProgress,
        ),
        ...blockingProgressOverlays(
          key: const ValueKey('runtime-install-progress'),
          state: runtimeInstallProgress,
        ),
        ...blockingProgressOverlays(
          key: const ValueKey('konyak-update-check-progress'),
          state: konyakUpdateCheckProgress,
        ),
      ],
    );
  }
}

List<Widget> blockingProgressOverlays({
  required Key key,
  required BlockingProgressState state,
}) {
  return switch (state) {
    HiddenBlockingProgress() => const <Widget>[],
    IndeterminateBlockingProgress(:final message) => <Widget>[
      BlockingProgressOverlay(key: key, message: message),
    ],
    DeterminateBlockingProgress(:final message, :final progress) => <Widget>[
      BlockingProgressOverlay(key: key, message: message, progress: progress),
    ],
  };
}
