import 'dart:convert';

import '../bottles/bottle_summary.dart';
import 'bottle_record_contract.dart';

const bottleListSchemaVersion = 1;

sealed class BottleListParseResult {
  const BottleListParseResult();
}

final class ParsedBottleList extends BottleListParseResult {
  const ParsedBottleList(this.bottles);

  final List<BottleSummary> bottles;
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
  for (final bottleValue in bottleValues) {
    switch (parseBottleSummary(bottleValue)) {
      case ParsedBottleSummary(:final bottle):
        bottles.add(bottle);
      case InvalidBottleSummary():
        return const BottleListParseFailure(
          'Bottle list payload contains an invalid bottle record.',
        );
    }
  }

  return ParsedBottleList(List.unmodifiable(bottles));
}
