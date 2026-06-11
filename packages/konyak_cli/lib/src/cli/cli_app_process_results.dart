part of '../../konyak_cli.dart';

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

const _wineProcessListConcurrency = 4;

Future<CliResult> _listWineProcessesJsonResultAsync({
  required BottleCatalog bottleCatalog,
  required ProgramRunPlanner programRunPlanner,
  required AsyncProgramRunner programRunner,
  required AsyncProgramMetadataExtractor programMetadataExtractor,
  required HostProcessSnapshotReader hostProcessSnapshotReader,
}) async {
  final bottlesResult = bottleCatalog.listBottles();
  final failure = bottlesResult.fold<CliResult?>(
    _bottleCatalogFailureJsonResult,
    (_) => null,
  );
  if (failure != null) {
    return failure;
  }

  final bottles = bottlesResult.getOrElse((_) => const <BottleRecord>[]);
  final activeBottles = await _activeWineProcessBottles(
    bottles: bottles,
    hostProcessSnapshotReader: hostProcessSnapshotReader,
  );
  final metadataCache = _AsyncProgramMetadataCache(programMetadataExtractor);
  final bottleResults =
      await _mapWithBoundedConcurrency<
        BottleRecord,
        _AsyncBottleWineProcessListResult
      >(
        activeBottles,
        _wineProcessListConcurrency,
        (bottle) => _listBottleWineProcessesAsync(
          bottle: bottle,
          programRunPlanner: programRunPlanner,
          programRunner: programRunner,
          metadataCache: metadataCache,
        ),
      );

  final records = <WineProcessRecord>[];
  for (final result in bottleResults) {
    final failure = result.failure;
    if (failure != null) {
      return failure;
    }
    records.addAll(result.records);
  }

  return _wineProcessListJsonResult(records);
}

Future<List<BottleRecord>> _activeWineProcessBottles({
  required List<BottleRecord> bottles,
  required HostProcessSnapshotReader hostProcessSnapshotReader,
}) async {
  if (bottles.isEmpty) {
    return const <BottleRecord>[];
  }

  final snapshot = await hostProcessSnapshotReader.read();
  if (snapshot.trim().isEmpty) {
    return const <BottleRecord>[];
  }

  return List.unmodifiable(
    bottles.where(
      (bottle) => _hostProcessSnapshotContainsBottle(
        snapshot: snapshot,
        bottle: bottle,
      ),
    ),
  );
}

bool _hostProcessSnapshotContainsBottle({
  required String snapshot,
  required BottleRecord bottle,
}) {
  final bottlePath = _normalizeFilesystemPath(bottle.path);
  if (bottlePath.isEmpty) {
    return false;
  }

  var start = snapshot.indexOf(bottlePath);
  while (start != -1) {
    final end = start + bottlePath.length;
    if (end >= snapshot.length ||
        _isHostProcessBottlePathBoundary(snapshot.codeUnitAt(end))) {
      return true;
    }

    start = snapshot.indexOf(bottlePath, start + 1);
  }

  return false;
}

bool _isHostProcessBottlePathBoundary(int codeUnit) {
  return codeUnit == 0x09 ||
      codeUnit == 0x0a ||
      codeUnit == 0x0d ||
      codeUnit == 0x20 ||
      codeUnit == 0x22 ||
      codeUnit == 0x27 ||
      codeUnit == 0x2f;
}

Future<_AsyncBottleWineProcessListResult> _listBottleWineProcessesAsync({
  required BottleRecord bottle,
  required ProgramRunPlanner programRunPlanner,
  required AsyncProgramRunner programRunner,
  required _AsyncProgramMetadataCache metadataCache,
}) async {
  final request = programRunPlanner.planWineProcessList(bottle: bottle);
  final result = await programRunner.run(request);
  switch (result) {
    case ProgramRunCompleted(:final processExitCode, :final stdout)
        when processExitCode == 0:
      final resolver = _AsyncWineProcessHostPathResolver(bottle: bottle);
      final records = await Future.wait(
        _parseWinedbgProcessList(stdout)
            .where((process) => !_isWineInfrastructureProcess(process))
            .map(
              (process) => _wineProcessRecordAsync(
                bottle: bottle,
                process: process,
                hostPathResolver: resolver,
                metadataCache: metadataCache,
              ),
            ),
      );
      return _AsyncBottleWineProcessListResult.records(records);
    case ProgramRunCompleted(:final processExitCode, :final stderr):
      return _AsyncBottleWineProcessListResult.failure(
        _jsonError(
          exitCode: 75,
          code: 'wineProcessListFailed',
          message:
              'Wine process list for `${bottle.id}` exited with code '
              '$processExitCode.',
          extra: <String, Object?>{'diagnostic': stderr},
        ),
      );
    case ProgramRunFailed(:final message):
      return _AsyncBottleWineProcessListResult.failure(
        _jsonError(
          exitCode: 75,
          code: 'wineProcessListFailed',
          message: message,
        ),
      );
  }
}

Future<WineProcessRecord> _wineProcessRecordAsync({
  required BottleRecord bottle,
  required _WinedbgProcess process,
  required _AsyncWineProcessHostPathResolver hostPathResolver,
  required _AsyncProgramMetadataCache metadataCache,
}) async {
  final hostPath = await hostPathResolver.hostPath(process.executable);
  final metadata = await hostPath.match(
    () async => const Option<ProgramMetadataRecord>.none(),
    (path) => metadataCache.extract(bottle: bottle, programPath: path),
  );
  return WineProcessRecord(
    bottleId: bottle.id,
    processId: process.processId,
    executable: process.executable,
    hostPath: hostPath,
    metadata: metadata,
  );
}

final class _AsyncBottleWineProcessListResult {
  _AsyncBottleWineProcessListResult.records(List<WineProcessRecord> records)
    : records = List.unmodifiable(records),
      failure = null;

  const _AsyncBottleWineProcessListResult.failure(this.failure)
    : records = const <WineProcessRecord>[];

  final List<WineProcessRecord> records;
  final CliResult? failure;
}

final class _AsyncProgramMetadataCache {
  _AsyncProgramMetadataCache(this._extractor);

  final AsyncProgramMetadataExtractor _extractor;
  final Map<String, Future<Option<ProgramMetadataRecord>>> _cache =
      <String, Future<Option<ProgramMetadataRecord>>>{};

  Future<Option<ProgramMetadataRecord>> extract({
    required BottleRecord bottle,
    required String programPath,
  }) {
    final key = '${bottle.id}\u0000${_normalizeFilesystemPath(programPath)}';
    return _cache.putIfAbsent(
      key,
      () => _extractor.extract(bottle: bottle, programPath: programPath),
    );
  }
}

Future<List<T>> _mapWithBoundedConcurrency<S, T>(
  List<S> items,
  int concurrency,
  Future<T> Function(S item) mapper,
) async {
  if (items.isEmpty) {
    return <T>[];
  }

  final workerCount = min(max(concurrency, 1), items.length);
  final results = List<T?>.filled(items.length, null);
  var nextIndex = 0;

  Future<void> worker() async {
    while (true) {
      final index = nextIndex;
      nextIndex += 1;
      if (index >= items.length) {
        return;
      }

      results[index] = await mapper(items[index]);
    }
  }

  await Future.wait(List<Future<void>>.generate(workerCount, (_) => worker()));
  return List<T>.unmodifiable(results.cast<T>());
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
