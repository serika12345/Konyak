import 'dart:convert';

import '../bottles/bottle_summary.dart';
import 'bottle_record_contract.dart';

const bottleDetailSchemaVersion = 1;

sealed class BottleDetailParseResult {
  const BottleDetailParseResult();
}

final class ParsedBottleDetail extends BottleDetailParseResult {
  const ParsedBottleDetail(this.bottle);

  final BottleSummary bottle;
}

final class BottleDetailNotFound extends BottleDetailParseResult {
  const BottleDetailNotFound({required this.bottleId, required this.message});

  final String bottleId;
  final String message;
}

final class BottleDetailParseFailure extends BottleDetailParseResult {
  const BottleDetailParseFailure(this.message);

  final String message;
}

BottleDetailParseResult parseBottleDetailPayload(String payload) {
  final Object? decoded;

  try {
    decoded = jsonDecode(payload);
  } on FormatException {
    return const BottleDetailParseFailure(
      'Bottle detail payload is not valid JSON.',
    );
  }

  if (decoded is! Map<String, dynamic>) {
    return const BottleDetailParseFailure(
      'Bottle detail payload must be an object.',
    );
  }

  final Object? schemaVersion = decoded['schemaVersion'];
  if (schemaVersion != bottleDetailSchemaVersion) {
    return const BottleDetailParseFailure(
      'Unsupported bottle detail schema version.',
    );
  }

  final notFound = _parseBottleNotFound(decoded['error']);
  if (notFound != null) {
    return notFound;
  }

  final bottle = parseBottleSummary(decoded['bottle']);
  if (bottle == null) {
    return const BottleDetailParseFailure(
      'Bottle detail payload contains an invalid bottle record.',
    );
  }

  return ParsedBottleDetail(bottle);
}

BottleDetailNotFound? _parseBottleNotFound(Object? value) {
  if (value is! Map<String, dynamic>) {
    return null;
  }

  final Object? code = value['code'];
  final Object? message = value['message'];
  final Object? bottleId = value['bottleId'];

  if (code != 'bottleNotFound' || message is! String || bottleId is! String) {
    return null;
  }

  return BottleDetailNotFound(bottleId: bottleId, message: message);
}
