part of '../home_loader/home_loader.dart';

extension _KonyakHomeLoaderPinnedPrograms on _KonyakHomeLoaderState {
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
}
