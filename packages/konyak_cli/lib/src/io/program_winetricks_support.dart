import 'package:fpdart/fpdart.dart';

import '../domain/program/program_catalog_models.dart';
import '../domain/shared/domain_value_objects.dart';
import 'external_payload_helpers.dart';

List<WinetricksCategoryRecord> parseWinetricksVerbs(String content) {
  final state = content
      .split('\n')
      .fold(
        WinetricksVerbParseState.empty(),
        (state, line) => state.withLine(line),
      );
  return state.flushCurrentCategory().categories;
}

final class WinetricksVerbParseState {
  WinetricksVerbParseState({
    required Iterable<WinetricksCategoryRecord> categories,
    required this.currentCategory,
  }) : categories = List.unmodifiable(categories);

  factory WinetricksVerbParseState.empty() {
    return WinetricksVerbParseState(
      categories: <WinetricksCategoryRecord>[],
      currentCategory: const Option.none(),
    );
  }

  final List<WinetricksCategoryRecord> categories;
  final Option<PendingWinetricksCategory> currentCategory;

  WinetricksVerbParseState withLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      return this;
    }

    return winetricksCategoryId(
      trimmed,
    ).match(() => withVerbLine(trimmed), startCategory);
  }

  WinetricksVerbParseState startCategory(String id) {
    return winetricksCategoryName(id).match(
      () => flushCurrentCategory().withoutCurrentCategory(),
      (name) => flushCurrentCategory().withCurrentCategory(
        PendingWinetricksCategory(id: id, name: name, verbs: const []),
      ),
    );
  }

  WinetricksVerbParseState withVerbLine(String line) {
    return currentCategory.match(
      () => this,
      (category) => parseWinetricksVerbLine(line).match(
        () => this,
        (verb) => withCurrentCategory(category.withVerb(verb)),
      ),
    );
  }

  WinetricksVerbParseState flushCurrentCategory() {
    return currentCategory.match(
      () => this,
      (category) => WinetricksVerbParseState(
        categories: category.verbs.isEmpty
            ? categories
            : <WinetricksCategoryRecord>[...categories, category.toRecord()],
        currentCategory: const Option.none(),
      ),
    );
  }

  WinetricksVerbParseState withoutCurrentCategory() {
    return WinetricksVerbParseState(
      categories: categories,
      currentCategory: const Option.none(),
    );
  }

  WinetricksVerbParseState withCurrentCategory(
    PendingWinetricksCategory category,
  ) {
    return WinetricksVerbParseState(
      categories: categories,
      currentCategory: Option.of(category),
    );
  }
}

final class PendingWinetricksCategory {
  PendingWinetricksCategory({
    required this.id,
    required this.name,
    required Iterable<WinetricksVerbRecord> verbs,
  }) : verbs = List.unmodifiable(verbs);

  final String id;
  final String name;
  final List<WinetricksVerbRecord> verbs;

  PendingWinetricksCategory withVerb(WinetricksVerbRecord verb) {
    return PendingWinetricksCategory(
      id: id,
      name: name,
      verbs: <WinetricksVerbRecord>[...verbs, verb],
    );
  }

  WinetricksCategoryRecord toRecord() {
    return WinetricksCategoryRecord(
      id: WinetricksCategoryId(id),
      name: WinetricksCategoryName(name),
      verbs: verbs,
    );
  }
}

Option<String> winetricksCategoryId(String line) {
  if (!line.startsWith('=====') || !line.endsWith('=====')) {
    return const Option.none();
  }

  final id = line.replaceAll('=', '').trim().toLowerCase();
  return id.isEmpty ? const Option.none() : Option.of(id);
}

Option<String> winetricksCategoryName(String id) {
  return switch (id) {
    'apps' => Option.of('Apps'),
    'benchmarks' => Option.of('Benchmarks'),
    'dlls' => Option.of('DLLs'),
    'fonts' => Option.of('Fonts'),
    'games' => Option.of('Games'),
    'settings' => Option.of('Settings'),
    _ => const Option.none(),
  };
}

Option<WinetricksVerbRecord> parseWinetricksVerbLine(String line) {
  return nullableOption(RegExp(r'^(\S+)\s*(.*)$').firstMatch(line)).flatMap(
    (match) => nullableOption(match.group(1)).flatMap((rawName) {
      final name = rawName.trim();
      if (!isSupportedWinetricksVerb(name)) {
        return const Option.none();
      }

      return Option.of(
        WinetricksVerbRecord(
          id: WinetricksVerbId(name),
          name: WinetricksVerbName(name),
          description: WinetricksVerbDescription(
            nullableOption(match.group(2)).match(() => '', (value) => value),
          ),
        ),
      );
    }),
  );
}

bool isSupportedWinetricksVerb(String verb) {
  return RegExp(r'^[A-Za-z0-9_.+-]+$').hasMatch(verb);
}
