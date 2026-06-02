part of '../konyak_cli.dart';

CliResult _appSettingsJsonResult(AppSettingsRecord settings) {
  return _jsonSuccess(<String, Object?>{'appSettings': settings.toJson()});
}

CliResult _appUpdateJsonResult(AppUpdateRecord update) {
  return _jsonSuccess(<String, Object?>{'appUpdate': update.toJson()});
}

CliResult _appUpdateInstallJsonResult(AppUpdateInstallRecord install) {
  return _jsonSuccess(<String, Object?>{'appUpdateInstall': install.toJson()});
}

CliResult _wineProcessTerminationJsonResult(
  List<WineProcessTerminationRecord> records, {
  String recordsKey = 'bottles',
}) {
  final hasFailures = records.any((record) => record.status != 'terminated');
  return _jsonSuccess(<String, Object?>{
    'wineProcessTermination': <String, Object?>{
      'hasFailures': hasFailures,
      recordsKey: records
          .map((record) => record.toJson())
          .toList(growable: false),
    },
  }, exitCode: hasFailures ? 75 : 0);
}

CliResult _wineProcessListJsonResult(List<WineProcessRecord> records) {
  return _jsonSuccess(<String, Object?>{
    'wineProcesses': <String, Object?>{
      'processes': records
          .map((record) => record.toJson())
          .toList(growable: false),
    },
  });
}

CliResult _terminateWineProcessesJsonResult({
  required BottleCatalog bottleCatalog,
  required ProgramRunPlanner programRunPlanner,
  required ProgramRunner? programRunner,
  Option<String> bottleId = const Option.none(),
}) {
  final runner = programRunner;
  if (runner == null) {
    return _programRunnerUnavailableError();
  }

  final records = <WineProcessTerminationRecord>[];
  final bottlesResult = bottleCatalog.listBottles();
  final failure = bottlesResult.fold<CliResult?>(
    _bottleCatalogFailureJsonResult,
    (_) => null,
  );
  if (failure != null) {
    return failure;
  }
  final bottles = bottlesResult.getOrElse((_) => const <BottleRecord>[]);
  final targetBottles = bottleId.match(
    () => bottles,
    (id) => _findBottle(
      bottles,
      id,
    ).match(() => const <BottleRecord>[], (bottle) => <BottleRecord>[bottle]),
  );
  if (bottleId.isSome() && targetBottles.isEmpty) {
    return bottleId.match(() => _bottleNotFoundError(''), _bottleNotFoundError);
  }

  for (final bottle in targetBottles) {
    final request = programRunPlanner.planWineProcessTermination(
      bottle: bottle,
    );
    final result = runner.run(request);
    switch (result) {
      case ProgramRunCompleted(:final processExitCode):
        records.add(
          WineProcessTerminationRecord(
            bottleId: bottle.id,
            status: _isSuccessfulWineServerTerminationExit(processExitCode)
                ? 'terminated'
                : 'failed',
            runnerKind: request.runnerKind,
            executable: request.executable,
            argv: request.argv,
            processExitCode: Option.of(processExitCode),
          ),
        );
      case ProgramRunFailed(:final message):
        records.add(
          WineProcessTerminationRecord(
            bottleId: bottle.id,
            status: 'failed',
            runnerKind: request.runnerKind,
            executable: request.executable,
            argv: request.argv,
            message: Option.of(message),
          ),
        );
    }
  }

  return _wineProcessTerminationJsonResult(records);
}

bool _isSuccessfulWineServerTerminationExit(int processExitCode) {
  return processExitCode == 0 || processExitCode == 1;
}

CliResult _listWineProcessesJsonResult({
  required BottleCatalog bottleCatalog,
  required ProgramRunPlanner programRunPlanner,
  required ProgramRunner? programRunner,
  required ProgramMetadataExtractor programMetadataExtractor,
}) {
  final runner = programRunner;
  if (runner == null) {
    return _programRunnerUnavailableError();
  }

  final records = <WineProcessRecord>[];
  final bottlesResult = bottleCatalog.listBottles();
  final failure = bottlesResult.fold<CliResult?>(
    _bottleCatalogFailureJsonResult,
    (_) => null,
  );
  if (failure != null) {
    return failure;
  }
  for (final bottle in bottlesResult.getOrElse((_) => const <BottleRecord>[])) {
    final request = programRunPlanner.planWineProcessList(bottle: bottle);
    final result = runner.run(request);
    switch (result) {
      case ProgramRunCompleted(:final processExitCode, :final stdout)
          when processExitCode == 0:
        records.addAll(
          _parseWinedbgProcessList(stdout)
              .where((process) {
                return !_isWineInfrastructureProcess(process);
              })
              .map((process) {
                final hostPath = _wineProcessHostPath(
                  bottle: bottle,
                  executable: process.executable,
                );
                final metadata = hostPath.match(
                  () => const Option<ProgramMetadataRecord>.none(),
                  (path) => programMetadataExtractor.extract(
                    bottle: bottle,
                    programPath: path,
                  ),
                );
                return WineProcessRecord(
                  bottleId: bottle.id,
                  processId: process.processId,
                  executable: process.executable,
                  hostPath: hostPath,
                  metadata: metadata,
                );
              }),
        );
      case ProgramRunCompleted(:final processExitCode, :final stderr):
        return _jsonError(
          exitCode: 75,
          code: 'wineProcessListFailed',
          message:
              'Wine process list for `${bottle.id}` exited with code '
              '$processExitCode.',
          extra: <String, Object?>{'diagnostic': stderr},
        );
      case ProgramRunFailed(:final message):
        return _jsonError(
          exitCode: 75,
          code: 'wineProcessListFailed',
          message: message,
        );
    }
  }

  return _wineProcessListJsonResult(records);
}

CliResult _terminateWineProcessJsonResult({
  required BottleCatalog bottleCatalog,
  required ProgramRunPlanner programRunPlanner,
  required ProgramRunner? programRunner,
  required String bottleId,
  required String processId,
}) {
  final runner = programRunner;
  if (runner == null) {
    return _programRunnerUnavailableError();
  }

  final bottlesResult = bottleCatalog.listBottles();
  final failure = bottlesResult.fold<CliResult?>(
    _bottleCatalogFailureJsonResult,
    (_) => null,
  );
  if (failure != null) {
    return failure;
  }
  final bottleOption = _findBottle(
    bottlesResult.getOrElse((_) => const <BottleRecord>[]),
    bottleId,
  );
  return bottleOption.match(() => _bottleNotFoundError(bottleId), (bottle) {
    final request = programRunPlanner.planWineProcessKill(
      bottle: bottle,
      processId: processId,
    );
    final result = runner.run(request);
    final record = switch (result) {
      ProgramRunCompleted(:final processExitCode) =>
        WineProcessTerminationRecord(
          bottleId: bottle.id,
          processId: Option.of(processId),
          status: processExitCode == 0 ? 'terminated' : 'failed',
          runnerKind: request.runnerKind,
          executable: request.executable,
          argv: request.argv,
          processExitCode: Option.of(processExitCode),
        ),
      ProgramRunFailed(:final message) => WineProcessTerminationRecord(
        bottleId: bottle.id,
        processId: Option.of(processId),
        status: 'failed',
        runnerKind: request.runnerKind,
        executable: request.executable,
        argv: request.argv,
        message: Option.of(message),
      ),
    };

    return _wineProcessTerminationJsonResult(<WineProcessTerminationRecord>[
      record,
    ], recordsKey: 'processes');
  });
}
