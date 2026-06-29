import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/cli/konyak_cli_winetricks_payload_parsers.dart';

void main() {
  test('parses winetricks categories into explicit parse results', () {
    final result = parseWinetricksCategorySummary({
      'id': 'dlls',
      'name': 'DLLs',
      'verbs': [
        {
          'id': 'corefonts',
          'name': 'corefonts',
          'description': 'Microsoft Core Fonts',
        },
      ],
    });

    expect(result, isA<ParsedWinetricksCategorySummary>());
    final category = (result as ParsedWinetricksCategorySummary).category;
    expect(category.id, 'dlls');
    expect(category.verbs.single.id, 'corefonts');
  });

  test('rejects invalid winetricks categories with explicit parse results', () {
    final result = parseWinetricksCategorySummary({
      'id': 'dlls',
      'name': 'DLLs',
      'verbs': [
        {'id': 'corefonts', 'name': 'corefonts'},
      ],
    });

    expect(result, isA<InvalidWinetricksCategorySummary>());
  });

  test('parses winetricks verbs into explicit parse results', () {
    final result = parseWinetricksVerbSummary({
      'id': 'corefonts',
      'name': 'corefonts',
      'description': 'Microsoft Core Fonts',
    });

    expect(result, isA<ParsedWinetricksVerbSummary>());
    final verb = (result as ParsedWinetricksVerbSummary).verb;
    expect(verb.description, 'Microsoft Core Fonts');
  });

  test('rejects invalid winetricks verbs with explicit parse results', () {
    final result = parseWinetricksVerbSummary({
      'id': 'corefonts',
      'name': 'corefonts',
    });

    expect(result, isA<InvalidWinetricksVerbSummary>());
  });
}
