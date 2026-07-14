import 'dart:convert';

import '../bottles/bottle_summary.dart';
import '../bottles/invalid_bottle_record.dart';
import 'bottle_record_contract.dart';

export '../bottles/invalid_bottle_record.dart';

const bottleListSchemaVersion = 1;

sealed class BottleListParseResult {
  const BottleListParseResult();
}

final class ParsedBottleList extends BottleListParseResult {
  const ParsedBottleList({required this.bottles, required this.invalidBottles});

  final List<BottleSummary> bottles;
  final List<InvalidBottleRecord> invalidBottles;
}

final class BottleListParseFailure extends BottleListParseResult {
  const BottleListParseFailure(this.message);

  final String message;
}

BottleListParseResult parseBottleListPayload(String payload) {
  final Object? decoded;

  try {
    decoded = jsonDecode(payload);
  } on FormatException {
    return const BottleListParseFailure(
      'Bottle list payload is not valid JSON.',
    );
  }

  if (decoded is! Map<String, dynamic>) {
    return const BottleListParseFailure(
      'Bottle list payload must be an object.',
    );
  }

  final Object? schemaVersion = decoded['schemaVersion'];
  if (schemaVersion != bottleListSchemaVersion) {
    return const BottleListParseFailure(
      'Unsupported bottle list schema version.',
    );
  }

  final Object? bottleValues = decoded['bottles'];
  if (bottleValues is! List<dynamic>) {
    return const BottleListParseFailure(
      'Bottle list payload must contain a bottles array.',
    );
  }

  final bottles = <BottleSummary>[];
  final storageIds = <String>{};
  for (final bottleValue in bottleValues) {
    switch (parseBottleSummary(bottleValue)) {
      case ParsedBottleSummary(:final bottle):
        if (!storageIds.add(bottle.id)) {
          return const BottleListParseFailure(
            'Bottle list payload contains duplicate bottle IDs.',
          );
        }
        bottles.add(bottle);
      case InvalidBottleSummary():
        return const BottleListParseFailure(
          'Bottle list payload contains an invalid bottle record.',
        );
    }
  }

  final Object? invalidBottleValues = decoded['invalidBottles'];
  if (invalidBottleValues != null && invalidBottleValues is! List<dynamic>) {
    return const BottleListParseFailure(
      'Bottle list payload invalidBottles must be an array.',
    );
  }

  final invalidBottles = <InvalidBottleRecord>[];
  for (final invalidBottleValue
      in invalidBottleValues as List<dynamic>? ?? const <dynamic>[]) {
    switch (_parseInvalidBottleRecord(invalidBottleValue)) {
      case _ParsedInvalidBottleRecord(:final record):
        if (!storageIds.add(record.storageId)) {
          return const BottleListParseFailure(
            'Bottle list payload contains duplicate bottle IDs.',
          );
        }
        invalidBottles.add(record);
      case _InvalidInvalidBottleRecord():
        return const BottleListParseFailure(
          'Bottle list payload contains an invalid invalid-bottle record.',
        );
    }
  }

  return ParsedBottleList(
    bottles: List.unmodifiable(bottles),
    invalidBottles: List.unmodifiable(invalidBottles),
  );
}

sealed class _InvalidBottleRecordParseResult {
  const _InvalidBottleRecordParseResult();
}

final class _ParsedInvalidBottleRecord extends _InvalidBottleRecordParseResult {
  const _ParsedInvalidBottleRecord(this.record);

  final InvalidBottleRecord record;
}

final class _InvalidInvalidBottleRecord
    extends _InvalidBottleRecordParseResult {
  const _InvalidInvalidBottleRecord();
}

_InvalidBottleRecordParseResult _parseInvalidBottleRecord(Object? value) {
  if (value is! Map<String, dynamic>) {
    return const _InvalidInvalidBottleRecord();
  }

  final storageId = value['storageId'];
  final path = value['path'];
  final code = switch (value['code']) {
    'invalidProgramProfiles' => InvalidBottleCode.invalidProgramProfiles,
    'invalidBottleMetadata' => InvalidBottleCode.invalidBottleMetadata,
    _ => null,
  };
  final message = value['message'];
  final recoveryActionValues = value['recoveryActions'];
  if (storageId is! String ||
      storageId.trim().isEmpty ||
      path is! String ||
      path.trim().isEmpty ||
      code == null ||
      message is! String ||
      message.trim().isEmpty ||
      recoveryActionValues is! List<dynamic>) {
    return const _InvalidInvalidBottleRecord();
  }

  final recoveryActions = <InvalidBottleRecoveryAction>[];
  for (final actionValue in recoveryActionValues) {
    switch (actionValue) {
      case 'discardInvalidProfiles':
        recoveryActions.add(InvalidBottleRecoveryAction.discardInvalidProfiles);
      default:
        return const _InvalidInvalidBottleRecord();
    }
  }

  return _ParsedInvalidBottleRecord(
    InvalidBottleRecord(
      storageId: storageId,
      path: path,
      code: code,
      message: message,
      recoveryActions: recoveryActions,
    ),
  );
}
