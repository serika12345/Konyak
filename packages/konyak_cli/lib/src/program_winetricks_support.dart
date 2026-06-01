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
    if (categoryId != null) {
      flushCurrentCategory();
      final categoryName = _winetricksCategoryName(categoryId);
      if (categoryName != null) {
        currentCategoryId = categoryId;
        currentCategoryName = categoryName;
      }
      continue;
    }

    if (currentCategoryId.isEmpty) {
      continue;
    }

    final verb = _parseWinetricksVerbLine(trimmed);
    if (verb != null) {
      currentVerbs.add(verb);
    }
  }

  flushCurrentCategory();

  return List.unmodifiable(
    categories.where((category) => category.verbs.isNotEmpty),
  );
}

String? _winetricksCategoryId(String line) {
  if (!line.startsWith('=====') || !line.endsWith('=====')) {
    return null;
  }

  final id = line.replaceAll('=', '').trim().toLowerCase();
  return id.isEmpty ? null : id;
}

String? _winetricksCategoryName(String id) {
  return switch (id) {
    'apps' => 'Apps',
    'benchmarks' => 'Benchmarks',
    'dlls' => 'DLLs',
    'fonts' => 'Fonts',
    'games' => 'Games',
    'settings' => 'Settings',
    _ => null,
  };
}

WinetricksVerbRecord? _parseWinetricksVerbLine(String line) {
  final match = RegExp(r'^(\S+)\s*(.*)$').firstMatch(line);
  if (match == null) {
    return null;
  }

  final name = match.group(1)?.trim() ?? '';
  if (!_isSupportedWinetricksVerb(name)) {
    return null;
  }

  return WinetricksVerbRecord(
    id: name,
    name: name,
    description: match.group(2)?.trim() ?? '',
  );
}

bool _isSupportedWinetricksVerb(String verb) {
  return RegExp(r'^[A-Za-z0-9_.+-]+$').hasMatch(verb);
}
