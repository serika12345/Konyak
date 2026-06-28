import 'dart:convert';

import 'konyak_cli_winetricks_result_types.dart';

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
    final parsedCategory = parseWinetricksCategorySummary(category);
    if (parsedCategory == null) {
      return const WinetricksVerbListLoadFailure(
        exitCode: 0,
        message: 'Invalid winetricks category record.',
        diagnostic: '',
      );
    }

    parsedCategories.add(parsedCategory);
  }

  return LoadedWinetricksVerbs(categories: parsedCategories);
}

WinetricksCategorySummary? parseWinetricksCategorySummary(Object? value) {
  if (value is! Map<String, Object?>) {
    return null;
  }

  final id = value['id'];
  final name = value['name'];
  final verbs = value['verbs'];
  if (id is! String || name is! String || verbs is! List<Object?>) {
    return null;
  }

  final parsedVerbs = <WinetricksVerbSummary>[];
  for (final verb in verbs) {
    final parsedVerb = parseWinetricksVerbSummary(verb);
    if (parsedVerb == null) {
      return null;
    }

    parsedVerbs.add(parsedVerb);
  }

  return WinetricksCategorySummary(id: id, name: name, verbs: parsedVerbs);
}

WinetricksVerbSummary? parseWinetricksVerbSummary(Object? value) {
  if (value is! Map<String, Object?>) {
    return null;
  }

  final id = value['id'];
  final name = value['name'];
  final description = value['description'];
  if (id is! String || name is! String || description is! String) {
    return null;
  }

  return WinetricksVerbSummary(id: id, name: name, description: description);
}
