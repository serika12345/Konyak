import 'dart:async';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../app/dialogs/bottle_programs_dialog.dart';
import '../app/dialogs/run_program_dialog.dart';
import '../app/utils/program_labels.dart';
import '../app/utils/program_run_feedback.dart';
import '../bottles/bottle_summary.dart';
import '../cli/konyak_cli_process_runner.dart' show NotifyProcessStart;
import '../cli/konyak_cli_program_commands.dart';
import '../cli/konyak_cli_program_result_types.dart';
import '../cli/konyak_cli_read_commands.dart';
import '../l10n/konyak_localizations.dart';
import 'home_loader.dart';
import 'home_loader_bottles.dart';
import 'home_loader_pinned_programs.dart';

part 'home_loader_programs.freezed.dart';

const programLaunchWindowPollInterval = Duration(milliseconds: 250);
const programLaunchWindowWatchTimeout = Duration(minutes: 5);
const programLaunchProcessStablePolls = 2;

extension KonyakHomeLoaderPrograms on KonyakHomeLoaderState {
  Future<void> runProgram(BottleSummary bottle) async {
    final result = await showDialog<RunProgramDialogResult>(
      context: context,
      builder: (context) => RunProgramDialog(
        bottleName: bottle.name,
        programFilePicker: widget.programFilePicker,
        initialDirectory: bottleDriveCPath(bottle.path),
        defaultLogPath: bottleRunLogPath(bottle.path),
        graphicsBackendHintsLoader: (programPath) =>
            widget.cliClient.suggestGraphicsBackend(programPath: programPath),
      ),
    );

    if (result == null) {
      return;
    }

    await runProgramPath(
      bottle: bottle,
      programPath: result.programPath,
      settings: result.settings,
    );
  }

  Future<void> runProgramPath({
    required BottleSummary bottle,
    required String programPath,
    ProgramSettingsSummary? settings,
  }) async {
    final launchId = beginProgramLaunch();
    final baselineWindowIds =
        await visibleExternalWindowIds(
          descendantOfProcessIds: const <int>{},
          includeWineProcessWindows: true,
        ) ??
        const <String>{};
    final baselineWineProcessIds =
        await runningWineProcessIds(
          descendantOfProcessIds: const <int>{},
          includeWineProcesses: true,
        ) ??
        const <int>{};
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
        settings: switch (settings) {
          null => const NoProgramRunSettings(),
          final settings => UseProgramRunSettings(settings),
        },
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
    return appSettings?.automaticallyPinNewInstalledPrograms ?? false;
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

      final currentWindowIds = await visibleExternalWindowIds(
        descendantOfProcessIds: <int>{rootProcessId},
        includeWineProcessWindows: true,
      );
      final currentWineProcessIds = await runningWineProcessIds(
        descendantOfProcessIds: <int>{rootProcessId},
        includeWineProcesses: true,
      );

      if (currentWindowIds == null && currentWineProcessIds == null) {
        return;
      }

      if (currentWindowIds != null &&
          currentWindowIds.any(
            (windowId) => !baselineWindowIds.contains(windowId),
          )) {
        finishProgramLaunch(launchId);
        return;
      }

      if (currentWineProcessIds == null) {
        continue;
      }

      final newWineProcessIds = currentWineProcessIds
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

  Future<Set<String>?> visibleExternalWindowIds({
    required Set<int> descendantOfProcessIds,
    required bool includeWineProcessWindows,
  }) async {
    return widget.programWindowProbe.visibleExternalWindowIds(
      widget.platform,
      descendantOfProcessIds: descendantOfProcessIds,
      includeWineProcessWindows: includeWineProcessWindows,
    );
  }

  Future<Set<int>?> runningWineProcessIds({
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
          latestRunLogPath = run.logPath;
        });
      case FailedProgramRun(:final logPath, :final logFileCreated)
          when logFileCreated:
        updateState(() {
          latestRunLogPath = logPath;
        });
      case CompletedProgramRun() || FailedProgramRun():
        updateState(() {
          latestRunLogPath = null;
        });
      case UnsupportedProgramRun() ||
          MissingProgramRunBottle() ||
          ProgramRunLoadFailure():
        break;
    }

    final feedbackMessage = programRunFeedback(result);
    if (feedbackMessage != null) {
      showSnackBar(feedbackMessage);
    }
  }

  Future<void> runBottleCommand({
    required BottleSummary bottle,
    required String command,
  }) async {
    final launchId = beginProgramLaunch();
    final baselineWindowIds =
        await visibleExternalWindowIds(
          descendantOfProcessIds: const <int>{},
          includeWineProcessWindows: true,
        ) ??
        const <String>{};
    final baselineWineProcessIds =
        await runningWineProcessIds(
          descendantOfProcessIds: const <int>{},
          includeWineProcesses: true,
        ) ??
        const <int>{};

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
