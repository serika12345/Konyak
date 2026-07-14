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

  test('parses invalid bottles alongside usable bottle records', () {
    final result = parseBottleListPayload('''
      {
        "schemaVersion": 1,
        "bottles": [
          {
            "id": "usable",
            "name": "Usable",
            "path": "/bottles/usable",
            "windowsVersion": "win10"
          }
        ],
        "invalidBottles": [
          {
            "storageId": "steam",
            "path": "/bottles/steam",
            "code": "invalidProgramProfiles",
            "message": "Program profile metadata is incompatible.",
            "recoveryActions": ["discardInvalidProfiles"]
          }
        ]
      }
      ''');

    expect(result, isA<ParsedBottleList>());
    final parsed = result as ParsedBottleList;
    expect(parsed.bottles.single.id, 'usable');
    expect(parsed.invalidBottles.single.storageId, 'steam');
    expect(parsed.invalidBottles.single.path, '/bottles/steam');
    expect(
      parsed.invalidBottles.single.code,
      InvalidBottleCode.invalidProgramProfiles,
    );
    expect(parsed.invalidBottles.single.recoveryActions, const [
      InvalidBottleRecoveryAction.discardInvalidProfiles,
    ]);
    expect(parsed.invalidBottles.clear, throwsUnsupportedError);
  });

  test('rejects invalid bottle records with unsupported recovery actions', () {
    final result = parseBottleListPayload('''
      {
        "schemaVersion": 1,
        "bottles": [],
        "invalidBottles": [
          {
            "storageId": "steam",
            "path": "/bottles/steam",
            "code": "invalidProgramProfiles",
            "message": "Program profile metadata is incompatible.",
            "recoveryActions": ["silentlyMigrateProfiles"]
          }
        ]
      }
      ''');

    expect(result, isA<BottleListParseFailure>());
  });

  test('rejects duplicate IDs in usable bottle records', () {
    final result = parseBottleListPayload('''
      {
        "schemaVersion": 1,
        "bottles": [
          {
            "id": "steam",
            "name": "Steam A",
            "path": "/bottles/steam-a",
            "windowsVersion": "win10"
          },
          {
            "id": "steam",
            "name": "Steam B",
            "path": "/bottles/steam-b",
            "windowsVersion": "win10"
          }
        ],
        "invalidBottles": []
      }
      ''');

    expect(result, isA<BottleListParseFailure>());
  });

  test('rejects duplicate storage IDs in invalid bottle records', () {
    final result = parseBottleListPayload('''
      {
        "schemaVersion": 1,
        "bottles": [],
        "invalidBottles": [
          {
            "storageId": "steam",
            "path": "/bottles/steam-a",
            "code": "invalidProgramProfiles",
            "message": "Program profile metadata is incompatible.",
            "recoveryActions": ["discardInvalidProfiles"]
          },
          {
            "storageId": "steam",
            "path": "/bottles/steam-b",
            "code": "invalidBottleMetadata",
            "message": "Bottle metadata is invalid.",
            "recoveryActions": []
          }
        ]
      }
      ''');

    expect(result, isA<BottleListParseFailure>());
  });

  test('rejects IDs shared by usable and invalid bottle records', () {
    final result = parseBottleListPayload('''
      {
        "schemaVersion": 1,
        "bottles": [
          {
            "id": "steam",
            "name": "Steam",
            "path": "/bottles/steam",
            "windowsVersion": "win10"
          }
        ],
        "invalidBottles": [
          {
            "storageId": "steam",
            "path": "/other-bottles/steam",
            "code": "invalidProgramProfiles",
            "message": "Program profile metadata is incompatible.",
            "recoveryActions": ["discardInvalidProfiles"]
          }
        ]
      }
      ''');

    expect(result, isA<BottleListParseFailure>());
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

  test('rejects malformed pinned program records', () {
    final result = parseBottleListPayload('''
      {
        "schemaVersion": 1,
        "bottles": [
          {
            "id": "bottle-1",
            "name": "Steam",
            "path": "/home/user/.local/share/konyak/bottles/steam",
            "windowsVersion": "win10",
            "pinnedPrograms": [
              {
                "name": "Steam",
                "path": "/downloads/Steam.exe",
                "removable": "yes"
              }
            ]
          }
        ]
      }
      ''');

    expect(result, isA<BottleListParseFailure>());
  });
}
