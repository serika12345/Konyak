import 'dart:convert';

import 'konyak_cli_winetricks_result_types.dart';

sealed class WinetricksCategorySummaryParseResult {
  const WinetricksCategorySummaryParseResult();
}

final class ParsedWinetricksCategorySummary
    extends WinetricksCategorySummaryParseResult {
  const ParsedWinetricksCategorySummary(this.category);

  final WinetricksCategorySummary category;
}

final class InvalidWinetricksCategorySummary
    extends WinetricksCategorySummaryParseResult {
  const InvalidWinetricksCategorySummary();
}

sealed class WinetricksVerbSummaryParseResult {
  const WinetricksVerbSummaryParseResult();
}

final class ParsedWinetricksVerbSummary
    extends WinetricksVerbSummaryParseResult {
  const ParsedWinetricksVerbSummary(this.verb);

  final WinetricksVerbSummary verb;
}

final class InvalidWinetricksVerbSummary
    extends WinetricksVerbSummaryParseResult {
  const InvalidWinetricksVerbSummary();
}

WinetricksVerbListLoadResult parseWinetricksVerbListPayload(String payload) {
  final Object? decoded;
  try {
    decoded = jsonDecode(payload);
  } on FormatException catch (error) {
    return WinetricksVerbListLoadFailure(
      exitCode: 0,
      message: error.message,
      diagnostic: '',
    );
  }

  if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
    return const WinetricksVerbListLoadFailure(
      exitCode: 0,
      message: 'Unsupported winetricks verb list payload.',
      diagnostic: '',
    );
  }

  final error = decoded['error'];
  if (error is Map<String, Object?>) {
    final message = error['message'];
    return WinetricksVerbListLoadFailure(
      exitCode: 0,
      message: message is String ? message : 'Winetricks verb list failed.',
      diagnostic: '',
    );
  }

  final winetricks = decoded['winetricks'];
  if (winetricks is! Map<String, Object?>) {
    return const WinetricksVerbListLoadFailure(
      exitCode: 0,
      message: 'Missing winetricks payload.',
      diagnostic: '',
    );
  }

  final categories = winetricks['categories'];
  if (categories is! List<Object?>) {
    return const WinetricksVerbListLoadFailure(
      exitCode: 0,
      message: 'Invalid winetricks categories payload.',
      diagnostic: '',
    );
  }

  final parsedCategories = <WinetricksCategorySummary>[];
  for (final category in categories) {
    switch (parseWinetricksCategorySummary(category)) {
      case ParsedWinetricksCategorySummary(:final category):
        parsedCategories.add(category);
      case InvalidWinetricksCategorySummary():
        return const WinetricksVerbListLoadFailure(
          exitCode: 0,
          message: 'Invalid winetricks category record.',
          diagnostic: '',
        );
    }
  }

  return LoadedWinetricksVerbs(categories: parsedCategories);
}

WinetricksCategorySummaryParseResult parseWinetricksCategorySummary(
  Object? value,
) {
  if (value is! Map<String, Object?>) {
    return const InvalidWinetricksCategorySummary();
  }

  final id = value['id'];
  final name = value['name'];
  final verbs = value['verbs'];
  if (id is! String || name is! String || verbs is! List<Object?>) {
    return const InvalidWinetricksCategorySummary();
  }

  final parsedVerbs = <WinetricksVerbSummary>[];
  for (final verb in verbs) {
    switch (parseWinetricksVerbSummary(verb)) {
      case ParsedWinetricksVerbSummary(:final verb):
        parsedVerbs.add(verb);
      case InvalidWinetricksVerbSummary():
        return const InvalidWinetricksCategorySummary();
    }
  }

  return ParsedWinetricksCategorySummary(
    WinetricksCategorySummary(id: id, name: name, verbs: parsedVerbs),
  );
}

WinetricksVerbSummaryParseResult parseWinetricksVerbSummary(Object? value) {
  if (value is! Map<String, Object?>) {
    return const InvalidWinetricksVerbSummary();
  }

  final id = value['id'];
  final name = value['name'];
  final description = value['description'];
  if (id is! String || name is! String || description is! String) {
    return const InvalidWinetricksVerbSummary();
  }

  return ParsedWinetricksVerbSummary(
    WinetricksVerbSummary(id: id, name: name, description: description),
  );
}
