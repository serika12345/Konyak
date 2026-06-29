import 'dart:convert';

import '../bottles/bottle_summary.dart';
import 'bottle_record_contract.dart';

const bottleCreateSchemaVersion = 1;

sealed class BottleCreateParseResult {
  const BottleCreateParseResult();
}

sealed class _BottleCreateConflictParseResult {
  const _BottleCreateConflictParseResult();
}

final class _ParsedBottleCreateConflict
    extends _BottleCreateConflictParseResult {
  const _ParsedBottleCreateConflict(this.conflict);

  final BottleCreateConflict conflict;
}

final class _NoBottleCreateConflict extends _BottleCreateConflictParseResult {
  const _NoBottleCreateConflict();
}

final class ParsedBottleCreate extends BottleCreateParseResult {
  const ParsedBottleCreate(this.bottle);

  final BottleSummary bottle;
}

final class BottleCreateConflict extends BottleCreateParseResult {
  const BottleCreateConflict({required this.bottleId, required this.message});

  final String bottleId;
  final String message;
}

final class BottleCreateParseFailure extends BottleCreateParseResult {
  const BottleCreateParseFailure(this.message);

  final String message;
}

BottleCreateParseResult parseBottleCreatePayload(String payload) {
  final Object? decoded;

  try {
    decoded = jsonDecode(payload);
  } on FormatException {
    return const BottleCreateParseFailure(
      'Bottle create payload is not valid JSON.',
    );
  }

  if (decoded is! Map<String, dynamic>) {
    return const BottleCreateParseFailure(
      'Bottle create payload must be an object.',
    );
  }

  final Object? schemaVersion = decoded['schemaVersion'];
  if (schemaVersion != bottleCreateSchemaVersion) {
    return const BottleCreateParseFailure(
      'Unsupported bottle create schema version.',
    );
  }

  switch (_parseBottleConflict(decoded['error'])) {
    case _ParsedBottleCreateConflict(:final conflict):
      return conflict;
    case _NoBottleCreateConflict():
      break;
  }

  return switch (parseBottleSummary(decoded['bottle'])) {
    ParsedBottleSummary(:final bottle) => ParsedBottleCreate(bottle),
    InvalidBottleSummary() => const BottleCreateParseFailure(
      'Bottle create payload contains an invalid bottle record.',
    ),
  };
}

_BottleCreateConflictParseResult _parseBottleConflict(Object? value) {
  if (value is! Map<String, dynamic>) {
    return const _NoBottleCreateConflict();
  }

  final Object? code = value['code'];
  final Object? message = value['message'];
  final Object? bottleId = value['bottleId'];

  if (code != 'bottleAlreadyExists' ||
      message is! String ||
      bottleId is! String) {
    return const _NoBottleCreateConflict();
  }

  return _ParsedBottleCreateConflict(
    BottleCreateConflict(bottleId: bottleId, message: message),
  );
}
