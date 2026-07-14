import 'dart:async';
import 'dart:convert';

import '../bottles/bottle_summary.dart';
import 'bottle_create_contract.dart';
import 'bottle_detail_contract.dart';
import 'bottle_metadata_repair_contract.dart';
import 'konyak_cli_bottle_payload_parsers.dart';
import 'konyak_cli_bottle_result_types.dart';
import 'konyak_cli_client.dart' show KonyakCliClient;
import 'konyak_cli_failure_messages.dart';
import 'konyak_cli_result_helpers.dart';

extension KonyakCliBottleCommands on KonyakCliClient {
  Future<BottleMetadataRepairLoadResult> discardInvalidBottleProfiles(
    String storageId,
  ) async {
    final result = await run([
      'repair-bottle-metadata',
      storageId,
      '--action',
      'discard-invalid-profiles',
      '--json',
    ]);
    final parsed = parseBottleMetadataRepairPayload(result.stdout);

    return switch (parsed) {
      ParsedBottleMetadataRepair(:final repair) when result.exitCode == 0 =>
        RepairedBottleMetadata(repair),
      ParsedBottleMetadataRepair() ||
      BottleMetadataRepairParseFailure() => BottleMetadataRepairLoadFailure(
        exitCode: result.exitCode,
        message: operationFailureMessage(result, 'repair-bottle-metadata'),
        diagnostic: result.stderr,
      ),
    };
  }

  Future<BottleCreateLoadResult> createBottle({
    required String name,
    required String windowsVersion,
  }) async {
    final result = await run([
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
        message: createFailureMessage(result),
        diagnostic: result.stderr,
      ),
    };
  }

  Future<BottleArchiveExportLoadResult> exportBottleArchive({
    required String bottleId,
    required String archivePath,
  }) async {
    final result = await run([
      'export-bottle-archive',
      bottleId,
      '--archive',
      archivePath,
      '--json',
    ]);

    final parsed = parseBottleArchiveExportPayload(result.stdout);
    return switch (parsed) {
      ExportedBottleArchive() when result.exitCode == 0 => parsed,
      ExportedBottleArchive() ||
      BottleArchiveExportLoadFailure() => BottleArchiveExportLoadFailure(
        exitCode: result.exitCode,
        message: operationFailureMessage(result, 'export-bottle-archive'),
        diagnostic: result.stderr,
      ),
    };
  }

  Future<BottleArchiveImportLoadResult> importBottleArchive({
    required String archivePath,
  }) async {
    final result = await run([
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
        message: operationFailureMessage(result, 'import-bottle-archive'),
        diagnostic: result.stderr,
      ),
    };
  }

  Future<BottleUpdateLoadResult> setWindowsVersion({
    required String bottleId,
    required String windowsVersion,
  }) async {
    final result = await run([
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
        message: updateFailureMessage(result),
        diagnostic: result.stderr,
      ),
    };
  }

  Future<BottleUpdateLoadResult> setRuntimeSettings({
    required String bottleId,
    required BottleRuntimeSettingsSummary runtimeSettings,
  }) async {
    final result = await run([
      'set-runtime-settings',
      bottleId,
      '--settings-json',
      jsonEncode(runtimeSettings.toJson()),
      '--json',
    ]);

    return bottleUpdateResultFromCommand(
      result: result,
      command: 'set-runtime-settings',
    );
  }

  Future<BottleDeleteLoadResult> deleteBottle(String bottleId) async {
    final result = await run(['delete-bottle', bottleId, '--json']);
    final parsed = parseBottleDeletePayload(result.stdout);

    return switch (parsed) {
      ParsedBottleDelete(:final bottle) when result.exitCode == 0 =>
        DeletedBottle(bottle),
      BottleDeleteNotFound(:final bottleId, :final message)
          when result.exitCode == 66 =>
        MissingBottleDelete(bottleId: bottleId, message: message),
      ParsedBottleDelete() ||
      BottleDeleteNotFound() ||
      BottleDeleteParseFailure() => BottleDeleteLoadFailure(
        exitCode: result.exitCode,
        message: deleteFailureMessage(result),
        diagnostic: result.stderr,
      ),
    };
  }

  Future<BottleUpdateLoadResult> renameBottle({
    required String bottleId,
    required String name,
  }) async {
    final result = await run([
      'rename-bottle',
      bottleId,
      '--name',
      name,
      '--json',
    ]);

    return bottleUpdateResultFromCommand(
      result: result,
      command: 'rename-bottle',
    );
  }

  Future<BottleUpdateLoadResult> moveBottle({
    required String bottleId,
    required String path,
  }) async {
    final result = await run([
      'move-bottle',
      bottleId,
      '--path',
      path,
      '--json',
    ]);

    return bottleUpdateResultFromCommand(
      result: result,
      command: 'move-bottle',
    );
  }
}
