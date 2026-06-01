part of '../home_loader/home_loader.dart';

extension _KonyakHomeLoaderPrograms on _KonyakHomeLoaderState {
  void _terminateWineProcessesOnClose() {
    if (!widget.enableBackgroundServices || _hasTerminatedWineProcesses) {
      return;
    }

    final settings = _appSettings;
    if (settings == null || !settings.terminateWineProcessesOnClose) {
      return;
    }

    _hasTerminatedWineProcesses = true;
    unawaited(widget.cliClient.terminateWineProcesses());
  }

  Future<void> _terminateBottleProcesses(BottleSummary bottle) async {
    final result = await widget.cliClient.terminateWineProcesses(
      bottleId: bottle.id,
    );

    if (!mounted) {
      return;
    }

    final message = switch (result) {
      TerminatedWineProcesses() => 'Stopped processes in ${bottle.name}',
      WineProcessTerminationLoadFailure(:final message) => message,
    };

    _showSnackBar(message);
  }

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
    final result = await widget.cliClient.runProgram(
      bottleId: bottle.id,
      programPath: programPath,
    );

    if (!mounted) {
      return;
    }

    _handleProgramRunResult(result);
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

  Future<void> _pinProgram(BottleSummary bottle) async {
    final input = await showDialog<PinProgramInput>(
      context: context,
      builder: (context) => PinProgramDialog(
        bottleName: bottle.name,
        programFilePicker: widget.programFilePicker,
      ),
    );

    if (input == null) {
      return;
    }

    await _pinProgramPath(
      bottle: bottle,
      name: input.name,
      programPath: input.programPath,
    );
  }

  Future<void> _pinProgramPath({
    required BottleSummary bottle,
    required String name,
    required String programPath,
  }) async {
    final result = await widget.cliClient.pinProgram(
      bottleId: bottle.id,
      name: name,
      programPath: programPath,
    );

    if (!mounted) {
      return;
    }

    _handleBottleUpdateResult(result, successMessage: (_) => 'Pinned $name');
  }

  Future<void> _unpinProgram({
    required BottleSummary bottle,
    required PinnedProgramSummary program,
  }) async {
    final result = await widget.cliClient.unpinProgram(
      bottleId: bottle.id,
      programPath: program.path,
    );

    if (!mounted) {
      return;
    }

    _handleBottleUpdateResult(
      result,
      successMessage: (_) => 'Unpinned ${program.name}',
    );
  }

