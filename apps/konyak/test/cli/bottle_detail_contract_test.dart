import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/cli/bottle_detail_contract.dart';

void main() {
  test('parses a valid bottle detail payload', () {
    final result = parseBottleDetailPayload('''
      {
        "schemaVersion": 1,
        "bottle": {
          "id": "steam",
          "name": "Steam",
          "path": "/home/user/.local/share/konyak/bottles/steam",
          "windowsVersion": "win10"
        }
      }
      ''');

    expect(result, isA<ParsedBottleDetail>());
    final parsed = result as ParsedBottleDetail;
    expect(parsed.bottle.id, 'steam');
    expect(parsed.bottle.name, 'Steam');
    expect(parsed.bottle.windowsVersion, 'win10');
  });

  test('parses a machine-readable bottle not-found error', () {
    final result = parseBottleDetailPayload('''
      {
        "schemaVersion": 1,
        "error": {
          "code": "bottleNotFound",
          "message": "Bottle not found.",
          "bottleId": "missing"
        }
      }
      ''');

    expect(result, isA<BottleDetailNotFound>());
    final notFound = result as BottleDetailNotFound;
    expect(notFound.bottleId, 'missing');
    expect(notFound.message, 'Bottle not found.');
  });

  test('rejects unsupported schema versions', () {
    final result = parseBottleDetailPayload(
      '{"schemaVersion":2,"bottle":{"id":"steam"}}',
    );

    expect(result, isA<BottleDetailParseFailure>());
  });

  test('rejects invalid bottle detail payloads', () {
    final result = parseBottleDetailPayload(
      '{"schemaVersion":1,"bottle":{"id":"missing-fields"}}',
    );

    expect(result, isA<BottleDetailParseFailure>());
  });
}
