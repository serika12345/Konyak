part of '../home_loader/home_loader.dart';

const _programLaunchWindowPollInterval = Duration(milliseconds: 250);
const _programLaunchWindowWatchTimeout = Duration(minutes: 5);
const _programLaunchProcessStablePolls = 2;

extension _KonyakHomeLoaderPrograms on _KonyakHomeLoaderState {
  Future<void> _runProgram(BottleSummary bottle) async {
    final result = await showDialog<RunProgramDialogResult>(
      context: context,
      builder: (context) => RunProgramDialog(
        bottleName: bottle.name,
        programFilePicker: widget.programFilePicker,
        initialDirectory: _bottleDriveCPath(bottle.path),
      ),
    );

    if (result == null) {
      return;
    }

    await _runProgramPath(
      bottle: bottle,
      programPath: result.programPath,
      settings: result.settings,
    );
  }

  Future<void> _runProgramPath({
    required BottleSummary bottle,
    required String programPath,
    ProgramSettingsSummary? settings,
  }) async {
    final launchId = _beginProgramLaunch();
    final baselineWindowIds =
        await _visibleExternalWindowIds(
          descendantOfProcessIds: const <int>{},
          includeWineProcessWindows: true,
        ) ??
        const <String>{};
    final baselineWineProcessIds =
        await _runningWineProcessIds(
          descendantOfProcessIds: const <int>{},
          includeWineProcesses: true,
        ) ??
        const <int>{};
    final baselineProgramPaths = await _installedProgramPathsForAutoPin(bottle);

    if (!mounted) {
      _finishProgramLaunch(launchId);
      return;
    }

    late final ProgramRunLoadResult result;
    try {
      result = await widget.cliClient.runProgram(
        bottleId: bottle.id,
        programPath: programPath,
        settings: settings,
        onStarted: (processId) {
          unawaited(
            _finishProgramLaunchWhenMatchingWindowAppears(
              launchId: launchId,
              rootProcessId: processId,
              baselineWindowIds: baselineWindowIds,
              baselineWineProcessIds: baselineWineProcessIds,
            ),
          );
        },
      );
    } finally {
      _finishProgramLaunch(launchId);
    }

    if (!mounted) {
      return;
    }

    _handleProgramRunResult(result);
    if (result is CompletedProgramRun && bottle.pinnedPrograms.isNotEmpty) {
      await _reloadBottle(bottle);
      if (!mounted) {
        return;
      }
    }
    await _autoPinNewInstalledPrograms(
      bottle: bottle,
      result: result,
      baselineProgramPaths: baselineProgramPaths,
    );
  }

  Future<Set<String>?> _installedProgramPathsForAutoPin(
    BottleSummary bottle,
  ) async {
    if (!_shouldAutomaticallyPinNewInstalledPrograms()) {
      return null;
    }

    final result = await widget.cliClient.listBottlePrograms(bottle.id);
    if (!mounted) {
      return null;
    }

    return switch (result) {
      LoadedBottlePrograms(:final programs) => _knownProgramPaths(
        bottle: bottle,
        programs: programs,
      ),
      BottleProgramListLoadFailure() => null,
    };
  }

  bool _shouldAutomaticallyPinNewInstalledPrograms() {
    return _appSettings?.automaticallyPinNewInstalledPrograms ?? false;
  }

  Set<String> _knownProgramPaths({
    required BottleSummary bottle,
    required List<BottleProgramSummary> programs,
  }) {
    return <String>{
      for (final program in programs) program.path,
      for (final program in bottle.pinnedPrograms) program.path,
    };
  }

  Future<void> _autoPinNewInstalledPrograms({
    required BottleSummary bottle,
    required ProgramRunLoadResult result,
    required Set<String>? baselineProgramPaths,
  }) async {
    if (baselineProgramPaths == null ||
        !_shouldAutomaticallyPinNewInstalledPrograms()) {
      return;
    }

    if (result is! CompletedProgramRun) {
      return;
    }

    final programsResult = await widget.cliClient.listBottlePrograms(bottle.id);

    if (!mounted) {
      return;
    }

    switch (programsResult) {
      case LoadedBottlePrograms(:final programs):
        final knownPaths = Set<String>.of(baselineProgramPaths);
        for (final program in programs) {
          if (!knownPaths.add(program.path)) {
            continue;
          }

          await _pinProgramPath(
            bottle: bottle,
            name: programDisplayName(program),
            programPath: program.path,
          );
          if (!mounted) {
            return;
          }
        }
      case BottleProgramListLoadFailure(:final message):
        _showSnackBar(message);
    }
  }

  int _beginProgramLaunch() {
    final launchId = _nextProgramLaunchId;
    _nextProgramLaunchId += 1;

    if (!mounted) {
      return launchId;
    }

    _updateState(() {
      _activeProgramLaunchIds.add(launchId);
    });

    return launchId;
  }

