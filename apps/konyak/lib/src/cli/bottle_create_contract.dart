import 'dart:convert';

import '../bottles/bottle_summary.dart';
import 'bottle_record_contract.dart';

const bottleCreateSchemaVersion = 1;

sealed class BottleCreateParseResult {
  const BottleCreateParseResult();
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

  final conflict = _parseBottleConflict(decoded['error']);
  if (conflict != null) {
    return conflict;
  }

  final bottle = parseBottleSummary(decoded['bottle']);
  if (bottle == null) {
    return const BottleCreateParseFailure(
      'Bottle create payload contains an invalid bottle record.',
    );
  }

  return ParsedBottleCreate(bottle);
}

BottleCreateConflict? _parseBottleConflict(Object? value) {
  if (value is! Map<String, dynamic>) {
    return null;
  }

  final Object? code = value['code'];
  final Object? message = value['message'];
  final Object? bottleId = value['bottleId'];

  if (code != 'bottleAlreadyExists' ||
      message is! String ||
      bottleId is! String) {
    return null;
  }

  return BottleCreateConflict(bottleId: bottleId, message: message);
}
