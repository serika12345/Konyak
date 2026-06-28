import 'dart:async';
import 'dart:math';

import 'package:fpdart/fpdart.dart';

import '../domain/app/app_settings_models.dart';
import '../domain/bottle/bottle_models.dart';
import '../domain/program/program_catalog_models.dart';
import '../domain/program/program_run_models.dart';
import '../domain/program/program_runner.dart';
import '../domain/update/update_records.dart';
import '../io/wine_process_metadata.dart';
import '../io/wine_process_metadata_io.dart';
import '../repository/repository_interfaces.dart';
import '../shared/common_helpers.dart';
import 'cli_bottle_results.dart';
import 'cli_json_helpers.dart';
import 'cli_program_run_handlers.dart';
import 'cli_result_model.dart';

CliResult appSettingsJsonResult(AppSettingsRecord settings) {
  return jsonSuccess(<String, Object?>{'appSettings': settings.toJson()});
}

CliResult appUpdateJsonResult(AppUpdateRecord update) {
  return jsonSuccess(<String, Object?>{'appUpdate': update.toJson()});
}

CliResult appUpdateInstallJsonResult(AppUpdateInstallRecord install) {
  return jsonSuccess(<String, Object?>{'appUpdateInstall': install.toJson()});
}

CliResult wineProcessTerminationJsonResult(
  List<WineProcessTerminationRecord> records, {
  String recordsKey = 'bottles',
}) {
  final hasFailures = records.any(
    (record) => record.status.value != 'terminated',
  );
  return jsonSuccess(<String, Object?>{
    'wineProcessTermination': <String, Object?>{
      'hasFailures': hasFailures,
      recordsKey: records
          .map((record) => record.toJson())
          .toList(growable: false),
    },
  }, exitCode: hasFailures ? 75 : 0);
}

CliResult wineProcessListJsonResult(List<WineProcessRecord> records) {
  return jsonSuccess(<String, Object?>{
    'wineProcesses': <String, Object?>{
      'processes': records
          .map((record) => record.toJson())
          .toList(growable: false),
    },
  });
}

CliResult terminateWineProcessesJsonResult({
  required BottleCatalog bottleCatalog,
  required ProgramRunPlanner programRunPlanner,
  required ProgramRunner? programRunner,
  Option<String> bottleId = const Option.none(),
}) {
  final runner = programRunner;
  if (runner == null) {
    return programRunnerUnavailableError();
  }

  return bottleCatalog.listBottles().match<CliResult>(
    bottleCatalogFailureJsonResult,
    (bottles) {
      final records = <WineProcessTerminationRecord>[];
      final targetBottles = bottleId.match(
        () => bottles,
        (id) => findBottle(bottles, id).match(
          () => const <BottleRecord>[],
          (bottle) => <BottleRecord>[bottle],
        ),
      );
      if (bottleId.isSome() && targetBottles.isEmpty) {
        return bottleId.match(
          () => bottleNotFoundError(''),
          bottleNotFoundError,
        );
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
                bottleId: bottle.id.value,
                status: isSuccessfulWineServerTerminationExit(processExitCode)
                    ? 'terminated'
                    : 'failed',
                runnerKind: request.runnerKind.value,
                executable: request.executable.value,
                argv: request.argv,
                processExitCode: Option.of(processExitCode),
              ),
            );
          case ProgramRunFailed(:final message):
            records.add(
              WineProcessTerminationRecord(
                bottleId: bottle.id.value,
                status: 'failed',
                runnerKind: request.runnerKind.value,
                executable: request.executable.value,
                argv: request.argv,
                message: Option.of(message),
              ),
            );
        }
      }

      return wineProcessTerminationJsonResult(records);
    },
  );
}

bool isSuccessfulWineServerTerminationExit(int processExitCode) {
  return processExitCode == 0 || processExitCode == 1;
}

CliResult listWineProcessesJsonResult({
  required BottleCatalog bottleCatalog,
  required ProgramRunPlanner programRunPlanner,
  required ProgramRunner? programRunner,
  required ProgramMetadataExtractor programMetadataExtractor,
}) {
  final runner = programRunner;
  if (runner == null) {
    return programRunnerUnavailableError();
  }

  return bottleCatalog.listBottles().match<CliResult>(
    bottleCatalogFailureJsonResult,
    (bottles) {
      final records = <WineProcessRecord>[];
      for (final bottle in bottles) {
        final request = programRunPlanner.planWineProcessList(bottle: bottle);
        final result = runner.run(request);
        switch (result) {
          case ProgramRunCompleted(:final processExitCode, :final stdout)
              when processExitCode == 0:
            records.addAll(
              parseWinedbgProcessList(stdout)
                  .where((process) {
                    return !isWineInfrastructureProcess(process);
                  })
                  .map((process) {
                    final hostPath = wineProcessHostPath(
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
                      bottleId: bottle.id.value,
                      processId: process.processId,
                      executable: process.executable,
                      hostPath: hostPath,
                      metadata: metadata,
                    );
                  }),
            );
          case ProgramRunCompleted(:final processExitCode, :final stderr):
            return jsonError(
              exitCode: 75,
              code: 'wineProcessListFailed',
              message:
                  'Wine process list for `${bottle.id.value}` exited with code '
                  '$processExitCode.',
              extra: <String, Object?>{'diagnostic': stderr},
            );
          case ProgramRunFailed(:final message):
            return jsonError(
              exitCode: 75,
              code: 'wineProcessListFailed',
              message: message,
            );
        }
      }

      return wineProcessListJsonResult(records);
    },
  );
}

