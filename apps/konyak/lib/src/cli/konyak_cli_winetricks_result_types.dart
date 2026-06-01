part of 'konyak_cli_client.dart';

final class WinetricksVerbSummary {
  const WinetricksVerbSummary({
    required this.id,
    required this.name,
    required this.description,
  });

  final String id;
  final String name;
  final String description;
}

final class WinetricksCategorySummary {
  WinetricksCategorySummary({
    required this.id,
    required this.name,
    required List<WinetricksVerbSummary> verbs,
  }) : verbs = List.unmodifiable(verbs);

  final String id;
  final String name;
  final List<WinetricksVerbSummary> verbs;
}

sealed class WinetricksVerbListLoadResult {
  const WinetricksVerbListLoadResult();
}

final class LoadedWinetricksVerbs extends WinetricksVerbListLoadResult {
  LoadedWinetricksVerbs({required List<WinetricksCategorySummary> categories})
    : categories = List.unmodifiable(categories);

  final List<WinetricksCategorySummary> categories;
}

final class WinetricksVerbListLoadFailure extends WinetricksVerbListLoadResult {
  const WinetricksVerbListLoadFailure({
    required this.exitCode,
    required this.message,
    required this.diagnostic,
  });

  final int exitCode;
  final String message;
  final String diagnostic;
}
