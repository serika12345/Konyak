import 'dart:convert';

import '../bottles/bottle_summary.dart';
import 'bottle_record_contract.dart';

const bottleDetailSchemaVersion = 1;

sealed class BottleDetailParseResult {
  const BottleDetailParseResult();
}

sealed class _BottleDetailNotFoundParseResult {
  const _BottleDetailNotFoundParseResult();
}

final class _ParsedBottleDetailNotFound
    extends _BottleDetailNotFoundParseResult {
  const _ParsedBottleDetailNotFound(this.notFound);

  final BottleDetailNotFound notFound;
}

final class _NoBottleDetailNotFound extends _BottleDetailNotFoundParseResult {
  const _NoBottleDetailNotFound();
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

  switch (_parseBottleNotFound(decoded['error'])) {
    case _ParsedBottleDetailNotFound(:final notFound):
      return notFound;
    case _NoBottleDetailNotFound():
      break;
  }

  return switch (parseBottleSummary(decoded['bottle'])) {
    ParsedBottleSummary(:final bottle) => ParsedBottleDetail(bottle),
    InvalidBottleSummary() => const BottleDetailParseFailure(
      'Bottle detail payload contains an invalid bottle record.',
    ),
  };
}

_BottleDetailNotFoundParseResult _parseBottleNotFound(Object? value) {
  if (value is! Map<String, dynamic>) {
    return const _NoBottleDetailNotFound();
  }

  final Object? code = value['code'];
  final Object? message = value['message'];
  final Object? bottleId = value['bottleId'];

  if (code != 'bottleNotFound' || message is! String || bottleId is! String) {
    return const _NoBottleDetailNotFound();
  }

  return _ParsedBottleDetailNotFound(
    BottleDetailNotFound(bottleId: bottleId, message: message),
  );
}
