import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/cli/bottle_create_contract.dart';

void main() {
  test('parses a valid bottle creation payload', () {
    final result = parseBottleCreatePayload('''
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

    expect(result, isA<ParsedBottleCreate>());
    final parsed = result as ParsedBottleCreate;
    expect(parsed.bottle.id, 'steam');
    expect(parsed.bottle.name, 'Steam');
  });

  test('parses a machine-readable bottle conflict error', () {
    final result = parseBottleCreatePayload('''
      {
        "schemaVersion": 1,
        "error": {
          "code": "bottleAlreadyExists",
          "message": "Bottle already exists.",
          "bottleId": "steam"
        }
      }
      ''');

    expect(result, isA<BottleCreateConflict>());
    final conflict = result as BottleCreateConflict;
    expect(conflict.bottleId, 'steam');
    expect(conflict.message, 'Bottle already exists.');
  });

  test('rejects unsupported schema versions', () {
    final result = parseBottleCreatePayload(
      '{"schemaVersion":2,"bottle":{"id":"steam"}}',
    );

    expect(result, isA<BottleCreateParseFailure>());
  });

  test('rejects invalid bottle creation payloads', () {
    final result = parseBottleCreatePayload(
      '{"schemaVersion":1,"bottle":{"id":"missing-fields"}}',
    );

    expect(result, isA<BottleCreateParseFailure>());
  });
}
