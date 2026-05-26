import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/cli/bottle_list_contract.dart';

void main() {
  test('parses a valid empty bottle list payload', () {
    final result = parseBottleListPayload('{"schemaVersion":1,"bottles":[]}');

    expect(result, isA<ParsedBottleList>());
    final parsed = result as ParsedBottleList;
    expect(parsed.bottles, isEmpty);
  });

  test('parses valid bottle records into immutable domain values', () {
    final result = parseBottleListPayload('''
      {
        "schemaVersion": 1,
        "bottles": [
          {
            "id": "bottle-1",
            "name": "Steam",
            "path": "/home/user/.local/share/konyak/bottles/steam",
            "windowsVersion": "win10"
          }
        ]
      }
      ''');

    expect(result, isA<ParsedBottleList>());
    final parsed = result as ParsedBottleList;
    expect(parsed.bottles.single.id, 'bottle-1');
    expect(parsed.bottles.single.name, 'Steam');
    expect(
      parsed.bottles.single.path,
      '/home/user/.local/share/konyak/bottles/steam',
    );
    expect(parsed.bottles.single.windowsVersion, 'win10');
    expect(
      () => parsed.bottles.add(parsed.bottles.single),
      throwsUnsupportedError,
    );
  });

  test('rejects unsupported schema versions', () {
    final result = parseBottleListPayload('{"schemaVersion":2,"bottles":[]}');

    expect(result, isA<BottleListParseFailure>());
  });

  test('rejects invalid bottle records', () {
    final result = parseBottleListPayload(
      '{"schemaVersion":1,"bottles":[{"id":"missing-fields"}]}',
    );

    expect(result, isA<BottleListParseFailure>());
  });
}