const wineProcessListConcurrency = 4;

Future<CliResult> listWineProcessesJsonResultAsync({
  required BottleCatalog bottleCatalog,
  required ProgramRunPlanner programRunPlanner,
  required AsyncProgramRunner programRunner,
  required AsyncProgramMetadataExtractor programMetadataExtractor,
  required HostProcessSnapshotReader hostProcessSnapshotReader,
}) async {
  return bottleCatalog.listBottles().match<Future<CliResult>>(
    (message) async => bottleCatalogFailureJsonResult(message),
    (bottles) async {
      final activeBottles = await activeWineProcessBottles(
        bottles: bottles,
        hostProcessSnapshotReader: hostProcessSnapshotReader,
      );
      final metadataCache = AsyncProgramMetadataCache(programMetadataExtractor);
      final bottleResults =
          await mapWithBoundedConcurrency<
            BottleRecord,
            AsyncBottleWineProcessListResult
          >(
            activeBottles,
            wineProcessListConcurrency,
            (bottle) => listBottleWineProcessesAsync(
              bottle: bottle,
              programRunPlanner: programRunPlanner,
              programRunner: programRunner,
              metadataCache: metadataCache,
            ),
          );

      final records = <WineProcessRecord>[];
      for (final result in bottleResults) {
        switch (result) {
          case AsyncBottleWineProcessListFailure(:final failure):
            return failure;
          case AsyncBottleWineProcessListRecords(records: final bottleRecords):
            records.addAll(bottleRecords);
        }
      }

      return wineProcessListJsonResult(records);
    },
  );
}

Future<List<BottleRecord>> activeWineProcessBottles({
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
      (bottle) =>
          hostProcessSnapshotContainsBottle(snapshot: snapshot, bottle: bottle),
    ),
  );
}

bool hostProcessSnapshotContainsBottle({
  required String snapshot,
  required BottleRecord bottle,
}) {
  final bottlePath = normalizeFilesystemPath(bottle.path.value);
  if (bottlePath.isEmpty) {
    return false;
  }

  var start = snapshot.indexOf(bottlePath);
  while (start != -1) {
    final end = start + bottlePath.length;
    if (end >= snapshot.length ||
        isHostProcessBottlePathBoundary(snapshot.codeUnitAt(end))) {
      return true;
    }

    start = snapshot.indexOf(bottlePath, start + 1);
  }

  return false;
}

bool isHostProcessBottlePathBoundary(int codeUnit) {
  return codeUnit == 0x09 ||
      codeUnit == 0x0a ||
      codeUnit == 0x0d ||
      codeUnit == 0x20 ||
      codeUnit == 0x22 ||
      codeUnit == 0x27 ||
      codeUnit == 0x2f;
}

Future<AsyncBottleWineProcessListResult> listBottleWineProcessesAsync({
  required BottleRecord bottle,
  required ProgramRunPlanner programRunPlanner,
  required AsyncProgramRunner programRunner,
  required AsyncProgramMetadataCache metadataCache,
}) async {
  final request = programRunPlanner.planWineProcessList(bottle: bottle);
  final result = await programRunner.run(request);
  switch (result) {
    case ProgramRunCompleted(:final processExitCode, :final stdout)
        when processExitCode == 0:
      final resolver = AsyncWineProcessHostPathResolver(bottle: bottle);
      final records = await Future.wait(
        parseWinedbgProcessList(stdout)
            .where((process) => !isWineInfrastructureProcess(process))
            .map(
              (process) => wineProcessRecordAsync(
                bottle: bottle,
                process: process,
                hostPathResolver: resolver,
                metadataCache: metadataCache,
              ),
            ),
      );
      return AsyncBottleWineProcessListRecords(records);
    case ProgramRunCompleted(:final processExitCode, :final stderr):
      return AsyncBottleWineProcessListFailure(
        jsonError(
          exitCode: 75,
          code: 'wineProcessListFailed',
          message:
              'Wine process list for `${bottle.id.value}` exited with code '
              '$processExitCode.',
          extra: <String, Object?>{'diagnostic': stderr},
        ),
      );
    case ProgramRunFailed(:final message):
      return AsyncBottleWineProcessListFailure(
        jsonError(
          exitCode: 75,
          code: 'wineProcessListFailed',
          message: message,
        ),
      );
  }
}

