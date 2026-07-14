import 'dart:convert';

import '../bottles/bottle_summary.dart';
import '../bottles/invalid_bottle_record.dart';
import 'bottle_record_contract.dart';

sealed class BottleMetadataRepairParseResult {
  const BottleMetadataRepairParseResult();
}

final class ParsedBottleMetadataRepair extends BottleMetadataRepairParseResult {
  const ParsedBottleMetadataRepair(this.repair);

  final BottleMetadataRepair repair;
}

final class BottleMetadataRepairParseFailure
    extends BottleMetadataRepairParseResult {
  const BottleMetadataRepairParseFailure(this.message);

  final String message;
}

final class BottleMetadataRepair {
  const BottleMetadataRepair({
    required this.storageId,
    required this.action,
    required this.backupPath,
    required this.bottle,
  });

  final String storageId;
  final InvalidBottleRecoveryAction action;
  final String backupPath;
  final BottleSummary bottle;
}

BottleMetadataRepairParseResult parseBottleMetadataRepairPayload(
  String payload,
) {
  final dynamic decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException {
    return const BottleMetadataRepairParseFailure(
      'Bottle metadata repair payload is not valid JSON.',
    );
  }

  if (decoded is! Map<String, dynamic> || decoded['schemaVersion'] != 1) {
    return const BottleMetadataRepairParseFailure(
      'Unsupported bottle metadata repair schema version.',
    );
  }

  final repair = decoded['bottleMetadataRepair'];
  if (repair is! Map<String, dynamic>) {
    return const BottleMetadataRepairParseFailure(
      'Bottle metadata repair payload is missing its result.',
    );
  }

  final storageId = repair['storageId'];
  final action = repair['action'];
  final backupPath = repair['backupPath'];
  if (storageId is! String ||
      storageId.trim().isEmpty ||
      action != 'discardInvalidProfiles' ||
      backupPath is! String ||
      backupPath.trim().isEmpty) {
    return const BottleMetadataRepairParseFailure(
      'Bottle metadata repair payload contains invalid fields.',
    );
  }

  return switch (parseBottleSummary(repair['bottle'])) {
    ParsedBottleSummary(:final bottle) => ParsedBottleMetadataRepair(
      BottleMetadataRepair(
        storageId: storageId,
        action: InvalidBottleRecoveryAction.discardInvalidProfiles,
        backupPath: backupPath,
        bottle: bottle,
      ),
    ),
    InvalidBottleSummary() => const BottleMetadataRepairParseFailure(
      'Bottle metadata repair payload contains an invalid bottle record.',
    ),
  };
}
