part of '../home_loader/home_loader.dart';

const _programLaunchWindowPollInterval = Duration(milliseconds: 250);
const _programLaunchWindowWatchTimeout = Duration(minutes: 5);

extension _KonyakHomeLoaderPrograms on _KonyakHomeLoaderState {
  Future<void> _runProgram(BottleSummary bottle) async {
    final programPath = await showDialog<String>(
      context: context,
      builder: (context) => RunProgramDialog(
        bottleName: bottle.name,
        programFilePicker: widget.programFilePicker,
      ),
    );

    if (programPath == null) {
      return;
    }

    await _runProgramPath(bottle: bottle, programPath: programPath);
  }

  Future<void> _runProgramPath({
    required BottleSummary bottle,
    required String programPath,
  }) async {
    final launchId = _beginProgramLaunch();
    final baselineWindowIds =
        await _visibleExternalWindowIds(
          descendantOfProcessIds: const <int>{},
          includeWineProcessWindows: true,
        ) ??
        const <String>{};

    if (!mounted) {
      _finishProgramLaunch(launchId);
      return;
    }

    late final ProgramRunLoadResult result;
    try {
      result = await widget.cliClient.runProgram(
        bottleId: bottle.id,
        programPath: programPath,
        onStarted: (processId) {
          unawaited(
            _finishProgramLaunchWhenMatchingWindowAppears(
              launchId: launchId,
              rootProcessId: processId,
              baselineWindowIds: baselineWindowIds,
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
  }) async {
    if (rootProcessId <= 0) {
      return;
    }

    final startedAt = DateTime.now();

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
      if (currentWindowIds == null) {
        return;
      }

      final hasNewMatchingWindow = currentWindowIds.any(
        (windowId) => !baselineWindowIds.contains(windowId),
      );
      if (hasNewMatchingWindow) {
        _finishProgramLaunch(launchId);
        return;
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

    final message = switch (result) {
      OpenedBottleLocation(:final location) =>
        'Opened ${locationLabel(location)}',
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
