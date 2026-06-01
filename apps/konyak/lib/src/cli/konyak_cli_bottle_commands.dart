part of 'konyak_cli_client.dart';

extension KonyakCliBottleCommands on KonyakCliClient {
  Future<BottleCreateLoadResult> createBottle({
    required String name,
    required String windowsVersion,
  }) async {
    final result = await _run([
      'create-bottle',
      '--name',
      name,
      '--windows-version',
      windowsVersion,
      '--json',
    ]);

    final parsed = parseBottleCreatePayload(result.stdout);

    return switch (parsed) {
      ParsedBottleCreate(:final bottle) when result.exitCode == 0 =>
        CreatedBottle(bottle),
      BottleCreateConflict(:final bottleId, :final message)
          when result.exitCode == 73 =>
        ExistingBottle(bottleId: bottleId, message: message),
      ParsedBottleCreate() ||
      BottleCreateConflict() ||
      BottleCreateParseFailure() => BottleCreateLoadFailure(
        exitCode: result.exitCode,
        message: _createFailureMessage(result),
        diagnostic: result.stderr,
      ),
    };
  }

  Future<BottleArchiveExportLoadResult> exportBottleArchive({
    required String bottleId,
    required String archivePath,
  }) async {
    final result = await _run([
      'export-bottle-archive',
      bottleId,
      '--archive',
      archivePath,
      '--json',
    ]);

    final parsed = _parseBottleArchiveExportPayload(result.stdout);
    return switch (parsed) {
      ExportedBottleArchive() when result.exitCode == 0 => parsed,
      ExportedBottleArchive() ||
      BottleArchiveExportLoadFailure() => BottleArchiveExportLoadFailure(
        exitCode: result.exitCode,
        message: _operationFailureMessage(result, 'export-bottle-archive'),
        diagnostic: result.stderr,
      ),
    };
  }

  Future<BottleArchiveImportLoadResult> importBottleArchive({
    required String archivePath,
  }) async {
    final result = await _run([
      'import-bottle-archive',
      '--archive',
      archivePath,
      '--json',
    ]);

    final parsed = parseBottleDetailPayload(result.stdout);
    return switch (parsed) {
      ParsedBottleDetail(:final bottle) when result.exitCode == 0 =>
        ImportedBottleArchive(bottle),
      ParsedBottleDetail() ||
      BottleDetailNotFound() ||
      BottleDetailParseFailure() => BottleArchiveImportLoadFailure(
        exitCode: result.exitCode,
        message: _operationFailureMessage(result, 'import-bottle-archive'),
        diagnostic: result.stderr,
      ),
    };
  }

  Future<BottleUpdateLoadResult> setWindowsVersion({
    required String bottleId,
    required String windowsVersion,
  }) async {
    final result = await _run([
      'set-windows-version',
      bottleId,
      '--windows-version',
      windowsVersion,
      '--json',
    ]);

    final parsed = parseBottleDetailPayload(result.stdout);

    return switch (parsed) {
      ParsedBottleDetail(:final bottle) when result.exitCode == 0 =>
        UpdatedBottle(bottle),
      BottleDetailNotFound(:final bottleId, :final message)
          when result.exitCode == 66 =>
        MissingBottleUpdate(bottleId: bottleId, message: message),
      ParsedBottleDetail() ||
      BottleDetailNotFound() ||
      BottleDetailParseFailure() => BottleUpdateLoadFailure(
        exitCode: result.exitCode,
        message: _updateFailureMessage(result),
        diagnostic: result.stderr,
      ),
    };
  }

  Future<BottleUpdateLoadResult> setRuntimeSettings({
    required String bottleId,
    required BottleRuntimeSettingsSummary runtimeSettings,
  }) async {
    final result = await _run([
      'set-runtime-settings',
      bottleId,
      '--settings-json',
      jsonEncode(runtimeSettings.toJson()),
      '--json',
    ]);

    return _bottleUpdateResultFromCommand(
      result: result,
      command: 'set-runtime-settings',
    );
  }

  Future<BottleDeleteLoadResult> deleteBottle(String bottleId) async {
    final result = await _run(['delete-bottle', bottleId, '--json']);
    final parsed = _parseBottleDeletePayload(result.stdout);

    return switch (parsed) {
      _ParsedBottleDelete(:final bottle) when result.exitCode == 0 =>
        DeletedBottle(bottle),
      _BottleDeleteNotFound(:final bottleId, :final message)
          when result.exitCode == 66 =>
        MissingBottleDelete(bottleId: bottleId, message: message),
      _ParsedBottleDelete() ||
      _BottleDeleteNotFound() ||
      _BottleDeleteParseFailure() => BottleDeleteLoadFailure(
        exitCode: result.exitCode,
        message: _deleteFailureMessage(result),
        diagnostic: result.stderr,
      ),
    };
  }

  Future<BottleUpdateLoadResult> renameBottle({
    required String bottleId,
    required String name,
  }) async {
    final result = await _run([
      'rename-bottle',
      bottleId,
      '--name',
      name,
      '--json',
    ]);

    return _bottleUpdateResultFromCommand(
      result: result,
      command: 'rename-bottle',
    );
  }

  Future<BottleUpdateLoadResult> moveBottle({
    required String bottleId,
    required String path,
  }) async {
    final result = await _run([
      'move-bottle',
      bottleId,
      '--path',
      path,
      '--json',
    ]);

    return _bottleUpdateResultFromCommand(
      result: result,
      command: 'move-bottle',
    );
  }
}
