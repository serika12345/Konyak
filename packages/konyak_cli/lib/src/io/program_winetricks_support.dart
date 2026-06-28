part of '../../konyak_cli.dart';

List<WinetricksCategoryRecord> parseWinetricksVerbs(String content) {
  final state = content
      .split('\n')
      .fold(
        _WinetricksVerbParseState.empty(),
        (state, line) => state.withLine(line),
      );
  return state.flushCurrentCategory().categories;
}

final class _WinetricksVerbParseState {
  _WinetricksVerbParseState({
    required Iterable<WinetricksCategoryRecord> categories,
    required this.currentCategory,
  }) : categories = List.unmodifiable(categories);

  factory _WinetricksVerbParseState.empty() {
    return _WinetricksVerbParseState(
      categories: <WinetricksCategoryRecord>[],
      currentCategory: const Option.none(),
    );
  }

  final List<WinetricksCategoryRecord> categories;
  final Option<_PendingWinetricksCategory> currentCategory;

  _WinetricksVerbParseState withLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      return this;
    }

    return _winetricksCategoryId(
      trimmed,
    ).match(() => withVerbLine(trimmed), startCategory);
  }

  _WinetricksVerbParseState startCategory(String id) {
    return _winetricksCategoryName(id).match(
      () => flushCurrentCategory().withoutCurrentCategory(),
      (name) => flushCurrentCategory().withCurrentCategory(
        _PendingWinetricksCategory(id: id, name: name, verbs: const []),
      ),
    );
  }

  _WinetricksVerbParseState withVerbLine(String line) {
    return currentCategory.match(
      () => this,
      (category) => _parseWinetricksVerbLine(line).match(
        () => this,
        (verb) => withCurrentCategory(category.withVerb(verb)),
      ),
    );
  }

  _WinetricksVerbParseState flushCurrentCategory() {
    return currentCategory.match(
      () => this,
      (category) => _WinetricksVerbParseState(
        categories: category.verbs.isEmpty
            ? categories
            : <WinetricksCategoryRecord>[...categories, category.toRecord()],
        currentCategory: const Option.none(),
      ),
    );
  }

  _WinetricksVerbParseState withoutCurrentCategory() {
    return _WinetricksVerbParseState(
      categories: categories,
      currentCategory: const Option.none(),
    );
  }

  _WinetricksVerbParseState withCurrentCategory(
    _PendingWinetricksCategory category,
  ) {
    return _WinetricksVerbParseState(
      categories: categories,
      currentCategory: Option.of(category),
    );
  }
}

final class _PendingWinetricksCategory {
  _PendingWinetricksCategory({
    required this.id,
    required this.name,
    required Iterable<WinetricksVerbRecord> verbs,
  }) : verbs = List.unmodifiable(verbs);

  final String id;
  final String name;
  final List<WinetricksVerbRecord> verbs;

  _PendingWinetricksCategory withVerb(WinetricksVerbRecord verb) {
    return _PendingWinetricksCategory(
      id: id,
      name: name,
      verbs: <WinetricksVerbRecord>[...verbs, verb],
    );
  }

  WinetricksCategoryRecord toRecord() {
    return WinetricksCategoryRecord(id: id, name: name, verbs: verbs);
  }
}

Option<String> _winetricksCategoryId(String line) {
  if (!line.startsWith('=====') || !line.endsWith('=====')) {
    return const Option.none();
  }

  final id = line.replaceAll('=', '').trim().toLowerCase();
  return id.isEmpty ? const Option.none() : Option.of(id);
}

Option<String> _winetricksCategoryName(String id) {
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

Option<WinetricksVerbRecord> _parseWinetricksVerbLine(String line) {
  return _nullableOption(RegExp(r'^(\S+)\s*(.*)$').firstMatch(line)).flatMap(
    (match) => _nullableOption(match.group(1)).flatMap((rawName) {
      final name = rawName.trim();
      if (!isSupportedWinetricksVerb(name)) {
        return const Option.none();
      }

      return Option.of(
        WinetricksVerbRecord(
          id: name,
          name: name,
          description: _nullableOption(
            match.group(2),
          ).match(() => '', (value) => value.trim()),
        ),
      );
    }),
  );
}

bool isSupportedWinetricksVerb(String verb) {
  return RegExp(r'^[A-Za-z0-9_.+-]+$').hasMatch(verb);
}
