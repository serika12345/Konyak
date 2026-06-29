import 'package:flutter_test/flutter_test.dart';
import 'package:konyak/src/cli/bottle_record_contract.dart';

void main() {
  test('parses bottle records into explicit parse results', () {
    final result = parseBottleSummary({
      'id': 'steam',
      'name': 'Steam',
      'path': '/home/user/.local/share/konyak/bottles/steam',
      'windowsVersion': 'win10',
      'runtimeSettings': {
        'enhancedSync': 'msync',
        'dxvkHud': 'off',
        'dpiScaling': 144,
      },
      'pinnedPrograms': [
        {
          'name': 'Steam',
          'path':
              '/home/user/.local/share/konyak/bottles/steam/drive_c/steam.exe',
          'removable': true,
          'iconPath': '/tmp/steam.png',
        },
      ],
    });

    expect(result, isA<ParsedBottleSummary>());
    final bottle = (result as ParsedBottleSummary).bottle;
    expect(bottle.id, 'steam');
    expect(bottle.runtimeSettings.dpiScaling, 144);
    expect(bottle.pinnedPrograms.single.iconPath, '/tmp/steam.png');
  });

  test('rejects invalid bottle records with explicit parse results', () {
    final result = parseBottleSummary({
      'id': 'steam',
      'name': 'Steam',
      'path': '/home/user/.local/share/konyak/bottles/steam',
      'windowsVersion': 'win10',
      'runtimeSettings': {'dpiScaling': 145},
    });

    expect(result, isA<InvalidBottleSummary>());
  });
}
