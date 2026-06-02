part of '../konyak_cli.dart';

List<WinetricksCategoryRecord> parseWinetricksVerbs(String content) {
  final categories = <WinetricksCategoryRecord>[];
  var currentCategoryId = '';
  var currentCategoryName = '';
  var currentVerbs = <WinetricksVerbRecord>[];

  void flushCurrentCategory() {
    if (currentCategoryId.isEmpty) {
      return;
    }

    categories.add(
      WinetricksCategoryRecord(
        id: currentCategoryId,
        name: currentCategoryName,
        verbs: currentVerbs,
      ),
    );
    currentCategoryId = '';
    currentCategoryName = '';
    currentVerbs = <WinetricksVerbRecord>[];
  }

  for (final line in content.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      continue;
    }

    final categoryId = _winetricksCategoryId(trimmed);
    categoryId.match(() {}, (id) {
      flushCurrentCategory();
      _winetricksCategoryName(id).match(() {}, (name) {
        currentCategoryId = id;
        currentCategoryName = name;
      });
    });
    if (categoryId.isSome()) {
      continue;
    }

    if (currentCategoryId.isEmpty) {
      continue;
    }

    final verb = _parseWinetricksVerbLine(trimmed);
    verb.match(() {}, currentVerbs.add);
  }

  flushCurrentCategory();

  return List.unmodifiable(
    categories.where((category) => category.verbs.isNotEmpty),
  );
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
  final match = RegExp(r'^(\S+)\s*(.*)$').firstMatch(line);
  if (match == null) {
    return const Option.none();
  }

  final name = match.group(1)?.trim() ?? '';
  if (!_isSupportedWinetricksVerb(name)) {
    return const Option.none();
  }

  return Option.of(
    WinetricksVerbRecord(
      id: name,
      name: name,
      description: match.group(2)?.trim() ?? '',
    ),
  );
}

bool _isSupportedWinetricksVerb(String verb) {
  return RegExp(r'^[A-Za-z0-9_.+-]+$').hasMatch(verb);
}