  void _finishProgramLaunch(int launchId) {
    if (!mounted || !_activeProgramLaunchIds.contains(launchId)) {
      return;
    }

    _updateState(() {
      _activeProgramLaunchIds.remove(launchId);
    });
  }

  Future<void> _finishProgramLaunchWhenMatchingWindowAppears({
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

    while (mounted && _activeProgramLaunchIds.contains(launchId)) {
      if (DateTime.now().difference(startedAt) >=
          _programLaunchWindowWatchTimeout) {
        return;
      }

      await Future<void>.delayed(_programLaunchWindowPollInterval);
      if (!mounted || !_activeProgramLaunchIds.contains(launchId)) {
        return;
      }

      final currentWindowIds = await _visibleExternalWindowIds(
        descendantOfProcessIds: <int>{rootProcessId},
        includeWineProcessWindows: true,
      );
      final currentWineProcessIds = await _runningWineProcessIds(
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
        _finishProgramLaunch(launchId);
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
        if (pollCount >= _programLaunchProcessStablePolls) {
          _finishProgramLaunch(launchId);
          return;
        }

        newWineProcessPollCounts[processId] = pollCount;
      }
    }
  }

  Future<Set<String>?> _visibleExternalWindowIds({
    required Set<int> descendantOfProcessIds,
    required bool includeWineProcessWindows,
  }) async {
    return widget.programWindowProbe.visibleExternalWindowIds(
      widget.platform,
      descendantOfProcessIds: descendantOfProcessIds,
      includeWineProcessWindows: includeWineProcessWindows,
    );
  }

  Future<Set<int>?> _runningWineProcessIds({
    required Set<int> descendantOfProcessIds,
    required bool includeWineProcesses,
  }) async {
    return widget.programWindowProbe.runningWineProcessIds(
      widget.platform,
      descendantOfProcessIds: descendantOfProcessIds,
      includeWineProcesses: includeWineProcesses,
    );
  }

  void _handleProgramRunResult(ProgramRunLoadResult result) {
    switch (result) {
      case CompletedProgramRun(:final run):
        _updateState(() {
          _latestRunLogPath = run.logPath;
        });
      case FailedProgramRun(:final logPath):
        _updateState(() {
          _latestRunLogPath = logPath;
        });
      case UnsupportedProgramRun() ||
          MissingProgramRunBottle() ||
          ProgramRunLoadFailure():
        break;
    }

    final feedbackMessage = programRunFeedback(result);
    if (feedbackMessage != null) {
      _showSnackBar(feedbackMessage);
    }
  }

  Future<void> _runBottleCommand({
    required BottleSummary bottle,
    required String command,
  }) async {
    final launchId = _beginProgramLaunch();
    final baselineWindowIds =
        await _visibleExternalWindowIds(
          descendantOfProcessIds: const <int>{},
          includeWineProcessWindows: true,
        ) ??
        const <String>{};
    final baselineWineProcessIds =
        await _runningWineProcessIds(
          descendantOfProcessIds: const <int>{},
          includeWineProcesses: true,
        ) ??
        const <int>{};

    if (!mounted) {
      _finishProgramLaunch(launchId);
      return;
    }

    late final ProgramRunLoadResult result;
    try {
      result = await widget.cliClient.runBottleCommand(
        bottleId: bottle.id,
        command: command,
        onStarted: (processId) {
          unawaited(
            _finishProgramLaunchWhenMatchingWindowAppears(
              launchId: launchId,
              rootProcessId: processId,
              baselineWindowIds: baselineWindowIds,
              baselineWineProcessIds: baselineWineProcessIds,
            ),
          );
        },
      );
    } finally {
      _finishProgramLaunch(launchId);
    }

    if (!mounted) {
      return;
    }

    _handleProgramRunResult(result);

    if (shouldRefreshBottleAfterCommand(command) &&
        result is CompletedProgramRun) {
      await _loadBottleConfiguration(bottle);
    }
  }

  Future<void> _openBottleLocation({
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

    _showSnackBar(message);
  }

  Future<void> _showBottlePrograms(BottleSummary bottle) async {
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
                _pinProgramPath(
                  bottle: bottle,
                  name: programDisplayName(program),
                  programPath: program.path,
                ),
              );
            },
            onRunProgram: (program) {
              Navigator.of(context).pop();
              _runProgramPath(bottle: bottle, programPath: program.path);
            },
          ),
        );
      case BottleProgramListLoadFailure(:final message):
        _showSnackBar(message);
    }
  }
}

String _bottleDriveCPath(String bottlePath) {
  if (bottlePath.endsWith('/')) {
    return '${bottlePath}drive_c';
  }

  return '$bottlePath/drive_c';
}
