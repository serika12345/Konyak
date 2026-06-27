part of 'konyak_cli_client.dart';

extension KonyakCliProgramCommands on KonyakCliClient {
  Future<ProgramRunLoadResult> runProgram({
    required String bottleId,
    required String programPath,
    ProgramSettingsSummary? settings,
    void Function(int processId)? onStarted,
  }) {
    final runArguments = <String>[
      'run-program',
      bottleId,
      '--program',
      programPath,
      if (settings != null) ...[
        '--settings-json',
        jsonEncode(settings.toJson()),
      ],
      '--json',
    ];

    return _programRunResultFromCommand(
      arguments: runArguments,
      failureMessage: _programRunFailureMessage,
      onStarted: onStarted,
    );
  }

  Future<BottleUpdateLoadResult> pinProgram({
    required String bottleId,
    required String name,
    required String programPath,
  }) async {
    final result = await _run([
      'pin-program',
      bottleId,
      '--name',
      name,
      '--program',
      programPath,
      '--json',
    ]);

    return _bottleUpdateResultFromCommand(
      result: result,
      command: 'pin-program',
    );
  }

  Future<BottleUpdateLoadResult> unpinProgram({
    required String bottleId,
    required String programPath,
  }) async {
    final result = await _run([
      'unpin-program',
      bottleId,
      '--program',
      programPath,
      '--json',
    ]);

    return _bottleUpdateResultFromCommand(
      result: result,
      command: 'unpin-program',
    );
  }

  Future<BottleUpdateLoadResult> renamePinnedProgram({
    required String bottleId,
    required String programPath,
    required String name,
  }) async {
    final result = await _run([
      'rename-pinned-program',
      bottleId,
      '--program',
      programPath,
      '--name',
      name,
      '--json',
    ]);

    return _bottleUpdateResultFromCommand(
      result: result,
      command: 'rename-pinned-program',
    );
  }

  Future<ProgramSettingsLoadResult> getProgramSettings({
    required String bottleId,
    required String programPath,
  }) async {
    final result = await _run([
      'get-program-settings',
      bottleId,
      '--program',
      programPath,
      '--json',
    ]);

    return _programSettingsResultFromCommand(
      result: result,
      command: 'get-program-settings',
    );
  }

  Future<ProgramSettingsLoadResult> setProgramSettings({
    required String bottleId,
    required String programPath,
    required ProgramSettingsSummary settings,
  }) async {
    final result = await _run([
      'set-program-settings',
      bottleId,
      '--program',
      programPath,
      '--settings-json',
      jsonEncode(settings.toJson()),
      '--json',
    ]);

    return _programSettingsResultFromCommand(
      result: result,
      command: 'set-program-settings',
    );
  }

  Future<ProgramRunLoadResult> runBottleCommand({
    required String bottleId,
    required String command,
    void Function(int processId)? onStarted,
  }) {
    return _programRunResultFromCommand(
      arguments: [
        'run-bottle-command',
        bottleId,
        '--command',
        command,
        '--json',
      ],
      failureMessage: (result) =>
          _commandFailureMessage('run-bottle-command', result),
      onStarted: onStarted,
    );
  }

  Future<ProgramRunLoadResult> runWinetricksVerb({
    required String bottleId,
    required String verb,
  }) {
    return _programRunResultFromCommand(
      arguments: ['run-winetricks', bottleId, '--verb', verb, '--json'],
      failureMessage: (result) =>
          _operationFailureMessage(result, 'run-winetricks'),
    );
  }

  Future<GraphicsBackendHintsLoadResult> suggestGraphicsBackend({
    required String programPath,
  }) async {
    final result = await _run([
      'suggest-graphics-backend',
      '--program',
      programPath,
      '--json',
    ]);

    final parsed = _parseGraphicsBackendHintsPayload(result.stdout);

    return switch (parsed) {
      LoadedGraphicsBackendHints() when result.exitCode == 0 => parsed,
      GraphicsBackendHintsLoadFailure(:final message) =>
        GraphicsBackendHintsLoadFailure(
          exitCode: result.exitCode,
          message: message,
          diagnostic: result.stderr,
        ),
      LoadedGraphicsBackendHints() => GraphicsBackendHintsLoadFailure(
        exitCode: result.exitCode,
        message: _commandFailureMessage('suggest-graphics-backend', result),
        diagnostic: result.stderr,
      ),
    };
  }

  Future<BottleLocationOpenResult> openBottleLocation({
    required String bottleId,
    required String location,
  }) async {
    final result = await _run([
      'open-bottle-location',
      bottleId,
      '--location',
      location,
      '--json',
    ]);

    final parsed = _parseBottleLocationOpenPayload(result.stdout);

    return switch (parsed) {
      OpenedBottleLocation() when result.exitCode == 0 => parsed,
      BottleLocationOpenFailure(:final message) => BottleLocationOpenFailure(
        exitCode: result.exitCode,
        message: message,
        diagnostic: result.stderr,
      ),
      OpenedBottleLocation() => BottleLocationOpenFailure(
        exitCode: result.exitCode,
        message: _commandFailureMessage('open-bottle-location', result),
        diagnostic: result.stderr,
      ),
    };
  }

  Future<ProgramLocationOpenResult> openProgramLocation({
    required String bottleId,
    required String programPath,
  }) async {
    final result = await _run([
      'open-program-location',
      bottleId,
      '--program',
      programPath,
      '--json',
    ]);

    final parsed = _parseProgramLocationOpenPayload(result.stdout);

    return switch (parsed) {
      OpenedProgramLocation() when result.exitCode == 0 => parsed,
      ProgramLocationOpenFailure(:final message) => ProgramLocationOpenFailure(
        exitCode: result.exitCode,
        message: message,
        diagnostic: result.stderr,
      ),
      OpenedProgramLocation() => ProgramLocationOpenFailure(
        exitCode: result.exitCode,
        message: _commandFailureMessage('open-program-location', result),
        diagnostic: result.stderr,
      ),
    };
  }
}
