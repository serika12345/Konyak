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
  String? bottleId,
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
  final targetBottles = bottleId == null
      ? bottles
      : <BottleRecord>[?_findBottle(bottles, bottleId)];
  if (bottleId != null && targetBottles.isEmpty) {
    return _bottleNotFoundError(bottleId);
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
            processExitCode: processExitCode,
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
            message: message,
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
                final metadata = hostPath == null
                    ? const Option<ProgramMetadataRecord>.none()
                    : programMetadataExtractor.extract(
                        bottle: bottle,
                        programPath: hostPath,
                      );
                return WineProcessRecord(
                  bottleId: bottle.id,
                  processId: process.processId,
                  executable: process.executable,
                  hostPath: Option.fromNullable(hostPath),
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
  final bottle = _findBottle(
    bottlesResult.getOrElse((_) => const <BottleRecord>[]),
    bottleId,
  );
  if (bottle == null) {
    return _bottleNotFoundError(bottleId);
  }

  final request = programRunPlanner.planWineProcessKill(
    bottle: bottle,
    processId: processId,
  );
  final result = runner.run(request);
  final record = switch (result) {
    ProgramRunCompleted(:final processExitCode) => WineProcessTerminationRecord(
      bottleId: bottle.id,
      processId: processId,
      status: processExitCode == 0 ? 'terminated' : 'failed',
      runnerKind: request.runnerKind,
      executable: request.executable,
      argv: request.argv,
      processExitCode: processExitCode,
    ),
    ProgramRunFailed(:final message) => WineProcessTerminationRecord(
      bottleId: bottle.id,
      processId: processId,
      status: 'failed',
      runnerKind: request.runnerKind,
      executable: request.executable,
      argv: request.argv,
      message: message,
    ),
  };

  return _wineProcessTerminationJsonResult(<WineProcessTerminationRecord>[
    record,
  ], recordsKey: 'processes');
}