  Future<void> _renamePinnedProgram({
    required BottleSummary bottle,
    required PinnedProgramSummary program,
  }) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) =>
          RenamePinnedProgramDialog(programName: program.name),
    );

    if (name == null) {
      return;
    }

    final result = await widget.cliClient.renamePinnedProgram(
      bottleId: bottle.id,
      programPath: program.path,
      name: name,
    );

    if (!mounted) {
      return;
    }

    _handleBottleUpdateResult(result, successMessage: (_) => 'Renamed $name');
  }

  Future<void> _openPinnedProgramLocation({
    required BottleSummary bottle,
    required PinnedProgramSummary program,
  }) async {
    final result = await widget.cliClient.openProgramLocation(
      bottleId: bottle.id,
      programPath: program.path,
    );

    if (!mounted) {
      return;
    }

    final message = switch (result) {
      OpenedProgramLocation() => 'Opened ${program.name} location',
      ProgramLocationOpenFailure(:final message) => message,
    };

    _showSnackBar(message);
  }

  Future<void> _loadPinnedProgramSettings({
    required BottleSummary bottle,
    required PinnedProgramSummary program,
  }) async {
    final key = programSettingsKey(
      bottleId: bottle.id,
      programPath: program.path,
    );
    _updateState(() {
      _loadingProgramSettings.add(key);
    });

    final result = await widget.cliClient.getProgramSettings(
      bottleId: bottle.id,
      programPath: program.path,
    );

    if (!mounted) {
      return;
    }

    _updateState(() {
      _loadingProgramSettings.remove(key);
      switch (result) {
        case LoadedProgramSettings(:final settings):
          _programSettings[key] = settings;
        case MissingProgramSettingsBottle() || ProgramSettingsLoadFailure():
          _programSettings.remove(key);
      }
    });

    switch (result) {
      case LoadedProgramSettings():
        break;
      case MissingProgramSettingsBottle(:final message) ||
          ProgramSettingsLoadFailure(:final message):
        _showSnackBar(message);
    }
  }

  Future<void> _setPinnedProgramSettings({
    required BottleSummary bottle,
    required PinnedProgramSummary program,
    required ProgramSettingsSummary settings,
  }) async {
    final result = await widget.cliClient.setProgramSettings(
      bottleId: bottle.id,
      programPath: program.path,
      settings: settings,
    );

    if (!mounted) {
      return;
    }

    switch (result) {
      case LoadedProgramSettings(:final settings):
        _updateState(() {
          _programSettings[programSettingsKey(
                bottleId: bottle.id,
                programPath: program.path,
              )] =
              settings;
        });
        _showSnackBar('Saved ${program.name} configuration');
      case MissingProgramSettingsBottle(:final message) ||
          ProgramSettingsLoadFailure(:final message):
        _showSnackBar(message);
    }
  }

  Future<void> _runBottleCommand({
    required BottleSummary bottle,
    required String command,
  }) async {
    final result = await widget.cliClient.runBottleCommand(
      bottleId: bottle.id,
      command: command,
    );

    if (!mounted) {
      return;
    }

    _handleProgramRunResult(result);

    if (shouldRefreshBottleAfterCommand(command) &&
        result is CompletedProgramRun) {
      await _loadBottleConfiguration(bottle);
    }
  }

  Future<void> _showWinetricks(BottleSummary bottle) async {
    _updateState(() {
      _isLoadingWinetricks = true;
    });

    late final WinetricksVerbListLoadResult listResult;
    try {
      listResult = await widget.cliClient.listWinetricksVerbs();
    } finally {
      if (mounted) {
        _updateState(() {
          _isLoadingWinetricks = false;
        });
      }
    }

    if (!mounted) {
      return;
    }

    switch (listResult) {
      case LoadedWinetricksVerbs(:final categories):
        final verb = await showDialog<String>(
          context: context,
          builder: (context) =>
              WinetricksDialog(bottleName: bottle.name, categories: categories),
        );

        if (!mounted || verb == null) {
          return;
        }

        _updateState(() {
          _winetricksInstallProgressMessage = 'Installing $verb...';
        });

        late final ProgramRunLoadResult runResult;
        try {
          runResult = await widget.cliClient.runWinetricksVerb(
            bottleId: bottle.id,
            verb: verb,
          );
        } finally {
          if (mounted) {
            _updateState(() {
              _winetricksInstallProgressMessage = null;
            });
          }
        }

        if (!mounted) {
          return;
        }

        _handleProgramRunResult(runResult);
      case WinetricksVerbListLoadFailure(:final message):
        _showSnackBar(message);
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

  Future<void> _showProcessManager() async {
    await showDialog<void>(
      context: context,
      builder: (context) => ProcessManagerDialog(
        bottles: _bottles,
        onLoadProcesses: widget.cliClient.listWineProcesses,
        onTerminateProcess: (process) {
          return widget.cliClient.terminateWineProcess(
            bottleId: process.bottleId,
            processId: process.processId,
          );
        },
      ),
    );
  }

  Future<void> _showLatestLog() async {
    final logPath = _latestRunLogPath;
    if (logPath == null) {
      return;
    }

    final result = await widget.logReader.readLog(logPath);

    if (!mounted) {
      return;
    }

    switch (result) {
      case ReadLog(:final content):
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Latest run log'),
            content: SizedBox(
              width: 640,
              child: SingleChildScrollView(child: SelectableText(content)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      case LogReadFailure(:final message):
        _showSnackBar(message);
    }
  }
}
