import 'dart:async';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../app/dialogs/bottle_programs_dialog.dart';
import '../app/dialogs/run_program_dialog.dart';
import '../app/programs/program_window_probe.dart';
import '../app/utils/program_labels.dart';
import '../app/utils/program_run_feedback.dart';
import '../bottles/bottle_summary.dart';
import '../cli/konyak_cli_process_runner.dart' show NotifyProcessStart;
import '../cli/konyak_cli_program_commands.dart';
import '../cli/konyak_cli_program_result_types.dart';
import '../cli/konyak_cli_read_commands.dart';
import '../l10n/konyak_localizations.dart';
import 'app_settings_state.dart' as app_settings_state;
import 'home_loader.dart';
import 'home_loader_bottles.dart';
import 'home_loader_pinned_programs.dart';
import 'latest_run_log_state.dart';

part 'home_loader_programs.freezed.dart';

const programLaunchWindowPollInterval = Duration(milliseconds: 250);
const programLaunchWindowWatchTimeout = Duration(minutes: 5);
const programLaunchProcessStablePolls = 2;

extension KonyakHomeLoaderPrograms on KonyakHomeLoaderState {
  Future<void> runProgram(BottleSummary bottle) async {
    final decision = runProgramDialogDecisionFromNullable(
      await showDialog<RunProgramDialogDecision>(
        context: context,
        builder: (context) => RunProgramDialog(
          bottleName: bottle.name,
          programFilePicker: widget.programFilePicker,
          initialDirectory: bottleDriveCPath(bottle.path),
          defaultLogPath: bottleRunLogPath(bottle.path),
          graphicsBackendHintsLoader: (programPath) =>
              widget.cliClient.suggestGraphicsBackend(programPath: programPath),
        ),
      ),
    );

    switch (decision) {
      case RunProgramFromDialog(:final programPath, :final settings):
        await runProgramPath(
          bottle: bottle,
          programPath: programPath,
          settings: settings,
        );
      case CancelledRunProgramDialog():
        return;
    }
  }

  Future<void> runProgramPath({
    required BottleSummary bottle,
    required String programPath,
    ProgramRunSettingsArgument settings = const NoProgramRunSettings(),
  }) async {
    final launchId = beginProgramLaunch();
    final baselineWindowIds = _probeIdsOrEmpty(
      await visibleExternalWindowIds(
        descendantOfProcessIds: const <int>{},
        includeWineProcessWindows: true,
      ),
    );
    final baselineWineProcessIds = _probeIdsOrEmpty(
      await runningWineProcessIds(
        descendantOfProcessIds: const <int>{},
        includeWineProcesses: true,
      ),
    );
    final baselineProgramPaths = await installedProgramPathsForAutoPin(bottle);

    if (!mounted) {
      finishProgramLaunch(launchId);
      return;
    }

    late final ProgramRunLoadResult result;
    try {
      result = await widget.cliClient.runProgram(
        bottleId: bottle.id,
        programPath: programPath,
        settings: settings,
        startObserver: NotifyProcessStart((processId) {
          unawaited(
            finishProgramLaunchWhenMatchingWindowAppears(
              launchId: launchId,
              rootProcessId: processId,
              baselineWindowIds: baselineWindowIds,
              baselineWineProcessIds: baselineWineProcessIds,
            ),
          );
        }),
      );
    } finally {
      finishProgramLaunch(launchId);
    }

    if (!mounted) {
      return;
    }

    handleProgramRunResult(result);
    if (result is CompletedProgramRun && bottle.pinnedPrograms.isNotEmpty) {
      await reloadBottle(bottle);
      if (!mounted) {
        return;
      }
    }
    await autoPinNewInstalledPrograms(
      bottle: bottle,
      result: result,
      baselineProgramPaths: baselineProgramPaths,
    );
  }

  Future<AutoPinBaselineProgramPaths> installedProgramPathsForAutoPin(
    BottleSummary bottle,
  ) async {
    if (!shouldAutomaticallyPinNewInstalledPrograms()) {
      return const AutoPinBaselineProgramPaths.unavailable();
    }

    final result = await widget.cliClient.listBottlePrograms(bottle.id);
    if (!mounted) {
      return const AutoPinBaselineProgramPaths.unavailable();
    }

    return switch (result) {
      LoadedBottlePrograms(:final programs) =>
        AutoPinBaselineProgramPaths.loaded(
          knownProgramPaths(bottle: bottle, programs: programs),
        ),
      BottleProgramListLoadFailure() =>
        const AutoPinBaselineProgramPaths.unavailable(),
    };
  }

  bool shouldAutomaticallyPinNewInstalledPrograms() {
    return app_settings_state.shouldAutomaticallyPinNewInstalledPrograms(
      appSettings,
    );
  }

  Set<String> knownProgramPaths({
    required BottleSummary bottle,
    required List<BottleProgramSummary> programs,
  }) {
    return <String>{
      for (final program in programs) program.path,
      for (final program in bottle.pinnedPrograms) program.path,
    };
  }

