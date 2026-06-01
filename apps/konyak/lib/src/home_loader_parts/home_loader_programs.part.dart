part of '../home_loader/home_loader.dart';

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