Future<WineProcessRecord> wineProcessRecordAsync({
  required BottleRecord bottle,
  required WinedbgProcess process,
  required AsyncWineProcessHostPathResolver hostPathResolver,
  required AsyncProgramMetadataCache metadataCache,
}) async {
  final hostPath = await hostPathResolver.hostPath(process.executable);
  final metadata = await hostPath.match(
    () async => const Option<ProgramMetadataRecord>.none(),
    (path) => metadataCache.extract(bottle: bottle, programPath: path),
  );
  return WineProcessRecord(
    bottleId: bottle.id.value,
    processId: process.processId,
    executable: process.executable,
    hostPath: hostPath,
    metadata: metadata,
  );
}

sealed class AsyncBottleWineProcessListResult {
  const AsyncBottleWineProcessListResult();
}

final class AsyncBottleWineProcessListRecords
    extends AsyncBottleWineProcessListResult {
  AsyncBottleWineProcessListRecords(List<WineProcessRecord> records)
    : records = List.unmodifiable(records);

  final List<WineProcessRecord> records;
}

final class AsyncBottleWineProcessListFailure
    extends AsyncBottleWineProcessListResult {
  const AsyncBottleWineProcessListFailure(this.failure);

  final CliResult failure;
}

final class AsyncProgramMetadataCache {
  AsyncProgramMetadataCache(this.extractor);

  final AsyncProgramMetadataExtractor extractor;
  final Map<String, Future<Option<ProgramMetadataRecord>>> cache =
      <String, Future<Option<ProgramMetadataRecord>>>{};

  Future<Option<ProgramMetadataRecord>> extract({
    required BottleRecord bottle,
    required String programPath,
  }) {
    final key =
        '${bottle.id.value}\u0000${normalizeFilesystemPath(programPath)}';
    return cache.putIfAbsent(
      key,
      () => extractor.extract(bottle: bottle, programPath: programPath),
    );
  }
}

Future<List<T>> mapWithBoundedConcurrency<S, T>(
  List<S> items,
  int concurrency,
  Future<T> Function(S item) mapper,
) async {
  if (items.isEmpty) {
    return <T>[];
  }

  final workerCount = min(max(concurrency, 1), items.length);
  final indexedResults = <(int, T)>[];
  var nextIndex = 0;

  Future<void> worker() async {
    while (true) {
      final index = nextIndex;
      nextIndex += 1;
      if (index >= items.length) {
        return;
      }

      indexedResults.add((index, await mapper(items[index])));
    }
  }

  await Future.wait(List<Future<void>>.generate(workerCount, (_) => worker()));
  indexedResults.sort((left, right) => left.$1.compareTo(right.$1));
  return List<T>.unmodifiable(indexedResults.map((result) => result.$2));
}

CliResult terminateWineProcessJsonResult({
  required BottleCatalog bottleCatalog,
  required ProgramRunPlanner programRunPlanner,
  required ProgramRunner? programRunner,
  required String bottleId,
  required String processId,
}) {
  final runner = programRunner;
  if (runner == null) {
    return programRunnerUnavailableError();
  }

  return bottleCatalog.listBottles().match<CliResult>(
    bottleCatalogFailureJsonResult,
    (bottles) {
      final bottleOption = findBottle(bottles, bottleId);
      return bottleOption.match(() => bottleNotFoundError(bottleId), (bottle) {
        final request = programRunPlanner.planWineProcessKill(
          bottle: bottle,
          processId: processId,
        );
        final result = runner.run(request);
        final record = switch (result) {
          ProgramRunCompleted(:final processExitCode) =>
            WineProcessTerminationRecord(
              bottleId: bottle.id.value,
              processId: Option.of(processId),
              status: processExitCode == 0 ? 'terminated' : 'failed',
              runnerKind: request.runnerKind.value,
              executable: request.executable.value,
              argv: request.argv,
              processExitCode: Option.of(processExitCode),
            ),
          ProgramRunFailed(:final message) => WineProcessTerminationRecord(
            bottleId: bottle.id.value,
            processId: Option.of(processId),
            status: 'failed',
            runnerKind: request.runnerKind.value,
            executable: request.executable.value,
            argv: request.argv,
            message: Option.of(message),
          ),
        };

        return wineProcessTerminationJsonResult(<WineProcessTerminationRecord>[
          record,
        ], recordsKey: 'processes');
      });
    },
  );
}