  Future<void> autoPinNewInstalledPrograms({
    required BottleSummary bottle,
    required ProgramRunLoadResult result,
    required AutoPinBaselineProgramPaths baselineProgramPaths,
  }) async {
    if (!shouldAutomaticallyPinNewInstalledPrograms()) {
      return;
    }

    if (result is! CompletedProgramRun) {
      return;
    }

    final Set<String> baselinePaths;
    switch (baselineProgramPaths) {
      case _AutoPinBaselineUnavailable():
        return;
      case _AutoPinBaselineLoaded(:final paths):
        baselinePaths = paths;
    }

    final programsResult = await widget.cliClient.listBottlePrograms(bottle.id);

    if (!mounted) {
      return;
    }

    switch (programsResult) {
      case LoadedBottlePrograms(:final programs):
        final knownPaths = Set<String>.of(baselinePaths);
        for (final program in programs) {
          if (!knownPaths.add(program.path)) {
            continue;
          }

          await pinProgramPath(
            bottle: bottle,
            name: programDisplayName(program),
            programPath: program.path,
          );
          if (!mounted) {
            return;
          }
        }
      case BottleProgramListLoadFailure(:final message):
        showSnackBar(message);
    }
  }

  int beginProgramLaunch() {
    final launchId = nextProgramLaunchId;
    nextProgramLaunchId += 1;

    if (!mounted) {
      return launchId;
    }

    updateState(() {
      activeProgramLaunchIds.add(launchId);
    });

    return launchId;
  }

  void finishProgramLaunch(int launchId) {
    if (!mounted || !activeProgramLaunchIds.contains(launchId)) {
      return;
    }

    updateState(() {
      activeProgramLaunchIds.remove(launchId);
    });
  }

  Future<void> finishProgramLaunchWhenMatchingWindowAppears({
    required int launchId,
    required int rootProcessId,
    required Set<String> baselineWindowIds,
    required Set<int> baselineWineProcessIds,
  }) async {
    if (rootProcessId <= 0) {
      return;
    }

    final startedAt = DateTime.now();
    final newWineProcessPollCounts = <int, int>{};

    while (mounted && activeProgramLaunchIds.contains(launchId)) {
      if (DateTime.now().difference(startedAt) >=
          programLaunchWindowWatchTimeout) {
        return;
      }

      await Future<void>.delayed(programLaunchWindowPollInterval);
      if (!mounted || !activeProgramLaunchIds.contains(launchId)) {
        return;
      }

      final currentWindowProbe = await visibleExternalWindowIds(
        descendantOfProcessIds: <int>{rootProcessId},
        includeWineProcessWindows: true,
      );
      final currentWineProcessProbe = await runningWineProcessIds(
        descendantOfProcessIds: <int>{rootProcessId},
        includeWineProcesses: true,
      );

      switch ((currentWindowProbe, currentWineProcessProbe)) {
        case (
          UnavailableProgramWindowProbeResult(),
          UnavailableProgramWindowProbeResult(),
        ):
          return;
        case _:
          break;
      }

      switch (currentWindowProbe) {
        case AvailableProgramWindowProbeResult(:final ids)
            when ids.any((windowId) => !baselineWindowIds.contains(windowId)):
          finishProgramLaunch(launchId);
          return;
        case AvailableProgramWindowProbeResult():
        case UnavailableProgramWindowProbeResult():
          break;
      }

      switch (currentWineProcessProbe) {
        case UnavailableProgramWindowProbeResult():
          continue;
        case AvailableProgramWindowProbeResult(:final ids):
          final newWineProcessIds = ids
              .where((processId) => !baselineWineProcessIds.contains(processId))
              .toSet();
          newWineProcessPollCounts.removeWhere(
            (processId, _) => !newWineProcessIds.contains(processId),
          );

          for (final processId in newWineProcessIds) {
            final pollCount = (newWineProcessPollCounts[processId] ?? 0) + 1;
            if (pollCount >= programLaunchProcessStablePolls) {
              finishProgramLaunch(launchId);
              return;
            }

            newWineProcessPollCounts[processId] = pollCount;
          }
      }
    }
  }

  Future<ProgramWindowProbeResult<String>> visibleExternalWindowIds({
    required Set<int> descendantOfProcessIds,
    required bool includeWineProcessWindows,
  }) async {
    return widget.programWindowProbe.visibleExternalWindowIds(
      widget.platform,
      descendantOfProcessIds: descendantOfProcessIds,
      includeWineProcessWindows: includeWineProcessWindows,
    );
  }

  Future<ProgramWindowProbeResult<int>> runningWineProcessIds({
    required Set<int> descendantOfProcessIds,
    required bool includeWineProcesses,
  }) async {
    return widget.programWindowProbe.runningWineProcessIds(
      widget.platform,
      descendantOfProcessIds: descendantOfProcessIds,
      includeWineProcesses: includeWineProcesses,
    );
  }

  void handleProgramRunResult(ProgramRunLoadResult result) {
    switch (result) {
      case CompletedProgramRun(:final run) when run.logFileCreated:
        updateState(() {
          latestRunLog = latestRunLogStateFromPath(run.logPath);
        });
      case FailedProgramRun(:final logPath, :final logFileCreated)
          when logFileCreated:
        updateState(() {
          latestRunLog = latestRunLogStateFromPath(logPath);
        });
      case CompletedProgramRun() || FailedProgramRun():
        updateState(() {
          latestRunLog = const LatestRunLogState.unavailable();
        });
      case UnsupportedProgramRun() ||
          MissingProgramRunBottle() ||
          ProgramRunLoadFailure():
        break;
    }

    switch (programRunFeedback(result)) {
      case ProgramRunFeedbackMessage(:final message):
        showSnackBar(message);
      case NoProgramRunFeedback():
        break;
    }
  }

  Future<void> runBottleCommand({
    required BottleSummary bottle,
    required String command,
  }) async {
    final launchId = beginProgramLaunch();
    final baselineWindowIds = _probeIdsOrEmpty(
      await visibleExternalWindowIds(
        descendantOfProcessIds: const <int>{},
        includeWineProcessWindows: true,
      ),
    );
    final baselineWineProcessIds = _probeIdsOrEmpty(
      await runningWineProcessIds(
        descendantOfProcessIds: const <int>{},
        includeWineProcesses: true,
      ),
    );

    if (!mounted) {
      finishProgramLaunch(launchId);
      return;
    }

    late final ProgramRunLoadResult result;
    try {
      result = await widget.cliClient.runBottleCommand(
        bottleId: bottle.id,
        command: command,
        startObserver: NotifyProcessStart((processId) {
          unawaited(
            finishProgramLaunchWhenMatchingWindowAppears(
              launchId: launchId,
              rootProcessId: processId,
              baselineWindowIds: baselineWindowIds,
              baselineWineProcessIds: baselineWineProcessIds,
            ),
          );
        }),
      );
    } finally {
      finishProgramLaunch(launchId);
    }

    if (!mounted) {
      return;
    }

    handleProgramRunResult(result);

    if (shouldRefreshBottleAfterCommand(command) &&
        result is CompletedProgramRun) {
      await loadBottleConfiguration(bottle);
    }
  }

  Future<void> openBottleLocation({
    required BottleSummary bottle,
    required String location,
  }) async {
    final result = await widget.cliClient.openBottleLocation(
      bottleId: bottle.id,
      location: location,
    );

    if (!mounted) {
      return;
    }

    final localizations = KonyakLocalizations.of(context);
    final message = switch (result) {
      OpenedBottleLocation(:final location) =>
        localizations.openedBottleLocation(
          localizedLocationLabel(location, localizations),
        ),
      BottleLocationOpenFailure(:final message) => message,
    };

    showSnackBar(message);
  }

  Future<void> showBottlePrograms(BottleSummary bottle) async {
    final result = await widget.cliClient.listBottlePrograms(bottle.id);

    if (!mounted) {
      return;
    }

    switch (result) {
      case LoadedBottlePrograms(:final programs):
        await showDialog<void>(
          context: context,
          builder: (context) => BottleProgramsDialog(
            bottleName: bottle.name,
            programs: programs,
            onPinProgram: (program) {
              Navigator.of(context).pop();
              unawaited(
                pinProgramPath(
                  bottle: bottle,
                  name: programDisplayName(program),
                  programPath: program.path,
                ),
              );
            },
            onRunProgram: (program) {
              Navigator.of(context).pop();
              runProgramPath(bottle: bottle, programPath: program.path);
            },
          ),
        );
      case BottleProgramListLoadFailure(:final message):
        showSnackBar(message);
    }
  }
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class AutoPinBaselineProgramPaths with _$AutoPinBaselineProgramPaths {
  const AutoPinBaselineProgramPaths._();

  const factory AutoPinBaselineProgramPaths.unavailable() =
      _AutoPinBaselineUnavailable;

  factory AutoPinBaselineProgramPaths.loaded(Set<String> paths) {
    return AutoPinBaselineProgramPaths._loaded(Set.unmodifiable(paths));
  }

  const factory AutoPinBaselineProgramPaths._loaded(Set<String> paths) =
      _AutoPinBaselineLoaded;
}

String bottleDriveCPath(String bottlePath) {
  if (bottlePath.endsWith('/')) {
    return '${bottlePath}drive_c';
  }

  return '$bottlePath/drive_c';
}

String bottleRunLogPath(String bottlePath) {
  if (bottlePath.endsWith('/')) {
    return '${bottlePath}logs/latest.log';
  }

  return '$bottlePath/logs/latest.log';
}

Set<T> _probeIdsOrEmpty<T>(ProgramWindowProbeResult<T> result) {
  return switch (result) {
    AvailableProgramWindowProbeResult(:final ids) => ids,
    UnavailableProgramWindowProbeResult() => Set<T>.unmodifiable(const []),
  };
}
